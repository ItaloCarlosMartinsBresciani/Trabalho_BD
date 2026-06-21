# Checklist Rigoroso - Entrega Parte 3 (Relatório e Código)

Baseado nos requisitos do documento `Projeto_Sustentabilidade_e_Gestao_de_Recursos.md`.

## 1. O que precisa ir para o Novo Relatório Final (PDF)
Vocês devem criar um arquivo final (ex: `relatorio_Parte3_Final.pdf`) que seja um aglomerado de todo o trabalho, contendo:

- [ ] **Inclusão da Parte 1 e 2:** Coloquem a Modelagem (MER e Descrição) e o Projeto Lógico das entregas anteriores. **Atenção:** Se o monitor descontou nota nas entregas 1 e 2, vocês **precisam** colocar a versão corrigida neste arquivo final e deixar claro/indicado o que foi arrumado. Se entregarem com os mesmos erros passados, a nota é descontada em dobro (está faltando corrigir os erros apontados na parte 2 em entregaveis_contexto/nossos_relatorios/2_entrega/correcao-monitor-comentarios.md).
- [ ] **Justificativas e Contexto das Consultas:** As 5 ou 6 consultas presentes em `consultas.sql` **precisam ser explicadas no relatório**. Copiem o que vocês têm no `explicacao_consultas.txt` para o PDF. É exigência justificar por que essa consulta é útil no contexto do negócio (CarbonTrack).
- [ ] **Descrição do Sistema (Nova Seção):** Criar um texto explicando o sistema que vocês implementaram no Python:
  - Informar o SGBD utilizado (PostgreSQL) e a linguagem (Python / Tkinter / psycopg2).
  - Descrever os requisitos do sistema (ex: "O aplicativo permite cadastrar projetos/atividades e realizar buscas no banco de forma interativa...").
- [ ] **Trechos de Código SQL no Relatório:** Vocês precisam colar no PDF os blocos de código SQL das operações implementadas no sistema. Para cada bloco, é obrigatório ter 3 coisas:
  1. O código SQL em si (o `INSERT INTO...` e o `SELECT...` que estão dentro do Python).
  2. Descrição sucinta do que ele faz.
  3. A **localização exata** (ex: *"Implementado no arquivo `codigo_sistema-aplicacao/app.py`, dentro do método/função `cadastrar_atividade()`"*).
- [ ] **Conclusão / Análise Crítica (FATOR DE ZERAMENTO):** Adicionar uma página ou seção final de Conclusão contendo obrigatoriamente:
  - As maiores dificuldades do grupo no projeto inteiro.
  - O que vocês aprenderam.
  - Críticas e sugestões para melhorar a disciplina no semestre que vem.
  - *Nota do corretor:* O pdf diz explicitamente que a ausência deste item zera esse tópico de avaliação. Não esqueçam!

---

## 2. Pontos de Atenção no Código e Arquivos
A nível de arquivos e código, as coisas parecem encaminhadas, mas verifiquem os seguintes itens antes de empacotar:

- [ ] **Controle Transacional Simples no Aplicativo:** O documento pede "controle transacional simples em casos de erros". Verifiquem no `app.py`, na parte onde ocorre o **Cadastro (INSERT)**, se vocês estão usando um bloco `try / except`. Deve haver um `conexao.commit()` se tudo der certo, e obrigatoriamente um `conexao.rollback()` no bloco de `except` caso dê erro de banco (como chave primária duplicada). Isso garante que o banco não trave por transações pendentes.
- [ ] **Limpeza da Pasta de Submissão:** Na hora de enviar os "Códigos-fonte", certifiquem-se de mandar a estrutura limpa. Enviem a pasta `scripts_sql` com o `esquema.sql`, `dados.sql` (garantam que todas as tabelas têm no mínimo 2 linhas inseridas) e `consultas.sql`, junto com a pasta do aplicativo e o PDF do relatório.