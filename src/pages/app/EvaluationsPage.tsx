import { useMutation, useQuery } from '@tanstack/react-query'
import { useNavigate } from 'react-router-dom'
import {
  Award,
  CheckCircle2,
  ClipboardCheck,
  Clock3,
  Eye,
  LockKeyhole,
  PlayCircle,
  RefreshCw,
  UsersRound,
} from 'lucide-react'
import { toast } from 'sonner'
import { useAuth } from '@/contexts/AuthContext'
import { ROUTES } from '@/constants/routes'
import {
  AssessmentServiceError,
  getAvailableAssessments,
  getManagedAssessmentProgress,
  startAssessmentAttempt,
} from '@/services/assessmentService'
import {
  getManagedCertifications,
  getMyCertifications,
} from '@/services/certificationService'
import type {
  AssessmentAvailability,
  AvailableAssessment,
  ManagedAssessmentProgressRow,
  ManagedAssessmentProgressStatus,
} from '@/types/assessments'
import EmptyState from '@/components/shared/EmptyState'
import LoadingSpinner from '@/components/shared/LoadingSpinner'
import PageHeader from '@/components/shared/PageHeader'
import AssessmentAccessAdminPanel from '@/components/assessments/AssessmentAccessAdminPanel'
import PersonalCertificationsPanel from '@/components/certifications/PersonalCertificationsPanel'

const AVAILABILITY_LABELS: Record<AssessmentAvailability, string> = {
  available: 'Disponível',
  in_progress: 'Em andamento',
  locked_prerequisite: 'Pré-requisito pendente',
  attempts_exhausted: 'Tentativas esgotadas',
  cooldown: 'Aguardando intervalo',
}

const AVAILABILITY_CLASSES: Record<AssessmentAvailability, string> = {
  available: 'bg-green-100 text-green-800',
  in_progress: 'bg-blue-100 text-blue-800',
  locked_prerequisite: 'bg-gray-100 text-gray-700',
  attempts_exhausted: 'bg-red-100 text-red-800',
  cooldown: 'bg-amber-100 text-amber-800',
}

function formatDifficulty(value: AvailableAssessment['difficulty']) {
  const labels: Record<AvailableAssessment['difficulty'], string> = {
    beginner: 'Iniciante',
    beginner_intermediate: 'Iniciante a intermediário',
    intermediate: 'Intermediário',
    intermediate_advanced: 'Intermediário a avançado',
    advanced: 'Avançado',
  }

  return labels[value]
}

function formatNextAttempt(value: string | null) {
  if (!value) return null

  return new Intl.DateTimeFormat('pt-BR', {
    dateStyle: 'short',
    timeStyle: 'short',
  }).format(new Date(value))
}

const MANAGED_PROGRESS_LABELS: Record<ManagedAssessmentProgressStatus, string> = {
  not_assigned: 'Não atribuída',
  not_started: 'Não iniciada',
  in_progress: 'Em andamento',
  submitted: 'Enviada',
  passed: 'Aprovado',
  failed: 'Reprovado',
  expired: 'Expirada',
  cancelled: 'Cancelada',
}

const MANAGED_PROGRESS_CLASSES: Record<ManagedAssessmentProgressStatus, string> = {
  not_assigned: 'bg-gray-100 text-gray-700',
  not_started: 'bg-slate-100 text-slate-700',
  in_progress: 'bg-blue-100 text-blue-800',
  submitted: 'bg-indigo-100 text-indigo-800',
  passed: 'bg-green-100 text-green-800',
  failed: 'bg-red-100 text-red-800',
  expired: 'bg-amber-100 text-amber-800',
  cancelled: 'bg-gray-100 text-gray-600',
}

function formatManagedScore(value: number | null) {
  if (value === null) return '—'
  return `${Number(value).toLocaleString('pt-BR', { maximumFractionDigits: 2 })}%`
}

function formatManagedDate(value: string | null) {
  if (!value) return '—'

  return new Intl.DateTimeFormat('pt-BR', {
    dateStyle: 'short',
    timeStyle: 'short',
  }).format(new Date(value))
}

