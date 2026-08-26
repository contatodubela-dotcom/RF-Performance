import { useMemo, useState } from 'react'
import { useQuery } from '@tanstack/react-query'
import {
  Bar,
  BarChart,
  CartesianGrid,
  XAxis,
  YAxis,
} from 'recharts'
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
import {
  ChartContainer,
  ChartLegend,
  ChartLegendContent,
  ChartTooltip,
  ChartTooltipContent,
  type ChartConfig,
} from '@/components/ui/chart'

interface ValidatedSalesActual {
  scope_type:
    | 'organization'
    | 'sales_location'
    | 'team'
    | 'organization_member'
  scope_id: string
  actual_value: number | null
}

interface SalespersonDrilldownActual {
  plan_id: string
  organization_id: string
  competence_month: string
  sales_location_id: string
  sales_location_name: string
  team_id: string
  team_name: string
  salesperson_member_id: string
  salesperson_name: string
  salesperson_email: string | null
  actual_value: number | null
}

interface CommercialProductivityIndicator {
  plan_id: string
  organization_id: string
  competence_month: string
  metric_code:
    | 'average_per_salesperson'
    | 'average_per_pdv'
  label: string
  unit: string
  target_value: number | null
  operational_reference: number | null
  denominator: number | null
  validated_units: number | null
  actual_value: number | null
}

const resultsComparisonChartConfig = {
  actual: {
    label: 'Realizado',
    color: '#15803d',
  },
  operationalReference: {
    label: 'Referência operacional',
    color: '#4ade80',
  },
  target: {
    label: 'Meta plena',
    color: '#14532d',
  },
} satisfies ChartConfig

const salespersonRankingChartConfig = {
  actual: {
    label: 'Realizado',
    color: '#15803d',
  },
} satisfies ChartConfig

function getCurrentCompetenceMonth(): string {
  const now = new Date()
  const month = String(now.getMonth() + 1).padStart(2, '0')

  return `${now.getFullYear()}-${month}-01`
}

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


