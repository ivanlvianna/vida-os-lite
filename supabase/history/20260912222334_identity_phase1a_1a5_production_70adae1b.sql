-- =============================================================================
-- MIGRATION B — IDENTITY PHASE 1A + 1A.5 — ARTEFATO CONSOLIDADO
-- =============================================================================
-- STATUS: CLOSED FOR CONSOLIDATION — não aplicar ainda em nenhum ambiente.
-- Consolidação MECÂNICA de B1 + B2 + B3 + B4, nesta ordem, sem alteração
-- semântica durante a concatenação. Cada bloco permanece com seus
-- próprios comentários de autoria/revisão (histórico preservado); os
-- separadores abaixo marcam onde cada bloco original começa/termina.
--
-- PROVENIÊNCIA DA SPEC CANÔNICA:
--   arquivo: as-is-identity-migration-design-v0.1-SPEC-FROZEN.sql
--   SHA-256: a758953457be51db6bef12959d5864941810a511a0d8e79d8a44288adfa44f28
--   verificado nesta versão: 3.12 = CANONICAL ROLLBACK GUARD,
--                             3.13 = RELEASE GATE de Migration B.
--   Esta migration depende da versão identificada por este SHA-256
--   especificamente -- nomes de arquivo não são identidade suficiente.
--
-- ARTEFATOS RELACIONADOS (fora deste arquivo, deliberadamente):
--   migration_b_identity_phase1_postdeploy_check.sql -- checkpoint
--     read-only, PÓS-DEPLOY EM PRODUÇÃO (6.1B), nunca incorporado a esta
--     transação de instalação.
--
-- ESTA É UMA ÚNICA MIGRATION FÍSICA: aplicada como uma transação só (ver
-- BEGIN/COMMIT abaixo), nunca B1/B2/B3/B4 separadamente em nenhum
-- ambiente real. A divisão em blocos existiu para autoria, auditoria e
-- revisão -- não para fragmentar o deploy.
--
-- HARDENING DE SEGURANÇA aplicado nesta rodada: as 3 funções SECURITY
-- DEFINER (vida_auth_user_exists, canonical_reconcile,
-- canonical_rollback_guard) agora fixam search_path = pg_catalog,
-- pg_temp -- pg_temp explicitamente por ÚLTIMO, conforme a recomendação
-- oficial do Postgres ("A secure arrangement can be obtained by forcing
-- the temporary schema to be searched last"). Sem isso, o schema
-- temporário -- buscado primeiro por padrão e normalmente gravável por
-- qualquer sessão -- poderia mascarar um objeto real que a função espera
-- resolver sem qualificação de schema.
--
-- PRÓXIMO PASSO APÓS ESTE ARQUIVO: revisão estática do artefato único,
-- e só então aplicação no projeto de ensaio (jijdyrinuzyjampptbaf) +
-- Release Gate 3.13 completo (33 casos). NÃO aplicar em produção antes
-- do Release Gate ter sido cumprido integralmente em ensaio.
--
-- PRÉ-REQUISITO: rodar migration_b_identity_phase1_preflight.sql
-- IMEDIATAMENTE ANTES deste arquivo -- correção desta rodada: a
-- checagem de precondição foi extraída para arquivo próprio, porque um
-- SELECT antes do BEGIN neste mesmo arquivo não abortaria nada por
-- conta própria, e comprometia a alegação de que esta migration inteira
-- roda dentro de uma única transação. Este arquivo agora começa direto
-- em BEGIN;, sem nenhum comando executável antes dele.
-- =============================================================================


BEGIN;


-- #############################################################################
-- ### BLOCO B1 — TARGET SCHEMA ESTRUTURAL (início)
-- #############################################################################

-- STATUS: DRAFT PARA REVISÃO — não aplicar ainda, nem em ensaio.
-- Este arquivo é um dos quatro blocos de autoria/revisão (B1-B4) que serão
-- consolidados em um único migration_b_identity_phase1.sql transacional.
-- NÃO é a migration física final — não aplicar isoladamente em nenhum
-- ambiente.
--
-- ESCOPO DESTE BLOCO: as 7 tabelas, FKs, NOT NULL, CHECKs, índices, PKs
-- (simples e compostas), geração de UUID. NENHUMA função, trigger,
-- GRANT/REVOKE ou permissão de aplicação — isso é B2/B3/B4.
--
-- Fonte de verdade: Identity Canonical Model v0.1 (SPEC FROZEN) +
-- As-Is → Identity Canonical Model — Migration Design v0.1 (SPEC FROZEN),
-- Bloco 3, itens 3.1-3.7. Nenhuma decisão de ontologia nova aqui —
-- só a materialização exata do que já foi congelado.
-- =============================================================================


-- -----------------------------------------------------------------------------
-- economic_entities
-- -----------------------------------------------------------------------------
CREATE TABLE public.economic_entities (
    id            uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    entity_type   text NOT NULL,
    display_name  text NOT NULL,
    created_at    timestamptz NOT NULL DEFAULT now(),

    CONSTRAINT economic_entities_entity_type_check
        CHECK (entity_type IN ('person', 'organization')),

    CONSTRAINT economic_entities_display_name_not_blank
        CHECK (btrim(display_name) <> '')
);

COMMENT ON TABLE public.economic_entities IS
'Sujeito econômico representado no patrimônio. Identidade interna e estável,
independente de nome, e-mail, documento ou qualquer atributo descritivo que
possa mudar. Não é identidade de login nem relação comercial.';

COMMENT ON COLUMN public.economic_entities.entity_type IS
'Domínio mínimo v0.1: pessoa física ou organização. Não modela família,
holding, trust ou qualquer agregador patrimonial — mas uma pessoa jurídica
que SEJA uma holding pode ser representada como organization normalmente.';

COMMENT ON COLUMN public.economic_entities.display_name IS
'Rótulo legível. Pode ser usado para exibição e busca textual. Nunca é:
identificador canônico; chave única; critério suficiente de deduplicação;
prova de identidade.';


-- -----------------------------------------------------------------------------
-- entity_relationships
-- -----------------------------------------------------------------------------
CREATE TABLE public.entity_relationships (
    id                 uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    from_entity_id     uuid NOT NULL REFERENCES public.economic_entities(id)
                           ON DELETE RESTRICT,
    to_entity_id       uuid NOT NULL REFERENCES public.economic_entities(id)
                           ON DELETE RESTRICT,
    relationship_type  text NOT NULL,
    created_at         timestamptz NOT NULL DEFAULT now(),

    CONSTRAINT entity_relationships_no_self_reference
        CHECK (from_entity_id <> to_entity_id),

    CONSTRAINT entity_relationships_relationship_type_check
        CHECK (relationship_type IN ('owns')),

    CONSTRAINT entity_relationships_unique_relationship
        UNIQUE (from_entity_id, to_entity_id, relationship_type)
);

CREATE INDEX idx_entity_relationships_to_entity_id
    ON public.entity_relationships(to_entity_id);

COMMENT ON TABLE public.entity_relationships IS
'Relações entre entidades econômicas, com vocabulário auditável e restrito.
Princípio de admissão: uma relação só é modelada quando a identidade das
partes altera o estado econômico ou decisório do sistema.';

COMMENT ON COLUMN public.entity_relationships.relationship_type IS
'Enum fechado e auditável. Único valor válido nesta versão: "owns". OWNS-001
(target de owns sempre organization) e o enforcement de que essa restrição
sobrevive a UPDATE/mudança de entity_type são instalados em B4 — este bloco
só declara a coluna e o CHECK de catálogo fechado.';

COMMENT ON CONSTRAINT entity_relationships_unique_relationship ON public.entity_relationships IS
'Impede que a MESMA relação seja cadastrada duas vezes. Não implica
cardinalidade 1:1.';


-- -----------------------------------------------------------------------------
-- client_accounts
-- -----------------------------------------------------------------------------
CREATE TABLE public.client_accounts (
    id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    created_at  timestamptz NOT NULL DEFAULT now()
);

COMMENT ON TABLE public.client_accounts IS
'Relação comercial do VIDA com quem é atendido. Não é a pessoa nem o usuário
autenticado. Pode estar associada a múltiplas economic_entities e a
múltiplos auth_user_id, sem que isso funda ou consolide as identidades
associadas. Nesta migration, nasce sem backfill (MIG-CLIENTACCOUNT-001).';


-- -----------------------------------------------------------------------------
-- client_account_entities (associativa)
-- -----------------------------------------------------------------------------
CREATE TABLE public.client_account_entities (
    client_account_id   uuid NOT NULL REFERENCES public.client_accounts(id)
                             ON DELETE RESTRICT,
    economic_entity_id  uuid NOT NULL REFERENCES public.economic_entities(id)
                             ON DELETE RESTRICT,
    created_at           timestamptz NOT NULL DEFAULT now(),

    PRIMARY KEY (client_account_id, economic_entity_id)
);

CREATE INDEX idx_client_account_entities_economic_entity_id
    ON public.client_account_entities(economic_entity_id);

COMMENT ON TABLE public.client_account_entities IS
'Associação N:M entre conta comercial e entidade econômica. A PK composta
expressa que o objeto relevante é a ASSOCIAÇÃO em si. Ausência de UNIQUE
unilateral em qualquer lado é deliberada.';


-- -----------------------------------------------------------------------------
-- client_account_users (associativa)
-- -----------------------------------------------------------------------------
CREATE TABLE public.client_account_users (
    client_account_id  uuid NOT NULL REFERENCES public.client_accounts(id)
                            ON DELETE CASCADE,
    auth_user_id        uuid NOT NULL,
    -- FK física para auth.users(id) deliberadamente NÃO declarada nesta
    -- fase. AUTH-001: a política do vínculo físico e de lifecycle/delete
    -- permanece fora de escopo até decisão explícita; auth_user_id
    -- continua referência lógica, não FK, neste estágio.
    created_at           timestamptz NOT NULL DEFAULT now(),

    PRIMARY KEY (client_account_id, auth_user_id)
);

CREATE INDEX idx_client_account_users_auth_user_id
    ON public.client_account_users(auth_user_id);

COMMENT ON TABLE public.client_account_users IS
'Associação N:M entre conta comercial e identidade de autenticação. Um
auth_user_id pode acessar mais de uma client_account sem que isso funda
nenhuma economic_entity associada às contas distintas. AUTH-001: quando a
integração real for estabelecida, todo auth_user_id aqui deve resolver para
uma identidade válida em auth.users.';


-- -----------------------------------------------------------------------------
-- reconciliation_source
-- -----------------------------------------------------------------------------
CREATE TABLE public.reconciliation_source (
    id                uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    source_namespace  text NOT NULL,
    source_value      text NOT NULL,
    created_at        timestamptz NOT NULL DEFAULT now(),

    CONSTRAINT reconciliation_source_unique
        UNIQUE (source_namespace, source_value)
);

COMMENT ON TABLE public.reconciliation_source IS
'Identidade ESTÁVEL de uma origem legada reconciliável (MIG-RECON-004).
Nunca ON DELETE CASCADE proveniente de auth.users em nenhuma FK — não há FK
física daqui para auth.users; source_value é texto livre, não referência
direta (MIG-RECON-005: existência validada NO MOMENTO da reconciliação,
nunca dependente depois). Imutável após INSERT — enforcement em B2.';

COMMENT ON COLUMN public.reconciliation_source.source_namespace IS
'Namespace do CAMPO semântico de origem, nunca apenas da tabela. Exemplo
vigente: "auth.users.id". O namespace identifica de modo não ambíguo qual
valor legado source_value representa.';

COMMENT ON COLUMN public.reconciliation_source.source_value IS
'Representação textual CANÔNICA do valor de origem (ex.: uuid::text,
minúsculo, formato padrão de hífens para UUIDs) — normalização é
responsabilidade do write path (B3), nunca inferida aqui.';


