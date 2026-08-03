import type {
  Organization,
  OrganizationMember,
  OrgRole,
  Profile,
  SystemRole,
} from './database'

export interface AuthUser {
  id: string
  email: string
}

export type CurrentRole = SystemRole | OrgRole | null

export type ActiveOrganizationSummary = Pick<
  Organization,
  | 'id'
  | 'trade_name'
  | 'slug'
  | 'logo_url'
  | 'status'
  | 'source_system'
>

export interface AuthContextType {
  user: AuthUser | null
  profile: Profile | null
  activeMembership: OrganizationMember | null
  activeOrganization: ActiveOrganizationSummary | null
  loading: boolean
  error: string | null

  // Computed role flags
  isAdmin: boolean
  isDirector: boolean
  isSupervisor: boolean
  isSalesperson: boolean
  currentRole: CurrentRole

  // Feature access
  canManageOrganization: boolean
  canManageTeams: boolean
  canViewAdmin: boolean

  // Actions
  signOut: () => Promise<void>
  setActiveOrganization: (
    org: ActiveOrganizationSummary | null,
  ) => void
  refreshProfile: () => Promise<void>
}
