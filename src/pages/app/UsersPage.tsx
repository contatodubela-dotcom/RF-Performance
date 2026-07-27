import { useState } from 'react'
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
import { formatDateTime, formatRelativeDate } from '@/lib/formatters'
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

type MemberProfile = Pick<Profile, 'full_name' | 'email' | 'preferred_name' | 'last_access_at'>

type OrganizationMemberRow = OrganizationMember & {
  profile: MemberProfile | null
}

function InviteForm({ orgId, onClose }: { orgId: string; onClose: () => void }) {
  const qc = useQueryClient()
  const { register, handleSubmit, formState: { errors } } = useForm<InviteData>({
    resolver: zodResolver(inviteUserSchema),
  })

  const mutation = useMutation({
    mutationFn: async (data: InviteData) => {
      const { data: result, error } = await supabase.functions.invoke('invite-user', {
        body: { email: data.email, full_name: data.full_name, role: data.role, organization_id: orgId },
      })
      if (error) {
        let msg = error.message
        if (error instanceof FunctionsHttpError) {
          try { const t = await error.context?.text(); msg = t || msg } catch { /* */ }
        }
        throw new Error(msg)
      }
      return result
    },
    onSuccess: () => {
      toast.success('Convite enviado com sucesso. O usuário receberá um e-mail de acesso.')
      qc.invalidateQueries({ queryKey: ['org-members'] })
      onClose()
    },
    onError: (e: Error) => toast.error(e.message),
  })

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
      <div>
        <label className="form-label">Perfil de acesso *</label>
        <select {...register('role')} className="form-input">
          <option value="">Selecione...</option>
          <option value={ORG_ROLES.DIRECTOR}>{ROLE_LABELS.director}</option>
          <option value={ORG_ROLES.SUPERVISOR}>{ROLE_LABELS.supervisor}</option>
          <option value={ORG_ROLES.SALESPERSON}>{ROLE_LABELS.salesperson}</option>
        </select>
        {errors.role && <p className="form-error">{errors.role.message}</p>}
      </div>
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
  const { activeOrganization, profile, isAdmin } = useAuth()
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
      if (!isAdmin && orgId) q = q.eq('organization_id', orgId)
      else if (orgId) q = q.eq('organization_id', orgId)
      const { data, error } = await q
      if (error) throw error
      return (data ?? []) as OrganizationMemberRow[]
    },
  })

  const toggleMutation = useMutation({
    mutationFn: async ({ id, currentStatus }: { id: string; currentStatus: string }) => {
      const newStatus = currentStatus === 'active' ? 'inactive' : 'active'
      const { error } = await supabase.from('organization_members').update({ status: newStatus, updated_by: profile?.id }).eq('id', id)
      if (error) throw error
    },
    onSuccess: (_, vars) => {
      toast.success(`Usuário ${vars.currentStatus === 'active' ? 'inativado' : 'ativado'}.`)
      qc.invalidateQueries({ queryKey: ['org-members'] })
    },
    onError: (e: Error) => toast.error(e.message),
  })

  const filtered = members?.filter(m => {
    const memberProfile = m.profile
    const name = memberProfile?.full_name?.toLowerCase() ?? ''
    const email = memberProfile?.email?.toLowerCase() ?? ''
    const matchSearch = !search || name.includes(search.toLowerCase()) || email.includes(search.toLowerCase())
    const matchRole = !roleFilter || m.role === roleFilter
    return matchSearch && matchRole
  }) ?? []

  if (!orgId) return <div className="page-container"><EmptyState icon={UserCog} title="Nenhuma organização ativa" /></div>

  return (
    <div className="page-container">
      <PageHeader
        title="Usuários"
        description="Gerencie os usuários e perfis de acesso da organização."
        action={canInviteUsers ? (
          <button onClick={() => setInviteOpen(true)} className="btn-primary">
            <Plus className="h-4 w-4" /> Convidar usuário
          </button>
        ) : undefined}
      />

      <div className="table-container">
        <div className="table-header flex-wrap gap-2">
          <SearchInput value={search} onChange={setSearch} placeholder="Pesquisar por nome ou e-mail..." className="flex-1 min-w-48" />
          <select
            value={roleFilter}
            onChange={e => setRoleFilter(e.target.value)}
            className="form-input w-auto text-sm h-9"
          >
            <option value="">Todos os perfis</option>
            <option value="director">{ROLE_LABELS.director}</option>
            <option value="supervisor">{ROLE_LABELS.supervisor}</option>
            <option value="salesperson">{ROLE_LABELS.salesperson}</option>
          </select>
          <span className="ml-auto text-xs text-gray-500 self-center">{filtered.length} usuário(s)</span>
        </div>

        {isLoading ? (
          <div className="py-12 flex justify-center"><LoadingSpinner /></div>
        ) : filtered.length === 0 ? (
          <EmptyState icon={UserCog} title="Nenhum usuário encontrado" description="Convide o primeiro usuário para começar." />
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
                            {m.status === 'active' ? <ToggleRight className="h-5 w-5" /> : <ToggleLeft className="h-5 w-5" />}
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
          <DialogHeader><DialogTitle>Convidar usuário</DialogTitle></DialogHeader>
          <InviteForm orgId={orgId} onClose={() => setInviteOpen(false)} />
        </DialogContent>
      </Dialog>

      <ConfirmDialog
        open={!!toggleConfirm}
        title={toggleConfirm?.status === 'active' ? 'Inativar usuário?' : 'Ativar usuário?'}
        description={`Esta ação alterará o acesso de "${toggleConfirm?.name}" ao sistema.`}
        onConfirm={() => {
          if (toggleConfirm) toggleMutation.mutate({ id: toggleConfirm.id, currentStatus: toggleConfirm.status })
          setToggleConfirm(null)
        }}
        onCancel={() => setToggleConfirm(null)}
      />
    </div>
  )
}
