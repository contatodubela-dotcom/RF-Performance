import {
  Building2,
  CheckCircle2,
  CheckSquare,
  Circle,
  Link2,
  MapPin,
  TrendingUp,
  UserCog,
  Users,
  Users2,
} from 'lucide-react'
import { useAuth } from '@/contexts/AuthContext'
import {
  useOrganizationStats,
  useSetupChecklist,
} from '@/hooks/useOrganizationStats'
import LoadingSpinner from '@/components/shared/LoadingSpinner'

interface StatCardProps {
  label: string
  value: number | string
  detail?: string
  icon: React.ElementType
  color: string
}

function StatCard({
  label,
  value,
  detail,
  icon: Icon,
  color,
}: StatCardProps) {
  return (
    <div className="stat-card">
      <div
        className={`mb-3 flex h-9 w-9 items-center justify-center rounded-lg ${color}`}
      >
        <Icon className="h-5 w-5 text-white" />
      </div>
      <p className="text-2xl font-bold text-gray-900">{value}</p>
      <p className="mt-0.5 text-sm text-gray-500">{label}</p>
      {detail && (
        <p className="mt-1 text-xs leading-4 text-gray-400">{detail}</p>
      )}
    </div>
  )
}

interface CheckItemProps {
  done: boolean
  label: string
}

function CheckItem({ done, label }: CheckItemProps) {
  return (
    <li className="flex items-center gap-3 border-b border-gray-100 py-2.5 last:border-0">
      {done ? (
        <CheckCircle2 className="h-5 w-5 shrink-0 text-green-600" />
      ) : (
        <Circle className="h-5 w-5 shrink-0 text-gray-300" />
      )}
      <span
        className={`text-sm ${done ? 'text-gray-900' : 'text-gray-400'}`}
      >
        {label}
      </span>
      {done && (
        <span className="ml-auto text-xs font-medium text-green-600">
          Concluído
        </span>
      )}
    </li>
  )
}