function SalespersonDrilldownTable({
  rows,
}: {
  rows: SalespersonDrilldownActual[]
}) {
  const [selectedLocationId, setSelectedLocationId] =
    useState('all')
  const [selectedTeamId, setSelectedTeamId] = useState('all')
  const [searchTerm, setSearchTerm] = useState('')

  const locationOptions = useMemo(() => {
    const locations = new Map<string, string>()

    rows.forEach((row) => {
      locations.set(
        row.sales_location_id,
        row.sales_location_name,
      )
    })

    return Array.from(locations, ([id, name]) => ({
      id,
      name,
    })).sort((first, second) =>
      first.name.localeCompare(second.name, 'pt-BR'),
    )
  }, [rows])

  const teamOptions = useMemo(() => {
    const teams = new Map<string, string>()

    rows
      .filter(
        (row) =>
          selectedLocationId === 'all' ||
          row.sales_location_id === selectedLocationId,
      )
      .forEach((row) => {
        teams.set(row.team_id, row.team_name)
      })

    return Array.from(teams, ([id, name]) => ({
      id,
      name,
    })).sort((first, second) =>
      first.name.localeCompare(second.name, 'pt-BR'),
    )
  }, [rows, selectedLocationId])

  const filteredRows = useMemo(() => {
    const normalizedSearch = searchTerm.trim().toLocaleLowerCase(
      'pt-BR',
    )

    return rows.filter((row) => {
      if (
        selectedLocationId !== 'all' &&
        row.sales_location_id !== selectedLocationId
      ) {
        return false
      }

      if (
        selectedTeamId !== 'all' &&
        row.team_id !== selectedTeamId
      ) {
        return false
      }

      if (!normalizedSearch) return true

      const searchableText = [
        row.salesperson_name,
        row.salesperson_email ?? '',
        row.team_name,
        row.sales_location_name,
      ]
        .join(' ')
        .toLocaleLowerCase('pt-BR')

      return searchableText.includes(normalizedSearch)
    })
  }, [
    rows,
    searchTerm,
    selectedLocationId,
    selectedTeamId,
  ])

  return (
    <section className="rounded-xl border border-gray-200 bg-white shadow-sm">
      <div className="flex flex-col gap-4 border-b border-gray-100 px-5 py-4 lg:flex-row lg:items-start lg:justify-between">
        <div className="flex items-start gap-3">
          <div className="rounded-lg bg-brand-50 p-2 text-brand-700">
            <Users2 className="h-5 w-5" />
          </div>

          <div>
            <h2 className="text-base font-semibold text-gray-900">
              Resultados por vendedor
            </h2>
            <p className="mt-1 text-sm text-gray-500">
              Drilldown das vendas validadas atribuídas a vendedor,
              preservando o PDV e a equipe registrados na venda.
            </p>
          </div>
        </div>

        <div className="grid w-full gap-3 sm:grid-cols-3 lg:max-w-3xl">
          <label className="text-xs font-medium text-gray-600">
            PDV
            <select
              value={selectedLocationId}
              onChange={(event) => {
                setSelectedLocationId(event.target.value)
                setSelectedTeamId('all')
              }}
              className="mt-1 w-full rounded-lg border border-gray-300 bg-white px-3 py-2 text-sm text-gray-900 outline-none focus:border-brand-500 focus:ring-2 focus:ring-brand-100"
            >
              <option value="all">Todos os PDVs</option>
              {locationOptions.map((location) => (
                <option key={location.id} value={location.id}>
                  {location.name}
                </option>
              ))}
            </select>
          </label>

          <label className="text-xs font-medium text-gray-600">
            Equipe
            <select
              value={selectedTeamId}
              onChange={(event) =>
                setSelectedTeamId(event.target.value)
              }
              className="mt-1 w-full rounded-lg border border-gray-300 bg-white px-3 py-2 text-sm text-gray-900 outline-none focus:border-brand-500 focus:ring-2 focus:ring-brand-100"
            >
              <option value="all">Todas as equipes</option>
              {teamOptions.map((team) => (
                <option key={team.id} value={team.id}>
                  {team.name}
                </option>
              ))}
            </select>
          </label>

          <label className="text-xs font-medium text-gray-600">
            Buscar
            <input
              type="search"
              value={searchTerm}
              onChange={(event) =>
                setSearchTerm(event.target.value)
              }
              placeholder="Vendedor, e-mail..."
              className="mt-1 w-full rounded-lg border border-gray-300 bg-white px-3 py-2 text-sm text-gray-900 outline-none placeholder:text-gray-400 focus:border-brand-500 focus:ring-2 focus:ring-brand-100"
            />
          </label>
        </div>
      </div>

      {rows.length === 0 ? (
        <div className="px-5 py-8 text-center">
          <p className="text-sm font-medium text-gray-700">
            Nenhuma venda validada atribuída a vendedor nesta
            competência.
          </p>
          <p className="mt-1 text-xs text-gray-500">
            O drilldown será exibido quando existirem vendas
            validadas com vendedor atribuído.
          </p>
        </div>
      ) : filteredRows.length === 0 ? (
        <div className="px-5 py-8 text-center text-sm text-gray-600">
          Nenhum vendedor encontrado para os filtros selecionados.
        </div>
      ) : (
        <div className="overflow-x-auto">
          <table className="min-w-full">
            <thead className="bg-gray-50">
              <tr className="text-left text-xs font-semibold uppercase tracking-wide text-gray-500">
                <th className="px-5 py-3">PDV</th>
                <th className="px-5 py-3">Equipe</th>
                <th className="px-5 py-3">Vendedor</th>
                <th className="px-5 py-3">E-mail</th>
                <th className="px-5 py-3 text-right">
                  Realizado
                </th>
              </tr>
            </thead>

            <tbody>
              {filteredRows.map((row) => (
                <tr
                  key={[
                    row.sales_location_id,
                    row.team_id,
                    row.salesperson_member_id,
                  ].join(':')}
                  className="border-t border-gray-100"
                >
                  <td className="px-5 py-4 text-sm text-gray-700">
                    {row.sales_location_name}
                  </td>

                  <td className="px-5 py-4 text-sm text-gray-700">
                    {row.team_name}
                  </td>

                  <td className="px-5 py-4">
                    <p className="text-sm font-medium text-gray-900">
                      {row.salesperson_name}
                    </p>
                  </td>

                  <td className="px-5 py-4 text-sm text-gray-500">
                    {row.salesperson_email ?? '—'}
                  </td>

                  <td className="px-5 py-4 text-right text-sm font-semibold text-brand-800">
                    {formatActual(row.actual_value)}
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}
    </section>
  )
}

function ResultsComparisonChart({
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

  const chartData = goals.map((goal) => ({
    name: getScopeLabel(goal),
    operationalReference: getMetadataNumber(
      goal,
      'current_operational_reference',
    ),
    target: goal.target_value,
    actual: goal.actual_value,
  }))

  const hasActual = chartData.some((item) => item.actual != null)
  const chartHeight = Math.max(300, chartData.length * 54)

  return (
    <div className="rounded-xl border border-gray-200 bg-white shadow-sm">
      <div className="flex flex-col gap-3 border-b border-gray-100 px-5 py-4 sm:flex-row sm:items-start sm:justify-between">
        <div className="flex items-start gap-3">
          <div className="rounded-lg bg-brand-50 p-2 text-brand-700">
            <Icon className="h-5 w-5" />
          </div>
          <div>
            <h3 className="text-sm font-semibold text-gray-900">
              {title}
            </h3>
            <p className="mt-1 text-xs leading-5 text-gray-500">
              {description}
            </p>
          </div>
        </div>

        {!hasActual && (
          <span className="w-fit rounded-full bg-gray-100 px-2.5 py-1 text-xs font-medium text-gray-600">
            Sem apuração realizada
          </span>
        )}
      </div>

      <div className="px-3 py-4 sm:px-5">
        <ChartContainer
          config={resultsComparisonChartConfig}
          className="w-full aspect-auto"
          style={{ height: chartHeight }}
        >
          <BarChart
            accessibilityLayer
            data={chartData}
            layout="vertical"
            margin={{ left: 0, right: 20 }}
          >
            <CartesianGrid horizontal={false} />
            <YAxis
              dataKey="name"
              type="category"
              tickLine={false}
              axisLine={false}
              width={150}
              tickMargin={8}
            />
            <XAxis
              type="number"
              tickLine={false}
              axisLine={false}
              allowDecimals={false}
              tickFormatter={(value) => formatNumber(Number(value))}
            />
            <ChartTooltip
              cursor={false}
              content={<ChartTooltipContent indicator="line" />}
            />
            <ChartLegend content={<ChartLegendContent />} />
            <Bar
              dataKey="operationalReference"
              fill="var(--color-operationalReference)"
              radius={4}
            />
            <Bar
              dataKey="target"
              fill="var(--color-target)"
              radius={4}
            />
            <Bar
              dataKey="actual"
              fill="var(--color-actual)"
              radius={4}
            />
          </BarChart>
        </ChartContainer>
      </div>
    </div>
  )
}

function CommercialVisualManagementSection({
  mainGoal,
  locationGoals,
  teamGoals,
  salespersonRows,
}: {
  mainGoal: PerformanceGoal
  locationGoals: PerformanceGoal[]
  teamGoals: PerformanceGoal[]
  salespersonRows: SalespersonDrilldownActual[]
}) {
  const consolidatedChartData = [
    {
      name: 'Competência atual',
      operationalReference: getMetadataNumber(
        mainGoal,
        'current_operational_reference',
      ),
      target: mainGoal.target_value,
      actual: mainGoal.actual_value,
    },
  ]

  const salespersonRankingData = useMemo(() => {
    const bySalesperson = new Map<
      string,
      { name: string; actual: number | null }
    >()

    salespersonRows.forEach((row) => {
      const current = bySalesperson.get(row.salesperson_member_id)

      if (!current) {
        bySalesperson.set(row.salesperson_member_id, {
          name: row.salesperson_name,
          actual: row.actual_value,
        })
        return
      }

      if (current.actual == null || row.actual_value == null) {
        current.actual = null
        return
      }

      current.actual += row.actual_value
    })

    return Array.from(bySalesperson.values()).sort((first, second) => {
      if (first.actual == null && second.actual == null) {
        return first.name.localeCompare(second.name, 'pt-BR')
      }
      if (first.actual == null) return 1
      if (second.actual == null) return -1
      if (second.actual !== first.actual) return second.actual - first.actual
      return first.name.localeCompare(second.name, 'pt-BR')
    })
  }, [salespersonRows])

  const hasSalespersonActual = salespersonRankingData.some(
    (item) => item.actual != null,
  )
  const salespersonChartHeight = Math.max(
    300,
    salespersonRankingData.length * 46,
  )

  return (
    <section className="rounded-xl border border-gray-200 bg-gray-50/60 p-4 shadow-sm sm:p-5">
      <div className="mb-5 flex items-start gap-3">
        <div className="rounded-lg bg-brand-700 p-2 text-white">
          <BarChart3 className="h-5 w-5" />
        </div>
        <div>
          <h2 className="text-base font-semibold text-gray-900">
            Gestão visual dos resultados
          </h2>
          <p className="mt-1 max-w-3xl text-sm text-gray-500">
            Leitura gerencial da competência atual com comparação entre
            referência operacional, meta plena e realizado, sem alterar
            a fonte de apuração das vendas validadas.
          </p>
        </div>
      </div>

      <div className="grid gap-5 xl:grid-cols-2">
        <div className="rounded-xl border border-gray-200 bg-white shadow-sm xl:col-span-2">
          <div className="flex flex-col gap-3 border-b border-gray-100 px-5 py-4 sm:flex-row sm:items-start sm:justify-between">
            <div>
              <h3 className="text-sm font-semibold text-gray-900">
                Visão consolidada do mês
              </h3>
              <p className="mt-1 text-xs leading-5 text-gray-500">
                Comparativo geral entre a capacidade atual de referência,
                a meta mensal e o realizado validado.
              </p>
            </div>

            {mainGoal.actual_value == null && (
              <span className="w-fit rounded-full bg-gray-100 px-2.5 py-1 text-xs font-medium text-gray-600">
                Sem apuração realizada
              </span>
            )}
          </div>

          <div className="px-3 py-4 sm:px-5">
            <ChartContainer
              config={resultsComparisonChartConfig}
              className="h-[300px] w-full aspect-auto"
            >
              <BarChart
                accessibilityLayer
                data={consolidatedChartData}
                margin={{ left: 0, right: 12 }}
              >
                <CartesianGrid vertical={false} />
                <XAxis
                  dataKey="name"
                  tickLine={false}
                  axisLine={false}
                  tickMargin={8}
                />
                <YAxis
                  tickLine={false}
                  axisLine={false}
                  allowDecimals={false}
                  width={44}
                  tickFormatter={(value) => formatNumber(Number(value))}
                />
                <ChartTooltip
                  cursor={false}
                  content={<ChartTooltipContent indicator="line" />}
                />
                <ChartLegend content={<ChartLegendContent />} />
                <Bar
                  dataKey="operationalReference"
                  fill="var(--color-operationalReference)"
                  radius={4}
                />
                <Bar
                  dataKey="target"
                  fill="var(--color-target)"
                  radius={4}
                />
                <Bar
                  dataKey="actual"
                  fill="var(--color-actual)"
                  radius={4}
                />
              </BarChart>
            </ChartContainer>
          </div>
        </div>

        <ResultsComparisonChart
          title="Desempenho por PDV"
          description="Comparação visual das unidades comerciais da competência atual."
          icon={MapPin}
          goals={locationGoals}
        />

        <ResultsComparisonChart
          title="Desempenho por equipe"
          description="Comparação visual das equipes comerciais da competência atual."
          icon={Users2}
          goals={teamGoals}
        />

        <div className="rounded-xl border border-gray-200 bg-white shadow-sm xl:col-span-2">
          <div className="flex flex-col gap-3 border-b border-gray-100 px-5 py-4 sm:flex-row sm:items-start sm:justify-between">
            <div className="flex items-start gap-3">
              <div className="rounded-lg bg-brand-50 p-2 text-brand-700">
                <TrendingUp className="h-5 w-5" />
              </div>
              <div>
                <h3 className="text-sm font-semibold text-gray-900">
                  Ranking por vendedor
                </h3>
                <p className="mt-1 text-xs leading-5 text-gray-500">
                  Total validado por vendedor na competência, somando
                  atribuições históricas do mesmo vendedor quando houver.
                </p>
              </div>
            </div>

            {!hasSalespersonActual && (
              <span className="w-fit rounded-full bg-gray-100 px-2.5 py-1 text-xs font-medium text-gray-600">
                Sem apuração realizada
              </span>
            )}
          </div>

          {salespersonRankingData.length === 0 ? (
            <div className="px-5 py-10 text-center">
              <p className="text-sm font-medium text-gray-700">
                Nenhuma venda validada atribuída a vendedor nesta
                competência.
              </p>
              <p className="mt-1 text-xs text-gray-500">
                O ranking será exibido quando houver apuração atribuída a
                vendedor.
              </p>
            </div>
          ) : (
            <div className="px-3 py-4 sm:px-5">
              <ChartContainer
                config={salespersonRankingChartConfig}
                className="w-full aspect-auto"
                style={{ height: salespersonChartHeight }}
              >
                <BarChart
                  accessibilityLayer
                  data={salespersonRankingData}
                  layout="vertical"
                  margin={{ left: 0, right: 20 }}
                >
                  <CartesianGrid horizontal={false} />
                  <YAxis
                    dataKey="name"
                    type="category"
                    tickLine={false}
                    axisLine={false}
                    width={160}
                    tickMargin={8}
                  />
                  <XAxis
                    type="number"
                    tickLine={false}
                    axisLine={false}
                    allowDecimals={false}
                    tickFormatter={(value) => formatNumber(Number(value))}
                  />
                  <ChartTooltip
                    cursor={false}
                    content={<ChartTooltipContent indicator="line" />}
                  />
                  <Bar
                    dataKey="actual"
                    fill="var(--color-actual)"
                    radius={4}
                  />
                </BarChart>
              </ChartContainer>
            </div>
          )}
        </div>
      </div>
    </section>
  )
}

function ProductivityIndicatorsSection({
  indicators,
}: {
  indicators: CommercialProductivityIndicator[]
}) {
  if (indicators.length === 0) return null

  return (
    <section className="rounded-xl border border-gray-200 bg-white shadow-sm">
      <div className="flex items-start gap-3 border-b border-gray-100 px-5 py-4">
        <div className="rounded-lg bg-brand-50 p-2 text-brand-700">
          <Gauge className="h-5 w-5" />
        </div>

        <div>
          <h2 className="text-base font-semibold text-gray-900">
            Indicadores de produtividade
          </h2>
          <p className="mt-1 text-sm text-gray-500">
            Médias mensais calculadas automaticamente sobre as
            vendas validadas da competência atual.
          </p>
        </div>
      </div>

      <div className="grid gap-4 p-5 md:grid-cols-2">
        {indicators.map((indicator) => {
          const achievement = calculateAchievement(
            indicator.actual_value,
            indicator.target_value,
          )
          const denominatorLabel =
            indicator.metric_code === 'average_per_salesperson'
              ? 'produtores ativos'
              : 'PDVs ativos'

          return (
            <div
              key={indicator.metric_code}
              className="rounded-xl border border-gray-200 bg-gray-50 p-5"
            >
              <div className="flex items-start justify-between gap-4">
                <div>
                  <p className="text-sm font-semibold text-gray-900">
                    {indicator.label}
                  </p>
                  <p className="mt-1 text-xs text-gray-500">
                    {indicator.metric_code ===
                    'average_per_salesperson'
                      ? 'Cotas validadas por produtor considerado no plano.'
                      : 'Cotas validadas por PDV considerado no plano.'}
                  </p>
                </div>

                {indicator.metric_code ===
                'average_per_salesperson' ? (
                  <Users2 className="h-5 w-5 shrink-0 text-brand-700" />
                ) : (
                  <MapPin className="h-5 w-5 shrink-0 text-brand-700" />
                )}
              </div>

              <p
                className={`mt-4 font-bold ${
                  indicator.actual_value == null
                    ? 'text-xl text-gray-600'
                    : 'text-3xl text-gray-900'
                }`}
              >
                {formatActual(indicator.actual_value)}
              </p>

              <div className="mt-4 grid gap-3 sm:grid-cols-2">
                <div>
                  <p className="text-xs text-gray-500">
                    Referência operacional
                  </p>
                  <p className="mt-1 text-sm font-semibold text-gray-800">
                    {formatNumber(
                      indicator.operational_reference,
                    )}
                  </p>
                </div>

                <div>
                  <p className="text-xs text-gray-500">
                    Meta
                  </p>
                  <p className="mt-1 text-sm font-semibold text-gray-800">
                    {formatNumber(indicator.target_value)}
                  </p>
                </div>

                <div>
                  <p className="text-xs text-gray-500">
                    Base de cálculo
                  </p>
                  <p className="mt-1 text-sm font-semibold text-gray-800">
                    {indicator.denominator == null
                      ? '—'
                      : `${formatNumber(
                          indicator.denominator,
                        )} ${denominatorLabel}`}
                  </p>
                </div>

                <div>
                  <p className="text-xs text-gray-500">
                    Atingimento
                  </p>
                  <p className="mt-1 text-sm font-semibold text-gray-800">
                    {formatAchievement(achievement)}
                  </p>
                </div>
              </div>
            </div>
          )
        })}
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

  const competenceMonth = useMemo(
    () => getCurrentCompetenceMonth(),
    [],
  )

  const {
    data: actuals = [],
    isLoading: actualsLoading,
    error: actualsError,
  } = useQuery({
    queryKey: [
      'validated-sales-actuals',
      plan?.id,
      user?.id,
      competenceMonth,
    ],
    enabled: !!plan?.id && !!user?.id,
    queryFn: async () => {
      const { data, error } = await supabase.rpc(
        'get_validated_sales_actuals' as never,
        {
          p_plan_id: plan!.id,
          p_competence_month: competenceMonth,
        } as never,
      )

      if (error) throw error

      return (data ?? []) as unknown as ValidatedSalesActual[]
    },
  })
  const {
    data: salespersonDrilldown = [],
    isLoading: salespersonDrilldownLoading,
    error: salespersonDrilldownError,
  } = useQuery({
    queryKey: [
      'validated-sales-salesperson-drilldown',
      plan?.id,
      user?.id,
      competenceMonth,
    ],
    enabled: !!plan?.id && !!user?.id,
    queryFn: async () => {
      const { data, error } = await supabase.rpc(
        'get_validated_sales_salesperson_drilldown' as never,
        {
          p_plan_id: plan!.id,
          p_competence_month: competenceMonth,
        } as never,
      )

      if (error) throw error

      return (data ?? []) as unknown as SalespersonDrilldownActual[]
    },
  })

  const {
    data: productivityIndicators = [],
    isLoading: productivityIndicatorsLoading,
    error: productivityIndicatorsError,
  } = useQuery({
    queryKey: [
      'commercial-productivity-indicators',
      plan?.id,
      user?.id,
      competenceMonth,
    ],
    enabled: !!plan?.id && !!user?.id,
    queryFn: async () => {
      const { data, error } = await supabase.rpc(
        'get_commercial_productivity_indicators' as never,
        {
          p_plan_id: plan!.id,
          p_competence_month: competenceMonth,
        } as never,
      )

      if (error) throw error

      return (data ?? []) as unknown as CommercialProductivityIndicator[]
    },
  })

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

  const actualValueByScope = useMemo(
    () => new Map(
      actuals.map((actual) => [
        `${actual.scope_type}:${actual.scope_id}`,
        actual.actual_value,
      ] as const),
    ),
    [actuals],
  )

  const resultGoals = useMemo(
    () => goals.map((goal) => ({
      ...goal,
      actual_value: actualValueByScope.get(
        `${goal.scope_type}:${goal.scope_id}`,
      ) ?? null,
    })),
    [goals, actualValueByScope],
  )
  const mainGoal = useMemo(
    () =>
      resultGoals.find(
        (goal) =>
          goal.scope_type === 'organization' &&
          goal.metric_code === 'validated_sales',
      ) ?? null,
    [resultGoals],
  )

  const locationGoals = useMemo(
    () =>
      resultGoals
        .filter(
          (goal) => goal.scope_type === 'sales_location',
        )
        .sort((first, second) =>
          getScopeLabel(first).localeCompare(
            getScopeLabel(second),
            'pt-BR',
          ),
        ),
    [resultGoals],
  )

  const teamGoals = useMemo(
    () =>
      resultGoals
        .filter((goal) => goal.scope_type === 'team')
        .sort((first, second) =>
          getScopeLabel(first).localeCompare(
            getScopeLabel(second),
            'pt-BR',
          ),
        ),
    [resultGoals],
  )

  if (
    planLoading ||
    goalsLoading ||
    actualsLoading ||
    salespersonDrilldownLoading ||
    productivityIndicatorsLoading
  ) {
    return (
      <div className="page-container flex min-h-[400px] items-center justify-center">
        <LoadingSpinner size="lg" />
      </div>
    )
  }

  if (
    planError ||
    goalsError ||
    actualsError ||
    salespersonDrilldownError ||
    productivityIndicatorsError
  ) {
    const message =
      planError instanceof Error
        ? planError.message
        : goalsError instanceof Error
          ? goalsError.message
          : actualsError instanceof Error
            ? actualsError.message
            : salespersonDrilldownError instanceof Error
              ? salespersonDrilldownError.message
              : productivityIndicatorsError instanceof Error
                ? productivityIndicatorsError.message
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
        O realizado apresentado nesta página é calculado automaticamente
        a partir das vendas validadas da competência atual. Enquanto não
        houver apuração válida, o sistema exibe “Sem apuração” e não
        assume resultado zero.
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
        <CommercialVisualManagementSection
          mainGoal={mainGoal}
          locationGoals={locationGoals}
          teamGoals={teamGoals}
          salespersonRows={salespersonDrilldown}
        />

        <ProductivityIndicatorsSection
          indicators={productivityIndicators}
        />

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

        <SalespersonDrilldownTable
          rows={salespersonDrilldown}
        />
      </div>
    </div>
  )
}
