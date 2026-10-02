-- ============================================================================
-- RF PERFORMANCE
-- Gestão administrativa da Biblioteca de Treinamentos
--
-- Objetivos:
--   1. permitir cadastro e manutenção pela interface, sem SQL manual;
--   2. restringir as novas RPCs administrativas ao Platform Admin;
--   3. preservar treinamentos, progresso e materiais existentes;
--   4. permitir upload privado no bucket training-materials pelo Platform Admin;
--   5. manter metadados de módulos, aulas e duração sincronizados.
-- ============================================================================

begin;

-- ============================================================================
-- 1. Sincronização dos metadados derivados do treinamento
-- ============================================================================

create or replace function private.refresh_training_library_metadata(
  p_organization_id uuid,
  p_training_id uuid
)
returns void
language plpgsql
security definer
set search_path = pg_catalog, public, private
as $function$
declare
  v_module_count integer;
  v_lesson_count integer;
  v_duration integer;
begin
  select count(*)::integer
  into v_module_count
  from public.training_library_modules m
  where m.organization_id = p_organization_id
    and m.training_id = p_training_id
    and m.status <> 'archived'
    and m.archived_at is null;

  select
    count(*)::integer,
    coalesce(sum(l.duration_minutes), 0)::integer
  into v_lesson_count, v_duration
  from public.training_library_lessons l
  where l.organization_id = p_organization_id
    and l.training_id = p_training_id
    and l.status <> 'archived'
    and l.archived_at is null;

  update public.training_library_items
  set metadata =
      coalesce(metadata, '{}'::jsonb)
      || jsonb_build_object(
        'learning_experience', v_lesson_count > 0,
        'module_count', v_module_count,
        'lesson_count', v_lesson_count,
        'estimated_duration_minutes', v_duration
      )
  where id = p_training_id
    and organization_id = p_organization_id
    and archived_at is null;
end;
$function$;

revoke all
on function private.refresh_training_library_metadata(uuid, uuid)
from public, anon, authenticated;

-- ============================================================================
-- 2. Estado administrativo completo
-- ============================================================================

create or replace function public.get_training_library_admin_state(
  p_organization_id uuid
)
returns jsonb
language plpgsql
stable
security definer
set search_path = pg_catalog, public, private
as $function$
declare
  v_user_id uuid := auth.uid();
begin
  if v_user_id is null then
    raise exception 'AUTH_REQUIRED' using errcode = '42501';
  end if;

  if not private.is_platform_admin() then
    raise exception 'TRAINING_LIBRARY_MANAGEMENT_FORBIDDEN'
      using errcode = '42501';
  end if;

  if not exists (
    select 1
    from public.organizations o
    where o.id = p_organization_id
      and o.status = 'active'
      and o.archived_at is null
  ) then
    raise exception 'ORGANIZATION_NOT_AVAILABLE'
      using errcode = 'P0001';
  end if;

  return jsonb_build_object(
    'organization_id', p_organization_id,
    'items', coalesce((
      select jsonb_agg(to_jsonb(i) order by i.sequence_no, i.created_at)
      from public.training_library_items i
      where i.organization_id = p_organization_id
        and i.archived_at is null
        and i.status <> 'archived'
    ), '[]'::jsonb),
    'assets', coalesce((
      select jsonb_agg(to_jsonb(a) order by a.training_id, a.sequence_no, a.created_at)
      from public.training_library_assets a
      where a.organization_id = p_organization_id
        and a.archived_at is null
        and a.status <> 'archived'
    ), '[]'::jsonb),
    'modules', coalesce((
      select jsonb_agg(to_jsonb(m) order by m.training_id, m.sequence_no, m.created_at)
      from public.training_library_modules m
      where m.organization_id = p_organization_id
        and m.archived_at is null
        and m.status <> 'archived'
    ), '[]'::jsonb),
    'lessons', coalesce((
      select jsonb_agg(to_jsonb(l) order by l.training_id, l.module_id, l.sequence_no, l.created_at)
      from public.training_library_lessons l
      where l.organization_id = p_organization_id
        and l.archived_at is null
        and l.status <> 'archived'
    ), '[]'::jsonb)
  );
