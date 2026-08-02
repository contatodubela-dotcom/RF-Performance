export type SetupStatus =
  | 'pending_confirmation'
  | 'confirmed'
  | 'operational_structure_confirmed'

export type DataOrigin =
  | 'template'
  | 'manual'
  | 'meeting_validation'

export interface MaturityCurvePoint {
  month: number
  sales_per_producer: number
  full_capacity_sales: number
}

export interface SetupMetadata {
  template_record?: boolean
  template_key?: string
  setup_template?: string
  setup_status?: SetupStatus
  data_origin?: DataOrigin
  structure_source?: string

  confirmed_at?: string | null
  confirmed_by?: string | null
  structure_confirmed_at?: string | null

  presentation_order?: number
  provisional_name?: boolean

  administrator_code?: string
  administrator_name?: string
  shopping_group_code?: string
  shopping_name_confirmation_pending?: boolean

  confirmed_supervisor_name?: string
  confirmed_supervisor_account_pending?: boolean
  confirmed_salesperson_names?: string[]

  confirmed_active_supervisors?: number
  confirmed_active_salespersons?: number
  confirmed_active_producers?: number

  planned_location_capacity?: number
  planned_team_capacity?: number
  planned_supervisor_capacity?: number
  planned_supervisor_positions?: number
  planned_salesperson_capacity?: number
  planned_producer_capacity?: number

  vacant_salesperson_positions?: number
  vacancy_fill_target_date?: string | null

  minimum_monthly_sales_per_producer?: number
  adjusted_monthly_capacity_reference?: number
  full_monthly_capacity_reference?: number

  baseline_monthly_sales?: number
  growth_target_percent?: number
  target_monthly_sales?: number

  shopping_center_count?: number
  consortium_administrator_count?: number
  consortium_administrators?: string[]

  next_supervisors_alignment_date?: string
  goal_distribution_status?: string
  maturity_curve?: MaturityCurvePoint[]
}

export function getSetupMetadata(
  metadata: Record<string, unknown> | null | undefined,
): SetupMetadata {
  if (!metadata || typeof metadata !== 'object') {
    return {}
  }

  return metadata as SetupMetadata
}

function getNumericMetadataValue(
  metadata: Record<string, unknown> | null | undefined,
  key: keyof SetupMetadata,
): number {
  const value = getSetupMetadata(metadata)[key]

  return typeof value === 'number' && Number.isFinite(value)
    ? value
    : 0
}

export function isTemplateRecord(
  metadata: Record<string, unknown> | null | undefined,
): boolean {
  return getSetupMetadata(metadata).template_record === true
}

export function isSetupConfirmed(
  metadata: Record<string, unknown> | null | undefined,
): boolean {
  const status = getSetupMetadata(metadata).setup_status

  return (
    status === 'confirmed' ||
    status === 'operational_structure_confirmed'
  )
}

export function getPlannedLocationCapacity(
  metadata: Record<string, unknown> | null | undefined,
): number {
  return getNumericMetadataValue(
    metadata,
    'planned_location_capacity',
  )
}

export function getPlannedTeamCapacity(
  metadata: Record<string, unknown> | null | undefined,
): number {
  return getNumericMetadataValue(
    metadata,
    'planned_team_capacity',
  )
}

export function getPlannedSalespersonCapacity(
  metadata: Record<string, unknown> | null | undefined,
): number {
  return getNumericMetadataValue(
    metadata,
    'planned_salesperson_capacity',
  )
}

export function getPlannedSupervisorCapacity(
  metadata: Record<string, unknown> | null | undefined,
): number {
  return getNumericMetadataValue(
    metadata,
    'planned_supervisor_capacity',
  )
}

export function getPlannedSupervisorPositions(
  metadata: Record<string, unknown> | null | undefined,
): number {
  return getNumericMetadataValue(
    metadata,
    'planned_supervisor_positions',
  )
}

export function getPlannedProducerCapacity(
  metadata: Record<string, unknown> | null | undefined,
): number {
  return getNumericMetadataValue(
    metadata,
    'planned_producer_capacity',
  )
}

export function getConfirmedActiveSupervisors(
  metadata: Record<string, unknown> | null | undefined,
): number {
  return getNumericMetadataValue(
    metadata,
    'confirmed_active_supervisors',
  )
}

