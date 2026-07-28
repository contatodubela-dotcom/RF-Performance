-- ============================================================================
-- RF Performance Comercial
-- Plano de 90 dias, metas, treinamentos, ações, reuniões e feedbacks
-- Data: 2026-07-28
--
-- Estrutura multiempresa reutilizável. Os registros iniciais da RF são
-- templates editáveis e não representam execução ou resultado realizado.
-- ============================================================================

begin;

-- --------------------------------------------------------------------------
-- Tabelas do plano comercial
-- --------------------------------------------------------------------------

create table public.commercial_plans (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null,
  operation_id uuid not null,
  title text not null,
  description text,
  duration_days integer not null default 90,
  baseline_monthly_sales numeric(12,2),
  target_monthly_sales numeric(12,2),
  growth_target_percent numeric(7,2),
  recognition_criteria text,
  start_date date,
  end_date date,
  status text not null default 'draft',
  setup_status text not null default 'template',
  is_template boolean not null default true,
  external_id text,
  source_system text not null default 'rf_performance',
  created_at timestamptz not null default now(),
  created_by uuid,
  updated_at timestamptz not null default now(),
  updated_by uuid,
  archived_at timestamptz,
  metadata jsonb not null default '{}'::jsonb,
  constraint commercial_plans_organization_id_fkey
    foreign key (organization_id)
    references public.organizations(id)
    on delete restrict,
  constraint commercial_plans_operation_org_fkey
    foreign key (operation_id, organization_id)
    references public.operations(id, organization_id)
    on delete restrict,
  constraint commercial_plans_id_org_key unique (id, organization_id),
  constraint commercial_plans_org_title_key unique (organization_id, title),
  constraint commercial_plans_duration_check check (duration_days between 1 and 730),
  constraint commercial_plans_status_check
    check (status in ('draft', 'active', 'completed', 'archived')),
  constraint commercial_plans_setup_status_check
    check (setup_status in ('template', 'pending_confirmation', 'confirmed')),
  constraint commercial_plans_sales_values_check
    check (
      (baseline_monthly_sales is null or baseline_monthly_sales >= 0)
      and (target_monthly_sales is null or target_monthly_sales >= 0)
      and (growth_target_percent is null or growth_target_percent >= 0)
    ),
  constraint commercial_plans_period_check
    check (end_date is null or start_date is null or end_date >= start_date),
  constraint commercial_plans_metadata_object_check
    check (jsonb_typeof(metadata) = 'object')
);

create table public.plan_phases (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null,
  plan_id uuid not null,
  sequence_no integer not null,
  name text not null,
  period_label text not null,
  start_day integer not null,
  end_day integer not null,
  objective text not null,
  status text not null default 'planned',
  progress_percent numeric(5,2) not null default 0,
  is_template boolean not null default true,
  created_at timestamptz not null default now(),
  created_by uuid,
  updated_at timestamptz not null default now(),
  updated_by uuid,
  archived_at timestamptz,
  metadata jsonb not null default '{}'::jsonb,
  constraint plan_phases_plan_org_fkey
    foreign key (plan_id, organization_id)
    references public.commercial_plans(id, organization_id)
    on delete restrict,
  constraint plan_phases_id_plan_org_key
    unique (id, plan_id, organization_id),
  constraint plan_phases_plan_sequence_key unique (plan_id, sequence_no),
  constraint plan_phases_days_check
    check (start_day >= 1 and end_day >= start_day),
  constraint plan_phases_progress_check
    check (progress_percent between 0 and 100),
  constraint plan_phases_status_check
    check (status in ('planned', 'in_progress', 'completed', 'archived')),
  constraint plan_phases_metadata_object_check
    check (jsonb_typeof(metadata) = 'object')
);

create table public.plan_actions (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null,
  plan_id uuid not null,
  phase_id uuid,
  title text not null,
  description text,
  category text not null,
  responsible_role text not null,
  due_day integer,
  priority text not null default 'medium',
  status text not null default 'planned',
  evidence text,
  completed_at timestamptz,
  is_template boolean not null default true,
  created_at timestamptz not null default now(),
  created_by uuid,
  updated_at timestamptz not null default now(),
  updated_by uuid,
  archived_at timestamptz,
  metadata jsonb not null default '{}'::jsonb,
  constraint plan_actions_plan_org_fkey
    foreign key (plan_id, organization_id)
    references public.commercial_plans(id, organization_id)
    on delete restrict,
  constraint plan_actions_phase_plan_org_fkey
    foreign key (phase_id, plan_id, organization_id)
    references public.plan_phases(id, plan_id, organization_id)
    on delete restrict,
  constraint plan_actions_plan_title_key unique (plan_id, title),
  constraint plan_actions_due_day_check
    check (due_day is null or due_day between 1 and 730),
  constraint plan_actions_category_check
    check (category in (
      'diagnosis', 'data', 'process', 'training', 'coaching',
      'follow_up', 'leadership', 'meeting', 'optimization', 'report'
    )),
  constraint plan_actions_responsible_role_check
    check (responsible_role in (
      'epsa', 'rf_direction', 'supervisor', 'salesperson', 'shared'
    )),
  constraint plan_actions_priority_check
    check (priority in ('low', 'medium', 'high', 'critical')),
  constraint plan_actions_status_check
    check (status in (
      'planned', 'in_progress', 'completed', 'blocked', 'cancelled', 'archived'
    )),
  constraint plan_actions_metadata_object_check
    check (jsonb_typeof(metadata) = 'object')
);

