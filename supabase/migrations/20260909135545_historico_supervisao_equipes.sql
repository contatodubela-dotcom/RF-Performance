-- ============================================================================
-- RF PERFORMANCE
-- Histórico de supervisão das equipes
-- Migration: 20260909135545_historico_supervisao_equipes.sql
--
-- Objetivos desta fase:
-- 1. criar histórico temporal de supervisores por equipe;
-- 2. reconstruir o histórico existente a partir de public.audit_logs;
-- 3. preservar snapshots mesmo após exclusão de membership/profile;
-- 4. manter public.teams.supervisor_member_id como ponteiro do supervisor atual;
-- 5. preparar sincronização automática para futuras mudanças de supervisor;
-- 6. permitir que um supervisor responda por mais de uma equipe simultaneamente.
--
-- IMPORTANTE:
-- - não altera vínculos de vendedores;
-- - não remove dados históricos;
-- - não cria unicidade por supervisor;
-- - vínculos históricos podem referenciar memberships já removidos.
-- ============================================================================

begin;

-- ============================================================================
-- 1. PREFLIGHT DEFENSIVO
-- ============================================================================

do $preflight$
begin
  -- --------------------------------------------------------------------------
  -- Tabelas obrigatórias
  -- --------------------------------------------------------------------------

  if pg_catalog.to_regclass('public.organizations') is null then
    raise exception
      'SUPERVISION_HISTORY_PREFLIGHT_FAILED: public.organizations não encontrada';
  end if;

  if pg_catalog.to_regclass('public.teams') is null then
    raise exception
      'SUPERVISION_HISTORY_PREFLIGHT_FAILED: public.teams não encontrada';
  end if;

  if pg_catalog.to_regclass('public.organization_members') is null then
    raise exception
      'SUPERVISION_HISTORY_PREFLIGHT_FAILED: public.organization_members não encontrada';
  end if;

  if pg_catalog.to_regclass('public.profiles') is null then
    raise exception
      'SUPERVISION_HISTORY_PREFLIGHT_FAILED: public.profiles não encontrada';
  end if;

  if pg_catalog.to_regclass('public.audit_logs') is null then
    raise exception
      'SUPERVISION_HISTORY_PREFLIGHT_FAILED: public.audit_logs não encontrada';
  end if;

  -- Esta migration é responsável pela criação da tabela histórica.
  if pg_catalog.to_regclass('public.team_supervisor_assignments') is not null then
    raise exception
      'SUPERVISION_HISTORY_PREFLIGHT_FAILED: public.team_supervisor_assignments já existe';
  end if;

  -- --------------------------------------------------------------------------
  -- Colunas essenciais de public.teams
  -- --------------------------------------------------------------------------

  if not exists (
    select 1
    from information_schema.columns
    where table_schema = 'public'
      and table_name = 'teams'
      and column_name = 'id'
      and data_type = 'uuid'
  ) then
    raise exception
      'SUPERVISION_HISTORY_PREFLIGHT_FAILED: teams.id ausente ou incompatível';
  end if;

  if not exists (
    select 1
    from information_schema.columns
    where table_schema = 'public'
      and table_name = 'teams'
      and column_name = 'organization_id'
      and data_type = 'uuid'
  ) then
    raise exception
      'SUPERVISION_HISTORY_PREFLIGHT_FAILED: teams.organization_id ausente ou incompatível';
  end if;

  if not exists (
    select 1
    from information_schema.columns
    where table_schema = 'public'
      and table_name = 'teams'
      and column_name = 'supervisor_member_id'
      and data_type = 'uuid'
  ) then
    raise exception
      'SUPERVISION_HISTORY_PREFLIGHT_FAILED: teams.supervisor_member_id ausente ou incompatível';
  end if;

  -- --------------------------------------------------------------------------
  -- Colunas essenciais de public.organization_members
  -- --------------------------------------------------------------------------

  if not exists (
    select 1
    from information_schema.columns
    where table_schema = 'public'
      and table_name = 'organization_members'
      and column_name = 'user_id'
      and data_type = 'uuid'
  ) then
    raise exception
      'SUPERVISION_HISTORY_PREFLIGHT_FAILED: organization_members.user_id ausente ou incompatível';
  end if;

  -- --------------------------------------------------------------------------
  -- Coluna necessária para snapshot legível do supervisor
  -- --------------------------------------------------------------------------

  if not exists (
    select 1
    from information_schema.columns
    where table_schema = 'public'
      and table_name = 'profiles'
      and column_name = 'full_name'
  ) then
    raise exception
      'SUPERVISION_HISTORY_PREFLIGHT_FAILED: profiles.full_name não encontrada';
  end if;

  -- --------------------------------------------------------------------------
  -- Colunas essenciais da trilha histórica
  -- --------------------------------------------------------------------------

  if not exists (
    select 1
    from information_schema.columns
    where table_schema = 'public'
      and table_name = 'audit_logs'
      and column_name = 'id'
      and data_type = 'uuid'
  ) then
    raise exception
      'SUPERVISION_HISTORY_PREFLIGHT_FAILED: audit_logs.id ausente ou incompatível';
  end if;

  if not exists (
    select 1
    from information_schema.columns
    where table_schema = 'public'
      and table_name = 'audit_logs'
      and column_name = 'entity_type'
  ) then
    raise exception
      'SUPERVISION_HISTORY_PREFLIGHT_FAILED: audit_logs.entity_type não encontrada';
  end if;

  if not exists (
    select 1
    from information_schema.columns
    where table_schema = 'public'
      and table_name = 'audit_logs'
      and column_name = 'entity_id'
      and data_type = 'uuid'
  ) then
    raise exception
      'SUPERVISION_HISTORY_PREFLIGHT_FAILED: audit_logs.entity_id ausente ou incompatível';
  end if;

  if not exists (
    select 1
    from information_schema.columns
    where table_schema = 'public'
      and table_name = 'audit_logs'
      and column_name = 'old_values'
      and data_type = 'jsonb'
  ) then
    raise exception
      'SUPERVISION_HISTORY_PREFLIGHT_FAILED: audit_logs.old_values ausente ou incompatível';
  end if;

  if not exists (
    select 1
    from information_schema.columns
    where table_schema = 'public'
      and table_name = 'audit_logs'
      and column_name = 'new_values'
      and data_type = 'jsonb'
  ) then
    raise exception
      'SUPERVISION_HISTORY_PREFLIGHT_FAILED: audit_logs.new_values ausente ou incompatível';
  end if;

  if not exists (
    select 1
    from information_schema.columns
    where table_schema = 'public'
      and table_name = 'audit_logs'
      and column_name = 'created_at'
      and data_type = 'timestamp with time zone'
  ) then
    raise exception
      'SUPERVISION_HISTORY_PREFLIGHT_FAILED: audit_logs.created_at ausente ou incompatível';
  end if;

  -- --------------------------------------------------------------------------
  -- Função de auditoria já existente no projeto
  -- --------------------------------------------------------------------------

  if pg_catalog.to_regprocedure('private.write_audit_log()') is null then
    raise exception
      'SUPERVISION_HISTORY_PREFLIGHT_FAILED: private.write_audit_log() não encontrada';
  end if;
