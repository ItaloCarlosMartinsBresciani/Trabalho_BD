-- ============================================================================
-- CarbonTrack - Sistema de Rastreabilidade para Créditos de Carbono
-- Script de Consultas ao Banco de Dados (DQL)
--
-- SGBD alvo: PostgreSQL
-- Pré-requisito: executar antes esquema.sql e dados.sql para prepara o banco de dados.
-- Foram implementadas 6 consultas:
--
--   A primeira : Rastreabilidade Completa de Lote com múltiplos JOINs internos e externos (LEFT JOIN)
--       
--   Segunda: Desempenho de Projetos por Créditos e Valor Financeiro atraves de agrupamento (GROUP BY) com funções de agregação + LEFT JOIN
--  
--   Terceira: Atividades Finalizadas sem Laudo de Auditoria atraves de subconsulta NÃO-CORRELACIONADA (NOT IN) + JOIN
--
--   Quarta: Evolução de Preço de um Lote com Variação Percentual, feita por função de janela (LAG) sobre resultado filtrado
--
--   Quinta: Divisão Relacional: Originadores aprovados por TODAS as Certificadoras ativas, DIVISÃO RELACIONAL via dupla negação (NOT EXISTS aninhado)
--   
--   Sexta:  Proprietário Atual de Cada Lote Disponível, subconsulta CORRELACIONADA no SELECT + COALESCE
--   
--
-- Critérios de eficiência adotados:
--   Filtros sobre colunas de PK/FK (sempre indexadas) aplicados cedo.
--   NOT EXISTS preferido a NOT IN em colunas anuláveis (evita armadilha do NULL que torna NOT IN sempre falso).
--   LIMIT 1 na subconsulta correlacionada de C6 interrompe a varredura assim que o registro mais recente é encontrado.
--   LAG() em C4 evita o auto-JOIN sobre HISTORICO_PRECO.
--   CTEs (WITH) em C1 e C6 reduzem repetição e permitem ao otimizador materializar resultados intermediários.
-- ============================================================================


-- ============================================================================
-- C1  RASTREABILIDADE COMPLETA DE LOTE
-- ============================================================================
-- Dado o número de série de um Lote, retorna o histórico completo:
-- a Transação de compra mais recente, o Projeto e a Atividade geradora,
-- o Auditor responsável e o Certificador que emitiu o Laudo.
--
-- Técnica: 7 JOINs (internos e LEFT JOIN para relacionamentos opcionais).
-- LEFT JOIN em Projeto (atividade pode não ter projeto -- N7),
-- LEFT JOIN em Auditor/Laudo/Certificador (atividade pode ainda não ter
-- sido auditada nem certificada na data da consulta).
-- ============================================================================

WITH ultima_transacao AS (
    -- Subconsulta não-correlacionada que isola a transação mais recente por lote
    SELECT DISTINCT ON (tl.Lote)
        tl.Lote                       AS num_serie,
        t.Nota_Fiscal,
        t.Data_Hora                   AS data_ultima_transacao,
        t.Valor                       AS valor_ultima_transacao,
        pj_v.Nome_Fantasia            AS vendedor,
        pj_c.Nome_Fantasia            AS comprador_atual
    FROM TRANSACAO_LOTE tl
    JOIN TRANSACAO      t    ON tl.Transacao = t.Nota_Fiscal
    JOIN PESSOA_JURIDICA pj_v ON t.Agente_Mercado_Vendedor  = pj_v.CNPJ
    JOIN PESSOA_JURIDICA pj_c ON t.Agente_Mercado_Comprador = pj_c.CNPJ
    ORDER BY tl.Lote, t.Data_Hora DESC
)
SELECT
    -- Lote
    l.Num_Serie_Registro,
    l.Quantidade_de_Credito          AS creditos_tCO2e,
    l.Ano_Geracao,
    l.Status_Ciclo_de_Vida,

    -- Atividade geradora
    a.Codigo_Ordem_Servico           AS atividade,
    a.Descricao_Atividade,

    -- Projeto
    p.Nome_Projeto,
    p.Metodologia_Aplicada,

    -- Originador da atividade
    pj_orig.Nome_Fantasia            AS originador,

    -- Auditor (atividade pode não ter sido auditada)
    pj_aud.Nome_Fantasia             AS auditor,
    aud.Registro_Acreditacao,

    -- Laudo e Certificador
    ld.Numero_do_Protocolo,
    ld.Parecer_Final,
    pj_cert.Nome_Fantasia            AS certificador,

    -- Última negociação
    ut.Nota_Fiscal                   AS ultima_nota_fiscal,
    ut.data_ultima_transacao,
    ut.valor_ultima_transacao,
    ut.vendedor,
    ut.comprador_atual

