# ============================================================================
# CarbonTrack - Sistema de Rastreabilidade para Créditos de Carbono
# Protótipo operacional (interface gráfica desktop)
#
# SGBD alvo: PostgreSQL
# Pré-requisitos no banco: executar antes esquema.sql e dados.sql.
#
# Bibliotecas:
#   * tkinter / ttk  -> interface gráfica nativa (janela de aplicativo desktop)
#   * psycopg2       ->  driver de conexão com o PostgreSQL
#       Instale com:  pip install -r requirements.txt
#
# Funcionalidades implementadas (atendendo ao enunciado):
#   (a) CADASTRO de dados: inserção em PROJETO e em ATIVIDADE, com validação
#       de entrada, cálculo do atributo derivado Duração (N10/N11) e tratamento
#       de erros do banco (PK duplicada, FK inexistente, CHECK violado etc.).
#   (b) CONSULTA parametrizada: as consultas C1..C6 do script consultas.sql,
#       com a entrada do usuário usada como parâmetro (placeholders %s,
#       imunes a SQL injection).
# ============================================================================

import tkinter as tk
from tkinter import ttk, messagebox
from datetime import datetime
from decimal import Decimal, InvalidOperation

try:
    import psycopg2
    from psycopg2 import errors as pg_errors
except ImportError:  # pragma: no cover
    psycopg2 = None
    pg_errors = None


# ----------------------------------------------------------------------------
# Widgets de entrada com máscara
# ----------------------------------------------------------------------------
class DateEntry(ttk.Entry):
    """Entry com máscara automática AAAA-MM-DD.
    Aceita apenas dígitos e insere os hífens automaticamente."""

    def __init__(self, master, textvariable, **kw):
        kw.setdefault("width", 14)
        super().__init__(master, textvariable=textvariable, **kw)
        self._var = textvariable
        self._busy = False
        self._var.trace_add("write", self._on_change)

    def _on_change(self, *_):
        if self._busy:
            return
        raw = self._var.get()
        digits = "".join(c for c in raw if c.isdigit())[:8]
        if len(digits) >= 7:
            fmt = f"{digits[:4]}-{digits[4:6]}-{digits[6:]}"
        elif len(digits) >= 5:
            fmt = f"{digits[:4]}-{digits[4:]}"
        else:
            fmt = digits
        if fmt == raw:
            return
        try:
            cur = self.index(tk.INSERT)
            n_digits_before = sum(1 for c in raw[:cur] if c.isdigit())
        except Exception:
            n_digits_before = len(digits)
        self._busy = True
        self._var.set(fmt)
        # Restaura o cursor após o mesmo número de dígitos na string formatada
        new_pos = len(fmt)
        count = 0
        for i, ch in enumerate(fmt):
            if ch.isdigit():
                count += 1
            if count == n_digits_before:
                new_pos = i + 1
                break
        self.after_idle(lambda p=new_pos: self.icursor(p))
        self._busy = False


class DecimalEntry(ttk.Entry):
    """Entry que aceita apenas valores decimais não-negativos.
    Aceita vírgula ou ponto como separador decimal."""

    def __init__(self, master, textvariable, **kw):
        kw.setdefault("width", 24)
        super().__init__(master, textvariable=textvariable, **kw)
        vcmd = (self.register(self._validate), "%P")
        self.configure(validate="key", validatecommand=vcmd)

    @staticmethod
    def _validate(new_val):
        if not new_val:
            return True
        if sum(1 for c in new_val if c in ".,") > 1:
            return False
        return all(c.isdigit() or c in ".," for c in new_val)


# ----------------------------------------------------------------------------
# Widgets de entrada com máscara
# ----------------------------------------------------------------------------
class DateEntry(ttk.Entry):
    """Entry com máscara automática AAAA-MM-DD.
    Aceita apenas dígitos e insere os hífens automaticamente."""

    def __init__(self, master, textvariable, **kw):
        kw.setdefault("width", 14)
        super().__init__(master, textvariable=textvariable, **kw)
        self._var = textvariable
        self._busy = False
        self._var.trace_add("write", self._on_change)

    def _on_change(self, *_):
        if self._busy:
            return
        raw = self._var.get()
        digits = "".join(c for c in raw if c.isdigit())[:8]
        if len(digits) >= 7:
            fmt = f"{digits[:4]}-{digits[4:6]}-{digits[6:]}"
        elif len(digits) >= 5:
            fmt = f"{digits[:4]}-{digits[4:]}"
        else:
            fmt = digits
        if fmt == raw:
            return
        try:
            cur = self.index(tk.INSERT)
            n_digits_before = sum(1 for c in raw[:cur] if c.isdigit())
        except Exception:
            n_digits_before = len(digits)
        self._busy = True
        self._var.set(fmt)
        # Restaura o cursor após o mesmo número de dígitos na string formatada
        new_pos = len(fmt)
        count = 0
        for i, ch in enumerate(fmt):
            if ch.isdigit():
                count += 1
            if count == n_digits_before:
                new_pos = i + 1
                break
        self.after_idle(lambda p=new_pos: self.icursor(p))
        self._busy = False


class DecimalEntry(ttk.Entry):
    """Entry que aceita apenas valores decimais não-negativos.
    Aceita vírgula ou ponto como separador decimal."""

    def __init__(self, master, textvariable, **kw):
        kw.setdefault("width", 24)
        super().__init__(master, textvariable=textvariable, **kw)
        vcmd = (self.register(self._validate), "%P")
        self.configure(validate="key", validatecommand=vcmd)

    @staticmethod
    def _validate(new_val):
        if not new_val:
            return True
        if sum(1 for c in new_val if c in ".,") > 1:
            return False
        return all(c.isdigit() or c in ".," for c in new_val)


