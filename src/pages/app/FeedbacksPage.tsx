import { useMemo, useState } from 'react'
import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query'
import { MessageSquare, Plus } from 'lucide-react'
import { toast } from 'sonner'
import { supabase } from '@/lib/supabase'
import { useAuth } from '@/contexts/AuthContext'
import { useCommercialPlanReference } from '@/hooks/useCommercialPlan'
import type { FeedbackRecord } from '@/types/commercialPlan'
import { formatDate } from '@/lib/formatters'
import PageHeader from '@/components/shared/PageHeader'
import LoadingSpinner from '@/components/shared/LoadingSpinner'
import EmptyState from '@/components/shared/EmptyState'
import {
  Dialog,
  DialogContent,
  DialogHeader,
  DialogTitle,
} from '@/components/ui/dialog'

type MemberOption = {
  id: string
  user_id: string
  role: string
  profiles:
    | { full_name: string | null; email: string | null }
    | { full_name: string | null; email: string | null }[]
    | null
}

function profileOf(value: MemberOption['profiles']) {
  return Array.isArray(value) ? (value[0] ?? null) : value
}

const FRAMEWORK = [
  ['Fato', 'O que observei ou qual indicador mudou?'],
  ['Impacto', 'Como isso afeta o cliente, o funil ou o resultado?'],
  ['Causa', 'É esforço, técnica, produto, processo ou contexto?'],
  ['Ação', 'Qual comportamento específico deve mudar?'],
  ['Prazo', 'Quando vamos observar novamente?'],
  ['Evidência', 'Qual indicador ou situação mostrará a evolução?'],
]

interface FeedbackFormProps {
  orgId: string
  planId: string
  members: MemberOption[]
  teams: { id: string; name: string }[]
  onClose: () => void
}

