import { useState } from 'react'
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query'
import { useForm } from 'react-hook-form'
import { zodResolver } from '@hookform/resolvers/zod'
import {
  BadgeCheck,
  Clock3,
  MapPin,
  Pencil,
  ToggleLeft,
  ToggleRight,
  Users,
} from 'lucide-react'
import { toast } from 'sonner'
import { z } from 'zod'
import { supabase } from '@/lib/supabase'
import { useAuth } from '@/contexts/AuthContext'
import { usePermissions } from '@/hooks/usePermissions'
import { salesLocationSchema } from '@/lib/validations'
import {
  getPlannedSalespersonCapacity,
  getSetupMetadata,
  isSetupConfirmed,
  isTemplateRecord,
  updateSetupMetadata,
} from '@/lib/setupMetadata'
import { LOCATION_TYPE_LABELS, BRAZILIAN_STATES } from '@/constants/roles'
import type { SalesLocation } from '@/types/database'
import PageHeader from '@/components/shared/PageHeader'
import StatusBadge from '@/components/shared/StatusBadge'
import EmptyState from '@/components/shared/EmptyState'
import LoadingSpinner from '@/components/shared/LoadingSpinner'
import ConfirmDialog from '@/components/shared/ConfirmDialog'
import {
  Dialog,
  DialogContent,
  DialogHeader,
  DialogTitle,
} from '@/components/ui/dialog'

type FormData = z.infer<typeof salesLocationSchema>