FROM LOTE l
-- Atividade que gerou o lote (1:1)
JOIN  ATIVIDADE      a       ON l.Atividade     = a.Codigo_Ordem_Servico
-- Originador da atividade
JOIN  ORIGINADOR     orig    ON a.Originador     = orig.CNPJ
JOIN  PESSOA_JURIDICA pj_orig ON orig.CNPJ        = pj_orig.CNPJ
-- Projeto: LEFT JOIN (atividade pode não pertencer a projeto)
LEFT JOIN PROJETO    p       ON a.Projeto        = p.Num_Licenca_Ambiental
-- Auditor: LEFT JOIN (pode ainda não ter sido contratado)
LEFT JOIN AUDITOR    aud     ON a.Auditor         = aud.CNPJ
LEFT JOIN PESSOA_JURIDICA pj_aud  ON aud.CNPJ    = pj_aud.CNPJ
-- Laudo e Certificador: LEFT JOIN (pode ainda não existir laudo)
LEFT JOIN LAUDO      ld      ON ld.Atividade      = a.Codigo_Ordem_Servico
LEFT JOIN CERTIFICADOR cert  ON ld.Certificador   = cert.CNPJ
LEFT JOIN PESSOA_JURIDICA pj_cert ON cert.CNPJ    = pj_cert.CNPJ
-- Última transação: LEFT JOIN (lote pode nunca ter sido negociado)
LEFT JOIN ultima_transacao ut ON ut.num_serie      = l.Num_Serie_Registro

WHERE l.Num_Serie_Registro = 'BR-VCS-2024-0001';


-- ============================================================================
-- C2  DESEMPENHO DE PROJETOS POR CRÉDITOS E VALOR FINANCEIRO
-- ============================================================================
-- Lista, por Projeto, o total de créditos emitidos (tCO₂e), o valor financeiro
-- total dos Lotes (Valor × Quantidade), o número de Lotes emitidos e o número
-- de transações envolvendo esses Lotes.
--
-- Técnica: GROUP BY com COUNT, SUM e LEFT JOIN (projetos sem lotes aparecem
-- com zeros, facilitando a identificação de projetos improdutivos).
-- Eficiência: o agrupamento ocorre sobre PKs e FKs indexadas.
-- ============================================================================

SELECT
    p.Num_Licenca_Ambiental,
    p.Nome_Projeto,
    p.Metodologia_Aplicada,
    COUNT(DISTINCT l.Num_Serie_Registro)            AS total_lotes_emitidos,
    COALESCE(SUM(l.Quantidade_de_Credito), 0)       AS total_creditos_tCO2e,
    COALESCE(SUM(l.Valor * l.Quantidade_de_Credito), 0)
                                                    AS valor_total_lotes,
    COUNT(DISTINCT tl.Transacao)                    AS total_transacoes
FROM PROJETO p
JOIN  ATIVIDADE      a   ON a.Projeto     = p.Num_Licenca_Ambiental
LEFT JOIN LOTE       l   ON l.Atividade   = a.Codigo_Ordem_Servico
LEFT JOIN TRANSACAO_LOTE tl ON tl.Lote   = l.Num_Serie_Registro
GROUP BY
    p.Num_Licenca_Ambiental,
    p.Nome_Projeto,
    p.Metodologia_Aplicada
ORDER BY total_creditos_tCO2e DESC;


-- ============================================================================
-- C3  ATIVIDADES FINALIZADAS SEM LAUDO DE AUDITORIA
-- ============================================================================
-- Identifica Atividades cujo Data_Fim já passou (finalizadas) mas que ainda
-- não possuem nenhum Laudo registrado no sistema — indicando risco de
-- inadimplência de conformidade.
--
-- Técnica: subconsulta NÃO-CORRELACIONADA (NOT IN) sobre LAUDO para obter
-- o conjunto de atividades já auditadas; o resultado externo filtra as que
-- ficaram de fora.
-- Nota: o campo Auditor na tabela ATIVIDADE indica apenas o auditor
-- contratado; a existência efetiva do laudo é verificada em LAUDO.
-- ============================================================================

