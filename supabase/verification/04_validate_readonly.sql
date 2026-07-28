-- RF Performance Comercial — Validação pós-migration somente leitura

-- 1. Tabelas e RLS
select
  c.relname as table_name,
  c.relrowsecurity as rls_enabled,
  c.relforcerowsecurity as force_rls
from pg_catalog.pg_class c
join pg_catalog.pg_namespace n on n.oid = c.relnamespace
where n.nspname = 'public'
  and c.relname in (
    'profiles', 'organizations', 'organization_members', 'operations',
    'sales_locations', 'teams', 'team_members', 'audit_logs'
  )
order by c.relname;

-- Esperado: 8 linhas, todas com rls_enabled = true.

-- 2. Policies
select
  schemaname,
  tablename,
  policyname,
  roles,
  cmd
from pg_catalog.pg_policies
where schemaname = 'public'
  and tablename in (
    'profiles', 'organizations', 'organization_members', 'operations',
    'sales_locations', 'teams', 'team_members', 'audit_logs'
  )
order by tablename, policyname;

-- 3. Dados iniciais
select id, trade_name, slug, status, source_system
from public.organizations
where slug = 'rf-consorcios';

select id, organization_id, name, slug, operation_type, status
from public.operations
where slug = 'consorcio-automoveis';

select id, organization_id, operation_id, name, slug, status, metadata
from public.sales_locations
where organization_id = '414a2e84-bc62-4c64-99ee-76db1cbc4654'
order by slug;

-- Esperado: 1 organização, 1 operação e 3 PDVs.

-- 4. Funções privadas críticas
select
  n.nspname as schema_name,
  p.proname as function_name,
  p.prosecdef as security_definer
from pg_catalog.pg_proc p
join pg_catalog.pg_namespace n on n.oid = p.pronamespace
where n.nspname = 'private'
order by p.proname;

-- 5. Triggers nas tabelas de negócio e auth.users
select
  event_object_schema,
  event_object_table,
  trigger_name,
  action_timing,
  event_manipulation
from information_schema.triggers
where event_object_schema in ('public', 'auth')
  and (
    event_object_table in (
      'profiles', 'organizations', 'organization_members', 'operations',
      'sales_locations', 'teams', 'team_members'
    )
    or trigger_name = 'auth_users_sync_profile'
  )
order by event_object_schema, event_object_table, trigger_name, event_manipulation;

-- 6. Nenhum grant direto para anon nas tabelas internas
select
  grantee,
  table_schema,
  table_name,
  privilege_type
from information_schema.role_table_grants
where grantee = 'anon'
  and table_schema = 'public'
  and table_name in (
    'profiles', 'organizations', 'organization_members', 'operations',
    'sales_locations', 'teams', 'team_members', 'audit_logs'
  )
order by table_name, privilege_type;

-- Esperado: 0 linhas.
