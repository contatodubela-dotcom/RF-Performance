import { useAuth } from '@/contexts/AuthContext'

export function usePermissions() {
  const { isAdmin, isDirector, isSupervisor, isSalesperson, currentRole } = useAuth()

  return {
    isAdmin,
    isDirector,
    isSupervisor,
    isSalesperson,

    // Page/feature access
    canViewOrganizations: isAdmin,
    canManageOrganizations: isAdmin,
    canViewOperations: isAdmin || isDirector,
    canManageOperations: isAdmin || isDirector,
    canViewPDVs: isAdmin || isDirector || isSupervisor,
    canManagePDVs: isAdmin || isDirector,
    canViewTeams: isAdmin || isDirector || isSupervisor,
    canManageTeams: isAdmin || isDirector,
    canViewUsers: isAdmin || isDirector || isSupervisor,
    canManageUsers: isAdmin || isDirector,
    canInviteUsers: isAdmin || isDirector || isSupervisor,
    canViewAdmin: isAdmin || isDirector,

    hasRole: (roles: string[]) => !!currentRole && roles.includes(currentRole),
  }
}
