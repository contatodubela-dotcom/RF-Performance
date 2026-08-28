import { useEffect, useMemo, useState } from 'react'
import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query'
import {
  BadgeCheck,
  Ban,
  Briefcase,
  ChevronLeft,
  ChevronRight,
  Clock3,
  Pencil,
  Plus,
  RotateCcw,
  XCircle,
} from 'lucide-react'
import { toast } from 'sonner'

import EmptyState from '@/components/shared/EmptyState'
import LoadingSpinner from '@/components/shared/LoadingSpinner'
import PageHeader from '@/components/shared/PageHeader'
import {
  Dialog,
  DialogContent,
  DialogHeader,
  DialogTitle,
} from '@/components/ui/dialog'
import { useAuth } from '@/contexts/AuthContext'
import { usePermissions } from '@/hooks/usePermissions'
import { supabase } from '@/lib/supabase'
import type {
  CommercialSale,
  CommercialSaleValidationStatus,
  Operation,
  Profile,
  SalesLocation,
  Team,
} from '@/types/database'

const PAGE_SIZE = 25

type Relation<T> = T | T[] | null

type NamedRelation = {
  id: string
  name: string
}

type SalespersonRelation = {
  id: string
  user_id: string
  role: string
  profile: Relation<Pick<Profile, 'full_name' | 'preferred_name' | 'email'>>
}

interface CommercialSaleRow extends CommercialSale {
  operation: Relation<NamedRelation>
  sales_location: Relation<NamedRelation>
  team: Relation<NamedRelation>
  salesperson_member: Relation<SalespersonRelation>
}

interface TeamMemberLookupRow {
  organization_member_id: string
  organization_member: Relation<{
    id: string
    user_id: string
    role: string
    status: string
    archived_at: string | null
    profile: Relation<Pick<Profile, 'full_name' | 'preferred_name' | 'email'>>
  }>
}

interface SaleFormState {
  sale_date: string
  operation_id: string
  sales_location_id: string
  team_id: string
  salesperson_member_id: string
  units_count: string
  external_id: string
}

interface StatusActionState {
  sale: CommercialSaleRow
  targetStatus: CommercialSaleValidationStatus
}

function firstRelation<T>(relation: Relation<T> | undefined): T | null {
  if (Array.isArray(relation)) return relation[0] ?? null
  return relation ?? null
}

function todayInputValue() {
  const now = new Date()
  const year = now.getFullYear()
  const month = String(now.getMonth() + 1).padStart(2, '0')
  const day = String(now.getDate()).padStart(2, '0')
  return `${year}-${month}-${day}`
}

function currentMonthInputValue() {
  const now = new Date()
  const year = now.getFullYear()
  const month = String(now.getMonth() + 1).padStart(2, '0')
  return `${year}-${month}`
}

function formatDate(value: string) {
  if (!value) return '—'

  const [year, month, day] = value.slice(0, 10).split('-')
  if (!year || !month || !day) return value

  return `${day}/${month}/${year}`
}

function salespersonLabel(salesperson: SalespersonRelation | null) {
  if (!salesperson) return 'Sem vendedor identificado'

  const profile = firstRelation(salesperson.profile)
  return (
    profile?.preferred_name ||
    profile?.full_name ||
    profile?.email ||
    'Vendedor sem nome'
  )
}

function validationStatusLabel(status: CommercialSaleValidationStatus) {
  const labels: Record<CommercialSaleValidationStatus, string> = {
    pending: 'Pendente',
    validated: 'Validada',
    rejected: 'Rejeitada',
    cancelled: 'Cancelada',
  }

  return labels[status]
}

function validationStatusClass(status: CommercialSaleValidationStatus) {
  const classes: Record<CommercialSaleValidationStatus, string> = {
    pending: 'bg-amber-50 text-amber-700',
    validated: 'bg-green-50 text-green-700',
    rejected: 'bg-red-50 text-red-700',
    cancelled: 'bg-gray-100 text-gray-600',
  }

  return classes[status]
}

function emptyForm(): SaleFormState {
  return {
    sale_date: todayInputValue(),
    operation_id: '',
    sales_location_id: '',
    team_id: '',
    salesperson_member_id: '',
    units_count: '1',
    external_id: '',
  }
}

