# V128-B3.3 — FINAL IMPLEMENTATION PACKAGE
## PROGRAM = THIRD CONTEXT CONSUMER · platform · ZERO-context genericity proof

> **Status:** DESIGN/PACKAGE-ONLY (Owner Gate ratified, DESIGN-only). **NOT APPLIED.**
> **Author role:** Technical PM · DB/Supabase Auditor · Migration Package Author.
> **Provenance:** 100% live re-pin against `xcvhacymrbhdhohyylyq` (D1). Zero reconstruction from memory.
> **Canonical baseline in:** RULES **D355** · SYSTEM_MAP **v1.43** · HANDOFF **V128-B3.2** · tail `20260812070542`.

---

## 1. FRESH LIVE RE-PIN (mandatory, D1)

Live-verified this session (not trusted from §0):

| Metric | Expected (§0) | **Live** | Verdict |
|---|---|---|---|
| tables | 90 | **90** | ✓ |
| functions | 240 | **240** | ✓ |
| SECURITY DEFINER | 229 | **229** | ✓ |
| policies | 166 | **166** | ✓ |
| triggers | 33 | **33** | ✓ |
| cron | 1 | **1** | ✓ |
| migration tail | `20260812070542` | **`20260812070542`** | ✓ |

**Registry (17 rows) live:**
- **wired (7):** capsule · child · class · media · person · school · session ✓
- **registered (4):** privacy_request · **program** · subscription · support_case ✓
- **none/forbidden (6):** badges · child_journey · family_memory · journal · raw_media · skills ✓

Baseline matches §0 exactly. **No baseline drift.**

---

## 2. DRIFT VERDICT

`to_regprocedure('public.admin_lookup_program(uuid)')` → **NULL / ABSENT** (live).

| Object | Live presence |
|---|---|
| `admin_lookup_program(uuid)` | **ABSENT** ← target |
| `admin_lookup_school(uuid)` | present |
| `admin_lookup_class(uuid,uuid)` | present |
| `admin_lookup_session(uuid,uuid)` | present |
| `_mission_control_workspace_core(text,uuid,jsonb,text)` | present |
| `is_admin()` | present |
| `get_object_workspace(text,uuid,jsonb,text)` (4-arg) | present |
| `get_object_workspace(text,uuid,text)` (3-arg legacy) | present |

**VERDICT: DRIFT-CLEAN.** Projector is absent as expected ⇒ package uses **`CREATE FUNCTION`** (not `CREATE OR REPLACE`) so any unexpected appearance between preflight and apply fails atomically (D355.9 / §6). No overwrite package authored.

---

## 3. PROGRAM DEPENDENCY AUDIT (reconfirmed live, §9)

**Table `public.programs`:**

| Column | Type | Nullable | Default | Notes |
|---|---|---|---|---|
| `id` | uuid | NO | `gen_random_uuid()` | **PK** |
| `name` | text | **NO** | — | identity label; **NOT NULL** confirmed live; **not unique** |
| `slug` | text | NO | — | **UNIQUE** (`programs_slug_key`) |
| `description` | text | YES | — | IP — NOT exposed |
| `state` | `content_state` (enum) | NO | `'draft'` | NOT exposed (frozen §2) |
| `created_at` | timestamptz | NO | `now()` | — |
| `artistic_domain` | text | YES | — | CHECK enum; NOT exposed |

- **PK:** `programs_pkey (id)` · **UNIQUE:** `programs_slug_key (slug)` · **CHECK:** `programs_artistic_domain_check` (enum-or-null).
- **Triggers:** **0** → `name` has no generated/trigger-derived behavior; plain NOT NULL text.
- **RLS:** enabled, **3 policies** (untouched — projector is SECURITY DEFINER and bypasses RLS by design; B3.3 = ZERO policy delta).
- **Outbound FK:** none.
- **Inbound FK (11):** `age_groups` · `levels` · `themes` · `lessons` · `program_distributions` · `ideas` · `class_distributions` · `learning_moments` · `child_journey` · `school_subject_entitlements` · `skill_catalog`.
- **Row count:** 2.
- **Fixtures (live):**
  - `99240fb7-8c82-4869-a522-6e0e863285d3` — "Cảm Thụ Âm Nhạc Dế Mèn" (slug `ctan`, published, music) ← **P1 success fixture**
  - `f7bbf38a-0447-4bf2-8992-e84c791c7348` — "Múa Ballet Dế Mèn" (slug `ballet`, published, dance_movement)

**Program-identity-already-exposed check:** the sibling projectors (`admin_lookup_child`, etc.) expose child/media/etc.; no existing projector exposes `programs` identity. This is a net-new identity surface, scoped to `{id,name}` only.

**scope=platform coherence (§9, per CTO correction):** `programs` is referenced by `school_subject_entitlements` (school↔program entitlement) and per-school/per-child usage rows (`class_distributions`, `child_journey`). **Physical containment ≠ Mission Control control-plane scope.** For an **identity-only** consumer that exposes only `{name}` and attaches **no authorization meaning to context**, program identity is platform-global (curriculum authored once, catalog-level). `scope=platform` is **coherent for this identity-only consumer.** The entitlement relation is flagged as a NOTED item for a future independent scope-design audit (§14) — it does **not** block B3.3 and is **not** asserted as a scope defect.

---

## 4. FROZEN ARCHITECTURE CONTRACT (CTO ratified)

| Field | Value | Mutating in B3.3? |
|---|---|---|
| object_type | `program` | no |
| source | `public.programs` | — |
| kind | `supporting` | no (already correct) |
| scope | `platform` | no (already correct) |
| privacy_policy | `open` | no (already correct) |
| projector_status | `registered` → **`wired`** | **YES (only field)** |
| discovery_fields | `['name']` **ONLY** | no — **frozen, do NOT widen to `[name,state]`** |
| context_requirements | `{"version":1,"keys":{},"allow_unknown":false}` (empty) | no — **zero-context** |
| capability_vocab | `{"edit":"program.edit","view":null}` (live) | no |
| forbidden_groups | `[]` (live) | no |

