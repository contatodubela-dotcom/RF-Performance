import { useEffect, useMemo, useState } from 'react'
import { useMutation, useQuery } from '@tanstack/react-query'
import {
  Archive,
  BookOpen,
  Copy,
  Download,
  ExternalLink,
  FilePlus2,
  FileText,
  FolderPlus,
  Pencil,
  Plus,
  RefreshCw,
  Star,
  Trash2,
} from 'lucide-react'
import { toast } from 'sonner'
import ConfirmDialog from '@/components/shared/ConfirmDialog'
import EmptyState from '@/components/shared/EmptyState'
import LoadingSpinner from '@/components/shared/LoadingSpinner'
import PageHeader from '@/components/shared/PageHeader'
import {
  Dialog,
  DialogContent,
  DialogHeader,
  DialogTitle,
} from '@/components/ui/dialog'
import { useAuth } from '@/contexts/AuthContext'
import {
  canPreviewTrainingAssetInBrowser,
  openTrainingAsset,
} from '@/services/trainingLibraryService'
import {
  archiveTrainingLibraryAsset,
  archiveTrainingLibraryItem,
  archiveTrainingLibraryLesson,
  archiveTrainingLibraryModule,
  createTrainingLibraryItem,
  duplicateTrainingLibraryItem,
  getTrainingLibraryAdminState,
  updateTrainingLibraryItem,
  uploadTrainingLibraryAsset,
  upsertTrainingLibraryLesson,
  upsertTrainingLibraryModule,
} from '@/services/trainingLibraryAdminService'
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

const CATEGORY_LABELS: Record<TrainingLibraryCategory, string> = {
  commercial_training: 'Formação comercial',
  sales_method: 'Método de vendas',
  leadership: 'Liderança',
  platform_guide: 'Guia da plataforma',
  other: 'Outros',
}

const ROLE_LABELS: Record<TrainingLibraryAudienceRole, string> = {
  director: 'Diretor',
  supervisor: 'Supervisor',
  salesperson: 'Vendedor',
}

const ASSET_LABELS: Record<TrainingLibraryAssetType, string> = {
  primary: 'Material principal',
  slides: 'Apresentação',
  workbook: 'Apostila',
  attachment: 'Anexo',
  cover: 'Capa',
}

const LESSON_LABELS: Record<TrainingLibraryLessonType, string> = {
  video: 'Vídeo',
  slides: 'Slides',
  document: 'Documento',
  text: 'Texto',
  interactive: 'Interativa',
  other: 'Outro',
}

function errorMessage(error: unknown) {
  return error instanceof Error
    ? error.message
    : 'Não foi possível concluir a operação.'
}

function metadataString(metadata: Record<string, unknown>, key: string) {
  const value = metadata[key]
  return typeof value === 'string' ? value : ''
}

function metadataStringArray(
  metadata: Record<string, unknown>,
  key: string,
): string[] {
  const value = metadata[key]
  return Array.isArray(value)
    ? value.filter((item): item is string => typeof item === 'string')
    : []
}

