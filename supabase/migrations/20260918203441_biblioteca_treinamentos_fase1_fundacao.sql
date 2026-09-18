-- ============================================================================
-- RF PERFORMANCE
-- Biblioteca de Treinamentos - Fase 1
-- Fundação: catálogo, materiais, bucket privado e RLS
--
-- Objetivos:
--   1. Preservar public.training_modules como trilha operacional do plano.
--   2. Criar uma biblioteca permanente de conteúdos de treinamento.
--   3. Permitir segmentação por papel organizacional.
--   4. Armazenar os arquivos em bucket privado.
--   5. Liberar leitura dos arquivos somente para usuários autorizados.
--   6. Reutilizar metadados, proteção de organização e auditoria existentes.
-- ============================================================================


-- ============================================================================
-- 1. CATÁLOGO DE TREINAMENTOS
-- ============================================================================

create table public.training_library_items (
  id uuid primary key default gen_random_uuid(),

  organization_id uuid not null
    references public.organizations(id)
    on delete restrict,

  sequence_no integer not null,

  title text not null,
  description text not null default '',

  category text not null default 'commercial_training',

  audience_roles text[] not null
    default array[
      'director',
      'supervisor',
      'salesperson'
    ]::text[],

  status text not null default 'draft',

  is_featured boolean not null default false,

  created_at timestamptz not null default now(),
  created_by uuid,

  updated_at timestamptz not null default now(),
  updated_by uuid,

  archived_at timestamptz,

  metadata jsonb not null default '{}'::jsonb,

  constraint training_library_items_id_org_key
    unique (id, organization_id),

  constraint training_library_items_org_sequence_key
    unique (organization_id, sequence_no),

  constraint training_library_items_sequence_check
    check (sequence_no > 0),

  constraint training_library_items_title_check
    check (btrim(title) <> ''),

  constraint training_library_items_category_check
    check (
      category in (
        'commercial_training',
        'sales_method',
        'leadership',
        'platform_guide',
        'other'
      )
    ),

  constraint training_library_items_status_check
    check (
      status in (
        'draft',
        'published',
        'archived'
      )
    ),

  constraint training_library_items_audience_not_empty_check
    check (
      cardinality(audience_roles) between 1 and 3
    ),

  constraint training_library_items_audience_roles_check
    check (
      audience_roles
        <@ array[
          'director',
          'supervisor',
          'salesperson'
        ]::text[]
      and array_position(audience_roles, null) is null
    ),

  constraint training_library_items_metadata_object_check
    check (
      jsonb_typeof(metadata) = 'object'
    )
);


-- ============================================================================
-- 2. ARQUIVOS / MATERIAIS DE CADA TREINAMENTO
-- ============================================================================

create table public.training_library_assets (
  id uuid primary key default gen_random_uuid(),

  organization_id uuid not null,

  training_id uuid not null,

  sequence_no integer not null default 1,

  asset_type text not null default 'primary',

  display_name text not null,

  storage_bucket text not null
    default 'training-materials',

  storage_path text not null,

  mime_type text not null,

  file_size_bytes bigint,

  status text not null default 'active',

  is_downloadable boolean not null default true,

  created_at timestamptz not null default now(),
  created_by uuid,

  updated_at timestamptz not null default now(),
  updated_by uuid,

  archived_at timestamptz,

  metadata jsonb not null default '{}'::jsonb,

  constraint training_library_assets_training_org_fkey
    foreign key (
      training_id,
      organization_id
    )
    references public.training_library_items(
      id,
      organization_id
    )
    on delete restrict,

  constraint training_library_assets_training_sequence_key
    unique (
      training_id,
      sequence_no
    ),

  constraint training_library_assets_storage_path_key
    unique (
      storage_bucket,
      storage_path
    ),

  constraint training_library_assets_sequence_check
    check (sequence_no > 0),

  constraint training_library_assets_display_name_check
    check (btrim(display_name) <> ''),

  constraint training_library_assets_storage_bucket_check
    check (
      storage_bucket = 'training-materials'
    ),

    constraint training_library_assets_storage_path_check
    check (
      btrim(storage_path) <> ''
    ),

  constraint training_library_assets_storage_scope_check
    check (
      storage_path like
        organization_id::text
        || '/'
        || training_id::text
        || '/%'
    ),

  constraint training_library_assets_mime_type_check
    check (
      btrim(mime_type) <> ''
    ),

  constraint training_library_assets_type_check
    check (
      asset_type in (
        'primary',
        'slides',
        'workbook',
        'attachment',
        'cover'
      )
    ),

  constraint training_library_assets_status_check
    check (
      status in (
        'active',
        'archived'
      )
    ),

  constraint training_library_assets_file_size_check
    check (
      file_size_bytes is null
      or file_size_bytes >= 0
    ),

  constraint training_library_assets_metadata_object_check
    check (
      jsonb_typeof(metadata) = 'object'
    )
);


