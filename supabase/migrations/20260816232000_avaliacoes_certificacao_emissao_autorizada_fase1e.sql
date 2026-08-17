begin;

-- ============================================================================
-- Fase 1E — Emissão autorizada de certificações
--
-- Objetivo:
--   Expor um wrapper público mínimo e autorizado para a emissão genérica
--   implementada na Fase 1D.
--
-- Regras:
--   - somente sessão autenticada;
--   - somente Platform Admin ativo;
--   - a função privada da Fase 1D permanece inacessível diretamente ao cliente;
--   - nenhuma ativação de programa;
--   - nenhuma alteração de dados operacionais nesta migration.
-- ============================================================================

do $preflight$
begin
  if to_regprocedure('private.is_platform_admin()') is null then
    raise exception
      'CERTIFICATION_ISSUANCE_AUTH_PREFLIGHT_FAILED: private.is_platform_admin() not found';
  end if;

  if to_regprocedure(
    'private.issue_certification_program_version(uuid,uuid,uuid)'
  ) is null then
    raise exception
      'CERTIFICATION_ISSUANCE_AUTH_PREFLIGHT_FAILED: private issuance engine not found';
  end if;

  if to_regprocedure(
    'public.issue_certification_program_version(uuid,uuid,uuid)'
  ) is not null then
    raise exception
      'CERTIFICATION_ISSUANCE_AUTH_PREFLIGHT_FAILED: public wrapper already exists';
  end if;

  if has_function_privilege(
    'authenticated',
    'private.issue_certification_program_version(uuid,uuid,uuid)',
    'EXECUTE'
  ) then
    raise exception
      'CERTIFICATION_ISSUANCE_AUTH_PREFLIGHT_FAILED: authenticated can execute private engine';
  end if;

  if has_function_privilege(
    'anon',
    'private.issue_certification_program_version(uuid,uuid,uuid)',
    'EXECUTE'
  ) then
    raise exception
      'CERTIFICATION_ISSUANCE_AUTH_PREFLIGHT_FAILED: anon can execute private engine';
  end if;
end;
$preflight$;


-- ============================================================================
-- Wrapper público autorizado
-- ============================================================================

create function public.issue_certification_program_version(
  p_organization_id uuid,
  p_organization_member_id uuid,
  p_certification_program_version_id uuid
)
returns jsonb
language plpgsql
volatile
security definer
set search_path = pg_catalog, public, private
as $function$
begin
  if auth.uid() is null then
    raise exception 'AUTH_REQUIRED'
      using errcode = '42501';
  end if;

  if not private.is_platform_admin() then
    raise exception 'CERTIFICATION_ISSUANCE_FORBIDDEN'
      using errcode = '42501';
  end if;

  if p_organization_id is null then
    raise exception 'CERTIFICATION_ORGANIZATION_REQUIRED';
  end if;

  if p_organization_member_id is null then
    raise exception 'CERTIFICATION_MEMBER_REQUIRED';
  end if;

  if p_certification_program_version_id is null then
    raise exception 'CERTIFICATION_PROGRAM_VERSION_REQUIRED';
  end if;

  if not exists (
    select 1
    from public.organizations o
    where o.id = p_organization_id
      and o.status = 'active'
      and o.archived_at is null
  ) then
    raise exception 'ORGANIZATION_NOT_AVAILABLE';
  end if;

  return private.issue_certification_program_version(
    p_organization_id,
    p_organization_member_id,
    p_certification_program_version_id
  );
end;
$function$;

comment on function public.issue_certification_program_version(
  uuid,
  uuid,
  uuid
) is
  'Emite ou reutiliza certificação genérica para um membro. '
  'Acesso restrito a Platform Admin autenticado; delega o motor de emissão '
  'à função privada implementada na Fase 1D.';


-- ============================================================================
-- Privilégios
--
-- authenticated pode alcançar somente o wrapper público.
-- A autorização efetiva ocorre dentro do wrapper.
-- O motor privado permanece sem EXECUTE para clientes.
-- ============================================================================

revoke all on function public.issue_certification_program_version(
  uuid,
  uuid,
  uuid
)
from public, anon, authenticated;

grant execute on function public.issue_certification_program_version(
  uuid,
  uuid,
  uuid
)
to authenticated;

revoke all on function private.issue_certification_program_version(
  uuid,
  uuid,
  uuid
)
from public, anon, authenticated;


-- ============================================================================
-- Pós-condições
-- ============================================================================

do $postcondition$
declare
  v_security_definer boolean;
  v_volatility "char";
begin
  if to_regprocedure(
    'public.issue_certification_program_version(uuid,uuid,uuid)'
  ) is null then
    raise exception
      'CERTIFICATION_ISSUANCE_AUTH_POSTCONDITION_FAILED: public wrapper missing';
  end if;

  select
    p.prosecdef,
    p.provolatile
  into
    v_security_definer,
    v_volatility
  from pg_proc p
  where p.oid = to_regprocedure(
    'public.issue_certification_program_version(uuid,uuid,uuid)'
  );

  if v_security_definer is distinct from true then
    raise exception
      'CERTIFICATION_ISSUANCE_AUTH_POSTCONDITION_FAILED: public wrapper is not SECURITY DEFINER';
  end if;

  if v_volatility is distinct from 'v'::"char" then
    raise exception
      'CERTIFICATION_ISSUANCE_AUTH_POSTCONDITION_FAILED: public wrapper is not VOLATILE';
  end if;

  if not has_function_privilege(
    'authenticated',
    'public.issue_certification_program_version(uuid,uuid,uuid)',
    'EXECUTE'
  ) then
    raise exception
      'CERTIFICATION_ISSUANCE_AUTH_POSTCONDITION_FAILED: authenticated cannot execute public wrapper';
  end if;

  if has_function_privilege(
    'anon',
    'public.issue_certification_program_version(uuid,uuid,uuid)',
    'EXECUTE'
  ) then
    raise exception
      'CERTIFICATION_ISSUANCE_AUTH_POSTCONDITION_FAILED: anon can execute public wrapper';
  end if;

  if has_function_privilege(
    'authenticated',
    'private.issue_certification_program_version(uuid,uuid,uuid)',
    'EXECUTE'
  ) then
    raise exception
      'CERTIFICATION_ISSUANCE_AUTH_POSTCONDITION_FAILED: authenticated can bypass public wrapper';
  end if;

  if has_function_privilege(
    'anon',
    'private.issue_certification_program_version(uuid,uuid,uuid)',
    'EXECUTE'
  ) then
    raise exception
      'CERTIFICATION_ISSUANCE_AUTH_POSTCONDITION_FAILED: anon can execute private engine';
  end if;
end;
$postcondition$;

commit;
