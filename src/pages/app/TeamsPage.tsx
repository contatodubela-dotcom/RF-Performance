import { useMemo, useState } from 'react'
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query'
import { useForm } from 'react-hook-form'
import { zodResolver } from '@hookform/resolvers/zod'
import {
  BadgeCheck,
  Clock3,
  Pencil,
  Plus,
  UserMinus,
  UserPlus,
  Users2,
} from 'lucide-react'
import { toast } from 'sonner'
import { z } from 'zod'
import { supabase } from '@/lib/supabase'
import { useAuth } from '@/contexts/AuthContext'
import { usePermissions } from '@/hooks/usePermissions'
import { teamSchema } from '@/lib/validations'
import {
  getPlannedSalespersonCapacity,
  getSetupMetadata,
  isSetupConfirmed,
  isTemplateRecord,
  updateSetupMetadata,
} from '@/lib/setupMetadata'
import type { OrgRole, Team, TeamMember } from '@/types/database'
import PageHeader from '@/components/shared/PageHeader'
import StatusBadge from '@/components/shared/StatusBadge'
import EmptyState from '@/components/shared/EmptyState'
import LoadingSpinner from '@/components/shared/LoadingSpinner'
import {
  Dialog,
  DialogContent,
  DialogHeader,
  DialogTitle,
} from '@/components/ui/dialog'
import { ROLE_LABELS } from '@/constants/roles'

type FormData = z.infer<typeof teamSchema>

type ProfileRelation = {
  full_name: string | null
  email?: string | null
}

type SupervisorOption = {
  id: string
  user_id: string
  profiles: ProfileRelation | ProfileRelation[] | null
}

type TeamMemberSummary = {
  id: string
  status: string
  archived_at: string | null
}

type TeamRow = Team & {
  sales_location: { name: string } | null
  supervisor: {
    user_id: string
    profiles: ProfileRelation | ProfileRelation[] | null
  } | null
  team_members: TeamMemberSummary[] | null
}

type TeamMemberRow = TeamMember & {
  organization_member: {
    user_id: string
    role: OrgRole
    profiles: ProfileRelation | ProfileRelation[] | null
  } | null
}

type AvailableMember = {
  id: string
  user_id: string
  role: OrgRole
  profiles: ProfileRelation | ProfileRelation[] | null
}

function getRelatedProfile(
  relation: ProfileRelation | ProfileRelation[] | null | undefined,
): ProfileRelation | null {
  if (Array.isArray(relation)) return relation[0] ?? null
  return relation ?? null
}