end
$preflight$;
-- ============================================================================
-- 2. TABELA HISTÓRICA DE SUPERVISÃO
-- ============================================================================

create table public.team_supervisor_assignments (
  id uuid primary key default gen_random_uuid(),

  organization_id uuid not null,
  team_id uuid not null,

  -- UUID histórico do membership do supervisor.
  -- Intencionalmente sem FK para organization_members:
  -- memberships removidos precisam continuar preservados no histórico.
  supervisor_member_id uuid not null,

  -- Snapshots independentes do estado atual de profiles/organization_members.
  supervisor_user_id_snapshot uuid not null,
  supervisor_name_snapshot text not null,

  start_at timestamptz not null,
  end_at timestamptz,

  status text not null default 'active',

  created_at timestamptz not null default now(),
  created_by uuid,
  updated_at timestamptz not null default now(),
  updated_by uuid,

  metadata jsonb not null default '{}'::jsonb,

  constraint team_supervisor_assignments_org_fkey
    foreign key (organization_id)
    references public.organizations(id)
    on delete restrict,

  constraint team_supervisor_assignments_team_org_fkey
    foreign key (team_id, organization_id)
    references public.teams(id, organization_id)
    on delete restrict,

  constraint team_supervisor_assignments_status_check
    check (status in ('active', 'inactive')),

  constraint team_supervisor_assignments_period_check
    check (
      (
        status = 'active'
        and end_at is null
      )
      or
      (
        status = 'inactive'
        and end_at is not null
        and end_at >= start_at
      )
    ),

  constraint team_supervisor_assignments_name_check
    check (length(btrim(supervisor_name_snapshot)) > 0),

  constraint team_supervisor_assignments_metadata_object_check
    check (jsonb_typeof(metadata) = 'object')
);

-- Uma equipe pode possuir somente um período de supervisão ativo por vez.
-- Não existe unicidade por supervisor: o mesmo supervisor pode responder
-- simultaneamente por mais de uma equipe.
create unique index team_supervisor_assignments_one_active_per_team_uidx
  on public.team_supervisor_assignments (organization_id, team_id)
  where status = 'active' and end_at is null;

create index team_supervisor_assignments_team_history_idx
  on public.team_supervisor_assignments (
    organization_id,
    team_id,
    start_at desc
  );

create index team_supervisor_assignments_supervisor_history_idx
  on public.team_supervisor_assignments (
    organization_id,
    supervisor_member_id,
    start_at desc
  );

create index team_supervisor_assignments_user_history_idx
  on public.team_supervisor_assignments (
    organization_id,
    supervisor_user_id_snapshot,
    start_at desc
  );

comment on table public.team_supervisor_assignments is
  'Histórico temporal de supervisores por equipe. Preserva snapshots mesmo após remoção do membership ou profile.';

comment on column public.team_supervisor_assignments.supervisor_member_id is
  'UUID histórico do organization_member do supervisor. Não possui FK intencionalmente para preservar memberships removidos.';

comment on column public.team_supervisor_assignments.supervisor_user_id_snapshot is
  'Snapshot do user_id vigente no momento do vínculo de supervisão.';

comment on column public.team_supervisor_assignments.supervisor_name_snapshot is
  'Snapshot legível do nome do supervisor no período histórico.';
  -- ============================================================================
-- 3. BACKFILL DO HISTÓRICO EXISTENTE
--
-- Reconstrói os períodos reais a partir das mudanças auditadas em
-- public.teams.supervisor_member_id.
--
-- O evento que atribui um supervisor abre o período.
-- A próxima mudança de supervisor da mesma equipe encerra o período anterior.
-- Mudanças para NULL encerram o vínculo sem criar um novo.
-- ============================================================================

do $backfill_preflight$
declare
  v_unresolved_count integer;
begin
  with supervisor_changes as (
    select
      t.organization_id,
      t.id as team_id,
      al.id as source_audit_log_id,
      al.user_id as start_actor_user_id,
      al.created_at as start_at,
      nullif(
        al.new_values ->> 'supervisor_member_id',
        ''
      )::uuid as supervisor_member_id,
      lead(al.id) over (
        partition by t.id
        order by al.created_at, al.id
      ) as end_audit_log_id,
      lead(al.user_id) over (
        partition by t.id
        order by al.created_at, al.id
      ) as end_actor_user_id,
      lead(al.created_at) over (
        partition by t.id
        order by al.created_at, al.id
      ) as end_at
    from public.audit_logs al
    join public.teams t
      on t.id = al.entity_id
    where al.entity_type = 'teams'
      and coalesce(
        al.old_values ->> 'supervisor_member_id',
        ''
      ) is distinct from coalesce(
        al.new_values ->> 'supervisor_member_id',
        ''
      )
  ),
  intervals as (
    select *
    from supervisor_changes
    where supervisor_member_id is not null
  ),
  resolved_users as (
    select
      i.*,
      coalesce(
        om.user_id,
        historical_member.user_id
      ) as supervisor_user_id_snapshot
    from intervals i
    left join public.organization_members om
      on om.id = i.supervisor_member_id
     and om.organization_id = i.organization_id

    left join lateral (
      select
        coalesce(
          nullif(al.new_values ->> 'user_id', ''),
          nullif(al.old_values ->> 'user_id', '')
        )::uuid as user_id
      from public.audit_logs al
      where al.entity_type = 'organization_members'
        and al.entity_id = i.supervisor_member_id
        and coalesce(
          nullif(al.new_values ->> 'user_id', ''),
          nullif(al.old_values ->> 'user_id', '')
        ) is not null
      order by al.created_at desc, al.id desc
      limit 1
    ) historical_member
      on true
  ),
  resolved_snapshots as (
    select
      r.*,
      coalesce(
        name_at_start.full_name,
        p.full_name,
        historical_name.full_name
      ) as supervisor_name_snapshot
    from resolved_users r

    left join public.profiles p
      on p.id = r.supervisor_user_id_snapshot

    -- Preferência: nome auditado vigente no início daquele período.
    left join lateral (
      select
        coalesce(
          nullif(al.new_values ->> 'full_name', ''),
          nullif(al.old_values ->> 'full_name', '')
        ) as full_name
      from public.audit_logs al
      where al.entity_type = 'profiles'
        and al.entity_id = r.supervisor_user_id_snapshot
        and al.created_at <= r.start_at
        and coalesce(
          nullif(al.new_values ->> 'full_name', ''),
          nullif(al.old_values ->> 'full_name', '')
        ) is not null
      order by al.created_at desc, al.id desc
      limit 1
    ) name_at_start
      on true

    -- Fallback para perfis posteriormente removidos.
    left join lateral (
      select
        coalesce(
          nullif(al.new_values ->> 'full_name', ''),
          nullif(al.old_values ->> 'full_name', '')
        ) as full_name
      from public.audit_logs al
      where al.entity_type = 'profiles'
        and al.entity_id = r.supervisor_user_id_snapshot
        and coalesce(
          nullif(al.new_values ->> 'full_name', ''),
          nullif(al.old_values ->> 'full_name', '')
        ) is not null
      order by al.created_at desc, al.id desc
      limit 1
    ) historical_name
      on true
  )
  select count(*)
    into v_unresolved_count
  from resolved_snapshots
  where supervisor_user_id_snapshot is null
     or supervisor_name_snapshot is null
     or btrim(supervisor_name_snapshot) = '';

  if v_unresolved_count <> 0 then
    raise exception
      'SUPERVISION_HISTORY_BACKFILL_FAILED: % período(s) sem identidade histórica resolvida',
      v_unresolved_count;
  end if;