function PDVForm({
  pdv,
  onClose,
}: {
  pdv: SalesLocation
  onClose: () => void
}) {
  const { profile } = useAuth()
  const qc = useQueryClient()
  const setup = getSetupMetadata(pdv.metadata)
  const [confirmData, setConfirmData] = useState(
    isSetupConfirmed(pdv.metadata),
  )

  const {
    register,
    handleSubmit,
    formState: { errors },
  } = useForm<FormData>({
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
      if (
        confirmData &&
        (!data.shopping_name || !data.city || !data.state_code)
      ) {
        throw new Error(
          'Para confirmar o PDV, informe shopping/local, cidade e UF.',
        )
      }

      const { error } = await supabase
        .from('sales_locations')
        .update({
          name: data.name,
          slug: data.slug,
          location_type: data.location_type,
          shopping_name: data.shopping_name || null,
          address_line: data.address_line || null,
          city: data.city || null,
          state_code: data.state_code?.toUpperCase() || null,
          metadata: updateSetupMetadata(pdv.metadata, {
            confirmed: confirmData,
            userId: profile?.id,
            plannedSalespersonCapacity:
              setup.planned_salesperson_capacity,
            plannedSupervisorPositions:
              setup.planned_supervisor_positions,
          }),
          updated_by: profile?.id,
        })
        .eq('id', pdv.id)

      if (error) throw error
    },
    onSuccess: () => {
      toast.success(
        confirmData
          ? 'PDV atualizado e confirmado.'
          : 'PDV atualizado como dado provisório.',
      )
      qc.invalidateQueries({ queryKey: ['sales-locations'] })
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
      {isTemplateRecord(pdv.metadata) && (
        <div className="rounded-lg border border-amber-200 bg-amber-50 p-3 text-sm text-amber-900">
          Este registro veio do template de apresentação. Substitua os dados
          provisórios pelas informações reais quando forem confirmadas.
        </div>
      )}

      <div className="grid grid-cols-2 gap-4">
        <div>
          <label className="form-label">Nome do PDV *</label>
          <input
            {...register('name')}
            className="form-input"
            placeholder="Ex: PDV Shopping ABC"
          />
          {errors.name && (
            <p className="form-error">{errors.name.message}</p>
          )}
        </div>
        <div>
          <label className="form-label">Slug *</label>
          <input
            {...register('slug')}
            className="form-input font-mono text-xs"
          />
          {errors.slug && (
            <p className="form-error">{errors.slug.message}</p>
          )}
        </div>
        <div className="col-span-2">
          <label className="form-label">Tipo de local</label>
          <select {...register('location_type')} className="form-input">
            {Object.entries(LOCATION_TYPE_LABELS).map(([key, value]) => (
              <option key={key} value={key}>
                {value}
              </option>
            ))}
          </select>
        </div>
        <div className="col-span-2">
          <label className="form-label">Nome do shopping / local</label>
          <input
            {...register('shopping_name')}
            className="form-input"
            placeholder="Ex: Shopping Iguatemi"
          />
        </div>
        <div className="col-span-2">
          <label className="form-label">Endereço</label>
          <input
            {...register('address_line')}
            className="form-input"
            placeholder="Rua / avenida / número"
          />
        </div>
        <div>
          <label className="form-label">Cidade</label>
          <input
            {...register('city')}
            className="form-input"
            placeholder="Rio de Janeiro"
          />
        </div>
        <div>
          <label className="form-label">Estado</label>
          <select {...register('state_code')} className="form-input">
            <option value="">Selecione...</option>
            {BRAZILIAN_STATES.map((state) => (
              <option key={state} value={state}>
                {state}
              </option>
            ))}
          </select>
        </div>
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
            Confirmar dados reais do PDV
          </span>
          <span className="block text-xs text-gray-500">
            Marque somente depois de validar nome, shopping/local, cidade e UF.
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
  const [toggleConfirm, setToggleConfirm] = useState<SalesLocation | null>(
    null,
  )

  const orgId = activeOrganization?.id

  const { data: locations, isLoading } = useQuery({
    queryKey: ['sales-locations', orgId],
    enabled: !!orgId,
    queryFn: async () => {
      let query = supabase
        .from('sales_locations')
        .select('*')
        .order('name')

      if (!isAdmin && orgId) {
        query = query.eq('organization_id', orgId)
      }

      const { data, error } = await query
      if (error) throw error
      return data as SalesLocation[]
    },
  })

  const toggleMutation = useMutation({
    mutationFn: async (location: SalesLocation) => {
      const newStatus =
        location.status === 'active' ? 'inactive' : 'active'
      const { error } = await supabase
        .from('sales_locations')
        .update({
          status: newStatus,
          updated_by: profile?.id,
        })
        .eq('id', location.id)

      if (error) throw error
    },
    onSuccess: (_, location) => {
      toast.success(
        `PDV ${
          location.status === 'active' ? 'inativado' : 'ativado'
        }.`,
      )
      qc.invalidateQueries({ queryKey: ['sales-locations'] })
      qc.invalidateQueries({ queryKey: ['org-stats'] })
    },
    onError: (error: Error) => toast.error(error.message),
  })

  if (!orgId) {
    return (
      <div className="page-container">
        <EmptyState icon={MapPin} title="Nenhuma organização ativa" />
      </div>
    )
  }

  return (
    <div className="page-container">
      <PageHeader
        title="Pontos de Venda (PDVs)"
        description="Edite os pontos de venda modelo e confirme os dados reais durante a implantação."
      />

      {isLoading ? (
        <div className="flex justify-center py-12">
          <LoadingSpinner size="lg" />
        </div>
      ) : (locations?.length ?? 0) === 0 ? (
        <EmptyState
          icon={MapPin}
          title="Nenhum PDV encontrado"
          description="Os PDVs são criados com a estrutura operacional."
        />
      ) : (
        <div className="grid grid-cols-1 gap-4 sm:grid-cols-2 lg:grid-cols-3">
          {locations?.map((location) => {
            const confirmed = isSetupConfirmed(location.metadata)
            const template = isTemplateRecord(location.metadata)
            const plannedCapacity =
              getPlannedSalespersonCapacity(location.metadata)

            return (
              <div key={location.id} className="card p-5">
                <div className="mb-3 flex items-start justify-between gap-3">
                  <div className="flex items-center gap-2">
                    <div className="flex h-9 w-9 items-center justify-center rounded-lg bg-brand-100">
                      <MapPin className="h-5 w-5 text-brand-700" />
                    </div>
                    <div>
                      <p className="text-sm font-semibold text-gray-900">
                        {location.name}
                      </p>
                      <p className="font-mono text-xs text-gray-400">
                        {location.slug}
                      </p>
                    </div>
                  </div>
                  <StatusBadge status={location.status} />
                </div>

                <div className="mb-4 flex flex-wrap gap-2">
                  {template && (
                    <span className="inline-flex items-center gap-1 rounded-full bg-blue-50 px-2 py-1 text-xs font-medium text-blue-700">
                      Modelo editável
                    </span>
                  )}
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
                    {confirmed
                      ? 'Dados confirmados'
                      : 'Confirmação pendente'}
                  </span>
                </div>

                <dl className="mb-4 space-y-1.5 text-sm">
                  <div className="flex justify-between gap-3">
                    <dt className="text-gray-500">Tipo</dt>
                    <dd className="text-right text-xs text-gray-900">
                      {LOCATION_TYPE_LABELS[location.location_type] ??
                        location.location_type}
                    </dd>
                  </div>
                  <div className="flex justify-between gap-3">
                    <dt className="text-gray-500">Shopping/Local</dt>
                    <dd className="text-right text-xs text-gray-900">
                      {location.shopping_name ?? (
                        <span className="italic text-gray-400">
                          A definir
                        </span>
                      )}
                    </dd>
                  </div>
                  <div className="flex justify-between gap-3">
                    <dt className="text-gray-500">Cidade</dt>
                    <dd className="text-right text-xs text-gray-900">
                      {location.city ? (
                        `${location.city}${
                          location.state_code
                            ? ` / ${location.state_code}`
                            : ''
                        }`
                      ) : (
                        <span className="italic text-gray-400">
                          A definir
                        </span>
                      )}
                    </dd>
                  </div>
                  {plannedCapacity > 0 && (
                    <div className="flex justify-between gap-3">
                      <dt className="flex items-center gap-1 text-gray-500">
                        <Users className="h-3.5 w-3.5" />
                        Capacidade
                      </dt>
                      <dd className="text-right text-xs font-medium text-gray-900">
                        {plannedCapacity} vendedores
                      </dd>
                    </div>
                  )}
                </dl>

                {canManagePDVs && (
                  <div className="flex items-center gap-2 border-t border-gray-100 pt-3">
                    <button
                      onClick={() => setEditPDV(location)}
                      className="btn-secondary flex-1 py-1.5 text-xs"
                    >
                      <Pencil className="h-3.5 w-3.5" /> Editar e confirmar
                    </button>
                    <button
                      onClick={() => setToggleConfirm(location)}
                      className={`rounded-md p-1.5 text-sm ${
                        location.status === 'active'
                          ? 'text-yellow-600 hover:bg-yellow-50'
                          : 'text-green-600 hover:bg-green-50'
                      }`}
                      title={
                        location.status === 'active'
                          ? 'Inativar'
                          : 'Ativar'
                      }
                    >
                      {location.status === 'active' ? (
                        <ToggleRight className="h-5 w-5" />
                      ) : (
                        <ToggleLeft className="h-5 w-5" />
                      )}
                    </button>
                  </div>
                )}
              </div>
            )
          })}
        </div>
      )}

      <Dialog
        open={!!editPDV}
        onOpenChange={(open) => {
          if (!open) setEditPDV(undefined)
        }}
      >
        <DialogContent>
          <DialogHeader>
            <DialogTitle>Editar PDV</DialogTitle>
          </DialogHeader>
          {editPDV && (
            <PDVForm
              pdv={editPDV}
              onClose={() => setEditPDV(undefined)}
            />
          )}
        </DialogContent>
      </Dialog>

      <ConfirmDialog
        open={!!toggleConfirm}
        title={
          toggleConfirm?.status === 'active'
            ? 'Inativar PDV'
            : 'Ativar PDV'
        }
        description={`Confirma a alteração de status de ${
          toggleConfirm?.name ?? 'este PDV'
        }?`}
        confirmLabel="Confirmar"
        variant="default"
        onConfirm={() => {
          if (toggleConfirm) toggleMutation.mutate(toggleConfirm)
          setToggleConfirm(null)
        }}
        onCancel={() => setToggleConfirm(null)}
      />
    </div>
  )
}
