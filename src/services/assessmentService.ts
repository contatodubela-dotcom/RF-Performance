import { supabase } from '@/lib/supabase'
import type {
  AssessmentAttempt,
  AssessmentAttemptResult,
  AssessmentOptionCode,
  AvailableAssessmentsResponse,
  ManagedAssessmentProgressRow,
  SaveAssessmentAnswerResponse,
  SubmitAssessmentAttemptResponse,
} from '@/types/assessments'

export type AssessmentErrorCode =
  | 'AUTH_REQUIRED'
  | 'ACTIVE_MEMBERSHIP_REQUIRED'
  | 'ASSESSMENT_NOT_PUBLISHED'
  | 'ASSESSMENT_PREREQUISITE_NOT_MET'
  | 'ASSESSMENT_ATTEMPTS_EXHAUSTED'
  | 'ASSESSMENT_COOLDOWN_ACTIVE'
  | 'ASSESSMENT_CATALOG_INTEGRITY_ERROR'
  | 'ASSESSMENT_SNAPSHOT_INTEGRITY_ERROR'
  | 'ATTEMPT_NOT_FOUND'
  | 'ATTEMPT_NOT_EDITABLE'
  | 'ATTEMPT_EXPIRED'
  | 'ATTEMPT_ITEM_OR_OPTION_NOT_FOUND'
  | 'ATTEMPT_NOT_GRADED'
  | 'ATTEMPT_NOT_SUBMITTABLE'
  | 'ALL_QUESTIONS_MUST_BE_ANSWERED'
  | 'ASSESSMENT_KEY_INTEGRITY_ERROR'
  | 'INVALID_OPTION_CODE'
  | 'ORGANIZATION_NOT_AVAILABLE'
  | 'ASSESSMENT_MANAGEMENT_FORBIDDEN'
  | 'ASSESSMENT_RPC_ERROR'

const ERROR_MESSAGES: Record<AssessmentErrorCode, string> = {
  AUTH_REQUIRED: 'Sua sessão expirou. Entre novamente para continuar.',
  ACTIVE_MEMBERSHIP_REQUIRED:
    'Seu usuário não possui vínculo ativo com esta organização.',
  ASSESSMENT_NOT_PUBLISHED: 'Esta avaliação ainda não está disponível.',
  ASSESSMENT_PREREQUISITE_NOT_MET:
    'Conclua os pré-requisitos antes de iniciar esta avaliação.',
  ASSESSMENT_ATTEMPTS_EXHAUSTED:
    'Você já utilizou todas as tentativas permitidas para esta avaliação.',
  ASSESSMENT_COOLDOWN_ACTIVE:
    'É necessário aguardar o intervalo definido antes de uma nova tentativa.',
  ASSESSMENT_CATALOG_INTEGRITY_ERROR:
    'A avaliação está temporariamente indisponível por inconsistência no catálogo.',
  ASSESSMENT_SNAPSHOT_INTEGRITY_ERROR:
    'Não foi possível preparar a avaliação com segurança.',
  ATTEMPT_NOT_FOUND: 'A tentativa informada não foi encontrada.',
  ATTEMPT_NOT_EDITABLE: 'Esta tentativa não aceita mais alterações.',
  ATTEMPT_EXPIRED: 'O prazo desta tentativa terminou.',
  ATTEMPT_ITEM_OR_OPTION_NOT_FOUND:
    'A questão ou alternativa selecionada não pertence a esta tentativa.',
  ATTEMPT_NOT_GRADED: 'O resultado desta tentativa ainda não está disponível.',
  ATTEMPT_NOT_SUBMITTABLE: 'Esta tentativa não pode ser entregue.',
  ALL_QUESTIONS_MUST_BE_ANSWERED:
    'Responda todas as questões antes de entregar a avaliação.',
  ASSESSMENT_KEY_INTEGRITY_ERROR:
    'A correção foi interrompida por uma inconsistência de segurança.',
  INVALID_OPTION_CODE: 'Selecione uma alternativa válida.',
  ORGANIZATION_NOT_AVAILABLE:
    'A organização selecionada não está disponível para esta consulta.',
  ASSESSMENT_MANAGEMENT_FORBIDDEN:
    'Seu perfil não possui permissão para acompanhar avaliações da equipe.',
  ASSESSMENT_RPC_ERROR:
    'Não foi possível concluir a operação de avaliação. Tente novamente.',
}

