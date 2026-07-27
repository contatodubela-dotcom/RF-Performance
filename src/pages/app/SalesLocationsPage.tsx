import { useState } from 'react'
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query'
import { useForm } from 'react-hook-form'
import { zodResolver } from '@hookform/resolvers/zod'
import { Pencil, MapPin, ToggleLeft, ToggleRight } from 'lucide-react'
import { toast } from 'sonner'
import { z } from 'zod'
import { supabase } from '@/lib/supabase'
import { useAuth } from '@/contexts/AuthContext'
import { usePermissions } from '@/hooks/usePermissions'
import { salesLocationSchema } from '@/lib/validations'
import { generateSlug } from '@/lib/utils'
import { LOCATION_TYPE_LABELS, BRAZILIAN_STATES } from '@/constants/roles'
import type { SalesLocation } from '@/types/database'
import PageHeader from '@/components/shared/PageHeader'
import StatusBadge from '@/components/shared/StatusBadge'
import EmptyState from '@/components/shared/EmptyState'
import LoadingSpinner from '@/components/shared/LoadingSpinner'
import ConfirmDialog from '@/components/shared/ConfirmDialog'
import { Dialog, DialogContent, DialogHeader, DialogTitle } from '@/components/ui/dialog'

type FormData = z.infer<typeof salesLocationSchema>

function PDVForm({ pdv, onClose }: { pdv: SalesLocation; onClose: () => void }) {
  const { profile } = useAuth()
  const qc = useQueryClient()

  const { register, handleSubmit, formState: { errors } } = useForm<FormData>({
    resolver: zodResolver(salesLocationSchema),
    defaultValues: {
      name: pdv.name,
      slug: pdv.slug,
      location_type: pdv.location_type,
      shopping_name: pdv.shopping_name ?? '',
      address_line: pdv.address_line ?? '',
      city: pdv.city ?? '',
      state_code: pdv.state_code ?? '',
    },
  })

  const mutation = useMutation({
    mutationFn: async (data: FormData) => {
      const { error } = await supabase.from('sales_locations').update({
        name: data.name,
        slug: data.slug,
        location_type: data.location_type,
        shopping_name: data.shopping_name || null,
        address_line: data.address_line || null,
        city: data.city || null,
        state_code: data.state_code?.toUpperCase() || null,
        updated_by: profile?.id,
      }).eq('id', pdv.id)
      if (error) throw error
    },
    onSuccess: () => {
      toast.success('PDV atualizado.')
      qc.invalidateQueries({ queryKey: ['sales-locations'] })
      onClose()
    },
    onError: (e: Error) => toast.error(e.message),
  })

  return (
    <form onSubmit={handleSubmit((d) => mutation.mutate(d))} className="space-y-4">
      <div className="grid grid-cols-2 gap-4">
        <div>
          <label className="form-label">Nome do PDV *</label>
          <input {...register('name')} className="form-input" placeholder="Ex: PDV Shopping ABC" />
          {errors.name && <p className="form-error">{errors.name.message}</p>}
        </div>
        <div>
          <label className="form-label">Slug *</label>
          <input {...register('slug')} className="form-input font-mono text-xs" />
          {errors.slug && <p className="form-error">{errors.slug.message}</p>}
        </div>
        <div className="col-span-2">
          <label className="form-label">Tipo de local</label>
          <select {...register('location_type')} className="form-input">
            {Object.entries(LOCATION_TYPE_LABELS).map(([k, v]) => (
              <option key={k} value={k}>{v}</option>
            ))}
          </select>
        </div>
        <div className="col-span-2">
          <label className="form-label">Nome do shopping / local</label>
          <input {...register('shopping_name')} className="form-input" placeholder="Ex: Shopping Iguatemi" />
        </div>
        <div className="col-span-2">
          <label className="form-label">Endereço</label>
          <input {...register('address_line')} className="form-input" placeholder="Rua / avenida / número" />
        </div>
        <div>
          <label className="form-label">Cidade</label>
          <input {...register('city')} className="form-input" placeholder="São Paulo" />
        </div>
        <div>
          <label className="form-label">Estado</label>
          <select {...register('state_code')} className="form-input">
            <option value="">Selecione...</option>
            {BRAZILIAN_STATES.map(s => <option key={s} value={s}>{s}</option>)}
          </select>
        </div>
      </div>
      <div className="flex gap-3 justify-end pt-2">
        <button type="button" onClick={onClose} className="btn-secondary">Cancelar</button>
        <button type="submit" disabled={mutation.isPending} className="btn-primary">
          {mutation.isPending ? 'Salvando...' : 'Salvar alterações'}
        </button>
      </div>
    </form>
  )
}

