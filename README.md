# Trabalho_BD

## Estrutura do repositório

- `docker-compose.yml`: arquivo de configuração do ambiente Docker contendo o banco de dados PostgreSQL e a interface pgAdmin.
- `README.md`: descrição geral do repositório.
- `scripts_sql/`: pasta contendo os scripts SQL:
  - `esquema.sql`: criação das tabelas (DDL).
  - `triggers.sql`: regras de negócio, validações automáticas e gatilhos.
  - `dados.sql`: inserção dos dados mockados (DML).
  - `consultas.sql`: relatórios e queries do sistema (DQL).
  - Explicações e resumos complementares.
- `entregaveis_contexto/`: pasta que agrupa os documentos contextuais e relatórios de entregas do projeto.
  - `links_importantes.txt`: lista de links úteis para o trabalho.
  - `nossos_relatorios/`: relatórios da 1ª entrega (com feedback) e da 2ª entrega (em andamento).
    - `1_entrega/`: materiais da primeira entrega.
    - `2_entrega/`: materiais da segunda entrega (contendo histórico de correções, justificativas de mapeamento, imagem do modelo relacional, etc.).
  - `pdf's_base/`: arquivos fornecidos para guiar o trabalho.
    - `projetos_antigos/`: exemplos de projetos de turmas anteriores.

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

### 2. Injetando a estrutura, as regras e os dados (Scripts SQL)
Com o banco rodando e inicializado, você deve injetar os scripts na ordem correta: primeiro as tabelas, depois as regras (triggers) e por fim os dados. Rode os comandos abaixo no terminal, um por vez:

**1. Criando as tabelas (Esquema):**
```bash
docker exec -i trabalho_bd_postgres psql -U rapazinhos -d CarbonTrack < ./scripts_sql/esquema.sql
```

**2. Criando as regras de negócio automáticas (Triggers):**
```bash
docker exec -i trabalho_bd_postgres psql -U rapazinhos -d CarbonTrack < ./scripts_sql/triggers.sql
```

**3. Inserindo os dados (Mock):**
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
3. No menu lateral esquerdo, clique com o **botão direito** em cima de **Servers** (Servidores), vá em **Register** (Registrar) e clique em **Server...**. Na janelinha que abrir, configure a conexão da seguinte forma:
   - **Aba General > Name:** "CarbonTrack DB" (ou outro nome de sua preferência)
   - **Aba Connection:**
     - **Host name/address:** `postgres_db` (o próprio docker resolve esse nome do serviço pra nós!)
     - **Port:** `5432`
     - **Maintenance database:** `CarbonTrack`
     - **Username:** `rapazinhos`
     - **Password:** `1234`
     - *(Recomendado marcar a caixinha "Save password" para não precisar digitar novamente)*
4. Clique em **Save**.
5. Agora que o servidor está registrado e conectado, para **visualizar as tabelas** basta navegar pelo menu esquerdo expandindo as seguintes opções em ordem: `Servers` > `CarbonTrack DB` > `Databases` > `CarbonTrack` > `Schemas` > `public` > `Tables`.

**Como rodar as queries (consultas) do relatório:**
1. No menu esquerdo do pgAdmin, expanda os nós do seu novo servidor "CarbonTrack DB", expanda a aba "Databases", clique com o botão direito sobre o banco `CarbonTrack` e selecione a opção **Query Tool** (Ferramenta de Consulta).
2. Abra no seu computador local o nosso arquivo `scripts_sql/consultas.sql`.
3. Lá existem 6 consultas complexas separadas (C1 a C6). Copie o bloco de código de **uma consulta por vez** (por exemplo, a C1 que faz Rastreabilidade Completa).
4. Cole o código copiado na área de texto em branco na parte superior da aba *Query Tool*.
5. Aperte o botão de **Play (Execute/Refresh)** que tem um ícone de triângulo na barra de tarefas da janela (ou apenas aperte a tecla **F5** no seu teclado).
6. Os resultados aparecerão instantaneamente na aba inferior chamada *Data Output*, exibindo a tabela formatada com os dados. (Excelente para tirar prints pro relatório da Parte 3!).

---

## Como executar a Interface Gráfica (App Desktop)

O projeto possui um protótipo de interface gráfica desenvolvido em Python localizado na pasta `codigo_sistema/`. Para rodá-lo, você precisará configurar o seu ambiente local:

### 1. Dependências do Sistema Operacional (Linux/Ubuntu)
A interface utiliza a biblioteca nativa `tkinter`. No Linux, é obrigatório instalar o pacote do sistema para que as janelas funcionem:
```bash
sudo apt-get update
sudo apt-get install -y python3-tk
```

### 2. Dependências do Python (Ambiente Virtual)
Ative a sua `venv` (ou crie uma) e certifique-se de que o driver de conexão com o PostgreSQL está instalado:
```bash
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
```
*(O arquivo `requirements.txt` já contém a dependência necessária `psycopg2-binary`).*

### 3. Executando o Aplicativo
Com os containers do Docker de banco de dados rodando (Passo 1 do tópico anterior), execute o script principal:
```bash
python codigo_sistema/app.py
```
Na tela inicial que irá se abrir, preencha as credenciais do banco para acessar o sistema:
- **Usuário:** `rapazinhos`
- **Senha:** `1234`
- **Banco:** `CarbonTrack`

---

### Comandos Úteis do Docker
- **Pausar** o ambiente (sem perder dados): `docker-compose stop` ou `docker compose stop` se o primeiro não rodar devido a versão do Docker.
- **Retomar** ambiente pausado: `docker-compose start` ou `docker compose start`.
- **Derrubar** o ambiente (dados da sessão são mantidos nos volumes de disco): `docker-compose down` ou `docker compose down`.
- **Reset Completo (Cuidado!):** Apagar os containers e **todos os dados** e configurações do banco (útil se errar a estrutura ou duplicar os dados e precisar recomeçar limpo do zero): `docker-compose down -v` ou `docker compose down -v`.