import { useMemo } from 'react'
import { useQuery } from '@tanstack/react-query'
import {
  BarChart3,
  Gauge,
  MapPin,
  Target,
  TrendingUp,
  Users2,
} from 'lucide-react'
import { supabase } from '@/lib/supabase'
import { useAuth } from '@/contexts/AuthContext'
import { useCommercialPlanReference } from '@/hooks/useCommercialPlan'
import type { PerformanceGoal } from '@/types/commercialPlan'
import PageHeader from '@/components/shared/PageHeader'
import LoadingSpinner from '@/components/shared/LoadingSpinner'
import EmptyState from '@/components/shared/EmptyState'

function getMetadataNumber(
  goal: PerformanceGoal,
  key: string,
): number | null {
  const value = goal.metadata?.[key]

  if (typeof value === 'number' && Number.isFinite(value)) {
    return value
  }

  if (typeof value === 'string' && value.trim() !== '') {
    const parsed = Number(value)
    return Number.isFinite(parsed) ? parsed : null
  }

  return null
}

function formatNumber(value: number | null): string {
  if (value == null) return '—'

  return new Intl.NumberFormat('pt-BR', {
    maximumFractionDigits: 2,
  }).format(value)
}

function formatActual(value: number | null): string {
  return value == null ? 'Sem apuração' : formatNumber(value)
}

function calculateAchievement(
  actual: number | null,
  target: number | null,
): number | null {
  if (actual == null || target == null || target <= 0) {
    return null
  }

  return (actual / target) * 100
}

function formatAchievement(value: number | null): string {
  if (value == null) return '—'

  return `${new Intl.NumberFormat('pt-BR', {
    minimumFractionDigits: 1,
    maximumFractionDigits: 1,
  }).format(value)}%`
}

function getScopeLabel(goal: PerformanceGoal): string {
  const cleaned = goal.label.replace(
    /^Cotas validadas\s*[-–—]\s*/i,
    '',
  )

  return cleaned || goal.label
}

function getSetupLabel(goal: PerformanceGoal): string {
  if (goal.setup_status === 'confirmed') return 'Confirmada'
  if (goal.setup_status === 'template') return 'Hipótese'
  return 'A validar'
}

function getSituation(goal: PerformanceGoal): {
  label: string
  className: string
} {
  if (goal.actual_value == null) {
    return {
      label: 'Sem apuração',
      className: 'bg-gray-100 text-gray-700',
    }
  }

  const operationalReference = getMetadataNumber(
    goal,
    'current_operational_reference',
  )

  if (
    goal.target_value != null &&
    goal.actual_value >= goal.target_value
  ) {
    return {
      label: 'Meta atingida',
      className: 'bg-green-100 text-green-800',
    }
  }

  if (
    operationalReference != null &&
    goal.actual_value >= operationalReference
  ) {
    return {
      label: 'Referência atingida',
      className: 'bg-blue-100 text-blue-800',
    }
  }

  return {
    label: 'Em acompanhamento',
    className: 'bg-amber-100 text-amber-800',
  }
}

