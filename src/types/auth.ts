import type { Profile, Organization, OrganizationMember, OrgRole, SystemRole } from './database'

export interface AuthUser {
  id: string
  email: string
}

export type CurrentRole = SystemRole | OrgRole | null

export interface AuthContextType {
  user: AuthUser | null
  profile: Profile | null
  activeMembership: OrganizationMember | null
  activeOrganization: Organization | null
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
  setActiveOrganization: (org: Organization | null) => void
  refreshProfile: () => Promise<void>
}