function FeedbackForm({
  orgId,
  planId,
  members,
  teams,
  onClose,
}: FeedbackFormProps) {
  const { profile, activeMembership } = useAuth()
  const qc = useQueryClient()
  const [target, setTarget] = useState('')
  const [team, setTeam] = useState('')
  const [type, setType] = useState('coaching')
  const [occurredOn, setOccurredOn] = useState(
    new Date().toISOString().slice(0, 10),
  )
  const [fact, setFact] = useState('')
  const [impact, setImpact] = useState('')
  const [cause, setCause] = useState('')
  const [action, setAction] = useState('')
  const [followUp, setFollowUp] = useState('')
  const [evidence, setEvidence] = useState('')

  const mutation = useMutation({
    mutationFn: async () => {
      if (!target || !fact || !impact || !action) {
        throw new Error(
          'Informe colaborador, fato, impacto e ação combinada.',
        )
      }

      const { error } = await supabase.from('feedback_records').insert({
        organization_id: orgId,
        plan_id: planId,
        team_id: team || null,
        target_member_id: target,
        author_member_id: activeMembership?.id ?? null,
        feedback_type: type,
        occurred_on: occurredOn,
        fact,
        impact,
        cause: cause || null,
        agreed_action: action,
        follow_up_on: followUp || null,
        evidence: evidence || null,
        status: followUp ? 'follow_up' : 'open',
        created_by: profile?.id,
      })

      if (error) throw error
    },
    onSuccess: () => {
      toast.success('Feedback registrado.')
      qc.invalidateQueries({ queryKey: ['feedback-records'] })
      onClose()
    },
    onError: (error: Error) => toast.error(error.message),
  })

  return (
    <div className="space-y-4">
      <div className="grid grid-cols-2 gap-3">
        <div>
          <label className="form-label">Colaborador *</label>
          <select
            className="form-input"
            value={target}
            onChange={(event) => setTarget(event.target.value)}
          >
            <option value="">Selecione...</option>
            {members.map((member) => {
              const memberProfile = profileOf(member.profiles)
              return (
                <option key={member.id} value={member.id}>
                  {memberProfile?.full_name ||
                    memberProfile?.email ||
                    member.user_id}{' '}
                  — {member.role}
                </option>
              )
            })}
          </select>
        </div>

        <div>
          <label className="form-label">Equipe</label>
          <select
            className="form-input"
            value={team}
            onChange={(event) => setTeam(event.target.value)}
          >
            <option value="">Selecione...</option>
            {teams.map((item) => (
              <option key={item.id} value={item.id}>
                {item.name}
              </option>
            ))}
          </select>
        </div>

        <div>
          <label className="form-label">Tipo</label>
          <select
            className="form-input"
            value={type}
            onChange={(event) => setType(event.target.value)}
          >
            <option value="coaching">Coaching</option>
            <option value="performance">Performance</option>
            <option value="recognition">Reconhecimento</option>
            <option value="corrective">Corretivo</option>
          </select>
        </div>

        <div>
          <label className="form-label">Data</label>
          <input
            type="date"
            className="form-input"
            value={occurredOn}
            onChange={(event) => setOccurredOn(event.target.value)}
          />
        </div>
      </div>

      <div>
        <label className="form-label">Fato *</label>
        <textarea
          className="form-input min-h-20"
          value={fact}
          onChange={(event) => setFact(event.target.value)}
        />
      </div>

      <div>
        <label className="form-label">Impacto *</label>
        <textarea
          className="form-input min-h-20"
          value={impact}
          onChange={(event) => setImpact(event.target.value)}
        />
      </div>

      <div>
        <label className="form-label">Causa</label>
        <textarea
          className="form-input min-h-16"
          value={cause}
          onChange={(event) => setCause(event.target.value)}
        />
      </div>

      <div>
        <label className="form-label">Ação combinada *</label>
        <textarea
          className="form-input min-h-20"
          value={action}
          onChange={(event) => setAction(event.target.value)}
        />
      </div>

      <div className="grid grid-cols-2 gap-3">
        <div>
          <label className="form-label">Revisar em</label>
          <input
            type="date"
            className="form-input"
            value={followUp}
            onChange={(event) => setFollowUp(event.target.value)}
          />
        </div>

        <div>
          <label className="form-label">Evidência esperada</label>
          <input
            className="form-input"
            value={evidence}
            onChange={(event) => setEvidence(event.target.value)}
          />
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
          {mutation.isPending ? 'Salvando...' : 'Registrar feedback'}
        </button>
      </div>
    </div>
  )
}

