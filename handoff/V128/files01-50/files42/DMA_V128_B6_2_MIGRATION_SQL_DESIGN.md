# V128-B6.2 — MIGRATION SQL DESIGN

> **Milestone:** V128-B6.2 · ACTION GOVERNANCE HARDENING · **SQL DESIGN ONLY**
> **Vai trò:** Builder (Claude) · Owner: Jean · CTO/CPO: ChatGPT
> **Ràng buộc:** blueprint SQL — **CHƯA production** · KHÔNG execute · KHÔNG apply · KHÔNG gọi DB · KHÔNG canonical · KHÔNG bump version.
> **Grounding:** live audit đầu phiên (tail `20260813113400`; owners=postgres; execute INVOKER; ledger policies `insert_own_processing`/`finish_own`/`select_own`; adapter `assign_class_distribution` DEFINER; `profile_role` enum tồn tại).

**Frozen:** PATH B (execute INVOKER **bất biến** → `mc_internal._mc_commit_action` DEFINER) · schema `mc_internal` (NOT PostgREST-exposed) · govern chỉ `class.assign` · capability dormant · risk LOW/MEDIUM/HIGH/CRITICAL (HIGH/CRITICAL declared-only) · lifecycle `shadow/enforcing/disabled`.

**Builder design decisions (nêu rõ):**
- **D-a** `_mc_commit_action` **KHÔNG** nhận `actor` từ caller → tự `current_profile()` nội bộ (chống forge identity qua direct-call, vì hàm buộc phải GRANT `authenticated`).
- **D-b** `_mc_commit_action` **KHÔNG** nhận `result_payload/status/completed_at` → result server-derived từ adapter.
- **D-c** `min_role_set = text[]` (so sánh `v_role::text`) — an toàn hơn `profile_role[]` khi chưa verify đủ nhãn enum. *(Confirm-able → §Open.)*
- **D-d** Risk **không** duplicate vào policies; `evaluate` join `mission_control_action_registry` đọc `risk_level` (single source).
- **D-e** M4 cài sẵn branch-logic gated theo `lifecycle` → **M5 = data-only UPDATE**; `execute` REPLACE **đúng 1 lần** (M3).

---

## SECTION 0 — GLOBAL SAFETY RULES

**D92 three-block** (mọi migration):
```
BLOCK-1  DDL        : CREATE / CREATE OR REPLACE / ALTER / DROP POLICY
BLOCK-2  ACL harden : REVOKE ALL FROM PUBLIC,anon,authenticated → GRANT tối thiểu (D231)
BLOCK-3  VERIFY     : DO $verify$ … IF NOT (...) THEN RAISE EXCEPTION … END IF; $verify$
```
- **D231:** `CREATE OR REPLACE FUNCTION` reset `proacl` + Supabase auto-grant anon/authenticated → **luôn** REVOKE lại tường minh ngay trong cùng migration.
- **Transaction boundary:** `apply_migration` wrap 1 transaction. `RAISE EXCEPTION` ở BLOCK-3 → **full atomic rollback** (không mutation nào sót). VERIFY thất bại = migration không land.
- **search_path='':** mọi function `SET search_path=''`; mọi object **fully-qualified** (`public.…`, `mc_internal.…`, `auth.uid()`).
- **Dollar-quote:** function body `$fn$`; verify `$verify$`; seed literal `$seed$` — tránh collision.
- **Rollback rule:** mỗi migration có rollback script **non-destructive**; business data (`class_distributions`/`audit_logs`/ledger business rows) **không bao giờ** bị đụng.
- **Verify ≠ apply:** trong giai đoạn thiết kế/thử, verify bằng rollback-safe simulation (`DO … RAISE EXCEPTION`), **không** `apply_migration`.

---

## SECTION 1 — MIGRATION M1 · GOVERNANCE SCHEMA FOUNDATION

### BLOCK-1 — DDL
```sql
-- 1. Internal governance schema (NOT PostgREST-exposed)
CREATE SCHEMA IF NOT EXISTS mc_internal;

-- 2. Authorization policy (declarative source of authz rule)
CREATE TABLE IF NOT EXISTS public.mission_control_action_policies (
  action_key         text PRIMARY KEY,                          -- soft-ref registry.action_key (no FK: registry untouched)
  required_scope     text NOT NULL
                       CHECK (required_scope IN ('platform','tenant','assignment')),
  min_role_set       text[] NOT NULL DEFAULT '{}',              -- D-c: text[], compared as v_role::text
  required_capability text NULL,                                -- dormant (frozen; evaluate ignores)
  policy_version     text NOT NULL DEFAULT 'b6.2-v1',
  lifecycle          text NOT NULL DEFAULT 'shadow'
                       CHECK (lifecycle IN ('shadow','enforcing','disabled')),
  evaluator          text NOT NULL DEFAULT 'mc_internal.evaluate_action_policy',
  created_at         timestamptz NOT NULL DEFAULT now(),
  updated_at         timestamptz NOT NULL DEFAULT now()
);

-- 3. Governance evidence (authorization decision ledger — SEPARATE from execution ledger)
CREATE TABLE IF NOT EXISTS public.mission_control_action_authorizations (
  id             uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  request_id     uuid NOT NULL,                                 -- soft link → mission_control_action_requests.request_id
  actor_id       uuid NOT NULL,
  action_key     text NOT NULL,
  object_type    text NOT NULL,
  object_id      uuid NOT NULL,
  decision       text NOT NULL CHECK (decision IN ('allow','deny')),
  reason_code    text NULL,
  policy_version text NOT NULL,
  risk_level     text NOT NULL,
  lifecycle      text NOT NULL,                                 -- lifecycle at decision time
  evaluated      jsonb NOT NULL DEFAULT '{}'::jsonb,            -- gate snapshot
  actual_outcome text NULL,                                     -- shadow divergence: authz_allow|authz_deny|business_fail
  created_at     timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_mc_action_authz_request
  ON public.mission_control_action_authorizations (request_id);
CREATE INDEX IF NOT EXISTS idx_mc_action_authz_action_time
  ON public.mission_control_action_authorizations (action_key, created_at DESC);

-- 4. RLS
ALTER TABLE public.mission_control_action_policies       ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.mission_control_action_authorizations ENABLE ROW LEVEL SECURITY;

-- admin-only SELECT; NO insert/update/delete policy → client write denied by default
CREATE POLICY mc_action_policies_select_admin
  ON public.mission_control_action_policies
  FOR SELECT TO authenticated USING (public.is_admin());

CREATE POLICY mc_action_authz_select_admin
  ON public.mission_control_action_authorizations
  FOR SELECT TO authenticated USING (public.is_admin());
```

