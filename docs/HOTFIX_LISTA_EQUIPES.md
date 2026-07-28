# Hotfix — listagem de equipes

## Sintoma

O painel inicial contabiliza três equipes, mas a tela `/app/equipes` exibe
“Nenhuma equipe criada”.

## Causa

A consulta da tela usava um relacionamento PostgREST com o identificador
`supervisor_member_id`. No banco, o vínculo entre `teams` e
`organization_members` é uma chave estrangeira composta denominada
`teams_supervisor_org_fkey`.

A consulta falhava, mas a interface tratava a ausência de dados como lista
vazia e não exibia o erro.

## Correção

- usa os nomes reais das três chaves estrangeiras compostas;
- limita a consulta à organização ativa, inclusive para `platform_admin`;
- exclui equipes arquivadas;
- diferencia erro de consulta de uma lista realmente vazia;
- preserva o template e os dados já aplicados no banco.

## Banco

Nenhuma migration nova é necessária. As três equipes já existem no Supabase.
