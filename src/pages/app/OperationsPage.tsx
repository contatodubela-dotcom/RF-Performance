import { useState } from 'react'
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query'
import { useForm } from 'react-hook-form'
import { zodResolver } from '@hookform/resolvers/zod'
import { Plus, Pencil, Archive, RotateCcw } from 'lucide-react'
import { toast } from 'sonner'
import { z } from 'zod'
import { supabase } from '@/lib/supabase'
import { useAuth } from '@/contexts/AuthContext'
import { usePermissions } from '@/hooks/usePermissions'
import { operationSchema } from '@/lib/validations'
import { generateSlug } from '@/lib/utils'
import { formatDateTime } from '@/lib/formatters'
import { OPERATION_TYPE_LABELS } from '@/constants/roles'
import type { Operation } from '@/types/database'
import PageHeader from '@/components/shared/PageHeader'
import StatusBadge from '@/components/shared/StatusBadge'
import EmptyState from '@/components/shared/EmptyState'
import LoadingSpinner from '@/components/shared/LoadingSpinner'
import SearchInput from '@/components/shared/SearchInput'
import ConfirmDialog from '@/components/shared/ConfirmDialog'
import { Dialog, DialogContent, DialogHeader, DialogTitle } from '@/components/ui/dialog'
import { Briefcase } from 'lucide-react'

type FormData = z.infer<typeof operationSchema>

function OpForm({ op, orgId, onClose }: { op?: Operation; orgId: string; onClose: () => void }) {
  const { profile } = useAuth()
  const qc = useQueryClient()

  const { register, handleSubmit, setValue, watch, formState: { errors } } = useForm<FormData>({
    resolver: zodResolver(operationSchema),
    defaultValues: {
      name: op?.name ?? '',
      slug: op?.slug ?? '',
      description: op?.description ?? '',
      operation_type: op?.operation_type ?? '',
    },
  })

  const name = watch('name')

  const mutation = useMutation({
    mutationFn: async (data: FormData) => {
      const payload = {
        ...data,
        organization_id: orgId,
        description: data.description || null,
        operation_type: data.operation_type || null,
        updated_by: profile?.id,
      }
      if (op) {
        const { error } = await supabase
          .from('operations')
          .update(payload)
          .eq('id', op.id)
          .eq('organization_id', orgId)
        if (error) throw error
      } else {
        const { error } = await supabase.from('operations').insert({ ...payload, created_by: profile?.id })
        if (error) throw error
      }
    },
    onSuccess: () => {
      toast.success(op ? 'Operação atualizada.' : 'Operação criada.')
      qc.invalidateQueries({ queryKey: ['operations'] })
      onClose()
    },
    onError: (e: Error) => toast.error(e.message),
  })

  return (
    <form onSubmit={handleSubmit((d) => mutation.mutate(d))} className="space-y-4">
      <div>
        <label className="form-label">Nome da operação *</label>
        <input {...register('name')} className="form-input" placeholder="Ex: Consórcio de Automóveis" onBlur={() => { if (!op && name) setValue('slug', generateSlug(name)) }} />
        {errors.name && <p className="form-error">{errors.name.message}</p>}
      </div>
      <div className="grid grid-cols-2 gap-4">
        <div>
          <label className="form-label">Slug *</label>
          <input {...register('slug')} className="form-input font-mono text-xs" placeholder="consorcio-automoveis" />
          {errors.slug && <p className="form-error">{errors.slug.message}</p>}
        </div>
        <div>
          <label className="form-label">Tipo de operação</label>
          <select {...register('operation_type')} className="form-input">
            <option value="">Selecione...</option>
            {Object.entries(OPERATION_TYPE_LABELS).map(([k, v]) => (
              <option key={k} value={k}>{v}</option>
            ))}
          </select>
        </div>
      </div>
      <div>
        <label className="form-label">Descrição</label>
        <textarea {...register('description')} className="form-input" rows={3} placeholder="Descrição opcional da operação" />
      </div>
      <div className="flex gap-3 justify-end pt-2">
        <button type="button" onClick={onClose} className="btn-secondary">Cancelar</button>
        <button type="submit" disabled={mutation.isPending} className="btn-primary">
          {mutation.isPending ? 'Salvando...' : op ? 'Salvar' : 'Criar operação'}
        </button>
      </div>
    </form>
  )
}