### BLOCK-2 — ACL harden (D231)
```sql
-- schema: internal; authenticated needs USAGE only to reach commit-core later (not these tables)
REVOKE ALL ON SCHEMA mc_internal FROM PUBLIC;
GRANT USAGE ON SCHEMA mc_internal TO authenticated;     -- required for INVOKER execute → commit-core (M3)

-- tables: strip default grants, allow admin SELECT only (RLS still gates), deny all client writes
REVOKE ALL ON public.mission_control_action_policies       FROM PUBLIC, anon, authenticated;
REVOKE ALL ON public.mission_control_action_authorizations FROM PUBLIC, anon, authenticated;
GRANT  SELECT ON public.mission_control_action_policies       TO authenticated;   -- gated by RLS admin
GRANT  SELECT ON public.mission_control_action_authorizations TO authenticated;   -- gated by RLS admin
-- NO INSERT/UPDATE/DELETE grant to anon/authenticated → only DEFINER commit-core (postgres) writes
```

### SEED — class.assign ONLY
```sql
INSERT INTO public.mission_control_action_policies
  (action_key, required_scope, min_role_set, required_capability, policy_version, lifecycle)
VALUES
  ('class.assign', 'tenant', ARRAY['master_admin','sub_admin']::text[], NULL, 'b6.2-v1', 'shadow')
ON CONFLICT (action_key) DO NOTHING;
-- ⛔ DO NOT seed class.edit / session / subscription / support_case / enrollment

-- documentation row (house-style, mirrors consent/evidence_derivation pattern)
INSERT INTO public.policy_registry
  (code, title, active_version, classification, defined_in, summary, admin_editable)
VALUES (
  'mission_control_action_governance',
  'Mission Control — Action Authorization Governance',
  'b6.2-v1', 'VERSIONED_POLICY',
  'mc_internal.evaluate_action_policy + mission_control_action_policies',
  $seed${"scope_allowlist":["platform","tenant","assignment"],"deny_precedence":"first-failing-gate; fail-closed","risk_tiers":{"LOW":"audit_only","MEDIUM":"evidence_required","HIGH/CRITICAL":"declared-only"},"evidence":"mission_control_action_authorizations (separate from execution ledger)","governed":["class.assign"]}$seed$::jsonb,
  false
) ON CONFLICT (code) DO NOTHING;
```

### BLOCK-3 — VERIFY
```sql
DO $verify$
BEGIN
  IF to_regnamespace('mc_internal') IS NULL THEN RAISE EXCEPTION 'M1: schema mc_internal missing'; END IF;
  IF to_regclass('public.mission_control_action_policies') IS NULL
     OR to_regclass('public.mission_control_action_authorizations') IS NULL
     THEN RAISE EXCEPTION 'M1: governance tables missing'; END IF;
  -- RLS enabled
  IF NOT (SELECT relrowsecurity FROM pg_class WHERE oid='public.mission_control_action_policies'::regclass)
     OR NOT (SELECT relrowsecurity FROM pg_class WHERE oid='public.mission_control_action_authorizations'::regclass)
     THEN RAISE EXCEPTION 'M1: RLS not enabled'; END IF;
  -- no client write policy (only SELECT admin exists)
  IF EXISTS (SELECT 1 FROM pg_policies
             WHERE schemaname='public'
               AND tablename IN ('mission_control_action_policies','mission_control_action_authorizations')
               AND cmd <> 'SELECT')
     THEN RAISE EXCEPTION 'M1: unexpected non-SELECT policy'; END IF;
  -- seed exactly class.assign, nothing else
  IF (SELECT count(*) FROM public.mission_control_action_policies) <> 1
     OR NOT EXISTS (SELECT 1 FROM public.mission_control_action_policies WHERE action_key='class.assign')
     THEN RAISE EXCEPTION 'M1: seed must be exactly class.assign'; END IF;
  IF NOT EXISTS (SELECT 1 FROM public.policy_registry WHERE code='mission_control_action_governance')
     THEN RAISE EXCEPTION 'M1: doc row missing'; END IF;
END $verify$;
```
**Security verify (rollback-safe sim, separate):** impersonate authenticated non-admin → `SELECT`/`INSERT` cả 2 bảng phải fail/empty; assert `mc_internal` không nằm trong PostgREST exposed schemas (kiểm cấu hình `PGRST_DB_SCHEMAS` trước apply — ngoài SQL).