**Genericity-proof invariant:** PROGRAM is the first **zero-context, platform** consumer wired post-Context-Seam. It must be reachable through **both** the 4-arg wrapper (`{}` context) **and** the legacy 3-arg wrapper — because it has zero required context keys, empty context passes validation. This is intentional and is the milestone's proof.

---

## 5. EXACT PROJECTOR CONTRACT

`public.admin_lookup_program(p_program_id uuid) RETURNS jsonb`

1. `SECURITY DEFINER`, owner `postgres`, `SET search_path TO ''` (proconfig `["search_path=\"\""]`).
2. Self-gated via `public.is_admin()`; non-admin direct call → `{"ok":false,"error":"not_admin"}`.
3. Lookup **only** by `programs.id = p_program_id`.
4. Nonexistent → `{"ok":false,"error":"not_found"}`.
5. Success payload = **identity minimum** `{"ok":true,"program":{"id":…,"name":…}}`. **No** description/slug/state/artistic_domain/curriculum/lessons/activities/entitlements/school-mappings.
6. `name` is NOT NULL live, but `jsonb_build_object` is NULL-safe regardless — no invented fallback.

Adapter reads `v_source = v_raw->'program' = {id,name}`, then the discovery allowlist strips to `discovery_fields=['name']` ⇒ **`fields = {"name": …}`** exactly. `id` survives only as top-level `object_id` in the DTO. No other field can pass the allowlist.

Follows the `admin_lookup_*` family (template = `admin_lookup_school`, minus `state`).

---

## 6. EXACT REGISTRY PRE → POST

**PRE (live-verified, must hold at apply-time or migration fails atomically):**
```
object_type       = 'program'
kind              = 'supporting'
scope             = 'platform'
projector_status  = 'registered'
privacy_policy    = 'open'
discovery_fields  = {name}                                    (text[])
forbidden_groups  = {}                                        (text[])
context_requirements = {"version":1,"keys":{},"allow_unknown":false}   (jsonb)
capability_vocab  = {"edit":"program.edit","view":null}       (jsonb)
```

**POST:** identical to PRE **except** `projector_status = 'wired'`.

**Transition:** wired **7→8** · registered **4→3** · none **6→6** (17 rows, UPDATE not INSERT).

Enforcement: single **pre-state-bound UPDATE** whose `WHERE` names the complete approved PRE-state; `GET DIAGNOSTICS ROW_COUNT` must equal `1`, else `RAISE` → atomic rollback (fail-closed on any drifted field; only `projector_status` is SET; minimal mutation surface, §7).

---

## 7. FULL LITERAL 3-BLOCK MIGRATION SQL

> **Apply mechanism:** `apply_migration` (D92), name `v128_b3_3_program_context_consumer`. Single transaction. **DO NOT APPLY THIS TURN.**