function ManagedAssessmentsPanel({
  rows,
  isLoading,
  isFetching,
  error,
  onRetry,
  scopeLabel,
}: {
  rows: ManagedAssessmentProgressRow[]
  isLoading: boolean
  isFetching: boolean
  error: unknown
  onRetry: () => void
  scopeLabel: string
}) {
  if (isLoading) {
    return (
      <div className="card flex min-h-[220px] items-center justify-center">
        <LoadingSpinner message="Carregando avaliações da equipe..." />
      </div>
    )
  }

  if (error) {
    const message =
      error instanceof AssessmentServiceError
        ? error.message
        : 'Não foi possível carregar o acompanhamento das avaliações.'

    return (
      <div className="card">
        <EmptyState
          icon={UsersRound}
          title="Falha ao carregar avaliações da equipe"
          description={message}
          action={(
            <button
              type="button"
              className="btn-secondary"
              onClick={onRetry}
              disabled={isFetching}
            >
              <RefreshCw
                className={`mr-2 h-4 w-4 ${isFetching ? 'animate-spin' : ''}`}
              />
              Tentar novamente
            </button>
          )}
        />
      </div>
    )
  }

  if (!rows.length) {
    return (
      <div className="card">
        <EmptyState
          icon={UsersRound}
          title="Nenhum participante no escopo"
          description={`Não há participantes com avaliações publicadas em ${scopeLabel}.`}
        />
      </div>
    )
  }

  const members = Array.from(
    rows.reduce((groups, row) => {
      const current = groups.get(row.organization_member_id) ?? []
      current.push(row)
      groups.set(row.organization_member_id, current)
      return groups
    }, new Map<string, ManagedAssessmentProgressRow[]>()),
  )

  return (
    <div className="space-y-4">
      {members.map(([memberId, memberRows]) => {
        const member = memberRows[0]
        const teams = member.team_contexts ?? []
        const assignedCount = memberRows.filter((row) => row.assigned).length
        const passedCount = memberRows.filter(
          (row) => row.progress_status === 'passed',
        ).length

        return (
          <section key={memberId} className="card overflow-hidden">
            <div className="flex flex-wrap items-start justify-between gap-3 border-b border-gray-100 p-4">
              <div>
                <h3 className="font-semibold text-gray-900">
                  {member.member_name}
                </h3>
                <p className="text-xs text-gray-500">{member.member_email}</p>
                <div className="mt-2 flex flex-wrap gap-1.5">
                  {teams.length ? (
                    teams.map((team) => (
                      <span
                        key={team.team_id}
                        className="badge bg-gray-100 text-gray-700"
                      >
                        {team.team_name}
                        {team.sales_location_name
                          ? ` · ${team.sales_location_name}`
                          : ''}
                      </span>
                    ))
                  ) : (
                    <span className="text-xs text-amber-700">
                      Sem equipe ativa no escopo
                    </span>
                  )}
                </div>
              </div>

              <div className="text-right text-xs text-gray-500">
                <p>{assignedCount} atribuída(s)</p>
                <p>{passedCount} concluída(s) com aprovação</p>
              </div>
            </div>

            <div className="overflow-x-auto">
              <table className="w-full">
                <thead>
                  <tr className="border-b border-gray-200 bg-gray-50">
                    <th className="table-th">Avaliação</th>
                    <th className="table-th">Status</th>
                    <th className="table-th">Tentativas</th>
                    <th className="table-th">Última nota</th>
                    <th className="table-th hidden lg:table-cell">Última atividade</th>
                  </tr>
                </thead>
                <tbody>
                  {memberRows
                    .slice()
                    .sort((a, b) => a.sequence_no - b.sequence_no)
                    .map((row) => (
                      <tr
                        key={`${row.organization_member_id}:${row.test_version_id}`}
                        className="border-b border-gray-100 last:border-b-0"
                      >
                        <td className="table-td">
                          <p className="font-medium text-gray-800">
                            {row.sequence_no}. {row.test_title}
                          </p>
                          <p className="text-xs text-gray-500">
                            {row.test_purpose === 'diagnostic'
                              ? 'Diagnóstico'
                              : 'Certificação'}
                          </p>
                        </td>
                        <td className="table-td">
                          <span
                            className={`badge ${MANAGED_PROGRESS_CLASSES[row.progress_status]}`}
                          >
                            {MANAGED_PROGRESS_LABELS[row.progress_status]}
                          </span>
                        </td>
                        <td className="table-td text-gray-600">
                          {row.attempts_used}
                        </td>
                        <td className="table-td text-gray-600">
                          {formatManagedScore(row.last_graded_overall_score)}
                        </td>
                        <td className="table-td hidden text-xs text-gray-500 lg:table-cell">
                          {formatManagedDate(
                            row.last_attempt_graded_at ??
                              row.last_attempt_submitted_at ??
                              row.last_attempt_started_at,
                          )}
                        </td>
                      </tr>
                    ))}
                </tbody>
              </table>
            </div>
          </section>
        )
      })}
    </div>
  )
}