### ROLLBACK M1
```sql
DROP TABLE IF EXISTS public.mission_control_action_authorizations;
DROP TABLE IF EXISTS public.mission_control_action_policies;
DELETE FROM public.policy_registry WHERE code='mission_control_action_governance';
DROP SCHEMA IF EXISTS mc_internal;   -- empty at M1
```
Preserved data: tất cả (chưa business data). Risk: **LOW**.

---

## SECTION 2 — MIGRATION M2 · GOVERNANCE EVALUATOR

### BLOCK-1 — DDL
```sql
CREATE OR REPLACE FUNCTION mc_internal.evaluate_action_policy(
  p_actor_id    uuid,
  p_action_key  text,
  p_object_type text,
  p_object_id   uuid,
  p_context     jsonb,
  p_input       jsonb
) RETURNS jsonb
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $fn$
DECLARE
  v_policy       public.mission_control_action_policies%rowtype;
  v_role         text;
  v_is_platform  boolean;
  v_school_id    uuid;
  v_actor_schools uuid[];
  v_ctx_school   uuid;
  v_risk         text;
  v_risk_req     text;
  v_role_ok      boolean := false;
  v_scope_ok     boolean := false;
  v_context_ok   boolean := false;
  v_reason       text := null;
BEGIN
  -- 1. policy (fail-closed if absent)
  SELECT * INTO v_policy FROM public.mission_control_action_policies WHERE action_key = p_action_key;
  IF NOT FOUND THEN
    RETURN jsonb_build_object('envelope','ActionPolicyDecision/v1','decision','deny',
      'reason_code','MC_POLICY_UNDEFINED','policy_version',null);
  END IF;

  -- 2. risk (single source = registry)
  SELECT risk_level INTO v_risk FROM public.mission_control_action_registry
   WHERE action_key = p_action_key AND status='active';
  v_risk_req := CASE v_risk
                  WHEN 'LOW' THEN 'audit_only'
                  WHEN 'MEDIUM' THEN 'evidence_required'
                  ELSE 'evidence_strict' END;   -- HIGH/CRITICAL declared-only

  -- 3. actor role/scope derived from p_actor_id (NOT auth.uid → testable; commit-core passes current_profile())
  SELECT role::text INTO v_role FROM public.profiles WHERE id = p_actor_id;
  IF v_role IS NULL THEN
    RETURN jsonb_build_object('envelope','ActionPolicyDecision/v1','decision','deny',
      'reason_code','MC_POLICY_ACTOR_UNKNOWN','policy_version',v_policy.policy_version,'risk_level',v_risk);
  END IF;
  v_is_platform := v_role IN ('super_admin','content_admin','senior_content_admin',
                              'operation_admin','sales_admin','support_admin');
  SELECT coalesce(array_agg(school_id),'{}') INTO v_actor_schools
    FROM public.profiles WHERE id = p_actor_id AND school_id IS NOT NULL;

  -- 4. object school (class-only in B6.2)
  IF p_object_type = 'class' THEN
    SELECT school_id INTO v_school_id FROM public.classes WHERE id = p_object_id;
  END IF;
  IF v_school_id IS NULL THEN
    RETURN jsonb_build_object('envelope','ActionPolicyDecision/v1','decision','deny',
      'reason_code','MC_POLICY_OBJECT_NOT_FOUND','policy_version',v_policy.policy_version,'risk_level',v_risk);
  END IF;

  -- 5. ROLE gate (platform admin satisfies role+scope)
  IF v_is_platform THEN
    v_role_ok := true; v_scope_ok := true;
  ELSE
    v_role_ok := v_role = ANY(v_policy.min_role_set);
    IF NOT v_role_ok THEN v_reason := 'MC_POLICY_ROLE_DENIED'; END IF;
    -- 6. SCOPE gate
    IF v_role_ok THEN
      v_scope_ok := CASE v_policy.required_scope
        WHEN 'tenant'     THEN v_school_id = ANY(v_actor_schools)
        WHEN 'platform'   THEN false               -- non-platform actor
        WHEN 'assignment' THEN false               -- reserved, no live action (fail-closed)
        ELSE false END;
      IF NOT v_scope_ok THEN v_reason := 'MC_POLICY_SCOPE_DENIED'; END IF;
    END IF;
  END IF;

  -- 7. CONTEXT coherence (school match) — only if role+scope passed
  IF v_role_ok AND v_scope_ok THEN
    BEGIN v_ctx_school := nullif(p_context->>'school_id','')::uuid; EXCEPTION WHEN others THEN v_ctx_school := null; END;
    v_context_ok := (v_ctx_school IS NOT NULL AND v_ctx_school = v_school_id);
    IF NOT v_context_ok THEN v_reason := 'MC_POLICY_CONTEXT_DENIED'; END IF;
  END IF;

  -- 8. capability: SKIPPED (frozen dormant) — no gate

  RETURN jsonb_build_object(
    'envelope','ActionPolicyDecision/v1',
    'decision', CASE WHEN v_role_ok AND v_scope_ok AND v_context_ok THEN 'allow' ELSE 'deny' END,
    'reason_code', v_reason,
    'policy_version', v_policy.policy_version,
    'risk_level', v_risk,
    'risk_requirement', v_risk_req,
    'evaluated', jsonb_build_object('role_ok',v_role_ok,'scope_ok',v_scope_ok,
                                    'context_ok',v_context_ok,'platform_override',v_is_platform),
    'actor_id', p_actor_id
  );
END
$fn$;
```
- **Owner:** postgres (created via migration). **Security:** DEFINER. **search_path:** `''`.
- **Failure model:** deny = return-value; **không** RAISE khi deny thường. *(Config-vỡ như policy-absent → deny UNDEFINED, không crash — fail-closed.)*