end;
$function$;

revoke all
on function public.get_training_library_admin_state(uuid)
from public, anon;

grant execute
on function public.get_training_library_admin_state(uuid)
to authenticated;

-- ============================================================================
-- 3. Criar treinamento
-- ============================================================================

create or replace function public.create_training_library_admin(
  p_organization_id uuid,
  p_title text,
  p_description text,
  p_category text,
  p_audience_roles text[],
  p_is_featured boolean default false
)
returns jsonb
language plpgsql
security definer
set search_path = pg_catalog, public, private
as $function$
declare
  v_user_id uuid := auth.uid();
  v_training_id uuid;
  v_sequence_no integer;
begin
  if v_user_id is null then
    raise exception 'AUTH_REQUIRED' using errcode = '42501';
  end if;

  if not private.is_platform_admin() then
    raise exception 'TRAINING_LIBRARY_MANAGEMENT_FORBIDDEN'
      using errcode = '42501';
  end if;

  if nullif(btrim(p_title), '') is null then
    raise exception 'TRAINING_LIBRARY_TITLE_REQUIRED'
      using errcode = 'P0001';
  end if;

  if p_category not in (
    'commercial_training',
    'sales_method',
    'leadership',
    'platform_guide',
    'other'
  ) then
    raise exception 'TRAINING_LIBRARY_CATEGORY_INVALID'
      using errcode = 'P0001';
  end if;

  if p_audience_roles is null
     or cardinality(p_audience_roles) not between 1 and 3
     or not (
       p_audience_roles <@ array['director','supervisor','salesperson']::text[]
     ) then
    raise exception 'TRAINING_LIBRARY_AUDIENCE_INVALID'
      using errcode = 'P0001';
  end if;

  perform pg_advisory_xact_lock(
    hashtextextended('training-library:' || p_organization_id::text, 0)
  );

  select coalesce(max(i.sequence_no), 0) + 1
  into v_sequence_no
  from public.training_library_items i
  where i.organization_id = p_organization_id;

  insert into public.training_library_items (
    organization_id,
    sequence_no,
    title,
    description,
    category,
    audience_roles,
    status,
    is_featured,
    metadata
  )
  values (
    p_organization_id,
    v_sequence_no,
    btrim(p_title),
    coalesce(p_description, ''),
    p_category,
    p_audience_roles,
    'draft',
    coalesce(p_is_featured, false),
    jsonb_build_object(
      'learning_experience', false,
      'module_count', 0,
      'lesson_count', 0,
      'estimated_duration_minutes', 0,
      'managed_by', 'training_admin_ui'
    )
  )
  returning id into v_training_id;

  return jsonb_build_object(
    'training_id', v_training_id,
    'sequence_no', v_sequence_no,
    'status', 'draft'
  );
end;
$function$;

revoke all
on function public.create_training_library_admin(uuid, text, text, text, text[], boolean)
from public, anon;

grant execute
on function public.create_training_library_admin(uuid, text, text, text, text[], boolean)
to authenticated;

-- ============================================================================
-- 4. Atualizar treinamento
-- ============================================================================

create or replace function public.update_training_library_admin(
  p_organization_id uuid,
  p_training_id uuid,
  p_title text,
  p_description text,
  p_category text,
  p_audience_roles text[],
  p_is_featured boolean,
  p_status text
)
returns jsonb
language plpgsql
security definer
set search_path = pg_catalog, public, private
as $function$
declare
  v_user_id uuid := auth.uid();
