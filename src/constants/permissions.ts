import { ROUTES } from '@/constants/routes'
import type { OrgRole, SystemRole } from '@/types/database'

export type AccessRole = SystemRole | OrgRole | null

type AssignedRole = Exclude<AccessRole, null>

const ALL_ROLES: readonly AssignedRole[] = [
  'platform_admin',
  'director',
  'supervisor',
  'salesperson',
]

const MANAGEMENT_ROLES: readonly AssignedRole[] = [
  'platform_admin',
  'director',
]

const TEAM_MANAGEMENT_ROLES: readonly AssignedRole[] = [
  'platform_admin',
  'director',
  'supervisor',
]

/**
 * Matriz de acesso às rotas.
 *
 * Algumas áreas permanecem temporariamente restritas a administrador e
 * diretor até que as policies RLS sejam limitadas por equipe, responsável
 * ou usuário.
 */
export const ROUTE_ACCESS: Partial<
  Record<string, readonly AssignedRole[]>
> = {
  [ROUTES.HOME]: ALL_ROLES,

  // Gestão estratégica
  [ROUTES.PLAN_90_DAYS]: MANAGEMENT_ROLES,
  [ROUTES.GOALS]: MANAGEMENT_ROLES,
  [ROUTES.RESULTS]: MANAGEMENT_ROLES,

  // Ações ainda possuem leitura organizacional ampla no banco.
  [ROUTES.ACTIONS]: MANAGEMENT_ROLES,

  // Operação e desenvolvimento
  [ROUTES.MEETINGS]: ALL_ROLES,
  [ROUTES.TRAINING]: ALL_ROLES,
  [ROUTES.EVALUATIONS]: ALL_ROLES,
  [ROUTES.FEEDBACKS]: ALL_ROLES,

  // Relatórios ainda serão separados por escopo.
  [ROUTES.REPORTS]: MANAGEMENT_ROLES,

  // Administração
  [ROUTES.ORGANIZATIONS]: MANAGEMENT_ROLES,
  [ROUTES.OPERATIONS]: MANAGEMENT_ROLES,
  [ROUTES.SALES_LOCATIONS]: TEAM_MANAGEMENT_ROLES,
  [ROUTES.TEAMS]: TEAM_MANAGEMENT_ROLES,
  [ROUTES.USERS]: MANAGEMENT_ROLES,
  [ROUTES.SETTINGS]: MANAGEMENT_ROLES,
}

export function canAccessRoute(
  role: AccessRole,
  route: string,
): boolean {
  if (!role) return false

  const allowedRoles = ROUTE_ACCESS[route]

  if (!allowedRoles) return false

  return allowedRoles.some((allowedRole) => allowedRole === role)
}