import { useMemo, useState } from 'react'
import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query'
import { ClipboardCheck, RefreshCw, UsersRound } from 'lucide-react'
import { toast } from 'sonner'
import { useAuth } from '@/contexts/AuthContext'
import {
  AssessmentServiceError,
  configureAssessmentAccess,
  getAssessmentAccessAdminState,
} from '@/services/assessmentService'
import type { AssessmentAccessScope } from '@/types/assessments'
import EmptyState from '@/components/shared/EmptyState'
import LoadingSpinner from '@/components/shared/LoadingSpinner'

const ROLE_LABELS = {
  salesperson: 'Vendedor',
  supervisor: 'Supervisor',
  director: 'Diretor',
} as const

export default function AssessmentAccessAdminPanel() {
  const { activeOrganization, isAdmin } = useAuth()
  const organizationId = activeOrganization?.id
  const queryClient = useQueryClient()
  const [selectedTestId, setSelectedTestId] = useState('')
  const [scope, setScope] = useState<AssessmentAccessScope>('organization')
  const [selectedMemberId, setSelectedMemberId] = useState('')

  const {
    data,
    error,
    isLoading,
    isFetching,
    refetch,
  } = useQuery({
    queryKey: ['assessment-access-admin-state', organizationId],
    enabled: !!organizationId && !!isAdmin,
    queryFn: () => getAssessmentAccessAdminState(organizationId!),
  })

  const effectiveTestId = selectedTestId || data?.tests[0]?.test_id || ''
  const effectiveMemberId =
    selectedMemberId || data?.members[0]?.organization_member_id || ''

  const selectedTest = useMemo(
    () => data?.tests.find((test) => test.test_id === effectiveTestId),
    [data?.tests, effectiveTestId],
  )

  const organizationGrant = useMemo(
    () =>
      data?.active_grants.find(
        (grant) =>
          grant.test_version_id === selectedTest?.test_version_id &&
          grant.access_scope === 'organization',
      ),
    [data?.active_grants, selectedTest?.test_version_id],
  )

  const memberGrant = useMemo(
    () =>
      data?.active_grants.find(
        (grant) =>
          grant.test_version_id === selectedTest?.test_version_id &&
          grant.access_scope === 'member' &&
          grant.organization_member_id === effectiveMemberId,
      ),
    [data?.active_grants, effectiveMemberId, selectedTest?.test_version_id],
  )

  const selectedMember = data?.members.find(
    (member) => member.organization_member_id === effectiveMemberId,
  )

  const activeGrant = scope === 'organization' ? organizationGrant : memberGrant

  const mutation = useMutation({
    mutationFn: (enabled: boolean) => {
      if (!organizationId || !effectiveTestId) {
        throw new Error('Organização ou avaliação não encontrada.')
      }

      return configureAssessmentAccess({
        organizationId,
        testId: effectiveTestId,
        accessScope: scope,
        organizationMemberId: scope === 'member' ? effectiveMemberId : null,
        enabled,
      })
    },
    onSuccess: async (result) => {
      toast.success(
        result.enabled
          ? 'Avaliação liberada com sucesso.'
          : 'Liberação revogada com sucesso.',
      )

      await Promise.all([
        refetch(),
        queryClient.invalidateQueries({
          queryKey: ['managed-assessment-progress', organizationId],
        }),
      ])
    },
    onError: (mutationError: Error) => {
      toast.error(
        mutationError instanceof AssessmentServiceError
          ? mutationError.message
          : 'Não foi possível alterar a liberação da avaliação.',
      )
    },
  })

  if (!isAdmin) return null

  if (isLoading) {
    return (
      <section className="card flex min-h-[180px] items-center justify-center">
        <LoadingSpinner message="Carregando liberações de avaliações..." />
      </section>
    )
  }

  if (error) {
    const message =
      error instanceof AssessmentServiceError
        ? error.message
        : 'Não foi possível carregar as liberações das avaliações.'

    return (
      <section className="card">
        <EmptyState
          icon={ClipboardCheck}
          title="Falha ao carregar liberações"
          description={message}
          action={(
            <button
              type="button"
              className="btn-secondary"
              onClick={() => refetch()}
              disabled={isFetching}
            >
              <RefreshCw
                className={`mr-2 h-4 w-4 ${isFetching ? 'animate-spin' : ''}`}
              />
              Tentar novamente
            </button>
          )}
        />
      </section>
    )
  }

  if (!data?.tests.length) {
    return (
      <section className="card">
        <EmptyState
          icon={ClipboardCheck}
          title="Nenhuma avaliação publicada"
          description="Não há avaliações publicadas disponíveis para liberação nesta organização."
        />
      </section>
    )
  }

  const canSubmit =
    !!effectiveTestId &&
    (scope === 'organization' || !!effectiveMemberId) &&
    !mutation.isPending

  return (
    <section>
      <div className="mb-4">
        <h2 className="flex items-center gap-2 text-lg font-semibold text-gray-900">
          <ClipboardCheck className="h-5 w-5 text-brand-700" />
          Liberação de avaliações
        </h2>
        <p className="mt-1 text-sm text-gray-500">
          Libere uma avaliação para toda a organização ou para um participante específico.
          O Administrador da Plataforma permanece somente como gestor.
        </p>
      </div>

      <div className="card p-5">
        <div className="grid gap-4 lg:grid-cols-2">
          <label className="text-sm font-medium text-gray-700">
            Avaliação
            <select
              className="mt-1 w-full rounded-lg border border-gray-300 bg-white px-3 py-2 text-sm text-gray-800"
              value={effectiveTestId}
              onChange={(event) => setSelectedTestId(event.target.value)}
            >
              {data.tests.map((test) => (
                <option key={test.test_id} value={test.test_id}>
                  {test.sequence_no}. {test.title}
                </option>
              ))}
            </select>
          </label>

          <label className="text-sm font-medium text-gray-700">
            Liberar para
            <select
              className="mt-1 w-full rounded-lg border border-gray-300 bg-white px-3 py-2 text-sm text-gray-800"
              value={scope}
              onChange={(event) =>
                setScope(event.target.value as AssessmentAccessScope)
              }
            >
              <option value="organization">Organização inteira</option>
              <option value="member">Usuário específico</option>
            </select>
          </label>
        </div>

        {scope === 'member' && (
          <div className="mt-4">
            <label className="text-sm font-medium text-gray-700">
              Participante
              <select
                className="mt-1 w-full rounded-lg border border-gray-300 bg-white px-3 py-2 text-sm text-gray-800"
                value={effectiveMemberId}
                onChange={(event) => setSelectedMemberId(event.target.value)}
                disabled={!data.members.length}
              >
                {!data.members.length && (
                  <option value="">Nenhum participante elegível</option>
                )}
                {data.members.map((member) => (
                  <option
                    key={member.organization_member_id}
                    value={member.organization_member_id}
                  >
                    {member.name} · {ROLE_LABELS[member.role]} · {member.email}
                  </option>
                ))}
              </select>
            </label>
          </div>
        )}

        <div className="mt-5 rounded-lg border border-gray-200 bg-gray-50 p-4">
          <div className="flex flex-wrap items-center justify-between gap-3">
            <div>
              <p className="text-sm font-medium text-gray-800">
                {activeGrant ? 'Liberação ativa' : 'Sem liberação direta'}
              </p>
              <p className="mt-1 text-xs text-gray-500">
                {scope === 'organization'
                  ? 'A liberação organizacional alcança Vendedores, Supervisores e Diretores ativos.'
                  : selectedMember
                    ? `${selectedMember.name} · ${ROLE_LABELS[selectedMember.role]}`
                    : 'Selecione um participante elegível.'}
              </p>
              {scope === 'member' && organizationGrant && (
                <p className="mt-1 text-xs text-amber-700">
                  Este participante já está coberto pela liberação da organização.
                </p>
              )}
            </div>

            <button
              type="button"
              className={activeGrant ? 'btn-secondary' : 'btn-primary'}
              disabled={!canSubmit}
              onClick={() => mutation.mutate(!activeGrant)}
            >
              {mutation.isPending
                ? 'Salvando...'
                : activeGrant
                  ? 'Revogar liberação'
                  : 'Liberar avaliação'}
            </button>
          </div>
        </div>

        <div className="mt-4 flex items-center gap-2 text-xs text-gray-500">
          <UsersRound className="h-4 w-4" />
          {data.members.length} participante(s) elegível(is) nesta organização.
        </div>
      </div>
    </section>
  )
}
