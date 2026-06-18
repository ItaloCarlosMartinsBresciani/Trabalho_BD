-- ============================================================================
-- CarbonTrack - Sistema de Rastreabilidade para Créditos de Carbono
-- Esquema de criação das tabelas (DDL)
--
-- SGBD alvo: PostgreSQL
-- Gerado a partir do Modelo Relacional V4 (nossos_relatorios/2_entrega)
-- e das Justificativas (J1-J10) e Notas (N1-N11) descritas em relatorio.tex
--
-- A ordem de criação respeita as dependências de chave estrangeira.
-- Restrições que NÃO podem ser garantidas apenas pelo DDL (totalidade/disjunção
-- de especializações, sincronização de identidade, recálculo de atributo
-- derivado etc.) estão indicadas em comentários e devem ser tratadas via
-- triggers ou na camada de aplicação, conforme as notas N3, N5, N8, N9 e N11.
--
-- VALIDAÇÃO DE FORMATO (REGEX): campos com formato fixo (CNPJ, CEP, UF e URL)
-- são validados por cláusulas CHECK usando o operador "~" do PostgreSQL.
--   CNPJ  → "NN.NNN.NNN/NNNN-NN"
--   CEP   → "NNNNN-NNN"
--   UF    → uma das 27 siglas oficiais (maiúsculas)
--   URL   → começa com "http://" ou "https://" sem espaços
-- ============================================================================

-- Remoção em ordem inversa de dependência (facilita recriação durante o desenvolvimento)
DROP TABLE IF EXISTS TRANSACAO_LOTE      CASCADE;
DROP TABLE IF EXISTS TRANSACAO           CASCADE;
DROP TABLE IF EXISTS LAUDO               CASCADE;
DROP TABLE IF EXISTS HISTORICO_PRECO     CASCADE;
DROP TABLE IF EXISTS LOTE                CASCADE;
DROP TABLE IF EXISTS ATIVIDADE           CASCADE;
DROP TABLE IF EXISTS PROJETO             CASCADE;
DROP TABLE IF EXISTS CERTIFICADOR        CASCADE;
DROP TABLE IF EXISTS AUDITOR             CASCADE;
DROP TABLE IF EXISTS AGENTE_CONFORMIDADE CASCADE;
DROP TABLE IF EXISTS TIPO_AGENTE_MERCADO CASCADE;
DROP TABLE IF EXISTS COMPRADOR           CASCADE;
DROP TABLE IF EXISTS ORIGINADOR          CASCADE;
DROP TABLE IF EXISTS AGENTE_MERCADO      CASCADE;
DROP TABLE IF EXISTS ENDERECO            CASCADE;
DROP TABLE IF EXISTS PESSOA_JURIDICA     CASCADE;


-- ============================================================================
-- PESSOA_JURIDICA (superclasse) -- J1
-- ============================================================================
CREATE TABLE PESSOA_JURIDICA (
    CNPJ          VARCHAR(18)  NOT NULL,
    Nome_Fantasia VARCHAR(255) NOT NULL,
    Razao_Social  VARCHAR(255) NOT NULL,
    Status        VARCHAR(10)  NOT NULL,
    Funcao        VARCHAR(25)  NOT NULL,

    CONSTRAINT pk_pessoa_juridica PRIMARY KEY (CNPJ),
    CONSTRAINT ck_pj_cnpj         CHECK (CNPJ   ~ '^[0-9]{2}\.[0-9]{3}\.[0-9]{3}/[0-9]{4}-[0-9]{2}$'),
    -- N2: domínio restrito de Status
    CONSTRAINT ck_pj_status       CHECK (Status IN ('Apto', 'Inapto')),
    -- Discriminador da especialização (Total e Disjunta)
    CONSTRAINT ck_funcao          CHECK (UPPER(Funcao) IN ('AGENTE DE MERCADO', 'AGENTE DE CONFORMIDADE'))
);