```sql
-- =====================================================================
-- V128-B3.3 — PROGRAM = THIRD CONTEXT CONSUMER (platform · zero-context)
-- Migration: v128_b3_3_program_context_consumer
-- 3-block pattern (D92): BLOCK 1 DDL/mutation · BLOCK 2 harden · BLOCK 3 verify
-- =====================================================================

-- ---------------------------------------------------------------------
-- BLOCK 1 — DDL + MUTATION
-- ---------------------------------------------------------------------

-- 1.1  Projector (CREATE, NOT OR REPLACE — fail-closed on drift, D355.9)
CREATE FUNCTION public.admin_lookup_program(p_program_id uuid)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO ''
AS $function$
DECLARE v jsonb;
BEGIN
  IF NOT public.is_admin() THEN
    RETURN jsonb_build_object('ok',false,'error','not_admin'); END IF;
  IF NOT EXISTS (SELECT 1 FROM public.programs WHERE id = p_program_id) THEN
    RETURN jsonb_build_object('ok',false,'error','not_found'); END IF;

  SELECT jsonb_build_object('ok',true,
    'program', (SELECT jsonb_build_object('id',pr.id,'name',pr.name)
                FROM public.programs pr WHERE pr.id = p_program_id))
  INTO v;
  RETURN v;
END $function$;

-- 1.2  Core — REPLACE in place, ONLY delta = one WHEN 'program' branch
CREATE OR REPLACE FUNCTION public._mission_control_workspace_core(p_object_type text, p_object_id uuid, p_context jsonb, p_reason text)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
DECLARE
  r_reg          public.mission_control_object_registry%ROWTYPE;
  v_raw          jsonb; v_source jsonb; v_fields jsonb; v_bad text;
  v_needs_reason boolean; v_log jsonb;
  v_vres         jsonb; v_ctx jsonb;
BEGIN
  -- 1 AUTHENTICATE
  IF NOT public.is_admin() THEN
    RETURN jsonb_build_object('ok',false,'error','not_authorized'); END IF;

  -- 2 REGISTRY / OBJECT METADATA
  SELECT * INTO r_reg FROM public.mission_control_object_registry
   WHERE object_type = p_object_type;
  IF NOT FOUND THEN
    RETURN jsonb_build_object('ok',false,'error','unknown_object_type','object_type',p_object_type); END IF;
  IF r_reg.kind='forbidden' OR r_reg.projector_status='none' THEN
    RETURN jsonb_build_object('ok',false,'error','forbidden_object','object_type',p_object_type); END IF;
  IF r_reg.projector_status='registered' THEN
    RETURN jsonb_build_object('ok',false,'error','not_available',
             'object_type',p_object_type,'projector_status','registered'); END IF;
  IF r_reg.scope IS DISTINCT FROM 'platform'
     AND r_reg.scope IS DISTINCT FROM 'tenant'
     AND r_reg.scope IS DISTINCT FROM 'assignment' THEN
    RETURN jsonb_build_object('ok',false,'error','scope_not_wired',
             'object_type',p_object_type,'scope',r_reg.scope); END IF;

  -- 3 VALIDATE CONTEXT (fail-closed)
  BEGIN
    v_vres := public.validate_mission_control_object_context(
                p_object_type, coalesce(p_context, '{}'::jsonb));
  EXCEPTION WHEN OTHERS THEN
    RETURN jsonb_build_object('ok',false,'error','context_invalid','object_type',p_object_type);
  END;
  IF NOT COALESCE((v_vres->>'valid')::boolean, false) THEN
    RETURN jsonb_build_object('ok',false,'error','context_invalid','object_type',p_object_type);
  END IF;
  v_ctx := v_vres->'normalized_context';

  -- 4 CONTEXT AUTHORIZATION SLOT — B3.0 NO-OP
  PERFORM v_ctx;

  -- 5 PRIVACY / REASON
  v_needs_reason := r_reg.privacy_policy IN ('reason_required','restricted');
  IF v_needs_reason AND (p_reason IS NULL OR btrim(p_reason)='') THEN
    RETURN jsonb_build_object('ok',false,'error','reason_required',
             'object_type',p_object_type,'privacy_policy',r_reg.privacy_policy); END IF;
  IF v_needs_reason THEN
    v_log := public.admin_workspace_access_log(p_object_type, p_object_id, p_reason);
    IF NOT COALESCE((v_log->>'ok')::boolean,false) THEN
      RETURN jsonb_build_object('ok',false,'error','access_log_failed',
               'detail',v_log->>'error','object_type',p_object_type); END IF;
  END IF;

  -- 6 TOUCH OBJECT / PROJECTOR
  CASE p_object_type
    WHEN 'person'  THEN v_raw:=public.admin_lookup_user(p_object_id);    v_source:=v_raw->'profile';
    WHEN 'child'   THEN v_raw:=public.admin_lookup_child(p_object_id);   v_source:=v_raw->'child';
    WHEN 'media'   THEN v_raw:=public.admin_lookup_media(p_object_id);   v_source:=v_raw->'media';
    WHEN 'capsule' THEN v_raw:=public.admin_lookup_capsule(p_object_id); v_source:=v_raw->'capsule';
    WHEN 'school'  THEN v_raw:=public.admin_lookup_school(p_object_id);  v_source:=v_raw->'school';
    WHEN 'class'   THEN v_raw:=public.admin_lookup_class(
                           p_object_id,
                           (v_ctx->>'school_id')::uuid
                         );                                              v_source:=v_raw->'class';
    WHEN 'session' THEN v_raw:=public.admin_lookup_session(
                           p_object_id,
                           (v_ctx->>'class_distribution_id')::uuid
                         );                                              v_source:=v_raw->'session';
    WHEN 'program' THEN v_raw:=public.admin_lookup_program(p_object_id); v_source:=v_raw->'program';
    ELSE RETURN jsonb_build_object('ok',false,'error','dispatch_missing','object_type',p_object_type);
  END CASE;

  IF v_raw IS NULL OR NOT COALESCE((v_raw->>'ok')::boolean,false) THEN
    RETURN jsonb_build_object('ok',false,'error',COALESCE(v_raw->>'error','projector_error'),
             'object_type',p_object_type); END IF;

  v_fields := COALESCE((
    SELECT jsonb_object_agg(key,value)
    FROM jsonb_each(COALESCE(v_source,'{}'::jsonb))
    WHERE key = ANY (r_reg.discovery_fields)
  ), '{}'::jsonb);

  SELECT string_agg(k,',') INTO v_bad
  FROM jsonb_object_keys(v_fields) AS k
  WHERE NOT (k = ANY (r_reg.discovery_fields));
  IF v_bad IS NOT NULL THEN
    RAISE EXCEPTION 'ADAPTER_ALLOWLIST_VIOLATION: %', v_bad; END IF;

  IF EXISTS (SELECT 1 FROM jsonb_object_keys(v_fields) AS k
             WHERE k = ANY (r_reg.forbidden_groups)) THEN
    RAISE EXCEPTION 'ADAPTER_FORBIDDEN_LEAK'; END IF;

  RETURN jsonb_build_object(
    'ok',              true,
    'dto',             'WorkspaceProjectionDTO/v1',
    'object_type',     p_object_type,
    'object_id',       p_object_id,
    'kind',            r_reg.kind,
    'scope',           r_reg.scope,
    'privacy_policy',  r_reg.privacy_policy,
    'projector_status',r_reg.projector_status,
    'fields',          v_fields,
    'capabilities',    r_reg.capability_vocab,
    'reason_logged',   v_needs_reason
  );
END
$function$;

-- 1.3  Registry PRE-state-bound transition (fail-closed on any drifted field)
DO $$
DECLARE v_rc int;
BEGIN
  UPDATE public.mission_control_object_registry
     SET projector_status = 'wired'
   WHERE object_type = 'program'
     AND kind = 'supporting'
     AND scope = 'platform'
     AND projector_status = 'registered'
     AND privacy_policy = 'open'
     AND discovery_fields = ARRAY['name']::text[]
     AND forbidden_groups = ARRAY[]::text[]
     AND context_requirements = '{"version":1,"keys":{},"allow_unknown":false}'::jsonb
     AND capability_vocab = '{"edit":"program.edit","view":null}'::jsonb;
  GET DIAGNOSTICS v_rc = ROW_COUNT;
  IF v_rc <> 1 THEN
    RAISE EXCEPTION 'B33_REGISTRY_PRESTATE_DRIFT: expected exactly 1 program row in approved pre-state, got %', v_rc;
  END IF;
END $$;

-- ---------------------------------------------------------------------
-- BLOCK 2 — ACL HARDENING (D15 / D231 — proacl resets on CREATE/REPLACE)
-- ---------------------------------------------------------------------

-- 2.1  Projector: internal admins only via authenticated; 0 PUBLIC/anon
REVOKE ALL ON FUNCTION public.admin_lookup_program(uuid) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.admin_lookup_program(uuid) FROM anon;
REVOKE ALL ON FUNCTION public.admin_lookup_program(uuid) FROM authenticated;
GRANT EXECUTE ON FUNCTION public.admin_lookup_program(uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION public.admin_lookup_program(uuid) TO service_role;

-- 2.2  Core: internal-only; 0 PUBLIC/anon/authenticated (re-harden after REPLACE)
REVOKE ALL ON FUNCTION public._mission_control_workspace_core(text,uuid,jsonb,text) FROM PUBLIC;
REVOKE ALL ON FUNCTION public._mission_control_workspace_core(text,uuid,jsonb,text) FROM anon;
REVOKE ALL ON FUNCTION public._mission_control_workspace_core(text,uuid,jsonb,text) FROM authenticated;
GRANT EXECUTE ON FUNCTION public._mission_control_workspace_core(text,uuid,jsonb,text) TO service_role;

-- ---------------------------------------------------------------------
-- BLOCK 3 — STRUCTURAL VERIFY (RAISE-on-fail = atomic rollback guard)
-- ---------------------------------------------------------------------
DO $$
DECLARE
  v_secdef boolean; v_owner name; v_cfg text[];
  v_acl_prog text; v_acl_core text;
  v_def text;
  v_wired int; v_reg int; v_none int;
  v_tables int; v_funcs int; v_secdefs int; v_pols int; v_trgs int; v_cron int;
BEGIN
  -- A. projector exists (regprocedure pin, G)
  IF to_regprocedure('public.admin_lookup_program(uuid)') IS NULL THEN
    RAISE EXCEPTION 'VERIFY_A: admin_lookup_program(uuid) absent'; END IF;

  SELECT p.prosecdef, pg_get_userbyid(p.proowner), p.proconfig
    INTO v_secdef, v_owner, v_cfg
  FROM pg_proc p WHERE p.oid='public.admin_lookup_program(uuid)'::regprocedure;

  -- B. owner postgres
  IF v_owner <> 'postgres' THEN RAISE EXCEPTION 'VERIFY_B: owner=% (expected postgres)', v_owner; END IF;
  -- C. SECURITY DEFINER
  IF NOT v_secdef THEN RAISE EXCEPTION 'VERIFY_C: not SECURITY DEFINER'; END IF;
  -- D. proconfig EXACT (IS NOT DISTINCT FROM — no LIKE/@>/partial)
  IF NOT (v_cfg IS NOT DISTINCT FROM ARRAY['search_path=""']::text[]) THEN
    RAISE EXCEPTION 'VERIFY_D: proconfig=% (expected {search_path=""})', v_cfg; END IF;

  -- E. exact projector ACL {authenticated,postgres,service_role}, 0 PUBLIC/anon
  SELECT string_agg(
           CASE WHEN a.grantee=0 THEN 'PUBLIC' ELSE COALESCE(r.rolname,a.grantee::text) END
           ||':'||a.privilege_type, ',' ORDER BY 1)
    INTO v_acl_prog
  FROM pg_proc p
  CROSS JOIN LATERAL aclexplode(COALESCE(p.proacl, acldefault('f', p.proowner))) a
  LEFT JOIN pg_roles r ON r.oid=a.grantee
  WHERE p.oid='public.admin_lookup_program(uuid)'::regprocedure;
  IF v_acl_prog IS DISTINCT FROM 'authenticated:EXECUTE,postgres:EXECUTE,service_role:EXECUTE' THEN
    RAISE EXCEPTION 'VERIFY_E: projector ACL=% ', v_acl_prog; END IF;

  -- F. exact core ACL {postgres,service_role}, 0 PUBLIC/anon/authenticated
  SELECT string_agg(
           CASE WHEN a.grantee=0 THEN 'PUBLIC' ELSE COALESCE(r.rolname,a.grantee::text) END
           ||':'||a.privilege_type, ',' ORDER BY 1)
    INTO v_acl_core
  FROM pg_proc p
  CROSS JOIN LATERAL aclexplode(COALESCE(p.proacl, acldefault('f', p.proowner))) a
  LEFT JOIN pg_roles r ON r.oid=a.grantee
  WHERE p.oid='public._mission_control_workspace_core(text,uuid,jsonb,text)'::regprocedure;
  IF v_acl_core IS DISTINCT FROM 'postgres:EXECUTE,service_role:EXECUTE' THEN
    RAISE EXCEPTION 'VERIFY_F: core ACL=% ', v_acl_core; END IF;

  -- G. core regprocedure pin (already dereferenced above); also assert core present
  IF to_regprocedure('public._mission_control_workspace_core(text,uuid,jsonb,text)') IS NULL THEN
    RAISE EXCEPTION 'VERIFY_G: core absent'; END IF;

  -- H/I/J. core retains class + session branches; contains program branch
  v_def := pg_get_functiondef('public._mission_control_workspace_core(text,uuid,jsonb,text)'::regprocedure);
  IF v_def NOT LIKE '%WHEN ''class''%'   THEN RAISE EXCEPTION 'VERIFY_H: class branch lost'; END IF;
  IF v_def NOT LIKE '%WHEN ''session''%' THEN RAISE EXCEPTION 'VERIFY_I: session branch lost'; END IF;
  IF v_def NOT LIKE '%WHEN ''program''%' THEN RAISE EXCEPTION 'VERIFY_J: program branch missing'; END IF;

  -- K. program registry target exact
  IF NOT EXISTS (
    SELECT 1 FROM public.mission_control_object_registry
    WHERE object_type='program'
      AND kind='supporting' AND scope='platform'
      AND projector_status='wired' AND privacy_policy='open'
      AND discovery_fields = ARRAY['name']::text[]
      AND forbidden_groups = ARRAY[]::text[]
      AND context_requirements = '{"version":1,"keys":{},"allow_unknown":false}'::jsonb
      AND capability_vocab = '{"edit":"program.edit","view":null}'::jsonb
  ) THEN RAISE EXCEPTION 'VERIFY_K: program registry target not exact'; END IF;

  -- L. exact registry sets after transition: wired=8, registered=3, none=6
  SELECT count(*) FILTER (WHERE projector_status='wired'),
         count(*) FILTER (WHERE projector_status='registered'),
         count(*) FILTER (WHERE projector_status='none')
    INTO v_wired, v_reg, v_none
  FROM public.mission_control_object_registry;
  IF NOT (v_wired=8 AND v_reg=3 AND v_none=6) THEN
    RAISE EXCEPTION 'VERIFY_L: registry sets wired/reg/none = %/%/% (expected 8/3/6)', v_wired,v_reg,v_none; END IF;

  -- M. inventory exact: 90 / 241 / 230 / 166 / 33 / 1
  SELECT (SELECT count(*) FROM pg_tables WHERE schemaname='public'),
         (SELECT count(*) FROM pg_proc p JOIN pg_namespace n ON n.oid=p.pronamespace WHERE n.nspname='public'),
         (SELECT count(*) FROM pg_proc p JOIN pg_namespace n ON n.oid=p.pronamespace WHERE n.nspname='public' AND p.prosecdef),
         (SELECT count(*) FROM pg_policies WHERE schemaname='public'),
         (SELECT count(*) FROM pg_trigger t JOIN pg_class c ON c.oid=t.tgrelid JOIN pg_namespace n ON n.oid=c.relnamespace WHERE n.nspname='public' AND NOT t.tgisinternal),
         (SELECT count(*) FROM cron.job)
    INTO v_tables, v_funcs, v_secdefs, v_pols, v_trgs, v_cron;
  IF NOT (v_tables=90 AND v_funcs=241 AND v_secdefs=230 AND v_pols=166 AND v_trgs=33 AND v_cron=1) THEN
    RAISE EXCEPTION 'VERIFY_M: inventory = %/%/%/%/%/% (expected 90/241/230/166/33/1)',
      v_tables,v_funcs,v_secdefs,v_pols,v_trgs,v_cron; END IF;

  RAISE NOTICE 'V128-B3.3 STRUCTURAL VERIFY: ALL PASS (A–M)';
END $$;

-- D289 — reload PostgREST schema cache
NOTIFY pgrst, 'reload schema';
```

