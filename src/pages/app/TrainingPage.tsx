import { useState } from 'react'
import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query'
import {
  Award,
  BookOpen,
  CalendarDays,
  Clock3,
  Pencil,
  ShieldAlert,
} from 'lucide-react'
import { toast } from 'sonner'
import { supabase } from '@/lib/supabase'
import { useAuth } from '@/contexts/AuthContext'
import { useCommercialPlanReference } from '@/hooks/useCommercialPlan'
import type { TrainingModule, TrainingStatus } from '@/types/commercialPlan'
import { TRAINING_STATUS_LABELS } from '@/lib/commercialPlan'
import PageHeader from '@/components/shared/PageHeader'
import LoadingSpinner from '@/components/shared/LoadingSpinner'
import EmptyState from '@/components/shared/EmptyState'
import {
  Dialog,
  DialogContent,
  DialogHeader,
  DialogTitle,
} from '@/components/ui/dialog'

function TrainingEditor({
  module,
  onClose,
}: {
  module: TrainingModule
  onClose: () => void
}) {
  const { profile } = useAuth()
  const qc = useQueryClient()
  const [title, setTitle] = useState(module.title)
  const [objective, setObjective] = useState(module.objective)
  const [duration, setDuration] = useState(String(module.duration_minutes))
  const [score, setScore] = useState(String(module.passing_score))
  const [scheduledDate, setScheduledDate] = useState(
    module.scheduled_date ?? '',
  )
  const [status, setStatus] = useState<TrainingStatus>(module.status)

  const mutation = useMutation({
    mutationFn: async () => {
      const { error } = await supabase
        .from('training_modules')
        .update({
          title,
          objective,
          duration_minutes: Number(duration),
          passing_score: Number(score),
          scheduled_date: scheduledDate || null,
          status,
          completed_date:
            status === 'completed'
              ? new Date().toISOString().slice(0, 10)
              : null,
          updated_by: profile?.id,
        })
        .eq('id', module.id)

      if (error) throw error
    },
    onSuccess: () => {
      toast.success('Treinamento atualizado.')
      qc.invalidateQueries({ queryKey: ['training-modules'] })
      onClose()
    },
    onError: (error: Error) => toast.error(error.message),
  })

  return (
    <div className="space-y-4">
      <div>
        <label className="form-label">Módulo</label>
        <input
          className="form-input"
          value={title}
          onChange={(event) => setTitle(event.target.value)}
        />
      </div>

      <div>
        <label className="form-label">Objetivo / conteúdo central</label>
        <textarea
          className="form-input min-h-24"
          value={objective}
          onChange={(event) => setObjective(event.target.value)}
        />
      </div>

      <div className="grid grid-cols-2 gap-3">
        <div>
          <label className="form-label">Duração (min)</label>
          <input
            type="number"
            className="form-input"
            value={duration}
            onChange={(event) => setDuration(event.target.value)}
          />
        </div>

        <div>
          <label className="form-label">Nota mínima</label>
          <input
            type="number"
            className="form-input"
            value={score}
            onChange={(event) => setScore(event.target.value)}
          />
        </div>

        <div>
          <label className="form-label">Data planejada</label>
          <input
            type="date"
            className="form-input"
            value={scheduledDate}
            onChange={(event) => setScheduledDate(event.target.value)}
          />
        </div>

        <div>
          <label className="form-label">Status</label>
          <select
            className="form-input"
            value={status}
            onChange={(event) =>
              setStatus(event.target.value as TrainingStatus)
            }
          >
            <option value="planned">Planejado</option>
            <option value="in_progress">Em andamento</option>
            <option value="completed">Concluído</option>
          </select>
        </div>
      </div>

      <div className="flex justify-end gap-2">
        <button className="btn-secondary" onClick={onClose}>
          Cancelar
        </button>
        <button
          className="btn-primary"
          onClick={() => mutation.mutate()}
          disabled={mutation.isPending}
        >
          {mutation.isPending ? 'Salvando...' : 'Salvar'}
        </button>
      </div>
    </div>
  )
}

