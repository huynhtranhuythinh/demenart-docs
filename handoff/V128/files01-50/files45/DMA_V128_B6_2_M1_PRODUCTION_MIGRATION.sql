-- =====================================================================
-- V128-B6.2 · MIGRATION M1 (PRODUCTION — NOT YET APPLIED)
-- GOVERNANCE SCHEMA FOUNDATION (governance evidence foundation)
-- Additive + dormant: no runtime wiring; nothing reads these until M4.
-- D92 three-block · single transaction · RAISE in BLOCK-3 → atomic rollback.
-- Grounded: policy_registry PK=code (8 cols); registry UNIQUE(object_type,action_key)
--   → policies.action_key is a SOFT reference (no FK); gen_random_uuid available.
-- =====================================================================

-- =====================================================================
-- BLOCK-1 : DDL
-- =====================================================================
CREATE SCHEMA IF NOT EXISTS mc_internal;

-- Declarative authorization policy (source of authz rule; risk stays in registry)
CREATE TABLE IF NOT EXISTS public.mission_control_action_policies (
  action_key          text PRIMARY KEY,                 -- soft-ref registry.action_key (registry untouched)
  required_scope      text NOT NULL
                        CHECK (required_scope IN ('platform','tenant','assignment')),
  min_role_set        text[] NOT NULL DEFAULT '{}',      -- compared as v_role::text (robust vs enum drift)
  required_capability text NULL,                         -- DORMANT (frozen; evaluator ignores)
  policy_version      text NOT NULL DEFAULT 'b6.2-v1',
  lifecycle           text NOT NULL DEFAULT 'shadow'
                        CHECK (lifecycle IN ('shadow','enforcing','disabled')),
  evaluator           text NOT NULL DEFAULT 'mc_internal.evaluate_action_policy',
  created_at          timestamptz NOT NULL DEFAULT now(),
  updated_at          timestamptz NOT NULL DEFAULT now()
);

