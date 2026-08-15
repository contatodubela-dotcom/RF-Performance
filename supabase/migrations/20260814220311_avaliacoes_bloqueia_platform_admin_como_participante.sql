-- ============================================================================
-- RF Performance — Avaliações
-- Platform Admin é exclusivamente gestor, nunca participante.
-- Data: 2026-08-14
--
-- Objetivos:
--   1. excluir system_role = platform_admin da elegibilidade de participante;
--   2. impedir que grants organizacionais alcancem Platform Admin;
--   3. impedir grant individual para Platform Admin;
--   4. impedir listagem/início/continuação/resposta/envio/resultado;
--   5. impedir que Platform Admin apareça como participante na visão gerencial;
--   6. preservar integralmente as capacidades administrativas e gerenciais.
-- ============================================================================

begin;

-- ============================================================================
-- Preflight
-- ============================================================================

do $preflight$
declare
  v_signature text;
begin
  if not exists (
    select 1
    from information_schema.columns
    where table_schema = 'public'
      and table_name = 'profiles'
      and column_name = 'system_role'
  ) then
    raise exception
      'PLATFORM_ADMIN_PARTICIPANT_PREFLIGHT_FAILED: profiles.system_role not found';
  end if;

  if to_regclass('private.assessment_test_access_grants') is null then
    raise exception
      'PLATFORM_ADMIN_PARTICIPANT_PREFLIGHT_FAILED: assessment_test_access_grants not found';
  end if;

  foreach v_signature in array array[
    'private.assessment_test_access_allowed(uuid,uuid,uuid,uuid)',
    'public.get_available_assessments(uuid)',
    'public.start_assessment_attempt(uuid,uuid)',
    'public.get_assessment_attempt(uuid)',
    'public.save_assessment_answer(uuid,uuid,text)',
    'public.submit_assessment_attempt(uuid)',
    'public.get_assessment_attempt_result(uuid)',
    'public.get_managed_assessment_progress(uuid)',
    'public.get_assessment_access_admin_state(uuid)',
    'public.configure_assessment_access(uuid,uuid,text,uuid,boolean,text)'
  ]
  loop
    if to_regprocedure(v_signature) is null then
      raise exception
        'PLATFORM_ADMIN_PARTICIPANT_PREFLIGHT_FAILED: function % not found',
        v_signature;
    end if;
  end loop;

  -- A migration não deve estar sendo reaplicada sobre os wrappers internos.
  if
    to_regprocedure(
      'public.get_available_assessments_unchecked_20260814220311(uuid)'
    ) is not null
    or to_regprocedure(
      'public.start_assessment_attempt_unchecked_20260814220311(uuid,uuid)'
    ) is not null
    or to_regprocedure(
      'public.get_assessment_attempt_unchecked_20260814220311(uuid)'
    ) is not null
    or to_regprocedure(
      'public.save_assessment_answer_unchecked_20260814220311(uuid,uuid,text)'
    ) is not null
    or to_regprocedure(
      'public.submit_assessment_attempt_unchecked_20260814220311(uuid)'
    ) is not null
    or to_regprocedure(
      'public.get_assessment_attempt_result_unchecked_20260814220311(uuid)'
    ) is not null
    or to_regprocedure(
      'public.get_managed_assessment_progress_unchecked_20260814220311(uuid)'
    ) is not null
    or to_regprocedure(
      'public.get_assessment_access_admin_state_unchecked_20260814220311(uuid)'
    ) is not null
    or to_regprocedure(
      'public.configure_assessment_access_unchecked_20260814220311(uuid,uuid,text,uuid,boolean,text)'
    ) is not null
  then
    raise exception
      'PLATFORM_ADMIN_PARTICIPANT_PREFLIGHT_FAILED: internal wrapper functions already exist';
  end if;
end;
$preflight$;

-- ============================================================================
-- Regra central de elegibilidade
--
-- IMPORTANTE:
-- Não usa private.is_platform_admin(), porque essa função verifica o CALLER.
-- Aqui precisamos verificar o USUÁRIO-ALVO.
-- ============================================================================

