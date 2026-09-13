export type Json =
  | string
  | number
  | boolean
  | null
  | { [key: string]: Json | undefined }
  | Json[]

export type Database = {
  // Allows to automatically instantiate createClient with right options
  // instead of createClient<Database, { PostgrestVersion: 'XX' }>(URL, KEY)
  __InternalSupabase: {
    PostgrestVersion: "14.5"
  }
  public: {
    Tables: {
      client_account_entities: {
        Row: {
          client_account_id: string
          created_at: string
          economic_entity_id: string
        }
        Insert: {
          client_account_id: string
          created_at?: string
          economic_entity_id: string
        }
        Update: {
          client_account_id?: string
          created_at?: string
          economic_entity_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "client_account_entities_client_account_id_fkey"
            columns: ["client_account_id"]
            isOneToOne: false
            referencedRelation: "client_accounts"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "client_account_entities_economic_entity_id_fkey"
            columns: ["economic_entity_id"]
            isOneToOne: false
            referencedRelation: "economic_entities"
            referencedColumns: ["id"]
          },
        ]
      }
      client_account_users: {
        Row: {
          auth_user_id: string
          client_account_id: string
          created_at: string
        }
        Insert: {
          auth_user_id: string
          client_account_id: string
          created_at?: string
        }
        Update: {
          auth_user_id?: string
          client_account_id?: string
          created_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "client_account_users_client_account_id_fkey"
            columns: ["client_account_id"]
            isOneToOne: false
            referencedRelation: "client_accounts"
            referencedColumns: ["id"]
          },
        ]
      }
      client_accounts: {
        Row: {
          created_at: string
          id: string
        }
        Insert: {
          created_at?: string
          id?: string
        }
        Update: {
          created_at?: string
          id?: string
        }
        Relationships: []
      }
      diagnosticos: {
        Row: {
          capital_decisorio: Json | null
          created_at: string | null
          id: string
          mecanismo_dominante: string | null
          narrativa: string | null
          perfil_identificado: string | null
          raw_json: Json | null
          scanner_nome: string | null
          scores: Json | null
          user_id: string
        }
        Insert: {
          capital_decisorio?: Json | null
          created_at?: string | null
          id?: string
          mecanismo_dominante?: string | null
          narrativa?: string | null
          perfil_identificado?: string | null
          raw_json?: Json | null
          scanner_nome?: string | null
          scores?: Json | null
          user_id: string
        }
        Update: {
          capital_decisorio?: Json | null
          created_at?: string | null
          id?: string
          mecanismo_dominante?: string | null
          narrativa?: string | null
          perfil_identificado?: string | null
          raw_json?: Json | null
          scanner_nome?: string | null
          scores?: Json | null
          user_id?: string
        }
        Relationships: []
      }
      diagnosticos_vida: {
        Row: {
          created_at: string
          external_id: string
          id: string
          instrumento: string
          link_relatorio: string | null
          perfil: string | null
          processado_em: string | null
          score: number | null
          status: string
          updated_at: string
          user_id: string
        }
        Insert: {
          created_at?: string
          external_id: string
          id?: string
          instrumento: string
          link_relatorio?: string | null
          perfil?: string | null
          processado_em?: string | null
          score?: number | null
          status?: string
          updated_at?: string
          user_id: string
        }
        Update: {
          created_at?: string
          external_id?: string
          id?: string
          instrumento?: string
          link_relatorio?: string | null
          perfil?: string | null
          processado_em?: string | null
          score?: number | null
          status?: string
          updated_at?: string
          user_id?: string
        }
        Relationships: []
      }
      economic_entities: {
        Row: {
          created_at: string
          display_name: string
          entity_type: string
          id: string
        }
        Insert: {
          created_at?: string
          display_name: string
          entity_type: string
          id?: string
        }
        Update: {
          created_at?: string
          display_name?: string
          entity_type?: string
          id?: string
        }
        Relationships: []
      }
      entity_relationships: {
        Row: {
          created_at: string
          from_entity_id: string
          id: string
          relationship_type: string
          to_entity_id: string
        }
        Insert: {
          created_at?: string
          from_entity_id: string
          id?: string
          relationship_type: string
          to_entity_id: string
        }
        Update: {
          created_at?: string
          from_entity_id?: string
          id?: string
          relationship_type?: string
          to_entity_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "entity_relationships_from_entity_id_fkey"
            columns: ["from_entity_id"]
            isOneToOne: false
            referencedRelation: "economic_entities"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "entity_relationships_to_entity_id_fkey"
            columns: ["to_entity_id"]
            isOneToOne: false
            referencedRelation: "economic_entities"
            referencedColumns: ["id"]
          },
        ]
      }
      hotmart_integration_config: {
        Row: {
          key: string
          secret_value: string
          updated_at: string
        }
        Insert: {
          key: string
          secret_value: string
          updated_at?: string
        }
        Update: {
          key?: string
          secret_value?: string
          updated_at?: string
        }
        Relationships: []
      }
      hotmart_products: {
        Row: {
          delivery_asset: string | null
          delivery_type: string
          id: string
          name: string
          net_revenue_cents: number
          sales_count: number
          status: string
          updated_at: string
        }
        Insert: {
          delivery_asset?: string | null
          delivery_type: string
          id: string
          name: string
          net_revenue_cents?: number
          sales_count?: number
          status?: string
          updated_at?: string
        }
        Update: {
          delivery_asset?: string | null
          delivery_type?: string
          id?: string
          name?: string
          net_revenue_cents?: number
          sales_count?: number
          status?: string
          updated_at?: string
        }
        Relationships: []
      }
      hotmart_purchases: {
        Row: {
          access_status: string
          buyer_email: string | null
          buyer_name: string | null
          completed_at: string | null
          delivery_status: string
          first_access_at: string | null
          gross_cents: number | null
          net_cents: number | null
          product_id: string
          product_name: string
          purchase_status: string
          purchased_at: string | null
          transaction_id: string
          updated_at: string
        }
        Insert: {
          access_status?: string
          buyer_email?: string | null
          buyer_name?: string | null
          completed_at?: string | null
          delivery_status?: string
          first_access_at?: string | null
          gross_cents?: number | null
          net_cents?: number | null
          product_id: string
          product_name: string
          purchase_status: string
          purchased_at?: string | null
          transaction_id: string
          updated_at?: string
        }
        Update: {
          access_status?: string
          buyer_email?: string | null
          buyer_name?: string | null
          completed_at?: string | null
          delivery_status?: string
          first_access_at?: string | null
          gross_cents?: number | null
          net_cents?: number | null
          product_id?: string
          product_name?: string
          purchase_status?: string
          purchased_at?: string | null
          transaction_id?: string
          updated_at?: string
        }
        Relationships: []
      }
      hotmart_webhook_events: {
        Row: {
          accepted: boolean
          event_id: string
          event_type: string
          product_id: string | null
          raw_payload: Json
          received_at: string
          transaction_id: string | null
        }
        Insert: {
          accepted?: boolean
          event_id: string
          event_type: string
          product_id?: string | null
          raw_payload: Json
          received_at?: string
          transaction_id?: string | null
        }
        Update: {
          accepted?: boolean
          event_id?: string
          event_type?: string
          product_id?: string | null
          raw_payload?: Json
          received_at?: string
          transaction_id?: string | null
        }
        Relationships: []
      }
      prontuario_patrimonial: {
        Row: {
          campo: string | null
          created_at: string | null
          dados: Json | null
          id: string
          secao: string | null
          updated_at: string | null
          user_id: string
          valor: string | null
        }
        Insert: {
          campo?: string | null
          created_at?: string | null
          dados?: Json | null
          id?: string
          secao?: string | null
          updated_at?: string | null
          user_id: string
          valor?: string | null
        }
        Update: {
          campo?: string | null
          created_at?: string | null
          dados?: Json | null
          id?: string
          secao?: string | null
          updated_at?: string | null
          user_id?: string
          valor?: string | null
        }
        Relationships: []
      }
      reconciliation_record: {
        Row: {
          decided_by: string
          decided_note: string | null
          economic_entity_id: string | null
          id: string
          reconciliation_source_id: string
          recorded_at: string
          result: string
          supersedes_reconciliation_record_id: string | null
        }
        Insert: {
          decided_by: string
          decided_note?: string | null
          economic_entity_id?: string | null
          id?: string
          reconciliation_source_id: string
          recorded_at: string
          result: string
          supersedes_reconciliation_record_id?: string | null
        }
        Update: {
          decided_by?: string
          decided_note?: string | null
          economic_entity_id?: string | null
          id?: string
          reconciliation_source_id?: string
          recorded_at?: string
          result?: string
          supersedes_reconciliation_record_id?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "reconciliation_record_economic_entity_id_fkey"
            columns: ["economic_entity_id"]
            isOneToOne: false
            referencedRelation: "economic_entities"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "reconciliation_record_reconciliation_source_id_fkey"
            columns: ["reconciliation_source_id"]
            isOneToOne: false
            referencedRelation: "reconciliation_source"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "reconciliation_record_supersedes_reconciliation_record_id_fkey"
            columns: ["supersedes_reconciliation_record_id"]
            isOneToOne: true
            referencedRelation: "reconciliation_record"
            referencedColumns: ["id"]
          },
        ]
      }
      reconciliation_source: {
        Row: {
          created_at: string
          id: string
          source_namespace: string
          source_value: string
        }
        Insert: {
          created_at?: string
          id?: string
          source_namespace: string
          source_value: string
        }
        Update: {
          created_at?: string
          id?: string
          source_namespace?: string
          source_value?: string
        }
        Relationships: []
      }
      scanner_vida_empresa_submissions: {
        Row: {
          blindagem_juridica: number | null
          consentimento_dados: boolean
          consentimento_marketing: boolean
          continuidade_financeira: number | null
          created_at: string
          dependencia_operacional: number | null
          email: string | null
          fase: string | null
          faturamento: string | null
          id: string
          indice_vida_empresa: number | null
          ip_hash: string | null
          nome: string
          origem: string
          pagina_origem: string | null
          pergunta_atual: number | null
          respostas: Json
          stage: string
          submission_id: string
          updated_at: string
          user_agent: string | null
          versao_consentimento: string
          whatsapp: string
        }
        Insert: {
          blindagem_juridica?: number | null
          consentimento_dados: boolean
          consentimento_marketing?: boolean
          continuidade_financeira?: number | null
          created_at?: string
          dependencia_operacional?: number | null
          email?: string | null
          fase?: string | null
          faturamento?: string | null
          id?: string
          indice_vida_empresa?: number | null
          ip_hash?: string | null
          nome: string
          origem?: string
          pagina_origem?: string | null
          pergunta_atual?: number | null
          respostas?: Json
          stage: string
          submission_id: string
          updated_at?: string
          user_agent?: string | null
          versao_consentimento: string
          whatsapp: string
        }
        Update: {
          blindagem_juridica?: number | null
          consentimento_dados?: boolean
          consentimento_marketing?: boolean
          continuidade_financeira?: number | null
          created_at?: string
          dependencia_operacional?: number | null
          email?: string | null
          fase?: string | null
          faturamento?: string | null
          id?: string
          indice_vida_empresa?: number | null
          ip_hash?: string | null
          nome?: string
          origem?: string
          pagina_origem?: string | null
          pergunta_atual?: number | null
          respostas?: Json
          stage?: string
          submission_id?: string
          updated_at?: string
          user_agent?: string | null
          versao_consentimento?: string
          whatsapp?: string
        }
        Relationships: []
      }
      users_profile: {
        Row: {
          created_at: string | null
          data_nascimento: string | null
          email: string | null
          estado_civil: string | null
          faixa_patrimonio: string | null
          id: string
          lgpd_aceito: boolean
          nome_completo: string | null
          numero_dependentes: number | null
          onboarding_concluido: boolean | null
          origin_lead: string | null
          possui_empresa: boolean | null
          possui_imoveis: boolean | null
          profissao: string | null
          telefone_whatsapp: string
          termos_aceito: boolean
          updated_at: string | null
        }
        Insert: {
          created_at?: string | null
          data_nascimento?: string | null
          email?: string | null
          estado_civil?: string | null
          faixa_patrimonio?: string | null
          id: string
          lgpd_aceito?: boolean
          nome_completo?: string | null
          numero_dependentes?: number | null
          onboarding_concluido?: boolean | null
          origin_lead?: string | null
          possui_empresa?: boolean | null
          possui_imoveis?: boolean | null
          profissao?: string | null
          telefone_whatsapp?: string
          termos_aceito?: boolean
          updated_at?: string | null
        }
        Update: {
          created_at?: string | null
          data_nascimento?: string | null
          email?: string | null
          estado_civil?: string | null
          faixa_patrimonio?: string | null
          id?: string
          lgpd_aceito?: boolean
          nome_completo?: string | null
          numero_dependentes?: number | null
          onboarding_concluido?: boolean | null
          origin_lead?: string | null
          possui_empresa?: boolean | null
          possui_imoveis?: boolean | null
          profissao?: string | null
          telefone_whatsapp?: string
          termos_aceito?: boolean
          updated_at?: string | null
        }
        Relationships: []
      }
      vida_public_submissions: {
        Row: {
          answers: Json
          client_computed: boolean
          consentimento_dados: boolean
          consentimento_marketing: boolean
          created_at: string
          email: string | null
          id: string
          instrument: string
          ip_hash: string | null
          nome: string
          pagina_origem: string | null
          result: Json
          stage: string
          submission_id: string
          updated_at: string
          user_agent: string | null
          versao_consentimento: string
          whatsapp: string | null
        }
        Insert: {
          answers?: Json
          client_computed?: boolean
          consentimento_dados: boolean
          consentimento_marketing?: boolean
          created_at?: string
          email?: string | null
          id?: string
          instrument: string
          ip_hash?: string | null
          nome: string
          pagina_origem?: string | null
          result?: Json
          stage?: string
          submission_id: string
          updated_at?: string
          user_agent?: string | null
          versao_consentimento: string
          whatsapp?: string | null
        }
        Update: {
          answers?: Json
          client_computed?: boolean
          consentimento_dados?: boolean
          consentimento_marketing?: boolean
          created_at?: string
          email?: string | null
          id?: string
          instrument?: string
          ip_hash?: string | null
          nome?: string
          pagina_origem?: string | null
          result?: Json
          stage?: string
          submission_id?: string
          updated_at?: string
          user_agent?: string | null
          versao_consentimento?: string
          whatsapp?: string | null
        }
        Relationships: []
      }
    }
    Views: {
      [_ in never]: never
    }
    Functions: {
      canonical_reconcile: {
        Args: {
          p_decided_by: string
          p_decided_note?: string
          p_decision: string
          p_deliberate_revision?: boolean
          p_display_name?: string
          p_economic_entity_id?: string
          p_entity_type?: string
          p_record_id: string
          p_source_namespace: string
          p_source_value_raw: string
        }
        Returns: {
          decided_by: string
          decided_note: string | null
          economic_entity_id: string | null
          id: string
          reconciliation_source_id: string
          recorded_at: string
          result: string
          supersedes_reconciliation_record_id: string | null
        }
        SetofOptions: {
          from: "*"
          to: "reconciliation_record"
          isOneToOne: true
          isSetofReturn: false
        }
      }
      canonical_reconciliation: {
        Args: { p_knowledge_as_of: string; p_source_id: string }
        Returns: {
          decided_by: string
          decided_note: string | null
          economic_entity_id: string | null
          id: string
          reconciliation_source_id: string
          recorded_at: string
          result: string
          supersedes_reconciliation_record_id: string | null
        }
        SetofOptions: {
          from: "*"
          to: "reconciliation_record"
          isOneToOne: true
          isSetofReturn: false
        }
      }
      canonical_rollback_guard: { Args: never; Returns: undefined }
      vida_auth_user_exists: { Args: { p_user_id: string }; Returns: boolean }
    }
    Enums: {
      [_ in never]: never
    }
    CompositeTypes: {
      [_ in never]: never
    }
  }
}

