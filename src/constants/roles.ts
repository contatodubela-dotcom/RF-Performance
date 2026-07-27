import type { OrgRole, SystemRole } from '@/types/database'

export const SYSTEM_ROLES = {
  PLATFORM_ADMIN: 'platform_admin' as SystemRole,
} as const

export const ORG_ROLES = {
  DIRECTOR: 'director' as OrgRole,
  SUPERVISOR: 'supervisor' as OrgRole,
  SALESPERSON: 'salesperson' as OrgRole,
} as const

export const ROLE_LABELS: Record<string, string> = {
  platform_admin: 'Administrador da Plataforma',
  director: 'Diretor',
  supervisor: 'Supervisor',
  salesperson: 'Vendedor',
}

export const ROLE_DESCRIPTIONS: Record<string, string> = {
  platform_admin: 'Acesso total à plataforma e todas as organizações',
  director: 'Gerencia operações, equipes e usuários da organização',
  supervisor: 'Gerencia equipes e vendedores vinculados',
  salesperson: 'Acessa somente seus próprios dados e metas',
}

export const STATUS_LABELS: Record<string, string> = {
  active: 'Ativo',
  inactive: 'Inativo',
  archived: 'Arquivado',
}

export const OPERATION_TYPE_LABELS: Record<string, string> = {
  automotive_consortium: 'Consórcio de Automóveis',
  real_estate_consortium: 'Consórcio Imobiliário',
  motorcycle_consortium: 'Consórcio de Motos',
  services_consortium: 'Consórcio de Serviços',
}

export const LOCATION_TYPE_LABELS: Record<string, string> = {
  shopping_kiosk: 'Quiosque em Shopping',
  shopping_store: 'Loja em Shopping',
  street_store: 'Loja de Rua',
  office: 'Escritório',
  virtual: 'Virtual / Remoto',
}

export const SOURCE_SYSTEM_LABELS: Record<string, string> = {
  rf_performance: 'RF Performance',
  epsa_core: 'EPSA Core',
  mci_consorcio: 'MCI Consórcio',
  manual_import: 'Importação Manual',
  spreadsheet_import: 'Importação de Planilha',
  api: 'API',
}

export const BRAZILIAN_STATES = [
  'AC','AL','AP','AM','BA','CE','DF','ES','GO','MA','MT','MS','MG',
  'PA','PB','PR','PE','PI','RJ','RN','RS','RO','RR','SC','SP','SE','TO',
]
