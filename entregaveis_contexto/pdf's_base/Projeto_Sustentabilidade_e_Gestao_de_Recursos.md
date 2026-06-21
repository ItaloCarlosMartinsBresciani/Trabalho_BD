# UNIVERSIDADE DE SÃO PAULO
## INSTITUTO DE CIÊNCIAS MATEMÁTICAS E DE COMPUTAÇÃO
### DEPARTAMENTO DE CIÊNCIAS DE COMPUTAÇÃO

**Profa.** Elaine Parros Machado de Sousa

**SCC0240 - Bases de Dados - 1º Semestre 2026**
**Estagiário PAE:** Anderson Henrique Giacomini

---

# Projeto – Sustentabilidade e Gestão de Recursos

## Objetivos do Projeto

O objetivo principal deste projeto é o desenvolvimento de um sistema de banco de dados para uma aplicação voltada à **Sustentabilidade e Gestão de Recursos**. O foco do projeto é a base de dados do sistema, projetada para a persistência e gerenciamento eficientes de dados. Além disso, com o intuito de integrar conhecimento de disciplinas distintas e aproximar o projeto de um cenário prático e real, deverá ser desenvolvido um protótipo simples do sistema para o usuário final, com funcionalidades relevantes para o contexto proposto.

Neste projeto, **deverá ser desenvolvido um sistema de base de dados voltado à gestão sustentável de recursos naturais e materiais, alinhado às diretrizes da Agenda 2030 da ONU e aos Objetivos de Desenvolvimento Sustentável (ODS)**, especialmente os relacionados à produção e ao consumo responsáveis, à ação climática e à proteção da vida terrestre e marinha. O grupo poderá escolher um subtema, como:

- Plataforma de troca e reutilização de produtos
- Sistema de logística reversa para embalagens
- Monitoramento de políticas públicas ambientais
- Gestão de indicadores de impacto socioambiental
- Controle de programas de economia circular em municípios
- Rastreamento de emissões e inventários de carbono corporativos
- Gestão de recursos hídricos
- Administração de áreas de conservação

Dessa forma, **há várias oportunidades a serem exploradas neste tema**, possibilitando a construção de bases de dados complexas quanto à diversidade de dados e aos relacionamentos entre eles.

O grupo deverá conceber uma aplicação no contexto desse tema, descrever o sistema proposto (com ênfase nos **requisitos de dados e de consultas**) e desenvolver um protótipo seguindo as etapas principais de projeto de base de dados. Vale ressaltar que os **requisitos do sistema são definidos pelo grupo**. Portanto, **usem a criatividade!**

É importante que sejam concebidas ideias com um escopo que permita a construção de uma base de dados de **complexidade média**, ou seja:

1. **Diversidade** de Conjuntos de Entidades (classes distintas do mundo real).
2. Utilização dos vários conceitos a serem apresentados ao longo da disciplina para estruturar uma base de dados.

---

## Parte 1: Descrição do Problema e Modelagem (MER)

**Entrega:** 22/03/2026 (até 23:55h)

**Entregar (obrigatoriamente!!!):**
- Arquivo(s) PDF (com BOA RESOLUÇÃO)
- No e-Disciplinas, em Atividade PROJETO PARTE 1
- Somente 1 dos membros do grupo deve fazer a submissão, preferencialmente o aluno cujo nome seja o primeiro na capa do relatório

### 1) Capa
Nome de instituição, disciplina, professor, título do projeto, nome e número USP de membros do grupo (grupos de 4 ou 5 alunos).

### 2) Descrição do Problema e dos Requisitos de Dados
Descrição detalhada e completa do problema a ser modelado, incluindo:

- Visão geral dos objetivos do sistema proposto: propósito, usuário-alvo, contexto, etc.
- Características, atributos e comportamento das entidades do 'mundo real'
- Relacionamento entre as entidades do 'mundo real'
- Restrições de integridade (consistência e validade) envolvendo as entidades e os relacionamentos do 'mundo real'
- Principais operações (funcionalidades):
  - Inserções (cadastros), atualizações e remoções de dados;
  - Consultas a serem realizadas - deve ser especificada uma quantidade significativa de consultas relevantes no domínio do problema, com complexidade média ou alta.
  - Não será necessário implementar, na Parte 3, todas as operações especificadas para o sistema, mas apenas uma parte delas.