create or replace function private.assessment_participant_eligible(
  p_organization_id uuid,
  p_organization_member_id uuid
)
returns boolean
language sql
stable
security definer
set search_path = pg_catalog, public, private
as $$
  select exists (
    select 1
    from public.organization_members om
    join public.profiles p
      on p.id = om.user_id
     and p.status = 'active'
     and p.archived_at is null
    where om.id = p_organization_member_id
      and om.organization_id = p_organization_id
      and om.status = 'active'
      and om.archived_at is null
      and om.role in ('salesperson', 'supervisor', 'director')
      and p.system_role is distinct from 'platform_admin'
  );
$$;

revoke all on function private.assessment_participant_eligible(uuid, uuid)
from public, anon, authenticated;

comment on function private.assessment_participant_eligible(uuid, uuid) is
  'Retorna true somente para participante ativo elegível. Platform Admin global nunca é participante, independentemente do papel organizacional.';

-- ============================================================================
-- Portão central de acesso às avaliações
--
-- Liberação individual OU organizacional continua funcionando,
-- mas apenas para participantes elegíveis.
-- ============================================================================

create or replace function private.assessment_test_access_allowed(
  p_organization_id uuid,
  p_organization_member_id uuid,
  p_test_id uuid,
  p_test_version_id uuid
)
returns boolean
language sql
stable
security definer
set search_path = pg_catalog, public, private
as $$
  select
    private.assessment_participant_eligible(
      p_organization_id,
      p_organization_member_id
    )
    and exists (
      select 1
      from public.assessment_tests t
      join public.assessment_test_versions tv
        on tv.id = p_test_version_id
       and tv.organization_id = p_organization_id
       and tv.test_id = p_test_id
       and tv.archived_at is null
      join private.assessment_test_access_grants access_grant
        on access_grant.organization_id = p_organization_id
       and access_grant.test_id = p_test_id
       and access_grant.test_version_id = p_test_version_id
       and access_grant.status = 'active'
       and access_grant.archived_at is null
       and (
         access_grant.valid_from is null
         or access_grant.valid_from <= now()
       )
       and (
         access_grant.valid_until is null
         or access_grant.valid_until > now()
       )
       and (
         (
           access_grant.access_scope = 'member'
           and access_grant.organization_member_id =
               p_organization_member_id
         )
         or
         (
           access_grant.access_scope = 'organization'
           and access_grant.organization_member_id is null
         )
       )
      where t.id = p_test_id
        and t.organization_id = p_organization_id
        and t.archived_at is null
    );
$$;

revoke all on function private.assessment_test_access_allowed(
  uuid,
  uuid,
  uuid,
  uuid
) from public, anon, authenticated;

comment on function private.assessment_test_access_allowed(
  uuid,
  uuid,
  uuid,
  uuid
) is
  'Valida grant ativo somente para participante elegível; Platform Admin global nunca recebe acesso como participante.';

-- ============================================================================
-- Revoga eventual grant individual ativo já existente para Platform Admin.
--
-- Grants de ORGANIZAÇÃO não são revogados: continuam válidos para os
-- participantes normais e o helper acima exclui automaticamente Platform Admin.
-- ============================================================================

update private.assessment_test_access_grants g
set
  status = 'revoked',
  updated_at = now(),
  metadata = g.metadata || jsonb_build_object(
    'revoked_by_migration', '20260814220311',
    'revoked_reason', 'platform_admin_not_participant',
    'revoked_at', now()
  )
from public.organization_members om
join public.profiles p
  on p.id = om.user_id
where g.access_scope = 'member'
  and g.organization_member_id = om.id
  and g.organization_id = om.organization_id
  and g.status = 'active'
  and g.archived_at is null
  and p.system_role = 'platform_admin';

-- ============================================================================
-- Preserva as implementações homologadas como funções internas.
-- Os nomes públicos originais serão recriados como wrappers seguros.
-- ============================================================================