function ResultsTable({
  title,
  description,
  icon: Icon,
  goals,
}: {
  title: string
  description: string
  icon: typeof MapPin
  goals: PerformanceGoal[]
}) {
  if (goals.length === 0) return null

  return (
    <section className="rounded-xl border border-gray-200 bg-white shadow-sm">
      <div className="flex items-start gap-3 border-b border-gray-100 px-5 py-4">
        <div className="rounded-lg bg-brand-50 p-2 text-brand-700">
          <Icon className="h-5 w-5" />
        </div>
        <div>
          <h2 className="text-base font-semibold text-gray-900">
            {title}
          </h2>
          <p className="mt-1 text-sm text-gray-500">
            {description}
          </p>
        </div>
      </div>

      <div className="overflow-x-auto">
        <table className="min-w-full">
          <thead className="bg-gray-50">
            <tr className="text-left text-xs font-semibold uppercase tracking-wide text-gray-500">
              <th className="px-5 py-3">Unidade</th>
              <th className="px-5 py-3 text-right">
                Referência operacional
              </th>
              <th className="px-5 py-3 text-right">
                Meta plena
              </th>
              <th className="px-5 py-3 text-right">
                Realizado
              </th>
              <th className="px-5 py-3 text-right">
                Atingimento
              </th>
              <th className="px-5 py-3">Situação</th>
            </tr>
          </thead>

          <tbody>
            {goals.map((goal) => {
              const operationalReference = getMetadataNumber(
                goal,
                'current_operational_reference',
              )
              const achievement = calculateAchievement(
                goal.actual_value,
                goal.target_value,
              )
              const situation = getSituation(goal)

              return (
                <tr
                  key={goal.id}
                  className="border-t border-gray-100"
                >
                  <td className="px-5 py-4">
                    <p className="text-sm font-medium text-gray-900">
                      {getScopeLabel(goal)}
                    </p>
                    <p className="mt-1 text-xs text-gray-500">
                      {getSetupLabel(goal)}
                    </p>
                  </td>

                  <td className="px-5 py-4 text-right text-sm text-gray-700">
                    {formatNumber(operationalReference)}
                  </td>

                  <td className="px-5 py-4 text-right text-sm font-semibold text-gray-900">
                    {formatNumber(goal.target_value)}
                  </td>

                  <td className="px-5 py-4 text-right text-sm font-semibold text-brand-800">
                    {formatActual(goal.actual_value)}
                  </td>

                  <td className="px-5 py-4 text-right text-sm text-gray-700">
                    {formatAchievement(achievement)}
                  </td>

                  <td className="px-5 py-4">
                    <span
                      className={`inline-flex rounded-full px-2.5 py-1 text-xs font-medium ${situation.className}`}
                    >
                      {situation.label}
                    </span>
                  </td>
                </tr>
              )
            })}
          </tbody>
        </table>
      </div>
    </section>
  )
}

