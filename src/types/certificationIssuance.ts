export interface CertificationRequirementEvaluation {
  requirement_id: string
  certification_program_version_id: string
  requirement_group_id: string | null
  sequence_no: number
  requirement_type: string
  title: string
  is_required: boolean
  supported: boolean
  satisfied: boolean
  reason: string
  evidence_type: string | null
  evidence_id: string | null
  evidence: Record<string, unknown> | null
}

export interface CertificationRequirementGroupEvaluation {
  group_id: string
  certification_program_version_id: string
  sequence_no: number
  code: string
  name: string
  group_mode: 'all' | 'any' | 'at_least' | string
  minimum_required: number | null
  is_required: boolean
  requirements_total: number
  requirements_supported: number
  requirements_satisfied: number
  satisfied: boolean
  reason: string
  requirements: CertificationRequirementEvaluation[]
}

export interface CertificationIssuanceStateRow {
  certification_program_id: string
  program_code: string
  program_name: string
  program_description: string | null
  program_status: string
  program_display_order: number

  certification_program_version_id: string
  version_code: string
  version_no: number
  version_name: string
  version_description: string | null
  version_status: string
  version_valid_from: string | null
  version_valid_until: string | null

  participant_eligible: boolean
  program_active: boolean
  version_currently_valid: boolean
  requirements_satisfied: boolean
  required_units_total: number
  required_units_satisfied: number
  eligible_for_issuance: boolean
  issuance_reason: string
  requirements: CertificationRequirementEvaluation[]
  requirement_groups: CertificationRequirementGroupEvaluation[]

  active_member_certification_id: string | null
  active_certificate_number: string | null
  active_certification_issued_at: string | null
  active_certification_valid_until: string | null
  active_certification_currently_valid: boolean
}

export interface IssueCertificationInput {
  organizationId: string
  organizationMemberId: string
  certificationProgramVersionId: string
}

export interface IssueCertificationResponse {
  created: boolean
  outcome: 'ISSUED' | 'ALREADY_ACTIVE' | string
  organization_id: string
  organization_member_id: string
  certification_program_id: string
  requested_certification_program_version_id?: string
  certification_program_version_id: string
  member_certification_id: string
  certificate_number: string
  status: string
  issued_at: string | null
  valid_until: string | null
  evidence_count: number
  evaluation?: Record<string, unknown>
}