alter function public.get_available_assessments(uuid)
  rename to get_available_assessments_unchecked_20260814220311;

alter function public.start_assessment_attempt(uuid, uuid)
  rename to start_assessment_attempt_unchecked_20260814220311;

alter function public.get_assessment_attempt(uuid)
  rename to get_assessment_attempt_unchecked_20260814220311;

alter function public.save_assessment_answer(uuid, uuid, text)
  rename to save_assessment_answer_unchecked_20260814220311;

alter function public.submit_assessment_attempt(uuid)
  rename to submit_assessment_attempt_unchecked_20260814220311;

alter function public.get_assessment_attempt_result(uuid)
  rename to get_assessment_attempt_result_unchecked_20260814220311;

alter function public.get_managed_assessment_progress(uuid)
  rename to get_managed_assessment_progress_unchecked_20260814220311;

alter function public.get_assessment_access_admin_state(uuid)
  rename to get_assessment_access_admin_state_unchecked_20260814220311;

alter function public.configure_assessment_access(
  uuid,
  uuid,
  text,
  uuid,
  boolean,
  text
)
  rename to configure_assessment_access_unchecked_20260814220311;

-- Nenhum cliente autenticado pode contornar os wrappers chamando as
-- implementações internas diretamente.

revoke all on function
  public.get_available_assessments_unchecked_20260814220311(uuid)
from public, anon, authenticated;

revoke all on function
  public.start_assessment_attempt_unchecked_20260814220311(uuid, uuid)
from public, anon, authenticated;

revoke all on function
  public.get_assessment_attempt_unchecked_20260814220311(uuid)
from public, anon, authenticated;

revoke all on function
  public.save_assessment_answer_unchecked_20260814220311(uuid, uuid, text)
from public, anon, authenticated;

revoke all on function
  public.submit_assessment_attempt_unchecked_20260814220311(uuid)
from public, anon, authenticated;

revoke all on function
  public.get_assessment_attempt_result_unchecked_20260814220311(uuid)
from public, anon, authenticated;

revoke all on function
  public.get_managed_assessment_progress_unchecked_20260814220311(uuid)
from public, anon, authenticated;

revoke all on function
  public.get_assessment_access_admin_state_unchecked_20260814220311(uuid)
from public, anon, authenticated;

revoke all on function
  public.configure_assessment_access_unchecked_20260814220311(
    uuid,
    uuid,
    text,
    uuid,
    boolean,
    text
  )
from public, anon, authenticated;

-- ============================================================================
-- WRAPPER 1 — Listagem pessoal
-- ============================================================================

create function public.get_available_assessments(
  p_organization_id uuid
)
returns jsonb
language plpgsql
stable
security definer
set search_path = pg_catalog, public, private
as $$
begin
  if private.is_platform_admin() then
    raise exception 'ASSESSMENT_PARTICIPANT_NOT_ELIGIBLE'
      using errcode = '42501';
  end if;

  return public.get_available_assessments_unchecked_20260814220311(
    p_organization_id
  );
end;
$$;

-- ============================================================================
-- WRAPPER 2 — Início/retomada
-- ============================================================================

create function public.start_assessment_attempt(
  p_organization_id uuid,
  p_test_id uuid
)
returns jsonb
language plpgsql
security definer
set search_path = pg_catalog, public, private
as $$
begin
  if private.is_platform_admin() then
    raise exception 'ASSESSMENT_PARTICIPANT_NOT_ELIGIBLE'
      using errcode = '42501';
  end if;

  return public.start_assessment_attempt_unchecked_20260814220311(
    p_organization_id,
    p_test_id
  );
end;
$$;

-- ============================================================================
-- WRAPPER 3 — Abrir tentativa existente
-- ============================================================================

create function public.get_assessment_attempt(
  p_attempt_id uuid
)
returns jsonb
language plpgsql
security definer
set search_path = pg_catalog, public, private
as $$
begin
  if private.is_platform_admin() then
    raise exception 'ASSESSMENT_PARTICIPANT_NOT_ELIGIBLE'
      using errcode = '42501';
  end if;

  return public.get_assessment_attempt_unchecked_20260814220311(
    p_attempt_id
  );
