import { useQuery } from '@tanstack/react-query'
import { supabase } from '@/lib/supabase'
import {
  getAdjustedMonthlyCapacityReference,
  getConfirmedActiveProducers,
  getConfirmedActiveSalespersons,
  getConfirmedActiveSupervisors,
  getFullMonthlyCapacityReference,
  getMaturityCurve,
  getMinimumMonthlySalesPerProducer,
  getPlannedLocationCapacity,
  getPlannedProducerCapacity,
  getPlannedSalespersonCapacity,
  getPlannedSupervisorCapacity,
  getPlannedSupervisorPositions,
  getPlannedTeamCapacity,
  getSetupMetadata,
  getVacantSalespersonPositions,
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
      const setupMetadata = getSetupMetadata(organizationMetadata)
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

      const confirmedSupervisorCount =
        getConfirmedActiveSupervisors(organizationMetadata) ||
        teams.reduce(
          (total, team) =>
            total + getConfirmedActiveSupervisors(team.metadata),
          0,
        )
      const confirmedSalespersonCount =
        getConfirmedActiveSalespersons(organizationMetadata) ||
        teams.reduce(
          (total, team) =>
            total + getConfirmedActiveSalespersons(team.metadata),
          0,
        )
      const confirmedProducerCount =
        getConfirmedActiveProducers(organizationMetadata) ||
        teams.reduce(
          (total, team) =>
            total + getConfirmedActiveProducers(team.metadata),
          0,
        )
      const vacantSalespersonCount =
        getVacantSalespersonPositions(organizationMetadata) ||
        teams.reduce(
          (total, team) =>
            total + getVacantSalespersonPositions(team.metadata),
          0,
        )
      const plannedProducerCount =
        getPlannedProducerCapacity(organizationMetadata) ||
        teams.reduce(
          (total, team) =>
            total + getPlannedProducerCapacity(team.metadata),
          0,
        )

      const supervisorCount = members.filter(
        (member) => member.role === 'supervisor',
      ).length
      const salespersonCount = members.filter(
        (member) => member.role === 'salesperson',
      ).length

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
        supervisorCount,
        salespersonCount,
        linkedProducerCount: supervisorCount + salespersonCount,
        totalMembers: members.length,

        plannedSupervisorCount,
        plannedSalespersonCount,
        plannedProducerCount,

        confirmedSupervisorCount,
        confirmedSalespersonCount,
        confirmedProducerCount,
        vacantSalespersonCount,

        minimumMonthlySalesPerProducer:
          getMinimumMonthlySalesPerProducer(organizationMetadata),
        adjustedMonthlyCapacityReference:
          getAdjustedMonthlyCapacityReference(organizationMetadata),
        fullMonthlyCapacityReference:
          getFullMonthlyCapacityReference(organizationMetadata),
        maturityCurve: getMaturityCurve(organizationMetadata),

        shoppingCenterCount:
          typeof setupMetadata.shopping_center_count === 'number'
            ? setupMetadata.shopping_center_count
            : 0,
        consortiumAdministratorCount:
          typeof setupMetadata.consortium_administrator_count === 'number'
            ? setupMetadata.consortium_administrator_count
            : 0,
        consortiumAdministrators:
          Array.isArray(setupMetadata.consortium_administrators)
            ? setupMetadata.consortium_administrators
            : [],

        baselineMonthlySales:
          Number(setupMetadata.baseline_monthly_sales) || 0,
        growthTargetPercent:
          Number(setupMetadata.growth_target_percent) || 0,
        targetMonthlySales:
          Number(setupMetadata.target_monthly_sales) || 0,
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
          .select('id, metadata')
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
          .select('id, supervisor_member_id, metadata')
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

      const organizationMetadata =
        organizationRes.data?.[0]?.metadata as
          | Record<string, unknown>
          | null
          | undefined
      const pdvs = pdvRes.data ?? []
      const supervisors = supervisorsRes.data ?? []
      const teams = teamsRes.data ?? []
      const salespersons = salespersonsRes.data ?? []
      const assignments = assignmentsRes.data ?? []

      const requiredPdvCount =
        getPlannedLocationCapacity(organizationMetadata) || 3
      const requiredTeamCount =
        getPlannedTeamCapacity(organizationMetadata) ||
        requiredPdvCount
      const requiredSupervisorAccountCount =
        getPlannedSupervisorCapacity(organizationMetadata) ||
        teams.reduce(
          (total, team) =>
            total + getPlannedSupervisorPositions(team.metadata),
          0,
        )
      const requiredSalespersonAccountCount =
        getConfirmedActiveSalespersons(organizationMetadata)

      const confirmedSupervisorCount =
        getConfirmedActiveSupervisors(organizationMetadata)
      const confirmedSalespersonCount =
        getConfirmedActiveSalespersons(organizationMetadata)
      const confirmedProducerCount =
        getConfirmedActiveProducers(organizationMetadata)
      const plannedProducerCount =
        getPlannedProducerCapacity(organizationMetadata)
      const vacantSalespersonCount =
        getVacantSalespersonPositions(organizationMetadata)

      const pdvsReviewed =
        pdvs.length >= requiredPdvCount &&
        pdvs.every((pdv) => isSetupConfirmed(pdv.metadata))
      const teamsCreated =
        teams.length >= requiredTeamCount &&
        teams.every((team) => isSetupConfirmed(team.metadata))

      const operationalPeopleConfirmed =
        confirmedSupervisorCount > 0 &&
        confirmedSalespersonCount > 0 &&
        confirmedProducerCount ===
          confirmedSupervisorCount + confirmedSalespersonCount &&
        confirmedProducerCount + vacantSalespersonCount ===
          plannedProducerCount

      const supervisorAccountsLinked =
        requiredSupervisorAccountCount > 0 &&
        supervisors.length >= requiredSupervisorAccountCount
      const salespersonAccountsLinked =
        requiredSalespersonAccountCount > 0 &&
        salespersons.length >= requiredSalespersonAccountCount

      const allTeamsHaveSupervisor =
        teams.length >= requiredTeamCount &&
        teams.every((team) => Boolean(team.supervisor_member_id))
      const assignedSalespersonIds = new Set(
        assignments.map(
          (assignment) => assignment.organization_member_id,
        ),
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
        teamsCreated,
        operationalPeopleConfirmed,
        operationalStructureConfirmed:
          pdvsReviewed && teamsCreated && operationalPeopleConfirmed,

        supervisorsRegistered: supervisorAccountsLinked,
        salespersonsRegistered: salespersonAccountsLinked,
        supervisorAccountsLinked,
        salespersonAccountsLinked,

        linksCompleted:
          supervisorAccountsLinked &&
          salespersonAccountsLinked &&
          allTeamsHaveSupervisor &&
          everySalespersonAssigned,
      }
    },
  })
}