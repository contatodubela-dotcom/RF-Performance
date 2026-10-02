import { supabase } from '@/lib/supabase'
import type {
  ArchiveTrainingLibraryItemResponse,
  CreateTrainingLibraryItemInput,
  CreateTrainingLibraryItemResponse,
  DuplicateTrainingLibraryItemResponse,
  TrainingLibraryAdminState,
  UpdateTrainingLibraryItemInput,
  UploadTrainingLibraryAssetInput,
  UpsertTrainingLibraryLessonInput,
  UpsertTrainingLibraryModuleInput,
} from '@/types/trainingLibraryAdmin'
import type { TrainingLibraryAsset } from '@/types/trainingLibrary'

function requireData<T>(data: unknown, operation: string): T {
  if (data === null || data === undefined) {
    throw new Error(`A operação ${operation} retornou uma resposta vazia.`)
  }

  return data as T
}

function safeFileName(name: string) {
  const normalized = name
    .normalize('NFD')
    .replace(/[\u0300-\u036f]/g, '')
    .replace(/[^a-zA-Z0-9._-]+/g, '_')
    .replace(/^_+|_+$/g, '')

  return normalized || 'material'
}

export async function getTrainingLibraryAdminState(
  organizationId: string,
): Promise<TrainingLibraryAdminState> {
  const { data, error } = await supabase.rpc(
    'get_training_library_admin_state',
    {
      p_organization_id: organizationId,
    },
  )

  if (error) throw error

  return requireData<TrainingLibraryAdminState>(
    data,
    'get_training_library_admin_state',
  )
}

export async function createTrainingLibraryItem({
  organizationId,
  title,
  description,
  category,
  audienceRoles,
  isFeatured,
}: CreateTrainingLibraryItemInput): Promise<CreateTrainingLibraryItemResponse> {
  const { data, error } = await supabase.rpc(
    'create_training_library_admin',
    {
      p_organization_id: organizationId,
      p_title: title,
      p_description: description,
      p_category: category,
      p_audience_roles: audienceRoles,
      p_is_featured: isFeatured,
    },
  )

  if (error) throw error

  return requireData<CreateTrainingLibraryItemResponse>(
    data,
    'create_training_library_admin',
  )
}

export async function updateTrainingLibraryItem({
  organizationId,
  trainingId,
  title,
  description,
  category,
  audienceRoles,
  isFeatured,
  status,
}: UpdateTrainingLibraryItemInput): Promise<void> {
  const { error } = await supabase.rpc(
    'update_training_library_admin',
    {
      p_organization_id: organizationId,
      p_training_id: trainingId,
      p_title: title,
      p_description: description,
      p_category: category,
      p_audience_roles: audienceRoles,
      p_is_featured: isFeatured,
      p_status: status,
    },
  )

  if (error) throw error
}

export async function duplicateTrainingLibraryItem(
  organizationId: string,
  trainingId: string,
): Promise<DuplicateTrainingLibraryItemResponse> {
  const { data, error } = await supabase.rpc(
    'duplicate_training_library_admin',
    {
      p_organization_id: organizationId,
      p_training_id: trainingId,
    },
  )

  if (error) throw error

  return requireData<DuplicateTrainingLibraryItemResponse>(
    data,
    'duplicate_training_library_admin',
  )
}

export async function archiveTrainingLibraryItem(
  organizationId: string,
  trainingId: string,
): Promise<ArchiveTrainingLibraryItemResponse> {
  const { data, error } = await supabase.rpc(
    'archive_training_library_admin',
    {
      p_organization_id: organizationId,
      p_training_id: trainingId,
    },
  )

  if (error) throw error

  return requireData<ArchiveTrainingLibraryItemResponse>(
    data,
    'archive_training_library_admin',
  )
}

export async function upsertTrainingLibraryModule({
  organizationId,
  trainingId,
  moduleId,
  title,
  description,
  status,
}: UpsertTrainingLibraryModuleInput): Promise<void> {
  const { error } = await supabase.rpc(
    'upsert_training_library_module_admin',
    {
      p_organization_id: organizationId,
      p_training_id: trainingId,
      p_module_id: moduleId ?? null,
      p_title: title,
      p_description: description,
      p_status: status,
    },
  )

  if (error) throw error
}

export async function upsertTrainingLibraryLesson({
  organizationId,
  trainingId,
  moduleId,
  lessonId,
  title,
  description,
  lessonType,
  durationMinutes,
  isRequired,
  status,
  learningObjective,
  summary,
  keyPoints,
}: UpsertTrainingLibraryLessonInput): Promise<void> {
  const { error } = await supabase.rpc(
    'upsert_training_library_lesson_admin',
    {
      p_organization_id: organizationId,
      p_training_id: trainingId,
      p_module_id: moduleId,
      p_lesson_id: lessonId ?? null,
      p_title: title,
      p_description: description,
      p_lesson_type: lessonType,
      p_duration_minutes: durationMinutes,
      p_is_required: isRequired,
      p_status: status,
      p_learning_objective: learningObjective,
      p_summary: summary,
      p_key_points: keyPoints,
    },
  )

  if (error) throw error
}

export async function uploadTrainingLibraryAsset({
  organizationId,
  trainingId,
  file,
  displayName,
  assetType,
  isDownloadable,
}: UploadTrainingLibraryAssetInput): Promise<void> {
  const uniquePrefix = crypto.randomUUID()
  const storagePath =
    `${organizationId}/${trainingId}/${uniquePrefix}_${safeFileName(file.name)}`

  const { error: uploadError } = await supabase.storage
    .from('training-materials')
    .upload(storagePath, file, {
      cacheControl: '3600',
      upsert: false,
      contentType: file.type || 'application/octet-stream',
    })

  if (uploadError) throw uploadError

  const { error: registerError } = await supabase.rpc(
    'register_training_library_asset_admin',
    {
      p_organization_id: organizationId,
      p_training_id: trainingId,
      p_asset_type: assetType,
      p_display_name: displayName,
      p_storage_path: storagePath,
      p_mime_type: file.type || 'application/octet-stream',
      p_file_size_bytes: file.size,
      p_is_downloadable: isDownloadable,
    },
  )

  if (!registerError) return

  await supabase.storage
    .from('training-materials')
    .remove([storagePath])

  throw registerError
}

export async function archiveTrainingLibraryAsset(
  organizationId: string,
  asset: TrainingLibraryAsset,
): Promise<void> {
  const { error } = await supabase.rpc(
    'archive_training_library_asset_admin',
    {
      p_organization_id: organizationId,
      p_asset_id: asset.id,
    },
  )

  if (error) throw error
}