begin
  if v_user_id is null then
    raise exception 'AUTH_REQUIRED' using errcode = '42501';
  end if;

  if not private.is_platform_admin() then
    raise exception 'TRAINING_LIBRARY_MANAGEMENT_FORBIDDEN'
      using errcode = '42501';
  end if;

  if nullif(btrim(p_title), '') is null then
    raise exception 'TRAINING_LIBRARY_TITLE_REQUIRED'
      using errcode = 'P0001';
  end if;

  if p_status not in ('draft', 'published') then
    raise exception 'TRAINING_LIBRARY_STATUS_INVALID'
      using errcode = 'P0001';
  end if;

  if p_category not in (
    'commercial_training',
    'sales_method',
    'leadership',
    'platform_guide',
    'other'
  ) then
    raise exception 'TRAINING_LIBRARY_CATEGORY_INVALID'
      using errcode = 'P0001';
  end if;

  if p_audience_roles is null
     or cardinality(p_audience_roles) not between 1 and 3
     or not (
       p_audience_roles <@ array['director','supervisor','salesperson']::text[]
     ) then
    raise exception 'TRAINING_LIBRARY_AUDIENCE_INVALID'
      using errcode = 'P0001';
  end if;

  update public.training_library_items
  set
    title = btrim(p_title),
    description = coalesce(p_description, ''),
    category = p_category,
    audience_roles = p_audience_roles,
    is_featured = coalesce(p_is_featured, false),
    status = p_status
  where id = p_training_id
    and organization_id = p_organization_id
    and archived_at is null
    and status <> 'archived';

  if not found then
    raise exception 'TRAINING_LIBRARY_NOT_FOUND'
      using errcode = 'P0001';
  end if;

  return jsonb_build_object(
    'training_id', p_training_id,
    'updated', true,
    'status', p_status
  );
end;
$function$;

revoke all
on function public.update_training_library_admin(uuid, uuid, text, text, text, text[], boolean, text)
from public, anon;

grant execute
on function public.update_training_library_admin(uuid, uuid, text, text, text, text[], boolean, text)
to authenticated;

-- ============================================================================
-- 5. Duplicar treinamento (estrutura, sem duplicar arquivos)
-- ============================================================================

create or replace function public.duplicate_training_library_admin(
  p_organization_id uuid,
  p_training_id uuid
)
returns jsonb
language plpgsql
security definer
set search_path = pg_catalog, public, private
as $function$
declare
  v_user_id uuid := auth.uid();
  v_source public.training_library_items%rowtype;
  v_new_training_id uuid;
  v_sequence_no integer;
  v_module record;
  v_lesson record;
  v_new_module_id uuid;
  v_modules_copied integer := 0;
  v_lessons_copied integer := 0;
begin
  if v_user_id is null then
    raise exception 'AUTH_REQUIRED' using errcode = '42501';
  end if;

  if not private.is_platform_admin() then
    raise exception 'TRAINING_LIBRARY_MANAGEMENT_FORBIDDEN'
      using errcode = '42501';
  end if;

  select *
  into v_source
  from public.training_library_items i
  where i.id = p_training_id
    and i.organization_id = p_organization_id
    and i.archived_at is null
    and i.status <> 'archived';

  if not found then
    raise exception 'TRAINING_LIBRARY_NOT_FOUND'
      using errcode = 'P0001';
  end if;

  perform pg_advisory_xact_lock(
    hashtextextended('training-library:' || p_organization_id::text, 0)
  );

  select coalesce(max(i.sequence_no), 0) + 1
  into v_sequence_no
  from public.training_library_items i
  where i.organization_id = p_organization_id;

  insert into public.training_library_items (
    organization_id,
    sequence_no,
    title,
    description,
    category,
    audience_roles,
    status,
    is_featured,
    metadata
  )
  values (
    p_organization_id,
    v_sequence_no,
    'Cópia de ' || v_source.title,
    v_source.description,
    v_source.category,
    v_source.audience_roles,
    'draft',
    false,
    (v_source.metadata - 'module_count' - 'lesson_count' - 'estimated_duration_minutes')
      || jsonb_build_object(
        'learning_experience', false,
        'module_count', 0,
        'lesson_count', 0,
        'estimated_duration_minutes', 0,
        'duplicated_from', p_training_id,
        'managed_by', 'training_admin_ui'
      )
  )
  returning id into v_new_training_id;

  for v_module in
    select *
    from public.training_library_modules m
    where m.organization_id = p_organization_id
      and m.training_id = p_training_id
      and m.archived_at is null
      and m.status <> 'archived'
    order by m.sequence_no
  loop
    insert into public.training_library_modules (
      organization_id,
      training_id,
      sequence_no,
      title,
      description,
      status,
      metadata
    )
    values (
      p_organization_id,
      v_new_training_id,
      v_module.sequence_no,
      v_module.title,
      v_module.description,
      'draft',
      v_module.metadata
        || jsonb_build_object('duplicated_from', v_module.id)
    )
    returning id into v_new_module_id;

    v_modules_copied := v_modules_copied + 1;

    for v_lesson in
      select *
      from public.training_library_lessons l
      where l.organization_id = p_organization_id
        and l.training_id = p_training_id
        and l.module_id = v_module.id
        and l.archived_at is null
        and l.status <> 'archived'
      order by l.sequence_no
    loop
      insert into public.training_library_lessons (
        organization_id,
        training_id,
        module_id,
        sequence_no,
        title,
        description,
        lesson_type,
        duration_minutes,
        is_required,
        status,
        metadata
      )
      values (
        p_organization_id,
        v_new_training_id,
        v_new_module_id,
        v_lesson.sequence_no,
        v_lesson.title,
        v_lesson.description,
        v_lesson.lesson_type,
        v_lesson.duration_minutes,
        v_lesson.is_required,
        'draft',
        v_lesson.metadata
          || jsonb_build_object('duplicated_from', v_lesson.id)
      );

      v_lessons_copied := v_lessons_copied + 1;
    end loop;
  end loop;

  perform private.refresh_training_library_metadata(
    p_organization_id,
    v_new_training_id
  );

  return jsonb_build_object(
    'source_training_id', p_training_id,
    'training_id', v_new_training_id,
    'modules_copied', v_modules_copied,
    'lessons_copied', v_lessons_copied,
    'assets_copied', false
  );
