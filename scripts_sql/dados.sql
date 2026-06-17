-- ============================================================================
-- CarbonTrack - Sistema de Rastreabilidade para Créditos de Carbono
-- Script de Alimentação Inicial da Base de Dados (DML)
--
-- SGBD alvo: PostgreSQL
-- Pré-requisito: executar antes o esquema.sql (criação das tabelas).
--
-- Este script popula TODAS as tabelas com, no mínimo, 2 tuplas cada,
-- respeitando a ordem de dependência das chaves estrangeiras e os domínios
-- definidos pelas cláusulas CHECK do esquema.
--
-- Cenários de negócio representados (além do mínimo de 2 tuplas):
--   * Agente de Mercado SOBREPOSTO: a mesma PJ atua como Originador e Comprador (J3).
--   * Especialização DISJUNTA de Conformidade: cada agente é só Auditor OU Certificador (J8/N8).
--   * Atividade sem projeto e sem auditor (Projeto opcional; Auditor nasce NULL -- N7).
--   * Relacionamento Gera 1:1 Atividade->Lote (J7).
--   * Lote presente em MÚLTIPLAS transações, demonstrando o N:N (J9).
--
-- Toda a carga é executada dentro de uma única transação: ou tudo é gravado,
-- ou nada é (consistência referencial garantida).
-- ============================================================================

BEGIN;

-- ----------------------------------------------------------------------------
-- 1) PESSOA_JURIDICA (superclasse)
--    Funcao = discriminador da especialização (Mercado / Conformidade).
--    7 instituições: 3 de mercado + 4 de conformidade.
-- ----------------------------------------------------------------------------
INSERT INTO PESSOA_JURIDICA (CNPJ, Nome_Fantasia, Razao_Social, Status, Funcao) VALUES
    ('11.111.111/0001-11', 'EcoFlorestas',    'EcoFlorestas Reflorestamento S.A.',        'Apto',   'Mercado'),
    ('22.222.222/0001-22', 'AeroBrasil',       'AeroBrasil Linhas Aéreas Ltda.',           'Apto',   'Mercado'),
    ('33.333.333/0001-33', 'VerdeAgro',        'VerdeAgro Agronegócios e Compensação S.A.','Apto',   'Mercado'),
    ('44.444.444/0001-44', 'AuditCarbon',      'AuditCarbon Verificações Ambientais Ltda.','Apto',   'Conformidade'),
    ('55.555.555/0001-55', 'Verra Brasil',     'Verra Standard Brasil Certificadora S.A.', 'Apto',   'Conformidade'),
    ('66.666.666/0001-66', 'GreenAudit',       'GreenAudit Inspeções Técnicas Ltda.',      'Apto',   'Conformidade'),
    ('77.777.777/0001-77', 'GoldStandard BR',  'Gold Standard Certificação Brasil S.A.',   'Inapto', 'Conformidade');

-- ----------------------------------------------------------------------------
-- 2) ENDERECO (atributo composto multivalorado -- J2)
--    PJ '11...' possui sede + filial (multivalorado); demais possuem 1 endereço.
-- ----------------------------------------------------------------------------
INSERT INTO ENDERECO (CNPJ, CEP, Estado, Rua) VALUES
    ('11.111.111/0001-11', '13560-970', 'SP', 'Av. Trabalhador São-carlense, 400'),   -- sede
    ('11.111.111/0001-11', '69010-000', 'AM', 'Rua das Seringueiras, 120'),           -- filial
    ('22.222.222/0001-22', '04578-000', 'SP', 'Av. das Nações Unidas, 12901'),
    ('33.333.333/0001-33', '74000-000', 'GO', 'Rod. GO-020, km 15, Zona Rural'),
    ('44.444.444/0001-44', '20010-000', 'RJ', 'Rua da Assembleia, 10'),
    ('55.555.555/0001-55', '01310-100', 'SP', 'Av. Paulista, 1578'),
    ('66.666.666/0001-66', '30130-000', 'MG', 'Av. Afonso Pena, 1500'),
    ('77.777.777/0001-77', '80010-000', 'PR', 'Rua XV de Novembro, 600');

-- ----------------------------------------------------------------------------
-- 3) AGENTE_MERCADO (subclasse de Pessoa Jurídica)
-- ----------------------------------------------------------------------------
INSERT INTO AGENTE_MERCADO (CNPJ) VALUES
    ('11.111.111/0001-11'),
    ('22.222.222/0001-22'),
    ('33.333.333/0001-33');

-- ----------------------------------------------------------------------------
-- 4) ORIGINADOR (subclasse de Agente de Mercado)
--    PJ '11...' (puro originador) e PJ '33...' (também comprador -> sobreposto).
-- ----------------------------------------------------------------------------
INSERT INTO ORIGINADOR (CNPJ, Setor_Atuacao, Capacidade_Tecnica) VALUES
    ('11.111.111/0001-11', 'Reflorestamento', 'https://docs.carbontrack.br/cap-tec/ecoflorestas.pdf'),
    ('33.333.333/0001-33', 'Agropecuária',    'https://docs.carbontrack.br/cap-tec/verdeagro.pdf');

