# Trabalho_BD

## Estrutura do repositório

- `docker-compose.yml`: arquivo de configuração do ambiente Docker contendo o banco de dados PostgreSQL e a interface pgAdmin.
- `links_importantes.txt`: lista de links úteis para o trabalho.
- `README.md`: descrição geral do repositório.
- `texto_descritivo_MER_(desatualizado).md`: texto descritivo do MER (arquivo antigo/desatualizado).
- `scripts_sql/`: pasta contendo os scripts SQL para a criação das tabelas (`esquema.sql`), inserção dos dados (`dados.sql`) e relatórios/queries (`consultas.sql`).
- `nossos_relatorios/`: relatórios da 1a entrega (com feedback) e da 2a entrega (em andamento).
  - `1_entrega/`: materiais da primeira entrega.
  - `2_entrega/`: materiais da segunda entrega.
    - Correções Parte 1 (Mudanças) - Trab.txt: explica as mudanças feitas.
    - Decisoes e vantagens.pdf: documento com justificativas do mapeamento do MER para o Relacional.
    - imagem do modelo relacional
    - V1 do relatório com correções da parte 1, modelo relacional e justificativas e notas do mapeamento.
- `pdf's_base/`: arquivos fornecidos pela professora Elaine que ajudam a guiar o trabalho.
  - `projetos_antigos/`: exemplos e projetos de turmas anteriores.

---

## Como executar o ambiente de Banco de Dados com Docker

Para padronizar o ambiente de desenvolvimento entre os membros do grupo e facilitar os testes da Parte 3 do trabalho, estamos utilizando **Docker**.

### Como funciona a criação da Base de Dados no Docker?
Quando rodamos o comando do Docker Compose, a imagem oficial do PostgreSQL lê as variáveis de ambiente que definimos (`POSTGRES_USER`, `POSTGRES_PASSWORD` e `POSTGRES_DB`). Com base nelas, o próprio Docker já cria um servidor de banco de dados e inicializa um banco vazio chamado `CarbonTrack` vinculado ao usuário `rapazinhos`.
Apenas depois dessa criação limpa (Passo 1) é que usamos os comandos de injeção (Passo 2) para jogar o conteúdo dos nossos arquivos locais `esquema.sql` (que constrói as tabelas) e `dados.sql` (que preenche com informações mockadas) para dentro do container do banco.

---

### Pré-requisitos
Ter o [Docker](https://docs.docker.com/get-docker/) e o [Docker Compose](https://docs.docker.com/compose/install/) instalados na sua máquina.

### 1. Iniciando os containers
Na raiz do repositório (onde fica o arquivo `docker-compose.yml`), abra o terminal e execute:
```bash
docker-compose up -d
```
Isso vai baixar as imagens necessárias e iniciar dois serviços em background:
- **postgres_db**: O nosso banco de dados.
- **pgadmin**: Interface visual gráfica para o banco.

### 2. Injetando a estrutura e os dados (Scripts SQL)
Com o banco rodando e inicializado, você deve injetar os scripts para criar as tabelas e povoar o banco. Rode os seguintes comandos no terminal, um por vez:

**Criando o esquema:**
```bash
docker exec -i trabalho_bd_postgres psql -U rapazinhos -d CarbonTrack < ./scripts_sql/esquema.sql
```

**Inserindo os dados:**
```bash
docker exec -i trabalho_bd_postgres psql -U rapazinhos -d CarbonTrack < ./scripts_sql/dados.sql
```

### 3. Acessando e testando as Consultas (pgAdmin)
O pgAdmin é a nossa interface visual. Ela permite que a gente visualize as tabelas e não precise ficar digitando SQL complexo diretamente no terminal de linha de comando. 

**Configurando o Servidor:**
1. Acesse `http://localhost:5050` no seu navegador.
2. Faça login com as credenciais padrão do pgAdmin:
   - **Email:** `admin@admin.com`
   - **Password:** `admin`
3. Clique em **Add New Server** e configure a conexão da seguinte forma:
   - **Aba General > Name:** "CarbonTrack DB" (ou outro nome de sua preferência)
   - **Aba Connection:**
     - **Host name/address:** `postgres_db` (o próprio docker resolve esse nome do serviço pra nós!)
     - **Port:** `5432`
     - **Maintenance database:** `CarbonTrack`
     - **Username:** `rapazinhos`
     - **Password:** `1234`
4. Clique em **Save**.

**Como rodar as queries (consultas) do relatório:**
1. No menu esquerdo do pgAdmin, expanda os nós do seu novo servidor "CarbonTrack DB", expanda a aba "Databases", clique com o botão direito sobre o banco `CarbonTrack` e selecione a opção **Query Tool** (Ferramenta de Consulta).
2. Abra no seu computador local o nosso arquivo `scripts_sql/consultas.sql`.
3. Lá existem 6 consultas complexas separadas (C1 a C6). Copie o bloco de código de **uma consulta por vez** (por exemplo, a C1 que faz Rastreabilidade Completa).
4. Cole o código copiado na área de texto em branco na parte superior da aba *Query Tool*.
5. Aperte o botão de **Play (Execute/Refresh)** que tem um ícone de triângulo na barra de tarefas da janela (ou apenas aperte a tecla **F5** no seu teclado).
6. Os resultados aparecerão instantaneamente na aba inferior chamada *Data Output*, exibindo a tabela formatada com os dados. (Excelente para tirar prints pro relatório da Parte 3!).

---

### Comandos Úteis do Docker
- **Pausar** o ambiente (sem perder dados): `docker-compose stop`
- **Retomar** ambiente pausado: `docker-compose start`
- **Derrubar** o ambiente (dados da sessão são mantidos nos volumes de disco): `docker-compose down`
- **Reset Completo (Cuidado!):** Apagar os containers e **todos os dados** e configurações do banco (útil se errar a estrutura ou duplicar os dados e precisar recomeçar limpo do zero): `docker-compose down -v`
