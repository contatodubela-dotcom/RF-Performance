import { supabase } from '@/lib/supabase'
import type {
  TrainingLibraryAsset,
  TrainingLibraryItem,
  TrainingLibraryItemWithAssets,
  TrainingLibraryLearningExperience,
  TrainingLibraryLesson,
  TrainingLibraryLessonProgress,
  TrainingLibraryLessonProgressStatus,
  TrainingLibraryModule,
} from '@/types/trainingLibrary'

const TRAINING_SIGNED_URL_TTL_SECONDS = 10 * 60

export async function getTrainingLibrary(
  organizationId: string,
): Promise<TrainingLibraryItemWithAssets[]> {
  const { data: itemsData, error: itemsError } = await supabase
    .from('training_library_items')
    .select('*')
    .eq('organization_id', organizationId)
    .neq('status', 'archived')
    .order('sequence_no')

  if (itemsError) throw itemsError

  const items = (itemsData ?? []) as TrainingLibraryItem[]

  if (!items.length) {
    return []
  }

  const { data: assetsData, error: assetsError } = await supabase
    .from('training_library_assets')
    .select('*')
    .eq('organization_id', organizationId)
    .neq('status', 'archived')
    .order('sequence_no')

  if (assetsError) throw assetsError

  const assets = (assetsData ?? []) as TrainingLibraryAsset[]

  return items.map((item) => ({
    ...item,
    assets: assets.filter((asset) => asset.training_id === item.id),
  }))
}

export async function createTrainingAssetSignedUrl(
  asset: TrainingLibraryAsset,
): Promise<string> {
  const { data, error } = await supabase.storage
    .from(asset.storage_bucket)
    .createSignedUrl(asset.storage_path, TRAINING_SIGNED_URL_TTL_SECONDS)

  if (error) throw error

  if (!data?.signedUrl) {
    throw new Error('Não foi possível gerar o acesso ao material.')
  }

  return data.signedUrl
}

export async function getTrainingLearningExperience(
  organizationId: string,
  trainingId: string,
): Promise<TrainingLibraryLearningExperience> {
  const {
    data: { user },
    error: userError,
  } = await supabase.auth.getUser()

  if (userError) throw userError

  if (!user) {
    throw new Error('Sessão autenticada necessária para acessar o treinamento.')
  }

  const userId = user.id
  const { data: trainingData, error: trainingError } = await supabase
    .from('training_library_items')
    .select('*')
    .eq('organization_id', organizationId)
    .eq('id', trainingId)
    .neq('status', 'archived')
    .single()

  if (trainingError) throw trainingError

  const training = trainingData as TrainingLibraryItem

  const [assetsResult, modulesResult, lessonsResult, progressResult] =
    await Promise.all([
      supabase
        .from('training_library_assets')
        .select('*')
        .eq('organization_id', organizationId)
        .eq('training_id', trainingId)
        .neq('status', 'archived')
        .order('sequence_no'),
      supabase
        .from('training_library_modules')
        .select('*')
        .eq('organization_id', organizationId)
        .eq('training_id', trainingId)
        .neq('status', 'archived')
        .order('sequence_no'),
      supabase
        .from('training_library_lessons')
        .select('*')
        .eq('organization_id', organizationId)
        .eq('training_id', trainingId)
        .neq('status', 'archived')
        .order('sequence_no'),
      supabase
        .from('training_library_lesson_progress')
        .select('*')
        .eq('organization_id', organizationId)
        .eq('training_id', trainingId)
        .eq('user_id', userId),
    ])

  if (assetsResult.error) throw assetsResult.error
  if (modulesResult.error) throw modulesResult.error
  if (lessonsResult.error) throw lessonsResult.error
  if (progressResult.error) throw progressResult.error

  const assets = (assetsResult.data ?? []) as TrainingLibraryAsset[]
  const modules = (modulesResult.data ?? []) as TrainingLibraryModule[]
  const lessons = (lessonsResult.data ?? []) as TrainingLibraryLesson[]
  const progress = (progressResult.data ?? []) as TrainingLibraryLessonProgress[]

  const progressByLessonId = new Map(
    progress.map((item) => [item.lesson_id, item]),
  )

  return {
    training: {
      ...training,
      assets,
    },
    modules: modules.map((module) => ({
      ...module,
      lessons: lessons
        .filter((lesson) => lesson.module_id === module.id)
        .sort((a, b) => a.sequence_no - b.sequence_no)
        .map((lesson) => ({
          ...lesson,
          progress: progressByLessonId.get(lesson.id) ?? null,
        })),
    })),
  }
}

interface SaveTrainingLessonProgressInput {
  organizationId: string
  trainingId: string
  lessonId: string
  status: Exclude<TrainingLibraryLessonProgressStatus, 'not_started'>
}

export async function saveTrainingLessonProgress({
  organizationId,
  trainingId,
  lessonId,
  status,
}: SaveTrainingLessonProgressInput): Promise<TrainingLibraryLessonProgress> {
  const {
    data: { user },
    error: userError,
  } = await supabase.auth.getUser()

  if (userError) throw userError

  if (!user) {
    throw new Error('Sessão autenticada necessária para registrar o progresso.')
  }

  const userId = user.id
  const now = new Date().toISOString()

  const { data: currentData, error: currentError } = await supabase
    .from('training_library_lesson_progress')
    .select('*')
    .eq('organization_id', organizationId)
    .eq('training_id', trainingId)
    .eq('lesson_id', lessonId)
    .eq('user_id', userId)
    .maybeSingle()

  if (currentError) throw currentError

  const current = currentData as TrainingLibraryLessonProgress | null

  if (current?.status === 'completed' && status === 'in_progress') {
    return current
  }

  const completed = status === 'completed'
  const payload = {
    organization_id: organizationId,
    training_id: trainingId,
    lesson_id: lessonId,
    user_id: userId,
    status,
    progress_percent: completed ? 100 : Math.max(current?.progress_percent ?? 0, 1),
    started_at: current?.started_at ?? now,
    last_activity_at: now,
    completed_at: completed ? current?.completed_at ?? now : null,
    metadata: current?.metadata ?? {},
  }

  const { data, error } = await supabase
    .from('training_library_lesson_progress')
    .upsert(payload, { onConflict: 'user_id,lesson_id' })
    .select('*')
    .single()

  if (error) throw error

  return data as TrainingLibraryLessonProgress
}
