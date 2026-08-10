import { useMemo, useState } from 'react'
import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query'
import { CheckCircle2, Circle, Filter, Zap } from 'lucide-react'
import { toast } from 'sonner'
import { supabase } from '@/lib/supabase'
import { useAuth } from '@/contexts/AuthContext'
import { useCommercialPlan } from '@/hooks/useCommercialPlan'
import type { ActionStatus, PlanAction, PlanPhase } from '@/types/commercialPlan'
import { ACTION_CATEGORY_LABELS, ACTION_STATUS_LABELS, RESPONSIBLE_ROLE_LABELS } from '@/lib/commercialPlan'
import PageHeader from '@/components/shared/PageHeader'
import LoadingSpinner from '@/components/shared/LoadingSpinner'
import EmptyState from '@/components/shared/EmptyState'

export default function ActionsPage() {
  const { activeOrganization, isAdmin, isDirector, profile } = useAuth()
  const orgId = activeOrganization?.id
  const canUpdate = isAdmin || isDirector
  const qc = useQueryClient()
  const [statusFilter, setStatusFilter] = useState('all')
  const [phaseFilter, setPhaseFilter] = useState('all')
  const { data: plan } = useCommercialPlan(orgId)
  const { data: phases } = useQuery({ queryKey: ['plan-phases', plan?.id], enabled: !!plan?.id, queryFn: async () => { const { data, error } = await supabase.from('plan_phases').select('*').eq('plan_id', plan!.id).order('sequence_no'); if (error) throw error; return (data ?? []) as PlanPhase[] } })
  const { data: actions, isLoading } = useQuery({ queryKey: ['plan-actions', plan?.id], enabled: !!plan?.id, queryFn: async () => { const { data, error } = await supabase.from('plan_actions').select('*').eq('plan_id', plan!.id).neq('status', 'archived').order('due_day'); if (error) throw error; return (data ?? []) as PlanAction[] } })
  const mutation = useMutation({ mutationFn: async ({ id, status }: { id: string; status: ActionStatus }) => { const { error } = await supabase.from('plan_actions').update({ status, completed_at: status === 'completed' ? new Date().toISOString() : null, updated_by: profile?.id }).eq('id', id); if (error) throw error }, onSuccess: () => { toast.success('Ação atualizada.'); qc.invalidateQueries({ queryKey: ['plan-actions'] }); qc.invalidateQueries({ queryKey: ['plan-phases'] }) }, onError: (error: Error) => toast.error(error.message) })
  const phaseNames = useMemo(() => new Map((phases ?? []).map((phase) => [phase.id, `${phase.sequence_no}. ${phase.name}`])), [phases])
  const filtered = (actions ?? []).filter((action) => (statusFilter === 'all' || action.status === statusFilter) && (phaseFilter === 'all' || action.phase_id === phaseFilter))

  if (isLoading) return <div className="page-container flex min-h-[400px] items-center justify-center"><LoadingSpinner size="lg" /></div>
  if (!actions?.length) return <div className="page-container"><EmptyState icon={Zap} title="Nenhuma ação cadastrada" /></div>

  return <div className="page-container"><PageHeader title="Ações" description="Execução do plano com responsáveis, prazos e evidências." /><div className="mb-5 flex flex-wrap items-center gap-3 rounded-lg border border-gray-200 bg-white p-3"><Filter className="h-4 w-4 text-gray-400" /><select className="form-input w-auto min-w-44" value={phaseFilter} onChange={(e) => setPhaseFilter(e.target.value)}><option value="all">Todas as fases</option>{(phases ?? []).map((phase) => <option key={phase.id} value={phase.id}>{phase.sequence_no}. {phase.name}</option>)}</select><select className="form-input w-auto min-w-40" value={statusFilter} onChange={(e) => setStatusFilter(e.target.value)}><option value="all">Todos os status</option>{Object.entries(ACTION_STATUS_LABELS).filter(([key]) => key !== 'archived').map(([key, label]) => <option key={key} value={key}>{label}</option>)}</select><span className="ml-auto text-sm text-gray-500">{filtered.length} ação(ões)</span></div><div className="space-y-3">{filtered.map((action) => <article key={action.id} className="card p-4"><div className="flex flex-col gap-4 sm:flex-row sm:items-start"><div className="flex min-w-0 flex-1 items-start gap-3">{action.status === 'completed' ? <CheckCircle2 className="mt-0.5 h-5 w-5 shrink-0 text-green-600" /> : <Circle className="mt-0.5 h-5 w-5 shrink-0 text-gray-300" />}<div><div className="flex flex-wrap items-center gap-2"><h2 className="text-sm font-semibold text-gray-900">{action.title}</h2><span className="badge bg-gray-100 text-gray-700">{ACTION_CATEGORY_LABELS[action.category] ?? action.category}</span><span className={`badge ${action.priority === 'critical' ? 'bg-red-100 text-red-800' : action.priority === 'high' ? 'bg-amber-100 text-amber-800' : 'bg-blue-50 text-blue-700'}`}>{action.priority === 'critical' ? 'Crítica' : action.priority === 'high' ? 'Alta' : action.priority === 'medium' ? 'Média' : 'Baixa'}</span></div><p className="mt-1 text-sm text-gray-600">{action.description}</p><p className="mt-2 text-xs text-gray-400">{action.phase_id ? phaseNames.get(action.phase_id) : 'Sem fase'} · {RESPONSIBLE_ROLE_LABELS[action.responsible_role] ?? action.responsible_role}{action.due_day ? ` · dia ${action.due_day}` : ''}</p></div></div>{canUpdate && <select className="form-input w-full sm:w-44" value={action.status} onChange={(e) => mutation.mutate({ id: action.id, status: e.target.value as ActionStatus })}>{Object.entries(ACTION_STATUS_LABELS).filter(([key]) => key !== 'archived').map(([key, label]) => <option key={key} value={key}>{label}</option>)}</select>}</div></article>)}</div></div>
}
