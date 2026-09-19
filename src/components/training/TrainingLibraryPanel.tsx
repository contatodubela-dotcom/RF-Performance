import { useState } from 'react'
import {
  BookOpen,
  ExternalLink,
  FileText,
  RefreshCw,
  Star,
} from 'lucide-react'
import { toast } from 'sonner'
import EmptyState from '@/components/shared/EmptyState'
import LoadingSpinner from '@/components/shared/LoadingSpinner'
import { createTrainingAssetSignedUrl } from '@/services/trainingLibraryService'
import type {
  TrainingLibraryAsset,
  TrainingLibraryCategory,
  TrainingLibraryItemWithAssets,
} from '@/types/trainingLibrary'

const CATEGORY_LABELS: Record<TrainingLibraryCategory, string> = {
  commercial_training: 'Formação comercial',
  sales_method: 'Método de vendas',
  leadership: 'Liderança',
  platform_guide: 'Guia da plataforma',
  other: 'Outros',
}

const ASSET_TYPE_LABELS: Record<TrainingLibraryAsset['asset_type'], string> = {
  primary: 'Material principal',
  slides: 'Apresentação',
  workbook: 'Apostila',
  attachment: 'Anexo',
  cover: 'Capa',
}

export default function TrainingLibraryPanel({
  rows,
  isLoading,
  isFetching,
  error,
  onRetry,
}: {
  rows: TrainingLibraryItemWithAssets[]
  isLoading: boolean
  isFetching: boolean
  error: unknown
  onRetry: () => void
}) {
  const [openingAssetId, setOpeningAssetId] = useState<string | null>(null)

  async function handleOpenAsset(asset: TrainingLibraryAsset) {
    setOpeningAssetId(asset.id)

    try {
      const signedUrl = await createTrainingAssetSignedUrl(asset)

      window.open(
        signedUrl,
        '_blank',
        'noopener,noreferrer',
      )
    } catch (openError) {
      const message =
        openError instanceof Error
          ? openError.message
          : 'Não foi possível abrir o material.'

      toast.error(message)
    } finally {
      setOpeningAssetId(null)
    }
  }

  if (isLoading) {
    return (
      <div className="card flex min-h-[180px] items-center justify-center">
        <LoadingSpinner message="Carregando biblioteca de treinamentos..." />
      </div>
    )
  }

  if (error) {
    const message =
      error instanceof Error
        ? error.message
        : 'Não foi possível carregar a biblioteca de treinamentos.'

    return (
      <div className="card">
        <EmptyState
          icon={BookOpen}
          title="Falha ao carregar biblioteca"
          description={message}
          action={(
            <button
              type="button"
              className="btn-secondary"
              onClick={onRetry}
              disabled={isFetching}
            >
              <RefreshCw
                className={`mr-2 h-4 w-4 ${
                  isFetching ? 'animate-spin' : ''
                }`}
              />
              Tentar novamente
            </button>
          )}
        />
      </div>
    )
  }

  if (!rows.length) {
    return (
      <div className="card">
        <EmptyState
          icon={BookOpen}
          title="Nenhum material disponível"
          description="Os treinamentos publicados para o seu perfil aparecerão aqui."
        />
      </div>
    )
  }

  return (
    <div className="grid gap-4 lg:grid-cols-2">
      {rows.map((training) => {
        const availableAssets = training.assets.filter(
          (asset) => asset.asset_type !== 'cover',
        )

        return (
          <article
            key={training.id}
            className="card p-5"
          >
            <div className="flex items-start justify-between gap-4">
              <div className="min-w-0">
                <div className="flex flex-wrap items-center gap-2">
                  <span className="text-xs font-semibold uppercase tracking-wide text-brand-700">
                    {CATEGORY_LABELS[training.category]}
                  </span>

                  {training.is_featured && (
                    <span className="badge bg-amber-100 text-amber-800">
                      <Star className="mr-1 h-3 w-3" />
                      Destaque
                    </span>
                  )}

                  {training.status === 'draft' && (
                    <span className="badge bg-gray-100 text-gray-700">
                      Rascunho
                    </span>
                  )}
                </div>

                <h3 className="mt-2 font-semibold text-gray-900">
                  {training.title}
                </h3>

                {training.description && (
                  <p className="mt-2 text-sm leading-5 text-gray-600">
                    {training.description}
                  </p>
                )}
              </div>

              <div className="flex h-10 w-10 shrink-0 items-center justify-center rounded-lg bg-brand-100 text-brand-700">
                <BookOpen className="h-5 w-5" />
              </div>
            </div>

            <div className="mt-5 border-t border-gray-100 pt-4">
              {availableAssets.length ? (
                <div className="space-y-2">
                  {availableAssets.map((asset) => {
                    const isOpening = openingAssetId === asset.id

                    return (
                      <button
                        key={asset.id}
                        type="button"
                        className="flex w-full items-center justify-between gap-3 rounded-lg border border-gray-200 px-3 py-2.5 text-left transition hover:border-brand-200 hover:bg-brand-50"
                        onClick={() => handleOpenAsset(asset)}
                        disabled={isOpening}
                      >
                        <span className="flex min-w-0 items-center gap-3">
                          <FileText className="h-4 w-4 shrink-0 text-gray-500" />

                          <span className="min-w-0">
                            <span className="block truncate text-sm font-medium text-gray-800">
                              {asset.display_name}
                            </span>

                            <span className="block text-xs text-gray-500">
                              {ASSET_TYPE_LABELS[asset.asset_type]}
                            </span>
                          </span>
                        </span>

                        {isOpening ? (
                          <RefreshCw className="h-4 w-4 shrink-0 animate-spin text-brand-700" />
                        ) : (
                          <ExternalLink className="h-4 w-4 shrink-0 text-gray-400" />
                        )}
                      </button>
                    )
                  })}
                </div>
              ) : (
                <p className="text-sm text-gray-500">
                  Material ainda não disponível para consulta.
                </p>
              )}
            </div>
          </article>
        )
      })}
    </div>
  )
}