-- ============================================================================
-- ENDERECO -- J2
-- Atributo composto e multivalorado: relação própria com PK composta
-- (CNPJ, CEP, Estado, Rua), permitindo sede + filiais sem duplicação.
-- N1: ON DELETE CASCADE para evitar endereços órfãos.
-- ============================================================================
CREATE TABLE ENDERECO (
    CNPJ   VARCHAR(18)  NOT NULL,
    CEP    VARCHAR(9)   NOT NULL,
    Estado CHAR(2)      NOT NULL,
    Rua    VARCHAR(255) NOT NULL,

    CONSTRAINT pk_endereco   PRIMARY KEY (CNPJ, CEP, Estado, Rua),
    CONSTRAINT fk_endereco_pj FOREIGN KEY (CNPJ)
        REFERENCES PESSOA_JURIDICA (CNPJ) ON DELETE CASCADE,
    CONSTRAINT ck_end_cnpj   CHECK (CNPJ   ~ '^[0-9]{2}\.[0-9]{3}\.[0-9]{3}/[0-9]{4}-[0-9]{2}$'),
    CONSTRAINT ck_end_cep    CHECK (CEP    ~ '^[0-9]{5}-[0-9]{3}$'),
    CONSTRAINT ck_end_estado CHECK (Estado ~ '^(AC|AL|AP|AM|BA|CE|DF|ES|GO|MA|MT|MS|MG|PA|PB|PR|PE|PI|RJ|RN|RS|RO|RR|SC|SP|SE|TO)$')
);

-- ============================================================================
-- AGENTE_MERCADO (subclasse de Pessoa Jurídica / superclasse de mercado) -- J3
-- N1: CNPJ é FK para PESSOA_JURIDICA com ON DELETE CASCADE.
-- ============================================================================
CREATE TABLE AGENTE_MERCADO (
    CNPJ VARCHAR(18) NOT NULL,

    CONSTRAINT pk_agente_mercado    PRIMARY KEY (CNPJ),
    CONSTRAINT fk_agente_mercado_pj FOREIGN KEY (CNPJ)
        REFERENCES PESSOA_JURIDICA (CNPJ) ON DELETE CASCADE,
    CONSTRAINT ck_am_cnpj           CHECK (CNPJ ~ '^[0-9]{2}\.[0-9]{3}\.[0-9]{3}/[0-9]{4}-[0-9]{2}$')
);

-- ============================================================================
-- ORIGINADOR (subclasse de Agente de Mercado) -- J3
-- N4: ON DELETE CASCADE em relação a AGENTE_MERCADO.
-- ============================================================================
CREATE TABLE ORIGINADOR (
    CNPJ               VARCHAR(18)  NOT NULL,
    Setor_Atuacao      VARCHAR(100),
    Capacidade_Tecnica VARCHAR(255),

    CONSTRAINT pk_originador    PRIMARY KEY (CNPJ),
    CONSTRAINT fk_originador_am FOREIGN KEY (CNPJ)
        REFERENCES AGENTE_MERCADO (CNPJ) ON DELETE CASCADE,
    CONSTRAINT ck_orig_cnpj     CHECK (CNPJ ~ '^[0-9]{2}\.[0-9]{3}\.[0-9]{3}/[0-9]{4}-[0-9]{2}$')
);

-- ============================================================================
-- COMPRADOR (subclasse de Agente de Mercado) -- J3
-- ============================================================================
CREATE TABLE COMPRADOR (
    CNPJ             VARCHAR(18)  NOT NULL,
    Perfil_Comprador VARCHAR(100),

    CONSTRAINT pk_comprador    PRIMARY KEY (CNPJ),
    CONSTRAINT fk_comprador_am FOREIGN KEY (CNPJ)
        REFERENCES AGENTE_MERCADO (CNPJ) ON DELETE CASCADE,
    CONSTRAINT ck_comp_cnpj    CHECK (CNPJ ~ '^[0-9]{2}\.[0-9]{3}\.[0-9]{3}/[0-9]{4}-[0-9]{2}$')
);

