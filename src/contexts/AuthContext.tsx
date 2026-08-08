import { createContext, useContext, useEffect, useState, useCallback } from 'react'
import type { User } from '@supabase/supabase-js'
import { useQueryClient } from '@tanstack/react-query'
import { supabase } from '@/lib/supabase'
import type { Profile, OrganizationMember } from '@/types/database'
import type {
  ActiveOrganizationSummary,
  AuthContextType,
  AuthUser,
} from '@/types/auth'

const AuthContext = createContext<AuthContextType | null>(null)

const ACTIVE_ORGANIZATION_COLUMNS =
  'id, trade_name, slug, logo_url, status, source_system'

function getAdminOrganizationStorageKey(userId: string) {
  return `rf-performance:admin-active-organization:${userId}`
}

function mapSupabaseUser(user: User): AuthUser {
  return { id: user.id, email: user.email! }
}

export function AuthProvider({ children }: { children: React.ReactNode }) {
  const queryClient = useQueryClient()
  const [user, setUser] = useState<AuthUser | null>(null)
  const [profile, setProfile] = useState<Profile | null>(null)
  const [activeMembership, setActiveMembership] = useState<OrganizationMember | null>(null)
  const [activeOrganization, setActiveOrg] =
    useState<ActiveOrganizationSummary | null>(null)
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)

  const loadUserData = useCallback(async (userId: string) => {
    console.log('[Auth] Loading data for user:', userId)
    setError(null)

    const { data: profileData, error: profileError } = await supabase
      .from('profiles')
      .select('*')
      .eq('id', userId)
      .single()

    if (profileError || !profileData) {
      setError('Perfil não encontrado. Contate o administrador da plataforma.')
      return
    }

    if (profileData.status !== 'active') {
      setError('Usuário inativo. Contate o administrador.')
      return
    }

    setProfile(profileData)

    // PLATFORM_ADMIN: restore the last selected active organization when possible.
    if (profileData.system_role === 'platform_admin') {
      const { data: orgs, error: organizationError } =
        await supabase
          .from('organizations')
          .select(ACTIVE_ORGANIZATION_COLUMNS)
          .eq('status', 'active')
          .order('trade_name', { ascending: true })

      if (organizationError) {
        setError('Erro ao carregar a organização ativa.')
        return
      }

      const activeOrganizations =
        (orgs ?? []) as ActiveOrganizationSummary[]
      const storageKey = getAdminOrganizationStorageKey(userId)
      const storedOrganizationId = window.localStorage.getItem(storageKey)
      const selectedOrganization =
        activeOrganizations.find(
          (organization) => organization.id === storedOrganizationId,
        ) ?? activeOrganizations[0] ?? null

      setActiveOrg(selectedOrganization)

      if (selectedOrganization) {
        window.localStorage.setItem(storageKey, selectedOrganization.id)
      } else {
        window.localStorage.removeItem(storageKey)
      }

      return
    }

    // Regular users: load org membership
    const { data: membership, error: membershipError } = await supabase
      .from('organization_members')
      .select('*')
      .eq('user_id', userId)
      .eq('status', 'active')
      .is('archived_at', null)
      .order('created_at', { ascending: true })
      .limit(1)
      .maybeSingle()

    if (membershipError) {
      setError('Erro ao carregar vínculo organizacional.')
      return
    }

    if (!membership) {
      setError('Usuário sem organização vinculada. Contate o administrador.')
      return
    }

    setActiveMembership(membership)

    const { data: org, error: organizationError } =
      await supabase
        .from('organizations')
        .select(ACTIVE_ORGANIZATION_COLUMNS)
        .eq('id', membership.organization_id)
        .single()

    if (organizationError || !org) {
      setError('Erro ao carregar a organização vinculada.')
      return
    }

    setActiveOrg(org as ActiveOrganizationSummary)

    // Update last access timestamp
    await supabase
      .from('profiles')
      .update({ last_access_at: new Date().toISOString() })
      .eq('id', userId)
  }, [])

  const clearAuth = useCallback(() => {
    queryClient.clear()
    setUser(null)
    setProfile(null)
    setActiveMembership(null)
    setActiveOrg(null)
    setError(null)
  }, [queryClient])

  useEffect(() => {
    let mounted = true

    // Safety #1: Check existing session
    supabase.auth.getSession().then(({ data: { session } }) => {
      if (!mounted) return
      if (session?.user) {
        setUser(mapSupabaseUser(session.user))
        loadUserData(session.user.id).finally(() => {
          if (mounted) setLoading(false)
        })
      } else {
        setLoading(false)
      }
    })

    // Safety #2: Listen to auth state changes
    const { data: { subscription } } = supabase.auth.onAuthStateChange((event, session) => {
      if (!mounted) return
      console.log('[Auth] State change:', event)

      if (event === 'SIGNED_IN' && session?.user) {
        setUser(mapSupabaseUser(session.user))
        loadUserData(session.user.id).finally(() => {
          if (mounted) setLoading(false)
        })
      } else if (event === 'SIGNED_OUT') {
        clearAuth()
        setLoading(false)
      } else if (event === 'TOKEN_REFRESHED' && session?.user) {
        setUser(mapSupabaseUser(session.user))
      } else if (event === 'PASSWORD_RECOVERY') {
        setLoading(false)
      }
    })

    return () => {
      mounted = false
      subscription.unsubscribe()
    }
  }, [loadUserData, clearAuth])

  const signOut = async () => {
    await supabase.auth.signOut()
  }

  const setActiveOrganization = useCallback((
    organization: ActiveOrganizationSummary | null,
  ) => {
    if (profile?.system_role !== 'platform_admin') return
    if (organization && organization.status !== 'active') return

    if (user?.id) {
      const storageKey = getAdminOrganizationStorageKey(user.id)
      if (organization) {
        window.localStorage.setItem(storageKey, organization.id)
      } else {
        window.localStorage.removeItem(storageKey)
      }
    }

    // Keep the global organizations list, but discard organization-scoped cache.
    queryClient.removeQueries({
      predicate: (query) => query.queryKey[0] !== 'organizations',
    })
    setActiveOrg(organization)
  }, [profile?.system_role, queryClient, user?.id])

  const isAdmin = profile?.system_role === 'platform_admin'
  const isDirector = !isAdmin && activeMembership?.role === 'director'
  const isSupervisor = !isAdmin && activeMembership?.role === 'supervisor'
  const isSalesperson = !isAdmin && activeMembership?.role === 'salesperson'

  return (
    <AuthContext.Provider value={{
      user,
      profile,
      activeMembership,
      activeOrganization,
      loading,
      error,
      isAdmin,
      isDirector,
      isSupervisor,
      isSalesperson,
      currentRole: isAdmin ? 'platform_admin' : (activeMembership?.role ?? null),
      canManageOrganization: isAdmin || isDirector,
      canManageTeams: isAdmin || isDirector,
      canViewAdmin: isAdmin || isDirector,
      signOut,
      setActiveOrganization,
      refreshProfile: () => user ? loadUserData(user.id) : Promise.resolve(),
    }}>
      {children}
    </AuthContext.Provider>
  )
}

export function useAuth(): AuthContextType {
  const ctx = useContext(AuthContext)
  if (!ctx) throw new Error('useAuth deve ser usado dentro de AuthProvider')
  return ctx
}
