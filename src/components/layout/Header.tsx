import { Menu, LogOut, ChevronRight } from 'lucide-react'
import { useLocation, Link } from 'react-router-dom'
import { useAuth } from '@/contexts/AuthContext'
import { ROLE_LABELS } from '@/constants/roles'
import { ROUTES } from '@/constants/routes'

const BREADCRUMB_LABELS: Record<string, string> = {
  app: 'App',
  inicio: 'Início',
  organizacoes: 'Organizações',
  operacoes: 'Operações',
  pdvs: 'PDVs',
  equipes: 'Equipes',
  usuarios: 'Usuários',
  configuracoes: 'Configurações',
  'plano-90-dias': 'Plano de 90 Dias',
  metas: 'Metas',
  resultados: 'Resultados',
  acoes: 'Ações',
  reunioes: 'Reuniões',
  treinamentos: 'Treinamentos',
  avaliacoes: 'Avaliações',
  feedbacks: 'Feedbacks',
  relatorios: 'Relatórios',
}

interface HeaderProps {
  onMenuClick: () => void
}

export default function Header({ onMenuClick }: HeaderProps) {
  const { profile, activeOrganization, currentRole, signOut } = useAuth()
  const location = useLocation()

  const segments = location.pathname.split('/').filter(Boolean)
  const breadcrumbs = segments.map((seg, i) => ({
    label: BREADCRUMB_LABELS[seg] ?? seg,
    path: '/' + segments.slice(0, i + 1).join('/'),
    isLast: i === segments.length - 1,
  }))

  const displayName = profile?.preferred_name || profile?.full_name?.split(' ')[0] || '—'
  const roleLabel = currentRole ? (ROLE_LABELS[currentRole] ?? '') : ''

  return (
    <header className="h-14 bg-white border-b border-gray-200 flex items-center px-4 gap-3 shrink-0 sticky top-0 z-10">
      {/* Hamburger (mobile/tablet) */}
      <button
        onClick={onMenuClick}
        className="lg:hidden p-2 rounded-md text-gray-500 hover:text-gray-700 hover:bg-gray-100 -ml-1"
        aria-label="Abrir menu"
      >
        <Menu className="h-5 w-5" />
      </button>

      {/* Breadcrumb */}
      <nav className="flex items-center gap-1 text-sm flex-1 min-w-0 overflow-hidden">
        {breadcrumbs.map((crumb, i) => (
          <span key={crumb.path} className="flex items-center gap-1 min-w-0">
            {i > 0 && <ChevronRight className="h-3.5 w-3.5 text-gray-400 shrink-0" />}
            {crumb.isLast ? (
              <span className="font-medium text-gray-900 truncate">{crumb.label}</span>
            ) : (
              <Link
                to={crumb.path}
                className="text-gray-500 hover:text-gray-700 truncate transition-colors"
              >
                {crumb.label}
              </Link>
            )}
          </span>
        ))}
      </nav>

      {/* Right side: user info + logout */}
      <div className="flex items-center gap-3 shrink-0">
        <div className="hidden sm:flex flex-col items-end">
          <span className="text-sm font-medium text-gray-900">{displayName}</span>
          <span className="text-xs text-gray-500">{roleLabel}</span>
        </div>
        <button
          onClick={signOut}
          title="Sair"
          className="p-2 rounded-md text-gray-500 hover:text-red-600 hover:bg-red-50 transition-colors"
        >
          <LogOut className="h-4 w-4" />
        </button>
      </div>
    </header>
  )
}