-- -----------------------------------------------------------------------------
-- reconciliation_record
-- -----------------------------------------------------------------------------
CREATE TABLE public.reconciliation_record (
    id                             uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    reconciliation_source_id       uuid NOT NULL
                                        REFERENCES public.reconciliation_source(id)
                                        ON DELETE RESTRICT,
    result                         text NOT NULL,
    economic_entity_id             uuid
                                        REFERENCES public.economic_entities(id)
                                        ON DELETE RESTRICT,
    supersedes_reconciliation_record_id
                                    uuid UNIQUE
                                        REFERENCES public.reconciliation_record(id)
                                        ON DELETE RESTRICT,
    recorded_at                    timestamptz NOT NULL,
    -- SEM DEFAULT — atribuído internamente pelo write path (B3), nunca
    -- pelo caller, segundo a disciplina system-assigned/commit-visible.
    decided_by                     text NOT NULL,
    decided_note                   text,

    CONSTRAINT reconciliation_record_result_check
        CHECK (result IN ('BLOCKED', 'REJECTED', 'CONFIRMED')),

    CONSTRAINT reconciliation_record_entity_matches_result
        CHECK (
            (result = 'CONFIRMED' AND economic_entity_id IS NOT NULL)
            OR (result IN ('BLOCKED', 'REJECTED') AND economic_entity_id IS NULL)
        ),

    CONSTRAINT reconciliation_record_no_self_supersede
        CHECK (supersedes_reconciliation_record_id IS NULL
               OR supersedes_reconciliation_record_id <> id),

    CONSTRAINT reconciliation_record_decided_by_not_blank
        CHECK (btrim(decided_by) <> '')
);

CREATE INDEX idx_reconciliation_record_source
    ON public.reconciliation_record(reconciliation_source_id, recorded_at);

CREATE UNIQUE INDEX uq_reconciliation_record_root
    ON public.reconciliation_record(reconciliation_source_id)
    WHERE supersedes_reconciliation_record_id IS NULL;

COMMENT ON TABLE public.reconciliation_record IS
'Representação append-only do conhecimento do VIDA sobre uma origem
reconciliável, numa versão específica. Identidade estável (source) separada
de historicidade (record) — MIG-RECON-004/006, mesma disciplina já usada em
economic_fact/supersedes e decision_record/supersedes. UPDATE/DELETE
proibidos fisicamente em B2 (esta tabela só declara a estrutura, o trigger
de bloqueio vem depois).';

COMMENT ON COLUMN public.reconciliation_record.result IS
'BLOCKED: informação insuficiente/ambígua, reconsiderável quando surgir
evidência nova. REJECTED: origem analisada, confirmada como NÃO
representando sujeito econômico — fechado contra reprocessamento
automático, mas corrigível por novo record supersedendo. CONFIRMED: origem
reconciliada com uma EconomicEntity, existente ou nova.';

COMMENT ON COLUMN public.reconciliation_record.economic_entity_id IS
'NOT NULL exatamente quando result=CONFIRMED (CHECK
reconciliation_record_entity_matches_result). Pode apontar para
EconomicEntity JÁ EXISTENTE (duas origens legítimas reconciliadas com a
mesma pessoa, por decisão humana explícita) ou recém-criada na mesma
transação — nunca inferido automaticamente.';

COMMENT ON COLUMN public.reconciliation_record.supersedes_reconciliation_record_id IS
'Correção/revisão de uma decisão de reconciliação anterior sobre a MESMA
origem — nunca correção de erro confundida com criação de nova origem.
UNIQUE garante cadeia linear (nenhum record é supersedido duas vezes).
uq_reconciliation_record_root garante no máximo uma raiz por source.';

COMMENT ON COLUMN public.reconciliation_record.recorded_at IS
'Tempo de entrada no conhecimento canônico comprometido do VIDA — nunca
tempo de negócio. Atribuído exclusivamente pelo write path canônico (B3),
segundo disciplina commit-visible (mesmo padrão de TEMP-010A/PROV-TIME-002/
DEC-TIME-002).';

COMMENT ON COLUMN public.reconciliation_record.decided_by IS
'Identificador AUDITÁVEL do operador/decisor da reconciliação — nunca nome
livre ornamental, nunca vazio. Mecanismo exato (UUID de admin, subject de
Auth, identificador administrativo) é decisão operacional de quem chama o
write path, não deste schema.';

-- =============================================================================
-- FIM DE B1 — nenhuma função, trigger, GRANT/REVOKE ou dado inserido.
-- Próximo: B2 (canonical_reconciliation, imutabilidade, raiz única, cadeia).
-- =============================================================================

-- #############################################################################
-- ### BLOCO B1 — FIM
-- #############################################################################


-- #############################################################################
-- ### BLOCO B2 — LEITURA CANÔNICA + IMUTABILIDADE + INTEGRIDADE DA CADEIA (início)
-- #############################################################################

-- STATUS: DRAFT PARA REVISÃO — não aplicar ainda, nem em ensaio.
-- Depende de B1 (target schema) já aplicado no mesmo ambiente.
--
-- ESCOPO DESTE BLOCO:
--   1. canonical_reconciliation(source, K) — DB-side, read-only, cardinalidade
--      contratual 0..1, falha explícita se a cadeia estiver corrompida.
--   2. Imutabilidade física de reconciliation_source (UPDATE/DELETE rejeitados).
--   3. Imutabilidade física de reconciliation_record (UPDATE/DELETE rejeitados).
--   4. Integridade de sucessão no INSERT de reconciliation_record: predecessor
--      existe, mesma source, é o terminal corrente, recorded_at estrito.
--   5. Verificação semântica de raiz única (redundante ao índice físico de
--      B1, nunca cria source/root automaticamente).
--
-- DELIBERADAMENTE FORA DE B2 (perímetro fixado por Ivan nesta rodada):
--   - criação/normalização de source_namespace/source_value;
--   - advisory/key lock antes da source existir (corrida da primeira
--     reconciliação — responsabilidade de B3);
--   - canonical_reconcile(...) (write path operacional);
--   - idempotência operacional;
--   - criação atômica EconomicEntity + reconciliation_record;
--   - atribuição system-assigned de recorded_at (B2 só VALIDA a ordem entre
--     predecessor/sucessor; QUEM atribui o valor é B3);
--   - garantia de que source + primeira raiz nascem na mesma transação;
--   - modelo GRANT/REVOKE; OWNS-001; Canonical Rollback Guard (B4).
--
-- OBRIGAÇÃO REGISTRADA PARA B4: triggers de imutabilidade (row-level) não
-- impedem TRUNCATE. B4, ao fechar SELECT/INSERT/UPDATE/DELETE/EXECUTE via
-- REVOKE, precisa incluir TRUNCATE nas tabelas canônicas (reconciliation_
-- source, reconciliation_record, economic_entities, entity_relationships,
-- client_accounts e associativas). Owner/superuser permanece break-glass,
-- já congelado -- esta obrigação é sobre roles operacionais normais.
--
-- Fonte de verdade: Identity Canonical Model v0.1 (SPEC FROZEN) + Migration
-- Design v0.1 (SPEC FROZEN), MIG-RECON-001/002/003/004/005/006.
-- =============================================================================


-- =============================================================================
-- 1 — canonical_reconciliation(p_source_id, p_knowledge_as_of)
-- =============================================================================
-- Implementação canônica ÚNICA da leitura temporal da cadeia (3.10A da
-- spec). Terminal = record visível (recorded_at <= K) que não foi
-- supersedido por outro record TAMBÉM visível naquele K.
--
-- Cardinalidade contratual: 0 ou 1. NUNCA usa LIMIT 1 para esconder uma
-- eventual violação física — se por algum motivo dois terminais aparecerem
-- simultaneamente (o que os enforcements desta migration deveriam impedir
-- estruturalmente), a função FALHA explicitamente em vez de escolher um
-- arbitrariamente.

CREATE FUNCTION public.canonical_reconciliation(
    p_source_id        uuid,
    p_knowledge_as_of  timestamptz
)
RETURNS public.reconciliation_record
LANGUAGE plpgsql
STABLE
AS $$
DECLARE
    v_terminals public.reconciliation_record[];