end;
$$;

-- ============================================================================
-- WRAPPER 4 — Salvar resposta
-- ============================================================================

create function public.save_assessment_answer(
  p_attempt_id uuid,
  p_attempt_item_id uuid,
  p_selected_option_code text
)
returns jsonb
language plpgsql
security definer
set search_path = pg_catalog, public, private
as $$
begin
  if private.is_platform_admin() then
    raise exception 'ASSESSMENT_PARTICIPANT_NOT_ELIGIBLE'
      using errcode = '42501';
  end if;

  return public.save_assessment_answer_unchecked_20260814220311(
    p_attempt_id,
    p_attempt_item_id,
    p_selected_option_code
  );
end;
$$;

-- ============================================================================
-- WRAPPER 5 — Enviar/corrigir tentativa
-- ============================================================================

create function public.submit_assessment_attempt(
  p_attempt_id uuid
)
returns jsonb
language plpgsql
security definer
set search_path = pg_catalog, public, private
as $$
begin
  if private.is_platform_admin() then
    raise exception 'ASSESSMENT_PARTICIPANT_NOT_ELIGIBLE'
      using errcode = '42501';
  end if;

  return public.submit_assessment_attempt_unchecked_20260814220311(
    p_attempt_id
  );
end;
$$;

-- ============================================================================
-- WRAPPER 6 — Resultado pessoal
-- ============================================================================

create function public.get_assessment_attempt_result(
  p_attempt_id uuid
)
returns jsonb
language plpgsql
stable
security definer
set search_path = pg_catalog, public, private
as $$
begin
  if private.is_platform_admin() then
    raise exception 'ASSESSMENT_PARTICIPANT_NOT_ELIGIBLE'
      using errcode = '42501';
  end if;

  return public.get_assessment_attempt_result_unchecked_20260814220311(
    p_attempt_id
  );
end;
$$;

-- ============================================================================
-- WRAPPER 7 — Visão gerencial
--
-- Platform Admin continua podendo GERENCIAR.
-- Apenas remove das linhas retornadas usuários que sejam Platform Admin.
-- ============================================================================

create function public.get_managed_assessment_progress(
  p_organization_id uuid
)
returns table (
  organization_member_id uuid,
  user_id uuid,
  member_name text,
  member_email text,
  member_role text,
  team_contexts jsonb,
  test_id uuid,
  test_code text,
  sequence_no integer,
  test_title text,
  test_purpose text,
  test_version_id uuid,
  version_code text,
  assigned boolean,
  attempts_used integer,
  in_progress_attempt_id uuid,
  last_attempt_id uuid,
  last_attempt_no integer,
  last_attempt_status text,
  last_attempt_started_at timestamptz,
  last_attempt_submitted_at timestamptz,
  last_attempt_graded_at timestamptz,
  last_attempt_overall_score numeric,
  last_attempt_legal_score numeric,
  last_attempt_passed boolean,
  last_graded_attempt_id uuid,
  last_graded_attempt_no integer,
  last_graded_overall_score numeric,
  last_graded_legal_score numeric,
  last_graded_passed boolean,
  progress_status text
)
language plpgsql
stable
security definer
set search_path = pg_catalog, public, private
as $$
begin
  return query
  select x.*
  from public.get_managed_assessment_progress_unchecked_20260814220311(
    p_organization_id
  ) x
  where private.assessment_participant_eligible(
    p_organization_id,
    x.organization_member_id
  );
end;
$$;

-- ============================================================================
-- WRAPPER 8 — Estado administrativo
--
-- Mantém Platform Admin como gestor, mas remove Platform Admin da relação
-- de participantes elegíveis e de eventual grant individual inválido.
-- ============================================================================

create function public.get_assessment_access_admin_state(
  p_organization_id uuid
)
returns jsonb
language plpgsql
stable
security definer
set search_path = pg_catalog, public, private
as $$
declare
  v_state jsonb;
  v_members jsonb;
  v_grants jsonb;