### BLOCK-2 — ACL (internal-only)
```sql
REVOKE ALL ON FUNCTION mc_internal.evaluate_action_policy(uuid,text,text,uuid,jsonb,jsonb)
  FROM PUBLIC, anon, authenticated;
-- KHÔNG grant authenticated → chỉ owner (postgres) + commit-core (chạy as postgres) gọi được
```

### BLOCK-3 — VERIFY
```sql
DO $verify$
DECLARE v_secdef boolean; v_cfg text[]; v_owner text; v_grants int;
BEGIN
  IF to_regprocedure('mc_internal.evaluate_action_policy(uuid,text,text,uuid,jsonb,jsonb)') IS NULL
     THEN RAISE EXCEPTION 'M2: evaluate missing'; END IF;
  SELECT p.prosecdef, p.proconfig, pg_get_userbyid(p.proowner)
    INTO v_secdef, v_cfg, v_owner
    FROM pg_proc p WHERE p.oid='mc_internal.evaluate_action_policy(uuid,text,text,uuid,jsonb,jsonb)'::regprocedure;
  IF NOT v_secdef THEN RAISE EXCEPTION 'M2: must be SECURITY DEFINER'; END IF;
  IF v_owner <> 'postgres' THEN RAISE EXCEPTION 'M2: owner must be postgres'; END IF;
  IF v_cfg IS DISTINCT FROM ARRAY['search_path=""']::text[] THEN RAISE EXCEPTION 'M2: search_path not empty'; END IF;
  -- no anon/authenticated EXECUTE
  SELECT count(*) INTO v_grants FROM (
    SELECT (aclexplode(coalesce(p.proacl, acldefault('f',p.proowner)))).grantee AS g
    FROM pg_proc p WHERE p.oid='mc_internal.evaluate_action_policy(uuid,text,text,uuid,jsonb,jsonb)'::regprocedure
  ) x WHERE g::regrole::text IN ('anon','authenticated');
  IF v_grants <> 0 THEN RAISE EXCEPTION 'M2: evaluate must be internal-only'; END IF;
END $verify$;
```
**Security verify (sim):** impersonate authenticated → `SELECT mc_internal.evaluate_action_policy(...)` → **permission denied**.

### ROLLBACK M2
```sql
DROP FUNCTION IF EXISTS mc_internal.evaluate_action_policy(uuid,text,text,uuid,jsonb,jsonb);
```
Preserved: all. Risk: **LOW** (dormant, no caller).

---

## SECTION 3 — MIGRATION M3 · EXECUTION INTEGRITY HARDENING (MOST CRITICAL)

### BLOCK-1a — commit-core (DEFINER; result server-derived; actor internal)
```sql
CREATE OR REPLACE FUNCTION mc_internal._mc_commit_action(
  p_request_id  uuid,
  p_action_key  text,
  p_object_type text,
  p_object_id   uuid,
  p_context     jsonb,
  p_input       jsonb
) RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $fn$
DECLARE
  v_actor       uuid;
  v_row         public.mission_control_action_requests%rowtype;
  v_program_id  uuid;
  v_lead_id     uuid;
  v_dist_id     uuid;
  v_result      jsonb;
  v_err_msg     text;
  v_err_code    text;
BEGIN
  -- D-a: derive actor INTERNALLY (never trust caller) → forge-proof identity
  v_actor := public.current_profile();
  IF v_actor IS NULL THEN
    RETURN jsonb_build_object('ok',false,'error',jsonb_build_object('code','MC_ACTION_PERMISSION_DENIED'));
  END IF;

  -- ownership + state guard: only finalize a processing row owned by caller, matching action/object
  SELECT * INTO v_row FROM public.mission_control_action_requests WHERE request_id = p_request_id;
  IF NOT FOUND OR v_row.actor_id IS DISTINCT FROM v_actor
     OR v_row.status <> 'processing'
     OR v_row.action_key IS DISTINCT FROM p_action_key
     OR v_row.object_id  IS DISTINCT FROM p_object_id THEN
    RETURN jsonb_build_object('ok',false,'error',jsonb_build_object('code','MC_ACTION_REQUEST_CONFLICT'));
  END IF;

  -- parse inputs (adapter re-validates anyway)
  BEGIN
    v_program_id := nullif(p_input->>'program_id','')::uuid;
    v_lead_id    := nullif(p_input->>'lead_teacher_id','')::uuid;
  EXCEPTION WHEN others THEN
    v_program_id := null;
  END;

  -- [M4 inserts governance seam here: evaluate + evidence + enforcing-branch]

  BEGIN
    v_dist_id := public.assign_class_distribution(p_object_id, v_program_id, v_lead_id);  -- adapter self-authorizes
    v_result := jsonb_build_object('ok',true,'replayed',false,'request_id',p_request_id,
      'action_key',p_action_key,'object_type',p_object_type,'object_id',p_object_id,
      'result',jsonb_build_object('class_distribution_id',v_dist_id),
      'audit',jsonb_build_object('event','CLASS_ASSIGNMENT_CREATED','recorded',true));
    UPDATE public.mission_control_action_requests
       SET status='completed', result_payload=v_result, error_code=null, completed_at=now()
     WHERE id = v_row.id;                                    -- DEFINER: bypass RLS (finish_own dropped)
    RETURN v_result;
  EXCEPTION
    WHEN unique_violation THEN v_err_code := 'MC_ACTION_CONFLICT';
    WHEN others THEN
      GET STACKED DIAGNOSTICS v_err_msg = MESSAGE_TEXT;
      v_err_code := CASE v_err_msg
        WHEN 'not_authorized_for_school' THEN 'MC_ACTION_PERMISSION_DENIED'
        WHEN 'distribution_exists'       THEN 'MC_ACTION_CONFLICT'
        WHEN 'class_not_found'           THEN 'MC_ACTION_OBJECT_NOT_FOUND'
        WHEN 'subject_not_entitled'      THEN 'MC_ACTION_INPUT_INVALID'
        WHEN 'lead_teacher_invalid'      THEN 'MC_ACTION_INPUT_INVALID'
        ELSE 'MC_ACTION_EXECUTION_FAILED' END;
  END;

  v_result := jsonb_build_object('ok',false,'replayed',false,'request_id',p_request_id,
    'action_key',p_action_key,'object_type',p_object_type,'object_id',p_object_id,
    'error',jsonb_build_object('code',v_err_code));
  UPDATE public.mission_control_action_requests
     SET status='failed', result_payload=v_result, error_code=v_err_code, completed_at=now()
   WHERE id = v_row.id;
  RETURN v_result;
END
$fn$;
```
- **May write:** `mission_control_action_requests` (finalize) + (M4) `mission_control_action_authorizations`. **Calls:** adapter `assign_class_distribution`.
- **MUST NOT accept:** `result_payload`, `status`, `completed_at` (D-b). **MUST NOT accept:** actor (D-a).