const KNOWN_ERROR_CODES = Object.keys(ERROR_MESSAGES).filter(
  (code) => code !== 'ASSESSMENT_RPC_ERROR',
) as Exclude<AssessmentErrorCode, 'ASSESSMENT_RPC_ERROR'>[]

export interface AssessmentRpcError {
  message: string
  details?: string | null
  hint?: string | null
  code?: string
}

export class AssessmentServiceError extends Error {
  readonly code: AssessmentErrorCode
  readonly originalError?: AssessmentRpcError

  constructor(
    code: AssessmentErrorCode,
    originalError?: AssessmentRpcError,
  ) {
    super(ERROR_MESSAGES[code])
    this.name = 'AssessmentServiceError'
    this.code = code
    this.originalError = originalError
  }
}

function mapRpcError(error: AssessmentRpcError): AssessmentServiceError {
  const haystack = [error.message, error.details, error.hint]
    .filter(Boolean)
    .join(' ')

  const knownCode = KNOWN_ERROR_CODES.find((code) => haystack.includes(code))

  return new AssessmentServiceError(
    knownCode ?? 'ASSESSMENT_RPC_ERROR',
    error,
  )
}

function requireRpcData<T>(data: unknown, rpcName: string): T {
  if (data === null || data === undefined) {
    throw new AssessmentServiceError('ASSESSMENT_RPC_ERROR', {
      code: 'EMPTY_RPC_RESPONSE',
      message: `RPC ${rpcName} retornou uma resposta vazia.`,
    })
  }

  return data as T
}

export async function getAvailableAssessments(
  organizationId: string,
): Promise<AvailableAssessmentsResponse> {
  const { data, error } = await supabase.rpc('get_available_assessments', {
    p_organization_id: organizationId,
  })

  if (error) throw mapRpcError(error)
  return requireRpcData<AvailableAssessmentsResponse>(
    data,
    'get_available_assessments',
  )
}

export async function startAssessmentAttempt(
  organizationId: string,
  testId: string,
): Promise<AssessmentAttempt> {
  const { data, error } = await supabase.rpc('start_assessment_attempt', {
    p_organization_id: organizationId,
    p_test_id: testId,
  })

  if (error) throw mapRpcError(error)
  return requireRpcData<AssessmentAttempt>(data, 'start_assessment_attempt')
}

export async function getAssessmentAttempt(
  attemptId: string,
): Promise<AssessmentAttempt> {
  const { data, error } = await supabase.rpc('get_assessment_attempt', {
    p_attempt_id: attemptId,
  })

  if (error) throw mapRpcError(error)
  return requireRpcData<AssessmentAttempt>(data, 'get_assessment_attempt')
}

export async function saveAssessmentAnswer(
  attemptId: string,
  attemptItemId: string,
  selectedOptionCode: AssessmentOptionCode,
): Promise<SaveAssessmentAnswerResponse> {
  const { data, error } = await supabase.rpc('save_assessment_answer', {
    p_attempt_id: attemptId,
    p_attempt_item_id: attemptItemId,
    p_selected_option_code: selectedOptionCode,
  })

  if (error) throw mapRpcError(error)
  return requireRpcData<SaveAssessmentAnswerResponse>(
    data,
    'save_assessment_answer',
  )
}

export async function submitAssessmentAttempt(
  attemptId: string,
): Promise<SubmitAssessmentAttemptResponse> {
  const { data, error } = await supabase.rpc('submit_assessment_attempt', {
    p_attempt_id: attemptId,
  })

  if (error) throw mapRpcError(error)
  return requireRpcData<SubmitAssessmentAttemptResponse>(
    data,
    'submit_assessment_attempt',
  )
}

export async function getAssessmentAttemptResult(
  attemptId: string,
): Promise<AssessmentAttemptResult> {
  const { data, error } = await supabase.rpc('get_assessment_attempt_result', {
    p_attempt_id: attemptId,
  })

  if (error) throw mapRpcError(error)
  return requireRpcData<AssessmentAttemptResult>(
    data,
    'get_assessment_attempt_result',
  )
}

export async function getManagedAssessmentProgress(
  organizationId: string,
): Promise<ManagedAssessmentProgressRow[]> {
  const { data, error } = await supabase.rpc('get_managed_assessment_progress', {
    p_organization_id: organizationId,
  })

  if (error) throw mapRpcError(error)
  return (data ?? []) as ManagedAssessmentProgressRow[]
}