function TeamForm({
  team,
  orgId,
  onClose,
}: {
  team?: Team
  orgId: string
  onClose: () => void
}) {
  const { profile } = useAuth()
  const qc = useQueryClient()
  const setup = getSetupMetadata(team?.metadata)
  const [plannedCapacity, setPlannedCapacity] = useState(
    getPlannedSalespersonCapacity(team?.metadata) || 1,
  )
  const [confirmData, setConfirmData] = useState(
    isSetupConfirmed(team?.metadata),
  )

  const { data: operations } = useQuery({
    queryKey: ['operations', orgId],
    queryFn: async () => {
      const { data, error } = await supabase
        .from('operations')
        .select('id, name')
        .eq('organization_id', orgId)
        .eq('status', 'active')

      if (error) throw error
      return data ?? []
    },
  })

  const { data: locations } = useQuery({
    queryKey: ['sales-locations', orgId],
    queryFn: async () => {
      const { data, error } = await supabase
        .from('sales_locations')
        .select('id, name')
        .eq('organization_id', orgId)
        .eq('status', 'active')

      if (error) throw error
      return data ?? []
    },
  })

  const { data: supervisors } = useQuery({
    queryKey: ['supervisors', orgId],
    queryFn: async () => {
      const { data, error } = await supabase
        .from('organization_members')
        .select(
          'id, user_id, profiles!organization_members_user_id_fkey(full_name)',
        )
        .eq('organization_id', orgId)
        .eq('role', 'supervisor')
        .eq('status', 'active')
        .is('archived_at', null)

      if (error) throw error
      return (data ?? []) as SupervisorOption[]
    },
  })

  const {
    register,
    handleSubmit,
    formState: { errors },
  } = useForm<FormData>({
    resolver: zodResolver(teamSchema),
    defaultValues: {
      name: team?.name ?? '',
      description: team?.description ?? '',
      operation_id: team?.operation_id ?? '',
      sales_location_id: team?.sales_location_id ?? '',
      supervisor_member_id: team?.supervisor_member_id ?? '',
    },
  })

  const mutation = useMutation({
    mutationFn: async (data: FormData) => {
      if (plannedCapacity < 1 || plannedCapacity > 500) {
        throw new Error('Informe uma capacidade entre 1 e 500 vendedores.')
      }

      if (
        confirmData &&
        (!data.sales_location_id || !data.supervisor_member_id)
      ) {
        throw new Error(
          'Para confirmar a equipe, selecione o PDV e o supervisor real.',
        )
      }

      const payload = {
        organization_id: orgId,
        operation_id: data.operation_id,
        sales_location_id: data.sales_location_id || null,
        supervisor_member_id: data.supervisor_member_id || null,
        name: data.name,
        description: data.description || null,
        metadata: updateSetupMetadata(team?.metadata, {
          confirmed: confirmData,
          userId: profile?.id,
          plannedSalespersonCapacity: plannedCapacity,
          plannedSupervisorPositions:
            setup.planned_supervisor_positions ?? 1,
        }),
        updated_by: profile?.id,
      }

      if (team) {
        const { error } = await supabase
          .from('teams')
          .update(payload)
          .eq('id', team.id)

        if (error) throw error
      } else {
        const { error } = await supabase.from('teams').insert({
          ...payload,
          source_system: 'rf_performance',
          created_by: profile?.id,
        })

        if (error) throw error
      }
    },
    onSuccess: () => {
      toast.success(
        team
          ? confirmData
            ? 'Equipe atualizada e confirmada.'
            : 'Equipe atualizada como estrutura provisória.'
          : 'Equipe criada.',
      )
      qc.invalidateQueries({ queryKey: ['teams'] })
      qc.invalidateQueries({ queryKey: ['org-stats'] })
      qc.invalidateQueries({ queryKey: ['setup-checklist'] })
      onClose()
    },
    onError: (error: Error) => toast.error(error.message),
  })

  return (
    <form
      onSubmit={handleSubmit((data) => mutation.mutate(data))}
      className="space-y-4"
    >
      {team && isTemplateRecord(team.metadata) && (
        <div className="rounded-lg border border-amber-200 bg-amber-50 p-3 text-sm text-amber-900">
          Equipe criada pelo template de apresentação. Edite o nome, o PDV, o
          supervisor e a capacidade conforme o diagnóstico real.
        </div>
      )}

      <div>
        <label className="form-label">Nome da equipe *</label>
        <input
          {...register('name')}
          className="form-input"
          placeholder="Ex: Equipe Shopping Tijuca"
        />
        {errors.name && (
          <p className="form-error">{errors.name.message}</p>
        )}
      </div>

      <div className="grid grid-cols-2 gap-4">
        <div>
          <label className="form-label">Operação *</label>
          <select {...register('operation_id')} className="form-input">
            <option value="">Selecione...</option>
            {operations?.map((operation) => (
              <option key={operation.id} value={operation.id}>
                {operation.name}
              </option>
            ))}
          </select>
          {errors.operation_id && (
            <p className="form-error">{errors.operation_id.message}</p>
          )}
        </div>
        <div>
          <label className="form-label">PDV</label>
          <select {...register('sales_location_id')} className="form-input">
            <option value="">Nenhum</option>
            {locations?.map((location) => (
              <option key={location.id} value={location.id}>
                {location.name}
              </option>
            ))}
          </select>
        </div>
      </div>

      <div className="grid grid-cols-2 gap-4">
        <div>
          <label className="form-label">Supervisor</label>
          <select
            {...register('supervisor_member_id')}
            className="form-input"
          >
            <option value="">A definir</option>
            {supervisors?.map((supervisor) => {
              const relatedProfile = getRelatedProfile(supervisor.profiles)

              return (
                <option key={supervisor.id} value={supervisor.id}>
                  {relatedProfile?.full_name ?? supervisor.user_id}
                </option>
              )
            })}
          </select>
        </div>
        <div>
          <label className="form-label">Capacidade de vendedores</label>
          <input
            type="number"
            min={1}
            max={500}
            value={plannedCapacity}
            onChange={(event) =>
              setPlannedCapacity(Number(event.target.value) || 1)
            }
            className="form-input"
          />
        </div>
      </div>

      <div>
        <label className="form-label">Descrição</label>
        <textarea
          {...register('description')}
          className="form-input"
          rows={2}
          placeholder="Objetivo ou observações da equipe"
        />
      </div>

      <label className="flex items-start gap-3 rounded-lg border border-gray-200 p-3">
        <input
          type="checkbox"
          checked={confirmData}
          onChange={(event) => setConfirmData(event.target.checked)}
          className="mt-1 h-4 w-4 rounded border-gray-300 text-brand-700"
        />
        <span>
          <span className="block text-sm font-medium text-gray-900">
            Confirmar estrutura real da equipe
          </span>
          <span className="block text-xs text-gray-500">
            Requer PDV e supervisor real selecionados.
          </span>
        </span>
      </label>

      <div className="flex justify-end gap-3 pt-2">
        <button type="button" onClick={onClose} className="btn-secondary">
          Cancelar
        </button>
        <button
          type="submit"
          disabled={mutation.isPending}
          className="btn-primary"
        >
          {mutation.isPending
            ? 'Salvando...'
            : team
              ? 'Salvar alterações'
              : 'Criar equipe'}
        </button>
      </div>
    </form>
  )
}

