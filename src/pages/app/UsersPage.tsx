import { useEffect, useMemo, useState } from 'react'
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query'
import { useForm } from 'react-hook-form'
import { zodResolver } from '@hookform/resolvers/zod'
import { Plus, UserCog, ToggleLeft, ToggleRight, Mail } from 'lucide-react'
import { toast } from 'sonner'
import { z } from 'zod'
import { supabase } from '@/lib/supabase'
import { FunctionsHttpError } from '@supabase/supabase-js'
import { useAuth } from '@/contexts/AuthContext'
import { usePermissions } from '@/hooks/usePermissions'
import { inviteUserSchema } from '@/lib/validations'
import { formatRelativeDate } from '@/lib/formatters'
import { ROLE_LABELS, ORG_ROLES } from '@/constants/roles'
import PageHeader from '@/components/shared/PageHeader'
import StatusBadge from '@/components/shared/StatusBadge'
import RoleBadge from '@/components/shared/RoleBadge'
import EmptyState from '@/components/shared/EmptyState'
import LoadingSpinner from '@/components/shared/LoadingSpinner'
import SearchInput from '@/components/shared/SearchInput'
import ConfirmDialog from '@/components/shared/ConfirmDialog'
import { Dialog, DialogContent, DialogHeader, DialogTitle } from '@/components/ui/dialog'
import type { OrganizationMember, Profile } from '@/types/database'

type InviteData = z.infer<typeof inviteUserSchema>

type InviteResult = {
  success: boolean
  user_id: string
  membership_id: string
  invite_sent: boolean
  already_member: boolean
  hierarchy_linked?: boolean
  team_id?: string | null
  sales_location_id?: string | null
  message?: string
}

type MemberProfile = Pick<Profile, 'full_name' | 'email' | 'preferred_name' | 'last_access_at'>

type OrganizationMemberRow = OrganizationMember & {
  profile: MemberProfile | null
}

type ProfileRelation = {
  full_name: string | null
}

type InviteTeamOption = {
  id: string
  name: string
  sales_location_id: string | null
  supervisor_member_id: string | null
  sales_location: { name: string } | { name: string }[] | null
  supervisor: {
    user_id: string
    profiles: ProfileRelation | ProfileRelation[] | null
  } | {
    user_id: string
    profiles: ProfileRelation | ProfileRelation[] | null
  }[] | null
}

function firstRelation<T>(relation: T | T[] | null | undefined): T | null {
  if (Array.isArray(relation)) return relation[0] ?? null
  return relation ?? null
}