> **OBS:** a descrição do problema e os requisitos de dados devem ser apresentados em texto descritivo. Lembre-se de que o texto será avaliado por alguém que não participou de sua elaboração e, portanto, deve ser claro e objetivo, contendo todos os detalhes e particularidades necessários ao entendimento do problema. Veja exemplos de descrição de requisitos de dados nos livros recomendados e nos projetos divulgados.

O grupo deve definir um contexto mais limitado (tema) para o desenvolvimento do projeto, dentro da ideia geral proposta. Mas é fundamental que o sistema tenha **DIVERSIDADE DE INFORMAÇÃO**, ou seja, deve ser rico em diferentes elementos ('entidades') do mundo real e em seus relacionamentos. A descrição deve conter uma grande variedade de informações que permita a geração de um modelo de dados satisfatório (complexidade média). Lembre-se de que a descrição deve dar maior enfoque aos requisitos de dados, sem esquecer as operações principais (funcionalidade).

### 3) Projeto Conceitual
Esquema conceitual representado por um Diagrama Entidade-Relacionamento, utilizando os construtores e conceitos do MER-X, conforme a notação apresentada em sala de aula. O projeto conceitual deve ser elaborado conforme a especificação apresentada na descrição do problema. Todos os requisitos descritos devem ser atendidos.

> **OBS:** no projeto conceitual, explore os conceitos vistos em aula, como atributos multivalorados, compostos, derivados, entidades fracas, agregações, especializações, etc. (lembrando que não é obrigatório incluir todos os conceitos).

---

## Parte 2: Projeto Lógico

**Entrega:** 10/05/2026 (até 23:55h)

**Entregar (obrigatoriamente!!!):**
- Arquivo(s) PDF (com BOA RESOLUÇÃO)
- No e-Disciplinas, em Atividade PROJETO PARTE 2
- Somente 1 dos membros do grupo deve fazer a submissão, preferencialmente o mesmo que realizou a submissão da Parte 1.

### 1) Projeto completo até esta fase, contendo:
- Parte 1 atualizada e corrigida. Indicar as correções realizadas.
- Projeto Lógico: esquema lógico da base de dados criado a partir do mapeamento do esquema conceitual para o Modelo Relacional, usando a notação apresentada em aula.
- Quando houver mais de uma possibilidade de mapeamento de um mesmo item do diagrama ER, discuta e justifique a opção adotada (o porquê, quais eram as outras alternativas e quais as vantagens da opção adotada). **ESSA DISCUSSÃO VALE 50% DA NOTA DO PROJETO LÓGICO.**
- Inclua todas as restrições de relação e restrições de integridade.
- Inclua todas as observações que julgar necessárias ao entendimento das soluções apresentadas.

> **OBS:** se os itens indicados para correção na Parte 1 não forem corrigidos, atualizados e entregues junto com a Parte 2, os pontos descontados na Parte 1 serão descontados novamente da nota da Parte 2.

---

## Parte 3: Implantação da base de dados e implementação do sistema

**Entrega:** 21/06/2026 (até 23:55h)

**Entregar (obrigatoriamente):**
- Arquivo(s) PDF (com BOA RESOLUÇÃO) e CÓDIGO.
- No e-Disciplinas, em Atividade PROJETO PARTE 3
- Somente 1 dos membros do grupo deve fazer a submissão, preferencialmente o aluno cujo nome conste primeiro na capa do relatório.

### 1) Criação da Base de Dados
Script (`esquema.sql`), documentado, com os comandos SQL para a criação da base de dados completa, de acordo com o esquema lógico.

### 2) Alimentação Inicial da Base de Dados
Script (`dados.sql`), documentado, com comandos SQL para a alimentação inicial de toda a base de dados, com no mínimo 2 tuplas por tabela.

### 3) Consultas
Script (`consultas.sql`), documentado, com os comandos SQL das consultas do sistema. Não é necessário implementar todas as consultas previstas na Parte 1, mas é requisito a elaboração de pelo menos **05 (cinco) consultas de complexidade média e alta**, considerando consultas diversificadas (junções internas e externas, agrupamentos, consultas aninhadas correlacionadas e não correlacionadas, …). As consultas devem ser documentadas e justificadas no relatório, considerando o contexto do projeto. E devem ser eficientes!

