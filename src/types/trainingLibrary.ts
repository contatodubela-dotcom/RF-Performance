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
