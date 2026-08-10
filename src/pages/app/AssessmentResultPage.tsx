import { useQuery } from '@tanstack/react-query'
import {
  Award,
  CheckCircle2,
  ClipboardCheck,
  LockKeyhole,
  Scale,
  ShieldAlert,
  XCircle,
} from 'lucide-react'
import { useNavigate, useParams } from 'react-router-dom'
import EmptyState from '@/components/shared/EmptyState'
import LoadingSpinner from '@/components/shared/LoadingSpinner'
import PageHeader from '@/components/shared/PageHeader'
import { ROUTES } from '@/constants/routes'
import {
  AssessmentServiceError,
  getAssessmentAttemptResult,
} from '@/services/assessmentService'
import type {
  AssessmentAttemptResult,
  AssessmentResultReason,
  AssessmentReviewItem,
} from '@/types/assessments'

const RESULT_REASON_LABELS: Record<AssessmentResultReason, string> = {
  critical_error: 'Reprovado por erro crítico',
  overall_score_below_minimum: 'Nota geral abaixo do mínimo',
  legal_score_below_minimum: 'Nota de legislação abaixo do mínimo',
  diagnostic_completed: 'Diagnóstico concluído',
  approved: 'Aprovado',
}

function errorMessage(error: unknown) {
  return error instanceof AssessmentServiceError
    ? error.message
    : 'Não foi possível carregar o resultado desta tentativa.'
}

function ReviewQuestion({ item }: { item: AssessmentReviewItem }) {
  return (
    <article className="card p-5">
      <div className="flex items-start justify-between gap-4">
        <div>
          <p className="text-xs font-semibold uppercase tracking-wide text-brand-700">
            Questão {item.position_no}
          </p>
          <h3 className="mt-2 font-semibold leading-6 text-gray-900">
            {item.prompt}
          </h3>
        </div>

        {item.is_correct ? (
          <span className="badge shrink-0 bg-green-100 text-green-800">
            <CheckCircle2 className="mr-1 h-3 w-3" />
            Correta
          </span>
        ) : (
          <span className="badge shrink-0 bg-red-100 text-red-800">
            <XCircle className="mr-1 h-3 w-3" />
            Incorreta
          </span>
        )}
      </div>

      <div className="mt-4 space-y-2">
        {item.options.map((option, optionIndex) => {
          const selected = item.selected_option_code === option.code
          const correct = item.correct_option_code === option.code

          return (
            <div
              key={option.code}
              className={`flex items-start gap-3 rounded-lg border p-3 text-sm ${
                correct
                  ? 'border-green-200 bg-green-50'
                  : selected
                    ? 'border-red-200 bg-red-50'
                    : 'border-gray-200 bg-white'
              }`}
            >
              <span
                className={`flex h-6 w-6 shrink-0 items-center justify-center rounded-full border text-xs font-semibold ${
                  correct
                    ? 'border-green-600 bg-green-600 text-white'
                    : selected
                      ? 'border-red-500 bg-red-500 text-white'
                      : 'border-gray-300 text-gray-600'
                }`}
              >
                {String.fromCharCode(65 + optionIndex)}
              </span>
              <div className="min-w-0 flex-1">
                <p className="leading-5 text-gray-800">{option.text}</p>
                <div className="mt-1 flex flex-wrap gap-2 text-xs font-medium">
                  {selected && <span className="text-gray-600">Sua resposta</span>}
                  {correct && <span className="text-green-700">Resposta correta</span>}
                </div>
              </div>
            </div>
          )
        })}
      </div>

      {(item.justification || item.source_reference) && (
        <div className="mt-4 rounded-lg bg-gray-50 p-4 text-sm text-gray-700">
          {item.justification && (
            <p className="leading-6">
              <strong>Justificativa:</strong> {item.justification}
            </p>
          )}
          {item.source_reference && (
            <p className="mt-2 leading-6">
              <strong>Referência:</strong> {item.source_reference}
            </p>
          )}
        </div>
      )}
    </article>
  )
}

function ResultBanner({ result }: { result: AssessmentAttemptResult }) {
  const diagnostic = result.test_purpose === 'diagnostic'
  const successful = diagnostic || result.passed

  return (
    <div
      className={`card border p-5 ${
        successful
          ? 'border-green-200 bg-green-50'
          : 'border-red-200 bg-red-50'
      }`}
    >
      <div className="flex items-start gap-3">
        {successful ? (
          <CheckCircle2 className="mt-0.5 h-6 w-6 shrink-0 text-green-700" />
        ) : (
          <XCircle className="mt-0.5 h-6 w-6 shrink-0 text-red-700" />
        )}

        <div>
          <h2
            className={`font-semibold ${
              successful ? 'text-green-900' : 'text-red-900'
            }`}
          >
            {diagnostic
              ? 'Diagnóstico concluído'
              : result.passed
                ? 'Certificação aprovada'
                : 'Certificação não aprovada'}
          </h2>
          <p
            className={`mt-1 text-sm ${
              successful ? 'text-green-800' : 'text-red-800'
            }`}
          >
            {RESULT_REASON_LABELS[result.result_reason]}
          </p>
        </div>
      </div>
    </div>
  )
}