end
$backfill_preflight$;


with supervisor_changes as (
  select
    t.organization_id,
    t.id as team_id,
    al.id as source_audit_log_id,
    al.user_id as start_actor_user_id,
    al.created_at as start_at,

    nullif(
      al.new_values ->> 'supervisor_member_id',
      ''
    )::uuid as supervisor_member_id,

    lead(al.id) over (
      partition by t.id
      order by al.created_at, al.id
    ) as end_audit_log_id,

    lead(al.user_id) over (
      partition by t.id
      order by al.created_at, al.id
    ) as end_actor_user_id,

    lead(al.created_at) over (
      partition by t.id
      order by al.created_at, al.id
    ) as end_at

  from public.audit_logs al

  join public.teams t
    on t.id = al.entity_id

  where al.entity_type = 'teams'
    and coalesce(
      al.old_values ->> 'supervisor_member_id',
      ''
    ) is distinct from coalesce(
      al.new_values ->> 'supervisor_member_id',
      ''
    )
),

intervals as (
  select *
  from supervisor_changes
  where supervisor_member_id is not null
),

resolved_users as (
  select
    i.*,

    coalesce(
      om.user_id,
      historical_member.user_id
    ) as supervisor_user_id_snapshot

  from intervals i

  left join public.organization_members om
    on om.id = i.supervisor_member_id
   and om.organization_id = i.organization_id

  left join lateral (
    select
      coalesce(
        nullif(al.new_values ->> 'user_id', ''),
        nullif(al.old_values ->> 'user_id', '')
      )::uuid as user_id

    from public.audit_logs al

    where al.entity_type = 'organization_members'
      and al.entity_id = i.supervisor_member_id
      and coalesce(
        nullif(al.new_values ->> 'user_id', ''),
        nullif(al.old_values ->> 'user_id', '')
      ) is not null

    order by al.created_at desc, al.id desc
    limit 1
  ) historical_member
    on true
),

resolved_snapshots as (
  select
    r.*,

    coalesce(
      name_at_start.full_name,
      p.full_name,
      historical_name.full_name
    ) as supervisor_name_snapshot

  from resolved_users r

  left join public.profiles p
    on p.id = r.supervisor_user_id_snapshot

  left join lateral (
    select
      coalesce(
        nullif(al.new_values ->> 'full_name', ''),
        nullif(al.old_values ->> 'full_name', '')
      ) as full_name

    from public.audit_logs al

    where al.entity_type = 'profiles'
      and al.entity_id = r.supervisor_user_id_snapshot
      and al.created_at <= r.start_at
      and coalesce(
        nullif(al.new_values ->> 'full_name', ''),
        nullif(al.old_values ->> 'full_name', '')
      ) is not null

    order by al.created_at desc, al.id desc
    limit 1
  ) name_at_start
    on true

  left join lateral (
    select
      coalesce(
        nullif(al.new_values ->> 'full_name', ''),
        nullif(al.old_values ->> 'full_name', '')
      ) as full_name

    from public.audit_logs al

    where al.entity_type = 'profiles'
      and al.entity_id = r.supervisor_user_id_snapshot
      and coalesce(
        nullif(al.new_values ->> 'full_name', ''),
        nullif(al.old_values ->> 'full_name', '')
      ) is not null

    order by al.created_at desc, al.id desc
    limit 1
  ) historical_name
    on true
)

insert into public.team_supervisor_assignments (
  organization_id,
  team_id,
  supervisor_member_id,
  supervisor_user_id_snapshot,
  supervisor_name_snapshot,
  start_at,
  end_at,
  status,
  created_at,
  created_by,
  updated_at,
  updated_by,
  metadata
)
select
  r.organization_id,
  r.team_id,
  r.supervisor_member_id,
  r.supervisor_user_id_snapshot,
  btrim(r.supervisor_name_snapshot),
  r.start_at,
  r.end_at,

  case
    when r.end_at is null then 'active'
    else 'inactive'
  end,

  r.start_at,
  r.start_actor_user_id,

  coalesce(
    r.end_at,
    r.start_at
  ),

  coalesce(
    r.end_actor_user_id,
    r.start_actor_user_id
  ),

  jsonb_build_object(
    'history_source', 'audit_logs_backfill',
    'source_team_audit_log_id', r.source_audit_log_id,
    'end_team_audit_log_id', r.end_audit_log_id
  )

from resolved_snapshots r
order by r.team_id, r.start_at;


-- ============================================================================
-- 3.1 PÓS-CONDIÇÕES DO BACKFILL
-- ============================================================================

do $backfill_postcondition$
declare
  v_expected_intervals integer;
  v_inserted_intervals integer;
  v_expected_active integer;
  v_inserted_active integer;
