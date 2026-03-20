
### Sistema de gerenciamento de créditos de carbono

**Entidades:**

**Pessoa Jurídica** (Entidade Supertipo): Entidade abstrata que centraliza os atributos comuns. Possui uma **Especialização Total e Disjunta** (indicada pela linha dupla e o círculo com "D"). Isso significa que toda Pessoa Jurídica no sistema *deve obrigatoriamente* pertencer a *apenas uma* das subentidades abaixo:
* **Originadores (Desenvolvedores de projeto):** Empresas ou ONGs que planejam e executam projetos em campo que de fato removem o carbono ou evitam emissão.
* **Auditores Independentes:** Organismos de validação e verificação que atestam se o projeto originador fez o que prometeu e se os cálculos de carbono estão corretos.
* **Certificadores/Registradoras:** Instituições responsáveis por analisar laudos de auditoria e, a partir disso, gerar o Lote de Crédito de carbono.
* **Compradores:** Entidades (empresas ou investidores) que adquirem os créditos de carbono gerados pelos projetos para compensar suas próprias emissões ou para investimento.

**Projeto:** Iniciativa estruturada de redução, evitação ou remoção de Gases de Efeito Estufa (GEE). 

**Atividade:** Ações ou fases específicas realizadas dentro do escopo de um Projeto (ex: plantio de uma área específica, instalação de equipamentos).

**Lote/Crédito:** A unidade quantificada e certificada de carbono.
* *Atributos sugeridos (conforme seu texto):* ID_Lote, Quantidade_Toneladas, Ano_Geracao (ano de captura, redução ou remoção de GEE ocorreu), Status (Pendente/Emitido).

---

**Entidades Associativas (Agregações):**
*No seu diagrama, elas aparecem como losangos dentro de retângulos. Elas ocorrem quando um relacionamento muitos-para-muitos (N:M) precisa se relacionar com outras entidades ou possuir atributos próprios.*

* **Transação (relacionamento *Negocia*):** Representa o evento de compra e venda formalizado entre `Compradores` e `Originadores`. 
* **Laudo (relacionamento *Audita*):** Representa o documento oficial e o processo em que uma `Atividade` é auditada por `Auditores`.
* **

---

**Relacionamentos:**

* **Participa (Originadores e Projeto):**
    * Um Originador participa de um ou mais Projetos.
    * *Regra do diagrama:* A linha dupla do lado de `Projeto` indica **participação total**. Ou seja, todo Projeto deve, obrigatoriamente, ter a participação de um Originador.
* **Realiza (Originadores e Atividade):**
    * Um Originador realiza diversas Atividades.
    * *Regra do diagrama:* A linha dupla do lado de `Atividade` indica **participação total**. Toda Atividade deve ser obrigatoriamente realizada por um Originador.
* **Contém (Projeto e Atividade):**
    * Um Projeto contém várias Atividades.
    * *Regra do diagrama:* A linha dupla do lado de `Projeto` indica **participação total**. Um projeto precisa ter atividades, mas nem toda atividade é contida por um Projeto.
* **Negocia / Transação (Compradores e Originadores):**
    * Compradores negociam com Originadores gerando uma `Transação`.
    * Compradores podem negociar créditos de carbono entre si. 
* **Audita / Laudo (Auditores e Atividade):**
    * Auditores avaliam uma Atividade, gerando um `Laudo`. Uma atividade "é auditada" e o auditor gera o laudo.
* **Verifica (Certificadores/Registradoras e Laudo):**
    * As Certificadoras não se relacionam diretamente com a atividade, mas sim com a entidade associativa `Laudo`. A certificadora avalia ("é verificado") o laudo emitido pelo auditor para garantir sua validade.
* **Registra (Certificadores/Registradoras e Lote/Crédito):**
    * Após a verificação positiva, a Certificadora registra e emite o `Lote/Crédito` de carbono.
* **Possui (Lote/Crédito e Agentes de Mercado)***:
    * O `Lote/Crédito` de carbono pode ser possuido por um agente de mercado.

***
---

Atributos das Entidades: 

* **Pessoa Jurídica (Super-tipo)**:
   * `CNPJ` (Chave Primária): O identificador único e exclusivo.
   * `Razao_Social`: essencial para contratos legais
   * `Nome_Fantasia`: também essencial para contratos e para interface do sistema
   * `Data_Cadastro`: data de cadastro da entidade no sistema.
   * `Status` (Ativo/Inativo): indica se a empresa está apta a operar (uma empresa banida não pode ser excluída do banco por questões de auditoria, apenas "inativada").