type DatabaseWithoutInternals = Omit<Database, "__InternalSupabase">

type DefaultSchema = DatabaseWithoutInternals[Extract<keyof Database, "public">]

export type Tables<
  DefaultSchemaTableNameOrOptions extends
    | keyof (DefaultSchema["Tables"] & DefaultSchema["Views"])
    | { schema: keyof DatabaseWithoutInternals },
  TableName extends (DefaultSchemaTableNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof (DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"] &
        DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Views"])
    : never) = never,
> = DefaultSchemaTableNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? (DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"] &
      DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Views"])[TableName] extends {
      Row: infer R
    }
    ? R
    : never
  : DefaultSchemaTableNameOrOptions extends keyof (DefaultSchema["Tables"] &
        DefaultSchema["Views"])
    ? (DefaultSchema["Tables"] &
        DefaultSchema["Views"])[DefaultSchemaTableNameOrOptions] extends {
        Row: infer R
      }
      ? R
      : never
    : never

export type TablesInsert<
  DefaultSchemaTableNameOrOptions extends
    | keyof DefaultSchema["Tables"]
    | { schema: keyof DatabaseWithoutInternals },
  TableName extends (DefaultSchemaTableNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"]
    : never) = never,
> = DefaultSchemaTableNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"][TableName] extends {
      Insert: infer I
    }
    ? I
    : never
  : DefaultSchemaTableNameOrOptions extends keyof DefaultSchema["Tables"]
    ? DefaultSchema["Tables"][DefaultSchemaTableNameOrOptions] extends {
        Insert: infer I
      }
      ? I
      : never
    : never

