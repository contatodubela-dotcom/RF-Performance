import { supabase } from '@/lib/supabase'

export type SalespersonPromotionErrorCode =
  | 'AUTH_REQUIRED'
  | 'SALESPERSON_PROMOTION_INVALID_INPUT'
  | 'SALESPERSON_PROMOTION_FORBIDDEN'
  | 'SALESPERSON_NOT_ACTIVE'
  | 'PROMOTION_TEAM_NOT_ACTIVE'
  | 'TEAM_SUPERVISOR_CHANGE_INVALID_INPUT'
  | 'TEAM_SUPERVISOR_CHANGE_FORBIDDEN'
  | 'TEAM_NOT_ACTIVE'
  | 'TEAM_SUPERVISOR_UNCHANGED'
  | 'NEW_SUPERVISOR_NOT_ACTIVE'
  | 'TEAM_SUPERVISOR_CHANGE_FAILED'
  | 'SALESPERSON_PROMOTION_RPC_ERROR'

const ERROR_MESSAGES: Record<SalespersonPromotionErrorCode, string> = {
  AUTH_REQUIRED:
    'Sua sessão expirou. Entre novamente para continuar.',
  SALESPERSON_PROMOTION_INVALID_INPUT:
    'Os dados informados para a promoção são inválidos.',
  SALESPERSON_PROMOTION_FORBIDDEN:
    'Seu perfil não possui permissão para promover vendedores.',
  SALESPERSON_NOT_ACTIVE:
    'O vendedor não está ativo ou já possui outro perfil.',
  PROMOTION_TEAM_NOT_ACTIVE:
    'A equipe selecionada não está ativa nesta organização.',
  TEAM_SUPERVISOR_CHANGE_INVALID_INPUT:
    'Os dados da equipe selecionada são inválidos.',
  TEAM_SUPERVISOR_CHANGE_FORBIDDEN:
    'Seu perfil não possui permissão para alterar o supervisor da equipe.',
  TEAM_NOT_ACTIVE:
    'A equipe selecionada não está ativa.',
  TEAM_SUPERVISOR_UNCHANGED:
    'O usuário já é o supervisor atual desta equipe.',
  NEW_SUPERVISOR_NOT_ACTIVE:
    'Não foi possível validar o novo supervisor.',
  TEAM_SUPERVISOR_CHANGE_FAILED:
    'A atribuição do supervisor à equipe não pôde ser concluída.',
  SALESPERSON_PROMOTION_RPC_ERROR:
    'Não foi possível promover o vendedor. Tente novamente.',
}

const KNOWN_CODES = Object.keys(ERROR_MESSAGES).filter(
  (code) => code !== 'SALESPERSON_PROMOTION_RPC_ERROR',
) as Exclude<SalespersonPromotionErrorCode, 'SALESPERSON_PROMOTION_RPC_ERROR'>[]

export class SalespersonPromotionServiceError extends Error {
  readonly code: SalespersonPromotionErrorCode
  readonly originalError?: {
    message: string
    details?: string | null
    hint?: string | null
    code?: string
  }

  constructor(
    code: SalespersonPromotionErrorCode,
    originalError?: {
      message: string
      details?: string | null
      hint?: string | null
      code?: string
    },
  ) {
    super(ERROR_MESSAGES[code])
    this.name = 'SalespersonPromotionServiceError'
    this.code = code
    this.originalError = originalError
  }
}

export interface PromoteSalespersonInput {
  organizationId: string
  organizationMemberId: string
  teamId?: string | null
}

export interface PromoteSalespersonResponse {
  success: boolean
  organization_id: string
  organization_member_id: string
  user_id: string
  profile_name: string | null
  previous_role: 'salesperson'
  new_role: 'supervisor'
  ended_salesperson_assignment_count: number
  assigned_team_id: string | null
  team_supervisor_change: {
    team_id?: string
    team_name?: string
    previous_supervisor_member_id?: string | null
    new_supervisor_member_id?: string
  } | null
  promoted_at: string
}

function mapRpcError(error: {
  message: string
  details?: string | null
  hint?: string | null
  code?: string
}) {
  const haystack = [error.message, error.details, error.hint]
    .filter(Boolean)
    .join(' ')

  const knownCode = KNOWN_CODES.find((code) => haystack.includes(code))

  return new SalespersonPromotionServiceError(
    knownCode ?? 'SALESPERSON_PROMOTION_RPC_ERROR',
    error,
  )
}

export async function promoteSalespersonToSupervisor({
  organizationId,
  organizationMemberId,
  teamId = null,
}: PromoteSalespersonInput): Promise<PromoteSalespersonResponse> {
  const { data, error } = await supabase.rpc(
    'promote_salesperson_to_supervisor' as never,
    {
      p_organization_id: organizationId,
      p_organization_member_id: organizationMemberId,
      p_team_id: teamId,
    } as never,
  )

  if (error) throw mapRpcError(error)

  if (!data) {
    throw new SalespersonPromotionServiceError(
      'SALESPERSON_PROMOTION_RPC_ERROR',
      {
        code: 'EMPTY_RPC_RESPONSE',
        message:
          'RPC promote_salesperson_to_supervisor retornou uma resposta vazia.',
      },
    )
  }

  return data as PromoteSalespersonResponse
}