* **Originadores (Sub-tipo)**:
  * `Setor_Atuacao`: (Ex: Florestal, Energia Renovável, Agricultura). Importante para relatórios e para investidore que podem buscar comprar créditos de nichos específicos.
  * `Capacidade_Tecnica`: Um documento que atesta que a ONG/Empresa tem permissão para atuar na área.

* **Auditores (Sub-tipo):
  * `Registro_Acreditação`: (Ex: Código de certificação ISO 14065). Prova legal que aquele auditor tem competência internacional para auditar carbono. Sem isso, o laudo não tem validade.
  * `Data_Validade_Acreditacao`: Auditores perdem a licença. O sistema precisa bloquear laudos de auditores com licenças vencidas.
 
* **Certificadores/Registradoras (Sub-tipo)**:
   * `Padrao_Certificacao`: (Ex: Verra, Gold Standard, CDM). Indica sob qual protocolo global essa entidade emite seus créditos. Isso afeta diretamente o valor de mercado do crédito de carbono, pois padrões mais rigorosos geram créditos mais caros.

* **Compradores (Sub-tipo)**:
   * `Perfil_Comprador`: (Ex: Investidor, Compensação). Define se a entidade está comprando para guardar e revender mais caro no futuro (especulação) ou para "aposentar" o crédito e abater sua própria poluição (compensação).
   * `Volume_Estimado_Demanda`: Dado estratégico de vendas para o sistema entender o tamanho do cliente e sugerir projetos adequados.

* **Projeto**:
   * `Numero_Licenca_Ambiental` (Chave Primária): Código alfanumérico oficial emitido pelo órgão governamental ou ambiental competente.
   * `Nome_Projeto`: O título comercial do projeto (Ex: "Reflorestamento Amazônia Legal Fase 1").
   * `Coordenadas_Geograficas` (Latitude/Longitude ou Polígono georreferenciado): Extremamente vital no mercado de carbono para evitar a "dupla contagem" (garantir que dois projetos não estejam vendendo carbono do mesmo pedaço exato de terra).
   * `Data_Inicio` e `Data_Fim_Prevista`: Delimita o ciclo de vida do projeto.
   * `Metodologia_Aplicada`: Qual regra científica e matemática será usada para calcular o carbono (ex: ACM0002).

* **Atividade**:
   * `Codigo_Ordem_Servico` (Chave Primária): O código do documento técnico ou ordem de serviço que formaliza a execução daquela ação no mundo real.
   * `Descricao_Atividade`: O que foi feito na prática (Ex: "Plantio de 10.000 mudas nativas no setor Norte").
   * `Descricao_Atividade`: O que foi feito na prática (Ex: "Plantio de 10.000 mudas nativas no setor Norte").
   * `Custo_Operacional`: Quanto custou a execução. Útil para o Originador calcular seu Retorno sobre Investimento (ROI).
   * `Periodo_Execucao` (Data Inicio e Fim): Fundamental para que o auditor saiba o intervalo de tempo exato que ele deve focar sua análise.

* **Lote/Crédito**:
   * `Número_Série_Registro` (Chave Primária): Identificador exclusivo do lote gerado.
   * `Quantidade_Toneladas`: O "dinheiro" do sistema. Cada tonelada equivale a um crédito.
   * `Ano_Geracao` (Vintage): O ano em que o carbono foi efetivamente capturado ou evitado. No mercado financeiro, créditos mais antigos costumam valer menos.
   * `Status_Ciclo_Vida`: (Ex: Pendente, Emitido, Negociado, Aposentado). **Crítico:** Quando um comprador usa o crédito para compensar sua poluição, o crédito é "Aposentado" (Retired) e sai de circulação para sempre.

* **Transação (Entidade Associativa proveniente de "Negocia")**:
   * `Nota_Fiscal` (Chave Primária): Registro oficial e único do contrato de compra e venda.
   * `Data_Hora_Transacao`: O momento exato (timestamp) da operação, vital para auditorias financeiras.
   * `Valor_Unitario` e `Valor_Total`: O histórico financeiro. *Nota técnica:* O banco de dados precisa garantir precisão decimal aqui (geralmente usamos o tipo numérico `DECIMAL` em SQL, nunca `FLOAT`, para evitar erros de arredondamento com dinheiro real).

* **Laudo (Entidade Associativa proveniente de "Audita")**:
   * `Numero_Protocolo_Auditoria` (Chave Primária): Número de registro do documento de auditoria.
   * `Parecer_Final`: (Ex: Aprovado, Reprovado, Necessita Correção). O resultado da auditoria.
   * `Documento_Anexo`: O caminho (URL segura ou hash criptográfico) do arquivo PDF assinado digitalmente pelo auditor. Nunca salvamos o arquivo PDF inteiro dentro da tabela do banco de dados por questões de performance.
