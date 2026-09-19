-- ============================================================================
-- RF PERFORMANCE
-- Biblioteca de Treinamentos - Fase 4A
-- Fundação para módulos, aulas e progresso individual
--
-- Objetivos:
--   1. Preservar training_library_items e training_library_assets existentes.
--   2. Permitir organização de treinamentos em módulos e aulas.
--   3. Registrar progresso individual por usuário e aula.
--   4. Manter segregação organizacional e autorização por perfil.
--   5. Não cadastrar conteúdo do piloto nesta fase.
-- ============================================================================


-- ============================================================================
-- 1. MÓDULOS DA BIBLIOTECA
-- ============================================================================

create table public.training_library_modules (
  id uuid primary key default gen_random_uuid(),

  organization_id uuid not null,

  training_id uuid not null,

  sequence_no integer not null,

  title text not null,

  description text not null default '',

  status text not null default 'draft',

  created_at timestamptz not null default now(),
  created_by uuid,

  updated_at timestamptz not null default now(),
  updated_by uuid,

  archived_at timestamptz,

  metadata jsonb not null default '{}'::jsonb,

  constraint training_library_modules_training_org_fkey
    foreign key (
      training_id,
      organization_id
    )
    references public.training_library_items(
      id,
      organization_id
    )
    on delete restrict,

  constraint training_library_modules_id_training_org_key
    unique (
      id,
      training_id,
      organization_id
    ),

  constraint training_library_modules_training_sequence_key
    unique (
      training_id,
      sequence_no
    ),

  constraint training_library_modules_sequence_check
    check (sequence_no > 0),

  constraint training_library_modules_title_check
    check (btrim(title) <> ''),

  constraint training_library_modules_status_check
    check (
      status in (
        'draft',
        'published',
        'archived'
      )
    ),

  constraint training_library_modules_metadata_object_check
    check (
      jsonb_typeof(metadata) = 'object'
    )
);


-- ============================================================================
-- 2. AULAS DA BIBLIOTECA
-- ============================================================================

create table public.training_library_lessons (
  id uuid primary key default gen_random_uuid(),

  organization_id uuid not null,

  training_id uuid not null,

  module_id uuid not null,

  sequence_no integer not null,

  title text not null,

  description text not null default '',

  lesson_type text not null default 'slides',

  duration_minutes integer,

  is_required boolean not null default true,

  status text not null default 'draft',

  created_at timestamptz not null default now(),
  created_by uuid,

  updated_at timestamptz not null default now(),
  updated_by uuid,

  archived_at timestamptz,

  metadata jsonb not null default '{}'::jsonb,

  constraint training_library_lessons_module_training_org_fkey
    foreign key (
      module_id,
      training_id,
      organization_id
    )
    references public.training_library_modules(
      id,
      training_id,
      organization_id
    )
    on delete restrict,

  constraint training_library_lessons_id_training_org_key
    unique (
      id,
      training_id,
      organization_id
    ),

  constraint training_library_lessons_module_sequence_key
    unique (
      module_id,
      sequence_no
    ),

  constraint training_library_lessons_sequence_check
    check (sequence_no > 0),

  constraint training_library_lessons_title_check
    check (btrim(title) <> ''),

  constraint training_library_lessons_type_check
    check (
      lesson_type in (
        'video',
        'slides',
        'document',
        'text',
        'interactive',
        'other'
      )
    ),

  constraint training_library_lessons_duration_check
    check (
      duration_minutes is null
      or duration_minutes > 0
    ),

  constraint training_library_lessons_status_check
    check (
      status in (
        'draft',
        'published',
        'archived'
      )
    ),

  constraint training_library_lessons_metadata_object_check
    check (
      jsonb_typeof(metadata) = 'object'
    )
);


-- ============================================================================
-- 3. PROGRESSO INDIVIDUAL POR AULA
-- ============================================================================

create table public.training_library_lesson_progress (
  id uuid primary key default gen_random_uuid(),

  organization_id uuid not null,

  training_id uuid not null,

  lesson_id uuid not null,

  user_id uuid not null
    references public.profiles(id)
    on delete restrict,

  status text not null default 'not_started',

  progress_percent integer not null default 0,

  started_at timestamptz,

  last_activity_at timestamptz not null default now(),

  completed_at timestamptz,

  created_at timestamptz not null default now(),
  created_by uuid,

  updated_at timestamptz not null default now(),
  updated_by uuid,

  metadata jsonb not null default '{}'::jsonb,

  constraint training_library_lesson_progress_lesson_training_org_fkey
    foreign key (
      lesson_id,
      training_id,
      organization_id
    )
    references public.training_library_lessons(
      id,
      training_id,
      organization_id
    )
    on delete restrict,

  constraint training_library_lesson_progress_user_lesson_key
    unique (
      user_id,
      lesson_id
    ),

  constraint training_library_lesson_progress_status_check
    check (
      status in (
        'not_started',
        'in_progress',
        'completed'
      )
    ),

  constraint training_library_lesson_progress_percent_check
    check (
      progress_percent between 0 and 100
    ),

  constraint training_library_lesson_progress_state_check
    check (
      (
        status = 'not_started'
        and progress_percent = 0
        and completed_at is null
      )
      or (
        status = 'in_progress'
        and progress_percent between 0 and 99
        and completed_at is null
      )
      or (
        status = 'completed'
        and progress_percent = 100
        and completed_at is not null
      )
    ),

  constraint training_library_lesson_progress_metadata_object_check
    check (
      jsonb_typeof(metadata) = 'object'
    )
);