-- ============================================================================
-- TIPO_AGENTE_MERCADO (tabela auxiliar de papéis sobrepostos) -- J3
-- N4: ON DELETE CASCADE.  N5: sincronização com ORIGINADOR/COMPRADOR via trigger/aplicação.
-- ============================================================================
CREATE TABLE TIPO_AGENTE_MERCADO (
    CNPJ VARCHAR(18) NOT NULL,
    Tipo VARCHAR(15) NOT NULL,

    CONSTRAINT pk_tipo_agente_mercado PRIMARY KEY (CNPJ, Tipo),
    CONSTRAINT fk_tipo_am             FOREIGN KEY (CNPJ)
        REFERENCES AGENTE_MERCADO (CNPJ) ON DELETE CASCADE,
    CONSTRAINT ck_tam_cnpj            CHECK (CNPJ ~ '^[0-9]{2}\.[0-9]{3}\.[0-9]{3}/[0-9]{4}-[0-9]{2}$'),
    CONSTRAINT ck_tam_tipo            CHECK (Tipo IN ('Originador', 'Comprador'))
);

-- ============================================================================
-- AGENTE_CONFORMIDADE (subclasse de Pessoa Jurídica) -- J8
-- N8: Atribuição com domínio restrito atua como discriminador disjunto.
-- ============================================================================
CREATE TABLE AGENTE_CONFORMIDADE (
    CNPJ       VARCHAR(18) NOT NULL,
    Atribuicao VARCHAR(15) NOT NULL,

    CONSTRAINT pk_agente_conformidade PRIMARY KEY (CNPJ),
    CONSTRAINT fk_agente_conf_pj      FOREIGN KEY (CNPJ)
        REFERENCES PESSOA_JURIDICA (CNPJ) ON DELETE CASCADE,
    CONSTRAINT ck_ac_cnpj             CHECK (CNPJ       ~ '^[0-9]{2}\.[0-9]{3}\.[0-9]{3}/[0-9]{4}-[0-9]{2}$'),
    CONSTRAINT ck_ac_atribuicao       CHECK (Atribuicao IN ('Auditor', 'Certificador'))
);

-- ============================================================================
-- AUDITOR (subclasse de Agente de Conformidade) -- J8
-- N8/N9: consistência com Atribuição e totalidade garantidas via trigger/aplicação.
-- ============================================================================
CREATE TABLE AUDITOR (
    CNPJ                      VARCHAR(18) NOT NULL,
    Registro_Acreditacao      VARCHAR(100),
    Data_Validade_Acreditacao DATE,

    CONSTRAINT pk_auditor    PRIMARY KEY (CNPJ),
    CONSTRAINT fk_auditor_ac FOREIGN KEY (CNPJ)
        REFERENCES AGENTE_CONFORMIDADE (CNPJ) ON DELETE CASCADE,
    CONSTRAINT ck_aud_cnpj   CHECK (CNPJ ~ '^[0-9]{2}\.[0-9]{3}\.[0-9]{3}/[0-9]{4}-[0-9]{2}$')
);

-- ============================================================================
-- CERTIFICADOR (subclasse de Agente de Conformidade) -- J8
-- ============================================================================
CREATE TABLE CERTIFICADOR (
    CNPJ                VARCHAR(18)  NOT NULL,
    Padrao_Certificacao VARCHAR(100),

    CONSTRAINT pk_certificador    PRIMARY KEY (CNPJ),
    CONSTRAINT fk_certificador_ac FOREIGN KEY (CNPJ)
        REFERENCES AGENTE_CONFORMIDADE (CNPJ) ON DELETE CASCADE,
    CONSTRAINT ck_cert_cnpj       CHECK (CNPJ ~ '^[0-9]{2}\.[0-9]{3}\.[0-9]{3}/[0-9]{4}-[0-9]{2}$')
);

-- ============================================================================
-- PROJETO
-- N10: Data_Fim >= Data_Inicio.  N11: Duracao mantida coerente via trigger/aplicação (J10).
-- ============================================================================
CREATE TABLE PROJETO (
    Num_Licenca_Ambiental VARCHAR(50)  NOT NULL,
    Nome_Projeto          VARCHAR(255) NOT NULL,
    Data_Inicio           DATE         NOT NULL,
    Data_Fim              DATE,
    Duracao               INTEGER,
    Metodologia_Aplicada  VARCHAR(255),

    CONSTRAINT pk_projeto      PRIMARY KEY (Num_Licenca_Ambiental),
    CONSTRAINT ck_projeto_datas CHECK (Data_Fim IS NULL OR Data_Fim >= Data_Inicio)
);

