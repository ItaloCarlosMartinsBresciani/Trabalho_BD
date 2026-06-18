# Justificativas e Notas do Mapeamento MER-Relacional

## 1. Justificativas de Mapeamento

### **Justificativa 1 (J1): Estrutura de Pessoa Jurídica**
Optamos pela criação de uma tabela **Pessoa Jurídica** e uma tabela para cada subclasse dela, sendo o **CNPJ** a chave estrangeira (FK) das tabelas da subclasse. 

* **Por que não mapear apenas as subclasses?** Evitaríamos o custo de *JOINs*, entretanto, para mapear o atributo multivalorado `ENDEREÇO`, teríamos que criar duas tabelas independentes (uma referenciando agentes de mercado e outra de conformidade), gerando redundância estrutural e dificultando consultas globais.
* **Por que não criar uma única tabela "Pezão"?** Uma tabela única com discriminador (ex: `Tipo_PJ`) resultaria em muitos valores `NULL` devido aos atributos específicos de cada subclasse. Além disso, a regra de negócio separa estritamente os papéis de conformidade e mercado, o que geraria confusão semântica.

### **Justificativa 2 (J2): Atributo Endereço**
O `Endereço` é um atributo composto e multivalorado, permitindo o cadastro de sede e filiais para a mesma Pessoa Jurídica. 
* **Solução:** A única opção estrutural correta é criar uma nova relação `Endereço` que recebe os componentes simples (logradouro, etc.) e a chave primária da relação proprietária (**CNPJ**).
* **Chave Primária (PK):** A PK desta nova tabela é a combinação de `(CNPJ, CEP, Estado, Rua)`.

### **Justificativa 3 (J3): Especialização de Agente de Mercado**
Optamos por não incluir o atributo `Tipo` na superclasse **Agente de Mercado**. Em vez disso, criamos uma nova tabela exclusiva para identificar a quais subtipos o agente pertence, mapeando as subclasses em tabelas distintas (**Originador** e **Comprador**).

* **Vantagem:** Otimização de consultas de perfil. Como a especialização é **sobreposta**, o sistema identifica rapidamente todos os papéis de um agente sem varrer ou realizar múltiplos *JOINs* em todas as tabelas de subclasses.
* **Desvantagem:** Fragmentação estrutural. Para recuperar os dados completos, o SGBD executará mais *JOINs* cruzando `Pessoa Juridica`, `Agente de Mercado`, `Tipo Agente Mercado` e as tabelas específicas.
* **Observação:** Esta abordagem não garante nativamente a especialização total via DDL simples.

### **Justificativa 4 (J4): O relacionamento Realiza entre o lado "1" (Originador) ao lado "N" (Atividade)**
Optamos por Escolher a relação do lado "N" e incluir nela  a chave primária da relação do lado "1" como uma Chave Estrangeira (FK).

* Ao usar a técnica de chave estrangeira, o banco fica otimizado e atende 
perfeitamente ao requisito de que "cada instância de entidade no lado N está 
relacionada a, no máximo, uma instância de entidade no lado 1
* A adoção da alternativa de Referência Cruzada (criação de uma tabela de ligação, ex: 'Realiza Atividade') é desencorajada para relacionamentos 1:N, pois cria uma relação extra de forma desnecessária, obrigando o banco de dados a realizar operações custosas de EQUIJUNÇÃO (JOIN) a mais apenas para descobrir quem é o dono de uma atividade.

### **Justificativa 5 (J5): O Mapeamento Múltiplo de de Relacionamentos 1:N na tabela Atividade**

Em vez de criar tabelas separadas para os relacionamentos Realiza, Contém e Audita, optou-se pela Técnica de Chave Estrangeira. A tabela ATIVIDADE (que representa o lado "N" de todos esses relacionamentos) absorveu as chaves estrangeiras do Originador, do Projeto e do Auditor. As justificativas para essa escolha se assemelham ao raciocínio da Justificativa 4, mas com um agravante: a criação de tabelas de ligação para cada relacionamento 1:N (ex: 'Realiza Atividade', 'Contém Atividade', 'Audita Atividade') não apenas introduz uma relação extra, mas também fragmenta a estrutura do banco, tornando as consultas mais complexas e menos performáticas.

### **Justificativa 7 (J7): Relacionamento Gera (1:1) entre Atividade e Lote**