create table public.performance_goals (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null,
  plan_id uuid not null,
  scope_type text not null,
  scope_id uuid not null,
  metric_code text not null,
  label text not null,
  baseline_value numeric(14,2),
  target_value numeric(14,2),
  actual_value numeric(14,2),
  unit text not null,
  period_type text not null default 'monthly',
  status text not null default 'active',
  setup_status text not null default 'template',
  is_template boolean not null default true,
  created_at timestamptz not null default now(),
  created_by uuid,
  updated_at timestamptz not null default now(),
  updated_by uuid,
  archived_at timestamptz,
  metadata jsonb not null default '{}'::jsonb,
  constraint performance_goals_plan_org_fkey
    foreign key (plan_id, organization_id)
    references public.commercial_plans(id, organization_id)
    on delete restrict,
  constraint performance_goals_plan_scope_metric_key
    unique (plan_id, scope_type, scope_id, metric_code),
  constraint performance_goals_scope_type_check
    check (scope_type in (
      'organization', 'sales_location', 'team', 'organization_member'
    )),
  constraint performance_goals_unit_check
    check (unit in ('count', 'percent', 'currency', 'ratio', 'score')),
  constraint performance_goals_period_type_check
    check (period_type in ('daily', 'weekly', 'monthly', '90_days')),
  constraint performance_goals_status_check
    check (status in ('active', 'inactive', 'archived')),
  constraint performance_goals_setup_status_check
    check (setup_status in ('template', 'pending_confirmation', 'confirmed')),
  constraint performance_goals_values_check
    check (
      (baseline_value is null or baseline_value >= 0)
      and (target_value is null or target_value >= 0)
      and (actual_value is null or actual_value >= 0)
    ),
  constraint performance_goals_metadata_object_check
    check (jsonb_typeof(metadata) = 'object')
);

create table public.training_modules (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null,
  plan_id uuid not null,
  sequence_no integer not null,
  title text not null,
  objective text not null,
  duration_minutes integer not null default 60,
  delivery_method text not null default 'explain_demo_simulate_apply',
  passing_score numeric(5,2) not null default 80,
  critical_error text,
  scheduled_date date,
  completed_date date,
  status text not null default 'planned',
  is_template boolean not null default true,
  created_at timestamptz not null default now(),
  created_by uuid,
  updated_at timestamptz not null default now(),
  updated_by uuid,
  archived_at timestamptz,
  metadata jsonb not null default '{}'::jsonb,
  constraint training_modules_plan_org_fkey
    foreign key (plan_id, organization_id)
    references public.commercial_plans(id, organization_id)
    on delete restrict,
  constraint training_modules_plan_sequence_key unique (plan_id, sequence_no),
  constraint training_modules_duration_check
    check (duration_minutes between 10 and 480),
  constraint training_modules_passing_score_check
    check (passing_score between 0 and 100),
  constraint training_modules_status_check
    check (status in ('planned', 'in_progress', 'completed', 'archived')),
  constraint training_modules_dates_check
    check (
      completed_date is null
      or scheduled_date is null
      or completed_date >= scheduled_date
    ),
  constraint training_modules_metadata_object_check
    check (jsonb_typeof(metadata) = 'object')
);

create table public.management_rituals (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null,
  plan_id uuid not null,
  title text not null,
  frequency_label text not null,
  responsible_role text not null,
  duration_minutes integer not null,
  expected_output text not null,
  status text not null default 'planned',
  is_template boolean not null default true,
  created_at timestamptz not null default now(),
  created_by uuid,
  updated_at timestamptz not null default now(),
  updated_by uuid,
  archived_at timestamptz,
  metadata jsonb not null default '{}'::jsonb,
  constraint management_rituals_plan_org_fkey
    foreign key (plan_id, organization_id)
    references public.commercial_plans(id, organization_id)
    on delete restrict,
  constraint management_rituals_id_org_key unique (id, organization_id),
  constraint management_rituals_plan_title_key unique (plan_id, title),
  constraint management_rituals_duration_check
    check (duration_minutes between 5 and 480),
  constraint management_rituals_status_check
    check (status in ('planned', 'active', 'inactive', 'archived')),
  constraint management_rituals_metadata_object_check
    check (jsonb_typeof(metadata) = 'object')
);

create table public.meeting_records (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null,
  plan_id uuid,
  ritual_id uuid,
  team_id uuid,
  title text not null,
  meeting_at timestamptz not null,
  summary text,
  decisions text,
  next_steps text,
  attendees_count integer,
  status text not null default 'scheduled',
  created_at timestamptz not null default now(),
  created_by uuid,
  updated_at timestamptz not null default now(),
  updated_by uuid,
  archived_at timestamptz,
  metadata jsonb not null default '{}'::jsonb,
  constraint meeting_records_organization_id_fkey
    foreign key (organization_id)
    references public.organizations(id)
    on delete restrict,
  constraint meeting_records_plan_org_fkey
    foreign key (plan_id, organization_id)
    references public.commercial_plans(id, organization_id)
    on delete restrict,
  constraint meeting_records_ritual_org_fkey
    foreign key (ritual_id, organization_id)
    references public.management_rituals(id, organization_id)
    on delete restrict,
  constraint meeting_records_team_org_fkey
    foreign key (team_id, organization_id)
    references public.teams(id, organization_id)
    on delete restrict,
  constraint meeting_records_attendees_check
    check (attendees_count is null or attendees_count >= 0),
  constraint meeting_records_status_check
    check (status in ('scheduled', 'held', 'cancelled', 'archived')),
  constraint meeting_records_metadata_object_check
    check (jsonb_typeof(metadata) = 'object')
);