begin
  with supervisor_changes as (
    select
      t.id as team_id,
      nullif(
        al.new_values ->> 'supervisor_member_id',
        ''
      )::uuid as supervisor_member_id
    from public.audit_logs al
    join public.teams t
      on t.id = al.entity_id
    where al.entity_type = 'teams'
      and coalesce(
        al.old_values ->> 'supervisor_member_id',
        ''
      ) is distinct from coalesce(
        al.new_values ->> 'supervisor_member_id',
        ''
      )
  )
  select count(*)
    into v_expected_intervals
  from supervisor_changes
  where supervisor_member_id is not null;

  select count(*)
    into v_inserted_intervals
  from public.team_supervisor_assignments;

  if v_inserted_intervals <> v_expected_intervals then
    raise exception
      'SUPERVISION_HISTORY_BACKFILL_FAILED: esperado % período(s), inserido(s) %',
      v_expected_intervals,
      v_inserted_intervals;
  end if;

  select count(*)
    into v_expected_active
  from public.teams
  where supervisor_member_id is not null;

  select count(*)
    into v_inserted_active
  from public.team_supervisor_assignments
  where status = 'active'
    and end_at is null;

  if v_inserted_active <> v_expected_active then
    raise exception
      'SUPERVISION_HISTORY_BACKFILL_FAILED: esperado % vínculo(s) ativo(s), inserido(s) %',
      v_expected_active,
      v_inserted_active;
  end if;

  if exists (
    select 1
    from public.teams t

    left join public.team_supervisor_assignments tsa
      on tsa.organization_id = t.organization_id
     and tsa.team_id = t.id
     and tsa.status = 'active'
     and tsa.end_at is null

    where t.supervisor_member_id
      is distinct from tsa.supervisor_member_id
  ) then
    raise exception
      'SUPERVISION_HISTORY_BACKFILL_FAILED: supervisor atual diverge do histórico ativo';
  end if;
end
$backfill_postcondition$;
-- ============================================================================
-- 4. SINCRONIZAÇÃO AUTOMÁTICA DO HISTÓRICO DE SUPERVISÃO
--
-- Fonte corrente:
--   public.teams.supervisor_member_id
--
-- Regra de supervisão efetiva:
--   - equipe ativa;
--   - não arquivada;
--   - supervisor_member_id definido.
--
-- Eventos tratados:
--   - criação de equipe já com supervisor;
--   - atribuição inicial de supervisor;
--   - troca A -> B;
--   - remoção A -> NULL;
--   - inativação/arquivamento da equipe;
--   - reativação da equipe preservando supervisor.
--
-- A função NÃO movimenta vendedores.
-- ============================================================================

create or replace function private.sync_team_supervisor_history()
returns trigger
language plpgsql
security definer
set search_path = ''
as $function$
declare
  v_old_effective_supervisor uuid;
  v_new_effective_supervisor uuid;

  v_supervisor_user_id uuid;
  v_supervisor_name text;

  v_actor_user_id uuid;
  v_changed_at timestamptz;

  v_closed_rows integer;
begin
  v_changed_at := now();
  v_actor_user_id := auth.uid();

  -- --------------------------------------------------------------------------
  -- Supervisor efetivo antes da alteração
  -- --------------------------------------------------------------------------

  if tg_op = 'UPDATE'
     and old.status = 'active'
     and old.archived_at is null
     and old.supervisor_member_id is not null then

    v_old_effective_supervisor := old.supervisor_member_id;
  else
    v_old_effective_supervisor := null;
  end if;

  -- --------------------------------------------------------------------------
  -- Supervisor efetivo depois da alteração
  -- --------------------------------------------------------------------------

  if new.status = 'active'
     and new.archived_at is null
     and new.supervisor_member_id is not null then

    v_new_effective_supervisor := new.supervisor_member_id;
  else
    v_new_effective_supervisor := null;
  end if;

  -- Nenhuma mudança efetiva de supervisão.
  if v_old_effective_supervisor
       is not distinct from
       v_new_effective_supervisor then
    return null;
  end if;

  -- --------------------------------------------------------------------------
  -- Encerra o período anterior, quando existir.
  -- --------------------------------------------------------------------------

  if v_old_effective_supervisor is not null then
    update public.team_supervisor_assignments
    set
      end_at = v_changed_at,
      status = 'inactive',
      updated_at = v_changed_at,
      updated_by = v_actor_user_id,
      metadata =
        metadata
        || jsonb_build_object(
          'end_source',
          'teams_sync_supervisor_history',
          'ended_at',
          v_changed_at,
          'ended_by',
          v_actor_user_id,
          'next_supervisor_member_id',
          v_new_effective_supervisor
        )
    where organization_id = old.organization_id
      and team_id = old.id
      and supervisor_member_id = v_old_effective_supervisor
      and status = 'active'
      and end_at is null;

    get diagnostics v_closed_rows = row_count;

    if v_closed_rows <> 1 then
      raise exception
        'SUPERVISION_HISTORY_SYNC_FAILED: esperado 1 vínculo ativo anterior para equipe %, encontrado(s) %',
        old.id,
        v_closed_rows;
    end if;
  end if;

  -- --------------------------------------------------------------------------
  -- Se a nova situação não possui supervisor efetivo, apenas encerra.
  -- --------------------------------------------------------------------------

  if v_new_effective_supervisor is null then
    return null;
  end if;

  -- --------------------------------------------------------------------------
  -- Resolve identidade do novo supervisor.
  --
  -- Para vínculo novo e ativo, o membership obrigatoriamente precisa existir
  -- e continuar válido. A validação estrutural de teams já ocorre antes deste
  -- trigger, mas repetimos a leitura para obter os snapshots.
  -- --------------------------------------------------------------------------

  select
    om.user_id,

    coalesce(
      nullif(btrim(p.full_name), ''),
      historical_name.full_name
    )

  into
    v_supervisor_user_id,
    v_supervisor_name

  from public.organization_members om

  left join public.profiles p
    on p.id = om.user_id

  left join lateral (
    select
      coalesce(
        nullif(al.new_values ->> 'full_name', ''),
        nullif(al.old_values ->> 'full_name', '')
      ) as full_name

    from public.audit_logs al

    where al.entity_type = 'profiles'
      and al.entity_id = om.user_id
      and coalesce(
        nullif(al.new_values ->> 'full_name', ''),
        nullif(al.old_values ->> 'full_name', '')
      ) is not null

    order by al.created_at desc, al.id desc
    limit 1
  ) historical_name
    on true

  where om.id = v_new_effective_supervisor
    and om.organization_id = new.organization_id
    and om.role = 'supervisor'
    and om.status = 'active'
    and om.archived_at is null;

  if not found then
    raise exception
      'SUPERVISION_HISTORY_SYNC_FAILED: novo supervisor % não é membership supervisor ativo da organização %',
      v_new_effective_supervisor,
      new.organization_id;
  end if;

  if v_supervisor_user_id is null then
    raise exception
      'SUPERVISION_HISTORY_SYNC_FAILED: user_id não resolvido para supervisor %',
      v_new_effective_supervisor;
  end if;

  if v_supervisor_name is null
     or btrim(v_supervisor_name) = '' then
    raise exception
      'SUPERVISION_HISTORY_SYNC_FAILED: nome não resolvido para supervisor %',
      v_new_effective_supervisor;
  end if;

  -- --------------------------------------------------------------------------
  -- Abre o novo período.
  -- --------------------------------------------------------------------------

  insert into public.team_supervisor_assignments (
    organization_id,
    team_id,
    supervisor_member_id,
    supervisor_user_id_snapshot,
    supervisor_name_snapshot,
    start_at,
    end_at,
    status,
    created_at,
    created_by,
    updated_at,
    updated_by,
    metadata
  )
  values (
    new.organization_id,
    new.id,
    v_new_effective_supervisor,
    v_supervisor_user_id,
    btrim(v_supervisor_name),
    v_changed_at,
    null,
    'active',
    v_changed_at,
    v_actor_user_id,
    v_changed_at,
    v_actor_user_id,
    jsonb_build_object(
      'history_source',
      'teams_sync_supervisor_history',
      'started_at',
      v_changed_at,
      'started_by',
      v_actor_user_id,
      'previous_supervisor_member_id',
      v_old_effective_supervisor
    )
  );

  return null;
