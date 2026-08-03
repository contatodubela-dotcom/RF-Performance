import { useState } from 'react'
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query'
import { useForm } from 'react-hook-form'
import { zodResolver } from '@hookform/resolvers/zod'
import { Plus, Pencil, ArchiveX, Archive, Building2 } from 'lucide-react'
import { toast } from 'sonner'
import { supabase } from '@/lib/supabase'
import { useAuth } from '@/contexts/AuthContext'
import { usePermissions } from '@/hooks/usePermissions'
import { organizationSchema } from '@/lib/validations'
import { generateSlug } from '@/lib/utils'
import { formatDateTime } from '@/lib/formatters'
import { type Organization } from '@/types/database'
import PageHeader from '@/components/shared/PageHeader'
import StatusBadge from '@/components/shared/StatusBadge'
import EmptyState from '@/components/shared/EmptyState'
import LoadingSpinner from '@/components/shared/LoadingSpinner'
import SearchInput from '@/components/shared/SearchInput'
import ConfirmDialog from '@/components/shared/ConfirmDialog'
import { Dialog, DialogContent, DialogHeader, DialogTitle } from '@/components/ui/dialog'
import { z } from 'zod'

type OrganizationManagement = Omit<Organization, 'metadata'>

type FormData = z.infer<typeof organizationSchema>

function OrgForm({
  org,
  onClose,
}: {
  org?: OrganizationManagement
  onClose: () => void
}) {
  const { profile } = useAuth()
  const qc = useQueryClient()
  const isEdit = !!org

  const { register, handleSubmit, setValue, watch, formState: { errors } } = useForm<FormData>({
    resolver: zodResolver(organizationSchema),
    defaultValues: {
      trade_name: org?.trade_name ?? '',
      legal_name: org?.legal_name ?? '',
      slug: org?.slug ?? '',
      document_number: org?.document_number ?? '',
      email: org?.email ?? '',
      phone: org?.phone ?? '',
    },
  })

  const tradeName = watch('trade_name')

  const mutation = useMutation({
    mutationFn: async (data: FormData) => {
      const payload = {
        ...data,
        legal_name: data.legal_name || null,
        document_number: data.document_number || null,
        email: data.email || null,
        phone: data.phone || null,
        updated_by: profile?.id,
      }
      if (isEdit) {
        const { error } = await supabase.from('organizations').update(payload).eq('id', org!.id)
        if (error) throw error
      } else {
        const { error } = await supabase.from('organizations').insert({ ...payload, created_by: profile?.id })
        if (error) throw error
      }
    },
    onSuccess: () => {
      toast.success(isEdit ? 'Organização atualizada.' : 'Organização criada.')
      qc.invalidateQueries({ queryKey: ['organizations'] })
      onClose()
    },
    onError: (e: Error) => toast.error(e.message),
  })

  const handleTradeNameBlur = () => {
    if (!isEdit && tradeName) setValue('slug', generateSlug(tradeName))
  }

  return (
    <form onSubmit={handleSubmit((d) => mutation.mutate(d))} className="space-y-4">
      <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
        <div className="sm:col-span-2">
          <label className="form-label">Nome fantasia *</label>
          <input {...register('trade_name')} className="form-input" onBlur={handleTradeNameBlur} placeholder="Ex: RF Consórcios" />
          {errors.trade_name && <p className="form-error">{errors.trade_name.message}</p>}
        </div>
        <div>
          <label className="form-label">Razão social</label>
          <input {...register('legal_name')} className="form-input" placeholder="Razão social (opcional)" />
          {errors.legal_name && <p className="form-error">{errors.legal_name.message}</p>}
        </div>
        <div>
          <label className="form-label">Slug *</label>
          <input {...register('slug')} className="form-input font-mono text-xs" placeholder="rf-consorcios" />
          {errors.slug && <p className="form-error">{errors.slug.message}</p>}
        </div>
        <div>
          <label className="form-label">CNPJ</label>
          <input {...register('document_number')} className="form-input" placeholder="00.000.000/0001-00" />
        </div>
        <div>
          <label className="form-label">E-mail</label>
          <input {...register('email')} type="email" className="form-input" placeholder="contato@empresa.com" />
          {errors.email && <p className="form-error">{errors.email.message}</p>}
        </div>
        <div>
          <label className="form-label">Telefone</label>
          <input {...register('phone')} className="form-input" placeholder="(11) 99999-9999" />
        </div>
      </div>

      <div className="flex gap-3 pt-2 justify-end">
        <button type="button" onClick={onClose} className="btn-secondary">Cancelar</button>
        <button type="submit" disabled={mutation.isPending} className="btn-primary">
          {mutation.isPending ? 'Salvando...' : isEdit ? 'Salvar alterações' : 'Criar organização'}
        </button>
      </div>
    </form>
  )
}