function CommercialSaleForm({
  orgId,
  sale,
  onClose,
}: {
  orgId: string
  sale?: CommercialSaleRow
  onClose: () => void
}) {
  const qc = useQueryClient()
  const isEdit = !!sale
  const saleOperation = firstRelation(sale?.operation)
  const saleLocation = firstRelation(sale?.sales_location)
  const saleTeam = firstRelation(sale?.team)
  const saleSalesperson = firstRelation(sale?.salesperson_member)

  const [form, setForm] = useState<SaleFormState>(() =>
    sale
      ? {
          sale_date: sale.sale_date,
          operation_id: sale.operation_id,
          sales_location_id: sale.sales_location_id,
          team_id: sale.team_id,
          salesperson_member_id: sale.salesperson_member_id ?? '',
          units_count: String(sale.units_count),
          external_id: sale.external_id ?? '',
        }
      : emptyForm(),
  )

  const { data: operations = [], isLoading: operationsLoading } = useQuery({
    queryKey: ['commercial-sale-form-operations', orgId],
    queryFn: async () => {
      const { data, error } = await supabase
        .from('operations')
        .select('id, name')
        .eq('organization_id', orgId)
        .eq('status', 'active')
        .is('archived_at', null)
        .order('name')

      if (error) throw error
      return (data ?? []) as Pick<Operation, 'id' | 'name'>[]
    },
  })

  const { data: salesLocations = [], isLoading: salesLocationsLoading } =
    useQuery({
      queryKey: ['commercial-sale-form-locations', orgId, form.operation_id],
      enabled: !!form.operation_id,
      queryFn: async () => {
        const { data, error } = await supabase
          .from('sales_locations')
          .select('id, name, operation_id')
          .eq('organization_id', orgId)
          .eq('operation_id', form.operation_id)
          .eq('status', 'active')
          .is('archived_at', null)
          .order('name')

        if (error) throw error
        return (data ?? []) as Pick<
          SalesLocation,
          'id' | 'name' | 'operation_id'
        >[]
      },
    })

  const { data: teams = [], isLoading: teamsLoading } = useQuery({
    queryKey: [
      'commercial-sale-form-teams',
      orgId,
      form.operation_id,
      form.sales_location_id,
    ],
    enabled: !!form.operation_id && !!form.sales_location_id,
    queryFn: async () => {
      const { data, error } = await supabase
        .from('teams')
        .select('id, name, operation_id, sales_location_id')
        .eq('organization_id', orgId)
        .eq('operation_id', form.operation_id)
        .eq('sales_location_id', form.sales_location_id)
        .eq('status', 'active')
        .is('archived_at', null)
        .order('name')

      if (error) throw error
      return (data ?? []) as Pick<
        Team,
        'id' | 'name' | 'operation_id' | 'sales_location_id'
      >[]
    },
  })

  const { data: teamSalespersons = [], isLoading: salespersonsLoading } =
    useQuery({
      queryKey: ['commercial-sale-form-salespersons', orgId, form.team_id],
      enabled: !!form.team_id,
      queryFn: async () => {
        const { data, error } = await supabase
          .from('team_members')
          .select(`
            organization_member_id,
            organization_member:organization_members!team_members_member_org_fkey(
              id,
              user_id,
              role,
              status,
              archived_at,
              profile:profiles!organization_members_user_id_fkey(
                full_name,
                preferred_name,
                email
              )
            )
          `)
          .eq('organization_id', orgId)
          .eq('team_id', form.team_id)
          .eq('membership_type', 'salesperson')
          .eq('status', 'active')
          .is('archived_at', null)
          .order('created_at', { ascending: true })

        if (error) throw error

        return ((data ?? []) as TeamMemberLookupRow[])
          .map((row) => firstRelation(row.organization_member))
          .filter(
            (member): member is NonNullable<typeof member> =>
              !!member &&
              member.role === 'salesperson' &&
              member.status === 'active' &&
              member.archived_at === null,
          )
      },
    })

  const operationOptions = useMemo(() => {
    if (
      !saleOperation ||
      operations.some((item) => item.id === saleOperation.id)
    ) {
      return operations
    }

    return [saleOperation, ...operations]
  }, [operations, saleOperation])

  const locationOptions = useMemo(() => {
    if (
      !saleLocation ||
      form.operation_id !== sale?.operation_id ||
      salesLocations.some((item) => item.id === saleLocation.id)
    ) {
      return salesLocations
    }

    return [saleLocation, ...salesLocations]
  }, [form.operation_id, sale?.operation_id, saleLocation, salesLocations])

  const teamOptions = useMemo(() => {
    if (
      !saleTeam ||
      form.operation_id !== sale?.operation_id ||
      form.sales_location_id !== sale?.sales_location_id ||
      teams.some((item) => item.id === saleTeam.id)
    ) {
      return teams
    }

    return [saleTeam, ...teams]
  }, [
    form.operation_id,
    form.sales_location_id,
    sale?.operation_id,
    sale?.sales_location_id,
    saleTeam,
    teams,
  ])

  const salespersonOptions = useMemo(() => {
    if (
      !saleSalesperson ||
      form.team_id !== sale?.team_id ||
      teamSalespersons.some((item) => item.id === saleSalesperson.id)
    ) {
      return teamSalespersons
    }

    return [saleSalesperson, ...teamSalespersons]
  }, [form.team_id, sale?.team_id, saleSalesperson, teamSalespersons])

  const mutation = useMutation({
    mutationFn: async () => {
      const unitsCount = Number.parseInt(form.units_count, 10)

      if (!form.sale_date) throw new Error('Informe a data da venda.')
      if (!form.operation_id) throw new Error('Selecione a operação.')
      if (!form.sales_location_id) throw new Error('Selecione o PDV.')
      if (!form.team_id) throw new Error('Selecione a equipe.')

      if (!Number.isInteger(unitsCount) || unitsCount < 1) {
        throw new Error(
          'A quantidade de unidades deve ser um número inteiro maior ou igual a 1.',
        )
      }

      const metadata = sale
        ? { ...sale.metadata, ui_source: 'commercial_sales_page' }
        : { ui_source: 'commercial_sales_page' }

      if (sale) {
        const { error } = await supabase.rpc('update_pending_commercial_sale', {
          p_sale_id: sale.id,
          p_operation_id: form.operation_id,
          p_sales_location_id: form.sales_location_id,
          p_team_id: form.team_id,
          p_sale_date: form.sale_date,
          p_units_count: unitsCount,
          p_salesperson_member_id: form.salesperson_member_id || null,
          p_external_id: form.external_id.trim() || null,
          p_metadata: metadata,
        })

        if (error) throw error
        return
      }

      const { error } = await supabase.rpc('create_commercial_sale', {
        p_organization_id: orgId,
        p_operation_id: form.operation_id,
        p_sales_location_id: form.sales_location_id,
        p_team_id: form.team_id,
        p_sale_date: form.sale_date,
        p_units_count: unitsCount,
        p_salesperson_member_id: form.salesperson_member_id || null,
        p_external_id: form.external_id.trim() || null,
        p_metadata: metadata,
      })

      if (error) throw error
    },
    onSuccess: () => {
      toast.success(
        sale ? 'Venda pendente atualizada.' : 'Venda cadastrada como pendente.',
      )
      qc.invalidateQueries({ queryKey: ['commercial-sales'] })
      onClose()
    },
    onError: (error: Error) => toast.error(error.message),
  })

  function changeOperation(operationId: string) {
    setForm((current) => ({
      ...current,
      operation_id: operationId,
      sales_location_id: '',
      team_id: '',
      salesperson_member_id: '',
    }))
  }

  function changeLocation(salesLocationId: string) {
    setForm((current) => ({
      ...current,
      sales_location_id: salesLocationId,
      team_id: '',
      salesperson_member_id: '',
    }))
  }

  function changeTeam(teamId: string) {
    setForm((current) => ({
      ...current,
      team_id: teamId,
      salesperson_member_id: '',
    }))
  }

  return (
    <form
      className="space-y-4"
      onSubmit={(event) => {
        event.preventDefault()
        mutation.mutate()
      }}
    >
      {isEdit && (
        <div className="rounded-lg border border-amber-200 bg-amber-50 p-3 text-sm text-amber-900">
          Somente vendas pendentes podem ter seus dados operacionais corrigidos.
        </div>
      )}

      <div className="grid grid-cols-1 gap-4 sm:grid-cols-2">
        <div>
          <label className="form-label">Data da venda *</label>
          <input
            type="date"
            className="form-input"
            value={form.sale_date}
            onChange={(event) =>
              setForm((current) => ({ ...current, sale_date: event.target.value }))
            }
          />
        </div>

        <div>
          <label className="form-label">Unidades / cotas *</label>
          <input
            type="number"
            min={1}
            step={1}
            className="form-input"
            value={form.units_count}
            onChange={(event) =>
              setForm((current) => ({
                ...current,
                units_count: event.target.value,
              }))
            }
          />
        </div>

        <div className="sm:col-span-2">
          <label className="form-label">Operação *</label>
          <select
            className="form-input"
            value={form.operation_id}
            disabled={operationsLoading}
            onChange={(event) => changeOperation(event.target.value)}
          >
            <option value="">Selecione...</option>
            {operationOptions.map((operation) => (
              <option key={operation.id} value={operation.id}>
                {operation.name}
              </option>
            ))}
          </select>
        </div>

        <div className="sm:col-span-2">
          <label className="form-label">PDV *</label>
          <select
            className="form-input"
            value={form.sales_location_id}
            disabled={!form.operation_id || salesLocationsLoading}
            onChange={(event) => changeLocation(event.target.value)}
          >
            <option value="">Selecione...</option>
            {locationOptions.map((location) => (
              <option key={location.id} value={location.id}>
                {location.name}
              </option>
            ))}
          </select>
        </div>

        <div className="sm:col-span-2">
          <label className="form-label">Equipe *</label>
          <select
            className="form-input"
            value={form.team_id}
            disabled={!form.sales_location_id || teamsLoading}
            onChange={(event) => changeTeam(event.target.value)}
          >
            <option value="">Selecione...</option>
            {teamOptions.map((team) => (
              <option key={team.id} value={team.id}>
                {team.name}
              </option>
            ))}
          </select>
        </div>

        <div className="sm:col-span-2">
          <label className="form-label">Vendedor</label>
          <select
            className="form-input"
            value={form.salesperson_member_id}
            disabled={!form.team_id || salespersonsLoading}
            onChange={(event) =>
              setForm((current) => ({
                ...current,
                salesperson_member_id: event.target.value,
              }))
            }
          >
            <option value="">Sem vendedor identificado</option>
            {salespersonOptions.map((salesperson) => (
              <option key={salesperson.id} value={salesperson.id}>
                {salespersonLabel(salesperson)}
              </option>
            ))}
          </select>
          {!!form.team_id &&
            !salespersonsLoading &&
            salespersonOptions.length === 0 && (
              <p className="mt-1 text-xs text-amber-700">
                Nenhum vendedor ativo está vinculado a esta equipe. A venda pode ser
                registrada sem vendedor identificado.
              </p>
            )}
        </div>

        <div className="sm:col-span-2">
          <label className="form-label">Identificador externo</label>
          <input
            className="form-input"
            value={form.external_id}
            placeholder="Opcional"
            onChange={(event) =>
              setForm((current) => ({
                ...current,
                external_id: event.target.value,
              }))
            }
          />
          <p className="mt-1 text-xs text-gray-500">
            Use apenas quando existir um código de referência externo confiável para
            esta venda.
          </p>
        </div>
      </div>

      <div className="flex justify-end gap-3 pt-2">
        <button type="button" className="btn-secondary" onClick={onClose}>
          Cancelar
        </button>
        <button type="submit" className="btn-primary" disabled={mutation.isPending}>
          {mutation.isPending
            ? 'Salvando...'
            : sale
              ? 'Salvar alterações'
              : 'Cadastrar venda'}
        </button>
      </div>
    </form>
  )
}

