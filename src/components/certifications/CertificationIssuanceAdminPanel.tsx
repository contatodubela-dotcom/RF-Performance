import { useMemo, useState } from 'react'
import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query'
import {
  Award,
  CheckCircle2,
  RefreshCw,
  ShieldCheck,
  ShieldX,
  UsersRound,
} from 'lucide-react'
import { toast } from 'sonner'
import {
  CertificationIssuanceServiceError,
  getCertificationIssuanceState,
  issueCertificationProgramVersion,
} from '@/services/certificationIssuanceService'
import type { ManagedAssessmentProgressRow } from '@/types/assessments'
import type {
  CertificationIssuanceStateRow,
  CertificationRequirementEvaluation,
} from '@/types/certificationIssuance'
import EmptyState from '@/components/shared/EmptyState'
import LoadingSpinner from '@/components/shared/LoadingSpinner'

const ROLE_LABELS = {
  salesperson: 'Vendedor',
  supervisor: 'Supervisor',
  director: 'Diretor',
} as const

function formatDate(value: string | null) {
  if (!value) return '—'

  return new Intl.DateTimeFormat('pt-BR', {
    dateStyle: 'short',
    timeStyle: 'short',
  }).format(new Date(value))
}

function getEligibilityMessage(row: CertificationIssuanceStateRow) {
  if (row.active_certification_currently_valid) {
    return 'Já existe uma certificação ativa e vigente para este programa.'
  }

  if (!row.participant_eligible) {
    return 'O participante não está elegível para participar deste programa.'
  }

  if (!row.program_active) {
    return 'O programa ainda não está ativo para emissão.'
  }

  if (!row.version_currently_valid) {
    return 'A versão do programa está fora da vigência para emissão.'
  }

  if (!row.requirements_satisfied) {
    return 'Ainda existem requisitos obrigatórios pendentes.'
  }

  if (row.eligible_for_issuance) {
    return 'Todos os requisitos obrigatórios estão atendidos. A emissão manual está autorizada.'
  }

  return `Emissão indisponível: ${row.issuance_reason}`
}

function flattenRequirements(row: CertificationIssuanceStateRow) {
  const direct = Array.isArray(row.requirements) ? row.requirements : []
  const grouped = Array.isArray(row.requirement_groups)
    ? row.requirement_groups.flatMap((group) =>
        Array.isArray(group.requirements) ? group.requirements : [],
      )
    : []

  const seen = new Set<string>()

  return [...direct, ...grouped]
    .filter((requirement) => {
      if (!requirement?.requirement_id) return false
      if (seen.has(requirement.requirement_id)) return false
      seen.add(requirement.requirement_id)
      return true
    })
    .sort((left, right) => left.sequence_no - right.sequence_no)
}

function RequirementRow({
  requirement,
}: {
  requirement: CertificationRequirementEvaluation
}) {
  return (
    <div className="flex items-start gap-2 rounded-lg border border-gray-200 bg-white px-3 py-2 text-sm">
      {requirement.satisfied ? (
        <CheckCircle2 className="mt-0.5 h-4 w-4 shrink-0 text-green-600" />
      ) : (
        <ShieldX className="mt-0.5 h-4 w-4 shrink-0 text-amber-600" />
      )}
      <div className="min-w-0">
        <p className="font-medium text-gray-800">{requirement.title}</p>
        <p className="mt-0.5 text-xs text-gray-500">
          {requirement.satisfied
            ? 'Requisito atendido'
            : requirement.supported
              ? 'Requisito ainda não atendido'
              : 'Requisito ainda não suportado pelo motor'}
        </p>
      </div>
    </div>
  )
}

