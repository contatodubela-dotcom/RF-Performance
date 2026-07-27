import { useState } from 'react'
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query'
import { useForm } from 'react-hook-form'
import { zodResolver } from '@hookform/resolvers/zod'
import { Plus, Pencil, Users2, UserMinus, UserPlus } from 'lucide-react'
import { toast } from 'sonner'
import { z } from 'zod'
import { supabase } from '@/lib/supabase'
import { useAuth } from '@/contexts/AuthContext'
import { usePermissions } from '@/hooks/usePermissions'
import { teamSchema } from '@/lib/validations'
import type { Team, Operation, SalesLocation, OrganizationMember, Profile } from '@/types/database'
import PageHeader from '@/components/shared/PageHeader'
import StatusBadge from '@/components/shared/StatusBadge'
import EmptyState from '@/components/shared/EmptyState'
import LoadingSpinner from '@/components/shared/LoadingSpinner'
import { Dialog, DialogContent, DialogHeader, DialogTitle } from '@/components/ui/dialog'
import { ROLE_LABELS } from '@/constants/roles'

type FormData = z.infer<typeof teamSchema>

interface MemberWithProfile extends OrganizationMember { profile?: Profile }

function TeamForm({ team, orgId, onClose }: { team?: Team; orgId: string; onClose: () => void }) {
  const { profile } = useAuth()
  const qc = useQueryClient()

  const { data: operations } = useQuery({
    queryKey: ['operations', orgId], queryFn: async () => {
      const { data } = await supabase.from('operations').select('id, name').eq('organization_id', orgId).eq('status', 'active')
      return data ?? []
    }
  })

  const { data: locations } = useQuery({
    queryKey: ['sales-locations', orgId], queryFn: async () => {
      const { data } = await supabase.from('sales_locations').select('id, name').eq('organization_id', orgId).eq('status', 'active')
      return data ?? []
    }
  })

  const { data: supervisors } = useQuery({
    queryKey: ['supervisors', orgId], queryFn: async () => {
      const { data } = await supabase.from('organization_members').select('id, user_id, profiles!organization_members_user_id_fkey(full_name)').eq('organization_id', orgId).eq('role', 'supervisor').eq('status', 'active')
      return data ?? []
    }
  })

  const { register, handleSubmit, formState: { errors } } = useForm<FormData>({
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
      const payload = {
        organization_id: orgId,
        operation_id: data.operation_id,
        sales_location_id: data.sales_location_id || null,
        supervisor_member_id: data.supervisor_member_id || null,
        name: data.name,
        description: data.description || null,
        updated_by: profile?.id,
      }
      if (team) {
        const { error } = await supabase.from('teams').update(payload).eq('id', team.id)
        if (error) throw error
      } else {
        const { error } = await supabase.from('teams').insert({ ...payload, created_by: profile?.id })
        if (error) throw error
      }
    },
    onSuccess: () => {
      toast.success(team ? 'Equipe atualizada.' : 'Equipe criada.')
      qc.invalidateQueries({ queryKey: ['teams'] })
      onClose()
    },
    onError: (e: Error) => toast.error(e.message),
  })

  return (
    <form onSubmit={handleSubmit((d) => mutation.mutate(d))} className="space-y-4">
      <div>
        <label className="form-label">Nome da equipe *</label>
        <input {...register('name')} className="form-input" placeholder="Ex: Equipe PDV 1" />
        {errors.name && <p className="form-error">{errors.name.message}</p>}
      </div>
      <div className="grid grid-cols-2 gap-4">
        <div>
          <label className="form-label">Operação *</label>
          <select {...register('operation_id')} className="form-input">
            <option value="">Selecione...</option>
            {operations?.map((op: { id: string; name: string }) => <option key={op.id} value={op.id}>{op.name}</option>)}
          </select>
          {errors.operation_id && <p className="form-error">{errors.operation_id.message}</p>}
        </div>
        <div>
          <label className="form-label">PDV</label>
          <select {...register('sales_location_id')} className="form-input">
            <option value="">Nenhum</option>
            {locations?.map((loc: { id: string; name: string }) => <option key={loc.id} value={loc.id}>{loc.name}</option>)}
          </select>
        </div>
      </div>
      <div>
        <label className="form-label">Supervisor</label>
        <select {...register('supervisor_member_id')} className="form-input">
          <option value="">Sem supervisor</option>
          {supervisors?.map((s: any) => (
            <option key={s.id} value={s.id}>{s.profiles?.full_name ?? s.user_id}</option>
          ))}
        </select>
      </div>
      <div>
        <label className="form-label">Descrição</label>
        <textarea {...register('description')} className="form-input" rows={2} placeholder="Opcional" />
      </div>
      <div className="flex gap-3 justify-end pt-2">
        <button type="button" onClick={onClose} className="btn-secondary">Cancelar</button>
        <button type="submit" disabled={mutation.isPending} className="btn-primary">
          {mutation.isPending ? 'Salvando...' : team ? 'Salvar' : 'Criar equipe'}
        </button>
      </div>
    </form>
  )
}

