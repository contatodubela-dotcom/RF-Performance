import { supabase } from '@/lib/supabase'

export type TeamSupervisorErrorCode =
  | 'AUTH_REQUIRED'
  | 'TEAM_SUPERVISOR_CHANGE_INVALID_INPUT'
  | 'TEAM_SUPERVISOR_CHANGE_FORBIDDEN'
  | 'TEAM_NOT_ACTIVE'
  | 'TEAM_SUPERVISOR_UNCHANGED'
  | 'NEW_SUPERVISOR_NOT_ACTIVE'
  | 'TEAM_SUPERVISOR_CHANGE_FAILED'
  | 'TEAM_SUPERVISOR_CHANGE_RPC_ERROR'

const ERROR_MESSAGES: Record<TeamSupervisorErrorCode, string> = {
  AUTH_REQUIRED:
    'Sua sessão expirou. Entre novamente para continuar.',

  TEAM_SUPERVISOR_CHANGE_INVALID_INPUT:
    'Os dados informados para a troca de supervisor são inválidos.',

  TEAM_SUPERVISOR_CHANGE_FORBIDDEN:
    'Seu perfil não possui permissão para trocar o supervisor da equipe.',

  TEAM_NOT_ACTIVE:
    'A equipe não está ativa ou não pertence a esta organização.',

  TEAM_SUPERVISOR_UNCHANGED:
    'O supervisor selecionado já é o supervisor atual desta equipe.',

  NEW_SUPERVISOR_NOT_ACTIVE:
    'O novo supervisor não está ativo ou não pertence a esta organização.',

  TEAM_SUPERVISOR_CHANGE_FAILED:
    'A troca de supervisor não pôde ser concluída.',

  TEAM_SUPERVISOR_CHANGE_RPC_ERROR:
    'Não foi possível trocar o supervisor da equipe. Tente novamente.',
}

const KNOWN_ERROR_CODES = Object.keys(ERROR_MESSAGES).filter(
  (code) => code !== 'TEAM_SUPERVISOR_CHANGE_RPC_ERROR',
) as Exclude<
  TeamSupervisorErrorCode,
  'TEAM_SUPERVISOR_CHANGE_RPC_ERROR'
>[]

export interface TeamSupervisorRpcError {
  message: string
  details?: string | null
  hint?: string | null
  code?: string
}

export class TeamSupervisorServiceError extends Error {
  readonly code: TeamSupervisorErrorCode
  readonly originalError?: TeamSupervisorRpcError

  constructor(
    code: TeamSupervisorErrorCode,
    originalError?: TeamSupervisorRpcError,
  ) {
    super(ERROR_MESSAGES[code])
    this.name = 'TeamSupervisorServiceError'
    this.code = code
    this.originalError = originalError
  }
}

export interface ChangeTeamSupervisorInput {
  organizationId: string
  teamId: string
  newSupervisorMemberId: string
}

export interface ChangeTeamSupervisorResponse {
  success: boolean
  organization_id: string
  team_id: string
  team_name: string
  previous_supervisor_member_id: string | null
  new_supervisor_member_id: string
  new_supervisor_user_id: string
  other_active_team_count: number
  supervisor_already_manages_other_teams: boolean
  changed_at: string
}

function mapRpcError(
  error: TeamSupervisorRpcError,
): TeamSupervisorServiceError {
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

  return new TeamSupervisorServiceError(
    knownCode ?? 'TEAM_SUPERVISOR_CHANGE_RPC_ERROR',
    error,
  )
}

export async function changeTeamSupervisor({
  organizationId,
  teamId,
  newSupervisorMemberId,
}: ChangeTeamSupervisorInput): Promise<ChangeTeamSupervisorResponse> {
  const { data, error } = await supabase.rpc(
    'change_team_supervisor' as never,
    {
      p_organization_id: organizationId,
      p_team_id: teamId,
      p_new_supervisor_member_id: newSupervisorMemberId,
    } as never,
  )

  if (error) {
    throw mapRpcError(error)
  }

  if (!data) {
    throw new TeamSupervisorServiceError(
      'TEAM_SUPERVISOR_CHANGE_RPC_ERROR',
      {
        code: 'EMPTY_RPC_RESPONSE',
        message:
          'RPC change_team_supervisor retornou uma resposta vazia.',
      },
    )
  }

  return data as ChangeTeamSupervisorResponse
}