### BLOCK-1b — execute REPLACE (preserve INVOKER + gates; delegate finalize only)
```sql
CREATE OR REPLACE FUNCTION public.execute_mission_control_action(
  p_action_key text, p_object_id uuid, p_context jsonb, p_input jsonb, p_request_id uuid
) RETURNS jsonb
LANGUAGE plpgsql
SET search_path = ''          -- ⚠ NO 'SECURITY DEFINER' → remains INVOKER (frozen invariant)
AS $fn$
DECLARE
  v_actor_id   uuid;
  v_request_pk uuid;
  v_existing   public.mission_control_action_requests%rowtype;
  v_school_id  uuid;
  v_ctx_school uuid;
BEGIN
  --— PRESERVED VERBATIM from live body —--
  --  auth.uid() null → MC_ACTION_PERMISSION_DENIED
  --  v_actor_id := current_profile(); null → PERMISSION_DENIED
  --  action_key <> 'class.assign' → MC_ACTION_NOT_FOUND
  --  object/request null → MC_ACTION_INPUT_INVALID
  --  context shape {school_id}-only → MC_ACTION_CONTEXT_DENIED
  --  input shape {program_id[,lead_teacher_id]} → MC_ACTION_INPUT_INVALID
  --  object school lookup; context.school_id === object.school_id (cross-tenant gate)
  --  pristine INSERT (insert_own_processing) ... ON CONFLICT (request_id) DO NOTHING RETURNING id INTO v_request_pk;
  --  IF v_request_pk IS NULL → replay handling (in-progress / completed / failed) RETURN as-is
  --  (all above unchanged, byte-for-byte)

  --— CHANGED: new-execution branch delegates finalize to DEFINER commit-core —--
  RETURN mc_internal._mc_commit_action(
           p_request_id, 'class.assign', 'class', p_object_id, p_context, p_input);
  -- (execute NO LONGER performs adapter-call / ledger UPDATE itself)
END
$fn$;
```
> **Design note (production):** BLOCK-1b tại apply-time = **full paste-over** (D95) toàn bộ body live, chỉ thay khối `BEGIN … adapter … UPDATE …` cuối bằng dòng delegate. Ở đây rút gọn phần PRESERVED để rõ seam; không đổi bất kỳ gate nào.

### BLOCK-1c — ledger RLS change
```sql
DROP POLICY IF EXISTS mission_control_action_requests_finish_own ON public.mission_control_action_requests;
-- KEEP: mission_control_action_requests_insert_own_processing  (client create)
-- KEEP: mission_control_action_requests_select_own             (client read status)
```

### BLOCK-2 — ACL harden (D231)
```sql
-- commit-core: internal, but authenticated MUST execute (INVOKER execute calls it)
REVOKE ALL ON FUNCTION mc_internal._mc_commit_action(uuid,text,text,uuid,jsonb,jsonb) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION mc_internal._mc_commit_action(uuid,text,text,uuid,jsonb,jsonb) TO authenticated;

-- execute: re-assert PRIOR ACL captured in M0 (preserve exact client-callability; do NOT widen)
REVOKE ALL ON FUNCTION public.execute_mission_control_action(text,uuid,jsonb,jsonb,uuid) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.execute_mission_control_action(text,uuid,jsonb,jsonb,uuid) TO authenticated;
```