# ----------------------------------------------------------------------------
# Paleta de cores e fontes # verde escuro (tema "carbono/floresta")
# ----------------------------------------------------------------------------
COR_PRIMARIA   = "#1b5e20"   
COR_SECUNDARIA = "#2e7d32"
COR_FUNDO      = "#f4f6f4"
COR_CARTAO     = "#ffffff"
COR_TEXTO      = "#1c2b1c"
COR_ERRO       = "#c62828"
COR_OK         = "#2e7d32"

FONTE_TITULO   = ("Segoe UI", 20, "bold")
FONTE_SUBTIT   = ("Segoe UI", 10)
FONTE_SECAO    = ("Segoe UI", 12, "bold")
FONTE_LABEL    = ("Segoe UI", 10)


# ----------------------------------------------------------------------------
# Catálogo de consultas parametrizadas (extraídas de scripts_sql/consultas.sql)
# Cada consulta declara seus parâmetros (rótulo + valor padrão). Os valores são
# enviados ao banco via placeholders %s, evitando concatenação de strings.
# ----------------------------------------------------------------------------
SQL_C1 = """
WITH ultima_transacao AS (
    SELECT DISTINCT ON (tl.Lote)
        tl.Lote            AS num_serie,
        t.Nota_Fiscal,
        t.Data_Hora        AS data_ultima_transacao,
        t.Valor            AS valor_ultima_transacao,
        pj_v.Nome_Fantasia AS vendedor,
        pj_c.Nome_Fantasia AS comprador_atual
    FROM TRANSACAO_LOTE tl
    JOIN TRANSACAO       t    ON tl.Transacao = t.Nota_Fiscal
    JOIN PESSOA_JURIDICA pj_v ON t.Agente_Mercado_Vendedor  = pj_v.CNPJ
    JOIN PESSOA_JURIDICA pj_c ON t.Agente_Mercado_Comprador = pj_c.CNPJ
    ORDER BY tl.Lote, t.Data_Hora DESC
)
SELECT
    l.Num_Serie_Registro,
    l.Quantidade_de_Credito AS creditos_tCO2e,
    l.Ano_Geracao,
    l.Status_Ciclo_de_Vida,
    a.Codigo_Ordem_Servico  AS atividade,
    a.Descricao_Atividade,
    p.Nome_Projeto,
    p.Metodologia_Aplicada,
    pj_orig.Nome_Fantasia   AS originador,
    pj_aud.Nome_Fantasia    AS auditor,
    aud.Registro_Acreditacao,
    ld.Numero_do_Protocolo,
    ld.Parecer_Final,
    pj_cert.Nome_Fantasia   AS certificador,
    ut.Nota_Fiscal          AS ultima_nota_fiscal,
    ut.data_ultima_transacao,
    ut.valor_ultima_transacao,
    ut.vendedor,
    ut.comprador_atual
FROM LOTE l
JOIN  ATIVIDADE       a       ON l.Atividade   = a.Codigo_Ordem_Servico
JOIN  ORIGINADOR      orig    ON a.Originador  = orig.CNPJ
JOIN  PESSOA_JURIDICA pj_orig ON orig.CNPJ     = pj_orig.CNPJ
LEFT JOIN PROJETO     p       ON a.Projeto     = p.Num_Licenca_Ambiental
LEFT JOIN AUDITOR     aud     ON a.Auditor     = aud.CNPJ
LEFT JOIN PESSOA_JURIDICA pj_aud  ON aud.CNPJ  = pj_aud.CNPJ
LEFT JOIN LAUDO       ld      ON ld.Atividade  = a.Codigo_Ordem_Servico
LEFT JOIN CERTIFICADOR cert   ON ld.Certificador = cert.CNPJ
LEFT JOIN PESSOA_JURIDICA pj_cert ON cert.CNPJ = pj_cert.CNPJ
LEFT JOIN ultima_transacao ut ON ut.num_serie = l.Num_Serie_Registro
WHERE l.Num_Serie_Registro = %s
"""

SQL_C2 = """
SELECT
    p.Num_Licenca_Ambiental,
    p.Nome_Projeto,
    p.Metodologia_Aplicada,
    COUNT(DISTINCT l.Num_Serie_Registro)              AS total_lotes_emitidos,
    COALESCE(SUM(l.Quantidade_de_Credito), 0)         AS total_creditos_tCO2e,
    COALESCE(SUM(l.Valor * l.Quantidade_de_Credito), 0) AS valor_total_lotes,
    COUNT(DISTINCT tl.Transacao)                      AS total_transacoes
FROM PROJETO p
JOIN  ATIVIDADE      a   ON a.Projeto   = p.Num_Licenca_Ambiental
LEFT JOIN LOTE       l   ON l.Atividade = a.Codigo_Ordem_Servico
LEFT JOIN TRANSACAO_LOTE tl ON tl.Lote = l.Num_Serie_Registro
GROUP BY p.Num_Licenca_Ambiental, p.Nome_Projeto, p.Metodologia_Aplicada
ORDER BY total_creditos_tCO2e DESC
"""