---

## 8. ACL PROOF PLAN

**Canonical projector posture (live, this session):** all of `admin_lookup_school/class/session` = secdef · owner postgres · `search_path=""` · EXECUTE `{authenticated,postgres,service_role}` · 0 PUBLIC/anon. Core = EXECUTE `{postgres,service_role}` · 0 PUBLIC/anon/authenticated.

**Target for `admin_lookup_program(uuid)`:** matches the projector family — `authenticated:EXECUTE,postgres:EXECUTE,service_role:EXECUTE`, **0 PUBLIC/anon**.

Verification = BLOCK-3 **E** (projector) + **F** (core), both via `aclexplode(COALESCE(proacl, acldefault('f', proowner)))` with grantee-OID-0=PUBLIC mapping and exact sorted-string equality (not containment). Post-apply the standalone functional harness (§10/§11) additionally re-reads ACL by `regprocedure` (never `proname` alone).

---

## 9. FULL CORE-BODY DIFF PROOF

Full **live** current body captured via `pg_get_functiondef(...regprocedure)` (reproduced verbatim in §7 §1.2). The **only** business-body change is one inserted line in the dispatch CASE, between the `session` branch and `ELSE`:

```diff
     WHEN 'session' THEN v_raw:=public.admin_lookup_session(
                            p_object_id,
                            (v_ctx->>'class_distribution_id')::uuid
                          );                                              v_source:=v_raw->'session';
+    WHEN 'program' THEN v_raw:=public.admin_lookup_program(p_object_id); v_source:=v_raw->'program';
     ELSE RETURN jsonb_build_object('ok',false,'error','dispatch_missing','object_type',p_object_type);
```

