import { CheckCircle2, Circle, Building2, Briefcase, MapPin, Users2, UserCog, Users, Link2, CheckSquare } from 'lucide-react'
import { useAuth } from '@/contexts/AuthContext'
import { useOrganizationStats, useSetupChecklist } from '@/hooks/useOrganizationStats'
import LoadingSpinner from '@/components/shared/LoadingSpinner'

interface StatCardProps {
  label: string
  value: number | string
  icon: React.ElementType
  color: string
}

function StatCard({ label, value, icon: Icon, color }: StatCardProps) {
  return (
    <div className="stat-card">
      <div className={`w-9 h-9 rounded-lg ${color} flex items-center justify-center mb-3`}>
        <Icon className="h-5 w-5 text-white" />
      </div>
      <p className="text-2xl font-bold text-gray-900">{value}</p>
      <p className="text-sm text-gray-500 mt-0.5">{label}</p>
    </div>
  )
}

interface CheckItemProps {
  done: boolean
  label: string
}

function CheckItem({ done, label }: CheckItemProps) {
  return (
    <li className="flex items-center gap-3 py-2.5 border-b border-gray-100 last:border-0">
      {done ? (
        <CheckCircle2 className="h-5 w-5 text-green-600 shrink-0" />
      ) : (
        <Circle className="h-5 w-5 text-gray-300 shrink-0" />
      )}
      <span className={`text-sm ${done ? 'text-gray-900' : 'text-gray-400'}`}>{label}</span>
      {done && (
        <span className="ml-auto text-xs text-green-600 font-medium">Concluído</span>
      )}
    </li>
  )
}

export default function HomePage() {
  const { activeOrganization, profile, isAdmin } = useAuth()
  const orgId = activeOrganization?.id

  const { data: stats, isLoading: statsLoading } = useOrganizationStats(orgId)
  const { data: checklist, isLoading: checklistLoading } = useSetupChecklist(orgId)

  const completedItems = checklist
    ? Object.values(checklist).filter(Boolean).length
    : 0
  const totalItems = 7

  if (statsLoading || checklistLoading) {
    return (
      <div className="page-container flex items-center justify-center min-h-[400px]">
        <LoadingSpinner size="lg" message="Carregando dados da operação..." />
      </div>
    )
  }

  return (
    <div className="page-container">
      {/* Welcome */}
      <div className="mb-6">
        <h1 className="text-xl font-bold text-gray-900">
          Bom dia, {profile?.preferred_name || profile?.full_name?.split(' ')[0] || 'bem-vindo'}!
        </h1>
        <p className="text-sm text-gray-500 mt-1">
          {activeOrganization ? (
            <span>Organização ativa: <strong className="text-gray-700">{activeOrganization.trade_name}</strong></span>
          ) : (
            'Nenhuma organização ativa selecionada.'
          )}
        </p>
      </div>

      {/* Stats */}
      <div className="grid grid-cols-2 sm:grid-cols-3 lg:grid-cols-5 gap-4 mb-6">
        <StatCard label="PDVs ativos" value={stats?.pdvCount ?? 0} icon={MapPin} color="bg-brand-700" />
        <StatCard label="Equipes" value={stats?.teamCount ?? 0} icon={Users2} color="bg-blue-600" />
        <StatCard label="Supervisores" value={stats?.supervisorCount ?? 0} icon={UserCog} color="bg-orange-500" />
        <StatCard label="Vendedores" value={stats?.salespersonCount ?? 0} icon={Users} color="bg-purple-600" />
        <StatCard label="Total de membros" value={stats?.totalMembers ?? 0} icon={Link2} color="bg-gray-600" />
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        {/* Setup Checklist */}
        <div className="card p-5">
          <div className="flex items-center justify-between mb-4">
            <div className="flex items-center gap-2">
              <CheckSquare className="h-5 w-5 text-brand-700" />
              <h2 className="font-semibold text-gray-900">Preparação da Operação</h2>
            </div>
            <span className="text-sm font-medium text-brand-700">
              {completedItems}/{totalItems}
            </span>
          </div>

          {/* Progress bar */}
          <div className="w-full bg-gray-100 rounded-full h-1.5 mb-4">
            <div
              className="bg-brand-600 h-1.5 rounded-full transition-all duration-500"
              style={{ width: `${(completedItems / totalItems) * 100}%` }}
            />
          </div>

          <ul>
            <CheckItem done={checklist?.orgRegistered ?? false} label="Organização cadastrada" />
            <CheckItem done={checklist?.operationRegistered ?? false} label="Operação cadastrada" />
            <CheckItem done={checklist?.pdvsReviewed ?? false} label="3 PDVs revisados (nome, shopping, cidade)" />
            <CheckItem done={checklist?.supervisorsRegistered ?? false} label="Supervisores cadastrados" />
            <CheckItem done={checklist?.teamsCreated ?? false} label="Equipes criadas" />
            <CheckItem done={checklist?.salespersonsRegistered ?? false} label="Vendedores cadastrados" />
            <CheckItem done={checklist?.linksCompleted ?? false} label="Vínculos concluídos" />
          </ul>

          {completedItems === totalItems && (
            <div className="mt-4 p-3 bg-green-50 rounded-lg border border-green-200 text-center">
              <p className="text-sm font-semibold text-green-800">
                ✅ Estrutura pronta para a próxima fase!
              </p>
            </div>
          )}
        </div>

        {/* Organization info */}
        <div className="card p-5">
          <div className="flex items-center gap-2 mb-4">
            <Building2 className="h-5 w-5 text-brand-700" />
            <h2 className="font-semibold text-gray-900">Configuração Atual</h2>
          </div>

          <dl className="space-y-3">
            <div className="flex items-start justify-between gap-4">
              <dt className="text-sm text-gray-500 shrink-0">Organização</dt>
              <dd className="text-sm font-medium text-gray-900 text-right">
                {activeOrganization?.trade_name ?? '—'}
              </dd>
            </div>
            <div className="flex items-start justify-between gap-4 border-t border-gray-100 pt-3">
              <dt className="text-sm text-gray-500 shrink-0">Status</dt>
              <dd>
                <span className={`badge ${activeOrganization?.status === 'active' ? 'badge-active' : 'badge-inactive'}`}>
                  {activeOrganization?.status === 'active' ? 'Ativa' : 'Inativa'}
                </span>
              </dd>
            </div>
            <div className="flex items-start justify-between gap-4 border-t border-gray-100 pt-3">
              <dt className="text-sm text-gray-500 shrink-0">Sistema</dt>
              <dd className="text-sm text-gray-900 text-right">{activeOrganization?.source_system ?? '—'}</dd>
            </div>
            {isAdmin && (
              <div className="flex items-start justify-between gap-4 border-t border-gray-100 pt-3">
                <dt className="text-sm text-gray-500 shrink-0">Modo</dt>
                <dd className="text-sm text-purple-700 font-medium">Administrador da Plataforma</dd>
              </div>
            )}
          </dl>

          <div className="mt-5 pt-4 border-t border-gray-100">
            <p className="text-xs text-gray-400 font-medium mb-2">Módulos em preparação</p>
            <div className="flex flex-wrap gap-1.5">
              {['Plano 90 Dias', 'Metas', 'Resultados', 'Treinamentos', 'Avaliações', 'Feedbacks'].map(m => (
                <span key={m} className="text-xs bg-gray-100 text-gray-500 px-2 py-0.5 rounded-full">{m}</span>
              ))}
            </div>
          </div>
        </div>
      </div>
    </div>
  )
}
