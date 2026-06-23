# Roteiro de Apresentação - CarbonTrack (15 Minutos)

Este roteiro estrutura a apresentação do sistema CarbonTrack para a Profa. Elaine e o monitor da disciplina de Bases de Dados. O objetivo é demonstrar o domínio técnico sobre o banco de dados e os requisitos exigidos no projeto.

---

## Estrutura da Apresentação
* **Integrante 1:** Apresentação Geral do Projeto (3 min)
* **Integrante 2:** A Aplicação (Demonstração Prática) (4 min)
* **Integrante 3:** Código-Fonte, Arquitetura e Triggers (4 min)
* **Integrante 4:** Consultas Analíticas (DQL) (4 min)

---

## Roteiro Detalhado

### 🗣️ Integrante 1: Apresentação Geral do Projeto (Slides) ⏱️ *3 Minutos*
**Objetivo:** Introduzir o contexto rapidamente e focar na robustez do modelo relacional.
* **(0:00 - 1:00) Introdução e Problema:**
  * *"Bom dia/boa tarde, professora Elaine e monitor. Nós somos o grupo responsável pelo **CarbonTrack**. Nosso projeto aborda a ODS de Ação Climática, com foco no mercado de compensação corporativa."*
  * Explicar rapidamente que o problema no mercado de carbono é a dupla contagem e a falta de rastreabilidade (fraudes). O sistema atua conectando quem planta (Originador), quem fiscaliza (Auditor/Certificador) e quem compra (Comprador).
* **(1:00 - 3:00) O Modelo Relacional (Slide principal):**
  * Mostrar o MER / Modelo Relacional no slide.
  * Destacar a complexidade média/alta que a professora exigiu: *"Para suportar esse cenário, modelamos um esquema que conta com **Especialização Sobreposta** (um agente pode ser Originador e Comprador ao mesmo tempo) e **Especialização Disjunta** (o Agente de Conformidade ou é Auditor ou Certificador)."*
  * Citar brevemente atributos multivalorados (Endereços das sedes) e como o Lote é conectado à Transação (relação N:N via tabela `Transacao_Lote`).

### 🗣️ Integrante 2: A Aplicação (Demonstração Prática) ⏱️ *4 Minutos*
**Objetivo:** Mostrar o sistema funcionando ao vivo (ou printado), destacando a interface para o "usuário final leigo" e o tratamento de transações em Python.
* **(3:00 - 4:30) Visão Geral do App e Cadastro:**
  * *"Nossa aplicação foi desenvolvida em Python nativo usando Tkinter, garantindo uma interface simples para um usuário corporativo registrar seus projetos."*
  * Mostrar a tela de inserção de **Projeto** ou **Atividade**. Explicar que a duração do projeto é calculada automaticamente.
  * *"Aqui garantimos a integridade visual: as chaves estrangeiras (ex: escolha do Originador) são carregadas dinamicamente do banco para o usuário não inserir um CNPJ inválido."*
* **(4:30 - 7:00) Segurança e Controle Transacional (Ponto de avaliação crucial):**
  * Tentar inserir um dado repetido (ou apenas explicar como acontece).
  * *"A documentação exigia controle transacional simples e tratamento de erros. Nós implementamos em toda a aplicação blocos `try/except`. Se o usuário ferir um `CHECK` ou uma `UniqueViolation` (inserir chave já existente), capturamos a exceção pelo `psycopg2`, enviamos um `self.conn.rollback()` para não travar a sessão do PostgreSQL, e alertamos o usuário na tela de forma amigável. Quando dá certo, realizamos o `self.conn.commit()`."*

### 🗣️ Integrante 3: Código-Fonte, Arquitetura e Triggers ⏱️ *4 Minutos*
**Objetivo:** Explicar minuciosamente a infraestrutura, provando que não há "caixas pretas" (como ORMs) e detalhando o uso avançado do PostgreSQL.
* **(7:00 - 8:30) A Arquitetura (Docker):**
  * *"Para garantir a reprodutibilidade, empacotamos tudo em um `docker-compose`. Usamos o PostgreSQL puro e injetamos o esquema e os dados mockados limpos via scripts DDL e DML."*
  * Explicar que o código Python manda **SQL explícito** (sem ORM, respeitando as regras do projeto), e os valores vêm parametrizados (`%s`) para evitar vulnerabilidades de **SQL Injection**.