a. Dentre as 05 consultas mínimas, é **obrigatória** a implementação de 1 consulta envolvendo **DIVISÃO RELACIONAL**.

### 4) Implementação de Sistema
Criação de um protótipo operacional, simples, implementando, no mínimo:

a. Uma funcionalidade de cadastro de dados (i.e. interface funcional para inserção de dados em uma ou mais tabelas da base de dados, considerando a lógica da aplicação), com o devido tratamento de erros;

b. Uma funcionalidade de consulta ao banco, com a entrada de dados do usuário como "parâmetro da consulta" (i.e., uma interface funcional para que o usuário realize consultas parametrizadas). Pode ser uma das 05 consultas implementadas no script.

### Observações Gerais (Parte 3)

- **OBS 1:** A base de dados poderá ser criada nos SGBD relacionais Oracle ou PostgreSQL. O sistema poderá ser implementado nas linguagens de programação C/C++/Java/JavaScript/Python/Rust.
- **OBS 2:** A interface do protótipo pode ser simples (em linha de comando, por exemplo), mas deve considerar o usuário final leigo, ou seja, sem nenhum conhecimento sobre sistemas de banco de dados.
- **OBS 3:** Devem ser usadas declarações SQL explícitas para todas as operações implementadas; ou seja, **NÃO serão aceitas** operações realizadas por métodos de classes/componentes que executam comandos SQL implicitamente.
- **OBS 4:** O código-fonte deve ser devidamente documentado.
- **OBS 5:** a proposta do projeto (requisitos de dados e funcionalidades) pode evoluir ao longo do semestre. Basta documentar a modificação.
- **OBS 6:** Quanto aos métodos de conexão com o SGBD, em todas as linguagens devem ser utilizadas técnicas de tratamento de vulnerabilidades provenientes da entrada de dados do usuário (e.g., SQL Injection). Leia a documentação das bibliotecas. Também deve ser utilizado um controle transacional simples durante a execução do protótipo em casos de erros do SGBD.

### ENTREGAR:

✔ **Relatório** (em PDF, com BOA RESOLUÇÃO) do projeto completo, contendo:
- Partes 1 e 2 atualizadas e corrigidas;
- Parte 3 - descrição inicial da implementação: SGBD e linguagem utilizados, requisitos de sistema, os trechos do código-fonte que contenham os comandos SQL utilizados para implementar as operações e consultas definidas no projeto. Cada trecho deve conter, além do código, uma descrição sucinta da operação ou consulta que implementa e a localização do trecho no código-fonte (nome do arquivo, classe ou rotina…).
- **Conclusão:** uma análise a respeito do projeto como um todo, destacando os pontos de maior dificuldade, o aprendizado com o projeto, críticas e sugestões para melhorar a aplicação do projeto em turmas seguintes. **IMPORTANTE:** na avaliação, somente será considerada a presença ou ausência desse item, e não seu conteúdo; o importante é que seja feita uma análise crítica e objetiva.

✔ **Códigos-fonte**, scripts de consultas, criação e alimentação da base de dados e relatório do Projeto.

> **OBS:** se os itens indicados para correção nas Partes 1 e 2 não forem corrigidos, atualizados e entregues junto com a Parte 3, os pontos descontados nas partes anteriores serão descontados novamente da nota da Parte 3.

---

## Final: Apresentação do Trabalho

**Apresentação:** de 23 de junho a 02 de julho, com horário agendado para o grupo durante o período de aula.

Os trabalhos serão apresentados pelo grupo (presença obrigatória de todo o grupo) em reunião a ser definida, no horário de aula (preferencialmente). Os membros do grupo apresentarão o protótipo do sistema e responderão a perguntas. Essa avaliação será considerada na nota final, e as respostas individuais de cada membro do grupo afetarão a nota do grupo como um todo.

No final do semestre serão divulgadas a agenda de apresentação dos grupos e as orientações necessárias. Cada grupo deverá comparecer apenas no seu dia/horário e fará a apresentação apenas aos estagiários.

---

## Cálculo da Nota do Projeto

| Parte | Peso |
|---|---|
| Parte 1 | 30% da nota final |
| Parte 2 | 30% da nota final |
| Parte 3 | 40% da nota final |