-- ----------------------------------------------------------------------------
-- 5) COMPRADOR (subclasse de Agente de Mercado)
--    PJ '22...' (puro comprador) e PJ '33...' (sobreposto: originador + comprador).
-- ----------------------------------------------------------------------------
INSERT INTO COMPRADOR (CNPJ, Perfil_Comprador) VALUES
    ('22.222.222/0001-22', 'Compensação corporativa - setor aéreo'),
    ('33.333.333/0001-33', 'Compensação corporativa - agronegócio');

-- ----------------------------------------------------------------------------
-- 6) TIPO_AGENTE_MERCADO (papéis sobrepostos -- J3)
--    Reflete a especialização sobreposta: PJ '33...' aparece nos dois papéis.
-- ----------------------------------------------------------------------------
INSERT INTO TIPO_AGENTE_MERCADO (CNPJ, Tipo) VALUES
    ('11.111.111/0001-11', 'Originador'),
    ('22.222.222/0001-22', 'Comprador'),
    ('33.333.333/0001-33', 'Originador'),
    ('33.333.333/0001-33', 'Comprador');

-- ----------------------------------------------------------------------------
-- 7) AGENTE_CONFORMIDADE (subclasse de Pessoa Jurídica)
--    Atribuicao = discriminador disjunto (N8): coerente com a subclasse de fato.
-- ----------------------------------------------------------------------------
INSERT INTO AGENTE_CONFORMIDADE (CNPJ, Atribuicao) VALUES
    ('44.444.444/0001-44', 'Auditor'),
    ('55.555.555/0001-55', 'Certificador'),
    ('66.666.666/0001-66', 'Auditor'),
    ('77.777.777/0001-77', 'Certificador');

-- ----------------------------------------------------------------------------
-- 8) AUDITOR (subclasse de Agente de Conformidade)
-- ----------------------------------------------------------------------------
INSERT INTO AUDITOR (CNPJ, Registro_Acreditacao, Data_Validade_Acreditacao) VALUES
    ('44.444.444/0001-44', 'INMETRO-AUD-2021-0098', '2026-12-31'),
    ('66.666.666/0001-66', 'INMETRO-AUD-2022-0455', '2027-06-30');

-- ----------------------------------------------------------------------------
-- 9) CERTIFICADOR (subclasse de Agente de Conformidade)
-- ----------------------------------------------------------------------------
INSERT INTO CERTIFICADOR (CNPJ, Padrao_Certificacao) VALUES
    ('55.555.555/0001-55', 'VCS - Verified Carbon Standard (Verra)'),
    ('77.777.777/0001-77', 'Gold Standard for the Global Goals');

-- ----------------------------------------------------------------------------
-- 10) PROJETO
--     Duracao em dias, coerente com (Data_Fim - Data_Inicio) -- N11/J10.
-- ----------------------------------------------------------------------------
INSERT INTO PROJETO (Num_Licenca_Ambiental, Nome_Projeto, Data_Inicio, Data_Fim, Duracao, Metodologia_Aplicada) VALUES
    ('LA-2024-001', 'Recuperação da Mata Atlântica - Vale do Ribeira', '2024-01-01', '2024-12-31', 365, 'VM0007 REDD+ Methodology Framework'),
    ('LA-2024-002', 'Manejo de Pastagens Sustentáveis - Cerrado',      '2024-03-01', '2024-08-31', 183, 'VM0042 Improved Agricultural Land Management');

-- ----------------------------------------------------------------------------
-- 11) ATIVIDADE (absorve FKs de Originador, Projeto e Auditor -- J4/J5)
--     OS-001: completa, com projeto e auditor já contratado.
--     OS-002: completa, com projeto e auditor.
--     OS-003: SEM projeto (opcional) e SEM auditor (NULL -- N7), demonstrando
--             os casos de FK opcional previstos no modelo.
-- ----------------------------------------------------------------------------
INSERT INTO ATIVIDADE (Codigo_Ordem_Servico, Originador, Projeto, Auditor, Descricao_Atividade, Custo_Operacional, Data_Inicio, Data_Fim, Duracao, Credito_Estimado) VALUES
    ('OS-001', '11.111.111/0001-11', 'LA-2024-001', '44.444.444/0001-44', 'Plantio de 50 mil mudas nativas em área degradada.', 480000.00, '2024-01-10', '2024-03-10', 60, 12000.00),
    ('OS-002', '33.333.333/0001-33', 'LA-2024-002', '66.666.666/0001-66', 'Implantação de sistema de pastejo rotacionado em 800 ha.', 320000.00, '2024-03-15', '2024-05-15', 61, 8500.00),
    ('OS-003', '11.111.111/0001-11', NULL,          NULL,                 'Monitoramento mensal por sensoriamento remoto (em andamento).', 45000.00, '2024-04-01', '2024-04-30', 29, 0.00);

