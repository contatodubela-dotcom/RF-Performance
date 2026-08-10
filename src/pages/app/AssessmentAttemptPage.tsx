import { useEffect, useMemo, useRef, useState } from 'react'
import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query'
import {
  ArrowLeft,
  ArrowRight,
  CheckCircle2,
  Clock3,
  Loader2,
  Send,
  ShieldAlert,
} from 'lucide-react'
import { useNavigate, useParams } from 'react-router-dom'
import { toast } from 'sonner'
import ConfirmDialog from '@/components/shared/ConfirmDialog'
import EmptyState from '@/components/shared/EmptyState'
import LoadingSpinner from '@/components/shared/LoadingSpinner'
import PageHeader from '@/components/shared/PageHeader'
import { Progress } from '@/components/ui/progress'
import { ROUTES } from '@/constants/routes'
import {
  AssessmentServiceError,
  getAssessmentAttempt,
  saveAssessmentAnswer,
  submitAssessmentAttempt,
} from '@/services/assessmentService'
import type {
  AssessmentAttempt,
  AssessmentOptionCode,
} from '@/types/assessments'
import { isAssessmentAttemptExpired } from '@/types/assessments'

function formatRemainingTime(totalSeconds: number) {
  const hours = Math.floor(totalSeconds / 3600)
  const minutes = Math.floor((totalSeconds % 3600) / 60)
  const seconds = totalSeconds % 60

  if (hours > 0) {
    return [hours, minutes, seconds]
      .map((value) => String(value).padStart(2, '0'))
      .join(':')
  }

  return [minutes, seconds]
    .map((value) => String(value).padStart(2, '0'))
    .join(':')
}

function errorMessage(error: unknown, fallback: string) {
  return error instanceof AssessmentServiceError ? error.message : fallback
}