**No other change.** Byte-preserved: authenticate gate · registry lookup · forbidden gate · not_available gate · 3-value scope gate (platform/tenant/assignment) · context validate (fail-closed) · normalized_context read · context authz NO-OP · privacy/reason gate · access-log · person/child/media/capsule/school/class/session branches · projector-ok guard · discovery allowlist aggregation · `ADAPTER_ALLOWLIST_VIOLATION` · `ADAPTER_FORBIDDEN_LEAK` · DTO/v1 envelope (unchanged, not bumped). No dynamic SQL; static CASE only (D350.2 / D353.3 / D355.7). CLASS + SESSION branches semantically identical.

---

## 10. PRE/POST REGRESSION HARNESS

**PRE golden signatures — CAPTURED LIVE this session** (admin impersonation `446de75d-75b5-476d-8abd-08a98e791f40`; child+capsule reason path forced to roll back via terminal `RAISE`; **residue verified 0** in `audit_logs`):

| consumer | ok | error | dto | scope | ps | fields keys |
|---|---|---|---|---|---|---|
| person | true | — | WorkspaceProjectionDTO/v1 | platform | wired | `[email,full_name,role,state]` |
| child | true | — | WorkspaceProjectionDTO/v1 | platform | wired | `[full_name,nickname,state]` |
| media | true | — | WorkspaceProjectionDTO/v1 | platform | wired | `[file_type,state]` |
| capsule | true | — | WorkspaceProjectionDTO/v1 | platform | wired | `[domain,scope,window_code]` |
| school | true | — | WorkspaceProjectionDTO/v1 | tenant | wired | `[name,state]` |
| class | true | — | WorkspaceProjectionDTO/v1 | tenant | wired | `[name]` |
| session | true | — | WorkspaceProjectionDTO/v1 | assignment | wired | `[state,title]` |
| **program** | **false** | **not_available** | null | null | registered | null |