-- ============================================================================
-- 3. ÍNDICES
-- ============================================================================

create index training_library_items_org_status_sequence_idx
  on public.training_library_items (
    organization_id,
    status,
    sequence_no
  );

create index training_library_assets_training_status_sequence_idx
  on public.training_library_assets (
    training_id,
    status,
    sequence_no
  );

create index training_library_assets_org_idx
  on public.training_library_assets (
    organization_id
  );


-- ============================================================================
-- 4. METADADOS, ESCOPO ORGANIZACIONAL E AUDITORIA
-- ============================================================================

create trigger training_library_items_set_row_metadata
before insert or update on public.training_library_items
for each row
execute function private.set_row_metadata();

create trigger training_library_items_guard_org
before update on public.training_library_items
for each row
execute function private.guard_organization_scope();

create trigger training_library_items_audit
after insert or update or delete on public.training_library_items
for each row
execute function private.write_audit_log();


create trigger training_library_assets_set_row_metadata
before insert or update on public.training_library_assets
for each row
execute function private.set_row_metadata();

create trigger training_library_assets_guard_org
before update on public.training_library_assets
for each row
execute function private.guard_organization_scope();

create trigger training_library_assets_audit
after insert or update or delete on public.training_library_assets
for each row
execute function private.write_audit_log();


-- ============================================================================
-- 5. RLS DAS TABELAS
-- ============================================================================

alter table public.training_library_items
  enable row level security;

alter table public.training_library_assets
  enable row level security;


revoke all
on table public.training_library_items
from anon, authenticated;

revoke all
on table public.training_library_assets
from anon, authenticated;


grant select, insert, update
on table public.training_library_items
to authenticated;

grant select, insert, update
on table public.training_library_assets
to authenticated;


-- --------------------------------------------------------------------------
-- Catálogo: leitura
--
-- Admin:
--   vê tudo.
--
-- Diretor:
--   vê tudo da própria organização, inclusive rascunhos.
--
-- Supervisor / vendedor:
--   vê somente treinamento publicado e cujo papel esteja em audience_roles.
-- --------------------------------------------------------------------------

create policy training_library_items_select_authorized
on public.training_library_items
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

    and private.has_org_role(
      organization_id,
      audience_roles
    )
  )
);


-- --------------------------------------------------------------------------
-- Catálogo: criação e atualização
-- --------------------------------------------------------------------------

create policy training_library_items_insert_management
on public.training_library_items
for insert
to authenticated
with check (
  private.is_platform_admin()

  or private.has_org_role(
    organization_id,
    array['director']
  )
);


create policy training_library_items_update_management
on public.training_library_items
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


-- --------------------------------------------------------------------------
-- Materiais: leitura
--
-- O usuário somente enxerga um material ativo se também puder enxergar
-- o treinamento pai.
-- --------------------------------------------------------------------------

create policy training_library_assets_select_authorized
on public.training_library_assets
for select
to authenticated
using (
  private.is_platform_admin()

  or private.has_org_role(
    organization_id,
    array['director']
  )

  or (
    status = 'active'

    and exists (
      select 1
      from public.training_library_items item
      where item.id = training_library_assets.training_id
        and item.organization_id = training_library_assets.organization_id
        and item.status = 'published'
        and private.has_org_role(
          item.organization_id,
          item.audience_roles
        )
    )
  )
);