-- Governance evidence (authorization decision ledger — SEPARATE from execution ledger)
CREATE TABLE IF NOT EXISTS public.mission_control_action_authorizations (
  id             uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  request_id     uuid NOT NULL,                          -- soft link → mission_control_action_requests.request_id
  actor_id       uuid NOT NULL,
  action_key     text NOT NULL,
  object_type    text NOT NULL,
  object_id      uuid NOT NULL,
  decision       text NOT NULL CHECK (decision IN ('allow','deny')),
  reason_code    text NULL,
  policy_version text NOT NULL,
  risk_level     text NOT NULL,
  lifecycle      text NOT NULL,
  evaluated      jsonb NOT NULL DEFAULT '{}'::jsonb,
  actual_outcome text NULL,                              -- shadow divergence: authz_allow|authz_deny|business_fail
  created_at     timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_mc_action_authz_request
  ON public.mission_control_action_authorizations (request_id);
CREATE INDEX IF NOT EXISTS idx_mc_action_authz_action_time
  ON public.mission_control_action_authorizations (action_key, created_at DESC);

ALTER TABLE public.mission_control_action_policies       ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.mission_control_action_authorizations ENABLE ROW LEVEL SECURITY;

-- admin-only SELECT (mirrors policy_registry_select_admin). No write policy → client writes denied.
CREATE POLICY mc_action_policies_select_admin
  ON public.mission_control_action_policies
  FOR SELECT TO authenticated USING (public.is_admin());

CREATE POLICY mc_action_authz_select_admin
  ON public.mission_control_action_authorizations
  FOR SELECT TO authenticated USING (public.is_admin());

-- =====================================================================
-- BLOCK-2 : ACL HARDEN (D231)
-- =====================================================================
REVOKE ALL ON SCHEMA mc_internal FROM PUBLIC;
GRANT  USAGE ON SCHEMA mc_internal TO authenticated;     -- for INVOKER execute → commit-core (M3)

REVOKE ALL ON public.mission_control_action_policies       FROM PUBLIC, anon, authenticated;
REVOKE ALL ON public.mission_control_action_authorizations FROM PUBLIC, anon, authenticated;
GRANT  SELECT ON public.mission_control_action_policies       TO authenticated;  -- RLS gates to admin
GRANT  SELECT ON public.mission_control_action_authorizations TO authenticated;  -- RLS gates to admin
-- No INSERT/UPDATE/DELETE grant to client roles → only DEFINER commit-core (postgres) writes.

-- SEED — class.assign ONLY (no class.edit / session / subscription / support_case / enrollment)
INSERT INTO public.mission_control_action_policies
  (action_key, required_scope, min_role_set, required_capability, policy_version, lifecycle)
VALUES
  ('class.assign', 'tenant', ARRAY['master_admin','sub_admin']::text[], NULL, 'b6.2-v1', 'shadow')
ON CONFLICT (action_key) DO NOTHING;

-- policy_registry documentation row (house-style; exact columns per live schema)
INSERT INTO public.policy_registry
  (code, title, active_version, classification, defined_in, summary, admin_editable)
VALUES (
  'mission_control_action_governance',
  'Mission Control — Action Authorization Governance',
  'b6.2-v1',
  'VERSIONED_POLICY',
  'mc_internal.evaluate_action_policy + public.mission_control_action_policies',
  $seed${"scope_allowlist":["platform","tenant","assignment"],"deny_precedence":"first-failing-gate; fail-closed","risk_tiers":{"LOW":"audit_only","MEDIUM":"evidence_required","HIGH/CRITICAL":"declared-only"},"evidence_layer":"public.mission_control_action_authorizations (separate from execution ledger)","governed":["class.assign"],"capability":"reserved/dormant"}$seed$::jsonb,
  false
)
ON CONFLICT (code) DO NOTHING;

-- =====================================================================
-- BLOCK-3 : VERIFY
-- =====================================================================
DO $verify$
BEGIN
  IF to_regnamespace('mc_internal') IS NULL THEN RAISE EXCEPTION 'M1 FAIL: schema mc_internal missing'; END IF;
  IF to_regclass('public.mission_control_action_policies') IS NULL
     OR to_regclass('public.mission_control_action_authorizations') IS NULL
     THEN RAISE EXCEPTION 'M1 FAIL: governance tables missing'; END IF;

  IF NOT (SELECT relrowsecurity FROM pg_class WHERE oid='public.mission_control_action_policies'::regclass)
     OR NOT (SELECT relrowsecurity FROM pg_class WHERE oid='public.mission_control_action_authorizations'::regclass)
     THEN RAISE EXCEPTION 'M1 FAIL: RLS not enabled'; END IF;

  -- only SELECT policies exist (no client write path)
  IF EXISTS (SELECT 1 FROM pg_policies
             WHERE schemaname='public'
               AND tablename IN ('mission_control_action_policies','mission_control_action_authorizations')
               AND cmd <> 'SELECT')
     THEN RAISE EXCEPTION 'M1 FAIL: unexpected non-SELECT policy'; END IF;

  -- client cannot write governance tables
  IF has_table_privilege('authenticated','public.mission_control_action_policies','INSERT')
     OR has_table_privilege('authenticated','public.mission_control_action_policies','UPDATE')
     OR has_table_privilege('authenticated','public.mission_control_action_authorizations','INSERT')
     OR has_table_privilege('authenticated','public.mission_control_action_authorizations','UPDATE')
     THEN RAISE EXCEPTION 'M1 FAIL: authenticated must not write governance tables'; END IF;

  -- seed = exactly class.assign
  IF (SELECT count(*) FROM public.mission_control_action_policies) <> 1
     OR NOT EXISTS (SELECT 1 FROM public.mission_control_action_policies WHERE action_key='class.assign')
     THEN RAISE EXCEPTION 'M1 FAIL: seed must be exactly class.assign'; END IF;

  -- doc row correct
  IF NOT EXISTS (SELECT 1 FROM public.policy_registry
                 WHERE code='mission_control_action_governance'
                   AND classification='VERSIONED_POLICY' AND admin_editable=false)
     THEN RAISE EXCEPTION 'M1 FAIL: policy_registry doc row incorrect'; END IF;

  RAISE NOTICE 'M1 VERIFY PASS';
END $verify$;
-- ===================== END M1 (NOT APPLIED) ==========================