-- ============================================================================
-- ATIVIDADE -- J4, J5
-- Absorve por Chave Estrangeira os relacionamentos 1:N Realiza (Originador),
-- Contém (Projeto) e Audita (Auditor).
--   * Originador  -> NOT NULL, N6: ON DELETE RESTRICT (preserva rastreabilidade).
--   * Projeto     -> opcional (atividade pode não pertencer a um projeto).
--   * Auditor     -> N7: nasce NULL, preenchido por UPDATE na contratação.
-- N10: Data_Fim >= Data_Inicio.  N11: Duracao via trigger/aplicação (J10).
-- ============================================================================
CREATE TABLE ATIVIDADE (
    Codigo_Ordem_Servico VARCHAR(50)   NOT NULL,
    Originador           VARCHAR(18)   NOT NULL,
    Projeto              VARCHAR(50),
    Auditor              VARCHAR(18),
    Descricao_Atividade  TEXT,
    Custo_Operacional    NUMERIC(15,2),
    Data_Inicio          DATE          NOT NULL,
    Data_Fim             DATE,
    Duracao              INTEGER,
    Credito_Estimado     NUMERIC(15,2),

    CONSTRAINT pk_atividade            PRIMARY KEY (Codigo_Ordem_Servico),
    CONSTRAINT fk_atividade_originador FOREIGN KEY (Originador)
        REFERENCES ORIGINADOR (CNPJ) ON DELETE RESTRICT,
    CONSTRAINT fk_atividade_projeto    FOREIGN KEY (Projeto)
        REFERENCES PROJETO (Num_Licenca_Ambiental) ON DELETE SET NULL,
    CONSTRAINT fk_atividade_auditor    FOREIGN KEY (Auditor)
        REFERENCES AUDITOR (CNPJ) ON DELETE SET NULL,
    CONSTRAINT ck_atv_orig_cnpj        CHECK (Originador ~ '^[0-9]{2}\.[0-9]{3}\.[0-9]{3}/[0-9]{4}-[0-9]{2}$'),
    CONSTRAINT ck_atv_aud_cnpj         CHECK (Auditor IS NULL OR Auditor ~ '^[0-9]{2}\.[0-9]{3}\.[0-9]{3}/[0-9]{4}-[0-9]{2}$'),
    CONSTRAINT ck_atividade_datas      CHECK (Data_Fim IS NULL OR Data_Fim >= Data_Inicio)
);

-- ============================================================================
-- LOTE -- J7
-- Relacionamento Gera (1:1 Atividade->Lote): FK Atividade com UNIQUE + NOT NULL.
-- N5: Status_Ciclo_de_Vida restrito a Disponível / Aposentado / Invalidado.
-- ============================================================================
CREATE TABLE LOTE (
    Num_Serie_Registro    VARCHAR(50)   NOT NULL,
    Valor                 NUMERIC(15,2),
    Quantidade_de_Credito NUMERIC(15,2) NOT NULL,
    Ano_Geracao           INTEGER,
    Status_Ciclo_de_Vida  VARCHAR(15)   NOT NULL,
    Atividade             VARCHAR(50)   NOT NULL,

    CONSTRAINT pk_lote           PRIMARY KEY (Num_Serie_Registro),
    CONSTRAINT uq_lote_atividade UNIQUE (Atividade),
    CONSTRAINT fk_lote_atividade FOREIGN KEY (Atividade)
        REFERENCES ATIVIDADE (Codigo_Ordem_Servico) ON DELETE RESTRICT,
    CONSTRAINT ck_lote_ano       CHECK (Ano_Geracao BETWEEN 1990 AND 2100),
    CONSTRAINT ck_lote_status    CHECK (Status_Ciclo_de_Vida IN ('Disponível', 'Aposentado', 'Invalidado'))
);

-- ============================================================================
-- HISTORICO_PRECO (entidade fraca dependente do Lote) -- N6 (MER)
-- ON DELETE CASCADE: o histórico não existe sem o lote.
-- ============================================================================
CREATE TABLE HISTORICO_PRECO (
    Num_Serie_Registro VARCHAR(50)   NOT NULL,
    Data               DATE          NOT NULL,
    Preco              NUMERIC(15,2) NOT NULL,

    CONSTRAINT pk_historico_preco PRIMARY KEY (Num_Serie_Registro, Data),
    CONSTRAINT fk_historico_lote  FOREIGN KEY (Num_Serie_Registro)
        REFERENCES LOTE (Num_Serie_Registro) ON DELETE CASCADE
);