function AssessmentCard({
  assessment,
  isStarting,
  onStart,
  onViewResult,
}: {
  assessment: AvailableAssessment
  isStarting: boolean
  onStart: (assessment: AvailableAssessment) => void
  onViewResult: (attemptId: string) => void
}) {
  const nextAttempt = formatNextAttempt(assessment.next_attempt_at)
  const canOpen =
    assessment.availability === 'available' ||
    assessment.availability === 'in_progress'
  const actionLabel =
    assessment.availability === 'in_progress'
      ? 'Continuar avaliação'
      : 'Iniciar avaliação'
  const hasGradedResult = Boolean(assessment.last_graded_attempt_id)
  const resultActionLabel = canOpen
    ? 'Ver último resultado'
    : 'Ver resultado'

  return (
    <article className="card p-5">
      <div className="flex items-start justify-between gap-4">
        <div className="flex min-w-0 items-start gap-3">
          <div className="flex h-10 w-10 shrink-0 items-center justify-center rounded-full bg-brand-100 font-bold text-brand-800">
            {assessment.sequence_no}
          </div>

          <div className="min-w-0">
            <p className="text-xs font-semibold uppercase tracking-wide text-brand-700">
              {assessment.purpose === 'diagnostic'
                ? 'Diagnóstico'
                : 'Certificação'}
            </p>
            <h2 className="mt-1 font-semibold text-gray-900">
              {assessment.title}
            </h2>
            {assessment.description && (
              <p className="mt-2 text-sm leading-5 text-gray-600">
                {assessment.description}
              </p>
            )}
          </div>
        </div>

        <span
          className={`badge shrink-0 ${AVAILABILITY_CLASSES[assessment.availability]}`}
        >
          {AVAILABILITY_LABELS[assessment.availability]}
        </span>
      </div>

      <div className="mt-4 flex flex-wrap gap-2 text-xs">
        <span className="badge bg-gray-100 text-gray-700">
          <ClipboardCheck className="mr-1 h-3 w-3" />
          {assessment.question_count} questões
        </span>
        <span className="badge bg-gray-100 text-gray-700">
          <Award className="mr-1 h-3 w-3" />
          Nota mínima {assessment.passing_score}%
        </span>
        <span className="badge bg-gray-100 text-gray-700">
          {formatDifficulty(assessment.difficulty)}
        </span>
        {assessment.time_limit_minutes && (
          <span className="badge bg-gray-100 text-gray-700">
            <Clock3 className="mr-1 h-3 w-3" />
            {assessment.time_limit_minutes} min
          </span>
        )}
      </div>

      <div className="mt-4 border-t border-gray-100 pt-4 text-sm text-gray-600">
        <div className="flex flex-wrap items-center justify-between gap-2">
          <span>
            Tentativas: {assessment.attempts_used}/{assessment.max_attempts}
          </span>
          <span>Legislação mínima: {assessment.legal_min_score}%</span>
        </div>

        {assessment.availability === 'locked_prerequisite' && (
          <p className="mt-3 flex items-center gap-2 text-gray-600">
            <LockKeyhole className="h-4 w-4" />
            Conclua a etapa anterior para liberar esta avaliação.
          </p>
        )}

        {assessment.availability === 'cooldown' && nextAttempt && (
          <p className="mt-3 flex items-center gap-2 text-amber-700">
            <Clock3 className="h-4 w-4" />
            Próxima tentativa disponível em {nextAttempt}.
          </p>
        )}

        {assessment.last_attempt_passed === true && (
          <p className="mt-3 flex items-center gap-2 text-green-700">
            <CheckCircle2 className="h-4 w-4" />
            Última tentativa aprovada.
          </p>
        )}

        {(hasGradedResult || canOpen) && (
          <div className="mt-4 flex flex-wrap justify-end gap-2">
            {assessment.last_graded_attempt_id && (
              <button
                type="button"
                className="btn-secondary"
                onClick={() =>
                  onViewResult(assessment.last_graded_attempt_id!)
                }
              >
                <Eye className="mr-2 h-4 w-4" />
                {resultActionLabel}
              </button>
            )}

            {canOpen && (
              <button
                type="button"
                className="btn-primary"
                onClick={() => onStart(assessment)}
                disabled={isStarting}
              >
                <PlayCircle className="mr-2 h-4 w-4" />
                {isStarting ? 'Preparando...' : actionLabel}
              </button>
            )}
          </div>
        )}
      </div>
    </article>
  )
}