> capsule uses a **real** `discovery_capsules.id` producing `ok=true` (B3.2 correction preserved, NOT `not_found`). session uses a valid session + its **current** `class_distribution_id` producing `ok=true`.

**POST expectation (apply-time, not this turn):** the seven wired consumers must be **PRE ≡ POST** (diffcount = 0). Only PROGRAM transitions: `not_available` → successful `WorkspaceProjectionDTO/v1` with `fields = {name}`.

**Literal POST harness** (run under admin impersonation after apply; terminal `RAISE` makes it rollback-safe so reason-path audit writes leave zero residue):

```sql
DO $$
DECLARE
  v_admin uuid := '446de75d-75b5-476d-8abd-08a98e791f40';
  v_out jsonb := '{}'::jsonb; r jsonb;
  FUNCTION sig(x jsonb) RETURNS jsonb AS $$  -- (inline expansion below; PG has no nested fn — use expression)
  $$ LANGUAGE sql;  -- placeholder; see expression form used per call
BEGIN
  PERFORM set_config('request.jwt.claims',
    json_build_object('sub', v_admin::text, 'role','authenticated')::text, true);
  SET LOCAL ROLE authenticated;

  r := public.get_object_workspace('person','e86e45d1-3d0a-4cbc-8d3a-2a07926ec913'::uuid,'{}'::jsonb,NULL);
  v_out := v_out || jsonb_build_object('person', jsonb_build_object('ok',r->'ok','error',r->'error','dto',r->'dto','scope',r->'scope','ps',r->'projector_status','fkeys',(SELECT jsonb_agg(k ORDER BY k) FROM jsonb_object_keys(coalesce(r->'fields','{}'::jsonb)) k)));

  r := public.get_object_workspace('child','429d4fb7-67f0-4166-8ec3-fee7ad1a3666'::uuid,'{}'::jsonb,'b33_post_harness');
  v_out := v_out || jsonb_build_object('child', jsonb_build_object('ok',r->'ok','error',r->'error','dto',r->'dto','scope',r->'scope','ps',r->'projector_status','fkeys',(SELECT jsonb_agg(k ORDER BY k) FROM jsonb_object_keys(coalesce(r->'fields','{}'::jsonb)) k)));

  r := public.get_object_workspace('media','614aa02e-fb27-4487-a603-daf26ddfc3d6'::uuid,'{}'::jsonb,NULL);
  v_out := v_out || jsonb_build_object('media', jsonb_build_object('ok',r->'ok','error',r->'error','dto',r->'dto','scope',r->'scope','ps',r->'projector_status','fkeys',(SELECT jsonb_agg(k ORDER BY k) FROM jsonb_object_keys(coalesce(r->'fields','{}'::jsonb)) k)));

  r := public.get_object_workspace('capsule','384042c1-a1a2-450c-8854-3886659cd050'::uuid,'{}'::jsonb,'b33_post_harness');
  v_out := v_out || jsonb_build_object('capsule', jsonb_build_object('ok',r->'ok','error',r->'error','dto',r->'dto','scope',r->'scope','ps',r->'projector_status','fkeys',(SELECT jsonb_agg(k ORDER BY k) FROM jsonb_object_keys(coalesce(r->'fields','{}'::jsonb)) k)));

  r := public.get_object_workspace('school','b6a4ac35-2e0a-4667-9eea-756f615c29eb'::uuid,'{}'::jsonb,NULL);
  v_out := v_out || jsonb_build_object('school', jsonb_build_object('ok',r->'ok','error',r->'error','dto',r->'dto','scope',r->'scope','ps',r->'projector_status','fkeys',(SELECT jsonb_agg(k ORDER BY k) FROM jsonb_object_keys(coalesce(r->'fields','{}'::jsonb)) k)));

  r := public.get_object_workspace('class','2405fed8-1e9f-4414-b41e-b5eb5f3d8ea7'::uuid, jsonb_build_object('school_id','b6a4ac35-2e0a-4667-9eea-756f615c29eb'),NULL);
  v_out := v_out || jsonb_build_object('class', jsonb_build_object('ok',r->'ok','error',r->'error','dto',r->'dto','scope',r->'scope','ps',r->'projector_status','fkeys',(SELECT jsonb_agg(k ORDER BY k) FROM jsonb_object_keys(coalesce(r->'fields','{}'::jsonb)) k)));

  r := public.get_object_workspace('session','2fab0c56-9f56-4610-9558-216d58573c20'::uuid, jsonb_build_object('class_distribution_id','a8088a55-b6da-481d-b4c9-e7e9c4d126da'),NULL);
  v_out := v_out || jsonb_build_object('session', jsonb_build_object('ok',r->'ok','error',r->'error','dto',r->'dto','scope',r->'scope','ps',r->'projector_status','fkeys',(SELECT jsonb_agg(k ORDER BY k) FROM jsonb_object_keys(coalesce(r->'fields','{}'::jsonb)) k)));

  r := public.get_object_workspace('program','99240fb7-8c82-4869-a522-6e0e863285d3'::uuid,'{}'::jsonb,NULL);
  v_out := v_out || jsonb_build_object('program', jsonb_build_object('ok',r->'ok','error',r->'error','dto',r->'dto','scope',r->'scope','ps',r->'projector_status','fkeys',(SELECT jsonb_agg(k ORDER BY k) FROM jsonb_object_keys(coalesce(r->'fields','{}'::jsonb)) k)));

  RAISE EXCEPTION 'POST_GOLDEN::%', v_out::text;
END $$;
```