export default function SalesLocationsPage() {
  const { activeOrganization, profile, isAdmin } = useAuth()
  const { canManagePDVs } = usePermissions()
  const qc = useQueryClient()
  const [editPDV, setEditPDV] = useState<SalesLocation | undefined>()
  const [toggleConfirm, setToggleConfirm] = useState<SalesLocation | null>(null)

  const orgId = activeOrganization?.id

  const { data: locations, isLoading } = useQuery({
    queryKey: ['sales-locations', orgId],
    enabled: !!orgId,
    queryFn: async () => {
      let q = supabase.from('sales_locations').select('*').order('name')
      if (!isAdmin && orgId) q = q.eq('organization_id', orgId)
      const { data, error } = await q
      if (error) throw error
      return data as SalesLocation[]
    },
  })

  const toggleMutation = useMutation({
    mutationFn: async (loc: SalesLocation) => {
      const newStatus = loc.status === 'active' ? 'inactive' : 'active'
      const { error } = await supabase.from('sales_locations').update({
        status: newStatus, updated_by: profile?.id,
      }).eq('id', loc.id)
      if (error) throw error
    },
    onSuccess: (_, loc) => {
      toast.success(`PDV ${loc.status === 'active' ? 'inativado' : 'ativado'}.`)
      qc.invalidateQueries({ queryKey: ['sales-locations'] })
    },
    onError: (e: Error) => toast.error(e.message),
  })

  if (!orgId) {
    return <div className="page-container"><EmptyState icon={MapPin} title="Nenhuma organização ativa" /></div>
  }

  return (
    <div className="page-container">
      <PageHeader
        title="Pontos de Venda (PDVs)"
        description="Gerencie os pontos de venda da operação. Atualize nomes, localização e status."
      />

      {isLoading ? (
        <div className="flex justify-center py-12"><LoadingSpinner size="lg" /></div>
      ) : (locations?.length ?? 0) === 0 ? (
        <EmptyState icon={MapPin} title="Nenhum PDV encontrado" description="Os PDVs são criados automaticamente com a operação." />
      ) : (
        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-4">
          {locations?.map(loc => (
            <div key={loc.id} className="card p-5">
              <div className="flex items-start justify-between mb-3">
                <div className="flex items-center gap-2">
                  <div className="w-9 h-9 rounded-lg bg-brand-100 flex items-center justify-center">
                    <MapPin className="h-5 w-5 text-brand-700" />
                  </div>
                  <div>
                    <p className="font-semibold text-gray-900 text-sm">{loc.name}</p>
                    <p className="text-xs text-gray-400 font-mono">{loc.slug}</p>
                  </div>
                </div>
                <StatusBadge status={loc.status} />
              </div>

              <dl className="space-y-1.5 text-sm mb-4">
                <div className="flex justify-between">
                  <dt className="text-gray-500">Tipo</dt>
                  <dd className="text-gray-900 text-xs">{LOCATION_TYPE_LABELS[loc.location_type] ?? loc.location_type}</dd>
                </div>
                <div className="flex justify-between">
                  <dt className="text-gray-500">Shopping/Local</dt>
                  <dd className="text-gray-900 text-xs">{loc.shopping_name ?? <span className="text-gray-400 italic">Não informado</span>}</dd>
                </div>
                <div className="flex justify-between">
                  <dt className="text-gray-500">Cidade</dt>
                  <dd className="text-gray-900 text-xs">
                    {loc.city ? `${loc.city}${loc.state_code ? ` / ${loc.state_code}` : ''}` : <span className="text-gray-400 italic">Não informada</span>}
                  </dd>
                </div>
                <div className="flex justify-between">
                  <dt className="text-gray-500">Fuso horário</dt>
                  <dd className="text-gray-900 text-xs">{loc.timezone}</dd>
                </div>
              </dl>

              {canManagePDVs && (
                <div className="flex items-center gap-2 pt-3 border-t border-gray-100">
                  <button onClick={() => setEditPDV(loc)} className="btn-secondary flex-1 text-xs py-1.5">
                    <Pencil className="h-3.5 w-3.5" /> Editar
                  </button>
                  <button
                    onClick={() => setToggleConfirm(loc)}
                    className={`p-1.5 rounded-md text-sm ${loc.status === 'active' ? 'text-yellow-600 hover:bg-yellow-50' : 'text-green-600 hover:bg-green-50'}`}
                    title={loc.status === 'active' ? 'Inativar' : 'Ativar'}
                  >
                    {loc.status === 'active' ? <ToggleRight className="h-5 w-5" /> : <ToggleLeft className="h-5 w-5" />}
                  </button>
                </div>
              )}
            </div>
          ))}
        </div>
      )}

      <Dialog open={!!editPDV} onOpenChange={() => setEditPDV(undefined)}>
        <DialogContent>
          <DialogHeader><DialogTitle>Editar PDV</DialogTitle></DialogHeader>
          {editPDV && <PDVForm pdv={editPDV} onClose={() => setEditPDV(undefined)} />}
        </DialogContent>
      </Dialog>

      <ConfirmDialog
        open={!!toggleConfirm}
        title={toggleConfirm?.status === 'active' ? 'Inativar PDV?' : 'Ativar PDV?'}
        description={`Esta ação alterará o status de "${toggleConfirm?.name}".`}
        confirmLabel="Confirmar"
        onConfirm={() => { if (toggleConfirm) toggleMutation.mutate(toggleConfirm); setToggleConfirm(null) }}
        onCancel={() => setToggleConfirm(null)}
      />
    </div>
  )
}
