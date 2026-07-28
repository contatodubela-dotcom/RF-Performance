export type SetupStatus = 'pending_confirmation' | 'confirmed'

export interface SetupMetadata {
  template_record?: boolean
  template_key?: string
  setup_status?: SetupStatus
  data_origin?: 'template' | 'manual'
  confirmed_at?: string | null
  confirmed_by?: string | null
  presentation_order?: number
  planned_supervisor_positions?: number
  planned_salesperson_capacity?: number
  provisional_name?: boolean
}

export function getSetupMetadata(
  metadata: Record<string, unknown> | null | undefined,
): SetupMetadata {
  if (!metadata || typeof metadata !== 'object') return {}

  return metadata as SetupMetadata
}

export function isTemplateRecord(
  metadata: Record<string, unknown> | null | undefined,
): boolean {
  return getSetupMetadata(metadata).template_record === true
}

export function isSetupConfirmed(
  metadata: Record<string, unknown> | null | undefined,
): boolean {
  return getSetupMetadata(metadata).setup_status === 'confirmed'
}

export function getPlannedSalespersonCapacity(
  metadata: Record<string, unknown> | null | undefined,
): number {
  const value = getSetupMetadata(metadata).planned_salesperson_capacity
  return typeof value === 'number' && Number.isFinite(value) ? value : 0
}

export function getPlannedSupervisorPositions(
  metadata: Record<string, unknown> | null | undefined,
): number {
  const value = getSetupMetadata(metadata).planned_supervisor_positions
  return typeof value === 'number' && Number.isFinite(value) ? value : 0
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
