import { useMemo, useState } from 'react'
import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query'
import {
  CheckCircle2,
  ClipboardCheck,
  RefreshCw,
  ShieldAlert,
  UsersRound,
} from 'lucide-react'
import { toast } from 'sonner'
import {
  AssessmentServiceError,
  getManagedPracticalAssessmentRequirements,
  recordPracticalAssessment,
} from '@/services/assessmentService'
import type {
  ManagedAssessmentProgressRow,
  ManagedPracticalAssessmentRequirement,
  PracticalAssessmentType,
} from '@/types/assessments'
import EmptyState from '@/components/shared/EmptyState'
import LoadingSpinner from '@/components/shared/LoadingSpinner'

const ROLE_LABELS = {
  salesperson: 'Vendedor',
  supervisor: 'Supervisor',
  director: 'Diretor',
} as const

const PRACTICAL_TYPE_LABELS: Record<PracticalAssessmentType, string> = {
  role_play: 'Role play',
  full_simulation: 'Simulação completa',
  case_presentation: 'Apresentação de caso',
  microtraining: 'Microtreinamento',
}

function formatScore(value: number | null) {
  if (value === null) return '—'

  return `${Number(value).toLocaleString('pt-BR', {
    maximumFractionDigits: 2,
  })}%`
}

function formatDate(value: string | null) {
  if (!value) return '—'

  return new Intl.DateTimeFormat('pt-BR', {
    dateStyle: 'short',
    timeStyle: 'short',
  }).format(new Date(value))
}

function getRequirementStatus(requirement: ManagedPracticalAssessmentRequirement) {
  if (!requirement.latest_practical_assessment_id) {
    return {
      label: 'Pendente',
      className: 'bg-gray-100 text-gray-700',
    }
  }

  if (requirement.latest_passed) {
    return {
      label: 'Aprovado',
      className: 'bg-green-100 text-green-800',
    }
  }

  return {
    label: 'Não aprovado',
    className: 'bg-red-100 text-red-800',
  }
}

