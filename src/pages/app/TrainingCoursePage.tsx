import { useEffect, useMemo, useRef, useState } from 'react'
import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query'
import {
  ArrowLeft,
  ArrowRight,
  BookOpen,
  CheckCircle2,
  Circle,
  Clock3,
  Download,
  ExternalLink,
  FileText,
  Loader2,
  RefreshCw,
  ShieldAlert,
} from 'lucide-react'
import { useNavigate, useParams } from 'react-router-dom'
import { toast } from 'sonner'
import EmptyState from '@/components/shared/EmptyState'
import LoadingSpinner from '@/components/shared/LoadingSpinner'
import PageHeader from '@/components/shared/PageHeader'
import { Progress } from '@/components/ui/progress'
import { ROUTES } from '@/constants/routes'
import { useAuth } from '@/contexts/AuthContext'
import {
  createTrainingAssetSignedUrl,
  getTrainingLearningExperience,
  saveTrainingLessonProgress,
} from '@/services/trainingLibraryService'
import type {
  TrainingLibraryAsset,
  TrainingLibraryLessonWithProgress,
  TrainingLibraryModuleWithLessons,
} from '@/types/trainingLibrary'

type Metadata = Record<string, unknown>

function metadataString(metadata: Metadata, key: string) {
  const value = metadata[key]
  return typeof value === 'string' && value.trim() ? value : null
}

function metadataStringArray(metadata: Metadata, key: string) {
  const value = metadata[key]

  if (!Array.isArray(value)) return []

  return value.filter(
    (item): item is string => typeof item === 'string' && item.trim().length > 0,
  )
}

function metadataObjectArray(metadata: Metadata, key: string) {
  const value = metadata[key]

  if (!Array.isArray(value)) return []

  return value.filter(
    (item): item is Record<string, unknown> =>
      !!item && typeof item === 'object' && !Array.isArray(item),
  )
}

function objectString(item: Record<string, unknown>, key: string) {
  const value = item[key]
  return typeof value === 'string' ? value : ''
}

function objectNumber(item: Record<string, unknown>, key: string) {
  const value = item[key]
  return typeof value === 'number' ? value : null
}

function ContentList({
  title,
  items,
}: {
  title: string
  items: string[]
}) {
  if (!items.length) return null

  return (
    <section className="rounded-xl border border-gray-200 bg-white p-4">
      <h3 className="font-semibold text-gray-900">{title}</h3>
      <ul className="mt-3 space-y-2">
        {items.map((item, index) => (
          <li
            key={`${title}-${index}`}
            className="flex gap-3 text-sm leading-6 text-gray-700"
          >
            <CheckCircle2 className="mt-1 h-4 w-4 shrink-0 text-brand-700" />
            <span>{item}</span>
          </li>
        ))}
      </ul>
    </section>
  )
}

function Highlight({
  label,
  value,
}: {
  label: string
  value: string | null
}) {
  if (!value) return null

  return (
    <section className="rounded-xl border border-brand-100 bg-brand-50 p-4">
      <p className="text-xs font-semibold uppercase tracking-wide text-brand-700">
        {label}
      </p>
      <p className="mt-2 text-sm font-medium leading-6 text-gray-900">
        {value}
      </p>
    </section>
  )
}

