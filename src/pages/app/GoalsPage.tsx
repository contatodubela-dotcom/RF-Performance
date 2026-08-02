import { useMemo, useState } from 'react'
import {
  useMutation,
  useQuery,
  useQueryClient,
} from '@tanstack/react-query'
import {
  Flag,
  Pencil,
  Target,
  TrendingUp,
} from 'lucide-react'
import { toast } from 'sonner'
import { supabase } from '@/lib/supabase'
import { useAuth } from '@/contexts/AuthContext'
import { useCommercialPlan } from '@/hooks/useCommercialPlan'
import { useOrganizationStats } from '@/hooks/useOrganizationStats'
import type { PerformanceGoal } from '@/types/commercialPlan'
import { formatGoalValue } from '@/lib/commercialPlan'
import PageHeader from '@/components/shared/PageHeader'
import LoadingSpinner from '@/components/shared/LoadingSpinner'
import EmptyState from '@/components/shared/EmptyState'
import {
  Dialog,
  DialogContent,
  DialogHeader,
  DialogTitle,
} from '@/components/ui/dialog'

function getNumericGoalMetadata(
  goal: PerformanceGoal,
  key: string,
): number | null {
  const value = goal.metadata?.[key]

  return typeof value === 'number' &&
    Number.isFinite(value)
    ? value
    : null
}

function GoalEditor({
  goal,
  onClose,
}: {
  goal: PerformanceGoal
  onClose: () => void
}) {
  const { profile } = useAuth()
  const qc = useQueryClient()
  const [baseline, setBaseline] = useState(
    goal.baseline_value?.toString() ?? '',
  )
  const [target, setTarget] = useState(
    goal.target_value?.toString() ?? '',
  )
  const [actual, setActual] = useState(
    goal.actual_value?.toString() ?? '',
  )
  const [confirmed, setConfirmed] = useState(
    goal.setup_status === 'confirmed',
  )

  const currentOperationalReference =
    getNumericGoalMetadata(
      goal,
      'current_operational_reference',
    )

  const mutation = useMutation({
    mutationFn: async () => {
      const { error } = await supabase
        .from('performance_goals')
        .update({
          baseline_value:
            baseline === '' ? null : Number(baseline),
          target_value:
            target === '' ? null : Number(target),
          actual_value:
            actual === '' ? null : Number(actual),
          setup_status: confirmed
            ? 'confirmed'
            : 'pending_confirmation',
          is_template: !confirmed,
          updated_by: profile?.id,
        })
        .eq('id', goal.id)

      if (error) throw error
    },
    onSuccess: () => {
      toast.success('Meta atualizada.')
      qc.invalidateQueries({
        queryKey: ['performance-goals'],
      })
      onClose()
    },
    onError: (error: Error) =>
      toast.error(error.message),
  })

  return (
    <div className="space-y-4">
      <div className="rounded-lg border border-blue-200 bg-blue-50 p-3 text-sm text-blue-900">
        O baseline histórico só deve ser preenchido após a
        validação do dashboard oficial. As referências de
        capacidade permanecem sujeitas ao alinhamento com a
        liderança.
      </div>

      <div>
        <label className="form-label">Indicador</label>
        <input
          className="form-input bg-gray-50"
          value={goal.label}
          disabled
        />
      </div>

      {currentOperationalReference != null && (
        <div>
          <label className="form-label">
            Referência operacional atual
          </label>
          <input
            className="form-input bg-gray-50"
            value={formatGoalValue(
              currentOperationalReference,
              goal.unit,
            )}
            disabled
          />
        </div>
      )}

      <div className="grid grid-cols-3 gap-3">
        <div>
          <label className="form-label">
            Baseline histórico
          </label>
          <input
            type="number"
            step="0.01"
            className="form-input"
            value={baseline}
            onChange={(event) =>
              setBaseline(event.target.value)
            }
            placeholder="A definir"
          />
        </div>
        <div>
          <label className="form-label">
            Capacidade plena / meta
          </label>
          <input
            type="number"
            step="0.01"
            className="form-input"
            value={target}
            onChange={(event) =>
              setTarget(event.target.value)
            }
          />
        </div>
        <div>
          <label className="form-label">
            Realizado
          </label>
          <input
            type="number"
            step="0.01"
            className="form-input"
            value={actual}
            onChange={(event) =>
              setActual(event.target.value)
            }
            placeholder="Sem apuração"
          />
        </div>
      </div>

      <label className="flex items-start gap-3 rounded-lg border border-gray-200 p-3">
        <input
          type="checkbox"
          className="mt-1 h-4 w-4"
          checked={confirmed}
          onChange={(event) =>
            setConfirmed(event.target.checked)
          }
        />
        <span>
          <span className="block text-sm font-medium text-gray-900">
            Confirmar meta após diagnóstico e alinhamento
          </span>
          <span className="block text-xs text-gray-500">
            Marque somente quando baseline, capacidade e
            distribuição estiverem validados.
          </span>
        </span>
      </label>

      <div className="flex justify-end gap-2">
        <button
          className="btn-secondary"
          onClick={onClose}
        >
          Cancelar
        </button>
        <button
          className="btn-primary"
          disabled={mutation.isPending}
          onClick={() => mutation.mutate()}
        >
          {mutation.isPending
            ? 'Salvando...'
            : 'Salvar'}
        </button>
      </div>
    </div>
  )
}

