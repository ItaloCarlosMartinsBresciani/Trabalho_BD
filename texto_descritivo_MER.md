
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
   * `Status_Atividade` (Ativo/Inativo): indica se a empresa está apta a operar (uma empresa banida não pode ser excluída do banco por questões de auditoria, apenas "inativada").

* **Originadores (Sub-tipo)**:
  * `Setor_Atuacao`: (Ex: Florestal, Energia Renovável, Agricultura). Importante para relatórios e para investidore que podem buscar comprar créditos de nichos específicos.
  * `Capacidade_Tecnica_Comprovada`: Um documento que atesta que a ONG/Empresa tem permissão para atuar na área.

* **Auditores (Sub-tipo):
  * `Registro_Acreditação`: (Ex: Código de certificação ISO 14065). Prova legal que aquele auditor tem competência internacional para auditar carbono. Sem isso, o laudo não tem validade.
  * `Data_Validade_Acreditacao`: Auditores perdem a licença. O sistema precisa bloquear laudos de auditores com licenças vencidas.
 
* **Certificadores/Registradores (Sub-Tipo)** 