begin
  v_state :=
    public.get_assessment_access_admin_state_unchecked_20260814220311(
      p_organization_id
    );

  select coalesce(
    jsonb_agg(e.item order by e.ordinality),
    '[]'::jsonb
  )
  into v_members
  from jsonb_array_elements(
    coalesce(v_state -> 'members', '[]'::jsonb)
  ) with ordinality as e(item, ordinality)
  where private.assessment_participant_eligible(
    p_organization_id,
    nullif(e.item ->> 'organization_member_id', '')::uuid
  );

  select coalesce(
    jsonb_agg(e.item order by e.ordinality),
    '[]'::jsonb
  )
  into v_grants
  from jsonb_array_elements(
    coalesce(v_state -> 'active_grants', '[]'::jsonb)
  ) with ordinality as e(item, ordinality)
  where
    e.item ->> 'access_scope' = 'organization'
    or (
      e.item ->> 'access_scope' = 'member'
      and private.assessment_participant_eligible(
        p_organization_id,
        nullif(e.item ->> 'organization_member_id', '')::uuid
      )
    );

  return jsonb_set(
    jsonb_set(
      v_state,
      '{members}',
      v_members,
      true
    ),
    '{active_grants}',
    v_grants,
    true
  );
end;
$$;

-- ============================================================================
-- WRAPPER 9 — Configuração administrativa de acesso
--
-- Platform Admin continua sendo o único gestor autorizado pelo RPC interno.
-- Aqui apenas fortalecemos a elegibilidade do ALVO para scope = member.
-- ============================================================================

create function public.configure_assessment_access(
  p_organization_id uuid,
  p_test_id uuid,
  p_access_scope text,
  p_organization_member_id uuid,
  p_enabled boolean,
  p_reason text default null
)
returns jsonb
language plpgsql
security definer
set search_path = pg_catalog, public, private
as $$
begin
  if auth.uid() is null then
    raise exception 'AUTH_REQUIRED'
      using errcode = '42501';
  end if;

  if not private.is_platform_admin() then
    raise exception 'ASSESSMENT_ACCESS_MANAGEMENT_FORBIDDEN'
      using errcode = '42501';
  end if;

  if p_access_scope not in ('member', 'organization') then
    raise exception 'ASSESSMENT_ACCESS_SCOPE_INVALID';
  end if;

  if p_access_scope = 'member'
     and p_organization_member_id is null then
    raise exception 'ASSESSMENT_MEMBER_REQUIRED';
  end if;

  if p_access_scope = 'organization'
     and p_organization_member_id is not null then
    raise exception
      'ASSESSMENT_MEMBER_NOT_ALLOWED_FOR_ORGANIZATION_SCOPE';
  end if;

  if p_access_scope = 'member'
     and not private.assessment_participant_eligible(
       p_organization_id,
       p_organization_member_id
     ) then
    raise exception 'ASSESSMENT_PARTICIPANT_NOT_ELIGIBLE'
      using errcode = '42501';
  end if;

  return public.configure_assessment_access_unchecked_20260814220311(
    p_organization_id,
    p_test_id,
    p_access_scope,
    p_organization_member_id,
    p_enabled,
    p_reason
  );
end;
$$;

-- ============================================================================
-- Grants públicos mínimos
-- ============================================================================

revoke all on function public.get_available_assessments(uuid)
from public, anon, authenticated;

revoke all on function public.start_assessment_attempt(uuid, uuid)
from public, anon, authenticated;

revoke all on function public.get_assessment_attempt(uuid)
from public, anon, authenticated;

revoke all on function public.save_assessment_answer(uuid, uuid, text)
from public, anon, authenticated;

revoke all on function public.submit_assessment_attempt(uuid)
from public, anon, authenticated;

revoke all on function public.get_assessment_attempt_result(uuid)
from public, anon, authenticated;