end;
$function$;

revoke all
on function public.duplicate_training_library_admin(uuid, uuid)
from public, anon;

grant execute
on function public.duplicate_training_library_admin(uuid, uuid)
to authenticated;

-- ============================================================================
-- 6. Arquivar treinamento sem apagar histórico
-- ============================================================================

create or replace function public.archive_training_library_admin(
  p_organization_id uuid,
  p_training_id uuid
)
returns jsonb
language plpgsql
security definer
set search_path = pg_catalog, public, private
as $function$
declare
  v_user_id uuid := auth.uid();
  v_modules integer := 0;
  v_lessons integer := 0;
  v_assets integer := 0;
begin
  if v_user_id is null then
    raise exception 'AUTH_REQUIRED' using errcode = '42501';
  end if;

  if not private.is_platform_admin() then
    raise exception 'TRAINING_LIBRARY_MANAGEMENT_FORBIDDEN'
      using errcode = '42501';
  end if;

  update public.training_library_lessons
  set
    status = 'archived',
    archived_at = coalesce(archived_at, now())
  where organization_id = p_organization_id
    and training_id = p_training_id
    and archived_at is null;

  get diagnostics v_lessons = row_count;

  update public.training_library_modules
  set
    status = 'archived',
    archived_at = coalesce(archived_at, now())
  where organization_id = p_organization_id
    and training_id = p_training_id
    and archived_at is null;

  get diagnostics v_modules = row_count;

  update public.training_library_assets
  set
    status = 'archived',
    archived_at = coalesce(archived_at, now())
  where organization_id = p_organization_id
    and training_id = p_training_id
    and archived_at is null;

  get diagnostics v_assets = row_count;

  update public.training_library_items
  set
    status = 'archived',
    archived_at = coalesce(archived_at, now())
  where id = p_training_id
    and organization_id = p_organization_id
    and archived_at is null;

  if not found then
    raise exception 'TRAINING_LIBRARY_NOT_FOUND'
      using errcode = 'P0001';
  end if;

  return jsonb_build_object(
    'training_id', p_training_id,
    'archived', true,
    'modules_archived', v_modules,
    'lessons_archived', v_lessons,
    'assets_archived', v_assets
  );
end;
$function$;

revoke all
on function public.archive_training_library_admin(uuid, uuid)
from public, anon;