* **(8:30 - 11:00) Regras de Negócio e Triggers (Diferencial):**
  * Explicar que certas regras não podem ser garantidas pelo DDL básico do modelo relacional.
  * Dar um exemplo de Trigger criado: *"Para garantir a disjunção da especialização, criamos a trigger `validar_disjuncao_auditor()`. Se tentarmos inserir na tabela filha de Auditor um CNPJ que foi classificado como Certificador na classe mãe, o PL/pgSQL levanta uma exception e aborta a operação."*
  * Citar a automação do cálculo do atributo derivado (Duração), que atualiza automaticamente o valor sempre que a data de fim ou de início mudar.

### 🗣️ Integrante 4: Consultas (DQL) ⏱️ *4 Minutos*
**Objetivo:** Apresentar a força matriz do projeto. Falar rapidamente das 6, mas focar em explicar minuciosamente as 3 mais difíceis (incluindo a Divisão Relacional, que é obrigatória).
* **(11:00 - 12:30) Divisão Relacional (Consulta C5 - Obrigatória):**
  * *"Temos 6 consultas gerenciais. A C5 atende o requisito de divisão relacional. O objetivo é buscar os Originadores que tiveram atividades aprovadas por **TODAS** as Certificadoras ativas."*
  * Mostrar o trecho do SQL. Explicar: *"Traduzimos o quantificador universal com um `NOT EXISTS` aninhado. Retornamos o originador para o qual NÃO EXISTE certificadora ativa da qual NÃO EXISTA um laudo assinado por ela para ele. Isso barra a fraude cruzada."*
* **(12:30 - 14:00) Consultas Correlacionadas e Janelas:**
  * Explicar a consulta **C4 (Evolução de Preço)**: *"Nós usamos a Window Function `LAG() OVER(PARTITION BY Lote ORDER BY Data)` para comparar o preço atual de um Lote com o mês anterior na mesma linha sem fazer um auto-JOIN, melhorando a eficiência computacional."*
  * Explicar a consulta **C6 (Proprietário Atual)**: *"Usamos uma subconsulta correlacionada com `COALESCE`. O dono do lote é o último comprador da cadeia. Se ele não possui transações ainda, o `COALESCE` faz o fallback (recuo) automático e infere que o dono atual é o originador que gerou o crédito."*
* **(14:00 - 15:00) Fechamento:**
  * Encerramento rápido: *"Esse projeto evidenciou o abismo entre o modelo conceitual e o que o modelo relacional garante nativamente. O uso das triggers e controle transacional no Python preencheram essas lacunas. Obrigado, estamos abertos a dúvidas."*

---

## 🚨 Preparação para as Perguntas (10 Minutos do Monitor/Professora)
Estejam preparados para estas possíveis perguntas da banca:

1. **"Por que não juntar Auditor e Certificador em uma mesma tabela?"**
   * *Resposta:* Por ser uma especialização disjunta, ambas as funções têm atributos exclusivos. O Auditor possui um "Registro de Acreditação", já o Certificador possui um "Padrão de Certificação". Se os juntássemos, o banco ficaria cheio de espaços nulos (`NULL`) e perderíamos a normalização.
2. **"Como vocês garantiram a segurança contra SQL Injection no Python?"**
   * *Resposta:* Evitamos a concatenação de strings direta no código (ex: `f"INSERT INTO tabela VALUES ({valor})"`). Usamos passagem de parâmetros do próprio `psycopg2` com o placeholder `%s`, passando os valores por tuplas no `execute()`. Isso trata a entrada e limpa as aspas perigosas automaticamente.
3. **"Por que um lote tem N transações se ele só pode pertencer a 1 dono naquele momento?"**
   * *Resposta:* O Lote de Carbono é um ativo financeiro. A nossa tabela `Transacao` é a nota fiscal. Ao longo de 5 anos, um crédito pode ser vendido e revendido dezenas de vezes. O relacionamento M:N guarda a *rastreabilidade de todas as mãos pelas quais o lote passou*. O dono "atual" inferido é sempre o da transação mais recente.
4. **"Expliquem o `ON DELETE CASCADE` de vocês."**
   * *Resposta:* Se deletarmos o CNPJ da superclasse Pessoa Jurídica, o "CASCADE" propagará a exclusão para os atributos multivalorados (Endereço) e paras as subclasses (Originador/Comprador), garantindo que não fiquem tabelas "órfãs" flutuando no banco.