function StatusChangeDialog({
  action,
  onClose,
}: {
  action: StatusActionState | null
  onClose: () => void
}) {
  const qc = useQueryClient()
  const [reason, setReason] = useState('')

  useEffect(() => {
    setReason('')
  }, [action?.sale.id, action?.targetStatus])

  const mutation = useMutation({
    mutationFn: async () => {
      if (!action) return

      const requiresReason =
        action.targetStatus === 'rejected' || action.targetStatus === 'cancelled'

      if (requiresReason && !reason.trim()) {
        throw new Error(
          action.targetStatus === 'rejected'
            ? 'Informe o motivo da rejeição.'
            : 'Informe o motivo do cancelamento.',
        )
      }

      const { error } = await supabase.rpc('change_commercial_sale_status', {
        p_sale_id: action.sale.id,
        p_target_status: action.targetStatus,
        p_reason: reason.trim() || null,
      })

      if (error) throw error
    },
    onSuccess: () => {
      if (!action) return

      toast.success(
        action.targetStatus === 'validated'
          ? 'Venda validada.'
          : action.targetStatus === 'rejected'
            ? 'Venda rejeitada.'
            : action.targetStatus === 'cancelled'
              ? 'Venda cancelada.'
              : 'Venda reaberta como pendente.',
      )
      qc.invalidateQueries({ queryKey: ['commercial-sales'] })
      onClose()
    },
    onError: (error: Error) => toast.error(error.message),
  })

  if (!action) return null

  const requiresReason =
    action.targetStatus === 'rejected' || action.targetStatus === 'cancelled'

  const title =
    action.targetStatus === 'validated'
      ? 'Validar venda'
      : action.targetStatus === 'rejected'
        ? 'Rejeitar venda'
        : action.targetStatus === 'cancelled'
          ? 'Cancelar venda'
          : 'Reabrir venda'

  const description =
    action.targetStatus === 'validated'
      ? 'Esta venda passará a compor a apuração de vendas validadas.'
      : action.targetStatus === 'rejected'
        ? 'A venda ficará rejeitada e poderá ser reaberta posteriormente.'
        : action.targetStatus === 'cancelled'
          ? 'O cancelamento é terminal neste workflow e não poderá ser revertido pela interface.'
          : 'A venda voltará ao estado pendente e poderá ser corrigida ou validada.'

  return (
    <Dialog
      open
      onOpenChange={(open) => {
        if (!open && !mutation.isPending) onClose()
      }}
    >
      <DialogContent>
        <DialogHeader>
          <DialogTitle>{title}</DialogTitle>
        </DialogHeader>

        <div className="space-y-4">
          <p className="text-sm text-gray-600">{description}</p>

          {requiresReason && (
            <div>
              <label className="form-label">Motivo *</label>
              <textarea
                className="form-input min-h-24 resize-y"
                value={reason}
                onChange={(event) => setReason(event.target.value)}
                placeholder={
                  action.targetStatus === 'rejected'
                    ? 'Informe por que a venda foi rejeitada.'
                    : 'Informe por que a venda foi cancelada.'
                }
              />
            </div>
          )}

          <div className="flex justify-end gap-3">
            <button
              type="button"
              className="btn-secondary"
              disabled={mutation.isPending}
              onClick={onClose}
            >
              Voltar
            </button>
            <button
              type="button"
              className="btn-primary"
              disabled={mutation.isPending}
              onClick={() => mutation.mutate()}
            >
              {mutation.isPending ? 'Processando...' : title}
            </button>
          </div>
        </div>
      </DialogContent>
    </Dialog>
  )
}

