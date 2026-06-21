-- ============================================================================
-- CarbonTrack - Sistema de Rastreabilidade para Créditos de Carbono
-- Script de Triggers e Funções (Regras de Negócio Automáticas)
--
-- SGBD alvo: PostgreSQL
-- Pré-requisito: executar após esquema.sql e antes de dados.sql.
-- ============================================================================

-- ============================================================================
-- NOTA N11: CÁLCULO DE ATRIBUTO DERIVADO (Duração)
-- Calcula automaticamente a Duração (em dias) com base na Data Inicial e Final.
-- ============================================================================
CREATE OR REPLACE FUNCTION calcular_duracao()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.Data_Fim IS NOT NULL THEN
        NEW.Duracao := NEW.Data_Fim - NEW.Data_Inicio;
    ELSE
        NEW.Duracao := NULL;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_calc_duracao_projeto
BEFORE INSERT OR UPDATE ON PROJETO
FOR EACH ROW EXECUTE PROCEDURE calcular_duracao();

CREATE TRIGGER trg_calc_duracao_atividade
BEFORE INSERT OR UPDATE ON ATIVIDADE
FOR EACH ROW EXECUTE PROCEDURE calcular_duracao();

-- ============================================================================
-- NOTA N8: GARANTIA DE DISJUNÇÃO (Auditor e Certificador)
-- Impede que um Agente com atribuição 'Auditor' seja inserido na tabela CERTIFICADOR,
-- e vice-versa, cruzando os dados com a superclasse AGENTE_CONFORMIDADE.
-- ============================================================================
CREATE OR REPLACE FUNCTION validar_disjuncao_auditor()
RETURNS TRIGGER AS $$
DECLARE
    v_atribuicao VARCHAR(15);
BEGIN
    SELECT Atribuicao INTO v_atribuicao 
    FROM AGENTE_CONFORMIDADE 
    WHERE CNPJ = NEW.CNPJ;

    IF v_atribuicao <> 'Auditor' THEN
        RAISE EXCEPTION 'Disjunção violada: O CNPJ % não tem atribuição de Auditor em Agente de Conformidade.', NEW.CNPJ;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_valida_auditor
BEFORE INSERT ON AUDITOR
FOR EACH ROW EXECUTE PROCEDURE validar_disjuncao_auditor();

CREATE OR REPLACE FUNCTION validar_disjuncao_certificador()
RETURNS TRIGGER AS $$
DECLARE
    v_atribuicao VARCHAR(15);
BEGIN
    SELECT Atribuicao INTO v_atribuicao 
    FROM AGENTE_CONFORMIDADE 
    WHERE CNPJ = NEW.CNPJ;

    IF v_atribuicao <> 'Certificador' THEN
        RAISE EXCEPTION 'Disjunção violada: O CNPJ % não tem atribuição de Certificador em Agente de Conformidade.', NEW.CNPJ;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_valida_certificador
BEFORE INSERT ON CERTIFICADOR
FOR EACH ROW EXECUTE PROCEDURE validar_disjuncao_certificador();

-- ============================================================================
-- NOTA N5: SINCRONIZAÇÃO DE IDENTIDADE (Papéis de Mercado)
-- Quando um Originador ou Comprador é inserido, automaticamente criamos 
-- o registro correspondente na tabela auxiliar TIPO_AGENTE_MERCADO para 
-- manter a consistência da especialização sobreposta.
-- ============================================================================
CREATE OR REPLACE FUNCTION sincronizar_tipo_originador()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO TIPO_AGENTE_MERCADO (CNPJ, Tipo) 
    VALUES (NEW.CNPJ, 'Originador')
    ON CONFLICT DO NOTHING; -- Evita erro de duplicidade se a aplicação já tiver inserido
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_sinc_originador
AFTER INSERT ON ORIGINADOR
FOR EACH ROW EXECUTE PROCEDURE sincronizar_tipo_originador();

CREATE OR REPLACE FUNCTION sincronizar_tipo_comprador()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO TIPO_AGENTE_MERCADO (CNPJ, Tipo) 
    VALUES (NEW.CNPJ, 'Comprador')
    ON CONFLICT DO NOTHING;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_sinc_comprador
AFTER INSERT ON COMPRADOR
FOR EACH ROW EXECUTE PROCEDURE sincronizar_tipo_comprador();