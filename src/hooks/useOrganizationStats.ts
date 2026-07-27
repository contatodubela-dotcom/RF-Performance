import { useQuery } from '@tanstack/react-query'
import { supabase } from '@/lib/supabase'

export function useOrganizationStats(organizationId: string | undefined) {
  return useQuery({
    queryKey: ['org-stats', organizationId],
    enabled: !!organizationId,
    staleTime: 1000 * 60 * 2,
    queryFn: async () => {
      if (!organizationId) return null

      const [pdvRes, teamRes, memberRes] = await Promise.all([
        supabase.from('sales_locations').select('id', { count: 'exact', head: true })
          .eq('organization_id', organizationId).eq('status', 'active'),
        supabase.from('teams').select('id', { count: 'exact', head: true })
          .eq('organization_id', organizationId).eq('status', 'active'),
        supabase.from('organization_members').select('id, role')
          .eq('organization_id', organizationId).eq('status', 'active'),
      ])

      const members = memberRes.data ?? []
      return {
        pdvCount: pdvRes.count ?? 0,
        teamCount: teamRes.count ?? 0,
        directorCount: members.filter(m => m.role === 'director').length,
        supervisorCount: members.filter(m => m.role === 'supervisor').length,
        salespersonCount: members.filter(m => m.role === 'salesperson').length,
        totalMembers: members.length,
      }
    },
  })
}

export function useSetupChecklist(organizationId: string | undefined) {
  return useQuery({
    queryKey: ['setup-checklist', organizationId],
    enabled: !!organizationId,
    staleTime: 1000 * 60,
    queryFn: async () => {
      if (!organizationId) return null

      const [orgRes, opRes, pdvRes, supervisorsRes, teamsRes, salesRes] = await Promise.all([
        supabase.from('organizations').select('id').eq('id', organizationId).eq('status', 'active'),
        supabase.from('operations').select('id').eq('organization_id', organizationId).eq('status', 'active'),
        supabase.from('sales_locations').select('id, shopping_name').eq('organization_id', organizationId).eq('status', 'active'),
        supabase.from('organization_members').select('id').eq('organization_id', organizationId).eq('role', 'supervisor').eq('status', 'active'),
        supabase.from('teams').select('id').eq('organization_id', organizationId).eq('status', 'active'),
        supabase.from('organization_members').select('id').eq('organization_id', organizationId).eq('role', 'salesperson').eq('status', 'active'),
      ])

      const pdvs = pdvRes.data ?? []
      const pdvsReviewed = pdvs.length >= 3 && pdvs.some(p => p.shopping_name)

      return {
        orgRegistered: (orgRes.data?.length ?? 0) > 0,
        operationRegistered: (opRes.data?.length ?? 0) > 0,
        pdvsReviewed,
        supervisorsRegistered: (supervisorsRes.data?.length ?? 0) > 0,
        teamsCreated: (teamsRes.data?.length ?? 0) > 0,
        salespersonsRegistered: (salesRes.data?.length ?? 0) > 0,
        linksCompleted: (teamsRes.data?.length ?? 0) > 0 && (salesRes.data?.length ?? 0) > 0,
      }
    },
  })
}