export default function OperationsPage() {
  const { activeOrganization, profile } = useAuth()
  const { canManageOperations } = usePermissions()
  const qc = useQueryClient()
  const [search, setSearch] = useState('')
  const [formOpen, setFormOpen] = useState(false)
  const [editOp, setEditOp] = useState<Operation | undefined>()
  const [confirmArchive, setConfirmArchive] = useState<Operation | null>(null)
  const [confirmRestore, setConfirmRestore] = useState<Operation | null>(null)

  const orgId = activeOrganization?.id

  const { data: ops, isLoading } = useQuery({
    queryKey: ['operations', orgId],
    enabled: !!orgId,
    queryFn: async () => {
      if (!orgId) return []

      const { data, error } = await supabase
        .from('operations')
        .select('*')
        .eq('organization_id', orgId)
        .order('name')

      if (error) throw error
      return data as Operation[]
    },
  })

  const archiveMutation = useMutation({
    mutationFn: async (op: Operation) => {
      if (!orgId) throw new Error('Nenhuma organização ativa.')

      const { error } = await supabase
        .from('operations')
        .update({
          status: 'archived',
          archived_at: new Date().toISOString(),
          updated_by: profile?.id,
        })
        .eq('id', op.id)
        .eq('organization_id', orgId)

      if (error) throw error
    },
    onSuccess: () => { toast.success('Operação arquivada.'); qc.invalidateQueries({ queryKey: ['operations'] }) },
    onError: (e: Error) => toast.error(e.message),
  })

  const restoreMutation = useMutation({
    mutationFn: async (op: Operation) => {
      if (!orgId) throw new Error('Nenhuma organização ativa.')

      const { error } = await supabase
        .from('operations')
        .update({
          status: 'active',
          archived_at: null,
          updated_by: profile?.id,
        })
        .eq('id', op.id)
        .eq('organization_id', orgId)

      if (error) throw error
    },
    onSuccess: () => { toast.success('Operação restaurada.'); qc.invalidateQueries({ queryKey: ['operations'] }) },
    onError: (e: Error) => toast.error(e.message),
  })

  const filtered = ops?.filter(o => !search || o.name.toLowerCase().includes(search.toLowerCase())) ?? []

  if (!orgId) {
    return <div className="page-container"><EmptyState icon={Briefcase} title="Nenhuma organização ativa" description="Selecione ou crie uma organização primeiro." /></div>
  }

  return (
    <div className="page-container">
      <PageHeader
        title="Operações"
        description="Gerencie as operações comerciais da organização."
        action={canManageOperations ? (
          <button onClick={() => { setEditOp(undefined); setFormOpen(true) }} className="btn-primary">
            <Plus className="h-4 w-4" /> Nova operação
          </button>
        ) : undefined}
      />

      <div className="table-container">
        <div className="table-header">
          <SearchInput value={search} onChange={setSearch} placeholder="Pesquisar operações..." className="w-64" />
          <span className="ml-auto text-xs text-gray-500">{filtered.length} registro(s)</span>
        </div>

        {isLoading ? (
          <div className="py-12 flex justify-center"><LoadingSpinner /></div>
        ) : filtered.length === 0 ? (
          <EmptyState icon={Briefcase} title="Nenhuma operação encontrada" description="Crie a primeira operação para começar." />
        ) : (
          <div className="overflow-x-auto">
            <table className="w-full">
              <thead>
                <tr className="border-b border-gray-200 bg-gray-50">
                  <th className="table-th">Nome</th>
                  <th className="table-th hidden sm:table-cell">Tipo</th>
                  <th className="table-th">Status</th>
                  <th className="table-th hidden md:table-cell">Criado em</th>
                  <th className="table-th text-right">Ações</th>
                </tr>
              </thead>
              <tbody>
                {filtered.map(op => (
                  <tr key={op.id} className="table-tr">
                    <td className="table-td">
                      <div className="font-medium text-gray-900">{op.name}</div>
                      <div className="text-xs text-gray-400 font-mono">{op.slug}</div>
                    </td>
                    <td className="table-td hidden sm:table-cell text-gray-500 text-xs">
                      {op.operation_type ? (OPERATION_TYPE_LABELS[op.operation_type] ?? op.operation_type) : '—'}
                    </td>
                    <td className="table-td"><StatusBadge status={op.status} /></td>
                    <td className="table-td hidden md:table-cell text-gray-500 text-xs">{formatDateTime(op.created_at)}</td>
                    <td className="table-td text-right">
                      {canManageOperations && (
                        <div className="flex items-center justify-end gap-1">
                          {op.status === 'archived' ? (
                            <button onClick={() => setConfirmRestore(op)} className="p-1.5 rounded text-gray-400 hover:text-brand-700 hover:bg-brand-50" title="Restaurar">
                              <RotateCcw className="h-4 w-4" />
                            </button>
                          ) : (
                            <>
                              <button onClick={() => { setEditOp(op); setFormOpen(true) }} className="p-1.5 rounded text-gray-400 hover:text-brand-700 hover:bg-brand-50" title="Editar">
                                <Pencil className="h-4 w-4" />
                              </button>
                              <button onClick={() => setConfirmArchive(op)} className="p-1.5 rounded text-gray-400 hover:text-red-600 hover:bg-red-50" title="Arquivar">
                                <Archive className="h-4 w-4" />
                              </button>
                            </>
                          )}
                        </div>
                      )}
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}
      </div>

      <Dialog open={formOpen} onOpenChange={setFormOpen}>
        <DialogContent>
          <DialogHeader><DialogTitle>{editOp ? 'Editar operação' : 'Nova operação'}</DialogTitle></DialogHeader>
          {orgId && <OpForm op={editOp} orgId={orgId} onClose={() => setFormOpen(false)} />}
        </DialogContent>
      </Dialog>

      <ConfirmDialog
        open={!!confirmArchive}
        title="Arquivar operação?"
        description={`A operação "${confirmArchive?.name}" será arquivada e ficará indisponível para novos vínculos.`}
        confirmLabel="Arquivar"
        variant="destructive"
        onConfirm={() => { if (confirmArchive) archiveMutation.mutate(confirmArchive); setConfirmArchive(null) }}
        onCancel={() => setConfirmArchive(null)}
      />

      <ConfirmDialog
        open={!!confirmRestore}
        title="Restaurar operação?"
        description={`A operação "${confirmRestore?.name}" voltará ao status ativo e poderá receber novos vínculos.`}
        confirmLabel="Restaurar"
        variant="default"
        onConfirm={() => { if (confirmRestore) restoreMutation.mutate(confirmRestore); setConfirmRestore(null) }}
        onCancel={() => setConfirmRestore(null)}
      />
    </div>
  )
}