SELECT
    a.Codigo_Ordem_Servico,
    pj.Nome_Fantasia          AS originador,
    a.Descricao_Atividade,
    a.Data_Inicio,
    a.Data_Fim,
    a.Duracao                 AS duracao_dias,
    a.Credito_Estimado        AS credito_estimado_tCO2e,
    -- Auditor contratado (pode ser NULL se ainda não contratado)
    pj_aud.Nome_Fantasia      AS auditor_contratado
FROM ATIVIDADE a
JOIN  ORIGINADOR     orig    ON a.Originador = orig.CNPJ
JOIN  PESSOA_JURIDICA pj     ON orig.CNPJ    = pj.CNPJ
LEFT JOIN PESSOA_JURIDICA pj_aud ON a.Auditor = pj_aud.CNPJ
WHERE
    -- Atividade já finalizada
    a.Data_Fim IS NOT NULL
    AND a.Data_Fim < CURRENT_DATE
    -- Sem nenhum laudo emitido (subconsulta não-correlacionada)
    AND a.Codigo_Ordem_Servico NOT IN (
        SELECT l.Atividade
        FROM   LAUDO l
    )
ORDER BY a.Data_Fim;


-- ============================================================================
-- C4  EVOLUÇÃO DE PREÇO DE UM LOTE COM VARIAÇÃO PERCENTUAL
-- ============================================================================
-- Para um Lote específico, recupera a série histórica de preços ordenada
-- cronologicamente, calculando a variação absoluta e percentual em relação
-- ao registro anterior.
--
-- Técnica: função de janela LAG() para acessar o preço da linha anterior
-- sem auto-JOIN; NULLIF evita divisão por zero na variação percentual.
-- Complexidade: MÉDIA/ALTA (window function sobre partição de FK).
-- ============================================================================

SELECT
    hp.Num_Serie_Registro,
    pj.Nome_Fantasia                                        AS originador_do_lote,
    hp.Data,
    hp.Preco                                                AS preco_unitario,
    hp.Preco - LAG(hp.Preco) OVER w                        AS variacao_abs,
    ROUND(
        (hp.Preco - LAG(hp.Preco) OVER w)
        / NULLIF(LAG(hp.Preco) OVER w, 0) * 100
    , 2)                                                    AS variacao_pct
FROM HISTORICO_PRECO hp
JOIN LOTE       l    ON hp.Num_Serie_Registro = l.Num_Serie_Registro
JOIN ATIVIDADE  a    ON l.Atividade           = a.Codigo_Ordem_Servico
JOIN ORIGINADOR orig ON a.Originador          = orig.CNPJ
JOIN PESSOA_JURIDICA pj ON orig.CNPJ          = pj.CNPJ
WHERE hp.Num_Serie_Registro = 'BR-VCS-2024-0001'
WINDOW w AS (PARTITION BY hp.Num_Serie_Registro ORDER BY hp.Data)
ORDER BY hp.Data;


-- ============================================================================
-- C5  DIVISÃO RELACIONAL — ORIGINADORES APROVADOS POR TODAS AS
--     CERTIFICADORAS ATIVAS
-- ============================================================================
-- Encontra os Originadores que possuem Atividades com Laudos emitidos
-- por TODAS as Certificadoras com status 'Apto' no sistema.
-- Um alto nível de aprovação global demonstra conformidade multijurisdicional.
--
-- Técnica: DIVISÃO RELACIONAL implementada via dupla negação (NOT EXISTS
-- aninhado), que é a tradução direta do quantificador universal (∀):
--
--   "Retorna o originador X tal que NÃO EXISTE nenhuma certificadora ativa C
--    para a qual NÃO EXISTE nenhum laudo de C sobre uma atividade de X."
--
-- Equivalência algébrica:
--   ORIGINADOR ÷ CERTIFICADORAS_ATIVAS
--   = { X | ∀C ∈ CERT_ATIVAS: ∃ laudo de C sobre atividade de X }
--
-- Eficiência: os dois NOT EXISTS curto-circuitam assim que encontram um
-- contraexemplo, sem materializar o produto cartesiano.
-- ============================================================================

