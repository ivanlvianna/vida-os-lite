export type AuthorizationRole =
  | 'planner_owner'
  | 'internal_staff'
  | 'client_primary'
  | 'client_participant'
  | 'external_advisor'

export type AuthorizationScopeType = 'account' | 'engagement' | 'entity'

export type PlanningEngagementState =
  | 'onboarding_em_andamento'
  | 'dados_incompletos'
  | 'dados_completos'
  | 'diagnostico_em_elaboracao'
  | 'diagnostico_validado'
  | 'plano_em_elaboracao'
  | 'plano_aprovado'
  | 'implementacao'
  | 'acompanhamento'
  | 'revisao'
  | 'documentos_pendentes'
  | 'pausado'
  | 'encerrado_concluido'
  | 'encerrado_cancelado'
  | 'abandonado'

export type PlanningEventOrigin = 'system' | 'planner' | 'client' | 'external'
