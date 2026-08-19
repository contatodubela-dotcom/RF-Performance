import { Award, RefreshCw } from 'lucide-react'
import EmptyState from '@/components/shared/EmptyState'
import LoadingSpinner from '@/components/shared/LoadingSpinner'
import { CertificationServiceError } from '@/services/certificationService'
import type { CertificationRecord } from '@/types/certifications'

function formatCertificationDate(value: string | null) {
  if (!value) return '—'

  return new Intl.DateTimeFormat('pt-BR', {
    dateStyle: 'short',
  }).format(new Date(value))
}

function getCertificationStatus(certification: CertificationRecord) {
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

export default function PersonalCertificationsPanel({
  rows,
  isLoading,
  isFetching,
  error,
  onRetry,
}: {
  rows: CertificationRecord[]
  isLoading: boolean
  isFetching: boolean
  error: unknown
  onRetry: () => void
}) {
  if (isLoading) {
    return (
      <div className="card flex min-h-[180px] items-center justify-center">
        <LoadingSpinner message="Carregando suas certificações..." />
      </div>
    )
  }

  if (error) {
    const message =
      error instanceof CertificationServiceError
        ? error.message
        : 'Não foi possível carregar suas certificações.'

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
          description="As certificações efetivamente emitidas para você aparecerão aqui. A aprovação em uma avaliação, isoladamente, não representa a emissão de uma certificação."
        />
      </div>
    )
  }

  return (
    <div className="grid gap-4 lg:grid-cols-2">
      {rows.map((certification) => {
        const status = getCertificationStatus(certification)
        const title =
          certification.program_name ??
          certification.version_name ??
          'Certificação registrada'

        const description =
          certification.program_description ??
          certification.version_description

        return (
          <article
            key={certification.certification_id}
            className="card p-5"
          >
            <div className="flex items-start justify-between gap-4">
              <div className="min-w-0">
                <p className="text-xs font-semibold uppercase tracking-wide text-brand-700">
                  Certificação emitida
                </p>

                <h3 className="mt-1 font-semibold text-gray-900">
                  {title}
                </h3>

                {description && (
                  <p className="mt-2 text-sm leading-5 text-gray-600">
                    {description}
                  </p>
                )}
              </div>

              <span className={`badge shrink-0 ${status.className}`}>
                {status.label}
              </span>
            </div>

            <dl className="mt-4 grid gap-3 border-t border-gray-100 pt-4 text-sm sm:grid-cols-2">
              <div>
                <dt className="text-xs text-gray-500">Número</dt>
                <dd className="mt-1 font-medium text-gray-800">
                  {certification.certificate_number}
                </dd>
              </div>

              <div>
                <dt className="text-xs text-gray-500">Emissão</dt>
                <dd className="mt-1 text-gray-700">
                  {formatCertificationDate(certification.issued_at)}
                </dd>
              </div>

              <div>
                <dt className="text-xs text-gray-500">Validade</dt>
                <dd className="mt-1 text-gray-700">
                  {certification.valid_until
                    ? formatCertificationDate(certification.valid_until)
                    : 'Sem vencimento definido'}
                </dd>
              </div>

              {certification.version_code && (
                <div>
                  <dt className="text-xs text-gray-500">Versão</dt>
                  <dd className="mt-1 text-gray-700">
                    {certification.version_code}
                  </dd>
                </div>
              )}
            </dl>
          </article>
        )
      })}
    </div>
  )
}
