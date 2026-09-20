export type TrainingLibraryCategory =
  | 'commercial_training'
  | 'sales_method'
  | 'leadership'
  | 'platform_guide'
  | 'other'

export type TrainingLibraryAudienceRole =
  | 'director'
  | 'supervisor'
  | 'salesperson'

export type TrainingLibraryItemStatus =
  | 'draft'
  | 'published'
  | 'archived'

export type TrainingLibraryAssetType =
  | 'primary'
  | 'slides'
  | 'workbook'
  | 'attachment'
  | 'cover'

export type TrainingLibraryAssetStatus =
  | 'active'
  | 'archived'

export type TrainingLibraryLessonType =
  | 'video'
  | 'slides'
  | 'document'
  | 'text'
  | 'interactive'
  | 'other'

export type TrainingLibraryLessonProgressStatus =
  | 'not_started'
  | 'in_progress'
  | 'completed'

export interface TrainingLibraryItem {
  id: string
  organization_id: string
  sequence_no: number
  title: string
  description: string
  category: TrainingLibraryCategory
  audience_roles: TrainingLibraryAudienceRole[]
  status: TrainingLibraryItemStatus
  is_featured: boolean
  created_at: string
  created_by: string | null
  updated_at: string
  updated_by: string | null
  archived_at: string | null
  metadata: Record<string, unknown>
}

export interface TrainingLibraryAsset {
  id: string
  organization_id: string
  training_id: string
  sequence_no: number
  asset_type: TrainingLibraryAssetType
  display_name: string
  storage_bucket: 'training-materials'
  storage_path: string
  mime_type: string
  file_size_bytes: number | null
  status: TrainingLibraryAssetStatus
  is_downloadable: boolean
  created_at: string
  created_by: string | null
  updated_at: string
  updated_by: string | null
  archived_at: string | null
  metadata: Record<string, unknown>
}

export interface TrainingLibraryItemWithAssets extends TrainingLibraryItem {
  assets: TrainingLibraryAsset[]
}

export interface TrainingLibraryModule {
  id: string
  organization_id: string
  training_id: string
  sequence_no: number
  title: string
  description: string
  status: TrainingLibraryItemStatus
  created_at: string
  created_by: string | null
  updated_at: string
  updated_by: string | null
  archived_at: string | null
  metadata: Record<string, unknown>
}

export interface TrainingLibraryLesson {
  id: string
  organization_id: string
  training_id: string
  module_id: string
  sequence_no: number
  title: string
  description: string
  lesson_type: TrainingLibraryLessonType
  duration_minutes: number | null
  is_required: boolean
  status: TrainingLibraryItemStatus
  created_at: string
  created_by: string | null
  updated_at: string
  updated_by: string | null
  archived_at: string | null
  metadata: Record<string, unknown>
}

export interface TrainingLibraryLessonProgress {
  id: string
  organization_id: string
  training_id: string
  lesson_id: string
  user_id: string
  status: TrainingLibraryLessonProgressStatus
  progress_percent: number
  started_at: string | null
  last_activity_at: string
  completed_at: string | null
  created_at: string
  created_by: string | null
  updated_at: string
  updated_by: string | null
  metadata: Record<string, unknown>
}

export interface TrainingLibraryLessonWithProgress extends TrainingLibraryLesson {
  progress: TrainingLibraryLessonProgress | null
}

export interface TrainingLibraryModuleWithLessons extends TrainingLibraryModule {
  lessons: TrainingLibraryLessonWithProgress[]
}

export interface TrainingLibraryLearningExperience {
  training: TrainingLibraryItemWithAssets
  modules: TrainingLibraryModuleWithLessons[]
}