export default function CommercialSalesPage() {
  const { activeOrganization } = useAuth()
  const { canViewCommercialSales, canManageCommercialSales } = usePermissions()
  const orgId = activeOrganization?.id

  const [competenceFilter, setCompetenceFilter] = useState(
    currentMonthInputValue(),
  )
  const [statusFilter, setStatusFilter] = useState('')
  const [page, setPage] = useState(1)
  const [formOpen, setFormOpen] = useState(false)
  const [editSale, setEditSale] = useState<CommercialSaleRow | undefined>()
  const [statusAction, setStatusAction] = useState<StatusActionState | null>(null)

  const {
    data: salesResult,
    isLoading,
    isFetching,
    isError,
    error,
    refetch,
  } = useQuery({
    queryKey: [
      'commercial-sales',
      orgId,
      competenceFilter,
      statusFilter,
      page,
    ],
    enabled: !!orgId && canViewCommercialSales,
    queryFn: async () => {
      if (!orgId) return { rows: [] as CommercialSaleRow[], count: 0 }

      const from = (page - 1) * PAGE_SIZE
      const to = from + PAGE_SIZE - 1

      let query = supabase
        .from('commercial_sales')
        .select(
          `
            *,
            operation:operations!commercial_sales_operation_org_fkey(
              id,
              name
            ),
            sales_location:sales_locations!commercial_sales_location_org_operation_fkey(
              id,
              name
            ),
            team:teams!commercial_sales_team_org_fkey(
              id,
              name
            ),
            salesperson_member:organization_members!commercial_sales_salesperson_member_org_fkey(
              id,
              user_id,
              role,
              profile:profiles!organization_members_user_id_fkey(
                full_name,
                preferred_name,
                email
              )
            )
          `,
          { count: 'exact' },
        )
        .eq('organization_id', orgId)
        .is('archived_at', null)
        .order('sale_date', { ascending: false })
        .order('created_at', { ascending: false })

      if (competenceFilter) {
        query = query.eq('competence_month', `${competenceFilter}-01`)
      }

      if (statusFilter) {
        query = query.eq('validation_status', statusFilter)
      }

      const { data, error: queryError, count } = await query.range(from, to)
      if (queryError) throw queryError

      return {
        rows: (data ?? []) as CommercialSaleRow[],
        count: count ?? 0,
      }
    },
  })

  const sales = salesResult?.rows ?? []
  const totalCount = salesResult?.count ?? 0
  const totalPages = Math.max(1, Math.ceil(totalCount / PAGE_SIZE))

  useEffect(() => {
    if (page > totalPages) setPage(totalPages)
  }, [page, totalPages])

  if (!orgId) {
    return (
      <div className="page-container">
        <EmptyState icon={Briefcase} title="Nenhuma organização ativa" />
      </div>
    )
  }

  if (!canViewCommercialSales) {
    return (
      <div className="page-container">
        <EmptyState
          icon={Briefcase}
          title="Acesso não permitido"
          description="Seu perfil não possui acesso às vendas comerciais."
        />
      </div>
    )
  }

  return (
    <div className="page-container">
      <PageHeader
        title="Vendas"
        description={
          canManageCommercialSales
            ? 'Cadastre, corrija e valide as vendas comerciais da organização ativa.'
            : 'Consulte as vendas das equipes sob sua gestão.'
        }
        action={
          canManageCommercialSales ? (
            <button
              className="btn-primary"
              onClick={() => {
                setEditSale(undefined)
                setFormOpen(true)
              }}
            >
              <Plus className="h-4 w-4" />
              Nova venda
            </button>
          ) : undefined
        }
      />

      <div className="card mb-4 p-4">
        <div className="grid grid-cols-1 gap-3 sm:grid-cols-3">
          <div>
            <label className="form-label">Competência</label>
            <input
              type="month"
              className="form-input"
              value={competenceFilter}
              onChange={(event) => {
                setCompetenceFilter(event.target.value)
                setPage(1)
              }}
            />
          </div>

          <div>
            <label className="form-label">Status</label>
            <select
              className="form-input"
              value={statusFilter}
              onChange={(event) => {
                setStatusFilter(event.target.value)
                setPage(1)
              }}
            >
              <option value="">Todos</option>
              <option value="pending">Pendentes</option>
              <option value="validated">Validadas</option>
              <option value="rejected">Rejeitadas</option>
              <option value="cancelled">Canceladas</option>
            </select>
          </div>

          <div className="flex items-end">
            <div className="w-full rounded-lg bg-gray-50 px-3 py-2.5 text-sm text-gray-600">
              <span className="font-semibold text-gray-900">{totalCount}</span>{' '}
              venda(s) encontrada(s)
              {isFetching && !isLoading ? ' — atualizando...' : ''}
            </div>
          </div>
        </div>
      </div>

      {isLoading ? (
        <div className="flex justify-center py-12">
          <LoadingSpinner size="lg" />
        </div>
      ) : isError ? (
        <div className="card p-6 text-center">
          <p className="text-sm font-medium text-red-700">
            Não foi possível carregar as vendas.
          </p>
          <p className="mt-1 text-xs text-gray-500">
            {error instanceof Error ? error.message : 'Erro desconhecido.'}
          </p>
          <button className="btn-secondary mt-4" onClick={() => refetch()}>
            Tentar novamente
          </button>
        </div>
      ) : sales.length === 0 ? (
        <EmptyState
          icon={Briefcase}
          title="Nenhuma venda encontrada"
          description={
            canManageCommercialSales
              ? 'Cadastre uma venda ou ajuste os filtros da consulta.'
              : 'Nenhuma venda está disponível para suas equipes nos filtros selecionados.'
          }
        />
      ) : (
        <>
          <div className="card overflow-hidden">
            <div className="overflow-x-auto">
              <table className="min-w-full divide-y divide-gray-200">
                <thead className="bg-gray-50">
                  <tr>
                    <th className="px-4 py-3 text-left text-xs font-semibold uppercase tracking-wide text-gray-500">
                      Venda
                    </th>
                    <th className="px-4 py-3 text-left text-xs font-semibold uppercase tracking-wide text-gray-500">
                      Estrutura
                    </th>
                    <th className="px-4 py-3 text-left text-xs font-semibold uppercase tracking-wide text-gray-500">
                      Vendedor
                    </th>
                    <th className="px-4 py-3 text-center text-xs font-semibold uppercase tracking-wide text-gray-500">
                      Unidades
                    </th>
                    <th className="px-4 py-3 text-left text-xs font-semibold uppercase tracking-wide text-gray-500">
                      Status
                    </th>
                    {canManageCommercialSales && (
                      <th className="px-4 py-3 text-right text-xs font-semibold uppercase tracking-wide text-gray-500">
                        Ações
                      </th>
                    )}
                  </tr>
                </thead>

                <tbody className="divide-y divide-gray-100 bg-white">
                  {sales.map((sale) => {
                    const operation = firstRelation(sale.operation)
                    const location = firstRelation(sale.sales_location)
                    const team = firstRelation(sale.team)
                    const salesperson = firstRelation(sale.salesperson_member)

                    return (
                      <tr key={sale.id} className="align-top">
                        <td className="px-4 py-4">
                          <p className="text-sm font-medium text-gray-900">
                            {formatDate(sale.sale_date)}
                          </p>
                          <p className="mt-1 text-xs text-gray-500">
                            {sale.external_id
                              ? `Ref. ${sale.external_id}`
                              : `ID ${sale.id.slice(0, 8)}`}
                          </p>
                        </td>

                        <td className="px-4 py-4">
                          <p className="text-sm text-gray-900">
                            {location?.name ?? 'PDV não identificado'}
                          </p>
                          <p className="mt-1 text-xs text-gray-500">
                            {operation?.name ?? 'Operação não identificada'} ·{' '}
                            {team?.name ?? 'Equipe não identificada'}
                          </p>
                        </td>

                        <td className="px-4 py-4">
                          <p className="text-sm text-gray-900">
                            {salespersonLabel(salesperson)}
                          </p>
                        </td>

                        <td className="px-4 py-4 text-center">
                          <span className="inline-flex min-w-8 justify-center rounded-full bg-gray-100 px-2 py-1 text-xs font-semibold text-gray-700">
                            {sale.units_count}
                          </span>
                        </td>

                        <td className="px-4 py-4">
                          <span
                            className={`inline-flex rounded-full px-2.5 py-1 text-xs font-medium ${validationStatusClass(
                              sale.validation_status,
                            )}`}
                          >
                            {validationStatusLabel(sale.validation_status)}
                          </span>

                          {sale.status_reason && (
                            <p
                              className="mt-1 max-w-56 text-xs text-gray-500"
                              title={sale.status_reason}
                            >
                              {sale.status_reason}
                            </p>
                          )}
                        </td>

                        {canManageCommercialSales && (
                          <td className="px-4 py-4">
                            <div className="flex flex-wrap justify-end gap-2">
                              {sale.validation_status === 'pending' && (
                                <>
                                  <button
                                    className="btn-secondary px-2 py-1 text-xs"
                                    onClick={() => {
                                      setEditSale(sale)
                                      setFormOpen(true)
                                    }}
                                  >
                                    <Pencil className="h-3.5 w-3.5" />
                                    Editar
                                  </button>

                                  <button
                                    className="inline-flex items-center gap-1 rounded-md bg-green-50 px-2 py-1 text-xs font-medium text-green-700 hover:bg-green-100"
                                    onClick={() =>
                                      setStatusAction({
                                        sale,
                                        targetStatus: 'validated',
                                      })
                                    }
                                  >
                                    <BadgeCheck className="h-3.5 w-3.5" />
                                    Validar
                                  </button>

                                  <button
                                    className="inline-flex items-center gap-1 rounded-md bg-red-50 px-2 py-1 text-xs font-medium text-red-700 hover:bg-red-100"
                                    onClick={() =>
                                      setStatusAction({
                                        sale,
                                        targetStatus: 'rejected',
                                      })
                                    }
                                  >
                                    <XCircle className="h-3.5 w-3.5" />
                                    Rejeitar
                                  </button>

                                  <button
                                    className="inline-flex items-center gap-1 rounded-md bg-gray-100 px-2 py-1 text-xs font-medium text-gray-700 hover:bg-gray-200"
                                    onClick={() =>
                                      setStatusAction({
                                        sale,
                                        targetStatus: 'cancelled',
                                      })
                                    }
                                  >
                                    <Ban className="h-3.5 w-3.5" />
                                    Cancelar
                                  </button>
                                </>
                              )}

                              {sale.validation_status === 'rejected' && (
                                <button
                                  className="btn-secondary px-2 py-1 text-xs"
                                  onClick={() =>
                                    setStatusAction({ sale, targetStatus: 'pending' })
                                  }
                                >
                                  <RotateCcw className="h-3.5 w-3.5" />
                                  Reabrir
                                </button>
                              )}

                              {sale.validation_status === 'validated' && (
                                <button
                                  className="inline-flex items-center gap-1 rounded-md bg-gray-100 px-2 py-1 text-xs font-medium text-gray-700 hover:bg-gray-200"
                                  onClick={() =>
                                    setStatusAction({
                                      sale,
                                      targetStatus: 'cancelled',
                                    })
                                  }
                                >
                                  <Ban className="h-3.5 w-3.5" />
                                  Cancelar
                                </button>
                              )}

                              {sale.validation_status === 'cancelled' && (
                                <span className="inline-flex items-center gap-1 text-xs text-gray-400">
                                  <Clock3 className="h-3.5 w-3.5" />
                                  Encerrada
                                </span>
                              )}
                            </div>
                          </td>
                        )}
                      </tr>
                    )
                  })}
                </tbody>
              </table>
            </div>
          </div>

          <div className="mt-4 flex flex-col gap-3 sm:flex-row sm:items-center sm:justify-between">
            <p className="text-xs text-gray-500">
              Página {page} de {totalPages} · {totalCount} registro(s)
            </p>

            <div className="flex items-center gap-2">
              <button
                className="btn-secondary px-3 py-1.5 text-xs"
                disabled={page <= 1}
                onClick={() => setPage((current) => Math.max(1, current - 1))}
              >
                <ChevronLeft className="h-4 w-4" />
                Anterior
              </button>

              <button
                className="btn-secondary px-3 py-1.5 text-xs"
                disabled={page >= totalPages}
                onClick={() =>
                  setPage((current) => Math.min(totalPages, current + 1))
                }
              >
                Próxima
                <ChevronRight className="h-4 w-4" />
              </button>
            </div>
          </div>
        </>
      )}

      <Dialog
        open={formOpen}
        onOpenChange={(open) => {
          setFormOpen(open)
          if (!open) setEditSale(undefined)
        }}
      >
        <DialogContent className="max-h-[90vh] overflow-y-auto">
          <DialogHeader>
            <DialogTitle>
              {editSale ? 'Editar venda pendente' : 'Nova venda'}
            </DialogTitle>
          </DialogHeader>

          {formOpen && (
            <CommercialSaleForm
              orgId={orgId}
              sale={editSale}
              onClose={() => {
                setFormOpen(false)
                setEditSale(undefined)
              }}
            />
          )}
        </DialogContent>
      </Dialog>

      <StatusChangeDialog
        action={statusAction}
        onClose={() => setStatusAction(null)}
      />
    </div>
  )
}