function InviteForm({
  orgId,
  allowDirectorRole,
  isSupervisor,
  activeMembershipId,
  onClose,
}: {
  orgId: string
  allowDirectorRole: boolean
  isSupervisor: boolean
  activeMembershipId: string | null
  onClose: () => void
}) {
  const qc = useQueryClient()
  const {
    register,
    handleSubmit,
    watch,
    setValue,
    formState: { errors },
  } = useForm<InviteData>({
    resolver: zodResolver(inviteUserSchema),
    defaultValues: {
      role: isSupervisor ? ORG_ROLES.SALESPERSON : undefined,
      team_id: '',
    },
  })

  const selectedRole = watch('role')
  const selectedTeamId = watch('team_id')
  const needsTeamContext =
    selectedRole === ORG_ROLES.SALESPERSON ||
    selectedRole === ORG_ROLES.SUPERVISOR

  const { data: teams, isLoading: teamsLoading } = useQuery({
    queryKey: ['invite-user-teams', orgId, isSupervisor, activeMembershipId],
    enabled:
      !!orgId &&
      needsTeamContext &&
      (!isSupervisor || !!activeMembershipId),
    queryFn: async () => {
      let query = supabase
        .from('teams')
        .select(`
          id,
          name,
          sales_location_id,
          supervisor_member_id,
          sales_location:sales_locations!teams_location_org_operation_fkey(name),
          supervisor:organization_members!teams_supervisor_org_fkey(
            user_id,
            profiles!organization_members_user_id_fkey(full_name)
          )
        `)
        .eq('organization_id', orgId)
        .eq('status', 'active')
        .is('archived_at', null)
        .order('name')

      if (isSupervisor && activeMembershipId) {
        query = query.eq('supervisor_member_id', activeMembershipId)
      }

      const { data, error } = await query
      if (error) throw error
      return (data ?? []) as InviteTeamOption[]
    },
  })

  const eligibleTeams = useMemo(() => {
    if (!needsTeamContext) return []

    return (teams ?? []).filter((team) => {
      if (!team.sales_location_id) return false

      if (selectedRole === ORG_ROLES.SALESPERSON) {
        return !!team.supervisor_member_id
      }

      if (selectedRole === ORG_ROLES.SUPERVISOR) {
        return !team.supervisor_member_id
      }

      return false
    })
  }, [needsTeamContext, selectedRole, teams])

  useEffect(() => {
    if (
      isSupervisor &&
      selectedRole === ORG_ROLES.SALESPERSON &&
      eligibleTeams.length === 1 &&
      !selectedTeamId
    ) {
      setValue('team_id', eligibleTeams[0].id, {
        shouldDirty: false,
        shouldValidate: true,
      })
    }
  }, [eligibleTeams, isSupervisor, selectedRole, selectedTeamId, setValue])

  useEffect(() => {
    if (!needsTeamContext && selectedTeamId) {
      setValue('team_id', '', {
        shouldDirty: false,
        shouldValidate: true,
      })
    }
  }, [needsTeamContext, selectedTeamId, setValue])

  const mutation = useMutation({
    mutationFn: async (data: InviteData) => {
      const role = isSupervisor ? ORG_ROLES.SALESPERSON : data.role

      const { data: result, error } = await supabase.functions.invoke('invite-user', {
        body: {
          email: data.email,
          full_name: data.full_name,
          role,
          organization_id: orgId,
          team_id: data.team_id || null,
        },
      })

      if (error) {
        let message = error.message

        if (error instanceof FunctionsHttpError) {
          try {
            const payload = await error.context?.json() as {
              error?: string
              message?: string
            } | undefined

            message =
              payload?.error ??
              payload?.message ??
              message
          } catch {
            // Mantém a mensagem original quando a resposta não é JSON.
          }
        }

        throw new Error(message)
      }

      return result as InviteResult
    },
    onSuccess: (result) => {
      toast.success(
        result.message ??
          (
            result.invite_sent
              ? 'Convite enviado com sucesso.'
              : 'Vínculo criado com sucesso.'
          ),
      )
      qc.invalidateQueries({ queryKey: ['org-members'] })
      qc.invalidateQueries({ queryKey: ['teams'] })
      qc.invalidateQueries({ queryKey: ['team-members'] })
      qc.invalidateQueries({ queryKey: ['available-salespersons'] })
      qc.invalidateQueries({ queryKey: ['org-stats'] })
      qc.invalidateQueries({ queryKey: ['setup-checklist'] })
      onClose()
    },
    onError: (e: Error) => toast.error(e.message),
  })

  const selectedTeam = eligibleTeams.find((team) => team.id === selectedTeamId)
  const selectedLocation = firstRelation(selectedTeam?.sales_location)
  const selectedSupervisor = firstRelation(selectedTeam?.supervisor)
  const selectedSupervisorProfile = firstRelation(selectedSupervisor?.profiles)

  return (
    <form onSubmit={handleSubmit((d) => mutation.mutate(d))} className="space-y-4">
      <div>
        <label className="form-label">Nome completo *</label>
        <input {...register('full_name')} className="form-input" placeholder="Nome do usuário" />
        {errors.full_name && <p className="form-error">{errors.full_name.message}</p>}
      </div>

      <div>
        <label className="form-label">E-mail *</label>
        <input {...register('email')} type="email" className="form-input" placeholder="usuario@empresa.com" />
        {errors.email && <p className="form-error">{errors.email.message}</p>}
      </div>

      {isSupervisor ? (
        <div className="rounded-lg border border-blue-200 bg-blue-50 p-3">
          <input type="hidden" {...register('role')} />
          <p className="text-sm font-medium text-blue-900">Perfil: {ROLE_LABELS.salesperson}</p>
          <p className="mt-1 text-xs text-blue-700">
            Supervisores podem cadastrar somente vendedores vinculados às próprias equipes.
          </p>
        </div>
      ) : (
        <div>
          <label className="form-label">Perfil de acesso *</label>
          <select {...register('role')} className="form-input">
            <option value="">Selecione...</option>
            {allowDirectorRole && (
              <option value={ORG_ROLES.DIRECTOR}>
                {ROLE_LABELS.director}
              </option>
            )}
            <option value={ORG_ROLES.SUPERVISOR}>{ROLE_LABELS.supervisor}</option>
            <option value={ORG_ROLES.SALESPERSON}>{ROLE_LABELS.salesperson}</option>
          </select>
          {errors.role && <p className="form-error">{errors.role.message}</p>}
        </div>
      )}

      {needsTeamContext && (
        <div>
          <label className="form-label">
            {selectedRole === ORG_ROLES.SALESPERSON
              ? 'Equipe / PDV *'
              : 'Vincular a uma equipe agora'}
          </label>
          <select
            {...register('team_id')}
            className="form-input"
            disabled={teamsLoading}
          >
            <option value="">
              {selectedRole === ORG_ROLES.SALESPERSON
                ? 'Selecione a equipe...'
                : 'Não vincular agora'}
            </option>
            {eligibleTeams.map((team) => {
              const location = firstRelation(team.sales_location)
              const supervisor = firstRelation(team.supervisor)
              const supervisorProfile = firstRelation(supervisor?.profiles)

              return (
                <option key={team.id} value={team.id}>
                  {team.name}
                  {location?.name ? ` — ${location.name}` : ''}
                  {supervisorProfile?.full_name
                    ? ` — ${supervisorProfile.full_name}`
                    : ''}
                </option>
              )
            })}
          </select>
          {errors.team_id && <p className="form-error">{errors.team_id.message}</p>}

          {!teamsLoading && eligibleTeams.length === 0 && (
            <p className="mt-2 text-xs text-amber-700">
              {selectedRole === ORG_ROLES.SALESPERSON
                ? 'Nenhuma equipe ativa com PDV e supervisor configurados está disponível para este cadastro.'
                : 'Nenhuma equipe ativa com PDV e sem supervisor está disponível para vínculo imediato.'}
            </p>
          )}

          {selectedTeam && (
            <div className="mt-2 rounded-md bg-gray-50 p-2 text-xs text-gray-600">
              <span className="font-medium">Hierarquia:</span>{' '}
              {selectedLocation?.name ?? 'PDV não definido'} → {selectedTeam.name}
              {selectedRole === ORG_ROLES.SALESPERSON && (
                <> → {selectedSupervisorProfile?.full_name ?? 'Supervisor não definido'}</>
              )}
            </div>
          )}
        </div>
      )}

      <p className="text-xs text-gray-500 bg-blue-50 p-3 rounded-md">
        O usuário receberá um e-mail de convite com instruções para definir sua senha e acessar o sistema.
      </p>

      <div className="flex gap-3 justify-end pt-2">
        <button type="button" onClick={onClose} className="btn-secondary">Cancelar</button>
        <button type="submit" disabled={mutation.isPending} className="btn-primary">
          <Mail className="h-4 w-4" />
          {mutation.isPending ? 'Enviando...' : 'Enviar convite'}
        </button>
      </div>
    </form>
  )
}

