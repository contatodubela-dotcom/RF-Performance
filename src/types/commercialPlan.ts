export type PlanStatus = 'draft' | 'active' | 'completed' | 'archived'
export type PhaseStatus = 'planned' | 'in_progress' | 'completed' | 'archived'
export type ActionStatus =
  | 'planned'
  | 'in_progress'
  | 'completed'
  | 'blocked'
  | 'cancelled'
  | 'archived'
export type TrainingStatus = 'planned' | 'in_progress' | 'completed' | 'archived'

export interface CommercialPlan {
  id: string
  organization_id: string
  operation_id: string
  title: string
  description: string | null
  duration_days: number
  baseline_monthly_sales: number | null
  target_monthly_sales: number | null
  growth_target_percent: number | null
  recognition_criteria: string | null
  start_date: string | null
  end_date: string | null
  status: PlanStatus
  setup_status: 'template' | 'pending_confirmation' | 'confirmed'
  is_template: boolean
  metadata: Record<string, unknown>
}

export interface PlanPhase {
  id: string
  organization_id: string
  plan_id: string
  sequence_no: number
  name: string
  period_label: string
  start_day: number
  end_day: number
  objective: string
  status: PhaseStatus
  progress_percent: number
  is_template: boolean
  metadata: Record<string, unknown>
}

export interface PlanAction {
  id: string
  organization_id: string
  plan_id: string
  phase_id: string | null
  title: string
  description: string | null
  category: string
  responsible_role: string
  due_day: number | null
  priority: 'low' | 'medium' | 'high' | 'critical'
  status: ActionStatus
  evidence: string | null
  completed_at: string | null
  is_template: boolean
}

export interface PerformanceGoal {
  id: string
  organization_id: string
  plan_id: string
  scope_type: 'organization' | 'sales_location' | 'team' | 'organization_member'
  scope_id: string
  metric_code: string
  label: string
  baseline_value: number | null
  target_value: number | null
  actual_value: number | null
  unit: 'count' | 'percent' | 'currency' | 'ratio' | 'score'
  period_type: 'daily' | 'weekly' | 'monthly' | '90_days'
  status: 'active' | 'inactive' | 'archived'
  setup_status: 'template' | 'pending_confirmation' | 'confirmed'
  is_template: boolean
  metadata: Record<string, unknown>
}

export interface TrainingModule {
  id: string
  organization_id: string
  plan_id: string
  sequence_no: number
  title: string
  objective: string
  duration_minutes: number
  delivery_method: string
  passing_score: number
  critical_error: string | null
  scheduled_date: string | null
  completed_date: string | null
  status: TrainingStatus
  is_template: boolean
  metadata: Record<string, unknown>
}

export interface ManagementRitual {
  id: string
  organization_id: string
  plan_id: string
  title: string
  frequency_label: string
  responsible_role: string
  duration_minutes: number
  expected_output: string
  status: 'planned' | 'active' | 'inactive' | 'archived'
  is_template: boolean
}

export interface MeetingRecord {
  id: string
  organization_id: string
  plan_id: string | null
  ritual_id: string | null
  team_id: string | null
  title: string
  meeting_at: string
  summary: string | null
  decisions: string | null
  next_steps: string | null
  attendees_count: number | null
  status: 'scheduled' | 'held' | 'cancelled' | 'archived'
}

export interface FeedbackRecord {
  id: string
  organization_id: string
  plan_id: string | null
  team_id: string | null
  target_member_id: string
  author_member_id: string | null
  feedback_type: 'coaching' | 'performance' | 'recognition' | 'corrective'
  occurred_on: string
  fact: string
  impact: string
  cause: string | null
  agreed_action: string
  follow_up_on: string | null
  evidence: string | null
  status: 'open' | 'follow_up' | 'completed' | 'archived'
}
