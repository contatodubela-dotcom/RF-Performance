-- RF Performance — H2B
-- Restringe UPDATE de organization_members por Diretor aos alvos
-- supervisor e salesperson da própria organização.
--
-- Segurança:
-- - platform_admin mantém a policy própria e não é reduzido por esta migration.
-- - Diretor não pode atualizar linhas cujo papel seja director.
-- - guard_membership_update continua impedindo alteração de organization_id,
--   user_id e role por não-admin.
-- - guard_hierarchy_membership_lifecycle continua protegendo vínculos ativos.

begin;

drop policy if exists organization_members_update_director
on public.organization_members;

create policy organization_members_update_director
on public.organization_members
for update
to authenticated
using (
  private.has_org_role(organization_id, array['director'])
  and role in ('supervisor', 'salesperson')
)
with check (
  private.has_org_role(organization_id, array['director'])
  and role in ('supervisor', 'salesperson')
);

commit;