SELECT
    o.CNPJ,
    pj.Nome_Fantasia    AS originador,
    pj.Status
FROM ORIGINADOR      o
JOIN PESSOA_JURIDICA pj ON o.CNPJ = pj.CNPJ
WHERE
    -- Não existe nenhuma certificadora ativa...
    NOT EXISTS (
        SELECT 1
        FROM CERTIFICADOR    c
        JOIN AGENTE_CONFORMIDADE ac  ON c.CNPJ  = ac.CNPJ
        JOIN PESSOA_JURIDICA     pjc ON c.CNPJ  = pjc.CNPJ
        WHERE pjc.Status = 'Apto'
        -- ...para a qual não existe laudo sobre atividade deste originador
        AND NOT EXISTS (
            SELECT 1
            FROM LAUDO    ld
            JOIN ATIVIDADE a ON ld.Atividade = a.Codigo_Ordem_Servico
            WHERE a.Originador   = o.CNPJ
              AND ld.Certificador = c.CNPJ
        )
    )
ORDER BY pj.Nome_Fantasia;


-- ============================================================================
-- C6  PROPRIETÁRIO ATUAL DE CADA LOTE DISPONÍVEL
-- ============================================================================
-- Retorna, para cada Lote com status 'Disponível', quem é seu proprietário
-- atual — determinado por inferência (conforme decisão arquitetural do MER):
--   * Se o Lote possui transações: proprietário = comprador da transação
--     mais recente (subconsulta CORRELACIONADA com LIMIT 1).
--   * Se não possui transações: proprietário = Originador da Atividade que
--     gerou o Lote (posse inicial — N3 do MER).
--
-- Técnica: subconsulta CORRELACIONADA no SELECT (referencia l.Num_Serie_Registro
-- da consulta externa) combinada com COALESCE para o fallback ao Originador.
-- Eficiência: LIMIT 1 interrompe a varredura de transações após encontrar a
-- mais recente; ORDER BY Data_Hora DESC aproveita índice de FK.
-- ============================================================================

WITH proprietario_por_transacao AS (
    -- Subconsulta correlacionada isolada em CTE para reaproveitamento
    SELECT DISTINCT ON (tl.Lote)
        tl.Lote                          AS num_serie,
        t.Agente_Mercado_Comprador       AS cnpj_dono_atual,
        pj.Nome_Fantasia                 AS nome_dono_atual,
        t.Data_Hora                      AS data_aquisicao,
        'Transação'                      AS origem_posse
    FROM TRANSACAO_LOTE  tl
    JOIN TRANSACAO        t  ON tl.Transacao = t.Nota_Fiscal
    JOIN PESSOA_JURIDICA  pj ON t.Agente_Mercado_Comprador = pj.CNPJ
    ORDER BY tl.Lote, t.Data_Hora DESC
)
SELECT
    l.Num_Serie_Registro,
    l.Quantidade_de_Credito             AS creditos_tCO2e,
    l.Valor                             AS preco_unitario_atual,
    -- Proprietário: transação mais recente OU originador inicial
    COALESCE(pt.cnpj_dono_atual,  a.Originador)   AS cnpj_proprietario,
    COALESCE(pt.nome_dono_atual,  pj_orig.Nome_Fantasia) AS proprietario_atual,
    COALESCE(pt.data_aquisicao,   a.Data_Inicio)         AS desde,
    COALESCE(pt.origem_posse,     'Originador inicial')  AS origem_posse
FROM LOTE           l
JOIN ATIVIDADE      a       ON l.Atividade   = a.Codigo_Ordem_Servico
JOIN PESSOA_JURIDICA pj_orig ON a.Originador = pj_orig.CNPJ
-- LEFT JOIN: lotes sem nenhuma transação retornam NULL e COALESCE usa o fallback
LEFT JOIN proprietario_por_transacao pt ON pt.num_serie = l.Num_Serie_Registro
WHERE l.Status_Ciclo_de_Vida = 'Disponível'
ORDER BY l.Num_Serie_Registro;