BEGIN
    IF p_source_id IS NULL THEN
        RAISE EXCEPTION 'canonical_reconciliation: p_source_id não pode ser NULL';
    END IF;

    IF p_knowledge_as_of IS NULL THEN
        RAISE EXCEPTION 'canonical_reconciliation: p_knowledge_as_of não pode ser NULL';
    END IF;

    -- Sem esta checagem, p_knowledge_as_of NULL faria "recorded_at <= NULL"
    -- nunca ser verdadeiro e a função retornaria NULL como se significasse
    -- "nenhum record era conhecido naquele K" -- quando na realidade não
    -- houve K válido algum. Input inválido nunca vira resposta
    -- epistemológica válida.

    SELECT array_agg(r.*)
    INTO v_terminals
    FROM public.reconciliation_record r
    WHERE r.reconciliation_source_id = p_source_id
      AND r.recorded_at <= p_knowledge_as_of
      AND NOT EXISTS (
          SELECT 1
          FROM public.reconciliation_record s
          WHERE s.supersedes_reconciliation_record_id = r.id
            AND s.recorded_at <= p_knowledge_as_of
      );

    IF v_terminals IS NULL THEN
        -- nenhum record visível para esta source neste K -- "o VIDA ainda
        -- não sabia desta origem naquele momento", nunca erro nem valor
        -- inventado.
        RETURN NULL;
    END IF;

    IF array_length(v_terminals, 1) > 1 THEN
        RAISE EXCEPTION
            'canonical_reconciliation: % terminais visíveis para source % em K=% — cadeia corrompida, esperado no máximo 1 (violação de MIG-RECON-006, deveria ter sido impedida estruturalmente por esta mesma migration)',
            array_length(v_terminals, 1), p_source_id, p_knowledge_as_of;
    END IF;

    RETURN v_terminals[1];
END;
$$;

COMMENT ON FUNCTION public.canonical_reconciliation(uuid, timestamptz) IS
'Leitura canônica ÚNICA da cadeia de reconciliação de uma source, em um
cutoff de conhecimento K. Retorna NULL se nada visível ainda; RAISE
EXCEPTION se mais de um terminal for encontrado (nunca escolhe
arbitrariamente). DB-side por design — 3.11 (B3) depende de chamar esta
função dentro da mesma transação/lock, o que exige que ela viva no banco.';


-- =============================================================================
-- 2 — Imutabilidade física de reconciliation_source
-- =============================================================================

CREATE FUNCTION public.reconciliation_source_block_mutation()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
    IF TG_OP = 'UPDATE' THEN
        RAISE EXCEPTION
            'reconciliation_source é imutável após INSERT — UPDATE rejeitado (id=%)',
            OLD.id;
    ELSIF TG_OP = 'DELETE' THEN
        RAISE EXCEPTION
            'reconciliation_source é imutável — DELETE rejeitado (id=%). Ver MIG-ROLLBACK-001/Canonical Rollback Guard (B4) para o único caminho suportado de remoção estrutural, e mesmo assim só antes de qualquer reconciliation_record existir.',
            OLD.id;
    END IF;
    RETURN NULL;
END;
$$;

CREATE TRIGGER trg_reconciliation_source_immutable
    BEFORE UPDATE OR DELETE ON public.reconciliation_source
    FOR EACH ROW
    EXECUTE FUNCTION public.reconciliation_source_block_mutation();

COMMENT ON TRIGGER trg_reconciliation_source_immutable ON public.reconciliation_source IS
'Fecha (source_namespace, source_value) como estável para sempre após
INSERT — MIG-RECON-004.';


-- =============================================================================
-- 3 — Imutabilidade física de reconciliation_record
-- =============================================================================

CREATE FUNCTION public.reconciliation_record_block_mutation()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
    IF TG_OP = 'UPDATE' THEN
        RAISE EXCEPTION
            'reconciliation_record é append-only — UPDATE rejeitado (id=%). Toda mudança epistemológica exige um NOVO record supersedendo este.',
            OLD.id;
    ELSIF TG_OP = 'DELETE' THEN
        RAISE EXCEPTION
            'reconciliation_record é append-only — DELETE rejeitado (id=%).',
            OLD.id;
    END IF;
    RETURN NULL;
END;
$$;

CREATE TRIGGER trg_reconciliation_record_immutable
    BEFORE UPDATE OR DELETE ON public.reconciliation_record
    FOR EACH ROW
    EXECUTE FUNCTION public.reconciliation_record_block_mutation();

COMMENT ON TRIGGER trg_reconciliation_record_immutable ON public.reconciliation_record IS
'Nenhuma linha de reconciliation_record muda ou desaparece após INSERT —
MIG-RECON-003. Correção/revisão é sempre novo record.';


-- =============================================================================
-- 4 e 5 — Integridade de sucessão + verificação semântica de raiz
-- =============================================================================
-- Roda no INSERT (a imutabilidade acima cobre UPDATE/DELETE; este trigger
-- cobre a validade do que está sendo inserido). Não atribui recorded_at —
-- só valida a ORDEM entre o que já veio preenchido em NEW e o predecessor.
-- Quem atribui o valor de NEW.recorded_at é o write path (B3).

CREATE FUNCTION public.reconciliation_record_validate_succession()
RETURNS trigger
LANGUAGE plpgsql
AS $$
DECLARE
    v_predecessor public.reconciliation_record;
BEGIN
    IF NEW.supersedes_reconciliation_record_id IS NOT NULL THEN

        -- (4.1) predecessor precisa existir
        SELECT * INTO v_predecessor
        FROM public.reconciliation_record
        WHERE id = NEW.supersedes_reconciliation_record_id;

        IF NOT FOUND THEN
            RAISE EXCEPTION
                'reconciliation_record: predecessor % não existe',
                NEW.supersedes_reconciliation_record_id;
        END IF;

        -- (4.2) mesma reconciliation_source_id
        IF v_predecessor.reconciliation_source_id <> NEW.reconciliation_source_id THEN
            RAISE EXCEPTION
                'reconciliation_record: sucessor precisa pertencer à MESMA reconciliation_source do predecessor (predecessor source=%, novo source=%)',
                v_predecessor.reconciliation_source_id, NEW.reconciliation_source_id;
        END IF;

        -- (4.3) predecessor precisa ser o terminal canônico corrente --
        -- nenhum outro record já supersede este predecessor.
        IF EXISTS (
            SELECT 1 FROM public.reconciliation_record
            WHERE supersedes_reconciliation_record_id = v_predecessor.id
        ) THEN
            RAISE EXCEPTION
                'reconciliation_record: predecessor % já foi supersedido — sucessor precisa apontar para o terminal canônico corrente, nunca para um record do meio da cadeia',
                v_predecessor.id;
        END IF;

        -- (4.4) recorded_at estritamente posterior
        IF NEW.recorded_at <= v_predecessor.recorded_at THEN
            RAISE EXCEPTION
                'reconciliation_record: recorded_at do sucessor (%) precisa ser estritamente posterior ao do predecessor (%)',
                NEW.recorded_at, v_predecessor.recorded_at;
        END IF;

    ELSE
        -- (5) raiz -- verificação SEMÂNTICA adicional, redundante por
        -- design ao índice físico uq_reconciliation_record_root (B1).
        -- Nunca cria source ou root automaticamente -- só valida o que
        -- está sendo inserido.
        IF EXISTS (
            SELECT 1 FROM public.reconciliation_record
            WHERE reconciliation_source_id = NEW.reconciliation_source_id
              AND supersedes_reconciliation_record_id IS NULL
        ) THEN
            RAISE EXCEPTION
                'reconciliation_record: já existe uma raiz para a source % — nova raiz não permitida (também bloqueado fisicamente por uq_reconciliation_record_root; esta é a checagem semântica redundante)',
                NEW.reconciliation_source_id;
        END IF;
    END IF;

    RETURN NEW;
END;
$$;

CREATE TRIGGER trg_reconciliation_record_validate_succession
    BEFORE INSERT ON public.reconciliation_record
    FOR EACH ROW
    EXECUTE FUNCTION public.reconciliation_record_validate_succession();

COMMENT ON TRIGGER trg_reconciliation_record_validate_succession ON public.reconciliation_record IS
'Valida mesma source, terminal corrente e ordem temporal estrita em cada
INSERT (MIG-RECON-006/DEC-RECORD-002, mesmo padrão aplicado aqui). Duas
transações podem passar simultaneamente por esta validação. As UNIQUE
constraints de B1 (supersedes_reconciliation_record_id, e o índice parcial
de raiz) ainda impedem dois forks/raízes de COMMITAREM com sucesso -- uma
das transações concorrentes acaba rejeitada pela constraint física, nunca
os dois commits coexistindo. B3 acrescenta serialização determinística por
chave namespaced para tornar o write path idempotente e livre dessa
corrida OPERACIONAL (evitar trabalho conflitante/erro de aplicação em vez
de depender de uma transação falhar por constraint), não para suprir uma
ausência de garantia estrutural que já existe desde B1.';


-- =============================================================================
-- FIM DE B2 — nenhum GRANT/REVOKE, nenhum write path operacional, nenhum
-- lock de concorrência. Próximo: B3 (canonical_reconcile, normalização de
-- chave, lock antes da source existir, atomicidade, recorded_at
-- system-assigned).
--
-- NOTA PARA O PREFLIGHT FINAL DA MIGRATION B CONSOLIDADA: como este bloco
-- usa CREATE FUNCTION (não CREATE OR REPLACE), o Gate B final precisa
-- verificar ausência prévia não só das 7 tabelas (já coberto em B1), mas
-- também das funções e triggers canônicos introduzidas aqui e em B3/B4
-- (canonical_reconciliation, canonical_reconcile, funções de trigger de
-- imutabilidade/sucessão/OWNS-001, Canonical Rollback Guard) -- se algo
-- já existir, ABORTAR e investigar, nunca presumir que é seguro
-- sobrescrever silenciosamente uma implementação parcial anterior.
-- =============================================================================

-- #############################################################################
-- ### BLOCO B2 — FIM
-- #############################################################################


-- #############################################################################
-- ### BLOCO B3 — WRITE PATH CANÔNICO (início)
-- #############################################################################

