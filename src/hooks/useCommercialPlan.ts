import { useQuery } from '@tanstack/react-query'
import { supabase } from '@/lib/supabase'
import type { CommercialPlan } from '@/types/commercialPlan'

export function useCommercialPlan(organizationId?: string) {
  return useQuery({
    queryKey: ['commercial-plan', organizationId],
    enabled: !!organizationId,
    queryFn: async () => {
      if (!organizationId) return null

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