export default function FeedbacksPage() {
  const {
    activeOrganization,
    activeMembership,
    profile,
    user,
    isAdmin,
    isDirector,
    isSupervisor,
  } = useAuth()
  const orgId = activeOrganization?.id
  const canCreate = isAdmin || isDirector || isSupervisor
  const [open, setOpen] = useState(false)
  const { data: plan } = useCommercialPlanReference(orgId)

  const { data: records, isLoading } = useQuery({
    queryKey: ['feedback-records', orgId, user?.id],
    enabled: !!orgId && !!user?.id,
    queryFn: async () => {
      const { data, error } = await supabase
        .from('feedback_records')
        .select('*')
        .eq('organization_id', orgId!)
        .neq('status', 'archived')
        .order('occurred_on', { ascending: false })

      if (error) throw error
      return (data ?? []) as FeedbackRecord[]
    },
  })

  const { data: members } = useQuery({
    queryKey: ['feedback-members', orgId, user?.id],
    enabled: !!orgId && !!user?.id && canCreate,
    queryFn: async () => {
      const { data, error } = await supabase
        .from('organization_members')
        .select(
          'id, user_id, role, profiles!organization_members_user_id_fkey(full_name, email)',
        )
        .eq('organization_id', orgId!)
        .eq('status', 'active')
        .is('archived_at', null)

      if (error) throw error
      return (data ?? []) as MemberOption[]
    },
  })

  const { data: teams } = useQuery({
    queryKey: ['feedback-teams', orgId, user?.id],
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

  const names = useMemo(() => {
    const map = new Map<string, string>()

    if (activeMembership?.id) {
      map.set(
        activeMembership.id,
        profile?.preferred_name ||
          profile?.full_name ||
          profile?.email ||
          'Você',
      )
    }

    for (const member of members ?? []) {
      const memberProfile = profileOf(member.profiles)
      map.set(
        member.id,
        memberProfile?.full_name ||
          memberProfile?.email ||
          member.user_id,
      )
    }

    return map
  }, [activeMembership?.id, members, profile])

  if (isLoading) {
    return (
      <div className="page-container flex min-h-[400px] items-center justify-center">
        <LoadingSpinner size="lg" />
      </div>
    )
  }

  return (
    <div className="page-container">
      <PageHeader
        title="Feedbacks"
        description="Modelo estruturado com fato, impacto, causa, ação, prazo e evidência."
        action={
          canCreate ? (
            <button
              className="btn-primary flex items-center gap-2"
              onClick={() => setOpen(true)}
            >
              <Plus className="h-4 w-4" />
              Novo feedback
            </button>
          ) : undefined
        }
      />

      <div className="mb-6 grid gap-3 md:grid-cols-3">
        {FRAMEWORK.map(([step, question]) => (
          <div key={step} className="card p-4">
            <p className="text-sm font-semibold text-brand-800">{step}</p>
            <p className="mt-1 text-xs leading-5 text-gray-500">
              {question}
            </p>
          </div>
        ))}
      </div>

      {records?.length ? (
        <div className="space-y-3">
          {records.map((record) => (
            <article key={record.id} className="card p-5">
              <div className="flex flex-col justify-between gap-3 sm:flex-row">
                <div>
                  <h2 className="text-sm font-semibold text-gray-900">
                    {names.get(record.target_member_id) ?? 'Colaborador'}
                  </h2>
                  <p className="mt-1 text-xs text-gray-400">
                    {formatDate(record.occurred_on)} · {record.feedback_type}
                  </p>
                </div>
                <span
                  className={`badge ${
                    record.status === 'completed'
                      ? 'badge-active'
                      : 'badge-inactive'
                  }`}
                >
                  {record.status === 'completed'
                    ? 'Concluído'
                    : record.status === 'follow_up'
                      ? 'Acompanhamento'
                      : 'Aberto'}
                </span>
              </div>

              <div className="mt-4 grid gap-3 md:grid-cols-2">
                <div className="rounded-lg bg-gray-50 p-3">
                  <p className="text-xs font-semibold text-gray-500">Fato</p>
                  <p className="mt-1 text-sm text-gray-800">{record.fact}</p>
                </div>
                <div className="rounded-lg bg-gray-50 p-3">
                  <p className="text-xs font-semibold text-gray-500">
                    Impacto
                  </p>
                  <p className="mt-1 text-sm text-gray-800">
                    {record.impact}
                  </p>
                </div>
                <div className="rounded-lg border border-brand-100 bg-brand-50 p-3 md:col-span-2">
                  <p className="text-xs font-semibold text-brand-700">
                    Ação combinada
                  </p>
                  <p className="mt-1 text-sm text-brand-900">
                    {record.agreed_action}
                  </p>
                </div>
              </div>
            </article>
          ))}
        </div>
      ) : (
        <div className="card">
          <EmptyState
            icon={MessageSquare}
            title="Nenhum feedback real registrado"
            description="O framework está pronto. Os registros começam após as observações e 1:1 reais."
          />
        </div>
      )}

      {canCreate && (
        <Dialog open={open} onOpenChange={setOpen}>
          <DialogContent>
            <DialogHeader>
              <DialogTitle>Novo feedback</DialogTitle>
            </DialogHeader>
            {orgId && plan && (
              <FeedbackForm
                orgId={orgId}
                planId={plan.id}
                members={members ?? []}
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