create table public.feedback_records (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null,
  plan_id uuid,
  team_id uuid,
  target_member_id uuid not null,
  author_member_id uuid,
  feedback_type text not null default 'coaching',
  occurred_on date not null default current_date,
  fact text not null,
  impact text not null,
  cause text,
  agreed_action text not null,
  follow_up_on date,
  evidence text,
  status text not null default 'open',
  created_at timestamptz not null default now(),
  created_by uuid,
  updated_at timestamptz not null default now(),
  updated_by uuid,
  archived_at timestamptz,
  metadata jsonb not null default '{}'::jsonb,
  constraint feedback_records_organization_id_fkey
    foreign key (organization_id)
    references public.organizations(id)
    on delete restrict,
  constraint feedback_records_plan_org_fkey
    foreign key (plan_id, organization_id)
    references public.commercial_plans(id, organization_id)
    on delete restrict,
  constraint feedback_records_team_org_fkey
    foreign key (team_id, organization_id)
    references public.teams(id, organization_id)
    on delete restrict,
  constraint feedback_records_target_org_fkey
    foreign key (target_member_id, organization_id)
    references public.organization_members(id, organization_id)
    on delete restrict,
  constraint feedback_records_author_org_fkey
    foreign key (author_member_id, organization_id)
    references public.organization_members(id, organization_id)
    on delete restrict,
  constraint feedback_records_type_check
    check (feedback_type in ('coaching', 'performance', 'recognition', 'corrective')),
  constraint feedback_records_status_check
    check (status in ('open', 'follow_up', 'completed', 'archived')),
  constraint feedback_records_follow_up_check
    check (follow_up_on is null or follow_up_on >= occurred_on),
  constraint feedback_records_metadata_object_check
    check (jsonb_typeof(metadata) = 'object')
);

-- --------------------------------------------------------------------------
-- Índices
-- --------------------------------------------------------------------------

create index commercial_plans_org_status_idx
  on public.commercial_plans (organization_id, status, created_at desc);
create index plan_phases_plan_sequence_idx
  on public.plan_phases (plan_id, sequence_no);
create index plan_actions_plan_status_idx
  on public.plan_actions (plan_id, status, due_day);
create index plan_actions_phase_status_idx
  on public.plan_actions (phase_id, status);
create index performance_goals_org_scope_idx
  on public.performance_goals (organization_id, scope_type, status);
create index training_modules_plan_sequence_idx
  on public.training_modules (plan_id, sequence_no);
create index management_rituals_plan_status_idx
  on public.management_rituals (plan_id, status);
create index meeting_records_org_date_idx
  on public.meeting_records (organization_id, meeting_at desc);
create index feedback_records_target_date_idx
  on public.feedback_records (target_member_id, occurred_on desc);
create index feedback_records_team_date_idx
  on public.feedback_records (team_id, occurred_on desc);

-- --------------------------------------------------------------------------
-- Validações auxiliares
-- --------------------------------------------------------------------------

create or replace function private.validate_performance_goal_scope()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  if new.scope_type = 'organization' then
    if new.scope_id <> new.organization_id then
      raise exception 'Meta organizacional deve usar a própria organização como escopo.';
    end if;
  elsif new.scope_type = 'sales_location' then
    if not exists (
      select 1 from public.sales_locations sl
      where sl.id = new.scope_id
        and sl.organization_id = new.organization_id
    ) then
      raise exception 'PDV da meta não pertence à organização.';
    end if;
  elsif new.scope_type = 'team' then
    if not exists (
      select 1 from public.teams t
      where t.id = new.scope_id
        and t.organization_id = new.organization_id
    ) then
      raise exception 'Equipe da meta não pertence à organização.';
    end if;
  elsif new.scope_type = 'organization_member' then
    if not exists (
      select 1 from public.organization_members om
      where om.id = new.scope_id
        and om.organization_id = new.organization_id
    ) then
      raise exception 'Membro da meta não pertence à organização.';
    end if;
  end if;

  return new;
end;
$$;

create or replace function private.refresh_plan_phase_progress()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_phase_ids uuid[];
  v_phase_id uuid;
  v_total integer;
  v_completed integer;
  v_progress numeric(5,2);
begin
  if tg_op = 'INSERT' then
    v_phase_ids := array[new.phase_id];
  elsif tg_op = 'DELETE' then
    v_phase_ids := array[old.phase_id];
  else
    v_phase_ids := array[old.phase_id, new.phase_id];
  end if;

  foreach v_phase_id in array v_phase_ids loop
    if v_phase_id is null then
      continue;
    end if;

    select
      count(*)::integer,
      count(*) filter (where pa.status = 'completed')::integer
    into v_total, v_completed
    from public.plan_actions pa
    where pa.phase_id = v_phase_id
      and pa.status <> 'archived';

    v_progress := case
      when v_total = 0 then 0
      else round((v_completed::numeric / v_total::numeric) * 100, 2)
    end;

    update public.plan_phases pp
    set
      progress_percent = v_progress,
      status = case
        when v_progress = 100 then 'completed'
        when v_progress > 0 and pp.status = 'planned' then 'in_progress'
        when v_progress = 0 and pp.status = 'in_progress' then 'planned'
        else pp.status
      end,
      updated_at = now()
    where pp.id = v_phase_id;
  end loop;

  return null;
end;
$$;

create or replace function private.can_manage_feedback_target(
  p_organization_id uuid,
  p_target_member_id uuid
)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select
    private.is_platform_admin()
    or private.has_org_role(p_organization_id, array['director'])
    or exists (
      select 1
      from public.team_members tm
      where tm.organization_member_id = p_target_member_id
        and tm.organization_id = p_organization_id
        and tm.status = 'active'
        and tm.archived_at is null
        and tm.team_id in (select private.managed_team_ids())
    );
$$;