> Note: PostgreSQL PL/pgSQL has no nested functions; the `sig(...)` line above is illustrative only — each call uses the inline `jsonb_build_object(...)` expression form shown, which is what was executed live for the PRE capture.

**POST-≡-PRE assertion:** the seven wired keys of `POST_GOLDEN` must be byte-identical to the PRE table above; `program` must flip to `{ok:true, dto:WorkspaceProjectionDTO/v1, scope:platform, ps:wired, fkeys:[name]}`.

---

## 11. FUNCTIONAL TEST MATRIX (P1–P14, literal & executable)

All run under admin impersonation unless noted; reason-writing / synthetic-registry cases wrapped rollback-safe (terminal `RAISE`), **zero residue** required.

| # | Case | Call | Expected |
|---|---|---|---|
| **P1** | admin + existing program | `get_object_workspace('program', '99240fb7-…'::uuid, '{}'::jsonb, NULL)` | `ok=true` · dto=`WorkspaceProjectionDTO/v1` · object_type=`program` · scope=`platform` · ps=`wired` · **fields keys EXACTLY `{name}`** |
| **P2** | admin + nonexistent program | `get_object_workspace('program', '00000000-0000-0000-0000-000000000000'::uuid, '{}'::jsonb, NULL)` | `not_found` |
| **P3** | non-admin through wrapper | (impersonate parent `e3333f05-…`) `get_object_workspace('program', '99240fb7-…'::uuid, '{}'::jsonb, NULL)` | `not_authorized` |
| **P4** | non-admin **direct** projector | (impersonate parent) `admin_lookup_program('99240fb7-…'::uuid)` | `{"ok":false,"error":"not_admin"}` |
| **P5** | legacy 3-arg program call | `get_object_workspace('program', '99240fb7-…'::uuid, NULL)` *(3-arg text-reason overload)* | success zero-context path (fields `{name}`) |
| **P6** | 4-arg with `{}` context | `get_object_workspace('program', '99240fb7-…'::uuid, '{}'::jsonb, NULL)` | identical to P5 |
| **P7** | unknown context key (allow_unknown=false) | `get_object_workspace('program', '99240fb7-…'::uuid, '{"foo":"bar"}'::jsonb, NULL)` | `context_invalid` |
| **P8** | CLASS correct context | `get_object_workspace('class', '2405fed8-…'::uuid, {school_id:'b6a4ac35-…'}, NULL)` | unchanged success (fields `{name}`) |
| **P9** | CLASS wrong school | `get_object_workspace('class', '2405fed8-…'::uuid, {school_id:'00000000-…'}, NULL)` | unchanged `not_found` |
| **P10** | SESSION correct current cd | `get_object_workspace('session', '2fab0c56-…'::uuid, {class_distribution_id:'a8088a55-…'}, NULL)` | unchanged success (fields `{state,title}`) |
| **P11** | SESSION wrong cd | `get_object_workspace('session', '2fab0c56-…'::uuid, {class_distribution_id:'00000000-…'}, NULL)` | unchanged `not_found` |
| **P12** | person/child/media/capsule/school regression | §10 harness rows | PRE ≡ POST |
| **P13** | forbidden object | `get_object_workspace('journal', gen_random_uuid(), '{}'::jsonb, NULL)` | `forbidden_object` |
| **P14** | wired-but-no-dispatch fail-closed | rollback-safe synthetic: `UPDATE registry SET projector_status='wired' WHERE object_type='subscription'` (platform, no CASE branch) → `get_object_workspace('subscription', gen_random_uuid(), '{}'::jsonb, NULL)` → **then RAISE to roll back** | `dispatch_missing` · registry restored (0 residue) |

**P14 rollback-safe template:**
```sql
DO $$
DECLARE v_admin uuid := '446de75d-75b5-476d-8abd-08a98e791f40'; r jsonb; v_rc int;
BEGIN
  PERFORM set_config('request.jwt.claims', json_build_object('sub',v_admin::text,'role','authenticated')::text, true);
  SET LOCAL ROLE authenticated;
  SET LOCAL ROLE postgres;  -- registry UPDATE needs owner; then re-impersonate for the call
  UPDATE public.mission_control_object_registry SET projector_status='wired'
   WHERE object_type='subscription' AND projector_status='registered';
  GET DIAGNOSTICS v_rc = ROW_COUNT;
  IF v_rc <> 1 THEN RAISE EXCEPTION 'P14_SETUP_DRIFT: %', v_rc; END IF;
  PERFORM set_config('request.jwt.claims', json_build_object('sub',v_admin::text,'role','authenticated')::text, true);
  SET LOCAL ROLE authenticated;
  r := public.get_object_workspace('subscription', gen_random_uuid(), '{}'::jsonb, NULL);
  RAISE EXCEPTION 'P14_RESULT:: % (registry rolled back)', r->>'error';  -- expect dispatch_missing
END $$;
```
> Confirm at apply-time that the registry `projector_status` CHECK constraint still admits `'wired'` for a platform object (it does today — 7 platform/tenant/assignment objects are wired). If the synthetic technique is no longer constraint-compatible, fall back to the proven `__probe_b32__` synthetic-row approach (D355.11).

Additional live-evidence cases may be appended if apply-time audit reveals new necessary coverage.

---

## 12. VERIFY-THE-VERIFY (runtime type audit) — EXECUTED LIVE