function LessonContent({
  lesson,
}: {
  lesson: TrainingLibraryLessonWithProgress
}) {
  const metadata = lesson.metadata
  const learningObjective = metadataString(metadata, 'learning_objective')
  const summary = metadataString(metadata, 'summary')
  const customerQuestion = metadataString(metadata, 'customer_question')
  const keyPoints = metadataStringArray(metadata, 'key_points')
  const framework = metadataObjectArray(metadata, 'framework')
  const practiceQuestions = metadataStringArray(metadata, 'practice_questions')
  const recommendedPhrase = metadataString(metadata, 'recommended_phrase')
  const callout = metadataString(metadata, 'callout')
  const example = metadataString(metadata, 'example')
  const costOfInaction = metadataStringArray(
    metadata,
    'cost_of_inaction_examples',
  )
  const practiceQuestion = metadataString(metadata, 'practice_question')
  const closingQuestions = metadataStringArray(metadata, 'closing_questions')
  const serviceScript = metadataObjectArray(metadata, 'service_script')
  const exercise = metadataString(metadata, 'exercise')
  const practiceChecklist = metadataStringArray(metadata, 'practice_checklist')
  const leaderEvaluation = metadataStringArray(metadata, 'leader_evaluation')
  const closingMessage = metadataString(metadata, 'closing_message')
  const teamCommitment = metadataString(metadata, 'team_commitment')

  return (
    <div className="space-y-4">
      {lesson.description && (
        <p className="text-base leading-7 text-gray-700">
          {lesson.description}
        </p>
      )}

      <Highlight
        label="Objetivo da aula"
        value={learningObjective}
      />

      {summary && (
        <section className="rounded-xl border border-gray-200 bg-gray-50 p-4">
          <h3 className="font-semibold text-gray-900">Resumo</h3>
          <p className="mt-2 text-sm leading-6 text-gray-700">{summary}</p>
        </section>
      )}

      <Highlight
        label="Pergunta silenciosa do cliente"
        value={customerQuestion}
      />

      <ContentList
        title="Pontos principais"
        items={keyPoints}
      />

      {!!framework.length && (
        <section className="rounded-xl border border-gray-200 bg-white p-4">
          <h3 className="font-semibold text-gray-900">Os 5 Sims</h3>
          <div className="mt-3 grid gap-3 sm:grid-cols-2 xl:grid-cols-5">
            {framework.map((item, index) => {
              const sequence = objectNumber(item, 'sequence') ?? index + 1
              const name = objectString(item, 'name')
              const question = objectString(item, 'customer_question')

              return (
                <div
                  key={`${sequence}-${name}`}
                  className="rounded-lg border border-gray-200 p-3"
                >
                  <span className="text-xs font-semibold text-brand-700">
                    SIM {sequence}
                  </span>
                  <p className="mt-1 font-semibold text-gray-900">{name}</p>
                  {question && (
                    <p className="mt-1 text-xs leading-5 text-gray-500">
                      {question}
                    </p>
                  )}
                </div>
              )
            })}
          </div>
        </section>
      )}

      <ContentList
        title="Perguntas para praticar"
        items={practiceQuestions}
      />

      <Highlight
        label="Frase recomendada"
        value={recommendedPhrase}
      />

      <Highlight
        label="Atenção"
        value={callout}
      />

      <Highlight
        label="Exemplo prático"
        value={example}
      />

      <ContentList
        title="Custos de continuar parado"
        items={costOfInaction}
      />

      <Highlight
        label="Pergunta para praticar"
        value={practiceQuestion}
      />

      <ContentList
        title="Perguntas de fechamento"
        items={closingQuestions}
      />

      {!!serviceScript.length && (
        <section className="rounded-xl border border-gray-200 bg-white p-4">
          <h3 className="font-semibold text-gray-900">Roteiro de atendimento</h3>
          <div className="mt-3 space-y-3">
            {serviceScript.map((item, index) => {
              const sequence = objectNumber(item, 'sequence') ?? index + 1
              const step = objectString(item, 'step')
              const focus = objectString(item, 'focus')

              return (
                <div
                  key={`${sequence}-${step}`}
                  className="flex gap-3 rounded-lg bg-gray-50 p-3"
                >
                  <span className="flex h-7 w-7 shrink-0 items-center justify-center rounded-full bg-brand-600 text-xs font-bold text-white">
                    {sequence}
                  </span>
                  <div>
                    <p className="text-sm font-semibold text-gray-900">{step}</p>
                    {focus && (
                      <p className="mt-1 text-xs leading-5 text-gray-600">
                        {focus}
                      </p>
                    )}
                  </div>
                </div>
              )
            })}
          </div>
        </section>
      )}

      <Highlight
        label="Exercício"
        value={exercise}
      />

      <ContentList
        title="Checklist da prática"
        items={practiceChecklist}
      />

      <ContentList
        title="O líder observa"
        items={leaderEvaluation}
      />

      <Highlight
        label="Mensagem final"
        value={closingMessage}
      />

      <Highlight
        label="Compromisso da equipe"
        value={teamCommitment}
      />
    </div>
  )
}

function lessonStatusLabel(lesson: TrainingLibraryLessonWithProgress) {
  if (lesson.progress?.status === 'completed') return 'Concluída'
  if (lesson.progress?.status === 'in_progress') return 'Em andamento'
  return 'Não iniciada'
}

function canPreviewAssetInBrowser(asset: TrainingLibraryAsset) {
  return (
    asset.mime_type === 'application/pdf' ||
    asset.mime_type.startsWith('image/')
  )
}

