import { supabase } from '@/lib/supabase'
import type {
  TrainingLibraryAsset,
  TrainingLibraryItem,
  TrainingLibraryItemWithAssets,
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