-- ============================================================================
-- 4. ÍNDICES
-- ============================================================================

create index training_library_modules_org_training_status_sequence_idx
  on public.training_library_modules (
    organization_id,
    training_id,
    status,
    sequence_no
  );

create index training_library_lessons_org_training_module_status_sequence_idx
  on public.training_library_lessons (
    organization_id,
    training_id,
    module_id,
    status,
    sequence_no
  );

create index training_library_lesson_progress_user_training_idx
  on public.training_library_lesson_progress (
    user_id,
    training_id
  );

create index training_library_lesson_progress_org_training_status_idx
  on public.training_library_lesson_progress (
    organization_id,
    training_id,
    status
  );


-- ============================================================================
-- 5. METADADOS, ESCOPO ORGANIZACIONAL E AUDITORIA
-- ============================================================================

create trigger training_library_modules_set_row_metadata
before insert or update on public.training_library_modules
for each row
execute function private.set_row_metadata();

create trigger training_library_modules_guard_org
before update on public.training_library_modules
for each row
execute function private.guard_organization_scope();

create trigger training_library_modules_audit
after insert or update or delete on public.training_library_modules
for each row
execute function private.write_audit_log();


create trigger training_library_lessons_set_row_metadata
before insert or update on public.training_library_lessons
for each row
execute function private.set_row_metadata();

create trigger training_library_lessons_guard_org
before update on public.training_library_lessons
for each row
execute function private.guard_organization_scope();

create trigger training_library_lessons_audit
after insert or update or delete on public.training_library_lessons
for each row
execute function private.write_audit_log();


create trigger training_library_lesson_progress_set_row_metadata
before insert or update on public.training_library_lesson_progress
for each row
execute function private.set_row_metadata();

create trigger training_library_lesson_progress_guard_org
before update on public.training_library_lesson_progress
for each row
execute function private.guard_organization_scope();

create trigger training_library_lesson_progress_audit
after insert or update or delete on public.training_library_lesson_progress
for each row
execute function private.write_audit_log();


-- ============================================================================
-- 6. FUNÇÕES PRIVADAS DE AUTORIZAÇÃO
-- ============================================================================

create or replace function private.can_view_training_library_item(
  p_training_id uuid,
  p_organization_id uuid
)
returns boolean
language sql
stable
security definer
set search_path = ''
as $function$
  select exists (
    select 1
    from public.training_library_items item
    where item.id = p_training_id
      and item.organization_id = p_organization_id
      and (
        private.is_platform_admin()

        or private.has_org_role(
          item.organization_id,
          array['director']
        )

        or (
          item.status = 'published'

          and private.has_org_role(
            item.organization_id,
            item.audience_roles
          )
        )
      )
  );
$function$;

revoke all
on function private.can_view_training_library_item(uuid, uuid)
from public, anon, authenticated;

grant execute
on function private.can_view_training_library_item(uuid, uuid)
to authenticated;


create or replace function private.can_view_training_library_lesson(
  p_lesson_id uuid,
  p_organization_id uuid
)
returns boolean
language sql
stable
security definer
set search_path = ''
as $function$
  select exists (
    select 1
    from public.training_library_lessons lesson
    join public.training_library_modules module
      on module.id = lesson.module_id
     and module.training_id = lesson.training_id
     and module.organization_id = lesson.organization_id
    where lesson.id = p_lesson_id
      and lesson.organization_id = p_organization_id
      and (
        private.is_platform_admin()

        or private.has_org_role(
          lesson.organization_id,
          array['director']
        )

        or (
          lesson.status = 'published'
          and module.status = 'published'
          and private.can_view_training_library_item(
            lesson.training_id,
            lesson.organization_id
          )
        )
      )
  );
$function$;

revoke all
on function private.can_view_training_library_lesson(uuid, uuid)
from public, anon, authenticated;

grant execute
on function private.can_view_training_library_lesson(uuid, uuid)
to authenticated;


-- ============================================================================
-- 7. RLS E PRIVILÉGIOS
-- ============================================================================

alter table public.training_library_modules
  enable row level security;

alter table public.training_library_lessons
  enable row level security;

alter table public.training_library_lesson_progress
  enable row level security;


revoke all
on table public.training_library_modules
from anon, authenticated;

revoke all
on table public.training_library_lessons
from anon, authenticated;

revoke all
on table public.training_library_lesson_progress
from anon, authenticated;


grant select, insert, update
on table public.training_library_modules
to authenticated;

grant select, insert, update
on table public.training_library_lessons
to authenticated;

grant select, insert, update
on table public.training_library_lesson_progress
to authenticated;