-- ----------------------------------------------------------------------------
-- 12) LAUDO (mapeamento da agregação Audita -- J6)
--     A FK Atividade já identifica indiretamente o Auditor; Certificador é o
--     agente que analisou o laudo.
-- ----------------------------------------------------------------------------
INSERT INTO LAUDO (Numero_do_Protocolo, Atividade, Data, Parecer_Final, URL_do_Documento, Credito_Real, Certificador) VALUES
    ('PROT-2024-001', 'OS-001', '2024-03-20', 'Aprovado: execução conforme metodologia VM0007.',  'https://docs.carbontrack.br/laudos/prot-2024-001.pdf', 11800.00, '55.555.555/0001-55'),
    ('PROT-2024-002', 'OS-002', '2024-05-25', 'Aprovado com ressalvas: créditos ajustados.',       'https://docs.carbontrack.br/laudos/prot-2024-002.pdf',  8200.00, '77.777.777/0001-77');

-- ----------------------------------------------------------------------------
-- 13) LOTE (relacionamento Gera 1:1 Atividade->Lote -- J7)
--     FK Atividade UNIQUE + NOT NULL. OS-003 ainda não gerou lote (correto).
--     N3 (MER): a posse inicial é inferida do Originador da Atividade
--               (LT-0001 -> PJ '11...'; LT-0002 -> PJ '33...').
-- ----------------------------------------------------------------------------
INSERT INTO LOTE (Num_Serie_Registro, Valor, Quantidade_de_Credito, Ano_Geracao, Status_Ciclo_de_Vida, Atividade) VALUES
    ('BR-VCS-2024-0001', 95.00, 11800.00, 2024, 'Disponível',  'OS-001'),
    ('BR-VCS-2024-0002', 82.50,  8200.00, 2024, 'Aposentado',  'OS-002');

-- ----------------------------------------------------------------------------
-- 14) HISTORICO_PRECO (entidade fraca dependente do Lote -- N6)
--     Evolução cronológica de preço por lote.
-- ----------------------------------------------------------------------------
INSERT INTO HISTORICO_PRECO (Num_Serie_Registro, Data, Preco) VALUES
    ('BR-VCS-2024-0001', '2024-04-01', 88.00),
    ('BR-VCS-2024-0001', '2024-05-01', 92.00),
    ('BR-VCS-2024-0001', '2024-06-01', 95.00),
    ('BR-VCS-2024-0002', '2024-06-01', 80.00),
    ('BR-VCS-2024-0002', '2024-07-01', 82.50);

-- ----------------------------------------------------------------------------
-- 15) TRANSACAO (agregação que substituiu o ternário Negocia)
--     Vendedor e comprador são Agentes de Mercado distintos (CHECK do esquema).
--     NF-1003: revenda do LT-0001 (PJ '22...' vende para PJ '33...').
-- ----------------------------------------------------------------------------
INSERT INTO TRANSACAO (Nota_Fiscal, Agente_Mercado_Vendedor, Agente_Mercado_Comprador, Data_Hora, Valor) VALUES
    ('NF-1001', '11.111.111/0001-11', '22.222.222/0001-22', '2024-06-05 10:30:00', 1121000.00),
    ('NF-1002', '33.333.333/0001-33', '22.222.222/0001-22', '2024-07-02 14:15:00',  676500.00),
    ('NF-1003', '22.222.222/0001-22', '33.333.333/0001-33', '2024-08-10 09:00:00',  590000.00);

-- ----------------------------------------------------------------------------
-- 16) TRANSACAO_LOTE (tabela de ligação N:N -- J9)
--     LT-0001 aparece em DUAS transações (NF-1001 e NF-1003), demonstrando que
--     um lote pode ser negociado sucessivamente ao longo do ciclo de vida.
-- ----------------------------------------------------------------------------
INSERT INTO TRANSACAO_LOTE (Transacao, Lote) VALUES
    ('NF-1001', 'BR-VCS-2024-0001'),
    ('NF-1002', 'BR-VCS-2024-0002'),
    ('NF-1003', 'BR-VCS-2024-0001');

COMMIT;

-- ============================================================================
-- Fim da alimentação inicial.
-- Contagem mínima atendida (>= 2 tuplas por tabela):
--   PESSOA_JURIDICA(7), ENDERECO(8), AGENTE_MERCADO(3), ORIGINADOR(2),
--   COMPRADOR(2), TIPO_AGENTE_MERCADO(4), AGENTE_CONFORMIDADE(4), AUDITOR(2),
--   CERTIFICADOR(2), PROJETO(2), ATIVIDADE(3), LAUDO(2), LOTE(2),
--   HISTORICO_PRECO(5), TRANSACAO(3), TRANSACAO_LOTE(3).
-- ============================================================================