export default function ResultsPage() {
  const { activeOrganization, user } = useAuth()
  const orgId = activeOrganization?.id

  const {
    data: plan,
    isLoading: planLoading,
    error: planError,
  } = useCommercialPlanReference(orgId)

  const {
    data: goals = [],
    isLoading: goalsLoading,
    error: goalsError,
  } = useQuery({
    queryKey: [
      'commercial-results',
      plan?.id,
      user?.id,
      'validated-sales',
    ],
    enabled: !!plan?.id && !!user?.id,
    queryFn: async () => {
      const { data, error } = await supabase
        .from('performance_goals')
        .select('*')
        .eq('plan_id', plan!.id)
        .eq('metric_code', 'validated_sales')
        .neq('status', 'archived')
        .order('scope_type')
        .order('label')

      if (error) throw error

      return (data ?? []) as PerformanceGoal[]
    },
  })

  const mainGoal = useMemo(
    () =>
      goals.find(
        (goal) =>
          goal.scope_type === 'organization' &&
          goal.metric_code === 'validated_sales',
      ) ?? null,
    [goals],
  )

  const locationGoals = useMemo(
    () =>
      goals
        .filter(
          (goal) => goal.scope_type === 'sales_location',
        )
        .sort((first, second) =>
          getScopeLabel(first).localeCompare(
            getScopeLabel(second),
            'pt-BR',
          ),
        ),
    [goals],
  )

  const teamGoals = useMemo(
    () =>
      goals
        .filter((goal) => goal.scope_type === 'team')
        .sort((first, second) =>
          getScopeLabel(first).localeCompare(
            getScopeLabel(second),
            'pt-BR',
          ),
        ),
    [goals],
  )

  if (planLoading || goalsLoading) {
    return (
      <div className="page-container flex min-h-[400px] items-center justify-center">
        <LoadingSpinner size="lg" />
      </div>
    )
  }

  if (planError || goalsError) {
    const message =
      planError instanceof Error
        ? planError.message
        : goalsError instanceof Error
          ? goalsError.message
          : 'Não foi possível carregar os resultados comerciais.'

    return (
      <div className="page-container">
        <PageHeader
          title="Resultados"
          description="Meta, referência operacional e realizado consolidado de cotas validadas."
        />

        <div className="rounded-xl border border-red-200 bg-red-50 p-5 text-sm text-red-800">
          {message}
        </div>
      </div>
    )
  }

  if (!plan || !mainGoal) {
    return (
      <div className="page-container">
        <PageHeader
          title="Resultados"
          description="Meta, referência operacional e realizado consolidado de cotas validadas."
        />

        <EmptyState
          icon={BarChart3}
          title="Nenhum resultado comercial disponível"
        />
      </div>
    )
  }

  const operationalReference = getMetadataNumber(
    mainGoal,
    'current_operational_reference',
  )
  const achievement = calculateAchievement(
    mainGoal.actual_value,
    mainGoal.target_value,
  )

  return (
    <div className="page-container">
      <PageHeader
        title="Resultados"
        description="Meta, referência operacional e realizado consolidado de cotas validadas."
      />

      <div className="mb-6 rounded-xl border border-blue-200 bg-blue-50 p-4 text-sm text-blue-900">
        O realizado apresentado nesta página utiliza a apuração
        consolidada registrada nas metas comerciais. Enquanto não
        houver apuração, o sistema exibe “Sem apuração” e não assume
        resultado zero. Esta etapa não calcula conversão nem vendas
        transacionais em tempo real.
      </div>

      <section className="mb-6 grid gap-4 sm:grid-cols-2 xl:grid-cols-4">
        <div className="rounded-xl border border-gray-200 bg-white p-5 shadow-sm">
          <div className="flex items-center justify-between">
            <p className="text-sm font-medium text-gray-500">
              Meta mensal
            </p>
            <Target className="h-5 w-5 text-brand-700" />
          </div>
          <p className="mt-3 text-3xl font-bold text-gray-900">
            {formatNumber(mainGoal.target_value)}
          </p>
          <p className="mt-1 text-xs text-gray-500">
            cotas validadas
          </p>
        </div>

        <div className="rounded-xl border border-gray-200 bg-white p-5 shadow-sm">
          <div className="flex items-center justify-between">
            <p className="text-sm font-medium text-gray-500">
              Referência operacional
            </p>
            <Gauge className="h-5 w-5 text-brand-700" />
          </div>
          <p className="mt-3 text-3xl font-bold text-gray-900">
            {formatNumber(operationalReference)}
          </p>
          <p className="mt-1 text-xs text-gray-500">
            capacidade atual de referência
          </p>
        </div>

        <div className="rounded-xl border border-gray-200 bg-white p-5 shadow-sm">
          <div className="flex items-center justify-between">
            <p className="text-sm font-medium text-gray-500">
              Realizado
            </p>
            <TrendingUp className="h-5 w-5 text-brand-700" />
          </div>
          <p
            className={`mt-3 font-bold ${
              mainGoal.actual_value == null
                ? 'text-xl text-gray-600'
                : 'text-3xl text-gray-900'
            }`}
          >
            {formatActual(mainGoal.actual_value)}
          </p>
          <p className="mt-1 text-xs text-gray-500">
            apuração consolidada do mês
          </p>
        </div>

        <div className="rounded-xl border border-gray-200 bg-white p-5 shadow-sm">
          <div className="flex items-center justify-between">
            <p className="text-sm font-medium text-gray-500">
              Atingimento
            </p>
            <BarChart3 className="h-5 w-5 text-brand-700" />
          </div>
          <p className="mt-3 text-3xl font-bold text-gray-900">
            {formatAchievement(achievement)}
          </p>
          <p className="mt-1 text-xs text-gray-500">
            realizado ÷ meta mensal
          </p>
        </div>
      </section>

      <div className="space-y-6">
        <ResultsTable
          title="Resultados por PDV"
          description="Referência operacional, meta plena e realizado das unidades visíveis para o seu perfil."
          icon={MapPin}
          goals={locationGoals}
        />

        <ResultsTable
          title="Resultados por equipe"
          description="Acompanhamento consolidado das equipes visíveis dentro da hierarquia comercial."
          icon={Users2}
          goals={teamGoals}
        />
      </div>
    </div>
  )
}