export default function CertificationIssuanceAdminPanel({
  organizationId,
  rows,
}: {
  organizationId: string
  rows: ManagedAssessmentProgressRow[]
}) {
  const queryClient = useQueryClient()

  const members = useMemo(() => {
    const memberMap = new Map<
      string,
      Pick<
        ManagedAssessmentProgressRow,
        | 'organization_member_id'
        | 'member_name'
        | 'member_email'
        | 'member_role'
        | 'team_contexts'
      >
    >()

    rows.forEach((row) => {
      if (!memberMap.has(row.organization_member_id)) {
        memberMap.set(row.organization_member_id, {
          organization_member_id: row.organization_member_id,
          member_name: row.member_name,
          member_email: row.member_email,
          member_role: row.member_role,
          team_contexts: row.team_contexts,
        })
      }
    })

    return Array.from(memberMap.values()).sort((left, right) =>
      left.member_name.localeCompare(right.member_name, 'pt-BR'),
    )
  }, [rows])

  const [selectedMemberId, setSelectedMemberId] = useState('')
  const [confirmingVersionId, setConfirmingVersionId] = useState<string | null>(
    null,
  )

  const effectiveMemberId =
    selectedMemberId || members[0]?.organization_member_id || ''
  const selectedMember = members.find(
    (member) => member.organization_member_id === effectiveMemberId,
  )

  const {
    data: states = [],
    error,
    isLoading,
    isFetching,
    refetch,
  } = useQuery({
    queryKey: [
      'certification-issuance-state',
      organizationId,
      effectiveMemberId,
    ],
    enabled: !!organizationId && !!effectiveMemberId,
    queryFn: () =>
      getCertificationIssuanceState(organizationId, effectiveMemberId),
  })

  const mutation = useMutation({
    mutationFn: (state: CertificationIssuanceStateRow) =>
      issueCertificationProgramVersion({
        organizationId,
        organizationMemberId: effectiveMemberId,
        certificationProgramVersionId:
          state.certification_program_version_id,
      }),
    onSuccess: async (result) => {
      toast.success(
        result.outcome === 'ALREADY_ACTIVE'
          ? `Certificação já estava ativa: ${result.certificate_number}`
          : `Certificação emitida: ${result.certificate_number}`,
      )

      setConfirmingVersionId(null)

      await Promise.all([
        refetch(),
        queryClient.invalidateQueries({
          queryKey: ['managed-certifications', organizationId],
        }),
      ])
    },
    onError: (mutationError: Error) => {
      toast.error(
        mutationError instanceof CertificationIssuanceServiceError
          ? mutationError.message
          : mutationError.message ||
              'Não foi possível emitir a certificação.',
      )
    },
  })

  if (!members.length) {
    return (
      <div className="card">
        <EmptyState
          icon={UsersRound}
          title="Nenhum participante disponível"
          description="Não há participantes ativos na organização para consultar a elegibilidade de certificação."
        />
      </div>
    )
  }

  return (
    <div className="space-y-4">
      <div className="card p-5">
        <label className="text-sm font-medium text-gray-700">
          Participante
          <select
            className="mt-1 w-full rounded-lg border border-gray-300 bg-white px-3 py-2 text-sm text-gray-800"
            value={effectiveMemberId}
            onChange={(event) => {
              setSelectedMemberId(event.target.value)
              setConfirmingVersionId(null)
            }}
          >
            {members.map((member) => (
              <option
                key={member.organization_member_id}
                value={member.organization_member_id}
              >
                {member.member_name} · {ROLE_LABELS[member.member_role]} ·{' '}
                {member.member_email}
              </option>
            ))}
          </select>
        </label>

        {selectedMember && (
          <div className="mt-3 flex flex-wrap gap-1.5">
            <span className="badge bg-brand-50 text-brand-700">
              {ROLE_LABELS[selectedMember.member_role]}
            </span>
            {selectedMember.team_contexts.map((team) => (
              <span
                key={team.team_id}
                className="badge bg-gray-100 text-gray-700"
              >
                {team.team_name}
                {team.sales_location_name
                  ? ` · ${team.sales_location_name}`
                  : ''}
              </span>
            ))}
          </div>
        )}
      </div>

      {isLoading ? (
        <div className="card flex min-h-[220px] items-center justify-center">
          <LoadingSpinner message="Calculando elegibilidade de certificação..." />
        </div>
      ) : error ? (
        <div className="card">
          <EmptyState
            icon={Award}
            title="Falha ao consultar elegibilidade"
            description={
              error instanceof CertificationIssuanceServiceError
                ? error.message
                : 'Não foi possível consultar a elegibilidade deste participante.'
            }
            action={(
              <button
                type="button"
                className="btn-secondary"
                onClick={() => refetch()}
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
      ) : !states.length ? (
        <div className="card">
          <EmptyState
            icon={Award}
            title="Nenhum programa de certificação"
            description="Não há versões de programas de certificação disponíveis nesta organização."
          />
        </div>
      ) : (
        <div className="space-y-4">
          {states.map((state) => {
            const requirements = flattenRequirements(state)
            const isConfirming =
              confirmingVersionId === state.certification_program_version_id
            const isIssuing =
              mutation.isPending &&
              mutation.variables?.certification_program_version_id ===
                state.certification_program_version_id

            return (
              <article
                key={state.certification_program_version_id}
                className="card p-5"
              >
                <div className="flex flex-wrap items-start justify-between gap-3">
                  <div>
                    <p className="text-xs font-semibold uppercase tracking-wide text-brand-700">
                      {state.program_name} · versão {state.version_code}
                    </p>
                    {state.program_description && (
                      <p className="mt-1 text-sm text-gray-500">
                        {state.program_description}
                      </p>
                    )}
                  </div>

                  <span
                    className={`badge ${
                      state.active_certification_currently_valid
                        ? 'bg-blue-100 text-blue-800'
                        : state.eligible_for_issuance
                          ? 'bg-green-100 text-green-800'
                          : 'bg-amber-100 text-amber-800'
                    }`}
                  >
                    {state.active_certification_currently_valid
                      ? 'Certificação ativa'
                      : state.eligible_for_issuance
                        ? 'Elegível para emissão'
                        : 'Não elegível'}
                  </span>
                </div>

                <div className="mt-4 flex flex-wrap gap-2 text-xs">
                  <span
                    className={`badge ${
                      state.program_active
                        ? 'bg-green-50 text-green-700'
                        : 'bg-gray-100 text-gray-700'
                    }`}
                  >
                    Programa {state.program_status}
                  </span>
                  <span
                    className={`badge ${
                      state.version_currently_valid
                        ? 'bg-green-50 text-green-700'
                        : 'bg-gray-100 text-gray-700'
                    }`}
                  >
                    Versão {state.version_status}
                  </span>
                  <span className="badge bg-gray-100 text-gray-700">
                    Requisitos {state.required_units_satisfied}/
                    {state.required_units_total}
                  </span>
                </div>

                <div
                  className={`mt-4 rounded-lg border p-4 text-sm ${
                    state.eligible_for_issuance
                      ? 'border-green-200 bg-green-50 text-green-800'
                      : state.active_certification_currently_valid
                        ? 'border-blue-200 bg-blue-50 text-blue-800'
                        : 'border-amber-200 bg-amber-50 text-amber-800'
                  }`}
                >
                  <div className="flex items-start gap-2">
                    {state.eligible_for_issuance ? (
                      <ShieldCheck className="mt-0.5 h-4 w-4 shrink-0" />
                    ) : (
                      <ShieldX className="mt-0.5 h-4 w-4 shrink-0" />
                    )}
                    <p>{getEligibilityMessage(state)}</p>
                  </div>
                </div>

                {requirements.length > 0 && (
                  <div className="mt-4 grid gap-2 lg:grid-cols-2">
                    {requirements.map((requirement) => (
                      <RequirementRow
                        key={requirement.requirement_id}
                        requirement={requirement}
                      />
                    ))}
                  </div>
                )}

                {state.active_certification_currently_valid && (
                  <div className="mt-4 rounded-lg border border-blue-200 bg-blue-50 p-4 text-sm text-blue-800">
                    <p className="font-medium">
                      Certificado {state.active_certificate_number}
                    </p>
                    <p className="mt-1 text-xs">
                      Emitido em {formatDate(state.active_certification_issued_at)}
                      {state.active_certification_valid_until
                        ? ` · válido até ${formatDate(
                            state.active_certification_valid_until,
                          )}`
                        : ' · sem prazo de expiração configurado'}
                    </p>
                  </div>
                )}

                {!state.active_certification_currently_valid &&
                  state.eligible_for_issuance && (
                    <div className="mt-5 flex justify-end">
                      {!isConfirming ? (
                        <button
                          type="button"
                          className="btn-primary"
                          onClick={() =>
                            setConfirmingVersionId(
                              state.certification_program_version_id,
                            )
                          }
                        >
                          Emitir certificação
                        </button>
                      ) : (
                        <div className="w-full rounded-lg border border-brand-200 bg-brand-50 p-4">
                          <p className="text-sm font-medium text-gray-900">
                            Confirmar emissão para {selectedMember?.member_name}?
                          </p>
                          <p className="mt-1 text-sm text-gray-600">
                            A certificação será registrada com snapshot auditável das evidências usadas pelo motor.
                          </p>
                          <div className="mt-4 flex flex-wrap justify-end gap-2">
                            <button
                              type="button"
                              className="btn-secondary"
                              disabled={mutation.isPending}
                              onClick={() => setConfirmingVersionId(null)}
                            >
                              Cancelar
                            </button>
                            <button
                              type="button"
                              className="btn-primary"
                              disabled={mutation.isPending}
                              onClick={() => mutation.mutate(state)}
                            >
                              {isIssuing
                                ? 'Emitindo...'
                                : 'Confirmar emissão'}
                            </button>
                          </div>
                        </div>
                      )}
                    </div>
                  )}
              </article>
            )
          })}
        </div>
      )}
    </div>
  )
}