grant execute
on function public.archive_training_library_admin(uuid, uuid)
to authenticated;

-- ============================================================================
-- 7. Criar/editar módulo
-- ============================================================================

create or replace function public.upsert_training_library_module_admin(
  p_organization_id uuid,
  p_training_id uuid,
  p_module_id uuid,
  p_title text,
  p_description text,
  p_status text
)
returns jsonb
language plpgsql
security definer
set search_path = pg_catalog, public, private
as $function$
declare
  v_user_id uuid := auth.uid();
  v_module_id uuid;
  v_sequence_no integer;
begin
  if v_user_id is null then
    raise exception 'AUTH_REQUIRED' using errcode = '42501';
  end if;

  if not private.is_platform_admin() then
    raise exception 'TRAINING_LIBRARY_MANAGEMENT_FORBIDDEN'
      using errcode = '42501';
  end if;

  if nullif(btrim(p_title), '') is null then
    raise exception 'TRAINING_LIBRARY_MODULE_TITLE_REQUIRED'
      using errcode = 'P0001';
  end if;

  if p_status not in ('draft', 'published') then
    raise exception 'TRAINING_LIBRARY_STATUS_INVALID'
      using errcode = 'P0001';
  end if;

  if p_module_id is null then
    perform pg_advisory_xact_lock(
      hashtextextended('training-module:' || p_training_id::text, 0)
    );

    select coalesce(max(m.sequence_no), 0) + 1
    into v_sequence_no
    from public.training_library_modules m
    where m.organization_id = p_organization_id
      and m.training_id = p_training_id;

    insert into public.training_library_modules (
      organization_id,
      training_id,
      sequence_no,
      title,
      description,
      status,
      metadata
    )
    values (
      p_organization_id,
      p_training_id,
      v_sequence_no,
      btrim(p_title),
      coalesce(p_description, ''),
      p_status,
      '{}'::jsonb
    )
    returning id into v_module_id;
  else
    update public.training_library_modules
    set
      title = btrim(p_title),
      description = coalesce(p_description, ''),
      status = p_status
    where id = p_module_id
      and organization_id = p_organization_id
      and training_id = p_training_id
      and archived_at is null
      and status <> 'archived'
    returning id into v_module_id;

    if v_module_id is null then
      raise exception 'TRAINING_LIBRARY_MODULE_NOT_FOUND'
        using errcode = 'P0001';
    end if;
  end if;

  perform private.refresh_training_library_metadata(
    p_organization_id,
    p_training_id
  );

  return jsonb_build_object(
    'module_id', v_module_id,
    'training_id', p_training_id,
    'saved', true
  );
end;
$function$;

revoke all
on function public.upsert_training_library_module_admin(uuid, uuid, uuid, text, text, text)
from public, anon;

grant execute
on function public.upsert_training_library_module_admin(uuid, uuid, uuid, text, text, text)
to authenticated;

-- ============================================================================
-- 8. Criar/editar aula
-- ============================================================================

create or replace function public.upsert_training_library_lesson_admin(
  p_organization_id uuid,
  p_training_id uuid,
  p_module_id uuid,
  p_lesson_id uuid,
  p_title text,
  p_description text,
  p_lesson_type text,
  p_duration_minutes integer,
  p_is_required boolean,
  p_status text,
  p_learning_objective text,
  p_summary text,
  p_key_points text[]
)
returns jsonb
language plpgsql
security definer
set search_path = pg_catalog, public, private
as $function$
declare
  v_user_id uuid := auth.uid();
  v_lesson_id uuid;
  v_sequence_no integer;
  v_metadata jsonb;
