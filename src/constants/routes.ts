export const ROUTES = {
  // Public
  LOGIN: '/login',
  RECOVER_PASSWORD: '/recuperar-senha',
  UPDATE_PASSWORD: '/atualizar-senha',

  // App
  APP: '/app',
  HOME: '/app/inicio',

  // Administration
  ORGANIZATIONS: '/app/organizacoes',
  OPERATIONS: '/app/operacoes',
  SALES_LOCATIONS: '/app/pdvs',
  TEAMS: '/app/equipes',
  USERS: '/app/usuarios',
  SETTINGS: '/app/configuracoes',

  // Gestão (future)
  PLAN_90_DAYS: '/app/plano-90-dias',
  GOALS: '/app/metas',
  RESULTS: '/app/resultados',
  ACTIONS: '/app/acoes',
  MEETINGS: '/app/reunioes',

  // Desenvolvimento (future)
  TRAINING: '/app/treinamentos',
  EVALUATIONS: '/app/avaliacoes',
  FEEDBACKS: '/app/feedbacks',

  // Análise (future)
  REPORTS: '/app/relatorios',
} as const

export type AppRoute = (typeof ROUTES)[keyof typeof ROUTES]
