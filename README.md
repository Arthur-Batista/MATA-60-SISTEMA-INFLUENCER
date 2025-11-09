## Projeto de Banco de Dados - Agenciamento de Influenciadores

Este repositório contém os artefatos do projeto de banco de dados para a disciplina MATA60 (UFBA), focado na modelagem, implantação e otimização de um sistema para agenciamento de influenciadores digitais.

O projeto inclui o Modelo Lógico, scripts DDL para criação da estrutura, DML para população de dados em massa, e um conjunto de consultas analíticas (intermediárias e avançadas) para validação do modelo e testes de desempenho.

#### Tecnologias Utilizadas
- SGBD: PostgreSQL

#### Tecnologias Utilizadas
- ``` / ```:  Contém os principais scripts SQL do projeto.
    - ```ddl_influencers.sql ```: Script DDL (Data Definition Language) para criar o banco de dados e todas as tabelas, constraints e sequências.
    -  ```dml_influencers.sql ```: Script DML (Data Manipulation Language) para popular o banco com dados fictícios (realiza um TRUNCATE antes de inserir).
    - ```querys-intermediarias.sql ```: Contém 10 consultas de nível intermediário.
    - `querys-avancadas.sql`: Contém 20 consultas de nível avançado para análises complexas.
    - `plano_indexacao.sql`: Script DDL para criar (e remover) os índices de otimização utilizados na análise de desempenho.

#### Como Executar o Projeto (Tutorial)

Para recriar o ambiente e executar os testes, siga esta ordem:

- **Passo 1**: Criar o Banco e as Tabelas (DDL)

    Este script cria a estrutura vazia do banco de dados.

    1. Conecte-se a um banco de dados previamente criado.
    2. Execute o script `ddl_influencers.sql`.


- **Passo 2**: Popular o Banco de Dados (DML)
    Este script insere os dados fictícios nas tabelas.

    1. Certifique-se de que você está conectado ao banco SISTEMA_GERENCIADOR_INFLUENCER (Ou outro nome).

    2. Execute o script dml_influencers.sql em sua totalidade.

    *Nota: O script inclui TRUNCATE ... RESTART IDENTITY CASCADE para limpar dados de execuções anteriores antes de inserir os novos.*

- **Passo 3**: Executar Consultas (Baseline de Desempenho)
    Agora, com o banco populado e sem índices, execute as consultas de análise para obter o tempo base (Baseline).

    1. Abra e execute (uma a uma ou todas) as consultas nos arquivos:

        `querys-intermediarias.sql`

        `querys-avancadas.sql`

    2. Para uma análise real, use o *EXPLAIN ANALYZE* antes de cada SELECT.

        Exemplo:
        `EXPLAIN ANALYZE
            SELECT m.nm_razao_social, c.nm_campanha, ...`

- **Passo 4**: Otimizar o Banco (Plano de indexação)
    Com o baseline medido, vamos criar os índices de otimização.

    1. Execute a primeira metade do script `plano_indexacao.sql`.

## AUTORES
 - Arthur Batista dos Santos Borges
 - Tiago Almeida de Oliveira
 - Greice Kelly Araújo Leal
