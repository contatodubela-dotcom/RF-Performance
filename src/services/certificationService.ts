import { supabase } from '@/lib/supabase'
import type {
  CertificationRecord,
  ManagedCertificationRow,
} from '@/types/certifications'

export type CertificationErrorCode =
  | 'AUTH_REQUIRED'
  | 'ACTIVE_MEMBERSHIP_REQUIRED'
  | 'ORGANIZATION_NOT_AVAILABLE'
  | 'CERTIFICATION_ORGANIZATION_REQUIRED'
  | 'CERTIFICATION_PARTICIPANT_NOT_ELIGIBLE'
  | 'CERTIFICATION_MANAGEMENT_FORBIDDEN'
  | 'CERTIFICATION_RPC_ERROR'

const ERROR_MESSAGES: Record<CertificationErrorCode, string> = {
  AUTH_REQUIRED: 'Sua sess\u00e3o expirou. Entre novamente para continuar.',
  ACTIVE_MEMBERSHIP_REQUIRED:
    'Seu usu\u00e1rio n\u00e3o possui v\u00ednculo ativo com esta organiza\u00e7\u00e3o.',
  ORGANIZATION_NOT_AVAILABLE:
    'A organiza\u00e7\u00e3o selecionada n\u00e3o est\u00e1 dispon\u00edvel para esta consulta.',
  CERTIFICATION_ORGANIZATION_REQUIRED:
    'Selecione uma organiza\u00e7\u00e3o para consultar as certifica\u00e7\u00f5es.',
  CERTIFICATION_PARTICIPANT_NOT_ELIGIBLE:
    'Seu perfil n\u00e3o est\u00e1 eleg\u00edvel para participar do processo de certifica\u00e7\u00e3o.',
  CERTIFICATION_MANAGEMENT_FORBIDDEN:
    'Seu perfil n\u00e3o possui permiss\u00e3o para acompanhar certifica\u00e7\u00f5es da equipe.',
  CERTIFICATION_RPC_ERROR:
    'N\u00e3o foi poss\u00edvel consultar as certifica\u00e7\u00f5es. Tente novamente.',
}

const KNOWN_ERROR_CODES = Object.keys(ERROR_MESSAGES).filter(
  (code) => code !== 'CERTIFICATION_RPC_ERROR',
) as Exclude<CertificationErrorCode, 'CERTIFICATION_RPC_ERROR'>[]

export interface CertificationRpcError {
  message: string
  details?: string | null
  hint?: string | null
  code?: string
}

export class CertificationServiceError extends Error {
  readonly code: CertificationErrorCode
  readonly originalError?: CertificationRpcError

  constructor(
    code: CertificationErrorCode,
    originalError?: CertificationRpcError,
  ) {
    super(ERROR_MESSAGES[code])
    this.name = 'CertificationServiceError'
    this.code = code
    this.originalError = originalError
  }
}

function mapRpcError(
  error: CertificationRpcError,
): CertificationServiceError {
  const haystack = [error.message, error.details, error.hint]
    .filter(Boolean)
    .join(' ')

  const knownCode = KNOWN_ERROR_CODES.find((code) =>
    haystack.includes(code),
  )

  return new CertificationServiceError(
    knownCode ?? 'CERTIFICATION_RPC_ERROR',
    error,
  )
}

export async function getMyCertifications(
  organizationId: string,
): Promise<CertificationRecord[]> {
  const { data, error } = await supabase.rpc('get_my_certifications', {
    p_organization_id: organizationId,
  })

  if (error) throw mapRpcError(error)

  return (data ?? []) as CertificationRecord[]
}

export async function getManagedCertifications(
  organizationId: string,
): Promise<ManagedCertificationRow[]> {
  const { data, error } = await supabase.rpc(
    'get_managed_certifications',
    {
      p_organization_id: organizationId,
    },
  )

  if (error) throw mapRpcError(error)

  return (data ?? []) as ManagedCertificationRow[]
}