-- STATUS: ARCHITECTURE CLOSED — 3 emendas de integração aplicadas: FOR
-- KEY SHARE -> SELECT simples; SELECT direto em auth.users -> bridge
-- vida_auth_user_exists(); e o bridge corrigido de STABLE para VOLATILE
-- (STABLE usaria o snapshot da query chamadora, podendo esconder uma
-- exclusão concorrente committada durante a espera nos advisory locks).
-- Depende de B1 (schema) + B2 (leitura canônica, imutabilidade, validação
-- de sucessão) já aplicados no mesmo ambiente.
--
-- ESCOPO DESTE BLOCO:
--   canonical_reconcile(...) — o único caminho operacional de escrita para
--   reconciliation_source/reconciliation_record (e, quando aplicável,
--   economic_entities nova). Cobre: normalização/validação da chave
--   namespaced, lock por OPERAÇÃO (espaço bigint) seguido de lock por
--   SOURCE (espaço int4+int4, fisicamente distinto — nunca colide com o
--   de operação por construção), ordem fixa nunca invertida DENTRO de
--   uma invocação, idempotência de retry por identidade de operação,
--   revisão deliberada explícita como único caminho para gravar estado
--   divergente do terminal, atomicidade source+entidade+record,
--   recorded_at system-assigned monotônico.
--
--   CONTRATO: uma operação de reconciliação por transação nesta v0.1 —
--   a ordem de locks elimina inversão ENTRE invocações concorrentes que
--   respeitem este contrato, mas não cobre múltiplas reconciliações
--   distintas dentro da MESMA transação (fora de escopo, não suportado).
--
-- DELIBERADAMENTE FORA DE B3:
--   - fechamento por privilégios (GRANT/REVOKE/EXECUTE) — B4;
--   - OWNS-001, Canonical Rollback Guard — B4;
--   - criação de ClientAccount, associações ou entity_relationships —
--     MIG-NOAUTO-001 permanece absoluto, nenhuma menção a essas tabelas
--     aparece neste arquivo;
--   - fingerprint/receipt imutável do payload original de uma operação —
--     nesta v0.1, retry de CONFIRMED_NEW é reconhecido apenas por
--     p_record_id + mesma source + mesmo result, nunca por comparar
--     atributos atuais (mutáveis) da entidade já criada. Uma garantia
--     forte de "mesmo operation ID implica payload byte-a-byte idêntico"
--     exigiria uma tabela de fingerprint, fora de escopo aqui.
--
-- OBRIGAÇÕES REGISTRADAS PARA B4 (não implementadas aqui):
--   - canonical_reconcile precisa se tornar SECURITY DEFINER, com owner
--     restrito e search_path controlado;
--   - GRANT EXECUTE restrito ao papel operacional; REVOKE de PUBLIC;
--   - confiabilidade de decided_by: hoje é texto fornecido pelo próprio
--     caller, sem vínculo verificado. Quando a função virar SECURITY
--     DEFINER, B4 precisa decidir se esse valor é uma asserção confiável
--     de um processo administrativo controlado ou se deve ser amarrado
--     a uma identidade de autenticação verificável (ex.: auth.uid() do
--     Supabase). Não decidido aqui, deliberadamente.
--
-- CONTRATO DE ISOLAMENTO: suportada SOMENTE sob READ COMMITTED — rejeitada
-- explicitamente sob isolamento diferente.
--
-- Fonte de verdade: MIG-RECON-001/002/004/005/006, MIG-ATOMIC-001,
-- MIG-CONCURRENCY-001, MIG-IDEMPOTENT-001, MIG-NOINFER-001,
-- MIG-NOAUTO-001, Caso 33.
-- =============================================================================


CREATE FUNCTION public.vida_auth_user_exists(p_user_id uuid)
RETURNS boolean
LANGUAGE sql
VOLATILE
SECURITY DEFINER
SET search_path = pg_catalog, pg_temp
AS $$
    SELECT EXISTS (
        SELECT 1
        FROM auth.users
        WHERE id = p_user_id
    );
$$;