function MembersPanel({
  team,
  orgId,
  canManage,
  onClose,
}: {
  team: TeamRow
  orgId: string
  canManage: boolean
  onClose: () => void
}) {
  const { profile } = useAuth()
  const qc = useQueryClient()
  const [selectedMemberId, setSelectedMemberId] = useState('')

  const { data: teamMembers, isLoading: membersLoading } = useQuery({
    queryKey: ['team-members', team.id],
    queryFn: async () => {
      const { data, error } = await supabase
        .from('team_members')
        .select(
          '*, organization_member:organization_members(user_id, role, profiles!organization_members_user_id_fkey(full_name, email))',
        )
        .eq('team_id', team.id)
        .eq('status', 'active')
        .is('archived_at', null)

      if (error) throw error
      return (data ?? []) as TeamMemberRow[]
    },
  })

  const { data: availableMembers, isLoading: availableLoading } = useQuery({
    queryKey: ['available-salespersons', orgId, team.id],
    enabled: canManage,
    queryFn: async () => {
      const [membersResult, assignmentsResult] = await Promise.all([
        supabase
          .from('organization_members')
          .select(
            'id, user_id, role, profiles!organization_members_user_id_fkey(full_name, email)',
          )
          .eq('organization_id', orgId)
          .eq('role', 'salesperson')
          .eq('status', 'active')
          .is('archived_at', null),
        supabase
          .from('team_members')
          .select('organization_member_id')
          .eq('organization_id', orgId)
          .eq('status', 'active')
          .is('archived_at', null),
      ])

      if (membersResult.error) throw membersResult.error
      if (assignmentsResult.error) throw assignmentsResult.error

      const assignedIds = new Set(
        (assignmentsResult.data ?? []).map(
          (assignment) => assignment.organization_member_id,
        ),
      )

      return ((membersResult.data ?? []) as AvailableMember[]).filter(
        (member) => !assignedIds.has(member.id),
      )
    },
  })

  const addMemberMutation = useMutation({
    mutationFn: async (organizationMemberId: string) => {
      if (!organizationMemberId) {
        throw new Error('Selecione um vendedor disponível.')
      }

      const { error } = await supabase.from('team_members').insert({
        organization_id: orgId,
        team_id: team.id,
        organization_member_id: organizationMemberId,
        membership_type: 'salesperson',
        start_at: new Date().toISOString(),
        status: 'active',
        created_by: profile?.id,
        updated_by: profile?.id,
        metadata: {
          assignment_source: 'admin_ui',
        },
      })

      if (error) throw error
    },
    onSuccess: () => {
      toast.success('Vendedor vinculado à equipe.')
      setSelectedMemberId('')
      qc.invalidateQueries({ queryKey: ['team-members'] })
      qc.invalidateQueries({ queryKey: ['available-salespersons'] })
      qc.invalidateQueries({ queryKey: ['teams'] })
      qc.invalidateQueries({ queryKey: ['org-stats'] })
      qc.invalidateQueries({ queryKey: ['setup-checklist'] })
    },
    onError: (error: Error) => toast.error(error.message),
  })

  const removeMemberMutation = useMutation({
    mutationFn: async (teamMemberId: string) => {
      const { error } = await supabase
        .from('team_members')
        .update({
          status: 'inactive',
          end_at: new Date().toISOString(),
          updated_by: profile?.id,
        })
        .eq('id', teamMemberId)

      if (error) throw error
    },
    onSuccess: () => {
      toast.success('Vínculo encerrado e histórico preservado.')
      qc.invalidateQueries({ queryKey: ['team-members'] })
      qc.invalidateQueries({ queryKey: ['available-salespersons'] })
      qc.invalidateQueries({ queryKey: ['teams'] })
      qc.invalidateQueries({ queryKey: ['org-stats'] })
      qc.invalidateQueries({ queryKey: ['setup-checklist'] })
    },
    onError: (error: Error) => toast.error(error.message),
  })

  const plannedCapacity = getPlannedSalespersonCapacity(team.metadata)
  const activeCount = teamMembers?.length ?? 0

  return (
    <div className="space-y-4">
      <div className="rounded-lg bg-gray-50 p-3">
        <div className="flex items-center justify-between text-sm">
          <span className="text-gray-500">Ocupação planejada</span>
          <span className="font-semibold text-gray-900">
            {activeCount}/{plannedCapacity || '—'} vendedores
          </span>
        </div>
      </div>

      {canManage && (
        <div className="rounded-lg border border-gray-200 p-3">
          <label className="form-label">Adicionar vendedor disponível</label>
          <div className="flex gap-2">
            <select
              value={selectedMemberId}
              onChange={(event) => setSelectedMemberId(event.target.value)}
              className="form-input"
              disabled={availableLoading}
            >
              <option value="">Selecione...</option>
              {availableMembers?.map((member) => {
                const relatedProfile = getRelatedProfile(member.profiles)
                return (
                  <option key={member.id} value={member.id}>
                    {relatedProfile?.full_name ?? member.user_id}
                  </option>
                )
              })}
            </select>
            <button
              type="button"
              onClick={() => addMemberMutation.mutate(selectedMemberId)}
              disabled={!selectedMemberId || addMemberMutation.isPending}
              className="btn-primary shrink-0"
            >
              <UserPlus className="h-4 w-4" /> Vincular
            </button>
          </div>
          {!availableLoading && (availableMembers?.length ?? 0) === 0 && (
            <p className="mt-2 text-xs text-gray-500">
              Nenhum vendedor sem equipe está disponível.
            </p>
          )}
        </div>
      )}

      {membersLoading ? (
        <div className="flex justify-center py-8">
          <LoadingSpinner />
        </div>
      ) : (teamMembers?.length ?? 0) === 0 ? (
        <div className="py-8 text-center text-sm text-gray-500">
          Nenhum vendedor ativo nesta equipe.
        </div>
      ) : (
        <ul className="divide-y divide-gray-100">
          {teamMembers?.map((teamMember) => {
            const relatedProfile = getRelatedProfile(
              teamMember.organization_member?.profiles,
            )

            return (
              <li
                key={teamMember.id}
                className="flex items-center justify-between py-3"
              >
                <div>
                  <p className="text-sm font-medium text-gray-900">
                    {relatedProfile?.full_name ?? '—'}
                  </p>
                  <p className="text-xs text-gray-500">
                    {ROLE_LABELS[
                      teamMember.organization_member?.role ?? ''
                    ] ?? teamMember.organization_member?.role}
                  </p>
                </div>
                {canManage && (
                  <button
                    onClick={() =>
                      removeMemberMutation.mutate(teamMember.id)
                    }
                    className="rounded p-1.5 text-gray-400 hover:bg-red-50 hover:text-red-600"
                    title="Encerrar vínculo"
                  >
                    <UserMinus className="h-4 w-4" />
                  </button>
                )}
              </li>
            )
          })}
        </ul>
      )}

      <div className="flex justify-end">
        <button type="button" onClick={onClose} className="btn-secondary">
          Fechar
        </button>
      </div>
    </div>
  )
}

