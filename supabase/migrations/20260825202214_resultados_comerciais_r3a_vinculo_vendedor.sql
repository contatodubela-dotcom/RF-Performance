-- ============================================================================
-- RF Performance Comercial
-- R3A — vínculo transacional do vendedor
-- Data: 2026-08-25
--
-- Objetivos:
--   1) adicionar vendedor à fonte transacional commercial_sales;
--   2) usar organization_members.id como identidade comercial canônica;
--   3) preservar vendas/importações históricas sem vendedor identificado;
--   4) garantir que, quando informado, o membro pertença à mesma organização
--      e tenha papel salesperson;
--   5) não depender do vínculo atual em team_members, preservando histórico;
--   6) preparar índice para apuração por vendedor na R3B.
-- ============================================================================

begin;

-- ============================================================================
-- 1. PREFLIGHT
-- ============================================================================

do $$
begin
  if to_regclass('public.commercial_sales') is null then
    raise exception using
      errcode = '42P01',
      message = 'R3A_ABORT_COMMERCIAL_SALES_NOT_FOUND';
  end if;

  if to_regclass('public.organization_members') is null then
    raise exception using
      errcode = '42P01',
      message = 'R3A_ABORT_ORGANIZATION_MEMBERS_NOT_FOUND';
  end if;

  if exists (
    select 1
    from information_schema.columns
    where table_schema = 'public'
      and table_name = 'commercial_sales'
      and column_name = 'salesperson_member_id'
  ) then
    raise exception using
      errcode = '42701',
      message = 'R3A_ABORT_SALESPERSON_MEMBER_ID_ALREADY_EXISTS';
  end if;
end;
$$;

-- ============================================================================
-- 2. VÍNCULO TRANSACTIONAL DO VENDEDOR
-- ============================================================================

alter table public.commercial_sales
  add column salesperson_member_id uuid;

comment on column public.commercial_sales.salesperson_member_id is
  'Membro vendedor da organização atribuído historicamente à venda. Pode ser NULL para vendas/importações sem identificação individual.';

alter table public.commercial_sales
  add constraint commercial_sales_salesperson_member_org_fkey
  foreign key (
    salesperson_member_id,
    organization_id
  )
  references public.organization_members (
    id,
    organization_id
  )
  on delete restrict;

-- ============================================================================
-- 3. ÍNDICE PARA APURAÇÃO POR VENDEDOR
-- ============================================================================

create index commercial_sales_org_salesperson_competence_status_idx
  on public.commercial_sales (
    organization_id,
    salesperson_member_id,
    competence_month,
    validation_status
  )
  where salesperson_member_id is not null;

-- ============================================================================
-- 4. VALIDAÇÃO SEMÂNTICA DO VENDEDOR
--
-- Deliberadamente NÃO exige:
--   - organization_member atualmente ativo;
--   - vínculo atualmente ativo em team_members;
--   - sale_date entre start_at/end_at.
--
-- Isso preserva vendas históricas, transferências futuras e importações
-- retroativas legítimas.
-- ============================================================================

create or replace function private.validate_commercial_sale_salesperson()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  if new.salesperson_member_id is null then
    return new;
  end if;

  if not exists (
    select 1
    from public.organization_members om
    where om.id = new.salesperson_member_id
      and om.organization_id = new.organization_id
      and om.role = 'salesperson'
  ) then
    raise exception using
      errcode = '23514',
      message = 'O vendedor da venda deve ser um membro com papel salesperson da mesma organização.';
  end if;

  return new;
end;
$$;

revoke all
on function private.validate_commercial_sale_salesperson()
from public, anon, authenticated;

create trigger commercial_sales_validate_salesperson
before insert or update of
  organization_id,
  salesperson_member_id
on public.commercial_sales
for each row
execute function private.validate_commercial_sale_salesperson();

-- ============================================================================
-- 5. PÓS-CHECK ESTRUTURAL
-- ============================================================================

do $$
declare
  v_data_type text;
  v_is_nullable text;
  v_constraint_count integer;
  v_trigger_count integer;
begin
  select
    c.data_type,
    c.is_nullable
  into
    v_data_type,
    v_is_nullable
  from information_schema.columns c
  where c.table_schema = 'public'
    and c.table_name = 'commercial_sales'
    and c.column_name = 'salesperson_member_id';

  if not found then
    raise exception
      'R3A inválida: salesperson_member_id não foi criada.';
  end if;

  if v_data_type <> 'uuid' then
    raise exception
      'R3A inválida: salesperson_member_id não possui tipo uuid.';
  end if;

  if v_is_nullable <> 'YES' then
    raise exception
      'R3A inválida: salesperson_member_id deve permanecer nullable.';
  end if;

  select count(*)
  into v_constraint_count
  from pg_constraint con
  join pg_class c
    on c.oid = con.conrelid
  join pg_namespace n
    on n.oid = c.relnamespace
  where n.nspname = 'public'
    and c.relname = 'commercial_sales'
    and con.conname = 'commercial_sales_salesperson_member_org_fkey'
    and con.contype = 'f';

  if v_constraint_count <> 1 then
    raise exception
      'R3A inválida: FK de vendedor não foi criada corretamente.';
  end if;

  if to_regclass(
    'public.commercial_sales_org_salesperson_competence_status_idx'
  ) is null then
    raise exception
      'R3A inválida: índice de apuração por vendedor não foi criado.';
  end if;

  if to_regprocedure(
    'private.validate_commercial_sale_salesperson()'
  ) is null then
    raise exception
      'R3A inválida: função de validação do vendedor não foi criada.';
  end if;

  select count(*)
  into v_trigger_count
  from pg_trigger t
  join pg_class c
    on c.oid = t.tgrelid
  join pg_namespace n
    on n.oid = c.relnamespace
  where n.nspname = 'public'
    and c.relname = 'commercial_sales'
    and not t.tgisinternal
    and t.tgname = 'commercial_sales_validate_salesperson';

  if v_trigger_count <> 1 then
    raise exception
      'R3A inválida: trigger de validação do vendedor não foi criado.';
  end if;
end;
$$;

commit;