create or replace function private.can_view_performance_goal(
  p_organization_id uuid,
  p_scope_type text,
  p_scope_id uuid
)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select
    private.is_platform_admin()
    or private.has_org_role(p_organization_id, array['director'])
    or (
      private.has_active_membership(p_organization_id)
      and p_scope_type = 'organization'
    )
    or (
      p_scope_type = 'team'
      and (
        p_scope_id in (select private.managed_team_ids())
        or p_scope_id in (select private.current_user_team_ids())
      )
    )
    or (
      p_scope_type = 'sales_location'
      and exists (
        select 1
        from public.teams t
        where t.sales_location_id = p_scope_id
          and t.organization_id = p_organization_id
          and (
            t.id in (select private.managed_team_ids())
            or t.id in (select private.current_user_team_ids())
          )
      )
    )
    or (
      p_scope_type = 'organization_member'
      and (
        p_scope_id = private.current_member_id(p_organization_id)
        or exists (
          select 1
          from public.team_members tm
          where tm.organization_member_id = p_scope_id
            and tm.organization_id = p_organization_id
            and tm.status = 'active'
            and tm.archived_at is null
            and tm.team_id in (select private.managed_team_ids())
        )
      )
    );
$$;

revoke all on function private.validate_performance_goal_scope()
  from public, anon, authenticated;
revoke all on function private.refresh_plan_phase_progress()
  from public, anon, authenticated;
revoke all on function private.can_manage_feedback_target(uuid, uuid)
  from public, anon;
revoke all on function private.can_view_performance_goal(uuid, text, uuid)
  from public, anon;
grant execute on function private.can_manage_feedback_target(uuid, uuid)
  to authenticated;
grant execute on function private.can_view_performance_goal(uuid, text, uuid)
  to authenticated;

-- --------------------------------------------------------------------------
-- Triggers de metadados, escopo, progresso e auditoria
-- --------------------------------------------------------------------------

create trigger commercial_plans_set_row_metadata
before insert or update on public.commercial_plans
for each row execute function private.set_row_metadata();
create trigger plan_phases_set_row_metadata
before insert or update on public.plan_phases
for each row execute function private.set_row_metadata();
create trigger plan_actions_set_row_metadata
before insert or update on public.plan_actions
for each row execute function private.set_row_metadata();
create trigger performance_goals_set_row_metadata
before insert or update on public.performance_goals
for each row execute function private.set_row_metadata();
create trigger training_modules_set_row_metadata
before insert or update on public.training_modules
for each row execute function private.set_row_metadata();
create trigger management_rituals_set_row_metadata
before insert or update on public.management_rituals
for each row execute function private.set_row_metadata();
create trigger meeting_records_set_row_metadata
before insert or update on public.meeting_records
for each row execute function private.set_row_metadata();
create trigger feedback_records_set_row_metadata
before insert or update on public.feedback_records
for each row execute function private.set_row_metadata();

create trigger commercial_plans_guard_org
before update on public.commercial_plans
for each row execute function private.guard_organization_scope();
create trigger plan_phases_guard_org
before update on public.plan_phases
for each row execute function private.guard_organization_scope();
create trigger plan_actions_guard_org
before update on public.plan_actions
for each row execute function private.guard_organization_scope();
create trigger performance_goals_guard_org
before update on public.performance_goals
for each row execute function private.guard_organization_scope();
create trigger training_modules_guard_org
before update on public.training_modules
for each row execute function private.guard_organization_scope();
create trigger management_rituals_guard_org
before update on public.management_rituals
for each row execute function private.guard_organization_scope();
create trigger meeting_records_guard_org
before update on public.meeting_records
for each row execute function private.guard_organization_scope();
create trigger feedback_records_guard_org
before update on public.feedback_records
for each row execute function private.guard_organization_scope();

create trigger performance_goals_validate_scope
before insert or update of organization_id, scope_type, scope_id
on public.performance_goals
for each row execute function private.validate_performance_goal_scope();

create trigger plan_actions_refresh_phase_progress_insert_delete
  after insert or delete
  on public.plan_actions
  for each row execute function private.refresh_plan_phase_progress();

create trigger plan_actions_refresh_phase_progress_update
  after update of status, phase_id
  on public.plan_actions
  for each row execute function private.refresh_plan_phase_progress();

create trigger commercial_plans_audit
after insert or update or delete on public.commercial_plans
for each row execute function private.write_audit_log();
create trigger plan_phases_audit
after insert or update or delete on public.plan_phases
for each row execute function private.write_audit_log();
create trigger plan_actions_audit
after insert or update or delete on public.plan_actions
for each row execute function private.write_audit_log();
create trigger performance_goals_audit
after insert or update or delete on public.performance_goals
for each row execute function private.write_audit_log();
create trigger training_modules_audit
after insert or update or delete on public.training_modules
for each row execute function private.write_audit_log();
create trigger management_rituals_audit
after insert or update or delete on public.management_rituals
for each row execute function private.write_audit_log();
create trigger meeting_records_audit
after insert or update or delete on public.meeting_records
for each row execute function private.write_audit_log();
create trigger feedback_records_audit
after insert or update or delete on public.feedback_records
for each row execute function private.write_audit_log();

-- --------------------------------------------------------------------------
-- RLS, grants e policies
-- --------------------------------------------------------------------------

alter table public.commercial_plans enable row level security;
alter table public.plan_phases enable row level security;
alter table public.plan_actions enable row level security;
alter table public.performance_goals enable row level security;
alter table public.training_modules enable row level security;
alter table public.management_rituals enable row level security;
alter table public.meeting_records enable row level security;
alter table public.feedback_records enable row level security;

revoke all on table public.commercial_plans from anon, authenticated;
revoke all on table public.plan_phases from anon, authenticated;
revoke all on table public.plan_actions from anon, authenticated;
revoke all on table public.performance_goals from anon, authenticated;
revoke all on table public.training_modules from anon, authenticated;
revoke all on table public.management_rituals from anon, authenticated;
revoke all on table public.meeting_records from anon, authenticated;
revoke all on table public.feedback_records from anon, authenticated;

grant select, insert, update on table public.commercial_plans to authenticated;
grant select, insert, update on table public.plan_phases to authenticated;
grant select, insert, update on table public.plan_actions to authenticated;
grant select, insert, update on table public.performance_goals to authenticated;
grant select, insert, update on table public.training_modules to authenticated;
grant select, insert, update on table public.management_rituals to authenticated;
grant select, insert, update on table public.meeting_records to authenticated;
grant select, insert, update on table public.feedback_records to authenticated;