end;
$function$;


revoke all
on function private.sync_team_supervisor_history()
from public;


create trigger teams_sync_supervisor_history
after insert or update of
  supervisor_member_id,
  status,
  archived_at
on public.teams
for each row
execute function private.sync_team_supervisor_history();


-- ============================================================================
-- 4.1 PÓS-CONDIÇÕES DA SINCRONIZAÇÃO
-- ============================================================================

do $sync_postcondition$
declare
  v_trigger_definition text;
begin
  if pg_catalog.to_regprocedure(
    'private.sync_team_supervisor_history()'
  ) is null then
    raise exception
      'SUPERVISION_HISTORY_SYNC_POSTCONDITION_FAILED: função de sincronização ausente';
  end if;

  select pg_catalog.pg_get_triggerdef(tg.oid, true)
    into v_trigger_definition
  from pg_catalog.pg_trigger tg
  join pg_catalog.pg_class c
    on c.oid = tg.tgrelid
  join pg_catalog.pg_namespace n
    on n.oid = c.relnamespace
  where n.nspname = 'public'
    and c.relname = 'teams'
    and tg.tgname = 'teams_sync_supervisor_history'
    and not tg.tgisinternal
  limit 1;

  if v_trigger_definition is null then
    raise exception
      'SUPERVISION_HISTORY_SYNC_POSTCONDITION_FAILED: trigger de sincronização ausente';
  end if;

  if v_trigger_definition not ilike '%AFTER%'
     or v_trigger_definition not ilike '%INSERT%'
     or v_trigger_definition not ilike '%UPDATE%'
     or v_trigger_definition not ilike '%supervisor_member_id%'
     or v_trigger_definition not ilike '%status%'
     or v_trigger_definition not ilike '%archived_at%' then
    raise exception
      'SUPERVISION_HISTORY_SYNC_POSTCONDITION_FAILED: definição inesperada do trigger';
  end if;
end
$sync_postcondition$;
-- ============================================================================
-- 5. AUDITORIA SEMÂNTICA DA TROCA DE SUPERVISOR
--
-- Mantém o comportamento genérico já existente de private.write_audit_log()
-- e classifica especificamente mudanças em teams.supervisor_member_id como:
--
--   team_supervisor_changed
--
-- Não cria uma segunda linha manual de auditoria.
-- O próprio trigger teams_audit continua responsável pelo registro.
-- ============================================================================

create or replace function private.write_audit_log()
returns trigger
language plpgsql
security definer
set search_path = ''
as $function$
declare
  v_old jsonb;
  v_new jsonb;
  v_row jsonb;
  v_org_id uuid;
  v_entity_id uuid;
  v_action text;
  v_user_id uuid;
begin
  v_old := case
    when tg_op in ('UPDATE', 'DELETE') then to_jsonb(old)
  end;

  v_new := case
    when tg_op in ('INSERT', 'UPDATE') then to_jsonb(new)
  end;

  v_row := coalesce(v_new, v_old);

  if tg_table_name = 'organizations' then
    v_org_id := nullif(v_row ->> 'id', '')::uuid;
  else
    v_org_id := nullif(v_row ->> 'organization_id', '')::uuid;
  end if;

  v_entity_id := nullif(v_row ->> 'id', '')::uuid;

  if tg_op = 'INSERT' then
    v_action := 'create';

  elsif tg_op = 'DELETE' then
    v_action := 'delete';

  elsif tg_table_name = 'teams'
    and (v_old ->> 'supervisor_member_id')
      is distinct from
        (v_new ->> 'supervisor_member_id') then

    v_action := 'team_supervisor_changed';

  elsif (v_old ->> 'status')
    is distinct from
      (v_new ->> 'status') then

    v_action := case v_new ->> 'status'
      when 'active' then 'activate'
      when 'inactive' then 'deactivate'
      when 'archived' then 'archive'
      else 'update'
    end;

  else
    v_action := 'update';
  end if;

  select case
    when exists (
      select 1
      from public.profiles p
      where p.id = auth.uid()
    )
      then auth.uid()
    else null
  end
  into v_user_id;

  insert into public.audit_logs (
    organization_id,
    user_id,
    action,
    entity_type,
    entity_id,
    old_values,
    new_values,
    created_at
  )
  values (
    v_org_id,
    v_user_id,
    v_action,
    tg_table_name,
    v_entity_id,
    v_old,
    v_new,
    now()
  );

  return null;
end;
$function$;


-- ============================================================================
-- 5.1 PÓS-CONDIÇÕES DA AUDITORIA SEMÂNTICA
-- ============================================================================

do $audit_semantic_postcondition$
declare
  v_function_definition text;
begin
  select pg_catalog.pg_get_functiondef(
    'private.write_audit_log()'::regprocedure
  )
  into v_function_definition;

  if v_function_definition is null then
    raise exception
      'SUPERVISION_HISTORY_AUDIT_POSTCONDITION_FAILED: private.write_audit_log() ausente';
  end if;

  if position(
    'team_supervisor_changed'
    in v_function_definition
  ) = 0 then
    raise exception
      'SUPERVISION_HISTORY_AUDIT_POSTCONDITION_FAILED: ação semântica de troca de supervisor ausente';
  end if;

  if position(
    'activate'
    in v_function_definition
  ) = 0
  or position(
    'deactivate'
    in v_function_definition
  ) = 0
  or position(
    'archive'
    in v_function_definition
  ) = 0 then
    raise exception
      'SUPERVISION_HISTORY_AUDIT_POSTCONDITION_FAILED: comportamento genérico de status não preservado';
  end if;
