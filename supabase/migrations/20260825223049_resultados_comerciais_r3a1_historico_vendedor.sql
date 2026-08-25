begin;

-- R3A1
-- Permite atribuir uma venda historica a um membro que:
-- 1. atualmente possui role salesperson; ou
-- 2. possui historico comprovado como salesperson em team_members.
--
-- Nao exige vinculo ativo de equipe e nao relaciona sale_date
-- com start_at/end_at, preservando importacoes retroativas.

do $$
begin
  if to_regclass('public.commercial_sales') is null then
    raise exception
      'R3A1 invalida: public.commercial_sales nao existe.';
  end if;

  if to_regclass('public.organization_members') is null then
    raise exception
      'R3A1 invalida: public.organization_members nao existe.';
  end if;

  if to_regclass('public.team_members') is null then
    raise exception
      'R3A1 invalida: public.team_members nao existe.';
  end if;

  if to_regprocedure(
    'private.validate_commercial_sale_salesperson()'
  ) is null then
    raise exception
      'R3A1 invalida: funcao R3A de vendedor nao existe.';
  end if;
end;
$$;

create or replace function private.validate_commercial_sale_salesperson()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_current_role text;
  v_has_salesperson_history boolean;
begin
  if new.salesperson_member_id is null then
    return new;
  end if;

  select om.role
  into v_current_role
  from public.organization_members om
  where om.id = new.salesperson_member_id
    and om.organization_id = new.organization_id;

  if not found then
    raise exception
      'SALESPERSON_MEMBER_INVALID: member % does not belong to organization %.',
      new.salesperson_member_id,
      new.organization_id
      using errcode = '23503';
  end if;

  if v_current_role = 'salesperson' then
    return new;
  end if;

  select exists (
    select 1
    from public.team_members tm
    where tm.organization_id = new.organization_id
      and tm.organization_member_id = new.salesperson_member_id
      and tm.membership_type = 'salesperson'
  )
  into v_has_salesperson_history;

  if not v_has_salesperson_history then
    raise exception
      'SALESPERSON_MEMBER_INVALID: member % is not a salesperson and has no salesperson history in organization %.',
      new.salesperson_member_id,
      new.organization_id
      using errcode = '23514';
  end if;

  return new;
end;
$$;

revoke all
on function private.validate_commercial_sale_salesperson()
from public;

revoke all
on function private.validate_commercial_sale_salesperson()
from anon;

revoke all
on function private.validate_commercial_sale_salesperson()
from authenticated;

do $$
declare
  v_trigger_count integer;
begin
  if to_regprocedure(
    'private.validate_commercial_sale_salesperson()'
  ) is null then
    raise exception
      'R3A1 invalida: funcao de validacao nao foi atualizada.';
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
      'R3A1 invalida: trigger R3A de vendedor nao esta presente.';
  end if;
end;
$$;

commit;