### BLOCK-3 — VERIFY (exact checks)
```sql
DO $verify$
DECLARE v_exec_secdef boolean; v_core_secdef boolean;
BEGIN
  -- execute remains INVOKER
  SELECT prosecdef INTO v_exec_secdef FROM pg_proc
   WHERE oid='public.execute_mission_control_action(text,uuid,jsonb,jsonb,uuid)'::regprocedure;
  IF v_exec_secdef THEN RAISE EXCEPTION 'M3: execute must stay INVOKER'; END IF;
  -- commit-core DEFINER + owner postgres + search_path empty
  SELECT prosecdef INTO v_core_secdef FROM pg_proc
   WHERE oid='mc_internal._mc_commit_action(uuid,text,text,uuid,jsonb,jsonb)'::regprocedure;
  IF NOT v_core_secdef THEN RAISE EXCEPTION 'M3: commit-core must be DEFINER'; END IF;
  IF (SELECT pg_get_userbyid(proowner) FROM pg_proc
      WHERE oid='mc_internal._mc_commit_action(uuid,text,text,uuid,jsonb,jsonb)'::regprocedure) <> 'postgres'
     THEN RAISE EXCEPTION 'M3: commit-core owner must be postgres'; END IF;
  -- finish_own absent; insert/select kept
  IF EXISTS (SELECT 1 FROM pg_policies WHERE tablename='mission_control_action_requests'
             AND policyname='mission_control_action_requests_finish_own')
     THEN RAISE EXCEPTION 'M3: finish_own must be dropped'; END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename='mission_control_action_requests'
             AND policyname='mission_control_action_requests_insert_own_processing')
     OR NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename='mission_control_action_requests'
             AND policyname='mission_control_action_requests_select_own')
     THEN RAISE EXCEPTION 'M3: insert/select policies must remain'; END IF;
END $verify$;
```
**Behavior verify (sim, impersonate master_admin):** class.assign happy → 1 `class_distributions` INSERT · audit `CLASS_ASSIGNMENT_CREATED` · result DTO khớp cũ · ledger `processing→completed` · replay cùng `request_id` = replayed. Fail (wrong-school) → `MC_ACTION_PERMISSION_DENIED` + ledger `failed`.
**Security verify (sim):** impersonate authenticated → direct `UPDATE mission_control_action_requests SET status='completed',result_payload='{}'` → **DENIED** (finish_own gone). Direct `mc_internal._mc_commit_action(...)` forged input → result = adapter-derived (không forge).

### ROLLBACK M3
```sql
-- restore prior execute (full paste of pre-B6.2 body) — INVOKER, self-finalizing
CREATE OR REPLACE FUNCTION public.execute_mission_control_action(...) ... ; -- pre-B6.2 body (captured M0)
-- restore client finalize
CREATE POLICY mission_control_action_requests_finish_own ON public.mission_control_action_requests
  FOR UPDATE TO authenticated
  USING (actor_id = (SELECT current_profile()) AND status='processing')
  WITH CHECK (actor_id = (SELECT current_profile())
              AND status = ANY(ARRAY['completed','failed'])
              AND completed_at IS NOT NULL AND result_payload IS NOT NULL
              AND ((status='completed' AND error_code IS NULL) OR (status='failed' AND error_code IS NOT NULL)));
DROP FUNCTION IF EXISTS mc_internal._mc_commit_action(uuid,text,text,uuid,jsonb,jsonb);
-- re-harden execute ACL to captured prior state
```
Preserved: business data + ledger rows intact. Risk: **HIGH** (live path + frozen fn). → apply-session riêng + real-login regression.

---

## SECTION 4 — MIGRATION M4 · SHADOW GOVERNANCE

### BLOCK-1 — commit-core REPLACE (insert governance seam; behavior preserved; branch gated by lifecycle)
Chèn tại marker `[M4 inserts governance seam here]` trong commit-core; **execute KHÔNG đổi** (D-e):
```sql
  -- governance seam (inside _mc_commit_action, before adapter block)
  DECLARE
    v_policy    public.mission_control_action_policies%rowtype;
    v_decision  jsonb;
    v_evi_id    uuid;
  BEGIN
    SELECT * INTO v_policy FROM public.mission_control_action_policies WHERE action_key = p_action_key;
    IF FOUND AND v_policy.lifecycle <> 'disabled' THEN
      v_decision := mc_internal.evaluate_action_policy(
                      v_actor, p_action_key, p_object_type, p_object_id, p_context, p_input);

      -- write governance evidence (DEFINER → bypass RLS)
      INSERT INTO public.mission_control_action_authorizations
        (request_id, actor_id, action_key, object_type, object_id, decision, reason_code,
         policy_version, risk_level, lifecycle, evaluated)
      VALUES (p_request_id, v_actor, p_action_key, p_object_type, p_object_id,
              v_decision->>'decision', v_decision->>'reason_code',
              coalesce(v_decision->>'policy_version', v_policy.policy_version),
              coalesce(v_decision->>'risk_level','UNKNOWN'), v_policy.lifecycle,
              coalesce(v_decision->'evaluated','{}'::jsonb))
      RETURNING id INTO v_evi_id;

      -- ENFORCING branch (inert while lifecycle='shadow' → M5 flips data only, D-e)
      IF v_policy.lifecycle = 'enforcing' AND (v_decision->>'decision') = 'deny' THEN
        v_result := jsonb_build_object('ok',false,'replayed',false,'request_id',p_request_id,
          'action_key',p_action_key,'object_type',p_object_type,'object_id',p_object_id,
          'error',jsonb_build_object('code','MC_ACTION_PERMISSION_DENIED'));
        UPDATE public.mission_control_action_requests
           SET status='failed', result_payload=v_result, error_code='MC_ACTION_PERMISSION_DENIED', completed_at=now()
         WHERE id = v_row.id;
        RETURN v_result;   -- SKIP adapter
      END IF;
      -- SHADOW: fall through (no branch). actual_outcome updated post-adapter.
    END IF;
  END;
```
Post-adapter (shadow divergence): sau khi adapter trả/raise, `UPDATE ...authorizations SET actual_outcome = <authz_allow|authz_deny|business_fail> WHERE id=v_evi_id`.