COMMENT ON FUNCTION public.vida_auth_user_exists(uuid) IS
'Bridge mínimo de leitura de Auth -- correção de integração desta rodada:
o catálogo real do ambiente de ensaio mostrou que o schema auth é owned
por supabase_admin; "postgres" (o papel que executa esta migration) tem
USAGE no schema auth mas SEM grant option, portanto não pode repassar
USAGE a vida_identity_owner. "postgres" TEM SELECT WITH GRANT OPTION em
auth.users especificamente, mas conceder SELECT direto ainda ampliaria a
superfície de vida_identity_owner sobre uma tabela inteira do schema Auth.
search_path = pg_catalog, pg_temp -- pg_temp explicitamente por ÚLTIMO
(correção desta rodada, confirmada na documentação oficial do Postgres:
"A secure arrangement can be obtained by forcing the temporary schema
to be searched last. To do this, write pg_temp as the last entry in
search_path") -- sem isso, o schema temporário é buscado primeiro por
padrão e é normalmente gravável por qualquer sessão.
VOLATILE explícito (correção desta rodada, confirmada na documentação
oficial do Postgres: "STABLE and IMMUTABLE functions use a snapshot
established as of the start of the calling query, whereas VOLATILE
functions obtain a fresh snapshot at the start of each query they
execute") -- STABLE usaria o snapshot já estabelecido no início da query
CHAMADORA (canonical_reconcile), que pode ter sido estabelecido ANTES de
canonical_reconcile esperar nos advisory locks; um DELETE concorrente em
auth.users, committado nesse intervalo, poderia permanecer invisível a
uma checagem STABLE, quebrando exatamente a semântica "existia no
instante da revalidação" que este bridge existe para garantir. VOLATILE
é necessário para a garantia ser tecnicamente real, não só nomeada.
Esta função é um ADAPTADOR DA PLATAFORMA SUPABASE, não um objeto da
ontologia Identity -- deliberadamente owned por "postgres" (nunca
transferido para vida_identity_owner em B4), SQL fixo sem qualquer
entrada dinâmica além do uuid, superfície mínima. REVOKE/GRANT desta
função ocorrem em B4, junto do resto do modelo de privilégios. Em
eventual rollback estrutural, permanece junto do Canonical Rollback
Guard -- removido no cleanup administrativo explícito, não pelo guard
automaticamente.';


CREATE FUNCTION public.canonical_reconcile(
    p_record_id             uuid,   -- identidade ESTÁVEL da operação/tentativa,
                                     -- gerada pelo CALLER, reutilizada em retries.
                                     -- Precisa ser um UUID NOVO da operação --
                                     -- nunca reaproveitamento de auth.users.id,
                                     -- economic_entity_id ou qualquer outro UUID
                                     -- legado. A geração foi deslocada do banco
                                     -- (que usaria gen_random_uuid() como
                                     -- DEFAULT) para o caller, mas o princípio
                                     -- "nunca reutiliza UUID de outra fonte"
                                     -- (MIG-UUID-001) não foi revogado.
    p_source_namespace      text,
    p_source_value_raw      text,
    p_decision              text,   -- 'BLOCKED' | 'REJECTED' | 'CONFIRMED_NEW' | 'CONFIRMED_EXISTING'
    p_decided_by            text,
    p_decided_note          text DEFAULT NULL,
    p_economic_entity_id    uuid DEFAULT NULL,   -- exigido SOMENTE em CONFIRMED_EXISTING
    p_entity_type           text DEFAULT NULL,   -- exigido SOMENTE em CONFIRMED_NEW
    p_display_name          text DEFAULT NULL,   -- exigido SOMENTE em CONFIRMED_NEW
    p_deliberate_revision   boolean DEFAULT false
    -- AUTORIZAÇÃO EXPLÍCITA para gravar um estado que diverge do terminal
    -- corrente (correção desta rodada, renomeado de p_reassert com
    -- semântica mais estrita):
    --   sem terminal (primeira decisão da source): flag irrelevante,
    --     sempre permitido;
    --   terminal + mesmo estado comparável com segurança + false: NOOP;
    --   terminal + estado diferente + false: ERRO — revisão deliberada
    --     exigida, nunca grava automaticamente;
    --   terminal já CONFIRMED + CONFIRMED_NEW (novo p_record_id) + false:
    --     ERRO — não é possível provar que é a mesma entidade sem
    --     fingerprint, então esta combinação SEMPRE exige o flag;
    --   true: autoriza explicitamente novo sucessor — correção, revisão
    --     ou reafirmação deliberada do mesmo estado.
)
RETURNS public.reconciliation_record
LANGUAGE plpgsql
AS $$
DECLARE
    v_existing_record   public.reconciliation_record;
    v_canonical_value   text;
    v_uuid_value        uuid;
    v_op_lock_key       bigint;
    v_source_lock_class constant integer := 720000001;
    -- VIDA_RECONCILIATION_SOURCE_CLASS -- constante fixa do sistema,
    -- nunca reaproveitada para outro propósito. Correção desta rodada:
    -- separa FISICAMENTE o espaço de lock de source do espaço de lock de
    -- operação (ver (2)/(4) abaixo) -- dois hashtextextended() diferentes
    -- ainda convergem para o MESMO espaço de bigint de 64 bits e podem,
    -- por mais improvável que seja, colidir entre si; pg_advisory_xact_lock
    -- com dois argumentos int4 usa um espaço de chaves fisicamente
    -- distinto do espaço de um único argumento bigint (documentado pelo
    -- Postgres), eliminando essa colisão POR CONSTRUÇÃO, não por
    -- prefixo textual.
    v_source_lock_key   integer;
    v_source            public.reconciliation_source;
    v_terminal          public.reconciliation_record;
    v_result            text;
    v_target_entity_id  uuid;
    v_recorded_at       timestamptz;
    v_new_record        public.reconciliation_record;
BEGIN
    -- =========================================================================
    -- (-1) CONTRATO DE ISOLAMENTO
    -- =========================================================================

    IF current_setting('transaction_isolation') <> 'read committed' THEN
        RAISE EXCEPTION 'canonical_reconcile: requer isolamento READ COMMITTED (atual: %). Sob isolamento mais forte, a serialização operacional prometida por esta função não é garantida.',
            current_setting('transaction_isolation');
    END IF;

    -- =========================================================================
    -- (0) VALIDAÇÃO DE NULL E COERÊNCIA — falhar explicitamente.
    -- =========================================================================

    IF p_record_id IS NULL THEN
        RAISE EXCEPTION 'canonical_reconcile: p_record_id não pode ser NULL — identidade estável da operação é obrigatória';
    END IF;

    IF p_source_namespace IS NULL THEN
        RAISE EXCEPTION 'canonical_reconcile: p_source_namespace não pode ser NULL';
    END IF;

    IF p_source_value_raw IS NULL THEN
        RAISE EXCEPTION 'canonical_reconcile: p_source_value_raw não pode ser NULL';
    END IF;

    IF p_decision IS NULL OR p_decision NOT IN ('BLOCKED', 'REJECTED', 'CONFIRMED_NEW', 'CONFIRMED_EXISTING') THEN
        RAISE EXCEPTION 'canonical_reconcile: p_decision inválido (%). Esperado BLOCKED, REJECTED, CONFIRMED_NEW ou CONFIRMED_EXISTING.',
            p_decision;
    END IF;

    IF p_decided_by IS NULL OR btrim(p_decided_by) = '' THEN
        RAISE EXCEPTION 'canonical_reconcile: p_decided_by não pode ser nulo/vazio';
    END IF;

    IF p_deliberate_revision IS NULL THEN
        RAISE EXCEPTION 'canonical_reconcile: p_deliberate_revision não pode ser NULL — correção desta rodada: NULL não pode se comportar implicitamente como autorização (nem como negação) de gravação';
    END IF;

    IF p_decision IN ('BLOCKED', 'REJECTED') THEN
        IF p_economic_entity_id IS NOT NULL OR p_entity_type IS NOT NULL OR p_display_name IS NOT NULL THEN
            RAISE EXCEPTION 'canonical_reconcile: % não admite p_economic_entity_id/p_entity_type/p_display_name — parâmetros incoerentes com o modo de decisão',
                p_decision;
        END IF;
    ELSIF p_decision = 'CONFIRMED_EXISTING' THEN
        IF p_economic_entity_id IS NULL THEN
            RAISE EXCEPTION 'canonical_reconcile: CONFIRMED_EXISTING exige p_economic_entity_id';
        END IF;
        IF p_entity_type IS NOT NULL OR p_display_name IS NOT NULL THEN
            RAISE EXCEPTION 'canonical_reconcile: CONFIRMED_EXISTING não admite p_entity_type/p_display_name — a entidade já existe, esses parâmetros são exclusivos de CONFIRMED_NEW';
        END IF;
    ELSIF p_decision = 'CONFIRMED_NEW' THEN
        IF p_economic_entity_id IS NOT NULL THEN
            RAISE EXCEPTION 'canonical_reconcile: CONFIRMED_NEW não admite p_economic_entity_id — para reconciliar com entidade existente, use CONFIRMED_EXISTING';
        END IF;
        IF p_entity_type IS NULL OR p_display_name IS NULL THEN
            RAISE EXCEPTION 'canonical_reconcile: CONFIRMED_NEW exige p_entity_type E p_display_name explícitos — o namespace de origem nunca prova, por si só, qual é o entity_type correto (MIG-NOINFER-001). Nenhum default como person é assumido aqui.';
        END IF;
        IF p_entity_type NOT IN ('person', 'organization') THEN
            RAISE EXCEPTION 'canonical_reconcile: p_entity_type inválido (%)', p_entity_type;
        END IF;
        IF btrim(p_display_name) = '' THEN
            RAISE EXCEPTION 'canonical_reconcile: p_display_name não pode ser vazio/whitespace';
        END IF;
    END IF;

    -- =========================================================================
    -- (1) NORMALIZAÇÃO DA CHAVE NAMESPACED — apenas normalização, não a
    -- checagem de existência ainda (isso fica para depois do SOURCE lock,
    -- ver (5)). Catálogo fechado de namespaces v0.1: apenas 'auth.users.id'.
    -- =========================================================================

    IF p_source_namespace = 'auth.users.id' THEN
        BEGIN
            v_uuid_value := p_source_value_raw::uuid;
        EXCEPTION WHEN invalid_text_representation THEN
            RAISE EXCEPTION 'canonical_reconcile: p_source_value_raw (%) não é um UUID válido para o namespace auth.users.id',
                p_source_value_raw;
        END;
        v_canonical_value := v_uuid_value::text;
    ELSE
        RAISE EXCEPTION 'canonical_reconcile: source_namespace "%" não suportado nesta v0.1. Único namespace suportado: auth.users.id.',
            p_source_namespace;
    END IF;

    -- =========================================================================
    -- (2) LOCK DE OPERAÇÃO — ANTES de qualquer lookup de p_record_id.
    -- Correção desta rodada: sem este lock, duas chamadas simultâneas com
    -- o MESMO p_record_id mas sources diferentes poderiam ambas observar
    -- "record inexistente", seguir para o lock de SOURCE de cada uma
    -- (diferentes), e só colidir no PK violation final -- tarde demais
    -- para a semântica de identidade operacional pretendida. Espaço de
    -- lock FISICAMENTE distinto do lock de source (bigint de um único
    -- argumento aqui vs. par de int4 em (4)) -- nunca colide com ele por
    -- construção, não apenas por prefixo textual improvável de colidir.
    --
    -- ORDEM FIXA, NUNCA INVERTIDA, dentro de uma mesma invocação: lock de
    -- OPERAÇÃO sempre antes do lock de SOURCE. Essa ordem elimina
    -- inversão de locks entre invocações concorrentes que respeitem o
    -- CONTRATO abaixo -- correção desta rodada: a ordem sozinha NÃO
    -- garante ausência absoluta de deadlock se uma mesma transação
    -- executar múltiplas reconciliações distintas (pg_advisory_xact_lock
    -- dura até o fim da transação; duas transações podem, em teoria,
    -- reter o lock de uma operação enquanto esperam o de outra, gerando
    -- ciclo). Por isso:
    --
    --   CONTRATO canonical_reconcile v0.1: uma operação de reconciliação
    --   por transação. O lock order operação->source elimina inversão de
    --   locks entre invocações concorrentes que obedecem a este
    --   contrato. Múltiplas reconciliações distintas dentro da MESMA
    --   transação NÃO são uma modalidade suportada nesta v0.1 -- isso
    --   também precisa constar do harness do release gate (B da spec),
    --   não só deste comentário.
    -- =========================================================================

    v_op_lock_key := hashtextextended('vida.reconcile.op:' || p_record_id::text, 0);
    PERFORM pg_advisory_xact_lock(v_op_lock_key);

    -- =========================================================================
    -- (3) RETRY-CHECK POR IDENTIDADE DE OPERAÇÃO, já sob o lock de operação.
    -- Correção desta rodada: NÃO compara entity_type/display_name mesmo no
    -- retry -- display_name é mutável e não é identidade (B1); uma
    -- correção legítima de grafia feita depois tornaria um retry
    -- autêntico da operação original indistinguível de reuso indevido. A
    -- validação de consistência fica restrita ao que é IMUTAVELMENTE
    -- demonstrável pelo banco: mesma source, mesmo result, e (só para
    -- CONFIRMED_EXISTING) mesmo economic_entity_id.
    -- =========================================================================

    SELECT * INTO v_existing_record
    FROM public.reconciliation_record
    WHERE id = p_record_id;

    IF v_existing_record.id IS NOT NULL THEN
        SELECT * INTO v_source
        FROM public.reconciliation_source
        WHERE id = v_existing_record.reconciliation_source_id;

        IF v_source.source_namespace <> p_source_namespace
           OR v_source.source_value <> v_canonical_value THEN
            RAISE EXCEPTION 'canonical_reconcile: p_record_id % já foi usado para uma origem diferente (source persistida: %/%, chamada atual: %/%) — reuso indevido de identidade de operação',
                p_record_id, v_source.source_namespace, v_source.source_value,
                p_source_namespace, v_canonical_value;
        END IF;

        v_result := CASE p_decision
                        WHEN 'CONFIRMED_NEW' THEN 'CONFIRMED'
                        WHEN 'CONFIRMED_EXISTING' THEN 'CONFIRMED'
                        ELSE p_decision
                    END;

        IF v_existing_record.result <> v_result THEN
            RAISE EXCEPTION 'canonical_reconcile: p_record_id % já foi persistido com result=% — chamada atual pede result=% — reuso indevido de identidade de operação',
                p_record_id, v_existing_record.result, v_result;
        END IF;

        IF p_decision = 'CONFIRMED_EXISTING' AND v_existing_record.economic_entity_id <> p_economic_entity_id THEN
            RAISE EXCEPTION 'canonical_reconcile: p_record_id % já foi persistido apontando para economic_entity_id % — chamada atual pede % — reuso indevido de identidade de operação',
                p_record_id, v_existing_record.economic_entity_id, p_economic_entity_id;
        END IF;

        -- CONFIRMED_NEW: nenhuma comparação de entity_type/display_name
        -- aqui, deliberadamente. Mesma source + mesmo result=CONFIRMED já
        -- persistido para este p_record_id é aceito como retry legítimo.

        RETURN v_existing_record;
    END IF;

    -- =========================================================================
    -- (4) LOCK DE SOURCE — só depois do lock de operação (ordem fixa) e só
    -- quando (3) confirmou que esta é uma operação NOVA (p_record_id ainda
    -- não persistido). Espaço de lock (int4, int4), fisicamente distinto
    -- do espaço bigint de (2) -- separação por construção, não por
    -- prefixo textual.
    -- =========================================================================

    v_source_lock_key := hashtext(p_source_namespace || chr(30) || v_canonical_value);
    PERFORM pg_advisory_xact_lock(v_source_lock_class, v_source_lock_key);

    -- =========================================================================
    -- (5) EXISTÊNCIA DE auth.users — já sob o lock de source. Correção
    -- desta rodada (integração real com o ambiente Supabase, confirmada
    -- por inspeção do catálogo do projeto de ensaio): vida_identity_owner
    -- NÃO acessa auth.users diretamente -- nem USAGE no schema auth, nem
    -- SELECT na tabela. A checagem passa pelo bridge
    -- vida_auth_user_exists(), owned por "postgres", SECURITY DEFINER,
    -- superfície mínima (booleano fixo, sem SQL dinâmico). O ponto de
    -- linearização continua "o usuário existia no instante da
    -- revalidação" -- MIG-RECON-005, sem alteração de semântica, só de
    -- mecanismo de acesso.
    -- =========================================================================

    IF p_source_namespace = 'auth.users.id' THEN
        IF NOT public.vida_auth_user_exists(v_uuid_value) THEN
            RAISE EXCEPTION 'canonical_reconcile: auth.users.id % não existe no momento da reconciliação (MIG-RECON-005: existência validada AGORA, nunca dependente depois)',
                v_uuid_value;
        END IF;
    END IF;

    -- =========================================================================
    -- (6) BUSCAR OU CONSTATAR AUSÊNCIA da reconciliation_source, já sob lock.
    -- =========================================================================

    SELECT * INTO v_source
    FROM public.reconciliation_source
    WHERE source_namespace = p_source_namespace
      AND source_value = v_canonical_value;

    -- =========================================================================
    -- (7) TERMINAL CORRENTE — reaproveita canonical_reconciliation() (B2).
    -- K = 'infinity': dentro do write path queremos o estado corrente
    -- ABSOLUTO entre todos os records já visíveis, não uma leitura sujeita
    -- a nuances de relógio de parede.
    -- =========================================================================

    IF v_source.id IS NOT NULL THEN
        v_terminal := public.canonical_reconciliation(v_source.id, 'infinity'::timestamptz);
    END IF;

    v_result := CASE p_decision
                    WHEN 'CONFIRMED_NEW' THEN 'CONFIRMED'
                    WHEN 'CONFIRMED_EXISTING' THEN 'CONFIRMED'
                    ELSE p_decision
                END;

    -- =========================================================================
    -- (8) GATE DE REVISÃO DELIBERADA — correção central desta rodada:
    -- estado divergente do terminal NUNCA grava automaticamente. Apenas
    -- p_deliberate_revision=true autoriza. Sem terminal (primeira decisão
    -- da source), a flag é irrelevante e sempre prossegue.
    -- =========================================================================

    IF v_terminal.id IS NULL THEN
        NULL; -- primeira decisão da source: sempre prossegue, flag irrelevante.

    ELSIF v_terminal.result <> v_result THEN
        -- estado claramente diferente (ex.: BLOCKED -> CONFIRMED, ou
        -- CONFIRMED -> REJECTED)
        IF NOT p_deliberate_revision THEN
            RAISE EXCEPTION 'canonical_reconcile: estado solicitado (%) diverge do terminal corrente (%) para esta source — revisão deliberada exigida (p_deliberate_revision=true). Nenhuma escrita automática de estado divergente é permitida.',
                v_result, v_terminal.result;
        END IF;
        -- true: prossegue (correção/revisão genuína).

    ELSIF v_result = 'CONFIRMED' AND p_decision = 'CONFIRMED_NEW' THEN
        -- terminal já CONFIRMED e a chamada pede CONFIRMED_NEW de novo,
        -- com p_record_id NOVO (o retry-check em (3) já teria retornado
        -- se fosse o mesmo p_record_id) -- não há como provar com
        -- segurança que se trata da mesma entidade sem fingerprint, então
        -- esta combinação SEMPRE exige revisão deliberada, mesmo que
        -- "pareça" o mesmo resultado.
        IF NOT p_deliberate_revision THEN
            RAISE EXCEPTION 'canonical_reconcile: terminal já CONFIRMED e CONFIRMED_NEW não permite comparar com segurança se a entidade pretendida é a mesma (display_name não é identidade) — revisão deliberada exigida (p_deliberate_revision=true) para criar explicitamente uma nova reconciliação para esta source.';
        END IF;
        -- true: prossegue (nova entidade deliberadamente).

    ELSIF v_result = 'CONFIRMED' AND p_decision = 'CONFIRMED_EXISTING' THEN
        IF v_terminal.economic_entity_id = p_economic_entity_id THEN
            IF NOT p_deliberate_revision THEN
                RETURN v_terminal; -- NOOP: mesmo estado, comparação segura, sem flag.
            END IF;
            -- true: prossegue (reafirmação deliberada do mesmo estado).
        ELSE
            IF NOT p_deliberate_revision THEN
                RAISE EXCEPTION 'canonical_reconcile: CONFIRMED_EXISTING para economic_entity_id % diverge da entidade do terminal corrente (%) — revisão deliberada exigida (p_deliberate_revision=true).',
                    p_economic_entity_id, v_terminal.economic_entity_id;
            END IF;
            -- true: prossegue (correção para outra entidade).
        END IF;

    ELSE
        -- BLOCKED/REJECTED com mesmo result do terminal (comparação
        -- segura, sem envolver entity_id nenhum)
        IF NOT p_deliberate_revision THEN
            RETURN v_terminal; -- NOOP.
        END IF;
        -- true: prossegue (reafirmação deliberada do mesmo estado).
    END IF;

    -- =========================================================================
    -- (9) ESCRITA — só alcançada quando: primeira decisão da source, OU
    -- p_deliberate_revision=true explícito. Falha em qualquer ponto daqui
    -- em diante reverte TUDO que este bloco já tiver inserido nesta
    -- chamada (atomicidade de statement do Postgres, cobre o Caso 33 sem
    -- SAVEPOINT explícito, desde que o caller não engula a exceção).
    -- =========================================================================

    IF v_source.id IS NULL THEN
        INSERT INTO public.reconciliation_source (source_namespace, source_value)
        VALUES (p_source_namespace, v_canonical_value)
        RETURNING * INTO v_source;
    END IF;

    IF p_decision = 'CONFIRMED_NEW' THEN
        INSERT INTO public.economic_entities (entity_type, display_name)
        VALUES (p_entity_type, p_display_name)
        RETURNING id INTO v_target_entity_id;
    ELSIF p_decision = 'CONFIRMED_EXISTING' THEN
        IF NOT EXISTS (SELECT 1 FROM public.economic_entities WHERE id = p_economic_entity_id) THEN
            RAISE EXCEPTION 'canonical_reconcile: CONFIRMED_EXISTING referencia economic_entity_id % que não existe',
                p_economic_entity_id;
        END IF;
        v_target_entity_id := p_economic_entity_id;
    ELSE
        v_target_entity_id := NULL;  -- BLOCKED/REJECTED
    END IF;

    -- recorded_at system-assigned, monotônico -- calculado AQUI, depois de
    -- ambos os locks, nunca antes. clock_timestamp() + greatest() contra o
    -- predecessor garante estrita monotonicidade mesmo diante de
    -- ajuste/resolução de relógio. Nunca chamado de "timestamp de commit"
    -- -- Postgres não conhece antecipadamente o instante de commit.
    IF v_terminal.id IS NOT NULL THEN
        v_recorded_at := greatest(clock_timestamp(), v_terminal.recorded_at + interval '1 microsecond');
    ELSE
        v_recorded_at := clock_timestamp();
    END IF;

    INSERT INTO public.reconciliation_record (
        id,
        reconciliation_source_id,
        result,
        economic_entity_id,
        supersedes_reconciliation_record_id,
        recorded_at,
        decided_by,
        decided_note
    ) VALUES (
        p_record_id,
        v_source.id,
        v_result,
        v_target_entity_id,
        v_terminal.id,   -- NULL se for raiz
        v_recorded_at,
        p_decided_by,
        p_decided_note
    )
    RETURNING * INTO v_new_record;

    RETURN v_new_record;
END;
$$;

COMMENT ON FUNCTION public.canonical_reconcile(uuid, text, text, text, text, text, uuid, text, text, boolean) IS
'Único caminho operacional de escrita para reconciliation_source/
reconciliation_record e, quando aplicável, para a criação de uma nova
economic_entities. Fechamento por privilégios (SECURITY DEFINER, ausência
de acesso direto às tabelas para o papel operacional) é responsabilidade
de B4.

Dois locks em espaços fisicamente distintos (bigint para operação, int4+int4
para source), ordem SEMPRE fixa dentro de uma invocação (operação antes de
source). CONTRATO v0.1: uma operação de reconciliação por transação --
múltiplas reconciliações distintas na mesma transação não são suportadas
(a ordem de locks não cobre esse caso).

Idempotência de RETRY: p_record_id identifica a OPERAÇÃO. Reexecutar com
mesmo p_record_id valida apenas o IMUTAVELMENTE demonstrável pelo banco
(mesma source, mesmo result, e para CONFIRMED_EXISTING o mesmo
economic_entity_id) -- nunca compara display_name/entity_type, que são
mutáveis e não são identidade (B1). Payload inconsistente com o já
persistido falha explicitamente como reuso indevido.

Revisão deliberada: gravar um estado que diverge do terminal corrente
exige p_deliberate_revision=true explícito, sempre -- nunca automático,
mesmo quando o estado "parece" razoável. Isso fecha o caso de um retry
atrasado (ex.: um BLOCKED antigo chegando depois de já existir um
CONFIRMED mais recente) tentar regredir o estado silenciosamente. Quando
o estado solicitado JÁ coincide com o terminal corrente E a comparação é
segura (nunca via display_name -- portanto nunca para CONFIRMED_NEW),
p_deliberate_revision=false retorna NOOP.

Não cria ClientAccount, associações nem entity_relationships em nenhuma
circunstância (MIG-NOAUTO-001 absoluto).';


-- =============================================================================
-- FIM DE B3 — nenhum GRANT/REVOKE, nenhum OWNS-001, nenhum Canonical
-- Rollback Guard, nenhuma criação de ClientAccount/associações/owns.
-- Próximo: B4 (SECURITY DEFINER + search_path/owner desta função, modelo
-- de privilégios completo, OWNS-001, Canonical Rollback Guard, checkpoint
-- de catálogo).
-- =============================================================================

-- #############################################################################
-- ### BLOCO B3 — FIM
-- #############################################################################


-- #############################################################################
-- ### BLOCO B4 — ENFORCEMENT LATERAL + SEGURANÇA OPERACIONAL (início)
-- #############################################################################

-- STATUS: DRAFT PARA REVISÃO — não aplicar ainda, nem em ensaio.
-- Depende de B1+B2+B3 já aplicados no mesmo ambiente. B3 recebeu duas
-- emendas de integração (FOR KEY SHARE -> SELECT simples; depois
-- acesso direto a auth.users -> bridge vida_auth_user_exists()).
--
-- ESCOPO DESTE BLOCO:
--   1. OWNS-001 concorrência-segura nos dois sentidos.
--   2. Modelo de privilégios completo -- ORDEM CORRIGIDA: configurar
--      SECURITY DEFINER/ACLs/REVOKE enquanto o executor ainda é owner,
--      só então transferir ownership como etapa quase-final. Membership
--      de "postgres" em vida_identity_owner concedida explicitamente com
--      SET TRUE, INHERIT FALSE (correção desta rodada, confirmada na
--      documentação do Postgres 17: CREATE ROLE por um CREATEROLE
--      não-superuser NÃO concede SET ROLE automaticamente). Acesso a
--      Auth exclusivamente via bridge de B3, nunca GRANT direto no
--      schema auth ou em auth.users a vida_identity_owner (correção
--      desta rodada, a partir de inspeção real do catálogo do ambiente
--      de ensaio).
--   3. Canonical Rollback Guard, SECURITY DEFINER, alcançável via papel
--      próprio (vida_identity_rollback_operator), sem depender de
--      superuser (Supabase não concede superuser real a "postgres" --
--      confirmado).
--
-- O CHECKPOINT DE CATÁLOGO NÃO ESTÁ NESTE ARQUIVO (correção desta
-- rodada) -- o Migration Design congelado exige que ele seja read-only
-- e PÓS-DEPLOY em produção, fisicamente separado da transação de
-- instalação (um SELECT que "der errado" não aborta uma migration). Ver
-- migration_b_identity_phase1_postdeploy_check.sql.
--
-- DECISÕES FIXADAS ANTES DO CÓDIGO:
--   - decided_by permanece atestação administrativa explícita nesta v0.1;
--   - owner técnico dedicado (vida_identity_owner), nunca "postgres";
--   - owner e operador são papéis SEPARADOS;
--   - EXECUTE em canonical_reconcile NÃO é concedido a service_role;
--   - Canonical Rollback Guard usa lista GOVERNADA de objetos, nunca
--     DROP ... CASCADE, e não se autodestrói durante a própria execução.
-- =============================================================================


-- =============================================================================
-- 1 — OWNS-001, concorrência-segura nos dois sentidos
-- =============================================================================

CREATE FUNCTION public.entity_relationships_enforce_owns_target()
RETURNS trigger
LANGUAGE plpgsql
AS $$
DECLARE
    v_target public.economic_entities;
BEGIN
    IF NEW.relationship_type = 'owns' THEN
        SELECT * INTO v_target
        FROM public.economic_entities
        WHERE id = NEW.to_entity_id
        FOR SHARE;

        IF NOT FOUND THEN
            RAISE EXCEPTION 'entity_relationships: to_entity_id % não existe',
                NEW.to_entity_id;
        END IF;

        IF v_target.entity_type <> 'organization' THEN
            RAISE EXCEPTION 'entity_relationships: OWNS-001 -- relationship_type=owns exige to_entity_id com entity_type=organization (encontrado: %)',
                v_target.entity_type;
        END IF;
    END IF;
    RETURN NEW;
END;
$$;

CREATE TRIGGER trg_entity_relationships_enforce_owns_target
    BEFORE INSERT OR UPDATE ON public.entity_relationships
    FOR EACH ROW
    EXECUTE FUNCTION public.entity_relationships_enforce_owns_target();

COMMENT ON TRIGGER trg_entity_relationships_enforce_owns_target ON public.entity_relationships IS
'OWNS-001, lado A. FOR SHARE no target antes de validar entity_type -- um
FOR SHARE conflita com o lock implícito de um UPDATE concorrente na mesma
linha (lado B, abaixo), serializando as duas operações.';


CREATE FUNCTION public.economic_entities_protect_owns_target()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
    IF OLD.entity_type = 'organization' AND NEW.entity_type = 'person' THEN
        IF EXISTS (
            SELECT 1 FROM public.entity_relationships
            WHERE to_entity_id = OLD.id AND relationship_type = 'owns'
        ) THEN
            RAISE EXCEPTION 'economic_entities: OWNS-001 -- não é possível mudar entity_type de organization para person: entidade % é alvo de pelo menos uma relação owns',
                OLD.id;
        END IF;
    END IF;
    RETURN NEW;
END;
$$;

CREATE TRIGGER trg_economic_entities_protect_owns_target
    BEFORE UPDATE OF entity_type ON public.economic_entities
    FOR EACH ROW
    EXECUTE FUNCTION public.economic_entities_protect_owns_target();

COMMENT ON TRIGGER trg_economic_entities_protect_owns_target ON public.economic_entities IS
'OWNS-001, lado B. Combinado com o FOR SHARE do lado A: um INSERT de owns
concorrente com este UPDATE de entity_type fica serializado pelo conflito
de locks.';


-- =============================================================================
-- 2 — MODELO DE PRIVILÉGIOS (ordem corrigida nesta rodada)
-- =============================================================================

-- -----------------------------------------------------------------------------
-- 2.1 — papéis técnicos NOLOGIN. Sem IF NOT EXISTS -- mesma disciplina de
-- B2: se já existir, FALHA explicitamente.
-- -----------------------------------------------------------------------------

CREATE ROLE vida_identity_owner NOLOGIN;
CREATE ROLE vida_reconciliation_operator NOLOGIN;
CREATE ROLE vida_identity_rollback_operator NOLOGIN;

COMMENT ON ROLE vida_identity_owner IS
'Owner técnico de todos os objetos canônicos de Identity. NUNCA "postgres".
Nenhuma capacidade de INSERT/UPDATE/DELETE nas tabelas legadas.';

COMMENT ON ROLE vida_reconciliation_operator IS
'Papel operacional restrito. Única permissão: EXECUTE em
canonical_reconcile + USAGE no schema public. Nenhum acesso direto às 7
tabelas canônicas. NÃO concedido a service_role nesta migration.';

COMMENT ON ROLE vida_identity_rollback_operator IS
'Papel administrativo SEPARADO, exclusivo para rollback estrutural. Única
permissão: EXECUTE em canonical_rollback_guard. Nenhum acesso a DML
canônico -- o reconciliador nunca pode destruir a estrutura, e este papel
nunca recebe DML canônico. Acesso real (login/membership) a este papel é
concedido administrativamente, fora desta migration, só quando uma
operação de rollback for de fato necessária.';

-- -----------------------------------------------------------------------------
-- 2.2 — preparar a transferência de ownership: o executor desta migration
-- precisa conseguir SET ROLE para vida_identity_owner, e o novo owner
-- precisa de CREATE no schema public -- ambos concedidos agora,
-- revogados/ajustados ao final (2.9). Supabase não concede superuser
-- real ao papel "postgres" (confirmado) -- por isso este passo é
-- necessário e não pode ser contornado por bypass de superuser.
--
-- Correção desta rodada, confirmada na documentação oficial do
-- PostgreSQL 17: quando um não-superuser com CREATEROLE cria um papel,
-- o Postgres concede de volta a membership automaticamente com
-- "ADMIN TRUE, SET FALSE, INHERIT FALSE" -- ou seja, "postgres" NÃO
-- ganha capacidade de SET ROLE automaticamente só por ter criado
-- vida_identity_owner em 2.1. Precisa ser concedido explicitamente:
-- -----------------------------------------------------------------------------

GRANT vida_identity_owner TO postgres WITH SET TRUE, INHERIT FALSE;
-- INHERIT FALSE deliberado: "postgres" ganha capacidade de SET ROLE
-- (necessária para ALTER ... OWNER TO), mas NÃO herda passivamente os
-- privilégios de vida_identity_owner no dia a dia -- evita que a fronteira
-- de privilégio mínimo do owner técnico seja silenciosamente contornada
-- por herança automática.
GRANT CREATE, USAGE ON SCHEMA public TO vida_identity_owner;
GRANT USAGE ON SCHEMA public TO vida_reconciliation_operator;
GRANT USAGE ON SCHEMA public TO vida_identity_rollback_operator;

-- -----------------------------------------------------------------------------
-- 2.3 — SECURITY DEFINER + search_path em canonical_reconcile, AINDA sob
-- o owner original (ALTER FUNCTION não exige ser o security definer
-- alvo, só o owner atual do objeto).
-- -----------------------------------------------------------------------------

ALTER FUNCTION public.canonical_reconcile(uuid, text, text, text, text, text, uuid, text, text, boolean)
    SECURITY DEFINER
    SET search_path = pg_catalog, pg_temp;

-- pg_temp explicitamente por ÚLTIMO (correção desta rodada, confirmada
-- na documentação oficial do Postgres: "A secure arrangement can be
-- obtained by forcing the temporary schema to be searched last. To do
-- this, write pg_temp as the last entry in search_path") -- sem isso,
-- o schema temporário recebe tratamento especial e é buscado primeiro
-- por padrão, sendo normalmente gravável por qualquer sessão; um
-- objeto criado ali poderia mascarar um objeto real que a função
-- espera resolver sem qualificação de schema.

-- -----------------------------------------------------------------------------
-- 2.4 — acesso a Auth: NENHUM grant direto a vida_identity_owner.
-- Correção desta rodada, a partir de inspeção real do catálogo do
-- ambiente de ensaio: "postgres" tem USAGE no schema auth SEM grant
-- option (não pode repassar) e SELECT WITH GRANT OPTION em auth.users
-- especificamente (poderia repassar, mas isso ampliaria a superfície de
-- vida_identity_owner sobre uma tabela inteira do schema Auth além do
-- necessário). O acesso passa exclusivamente pelo bridge
-- vida_auth_user_exists() -- criado em B3, owned por "postgres" (NUNCA
-- transferido para vida_identity_owner em 2.9), REVOKE/GRANT abaixo:
-- -----------------------------------------------------------------------------

REVOKE ALL ON FUNCTION public.vida_auth_user_exists(uuid)
    FROM PUBLIC, anon, authenticated, service_role,
         vida_reconciliation_operator, vida_identity_rollback_operator;

GRANT EXECUTE ON FUNCTION public.vida_auth_user_exists(uuid)
    TO vida_identity_owner;

-- -----------------------------------------------------------------------------
-- 2.5 — fronteira explícita contra o legado (defesa em profundidade)
-- -----------------------------------------------------------------------------

REVOKE ALL PRIVILEGES ON
    public.users_profile,
    public.prontuario_patrimonial,
    public.diagnosticos,
    public.diagnosticos_vida
FROM vida_identity_owner;

-- -----------------------------------------------------------------------------
-- 2.6 — REVOKE ALL dos papéis genéricos nas 7 tabelas canônicas.
-- Correção desta rodada: um REVOKE remove privilégios EXISTENTES no
-- momento em que roda -- não é uma barreira permanente contra um GRANT
-- futuro. O release gate (4) precisa reconfirmar isso por privilégio
-- efetivo a cada execução, nunca presumir que o REVOKE de hoje protege
-- para sempre.
-- -----------------------------------------------------------------------------

REVOKE ALL PRIVILEGES ON
    public.economic_entities,
    public.entity_relationships,
    public.client_accounts,
    public.client_account_entities,
    public.client_account_users,
    public.reconciliation_source,
    public.reconciliation_record
FROM PUBLIC, anon, authenticated, service_role;

-- -----------------------------------------------------------------------------
-- 2.7 — REVOKE ALL nas funções canônicas, de TODAS as roles genéricas
-- explicitamente -- correção desta rodada: antes só revogava de PUBLIC,
-- embora o cabeçalho já declarasse que anon/authenticated/service_role
-- não teriam acesso. A política não deve depender da ausência presumida
-- de grants específicos a essas roles -- revoga de todas explicitamente.
-- -----------------------------------------------------------------------------

REVOKE ALL ON FUNCTION public.canonical_reconciliation(uuid, timestamptz)
    FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON FUNCTION public.canonical_reconcile(uuid, text, text, text, text, text, uuid, text, text, boolean)
    FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON FUNCTION public.reconciliation_source_block_mutation()
    FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON FUNCTION public.reconciliation_record_block_mutation()
    FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON FUNCTION public.reconciliation_record_validate_succession()
    FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON FUNCTION public.entity_relationships_enforce_owns_target()
    FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON FUNCTION public.economic_entities_protect_owns_target()
    FROM PUBLIC, anon, authenticated, service_role;

-- -----------------------------------------------------------------------------
-- 2.8 — únicos GRANTs positivos desta migration
-- -----------------------------------------------------------------------------

GRANT EXECUTE ON FUNCTION public.canonical_reconcile(uuid, text, text, text, text, text, uuid, text, text, boolean)
    TO vida_reconciliation_operator;

-- (GRANT do rollback guard ao vida_identity_rollback_operator ocorre em
-- (3), depois que a função existir e virar SECURITY DEFINER.)


-- =============================================================================
-- 3 — CANONICAL ROLLBACK GUARD
-- =============================================================================

CREATE FUNCTION public.canonical_rollback_guard()
RETURNS void
LANGUAGE plpgsql
AS $$
BEGIN
    IF EXISTS (SELECT 1 FROM public.reconciliation_record) THEN
        RAISE EXCEPTION 'canonical_rollback_guard: existe pelo menos um reconciliation_record -- rollback estrutural RECUSADO. Ver MIG-ROLLBACK-001 janela 2.';
    END IF;

    DROP TRIGGER IF EXISTS trg_economic_entities_protect_owns_target ON public.economic_entities;
    DROP TRIGGER IF EXISTS trg_entity_relationships_enforce_owns_target ON public.entity_relationships;
    DROP TRIGGER IF EXISTS trg_reconciliation_record_validate_succession ON public.reconciliation_record;
    DROP TRIGGER IF EXISTS trg_reconciliation_record_immutable ON public.reconciliation_record;
    DROP TRIGGER IF EXISTS trg_reconciliation_source_immutable ON public.reconciliation_source;

    DROP FUNCTION IF EXISTS public.economic_entities_protect_owns_target();
    DROP FUNCTION IF EXISTS public.entity_relationships_enforce_owns_target();
    DROP FUNCTION IF EXISTS public.reconciliation_record_validate_succession();
    DROP FUNCTION IF EXISTS public.reconciliation_record_block_mutation();
    DROP FUNCTION IF EXISTS public.reconciliation_source_block_mutation();

    DROP FUNCTION IF EXISTS public.canonical_reconcile(uuid, text, text, text, text, text, uuid, text, text, boolean);
    DROP FUNCTION IF EXISTS public.canonical_reconciliation(uuid, timestamptz);

    DROP TABLE IF EXISTS public.reconciliation_record;
    DROP TABLE IF EXISTS public.reconciliation_source;
    DROP TABLE IF EXISTS public.client_account_users;
    DROP TABLE IF EXISTS public.client_account_entities;
    DROP TABLE IF EXISTS public.client_accounts;
    DROP TABLE IF EXISTS public.entity_relationships;
    DROP TABLE IF EXISTS public.economic_entities;

    -- papéis (vida_identity_owner, vida_reconciliation_operator,
    -- vida_identity_rollback_operator) NÃO são removidos aqui -- decisão
    -- deliberada, mesma justificativa da versão anterior.

    -- este guard NÃO se autodestrói -- permanece como sentinela
    -- administrativo. Sua remoção é cleanup explícito separado.
END;
$$;

REVOKE ALL ON FUNCTION public.canonical_rollback_guard()
    FROM PUBLIC, anon, authenticated, service_role;

-- Correção desta rodada: torna o guard SECURITY DEFINER e alcançável por
-- um papel operacional próprio, em vez de depender de "owner/superuser"
-- -- Supabase não concede superuser real ao papel "postgres" (confirmado
-- na documentação oficial), então "só owner/superuser alcança" tornaria
-- o "único caminho suportado" de rollback um caminho que ninguém
-- consegue usar normalmente em produção.

ALTER FUNCTION public.canonical_rollback_guard()
    SECURITY DEFINER
    SET search_path = pg_catalog, pg_temp;
-- pg_temp por último, mesma razão de canonical_reconcile acima --
-- crítico aqui em particular, já que este guard executa DROP TABLE/
-- DROP FUNCTION; qualquer resolução de nome sem qualificação de schema
-- capturada por um objeto em pg_temp seria um vetor de escalação sério.

GRANT EXECUTE ON FUNCTION public.canonical_rollback_guard()
    TO vida_identity_rollback_operator;

COMMENT ON FUNCTION public.canonical_rollback_guard() IS
'Único caminho suportado para rollback estrutural de Migration B (Caso
30/31). Recusa automaticamente se existir qualquer reconciliation_record.
SECURITY DEFINER, alcançável apenas via EXECUTE concedido a
vida_identity_rollback_operator -- papel separado de
vida_reconciliation_operator: quem reconcilia nunca pode fazer rollback,
quem faz rollback nunca recebe DML canônico. DDL manual fora deste guard,
por quem tiver privilégio administrativo suficiente no cluster,
permanece fisicamente possível -- isso é break-glass explícito, nunca
parte do contrato normal desta migration.';


-- =============================================================================
-- 2.9 — TRANSFERÊNCIA DE OWNERSHIP (etapa quase-final, agora que
-- SECURITY DEFINER/REVOKE/GRANT/guard já estão prontos)
-- =============================================================================

ALTER TABLE public.economic_entities        OWNER TO vida_identity_owner;
ALTER TABLE public.entity_relationships      OWNER TO vida_identity_owner;
ALTER TABLE public.client_accounts           OWNER TO vida_identity_owner;
ALTER TABLE public.client_account_entities   OWNER TO vida_identity_owner;
ALTER TABLE public.client_account_users      OWNER TO vida_identity_owner;
ALTER TABLE public.reconciliation_source     OWNER TO vida_identity_owner;
ALTER TABLE public.reconciliation_record     OWNER TO vida_identity_owner;

ALTER FUNCTION public.canonical_reconciliation(uuid, timestamptz)
    OWNER TO vida_identity_owner;
ALTER FUNCTION public.canonical_reconcile(uuid, text, text, text, text, text, uuid, text, text, boolean)
    OWNER TO vida_identity_owner;
ALTER FUNCTION public.reconciliation_source_block_mutation()
    OWNER TO vida_identity_owner;
ALTER FUNCTION public.reconciliation_record_block_mutation()
    OWNER TO vida_identity_owner;
ALTER FUNCTION public.reconciliation_record_validate_succession()
    OWNER TO vida_identity_owner;
ALTER FUNCTION public.entity_relationships_enforce_owns_target()
    OWNER TO vida_identity_owner;
ALTER FUNCTION public.economic_entities_protect_owns_target()
    OWNER TO vida_identity_owner;
ALTER FUNCTION public.canonical_rollback_guard()
    OWNER TO vida_identity_owner;

-- -----------------------------------------------------------------------------
-- 2.10 — cleanup: revogar CREATE de vida_identity_owner no schema public
-- (mantém USAGE, que continua necessário). A membership de "postgres" em
-- vida_identity_owner permanece (não revogada) -- necessária para
-- futuras migrations que precisem alterar estes objetos; "postgres" já
-- é o papel administrativo elevado do Supabase, manter essa membership
-- não amplia superfície de risco relevante.
-- -----------------------------------------------------------------------------

REVOKE CREATE ON SCHEMA public FROM vida_identity_owner;


-- =============================================================================
-- OBRIGAÇÃO REGISTRADA PARA A OPERAÇÃO C (ponto não-bloqueante desta
-- rodada, deliberadamente FORA do escopo de Migration B):
--
-- vida_reconciliation_operator é NOLOGIN. Este arquivo não define quem
-- recebe capacidade temporária de SET ROLE para ele -- isso pertence ao
-- procedimento operacional da Operação C (Bloco 4 do Migration Design),
-- não a esta migration de instalação. A Operação C precisa documentar
-- explicitamente:
--   1. conceder temporariamente SET ao executor administrativo daquela
--      rodada (ex.: GRANT vida_reconciliation_operator TO <executor>
--      WITH SET TRUE, INHERIT FALSE -- mesma disciplina fixada em 2.2
--      para vida_identity_owner);
--   2. SET ROLE vida_reconciliation_operator;
--   3. executar UMA reconciliação por transação (contrato já fixado em
--      B3);
--   4. RESET ROLE;
--   5. revogar a membership temporária ao final da rodada, se não for
--      permanente por decisão administrativa.
--
-- O owner (vida_identity_owner) continua como break-glass administrativo
-- -- nunca como caminho normal de operação.
-- =============================================================================


-- =============================================================================
-- FIM DE B4 — último bloco de autoria antes da consolidação. O checkpoint
-- de catálogo NÃO faz parte deste arquivo (correção desta rodada -- o
-- Migration Design congelado exige que ele seja read-only e PÓS-DEPLOY em
-- produção, nunca incorporado à transação de instalação, já que um
-- SELECT que "der errado" não aborta a migration). Ver arquivo separado:
-- migration_b_identity_phase1_postdeploy_check.sql.
--
-- Próximo passo: revisão de B4, depois consolidação de B1+B2+B3+B4 em
-- migration_b_identity_phase1.sql transacional único.
-- =============================================================================

-- #############################################################################
-- ### BLOCO B4 — FIM
-- #############################################################################


COMMIT;


-- =============================================================================
-- FIM DE migration_b_identity_phase1.sql -- artefato único, consolidação
-- mecânica de B1+B2+B3+B4, nenhuma alteração semântica introduzida na
-- concatenação. Checkpoint pós-deploy permanece arquivo separado
-- (migration_b_identity_phase1_postdeploy_check.sql). Não aplicar ainda
-- em nenhum ambiente -- próximo passo: revisão estática deste arquivo
-- único, depois aplicação em ensaio + Release Gate 3.13 completo.
-- =============================================================================
