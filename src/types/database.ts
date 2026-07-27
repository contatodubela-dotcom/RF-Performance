// ================================================================
// RF Performance Comercial — Database Types
// Mirror of PostgreSQL schema
// ================================================================

export type SystemRole = 'platform_admin'
export type OrgRole = 'director' | 'supervisor' | 'salesperson'
export type RecordStatus = 'active' | 'inactive' | 'archived'
export type SourceSystem =
  | 'rf_performance'
  | 'epsa_core'
  | 'mci_consorcio'
  | 'manual_import'
  | 'spreadsheet_import'
  | 'api'

export interface Profile {
  id: string
  full_name: string
  preferred_name: string | null
  email: string | null
  phone: string | null
  avatar_url: string | null
  system_role: SystemRole | null
  status: 'active' | 'inactive'
  last_access_at: string | null
  created_at: string
  created_by: string | null
  updated_at: string
  updated_by: string | null
  archived_at: string | null
  metadata: Record<string, unknown>
}

export interface Organization {
  id: string
  legal_name: string | null
  trade_name: string
  slug: string
  document_number: string | null
  email: string | null
  phone: string | null
  logo_url: string | null
  status: RecordStatus
  external_id: string | null
  source_system: SourceSystem
  created_at: string
  created_by: string | null
  updated_at: string
  updated_by: string | null
  archived_at: string | null
  metadata: Record<string, unknown>
}

export interface OrganizationMember {
  id: string
  organization_id: string
  user_id: string
  role: OrgRole
  status: RecordStatus
  invited_at: string | null
  joined_at: string | null
  external_id: string | null
  source_system: SourceSystem
  created_at: string
  created_by: string | null
  updated_at: string
  updated_by: string | null
  archived_at: string | null
  metadata: Record<string, unknown>
}

export interface Operation {
  id: string
  organization_id: string
  name: string
  slug: string
  description: string | null
  operation_type: string | null
  status: RecordStatus
  external_id: string | null
  source_system: SourceSystem
  created_at: string
  created_by: string | null
  updated_at: string
  updated_by: string | null
  archived_at: string | null
  metadata: Record<string, unknown>
}

export interface SalesLocation {
  id: string
  organization_id: string
  operation_id: string
  name: string
  slug: string
  location_type: string
  shopping_name: string | null
  address_line: string | null
  city: string | null
  state_code: string | null
  timezone: string
  status: RecordStatus
  external_id: string | null
  source_system: SourceSystem
  created_at: string
  created_by: string | null
  updated_at: string
  updated_by: string | null
  archived_at: string | null
  metadata: Record<string, unknown>
}

export interface Team {
  id: string
  organization_id: string
  operation_id: string
  sales_location_id: string | null
  name: string
  description: string | null
  supervisor_member_id: string | null
  status: RecordStatus
  external_id: string | null
  source_system: SourceSystem
  created_at: string
  created_by: string | null
  updated_at: string
  updated_by: string | null
  archived_at: string | null
  metadata: Record<string, unknown>
}

export interface TeamMember {
  id: string
  organization_id: string
  team_id: string
  organization_member_id: string
  membership_type: string
  start_at: string | null
  end_at: string | null
  status: RecordStatus
  created_at: string
  created_by: string | null
  updated_at: string
  updated_by: string | null
  archived_at: string | null
  metadata: Record<string, unknown>
}

export interface AuditLog {
  id: string
  organization_id: string | null
  user_id: string | null
  action: string
  entity_type: string
  entity_id: string | null
  old_values: Record<string, unknown> | null
  new_values: Record<string, unknown> | null
  created_at: string
}

// ---- Extended types with relations ----

export interface OrganizationMemberWithProfile extends OrganizationMember {
  profile?: Profile
}

export interface TeamWithRelations extends Team {
  sales_location?: SalesLocation
  supervisor_member?: OrganizationMemberWithProfile
  member_count?: number
}

export interface TeamMemberWithRelations extends TeamMember {
  organization_member?: OrganizationMemberWithProfile
}
