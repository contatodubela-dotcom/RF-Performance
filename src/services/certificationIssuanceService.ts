import { supabase } from '@/lib/supabase'
import type {
  CertificationIssuanceStateRow,
  IssueCertificationInput,
  IssueCertificationResponse,
} from '@/types/certificationIssuance'

export type CertificationIssuanceErrorCode =
  | 'AUTH_REQUIRED'
  | 'ORGANIZATION_NOT_AVAILABLE'
  | 'CERTIFICATION_ORGANIZATION_REQUIRED'
  | 'CERTIFICATION_MEMBER_REQUIRED'
  | 'CERTIFICATION_MEMBER_NOT_FOUND'
  | 'CERTIFICATION_PROGRAM_VERSION_REQUIRED'
  | 'CERTIFICATION_ISSUANCE_FORBIDDEN'
  | 'CERTIFICATION_PARTICIPANT_NOT_ELIGIBLE'
  | 'CERTIFICATION_PROGRAM_VERSION_NOT_FOUND'
  | 'CERTIFICATION_PROGRAM_NOT_FOUND'
  | 'CERTIFICATION_NOT_ELIGIBLE'
  | 'CERTIFICATION_ENGINE_INVALID_RESULT'
  | 'CERTIFICATION_ISSUANCE_RPC_ERROR'

const ERROR_MESSAGES: Record<CertificationIssuanceErrorCode, string> = {
  AUTH_REQUIRED: 'Sua sessão expirou. Entre novamente para continuar.',
  ORGANIZATION_NOT_AVAILABLE:
    'A organização selecionada não está disponível para esta operação.',
  CERTIFICATION_ORGANIZATION_REQUIRED:
    'Selecione uma organização para consultar ou emitir certificações.',
  CERTIFICATION_MEMBER_REQUIRED:
    'Selecione um participante para consultar ou emitir a certificação.',
  CERTIFICATION_MEMBER_NOT_FOUND:
    'O participante selecionado não foi encontrado nesta organização.',
  CERTIFICATION_PROGRAM_VERSION_REQUIRED:
    'Selecione uma versão de programa de certificação.',
  CERTIFICATION_ISSUANCE_FORBIDDEN:
    'Somente o Administrador da Plataforma pode emitir certificações.',
  CERTIFICATION_PARTICIPANT_NOT_ELIGIBLE:
    'O participante selecionado não está elegível para certificação.',
  CERTIFICATION_PROGRAM_VERSION_NOT_FOUND:
    'A versão do programa de certificação não foi encontrada.',
  CERTIFICATION_PROGRAM_NOT_FOUND:
    'O programa de certificação não foi encontrado.',
  CERTIFICATION_NOT_ELIGIBLE:
    'A certificação não pode ser emitida porque os requisitos ainda não estão atendidos.',
  CERTIFICATION_ENGINE_INVALID_RESULT:
    'O motor de certificação retornou um estado inválido e a emissão foi interrompida.',
  CERTIFICATION_ISSUANCE_RPC_ERROR:
    'Não foi possível concluir a operação de certificação. Tente novamente.',
}

const KNOWN_ERROR_CODES = Object.keys(ERROR_MESSAGES).filter(
  (code) => code !== 'CERTIFICATION_ISSUANCE_RPC_ERROR',
) as Exclude<CertificationIssuanceErrorCode, 'CERTIFICATION_ISSUANCE_RPC_ERROR'>[]

export interface CertificationIssuanceRpcError {
  message: string
  details?: string | null
  hint?: string | null
  code?: string
}

export class CertificationIssuanceServiceError extends Error {
  readonly code: CertificationIssuanceErrorCode
  readonly originalError?: CertificationIssuanceRpcError

  constructor(
    code: CertificationIssuanceErrorCode,
    originalError?: CertificationIssuanceRpcError,
  ) {
    super(ERROR_MESSAGES[code])
    this.name = 'CertificationIssuanceServiceError'
    this.code = code
    this.originalError = originalError
  }
}

function mapRpcError(
  error: CertificationIssuanceRpcError,
): CertificationIssuanceServiceError {
  const haystack = [error.message, error.details, error.hint]
    .filter(Boolean)
    .join(' ')

  const knownCode = KNOWN_ERROR_CODES.find((code) => haystack.includes(code))

  return new CertificationIssuanceServiceError(
    knownCode ?? 'CERTIFICATION_ISSUANCE_RPC_ERROR',
    error,
  )
}

export async function getCertificationIssuanceState(
  organizationId: string,
  organizationMemberId: string,
): Promise<CertificationIssuanceStateRow[]> {
  const { data, error } = await supabase.rpc(
    'get_certification_issuance_state',
    {
      p_organization_id: organizationId,
      p_organization_member_id: organizationMemberId,
    },
  )

  if (error) throw mapRpcError(error)

  return (data ?? []) as CertificationIssuanceStateRow[]
}

export async function issueCertificationProgramVersion({
  organizationId,
  organizationMemberId,
  certificationProgramVersionId,
}: IssueCertificationInput): Promise<IssueCertificationResponse> {
  const { data, error } = await supabase.rpc(
    'issue_certification_program_version',
    {
      p_organization_id: organizationId,
      p_organization_member_id: organizationMemberId,
      p_certification_program_version_id: certificationProgramVersionId,
    },
  )

  if (error) throw mapRpcError(error)

  if (!data || typeof data !== 'object') {
    throw new CertificationIssuanceServiceError(
      'CERTIFICATION_ISSUANCE_RPC_ERROR',
      {
        code: 'EMPTY_RPC_RESPONSE',
        message:
          'RPC issue_certification_program_version retornou uma resposta vazia.',
      },
    )
  }

  return data as unknown as IssueCertificationResponse
}