function GoalRow({
  goal,
  locationName,
  teamNames,
  canManage,
  onEdit,
}: {
  goal: PerformanceGoal
  locationName: string
  teamNames: string[]
  canManage: boolean
  onEdit: () => void
}) {
  const currentOperationalReference =
    getNumericGoalMetadata(
      goal,
      'current_operational_reference',
    )

  const situationLabel =
    goal.setup_status === 'confirmed'
      ? 'Confirmada'
      : goal.setup_status === 'template'
        ? 'Hipótese'
        : 'A validar'

  const situationClass =
    goal.setup_status === 'confirmed'
      ? 'badge-active'
      : 'badge-inactive'

  return (
    <tr className="border-t border-gray-100">
      <td className="px-4 py-3">
        <p className="text-sm font-medium text-gray-900">
          {locationName}
        </p>
        <p className="text-xs text-gray-400">
          {goal.label}
        </p>
      </td>
      <td className="px-4 py-3 text-sm text-gray-700">
        {teamNames.length > 0
          ? teamNames.join(', ')
          : 'Equipe não vinculada'}
      </td>
      <td className="px-4 py-3 text-sm font-medium text-gray-700">
        {formatGoalValue(
          currentOperationalReference,
          goal.unit,
        )}
      </td>
      <td className="px-4 py-3 text-sm font-semibold text-brand-800">
        {formatGoalValue(
          goal.target_value,
          goal.unit,
        )}
      </td>
      <td className="px-4 py-3 text-sm text-gray-600">
        {goal.actual_value == null
          ? 'Sem apuração'
          : formatGoalValue(
              goal.actual_value,
              goal.unit,
            )}
      </td>
      <td className="px-4 py-3">
        <span className={`badge ${situationClass}`}>
          {situationLabel}
        </span>
      </td>
      <td className="px-4 py-3 text-right">
        {canManage && (
          <button
            onClick={onEdit}
            className="rounded p-1.5 text-gray-400 hover:bg-gray-100 hover:text-brand-700"
            title="Editar meta do PDV"
          >
            <Pencil className="h-4 w-4" />
          </button>
        )}
      </td>
    </tr>
  )
}

