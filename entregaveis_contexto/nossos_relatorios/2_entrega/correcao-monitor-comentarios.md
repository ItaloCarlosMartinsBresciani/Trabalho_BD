[Observações no MODELO RELACIONAL]: talvez seja interessante pensar na possibilidade de adicionar mais algumas restrições de not null. por ex: faz sentido o sistema permitir o cadastro de um projeto sem nome? quais outros atributos podem ser not null? o mesmo vale para os demais atributos de critério das generalizações totais.

Correções feitas por nós em relação a essa observação no modelo relacional:
- Na tabela `Projeto`, o atributo `Nome_Projeto` foi alterado para `NOT NULL` assim como `Data_Inicio` porque todo projeto precisa ter um início previsto.
- Na tabela `Transacao`, o atributo `valor` foi alterado para `NOT NULL`.
- Na tabela `Pessoa_Juridica`, o atributo `Funcao` foi alterado para `NOT NULL` assim como todos os atributos por se tratar de uma tabela mãe de várias entidades, o que garante mais detalhamento das empresas/corporações envolvidas.
- Na tabela `Agente_Conformidade`, o atributo `Atribuicao` foi alterado para `NOT NULL` para garantir que cada agente de conformidade tenha uma atribuição definida.
- Na tabela `Atividade`, o atributo `Data_Inicio` foi alterado para `NOT NULL` para garantir que toda atividade tenha uma data de início prevista.
- Na tabela `Lote`, o atributo `Status_Ciclo_de_Vida` foi alterado para `NOT NULL` para garantir que todo lote tenha um status definido  (`disponível`, `aposentado`, `invalidado`).
- Na tabela `Laudo`, o atributo `Certificador` foi alterado para `NOT NULL` para garantir que todo laudo tenha um certificador definido.

[Observação na justificativa J2] "...a única solução estruturalmente correta..." é uma afirmação muito drástica

[Observação na Justificativa J3] "...permite identificar rapidamente todos os papéis.."  mas precisa fazer operações de junção pra identificar os papeis.

[Observação na Justificativa J4] "... requisito de que cada Atividade está vinculada a, no máximo, um
Originador..."  E no mínimo a 1 também (faltou comentar sobre a totalidade, isto é, sobre que toda ocorrência de atividade precisa estar associada a pelo menos um Originador).

[Observação na Justificativa J5] aqui também poderia ter comentado sobre as totalidades (Projeto precisa estar vinculado a atividade porque tem participação total assim como Atividade precisa estar associado a originador).