### BLOCK-3 — VERIFY
```sql
-- structural: commit-core still DEFINER/postgres; signature unchanged; execute untouched (regprocedure identical)
-- behavioral (sim): allow-path writes 1 evidence row decision='allow'; deny-fixture writes decision='deny';
--                   lifecycle='shadow' → verdict NOT branched (adapter still runs on deny fixture)
-- security: client cannot INSERT authorizations directly (RLS/grant deny)
```

### ROLLBACK M4
```sql
-- REPLACE commit-core back to M3 body (remove governance seam)  — OR kill-switch:
UPDATE public.mission_control_action_policies SET lifecycle='disabled', updated_at=now() WHERE action_key='class.assign';
```
Preserved: evidence rows kept (audit, harmless). Risk: **LOW–MEDIUM**.

---

## SECTION 5 — MIGRATION M5 · ENFORCEMENT FLIP (DATA-ONLY)

### BLOCK-1 — data
```sql
UPDATE public.mission_control_action_policies
   SET lifecycle='enforcing', updated_at=now()
 WHERE action_key='class.assign' AND lifecycle='shadow';
-- NO code change (branch logic already installed M4, D-e)
```

### BLOCK-3 — VERIFY
```sql
-- data: lifecycle='enforcing' on class.assign
-- behavioral (sim): deny fixture → NO class_distributions insert, ledger 'failed' MC_ACTION_PERMISSION_DENIED,
--                   evidence decision='deny'; allow fixture unchanged
-- rollback proof: SET lifecycle='shadow' → deny fixture no longer blocks (adapter runs again)
```

### ROLLBACK M5
```sql
UPDATE public.mission_control_action_policies SET lifecycle='shadow', updated_at=now() WHERE action_key='class.assign';
```
Preserved: all. Risk: **MEDIUM** (verdict change) nhưng reversible tức thì. **Owner Gate bắt buộc.**

---

## SECTION 6 — EXACT OBJECT TOUCH MAP

| Object | Action | Security Change | Risk |
|---|---|---|---|
| `mc_internal` (schema) | CREATE (M1) | USAGE→authenticated; not PGRST-exposed | LOW |
| `public.mission_control_action_policies` | CREATE+SEED (M1) | RLS admin-SELECT; no client write | LOW |
| `public.mission_control_action_authorizations` | CREATE (M1) | RLS admin-SELECT; DEFINER-write only | LOW |
| idx (request_id),(action_key,created_at) | CREATE (M1) | — | LOW |
| `public.policy_registry` (row) | INSERT (M1) | (existing RLS) | LOW |
| `mc_internal.evaluate_action_policy` | CREATE (M2) | DEFINER/postgres; REVOKE anon+authenticated (internal-only) | LOW |
| `mc_internal._mc_commit_action` | CREATE (M3), REPLACE (M4) | DEFINER/postgres; GRANT authenticated (callable by INVOKER execute) | MEDIUM |
| `public.execute_mission_control_action` | REPLACE (M3 only) | **stays INVOKER**; ACL re-asserted (unchanged) | **HIGH** |
| `mission_control_action_requests` RLS | DROP finish_own (M3) | keep insert_own_processing + select_own | MEDIUM |
| `assign_class_distribution` | **UNTOUCHED** | — | — |
| `mission_control_action_registry` | **UNTOUCHED** (risk_level authoritative) | — | — |
| `audit_logs` / `class_distributions` | **UNTOUCHED** | — | — |
| `...action_policies.lifecycle` (data) | UPDATE shadow→enforcing (M5) | data-only | MEDIUM |

---

## SECTION 7 — SECURITY REVIEW

**Q1 — Vì sao DEFINER không bypass domain authorization?**
`SECURITY DEFINER` escalate **executing role** (cho RLS/table-privilege), **KHÔNG** escalate **JWT identity** — `auth.uid()` bất biến xuyên mọi ranh giới DEFINER trong 1 request. Grounded: `is_admin/current_profile/current_profile_role/user_school_ids` đều `where user_id = auth.uid()`. Adapter `assign_class_distribution` authorize bằng chính các helper đó → dù bị gọi từ commit-core DEFINER (postgres), vẫn key theo client thật. DEFINER bypass được **row access**, không bypass được **identity-based authz**.

