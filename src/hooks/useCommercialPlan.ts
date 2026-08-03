import { useQuery } from '@tanstack/react-query'
import { supabase } from '@/lib/supabase'
import { useAuth } from '@/contexts/AuthContext'
import type { CommercialPlan } from '@/types/commercialPlan'

export interface CommercialPlanReference {
  id: string
  organization_id: string
  title: string
  status: string
}

export function useCommercialPlan(organizationId?: string) {
  const { user, isAdmin, isDirector } = useAuth()
  const canViewFullPlan = isAdmin || isDirector

  return useQuery({
    queryKey: ['commercial-plan', organizationId, user?.id, 'full'],
    enabled: !!organizationId && !!user?.id && canViewFullPlan,
    queryFn: async () => {
      if (!organizationId || !user?.id || !canViewFullPlan) return null

      const { data, error } = await supabase
        .from('commercial_plans')
        .select('*')
        .eq('organization_id', organizationId)
        .neq('status', 'archived')
        .order('created_at', { ascending: true })
        .limit(1)
        .maybeSingle()

      if (error) throw error
      return data as CommercialPlan | null
    },
  })
}

export function useCommercialPlanReference(organizationId?: string) {
  const { user } = useAuth()

  return useQuery({
    queryKey: ['commercial-plan', organizationId, user?.id, 'reference'],
    enabled: !!organizationId && !!user?.id,
    queryFn: async () => {
      if (!organizationId || !user?.id) return null

      const { data, error } = await supabase
        .rpc('get_commercial_plan_reference', {
          p_organization_id: organizationId,
        })
        .maybeSingle()

      if (error) throw error
      return data as CommercialPlanReference | null
    },
  })
}
