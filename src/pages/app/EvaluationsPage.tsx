import { useQuery } from '@tanstack/react-query'
import {
  Award,
  CheckCircle2,
  ClipboardCheck,
  Clock3,
  LockKeyhole,
  RefreshCw,
  ShieldCheck,
} from 'lucide-react'
import { useAuth } from '@/contexts/AuthContext'
import {
  AssessmentServiceError,
  getAvailableAssessments,
} from '@/services/assessmentService'
import type {
  AssessmentAvailability,
  AvailableAssessment,
} from '@/types/assessments'
import EmptyState from '@/components/shared/EmptyState'
import LoadingSpinner from '@/components/shared/LoadingSpinner'
import PageHeader from '@/components/shared/PageHeader'

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

function AssessmentCard({ assessment }: { assessment: AvailableAssessment }) {
  const nextAttempt = formatNextAttempt(assessment.next_attempt_at)

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
      </div>
    </article>
  )
}

export default function EvaluationsPage() {
  const { activeOrganization, user, isAdmin } = useAuth()
  const organizationId = activeOrganization?.id

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

  if (isAdmin) {
    return (
      <div className="page-container">
        <PageHeader
          title="Avaliações e certificações"
          description="Diagnóstico técnico e progressão de certificação dos participantes."
        />

        <div className="card">
          <EmptyState
            icon={ShieldCheck}
            title="Área destinada aos participantes"
            description="O administrador da plataforma não inicia tentativas. A aplicação das avaliações exige um usuário com vínculo ativo na organização."
          />
        </div>
      </div>
    )
  }

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

  return (
    <div className="page-container">
      <PageHeader
        title="Avaliações e certificações"
        description="Diagnóstico técnico e progressão de certificação dos participantes."
      />

      {!assessments.length ? (
        <div className="card">
          <EmptyState
            icon={ClipboardCheck}
            title="Nenhuma avaliação disponível"
            description="As avaliações aparecerão aqui quando forem publicadas para a sua organização."
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
              <p className="text-sm text-gray-500">avaliações publicadas</p>
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
              />
            ))}
          </div>
        </>
      )}
    </div>
  )
}