end
$audit_semantic_postcondition$;
-- ============================================================================
-- 6. TROCA SEGURA DE SUPERVISOR DA EQUIPE
--
-- Arquitetura:
--   public.change_team_supervisor(...)
--     -> wrapper SECURITY INVOKER
--
--   private.change_team_supervisor_impl(...)
--     -> implementação SECURITY DEFINER
--
-- Regras:
--   - exige usuário autenticado;
--   - somente Platform Admin ou Diretor da organização;
--   - somente equipe ativa e não arquivada;
--   - novo supervisor precisa ser supervisor ativo da mesma organização;
--   - a operação é serializada por lock da equipe;
--   - não movimenta vendedores;
--   - não impede o supervisor de responder por várias equipes;
--   - retorna quantidade de outras equipes ativas já supervisionadas;
--   - histórico é mantido pelo trigger teams_sync_supervisor_history;
--   - auditoria é mantida pelo trigger teams_audit.
-- ============================================================================

do $change_supervisor_preflight$
begin
  if pg_catalog.to_regprocedure(
    'private.change_team_supervisor_impl(uuid,uuid,uuid)'
  ) is not null then
    raise exception
      'CHANGE_TEAM_SUPERVISOR_PREFLIGHT_FAILED: implementação privada já existe';
  end if;

  if pg_catalog.to_regprocedure(
    'public.change_team_supervisor(uuid,uuid,uuid)'
  ) is not null then
    raise exception
      'CHANGE_TEAM_SUPERVISOR_PREFLIGHT_FAILED: wrapper público já existe';
  end if;
end
$change_supervisor_preflight$;


create function private.change_team_supervisor_impl(
  p_organization_id uuid,
  p_team_id uuid,
  p_new_supervisor_member_id uuid
)
returns jsonb
language plpgsql
volatile
security definer
set search_path = ''
as $function$
declare
  v_actor_user_id uuid := auth.uid();
  v_now timestamptz := pg_catalog.now();

  v_team public.teams%rowtype;
  v_new_supervisor public.organization_members%rowtype;

  v_previous_supervisor_member_id uuid;

  v_other_active_team_count integer := 0;
  v_updated_rows integer := 0;
begin
  -- --------------------------------------------------------------------------
  -- Autenticação
  -- --------------------------------------------------------------------------

  if v_actor_user_id is null then
    raise exception 'AUTH_REQUIRED'
      using errcode = '42501';
  end if;

  -- --------------------------------------------------------------------------
  -- Entrada
  -- --------------------------------------------------------------------------

  if p_organization_id is null
     or p_team_id is null
     or p_new_supervisor_member_id is null then
    raise exception 'TEAM_SUPERVISOR_CHANGE_INVALID_INPUT'
      using errcode = '22023';
  end if;

  -- --------------------------------------------------------------------------
  -- Autorização
  -- --------------------------------------------------------------------------

  if not (
    coalesce(
      private.is_platform_admin(),
      false
    )
    or coalesce(
      private.has_org_role(
        p_organization_id,
        array['director']::text[]
      ),
      false
    )
  ) then
    raise exception 'TEAM_SUPERVISOR_CHANGE_FORBIDDEN'
      using errcode = '42501';
  end if;

  -- --------------------------------------------------------------------------
  -- Lock da equipe.
  --
  -- Serializa trocas concorrentes de supervisor na mesma equipe e garante
  -- que OLD -> NEW permaneça consistente até o UPDATE.
  -- --------------------------------------------------------------------------

  select t.*
    into v_team
  from public.teams t
  where t.id = p_team_id
    and t.organization_id = p_organization_id
    and t.status = 'active'
    and t.archived_at is null
  for update;

  if not found then
    raise exception 'TEAM_NOT_ACTIVE'
      using errcode = 'P0002';
  end if;

  v_previous_supervisor_member_id :=
    v_team.supervisor_member_id;

  if v_previous_supervisor_member_id
       is not distinct from
       p_new_supervisor_member_id then
    raise exception 'TEAM_SUPERVISOR_UNCHANGED'
      using errcode = '22023';
  end if;

  -- --------------------------------------------------------------------------
  -- Novo supervisor.
  --
  -- O lock também evita que o membership seja alterado simultaneamente
  -- durante a troca.
  -- --------------------------------------------------------------------------

  select om.*
    into v_new_supervisor
  from public.organization_members om
  where om.id = p_new_supervisor_member_id
    and om.organization_id = p_organization_id
    and om.role = 'supervisor'
    and om.status = 'active'
    and om.archived_at is null
  for update;

  if not found then
    raise exception 'NEW_SUPERVISOR_NOT_ACTIVE'
      using errcode = 'P0002';
  end if;

  -- --------------------------------------------------------------------------
  -- Multi-equipe.
  --
  -- Não existe bloqueio.
  -- O total abaixo é apenas informativo para que a interface possa alertar
  -- que o supervisor já responde por outra(s) equipe(s).
  -- --------------------------------------------------------------------------

  select pg_catalog.count(*)::integer
    into v_other_active_team_count
  from public.teams t
  where t.organization_id = p_organization_id
    and t.id <> p_team_id
    and t.supervisor_member_id = p_new_supervisor_member_id
    and t.status = 'active'
    and t.archived_at is null;

  -- --------------------------------------------------------------------------
  -- Troca.
  --
  -- Os triggers existentes continuam responsáveis por:
  --   * validação estrutural da equipe;
  --   * preservação da hierarquia;
  --   * metadados da linha;
  --   * histórico temporal;
  --   * auditoria semântica.
  --
  -- Nenhum team_member é alterado.
  -- --------------------------------------------------------------------------

  update public.teams
  set supervisor_member_id = p_new_supervisor_member_id
  where id = p_team_id
    and organization_id = p_organization_id;

  get diagnostics v_updated_rows = row_count;

  if v_updated_rows <> 1 then
    raise exception
      'TEAM_SUPERVISOR_CHANGE_FAILED'
      using
        errcode = 'P0001',
        detail = pg_catalog.format(
          'Esperado atualizar 1 equipe, atualizado(s) %s.',
          v_updated_rows
        );
  end if;

  -- --------------------------------------------------------------------------
  -- Retorno
  -- --------------------------------------------------------------------------

  return pg_catalog.jsonb_build_object(
    'success', true,

    'organization_id',
    p_organization_id,

    'team_id',
    v_team.id,

    'team_name',
    v_team.name,

    'previous_supervisor_member_id',
    v_previous_supervisor_member_id,

    'new_supervisor_member_id',
    p_new_supervisor_member_id,

    'new_supervisor_user_id',
    v_new_supervisor.user_id,

    'other_active_team_count',
    v_other_active_team_count,

    'supervisor_already_manages_other_teams',
    v_other_active_team_count > 0,

    'changed_at',
    v_now
  );
