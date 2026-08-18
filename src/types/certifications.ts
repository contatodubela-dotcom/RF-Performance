export type CertificationMemberRole =
  | 'director'
  | 'supervisor'
  | 'salesperson'

export interface CertificationTeamContext {
  team_id: string
  team_name: string
  sales_location_id: string | null
  sales_location_name: string | null
}

export interface CertificationRecord {
  certification_id: string
  organization_member_id: string
  certification_level_id: string | null
  certification_program_id: string | null
  certification_program_version_id: string | null
  certificate_number: string
  certification_status: string
  issued_at: string | null
  valid_until: string | null
  revoked_at: string | null
  revocation_reason: string | null
  currently_valid: boolean
  program_code: string | null
  program_name: string | null
  program_description: string | null
  program_category: string | null
  program_display_order: number | null
  program_status: string | null
  version_code: string | null
  version_no: number | null
  version_name: string | null
  version_description: string | null
  version_status: string | null
  version_valid_from: string | null
  version_valid_until: string | null
}

export interface ManagedCertificationRow extends CertificationRecord {
  user_id: string
  member_name: string
  member_email: string
  member_role: CertificationMemberRole
  team_contexts: CertificationTeamContext[]
}
