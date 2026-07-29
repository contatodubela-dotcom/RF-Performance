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

  const completedItems = checklist
    ? Object.values(checklist).filter(Boolean).length
    : 0
  const totalItems = 7

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

      {stats?.baselineMonthlySales && stats?.targetMonthlySales ? (
        <div className="mb-6 rounded-xl border border-brand-200 bg-brand-50 p-5">
          <div className="flex flex-col justify-between gap-4 sm:flex-row sm:items-center">
            <div className="flex items-start gap-3">
              <div className="flex h-10 w-10 shrink-0 items-center justify-center rounded-lg bg-brand-700">
                <TrendingUp className="h-5 w-5 text-white" />
              </div>
              <div>
                <p className="text-sm font-semibold text-brand-900">
                  Objetivo de aceleração comercial
                </p>
                <p className="mt-1 text-sm text-brand-800">
                  Evoluir de {stats.baselineMonthlySales} para{' '}
                  {stats.targetMonthlySales} cotas mensais sem ampliar os 3
                  PDVs, os 3 supervisores ou os 20 vendedores planejados.
                </p>
              </div>
            </div>
            <div className="rounded-lg bg-white px-4 py-3 text-center shadow-sm">
              <p className="text-2xl font-bold text-brand-800">
                +{stats.growthTargetPercent}%
              </p>
              <p className="text-xs text-gray-500">meta de crescimento</p>
            </div>
          </div>
        </div>
      ) : null}

      <div className="mb-6 grid grid-cols-2 gap-4 sm:grid-cols-3 lg:grid-cols-5">
        <StatCard
          label="PDVs ativos"
          value={stats?.pdvCount ?? 0}
          detail={
            (stats?.pendingPdvCount ?? 0) > 0
              ? `${stats?.pendingPdvCount} aguardando dados reais`
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
              ? `${stats?.templateTeamCount} modelos editáveis`
              : undefined
          }
          icon={Users2}
          color="bg-blue-600"
        />
        <StatCard
          label="Supervisores"
          value={stats?.supervisorCount ?? 0}
          detail={`${stats?.plannedSupervisorCount ?? 0} posições planejadas`}
          icon={UserCog}
          color="bg-orange-500"
        />
        <StatCard
          label="Vendedores"
          value={stats?.salespersonCount ?? 0}
          detail={`${stats?.plannedSalespersonCount ?? 0} posições planejadas`}
          icon={Users}
          color="bg-purple-600"
        />
        <StatCard
          label="Total de membros"
          value={stats?.totalMembers ?? 0}
          detail="Usuários reais vinculados"
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
              label="3 PDVs confirmados (nome, shopping, cidade)"
            />
            <CheckItem
              done={checklist?.supervisorsRegistered ?? false}
              label="3 supervisores cadastrados"
            />
            <CheckItem
              done={checklist?.teamsCreated ?? false}
              label="3 equipes modelo criadas"
            />
            <CheckItem
              done={checklist?.salespersonsRegistered ?? false}
              label="Vendedores cadastrados"
            />
            <CheckItem
              done={checklist?.linksCompleted ?? false}
              label="Supervisores, equipes e vendedores vinculados"
            />
          </ul>

          {completedItems === totalItems && (
            <div className="mt-4 rounded-lg border border-green-200 bg-green-50 p-3 text-center">
              <p className="text-sm font-semibold text-green-800">
                Estrutura pronta para a execução do plano.
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
                Estrutura modelo
              </dt>
              <dd className="text-right text-sm text-gray-900">
                3 PDVs · 3 equipes · 20 vendedores
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