export default function HomePage() {
  const { activeOrganization, profile, isAdmin } = useAuth()
  const orgId = activeOrganization?.id

  const { data: stats, isLoading: statsLoading } =
    useOrganizationStats(orgId)
  const { data: checklist, isLoading: checklistLoading } =
    useSetupChecklist(orgId)

  const checklistProgress = [
    checklist?.orgRegistered ?? false,
    checklist?.operationRegistered ?? false,
    checklist?.pdvsReviewed ?? false,
    checklist?.teamsCreated ?? false,
    checklist?.operationalPeopleConfirmed ?? false,
    checklist?.supervisorAccountsLinked ?? false,
    checklist?.salespersonAccountsLinked ?? false,
    checklist?.linksCompleted ?? false,
  ]
  const completedItems = checklistProgress.filter(Boolean).length
  const totalItems = checklistProgress.length

  if (statsLoading || checklistLoading) {
    return (
      <div className="page-container flex min-h-[400px] items-center justify-center">
        <LoadingSpinner
          size="lg"
          message="Carregando dados da operação..."
        />
      </div>
    )
  }

  return (
    <div className="page-container">
      <div className="mb-6">
        <h1 className="text-xl font-bold text-gray-900">
          Bom dia,{' '}
          {profile?.preferred_name ||
            profile?.full_name ||
            'bem-vindo'}
          !
        </h1>
        <p className="mt-1 text-sm text-gray-500">
          {activeOrganization ? (
            <span>
              Organização ativa:{' '}
              <strong className="text-gray-700">
                {activeOrganization.trade_name}
              </strong>
            </span>
          ) : (
            'Nenhuma organização ativa selecionada.'
          )}
        </p>
      </div>

      {(stats?.adjustedMonthlyCapacityReference ?? 0) > 0 &&
      (stats?.fullMonthlyCapacityReference ?? 0) > 0 ? (
        <div className="mb-6 rounded-xl border border-brand-200 bg-brand-50 p-5">
          <div className="grid gap-5 lg:grid-cols-[1fr_auto] lg:items-center">
            <div className="flex items-start gap-3">
              <div className="flex h-10 w-10 shrink-0 items-center justify-center rounded-lg bg-brand-700">
                <TrendingUp className="h-5 w-5 text-white" />
              </div>
              <div>
                <p className="text-sm font-semibold text-brand-900">
                  Referência operacional de curto prazo
                </p>
                <p className="mt-1 max-w-3xl text-sm text-brand-800">
                  Com {stats?.confirmedProducerCount ?? 0} produtores
                  ativos e mínimo de{' '}
                  {stats?.minimumMonthlySalesPerProducer ?? 0} cotas por
                  produtor, a referência atual é de{' '}
                  <strong>
                    {stats?.adjustedMonthlyCapacityReference ?? 0} cotas
                    mensais
                  </strong>
                  . Com a equipe completa de{' '}
                  {stats?.plannedProducerCount ?? 0} produtores, a
                  capacidade plena inicial é de{' '}
                  <strong>
                    {stats?.fullMonthlyCapacityReference ?? 0} cotas
                    mensais
                  </strong>
                  .
                </p>
                <p className="mt-2 text-xs text-brand-700">
                  Esses números representam capacidade operacional, não
                  baseline histórico validado.
                </p>
              </div>
            </div>

            <div className="grid grid-cols-2 gap-2 text-center">
              <div className="rounded-lg bg-white px-4 py-3 shadow-sm">
                <p className="text-2xl font-bold text-brand-800">
                  {stats?.adjustedMonthlyCapacityReference ?? 0}
                </p>
                <p className="text-xs text-gray-500">
                  referência atual
                </p>
              </div>
              <div className="rounded-lg bg-white px-4 py-3 shadow-sm">
                <p className="text-2xl font-bold text-green-700">
                  {stats?.fullMonthlyCapacityReference ?? 0}
                </p>
                <p className="text-xs text-gray-500">
                  capacidade plena
                </p>
              </div>
            </div>
          </div>
        </div>
      ) : null}

      <div className="mb-6 grid grid-cols-2 gap-4 sm:grid-cols-3 xl:grid-cols-6">
        <StatCard
          label="PDVs ativos"
          value={stats?.pdvCount ?? 0}
          detail={
            (stats?.pendingPdvCount ?? 0) > 0
              ? `${stats?.pendingPdvCount} aguardando confirmação`
              : 'Dados confirmados'
          }
          icon={MapPin}
          color="bg-brand-700"
        />
        <StatCard
          label="Equipes"
          value={stats?.teamCount ?? 0}
          detail={
            (stats?.templateTeamCount ?? 0) > 0
              ? `${stats?.templateTeamCount} registros de modelo`
              : 'Estrutura confirmada'
          }
          icon={Users2}
          color="bg-blue-600"
        />
        <StatCard
          label="Produtores ativos"
          value={stats?.confirmedProducerCount ?? 0}
          detail={`${stats?.confirmedSupervisorCount ?? 0} supervisores + ${stats?.confirmedSalespersonCount ?? 0} vendedores`}
          icon={Users}
          color="bg-purple-600"
        />
        <StatCard
          label="Vagas"
          value={stats?.vacantSalespersonCount ?? 0}
          detail="Posições de vendedor em aberto"
          icon={UserCog}
          color="bg-orange-500"
        />
        <StatCard
          label="Capacidade plena"
          value={stats?.plannedProducerCount ?? 0}
          detail="5 produtores por equipe"
          icon={Building2}
          color="bg-green-600"
        />
        <StatCard
          label="Usuários vinculados"
          value={stats?.linkedProducerCount ?? 0}
          detail={`${stats?.supervisorCount ?? 0} supervisores + ${stats?.salespersonCount ?? 0} vendedores`}
          icon={Link2}
          color="bg-gray-600"
        />
      </div>

      <div className="grid grid-cols-1 gap-6 lg:grid-cols-2">
        <div className="card p-5">
          <div className="mb-4 flex items-center justify-between">
            <div className="flex items-center gap-2">
              <CheckSquare className="h-5 w-5 text-brand-700" />
              <h2 className="font-semibold text-gray-900">
                Preparação da Operação
              </h2>
            </div>
            <span className="text-sm font-medium text-brand-700">
              {completedItems}/{totalItems}
            </span>
          </div>

          <div className="mb-4 h-1.5 w-full rounded-full bg-gray-100">
            <div
              className="h-1.5 rounded-full bg-brand-600 transition-all duration-500"
              style={{
                width: `${(completedItems / totalItems) * 100}%`,
              }}
            />
          </div>

          <ul>
            <CheckItem
              done={checklist?.orgRegistered ?? false}
              label="Organização cadastrada"
            />
            <CheckItem
              done={checklist?.operationRegistered ?? false}
              label="Operação cadastrada"
            />
            <CheckItem
              done={checklist?.pdvsReviewed ?? false}
              label={`${stats?.pdvCount ?? 0} PDVs confirmados`}
            />
            <CheckItem
              done={checklist?.teamsCreated ?? false}
              label={`${stats?.teamCount ?? 0} equipes confirmadas`}
            />
            <CheckItem
              done={checklist?.operationalPeopleConfirmed ?? false}
              label={`${stats?.confirmedSupervisorCount ?? 0} supervisores-vendedores e ${stats?.confirmedSalespersonCount ?? 0} vendedores confirmados`}
            />
            <CheckItem
              done={checklist?.supervisorAccountsLinked ?? false}
              label={`Contas dos supervisores vinculadas (${stats?.supervisorCount ?? 0}/${stats?.confirmedSupervisorCount ?? 0})`}
            />
            <CheckItem
              done={checklist?.salespersonAccountsLinked ?? false}
              label={`Contas dos vendedores vinculadas (${stats?.salespersonCount ?? 0}/${stats?.confirmedSalespersonCount ?? 0})`}
            />
            <CheckItem
              done={checklist?.linksCompleted ?? false}
              label="Supervisores, equipes e vendedores vinculados"
            />
          </ul>

          {completedItems === totalItems ? (
            <div className="mt-4 rounded-lg border border-green-200 bg-green-50 p-3 text-center">
              <p className="text-sm font-semibold text-green-800">
                Estrutura pronta para a execução do plano.
              </p>
            </div>
          ) : (
            <div className="mt-4 rounded-lg border border-amber-200 bg-amber-50 p-3">
              <p className="text-sm font-semibold text-amber-900">
                Estrutura operacional confirmada; vinculação de contas
                ainda em andamento.
              </p>
            </div>
          )}
        </div>

        <div className="card p-5">
          <div className="mb-4 flex items-center gap-2">
            <Building2 className="h-5 w-5 text-brand-700" />
            <h2 className="font-semibold text-gray-900">
              Configuração Atual
            </h2>
          </div>

          <dl className="space-y-3">
            <div className="flex items-start justify-between gap-4">
              <dt className="shrink-0 text-sm text-gray-500">
                Organização
              </dt>
              <dd className="text-right text-sm font-medium text-gray-900">
                {activeOrganization?.trade_name ?? '—'}
              </dd>
            </div>
            <div className="flex items-start justify-between gap-4 border-t border-gray-100 pt-3">
              <dt className="shrink-0 text-sm text-gray-500">Status</dt>
              <dd>
                <span
                  className={`badge ${
                    activeOrganization?.status === 'active'
                      ? 'badge-active'
                      : 'badge-inactive'
                  }`}
                >
                  {activeOrganization?.status === 'active'
                    ? 'Ativa'
                    : 'Inativa'}
                </span>
              </dd>
            </div>
            <div className="flex items-start justify-between gap-4 border-t border-gray-100 pt-3">
              <dt className="shrink-0 text-sm text-gray-500">
                Estrutura operacional
              </dt>
              <dd className="text-right text-sm text-gray-900">
                {stats?.pdvCount ?? 0} PDVs · {stats?.teamCount ?? 0}{' '}
                equipes · {stats?.confirmedProducerCount ?? 0}{' '}
                produtores ativos
              </dd>
            </div>
            <div className="flex items-start justify-between gap-4 border-t border-gray-100 pt-3">
              <dt className="shrink-0 text-sm text-gray-500">
                Composição confirmada
              </dt>
              <dd className="text-right text-sm text-gray-900">
                {stats?.confirmedSupervisorCount ?? 0}{' '}
                supervisores-vendedores ·{' '}
                {stats?.confirmedSalespersonCount ?? 0} vendedores
              </dd>
            </div>
            <div className="flex items-start justify-between gap-4 border-t border-gray-100 pt-3">
              <dt className="shrink-0 text-sm text-gray-500">
                Capacidade e vagas
              </dt>
              <dd className="text-right text-sm text-gray-900">
                {stats?.plannedProducerCount ?? 0} produtores ·{' '}
                {stats?.vacantSalespersonCount ?? 0} vagas
              </dd>
            </div>
            <div className="flex items-start justify-between gap-4 border-t border-gray-100 pt-3">
              <dt className="shrink-0 text-sm text-gray-500">
                Contas vinculadas
              </dt>
              <dd className="text-right text-sm text-gray-900">
                {stats?.supervisorCount ?? 0} supervisores ·{' '}
                {stats?.salespersonCount ?? 0} vendedores
              </dd>
            </div>
            <div className="flex items-start justify-between gap-4 border-t border-gray-100 pt-3">
              <dt className="shrink-0 text-sm text-gray-500">
                Período inicial
              </dt>
              <dd className="text-right text-sm text-gray-900">
                Plano de 90 dias
              </dd>
            </div>
            {isAdmin && (
              <div className="flex items-start justify-between gap-4 border-t border-gray-100 pt-3">
                <dt className="shrink-0 text-sm text-gray-500">Modo</dt>
                <dd className="text-sm font-medium text-purple-700">
                  Administrador da Plataforma
                </dd>
              </div>
            )}
          </dl>

          <div className="mt-5 border-t border-gray-100 pt-4">
            <p className="mb-2 text-xs font-medium text-gray-400">
              Próximos módulos da apresentação
            </p>
            <div className="flex flex-wrap gap-1.5">
              {[
                'Plano 90 Dias',
                'Metas',
                'Resultados',
                'Treinamentos',
                'Avaliações',
                'Feedbacks',
              ].map((module) => (
                <span
                  key={module}
                  className="rounded-full bg-gray-100 px-2 py-0.5 text-xs text-gray-500"
                >
                  {module}
                </span>
              ))}
            </div>
          </div>
        </div>
      </div>
    </div>
  )
}