**Q2 — Vì sao client không gọi được commit-core (forge)?**
Hai lớp: (a) **Placement** — commit-core ở `mc_internal`, schema **không** trong `PGRST_DB_SCHEMAS` → **không** có PostgREST RPC endpoint; FE/client không có bề mặt gọi. (b) **Ngay cả khi gọi được** (authenticated có EXECUTE để INVOKER execute delegate): commit-core **tự derive actor** `current_profile()` (D-a, không nhận actor giả) + **kiểm ownership** ledger row (actor_id=self, status=processing, action/object khớp) + **result server-derived** từ adapter (D-b, không nhận `result_payload/status/completed_at`). ⇒ direct-call chỉ là một execution hợp lệ (adapter tự authorize), **không** forge được completion. Cộng: `finish_own` đã DROP → client **không** UPDATE ledger trực tiếp được nữa.

**Q3 — Vì sao invariant execute INVOKER vẫn đúng?**
M3 REPLACE `execute` **không** thêm `SECURITY DEFINER` (BLOCK-1b có comment ⚠), giữ nguyên signature + ACL + mọi gate + pristine INSERT + idempotency. VERIFY BLOCK-3 assert `prosecdef=false`. Thay đổi duy nhất: khối adapter-call+finalize cuối → delegate xuống commit-core. execute vẫn là INVOKER client entry.

**Q4 — Vì sao adapter vẫn là business backstop cuối?**
`assign_class_distribution` **UNTOUCHED**: giữ predicate authz (`is_admin() OR master/sub_admin+school∈user_school_ids()`) + business rules (`has_subject_entitlement`, `dma_assignable_teacher_reason`, dup-guard) + `write_audit_log`. Governance layer (policy/evaluate) là **thêm phía trước**, không thay adapter. Kể cả policy/commit có bug, adapter vẫn raise `not_authorized_for_school` → map `MC_ACTION_PERMISSION_DENIED`. Defense-in-depth: authz kiểm 2 lần (evaluate + adapter), verdict cuối luôn có adapter chốt.

---

## SECTION 8 — VERIFICATION BLOCK DESIGN (per migration)

| M | Structural | Behavior | Security |
|---|---|---|---|
| M1 | schema/tables/index/RLS exist; seed=1 (class.assign); doc row | execute path unchanged (smoke) | client SELECT/INSERT 2 tables denied |
| M2 | `to_regprocedure` not null; `prosecdef`; owner=postgres; `proconfig=search_path=""`; ACL no anon/auth | evaluate fixtures: allow/deny ROLE/SCOPE/CONTEXT/UNDEFINED; no capability branch | authenticated direct-call evaluate → denied |
| M3 | execute `prosecdef=false`; commit-core DEFINER+postgres; `finish_own` absent; insert/select kept | class.assign **byte-identical** (dist insert, audit, DTO, ledger, replay) | client UPDATE ledger→completed **denied**; commit-core direct forged input → adapter-derived |
| M4 | commit-core sig unchanged; execute untouched (regprocedure identical) | allow/deny evidence written; **no verdict branch** under shadow | client INSERT authorizations denied |
| M5 | lifecycle='enforcing' (data) | deny blocks pre-adapter; allow unchanged; flip-back restores shadow | cross-school/wrong-role real-login denied |

**Convention:** `to_regprocedure/to_regclass/to_regnamespace` (NULL-safe existence) · `prosecdef` · `proconfig IS NOT DISTINCT FROM ARRAY['search_path=""']` · `aclexplode(coalesce(proacl,acldefault('f',proowner)))` · `pg_policies` presence/absence · impersonation `set_config('request.jwt.claims',…) + SET LOCAL ROLE authenticated` + `RESET ROLE` · inventory Δ post-apply.

---

## SECTION 9 — ROLLBACK DESIGN

| M | Rollback action | Preserved data | Risk |
|---|---|---|---|
| M1 | DROP 2 tables + DELETE doc row + DROP empty schema | all (no business data) | LOW |
| M2 | DROP evaluate function | all | LOW |
| M3 | Restore prior execute (full paste) + re-CREATE `finish_own` + DROP commit-core + re-harden execute ACL | business + ledger rows intact | **HIGH** (careful; captured M0 body required) |
| M4 | REPLACE commit-core → M3 body **or** kill-switch lifecycle='disabled' | evidence rows kept (harmless) | LOW–MEDIUM |
| M5 | UPDATE lifecycle 'enforcing'→'shadow' (data-only) | all | LOW (instant) |

**Invariant:** mọi rollback non-destructive; `class_distributions`/`audit_logs`/ledger business rows **không** đụng; full teardown = M3-restore → drop M2 → drop M1.

---

## OPEN (confirm-able, không chặn design)

1. `min_role_set text[]` (D-c, an toàn) — confirm hay đổi `profile_role[]` (cần verify đủ nhãn enum trước)?
2. `evaluate` + `_mc_commit_action` đều ở `mc_internal` ✅ (theo CTO). Xác nhận `PGRST_DB_SCHEMAS` sẽ **không** thêm `mc_internal` (pre-apply config check — ngoài SQL).
3. Shadow stop-criteria N/T (số request thật / ngày) cho divergence-zero trước M5.

---

**FINAL:** SQL DESIGN ONLY. Blueprint chưa production — 0 execute, 0 apply, 0 DB call, 0 mutation, 0 canonical, 0 version bump. Production paste-over (D95 full-body execute) + `apply_migration` (D92 three-block, mỗi phase một migration, M3 tách session + real-login regression) chỉ khi có **Owner Gate apply** riêng. Không phát hiện architecture conflict — PATH B + mc_internal nhất quán.
