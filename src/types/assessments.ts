export type AssessmentPurpose = 'diagnostic' | 'certification'

export type AssessmentDifficulty =
  | 'beginner'
  | 'beginner_intermediate'
  | 'intermediate'
  | 'intermediate_advanced'
  | 'advanced'

export type AssessmentAvailability =
  | 'available'
  | 'in_progress'
  | 'locked_prerequisite'
  | 'attempts_exhausted'
  | 'cooldown'

export type AssessmentAttemptStatus =
  | 'in_progress'
  | 'submitted'
  | 'graded'
  | 'cancelled'
  | 'expired'

export type AssessmentOptionCode = 'A' | 'B' | 'C' | 'D'

export type AssessmentResultReason =
  | 'critical_error'
  | 'overall_score_below_minimum'
  | 'legal_score_below_minimum'
  | 'diagnostic_completed'
  | 'approved'

export type AssessmentReviewPolicy =
  | 'immediate_after_grading'
  | 'after_pass_or_final_attempt'

export interface AvailableAssessment {
  test_id: string
  test_code: string
  sequence_no: number
  title: string
  description: string | null
  purpose: AssessmentPurpose
  difficulty: AssessmentDifficulty
  question_count: number
  time_limit_minutes: number | null
  max_attempts: number
  cooldown_hours: number
  version_id: string
  version_code: string
  passing_score: number
  legal_min_score: number
  prerequisites_met: boolean
  attempts_used: number
  in_progress_attempt_id: string | null
  last_graded_attempt_id: string | null
  last_attempt_status: AssessmentAttemptStatus | null
  last_attempt_passed: boolean | null
  next_attempt_at: string | null
  availability: AssessmentAvailability
}

export interface AvailableAssessmentsResponse {
  organization_id: string
  organization_member_id: string
  tests: AvailableAssessment[]
}

export interface AssessmentAttemptOption {
  code: AssessmentOptionCode
  text: string
}

export interface AssessmentAttemptItem {
  attempt_item_id: string
  position_no: number
  block_code: string
  prompt: string
  options: AssessmentAttemptOption[]
  selected_option_code: AssessmentOptionCode | null
  answered_at: string | null
}

export interface AssessmentAttempt {
  attempt_id: string
  organization_id: string
  test_id: string
  test_code: string
  test_title: string
  test_purpose: AssessmentPurpose
  version_id: string
  version_code: string
  attempt_no: number
  status: AssessmentAttemptStatus
  started_at: string
  expires_at: string | null
  submitted_at: string | null
  graded_at: string | null
  total_questions: number
  answered_questions: number
  passing_score: number
  legal_min_score: number
  items: AssessmentAttemptItem[]
}

export interface AssessmentAnswerSaved {
  attempt_id: string
  attempt_item_id: string
  selected_option_code: AssessmentOptionCode
  answered_questions: number
  total_questions: number
  saved_at: string
}

export interface AssessmentAttemptExpired {
  attempt_id: string
  status: 'expired'
  error_code: 'ATTEMPT_EXPIRED'
}

export type SaveAssessmentAnswerResponse =
  | AssessmentAnswerSaved
  | AssessmentAttemptExpired

export interface AssessmentCompetencyScore {
  competency_id: string
  competency_code: string
  competency_name: string
  is_legal: boolean
  questions_count: number
  correct_count: number
  score: number
  passed: boolean
}

export interface AssessmentReviewItem {
  position_no: number
  block_code: string
  prompt: string
  options: AssessmentAttemptOption[]
  selected_option_code: AssessmentOptionCode
  correct_option_code: AssessmentOptionCode
  is_correct: boolean
  is_critical_error: boolean
  justification: string | null
  source_reference: string | null
}

export interface AssessmentAttemptResult {
  attempt_id: string
  test_id: string
  test_code: string
  test_title: string
  test_purpose: AssessmentPurpose
  version_code: string
  attempt_no: number
  status: 'graded'
  submitted_at: string
  graded_at: string
  total_questions: number
  answered_questions: number
  correct_answers: number
  overall_score: number
  legal_score: number
  passing_score: number
  legal_min_score: number
  critical_errors: number
  passed: boolean
  result_reason: AssessmentResultReason
  competency_scores: AssessmentCompetencyScore[]
  review_available: boolean
  review_policy: AssessmentReviewPolicy
  review: AssessmentReviewItem[]
}

export type SubmitAssessmentAttemptResponse =
  | AssessmentAttemptResult
  | AssessmentAttemptExpired

export function isAssessmentAttemptExpired(
  value: SaveAssessmentAnswerResponse | SubmitAssessmentAttemptResponse,
): value is AssessmentAttemptExpired {
  return 'status' in value && value.status === 'expired'
}