create policy commercial_plans_select_members
on public.commercial_plans for select to authenticated
using (private.is_platform_admin() or private.has_active_membership(organization_id));
create policy commercial_plans_manage_leadership
on public.commercial_plans for all to authenticated
using (private.is_platform_admin() or private.has_org_role(organization_id, array['director']))
with check (private.is_platform_admin() or private.has_org_role(organization_id, array['director']));

create policy plan_phases_select_members
on public.plan_phases for select to authenticated
using (private.is_platform_admin() or private.has_active_membership(organization_id));
create policy plan_phases_manage_leadership
on public.plan_phases for all to authenticated
using (private.is_platform_admin() or private.has_org_role(organization_id, array['director']))
with check (private.is_platform_admin() or private.has_org_role(organization_id, array['director']));

create policy plan_actions_select_members
on public.plan_actions for select to authenticated
using (private.is_platform_admin() or private.has_active_membership(organization_id));
create policy plan_actions_insert_leadership
on public.plan_actions for insert to authenticated
with check (private.is_platform_admin() or private.has_org_role(organization_id, array['director']));
create policy plan_actions_update_management
on public.plan_actions for update to authenticated
using (
  private.is_platform_admin()
  or private.has_org_role(organization_id, array['director', 'supervisor'])
)
with check (
  private.is_platform_admin()
  or private.has_org_role(organization_id, array['director', 'supervisor'])
);

create policy performance_goals_select_authorized
on public.performance_goals for select to authenticated
using (
  private.can_view_performance_goal(
    organization_id,
    scope_type,
    scope_id
  )
);
create policy performance_goals_manage_leadership
on public.performance_goals for all to authenticated
using (private.is_platform_admin() or private.has_org_role(organization_id, array['director']))
with check (private.is_platform_admin() or private.has_org_role(organization_id, array['director']));

create policy training_modules_select_members
on public.training_modules for select to authenticated
using (private.is_platform_admin() or private.has_active_membership(organization_id));
create policy training_modules_manage_leadership
on public.training_modules for all to authenticated
using (private.is_platform_admin() or private.has_org_role(organization_id, array['director']))
with check (private.is_platform_admin() or private.has_org_role(organization_id, array['director']));

create policy management_rituals_select_members
on public.management_rituals for select to authenticated
using (private.is_platform_admin() or private.has_active_membership(organization_id));
create policy management_rituals_manage_leadership
on public.management_rituals for all to authenticated
using (private.is_platform_admin() or private.has_org_role(organization_id, array['director']))
with check (private.is_platform_admin() or private.has_org_role(organization_id, array['director']));

create policy meeting_records_select_authorized
on public.meeting_records for select to authenticated
using (
  private.is_platform_admin()
  or private.has_org_role(organization_id, array['director'])
  or team_id in (select private.managed_team_ids())
  or team_id in (select private.current_user_team_ids())
);
create policy meeting_records_insert_management
on public.meeting_records for insert to authenticated
with check (
  private.is_platform_admin()
  or private.has_org_role(organization_id, array['director'])
  or (
    private.has_org_role(organization_id, array['supervisor'])
    and team_id in (select private.managed_team_ids())
  )
);
create policy meeting_records_update_management
on public.meeting_records for update to authenticated
using (
  private.is_platform_admin()
  or private.has_org_role(organization_id, array['director'])
  or (
    private.has_org_role(organization_id, array['supervisor'])
    and team_id in (select private.managed_team_ids())
  )
)
with check (
  private.is_platform_admin()
  or private.has_org_role(organization_id, array['director'])
  or (
    private.has_org_role(organization_id, array['supervisor'])
    and team_id in (select private.managed_team_ids())
  )
);

create policy feedback_records_select_authorized
on public.feedback_records for select to authenticated
using (
  private.is_platform_admin()
  or private.has_org_role(organization_id, array['director'])
  or target_member_id = private.current_member_id(organization_id)
  or author_member_id = private.current_member_id(organization_id)
  or team_id in (select private.managed_team_ids())
);
create policy feedback_records_insert_management
on public.feedback_records for insert to authenticated
with check (private.can_manage_feedback_target(organization_id, target_member_id));
create policy feedback_records_update_management
on public.feedback_records for update to authenticated
using (private.can_manage_feedback_target(organization_id, target_member_id))
with check (private.can_manage_feedback_target(organization_id, target_member_id));

-- --------------------------------------------------------------------------
-- Template inicial RF Consórcios
-- --------------------------------------------------------------------------

do $$
declare
  v_org_id uuid;
  v_operation_id uuid;
  v_plan_id uuid;
  v_phase1 uuid;
  v_phase2 uuid;
  v_phase3 uuid;
  v_phase4 uuid;