export default function EvaluationsPage() {
  const { activeOrganization, user, isAdmin, isDirector, isSupervisor } = useAuth()
  const organizationId = activeOrganization?.id
  const navigate = useNavigate()

  const {
    data,
    error,
    isLoading,
    isFetching,
    refetch,
  } = useQuery({
    queryKey: ['available-assessments', organizationId, user?.id],
    enabled: !!organizationId && !!user?.id && !isAdmin,
    queryFn: () => getAvailableAssessments(organizationId!),
  })

  const {
    data: managedRows = [],
    error: managedError,
    isLoading: managedIsLoading,
    isFetching: managedIsFetching,
    refetch: refetchManaged,
  } = useQuery({
    queryKey: ['managed-assessment-progress', organizationId, user?.id],
    enabled:
      !!organizationId &&
      !!user?.id &&
      (isAdmin || isSupervisor || isDirector),
    queryFn: () => getManagedAssessmentProgress(organizationId!),
  })

  const {
    data: myCertifications = [],
    error: myCertificationsError,
    isLoading: myCertificationsIsLoading,
    isFetching: myCertificationsIsFetching,
    refetch: refetchMyCertifications,
  } = useQuery({
    queryKey: ['my-certifications', organizationId, user?.id],
    enabled: !!organizationId && !!user?.id && !isAdmin,
    queryFn: () => getMyCertifications(organizationId!),
  })

  const {
    data: managedCertifications = [],
    error: managedCertificationsError,
    isLoading: managedCertificationsIsLoading,
    isFetching: managedCertificationsIsFetching,
    refetch: refetchManagedCertifications,
  } = useQuery({
    queryKey: ['managed-certifications', organizationId, user?.id],
    enabled:
      !!organizationId &&
      !!user?.id &&
      (isAdmin || isSupervisor || isDirector),
    queryFn: () => getManagedCertifications(organizationId!),
  })
  const startMutation = useMutation({
    mutationFn: (assessment: AvailableAssessment) => {
      if (!organizationId) {
        throw new Error('Organização ativa não encontrada.')
      }

      return startAssessmentAttempt(organizationId, assessment.test_id)
    },
    onSuccess: (attempt) => {
      navigate(`${ROUTES.EVALUATIONS}/${attempt.attempt_id}`)
    },
    onError: (mutationError: Error) => {
      const message =
        mutationError instanceof AssessmentServiceError
          ? mutationError.message
          : 'Não foi possível iniciar a avaliação.'

      toast.error(message)
    },
  })

  if (isLoading) {
    return (
      <div className="page-container flex min-h-[400px] items-center justify-center">
        <LoadingSpinner size="lg" message="Carregando avaliações..." />
      </div>
    )
  }

  if (error) {
    const message =
      error instanceof AssessmentServiceError
        ? error.message
        : 'Não foi possível carregar as avaliações.'

    return (
      <div className="page-container">
        <PageHeader
          title="Avaliações e certificações"
          description="Diagnóstico técnico e progressão de certificação dos participantes."
        />

        <div className="card">
          <EmptyState
            icon={ClipboardCheck}
            title="Falha ao carregar avaliações"
            description={message}
            action={(
              <button
                type="button"
                className="btn-secondary"
                onClick={() => refetch()}
                disabled={isFetching}
              >
                <RefreshCw
                  className={`mr-2 h-4 w-4 ${isFetching ? 'animate-spin' : ''}`}
                />
                Tentar novamente
              </button>
            )}
          />
        </div>
      </div>
    )
  }

  const assessments = data?.tests ?? []
  const availableCount = assessments.filter(
    (assessment) => assessment.availability === 'available',
  ).length
  const completedCount = assessments.filter(
    (assessment) => assessment.last_attempt_passed === true,
  ).length

  const hasManagementScope = isAdmin || isSupervisor || isDirector

  const personalAssessments = !assessments.length ? (
    <div className="card">
      <EmptyState
        icon={ClipboardCheck}
        title={
          hasManagementScope
            ? 'Nenhuma avaliação atribuída a você'
            : 'Nenhuma avaliação disponível'
        }
        description={
          hasManagementScope
            ? 'Suas avaliações aparecerão aqui quando forem atribuídas ao seu usuário.'
            : 'As avaliações aparecerão aqui quando forem publicadas para a sua organização.'
        }
      />
    </div>
  ) : (
    <>
      <div className="mb-6 grid gap-4 sm:grid-cols-3">
        <div className="card p-4">
          <ClipboardCheck className="mb-2 h-5 w-5 text-brand-700" />
          <p className="text-2xl font-bold text-gray-900">
            {assessments.length}
          </p>
          <p className="text-sm text-gray-500">avaliações atribuídas</p>
        </div>

        <div className="card p-4">
          <CheckCircle2 className="mb-2 h-5 w-5 text-green-600" />
          <p className="text-2xl font-bold text-gray-900">
            {completedCount}
          </p>
          <p className="text-sm text-gray-500">etapas aprovadas</p>
        </div>

        <div className="card p-4">
          <Award className="mb-2 h-5 w-5 text-amber-600" />
          <p className="text-2xl font-bold text-gray-900">
            {availableCount}
          </p>
          <p className="text-sm text-gray-500">disponíveis agora</p>
        </div>
      </div>

      <div className="grid gap-4 lg:grid-cols-2">
        {assessments.map((assessment) => (
          <AssessmentCard
            key={assessment.test_id}
            assessment={assessment}
            isStarting={
              startMutation.isPending &&
              startMutation.variables?.test_id === assessment.test_id
            }
            onStart={(selectedAssessment) =>
              startMutation.mutate(selectedAssessment)
            }
            onViewResult={(attemptId) =>
              navigate(`${ROUTES.EVALUATIONS}/${attemptId}/resultado`)
            }
          />
        ))}
      </div>
    </>
  )

  const personalCertifications = (
    <PersonalCertificationsPanel
      rows={myCertifications}
      isLoading={myCertificationsIsLoading}
      isFetching={myCertificationsIsFetching}
      error={myCertificationsError}
      onRetry={() => refetchMyCertifications()}
    />
  )
  return (
    <div className="page-container">
      <PageHeader
        title="Avaliações e certificações"
        description="Diagnóstico técnico e progressão de certificação dos participantes."
      />

      {hasManagementScope ? (
        <div className="space-y-8">
          {isAdmin && <AssessmentAccessAdminPanel />}

          {!isAdmin && (
            <section>
            <div className="mb-4">
              <h2 className="text-lg font-semibold text-gray-900">
                Minhas avaliações
              </h2>
              <p className="mt-1 text-sm text-gray-500">
                Avaliações atribuídas diretamente ao seu usuário.
              </p>
            </div>
            {personalAssessments}
            </section>
          )}

          {!isAdmin && (
            <section>
              <div className="mb-4">
                <h2 className="text-lg font-semibold text-gray-900">
                  Minhas certificações
                </h2>
                <p className="mt-1 text-sm text-gray-500">
                  Certificações efetivamente emitidas para o seu usuário.
                </p>
              </div>
              {personalCertifications}
            </section>
          )}
          <section>
            <div className="mb-4">
              <h2 className="flex items-center gap-2 text-lg font-semibold text-gray-900">
                <UsersRound className="h-5 w-5 text-brand-700" />
                {isSupervisor
                  ? 'Avaliações da minha equipe'
                  : 'Avaliações da organização'}
              </h2>
              <p className="mt-1 text-sm text-gray-500">
                {isSupervisor
                  ? 'Acompanhe somente os vendedores das equipes sob sua responsabilidade.'
                  : isAdmin
                  ? 'Acompanhe diretores, supervisores e vendedores ativos da organização.'
                  : 'Acompanhe supervisores e vendedores ativos da organização.'}
              </p>
            </div>

            <ManagedAssessmentsPanel
              rows={managedRows}
              isLoading={managedIsLoading}
              isFetching={managedIsFetching}
              error={managedError}
              onRetry={() => refetchManaged()}
              scopeLabel={
                isSupervisor ? 'suas equipes' : 'esta organização'
              }
            />
          </section>
        </div>
      ) : (
        <div className="space-y-8">
          <section>
            <div className="mb-4">
              <h2 className="text-lg font-semibold text-gray-900">
                Minhas avaliações
              </h2>
              <p className="mt-1 text-sm text-gray-500">
                Avaliações atribuídas diretamente ao seu usuário.
              </p>
            </div>
            {personalAssessments}
          </section>

          <section>
            <div className="mb-4">
              <h2 className="text-lg font-semibold text-gray-900">
                Minhas certificações
              </h2>
              <p className="mt-1 text-sm text-gray-500">
                Certificações efetivamente emitidas para o seu usuário.
              </p>
            </div>
            {personalCertifications}
          </section>
        </div>
      )}
    </div>
  )
}