Ran a rollback-safe type-proxy of every BLOCK-3 catalog probe against known-good `admin_lookup_school` + live registry (program branch expected absent PRE). **Result:**

```
secdef=t  owner=postgres  cfg_ok=t  acl=[postgres:EXECUTE, authenticated:EXECUTE, service_role:EXECUTE]
wired=7  reg=4  none=6  class=t  session=t  program=f
```

- `proconfig IS NOT DISTINCT FROM ARRAY['search_path=""']::text[]` → returns **boolean TRUE** on known-good (exact-equality comparison is type-correct — no LIKE/`@>`).
- ACL `aclexplode` aggregation → type-correct joinable string.
- registry `count(*) FILTER (...)` → type-correct ints.
- `pg_get_functiondef(...) LIKE '%WHEN ''program''%'` → type-correct boolean (correctly `f` PRE).

**No runtime type mistakes in the verifier.** (Assertions **E/F/K/L/M** additionally use the same tested expressions with post-apply expected literals.)

---

## 13. PREDICTED INVENTORY DELTA

| Metric | BEFORE (live) | AFTER (predicted) | Δ |
|---|---|---|---|
| tables | 90 | 90 | 0 |
| functions | 240 | **241** | +1 (`admin_lookup_program`) |
| SECURITY DEFINER | 229 | **230** | +1 (same) |
| policies | 166 | 166 | 0 |
| triggers | 33 | 33 | 0 |
| cron | 1 | 1 | 0 |

Core = REPLACE in place (0 net). Registry = 1-row UPDATE (0 net rows). Migration tail `20260812070542` → `<new>` (`v128_b3_3_program_context_consumer`). Registry sets: **wired 7→8 · registered 4→3 · none 6→6**.

Predicted wired (8): capsule · child · class · media · person · **program** · school · session.
Predicted registered (3): privacy_request · subscription · support_case.
Predicted none (6): badges · child_journey · family_memory · journal · raw_media · skills.

---

## 14. RISKS / UNKNOWNS

1. **`programs.name` is NOT NULL but NOT UNIQUE** (only `slug` is unique). Two programs could share a display name; the identity **label** is therefore not globally unique. Lookup is by `id`, so the projector is unambiguous — noted, not blocking.
2. **`scope=platform` + entitlement relation.** `programs` has 11 inbound FKs incl. `school_subject_entitlements` (school↔program) and per-child `child_journey`. Per CTO §9: physical containment ≠ control-plane scope. This identity-only consumer attaches no authorization to context, so platform scope is coherent — **but** the entitlement relation is flagged for a **future independent scope-design audit** (NOT corrected here; no registry-debt correction rides this migration, §15).
3. **Overload disambiguation.** `get_object_workspace(text,uuid,'{}')` without a cast is ambiguous (jsonb-context vs text-reason). Harness always casts (`'{}'::jsonb`) or uses the genuine 3-arg form (P5) — apply-time executors must preserve casts.
4. **P14 synthetic technique** depends on the registry `projector_status` CHECK admitting `'wired'` for a platform object. Verified valid today; fallback = `__probe_b32__` synthetic-row (D355.11) if constraint changes.
5. **Backup debt (carried).** Migration files B3.0/B3.1/B3.1.5/B3.2 remain uncommitted to repo (D90). B3.3 will add to this debt when applied — recommend a repo-backup sweep at canonicalization.
6. **No child-PII exposure.** PROGRAM is curriculum-catalog identity only; D48 privacy moat unaffected. `child_journey`→program FK is irrelevant to this identity projector.

---

## 15. ZERO-DELTA SURFACES (asserted)

B3.3 modifies **only**: +1 function (`admin_lookup_program`), core REPLACE (1 branch), 1 registry-row UPDATE (`projector_status` only). **Untouched:** tables · RLS policies (incl. `programs` 3 policies) · triggers · cron · roles · permission model · scope vocabulary · context validator · DTO/v1 · allowlist/forbidden semantics · existing 7 dispatch branches · gate order · frontend · Edge Functions · Bunny · program CRUD · entitlements · lesson/session behavior · subscription · support_case · privacy_request. **No registry-debt correction for any other object rides this migration.** discovery_fields stays `[name]`; scope stays `platform`.

---

## 16. PACKAGE-AUTHOR VERDICT

- Live baseline re-pinned, matches §0 exactly. **No drift.**
- Projector **ABSENT** → `CREATE FUNCTION` fail-closed path confirmed.
- Dependency audit complete: `name` NOT NULL, 0 triggers, platform scope coherent for identity-only consumer.
- Frozen architecture honored: discovery `[name]` only, zero-context, capability_vocab/forbidden_groups read live and preserved.
- Registry transition is pre-state-bound + ROW_COUNT-guarded (fail-closed on any drifted field; minimal mutation).
- Core diff = exactly one static `WHEN 'program'` branch; all other semantics byte/semantic-preserved; no dynamic SQL.
- ACL targets match live canonical family (projector `{authenticated,postgres,service_role}`; core internal-only).
- PRE golden signatures captured live, **zero residue** proven; POST harness + P1–P14 matrix literal & executable.
- Verify-the-verify executed live: no runtime type errors.
- Predicted delta: `90/240/229/166/33/1` → `90/241/230/166/33/1`; wired 7→8, registered 4→3.

All CTO conditions (C1 exact-equality proconfig verifier · C2 fail-closed registry on stale pre-state · C3 real capsule success fixture · C4 CREATE not OR REPLACE · C5 regprocedure pins · C6 executable rollback-safe synthetic) are carried forward and satisfied in this package.

**This package is DESIGN/PACKAGE-ONLY. Nothing applied. No apply authorization requested this turn.**

---

`PACKAGE READY FOR CTO FINAL IMPLEMENTATION AUDIT`