-- ============================================================================
-- 8. RLS - MÓDULOS
-- ============================================================================

create policy training_library_modules_select_authorized
on public.training_library_modules
for select
to authenticated
using (
  private.is_platform_admin()

  or private.has_org_role(
    organization_id,
    array['director']
  )

  or (
    status = 'published'

    and private.can_view_training_library_item(
      training_id,
      organization_id
    )
  )
);


create policy training_library_modules_insert_management
on public.training_library_modules
for insert
to authenticated
with check (
  private.is_platform_admin()

  or private.has_org_role(
    organization_id,
    array['director']
  )
);


create policy training_library_modules_update_management
on public.training_library_modules
for update
to authenticated
using (
  private.is_platform_admin()

  or private.has_org_role(
    organization_id,
    array['director']
  )
)
with check (
  private.is_platform_admin()

  or private.has_org_role(
    organization_id,
    array['director']
  )
);


-- ============================================================================
-- 9. RLS - AULAS
-- ============================================================================

create policy training_library_lessons_select_authorized
on public.training_library_lessons
for select
to authenticated
using (
  private.can_view_training_library_lesson(
    id,
    organization_id
  )
);


create policy training_library_lessons_insert_management
on public.training_library_lessons
for insert
to authenticated
with check (
  private.is_platform_admin()

  or private.has_org_role(
    organization_id,
    array['director']
  )
);


create policy training_library_lessons_update_management
on public.training_library_lessons
for update
to authenticated
using (
  private.is_platform_admin()

  or private.has_org_role(
    organization_id,
    array['director']
  )
)
with check (
  private.is_platform_admin()

  or private.has_org_role(
    organization_id,
    array['director']
  )
);


-- ============================================================================
-- 10. RLS - PROGRESSO INDIVIDUAL
-- ============================================================================

create policy training_library_lesson_progress_select_authorized
on public.training_library_lesson_progress
for select
to authenticated
using (
  private.is_platform_admin()

  or private.has_org_role(
    organization_id,
    array['director']
  )

  or (
    user_id = (select auth.uid())

    and private.can_view_training_library_lesson(
      lesson_id,
      organization_id
    )
  )
);


create policy training_library_lesson_progress_insert_own
on public.training_library_lesson_progress
for insert
to authenticated
with check (
  user_id = (select auth.uid())

  and private.can_view_training_library_lesson(
    lesson_id,
    organization_id
  )
);


create policy training_library_lesson_progress_update_own
on public.training_library_lesson_progress
for update
to authenticated
using (
  user_id = (select auth.uid())

  and private.can_view_training_library_lesson(
    lesson_id,
    organization_id
  )
)
with check (
  user_id = (select auth.uid())

  and private.can_view_training_library_lesson(
    lesson_id,
    organization_id
  )
);


-- ============================================================================
-- 11. PÓS-CONDIÇÕES
-- ============================================================================

do $training_library_phase4a_postconditions$
declare
  v_modules_rls boolean;
  v_lessons_rls boolean;
  v_progress_rls boolean;
  v_existing_items bigint;
  v_existing_assets bigint;
begin
  select c.relrowsecurity
  into v_modules_rls
  from pg_catalog.pg_class c
  join pg_catalog.pg_namespace n
    on n.oid = c.relnamespace
  where n.nspname = 'public'
    and c.relname = 'training_library_modules';

  if coalesce(v_modules_rls, false) = false then
    raise exception
      'TRAINING_LIBRARY_PHASE4A_POSTCONDITION_FAILED: RLS ausente em training_library_modules';
  end if;


  select c.relrowsecurity
  into v_lessons_rls
  from pg_catalog.pg_class c
  join pg_catalog.pg_namespace n
    on n.oid = c.relnamespace
  where n.nspname = 'public'
    and c.relname = 'training_library_lessons';

  if coalesce(v_lessons_rls, false) = false then
    raise exception
      'TRAINING_LIBRARY_PHASE4A_POSTCONDITION_FAILED: RLS ausente em training_library_lessons';
  end if;


  select c.relrowsecurity
  into v_progress_rls
  from pg_catalog.pg_class c
  join pg_catalog.pg_namespace n
    on n.oid = c.relnamespace
  where n.nspname = 'public'
    and c.relname = 'training_library_lesson_progress';

  if coalesce(v_progress_rls, false) = false then
    raise exception
      'TRAINING_LIBRARY_PHASE4A_POSTCONDITION_FAILED: RLS ausente em training_library_lesson_progress';
  end if;


  select count(*)
  into v_existing_items
  from public.training_library_items;

  select count(*)
  into v_existing_assets
  from public.training_library_assets;

  if v_existing_items < 6 then
    raise exception
      'TRAINING_LIBRARY_PHASE4A_POSTCONDITION_FAILED: catálogo existente foi alterado inesperadamente';
  end if;

  if v_existing_assets < 8 then
    raise exception
      'TRAINING_LIBRARY_PHASE4A_POSTCONDITION_FAILED: assets existentes foram alterados inesperadamente';
  end if;
end;
$training_library_phase4a_postconditions$;