O relacionamento Gera foi mapeado pela Técnica de Chave Estrangeira, inserindo o atributo Atividade com restrições UNIQUE e NOT NULL dentro da tabela LOTE. A FK foi posicionada em LOTE (e não em ATIVIDADE) pois todo Lote necessariamente deriva de uma Atividade, enquanto uma Atividade pode ainda não ter gerado nenhum Lote: expressar isso com NOT NULL em LOTE é semanticamente mais preciso do que conviver com valores nulos do lado oposto. A restrição UNIQUE é o elemento central do mapeamento, pois transforma uma FK comum (que naturalmente expressaria uma cardinalidade 1:N) em uma FK que impõe o 1:1 diretamente no DDL, sem necessidade de triggers ou lógica de aplicação. A criação de uma tabela de ligação intermediária foi descartada pelos mesmos motivos da Justificativa 4: para relacionamentos 1:1 e 1:N, essa alternativa introduz um JOIN extra sem representar qualquer informação adicional.

### **Justificativa 8 (J8): Especialização de Agente de Conformidade**

Optou-se por criar uma tabela AGENTE_CONFORMIDADE para a superclasse e tabelas distintas para cada subclasse, AUDITOR e CERTIFICADOR, com seus atributos específicos. O CNPJ é a chave primária de todas as tabelas e a FK das subclasses referencia sempre AGENTE_CONFORMIDADE. O atributo Atribuição, presente na tabela AGENTE_CONFORMIDADE, funciona como discriminador do tipo do agente, indicando se ele é Auditor ou Certificador, o que permite identificar a subclasse correspondente sem a necessidade de consultar as tabelas de subclasse diretamente. Diferentemente do mapeamento adotado para Agente de Mercado (J3), não foi criada uma tabela auxiliar de tipo, pois a especialização aqui é disjunta: cada agente pertence a exatamente uma subclasse, tornando desnecessário o controle de múltiplos papéis simultâneos. A desvantagem dessa abordagem é que, para recuperar o perfil completo de um agente, o SGBD precisará cruzar AGENTE_CONFORMIDADE com a tabela da subclasse correspondente. No entanto, o modelo relacional sozinho não garante nativamente nem a disjunção nem a totalidade da especialização, conforme tratado nas notas abaixo.

### **Justificativa 9 (J9): Relacionamento N:N Transação-Lote**

O relacionamento entre Transação e Lote foi mapeado via tabela intermediária (`Transação_Lote`) devido à sua natureza Muitos-para-Muitos. Um Lote pode ser objeto de múltiplas transações ao longo de seu ciclo de vida (vendas sucessivas entre agentes), e uma única Transação (nota fiscal) pode englobar um conjunto de diferentes Lotes.

Duas alternativas foram consideradas e descartadas. A primeira seria inserir uma FK de Transação diretamente na tabela `LOTE`: isso limitaria cada Lote a uma única transação, tornando impossível registrar o histórico de vendas sucessivas do ativo e destruindo a rastreabilidade do ciclo de vida. A segunda alternativa seria inserir uma FK de Lote diretamente na tabela `TRANSACAO`: isso restringiria cada nota fiscal a um único Lote, impedindo que uma negociação envolva múltiplos ativos simultaneamente, o que contraria diretamente a regra de negócio. A criação da tabela intermediária é, portanto, a única solução estruturalmente correta para essa cardinalidade, pois preserva ambas as direções do relacionamento sem redundância.

### **Justificativa 10 (J10): Atributo Derivado Duração**

Optou-se por manter o atributo `Duração` fisicamente nas tabelas `PROJETO` e `ATIVIDADE`, ainda que seja derivado das datas de início e fim.

Duas alternativas foram consideradas. A primeira seria **não armazenar o atributo**, calculando-o sempre em tempo de execução via expressão SQL (`Data_Fim - Data_Inicio`) a cada consulta. Essa abordagem elimina qualquer risco de inconsistência, mas impõe um custo computacional recorrente em consultas de auditoria que varrem grandes volumes de registros,  exatamente o caso de uso mais frequente do sistema. A segunda alternativa seria utilizar uma **coluna gerada**, recurso suportado pelo PostgreSQL, que manteria o valor atualizado automaticamente pelo SGBD sem intervenção de *triggers* ou aplicação. Embora tecnicamente elegante, essa solução introduz dependência de uma funcionalidade específica do SGBD, reduzindo a portabilidade do esquema.

Optou-se pela persistência física do atributo por oferecer o melhor equilíbrio entre desempenho de leitura e simplicidade de implementação, dado que a `Duração` é determinada no cadastro e permanece estável enquanto as datas não forem alteradas. A consistência do valor é garantida por *triggers* ou pela camada de aplicação, conforme detalhado na Nota N11.


---

## 2. Notas Técnicas de Implementação

