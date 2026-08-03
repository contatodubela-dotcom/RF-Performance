begin;

-- Fase 2 do hardening:
-- remove as policies amplas de compatibilidade somente depois de:
-- 1) as RPCs seguras existirem e estarem protegidas;
-- 2) a versão compatível do frontend estar publicada e validada em produção;
-- 3) as policies de liderança permanecerem ativas.
do $guard$
declare
  v_commercial_plans_rls boolean;
  v_management_rituals_rls boolean;
begin
  select c.relrowsecurity
    into v_commercial_plans_rls
  from pg_class c
  join pg_namespace n
    on n.oid = c.relnamespace
  where n.nspname = 'public'
    and c.relname = 'commercial_plans'
    and c.relkind = 'r';

  select c.relrowsecurity
    into v_management_rituals_rls
  from pg_class c
  join pg_namespace n
    on n.oid = c.relnamespace
  where n.nspname = 'public'
    and c.relname = 'management_rituals'
    and c.relkind = 'r';

  if coalesce(v_commercial_plans_rls, false) is not true then
    raise exception 'Hardening abortado: RLS não está ativa em public.commercial_plans.';
  end if;

  if coalesce(v_management_rituals_rls, false) is not true then
    raise exception 'Hardening abortado: RLS não está ativa em public.management_rituals.';
  end if;

  if to_regprocedure('public.get_commercial_plan_reference(uuid)') is null then
    raise exception 'Hardening abortado: RPC public.get_commercial_plan_reference(uuid) ausente.';
  end if;

  if to_regprocedure('public.get_management_rituals_for_current_user(uuid)') is null then
    raise exception 'Hardening abortado: RPC public.get_management_rituals_for_current_user(uuid) ausente.';
  end if;

  if not exists (
    select 1
    from pg_policies
    where schemaname = 'public'
      and tablename = 'commercial_plans'
      and policyname = 'commercial_plans_manage_leadership'
      and cmd = 'ALL'
  ) then
    raise exception 'Hardening abortado: policy de liderança de commercial_plans ausente.';
  end if;

  if not exists (
    select 1
    from pg_policies
    where schemaname = 'public'
      and tablename = 'management_rituals'
      and policyname = 'management_rituals_manage_leadership'
      and cmd = 'ALL'
  ) then
    raise exception 'Hardening abortado: policy de liderança de management_rituals ausente.';
  end if;

  if not (
    select p.prosecdef
    from pg_proc p
    where p.oid = to_regprocedure('public.get_commercial_plan_reference(uuid)')
  ) then
    raise exception 'Hardening abortado: get_commercial_plan_reference não é SECURITY DEFINER.';
  end if;

  if not (
    select p.prosecdef
    from pg_proc p
    where p.oid = to_regprocedure('public.get_management_rituals_for_current_user(uuid)')
  ) then
    raise exception 'Hardening abortado: get_management_rituals_for_current_user não é SECURITY DEFINER.';
  end if;

  if not has_function_privilege(
    'authenticated',
    to_regprocedure('public.get_commercial_plan_reference(uuid)'),
    'EXECUTE'
  ) then
    raise exception 'Hardening abortado: authenticated não executa get_commercial_plan_reference.';
  end if;

  if not has_function_privilege(
    'authenticated',
    to_regprocedure('public.get_management_rituals_for_current_user(uuid)'),
    'EXECUTE'
  ) then
    raise exception 'Hardening abortado: authenticated não executa get_management_rituals_for_current_user.';
  end if;

  if has_function_privilege(
    'anon',
    to_regprocedure('public.get_commercial_plan_reference(uuid)'),
    'EXECUTE'
  ) then
    raise exception 'Hardening abortado: anon ainda executa get_commercial_plan_reference.';
  end if;

  if has_function_privilege(
    'anon',
    to_regprocedure('public.get_management_rituals_for_current_user(uuid)'),
    'EXECUTE'
  ) then
    raise exception 'Hardening abortado: anon ainda executa get_management_rituals_for_current_user.';
  end if;
end;
$guard$;

-- A policy ALL de liderança permanece responsável pelo SELECT direto
-- de administrador da plataforma e diretor.
drop policy if exists commercial_plans_select_members
  on public.commercial_plans;

drop policy if exists management_rituals_select_members
  on public.management_rituals;

commit;
