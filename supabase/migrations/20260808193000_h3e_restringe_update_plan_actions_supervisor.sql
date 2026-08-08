-- ============================================================================
-- H3E - HARDENING DE UPDATE EM plan_actions
-- Objetivo:
--   alinhar o backend à matriz do frontend:
--   platform_admin + director podem UPDATE; supervisor não pode.
--
-- Escopo:
--   altera somente a policy public.plan_actions_update_management.
--   não altera dados, SELECT, INSERT, DELETE, grants ou FORCE RLS.
-- ============================================================================

begin;

do $h3e_guard$
declare
  v_update_policy_count integer;
  v_policy record;
  v_rls_enabled boolean;
begin
  if to_regclass('public.plan_actions') is null then
    raise exception 'H3E abortada: public.plan_actions não existe.';
  end if;

  select c.relrowsecurity
    into v_rls_enabled
  from pg_catalog.pg_class c
  join pg_catalog.pg_namespace n
    on n.oid = c.relnamespace
  where n.nspname = 'public'
    and c.relname = 'plan_actions';

  if coalesce(v_rls_enabled, false) is not true then
    raise exception 'H3E abortada: RLS não está habilitado em public.plan_actions.';
  end if;

  select count(*)
    into v_update_policy_count
  from pg_catalog.pg_policies
  where schemaname = 'public'
    and tablename = 'plan_actions'
    and cmd = 'UPDATE';

  if v_update_policy_count <> 1 then
    raise exception
      'H3E abortada: esperado exatamente 1 policy UPDATE em public.plan_actions; encontrado %.',
      v_update_policy_count;
  end if;

  select
    policyname,
    permissive,
    roles,
    qual,
    with_check
  into v_policy
  from pg_catalog.pg_policies
  where schemaname = 'public'
    and tablename = 'plan_actions'
    and cmd = 'UPDATE'
    and policyname = 'plan_actions_update_management';

  if not found then
    raise exception 'H3E abortada: policy plan_actions_update_management não encontrada.';
  end if;

  if v_policy.permissive <> 'PERMISSIVE'
     or not ('authenticated' = any(v_policy.roles)) then
    raise exception
      'H3E abortada: policy UPDATE não está no estado esperado (PERMISSIVE/authenticated).';
  end if;

  if lower(coalesce(v_policy.qual, '')) not like '%is_platform_admin%'
     or lower(coalesce(v_policy.qual, '')) not like '%director%'
     or lower(coalesce(v_policy.qual, '')) not like '%supervisor%'
     or lower(coalesce(v_policy.with_check, '')) not like '%is_platform_admin%'
     or lower(coalesce(v_policy.with_check, '')) not like '%director%'
     or lower(coalesce(v_policy.with_check, '')) not like '%supervisor%' then
    raise exception
      'H3E abortada: definição atual da policy UPDATE diverge do preflight esperado.';
  end if;
end
$h3e_guard$;

drop policy plan_actions_update_management
  on public.plan_actions;

create policy plan_actions_update_management
on public.plan_actions
for update
to authenticated
using (
  private.is_platform_admin()
  or private.has_org_role(organization_id, array['director'])
)
with check (
  private.is_platform_admin()
  or private.has_org_role(organization_id, array['director'])
);

commit;