-- ============================================================================
-- LAUDO (mapeamento da agregação Audita) -- J6
-- A FK Atividade já identifica indiretamente o Auditor (evita redundância -- J6).
-- URL_do_Documento validada por regex http(s).
-- ============================================================================
CREATE TABLE LAUDO (
    Numero_do_Protocolo VARCHAR(50)  NOT NULL,
    Atividade           VARCHAR(50)  NOT NULL,
    Data                DATE,
    Parecer_Final       TEXT,
    URL_do_Documento    VARCHAR(500),
    Credito_Real        NUMERIC(15,2),
    Certificador        VARCHAR(18),

    CONSTRAINT pk_laudo              PRIMARY KEY (Numero_do_Protocolo),
    CONSTRAINT fk_laudo_atividade    FOREIGN KEY (Atividade)
        REFERENCES ATIVIDADE (Codigo_Ordem_Servico) ON DELETE RESTRICT,
    CONSTRAINT fk_laudo_certificador FOREIGN KEY (Certificador)
        REFERENCES CERTIFICADOR (CNPJ) ON DELETE SET NULL,
    CONSTRAINT ck_laudo_url          CHECK (URL_do_Documento IS NULL OR URL_do_Documento ~ '^https?://[^[:space:]]+$'),
    CONSTRAINT ck_laudo_cert_cnpj    CHECK (Certificador IS NULL OR Certificador ~ '^[0-9]{2}\.[0-9]{3}\.[0-9]{3}/[0-9]{4}-[0-9]{2}$')
);

-- ============================================================================
-- TRANSACAO (agregação que substituiu o ternário Negocia)
-- N7 (MER): a regra "agente não compra lote próprio" é validada na aplicação.
-- ============================================================================
CREATE TABLE TRANSACAO (
    Nota_Fiscal              VARCHAR(50)  NOT NULL,
    Agente_Mercado_Vendedor  VARCHAR(18)  NOT NULL,
    Agente_Mercado_Comprador VARCHAR(18)  NOT NULL,
    Data_Hora                TIMESTAMP    NOT NULL,
    Valor                    NUMERIC(15,2),

    CONSTRAINT pk_transacao           PRIMARY KEY (Nota_Fiscal),
    CONSTRAINT fk_transacao_vendedor  FOREIGN KEY (Agente_Mercado_Vendedor)
        REFERENCES AGENTE_MERCADO (CNPJ) ON DELETE RESTRICT,
    CONSTRAINT fk_transacao_comprador FOREIGN KEY (Agente_Mercado_Comprador)
        REFERENCES AGENTE_MERCADO (CNPJ) ON DELETE RESTRICT,
    CONSTRAINT ck_tr_vendedor_cnpj    CHECK (Agente_Mercado_Vendedor  ~ '^[0-9]{2}\.[0-9]{3}\.[0-9]{3}/[0-9]{4}-[0-9]{2}$'),
    CONSTRAINT ck_tr_comprador_cnpj   CHECK (Agente_Mercado_Comprador ~ '^[0-9]{2}\.[0-9]{3}\.[0-9]{3}/[0-9]{4}-[0-9]{2}$'),
    CONSTRAINT ck_transacao_partes    CHECK (Agente_Mercado_Vendedor  <> Agente_Mercado_Comprador)
);

-- ============================================================================
-- TRANSACAO_LOTE (tabela de ligação N:N entre Transação e Lote) -- J9
-- ============================================================================
CREATE TABLE TRANSACAO_LOTE (
    Transacao VARCHAR(50) NOT NULL,
    Lote      VARCHAR(50) NOT NULL,

    CONSTRAINT pk_transacao_lote PRIMARY KEY (Transacao, Lote),
    CONSTRAINT fk_tl_transacao   FOREIGN KEY (Transacao)
        REFERENCES TRANSACAO (Nota_Fiscal) ON DELETE CASCADE,
    CONSTRAINT fk_tl_lote        FOREIGN KEY (Lote)
        REFERENCES LOTE (Num_Serie_Registro) ON DELETE RESTRICT
);