SQL_C3 = """
SELECT
    a.Codigo_Ordem_Servico,
    pj.Nome_Fantasia     AS originador,
    a.Descricao_Atividade,
    a.Data_Inicio,
    a.Data_Fim,
    a.Duracao            AS duracao_dias,
    a.Credito_Estimado   AS credito_estimado_tCO2e,
    pj_aud.Nome_Fantasia AS auditor_contratado
FROM ATIVIDADE a
JOIN  ORIGINADOR      orig ON a.Originador = orig.CNPJ
JOIN  PESSOA_JURIDICA pj   ON orig.CNPJ    = pj.CNPJ
LEFT JOIN PESSOA_JURIDICA pj_aud ON a.Auditor = pj_aud.CNPJ
WHERE a.Data_Fim IS NOT NULL
  AND a.Data_Fim < CURRENT_DATE
  AND a.Codigo_Ordem_Servico NOT IN (SELECT l.Atividade FROM LAUDO l)
ORDER BY a.Data_Fim
"""

SQL_C4 = """
SELECT
    hp.Num_Serie_Registro,
    pj.Nome_Fantasia AS originador_do_lote,
    hp.Data,
    hp.Preco         AS preco_unitario,
    hp.Preco - LAG(hp.Preco) OVER w AS variacao_abs,
    ROUND(
        (hp.Preco - LAG(hp.Preco) OVER w)
        / NULLIF(LAG(hp.Preco) OVER w, 0) * 100
    , 2)             AS variacao_pct
FROM HISTORICO_PRECO hp
JOIN LOTE       l    ON hp.Num_Serie_Registro = l.Num_Serie_Registro
JOIN ATIVIDADE  a    ON l.Atividade           = a.Codigo_Ordem_Servico
JOIN ORIGINADOR orig ON a.Originador          = orig.CNPJ
JOIN PESSOA_JURIDICA pj ON orig.CNPJ          = pj.CNPJ
WHERE hp.Num_Serie_Registro = %s
WINDOW w AS (PARTITION BY hp.Num_Serie_Registro ORDER BY hp.Data)
ORDER BY hp.Data
"""

SQL_C5 = """
SELECT
    o.CNPJ,
    pj.Nome_Fantasia AS originador,
    pj.Status
FROM ORIGINADOR      o
JOIN PESSOA_JURIDICA pj ON o.CNPJ = pj.CNPJ
WHERE NOT EXISTS (
    SELECT 1
    FROM CERTIFICADOR        c
    JOIN AGENTE_CONFORMIDADE ac  ON c.CNPJ = ac.CNPJ
    JOIN PESSOA_JURIDICA     pjc ON c.CNPJ = pjc.CNPJ
    WHERE pjc.Status = 'Apto'
      AND NOT EXISTS (
          SELECT 1
          FROM LAUDO     ld
          JOIN ATIVIDADE a ON ld.Atividade = a.Codigo_Ordem_Servico
          WHERE a.Originador    = o.CNPJ
            AND ld.Certificador = c.CNPJ
      )
)
ORDER BY pj.Nome_Fantasia
"""

SQL_C6 = """
WITH proprietario_por_transacao AS (
    SELECT DISTINCT ON (tl.Lote)
        tl.Lote                    AS num_serie,
        t.Agente_Mercado_Comprador AS cnpj_dono_atual,
        pj.Nome_Fantasia           AS nome_dono_atual,
        t.Data_Hora                AS data_aquisicao,
        'Transação'                AS origem_posse
    FROM TRANSACAO_LOTE  tl
    JOIN TRANSACAO       t  ON tl.Transacao = t.Nota_Fiscal
    JOIN PESSOA_JURIDICA pj ON t.Agente_Mercado_Comprador = pj.CNPJ
    ORDER BY tl.Lote, t.Data_Hora DESC
)
SELECT
    l.Num_Serie_Registro,
    l.Quantidade_de_Credito AS creditos_tCO2e,
    l.Valor                 AS preco_unitario_atual,
    COALESCE(pt.cnpj_dono_atual, a.Originador)            AS cnpj_proprietario,
    COALESCE(pt.nome_dono_atual, pj_orig.Nome_Fantasia)  AS proprietario_atual,
    COALESCE(pt.data_aquisicao,  a.Data_Inicio)          AS desde,
    COALESCE(pt.origem_posse,    'Originador inicial')   AS origem_posse
FROM LOTE            l
JOIN ATIVIDADE       a       ON l.Atividade  = a.Codigo_Ordem_Servico
JOIN PESSOA_JURIDICA pj_orig ON a.Originador = pj_orig.CNPJ
LEFT JOIN proprietario_por_transacao pt ON pt.num_serie = l.Num_Serie_Registro
WHERE l.Status_Ciclo_de_Vida = 'Disponível'
ORDER BY l.Num_Serie_Registro
"""

CONSULTAS = {
    "C1 - Rastreabilidade completa de um Lote": {
        "sql": SQL_C1,
        "descricao": "Histórico completo de um lote: atividade/projeto geradores, "
                     "auditor, certificador e última transação.",
        "params": [("Número de Série do Lote", "BR-VCS-2024-0001")],
    },
    "C2 - Desempenho de Projetos (créditos e valor)": {
        "sql": SQL_C2,
        "descricao": "Total de créditos e valor financeiro movimentado, agrupado "
                     "por projeto (GROUP BY + agregações).",
        "params": [],
    },
    "C3 - Atividades finalizadas sem Laudo": {
        "sql": SQL_C3,
        "descricao": "Atividades já encerradas que ainda não possuem laudo "
                     "de auditoria (risco de conformidade).",
        "params": [],
    },
    "C4 - Evolução de preço de um Lote": {
        "sql": SQL_C4,
        "descricao": "Série histórica de preços de um lote, com variação "
                     "absoluta e percentual (função de janela LAG).",
        "params": [("Número de Série do Lote", "BR-VCS-2024-0001")],
    },
    "C5 - Originadores aprovados por TODAS as certificadoras": {
        "sql": SQL_C5,
        "descricao": "Divisão relacional: originadores com laudos de todas as "
                     "certificadoras ativas (NOT EXISTS aninhado).",
        "params": [],
    },
    "C6 - Proprietário atual de cada Lote disponível": {
        "sql": SQL_C6,
        "descricao": "Dono atual de cada lote 'Disponível', inferido pela última "
                     "transação ou pelo originador inicial.",
        "params": [],
    },
}