end;
$function$;


comment on function private.change_team_supervisor_impl(
  uuid,
  uuid,
  uuid
) is
  'Implementação privilegiada da troca atômica de supervisor de uma equipe. Autoriza somente Platform Admin/Diretor, valida supervisor ativo da organização e preserva vendedores.';


-- A implementação privada não é chamada por anon.
-- authenticated precisa de EXECUTE porque o wrapper público é
-- SECURITY INVOKER.
revoke all on function private.change_team_supervisor_impl(
  uuid,
  uuid,
  uuid
) from public, anon, authenticated;

grant execute on function private.change_team_supervisor_impl(
  uuid,
  uuid,
  uuid
) to authenticated;


-- ============================================================================
-- 6.1 WRAPPER PÚBLICO
-- ============================================================================

create function public.change_team_supervisor(
  p_organization_id uuid,
  p_team_id uuid,
  p_new_supervisor_member_id uuid
)
returns jsonb
language sql
volatile
security invoker
set search_path = ''
as $function$
  select private.change_team_supervisor_impl(
    p_organization_id,
    p_team_id,
    p_new_supervisor_member_id
  );
$function$;


comment on function public.change_team_supervisor(
  uuid,
  uuid,
  uuid
) is
  'Wrapper SECURITY INVOKER para troca segura do supervisor de uma equipe. A implementação privilegiada permanece no schema private.';


revoke all on function public.change_team_supervisor(
  uuid,
  uuid,
  uuid
) from public, anon, authenticated;

grant execute on function public.change_team_supervisor(
  uuid,
  uuid,
  uuid
) to authenticated;


-- ============================================================================
-- 6.2 PÓS-CONDIÇÕES DE HARDENING DA RPC
-- ============================================================================

do $change_supervisor_postcondition$
declare
  v_private_oid oid;
  v_public_oid oid;

  v_private_security_definer boolean;
  v_public_security_definer boolean;

  v_public_definition text;
begin
  v_private_oid :=
    pg_catalog.to_regprocedure(
      'private.change_team_supervisor_impl(uuid,uuid,uuid)'
    );

  v_public_oid :=
    pg_catalog.to_regprocedure(
      'public.change_team_supervisor(uuid,uuid,uuid)'
    );

  if v_private_oid is null then
    raise exception
      'CHANGE_TEAM_SUPERVISOR_POSTCONDITION_FAILED: implementação privada ausente';
  end if;

  if v_public_oid is null then
    raise exception
      'CHANGE_TEAM_SUPERVISOR_POSTCONDITION_FAILED: wrapper público ausente';
  end if;

  select p.prosecdef
    into v_private_security_definer
  from pg_catalog.pg_proc p
  where p.oid = v_private_oid;

  if v_private_security_definer is distinct from true then
    raise exception
      'CHANGE_TEAM_SUPERVISOR_POSTCONDITION_FAILED: implementação privada não é SECURITY DEFINER';
  end if;

  select p.prosecdef
    into v_public_security_definer
  from pg_catalog.pg_proc p
  where p.oid = v_public_oid;

  if v_public_security_definer is distinct from false then
    raise exception
      'CHANGE_TEAM_SUPERVISOR_POSTCONDITION_FAILED: wrapper público não é SECURITY INVOKER';
  end if;

  if pg_catalog.has_function_privilege(
    'anon',
    'private.change_team_supervisor_impl(uuid,uuid,uuid)',
    'EXECUTE'
  ) then
    raise exception
      'CHANGE_TEAM_SUPERVISOR_POSTCONDITION_FAILED: anon possui EXECUTE na implementação privada';
  end if;

  if not pg_catalog.has_function_privilege(
    'authenticated',
    'private.change_team_supervisor_impl(uuid,uuid,uuid)',
    'EXECUTE'
  ) then
    raise exception
      'CHANGE_TEAM_SUPERVISOR_POSTCONDITION_FAILED: authenticated sem EXECUTE na implementação privada';
  end if;

  if pg_catalog.has_function_privilege(
    'anon',
    'public.change_team_supervisor(uuid,uuid,uuid)',
    'EXECUTE'
  ) then
    raise exception
      'CHANGE_TEAM_SUPERVISOR_POSTCONDITION_FAILED: anon possui EXECUTE no wrapper público';
  end if;

  if not pg_catalog.has_function_privilege(
    'authenticated',
    'public.change_team_supervisor(uuid,uuid,uuid)',
    'EXECUTE'
  ) then
    raise exception
      'CHANGE_TEAM_SUPERVISOR_POSTCONDITION_FAILED: authenticated sem EXECUTE no wrapper público';
  end if;

  select pg_catalog.pg_get_functiondef(v_public_oid)
    into v_public_definition;

  if position(
    'private.change_team_supervisor_impl'
    in v_public_definition
  ) = 0 then
    raise exception
      'CHANGE_TEAM_SUPERVISOR_POSTCONDITION_FAILED: wrapper não delega para implementação privada';
  end if;
end
$change_supervisor_postcondition$;
-- ============================================================================
-- 7. RLS E PRIVILÉGIOS DO HISTÓRICO DE SUPERVISÃO
--
-- Modelo alinhado a public.audit_logs:
--
--   authenticated:
--     - SELECT somente;
--     - leitura apenas para Platform Admin ou Diretor da organização.
--
--   anon:
--     - nenhum privilégio.
--
--   service_role:
--     - privilégios completos.
--
-- Escritas normais do histórico são realizadas pela função
-- private.sync_team_supervisor_history(), executada como SECURITY DEFINER.
-- Não existem policies de INSERT, UPDATE ou DELETE para clientes autenticados.
-- ============================================================================

alter table public.team_supervisor_assignments
enable row level security;


-- --------------------------------------------------------------------------
-- Normalização explícita dos privilégios da tabela.
-- --------------------------------------------------------------------------

revoke all
on table public.team_supervisor_assignments
from public, anon, authenticated;

grant select
on table public.team_supervisor_assignments
to authenticated;

grant all privileges
on table public.team_supervisor_assignments
to service_role;