export default function AssessmentResultPage() {
  const { attemptId } = useParams<{ attemptId: string }>()
  const navigate = useNavigate()

  const {
    data: result,
    error,
    isLoading,
    isFetching,
    refetch,
  } = useQuery({
    queryKey: ['assessment-result', attemptId],
    enabled: !!attemptId,
    queryFn: () => getAssessmentAttemptResult(attemptId!),
    refetchOnWindowFocus: false,
  })

  if (!attemptId) {
    return (
      <div className="page-container">
        <div className="card">
          <EmptyState
            icon={ShieldAlert}
            title="Resultado inválido"
            description="O identificador da tentativa não foi informado."
          />
        </div>
      </div>
    )
  }

  if (isLoading) {
    return (
      <div className="page-container flex min-h-[400px] items-center justify-center">
        <LoadingSpinner size="lg" message="Carregando resultado..." />
      </div>
    )
  }

  if (error || !result) {
    return (
      <div className="page-container">
        <PageHeader
          title="Resultado da avaliação"
          description="Não foi possível carregar o resultado."
        />

        <div className="card">
          <EmptyState
            icon={ShieldAlert}
            title="Resultado indisponível"
            description={errorMessage(error)}
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

  return (
    <div className="page-container">
      <PageHeader
        title={result.test_title}
        description={`Resultado da tentativa ${result.attempt_no} • versão ${result.version_code}`}
      />

      <ResultBanner result={result} />

      <div className="my-5 grid gap-4 sm:grid-cols-2 xl:grid-cols-4">
        <div className="card p-4">
          <Award className="mb-2 h-5 w-5 text-brand-700" />
          <p className="text-2xl font-bold text-gray-900">
            {result.overall_score}%
          </p>
          <p className="text-sm text-gray-500">
            nota geral • mínimo {result.passing_score}%
          </p>
        </div>

        <div className="card p-4">
          <Scale className="mb-2 h-5 w-5 text-blue-600" />
          <p className="text-2xl font-bold text-gray-900">
            {result.legal_score}%
          </p>
          <p className="text-sm text-gray-500">
            legislação • mínimo {result.legal_min_score}%
          </p>
        </div>

        <div className="card p-4">
          <ClipboardCheck className="mb-2 h-5 w-5 text-green-600" />
          <p className="text-2xl font-bold text-gray-900">
            {result.correct_answers}/{result.total_questions}
          </p>
          <p className="text-sm text-gray-500">respostas corretas</p>
        </div>

        <div className="card p-4">
          <ShieldAlert className="mb-2 h-5 w-5 text-amber-600" />
          <p className="text-2xl font-bold text-gray-900">
            {result.critical_errors}
          </p>
          <p className="text-sm text-gray-500">erros críticos registrados</p>
        </div>
      </div>

      <section className="card p-5">
        <h2 className="font-semibold text-gray-900">Desempenho por competência</h2>
        <p className="mt-1 text-sm text-gray-500">
          Resultado calculado no servidor para cada domínio avaliado.
        </p>

        {result.competency_scores.length ? (
          <div className="mt-4 grid gap-3 md:grid-cols-2 xl:grid-cols-3">
            {result.competency_scores.map((competency) => (
              <article
                key={competency.competency_id}
                className="rounded-xl border border-gray-200 p-4"
              >
                <div className="flex items-start justify-between gap-3">
                  <div>
                    <p className="font-medium text-gray-900">
                      {competency.competency_name}
                    </p>
                    <p className="mt-1 text-xs text-gray-500">
                      {competency.correct_count}/{competency.questions_count} corretas
                      {competency.is_legal ? ' • legislação' : ''}
                    </p>
                  </div>
                  <span
                    className={`badge shrink-0 ${
                      competency.passed
                        ? 'bg-green-100 text-green-800'
                        : 'bg-red-100 text-red-800'
                    }`}
                  >
                    {competency.score}%
                  </span>
                </div>
              </article>
            ))}
          </div>
        ) : (
          <p className="mt-4 text-sm text-gray-500">
            Nenhuma competência foi calculada para esta tentativa.
          </p>
        )}
      </section>

      <section className="mt-5">
        <div className="mb-3 flex flex-wrap items-end justify-between gap-3">
          <div>
            <h2 className="font-semibold text-gray-900">Revisão das questões</h2>
            <p className="mt-1 text-sm text-gray-500">
              A exibição do gabarito segue a política segura da avaliação.
            </p>
          </div>

          <button
            type="button"
            className="btn-secondary"
            onClick={() => navigate(ROUTES.EVALUATIONS)}
          >
            Voltar às avaliações
          </button>
        </div>

        {result.review_available && result.review.length ? (
          <div className="space-y-4">
            {result.review.map((item) => (
              <ReviewQuestion
                key={`${result.attempt_id}-${item.position_no}`}
                item={item}
              />
            ))}
          </div>
        ) : (
          <div className="card">
            <EmptyState
              icon={LockKeyhole}
              title="Revisão detalhada protegida"
              description={
                result.test_purpose === 'diagnostic'
                  ? 'A revisão ainda não está disponível para esta tentativa.'
                  : 'Nas certificações, o gabarito é liberado somente após aprovação ou após a última tentativa permitida.'
              }
            />
          </div>
        )}
      </section>
    </div>
  )
}