# ----------------------------------------------------------------------------
# Aplicação principal
# ----------------------------------------------------------------------------
class CarbonTrackApp(tk.Tk):
    def __init__(self):
        super().__init__()
        self.conn = None  # conexão psycopg2 (ou None enquanto desconectado)

        self.title("CarbonTrack — Rastreabilidade de Créditos de Carbono")
        self.geometry("1080x720")
        self.minsize(960, 640)
        self.configure(bg=COR_FUNDO)

        self._configurar_estilo()
        self._construir_cabecalho()
        self._construir_barra_conexao()

        # Caderno (abas) principal
        self.notebook = ttk.Notebook(self)
        self.notebook.pack(fill="both", expand=True, padx=12, pady=(0, 6))

        self.aba_cadastro = ttk.Frame(self.notebook, style="Card.TFrame")
        self.aba_consulta = ttk.Frame(self.notebook, style="Card.TFrame")
        self.notebook.add(self.aba_cadastro, text="  Cadastro de Dados  ")
        self.notebook.add(self.aba_consulta, text="  Consultas Parametrizadas  ")

        self._construir_aba_cadastro()
        self._construir_aba_consulta()
        self._construir_barra_status()

        if psycopg2 is None:
            self.after(300, self._avisar_sem_driver)

    # --- estilo
    def _configurar_estilo(self):
        style = ttk.Style(self)
        try:
            style.theme_use("clam")
        except tk.TclError:
            pass

        style.configure("TFrame", background=COR_FUNDO)
        style.configure("Card.TFrame", background=COR_CARTAO)
        style.configure("TLabel", background=COR_CARTAO, foreground=COR_TEXTO,
                        font=FONTE_LABEL)
        style.configure("Bar.TLabel", background=COR_FUNDO, foreground=COR_TEXTO,
                        font=FONTE_LABEL)
        style.configure("Secao.TLabel", background=COR_CARTAO,
                        foreground=COR_PRIMARIA, font=FONTE_SECAO)
        style.configure("TButton", font=("Segoe UI", 10, "bold"), padding=6)
        style.configure("Accent.TButton", foreground="white",
                        background=COR_PRIMARIA)
        style.map("Accent.TButton",
                  background=[("active", COR_SECUNDARIA), ("disabled", "#9e9e9e")])
        style.configure("TEntry", padding=4)
        style.configure("TCombobox", padding=4)
        style.configure("Treeview", font=("Segoe UI", 9), rowheight=24,
                        background="white", fieldbackground="white")
        style.configure("Treeview.Heading", font=("Segoe UI", 9, "bold"),
                        background=COR_SECUNDARIA, foreground="white")
        style.configure("TNotebook", background=COR_FUNDO, borderwidth=0)
        style.configure("TNotebook.Tab", font=("Segoe UI", 10, "bold"), padding=(14, 8))

    # --- cabeçalho
    def _construir_cabecalho(self):
        header = tk.Frame(self, bg=COR_PRIMARIA, height=70)
        header.pack(fill="x")
        header.pack_propagate(False)
        tk.Label(header, text=" CarbonTrack", bg=COR_PRIMARIA, fg="white",
                 font=FONTE_TITULO).pack(side="left", padx=20)
        tk.Label(header, text="Sistema de Rastreabilidade para Créditos de Carbono",
                 bg=COR_PRIMARIA, fg="#c8e6c9", font=FONTE_SUBTIT).pack(
                 side="left", padx=4, pady=24)

    # --- barra conexão
    def _construir_barra_conexao(self):
        frame = ttk.Frame(self, padding=(12, 10))
        frame.pack(fill="x")

        self.var_host = tk.StringVar(value="localhost")
        self.var_port = tk.StringVar(value="5433")
        self.var_db   = tk.StringVar(value="CarbonTrack")
        self.var_user = tk.StringVar(value="rapazinhos")
        self.var_pass = tk.StringVar(value="1234")

        campos = [
            ("Host", self.var_host, 12),
            ("Porta", self.var_port, 6),
            ("Banco", self.var_db, 14),
            ("Usuário", self.var_user, 12),
            ("Senha", self.var_pass, 12),
        ]
        for rotulo, var, largura in campos:
            ttk.Label(frame, text=rotulo, style="Bar.TLabel").pack(side="left", padx=(6, 2))
            entry = ttk.Entry(frame, textvariable=var, width=largura,
                              show="•" if rotulo == "Senha" else "")
            entry.pack(side="left")

        self.btn_conectar = ttk.Button(frame, text="Conectar",
                                       style="Accent.TButton", command=self.conectar)
        self.btn_conectar.pack(side="left", padx=(12, 4))
        self.btn_desconectar = ttk.Button(frame, text="Desconectar",
                                          command=self.desconectar, state="disabled")
        self.btn_desconectar.pack(side="left")

        self.lbl_conexao = ttk.Label(frame, text="● Desconectado",
                                     style="Bar.TLabel", foreground=COR_ERRO)
        self.lbl_conexao.pack(side="right", padx=8)

    # --- aba cadastro
    def _construir_aba_cadastro(self):
        sub = ttk.Notebook(self.aba_cadastro)
        sub.pack(fill="both", expand=True, padx=14, pady=14)

        self.frame_proj = ttk.Frame(sub, style="Card.TFrame", padding=20)
        self.frame_atv  = ttk.Frame(sub, style="Card.TFrame", padding=20)
        sub.add(self.frame_proj, text="  Novo Projeto  ")
        sub.add(self.frame_atv,  text="  Nova Atividade  ")

        self._form_projeto(self.frame_proj)
        self._form_atividade(self.frame_atv)

    # ---- formulário de Projeto 
    def _form_projeto(self, master):
        ttk.Label(master, text="Cadastro de Projeto de Mitigação",
                  style="Secao.TLabel").grid(row=0, column=0, columnspan=2,
                                             sticky="w", pady=(0, 4))
        ttk.Label(master, text="A Duração (em dias) é calculada automaticamente "
                  "a partir das datas (N10/N11).").grid(
                  row=1, column=0, columnspan=2, sticky="w", pady=(0, 14))

        self.p_num   = tk.StringVar()
        self.p_nome  = tk.StringVar()
        self.p_ini   = tk.StringVar()
        self.p_fim   = tk.StringVar()
        self.p_metod = tk.StringVar()

        linhas = [
            ("Nº Licença Ambiental *", self.p_num,   "ex.: LA-2025-010"),
            ("Nome do Projeto *",      self.p_nome,  "ex.: Recuperação de Nascentes"),
            ("Data de Início *",       self.p_ini,   "ex.: 20250101",  DateEntry),
            ("Data de Fim",            self.p_fim,   "opcional",       DateEntry),
            ("Metodologia Aplicada",   self.p_metod, "opcional"),
        ]
        self._grade_campos(master, linhas, linha_inicial=2)

        ttk.Button(master, text="Cadastrar Projeto", style="Accent.TButton",
                   command=self.cadastrar_projeto).grid(
                   row=2 + len(linhas), column=1, sticky="e", pady=(18, 0))
        ttk.Button(master, text="Limpar", command=lambda: self._limpar(
                   [self.p_num, self.p_nome, self.p_ini, self.p_fim, self.p_metod])
                   ).grid(row=2 + len(linhas), column=0, sticky="w", pady=(18, 0))

    # ---- formulário de Atividade 
    def _form_atividade(self, master):
        ttk.Label(master, text="Cadastro de Atividade de Campo",
                  style="Secao.TLabel").grid(row=0, column=0, columnspan=2,
                                             sticky="w", pady=(0, 4))
        ttk.Label(master, text="O Originador é obrigatório; Projeto e Auditor são opcionais.").grid(
                  row=1, column=0, columnspan=2, sticky="w", pady=(0, 14))

        self.a_cod    = tk.StringVar()
        self.a_orig   = tk.StringVar()
        self.a_proj   = tk.StringVar()
        self.a_aud    = tk.StringVar()
        self.a_desc   = tk.StringVar()
        self.a_custo  = tk.StringVar()
        self.a_ini    = tk.StringVar()
        self.a_fim    = tk.StringVar()
        self.a_cred   = tk.StringVar()
        self._aud_map = {}

        r = 2
        ttk.Label(master, text="Código Ordem de Serviço *").grid(row=r, column=0, sticky="w", pady=5)
        ttk.Entry(master, textvariable=self.a_cod, width=42).grid(row=r, column=1, sticky="w"); r += 1

        ttk.Label(master, text="Originador * (CNPJ)").grid(row=r, column=0, sticky="w", pady=5)
        self.cb_orig = ttk.Combobox(master, textvariable=self.a_orig, width=40, state="readonly")
        self.cb_orig.grid(row=r, column=1, sticky="w"); r += 1

        ttk.Label(master, text="Projeto (opcional)").grid(row=r, column=0, sticky="w", pady=5)
        self.cb_proj = ttk.Combobox(master, textvariable=self.a_proj, width=40, state="readonly")
        self.cb_proj.grid(row=r, column=1, sticky="w"); r += 1

        ttk.Label(master, text="Auditor (opcional)").grid(row=r, column=0, sticky="w", pady=5)
        self.cb_aud = ttk.Combobox(master, textvariable=self.a_aud, width=40, state="readonly")
        self.cb_aud.grid(row=r, column=1, sticky="w"); r += 1

        for rotulo, var, cls in [
            ("Descrição da Atividade",  self.a_desc,  ttk.Entry),
            ("Custo Operacional (R$)",  self.a_custo, DecimalEntry),
            ("Data de Início *",        self.a_ini,   DateEntry),
            ("Data de Fim",             self.a_fim,   DateEntry),
            ("Crédito Estimado (tCO₂e)", self.a_cred, DecimalEntry),
        ]:
            ttk.Label(master, text=rotulo).grid(row=r, column=0, sticky="w", pady=5)
            cls(master, textvariable=var, width=42).grid(row=r, column=1, sticky="w")
            r += 1

        ttk.Button(master, text="Atualizar listas", command=self._carregar_combos).grid(
            row=r, column=0, sticky="w", pady=(18, 0))
        ttk.Button(master, text="Cadastrar Atividade", style="Accent.TButton",
                   command=self.cadastrar_atividade).grid(
                   row=r, column=1, sticky="e", pady=(18, 0))

    def _grade_campos(self, master, linhas, linha_inicial):
        for i, item in enumerate(linhas):
            rotulo, var, dica = item[0], item[1], item[2]
            cls = item[3] if len(item) > 3 else ttk.Entry
            r = linha_inicial + i
            ttk.Label(master, text=rotulo).grid(row=r, column=0, sticky="w", pady=5)
            entry = cls(master, textvariable=var, width=42)
            entry.grid(row=r, column=1, sticky="w")
            if dica:
                ttk.Label(master, text=dica, foreground="#888").grid(
                    row=r, column=2, sticky="w", padx=8)

    # --- aba consulta
    def _construir_aba_consulta(self):
        topo = ttk.Frame(self.aba_consulta, style="Card.TFrame", padding=(16, 16, 16, 6))
        topo.pack(fill="x")

        ttk.Label(topo, text="Selecione a consulta:", style="Secao.TLabel").grid(
            row=0, column=0, sticky="w")
        self.var_consulta = tk.StringVar(value=list(CONSULTAS.keys())[0])
        self.cb_consulta = ttk.Combobox(topo, textvariable=self.var_consulta,
                                        values=list(CONSULTAS.keys()),
                                        state="readonly", width=55)
        self.cb_consulta.grid(row=0, column=1, sticky="w", padx=10)
        self.cb_consulta.bind("<<ComboboxSelected>>", lambda e: self._atualizar_params())

        self.lbl_desc = ttk.Label(topo, text="", foreground="#555", wraplength=900)
        self.lbl_desc.grid(row=1, column=0, columnspan=3, sticky="w", pady=(8, 8))

        # Área dinâmica de parâmetros
        self.frame_params = ttk.Frame(topo, style="Card.TFrame")
        self.frame_params.grid(row=2, column=0, columnspan=3, sticky="w")
        self.param_vars = []  # lista de (StringVar) na ordem dos %s

        ttk.Button(topo, text="Executar Consulta", style="Accent.TButton",
                   command=self.executar_consulta).grid(
                   row=3, column=0, sticky="w", pady=(12, 4))
        self.lbl_resultado = ttk.Label(topo, text="", foreground=COR_PRIMARIA)
        self.lbl_resultado.grid(row=3, column=1, sticky="w", pady=(12, 4))

        # Tabela de resultados (Treeview com rolagem)
        corpo = ttk.Frame(self.aba_consulta, style="Card.TFrame", padding=(16, 0, 16, 16))
        corpo.pack(fill="both", expand=True)
        self.tree = ttk.Treeview(corpo, show="headings")
        vsb = ttk.Scrollbar(corpo, orient="vertical", command=self.tree.yview)
        hsb = ttk.Scrollbar(corpo, orient="horizontal", command=self.tree.xview)
        self.tree.configure(yscrollcommand=vsb.set, xscrollcommand=hsb.set)
        self.tree.grid(row=0, column=0, sticky="nsew")
        vsb.grid(row=0, column=1, sticky="ns")
        hsb.grid(row=1, column=0, sticky="ew")
        corpo.rowconfigure(0, weight=1)
        corpo.columnconfigure(0, weight=1)

        self._atualizar_params()

    def _atualizar_params(self):
        for w in self.frame_params.winfo_children():
            w.destroy()
        self.param_vars = []
        info = CONSULTAS[self.var_consulta.get()]
        self.lbl_desc.config(text=info["descricao"])
        if not info["params"]:
            ttk.Label(self.frame_params, text="(esta consulta não exige parâmetros)",
                      foreground="#888").pack(side="left")
            return
        for rotulo, padrao in info["params"]:
            ttk.Label(self.frame_params, text=rotulo + ":").pack(side="left", padx=(0, 6))
            var = tk.StringVar(value=padrao)
            ttk.Entry(self.frame_params, textvariable=var, width=28).pack(
                side="left", padx=(0, 16))
            self.param_vars.append(var)

    # --- barra status
    def _construir_barra_status(self):
        self.status = tk.Label(self, text="Pronto.", bg="#e8eee8", fg=COR_TEXTO,
                               anchor="w", font=("Segoe UI", 9), padx=10)
        self.status.pack(fill="x", side="bottom")

    def _set_status(self, texto, erro=False):
        self.status.config(text=texto, fg=COR_ERRO if erro else COR_TEXTO)

    # === conexão ao banco
    def _avisar_sem_driver(self):
        messagebox.showwarning(
            "Driver ausente",
            "A biblioteca 'psycopg2' não está instalada.\n\n"
            "Instale com:\n    pip install psycopg2-binary\n\n"
            "A interface abre normalmente, mas conexão e consultas exigem o driver.")

    def conectar(self):
        if psycopg2 is None:
            self._avisar_sem_driver()
            return
        try:
            self.conn = psycopg2.connect(
                host=self.var_host.get().strip(),
                port=self.var_port.get().strip(),
                dbname=self.var_db.get().strip(),
                user=self.var_user.get().strip(),
                password=self.var_pass.get(),
                connect_timeout=5,
            )
            self.conn.autocommit = False
            self.lbl_conexao.config(text="● Conectado", foreground=COR_OK)
            self.btn_conectar.config(state="disabled")
            self.btn_desconectar.config(state="normal")
            self._set_status(f"Conectado ao banco '{self.var_db.get()}' em "
                             f"{self.var_host.get()}:{self.var_port.get()}.")
            self._carregar_combos()
        except Exception as exc:  # psycopg2.OperationalError etc.
            self.conn = None
            messagebox.showerror("Falha na conexão",
                                 f"Não foi possível conectar ao PostgreSQL:\n\n{exc}")
            self._set_status("Falha ao conectar.", erro=True)

    def desconectar(self):
        if self.conn is not None:
            try:
                self.conn.close()
            except Exception:
                pass
        self.conn = None
        self.lbl_conexao.config(text="● Desconectado", foreground=COR_ERRO)
        self.btn_conectar.config(state="normal")
        self.btn_desconectar.config(state="disabled")
        self._set_status("Desconectado.")

    def _exige_conexao(self):
        if self.conn is None:
            messagebox.showwarning("Sem conexão",
                                   "Conecte-se ao banco de dados primeiro.")
            return False
        return True

    def _carregar_combos(self):
        """Carrega Originadores e Projetos para os comboboxes da aba Atividade."""
        if self.conn is None:
            return
        try:
            with self.conn.cursor() as cur:
                cur.execute("""
                    SELECT o.CNPJ, pj.Nome_Fantasia
                    FROM ORIGINADOR o JOIN PESSOA_JURIDICA pj ON o.CNPJ = pj.CNPJ
                    ORDER BY pj.Nome_Fantasia
                """)
                self._orig_map = {f"{nome} — {cnpj}": cnpj for cnpj, nome in cur.fetchall()}
                cur.execute("""
                    SELECT Num_Licenca_Ambiental, Nome_Projeto
                    FROM PROJETO ORDER BY Nome_Projeto
                """)
                self._proj_map = {f"{nome} — {num}": num for num, nome in cur.fetchall()}
                cur.execute("""
                    SELECT a.CNPJ, pj.Nome_Fantasia
                    FROM AUDITOR a JOIN PESSOA_JURIDICA pj ON a.CNPJ = pj.CNPJ
                    ORDER BY pj.Nome_Fantasia
                """)
                self._aud_map = {f"{nome} — {cnpj}": cnpj for cnpj, nome in cur.fetchall()}
            self.conn.rollback()  # encerra a transação de leitura
            self.cb_orig["values"] = list(self._orig_map.keys())
            self.cb_proj["values"] = ["(nenhum)"] + list(self._proj_map.keys())
            self.cb_aud["values"]  = ["(nenhum)"] + list(self._aud_map.keys())
            self._set_status("Listas de Originadores, Projetos e Auditores atualizadas.")
        except Exception as exc:
            self.conn.rollback()
            self._set_status(f"Erro ao carregar listas: {exc}", erro=True)

    # === validações comuns
    @staticmethod
    def _parse_data(texto, obrigatorio, nome_campo):
        texto = (texto or "").strip()
        if not texto:
            if obrigatorio:
                raise ValueError(f"O campo '{nome_campo}' é obrigatório.")
            return None
        try:
            return datetime.strptime(texto, "%Y-%m-%d").date()
        except ValueError:
            raise ValueError(f"'{nome_campo}' deve estar no formato AAAA-MM-DD.")

    @staticmethod
    def _parse_decimal(texto, nome_campo):
        texto = (texto or "").strip().replace(",", ".")
        if not texto:
            return None
        try:
            return Decimal(texto)
        except InvalidOperation:
            raise ValueError(f"'{nome_campo}' deve ser um número válido.")

    def _tratar_erro_banco(self, exc):
        """Converte erros do psycopg2 em mensagens claras ao usuário."""
        self.conn.rollback()
        if pg_errors is not None:
            if isinstance(exc, pg_errors.UniqueViolation):
                msg = "Registro duplicado: já existe um item com essa chave primária."
            elif isinstance(exc, pg_errors.ForeignKeyViolation):
                msg = "Referência inválida: a chave estrangeira informada não existe."
            elif isinstance(exc, pg_errors.CheckViolation):
                msg = ("Violação de restrição (CHECK): algum valor fere as regras do "
                       "banco (domínio, formato ou datas).")
            elif isinstance(exc, pg_errors.NotNullViolation):
                msg = "Campo obrigatório ausente: um valor NOT NULL ficou vazio."
            else:
                msg = str(exc)
        else:
            msg = str(exc)
        messagebox.showerror("Erro no banco de dados", msg)
        self._set_status("Operação não concluída (erro no banco).", erro=True)

    # === cadastro: projeto
    def cadastrar_projeto(self):
        if not self._exige_conexao():
            return
        try:
            num   = self.p_num.get().strip()
            nome  = self.p_nome.get().strip()
            metod = self.p_metod.get().strip() or None
            if not num or not nome:
                raise ValueError("Nº Licença Ambiental e Nome do Projeto são obrigatórios.")
            d_ini = self._parse_data(self.p_ini.get(), True, "Data de Início")
            d_fim = self._parse_data(self.p_fim.get(), False, "Data de Fim")
            if d_fim is not None and d_fim < d_ini:
                raise ValueError("A Data de Fim não pode ser anterior à Data de Início (N10).")
            duracao = (d_fim - d_ini).days if d_fim is not None else None  # N11
        except ValueError as ve:
            messagebox.showwarning("Dados inválidos", str(ve))
            return

        try:
            with self.conn.cursor() as cur:
                cur.execute("""
                    INSERT INTO PROJETO
                        (Num_Licenca_Ambiental, Nome_Projeto, Data_Inicio,
                         Data_Fim, Duracao, Metodologia_Aplicada)
                    VALUES (%s, %s, %s, %s, %s, %s)
                """, (num, nome, d_ini, d_fim, duracao, metod))
            self.conn.commit()
            messagebox.showinfo("Sucesso",
                                f"Projeto '{nome}' cadastrado com sucesso.\n"
                                f"Duração calculada: "
                                f"{duracao if duracao is not None else '—'} dias.")
            self._set_status(f"Projeto {num} inserido.")
            self._limpar([self.p_num, self.p_nome, self.p_ini, self.p_fim, self.p_metod])
            self._carregar_combos()
        except Exception as exc:
            self._tratar_erro_banco(exc)

    # ===================================================== cadastro: atividade
    def cadastrar_atividade(self):
        if not self._exige_conexao():
            return
        try:
            cod  = self.a_cod.get().strip()
            if not cod:
                raise ValueError("O Código da Ordem de Serviço é obrigatório.")
            sel_orig = self.a_orig.get().strip()
            if not sel_orig:
                raise ValueError("Selecione um Originador.")
            cnpj_orig = self._orig_map.get(sel_orig)
            if cnpj_orig is None:
                raise ValueError("Originador inválido. Atualize a lista e selecione novamente.")

            sel_proj = self.a_proj.get().strip()
            num_proj = None
            if sel_proj and sel_proj != "(nenhum)":
                num_proj = self._proj_map.get(sel_proj)
                if num_proj is None:
                    raise ValueError("Projeto inválido. Atualize a lista e selecione novamente.")

            sel_aud = self.a_aud.get().strip()
            cnpj_aud = None
            if sel_aud and sel_aud != "(nenhum)":
                cnpj_aud = self._aud_map.get(sel_aud)
                if cnpj_aud is None:
                    raise ValueError("Auditor inválido. Atualize a lista e selecione novamente.")

            desc  = self.a_desc.get().strip() or None
            custo = self._parse_decimal(self.a_custo.get(), "Custo Operacional")
            cred  = self._parse_decimal(self.a_cred.get(), "Crédito Estimado")
            d_ini = self._parse_data(self.a_ini.get(), True, "Data de Início")
            d_fim = self._parse_data(self.a_fim.get(), False, "Data de Fim")
            if d_fim is not None and d_fim < d_ini:
                raise ValueError("A Data de Fim não pode ser anterior à Data de Início (N10).")
            duracao = (d_fim - d_ini).days if d_fim is not None else None  # N11
        except ValueError as ve:
            messagebox.showwarning("Dados inválidos", str(ve))
            return

        try:
            with self.conn.cursor() as cur:
                cur.execute("""
                    INSERT INTO ATIVIDADE
                        (Codigo_Ordem_Servico, Originador, Projeto, Auditor,
                         Descricao_Atividade, Custo_Operacional, Data_Inicio,
                         Data_Fim, Duracao, Credito_Estimado)
                    VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s)
                """, (cod, cnpj_orig, num_proj, cnpj_aud, desc, custo, d_ini, d_fim, duracao, cred))
            self.conn.commit()
            messagebox.showinfo("Sucesso",
                                f"Atividade '{cod}' cadastrada com sucesso.\n"
                                f"Duração calculada: "
                                f"{duracao if duracao is not None else '—'} dias.")
            self._set_status(f"Atividade {cod} inserida.")
            self._limpar([self.a_cod, self.a_desc, self.a_custo, self.a_ini,
                          self.a_fim, self.a_cred])
            self.a_orig.set("")
            self.a_proj.set("")
            self.a_aud.set("")
        except Exception as exc:
            self._tratar_erro_banco(exc)

    # === execução consulta
    def executar_consulta(self):
        if not self._exige_conexao():
            return
        info = CONSULTAS[self.var_consulta.get()]
        valores = []
        for var, (rotulo, _padrao) in zip(self.param_vars, info["params"]):
            v = var.get().strip()
            if not v:
                messagebox.showwarning("Parâmetro ausente",
                                       f"Informe o valor de '{rotulo}'.")
                return
            valores.append(v)

        try:
            with self.conn.cursor() as cur:
                cur.execute(info["sql"], tuple(valores))  # parâmetros via %s
                colunas = [d[0] for d in cur.description]
                linhas = cur.fetchall()
            self.conn.rollback()  # encerra a transação de leitura
            self._preencher_tabela(colunas, linhas)
            self.lbl_resultado.config(text=f"{len(linhas)} registro(s) encontrado(s).")
            self._set_status(f"Consulta executada: {len(linhas)} linha(s).")
            if not linhas:
                messagebox.showinfo("Sem resultados",
                                    "A consulta não retornou nenhum registro "
                                    "para os parâmetros informados.")
        except Exception as exc:
            self.conn.rollback()
            messagebox.showerror("Erro na consulta", str(exc))
            self._set_status("Falha ao executar a consulta.", erro=True)

    def _preencher_tabela(self, colunas, linhas):
        self.tree.delete(*self.tree.get_children())
        self.tree["columns"] = colunas
        for col in colunas:
            self.tree.heading(col, text=col)
            self.tree.column(col, width=max(110, min(260, len(col) * 11)), anchor="w")
        for i, linha in enumerate(linhas):
            valores = ["" if v is None else str(v) for v in linha]
            tag = "par" if i % 2 == 0 else "impar"
            self.tree.insert("", "end", values=valores, tags=(tag,))
        self.tree.tag_configure("impar", background="#f0f5f0")
        self.tree.tag_configure("par", background="white")

    # --- utilidade
    @staticmethod
    def _limpar(variaveis):
        for v in variaveis:
            v.set("")

    def destroy(self):
        if self.conn is not None:
            try:
                self.conn.close()
            except Exception:
                pass
        super().destroy()


if __name__ == "__main__":
    app = CarbonTrackApp()
    app.mainloop()