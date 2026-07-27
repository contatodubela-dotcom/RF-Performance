import { NavLink } from 'react-router-dom'
import {
  Home, Calendar, Target, BarChart2, Zap, Users2,
  BookOpen, ClipboardCheck, MessageSquare, FileText,
  Building2, Briefcase, MapPin, UserCog, Settings, X, TrendingUp,
} from 'lucide-react'
import { cn } from '@/lib/utils'
import { ROUTES } from '@/constants/routes'
import { useAuth } from '@/contexts/AuthContext'
import { ROLE_LABELS } from '@/constants/roles'
import { getInitials } from '@/lib/utils'

interface NavItem {
  label: string
  path: string
  icon: React.ElementType
  pending?: boolean
  adminOnly?: boolean
  superiorOnly?: boolean
}

interface NavSection {
  title: string
  items: NavItem[]
  condition?: boolean
}

const NAV: NavSection[] = [
  {
    title: 'GESTÃO',
    items: [
      { label: 'Início', path: ROUTES.HOME, icon: Home },
      { label: 'Plano de 90 Dias', path: ROUTES.PLAN_90_DAYS, icon: Calendar, pending: true },
      { label: 'Metas', path: ROUTES.GOALS, icon: Target, pending: true },
      { label: 'Resultados', path: ROUTES.RESULTS, icon: TrendingUp, pending: true },
      { label: 'Ações', path: ROUTES.ACTIONS, icon: Zap, pending: true },
      { label: 'Reuniões', path: ROUTES.MEETINGS, icon: Users2, pending: true },
    ],
  },
  {
    title: 'DESENVOLVIMENTO',
    items: [
      { label: 'Treinamentos', path: ROUTES.TRAINING, icon: BookOpen, pending: true },
      { label: 'Avaliações', path: ROUTES.EVALUATIONS, icon: ClipboardCheck, pending: true },
      { label: 'Feedbacks', path: ROUTES.FEEDBACKS, icon: MessageSquare, pending: true },
    ],
  },
  {
    title: 'ANÁLISE',
    items: [
      { label: 'Relatórios', path: ROUTES.REPORTS, icon: FileText, pending: true },
    ],
  },
  {
    title: 'ADMINISTRAÇÃO',
    items: [
      { label: 'Organizações', path: ROUTES.ORGANIZATIONS, icon: Building2, adminOnly: true },
      { label: 'Operações', path: ROUTES.OPERATIONS, icon: Briefcase },
      { label: 'PDVs', path: ROUTES.SALES_LOCATIONS, icon: MapPin },
      { label: 'Equipes', path: ROUTES.TEAMS, icon: Users2 },
      { label: 'Usuários', path: ROUTES.USERS, icon: UserCog },
      { label: 'Configurações', path: ROUTES.SETTINGS, icon: Settings },
    ],
  },
]

interface SidebarProps {
  open: boolean
  onClose: () => void
}

export default function Sidebar({ open, onClose }: SidebarProps) {
  const { profile, activeOrganization, currentRole, isAdmin, canViewAdmin } = useAuth()

  const displayName = profile?.preferred_name || profile?.full_name || profile?.email || '—'
  const initials = getInitials(profile?.full_name || profile?.email || '?')
  const roleLabel = currentRole ? (ROLE_LABELS[currentRole] ?? currentRole) : ''

  return (
    <>
      {/* Overlay (mobile) */}
      {open && (
        <div
          className="fixed inset-0 z-20 bg-black/50 lg:hidden"
          onClick={onClose}
          aria-hidden="true"
        />
      )}

      {/* Sidebar */}
      <aside
        className={cn(
          'fixed top-0 left-0 h-screen w-64 bg-brand-900 z-30 flex flex-col',
          'transform transition-transform duration-300 ease-in-out',
          open ? 'translate-x-0' : '-translate-x-full lg:translate-x-0'
        )}
      >
        {/* Header */}
        <div className="flex items-center justify-between px-4 py-5 border-b border-brand-800">
          <div>
            <div className="flex items-center gap-2">
              <div className="w-7 h-7 rounded-md bg-brand-600 flex items-center justify-center">
                <BarChart2 className="h-4 w-4 text-white" />
              </div>
              <span className="text-sm font-bold text-white leading-tight">RF Performance</span>
            </div>
            <p className="text-xs text-green-400 mt-0.5 pl-9">Comercial</p>
          </div>
          <button
            onClick={onClose}
            className="lg:hidden text-green-300 hover:text-white p-1 rounded"
          >
            <X className="h-5 w-5" />
          </button>
        </div>

        {/* Organization badge */}
        {activeOrganization && (
          <div className="px-4 py-2.5 bg-brand-800/60 border-b border-brand-800">
            <p className="text-xs text-green-400 font-medium truncate">{activeOrganization.trade_name}</p>
            {isAdmin && <p className="text-xs text-green-500/70">Modo administrador</p>}
          </div>
        )}

        {/* Navigation */}
        <nav className="flex-1 overflow-y-auto py-4 px-2 space-y-5">
          {NAV.map((section) => {
            // Filter admin section
            if (section.title === 'ADMINISTRAÇÃO' && !canViewAdmin) return null

            // Filter items
            const visibleItems = section.items.filter(item => {
              if (item.adminOnly && !isAdmin) return false
              return true
            })

            if (!visibleItems.length) return null

            return (
              <div key={section.title}>
                <p className="px-3 mb-1.5 text-xs font-semibold text-green-500 tracking-wider uppercase">
                  {section.title}
                </p>
                <ul className="space-y-0.5">
                  {visibleItems.map((item) => {
                    const Icon = item.icon
                    if (item.pending) {
                      return (
                        <li key={item.path}>
                          <div className="sidebar-link sidebar-link-pending">
                            <Icon className="h-4 w-4 shrink-0" />
                            <span>{item.label}</span>
                            <span className="ml-auto text-xs bg-brand-950/40 text-green-500/60 px-1.5 py-0.5 rounded-full">
                              Em breve
                            </span>
                          </div>
                        </li>
                      )
                    }
                    return (
                      <li key={item.path}>
                        <NavLink
                          to={item.path}
                          onClick={() => onClose()}
                          className={({ isActive }) =>
                            cn('sidebar-link', isActive ? 'sidebar-link-active' : 'sidebar-link-inactive')
                          }
                        >
                          <Icon className="h-4 w-4 shrink-0" />
                          <span>{item.label}</span>
                        </NavLink>
                      </li>
                    )
                  })}
                </ul>
              </div>
            )
          })}
        </nav>

        {/* User profile footer */}
        <div className="border-t border-brand-800 px-4 py-4">
          <div className="flex items-center gap-3">
            <div className="w-8 h-8 rounded-full bg-brand-600 flex items-center justify-center shrink-0">
              <span className="text-xs font-semibold text-white">{initials}</span>
            </div>
            <div className="flex-1 min-w-0">
              <p className="text-sm font-medium text-white truncate">{displayName}</p>
              <p className="text-xs text-green-400 truncate">{roleLabel}</p>
            </div>
          </div>
          <p className="mt-3 text-xs text-green-600 text-center">Tecnologia e método EPSA</p>
        </div>
      </aside>
    </>
  )
}