revoke all on function public.get_managed_assessment_progress(uuid)
from public, anon, authenticated;

revoke all on function public.get_assessment_access_admin_state(uuid)
from public, anon, authenticated;

revoke all on function public.configure_assessment_access(
  uuid,
  uuid,
  text,
  uuid,
  boolean,
  text
)
from public, anon, authenticated;

grant execute on function public.get_available_assessments(uuid)
to authenticated;

grant execute on function public.start_assessment_attempt(uuid, uuid)
to authenticated;

grant execute on function public.get_assessment_attempt(uuid)
to authenticated;

grant execute on function public.save_assessment_answer(uuid, uuid, text)
to authenticated;

grant execute on function public.submit_assessment_attempt(uuid)
to authenticated;

grant execute on function public.get_assessment_attempt_result(uuid)
to authenticated;

grant execute on function public.get_managed_assessment_progress(uuid)
to authenticated;

grant execute on function public.get_assessment_access_admin_state(uuid)
to authenticated;

grant execute on function public.configure_assessment_access(
  uuid,
  uuid,
  text,
  uuid,
  boolean,
  text
)
to authenticated;

-- ============================================================================
-- Comentários
-- ============================================================================

comment on function public.get_available_assessments(uuid) is
  'Lista avaliações do próprio participante. Platform Admin é explicitamente bloqueado.';

comment on function public.start_assessment_attempt(uuid, uuid) is
  'Inicia ou retoma tentativa própria somente para participante elegível. Platform Admin é explicitamente bloqueado.';

comment on function public.get_assessment_attempt(uuid) is
  'Abre tentativa própria somente para participante elegível. Platform Admin é explicitamente bloqueado.';

comment on function public.save_assessment_answer(uuid, uuid, text) is
  'Salva resposta própria somente para participante elegível. Platform Admin é explicitamente bloqueado.';

comment on function public.submit_assessment_attempt(uuid) is
  'Envia tentativa própria somente para participante elegível. Platform Admin é explicitamente bloqueado.';

comment on function public.get_assessment_attempt_result(uuid) is
  'Consulta resultado próprio somente para participante elegível. Platform Admin é explicitamente bloqueado.';

comment on function public.get_managed_assessment_progress(uuid) is
  'Visão gerencial preservada, excluindo Platform Admin das linhas de participantes.';

comment on function public.get_assessment_access_admin_state(uuid) is
  'Estado administrativo de avaliações com participantes elegíveis; Platform Admin permanece apenas como gestor.';

comment on function public.configure_assessment_access(
  uuid,
  uuid,
  text,
  uuid,
  boolean,
  text
) is
  'Configura liberação administrativa. Grant individual somente para participante elegível; grant organizacional nunca torna Platform Admin participante.';

-- ============================================================================
-- Pós-condições
-- ============================================================================

do $postcondition$
declare
  v_signature text;
