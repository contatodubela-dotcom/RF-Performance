import {
  useMutation,
  useQuery,
  useQueryClient,
} from '@tanstack/react-query'
import {
  CalendarDays,
  CheckCircle2,
  Circle,
  Clock3,
  Flag,
  ShieldCheck,
  TrendingUp,
} from 'lucide-react'
import { toast } from 'sonner'
import { useAuth } from '@/contexts/AuthContext'
import { supabase } from '@/lib/supabase'
import { useCommercialPlan } from '@/hooks/useCommercialPlan'
import { useOrganizationStats } from '@/hooks/useOrganizationStats'
import type {
  PhaseStatus,
  PlanAction,
  PlanPhase,
} from '@/types/commercialPlan'
import {
  ACTION_STATUS_LABELS,
  formatGoalValue,
  PHASE_STATUS_LABELS,
  PLAN_STATUS_LABELS,
  RESPONSIBLE_ROLE_LABELS,
} from '@/lib/commercialPlan'
import PageHeader from '@/components/shared/PageHeader'
import LoadingSpinner from '@/components/shared/LoadingSpinner'
import EmptyState from '@/components/shared/EmptyState'

function PhaseCard({
  phase,
  actions,
  canManage,
  onStatus,
}: {
  phase: PlanPhase
  actions: PlanAction[]
  canManage: boolean
  onStatus: (id: string, status: PhaseStatus) => void
}) {
  const completed = actions.filter(
    (action) => action.status === 'completed',
  ).length

  return (
    <article className="card overflow-hidden">
      <div className="border-b border-gray-100 p-5">
        <div className="flex flex-col justify-between gap-3 sm:flex-row sm:items-start">
          <div className="flex items-start gap-3">
            <div className="flex h-9 w-9 shrink-0 items-center justify-center rounded-full bg-brand-100 text-sm font-bold text-brand-800">
              {phase.sequence_no}
            </div>
            <div>
              <h2 className="font-semibold text-gray-900">
                {phase.name}
              </h2>
              <p className="mt-0.5 text-xs font-medium text-brand-700">
                {phase.period_label}
              </p>
              <p className="mt-2 text-sm text-gray-600">
                {phase.objective}
              </p>
            </div>
          </div>
          <span
            className={`badge ${
              phase.status === 'completed'
                ? 'badge-active'
                : 'badge-inactive'
            }`}
          >
            {PHASE_STATUS_LABELS[phase.status]}
          </span>
        </div>

        <div className="mt-4">
          <div className="mb-1 flex items-center justify-between text-xs text-gray-500">
            <span>
              {completed}/{actions.length} ações concluídas
            </span>
            <span>
              {Number(phase.progress_percent).toFixed(0)}%
            </span>
          </div>
          <div className="h-2 rounded-full bg-gray-100">
            <div
              className="h-2 rounded-full bg-brand-600 transition-all"
              style={{ width: `${phase.progress_percent}%` }}
            />
          </div>
        </div>
      </div>

      <div className="p-5">
        <ul className="space-y-2">
          {actions.slice(0, 5).map((action) => (
            <li
              key={action.id}
              className="flex items-start gap-2 text-sm"
            >
              {action.status === 'completed' ? (
                <CheckCircle2 className="mt-0.5 h-4 w-4 shrink-0 text-green-600" />
              ) : (
                <Circle className="mt-0.5 h-4 w-4 shrink-0 text-gray-300" />
              )}
              <div className="min-w-0 flex-1">
                <p className="text-gray-800">{action.title}</p>
                <p className="text-xs text-gray-400">
                  {RESPONSIBLE_ROLE_LABELS[
                    action.responsible_role
                  ] ?? action.responsible_role}
                  {action.due_day
                    ? ` · até o dia ${action.due_day}`
                    : ''}
                  {' · '}
                  {ACTION_STATUS_LABELS[action.status]}
                </p>
              </div>
            </li>
          ))}
        </ul>

        {actions.length > 5 && (
          <p className="mt-3 text-xs text-gray-400">
            + {actions.length - 5} ações no módulo Ações
          </p>
        )}

        {canManage && phase.status !== 'completed' && (
          <div className="mt-4 flex gap-2 border-t border-gray-100 pt-4">
            {phase.status === 'planned' && (
              <button
                className="btn-secondary"
                onClick={() =>
                  onStatus(phase.id, 'in_progress')
                }
              >
                Iniciar fase
              </button>
            )}
            <span className="self-center text-xs text-gray-400">
              A fase será concluída quando todas as ações forem
              finalizadas.
            </span>
          </div>
        )}
      </div>
    </article>
  )
}

