import { Award, RefreshCw } from 'lucide-react'
import EmptyState from '@/components/shared/EmptyState'
import LoadingSpinner from '@/components/shared/LoadingSpinner'
import { CertificationServiceError } from '@/services/certificationService'
import type {
  CertificationMemberRole,
  ManagedCertificationRow,
} from '@/types/certifications'

const ROLE_LABELS: Record<CertificationMemberRole, string> = {
  director: 'Diretor',
  supervisor: 'Supervisor',
  salesperson: 'Vendedor',
}

function formatCertificationDate(value: string | null) {
  if (!value) return '—'

  return new Intl.DateTimeFormat('pt-BR', {
    dateStyle: 'short',
  }).format(new Date(value))
}

function getCertificationStatus(certification: ManagedCertificationRow) {
  if (certification.currently_valid) {
    return {
      label: 'Vigente',
      className: 'bg-green-100 text-green-800',
    }
  }

  if (
    certification.revoked_at ||
    certification.certification_status === 'revoked'
  ) {
    return {
      label: 'Revogada',
      className: 'bg-red-100 text-red-800',
    }
  }

  if (
    certification.valid_until &&
    new Date(certification.valid_until).getTime() < Date.now()
  ) {
    return {
      label: 'Expirada',
      className: 'bg-amber-100 text-amber-800',
    }
  }

  return {
    label: certification.certification_status,
    className: 'bg-gray-100 text-gray-700',
  }
}

export default function ManagedCertificationsPanel({
  rows,
  isLoading,
  isFetching,
  error,
  onRetry,
  scopeLabel,
}: {
  rows: ManagedCertificationRow[]
  isLoading: boolean
  isFetching: boolean
  error: unknown
  onRetry: () => void
  scopeLabel: string
}) {
  if (isLoading) {
    return (
      <div className="card flex min-h-[220px] items-center justify-center">
        <LoadingSpinner message="Carregando certificações..." />
      </div>
    )
  }

  if (error) {
    const message =
      error instanceof CertificationServiceError
        ? error.message
        : 'Não foi possível carregar as certificações do escopo.'

    return (
      <div className="card">
        <EmptyState
          icon={Award}
          title="Falha ao carregar certificações"
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
          icon={Award}
          title="Nenhuma certificação emitida"
          description={`Não há certificações emitidas para participantes em ${scopeLabel}.`}
        />
      </div>
    )
  }

  const members = Array.from(
    rows.reduce((groups, row) => {
      const current = groups.get(row.organization_member_id) ?? []
      current.push(row)
      groups.set(row.organization_member_id, current)
      return groups
    }, new Map<string, ManagedCertificationRow[]>()),
  ).sort(([, leftRows], [, rightRows]) =>
    leftRows[0].member_name.localeCompare(
      rightRows[0].member_name,
      'pt-BR',
    ),
  )

  return (
    <div className="space-y-4">
      {members.map(([memberId, memberRows]) => {
        const member = memberRows[0]
        const teams = member.team_contexts ?? []
        const validCount = memberRows.filter(
          (certification) => certification.currently_valid,
        ).length

        return (
          <section key={memberId} className="card overflow-hidden">
            <div className="flex flex-wrap items-start justify-between gap-3 border-b border-gray-100 p-4">
              <div>
                <h3 className="font-semibold text-gray-900">
                  {member.member_name}
                </h3>
                <p className="text-xs text-gray-500">
                  {member.member_email}
                </p>

                <div className="mt-2 flex flex-wrap gap-1.5">
                  <span className="badge bg-brand-50 text-brand-700">
                    {ROLE_LABELS[member.member_role]}
                  </span>

                  {teams.length ? (
                    teams.map((team) => (
                      <span
                        key={team.team_id}
                        className="badge bg-gray-100 text-gray-700"
                      >
                        {team.team_name}
                        {team.sales_location_name
                          ? ` · ${team.sales_location_name}`
                          : ''}
                      </span>
                    ))
                  ) : (
                    <span className="text-xs text-amber-700">
                      Sem equipe ativa no escopo
                    </span>
                  )}
                </div>
              </div>

              <div className="text-right text-xs text-gray-500">
                <p>{memberRows.length} certificação(ões)</p>
                <p>{validCount} vigente(s)</p>
              </div>
            </div>

            <div className="overflow-x-auto">
              <table className="w-full">
                <thead>
                  <tr className="border-b border-gray-200 bg-gray-50">
                    <th className="table-th">Certificação</th>
                    <th className="table-th">Status</th>
                    <th className="table-th">Emissão</th>
                    <th className="table-th">Validade</th>
                    <th className="table-th hidden lg:table-cell">
                      Número
                    </th>
                  </tr>
                </thead>

                <tbody>
                  {memberRows
                    .slice()
                    .sort((left, right) => {
                      const leftIssuedAt = left.issued_at
                        ? new Date(left.issued_at).getTime()
                        : 0
                      const rightIssuedAt = right.issued_at
                        ? new Date(right.issued_at).getTime()
                        : 0

                      return rightIssuedAt - leftIssuedAt
                    })
                    .map((certification) => {
                      const status =
                        getCertificationStatus(certification)
                      const title =
                        certification.program_name ??
                        certification.version_name ??
                        'Certificação registrada'

                      return (
                        <tr
                          key={certification.certification_id}
                          className="border-b border-gray-100 last:border-b-0"
                        >
                          <td className="table-td">
                            <p className="font-medium text-gray-800">
                              {title}
                            </p>
                            {certification.version_code && (
                              <p className="text-xs text-gray-500">
                                Versão {certification.version_code}
                              </p>
                            )}
                          </td>

                          <td className="table-td">
                            <span
                              className={`badge ${status.className}`}
                            >
                              {status.label}
                            </span>
                          </td>

                          <td className="table-td text-gray-600">
                            {formatCertificationDate(
                              certification.issued_at,
                            )}
                          </td>

                          <td className="table-td text-gray-600">
                            {certification.valid_until
                              ? formatCertificationDate(
                                  certification.valid_until,
                                )
                              : 'Sem vencimento'}
                          </td>

                          <td className="table-td hidden text-xs text-gray-500 lg:table-cell">
                            {certification.certificate_number}
                          </td>
                        </tr>
                      )
                    })}
                </tbody>
              </table>
            </div>
          </section>
        )
      })}
    </div>
  )
}
