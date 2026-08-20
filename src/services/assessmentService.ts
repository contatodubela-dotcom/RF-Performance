import { supabase } from '@/lib/supabase'
import type {
  AssessmentAccessAdminState,
  AssessmentAttempt,
  AssessmentAttemptResult,
  AssessmentOptionCode,
  AvailableAssessmentsResponse,
  ConfigureAssessmentAccessInput,
  ConfigureAssessmentAccessResponse,
  ManagedAssessmentProgressRow,
  ManagedPracticalAssessmentRequirement,
  RecordPracticalAssessmentInput,
  RecordPracticalAssessmentResponse,
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
  | 'ASSESSMENT_ACCESS_MANAGEMENT_FORBIDDEN'
  | 'ASSESSMENT_ACCESS_SCOPE_INVALID'
  | 'ASSESSMENT_MEMBER_REQUIRED'
  | 'ASSESSMENT_MEMBER_NOT_ALLOWED_FOR_ORGANIZATION_SCOPE'
  | 'ASSESSMENT_PARTICIPANT_NOT_ELIGIBLE'
  | 'PRACTICAL_ASSESSMENT_ORGANIZATION_REQUIRED'
  | 'PRACTICAL_ASSESSMENT_MEMBER_REQUIRED'
  | 'PRACTICAL_ASSESSMENT_MANAGEMENT_FORBIDDEN'
  | 'PRACTICAL_ASSESSMENT_SCORE_INVALID'
  | 'PRACTICAL_ASSESSMENT_CRITICAL_ERRORS_INVALID'
  | 'PRACTICAL_ASSESSMENT_CRITERIA_INVALID'
  | 'PRACTICAL_ASSESSMENT_EVIDENCE_INVALID'
  | 'PRACTICAL_ASSESSMENT_NOTES_TOO_LONG'
  | 'PRACTICAL_ASSESSMENT_PLATFORM_ADMIN_CANNOT_EVALUATE'
  | 'PRACTICAL_ASSESSMENT_EVALUATOR_ROLE_REQUIRED'
  | 'PRACTICAL_ASSESSMENT_TARGET_FORBIDDEN'
  | 'PRACTICAL_ASSESSMENT_TARGET_NOT_ELIGIBLE'
  | 'PRACTICAL_ASSESSMENT_TARGET_NOT_AVAILABLE'
  | 'PRACTICAL_ASSESSMENT_REQUIREMENT_REQUIRED'
  | 'PRACTICAL_ASSESSMENT_REQUIREMENT_NOT_AVAILABLE'
  | 'PRACTICAL_ASSESSMENT_PROGRAM_VERSION_NOT_AVAILABLE'
  | 'PRACTICAL_ASSESSMENT_TYPE_NOT_CONFIGURED'
  | 'PRACTICAL_ASSESSMENT_TYPE_UNSUPPORTED'
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
  ASSESSMENT_ACCESS_MANAGEMENT_FORBIDDEN:
    'Seu perfil não possui permissão para liberar ou revogar avaliações.',
  ASSESSMENT_ACCESS_SCOPE_INVALID:
    'O tipo de liberação informado não é válido.',
  ASSESSMENT_MEMBER_REQUIRED:
    'Selecione um participante para a liberação individual.',
  ASSESSMENT_MEMBER_NOT_ALLOWED_FOR_ORGANIZATION_SCOPE:
    'A liberação para a organização não pode indicar um participante específico.',
  ASSESSMENT_PARTICIPANT_NOT_ELIGIBLE:
    'O usuário selecionado não está elegível para participar das avaliações.',
  PRACTICAL_ASSESSMENT_ORGANIZATION_REQUIRED:
    'Selecione uma organização para registrar a avaliação prática.',
  PRACTICAL_ASSESSMENT_MEMBER_REQUIRED:
    'Selecione um participante para registrar a avaliação prática.',
  PRACTICAL_ASSESSMENT_MANAGEMENT_FORBIDDEN:
    'Seu perfil não possui permissão para consultar avaliações práticas deste participante.',
  PRACTICAL_ASSESSMENT_SCORE_INVALID:
    'Informe uma nota válida entre 0 e 100.',
  PRACTICAL_ASSESSMENT_CRITICAL_ERRORS_INVALID:
    'Informe uma quantidade válida de erros críticos.',
  PRACTICAL_ASSESSMENT_CRITERIA_INVALID:
    'Os critérios da avaliação prática estão em formato inválido.',
  PRACTICAL_ASSESSMENT_EVIDENCE_INVALID:
    'As evidências da avaliação prática estão em formato inválido.',
  PRACTICAL_ASSESSMENT_NOTES_TOO_LONG:
    'As observações da avaliação prática ultrapassam o limite permitido.',
  PRACTICAL_ASSESSMENT_PLATFORM_ADMIN_CANNOT_EVALUATE:
    'O Administrador da Plataforma acompanha a gestão, mas não atua como avaliador prático.',
  PRACTICAL_ASSESSMENT_EVALUATOR_ROLE_REQUIRED:
    'Somente Diretor ou Supervisor com vínculo ativo pode registrar avaliação prática.',
  PRACTICAL_ASSESSMENT_TARGET_FORBIDDEN:
    'O participante selecionado não está no seu escopo de gestão.',
  PRACTICAL_ASSESSMENT_TARGET_NOT_ELIGIBLE:
    'O participante selecionado não está elegível para o processo de avaliação.',
  PRACTICAL_ASSESSMENT_TARGET_NOT_AVAILABLE:
    'O participante selecionado não está disponível para esta avaliação.',
  PRACTICAL_ASSESSMENT_REQUIREMENT_REQUIRED:
    'Selecione um requisito prático para registrar a avaliação.',
  PRACTICAL_ASSESSMENT_REQUIREMENT_NOT_AVAILABLE:
    'O requisito prático selecionado não está disponível.',
  PRACTICAL_ASSESSMENT_PROGRAM_VERSION_NOT_AVAILABLE:
    'A versão do programa de certificação não está disponível.',
  PRACTICAL_ASSESSMENT_TYPE_NOT_CONFIGURED:
    'O tipo da avaliação prática não está configurado no requisito.',
  PRACTICAL_ASSESSMENT_TYPE_UNSUPPORTED:
    'O tipo da avaliação prática configurado não é suportado.',
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

export async function getAssessmentAccessAdminState(
  organizationId: string,
): Promise<AssessmentAccessAdminState> {
  const { data, error } = await supabase.rpc(
    'get_assessment_access_admin_state',
    {
      p_organization_id: organizationId,
    },
  )

  if (error) throw mapRpcError(error)
  return requireRpcData<AssessmentAccessAdminState>(
    data,
    'get_assessment_access_admin_state',
  )
}

export async function configureAssessmentAccess({
  organizationId,
  testId,
  accessScope,
  organizationMemberId,
  enabled,
  reason = null,
}: ConfigureAssessmentAccessInput): Promise<ConfigureAssessmentAccessResponse> {
  const { data, error } = await supabase.rpc('configure_assessment_access', {
    p_organization_id: organizationId,
    p_test_id: testId,
    p_access_scope: accessScope,
    p_organization_member_id: organizationMemberId,
    p_enabled: enabled,
    p_reason: reason,
  })

  if (error) throw mapRpcError(error)
  return requireRpcData<ConfigureAssessmentAccessResponse>(
    data,
    'configure_assessment_access',
  )
}

export async function getManagedPracticalAssessmentRequirements(
  organizationId: string,
  organizationMemberId: string,
): Promise<ManagedPracticalAssessmentRequirement[]> {
  const { data, error } = await supabase.rpc(
    'get_managed_practical_assessment_requirements',
    {
      p_organization_id: organizationId,
      p_organization_member_id: organizationMemberId,
    },
  )

  if (error) throw mapRpcError(error)
  return (data ?? []) as ManagedPracticalAssessmentRequirement[]
}

export async function recordPracticalAssessment({
  organizationId,
  organizationMemberId,
  certificationRequirementId,
  score,
  criticalErrors = 0,
  criteriaScores = {},
  notes = null,
  evidence = [],
}: RecordPracticalAssessmentInput): Promise<RecordPracticalAssessmentResponse> {
  const { data, error } = await supabase.rpc('record_practical_assessment', {
    p_organization_id: organizationId,
    p_organization_member_id: organizationMemberId,
    p_certification_requirement_id: certificationRequirementId,
    p_score: score,
    p_critical_errors: criticalErrors,
    p_criteria_scores: criteriaScores,
    p_notes: notes,
    p_evidence: evidence,
  })

  if (error) throw mapRpcError(error)
  return requireRpcData<RecordPracticalAssessmentResponse>(
    data,
    'record_practical_assessment',
  )
}

