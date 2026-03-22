### CarbonTrack - Sistema de regulação de compra e venda de créditos de carbono

**Entidades:**

**Pessoa Jurídica** (Entidade Supertipo): Entidade abstrata que centraliza os atributos comuns a todas as instituições. Possui uma **Especialização Total e Disjunta** (linha dupla + "D"). No sistema, uma instituição deve obrigatoriamente ser ou um Agente de Mercado ou um Agente de Conformidade.

* **Agente de Mercado (Sub-tipo):** Empresas que operam financeiramente no sistema. Possuem **Especialização Sobreposta (O)**, permitindo que uma mesma empresa atue como Originadora e Compradora simultaneamente.

* **Agente de Conformidade (Sub-tipo):** Entidades reguladoras. Possuem **Especialização Disjunta (D)** entre Auditor e Certificador, garantindo a imparcialidade do processo.

* **Projeto:** Iniciativa de mitigação ambiental (ex: reflorestamento, energia limpa) que serve como o agrupador das atividades de campo.

* **Atividade:** Ações específicas de execução (plantio, monitoramento). As atividades podem ou não estarem contidas dentro de um projeto, isto porque uma empresa pode realizar atividades de forma avulsa sem que a mesma esteja envolvido com um projeto. 

**Lote:** Conjunto certificado de créditos de carbono. Representa o ativo financeiro gerado após a validação das atividades. Um Lote tem um valor monetário e uma quantidade de créditos (representa o quanto de CO2 deixou de ser emitido).

* **Histórico Preços (Entidade Fraca de Crédito):** Rastreia o histórico de preços de 
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
  * Participação total do Projeto: não existe Projeto sem atividades. O pressuposto é de que um projeto é cadastrado no sistema com atividades associadas
    
* **Audita / Laudo (Auditor e Atividade):**
  * O auditor avalia a execução da atividade, gerando um laudo.

* **Verifica (Certificador e Laudo):**
  * A certificadora não avalia diretamente a atividade, mas sim o laudo gerado pelo auditor.

* **Registra (Certificador e Lote):**
  * Após verificação positiva, a certificadora emite e registra o lote.

* **Negocia / Transação (entidade associativa)  (Agente de Mercado e Lote):**
  * Evento onde a titularidade do lote é transferida.
  * O sistema usa esse relacionamento para determinar o proprietário atual.
 
* **Possui (Lote e Histórico Preços):**
  * Relacionamento identificador para associar um lote de créditros a seu histórico de preços.
  * Histórico Preços é entidade fraca de Lote.

---

**Atributos das Entidades:**

* **Pessoa Jurídica (Super-tipo):**
  * `CNPJ` (Chave Primária): Identificador único universal.
  * `Razao_Social` / `Nome_Fantasia`: Dados cadastrais legais.
  * `Endereço` (Atributo Composto): CEP, Estado e Rua.
  * `Status`: Indica se a instituição está apta a operar.

* **Agente de Mercado (Sub-tipo):**
  * `Tipo`: atributo para diferenciar Comprador/Originador

* **Auditor (Sub-tipo):**
  * `Registro_Acreditação` / `Data Validade Acreditação`: Credenciais técnicas do auditor.

* **Certificador (Sub-tipo):**
  * `Padrão_Certificacao`: Protocolo internacional seguido (ex: Verra).

* **Projeto:**
  * `Num_Licenca_Ambiental` (Chave Primária): Registro oficial governamental.
  * `Nome_Projeto` / `Metodologia_Aplicada`: Identificação comercial e técnica.
  * `Data_Inicio` / `Data_Fim`: Cronograma.
  * `Duração` (atributo derivado): obtido a partir de `Data Inicio` e `Data_Fim`

* **Atividade:**
  * `Codigo_Ordem_Servico` (Chave Primária): Identificador dentro do projeto.
  * `Custo_Operacional` / `Data_Execucao`: Dados de execução.
  * `Data_Inicio` / `Data_Fim`: Cronograma.
  * `Duração` (atributo derivado): obtido a partir de `Data Inicio` e `Data_Fim`
  * `Credito_Estimado`: Projeção de carbono.

* **Lote:**
  * `Num_Serie_Registro` (Chave Primária): Identificador global.
  * `Valor do Cédito`: Valor estipulado para adquirir o lote
  * `Quantidade Créditos`: Quantidade de carbono que deixou de ser emitido em toneladas (1 tonelada de CO2 = 1 Crédito).
  * `Ano_Geracao`: Ano da redução de emissão.
  * `Status_Ciclo_Vida`: (Pendente, Emitido, Aposentado).

* **Transação (Agregação *Negocia*):**
  * `Nota_Fiscal` (Chave Primária): Identificador do contrato.
  * `Data_Hora` / `Valor`: Dados financeiros e temporais.

* **Laudo (Agregação *Audita*):**
  * `Numero_Protocolo` (Chave Primária): Identificador do documento.
  * `Parecer_Final` / `Credito_Real`: Resultado técnico e quantidade validada.
 
* **Histórico Preços (Entidade Fraca de Lote):** 
  * `Data` (Chave Secundária): Identificar a data da mudança do preço
  * `Preço`: Preço referente a esta data.

---

**Observações/Notas**

* Uma empresa pode armazenar os endereços de sua sede e de suas filiais, por isso o uso do atributo multivalorado composto.
* Um projeto representa um conjunto de atividades relacionadas à geração de créditos ambientais.
* Assim que a empresa Certificadora registra um Lote novo, este deve ser atribuído a empresa originadora que o fez, sendo esta a primeira detentora deste Lote.
* Para garantir a integridade referencial, o sistema implementará uma regra de automação (Trigger). No momento em que a Certificadora valida uma Atividade e registra o Crédito correspondente, o sistema identifica automaticamente o Originador responsável por aquela atividade e vincula-o como o detentor inicial do crédito a partir da relação Gera.
