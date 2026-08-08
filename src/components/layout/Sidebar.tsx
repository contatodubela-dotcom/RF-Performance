import type { ElementType } from 'react'
import { useEffect } from 'react'
import { useQuery } from '@tanstack/react-query'
import { NavLink, useNavigate } from 'react-router-dom'
import {
  BarChart2,
  BookOpen,
  Briefcase,
  Building2,
  Calendar,
  ClipboardCheck,
  FileText,
  Home,
  MapPin,
  MessageSquare,
  Settings,
  Target,
  TrendingUp,
  UserCog,
  Users2,
  X,
  Zap,
} from 'lucide-react'

import { canAccessRoute } from '@/constants/permissions'
import { ROLE_LABELS } from '@/constants/roles'
import { ROUTES } from '@/constants/routes'
import { useAuth } from '@/contexts/AuthContext'
import { supabase } from '@/lib/supabase'
import { cn, getInitials } from '@/lib/utils'
import type { ActiveOrganizationSummary } from '@/types/auth'

interface NavItem {
  label: string
  path: string
  icon: ElementType
  pending?: boolean
}

interface NavSection {
  title: string
  items: NavItem[]
}

const NAV: NavSection[] = [
  {
    title: 'GESTÃO',
    items: [
      {
        label: 'Início',
        path: ROUTES.HOME,
        icon: Home,
      },
      {
        label: 'Plano de 90 Dias',
        path: ROUTES.PLAN_90_DAYS,
        icon: Calendar,
      },
      {
        label: 'Metas',
        path: ROUTES.GOALS,
        icon: Target,
      },
      {
        label: 'Resultados',
        path: ROUTES.RESULTS,
        icon: TrendingUp,
        pending: true,
      },
      {
        label: 'Ações',
        path: ROUTES.ACTIONS,
        icon: Zap,
      },
      {
        label: 'Reuniões',
        path: ROUTES.MEETINGS,
        icon: Users2,
      },
    ],
  },
  {
    title: 'DESENVOLVIMENTO',
    items: [
      {
        label: 'Treinamentos',
        path: ROUTES.TRAINING,
        icon: BookOpen,
      },
      {
        label: 'Avaliações',
        path: ROUTES.EVALUATIONS,
        icon: ClipboardCheck,
        pending: true,
      },
      {
        label: 'Feedbacks',
        path: ROUTES.FEEDBACKS,
        icon: MessageSquare,
      },
    ],
  },
  {
    title: 'ANÁLISE',
    items: [
      {
        label: 'Relatórios',
        path: ROUTES.REPORTS,
        icon: FileText,
        pending: true,
      },
    ],
  },
  {
    title: 'ADMINISTRAÇÃO',
    items: [
      {
        label: 'Organizações',
        path: ROUTES.ORGANIZATIONS,
        icon: Building2,
      },
      {
        label: 'Operações',
        path: ROUTES.OPERATIONS,
        icon: Briefcase,
      },
      {
        label: 'PDVs',
        path: ROUTES.SALES_LOCATIONS,
        icon: MapPin,
      },
      {
        label: 'Equipes',
        path: ROUTES.TEAMS,
        icon: Users2,
      },
      {
        label: 'Usuários',
        path: ROUTES.USERS,
        icon: UserCog,
      },
      {
        label: 'Configurações',
        path: ROUTES.SETTINGS,
        icon: Settings,
      },
    ],
  },
]

interface SidebarProps {
  open: boolean
  onClose: () => void
}