export default function AssessmentAttemptPage() {
  const { attemptId } = useParams<{ attemptId: string }>()
  const navigate = useNavigate()
  const queryClient = useQueryClient()
  const [currentIndex, setCurrentIndex] = useState(0)
  const [submitConfirmationOpen, setSubmitConfirmationOpen] = useState(false)
  const [pendingOptionCode, setPendingOptionCode] =
    useState<AssessmentOptionCode | null>(null)
  const [now, setNow] = useState(() => Date.now())
  const initializedAttemptId = useRef<string | null>(null)
  const expirationNotified = useRef(false)

  const attemptQueryKey = ['assessment-attempt', attemptId]

  const {
    data: attempt,
    error,
    isLoading,
    isFetching,
    refetch,
  } = useQuery({
    queryKey: attemptQueryKey,
    enabled: !!attemptId,
    queryFn: () => getAssessmentAttempt(attemptId!),
    refetchOnWindowFocus: false,
  })

  useEffect(() => {
    if (!attempt?.expires_at || attempt.status !== 'in_progress') return

    const timer = window.setInterval(() => setNow(Date.now()), 1000)
    return () => window.clearInterval(timer)
  }, [attempt?.expires_at, attempt?.status])

  const remainingSeconds = useMemo(() => {
    if (!attempt?.expires_at) return null

    return Math.max(
      0,
      Math.floor((new Date(attempt.expires_at).getTime() - now) / 1000),
    )
  }, [attempt?.expires_at, now])

  useEffect(() => {
    if (
      attempt?.status === 'in_progress' &&
      remainingSeconds === 0 &&
      !expirationNotified.current
    ) {
      expirationNotified.current = true
      toast.error('O prazo desta tentativa terminou.')
      void refetch()
    }
  }, [attempt?.status, refetch, remainingSeconds])

  useEffect(() => {
    if (!attempt || initializedAttemptId.current === attempt.attempt_id) return

    const firstUnanswered = attempt.items.findIndex(
      (item) => item.selected_option_code === null,
    )

    setCurrentIndex(firstUnanswered >= 0 ? firstUnanswered : 0)
    initializedAttemptId.current = attempt.attempt_id
  }, [attempt])

  useEffect(() => {
    if (attempt?.status === 'graded' && attemptId) {
      navigate(`${ROUTES.EVALUATIONS}/${attemptId}/resultado`, {
        replace: true,
      })
    }
  }, [attempt?.status, attemptId, navigate])

  const answerMutation = useMutation({
    mutationFn: ({
      attemptItemId,
      optionCode,
    }: {
      attemptItemId: string
      optionCode: AssessmentOptionCode
    }) => saveAssessmentAnswer(attemptId!, attemptItemId, optionCode),
    onSuccess: (response, variables) => {
      if (isAssessmentAttemptExpired(response)) {
        toast.error('O prazo desta tentativa terminou.')
        navigate(ROUTES.EVALUATIONS, { replace: true })
        return
      }

      queryClient.setQueryData<AssessmentAttempt>(
        attemptQueryKey,
        (current) => {
          if (!current) return current

          return {
            ...current,
            answered_questions: response.answered_questions,
            items: current.items.map((item) =>
              item.attempt_item_id === variables.attemptItemId
                ? {
                    ...item,
                    selected_option_code: response.selected_option_code,
                    answered_at: response.saved_at,
                  }
                : item,
            ),
          }
        },
      )
    },
    onError: (mutationError) => {
      toast.error(
        errorMessage(mutationError, 'Não foi possível salvar esta resposta.'),
      )
    },
    onSettled: () => setPendingOptionCode(null),
  })

  const submitMutation = useMutation({
    mutationFn: () => submitAssessmentAttempt(attemptId!),
    onSuccess: (response) => {
      if (isAssessmentAttemptExpired(response)) {
        toast.error('O prazo desta tentativa terminou.')
        navigate(ROUTES.EVALUATIONS, { replace: true })
        return
      }

      queryClient.setQueryData(
        ['assessment-result', attemptId],
        response,
      )
      queryClient.invalidateQueries({ queryKey: ['available-assessments'] })
      navigate(`${ROUTES.EVALUATIONS}/${attemptId}/resultado`, {
        replace: true,
      })
    },
    onError: (mutationError) => {
      toast.error(
        errorMessage(mutationError, 'Não foi possível entregar a avaliação.'),
      )
    },
    onSettled: () => setSubmitConfirmationOpen(false),
  })

  if (!attemptId) {
    return (
      <div className="page-container">
        <div className="card">
          <EmptyState
            icon={ShieldAlert}
            title="Tentativa inválida"
            description="O identificador da tentativa não foi informado."
          />
        </div>
      </div>
    )
  }

  if (isLoading) {
    return (
      <div className="page-container flex min-h-[400px] items-center justify-center">
        <LoadingSpinner size="lg" message="Carregando avaliação..." />
      </div>
    )
  }

  if (error || !attempt) {
    return (
      <div className="page-container">
        <PageHeader
          title="Avaliação"
          description="Não foi possível carregar a tentativa."
        />

        <div className="card">
          <EmptyState
            icon={ShieldAlert}
            title="Falha ao carregar tentativa"
            description={errorMessage(
              error,
              'Não foi possível carregar esta tentativa.',
            )}
            action={(
              <div className="flex flex-wrap justify-center gap-2">
                <button
                  type="button"
                  className="btn-secondary"
                  onClick={() => navigate(ROUTES.EVALUATIONS)}
                >
                  Voltar às avaliações
                </button>
                <button
                  type="button"
                  className="btn-primary"
                  onClick={() => refetch()}
                  disabled={isFetching}
                >
                  {isFetching ? 'Carregando...' : 'Tentar novamente'}
                </button>
              </div>
            )}
          />
        </div>
      </div>
    )
  }

  if (attempt.status === 'graded') {
    return (
      <div className="page-container flex min-h-[400px] items-center justify-center">
        <LoadingSpinner size="lg" message="Abrindo resultado..." />
      </div>
    )
  }

  if (attempt.status !== 'in_progress') {
    return (
      <div className="page-container">
        <PageHeader
          title={attempt.test_title}
          description={`Tentativa ${attempt.attempt_no}`}
        />

        <div className="card">
          <EmptyState
            icon={Clock3}
            title="Tentativa indisponível"
            description="Esta tentativa não está mais aberta para respostas."
            action={(
              <button
                type="button"
                className="btn-secondary"
                onClick={() => navigate(ROUTES.EVALUATIONS)}
              >
                Voltar às avaliações
              </button>
            )}
          />
        </div>
      </div>
    )
  }

  const currentItem = attempt.items[currentIndex]
  const answeredCount = attempt.items.filter(
    (item) => item.selected_option_code !== null,
  ).length
  const progress = attempt.total_questions
    ? (answeredCount / attempt.total_questions) * 100
    : 0
  const allAnswered = answeredCount === attempt.total_questions
  const displayedSelection =
    pendingOptionCode ?? currentItem?.selected_option_code ?? null

  if (!currentItem) {
    return (
      <div className="page-container">
        <div className="card">
          <EmptyState
            icon={ShieldAlert}
            title="Avaliação sem questões"
            description="A tentativa não possui questões disponíveis."
          />
        </div>
      </div>
    )
  }

  return (
    <div className="page-container">
      <PageHeader
        title={attempt.test_title}
        description={`Tentativa ${attempt.attempt_no} • ${attempt.total_questions} questões`}
      />

      <div className="mb-5 grid gap-4 lg:grid-cols-[1fr_auto]">
        <div className="card p-4">
          <div className="mb-2 flex items-center justify-between gap-3 text-sm">
            <span className="font-medium text-gray-700">
              {answeredCount} de {attempt.total_questions} respondidas
            </span>
            <span className="text-gray-500">{Math.round(progress)}%</span>
          </div>
          <Progress value={progress} className="h-2" />
        </div>

        <div className="card flex min-w-48 items-center gap-3 p-4">
          <Clock3 className="h-5 w-5 text-brand-700" />
          <div>
            <p className="text-xs font-medium uppercase tracking-wide text-gray-500">
              Tempo restante
            </p>
            <p className="font-semibold text-gray-900">
              {remainingSeconds === null
                ? 'Sem limite'
                : formatRemainingTime(remainingSeconds)}
            </p>
          </div>
        </div>
      </div>

      <div className="grid gap-5 xl:grid-cols-[minmax(0,1fr)_280px]">
        <section className="card p-5 sm:p-6">
          <div className="mb-5 flex items-start justify-between gap-4">
            <div>
              <p className="text-xs font-semibold uppercase tracking-wide text-brand-700">
                Questão {currentItem.position_no} de {attempt.total_questions}
              </p>
              <h2 className="mt-2 text-lg font-semibold leading-7 text-gray-900">
                {currentItem.prompt}
              </h2>
            </div>

            {answerMutation.isPending && (
              <span className="flex shrink-0 items-center gap-2 text-xs text-gray-500">
                <Loader2 className="h-4 w-4 animate-spin" />
                Salvando
              </span>
            )}
          </div>

          <div className="space-y-3">
            {currentItem.options.map((option, optionIndex) => {
              const selected = displayedSelection === option.code

              return (
                <button
                  key={option.code}
                  type="button"
                  className={`flex w-full items-start gap-3 rounded-xl border p-4 text-left transition-colors ${
                    selected
                      ? 'border-brand-500 bg-brand-50'
                      : 'border-gray-200 bg-white hover:border-brand-300 hover:bg-gray-50'
                  }`}
                  onClick={() => {
                    setPendingOptionCode(option.code)
                    answerMutation.mutate({
                      attemptItemId: currentItem.attempt_item_id,
                      optionCode: option.code,
                    })
                  }}
                  disabled={answerMutation.isPending || submitMutation.isPending}
                >
                  <span
                    className={`flex h-7 w-7 shrink-0 items-center justify-center rounded-full border text-sm font-semibold ${
                      selected
                        ? 'border-brand-600 bg-brand-600 text-white'
                        : 'border-gray-300 text-gray-600'
                    }`}
                  >
                    {String.fromCharCode(65 + optionIndex)}
                  </span>
                  <span className="pt-0.5 text-sm leading-6 text-gray-800">
                    {option.text}
                  </span>
                </button>
              )
            })}
          </div>

          <div className="mt-6 flex flex-wrap items-center justify-between gap-3 border-t border-gray-100 pt-5">
            <button
              type="button"
              className="btn-secondary"
              onClick={() => setCurrentIndex((index) => Math.max(0, index - 1))}
              disabled={currentIndex === 0 || answerMutation.isPending}
            >
              <ArrowLeft className="mr-2 h-4 w-4" />
              Anterior
            </button>

            {currentIndex < attempt.items.length - 1 ? (
              <button
                type="button"
                className="btn-primary"
                onClick={() =>
                  setCurrentIndex((index) =>
                    Math.min(attempt.items.length - 1, index + 1),
                  )
                }
                disabled={answerMutation.isPending}
              >
                Próxima
                <ArrowRight className="ml-2 h-4 w-4" />
              </button>
            ) : (
              <button
                type="button"
                className="btn-primary"
                onClick={() => setSubmitConfirmationOpen(true)}
                disabled={
                  !allAnswered ||
                  answerMutation.isPending ||
                  submitMutation.isPending
                }
              >
                <Send className="mr-2 h-4 w-4" />
                Entregar avaliação
              </button>
            )}
          </div>

          {!allAnswered && currentIndex === attempt.items.length - 1 && (
            <p className="mt-3 text-right text-xs text-amber-700">
              Responda todas as questões antes de entregar.
            </p>
          )}
        </section>

        <aside className="card h-fit p-4">
          <h2 className="text-sm font-semibold text-gray-900">Questões</h2>
          <p className="mt-1 text-xs text-gray-500">
            Selecione um número para revisar uma resposta.
          </p>

          <div className="mt-4 grid grid-cols-5 gap-2">
            {attempt.items.map((item, index) => {
              const isCurrent = index === currentIndex
              const isAnswered = item.selected_option_code !== null

              return (
                <button
                  key={item.attempt_item_id}
                  type="button"
                  className={`flex h-9 items-center justify-center rounded-lg border text-sm font-semibold transition-colors ${
                    isCurrent
                      ? 'border-brand-600 bg-brand-600 text-white'
                      : isAnswered
                        ? 'border-green-200 bg-green-50 text-green-700'
                        : 'border-gray-200 bg-white text-gray-600 hover:border-brand-300'
                  }`}
                  onClick={() => setCurrentIndex(index)}
                  disabled={answerMutation.isPending}
                  aria-label={`Ir para a questão ${item.position_no}`}
                >
                  {item.position_no}
                </button>
              )
            })}
          </div>

          <div className="mt-5 space-y-2 border-t border-gray-100 pt-4 text-xs text-gray-600">
            <p className="flex items-center gap-2">
              <CheckCircle2 className="h-4 w-4 text-green-600" />
              As respostas são salvas uma a uma.
            </p>
            <p className="flex items-start gap-2">
              <ShieldAlert className="mt-0.5 h-4 w-4 shrink-0 text-brand-700" />
              O gabarito permanece protegido durante a avaliação.
            </p>
          </div>
        </aside>
      </div>

      <ConfirmDialog
        open={submitConfirmationOpen}
        title="Entregar avaliação?"
        description={`Você respondeu ${answeredCount} de ${attempt.total_questions} questões. Após a entrega, as respostas não poderão ser alteradas.`}
        confirmLabel={submitMutation.isPending ? 'Entregando...' : 'Entregar'}
        onConfirm={() => submitMutation.mutate()}
        onCancel={() => setSubmitConfirmationOpen(false)}
      />
    </div>
  )
}