export default function TeamsPage() {
  const { activeOrganization, profile, isAdmin } = useAuth()
  const { canManageTeams } = usePermissions()
  const qc = useQueryClient()
  const [formOpen, setFormOpen] = useState(false)
  const [editTeam, setEditTeam] = useState<Team | undefined>()
  const [membersTeam, setMembersTeam] = useState<Team | undefined>()

  const orgId = activeOrganization?.id

  const { data: teams, isLoading } = useQuery({
    queryKey: ['teams', orgId],
    enabled: !!orgId,
    queryFn: async () => {
      let q = supabase.from('teams').select(`
        *,
        sales_location:sales_locations(name),
        supervisor:organization_members!supervisor_member_id(user_id, profiles!organization_members_user_id_fkey(full_name))
      `).order('name')
      if (!isAdmin && orgId) q = q.eq('organization_id', orgId)
      const { data, error } = await q
      if (error) throw error
      return data
    },
  })

  const { data: teamMembers, isLoading: membersLoading } = useQuery({
    queryKey: ['team-members', membersTeam?.id],
    enabled: !!membersTeam,
    queryFn: async () => {
      const { data, error } = await supabase
        .from('team_members')
        .select('*, organization_member:organization_members(user_id, role, profiles!organization_members_user_id_fkey(full_name, email))')
        .eq('team_id', membersTeam!.id)
        .eq('status', 'active')
      if (error) throw error
      return data
    },
  })

  const removeMemberMutation = useMutation({
    mutationFn: async (tmId: string) => {
      const { error } = await supabase.from('team_members').update({ status: 'inactive', updated_by: profile?.id }).eq('id', tmId)
      if (error) throw error
    },
    onSuccess: () => { toast.success('Membro removido da equipe.'); qc.invalidateQueries({ queryKey: ['team-members'] }) },
    onError: (e: Error) => toast.error(e.message),
  })

  if (!orgId) return <div className="page-container"><EmptyState icon={Users2} title="Nenhuma organização ativa" /></div>

  return (
    <div className="page-container">
      <PageHeader
        title="Equipes"
        description="Crie e gerencie equipes vinculadas às operações e PDVs."
        action={canManageTeams ? (
          <button onClick={() => { setEditTeam(undefined); setFormOpen(true) }} className="btn-primary">
            <Plus className="h-4 w-4" /> Nova equipe
          </button>
        ) : undefined}
      />

      {isLoading ? (
        <div className="flex justify-center py-12"><LoadingSpinner size="lg" /></div>
      ) : (teams?.length ?? 0) === 0 ? (
        <EmptyState icon={Users2} title="Nenhuma equipe criada" description="Crie equipes vinculadas aos PDVs e supervisores." />
      ) : (
        <div className="table-container">
          <div className="overflow-x-auto">
            <table className="w-full">
              <thead>
                <tr className="border-b border-gray-200 bg-gray-50">
                  <th className="table-th">Equipe</th>
                  <th className="table-th hidden sm:table-cell">PDV</th>
                  <th className="table-th hidden md:table-cell">Supervisor</th>
                  <th className="table-th">Status</th>
                  <th className="table-th text-right">Ações</th>
                </tr>
              </thead>
              <tbody>
                {teams?.map((team: any) => (
                  <tr key={team.id} className="table-tr">
                    <td className="table-td">
                      <div className="font-medium text-gray-900">{team.name}</div>
                      {team.description && <div className="text-xs text-gray-400">{team.description}</div>}
                    </td>
                    <td className="table-td hidden sm:table-cell text-gray-500 text-sm">{team.sales_location?.name ?? '—'}</td>
                    <td className="table-td hidden md:table-cell text-gray-500 text-sm">
                      {team.supervisor?.profiles?.full_name ?? '—'}
                    </td>
                    <td className="table-td"><StatusBadge status={team.status} /></td>
                    <td className="table-td text-right">
                      <div className="flex items-center justify-end gap-1">
                        <button onClick={() => setMembersTeam(team)} className="p-1.5 rounded text-gray-400 hover:text-blue-600 hover:bg-blue-50" title="Membros">
                          <UserPlus className="h-4 w-4" />
                        </button>
                        {canManageTeams && (
                          <button onClick={() => { setEditTeam(team); setFormOpen(true) }} className="p-1.5 rounded text-gray-400 hover:text-brand-700 hover:bg-brand-50" title="Editar">
                            <Pencil className="h-4 w-4" />
                          </button>
                        )}
                      </div>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </div>
      )}

      {/* Form dialog */}
      <Dialog open={formOpen} onOpenChange={setFormOpen}>
        <DialogContent>
          <DialogHeader><DialogTitle>{editTeam ? 'Editar equipe' : 'Nova equipe'}</DialogTitle></DialogHeader>
          <TeamForm team={editTeam} orgId={orgId} onClose={() => setFormOpen(false)} />
        </DialogContent>
      </Dialog>

      {/* Members dialog */}
      <Dialog open={!!membersTeam} onOpenChange={() => setMembersTeam(undefined)}>
        <DialogContent>
          <DialogHeader><DialogTitle>Membros — {membersTeam?.name}</DialogTitle></DialogHeader>
          {membersLoading ? (
            <div className="py-8 flex justify-center"><LoadingSpinner /></div>
          ) : (teamMembers?.length ?? 0) === 0 ? (
            <div className="py-8 text-center text-sm text-gray-500">
              Nenhum membro ativo nesta equipe.
            </div>
          ) : (
            <ul className="divide-y divide-gray-100">
              {teamMembers?.map((tm: any) => (
                <li key={tm.id} className="flex items-center justify-between py-3">
                  <div>
                    <p className="text-sm font-medium text-gray-900">{tm.organization_member?.profiles?.full_name ?? '—'}</p>
                    <p className="text-xs text-gray-500">{ROLE_LABELS[tm.organization_member?.role] ?? tm.organization_member?.role}</p>
                  </div>
                  {canManageTeams && (
                    <button onClick={() => removeMemberMutation.mutate(tm.id)} className="p-1.5 rounded text-gray-400 hover:text-red-600 hover:bg-red-50">
                      <UserMinus className="h-4 w-4" />
                    </button>
                  )}
                </li>
              ))}
            </ul>
          )}
        </DialogContent>
      </Dialog>
    </div>
  )
}