export default function GoalsPage() {
  const {
    activeOrganization,
    isAdmin,
    isDirector,
  } = useAuth()
  const orgId = activeOrganization?.id
  const canManage = isAdmin || isDirector
  const [editGoal, setEditGoal] =
    useState<PerformanceGoal | null>(null)

  const { data: plan } = useCommercialPlan(orgId)
  const {
    data: stats,
    isLoading: statsLoading,
  } = useOrganizationStats(orgId)

  const { data: goals, isLoading: goalsLoading } =
    useQuery({
      queryKey: ['performance-goals', plan?.id],
      enabled: !!plan?.id,
      queryFn: async () => {
        const { data, error } = await supabase
          .from('performance_goals')
          .select('*')
          .eq('plan_id', plan!.id)
          .neq('status', 'archived')
          .order('scope_type')
          .order('label')

        if (error) throw error
        return (data ?? []) as PerformanceGoal[]
      },
    })

  const { data: locations } = useQuery({
    queryKey: ['goal-locations', orgId],
    enabled: !!orgId,
    queryFn: async () => {
      const { data, error } = await supabase
        .from('sales_locations')
        .select('id, name')
        .eq('organization_id', orgId!)
        .eq('status', 'active')

      if (error) throw error
      return data ?? []
    },
  })

  const { data: teams } = useQuery({
    queryKey: ['goal-teams', orgId],
    enabled: !!orgId,
    queryFn: async () => {
      const { data, error } = await supabase
        .from('teams')
        .select('id, name, sales_location_id')
        .eq('organization_id', orgId!)
        .eq('status', 'active')

      if (error) throw error
      return data ?? []
    },
  })

  const locationNames = useMemo(
    () =>
      new Map(
        (locations ?? []).map(
          (location) =>
            [location.id, location.name] as const,
        ),
      ),
    [locations],
  )

  const teamsByLocation = useMemo(() => {
    const map = new Map<string, string[]>()

    for (const team of teams ?? []) {
      if (!team.sales_location_id) continue

      const current =
        map.get(team.sales_location_id) ?? []
      current.push(team.name)
      map.set(team.sales_location_id, current)
    }

    return map
  }, [teams])

  if (goalsLoading || statsLoading) {
    return (
      <div className="page-container flex min-h-[400px] items-center justify-center">
        <LoadingSpinner size="lg" />
      </div>
    )
  }

  if (!goals?.length) {
    return (
      <div className="page-container">
        <EmptyState
          icon={Target}
          title="Nenhuma meta cadastrada"
        />
      </div>
    )
  }

  const mainGoal = goals.find(
    (goal) =>
      goal.scope_type === 'organization' &&
      goal.metric_code === 'validated_sales',
  )
  const hypothesisGoals = goals.filter(
    (goal) =>
      goal.scope_type === 'organization' &&
      goal.unit === 'percent',
  )
  const locationGoals = goals
    .filter(
      (goal) =>
        goal.scope_type === 'sales_location',
    )
    .sort((first, second) =>
      (
        locationNames.get(first.scope_id) ??
        first.label
      ).localeCompare(
        locationNames.get(second.scope_id) ??
          second.label,
        'pt-BR',
      ),
    )

  const baselineHistorical = mainGoal
    ? formatGoalValue(
        mainGoal.baseline_value,
        mainGoal.unit,
      )
    : 'A definir'

  return (
    <div className="page-container">
      <PageHeader
        title="Metas"
        description="Referências de capacidade, metas de resultado e hipóteses de processo."
      />

      {mainGoal && (
        <section className="mb-6 rounded-xl border border-brand-200 bg-brand-50 p-5">
          <div className="grid gap-5 lg:grid-cols-[1fr_auto] lg:items-center">
            <div>
              <p className="text-sm font-semibold text-brand-900">
                Referências da{' '}
                {activeOrganization?.trade_name ??
                  'organização'}
              </p>
              <p className="mt-1 max-w-2xl text-sm text-brand-800">
                Venda reconhecida quando registrada e
                validada pela administradora. O histórico
                oficial permanece pendente de validação.
              </p>
            </div>

            <div className="flex flex-wrap items-center gap-3">
              <div className="min-w-24 text-center">
                <p className="text-2xl font-bold text-gray-900">
                  {baselineHistorical}
                </p>
                <p className="text-xs text-gray-500">
                  baseline histórico
                </p>
              </div>

              <TrendingUp className="h-5 w-5 text-brand-600" />

              <div className="min-w-24 text-center">
                <p className="text-2xl font-bold text-brand-800">
                  {stats?.adjustedMonthlyCapacityReference ??
                    0}
                </p>
                <p className="text-xs text-gray-500">
                  referência atual
                </p>
              </div>

              <div className="min-w-24 text-center">
                <p className="text-2xl font-bold text-green-700">
                  {stats?.fullMonthlyCapacityReference ??
                    mainGoal.target_value ??
                    0}
                </p>
                <p className="text-xs text-gray-500">
                  capacidade plena
                </p>
              </div>

              {canManage && (
                <button
                  className="rounded p-2 text-brand-700 hover:bg-white"
                  onClick={() =>
                    setEditGoal(mainGoal)
                  }
                  title="Editar meta geral"
                >
                  <Pencil className="h-4 w-4" />
                </button>
              )}
            </div>
          </div>
        </section>
      )}

      <div className="mb-6 grid gap-4 md:grid-cols-3">
        {hypothesisGoals.map((goal) => (
          <div key={goal.id} className="card p-4">
            <Flag className="mb-2 h-5 w-5 text-brand-700" />
            <p className="text-2xl font-bold text-gray-900">
              +
              {formatGoalValue(
                goal.target_value,
                'percent',
              )}
            </p>
            <p className="mt-1 text-sm text-gray-600">
              {goal.label}
            </p>
            <p className="mt-2 text-xs text-gray-400">
              Hipótese inicial a recalibrar.
            </p>
          </div>
        ))}
      </div>

      <div className="card overflow-hidden">
        <div className="border-b border-gray-100 px-4 py-4">
          <h2 className="font-semibold text-gray-900">
            Distribuição consolidada por PDV
          </h2>
          <p className="mt-1 text-xs text-gray-500">
            Cada linha reúne o PDV e sua equipe vinculada. As
            metas de equipe continuam registradas no banco
            para futuras visões de supervisão, sem duplicar
            os totais desta tela.
          </p>
        </div>

        <div className="overflow-x-auto">
          <table className="w-full">
            <thead>
              <tr className="bg-gray-50 text-left text-xs uppercase tracking-wide text-gray-500">
                <th className="px-4 py-3">
                  PDV
                </th>
                <th className="px-4 py-3">
                  Equipe
                </th>
                <th className="px-4 py-3">
                  Referência atual
                </th>
                <th className="px-4 py-3">
                  Capacidade plena
                </th>
                <th className="px-4 py-3">
                  Realizado
                </th>
                <th className="px-4 py-3">
                  Situação
                </th>
                <th className="px-4 py-3"></th>
              </tr>
            </thead>
            <tbody>
              {locationGoals.map((goal) => (
                <GoalRow
                  key={goal.id}
                  goal={goal}
                  locationName={
                    locationNames.get(
                      goal.scope_id,
                    ) ?? goal.label
                  }
                  teamNames={
                    teamsByLocation.get(
                      goal.scope_id,
                    ) ?? []
                  }
                  canManage={canManage}
                  onEdit={() =>
                    setEditGoal(goal)
                  }
                />
              ))}
            </tbody>
          </table>
        </div>
      </div>

      <Dialog
        open={!!editGoal}
        onOpenChange={(open) =>
          !open && setEditGoal(null)
        }
      >
        <DialogContent>
          <DialogHeader>
            <DialogTitle>
              Editar meta
            </DialogTitle>
          </DialogHeader>
          {editGoal && (
            <GoalEditor
              goal={editGoal}
              onClose={() =>
                setEditGoal(null)
              }
            />
          )}
        </DialogContent>
      </Dialog>
    </div>
  )
}