export default function TrainingCoursePage() {
  const { trainingId } = useParams<{ trainingId: string }>()
  const navigate = useNavigate()
  const queryClient = useQueryClient()
  const { activeOrganization, user } = useAuth()
  const orgId = activeOrganization?.id
  const [currentIndex, setCurrentIndex] = useState(0)
  const [openingAssetId, setOpeningAssetId] = useState<string | null>(null)
  const initializedTrainingId = useRef<string | null>(null)
  const startedLessonIds = useRef<Set<string>>(new Set())

  const queryKey = ['training-learning-experience', orgId, trainingId, user?.id]

  const {
    data: experience,
    error,
    isLoading,
    isFetching,
    refetch,
  } = useQuery({
    queryKey,
    enabled: !!orgId && !!trainingId && !!user?.id,
    queryFn: () => getTrainingLearningExperience(orgId!, trainingId!),
    refetchOnWindowFocus: false,
  })

  const visibleModules = useMemo<TrainingLibraryModuleWithLessons[]>(() => {
    if (!experience) return []

    return experience.modules
      .filter((module) => module.status === 'published')
      .map((module) => ({
        ...module,
        lessons: module.lessons.filter((lesson) => lesson.status === 'published'),
      }))
      .filter((module) => module.lessons.length > 0)
  }, [experience])

  const lessons = useMemo(
    () => visibleModules.flatMap((module) => module.lessons),
    [visibleModules],
  )

  useEffect(() => {
    if (!experience || !trainingId || initializedTrainingId.current === trainingId) {
      return
    }

    const firstIncomplete = lessons.findIndex(
      (lesson) => lesson.progress?.status !== 'completed',
    )

    setCurrentIndex(firstIncomplete >= 0 ? firstIncomplete : Math.max(lessons.length - 1, 0))
    initializedTrainingId.current = trainingId
  }, [experience, lessons, trainingId])

  const currentLesson = lessons[currentIndex] ?? null
  const requiredLessons = lessons.filter((lesson) => lesson.is_required)
  const completedRequired = requiredLessons.filter(
    (lesson) => lesson.progress?.status === 'completed',
  ).length
  const progressPercent = requiredLessons.length
    ? Math.round((completedRequired / requiredLessons.length) * 100)
    : 0

  const startMutation = useMutation({
    mutationFn: (lesson: TrainingLibraryLessonWithProgress) =>
      saveTrainingLessonProgress({
        organizationId: orgId!,
        trainingId: trainingId!,
        lessonId: lesson.id,
        status: 'in_progress',
      }),
    onSuccess: () => {
      void queryClient.invalidateQueries({ queryKey })
    },
    onError: () => {
      toast.error('Não foi possível registrar o início desta aula.')
    },
  })

  useEffect(() => {
    if (
      !currentLesson ||
      !orgId ||
      !trainingId ||
      currentLesson.progress?.status === 'completed' ||
      currentLesson.progress?.status === 'in_progress' ||
      startedLessonIds.current.has(currentLesson.id)
    ) {
      return
    }

    startedLessonIds.current.add(currentLesson.id)
    startMutation.mutate(currentLesson)
  }, [
    currentLesson,
    orgId,
    trainingId,
    startMutation,
  ])

  const completeMutation = useMutation({
    mutationFn: (lesson: TrainingLibraryLessonWithProgress) =>
      saveTrainingLessonProgress({
        organizationId: orgId!,
        trainingId: trainingId!,
        lessonId: lesson.id,
        status: 'completed',
      }),
    onSuccess: async () => {
      await queryClient.invalidateQueries({ queryKey })

      if (currentIndex < lessons.length - 1) {
        setCurrentIndex((index) => Math.min(index + 1, lessons.length - 1))
      } else {
        toast.success('Treinamento concluído.')
      }
    },
    onError: () => {
      toast.error('Não foi possível concluir esta aula.')
    },
  })

  async function handleOpenAsset(asset: TrainingLibraryAsset) {
    setOpeningAssetId(asset.id)

    try {
      const signedUrl = await createTrainingAssetSignedUrl(asset)
      window.open(signedUrl, '_blank', 'noopener,noreferrer')
    } catch (openError) {
      toast.error(
        openError instanceof Error
          ? openError.message
          : 'Não foi possível abrir o material.',
      )
    } finally {
      setOpeningAssetId(null)
    }
  }

  if (!trainingId) {
    return (
      <div className="page-container">
        <div className="card">
          <EmptyState
            icon={ShieldAlert}
            title="Treinamento inválido"
            description="O identificador do treinamento não foi informado."
          />
        </div>
      </div>
    )
  }

  if (!orgId || !user?.id || isLoading) {
    return (
      <div className="page-container flex min-h-[400px] items-center justify-center">
        <LoadingSpinner size="lg" message="Carregando treinamento..." />
      </div>
    )
  }

  if (error || !experience) {
    return (
      <div className="page-container">
        <PageHeader
          title="Treinamento"
          description="Não foi possível carregar a experiência de aprendizagem."
        />

        <div className="card">
          <EmptyState
            icon={ShieldAlert}
            title="Treinamento indisponível"
            description={
              error instanceof Error
                ? error.message
                : 'Não foi possível carregar este treinamento.'
            }
            action={(
              <div className="flex flex-wrap justify-center gap-2">
                <button
                  type="button"
                  className="btn-secondary"
                  onClick={() => navigate(ROUTES.TRAINING)}
                >
                  Voltar aos treinamentos
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

  if (!currentLesson) {
    return (
      <div className="page-container">
        <PageHeader
          title={experience.training.title}
          description={experience.training.description}
        />
        <div className="card">
          <EmptyState
            icon={BookOpen}
            title="Aulas ainda não disponíveis"
            description="Este treinamento ainda não possui aulas publicadas."
          />
        </div>
      </div>
    )
  }

  const currentModule = visibleModules.find(
    (module) => module.id === currentLesson.module_id,
  )
  const currentCompleted = currentLesson.progress?.status === 'completed'
  const assets = experience.training.assets.filter(
    (asset) => asset.asset_type !== 'cover',
  )

  return (
    <div className="page-container">
      <PageHeader
        title={experience.training.title}
        description={experience.training.description}
        action={(
          <button
            type="button"
            className="btn-secondary"
            onClick={() => navigate(ROUTES.TRAINING)}
          >
            <ArrowLeft className="mr-2 h-4 w-4" />
            Biblioteca
          </button>
        )}
      />

      <div className="mb-5 card p-4">
        <div className="mb-2 flex items-center justify-between gap-3 text-sm">
          <span className="font-medium text-gray-700">
            {completedRequired} de {requiredLessons.length} aulas obrigatórias concluídas
          </span>
          <span className="text-gray-500">{progressPercent}%</span>
        </div>
        <Progress value={progressPercent} className="h-2" />
      </div>

      <div className="grid gap-5 xl:grid-cols-[minmax(0,1fr)_320px]">
        <main className="space-y-5">
          <section className="card p-5 sm:p-6">
            <div className="mb-5 flex flex-wrap items-start justify-between gap-4">
              <div>
                <p className="text-xs font-semibold uppercase tracking-wide text-brand-700">
                  {currentModule?.title ?? 'Treinamento'}
                </p>
                <h2 className="mt-2 text-xl font-semibold text-gray-900">
                  {currentLesson.title}
                </h2>
                <div className="mt-2 flex flex-wrap items-center gap-3 text-xs text-gray-500">
                  {currentLesson.duration_minutes !== null && (
                    <span className="flex items-center gap-1">
                      <Clock3 className="h-3.5 w-3.5" />
                      {currentLesson.duration_minutes} min
                    </span>
                  )}
                  <span>{lessonStatusLabel(currentLesson)}</span>
                </div>
              </div>

              {startMutation.isPending && (
                <span className="flex items-center gap-2 text-xs text-gray-500">
                  <Loader2 className="h-4 w-4 animate-spin" />
                  Registrando progresso
                </span>
              )}
            </div>

            <LessonContent lesson={currentLesson} />

            <div className="mt-6 flex flex-wrap items-center justify-between gap-3 border-t border-gray-100 pt-5">
              <button
                type="button"
                className="btn-secondary"
                onClick={() => setCurrentIndex((index) => Math.max(index - 1, 0))}
                disabled={
                  currentIndex === 0 ||
                  startMutation.isPending ||
                  completeMutation.isPending
                }
              >
                <ArrowLeft className="mr-2 h-4 w-4" />
                Anterior
              </button>

              {currentCompleted ? (
                currentIndex < lessons.length - 1 ? (
                  <button
                    type="button"
                    className="btn-primary"
                    onClick={() =>
                      setCurrentIndex((index) =>
                        Math.min(index + 1, lessons.length - 1),
                      )
                    }
                    disabled={startMutation.isPending}
                  >
                    Próxima aula
                    <ArrowRight className="ml-2 h-4 w-4" />
                  </button>
                ) : (
                  <span className="flex items-center gap-2 text-sm font-semibold text-green-700">
                    <CheckCircle2 className="h-5 w-5" />
                    Treinamento concluído
                  </span>
                )
              ) : (
                <button
                  type="button"
                  className="btn-primary"
                  onClick={() => completeMutation.mutate(currentLesson)}
                  disabled={
                    startMutation.isPending ||
                    completeMutation.isPending
                  }
                >
                  {completeMutation.isPending ? (
                    <>
                      <Loader2 className="mr-2 h-4 w-4 animate-spin" />
                      Salvando...
                    </>
                  ) : (
                    <>
                      <CheckCircle2 className="mr-2 h-4 w-4" />
                      Concluir e avançar
                    </>
                  )}
                </button>
              )}
            </div>
          </section>

          {!!assets.length && (
            <section className="card p-5">
              <h2 className="font-semibold text-gray-900">Materiais de apoio</h2>
              <p className="mt-1 text-sm text-gray-500">
                Abra ou baixe os arquivos complementares deste treinamento.
              </p>

              <div className="mt-4 grid gap-2 sm:grid-cols-2">
                {assets.map((asset) => {
                  const opening = openingAssetId === asset.id
                  const previewable = canPreviewAssetInBrowser(asset)

                  return (
                    <button
                      key={asset.id}
                      type="button"
                      className="flex items-center justify-between gap-3 rounded-lg border border-gray-200 px-3 py-3 text-left transition hover:border-brand-200 hover:bg-brand-50"
                      onClick={() => handleOpenAsset(asset)}
                      disabled={opening}
                    >
                      <span className="flex min-w-0 items-center gap-3">
                        <FileText className="h-4 w-4 shrink-0 text-gray-500" />
                        <span className="min-w-0">
                          <span className="block truncate text-sm font-medium text-gray-800">
                            {asset.display_name}
                          </span>
                          <span className="block text-xs text-gray-500">
                            {previewable ? 'Abrir material' : 'Baixar material'}
                          </span>
                        </span>
                      </span>

                      {opening ? (
                        <RefreshCw className="h-4 w-4 shrink-0 animate-spin text-brand-700" />
                      ) : previewable ? (
                        <ExternalLink className="h-4 w-4 shrink-0 text-gray-400" />
                      ) : (
                        <Download className="h-4 w-4 shrink-0 text-gray-400" />
                      )}
                    </button>
                  )
                })}
              </div>
            </section>
          )}
        </main>

        <aside className="card h-fit p-4 xl:sticky xl:top-4">
          <h2 className="text-sm font-semibold text-gray-900">
            Conteúdo do treinamento
          </h2>
          <p className="mt-1 text-xs text-gray-500">
            Selecione uma aula para revisar ou continuar.
          </p>

          <div className="mt-4 space-y-4">
            {visibleModules.map((module) => (
              <section key={module.id}>
                <div className="mb-2">
                  <p className="text-xs font-semibold uppercase tracking-wide text-gray-500">
                    Módulo {module.sequence_no}
                  </p>
                  <p className="mt-1 text-sm font-semibold text-gray-900">
                    {module.title}
                  </p>
                </div>

                <div className="space-y-2">
                  {module.lessons.map((lesson) => {
                    const index = lessons.findIndex(
                      (candidate) => candidate.id === lesson.id,
                    )
                    const active = index === currentIndex
                    const completed = lesson.progress?.status === 'completed'
                    const inProgress = lesson.progress?.status === 'in_progress'

                    return (
                      <button
                        key={lesson.id}
                        type="button"
                        className={`flex w-full items-start gap-2 rounded-lg border p-3 text-left transition ${
                          active
                            ? 'border-brand-300 bg-brand-50'
                            : 'border-gray-200 bg-white hover:border-brand-200'
                        }`}
                        onClick={() => setCurrentIndex(index)}
                        disabled={completeMutation.isPending}
                      >
                        {completed ? (
                          <CheckCircle2 className="mt-0.5 h-4 w-4 shrink-0 text-green-600" />
                        ) : inProgress ? (
                          <BookOpen className="mt-0.5 h-4 w-4 shrink-0 text-brand-700" />
                        ) : (
                          <Circle className="mt-0.5 h-4 w-4 shrink-0 text-gray-400" />
                        )}

                        <span className="min-w-0">
                          <span className="block text-sm font-medium text-gray-800">
                            {lesson.title}
                          </span>
                          <span className="mt-1 block text-xs text-gray-500">
                            {lessonStatusLabel(lesson)}
                            {lesson.duration_minutes !== null
                              ? ` • ${lesson.duration_minutes} min`
                              : ''}
                          </span>
                        </span>
                      </button>
                    )
                  })}
                </div>
              </section>
            ))}
          </div>
        </aside>
      </div>
    </div>
  )
}