-- --------------------------------------------------------------------------
-- Materiais: criação e atualização
-- --------------------------------------------------------------------------

create policy training_library_assets_insert_management
on public.training_library_assets
for insert
to authenticated
with check (
  private.is_platform_admin()

  or private.has_org_role(
    organization_id,
    array['director']
  )
);


create policy training_library_assets_update_management
on public.training_library_assets
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
-- 6. FUNÇÃO PRIVADA PARA AUTORIZAR LEITURA NO STORAGE
-- ============================================================================

create or replace function private.can_view_training_storage_object(
  p_storage_path text
)
returns boolean
language sql
stable
security definer
set search_path = ''
as $function$
  select exists (
    select 1
    from public.training_library_assets asset
    join public.training_library_items item
      on item.id = asset.training_id
     and item.organization_id = asset.organization_id
    where asset.storage_bucket = 'training-materials'
      and asset.storage_path = p_storage_path
      and (
        private.is_platform_admin()

        or private.has_org_role(
          item.organization_id,
          array['director']
        )

        or (
          asset.status = 'active'
          and item.status = 'published'

          and private.has_org_role(
            item.organization_id,
            item.audience_roles
          )
        )
      )
  );
$function$;


revoke all
on function private.can_view_training_storage_object(text)
from public, anon, authenticated;

grant execute
on function private.can_view_training_storage_object(text)
to authenticated;


-- ============================================================================
-- 7. BUCKET PRIVADO
-- ============================================================================

insert into storage.buckets (
  id,
  name,
  public,
  file_size_limit,
  allowed_mime_types
)
values (
  'training-materials',
  'training-materials',
  false,
  104857600,
  array[
    'application/pdf',
    'application/vnd.ms-powerpoint',
    'application/vnd.openxmlformats-officedocument.presentationml.presentation',
    'application/msword',
    'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
    'image/jpeg',
    'image/png',
    'image/webp'
  ]::text[]
);


-- ============================================================================
-- 8. STORAGE RLS
--
-- Nesta fase:
--   - usuários autenticados autorizados podem LER arquivos;
--   - não existe upload/update/delete via aplicação;
--   - carga inicial será administrativa/controlada.
-- ============================================================================

create policy training_materials_select_authorized
on storage.objects
for select
to authenticated
using (
  bucket_id = 'training-materials'

  and private.can_view_training_storage_object(name)
);


-- ============================================================================
-- 9. PÓS-CONDIÇÕES
-- ============================================================================

do $training_library_postconditions$
declare
  v_bucket_public boolean;
  v_items_rls boolean;
  v_assets_rls boolean;
begin
  select b.public
  into v_bucket_public
  from storage.buckets b
  where b.id = 'training-materials';

  if v_bucket_public is null then
    raise exception
      'TRAINING_LIBRARY_POSTCONDITION_FAILED: bucket training-materials ausente';
  end if;

  if v_bucket_public then
    raise exception
      'TRAINING_LIBRARY_POSTCONDITION_FAILED: bucket training-materials não está privado';
  end if;


  select c.relrowsecurity
  into v_items_rls
  from pg_catalog.pg_class c
  join pg_catalog.pg_namespace n
    on n.oid = c.relnamespace
  where n.nspname = 'public'
    and c.relname = 'training_library_items';

  if coalesce(v_items_rls, false) = false then
    raise exception
      'TRAINING_LIBRARY_POSTCONDITION_FAILED: RLS ausente em training_library_items';
  end if;


  select c.relrowsecurity
  into v_assets_rls
  from pg_catalog.pg_class c
  join pg_catalog.pg_namespace n
    on n.oid = c.relnamespace
  where n.nspname = 'public'
    and c.relname = 'training_library_assets';

  if coalesce(v_assets_rls, false) = false then
    raise exception
      'TRAINING_LIBRARY_POSTCONDITION_FAILED: RLS ausente em training_library_assets';
  end if;
end;
$training_library_postconditions$;