export type TablesUpdate<
  DefaultSchemaTableNameOrOptions extends
    | keyof DefaultSchema["Tables"]
    | { schema: keyof DatabaseWithoutInternals },
  TableName extends (DefaultSchemaTableNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"]
    : never) = never,
> = DefaultSchemaTableNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"][TableName] extends {
      Update: infer U
    }
    ? U
    : never
  : DefaultSchemaTableNameOrOptions extends keyof DefaultSchema["Tables"]
    ? DefaultSchema["Tables"][DefaultSchemaTableNameOrOptions] extends {
        Update: infer U
      }
      ? U
      : never
    : never

export type Enums<
  DefaultSchemaEnumNameOrOptions extends
    | keyof DefaultSchema["Enums"]
    | { schema: keyof DatabaseWithoutInternals },
  EnumName extends (DefaultSchemaEnumNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof DatabaseWithoutInternals[DefaultSchemaEnumNameOrOptions["schema"]]["Enums"]
    : never) = never,
> = DefaultSchemaEnumNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? DatabaseWithoutInternals[DefaultSchemaEnumNameOrOptions["schema"]]["Enums"][EnumName]
  : DefaultSchemaEnumNameOrOptions extends keyof DefaultSchema["Enums"]
    ? DefaultSchema["Enums"][DefaultSchemaEnumNameOrOptions]
    : never

export type CompositeTypes<
  PublicCompositeTypeNameOrOptions extends
    | keyof DefaultSchema["CompositeTypes"]
    | { schema: keyof DatabaseWithoutInternals },
  CompositeTypeName extends (PublicCompositeTypeNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof DatabaseWithoutInternals[PublicCompositeTypeNameOrOptions["schema"]]["CompositeTypes"]
    : never) = never,
> = PublicCompositeTypeNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? DatabaseWithoutInternals[PublicCompositeTypeNameOrOptions["schema"]]["CompositeTypes"][CompositeTypeName]
  : PublicCompositeTypeNameOrOptions extends keyof DefaultSchema["CompositeTypes"]
    ? DefaultSchema["CompositeTypes"][PublicCompositeTypeNameOrOptions]
    : never

export const Constants = {
  public: {
    Enums: {},
  },
} as const