begin
  if v_user_id is null then
    raise exception 'AUTH_REQUIRED' using errcode = '42501';
  end if;

  if not private.is_platform_admin() then
    raise exception 'TRAINING_LIBRARY_MANAGEMENT_FORBIDDEN'
      using errcode = '42501';
  end if;

  if nullif(btrim(p_title), '') is null then
    raise exception 'TRAINING_LIBRARY_LESSON_TITLE_REQUIRED'
      using errcode = 'P0001';
  end if;

  if p_status not in ('draft', 'published') then
    raise exception 'TRAINING_LIBRARY_STATUS_INVALID'
      using errcode = 'P0001';
  end if;

  if p_lesson_type not in (
    'video', 'slides', 'document', 'text', 'interactive', 'other'
  ) then
    raise exception 'TRAINING_LIBRARY_LESSON_TYPE_INVALID'
      using errcode = 'P0001';
  end if;

  if p_duration_minutes is not null and p_duration_minutes <= 0 then
    raise exception 'TRAINING_LIBRARY_DURATION_INVALID'
      using errcode = 'P0001';
  end if;

  if not exists (
    select 1
    from public.training_library_modules m
    where m.id = p_module_id
      and m.organization_id = p_organization_id
      and m.training_id = p_training_id
      and m.archived_at is null
      and m.status <> 'archived'
  ) then
    raise exception 'TRAINING_LIBRARY_MODULE_NOT_FOUND'
      using errcode = 'P0001';
  end if;

  v_metadata := jsonb_build_object(
    'learning_objective', coalesce(p_learning_objective, ''),
    'summary', coalesce(p_summary, ''),
    'key_points', to_jsonb(coalesce(p_key_points, array[]::text[]))
  );

  if p_lesson_id is null then
    perform pg_advisory_xact_lock(
      hashtextextended('training-lesson:' || p_module_id::text, 0)
    );

    select coalesce(max(l.sequence_no), 0) + 1
    into v_sequence_no
    from public.training_library_lessons l
    where l.organization_id = p_organization_id
      and l.training_id = p_training_id
      and l.module_id = p_module_id;

    insert into public.training_library_lessons (
      organization_id,
      training_id,
      module_id,
      sequence_no,
      title,
      description,
      lesson_type,
      duration_minutes,
      is_required,
      status,
      metadata
    )
    values (
      p_organization_id,
      p_training_id,
      p_module_id,
      v_sequence_no,
      btrim(p_title),
      coalesce(p_description, ''),
      p_lesson_type,
      p_duration_minutes,
      coalesce(p_is_required, true),
      p_status,
      v_metadata
    )
    returning id into v_lesson_id;
  else
    update public.training_library_lessons
    set
      title = btrim(p_title),
      description = coalesce(p_description, ''),
      lesson_type = p_lesson_type,
      duration_minutes = p_duration_minutes,
      is_required = coalesce(p_is_required, true),
      status = p_status,
      metadata = coalesce(metadata, '{}'::jsonb) || v_metadata
    where id = p_lesson_id
      and organization_id = p_organization_id
      and training_id = p_training_id
      and module_id = p_module_id
      and archived_at is null
      and status <> 'archived'
    returning id into v_lesson_id;

    if v_lesson_id is null then
      raise exception 'TRAINING_LIBRARY_LESSON_NOT_FOUND'
        using errcode = 'P0001';
    end if;
  end if;

  perform private.refresh_training_library_metadata(
    p_organization_id,
    p_training_id
  );

  return jsonb_build_object(
    'lesson_id', v_lesson_id,
    'module_id', p_module_id,
    'training_id', p_training_id,
    'saved', true
  );
end;
$function$;

revoke all
on function public.upsert_training_library_lesson_admin(
  uuid, uuid, uuid, uuid, text, text, text, integer, boolean, text, text, text, text[]
)
from public, anon;

grant execute
on function public.upsert_training_library_lesson_admin(
  uuid, uuid, uuid, uuid, text, text, text, integer, boolean, text, text, text, text[]
)
to authenticated;

-- ============================================================================
-- 9. Registrar e arquivar materiais
-- ============================================================================

create or replace function public.register_training_library_asset_admin(
  p_organization_id uuid,
  p_training_id uuid,
  p_asset_type text,
  p_display_name text,
  p_storage_path text,
  p_mime_type text,
  p_file_size_bytes bigint,
  p_is_downloadable boolean default true
)
returns jsonb
language plpgsql
security definer
set search_path = pg_catalog, public, private
as $function$
declare
  v_user_id uuid := auth.uid();
  v_asset_id uuid;
  v_sequence_no integer;
