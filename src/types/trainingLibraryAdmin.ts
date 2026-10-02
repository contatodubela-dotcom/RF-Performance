import type {
  TrainingLibraryAsset,
  TrainingLibraryAssetType,
  TrainingLibraryAudienceRole,
  TrainingLibraryCategory,
  TrainingLibraryItem,
  TrainingLibraryItemStatus,
  TrainingLibraryLesson,
  TrainingLibraryLessonType,
  TrainingLibraryModule,
} from '@/types/trainingLibrary'

export interface TrainingLibraryAdminState {
  items: TrainingLibraryItem[]
  assets: TrainingLibraryAsset[]
  modules: TrainingLibraryModule[]
  lessons: TrainingLibraryLesson[]
}

export interface CreateTrainingLibraryItemInput {
  organizationId: string
  title: string
  description: string
  category: TrainingLibraryCategory
  audienceRoles: TrainingLibraryAudienceRole[]
  isFeatured: boolean
}

export interface UpdateTrainingLibraryItemInput {
  organizationId: string
  trainingId: string
  title: string
  description: string
  category: TrainingLibraryCategory
  audienceRoles: TrainingLibraryAudienceRole[]
  isFeatured: boolean
  status: TrainingLibraryItemStatus
}

export interface CreateTrainingLibraryItemResponse {
  training_id: string
  sequence_no: number
  status: TrainingLibraryItemStatus
}

export interface DuplicateTrainingLibraryItemResponse {
  source_training_id: string
  training_id: string
  modules_copied: number
  lessons_copied: number
  assets_copied: boolean
}

export interface ArchiveTrainingLibraryItemResponse {
  training_id: string
  archived: boolean
  modules_archived: number
  lessons_archived: number
  assets_archived: number
}

export interface UpsertTrainingLibraryModuleInput {
  organizationId: string
  trainingId: string
  moduleId?: string
  title: string
  description: string
  status: TrainingLibraryItemStatus
}

export interface UpsertTrainingLibraryLessonInput {
  organizationId: string
  trainingId: string
  moduleId: string
  lessonId?: string
  title: string
  description: string
  lessonType: TrainingLibraryLessonType
  durationMinutes: number | null
  isRequired: boolean
  status: TrainingLibraryItemStatus
  learningObjective: string
  summary: string
  keyPoints: string[]
}

export interface UploadTrainingLibraryAssetInput {
  organizationId: string
  trainingId: string
  file: File
  displayName: string
  assetType: TrainingLibraryAssetType
  isDownloadable: boolean
}
