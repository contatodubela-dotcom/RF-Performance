-- RF Performance
-- Segregação de dados estratégicos da organização e Home por perfil.
-- Esta migration:
--   1. remove o SELECT geral de authenticated em public.organizations;
--   2. mantém somente colunas básicas disponíveis por RLS;
--   3. expõe metadata estratégico apenas a platform_admin e director;
--   4. fornece listagem administrativa sem metadata apenas a platform_admin.
--
-- Não altera dados operacionais, usuários, vínculos, PDVs, equipes, metas ou histórico.

begin;

create or replace function public.get_organization_strategic_metadata(
  p_organization_id uuid
)
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $function$
declare
  v_metadata jsonb;
begin
  if not (
    private.is_platform_admin()
    or private.has_org_role(
      p_organization_id,
      array['director']::text[]
    )
  ) then
    raise exception 'access_denied'
      using errcode = '42501';
  end if;

  select o.metadata
    into v_metadata
  from public.organizations o
  where o.id = p_organization_id
    and o.archived_at is null;

  if not found then
    raise exception 'organization_not_found'
      using errcode = 'P0002';
  end if;

  return coalesce(v_metadata, '{}'::jsonb);
end;
$function$;

create or replace function public.list_organizations_for_platform_admin()
returns table (
  id uuid,
  legal_name text,
  trade_name text,
  slug text,
  document_number text,
  email text,
  phone text,
  logo_url text,
  status text,
  external_id text,
  source_system text,
  created_at timestamptz,
  created_by uuid,
  updated_at timestamptz,
  updated_by uuid,
  archived_at timestamptz
)
language plpgsql
stable
security definer
set search_path = ''
as $function$
begin
  if not private.is_platform_admin() then
    raise exception 'access_denied'
      using errcode = '42501';
  end if;

  return query
  select
    o.id,
    o.legal_name,
    o.trade_name,
    o.slug,
    o.document_number,
    o.email,
    o.phone,
    o.logo_url,
    o.status,
    o.external_id,
    o.source_system,
    o.created_at,
    o.created_by,
    o.updated_at,
    o.updated_by,
    o.archived_at
  from public.organizations o
  order by o.trade_name;
end;
$function$;

revoke all on function
  public.get_organization_strategic_metadata(uuid)
from public;

revoke all on function
  public.get_organization_strategic_metadata(uuid)
from anon;

grant execute on function
  public.get_organization_strategic_metadata(uuid)
to authenticated;

revoke all on function
  public.list_organizations_for_platform_admin()
from public;

revoke all on function
  public.list_organizations_for_platform_admin()
from anon;

grant execute on function
  public.list_organizations_for_platform_admin()
to authenticated;

-- O GRANT de tabela concedia leitura de todas as colunas, inclusive metadata.
-- Ele precisa ser retirado antes dos GRANTs por coluna.
revoke select on table public.organizations
from authenticated;

grant select (
  id,
  trade_name,
  slug,
  logo_url,
  status,
  source_system
)
on table public.organizations
to authenticated;

revoke select on table public.organizations
from anon;

comment on function
  public.get_organization_strategic_metadata(uuid)
is
  'Retorna metadata estratégico somente para platform_admin ou director da organização.';

comment on function
  public.list_organizations_for_platform_admin()
is
  'Lista dados cadastrais de organizações, sem metadata, somente para platform_admin.';

commit;