export default function TrainingPage() {
  const { activeOrganization, user, isAdmin, isDirector } = useAuth()
  const orgId = activeOrganization?.id
  const canManage = isAdmin || isDirector
  const [editing, setEditing] = useState<TrainingModule | null>(null)
  const { data: plan } = useCommercialPlanReference(orgId)

  const { data: modules, isLoading } = useQuery({
    queryKey: ['training-modules', plan?.id, user?.id],
    enabled: !!plan?.id && !!user?.id,
    queryFn: async () => {
      const { data, error } = await supabase
        .from('training_modules')
        .select('*')
        .eq('plan_id', plan!.id)
        .neq('status', 'archived')
        .order('sequence_no')

      if (error) throw error
      return (data ?? []) as TrainingModule[]
    },
  })

  if (isLoading) {
    return (
      <div className="page-container flex min-h-[400px] items-center justify-center">
        <LoadingSpinner size="lg" />
      </div>
    )
  }

  if (!modules?.length) {
    return (
      <div className="page-container">
        <EmptyState icon={BookOpen} title="Nenhum treinamento cadastrado" />
      </div>
    )
  }

  const completed = modules.filter(
    (module) => module.status === 'completed',
  ).length

  return (
    <div className="page-container">
      <PageHeader
        title="Treinamentos"
        description="Trilha aplicada: explicação, demonstração, simulação e atendimento real observado."
      />

      <div className="mb-6 grid gap-4 sm:grid-cols-3">
        <div className="card p-4">
          <BookOpen className="mb-2 h-5 w-5 text-brand-700" />
          <p className="text-2xl font-bold text-gray-900">{modules.length}</p>
          <p className="text-sm text-gray-500">módulos do programa</p>
        </div>

        <div className="card p-4">
          <Award className="mb-2 h-5 w-5 text-amber-600" />
          <p className="text-2xl font-bold text-gray-900">80%</p>
          <p className="text-sm text-gray-500">nota mínima recomendada</p>
        </div>

        <div className="card p-4">
          <CalendarDays className="mb-2 h-5 w-5 text-green-600" />
          <p className="text-2xl font-bold text-gray-900">
            {completed}/{modules.length}
          </p>
          <p className="text-sm text-gray-500">módulos concluídos</p>
        </div>
      </div>

      <div className="grid gap-4 lg:grid-cols-2">
        {modules.map((module) => (
          <article key={module.id} className="card p-5">
            <div className="flex items-start justify-between gap-3">
              <div className="flex items-start gap-3">
                <div className="flex h-9 w-9 shrink-0 items-center justify-center rounded-full bg-brand-100 text-sm font-bold text-brand-800">
                  {module.sequence_no}
                </div>
                <div>
                  <h2 className="font-semibold text-gray-900">
                    {module.title}
                  </h2>
                  <p className="mt-1 text-sm leading-5 text-gray-600">
                    {module.objective}
                  </p>
                </div>
              </div>

              {canManage && (
                <button
                  className="rounded p-1.5 text-gray-400 hover:bg-gray-100"
                  onClick={() => setEditing(module)}
                >
                  <Pencil className="h-4 w-4" />
                </button>
              )}
            </div>

            <div className="mt-4 flex flex-wrap gap-2 text-xs">
              <span className="badge bg-gray-100 text-gray-700">
                <Clock3 className="mr-1 h-3 w-3" />
                {module.duration_minutes} min
              </span>
              <span
                className={`badge ${
                  module.status === 'completed'
                    ? 'badge-active'
                    : 'badge-inactive'
                }`}
              >
                {TRAINING_STATUS_LABELS[module.status]}
              </span>
              {module.scheduled_date && (
                <span className="badge bg-blue-100 text-blue-800">
                  {new Date(
                    `${module.scheduled_date}T12:00:00`,
                  ).toLocaleDateString('pt-BR')}
                </span>
              )}
            </div>

            {module.critical_error && (
              <div className="mt-4 flex items-start gap-2 rounded-lg border border-red-100 bg-red-50 p-3">
                <ShieldAlert className="mt-0.5 h-4 w-4 shrink-0 text-red-600" />
                <p className="text-xs text-red-800">
                  <strong>Erro crítico:</strong> {module.critical_error}
                </p>
              </div>
            )}
          </article>
        ))}
      </div>

      <Dialog
        open={!!editing}
        onOpenChange={(open) => !open && setEditing(null)}
      >
        <DialogContent>
          <DialogHeader>
            <DialogTitle>Editar treinamento</DialogTitle>
          </DialogHeader>
          {editing && (
            <TrainingEditor
              module={editing}
              onClose={() => setEditing(null)}
            />
          )}
        </DialogContent>
      </Dialog>
    </div>
  )
}