export default function Plan90DaysPage() {
  const {
    activeOrganization,
    profile,
    isAdmin,
    isDirector,
  } = useAuth()
  const orgId = activeOrganization?.id
  const qc = useQueryClient()
  const canManage = isAdmin || isDirector

  const {
    data: plan,
    isLoading: planLoading,
  } = useCommercialPlan(orgId)
  const {
    data: stats,
    isLoading: statsLoading,
  } = useOrganizationStats(orgId)

  const { data: phases, isLoading: phasesLoading } =
    useQuery({
      queryKey: ['plan-phases', plan?.id],
      enabled: !!plan?.id,
      queryFn: async () => {
        const { data, error } = await supabase
          .from('plan_phases')
          .select('*')
          .eq('plan_id', plan!.id)
          .neq('status', 'archived')
          .order('sequence_no')

        if (error) throw error
        return (data ?? []) as PlanPhase[]
      },
    })

  const { data: actions, isLoading: actionsLoading } =
    useQuery({
      queryKey: ['plan-actions', plan?.id],
      enabled: !!plan?.id,
      queryFn: async () => {
        const { data, error } = await supabase
          .from('plan_actions')
          .select('*')
          .eq('plan_id', plan!.id)
          .neq('status', 'archived')
          .order('due_day')

        if (error) throw error
        return (data ?? []) as PlanAction[]
      },
    })

  const phaseMutation = useMutation({
    mutationFn: async ({
      id,
      status,
    }: {
      id: string
      status: PhaseStatus
    }) => {
      const { error } = await supabase
        .from('plan_phases')
        .update({
          status,
          updated_by: profile?.id,
        })
        .eq('id', id)

      if (error) throw error
    },
    onSuccess: () => {
      toast.success('Fase atualizada.')
      qc.invalidateQueries({ queryKey: ['plan-phases'] })
    },
    onError: (error: Error) =>
      toast.error(error.message),
  })

  if (
    planLoading ||
    statsLoading ||
    phasesLoading ||
    actionsLoading
  ) {
    return (
      <div className="page-container flex min-h-[400px] items-center justify-center">
        <LoadingSpinner size="lg" />
      </div>
    )
  }

  if (!plan) {
    return (
      <div className="page-container">
        <EmptyState
          icon={CalendarDays}
          title="Nenhum plano encontrado"
          description="Crie ou aplique um plano comercial para esta organização."
        />
      </div>
    )
  }

  const completedActions = (actions ?? []).filter(
    (action) => action.status === 'completed',
  ).length
  const progress = actions?.length
    ? Math.round(
        (completedActions / actions.length) * 100,
      )
    : 0

  const usesUpdatedOperationalModel =
    plan.metadata?.operational_model_version ===
    'rf_5_pdvs_2026_08'

  const protection =
    usesUpdatedOperationalModel &&
    typeof plan.metadata?.protection_expectation ===
      'string'
      ? plan.metadata.protection_expectation
      : 'As referências são objetivos de gestão e devem ser recalibradas com dados históricos validados, capacidade observada e disciplina de execução.'

  const setupLabel =
    plan.setup_status === 'confirmed'
      ? 'Plano confirmado'
      : plan.setup_status === 'pending_confirmation'
        ? 'Aguardando validação'
        : 'Plano editável'

  const maturityCurve = stats?.maturityCurve ?? []
  const baselineHistorical =
    plan.metadata?.baseline_status === 'validated'
      ? formatGoalValue(
          plan.baseline_monthly_sales,
          'count',
        )
      : 'A definir'

  return (
    <div className="page-container">
      <PageHeader
        title="Plano de 90 Dias"
        description="Diagnóstico, padronização, treinamento aplicado e aceleração comercial."
      />

      <section className="mb-6 rounded-xl border border-brand-200 bg-brand-50 p-5">
        <div className="grid gap-5 xl:grid-cols-[1fr_auto] xl:items-center">
          <div>
            <div className="flex flex-wrap items-center gap-2">
              <span className="badge bg-blue-100 text-blue-800">
                {setupLabel}
              </span>
              <span className="badge badge-inactive">
                {PLAN_STATUS_LABELS[plan.status]}
              </span>
            </div>

            <h2 className="mt-3 text-lg font-bold text-brand-950">
              {plan.title}
            </h2>
            <p className="mt-1 max-w-3xl text-sm text-brand-900">
              {plan.description}
            </p>

            <div className="mt-4 flex flex-wrap gap-x-6 gap-y-2 text-sm text-brand-900">
              <span className="flex items-center gap-1.5">
                <CalendarDays className="h-4 w-4" />
                {plan.duration_days} dias
              </span>
              <span className="flex items-center gap-1.5">
                <Flag className="h-4 w-4" />
                {phases?.length ?? 0} fases
              </span>
              <span className="flex items-center gap-1.5">
                <Clock3 className="h-4 w-4" />
                {actions?.length ?? 0} ações planejadas
              </span>
            </div>

            <p className="mt-3 text-xs text-brand-700">
              Baseline histórico validado:{' '}
              <strong>{baselineHistorical}</strong>. A referência
              operacional atual e a capacidade plena não substituem o
              histórico oficial.
            </p>
          </div>

          <div className="grid grid-cols-3 gap-2 text-center">
            <div className="rounded-lg bg-white p-3 shadow-sm">
              <p className="text-xl font-bold text-brand-800">
                {stats?.adjustedMonthlyCapacityReference ||
                  '—'}
              </p>
              <p className="text-xs text-gray-500">
                referência atual
              </p>
            </div>
            <div className="rounded-lg bg-white p-3 shadow-sm">
              <p className="text-xl font-bold text-green-700">
                {stats?.fullMonthlyCapacityReference ||
                  plan.target_monthly_sales ||
                  '—'}
              </p>
              <p className="text-xs text-gray-500">
                capacidade plena
              </p>
            </div>
            <div className="rounded-lg bg-white p-3 shadow-sm">
              <p className="text-xl font-bold text-gray-900">
                {stats?.minimumMonthlySalesPerProducer ||
                  '—'}
              </p>
              <p className="text-xs text-gray-500">
                cotas/produtor
              </p>
            </div>
          </div>
        </div>
      </section>

      <div className="mb-6 grid gap-4 sm:grid-cols-3">
        <div className="card p-4">
          <TrendingUp className="mb-2 h-5 w-5 text-brand-700" />
          <p className="text-2xl font-bold text-gray-900">
            {progress}%
          </p>
          <p className="text-sm text-gray-500">
            progresso das ações
          </p>
        </div>

        <div className="card p-4">
          <CheckCircle2 className="mb-2 h-5 w-5 text-green-600" />
          <p className="text-2xl font-bold text-gray-900">
            {completedActions}
          </p>
          <p className="text-sm text-gray-500">
            ações concluídas
          </p>
        </div>

        <div className="card p-4">
          <ShieldCheck className="mb-2 h-5 w-5 text-amber-600" />
          <p className="text-sm font-semibold text-gray-900">
            Venda responsável
          </p>
          <p className="mt-1 text-xs text-gray-500">
            Venda registrada e validada pela administradora, com
            acompanhamento de cancelamentos e persistência.
          </p>
        </div>
      </div>

      {maturityCurve.length > 0 && (
        <section className="mb-6 card p-5">
          <div className="mb-4">
            <h2 className="font-semibold text-gray-900">
              Curva de maturidade da operação
            </h2>
            <p className="mt-1 text-sm text-gray-500">
              Evolução projetada para a capacidade plena de{' '}
              {stats?.plannedProducerCount ?? 0} produtores.
            </p>
          </div>

          <div className="grid gap-3 sm:grid-cols-2 xl:grid-cols-4">
            {maturityCurve.map((point) => (
              <div
                key={point.month}
                className="rounded-lg border border-gray-200 bg-gray-50 p-4"
              >
                <p className="text-xs font-medium uppercase tracking-wide text-gray-500">
                  Mês {point.month}
                </p>
                <p className="mt-1 text-2xl font-bold text-brand-800">
                  {point.full_capacity_sales}
                </p>
                <p className="text-xs text-gray-500">
                  cotas mensais ·{' '}
                  {point.sales_per_producer} por produtor
                </p>
              </div>
            ))}
          </div>
        </section>
      )}

      <div className="mb-6 rounded-lg border border-amber-200 bg-amber-50 p-4">
        <p className="text-sm font-semibold text-amber-900">
          Proteção de expectativa
        </p>
        <p className="mt-1 text-sm text-amber-800">
          {protection}
        </p>
      </div>

      <div className="grid gap-5 xl:grid-cols-2">
        {(phases ?? []).map((phase) => (
          <PhaseCard
            key={phase.id}
            phase={phase}
            actions={(actions ?? []).filter(
              (action) =>
                action.phase_id === phase.id,
            )}
            canManage={canManage}
            onStatus={(id, status) =>
              phaseMutation.mutate({ id, status })
            }
          />
        ))}
      </div>
    </div>
  )
}