export function getConfirmedActiveSalespersons(
  metadata: Record<string, unknown> | null | undefined,
): number {
  return getNumericMetadataValue(
    metadata,
    'confirmed_active_salespersons',
  )
}

export function getConfirmedActiveProducers(
  metadata: Record<string, unknown> | null | undefined,
): number {
  return getNumericMetadataValue(
    metadata,
    'confirmed_active_producers',
  )
}

export function getVacantSalespersonPositions(
  metadata: Record<string, unknown> | null | undefined,
): number {
  return getNumericMetadataValue(
    metadata,
    'vacant_salesperson_positions',
  )
}

export function getMinimumMonthlySalesPerProducer(
  metadata: Record<string, unknown> | null | undefined,
): number {
  return getNumericMetadataValue(
    metadata,
    'minimum_monthly_sales_per_producer',
  )
}

export function getAdjustedMonthlyCapacityReference(
  metadata: Record<string, unknown> | null | undefined,
): number {
  return getNumericMetadataValue(
    metadata,
    'adjusted_monthly_capacity_reference',
  )
}

export function getFullMonthlyCapacityReference(
  metadata: Record<string, unknown> | null | undefined,
): number {
  return getNumericMetadataValue(
    metadata,
    'full_monthly_capacity_reference',
  )
}

export function getBaselineMonthlySales(
  metadata: Record<string, unknown> | null | undefined,
): number {
  return getNumericMetadataValue(
    metadata,
    'baseline_monthly_sales',
  )
}

export function getGrowthTargetPercent(
  metadata: Record<string, unknown> | null | undefined,
): number {
  return getNumericMetadataValue(
    metadata,
    'growth_target_percent',
  )
}

export function getTargetMonthlySales(
  metadata: Record<string, unknown> | null | undefined,
): number {
  return getNumericMetadataValue(
    metadata,
    'target_monthly_sales',
  )
}

export function getConfirmedSupervisorName(
  metadata: Record<string, unknown> | null | undefined,
): string | null {
  const value =
    getSetupMetadata(metadata).confirmed_supervisor_name

  return typeof value === 'string' && value.trim()
    ? value.trim()
    : null
}

export function getConfirmedSalespersonNames(
  metadata: Record<string, unknown> | null | undefined,
): string[] {
  const value =
    getSetupMetadata(metadata).confirmed_salesperson_names

  if (!Array.isArray(value)) {
    return []
  }

  return value.filter(
    (name): name is string =>
      typeof name === 'string' && name.trim().length > 0,
  )
}

export function getMaturityCurve(
  metadata: Record<string, unknown> | null | undefined,
): MaturityCurvePoint[] {
  const value = getSetupMetadata(metadata).maturity_curve

  if (!Array.isArray(value)) {
    return []
  }

  return value.filter(
    (point): point is MaturityCurvePoint =>
      typeof point === 'object' &&
      point !== null &&
      typeof point.month === 'number' &&
      Number.isFinite(point.month) &&
      typeof point.sales_per_producer === 'number' &&
      Number.isFinite(point.sales_per_producer) &&
      typeof point.full_capacity_sales === 'number' &&
      Number.isFinite(point.full_capacity_sales),
  )
}

export function updateSetupMetadata(
  current: Record<string, unknown> | null | undefined,
  options: {
    confirmed: boolean
    userId?: string | null
    plannedSalespersonCapacity?: number
    plannedSupervisorPositions?: number
  },
): Record<string, unknown> {
  const now = new Date().toISOString()

  return {
    ...(current ?? {}),
    setup_status: options.confirmed
      ? 'confirmed'
      : 'pending_confirmation',
    data_origin:
      getSetupMetadata(current).data_origin ?? 'manual',
    confirmed_at: options.confirmed ? now : null,
    confirmed_by: options.confirmed
      ? options.userId ?? null
      : null,
    provisional_name: !options.confirmed,
    ...(options.plannedSalespersonCapacity !== undefined
      ? {
          planned_salesperson_capacity:
            options.plannedSalespersonCapacity,
        }
      : {}),
    ...(options.plannedSupervisorPositions !== undefined
      ? {
          planned_supervisor_positions:
            options.plannedSupervisorPositions,
        }
      : {}),
  }
}