begin
  -- Platform Admin jamais pode ser considerado participante elegível.
  if exists (
    select 1
    from public.organization_members om
    join public.profiles p
      on p.id = om.user_id
    where p.system_role = 'platform_admin'
      and private.assessment_participant_eligible(
        om.organization_id,
        om.id
      )
  ) then
    raise exception
      'PLATFORM_ADMIN_PARTICIPANT_POSTCONDITION_FAILED: platform admin considered eligible';
  end if;

  -- Nenhum grant individual ativo pode permanecer apontando para Platform Admin.
  if exists (
    select 1
    from private.assessment_test_access_grants g
    join public.organization_members om
      on om.id = g.organization_member_id
     and om.organization_id = g.organization_id
    join public.profiles p
      on p.id = om.user_id
    where g.access_scope = 'member'
      and g.status = 'active'
      and g.archived_at is null
      and p.system_role = 'platform_admin'
  ) then
    raise exception
      'PLATFORM_ADMIN_PARTICIPANT_POSTCONDITION_FAILED: active direct grant remained';
  end if;

  -- Wrappers públicos devem existir.
  foreach v_signature in array array[
    'public.get_available_assessments(uuid)',
    'public.start_assessment_attempt(uuid,uuid)',
    'public.get_assessment_attempt(uuid)',
    'public.save_assessment_answer(uuid,uuid,text)',
    'public.submit_assessment_attempt(uuid)',
    'public.get_assessment_attempt_result(uuid)',
    'public.get_managed_assessment_progress(uuid)',
    'public.get_assessment_access_admin_state(uuid)',
    'public.configure_assessment_access(uuid,uuid,text,uuid,boolean,text)'
  ]
  loop
    if to_regprocedure(v_signature) is null then
      raise exception
        'PLATFORM_ADMIN_PARTICIPANT_POSTCONDITION_FAILED: wrapper % missing',
        v_signature;
    end if;

    if not has_function_privilege(
      'authenticated',
      to_regprocedure(v_signature),
      'EXECUTE'
    ) then
      raise exception
        'PLATFORM_ADMIN_PARTICIPANT_POSTCONDITION_FAILED: authenticated cannot execute wrapper %',
        v_signature;
    end if;
  end loop;

  -- Implementações internas devem existir e NÃO podem ser executáveis
  -- diretamente pelo papel authenticated.
  foreach v_signature in array array[
    'public.get_available_assessments_unchecked_20260814220311(uuid)',
    'public.start_assessment_attempt_unchecked_20260814220311(uuid,uuid)',
    'public.get_assessment_attempt_unchecked_20260814220311(uuid)',
    'public.save_assessment_answer_unchecked_20260814220311(uuid,uuid,text)',
    'public.submit_assessment_attempt_unchecked_20260814220311(uuid)',
    'public.get_assessment_attempt_result_unchecked_20260814220311(uuid)',
    'public.get_managed_assessment_progress_unchecked_20260814220311(uuid)',
    'public.get_assessment_access_admin_state_unchecked_20260814220311(uuid)',
    'public.configure_assessment_access_unchecked_20260814220311(uuid,uuid,text,uuid,boolean,text)'
  ]
  loop
    if to_regprocedure(v_signature) is null then
      raise exception
        'PLATFORM_ADMIN_PARTICIPANT_POSTCONDITION_FAILED: internal function % missing',
        v_signature;
    end if;

    if has_function_privilege(
      'authenticated',
      to_regprocedure(v_signature),
      'EXECUTE'
    ) then
      raise exception
        'PLATFORM_ADMIN_PARTICIPANT_POSTCONDITION_FAILED: authenticated can bypass wrapper %',
        v_signature;
    end if;
  end loop;

  if position(
    'assessment_participant_eligible'
    in pg_get_functiondef(
      'private.assessment_test_access_allowed(uuid,uuid,uuid,uuid)'::regprocedure
    )
  ) = 0 then
    raise exception
      'PLATFORM_ADMIN_PARTICIPANT_POSTCONDITION_FAILED: central access helper is not protected';
  end if;

  if position(
    'ASSESSMENT_PARTICIPANT_NOT_ELIGIBLE'
    in pg_get_functiondef(
      'public.start_assessment_attempt(uuid,uuid)'::regprocedure
    )
  ) = 0 then
    raise exception
      'PLATFORM_ADMIN_PARTICIPANT_POSTCONDITION_FAILED: start wrapper is not protected';
  end if;

  if position(
    'assessment_participant_eligible'
    in pg_get_functiondef(
      'public.get_managed_assessment_progress(uuid)'::regprocedure
    )
  ) = 0 then
    raise exception
      'PLATFORM_ADMIN_PARTICIPANT_POSTCONDITION_FAILED: management wrapper is not filtering participants';
  end if;

  if position(
    'assessment_participant_eligible'
    in pg_get_functiondef(
      'public.get_assessment_access_admin_state(uuid)'::regprocedure
    )
  ) = 0 then
    raise exception
      'PLATFORM_ADMIN_PARTICIPANT_POSTCONDITION_FAILED: admin state wrapper is not filtering participants';
  end if;
end;
$postcondition$;

commit;