| Nota | Assunto | Descrição |
| :--- | :--- | :--- |
| **N1** | **Integridade Referencial** | CNPJs em subclasses e endereços são Chaves Estrangeiras (FK). Aplica-se `ON DELETE CASCADE` para que a exclusão da Pessoa Jurídica remova automaticamente seus endereços e especializações. |
| **N2** | **Restrição de Domínio** | O campo `Status` da Pessoa Jurídica deve ter domínio restrito aos valores `'Apto'` e `'Inapto'` via cláusula `CHECK`. |
| **N3** | **Especialização** | Para garantir totalidade e disjunção (visto que o SGBD não impõe isso nativamente), devem ser utilizadas **Triggers** ou lógica de aplicação para validar se o CNPJ respeita as regras de negócio. |
| **N4** | **Propagação de Exclusão** | Como o CNPJ nas tabelas `ORIGINADOR`, `COMPRADOR` e `TIPO_AGENTE_MERCADO` referencia o `Agente de Mercado`, configura-se `ON DELETE CASCADE`. A exclusão do Agente Central propaga para categorias e papéis, evitando registros órfãos ("fantasmas"). |
| **N5** | **Sincronização de Identidade** | O Modelo Relacional sozinho não consegue garantir que os valores gravados na nova tabela `TIPO_AGENTE_MERCADO` sejam um reflexo real da existência da entidade nas tabelas de subclasse. Portanto, é necessário implementar uma camada de aplicação ou triggers para assegurar que a inserção de um agente de mercado em `ORIGINADOR` ou `COMPRADOR` seja refletida corretamente em `TIPO_AGENTE_MERCADO`, e vice-versa.|
| **N6** | **Integridade Referencial** | Como adotamos a Técnica de Chave Estrangeira, o valor do campo Originador na tabela ATIVIDADE deve apontar obrigatoriamente para um CNPJ existente e válido na tabela ORIGINADOR. Para este relacionamento, a configuração ideal da DDL é o uso do gatilho ON DELETE RESTRICT. Logo, se um Originador já realizou atividades no campo, o cadastro dessa empresa não pode ser excluído do sistema, pois isso destruiria a rastreabilidade do projeto de mitigação ambiental.|
| **N7** | **Ciclo de Vida da Auditoria** |  Como a Atividade é cadastrada primeiro e o Auditor só é contratado no futuro para fiscalizá-la, a coluna Auditor na tabela ATIVIDADE deve nascer com o valor NULL e ser atualizada (UPDATE) posteriormente. O sistema (aplicação) é quem deverá validar se a atividade já possui um Auditor preenchido 
antes de permitir a emissão do seu respectivo Laudo.
| **N8** | **Garantia de Disjunção** | A disjunção é parcialmente garantida via DDL pela cláusula `CHECK` sobre o atributo `Atribuição`, restringindo seus valores a `'Auditor'` ou `'Certificador'`. Para reforçar a consistência, deve-se implementar uma **trigger BEFORE INSERT** em AUDITOR e CERTIFICADOR que verifique se o valor de `Atribuição` em AGENTE\_CONFORMIDADE corresponde à subclasse sendo inserida, abortando a operação caso haja divergência. Isso impede, por exemplo, que um CNPJ com `Atribuição = 'Certificador'` seja inserido na tabela AUDITOR. |
| **N9** | **Garantia de Totalidade** | A totalidade não é garantida pelo DDL. Para impô-la, a camada de aplicação deve assegurar que toda inserção em AGENTE\_CONFORMIDADE seja acompanhada, na mesma transação, da inserção do respectivo registro em AUDITOR ou CERTIFICADOR conforme o valor de `Atribuição`. Dessa forma, nunca existirá um Agente de Conformidade sem subclasse correspondente. |
| **N10** | **Integridade Temporal** | Tanto a tabela PROJETO quanto a tabela ATIVIDADE possuem os atributos `Data Início` e `Data Fim`. Para garantir que `Data Fim` nunca seja anterior a `Data Início`, deve-se aplicar a cláusula `CHECK (Data_Fim >= Data_Inicio)` no DDL de ambas as tabelas. Essa restrição é suportada nativamente pelos principais SGBDs relacionais e será verificada automaticamente em toda operação de `INSERT` ou `UPDATE`, dispensando validação exclusiva na camada de aplicação. Recomenda-se, no entanto, que a aplicação também valide essa regra antes de submeter a operação ao banco, oferecendo uma mensagem de erro mais amigável ao usuário. |
| **N11** | **Cálculo de Atributo Derivado** | Para garantir a consistência do atributo `Duração` (mapeado fisicamente conforme J10), a implementação deve assegurar que seu valor seja sempre o reflexo fiel da diferença entre `Data Fim` e `Data Início`. Essa integridade deve ser mantida preferencialmente via **Triggers** (`BEFORE INSERT OR UPDATE`) no SGBD, que automatizam o recálculo sempre que houver alteração nas datas, ou através de lógica mandatória na camada de **Aplicação** antes da persistência. Isso evita que o banco armazene valores obsoletos ou divergentes das datas balizadoras caso uma atualização ocorra apenas parcialmente. |