function TrainingForm({
  initial,
  organizationId,
  onSaved,
  onClose,
}: {
  initial: TrainingLibraryItem | null
  organizationId: string
  onSaved: () => Promise<void>
  onClose: () => void
}) {
  const [title, setTitle] = useState(initial?.title ?? '')
  const [description, setDescription] = useState(initial?.description ?? '')
  const [category, setCategory] = useState<TrainingLibraryCategory>(
    initial?.category ?? 'commercial_training',
  )
  const [audienceRoles, setAudienceRoles] =
    useState<TrainingLibraryAudienceRole[]>(
      initial?.audience_roles ?? ['director', 'supervisor', 'salesperson'],
    )
  const [isFeatured, setIsFeatured] = useState(initial?.is_featured ?? false)
  const [status, setStatus] = useState<TrainingLibraryItemStatus>(
    initial?.status ?? 'draft',
  )

  const mutation = useMutation({
    mutationFn: async () => {
      if (!title.trim()) {
        throw new Error('Informe o título do treinamento.')
      }

      if (!audienceRoles.length) {
        throw new Error('Selecione ao menos um perfil de público.')
      }

      if (initial) {
        await updateTrainingLibraryItem({
          organizationId,
          trainingId: initial.id,
          title,
          description,
          category,
          audienceRoles,
          isFeatured,
          status,
        })
        return
      }

      await createTrainingLibraryItem({
        organizationId,
        title,
        description,
        category,
        audienceRoles,
        isFeatured,
      })
    },
    onSuccess: async () => {
      toast.success(
        initial
          ? 'Treinamento atualizado.'
          : 'Treinamento criado como rascunho.',
      )
      await onSaved()
      onClose()
    },
    onError: (error) => toast.error(errorMessage(error)),
  })

  function toggleRole(role: TrainingLibraryAudienceRole) {
    setAudienceRoles((current) =>
      current.includes(role)
        ? current.filter((item) => item !== role)
        : [...current, role],
    )
  }

  return (
    <div className="space-y-4">
      <div>
        <label className="form-label">Título</label>
        <input
          className="form-input"
          value={title}
          onChange={(event) => setTitle(event.target.value)}
          placeholder="Ex.: Etapas da Venda — Consórcio Volkswagen"
        />
      </div>

      <div>
        <label className="form-label">Descrição</label>
        <textarea
          className="form-input min-h-24"
          value={description}
          onChange={(event) => setDescription(event.target.value)}
          placeholder="Explique o objetivo e o conteúdo do treinamento."
        />
      </div>

      <div className="grid gap-3 md:grid-cols-2">
        <div>
          <label className="form-label">Categoria</label>
          <select
            className="form-input"
            value={category}
            onChange={(event) =>
              setCategory(event.target.value as TrainingLibraryCategory)
            }
          >
            {Object.entries(CATEGORY_LABELS).map(([value, label]) => (
              <option key={value} value={value}>
                {label}
              </option>
            ))}
          </select>
        </div>

        {initial && (
          <div>
            <label className="form-label">Status</label>
            <select
              className="form-input"
              value={status}
              onChange={(event) =>
                setStatus(event.target.value as TrainingLibraryItemStatus)
              }
            >
              <option value="draft">Rascunho</option>
              <option value="published">Publicado</option>
            </select>
          </div>
        )}
      </div>

      <div>
        <label className="form-label">Público</label>
        <div className="mt-2 flex flex-wrap gap-3">
          {(Object.keys(ROLE_LABELS) as TrainingLibraryAudienceRole[]).map(
            (role) => (
              <label
                key={role}
                className="flex items-center gap-2 rounded-lg border border-gray-200 px-3 py-2 text-sm"
              >
                <input
                  type="checkbox"
                  checked={audienceRoles.includes(role)}
                  onChange={() => toggleRole(role)}
                />
                {ROLE_LABELS[role]}
              </label>
            ),
          )}
        </div>
      </div>

      <label className="flex items-center gap-2 text-sm text-gray-700">
        <input
          type="checkbox"
          checked={isFeatured}
          onChange={(event) => setIsFeatured(event.target.checked)}
        />
        Destacar este treinamento na biblioteca
      </label>

      <div className="flex justify-end gap-2">
        <button type="button" className="btn-secondary" onClick={onClose}>
          Cancelar
        </button>
        <button
          type="button"
          className="btn-primary"
          onClick={() => mutation.mutate()}
          disabled={mutation.isPending}
        >
          {mutation.isPending ? 'Salvando...' : 'Salvar'}
        </button>
      </div>
    </div>
  )
}

function ModuleForm({
  organizationId,
  trainingId,
  initial,
  onSaved,
  onClose,
}: {
  organizationId: string
  trainingId: string
  initial: TrainingLibraryModule | null
  onSaved: () => Promise<void>
  onClose: () => void
}) {
  const [title, setTitle] = useState(initial?.title ?? '')
  const [description, setDescription] = useState(initial?.description ?? '')
  const [status, setStatus] = useState<TrainingLibraryItemStatus>(
    initial?.status ?? 'draft',
  )

  const mutation = useMutation({
    mutationFn: () =>
      upsertTrainingLibraryModule({
        organizationId,
        trainingId,
        moduleId: initial?.id,
        title,
        description,
        status,
      }),
    onSuccess: async () => {
      toast.success(initial ? 'Módulo atualizado.' : 'Módulo criado.')
      await onSaved()
      onClose()
    },
    onError: (error) => toast.error(errorMessage(error)),
  })

  return (
    <div className="space-y-4">
      <div>
        <label className="form-label">Título do módulo</label>
        <input
          className="form-input"
          value={title}
          onChange={(event) => setTitle(event.target.value)}
        />
      </div>

      <div>
        <label className="form-label">Descrição</label>
        <textarea
          className="form-input min-h-20"
          value={description}
          onChange={(event) => setDescription(event.target.value)}
        />
      </div>

      <div>
        <label className="form-label">Status</label>
        <select
          className="form-input"
          value={status}
          onChange={(event) =>
            setStatus(event.target.value as TrainingLibraryItemStatus)
          }
        >
          <option value="draft">Rascunho</option>
          <option value="published">Publicado</option>
        </select>
      </div>

      <div className="flex justify-end gap-2">
        <button type="button" className="btn-secondary" onClick={onClose}>
          Cancelar
        </button>
        <button
          type="button"
          className="btn-primary"
          onClick={() => mutation.mutate()}
          disabled={mutation.isPending}
        >
          {mutation.isPending ? 'Salvando...' : 'Salvar módulo'}
        </button>
      </div>
    </div>
  )
}

