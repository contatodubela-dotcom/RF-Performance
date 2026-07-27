import { Settings, Info } from 'lucide-react'
import { useAuth } from '@/contexts/AuthContext'
import { usePermissions } from '@/hooks/usePermissions'
import { ROLE_LABELS, SOURCE_SYSTEM_LABELS } from '@/constants/roles'
import { formatDateTime } from '@/lib/formatters'
import PageHeader from '@/components/shared/PageHeader'

export default function SettingsPage() {
  const { profile, activeOrganization, activeMembership, isAdmin } = useAuth()
  const { currentRole } = useAuth()

  return (
    <div className="page-container max-w-3xl">
      <PageHeader
        title="Configurações"
        description="Informações do sistema e do seu perfil de acesso."
      />

      <div className="space-y-6">
        {/* Perfil */}
        <div className="card p-5">
          <div className="flex items-center gap-2 mb-4">
            <Settings className="h-4 w-4 text-brand-700" />
            <h2 className="font-semibold text-gray-900">Meu perfil</h2>
          </div>
          <dl className="grid grid-cols-1 sm:grid-cols-2 gap-4">
            <div>
              <dt className="text-xs text-gray-500 mb-1">Nome completo</dt>
              <dd className="text-sm font-medium text-gray-900">{profile?.full_name ?? '—'}</dd>
            </div>
            <div>
              <dt className="text-xs text-gray-500 mb-1">E-mail</dt>
              <dd className="text-sm text-gray-900">{profile?.email ?? '—'}</dd>
            </div>
            <div>
              <dt className="text-xs text-gray-500 mb-1">Perfil de acesso</dt>
              <dd className="text-sm font-medium text-gray-900">{currentRole ? (ROLE_LABELS[currentRole] ?? currentRole) : '—'}</dd>
            </div>
            <div>
              <dt className="text-xs text-gray-500 mb-1">Status</dt>
              <dd className="text-sm">
                <span className={`badge ${profile?.status === 'active' ? 'badge-active' : 'badge-inactive'}`}>
                  {profile?.status === 'active' ? 'Ativo' : 'Inativo'}
                </span>
              </dd>
            </div>
            <div>
              <dt className="text-xs text-gray-500 mb-1">Último acesso</dt>
              <dd className="text-sm text-gray-900">{formatDateTime(profile?.last_access_at)}</dd>
            </div>
            <div>
              <dt className="text-xs text-gray-500 mb-1">Cadastrado em</dt>
              <dd className="text-sm text-gray-900">{formatDateTime(profile?.created_at)}</dd>
            </div>
          </dl>
          <div className="mt-4 pt-4 border-t border-gray-100">
            <p className="text-xs text-gray-500">
              Para alterar seu nome, e-mail ou senha, entre em contato com o administrador do sistema.
              A alteração de senha pode ser feita pelo fluxo de "Esqueci minha senha" na tela de login.
            </p>
          </div>
        </div>

        {/* Organização */}
        <div className="card p-5">
          <div className="flex items-center gap-2 mb-4">
            <Info className="h-4 w-4 text-brand-700" />
            <h2 className="font-semibold text-gray-900">Organização ativa</h2>
          </div>
          <dl className="grid grid-cols-1 sm:grid-cols-2 gap-4">
            <div>
              <dt className="text-xs text-gray-500 mb-1">Nome</dt>
              <dd className="text-sm font-medium text-gray-900">{activeOrganization?.trade_name ?? '—'}</dd>
            </div>
            <div>
              <dt className="text-xs text-gray-500 mb-1">Slug</dt>
              <dd className="text-sm font-mono text-gray-700">{activeOrganization?.slug ?? '—'}</dd>
            </div>
            <div>
              <dt className="text-xs text-gray-500 mb-1">Status</dt>
              <dd>
                <span className={`badge ${activeOrganization?.status === 'active' ? 'badge-active' : 'badge-inactive'}`}>
                  {activeOrganization?.status === 'active' ? 'Ativa' : 'Inativa'}
                </span>
              </dd>
            </div>
            <div>
              <dt className="text-xs text-gray-500 mb-1">Sistema de origem</dt>
              <dd className="text-sm text-gray-900">{SOURCE_SYSTEM_LABELS[activeOrganization?.source_system ?? ''] ?? activeOrganization?.source_system ?? '—'}</dd>
            </div>
          </dl>
        </div>

        {/* Sistema */}
        <div className="card p-5">
          <div className="flex items-center gap-2 mb-4">
            <Info className="h-4 w-4 text-brand-700" />
            <h2 className="font-semibold text-gray-900">Informações do sistema</h2>
          </div>
          <dl className="space-y-3 text-sm">
            <div className="flex justify-between items-start border-b border-gray-100 pb-2">
              <dt className="text-gray-500">Versão da aplicação</dt>
              <dd className="font-medium text-gray-900">1.0.0 — Fase 1</dd>
            </div>
            <div className="flex justify-between items-start border-b border-gray-100 pb-2">
              <dt className="text-gray-500">Segurança</dt>
              <dd className="text-gray-900">RLS ativa em todas as tabelas</dd>
            </div>
            <div className="flex justify-between items-start border-b border-gray-100 pb-2">
              <dt className="text-gray-500">Localidade</dt>
              <dd className="text-gray-900">pt-BR / America/Sao_Paulo</dd>
            </div>
            <div className="flex justify-between items-start">
              <dt className="text-gray-500">Tecnologia</dt>
              <dd className="text-gray-900 text-right">React + TypeScript + Supabase</dd>
            </div>
          </dl>
          <div className="mt-4 pt-4 border-t border-gray-100 text-center">
            <p className="text-xs text-gray-400">Tecnologia e método <strong>EPSA</strong></p>
            <p className="text-xs text-gray-400 mt-0.5">RF Performance Comercial — Gestão, desenvolvimento e execução comercial</p>
          </div>
        </div>
      </div>
    </div>
  )
}