begin
  if v_user_id is null then
    raise exception 'AUTH_REQUIRED' using errcode = '42501';
  end if;

  if not private.is_platform_admin() then
    raise exception 'TRAINING_LIBRARY_MANAGEMENT_FORBIDDEN'
      using errcode = '42501';
  end if;

  if p_asset_type not in ('primary', 'slides', 'workbook', 'attachment', 'cover') then
    raise exception 'TRAINING_LIBRARY_ASSET_TYPE_INVALID'
      using errcode = 'P0001';
  end if;

  if nullif(btrim(p_display_name), '') is null then
    raise exception 'TRAINING_LIBRARY_ASSET_NAME_REQUIRED'
      using errcode = 'P0001';
  end if;

  if p_storage_path not like (
    p_organization_id::text || '/' || p_training_id::text || '/%'
  ) then
    raise exception 'TRAINING_LIBRARY_STORAGE_PATH_INVALID'
      using errcode = 'P0001';
  end if;

  perform pg_advisory_xact_lock(
    hashtextextended('training-asset:' || p_training_id::text, 0)
  );

  select coalesce(max(a.sequence_no), 0) + 1
  into v_sequence_no
  from public.training_library_assets a
  where a.organization_id = p_organization_id
    and a.training_id = p_training_id;

  insert into public.training_library_assets (
    organization_id,
    training_id,
    sequence_no,
    asset_type,
    display_name,
    storage_bucket,
    storage_path,
    mime_type,
    file_size_bytes,
    status,
    is_downloadable,
    metadata
  )
  values (
    p_organization_id,
    p_training_id,
    v_sequence_no,
    p_asset_type,
    btrim(p_display_name),
    'training-materials',
    p_storage_path,
    p_mime_type,
    p_file_size_bytes,
    'active',
    coalesce(p_is_downloadable, true),
    jsonb_build_object('managed_by', 'training_admin_ui')
  )
  returning id into v_asset_id;

  return jsonb_build_object(
    'asset_id', v_asset_id,
    'training_id', p_training_id,
    'registered', true
  );
end;
$function$;

revoke all
on function public.register_training_library_asset_admin(
  uuid, uuid, text, text, text, text, bigint, boolean
)
from public, anon;

grant execute
on function public.register_training_library_asset_admin(
  uuid, uuid, text, text, text, text, bigint, boolean
)
to authenticated;

create or replace function public.archive_training_library_asset_admin(
  p_organization_id uuid,
  p_asset_id uuid
)
returns jsonb
language plpgsql
security definer
set search_path = pg_catalog, public, private
as $function$
declare
  v_user_id uuid := auth.uid();
begin
  if v_user_id is null then
    raise exception 'AUTH_REQUIRED' using errcode = '42501';
  end if;

  if not private.is_platform_admin() then
    raise exception 'TRAINING_LIBRARY_MANAGEMENT_FORBIDDEN'
      using errcode = '42501';
  end if;

  update public.training_library_assets
  set
    status = 'archived',
    archived_at = coalesce(archived_at, now())
  where id = p_asset_id
    and organization_id = p_organization_id
    and archived_at is null
    and status <> 'archived';

  if not found then
    raise exception 'TRAINING_LIBRARY_ASSET_NOT_FOUND'
      using errcode = 'P0001';
  end if;

  return jsonb_build_object(
    'asset_id', p_asset_id,
    'archived', true
  );
end;
$function$;

revoke all
on function public.archive_training_library_asset_admin(uuid, uuid)
from public, anon;

grant execute
on function public.archive_training_library_asset_admin(uuid, uuid)
to authenticated;

-- ============================================================================
-- 10. Storage: upload e limpeza de upload falho somente por Platform Admin
-- ============================================================================

create policy training_materials_insert_platform_admin
on storage.objects
for insert
to authenticated
with check (
  bucket_id = 'training-materials'
  and private.is_platform_admin()
);

create policy training_materials_delete_platform_admin
on storage.objects
for delete
to authenticated
using (
  bucket_id = 'training-materials'
  and private.is_platform_admin()
);

commit;
