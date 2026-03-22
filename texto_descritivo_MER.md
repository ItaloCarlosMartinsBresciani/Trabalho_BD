### Sistema de gerenciamento de créditos de carbono

**Entidades:**

**Pessoa Jurídica** (Entidade Supertipo): Entidade abstrata que centraliza os atributos comuns a todas as instituições. Possui uma **Especialização Total e Disjunta** (linha dupla + "D"). No sistema, uma instituição deve obrigatoriamente ser ou um Agente de Mercado ou um Agente de Conformidade.

* **Agentes de Mercado (Sub-tipo):** Empresas que operam financeiramente no sistema. Possuem **Especialização Sobreposta (O)**, permitindo que uma mesma empresa atue como Originadora e Compradora simultaneamente.

* **Agentes de Conformidade (Sub-tipo):** Entidades reguladoras. Possuem **Especialização Disjunta (D)** entre Auditor e Certificador, garantindo a imparcialidade do processo.

**Projeto:** Iniciativa de mitigação ambiental (ex: reflorestamento, energia limpa) que serve como o agrupador das atividades de campo.

**Atividade:** Ações específicas de execução (plantio, monitoramento). As atividades podem ou não estarem contidas dentro de um projeto, isto porque uma empresa pode realizar atividades de forma avulsa sem que a mesma esteja envolvido com um projeto. 

**Crédito:** A unidade certificada de crédito de carbono. Representa o ativo financeiro gerado após a validação das atividades. Um Crédito tem um valor monetário e uma quantidade de CO2 (representa o quanto de CO2 deixou de ser emitido).

---

**Entidades Associativas (Agregações):**

*No diagrama, são representadas por losangos envoltos em retângulos, permitindo relacionamentos complexos.*

* **Transação (Agregação *Negocia*):** Representa o evento de compra e venda. Envolve o Vendedor, o Comprador e o Lote específico, registrando dados fiscais e financeiros.

* **Laudo (Agregação *Audita*):** Representa o processo técnico onde um Auditor avalia uma Atividade. Esse bloco será posteriormente verificado para emissão de créditos.

---

**Relacionamentos:**

* **Realiza (Originador e Atividade):**
  * Relacionamento muitos-para-muitos (N:M).
  * Um originador executa diversas atividades, e uma atividade pode envolver múltiplos parceiros técnicos.

* **Contém (Projeto e Atividade):**
  * Relacionamento um-para-muitos (1:N).
  * Um projeto centraliza várias atividades.
  * Participação total do Projeto: não existe Projeto sem atividades. O pressu
    
* **Audita / Laudo (Auditor e Atividade):**
  * O auditor avalia a execução da atividade, gerando um laudo.

* **Verifica (Certificador e Laudo):**
  * A certificadora não avalia diretamente a atividade, mas sim o laudo gerado pelo auditor.

* **Registra (Certificador e Lote/Crédito):**
  * Após verificação positiva, a certificadora emite e registra o lote.

* **Negocia / Transação (Agente de Mercado e Lote):**
  * Evento onde a titularidade do lote é transferida.
  * O sistema usa esse relacionamento para determinar o proprietário atual.

---

**Atributos das Entidades:**

* **Pessoa Jurídica (Super-tipo):**
  * `CNPJ` (Chave Primária): Identificador único universal.
  * `Razao_Social` / `Nome_Fantasia`: Dados cadastrais legais.
  * `Endereço` (Atributo Composto): CEP, Estado e Rua.
  * `Status`: Indica se a instituição está apta a operar.

* **Agente de Mercado (Sub-tipo):**
  * `SaldoCarbono` (Atributo Derivado): Calculado em tempo real com base no histórico da agregação Negocia.

* **Auditor (Sub-tipo):**
  * `Registro_Acreditação` / `Data Validade Acreditação`: Credenciais técnicas do auditor.

* **Certificador (Sub-tipo):**
  * `Padrão_Certificacao`: Protocolo internacional seguido (ex: Verra).

* **Projeto:**
  * `Num_Licenca_Ambiental` (Chave Primária): Registro oficial governamental.
  * `Nome_Projeto` / `Metodologia_Aplicada`: Identificação comercial e técnica.
  * `Data_Inicio` / `Data_Fim_Prevista`: Cronograma.

* **Atividade:**
  * `Codigo_Ordem_Servico` (Chave Parcial): Identificador dentro do projeto.
  * `Custo_Operacional` / `Data_Execucao`: Dados de execução.
  * `Credito_Estimado`: Projeção de carbono.

* **Lote/Crédito:**
  * `Num_Serie_Registro` (Chave Primária): Identificador global.
  * `Ano_Geracao`: Ano da redução de emissão.
  * `Status_Ciclo_Vida`: (Pendente, Emitido, Aposentado).

* **Transação (Agregação *Negocia*):**
  * `Nota_Fiscal` (Chave Primária): Identificador do contrato.
  * `Data_Hora` / `Valor`: Dados financeiros e temporais.

* **Laudo (Agregação *Audita*):**
  * `Numero_Protocolo` (Chave Primária): Identificador do documento.
  * `Parecer_Final` / `Credito_Real`: Resultado técnico e quantidade validada.
