### CarbonTrack - Sistema de regulação de compra e venda de créditos de carbono

**Entidades:**

**Pessoa Jurídica** (Entidade Supertipo): Entidade abstrata que centraliza os atributos comuns a todas as instituições. Possui uma **Especialização Total e Disjunta** (linha dupla + "D"). No sistema, uma instituição deve obrigatoriamente ser ou um Agente de Mercado ou um Agente de Conformidade.

* **Agente de Mercado (Sub-tipo):** Empresas que operam financeiramente no sistema. Possuem **Especialização Sobreposta (O)**, permitindo que uma mesma empresa atue como Originadora e Compradora simultaneamente.

* **Comprador:**: subtipo de Agente de Mercado

* * **Originador:**: subtipo de Agente de Mercado

* **Agente de Conformidade (Sub-tipo):** Entidades reguladoras. Possuem **Especialização Disjunta (D)** entre Auditor e Certificador, garantindo a imparcialidade do processo.

* **Auditor:**: subtipo de Agente de Conformidade.

* **Certificador:**: subtipo de Agente de Conformidade.

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
  * Relacionamento 1-para-muitos (1:N).
  * Um originador executa diversas atividades, mas uma atividade só pode ser realizada por uma única empresa originadora. Isso porque um lote é gerado a partir de uma atividade e um lote deve estar associado, inicialmente, a apenas um originador.  

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
 
 * **Gera (Lote e Originador):**
  * Relacionamento que associa um lote a empresa que o originou. A empresa originadora é sempre a primeira dona do lote.
---

**Atributos das Entidades:**

* **Pessoa Jurídica (Super-tipo):**
  * `CNPJ` (Chave Primária): Identificador único universal.
  * `Razao_Social` / `Nome_Fantasia`: Dados cadastrais legais.
  * `Endereço` (Atributo Composto): CEP, Estado e Rua.
  * `Status`: Indica se a instituição está apta a operar.

* **Agente de Mercado (Sub-tipo de Pessoa Juridica):**
  * `Tipo`: atributo para diferenciar Comprador/Originador
 
* **Comprador (Sub-tipo de Agente de Mercado):**
  * `Perfil Comprador`: descreve o perfil do comprador

* **Originador (Sub-tipo de Agente de Mercado):**
  * `Setor Atuação`: descreve a área de impacto ambiental do originador (ex: reflorestamento, energia limpa)
  * `Capacidade Tecnica`: documento comprobatório da capacidade técnica do originador para realizar atividades.

* **Agente de Conformidade (Sub-tipo de Pessoa Juridica):**
  * `Atribuição`: atributo para atribuir a função de Auditor ou Certificador.

* **Auditor (Sub-tipo de Agente de Conformidade):**
  * `Registro_Acreditação` / `Data Validade Acreditação`: Credenciais técnicas do auditor.

* **Certificador (Sub-tipo de Agente de Conformidade):**
  * `Padrão_Certificacao`: Protocolo internacional seguido (ex: Verra).

* **Projeto:**
  * `Num_Licenca_Ambiental` (Chave Primária): Registro oficial governamental.
  * `Nome_Projeto` / `Metodologia_Aplicada`: Identificação comercial e técnica.
  * `Data_Inicio` / `Data_Fim`: Cronograma.
  * `Duração` (atributo derivado): obtido a partir de `Data Inicio` e `Data_Fim`

* **Atividade:**
  * `Codigo_Ordem_Servico` (Chave Primária): Identificador dentro do projeto.
  * `Custo_Operacional`: Dados monetários da execução da atividade.
  * `Descrição Atividade`: Descrição da atividade feita.
  * `Data_Inicio` / `Data_Fim`: Cronograma.
  * `Duração` (atributo derivado): obtido a partir de `Data Inicio` e `Data_Fim`
  * `Credito_Estimado`: Projeção de carbono.

* **Lote:**
  * `Num_Serie_Registro` (Chave Primária): Identificador global.
  * `Valor do Cédito`: Valor estipulado para adquirir o lote
  * `Quantidade Créditos`: Quantidade de carbono que deixou de ser emitido em toneladas (1 tonelada de CO2 = 1 Crédito).
  * `Ano_Geracao`: Ano da redução de emissão.
  * `Status_Ciclo_Vida`: (Disponível, Aposentado). Indica se o lote pode ser vendido ou se não pode mais ser comercializado porque foi aposentado.

* **Transação (Agregação *Negocia*):**
  * `Nota_Fiscal` (Chave Primária): Identificador do contrato.
  * `Data_Hora` / `Valor`: Dados financeiros e temporais.

* **Laudo (Agregação *Audita*):**
  * `Numero_Protocolo` (Chave Primária): Identificador do documento.
  * `Parecer_Final` / `Credito_Real`: Resultado técnico e quantidade validada.
  * `URL do Documento`: URL para direcionar ao documento do laudo. 
 
* **Histórico Preços (Entidade Fraca de Lote):** 
  * `Data` (Chave Secundária): Identificar a data da mudança do preço
  * `Preço`: Preço referente a esta data.

---

**Observações/Notas**

* (N1) Uma empresa pode armazenar os endereços de sua sede e de suas filiais, por isso o uso do atributo multivalorado composto.
* (N2) Um projeto representa um conjunto de atividades relacionadas à geração de créditos ambientais.
* (N3) Assim que a empresa Certificadora registra um Lote novo, este deve ser atribuído a empresa originadora que o fez, sendo esta a primeira detentora deste Lote.
* (N4) Para garantir a integridade referencial, o sistema implementará uma regra de automação (Trigger). No momento em que a Certificadora valida uma Atividade e registra o Crédito correspondente, o sistema identifica automaticamente o Originador responsável por aquela atividade e vincula-o como o detentor inicial do crédito a partir da relação Gera.
* (N5) O atributo Status Ciclo Vida do Lote possui domínio restrito a apenas dois valores: 'Disponível' e 'Aposentado'. No momento em que a Certificadora registra o Lote no sistema, este atributo deve ser obrigatoriamente inicializado como 'Disponível'. Ele transitará para o estado 'Aposentado' unicamente quando a empresa detentora decidir utilizá-lo para compensar suas emissões, o que inativará o Lote para futuras negociações
