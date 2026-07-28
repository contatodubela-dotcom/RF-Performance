# RF Performance Comercial — Fundação do schema v1

Este pacote contém três migrations versionadas e duas consultas de verificação.

## Arquivos

- `20260727203000_foundation_schema.sql`: tabelas, constraints, índices, triggers, auditoria e sincronização com `auth.users`.
- `20260727204000_rls_policies.sql`: funções privadas de autorização, grants e policies RLS.
- `20260727205000_initial_data.sql`: RF Consórcios, Consórcio de Automóveis e os três PDVs provisórios.
- `00_precheck_readonly.sql`: confirma que não existem relações conflitantes.
- `04_validate_readonly.sql`: valida tabelas, RLS, policies, funções, triggers, grants e seed.

## Sequência segura

1. Extraia o pacote na raiz do projeto.
2. Confirme que os três `.sql` ficaram em `supabase/migrations/`.
3. Execute `00_precheck_readonly.sql` no SQL Editor; deve retornar 0 linhas.
4. Execute `npx supabase migration list`.
5. Execute `npx supabase db push --dry-run`.
6. Revise a lista das três migrations.
7. Somente após autorização explícita, execute `npx supabase db push`.
8. Execute `04_validate_readonly.sql` no SQL Editor.

## Observações

- Nenhum usuário ou dado comercial fictício é criado.
- O primeiro `platform_admin` será promovido manualmente após a criação do usuário no Supabase Auth.
- Inserts de `organization_members` serão feitos futuramente por Edge Function segura.
- Não use `db reset --linked`.