export default function PracticalAssessmentManagementPanel({
  organizationId,
  rows,
}: {
  organizationId: string
  rows: ManagedAssessmentProgressRow[]
}) {
  const queryClient = useQueryClient()
  const members = useMemo(() => {
    const memberMap = new Map<
      string,
      Pick<
        ManagedAssessmentProgressRow,
        | 'organization_member_id'
        | 'member_name'
        | 'member_email'
        | 'member_role'
        | 'team_contexts'
      >
    >()

    rows.forEach((row) => {
      if (!memberMap.has(row.organization_member_id)) {
        memberMap.set(row.organization_member_id, {
          organization_member_id: row.organization_member_id,
          member_name: row.member_name,
          member_email: row.member_email,
          member_role: row.member_role,
          team_contexts: row.team_contexts,
        })
      }
    })

    return Array.from(memberMap.values()).sort((left, right) =>
      left.member_name.localeCompare(right.member_name, 'pt-BR'),
    )
  }, [rows])

  const [selectedMemberId, setSelectedMemberId] = useState('')
  const [editingRequirementId, setEditingRequirementId] = useState<string | null>(
    null,
  )
  const [score, setScore] = useState('')
  const [criticalErrors, setCriticalErrors] = useState('0')
  const [notes, setNotes] = useState('')

  const effectiveMemberId =
    selectedMemberId || members[0]?.organization_member_id || ''
  const selectedMember = members.find(
    (member) => member.organization_member_id === effectiveMemberId,
  )

  const {
    data: requirements = [],
    error,
    isLoading,
    isFetching,
    refetch,
  } = useQuery({
    queryKey: [
      'managed-practical-assessment-requirements',
      organizationId,
      effectiveMemberId,
    ],
    enabled: !!organizationId && !!effectiveMemberId,
    queryFn: () =>
      getManagedPracticalAssessmentRequirements(
        organizationId,
        effectiveMemberId,
      ),
  })

  const mutation = useMutation({
    mutationFn: (requirement: ManagedPracticalAssessmentRequirement) => {
      const numericScore = Number(score.replace(',', '.'))
      const numericCriticalErrors = Number(criticalErrors)

      if (!Number.isFinite(numericScore) || numericScore < 0 || numericScore > 100) {
        throw new Error('Informe uma nota entre 0 e 100.')
      }

      if (
        !Number.isInteger(numericCriticalErrors) ||
        numericCriticalErrors < 0
      ) {
        throw new Error('Informe uma quantidade válida de erros críticos.')
      }

      return recordPracticalAssessment({
        organizationId,
        organizationMemberId: effectiveMemberId,
        certificationRequirementId: requirement.certification_requirement_id,
        score: numericScore,
        criticalErrors: numericCriticalErrors,
        notes: notes.trim() || null,
      })
    },
    onSuccess: async (result) => {
      toast.success(
        result.passed
          ? 'Avaliação prática registrada com aprovação.'
          : 'Avaliação prática registrada. O requisito ainda não foi aprovado.',
      )

      setEditingRequirementId(null)
      setScore('')
      setCriticalErrors('0')
      setNotes('')

      await Promise.all([
        refetch(),
        queryClient.invalidateQueries({
          queryKey: [
            'managed-practical-assessment-requirements',
            organizationId,
            effectiveMemberId,
          ],
        }),
      ])
    },
    onError: (mutationError: Error) => {
      toast.error(
        mutationError instanceof AssessmentServiceError
          ? mutationError.message
          : mutationError.message ||
              'Não foi possível registrar a avaliação prática.',
      )
    },
  })

  const openForm = (requirementId: string) => {
    setEditingRequirementId(requirementId)
    setScore('')
    setCriticalErrors('0')
    setNotes('')
  }

  const cancelForm = () => {
    setEditingRequirementId(null)
    setScore('')
    setCriticalErrors('0')
    setNotes('')
  }

  if (!members.length) {
    return (
      <div className="card">
        <EmptyState
          icon={UsersRound}
          title="Nenhum participante disponível"
          description="Não há participantes no seu escopo para registrar avaliações práticas."
        />
      </div>
    )
  }

  return (
    <div className="space-y-4">
      <div className="card p-5">
        <label className="text-sm font-medium text-gray-700">
          Participante
          <select
            className="mt-1 w-full rounded-lg border border-gray-300 bg-white px-3 py-2 text-sm text-gray-800"
            value={effectiveMemberId}
            onChange={(event) => {
              setSelectedMemberId(event.target.value)
              cancelForm()
            }}
          >
            {members.map((member) => (
              <option
                key={member.organization_member_id}
                value={member.organization_member_id}
              >
                {member.member_name} · {ROLE_LABELS[member.member_role]} ·{' '}
                {member.member_email}
              </option>
            ))}
          </select>
        </label>

        {selectedMember && (
          <div className="mt-3 flex flex-wrap gap-1.5">
            <span className="badge bg-brand-50 text-brand-700">
              {ROLE_LABELS[selectedMember.member_role]}
            </span>
            {selectedMember.team_contexts.map((team) => (
              <span
                key={team.team_id}
                className="badge bg-gray-100 text-gray-700"
              >
                {team.team_name}
                {team.sales_location_name
                  ? ` · ${team.sales_location_name}`
                  : ''}
              </span>
            ))}
          </div>
        )}
      </div>

      {isLoading ? (
        <div className="card flex min-h-[220px] items-center justify-center">
          <LoadingSpinner message="Carregando requisitos práticos..." />
        </div>
      ) : error ? (
        <div className="card">
          <EmptyState
            icon={ClipboardCheck}
            title="Falha ao carregar avaliações práticas"
            description={
              error instanceof AssessmentServiceError
                ? error.message
                : 'Não foi possível carregar os requisitos práticos deste participante.'
            }
            action={(
              <button
                type="button"
                className="btn-secondary"
                onClick={() => refetch()}
                disabled={isFetching}
              >
                <RefreshCw
                  className={`mr-2 h-4 w-4 ${
                    isFetching ? 'animate-spin' : ''
                  }`}
                />
                Tentar novamente
              </button>
            )}
          />
        </div>
      ) : !requirements.length ? (
        <div className="card">
          <EmptyState
            icon={ClipboardCheck}
            title="Nenhum requisito prático configurado"
            description="Não há requisitos de avaliação prática configurados nos programas de certificação desta organização."
          />
        </div>
      ) : (
        <div className="space-y-4">
          {requirements.map((requirement) => {
            const status = getRequirementStatus(requirement)
            const isEditing =
              editingRequirementId === requirement.certification_requirement_id

            return (
              <article
                key={requirement.certification_requirement_id}
                className="card p-5"
              >
                <div className="flex flex-wrap items-start justify-between gap-3">
                  <div>
                    <p className="text-xs font-semibold uppercase tracking-wide text-brand-700">
                      {requirement.program_name} · versão{' '}
                      {requirement.version_code}
                    </p>
                    <h3 className="mt-1 font-semibold text-gray-900">
                      {requirement.requirement_title}
                    </h3>
                    {requirement.requirement_description && (
                      <p className="mt-1 text-sm text-gray-500">
                        {requirement.requirement_description}
                      </p>
                    )}
                  </div>

                  <span className={`badge ${status.className}`}>
                    {status.label}
                  </span>
                </div>

                <div className="mt-4 flex flex-wrap gap-2 text-xs">
                  <span className="badge bg-gray-100 text-gray-700">
                    {requirement.assessment_type
                      ? PRACTICAL_TYPE_LABELS[requirement.assessment_type]
                      : 'Tipo não configurado'}
                  </span>
                  <span className="badge bg-gray-100 text-gray-700">
                    Nota mínima {formatScore(requirement.minimum_score)}
                  </span>
                  <span className="badge bg-gray-100 text-gray-700">
                    Erros críticos máximos:{' '}
                    {requirement.max_critical_errors ?? 'sem limite'}
                  </span>
                  {requirement.program_status !== 'active' && (
                    <span className="badge bg-amber-100 text-amber-800">
                      Programa {requirement.program_status}
                    </span>
                  )}
                </div>

                {requirement.latest_practical_assessment_id && (
                  <div className="mt-4 rounded-lg border border-gray-200 bg-gray-50 p-4 text-sm text-gray-600">
                    <div className="flex flex-wrap items-center justify-between gap-2">
                      <span>
                        Última nota: {formatScore(requirement.latest_score)}
                      </span>
                      <span>
                        Erros críticos: {requirement.latest_critical_errors ?? 0}
                      </span>
                      <span>
                        {formatDate(requirement.latest_assessed_at)}
                      </span>
                    </div>
                    {requirement.latest_evaluator_name && (
                      <p className="mt-2 text-xs text-gray-500">
                        Avaliador: {requirement.latest_evaluator_name}
                      </p>
                    )}
                  </div>
                )}

                {!isEditing ? (
                  <div className="mt-4 flex justify-end">
                    <button
                      type="button"
                      className="btn-primary"
                      onClick={() =>
                        openForm(requirement.certification_requirement_id)
                      }
                    >
                      Registrar avaliação prática
                    </button>
                  </div>
                ) : (
                  <div className="mt-5 rounded-lg border border-brand-100 bg-brand-50/40 p-4">
                    <div className="flex items-start gap-2 text-sm text-gray-700">
                      <ShieldAlert className="mt-0.5 h-4 w-4 shrink-0 text-brand-700" />
                      <p>
                        O resultado de aprovação será calculado pelo servidor a
                        partir da nota mínima e do limite de erros críticos deste
                        requisito.
                      </p>
                    </div>

                    <div className="mt-4 grid gap-4 sm:grid-cols-2">
                      <label className="text-sm font-medium text-gray-700">
                        Nota (0 a 100)
                        <input
                          type="number"
                          min="0"
                          max="100"
                          step="0.01"
                          className="mt-1 w-full rounded-lg border border-gray-300 bg-white px-3 py-2 text-sm text-gray-800"
                          value={score}
                          onChange={(event) => setScore(event.target.value)}
                          placeholder="Ex.: 85"
                        />
                      </label>

                      <label className="text-sm font-medium text-gray-700">
                        Erros críticos
                        <input
                          type="number"
                          min="0"
                          step="1"
                          className="mt-1 w-full rounded-lg border border-gray-300 bg-white px-3 py-2 text-sm text-gray-800"
                          value={criticalErrors}
                          onChange={(event) =>
                            setCriticalErrors(event.target.value)
                          }
                        />
                      </label>
                    </div>

                    <label className="mt-4 block text-sm font-medium text-gray-700">
                      Observações do avaliador (opcional)
                      <textarea
                        className="mt-1 min-h-24 w-full rounded-lg border border-gray-300 bg-white px-3 py-2 text-sm text-gray-800"
                        value={notes}
                        onChange={(event) => setNotes(event.target.value)}
                        maxLength={5000}
                        placeholder="Registre pontos observados no desempenho prático."
                      />
                    </label>

                    <div className="mt-4 flex flex-wrap justify-end gap-2">
                      <button
                        type="button"
                        className="btn-secondary"
                        onClick={cancelForm}
                        disabled={mutation.isPending}
                      >
                        Cancelar
                      </button>
                      <button
                        type="button"
                        className="btn-primary"
                        disabled={!score.trim() || mutation.isPending}
                        onClick={() => mutation.mutate(requirement)}
                      >
                        {mutation.isPending
                          ? 'Registrando...'
                          : 'Confirmar resultado'}
                      </button>
                    </div>
                  </div>
                )}

                {requirement.latest_passed && (
                  <p className="mt-4 flex items-center gap-2 text-sm text-green-700">
                    <CheckCircle2 className="h-4 w-4" />
                    Este requisito prático está atendido pela última avaliação.
                  </p>
                )}
              </article>
            )
          })}
        </div>
      )}
    </div>
  )
}