begin
  select o.id into v_org_id
  from public.organizations o
  where o.slug = 'rf-consorcios'
  limit 1;

  select op.id into v_operation_id
  from public.operations op
  where op.organization_id = v_org_id
    and op.slug = 'consorcio-automoveis'
  limit 1;

  if v_org_id is null or v_operation_id is null then
    raise exception 'Organização RF ou operação de automóveis não encontrada.';
  end if;

  insert into public.commercial_plans (
    organization_id, operation_id, title, description, duration_days,
    baseline_monthly_sales, target_monthly_sales, growth_target_percent,
    recognition_criteria, status, setup_status, is_template, metadata
  ) values (
    v_org_id,
    v_operation_id,
    'Plano de Aceleração Comercial — 90 Dias',
    'Programa para elevar a produtividade da operação atual por diagnóstico, padronização, treinamento aplicado, coaching, metas, follow-up e gestão por dados.',
    90,
    130,
    169,
    30,
    'Cota registrada e validada, com primeira parcela paga. Cancelamentos e estornos devem ser ajustados sem deteriorar a persistência da carteira.',
    'draft',
    'template',
    true,
    jsonb_build_object(
      'data_origin', 'template',
      'protection_expectation', 'A meta de 30% é um objetivo de gestão condicionado aos dados, à liderança e à disciplina de execução; não constitui garantia de venda.',
      'first_milestone', 'Ao final dos 10 primeiros dias úteis: baseline, cinco maiores gargalos, metas preliminares e plano detalhado das semanas 3 a 12.',
      'learning_method', array['explicação', 'demonstração', 'simulação', 'aplicação'],
      'expected_structure', jsonb_build_object('pdvs', 3, 'supervisors', 3, 'salespersons', 20)
    )
  )
  returning id into v_plan_id;

  insert into public.plan_phases (
    organization_id, plan_id, sequence_no, name, period_label,
    start_day, end_day, objective, metadata
  ) values
    (v_org_id, v_plan_id, 1, 'Diagnóstico e baseline', 'Dias 1–10', 1, 10,
      'Entender como as 130 cotas são produzidas e localizar os maiores vazamentos do funil.',
      jsonb_build_object('deliverable', 'Dados históricos, observação em campo, mapa de gargalos e score inicial.')),
    (v_org_id, v_plan_id, 2, 'Padronização comercial', 'Semanas 3–4', 11, 30,
      'Criar linguagem, funil, metas e processo de atendimento comuns.',
      jsonb_build_object('deliverable', 'Funil, scripts, cadências, metas e critérios de registro.')),
    (v_org_id, v_plan_id, 3, 'Treinamento e coaching', 'Semanas 5–8', 31, 60,
      'Elevar competência técnica, comportamental e execução em campo.',
      jsonb_build_object('deliverable', 'Trilha, role-plays, certificação e coaching em campo.')),
    (v_org_id, v_plan_id, 4, 'Aceleração e otimização', 'Semanas 9–12', 61, 90,
      'Escalar o que funcionou, corrigir vazamentos e realizar o reforecast do dia 90.',
      jsonb_build_object('deliverable', 'Testes, reativação, gestão por indicadores e plano dos 90 dias seguintes.'));

  select id into v_phase1 from public.plan_phases where plan_id = v_plan_id and sequence_no = 1;
  select id into v_phase2 from public.plan_phases where plan_id = v_plan_id and sequence_no = 2;
  select id into v_phase3 from public.plan_phases where plan_id = v_plan_id and sequence_no = 3;
  select id into v_phase4 from public.plan_phases where plan_id = v_plan_id and sequence_no = 4;

  insert into public.plan_actions (
    organization_id, plan_id, phase_id, title, description, category,
    responsible_role, due_day, priority
  ) values
    (v_org_id, v_plan_id, v_phase1, 'Solicitar dados dos últimos 3 a 6 meses', 'Produção, crédito, qualidade, equipe, funil, produto, incentivos e base de oportunidades.', 'data', 'shared', 3, 'critical'),
    (v_org_id, v_plan_id, v_phase1, 'Validar o baseline de 130 cotas', 'Ajustar sazonalidade, dias de funcionamento, férias, campanhas, cancelamentos e persistência.', 'diagnosis', 'epsa', 5, 'critical'),
    (v_org_id, v_plan_id, v_phase1, 'Diagnosticar o funil dos 3 PDVs', 'Mapear abordagens, conversas, diagnósticos, simulações, propostas, vendas e follow-ups.', 'diagnosis', 'epsa', 8, 'high'),
    (v_org_id, v_plan_id, v_phase1, 'Observar atendimentos em campo', 'Avaliar abordagem, diagnóstico, explicação, objeções, fechamento e registro.', 'diagnosis', 'epsa', 8, 'high'),
    (v_org_id, v_plan_id, v_phase1, 'Mapear competências dos 20 vendedores', 'Classificar produto, técnica, processo, comportamento e produtividade.', 'diagnosis', 'epsa', 10, 'high'),
    (v_org_id, v_plan_id, v_phase1, 'Avaliar os 3 supervisores', 'Aplicar score inicial de gestão de funil, coaching, feedback e forecast.', 'leadership', 'epsa', 10, 'high'),
    (v_org_id, v_plan_id, v_phase1, 'Aplicar teste inicial de produto', 'Identificar lacunas de conhecimento e riscos de promessa indevida.', 'training', 'epsa', 10, 'high'),
    (v_org_id, v_plan_id, v_phase1, 'Priorizar os cinco maiores gargalos', 'Ordenar gargalos por impacto, urgência, evidência e possibilidade de correção.', 'diagnosis', 'shared', 10, 'critical'),
    (v_org_id, v_plan_id, v_phase1, 'Definir metas preliminares', 'Propor metas iniciais por RF, PDV, equipe e vendedor, sujeitas à validação.', 'data', 'shared', 10, 'high'),

    (v_org_id, v_plan_id, v_phase2, 'Padronizar o funil comercial', 'Definir critérios mínimos da abordagem até a 3ª parcela paga.', 'process', 'epsa', 18, 'critical'),
    (v_org_id, v_plan_id, v_phase2, 'Criar scripts flexíveis de abordagem e diagnóstico', 'Padronizar finalidade e perguntas sem robotizar a linguagem.', 'process', 'epsa', 21, 'high'),
    (v_org_id, v_plan_id, v_phase2, 'Estruturar apresentação em três cenários', 'Organizar cenários conservador, equilibrado e acelerado sem promessa de contemplação.', 'process', 'epsa', 23, 'high'),
    (v_org_id, v_plan_id, v_phase2, 'Criar manual de objeções', 'Cobrir urgência, prazo, confiança, financiamento, taxa e “vou pensar”.', 'process', 'epsa', 25, 'high'),
    (v_org_id, v_plan_id, v_phase2, 'Definir cadência de follow-up e reativação', 'Registrar motivo, interesse, cenário, canal, data e próximo passo.', 'follow_up', 'shared', 27, 'critical'),
    (v_org_id, v_plan_id, v_phase2, 'Definir critérios de registro no CRM', 'Aplicar a regra: sem responsável, etapa e próximo passo, não há forecast.', 'process', 'shared', 27, 'high'),
    (v_org_id, v_plan_id, v_phase2, 'Aprovar metas por PDV e equipe', 'Revisar a distribuição modelo após o diagnóstico de fluxo e capacidade.', 'data', 'rf_direction', 30, 'critical'),

    (v_org_id, v_plan_id, v_phase3, 'Treinar domínio do produto', 'Grupo, assembleias, contemplação, lances, taxas, reajustes, documentação e crédito.', 'training', 'epsa', 38, 'critical'),
    (v_org_id, v_plan_id, v_phase3, 'Treinar abordagem e venda consultiva', 'Praticar abertura curta, permissão, perguntas, escuta e recomendação.', 'training', 'epsa', 42, 'high'),
    (v_org_id, v_plan_id, v_phase3, 'Realizar role-plays e banca de objeções', 'Avaliar clareza, ética, direção e capacidade de condução.', 'coaching', 'shared', 48, 'high'),
    (v_org_id, v_plan_id, v_phase3, 'Executar coaching em campo', 'Observar atendimento real e registrar feedback com evidências.', 'coaching', 'epsa', 55, 'critical'),
    (v_org_id, v_plan_id, v_phase3, 'Certificar vendedores com nota mínima de 80%', 'Combinar prova de produto, simulação, objeções e atendimento observado.', 'training', 'shared', 60, 'critical'),
    (v_org_id, v_plan_id, v_phase3, 'Desenvolver supervisores nos rituais de gestão', 'Daily, microtreinamento, revisão de funil, feedback e forecast.', 'leadership', 'epsa', 60, 'critical'),
    (v_org_id, v_plan_id, v_phase3, 'Criar plano de recuperação dos não certificados', 'Definir ações, prazos, evidências e nova avaliação.', 'coaching', 'supervisor', 60, 'high'),

    (v_org_id, v_plan_id, v_phase4, 'Testar abordagem por horário e perfil de fluxo', 'Comparar taxa de parada e diagnóstico por turno.', 'optimization', 'supervisor', 70, 'medium'),
    (v_org_id, v_plan_id, v_phase4, 'Reativar contatos dos últimos 90 ou 180 dias', 'Recuperar simulações e propostas ainda aderentes.', 'follow_up', 'supervisor', 75, 'high'),
    (v_org_id, v_plan_id, v_phase4, 'Executar força-tarefa de simulações não fechadas', 'Priorizar oportunidades por aderência, urgência e próximo passo.', 'follow_up', 'shared', 78, 'high'),
    (v_org_id, v_plan_id, v_phase4, 'Implantar campanha de indicação', 'Solicitar indicações qualificadas sem comprometer a qualidade da venda.', 'optimization', 'rf_direction', 82, 'medium'),
    (v_org_id, v_plan_id, v_phase4, 'Replicar comportamentos dos melhores vendedores', 'Documentar e treinar práticas com evidência de conversão e qualidade.', 'coaching', 'supervisor', 84, 'high'),
    (v_org_id, v_plan_id, v_phase4, 'Realizar o reforecast do dia 90', 'Recalibrar metas com baseline, conversões, persistência e capacidade observada.', 'data', 'shared', 88, 'critical'),
    (v_org_id, v_plan_id, v_phase4, 'Apresentar relatório dos 90 dias', 'Resultados, aprendizados, gargalos remanescentes e decisões.', 'report', 'epsa', 90, 'critical'),
    (v_org_id, v_plan_id, v_phase4, 'Definir plano dos 90 dias seguintes', 'Consolidação, autonomia dos supervisores e continuidade da melhoria.', 'report', 'shared', 90, 'high');

  insert into public.performance_goals (
    organization_id, plan_id, scope_type, scope_id, metric_code, label,
    baseline_value, target_value, unit, period_type, setup_status, metadata
  ) values
    (v_org_id, v_plan_id, 'organization', v_org_id, 'validated_sales', 'Cotas validadas por mês', 130, 169, 'count', 'monthly', 'pending_confirmation', jsonb_build_object('recognition', '1ª parcela paga; ajustar cancelamentos e estornos')),
    (v_org_id, v_plan_id, 'organization', v_org_id, 'average_per_salesperson', 'Média por vendedor/mês', 6.50, 8.45, 'ratio', 'monthly', 'pending_confirmation', '{}'::jsonb),
    (v_org_id, v_plan_id, 'organization', v_org_id, 'average_per_pdv', 'Média por PDV/mês', 43.30, 56.30, 'ratio', 'monthly', 'pending_confirmation', '{}'::jsonb),
    (v_org_id, v_plan_id, 'organization', v_org_id, 'qualified_conversations_growth', 'Evolução de conversas qualificadas', 0, 10, 'percent', '90_days', 'template', jsonb_build_object('hypothesis', true)),
    (v_org_id, v_plan_id, 'organization', v_org_id, 'diagnosis_simulation_growth', 'Evolução de diagnóstico para simulação', 0, 10, 'percent', '90_days', 'template', jsonb_build_object('hypothesis', true)),
    (v_org_id, v_plan_id, 'organization', v_org_id, 'followup_closing_growth', 'Evolução de fechamento e follow-up', 0, 8, 'percent', '90_days', 'template', jsonb_build_object('hypothesis', true));

  insert into public.performance_goals (
    organization_id, plan_id, scope_type, scope_id, metric_code, label,
    baseline_value, target_value, unit, period_type, setup_status, metadata
  )
  select
    v_org_id,
    v_plan_id,
    'sales_location',
    sl.id,
    'validated_sales',
    'Cotas validadas — ' || sl.name,
    case sl.slug when 'pdv-1' then 43.30 when 'pdv-2' then 43.30 else 43.40 end,
    case sl.slug when 'pdv-1' then 56.30 when 'pdv-2' then 56.30 else 56.40 end,
    'count',
    'monthly',
    'pending_confirmation',
    jsonb_build_object('distribution', 'provisional_equal_split')
  from public.sales_locations sl
  where sl.organization_id = v_org_id
    and sl.slug in ('pdv-1', 'pdv-2', 'pdv-3');

  insert into public.performance_goals (
    organization_id, plan_id, scope_type, scope_id, metric_code, label,
    baseline_value, target_value, unit, period_type, setup_status, metadata
  )
  select
    v_org_id,
    v_plan_id,
    'team',
    t.id,
    'validated_sales',
    'Cotas validadas — ' || t.name,
    case t.name when 'Equipe Modelo 1' then 43.30 when 'Equipe Modelo 2' then 43.30 else 43.40 end,
    case t.name when 'Equipe Modelo 1' then 56.30 when 'Equipe Modelo 2' then 56.30 else 56.40 end,
    'count',
    'monthly',
    'pending_confirmation',
    jsonb_build_object('distribution', 'provisional_equal_split')
  from public.teams t
  where t.organization_id = v_org_id
    and t.name in ('Equipe Modelo 1', 'Equipe Modelo 2', 'Equipe Modelo 3');

  insert into public.training_modules (
    organization_id, plan_id, sequence_no, title, objective,
    duration_minutes, passing_score, critical_error, metadata
  ) values
    (v_org_id, v_plan_id, 1, 'Domínio do produto', 'Grupo, assembleias, contemplação, sorteio, lances, taxas, reajustes, documentação, uso do crédito e regras da administradora.', 90, 80, 'Promessa indevida ou omissão de condição relevante.', jsonb_build_object('phase', 3)),
    (v_org_id, v_plan_id, 2, 'Alternativas de compra', 'Comparar com responsabilidade consórcio, financiamento, compra à vista e planejamento financeiro.', 60, 80, 'Desqualificar alternativas sem diagnóstico do cliente.', jsonb_build_object('phase', 3)),
    (v_org_id, v_plan_id, 3, 'Abordagem em shopping', 'Abertura curta, permissão, curiosidade, leitura do fluxo e transição para o diagnóstico.', 60, 80, null, jsonb_build_object('phase', 3, 'attention_seconds', '30-60')),
    (v_org_id, v_plan_id, 4, 'Venda consultiva', 'Perguntas, escuta, objetivo, urgência, capacidade financeira e perfil decisório.', 90, 80, null, jsonb_build_object('phase', 3)),
    (v_org_id, v_plan_id, 5, 'Apresentação da solução', 'Simulação em cenários, recomendação e explicação simples e transparente.', 90, 80, 'Prometer contemplação ou prazo garantido.', jsonb_build_object('phase', 3)),
    (v_org_id, v_plan_id, 6, 'Tratamento de objeções', 'Urgência, prazo, confiança, financiamento, taxa, comparação e “vou pensar”.', 90, 80, null, jsonb_build_object('phase', 3)),
    (v_org_id, v_plan_id, 7, 'Fechamento', 'Resumo de valor, confirmação de entendimento, escolha entre opções e próximo passo.', 60, 80, null, jsonb_build_object('phase', 3)),
    (v_org_id, v_plan_id, 8, 'Follow-up', 'WhatsApp, ligação, cadência, recuperação de propostas e agendamento.', 60, 80, null, jsonb_build_object('phase', 3)),
    (v_org_id, v_plan_id, 9, 'Indicações e carteira', 'Solicitação de indicações, reativação de clientes e geração de oportunidades.', 60, 80, null, jsonb_build_object('phase', 4)),
    (v_org_id, v_plan_id, 10, 'Persistência', 'Alinhamento de expectativas, onboarding e redução de cancelamentos.', 60, 80, 'Venda sem alinhamento de expectativa ou informação relevante.', jsonb_build_object('phase', 4));

  insert into public.management_rituals (
    organization_id, plan_id, title, frequency_label, responsible_role,
    duration_minutes, expected_output
  ) values
    (v_org_id, v_plan_id, 'Abertura do PDV', 'Diária', 'Supervisor', 15, 'Resultado anterior, meta, agenda e foco do dia.'),
    (v_org_id, v_plan_id, 'Fechamento do dia', 'Diária', 'Supervisor', 10, 'Placar, aprendizados e follow-ups críticos.'),
    (v_org_id, v_plan_id, 'Microtreinamento', '2× por semana', 'Supervisor', 20, 'Um comportamento ou tema de produto praticado.'),
    (v_org_id, v_plan_id, 'Role-play', 'Semanal', 'Supervisor / EPSA', 45, 'Prática observada e avaliação com critérios.'),
    (v_org_id, v_plan_id, 'Revisão de funil', 'Semanal', 'Supervisor / EPSA', 60, 'Conversões, aging e plano de ação.'),
    (v_org_id, v_plan_id, 'Reunião de supervisores', 'Semanal', 'EPSA', 60, 'Comparação dos PDVs e coaching da liderança.'),
    (v_org_id, v_plan_id, 'Feedback individual', 'Quinzenal', 'Supervisor', 30, 'Evidência, causa, ação e acompanhamento.'),
    (v_org_id, v_plan_id, 'ROPRE com Raphael', 'Semanal', 'EPSA / RF', 45, 'Resultados, objetivos, premissas, riscos e entregas.'),
    (v_org_id, v_plan_id, 'Performance mensal', 'Mensal', 'Direção / Supervisores', 90, 'Vendas, conversão, qualidade e capacidade.');
end;
$$;

commit;
