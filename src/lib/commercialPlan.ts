import type {
  ActionStatus,
  PhaseStatus,
  PlanStatus,
  TrainingStatus,
} from '@/types/commercialPlan'

export const PLAN_STATUS_LABELS: Record<PlanStatus, string> = {
  draft: 'Modelo em preparação',
  active: 'Em execução',
  completed: 'Concluído',
  archived: 'Arquivado',
}

export const PHASE_STATUS_LABELS: Record<PhaseStatus, string> = {
  planned: 'Planejada',
  in_progress: 'Em andamento',
  completed: 'Concluída',
  archived: 'Arquivada',
}

export const ACTION_STATUS_LABELS: Record<ActionStatus, string> = {
  planned: 'Planejada',
  in_progress: 'Em andamento',
  completed: 'Concluída',
  blocked: 'Bloqueada',
  cancelled: 'Cancelada',
  archived: 'Arquivada',
}

export const TRAINING_STATUS_LABELS: Record<TrainingStatus, string> = {
  planned: 'Planejado',
  in_progress: 'Em andamento',
  completed: 'Concluído',
  archived: 'Arquivado',
}

export const ACTION_CATEGORY_LABELS: Record<string, string> = {
  diagnosis: 'Diagnóstico',
  data: 'Dados e metas',
  process: 'Processo comercial',
  training: 'Treinamento',
  coaching: 'Coaching',
  follow_up: 'Follow-up',
  leadership: 'Liderança',
  meeting: 'Reunião',
  optimization: 'Otimização',
  report: 'Relatório',
}

export const RESPONSIBLE_ROLE_LABELS: Record<string, string> = {
  epsa: 'EPSA',
  rf_direction: 'Direção da empresa',
  supervisor: 'Supervisor',
  salesperson: 'Vendedor',
  shared: 'EPSA / Empresa',
}

export function formatGoalValue(
  value: number | null,
  unit: string,
): string {
  if (value == null) return 'A definir'

  if (unit === 'percent') {
    return `${new Intl.NumberFormat('pt-BR', {
      maximumFractionDigits: 2,
    }).format(value)}%`
  }

  if (unit === 'currency') {
    return new Intl.NumberFormat('pt-BR', {
      style: 'currency',
      currency: 'BRL',
    }).format(value)
  }

  return new Intl.NumberFormat('pt-BR', {
    maximumFractionDigits: 2,
  }).format(value)
}