function LessonForm({
  organizationId,
  trainingId,
  moduleId,
  initial,
  onSaved,
  onClose,
}: {
  organizationId: string
  trainingId: string
  moduleId: string
  initial: TrainingLibraryLesson | null
  onSaved: () => Promise<void>
  onClose: () => void
}) {
  const [title, setTitle] = useState(initial?.title ?? '')
  const [description, setDescription] = useState(initial?.description ?? '')
  const [lessonType, setLessonType] = useState<TrainingLibraryLessonType>(
    initial?.lesson_type ?? 'text',
  )
  const [duration, setDuration] = useState(
    initial?.duration_minutes?.toString() ?? '',
  )
  const [isRequired, setIsRequired] = useState(initial?.is_required ?? true)
  const [status, setStatus] = useState<TrainingLibraryItemStatus>(
    initial?.status ?? 'draft',
  )
  const [learningObjective, setLearningObjective] = useState(
    initial ? metadataString(initial.metadata, 'learning_objective') : '',
  )
  const [summary, setSummary] = useState(
    initial ? metadataString(initial.metadata, 'summary') : '',
  )
  const [keyPoints, setKeyPoints] = useState(
    initial
      ? metadataStringArray(initial.metadata, 'key_points').join('\n')
      : '',
  )

  const mutation = useMutation({
    mutationFn: () =>
      upsertTrainingLibraryLesson({
        organizationId,
        trainingId,
        moduleId,
        lessonId: initial?.id,
        title,
        description,
        lessonType,
        durationMinutes: duration ? Number(duration) : null,
        isRequired,
        status,
        learningObjective,
        summary,
        keyPoints: keyPoints
          .split('\n')
          .map((item) => item.trim())
          .filter(Boolean),
      }),
    onSuccess: async () => {
      toast.success(initial ? 'Aula atualizada.' : 'Aula criada.')
      await onSaved()
      onClose()
    },
    onError: (error) => toast.error(errorMessage(error)),
  })

  return (
    <div className="max-h-[70vh] space-y-4 overflow-y-auto pr-1">
      <div>
        <label className="form-label">Título da aula</label>
        <input
          className="form-input"
          value={title}
          onChange={(event) => setTitle(event.target.value)}
        />
      </div>

      <div>
        <label className="form-label">Descrição</label>
        <textarea
          className="form-input min-h-20"
          value={description}
          onChange={(event) => setDescription(event.target.value)}
        />
      </div>

      <div className="grid gap-3 md:grid-cols-3">
        <div>
          <label className="form-label">Tipo</label>
          <select
            className="form-input"
            value={lessonType}
            onChange={(event) =>
              setLessonType(event.target.value as TrainingLibraryLessonType)
            }
          >
            {Object.entries(LESSON_LABELS).map(([value, label]) => (
              <option key={value} value={value}>
                {label}
              </option>
            ))}
          </select>
        </div>

        <div>
          <label className="form-label">Duração (min)</label>
          <input
            type="number"
            min={1}
            className="form-input"
            value={duration}
            onChange={(event) => setDuration(event.target.value)}
          />
        </div>

        <div>
          <label className="form-label">Status</label>
          <select
            className="form-input"
            value={status}
            onChange={(event) =>
              setStatus(event.target.value as TrainingLibraryItemStatus)
            }
          >
            <option value="draft">Rascunho</option>
            <option value="published">Publicado</option>
          </select>
        </div>
      </div>

      <div>
        <label className="form-label">Objetivo da aula</label>
        <textarea
          className="form-input min-h-20"
          value={learningObjective}
          onChange={(event) => setLearningObjective(event.target.value)}
        />
      </div>

      <div>
        <label className="form-label">Resumo / conteúdo principal</label>
        <textarea
          className="form-input min-h-28"
          value={summary}
          onChange={(event) => setSummary(event.target.value)}
        />
      </div>

      <div>
        <label className="form-label">Pontos-chave</label>
        <textarea
          className="form-input min-h-28"
          value={keyPoints}
          onChange={(event) => setKeyPoints(event.target.value)}
          placeholder="Um ponto por linha"
        />
        <p className="mt-1 text-xs text-gray-500">
          Digite um ponto-chave por linha.
        </p>
      </div>

      <label className="flex items-center gap-2 text-sm text-gray-700">
        <input
          type="checkbox"
          checked={isRequired}
          onChange={(event) => setIsRequired(event.target.checked)}
        />
        Aula obrigatória
      </label>

      <div className="flex justify-end gap-2">
        <button type="button" className="btn-secondary" onClick={onClose}>
          Cancelar
        </button>
        <button
          type="button"
          className="btn-primary"
          onClick={() => mutation.mutate()}
          disabled={mutation.isPending}
        >
          {mutation.isPending ? 'Salvando...' : 'Salvar aula'}
        </button>
      </div>
    </div>
  )
}

