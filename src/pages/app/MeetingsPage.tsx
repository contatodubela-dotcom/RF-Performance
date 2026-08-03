import { useState } from 'react'
import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query'
import { CalendarClock, Clock3, Plus, Users2 } from 'lucide-react'
import { toast } from 'sonner'
import { supabase } from '@/lib/supabase'
import { useAuth } from '@/contexts/AuthContext'
import { useCommercialPlanReference } from '@/hooks/useCommercialPlan'
import type { ManagementRitual, MeetingRecord } from '@/types/commercialPlan'
import { formatDateTime } from '@/lib/formatters'
import PageHeader from '@/components/shared/PageHeader'
import LoadingSpinner from '@/components/shared/LoadingSpinner'
import EmptyState from '@/components/shared/EmptyState'
import {
  Dialog,
  DialogContent,
  DialogHeader,
  DialogTitle,
} from '@/components/ui/dialog'

interface MeetingFormProps {
  orgId: string
  planId: string
  rituals: ManagementRitual[]
  teams: { id: string; name: string }[]
  onClose: () => void
}

function MeetingForm({
  orgId,
  planId,
  rituals,
  teams,
  onClose,
}: MeetingFormProps) {
  const { profile, activeMembership, isAdmin, isDirector } = useAuth()
  const qc = useQueryClient()
  const [title, setTitle] = useState('')
  const [ritualId, setRitualId] = useState('')
  const [teamId, setTeamId] = useState('')
  const [meetingAt, setMeetingAt] = useState('')
  const [summary, setSummary] = useState('')
  const [decisions, setDecisions] = useState('')
  const [nextSteps, setNextSteps] = useState('')

  const mutation = useMutation({
    mutationFn: async () => {
      if (!title || !meetingAt) {
        throw new Error('Informe título e data da reunião.')
      }

      if (!(isAdmin || isDirector) && !teamId) {
        throw new Error('Selecione a equipe da reunião.')
      }

      const { error } = await supabase.from('meeting_records').insert({
        organization_id: orgId,
        plan_id: planId,
        ritual_id: ritualId || null,
        team_id: teamId || null,
        title,
        meeting_at: new Date(meetingAt).toISOString(),
        summary: summary || null,
        decisions: decisions || null,
        next_steps: nextSteps || null,
        status: summary ? 'held' : 'scheduled',
        created_by: profile?.id,
        metadata: {
          author_member_id: activeMembership?.id ?? null,
        },
      })

      if (error) throw error
    },
    onSuccess: () => {
      toast.success('Reunião registrada.')
      qc.invalidateQueries({ queryKey: ['meeting-records'] })
      onClose()
    },
    onError: (error: Error) => toast.error(error.message),
  })

  return (
    <div className="space-y-4">
      <div>
        <label className="form-label">Título *</label>
        <input
          className="form-input"
          value={title}
          onChange={(event) => setTitle(event.target.value)}
          placeholder="Ex.: fechamento diário da equipe"
        />
      </div>

      <div className="grid grid-cols-2 gap-3">
        <div>
          <label className="form-label">Ritual</label>
          <select
            className="form-input"
            value={ritualId}
            onChange={(event) => setRitualId(event.target.value)}
          >
            <option value="">Selecione...</option>
            {rituals.map((ritual) => (
              <option key={ritual.id} value={ritual.id}>
                {ritual.title}
              </option>
            ))}
          </select>
        </div>

        <div>
          <label className="form-label">Equipe</label>
          <select
            className="form-input"
            value={teamId}
            onChange={(event) => setTeamId(event.target.value)}
          >
            <option value="">Organização / geral</option>
            {teams.map((team) => (
              <option key={team.id} value={team.id}>
                {team.name}
              </option>
            ))}
          </select>
        </div>
      </div>

      <div>
        <label className="form-label">Data e hora *</label>
        <input
          type="datetime-local"
          className="form-input"
          value={meetingAt}
          onChange={(event) => setMeetingAt(event.target.value)}
        />
      </div>

      <div>
        <label className="form-label">Resumo</label>
        <textarea
          className="form-input min-h-20"
          value={summary}
          onChange={(event) => setSummary(event.target.value)}
        />
      </div>

      <div>
        <label className="form-label">Decisões</label>
        <textarea
          className="form-input min-h-20"
          value={decisions}
          onChange={(event) => setDecisions(event.target.value)}
        />
      </div>

      <div>
        <label className="form-label">Próximos passos</label>
        <textarea
          className="form-input min-h-20"
          value={nextSteps}
          onChange={(event) => setNextSteps(event.target.value)}
        />
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
          {mutation.isPending ? 'Salvando...' : 'Registrar'}
        </button>
      </div>
    </div>
  )
}