export default function Sidebar({
  open,
  onClose,
}: SidebarProps) {
  const {
    profile,
    activeOrganization,
    currentRole,
    isAdmin,
    setActiveOrganization,
  } = useAuth()
  const navigate = useNavigate()

  const {
    data: adminOrganizations = [],
    isLoading: adminOrganizationsLoading,
  } = useQuery({
    queryKey: ['organizations', 'active-switcher'],
    enabled: isAdmin,
    queryFn: async () => {
      const { data, error } = await supabase
        .from('organizations')
        .select('id, trade_name, slug, logo_url, status, source_system')
        .eq('status', 'active')
        .order('trade_name', { ascending: true })

      if (error) throw error
      return (data ?? []) as ActiveOrganizationSummary[]
    },
  })

  useEffect(() => {
    if (!isAdmin || adminOrganizationsLoading || adminOrganizations.length === 0) {
      return
    }

    const activeOrganizationStillAvailable = adminOrganizations.some(
      (organization) => organization.id === activeOrganization?.id,
    )

    if (!activeOrganizationStillAvailable) {
      setActiveOrganization(adminOrganizations[0])
      navigate(ROUTES.HOME)
    }
  }, [
    activeOrganization?.id,
    adminOrganizations,
    adminOrganizationsLoading,
    isAdmin,
    navigate,
    setActiveOrganization,
  ])

  const handleOrganizationChange = (organizationId: string) => {
    const organization = adminOrganizations.find(
      (item) => item.id === organizationId,
    )
    if (!organization || organization.id === activeOrganization?.id) return

    setActiveOrganization(organization)
    navigate(ROUTES.HOME)
    onClose()
  }

  const displayName =
    profile?.preferred_name ||
    profile?.full_name ||
    profile?.email ||
    '—'

  const initials = getInitials(
    profile?.full_name ||
    profile?.email ||
    '?',
  )

  const roleLabel = currentRole
    ? (ROLE_LABELS[currentRole] ?? currentRole)
    : ''

  return (
    <>
      {/* Sobreposição em dispositivos móveis */}
      {open && (
        <div
          className="fixed inset-0 z-20 bg-black/50 lg:hidden"
          onClick={onClose}
          aria-hidden="true"
        />
      )}

      <aside
        className={cn(
          'fixed left-0 top-0 z-30 flex h-screen w-64 flex-col bg-brand-900',
          'transform transition-transform duration-300 ease-in-out',
          open
            ? 'translate-x-0'
            : '-translate-x-full lg:translate-x-0',
        )}
      >
        {/* Cabeçalho */}
        <div className="flex items-center justify-between border-b border-brand-800 px-4 py-5">
          <div>
            <div className="flex items-center gap-2">
              <div className="flex h-7 w-7 items-center justify-center rounded-md bg-brand-600">
                <BarChart2 className="h-4 w-4 text-white" />
              </div>

              <span className="text-sm font-bold leading-tight text-white">
                RF Performance
              </span>
            </div>

            <p className="mt-0.5 pl-9 text-xs text-green-400">
              Comercial
            </p>
          </div>

          <button
            type="button"
            onClick={onClose}
            className="rounded p-1 text-green-300 hover:text-white lg:hidden"
            aria-label="Fechar menu"
          >
            <X className="h-5 w-5" />
          </button>
        </div>

        {/* Organização ativa */}
        {activeOrganization && (
          <div className="border-b border-brand-800 bg-brand-800/60 px-4 py-2.5">
            {isAdmin ? (
              <>
                <label
                  htmlFor="active-organization-switcher"
                  className="block text-[11px] font-medium uppercase tracking-wide text-green-500/70"
                >
                  Organização ativa
                </label>
                <select
                  id="active-organization-switcher"
                  value={activeOrganization.id}
                  onChange={(event) => handleOrganizationChange(event.target.value)}
                  disabled={adminOrganizationsLoading || adminOrganizations.length === 0}
                  className="mt-1 w-full rounded-md border border-brand-700 bg-brand-950/40 px-2 py-1.5 text-xs font-medium text-white outline-none focus:border-green-400 disabled:cursor-not-allowed disabled:opacity-60"
                >
                  {adminOrganizations.map((organization) => (
                    <option key={organization.id} value={organization.id}>
                      {organization.trade_name}
                    </option>
                  ))}
                </select>
                <p className="mt-1 text-xs text-green-500/70">
                  Modo administrador
                </p>
              </>
            ) : (
              <p className="truncate text-xs font-medium text-green-400">
                {activeOrganization.trade_name}
              </p>
            )}
          </div>
        )}

        {/* Navegação */}
        <nav className="flex-1 space-y-5 overflow-y-auto px-2 py-4">
          {NAV.map((section) => {
            const visibleItems = section.items.filter((item) =>
              canAccessRoute(currentRole, item.path),
            )

            if (visibleItems.length === 0) {
              return null
            }

            return (
              <div key={section.title}>
                <p className="mb-1.5 px-3 text-xs font-semibold uppercase tracking-wider text-green-500">
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

                            <span className="ml-auto rounded-full bg-brand-950/40 px-1.5 py-0.5 text-xs text-green-500/60">
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
                          onClick={onClose}
                          className={({ isActive }) =>
                            cn(
                              'sidebar-link',
                              isActive
                                ? 'sidebar-link-active'
                                : 'sidebar-link-inactive',
                            )
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

        {/* Perfil do usuário */}
        <div className="border-t border-brand-800 px-4 py-4">
          <div className="flex items-center gap-3">
            <div className="flex h-8 w-8 shrink-0 items-center justify-center rounded-full bg-brand-600">
              <span className="text-xs font-semibold text-white">
                {initials}
              </span>
            </div>

            <div className="min-w-0 flex-1">
              <p className="truncate text-sm font-medium text-white">
                {displayName}
              </p>

              <p className="truncate text-xs text-green-400">
                {roleLabel}
              </p>
            </div>
          </div>

          <p className="mt-3 text-center text-xs text-green-600">
            Tecnologia e método EPSA
          </p>
        </div>
      </aside>
    </>
  )
}