function AssetForm({
  organizationId,
  trainingId,
  onSaved,
  onClose,
}: {
  organizationId: string
  trainingId: string
  onSaved: () => Promise<void>
  onClose: () => void
}) {
  const [file, setFile] = useState<File | null>(null)
  const [displayName, setDisplayName] = useState('')
  const [assetType, setAssetType] =
    useState<TrainingLibraryAssetType>('attachment')
  const [isDownloadable, setIsDownloadable] = useState(true)

  const mutation = useMutation({
    mutationFn: async () => {
      if (!file) throw new Error('Selecione um arquivo.')
      if (!displayName.trim()) throw new Error('Informe o nome do material.')

      await uploadTrainingLibraryAsset({
        organizationId,
        trainingId,
        file,
        displayName,
        assetType,
        isDownloadable,
      })
    },
    onSuccess: async () => {
      toast.success('Material enviado com sucesso.')
      await onSaved()
      onClose()
    },
    onError: (error) => toast.error(errorMessage(error)),
  })

  return (
    <div className="space-y-4">
      <div>
        <label className="form-label">Arquivo</label>
        <input
          type="file"
          className="form-input"
          accept=".pdf,.ppt,.pptx,.doc,.docx,.jpg,.jpeg,.png,.webp"
          onChange={(event) => {
            const selected = event.target.files?.[0] ?? null
            setFile(selected)
            if (selected && !displayName) {
              setDisplayName(selected.name.replace(/\.[^.]+$/, ''))
            }
          }}
        />
        <p className="mt-1 text-xs text-gray-500">
          PDF, PowerPoint, Word ou imagem. Limite atual do bucket: 100 MB.
        </p>
      </div>

      <div>
        <label className="form-label">Nome exibido</label>
        <input
          className="form-input"
          value={displayName}
          onChange={(event) => setDisplayName(event.target.value)}
        />
      </div>

      <div>
        <label className="form-label">Tipo do material</label>
        <select
          className="form-input"
          value={assetType}
          onChange={(event) =>
            setAssetType(event.target.value as TrainingLibraryAssetType)
          }
        >
          {Object.entries(ASSET_LABELS).map(([value, label]) => (
            <option key={value} value={value}>
              {label}
            </option>
          ))}
        </select>
      </div>

      <label className="flex items-center gap-2 text-sm text-gray-700">
        <input
          type="checkbox"
          checked={isDownloadable}
          onChange={(event) => setIsDownloadable(event.target.checked)}
        />
        Permitir download
      </label>

      <div className="flex justify-end gap-2">
        <button type="button" className="btn-secondary" onClick={onClose}>
          Cancelar
        </button>
        <button
          type="button"
          className="btn-primary"
          onClick={() => mutation.mutate()}
          disabled={mutation.isPending}
        >
          {mutation.isPending ? 'Enviando...' : 'Enviar material'}
        </button>
      </div>
    </div>
  )
}

type ConfirmTarget =
  | { type: 'training'; item: TrainingLibraryItem }
  | { type: 'module'; item: TrainingLibraryModule }
  | { type: 'lesson'; item: TrainingLibraryLesson }
  | { type: 'asset'; item: TrainingLibraryAsset }