-- --------------------------------------------------------------------------
-- Leitura administrativa.
--
-- Mesmo princípio utilizado em public.audit_logs:
--   * Platform Admin pode consultar;
--   * Diretor pode consultar somente a própria organização.
-- --------------------------------------------------------------------------

create policy team_supervisor_assignments_select_authorized
on public.team_supervisor_assignments
for select
to authenticated
using (
  private.is_platform_admin()
  or (
    organization_id is not null
    and private.has_org_role(
      organization_id,
      array['director'::text]
    )
  )
);


-- ============================================================================
-- 7.1 PÓS-CONDIÇÕES DE RLS E PRIVILÉGIOS
-- ============================================================================

do $history_rls_postcondition$
declare
  v_rls_enabled boolean;
  v_force_rls boolean;

  v_policy_count integer;
  v_policy_command "char";

  v_policy_expression text;
begin
  -- ------------------------------------------------------------------------
  -- RLS
  -- ------------------------------------------------------------------------

  select
    c.relrowsecurity,
    c.relforcerowsecurity
  into
    v_rls_enabled,
    v_force_rls
  from pg_catalog.pg_class c
  join pg_catalog.pg_namespace n
    on n.oid = c.relnamespace
  where n.nspname = 'public'
    and c.relname = 'team_supervisor_assignments';

  if v_rls_enabled is distinct from true then
    raise exception
      'SUPERVISION_HISTORY_RLS_POSTCONDITION_FAILED: RLS não está habilitado';
  end if;

  if v_force_rls is distinct from false then
    raise exception
      'SUPERVISION_HISTORY_RLS_POSTCONDITION_FAILED: FORCE RLS inesperadamente habilitado';
  end if;

  -- ------------------------------------------------------------------------
  -- authenticated: somente SELECT
  -- ------------------------------------------------------------------------

  if not pg_catalog.has_table_privilege(
    'authenticated',
    'public.team_supervisor_assignments',
    'SELECT'
  ) then
    raise exception
      'SUPERVISION_HISTORY_RLS_POSTCONDITION_FAILED: authenticated sem SELECT';
  end if;

  if pg_catalog.has_table_privilege(
    'authenticated',
    'public.team_supervisor_assignments',
    'INSERT'
  )
  or pg_catalog.has_table_privilege(
    'authenticated',
    'public.team_supervisor_assignments',
    'UPDATE'
  )
  or pg_catalog.has_table_privilege(
    'authenticated',
    'public.team_supervisor_assignments',
    'DELETE'
  )
  or pg_catalog.has_table_privilege(
    'authenticated',
    'public.team_supervisor_assignments',
    'TRUNCATE'
  ) then
    raise exception
      'SUPERVISION_HISTORY_RLS_POSTCONDITION_FAILED: authenticated possui privilégio de escrita';
  end if;

  -- ------------------------------------------------------------------------
  -- anon: nenhum acesso.
  --
  -- has_table_privilege também considera privilégios herdados de PUBLIC,
  -- portanto esta checagem protege contra grants indiretos.
  -- ------------------------------------------------------------------------

  if pg_catalog.has_table_privilege(
    'anon',
    'public.team_supervisor_assignments',
    'SELECT'
  )
  or pg_catalog.has_table_privilege(
    'anon',
    'public.team_supervisor_assignments',
    'INSERT'
  )
  or pg_catalog.has_table_privilege(
    'anon',
    'public.team_supervisor_assignments',
    'UPDATE'
  )
  or pg_catalog.has_table_privilege(
    'anon',
    'public.team_supervisor_assignments',
    'DELETE'
  )
  or pg_catalog.has_table_privilege(
    'anon',
    'public.team_supervisor_assignments',
    'TRUNCATE'
  ) then
    raise exception
      'SUPERVISION_HISTORY_RLS_POSTCONDITION_FAILED: anon possui privilégio inesperado';
  end if;

  -- ------------------------------------------------------------------------
  -- service_role: acesso operacional completo.
  -- ------------------------------------------------------------------------

  if not pg_catalog.has_table_privilege(
    'service_role',
    'public.team_supervisor_assignments',
    'SELECT'
  )
  or not pg_catalog.has_table_privilege(
    'service_role',
    'public.team_supervisor_assignments',
    'INSERT'
  )
  or not pg_catalog.has_table_privilege(
    'service_role',
    'public.team_supervisor_assignments',
    'UPDATE'
  )
  or not pg_catalog.has_table_privilege(
    'service_role',
    'public.team_supervisor_assignments',
    'DELETE'
  ) then
    raise exception
      'SUPERVISION_HISTORY_RLS_POSTCONDITION_FAILED: service_role sem privilégios esperados';
  end if;

  -- ------------------------------------------------------------------------
  -- Policy.
  -- Deve existir exatamente uma policy nesta tabela e ela deve ser SELECT.
  -- ------------------------------------------------------------------------

  select
    count(*)
  into v_policy_count
  from pg_catalog.pg_policy pol
  join pg_catalog.pg_class c
    on c.oid = pol.polrelid
  join pg_catalog.pg_namespace n
    on n.oid = c.relnamespace
  where n.nspname = 'public'
    and c.relname = 'team_supervisor_assignments';

  if v_policy_count <> 1 then
    raise exception
      'SUPERVISION_HISTORY_RLS_POSTCONDITION_FAILED: esperado 1 policy, encontrada(s) %',
      v_policy_count;
  end if;

  select
    pol.polcmd,
    pg_catalog.pg_get_expr(
      pol.polqual,
      pol.polrelid
    )
  into
    v_policy_command,
    v_policy_expression
  from pg_catalog.pg_policy pol
  join pg_catalog.pg_class c
    on c.oid = pol.polrelid
  join pg_catalog.pg_namespace n
    on n.oid = c.relnamespace
  where n.nspname = 'public'
    and c.relname = 'team_supervisor_assignments'
    and pol.polname =
      'team_supervisor_assignments_select_authorized';

  if not found then
    raise exception
      'SUPERVISION_HISTORY_RLS_POSTCONDITION_FAILED: policy autorizada ausente';
  end if;

  if v_policy_command <> 'r' then
    raise exception
      'SUPERVISION_HISTORY_RLS_POSTCONDITION_FAILED: policy não é SELECT';
  end if;

  if position(
    'private.is_platform_admin()'
    in v_policy_expression
  ) = 0
  or position(
    'private.has_org_role'
    in v_policy_expression
  ) = 0
  or position(
    'director'
    in v_policy_expression
  ) = 0 then
    raise exception
      'SUPERVISION_HISTORY_RLS_POSTCONDITION_FAILED: expressão da policy inesperada';
  end if;
end
$history_rls_postcondition$;
commit;
