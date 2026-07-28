import { useQuery } from '@tanstack/react-query'
import { supabase } from '@/lib/supabase'
import {
  getPlannedSalespersonCapacity,
  getPlannedSupervisorPositions,
  isSetupConfirmed,
  isTemplateRecord,
} from '@/lib/setupMetadata'

export function useOrganizationStats(
  organizationId: string | undefined,
) {
  return useQuery({
    queryKey: ['org-stats', organizationId],
    enabled: !!organizationId,
    staleTime: 1000 * 60 * 2,
    queryFn: async () => {
      if (!organizationId) return null

      const [organizationRes, pdvRes, teamRes, memberRes] =
        await Promise.all([
          supabase
            .from('organizations')
            .select('metadata')
            .eq('id', organizationId)
            .single(),
          supabase
            .from('sales_locations')
            .select('id, metadata')
            .eq('organization_id', organizationId)
            .eq('status', 'active'),
          supabase
            .from('teams')
            .select('id, metadata')
            .eq('organization_id', organizationId)
            .eq('status', 'active'),
          supabase
            .from('organization_members')
            .select('id, role')
            .eq('organization_id', organizationId)
            .eq('status', 'active'),
        ])

      if (organizationRes.error) throw organizationRes.error
      if (pdvRes.error) throw pdvRes.error
      if (teamRes.error) throw teamRes.error
      if (memberRes.error) throw memberRes.error

      const organizationMetadata =
        organizationRes.data?.metadata as Record<string, unknown> | null
      const pdvs = pdvRes.data ?? []
      const teams = teamRes.data ?? []
      const members = memberRes.data ?? []

      const plannedSupervisorCount = teams.reduce(
        (total, team) =>
          total + getPlannedSupervisorPositions(team.metadata),
        0,
      )
      const plannedSalespersonCount = teams.reduce(
        (total, team) =>
          total + getPlannedSalespersonCapacity(team.metadata),
        0,
      )

      return {
        pdvCount: pdvs.length,
        pendingPdvCount: pdvs.filter(
          (pdv) => !isSetupConfirmed(pdv.metadata),
        ).length,
        teamCount: teams.length,
        templateTeamCount: teams.filter((team) =>
          isTemplateRecord(team.metadata),
        ).length,
        directorCount: members.filter(
          (member) => member.role === 'director',
        ).length,
        supervisorCount: members.filter(
          (member) => member.role === 'supervisor',
        ).length,
        salespersonCount: members.filter(
          (member) => member.role === 'salesperson',
        ).length,
        totalMembers: members.length,
        plannedSupervisorCount,
        plannedSalespersonCount,
        baselineMonthlySales:
          Number(organizationMetadata?.baseline_monthly_sales) || 0,
        growthTargetPercent:
          Number(organizationMetadata?.growth_target_percent) || 0,
        targetMonthlySales:
          Number(organizationMetadata?.target_monthly_sales) || 0,
      }
    },
  })
}

export function useSetupChecklist(
  organizationId: string | undefined,
) {
  return useQuery({
    queryKey: ['setup-checklist', organizationId],
    enabled: !!organizationId,
    staleTime: 1000 * 60,
    queryFn: async () => {
      if (!organizationId) return null

      const [
        organizationRes,
        operationRes,
        pdvRes,
        supervisorsRes,
        teamsRes,
        salespersonsRes,
        assignmentsRes,
      ] = await Promise.all([
        supabase
          .from('organizations')
          .select('id')
          .eq('id', organizationId)
          .eq('status', 'active'),
        supabase
          .from('operations')
          .select('id')
          .eq('organization_id', organizationId)
          .eq('status', 'active'),
        supabase
          .from('sales_locations')
          .select('id, metadata')
          .eq('organization_id', organizationId)
          .eq('status', 'active'),
        supabase
          .from('organization_members')
          .select('id')
          .eq('organization_id', organizationId)
          .eq('role', 'supervisor')
          .eq('status', 'active'),
        supabase
          .from('teams')
          .select('id, supervisor_member_id')
          .eq('organization_id', organizationId)
          .eq('status', 'active'),
        supabase
          .from('organization_members')
          .select('id')
          .eq('organization_id', organizationId)
          .eq('role', 'salesperson')
          .eq('status', 'active'),
        supabase
          .from('team_members')
          .select('id, organization_member_id')
          .eq('organization_id', organizationId)
          .eq('status', 'active')
          .is('archived_at', null),
      ])

      const errors = [
        organizationRes.error,
        operationRes.error,
        pdvRes.error,
        supervisorsRes.error,
        teamsRes.error,
        salespersonsRes.error,
        assignmentsRes.error,
      ].filter(Boolean)

      if (errors.length > 0) throw errors[0]

      const pdvs = pdvRes.data ?? []
      const supervisors = supervisorsRes.data ?? []
      const teams = teamsRes.data ?? []
      const salespersons = salespersonsRes.data ?? []
      const assignments = assignmentsRes.data ?? []

      const pdvsReviewed =
        pdvs.length >= 3 &&
        pdvs.every((pdv) => isSetupConfirmed(pdv.metadata))
      const allTeamsHaveSupervisor =
        teams.length >= 3 &&
        teams.every((team) => Boolean(team.supervisor_member_id))
      const assignedSalespersonIds = new Set(
        assignments.map((assignment) => assignment.organization_member_id),
      )
      const everySalespersonAssigned =
        salespersons.length > 0 &&
        salespersons.every((salesperson) =>
          assignedSalespersonIds.has(salesperson.id),
        )

      return {
        orgRegistered: (organizationRes.data?.length ?? 0) > 0,
        operationRegistered: (operationRes.data?.length ?? 0) > 0,
        pdvsReviewed,
        supervisorsRegistered: supervisors.length >= 3,
        teamsCreated: teams.length >= 3,
        salespersonsRegistered: salespersons.length > 0,
        linksCompleted:
          allTeamsHaveSupervisor && everySalespersonAssigned,
      }
    },
  })
}
