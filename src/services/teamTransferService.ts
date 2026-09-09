import { supabase } from '@/lib/supabase'

export type TeamTransferErrorCode =
  | 'AUTH_REQUIRED'
  | 'SALESPERSON_TRANSFER_INVALID_INPUT'
  | 'SALESPERSON_TRANSFER_FORBIDDEN'
  | 'SALESPERSON_NOT_ACTIVE'
  | 'SALESPERSON_ACTIVE_TEAM_NOT_FOUND'
  | 'DESTINATION_TEAM_NOT_ACTIVE'
  | 'SALESPERSON_ALREADY_IN_DESTINATION_TEAM'
  | 'DESTINATION_TEAM_WITHOUT_SALES_LOCATION'
  | 'DESTINATION_TEAM_WITHOUT_SUPERVISOR'
  | 'DESTINATION_TEAM_SUPERVISOR_NOT_ACTIVE'
  | 'DESTINATION_TEAM_CAPACITY_EXCEEDED'
  | 'SALESPERSON_TRANSFER_RPC_ERROR'

const ERROR_MESSAGES: Record<TeamTransferErrorCode, string> = {
  AUTH_REQUIRED:
    'Sua sessão expirou. Entre novamente para continuar.',
  SALESPERSON_TRANSFER_INVALID_INPUT:
    'Os dados informados para a transferência são inválidos.',
  SALESPERSON_TRANSFER_FORBIDDEN:
    'Seu perfil não possui permissão para transferir vendedores entre equipes.',
  SALESPERSON_NOT_ACTIVE:
    'O vendedor selecionado não está ativo nesta organização.',
  SALESPERSON_ACTIVE_TEAM_NOT_FOUND:
    'Não foi encontrado um vínculo ativo do vendedor com a equipe atual.',
  DESTINATION_TEAM_NOT_ACTIVE:
    'A equipe de destino não está ativa ou não pertence a esta organização.',
  SALESPERSON_ALREADY_IN_DESTINATION_TEAM:
    'O vendedor já pertence à equipe selecionada.',
  DESTINATION_TEAM_WITHOUT_SALES_LOCATION:
    'A equipe de destino não possui um PDV ativo configurado.',
  DESTINATION_TEAM_WITHOUT_SUPERVISOR:
    'A equipe de destino não possui supervisor configurado.',
  DESTINATION_TEAM_SUPERVISOR_NOT_ACTIVE:
    'O supervisor da equipe de destino não está ativo.',
  DESTINATION_TEAM_CAPACITY_EXCEEDED:
    'A equipe de destino já atingiu a capacidade planejada de vendedores.',
  SALESPERSON_TRANSFER_RPC_ERROR:
    'Não foi possível transferir o vendedor. Tente novamente.',
}

const KNOWN_ERROR_CODES = Object.keys(ERROR_MESSAGES).filter(
  (code) => code !== 'SALESPERSON_TRANSFER_RPC_ERROR',
) as Exclude<TeamTransferErrorCode, 'SALESPERSON_TRANSFER_RPC_ERROR'>[]

export interface TeamTransferRpcError {
  message: string
  details?: string | null
  hint?: string | null
  code?: string
}

export class TeamTransferServiceError extends Error {
  readonly code: TeamTransferErrorCode
  readonly originalError?: TeamTransferRpcError

  constructor(
    code: TeamTransferErrorCode,
    originalError?: TeamTransferRpcError,
  ) {
    super(ERROR_MESSAGES[code])
    this.name = 'TeamTransferServiceError'
    this.code = code
    this.originalError = originalError
  }
}

export interface TransferSalespersonTeamInput {
  organizationId: string
  organizationMemberId: string
  destinationTeamId: string
}

export interface TransferSalespersonTeamResponse {
  success: boolean
  organization_id: string
  organization_member_id: string
  source_team_id: string
  source_team_name: string
  destination_team_id: string
  destination_team_name: string
  previous_team_member_id: string
  new_team_member_id: string
  transferred_at: string
}

function mapRpcError(
  error: TeamTransferRpcError,
): TeamTransferServiceError {
  const haystack = [
    error.message,
    error.details,
    error.hint,
  ]
    .filter(Boolean)
    .join(' ')

  const knownCode = KNOWN_ERROR_CODES.find((code) =>
    haystack.includes(code),
  )

  return new TeamTransferServiceError(
    knownCode ?? 'SALESPERSON_TRANSFER_RPC_ERROR',
    error,
  )
}

export async function transferSalespersonTeam({
  organizationId,
  organizationMemberId,
  destinationTeamId,
}: TransferSalespersonTeamInput): Promise<TransferSalespersonTeamResponse> {
  const { data, error } = await supabase.rpc(
    'transfer_salesperson_team' as never,
    {
      p_organization_id: organizationId,
      p_organization_member_id: organizationMemberId,
      p_destination_team_id: destinationTeamId,
    } as never,
  )

  if (error) {
    throw mapRpcError(error)
  }

  if (!data) {
    throw new TeamTransferServiceError(
      'SALESPERSON_TRANSFER_RPC_ERROR',
      {
        code: 'EMPTY_RPC_RESPONSE',
        message:
          'RPC transfer_salesperson_team retornou uma resposta vazia.',
      },
    )
  }

  return data as TransferSalespersonTeamResponse
}