export default function TrainingLibraryAdminPage() {
  const { activeOrganization, user, isAdmin } = useAuth()
  const organizationId = activeOrganization?.id
  const [selectedTrainingId, setSelectedTrainingId] = useState<string | null>(
    null,
  )
  const [trainingForm, setTrainingForm] = useState<TrainingLibraryItem | 'new' | null>(
    null,
  )
  const [moduleForm, setModuleForm] =
    useState<TrainingLibraryModule | 'new' | null>(null)
  const [lessonForm, setLessonForm] = useState<{
    moduleId: string
    lesson: TrainingLibraryLesson | null
  } | null>(null)
  const [assetFormOpen, setAssetFormOpen] = useState(false)
  const [confirmTarget, setConfirmTarget] = useState<ConfirmTarget | null>(null)
  const [openingAssetId, setOpeningAssetId] = useState<string | null>(null)

  const query = useQuery({
    queryKey: ['training-library-admin', organizationId, user?.id],
    enabled: !!organizationId && !!user?.id && isAdmin,
    queryFn: () => getTrainingLibraryAdminState(organizationId!),
  })

  const state = query.data
  const items = state?.items ?? []

  useEffect(() => {
    if (!items.length) {
      setSelectedTrainingId(null)
      return
    }

    if (!selectedTrainingId || !items.some((item) => item.id === selectedTrainingId)) {
      setSelectedTrainingId(items[0].id)
    }
  }, [items, selectedTrainingId])

  const selectedTraining = items.find(
    (item) => item.id === selectedTrainingId,
  ) ?? null

  const modules = useMemo(
    () =>
      (state?.modules ?? [])
        .filter((item) => item.training_id === selectedTrainingId)
        .sort((a, b) => a.sequence_no - b.sequence_no),
    [selectedTrainingId, state?.modules],
  )

  const assets = useMemo(
    () =>
      (state?.assets ?? [])
        .filter((item) => item.training_id === selectedTrainingId)
        .sort((a, b) => a.sequence_no - b.sequence_no),
    [selectedTrainingId, state?.assets],
  )

  const duplicateMutation = useMutation({
    mutationFn: (trainingId: string) =>
      duplicateTrainingLibraryItem(organizationId!, trainingId),
    onSuccess: async (result) => {
      toast.success('Treinamento duplicado como rascunho.')
      await query.refetch()
      setSelectedTrainingId(result.training_id)
    },
    onError: (error) => toast.error(errorMessage(error)),
  })

  const archiveMutation = useMutation({
    mutationFn: async (target: ConfirmTarget) => {
      if (!organizationId || !selectedTraining) {
        throw new Error('Organização ou treinamento não disponível.')
      }

      if (target.type === 'training') {
        await archiveTrainingLibraryItem(organizationId, target.item.id)
      } else if (target.type === 'module') {
        await archiveTrainingLibraryModule(
          organizationId,
          selectedTraining.id,
          target.item.id,
        )
      } else if (target.type === 'lesson') {
        await archiveTrainingLibraryLesson(
          organizationId,
          selectedTraining.id,
          target.item.id,
        )
      } else {
        await archiveTrainingLibraryAsset(
          organizationId,
          target.item,
        )
      }
    },
    onSuccess: async () => {
      toast.success('Item arquivado. O histórico foi preservado.')
      setConfirmTarget(null)
      await query.refetch()
    },
    onError: (error) => toast.error(errorMessage(error)),
  })

  async function handleOpenAsset(asset: TrainingLibraryAsset) {
    setOpeningAssetId(asset.id)
    try {
      await openTrainingAsset(asset)
    } catch (error) {
      toast.error(errorMessage(error))
    } finally {
      setOpeningAssetId(null)
    }
  }

  if (!isAdmin) {
    return (
      <div className="page-container">
        <div className="card">
          <EmptyState
            icon={BookOpen}
            title="Acesso restrito"
            description="A gestão da biblioteca é exclusiva do Administrador da Plataforma."
          />
        </div>
      </div>
    )
  }

  if (!organizationId) {
    return (
      <div className="page-container">
        <div className="card">
          <EmptyState
            icon={BookOpen}
            title="Selecione uma organização"
            description="Escolha uma organização ativa para gerenciar seus treinamentos."
          />
        </div>
      </div>
    )
  }

  if (query.isLoading) {
    return (
      <div className="page-container flex min-h-[400px] items-center justify-center">
        <LoadingSpinner size="lg" message="Carregando gestão de treinamentos..." />
      </div>
    )
  }

  if (query.error) {
    return (
      <div className="page-container">
        <PageHeader
          title="Gestão de Treinamentos"
          description="Cadastre e mantenha a biblioteca sem comandos ou SQL manual."
        />
        <div className="card">
          <EmptyState
            icon={BookOpen}
            title="Falha ao carregar a gestão"
            description={errorMessage(query.error)}
            action={(
              <button
                type="button"
                className="btn-secondary"
                onClick={() => query.refetch()}
              >
                <RefreshCw className="mr-2 h-4 w-4" />
                Tentar novamente
              </button>
            )}
          />
        </div>
      </div>
    )
  }

  return (
    <div className="page-container">
      <PageHeader
        title="Gestão de Treinamentos"
        description={`Cadastre treinamentos, módulos, aulas e materiais para ${activeOrganization?.trade_name ?? 'a organização ativa'}.`}
        action={(
          <button
            type="button"
            className="btn-primary"
            onClick={() => setTrainingForm('new')}
          >
            <Plus className="mr-2 h-4 w-4" />
            Novo treinamento
          </button>
        )}
      />

      <div className="grid gap-5 xl:grid-cols-[320px_minmax(0,1fr)]">
        <aside className="card h-fit p-4 xl:sticky xl:top-4">
          <div className="mb-3 flex items-center justify-between gap-2">
            <div>
              <h2 className="font-semibold text-gray-900">Biblioteca</h2>
              <p className="text-xs text-gray-500">
                {items.length} treinamento(s)
              </p>
            </div>
            {query.isFetching && (
              <RefreshCw className="h-4 w-4 animate-spin text-brand-700" />
            )}
          </div>

          {!items.length ? (
            <p className="rounded-lg bg-gray-50 p-3 text-sm text-gray-500">
              Nenhum treinamento cadastrado.
            </p>
          ) : (
            <div className="space-y-2">
              {items.map((item) => (
                <button
                  key={item.id}
                  type="button"
                  className={`w-full rounded-lg border p-3 text-left transition ${
                    item.id === selectedTrainingId
                      ? 'border-brand-300 bg-brand-50'
                      : 'border-gray-200 hover:border-brand-200'
                  }`}
                  onClick={() => setSelectedTrainingId(item.id)}
                >
                  <div className="flex items-start justify-between gap-2">
                    <span className="text-sm font-medium text-gray-900">
                      {item.sequence_no}. {item.title}
                    </span>
                    {item.is_featured && (
                      <Star className="h-4 w-4 shrink-0 text-amber-500" />
                    )}
                  </div>
                  <div className="mt-2 flex flex-wrap gap-1.5 text-xs">
                    <span className="badge bg-gray-100 text-gray-700">
                      {CATEGORY_LABELS[item.category]}
                    </span>
                    <span
                      className={`badge ${
                        item.status === 'published'
                          ? 'bg-green-100 text-green-800'
                          : 'bg-amber-100 text-amber-800'
                      }`}
                    >
                      {item.status === 'published' ? 'Publicado' : 'Rascunho'}
                    </span>
                  </div>
                </button>
              ))}
            </div>
          )}
        </aside>

        <main className="space-y-5">
          {!selectedTraining ? (
            <div className="card">
              <EmptyState
                icon={BookOpen}
                title="Crie seu primeiro treinamento"
                description="Use o botão “Novo treinamento” para começar."
              />
            </div>
          ) : (
            <>
              <section className="card p-5">
                <div className="flex flex-wrap items-start justify-between gap-4">
                  <div className="min-w-0">
                    <div className="flex flex-wrap items-center gap-2">
                      <span className="badge bg-brand-100 text-brand-800">
                        {CATEGORY_LABELS[selectedTraining.category]}
                      </span>
                      <span
                        className={`badge ${
                          selectedTraining.status === 'published'
                            ? 'bg-green-100 text-green-800'
                            : 'bg-amber-100 text-amber-800'
                        }`}
                      >
                        {selectedTraining.status === 'published'
                          ? 'Publicado'
                          : 'Rascunho'}
                      </span>
                    </div>
                    <h2 className="mt-3 text-xl font-semibold text-gray-900">
                      {selectedTraining.title}
                    </h2>
                    <p className="mt-2 text-sm leading-6 text-gray-600">
                      {selectedTraining.description || 'Sem descrição.'}
                    </p>
                    <p className="mt-3 text-xs text-gray-500">
                      Público:{' '}
                      {selectedTraining.audience_roles
                        .map((role) => ROLE_LABELS[role])
                        .join(', ')}
                    </p>
                  </div>

                  <div className="flex flex-wrap gap-2">
                    <button
                      type="button"
                      className="btn-secondary"
                      onClick={() => setTrainingForm(selectedTraining)}
                    >
                      <Pencil className="mr-2 h-4 w-4" />
                      Editar
                    </button>
                    <button
                      type="button"
                      className="btn-secondary"
                      onClick={() =>
                        duplicateMutation.mutate(selectedTraining.id)
                      }
                      disabled={duplicateMutation.isPending}
                    >
                      <Copy className="mr-2 h-4 w-4" />
                      Duplicar
                    </button>
                    <button
                      type="button"
                      className="btn-secondary text-red-700"
                      onClick={() =>
                        setConfirmTarget({
                          type: 'training',
                          item: selectedTraining,
                        })
                      }
                    >
                      <Archive className="mr-2 h-4 w-4" />
                      Arquivar
                    </button>
                  </div>
                </div>
              </section>

              <section className="card p-5">
                <div className="mb-4 flex flex-wrap items-center justify-between gap-3">
                  <div>
                    <h2 className="font-semibold text-gray-900">
                      Módulos e aulas
                    </h2>
                    <p className="mt-1 text-sm text-gray-500">
                      Estruture a experiência de aprendizagem. Novos itens entram no final da ordem atual.
                    </p>
                  </div>
                  <button
                    type="button"
                    className="btn-secondary"
                    onClick={() => setModuleForm('new')}
                  >
                    <FolderPlus className="mr-2 h-4 w-4" />
                    Novo módulo
                  </button>
                </div>

                {!modules.length ? (
                  <p className="rounded-lg bg-gray-50 p-4 text-sm text-gray-500">
                    Nenhum módulo cadastrado. O treinamento pode funcionar apenas com materiais ou receber uma trilha de aulas.
                  </p>
                ) : (
                  <div className="space-y-4">
                    {modules.map((module) => {
                      const lessons = (state?.lessons ?? [])
                        .filter((lesson) => lesson.module_id === module.id)
                        .sort((a, b) => a.sequence_no - b.sequence_no)

                      return (
                        <article
                          key={module.id}
                          className="rounded-xl border border-gray-200 p-4"
                        >
                          <div className="flex flex-wrap items-start justify-between gap-3">
                            <div>
                              <p className="text-xs font-semibold uppercase tracking-wide text-brand-700">
                                Módulo {module.sequence_no}
                              </p>
                              <h3 className="mt-1 font-semibold text-gray-900">
                                {module.title}
                              </h3>
                              {module.description && (
                                <p className="mt-1 text-sm text-gray-600">
                                  {module.description}
                                </p>
                              )}
                            </div>

                            <div className="flex flex-wrap gap-2">
                              <button
                                type="button"
                                className="btn-secondary"
                                onClick={() => setModuleForm(module)}
                              >
                                <Pencil className="mr-2 h-4 w-4" />
                                Editar
                              </button>
                              <button
                                type="button"
                                className="btn-secondary"
                                onClick={() =>
                                  setLessonForm({
                                    moduleId: module.id,
                                    lesson: null,
                                  })
                                }
                              >
                                <Plus className="mr-2 h-4 w-4" />
                                Aula
                              </button>
                              <button
                                type="button"
                                className="rounded p-2 text-red-600 hover:bg-red-50"
                                onClick={() =>
                                  setConfirmTarget({
                                    type: 'module',
                                    item: module,
                                  })
                                }
                                aria-label={`Arquivar ${module.title}`}
                              >
                                <Trash2 className="h-4 w-4" />
                              </button>
                            </div>
                          </div>

                          <div className="mt-4 space-y-2">
                            {!lessons.length ? (
                              <p className="text-sm text-gray-500">
                                Nenhuma aula neste módulo.
                              </p>
                            ) : (
                              lessons.map((lesson) => (
                                <div
                                  key={lesson.id}
                                  className="flex flex-wrap items-center justify-between gap-3 rounded-lg bg-gray-50 px-3 py-3"
                                >
                                  <div className="min-w-0">
                                    <p className="text-sm font-medium text-gray-900">
                                      {module.sequence_no}.{lesson.sequence_no}{' '}
                                      {lesson.title}
                                    </p>
                                    <p className="mt-1 text-xs text-gray-500">
                                      {LESSON_LABELS[lesson.lesson_type]}
                                      {lesson.duration_minutes
                                        ? ` • ${lesson.duration_minutes} min`
                                        : ''}
                                      {lesson.is_required
                                        ? ' • obrigatória'
                                        : ' • opcional'}
                                      {lesson.status === 'draft'
                                        ? ' • rascunho'
                                        : ''}
                                    </p>
                                  </div>
                                  <div className="flex gap-1">
                                    <button
                                      type="button"
                                      className="rounded p-2 text-gray-500 hover:bg-white"
                                      onClick={() =>
                                        setLessonForm({
                                          moduleId: module.id,
                                          lesson,
                                        })
                                      }
                                      aria-label={`Editar ${lesson.title}`}
                                    >
                                      <Pencil className="h-4 w-4" />
                                    </button>
                                    <button
                                      type="button"
                                      className="rounded p-2 text-red-600 hover:bg-red-50"
                                      onClick={() =>
                                        setConfirmTarget({
                                          type: 'lesson',
                                          item: lesson,
                                        })
                                      }
                                      aria-label={`Arquivar ${lesson.title}`}
                                    >
                                      <Trash2 className="h-4 w-4" />
                                    </button>
                                  </div>
                                </div>
                              ))
                            )}
                          </div>
                        </article>
                      )
                    })}
                  </div>
                )}
              </section>

              <section className="card p-5">
                <div className="mb-4 flex flex-wrap items-center justify-between gap-3">
                  <div>
                    <h2 className="font-semibold text-gray-900">
                      Materiais de apoio
                    </h2>
                    <p className="mt-1 text-sm text-gray-500">
                      Envie PDFs, apresentações, documentos e imagens diretamente pelo navegador.
                    </p>
                  </div>
                  <button
                    type="button"
                    className="btn-secondary"
                    onClick={() => setAssetFormOpen(true)}
                  >
                    <FilePlus2 className="mr-2 h-4 w-4" />
                    Enviar material
                  </button>
                </div>

                {!assets.length ? (
                  <p className="rounded-lg bg-gray-50 p-4 text-sm text-gray-500">
                    Nenhum material cadastrado.
                  </p>
                ) : (
                  <div className="space-y-2">
                    {assets.map((asset) => {
                      const previewable = canPreviewTrainingAssetInBrowser(asset)
                      const unavailable = !previewable && !asset.is_downloadable

                      return (
                      <div
                        key={asset.id}
                        className="flex flex-wrap items-center justify-between gap-3 rounded-lg border border-gray-200 px-3 py-3"
                      >
                        <div className="flex min-w-0 items-center gap-3">
                          <FileText className="h-4 w-4 shrink-0 text-gray-500" />
                          <div className="min-w-0">
                            <p className="truncate text-sm font-medium text-gray-900">
                              {asset.display_name}
                            </p>
                            <p className="text-xs text-gray-500">
                              {ASSET_LABELS[asset.asset_type]} •{' '}
                              {unavailable
                                ? 'download indisponível'
                                : previewable
                                  ? 'abrir no navegador'
                                  : 'baixar arquivo'}
                            </p>
                          </div>
                        </div>

                        <div className="flex gap-1">
                          <button
                            type="button"
                            className="rounded p-2 text-gray-500 hover:bg-gray-50"
                            onClick={() => handleOpenAsset(asset)}
                            disabled={openingAssetId === asset.id || unavailable}
                            aria-label={`Abrir ${asset.display_name}`}
                          >
                            {openingAssetId === asset.id ? (
                              <RefreshCw className="h-4 w-4 animate-spin" />
                            ) : previewable ? (
                              <ExternalLink className="h-4 w-4" />
                            ) : (
                              <Download className="h-4 w-4" />
                            )}
                          </button>
                          <button
                            type="button"
                            className="rounded p-2 text-red-600 hover:bg-red-50"
                            onClick={() =>
                              setConfirmTarget({
                                type: 'asset',
                                item: asset,
                              })
                            }
                            aria-label={`Arquivar ${asset.display_name}`}
                          >
                            <Trash2 className="h-4 w-4" />
                          </button>
                        </div>
                      </div>
                      )
                    })}
                  </div>
                )}
              </section>
            </>
          )}
        </main>
      </div>

      <Dialog
        open={trainingForm !== null}
        onOpenChange={(open) => !open && setTrainingForm(null)}
      >
        <DialogContent className="max-w-2xl">
          <DialogHeader>
            <DialogTitle>
              {trainingForm === 'new'
                ? 'Novo treinamento'
                : 'Editar treinamento'}
            </DialogTitle>
          </DialogHeader>
          {trainingForm !== null && (
            <TrainingForm
              initial={trainingForm === 'new' ? null : trainingForm}
              organizationId={organizationId}
              onSaved={async () => {
                await query.refetch()
              }}
              onClose={() => setTrainingForm(null)}
            />
          )}
        </DialogContent>
      </Dialog>

      <Dialog
        open={moduleForm !== null}
        onOpenChange={(open) => !open && setModuleForm(null)}
      >
        <DialogContent>
          <DialogHeader>
            <DialogTitle>
              {moduleForm === 'new' ? 'Novo módulo' : 'Editar módulo'}
            </DialogTitle>
          </DialogHeader>
          {moduleForm !== null && selectedTraining && (
            <ModuleForm
              organizationId={organizationId}
              trainingId={selectedTraining.id}
              initial={moduleForm === 'new' ? null : moduleForm}
              onSaved={async () => {
                await query.refetch()
              }}
              onClose={() => setModuleForm(null)}
            />
          )}
        </DialogContent>
      </Dialog>

      <Dialog
        open={lessonForm !== null}
        onOpenChange={(open) => !open && setLessonForm(null)}
      >
        <DialogContent className="max-w-2xl">
          <DialogHeader>
            <DialogTitle>
              {lessonForm?.lesson ? 'Editar aula' : 'Nova aula'}
            </DialogTitle>
          </DialogHeader>
          {lessonForm && selectedTraining && (
            <LessonForm
              organizationId={organizationId}
              trainingId={selectedTraining.id}
              moduleId={lessonForm.moduleId}
              initial={lessonForm.lesson}
              onSaved={async () => {
                await query.refetch()
              }}
              onClose={() => setLessonForm(null)}
            />
          )}
        </DialogContent>
      </Dialog>

      <Dialog
        open={assetFormOpen}
        onOpenChange={(open) => !open && setAssetFormOpen(false)}
      >
        <DialogContent>
          <DialogHeader>
            <DialogTitle>Enviar material</DialogTitle>
          </DialogHeader>
          {selectedTraining && (
            <AssetForm
              organizationId={organizationId}
              trainingId={selectedTraining.id}
              onSaved={async () => {
                await query.refetch()
              }}
              onClose={() => setAssetFormOpen(false)}
            />
          )}
        </DialogContent>
      </Dialog>

      <ConfirmDialog
        open={confirmTarget !== null}
        title="Arquivar item?"
        description="O item deixará de aparecer na biblioteca, mas o histórico existente será preservado. Esta ação não apaga progresso de usuários."
        confirmLabel={
          archiveMutation.isPending ? 'Arquivando...' : 'Arquivar'
        }
        variant="destructive"
        onConfirm={() => {
          if (confirmTarget && !archiveMutation.isPending) {
            archiveMutation.mutate(confirmTarget)
          }
        }}
        onCancel={() => {
          if (!archiveMutation.isPending) setConfirmTarget(null)
        }}
      />
    </div>
  )
}