export default function OrganizationsPage() {
  const { canManageOrganizations } = usePermissions()
  const qc = useQueryClient()
  const [search, setSearch] = useState('')
  const [formOpen, setFormOpen] = useState(false)
  const [editOrg, setEditOrg] =
    useState<OrganizationManagement | undefined>()
  const [confirmAction, setConfirmAction] = useState<{
    org: OrganizationManagement
    action: string
  } | null>(null)

  const { data: orgs, isLoading } = useQuery({
    queryKey: ['organizations'],
    queryFn: async () => {
      const { data, error } = await supabase.rpc(
        'list_organizations_for_platform_admin' as never,
      )
      if (error) throw error
      return (data ?? []) as unknown as
        OrganizationManagement[]
    },
  })

  const statusMutation = useMutation({
    mutationFn: async ({
      org,
      action,
    }: {
      org: OrganizationManagement
      action: string
    }) => {
      let update: Partial<OrganizationManagement> = {}
      if (action === 'activate') update = { status: 'active', archived_at: null }
      else if (action === 'inactivate') update = { status: 'inactive' }
      else if (action === 'archive') update = { status: 'archived', archived_at: new Date().toISOString() }
      const { error } = await supabase.from('organizations').update(update).eq('id', org.id)
      if (error) throw error
    },
    onSuccess: (_, vars) => {
      const labels: Record<string, string> = { activate: 'ativada', inactivate: 'inativada', archive: 'arquivada' }
      toast.success(`Organização ${labels[vars.action]}.`)
      qc.invalidateQueries({ queryKey: ['organizations'] })
    },
    onError: (e: Error) => toast.error(e.message),
  })

  const filtered = orgs?.filter(o =>
    !search || o.trade_name.toLowerCase().includes(search.toLowerCase()) || o.slug.includes(search.toLowerCase())
  ) ?? []

  if (!canManageOrganizations) {
    return (
      <div className="page-container">
        <EmptyState icon={Building2} title="Acesso restrito" description="Somente Administradores da Plataforma podem gerenciar organizações." />
      </div>
    )
  }

  return (
    <div className="page-container">
      <PageHeader
        title="Organizações"
        description="Gerencie as organizações cadastradas na plataforma."
        action={
          <button onClick={() => { setEditOrg(undefined); setFormOpen(true) }} className="btn-primary">
            <Plus className="h-4 w-4" /> Nova organização
          </button>
        }
      />

      <div className="table-container">
        <div className="table-header">
          <SearchInput value={search} onChange={setSearch} placeholder="Pesquisar organizações..." className="w-64" />
          <span className="ml-auto text-xs text-gray-500">{filtered.length} registro(s)</span>
        </div>

        {isLoading ? (
          <div className="py-12 flex justify-center"><LoadingSpinner size="md" /></div>
        ) : filtered.length === 0 ? (
          <EmptyState icon={Building2} title="Nenhuma organização encontrada" description="Crie a primeira organização para começar." />
        ) : (
          <div className="overflow-x-auto">
            <table className="w-full">
              <thead>
                <tr className="border-b border-gray-200 bg-gray-50">
                  <th className="table-th">Nome fantasia</th>
                  <th className="table-th">Slug</th>
                  <th className="table-th hidden sm:table-cell">E-mail</th>
                  <th className="table-th">Status</th>
                  <th className="table-th hidden md:table-cell">Criado em</th>
                  <th className="table-th text-right">Ações</th>
                </tr>
              </thead>
              <tbody>
                {filtered.map(org => (
                  <tr key={org.id} className="table-tr">
                    <td className="table-td font-medium">{org.trade_name}</td>
                    <td className="table-td font-mono text-xs text-gray-500">{org.slug}</td>
                    <td className="table-td hidden sm:table-cell text-gray-500">{org.email ?? '—'}</td>
                    <td className="table-td"><StatusBadge status={org.status} /></td>
                    <td className="table-td hidden md:table-cell text-gray-500 text-xs">{formatDateTime(org.created_at)}</td>
                    <td className="table-td text-right">
                      <div className="flex items-center justify-end gap-1">
                        <button onClick={() => { setEditOrg(org); setFormOpen(true) }} className="p-1.5 rounded text-gray-400 hover:text-brand-700 hover:bg-brand-50" title="Editar">
                          <Pencil className="h-4 w-4" />
                        </button>
                        {org.status === 'active' && (
                          <button onClick={() => setConfirmAction({ org, action: 'inactivate' })} className="p-1.5 rounded text-gray-400 hover:text-yellow-600 hover:bg-yellow-50" title="Inativar">
                            <ArchiveX className="h-4 w-4" />
                          </button>
                        )}
                        {org.status === 'inactive' && (
                          <button onClick={() => setConfirmAction({ org, action: 'activate' })} className="p-1.5 rounded text-gray-400 hover:text-green-600 hover:bg-green-50" title="Ativar">
                            <Archive className="h-4 w-4" />
                          </button>
                        )}
                        {org.status !== 'archived' && (
                          <button onClick={() => setConfirmAction({ org, action: 'archive' })} className="p-1.5 rounded text-gray-400 hover:text-red-600 hover:bg-red-50" title="Arquivar">
                            <Archive className="h-4 w-4" />
                          </button>
                        )}
                      </div>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}
      </div>

      {/* Form dialog */}
      <Dialog open={formOpen} onOpenChange={setFormOpen}>
        <DialogContent className="max-w-2xl">
          <DialogHeader>
            <DialogTitle>{editOrg ? 'Editar organização' : 'Nova organização'}</DialogTitle>
          </DialogHeader>
          <OrgForm org={editOrg} onClose={() => setFormOpen(false)} />
        </DialogContent>
      </Dialog>

      {/* Confirm dialog */}
      <ConfirmDialog
        open={!!confirmAction}
        title={confirmAction?.action === 'archive' ? 'Arquivar organização?' : confirmAction?.action === 'activate' ? 'Ativar organização?' : 'Inativar organização?'}
        description={`Esta ação será aplicada à organização "${confirmAction?.org.trade_name}".`}
        confirmLabel="Confirmar"
        variant={confirmAction?.action === 'archive' ? 'destructive' : 'default'}
        onConfirm={() => { if (confirmAction) statusMutation.mutate(confirmAction); setConfirmAction(null) }}
        onCancel={() => setConfirmAction(null)}
      />
    </div>
  )
}