export default function TeamsPage() {
  const { activeOrganization } = useAuth()
  const { canManageTeams } = usePermissions()
  const [formOpen, setFormOpen] = useState(false)
  const [editTeam, setEditTeam] = useState<Team | undefined>()
  const [membersTeam, setMembersTeam] = useState<TeamRow | undefined>()

  const orgId = activeOrganization?.id

  const {
    data: teams,
    isLoading,
    isError,
    error: teamsError,
  } = useQuery({
    queryKey: ['teams', orgId],
    enabled: !!orgId,
    queryFn: async () => {
      if (!orgId) return []

      const { data, error } = await supabase
        .from('teams')
        .select(`
          *,
          sales_location:sales_locations!teams_location_org_operation_fkey(
            name
          ),
          supervisor:organization_members!teams_supervisor_org_fkey(
            user_id,
            profiles!organization_members_user_id_fkey(full_name)
          ),
          team_members:team_members!team_members_team_org_fkey(
            id,
            status,
            archived_at
          )
        `)
        .eq('organization_id', orgId)
        .is('archived_at', null)
        .order('name')

      if (error) throw error
      return (data ?? []) as TeamRow[]
    },
  })

  const orderedTeams = useMemo(
    () =>
      [...(teams ?? [])].sort((first, second) => {
        const firstOrder =
          getSetupMetadata(first.metadata).presentation_order ?? 999
        const secondOrder =
          getSetupMetadata(second.metadata).presentation_order ?? 999

        return firstOrder - secondOrder ||
          first.name.localeCompare(second.name, 'pt-BR')
      }),
    [teams],
  )

  if (!orgId) {
    return (
      <div className="page-container">
        <EmptyState icon={Users2} title="Nenhuma organização ativa" />
      </div>
    )
  }

  return (
    <div className="page-container">
      <PageHeader
        title="Equipes"
        description="Estrutura modelo editável para os três PDVs, supervisores e vendedores."
        action={
          canManageTeams ? (
            <button
              onClick={() => {
                setEditTeam(undefined)
                setFormOpen(true)
              }}
              className="btn-primary"
            >
              <Plus className="h-4 w-4" /> Nova equipe
            </button>
          ) : undefined
        }
      />

      {isLoading ? (
        <div className="flex justify-center py-12">
          <LoadingSpinner size="lg" />
        </div>
      ) : isError ? (
        <EmptyState
          icon={Users2}
          title="Não foi possível carregar as equipes"
          description={
            teamsError instanceof Error
              ? teamsError.message
              : 'Atualize a página e tente novamente.'
          }
        />
      ) : orderedTeams.length === 0 ? (
        <EmptyState
          icon={Users2}
          title="Nenhuma equipe criada"
          description="Crie equipes vinculadas aos PDVs e supervisores."
        />
      ) : (
        <div className="table-container">
          <div className="overflow-x-auto">
            <table className="w-full">
              <thead>
                <tr className="border-b border-gray-200 bg-gray-50">
                  <th className="table-th">Equipe</th>
                  <th className="table-th hidden sm:table-cell">PDV</th>
                  <th className="table-th hidden md:table-cell">
                    Supervisor
                  </th>
                  <th className="table-th hidden lg:table-cell">
                    Capacidade
                  </th>
                  <th className="table-th">Configuração</th>
                  <th className="table-th text-right">Ações</th>
                </tr>
              </thead>
              <tbody>
                {orderedTeams.map((team) => {
                  const supervisorProfile = getRelatedProfile(
                    team.supervisor?.profiles,
                  )
                  const activeMembers = (team.team_members ?? []).filter(
                    (member) =>
                      member.status === 'active' && !member.archived_at,
                  ).length
                  const plannedCapacity =
                    getPlannedSalespersonCapacity(team.metadata)
                  const confirmed = isSetupConfirmed(team.metadata)

                  return (
                    <tr key={team.id} className="table-tr">
                      <td className="table-td">
                        <div className="font-medium text-gray-900">
                          {team.name}
                        </div>
                        <div className="mt-1 flex flex-wrap gap-1.5">
                          {isTemplateRecord(team.metadata) && (
                            <span className="rounded-full bg-blue-50 px-2 py-0.5 text-xs text-blue-700">
                              Modelo editável
                            </span>
                          )}
                          <StatusBadge status={team.status} />
                        </div>
                      </td>
                      <td className="table-td hidden text-sm text-gray-500 sm:table-cell">
                        {team.sales_location?.name ?? '—'}
                      </td>
                      <td className="table-td hidden text-sm text-gray-500 md:table-cell">
                        {supervisorProfile?.full_name ?? 'A definir'}
                      </td>
                      <td className="table-td hidden text-sm text-gray-600 lg:table-cell">
                        {activeMembers}/{plannedCapacity || '—'} vendedores
                      </td>
                      <td className="table-td">
                        <span
                          className={`inline-flex items-center gap-1 rounded-full px-2 py-1 text-xs font-medium ${
                            confirmed
                              ? 'bg-green-50 text-green-700'
                              : 'bg-amber-50 text-amber-700'
                          }`}
                        >
                          {confirmed ? (
                            <BadgeCheck className="h-3.5 w-3.5" />
                          ) : (
                            <Clock3 className="h-3.5 w-3.5" />
                          )}
                          {confirmed ? 'Confirmada' : 'Pendente'}
                        </span>
                      </td>
                      <td className="table-td text-right">
                        <div className="flex items-center justify-end gap-1">
                          <button
                            onClick={() => setMembersTeam(team)}
                            className="rounded p-1.5 text-gray-400 hover:bg-blue-50 hover:text-blue-600"
                            title="Vendedores da equipe"
                          >
                            <UserPlus className="h-4 w-4" />
                          </button>
                          {canManageTeams && (
                            <button
                              onClick={() => {
                                setEditTeam(team)
                                setFormOpen(true)
                              }}
                              className="rounded p-1.5 text-gray-400 hover:bg-brand-50 hover:text-brand-700"
                              title="Editar"
                            >
                              <Pencil className="h-4 w-4" />
                            </button>
                          )}
                        </div>
                      </td>
                    </tr>
                  )
                })}
              </tbody>
            </table>
          </div>
        </div>
      )}

      <Dialog
        open={formOpen}
        onOpenChange={(open) => {
          setFormOpen(open)
          if (!open) setEditTeam(undefined)
        }}
      >
        <DialogContent>
          <DialogHeader>
            <DialogTitle>
              {editTeam ? 'Editar equipe' : 'Nova equipe'}
            </DialogTitle>
          </DialogHeader>
          <TeamForm
            team={editTeam}
            orgId={orgId}
            onClose={() => {
              setFormOpen(false)
              setEditTeam(undefined)
            }}
          />
        </DialogContent>
      </Dialog>

      <Dialog
        open={!!membersTeam}
        onOpenChange={(open) => {
          if (!open) setMembersTeam(undefined)
        }}
      >
        <DialogContent>
          <DialogHeader>
            <DialogTitle>Vendedores — {membersTeam?.name}</DialogTitle>
          </DialogHeader>
          {membersTeam && (
            <MembersPanel
              team={membersTeam}
              orgId={orgId}
              canManage={canManageTeams}
              onClose={() => setMembersTeam(undefined)}
            />
          )}
        </DialogContent>
      </Dialog>
    </div>
  )
}