export default function UsersPage() {
  const {
    activeOrganization,
    activeMembership,
    profile,
    isAdmin,
    isSupervisor,
  } = useAuth()
  const { canManageUsers, canInviteUsers } = usePermissions()
  const qc = useQueryClient()
  const [search, setSearch] = useState('')
  const [roleFilter, setRoleFilter] = useState('')
  const [inviteOpen, setInviteOpen] = useState(false)
  const [toggleConfirm, setToggleConfirm] = useState<{ id: string; name: string; status: string } | null>(null)

  const orgId = activeOrganization?.id

  const { data: members, isLoading } = useQuery({
    queryKey: ['org-members', orgId],
    enabled: !!orgId,
    queryFn: async () => {
      let q = supabase
        .from('organization_members')
        .select('*, profile:profiles!organization_members_user_id_fkey(full_name, email, preferred_name, last_access_at)')
        .order('created_at', { ascending: false })

      if (orgId) q = q.eq('organization_id', orgId)

      const { data, error } = await q
      if (error) throw error
      return (data ?? []) as OrganizationMemberRow[]
    },
  })

  const toggleMutation = useMutation({
    mutationFn: async ({ id, currentStatus }: { id: string; currentStatus: string }) => {
      const newStatus = currentStatus === 'active' ? 'inactive' : 'active'
      const { error } = await supabase
        .from('organization_members')
        .update({ status: newStatus, updated_by: profile?.id })
        .eq('id', id)

      if (error) throw error
    },
    onSuccess: (_, vars) => {
      toast.success(`Usuário ${vars.currentStatus === 'active' ? 'inativado' : 'ativado'}.`)
      qc.invalidateQueries({ queryKey: ['org-members'] })
    },
    onError: (e: Error) => toast.error(e.message),
  })

  const visibleMembers = useMemo(
    () =>
      isSupervisor
        ? (members ?? []).filter((member) => member.role === ORG_ROLES.SALESPERSON)
        : (members ?? []),
    [isSupervisor, members],
  )

  const filtered = visibleMembers.filter((m) => {
    const memberProfile = m.profile
    const name = memberProfile?.full_name?.toLowerCase() ?? ''
    const email = memberProfile?.email?.toLowerCase() ?? ''
    const matchSearch = !search || name.includes(search.toLowerCase()) || email.includes(search.toLowerCase())
    const matchRole = !roleFilter || m.role === roleFilter
    return matchSearch && matchRole
  })

  if (!orgId) {
    return (
      <div className="page-container">
        <EmptyState icon={UserCog} title="Nenhuma organização ativa" />
      </div>
    )
  }

  return (
    <div className="page-container">
      <PageHeader
        title={isSupervisor ? 'Minha equipe' : 'Usuários'}
        description={
          isSupervisor
            ? 'Consulte e cadastre vendedores vinculados às equipes sob sua responsabilidade.'
            : 'Gerencie os usuários, perfis de acesso e vínculos da organização.'
        }
        action={canInviteUsers ? (
          <button onClick={() => setInviteOpen(true)} className="btn-primary">
            <Plus className="h-4 w-4" />
            {isSupervisor ? 'Cadastrar vendedor' : 'Convidar usuário'}
          </button>
        ) : undefined}
      />

      <div className="table-container">
        <div className="table-header flex-wrap gap-2">
          <SearchInput
            value={search}
            onChange={setSearch}
            placeholder="Pesquisar por nome ou e-mail..."
            className="flex-1 min-w-48"
          />
          {!isSupervisor && (
            <select
              value={roleFilter}
              onChange={(event) => setRoleFilter(event.target.value)}
              className="form-input w-auto text-sm h-9"
            >
              <option value="">Todos os perfis</option>
              <option value="director">{ROLE_LABELS.director}</option>
              <option value="supervisor">{ROLE_LABELS.supervisor}</option>
              <option value="salesperson">{ROLE_LABELS.salesperson}</option>
            </select>
          )}
          <span className="ml-auto text-xs text-gray-500 self-center">
            {filtered.length} {isSupervisor ? 'vendedor(es)' : 'usuário(s)'}
          </span>
        </div>

        {isLoading ? (
          <div className="py-12 flex justify-center"><LoadingSpinner /></div>
        ) : filtered.length === 0 ? (
          <EmptyState
            icon={UserCog}
            title={isSupervisor ? 'Nenhum vendedor vinculado' : 'Nenhum usuário encontrado'}
            description={
              isSupervisor
                ? 'Cadastre o primeiro vendedor da sua equipe.'
                : 'Convide o primeiro usuário para começar.'
            }
          />
        ) : (
          <div className="overflow-x-auto">
            <table className="w-full">
              <thead>
                <tr className="border-b border-gray-200 bg-gray-50">
                  <th className="table-th">Usuário</th>
                  <th className="table-th">Perfil</th>
                  <th className="table-th">Status</th>
                  <th className="table-th hidden md:table-cell">Último acesso</th>
                  <th className="table-th text-right">Ações</th>
                </tr>
              </thead>
              <tbody>
                {filtered.map((m) => {
                  const p = m.profile
                  const displayName = p?.full_name ?? m.user_id
                  return (
                    <tr key={m.id} className="table-tr">
                      <td className="table-td">
                        <div className="flex items-center gap-3">
                          <div className="w-8 h-8 rounded-full bg-brand-100 flex items-center justify-center shrink-0">
                            <span className="text-xs font-semibold text-brand-700">
                              {displayName.slice(0, 2).toUpperCase()}
                            </span>
                          </div>
                          <div>
                            <p className="font-medium text-gray-900 text-sm">{displayName}</p>
                            <p className="text-xs text-gray-500">{p?.email ?? '—'}</p>
                          </div>
                        </div>
                      </td>
                      <td className="table-td"><RoleBadge role={m.role} /></td>
                      <td className="table-td"><StatusBadge status={m.status} /></td>
                      <td className="table-td hidden md:table-cell text-gray-500 text-xs">
                        {formatRelativeDate(p?.last_access_at)}
                      </td>
                      <td className="table-td text-right">
                        {canManageUsers && m.user_id !== profile?.id && (
                          <button
                            onClick={() => setToggleConfirm({ id: m.id, name: displayName, status: m.status })}
                            className={`p-1.5 rounded text-sm ${m.status === 'active' ? 'text-gray-400 hover:text-yellow-600 hover:bg-yellow-50' : 'text-gray-400 hover:text-green-600 hover:bg-green-50'}`}
                            title={m.status === 'active' ? 'Inativar' : 'Ativar'}
                          >
                            {m.status === 'active'
                              ? <ToggleRight className="h-5 w-5" />
                              : <ToggleLeft className="h-5 w-5" />}
                          </button>
                        )}
                      </td>
                    </tr>
                  )
                })}
              </tbody>
            </table>
          </div>
        )}
      </div>

      <Dialog open={inviteOpen} onOpenChange={setInviteOpen}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle>
              {isSupervisor ? 'Cadastrar vendedor' : 'Convidar usuário'}
            </DialogTitle>
          </DialogHeader>
          <InviteForm
            orgId={orgId}
            allowDirectorRole={isAdmin}
            isSupervisor={isSupervisor}
            activeMembershipId={activeMembership?.id ?? null}
            onClose={() => setInviteOpen(false)}
          />
        </DialogContent>
      </Dialog>

      <ConfirmDialog
        open={!!toggleConfirm}
        title={toggleConfirm?.status === 'active' ? 'Inativar usuário?' : 'Ativar usuário?'}
        description={`Esta ação alterará o acesso de "${toggleConfirm?.name}" ao sistema.`}
        onConfirm={() => {
          if (toggleConfirm) {
            toggleMutation.mutate({
              id: toggleConfirm.id,
              currentStatus: toggleConfirm.status,
            })
          }
          setToggleConfirm(null)
        }}
        onCancel={() => setToggleConfirm(null)}
      />
    </div>
  )
}