export default function MeetingsPage() {
  const {
    activeOrganization,
    user,
    isAdmin,
    isDirector,
    isSupervisor,
    isSalesperson,
  } = useAuth()
  const orgId = activeOrganization?.id
  const canCreate = isAdmin || isDirector || isSupervisor
  const [open, setOpen] = useState(false)
  const { data: plan } = useCommercialPlanReference(orgId)

  const {
    data: rituals,
    isLoading: ritualsLoading,
  } = useQuery({
    queryKey: ['management-rituals', plan?.id, user?.id],
    enabled: !!plan?.id && !!user?.id,
    queryFn: async () => {
      const { data, error } = await supabase.rpc(
        'get_management_rituals_for_current_user',
        { p_plan_id: plan!.id },
      )

      if (error) throw error
      return (data ?? []) as ManagementRitual[]
    },
  })

  const {
    data: records,
    isLoading: recordsLoading,
  } = useQuery({
    queryKey: ['meeting-records', orgId, user?.id],
    enabled: !!orgId && !!user?.id,
    queryFn: async () => {
      const { data, error } = await supabase
        .from('meeting_records')
        .select(
          'id, organization_id, plan_id, ritual_id, team_id, title, meeting_at, summary, decisions, next_steps, attendees_count, status',
        )
        .eq('organization_id', orgId!)
        .neq('status', 'archived')
        .order('meeting_at', { ascending: false })

      if (error) throw error
      return (data ?? []) as MeetingRecord[]
    },
  })

  const { data: teams } = useQuery({
    queryKey: ['meeting-teams', orgId, user?.id],
    enabled: !!orgId && !!user?.id && canCreate,
    queryFn: async () => {
      const { data, error } = await supabase
        .from('teams')
        .select('id, name')
        .eq('organization_id', orgId!)
        .eq('status', 'active')

      if (error) throw error
      return data ?? []
    },
  })

  if (ritualsLoading || recordsLoading) {
    return (
      <div className="page-container flex min-h-[400px] items-center justify-center">
        <LoadingSpinner size="lg" />
      </div>
    )
  }

  const pageDescription = isSalesperson
    ? 'Encontros, compromissos e rituais relacionados à sua equipe e ao seu desenvolvimento.'
    : isSupervisor
      ? 'Cadência operacional e tática das equipes sob sua responsabilidade.'
      : 'Cadência de gestão curta, objetiva e orientada a responsáveis e próximos passos.'

  return (
    <div className="page-container">
      <PageHeader
        title="Reuniões"
        description={pageDescription}
        action={
          canCreate ? (
            <button
              className="btn-primary flex items-center gap-2"
              onClick={() => setOpen(true)}
            >
              <Plus className="h-4 w-4" />
              Registrar reunião
            </button>
          ) : undefined
        }
      />

      <h2 className="mb-3 font-semibold text-gray-900">
        {isSalesperson ? 'Rituais da sua rotina' : 'Rituais planejados'}
      </h2>

      {(rituals ?? []).length > 0 ? (
        <div className="mb-8 grid gap-4 md:grid-cols-2 xl:grid-cols-3">
          {(rituals ?? []).map((ritual) => (
            <article key={ritual.id} className="card p-4">
              <div className="flex items-start gap-3">
                <div className="flex h-9 w-9 shrink-0 items-center justify-center rounded-lg bg-brand-100">
                  <CalendarClock className="h-5 w-5 text-brand-700" />
                </div>
                <div>
                  <h3 className="text-sm font-semibold text-gray-900">
                    {ritual.title}
                  </h3>
                  <p className="mt-1 text-xs text-gray-500">
                    {ritual.frequency_label} · {ritual.responsible_role}
                  </p>
                </div>
              </div>
              <p className="mt-3 text-sm text-gray-600">
                {ritual.expected_output}
              </p>
              <p className="mt-3 flex items-center gap-1 text-xs text-gray-400">
                <Clock3 className="h-3.5 w-3.5" />
                {ritual.duration_minutes} minutos
              </p>
            </article>
          ))}
        </div>
      ) : (
        <div className="card mb-8">
          <EmptyState
            icon={CalendarClock}
            title="Nenhum ritual disponível para este perfil"
            description="Os rituais são exibidos de acordo com a responsabilidade de cada usuário."
          />
        </div>
      )}

      <h2 className="mb-3 font-semibold text-gray-900">
        {isSalesperson ? 'Suas reuniões' : 'Registros reais'}
      </h2>

      {records?.length ? (
        <div className="space-y-3">
          {records.map((record) => (
            <article key={record.id} className="card p-4">
              <div className="flex flex-col justify-between gap-3 sm:flex-row">
                <div>
                  <h3 className="text-sm font-semibold text-gray-900">
                    {record.title}
                  </h3>
                  <p className="mt-1 text-xs text-gray-400">
                    {formatDateTime(record.meeting_at)}
                  </p>
                  {record.summary && (
                    <p className="mt-2 text-sm text-gray-600">
                      {record.summary}
                    </p>
                  )}
                </div>
                <span
                  className={`badge ${
                    record.status === 'held'
                      ? 'badge-active'
                      : 'badge-inactive'
                  }`}
                >
                  {record.status === 'held'
                    ? 'Realizada'
                    : record.status === 'scheduled'
                      ? 'Agendada'
                      : 'Cancelada'}
                </span>
              </div>

              {record.next_steps && (
                <div className="mt-3 rounded-lg bg-gray-50 p-3 text-sm text-gray-700">
                  <strong>Próximos passos:</strong> {record.next_steps}
                </div>
              )}
            </article>
          ))}
        </div>
      ) : (
        <div className="card">
          <EmptyState
            icon={Users2}
            title="Nenhuma reunião vinculada ao seu perfil"
            description={
              isSalesperson
                ? 'Reuniões da sua equipe aparecerão aqui quando forem registradas.'
                : 'Os registros aparecerão quando a execução das reuniões for iniciada.'
            }
          />
        </div>
      )}

      {canCreate && (
        <Dialog open={open} onOpenChange={setOpen}>
          <DialogContent>
            <DialogHeader>
              <DialogTitle>Registrar reunião</DialogTitle>
            </DialogHeader>
            {orgId && plan && (
              <MeetingForm
                orgId={orgId}
                planId={plan.id}
                rituals={rituals ?? []}
                teams={teams ?? []}
                onClose={() => setOpen(false)}
              />
            )}
          </DialogContent>
        </Dialog>
      )}
    </div>
  )
}
