# V128-B3.3 — FINAL IMPLEMENTATION PACKAGE v3

**Scope:** PACKAGE-CORRECTION ONLY. No apply. No production mutation. No D356 canonicalization. No HANDOFF. No B3.4.
**Corrects:** the single CTO v2 governance blocker — registry transition not exact-PRE-state-bound + BLOCK-3 assertion K missing `context_requirements`/`capability_vocab`. All five v2 corrections are preserved verbatim; nothing reverted.
**All evidence below is fresh this session via rollback-safe (`RAISE`-abort) transactions. Zero production mutation** — verified at close: projector ABSENT, program `registered`, registry 17, functions 240, audit residue 0, probe residue 0.

---

## 1. FRESH LIVE RE-PIN (read-only)

| Item | Live | Expected | Match |
|---|---|---|---|
| migration tail | `20260812070542` | `20260812070542` | ✅ |
| tables | 90 | 90 | ✅ |
| functions | 240 | 240 | ✅ |
| SECURITY DEFINER | 229 | 229 | ✅ |
| policies | 166 | 166 | ✅ |
| triggers | 33 | 33 | ✅ |
| cron | 1 | 1 | ✅ |
| registry total | 17 | 17 | ✅ |
| `admin_lookup_program(uuid)` | ABSENT (0) | ABSENT | ✅ |
| core `WHEN 'program'` branch | ABSENT (pos 0) | ABSENT | ✅ |

Exact memberships (live):
- **wired** = `capsule,child,class,media,person,school,session`
- **registered** = `privacy_request,program,subscription,support_case`
- **none** = `badges,child_journey,family_memory,journal,raw_media,skills`

Core: `_mission_control_workspace_core(text,uuid,jsonb,text)`, `prosecdef=true`, owner `postgres`, `proconfig=["search_path=\"\""]`. Wrappers `get_object_workspace(text,uuid,text)` (legacy→`'{}'::jsonb`) + `(text,uuid,jsonb,text)` present, `LANGUAGE sql`, SECDEF, `search_path=""`. Validator + `is_admin()` present.

## 2. DRIFT VERDICT

**NO DRIFT.** All re-pinned surfaces match baseline exactly. Package v3 issued.

## 3. EXACT PROGRAM PRE-STATE (recaptured; predicate matches EXACTLY 1 row)

```
object_type          = program
kind                 = supporting
scope                = platform
projector_status     = registered
privacy_policy       = open
discovery_fields     = ["name"]
context_requirements = {"keys":{},"version":1,"allow_unknown":false}
capability_vocab     = {"edit":"program.edit","view":null}
forbidden_groups     = []
```
Full frozen-field predicate → `pred_count = 1` (live). `programs.name` NOT NULL confirmed; projector projects only `{id,name}`.

## 4. CTO BLOCKER CORRECTION

**Blocker (v2):** registry `UPDATE` bound only `object_type='program' AND projector_status='registered'` — weaker than the B3.2 fail-closed pattern; and BLOCK-3 assertion K omitted `context_requirements` + `capability_vocab`.

**Correction (v3):**
1. **Registry transition** is now a guarded `DO` block whose `WHERE` binds **all nine frozen PRE-state fields**, followed by `GET DIAGNOSTICS v_n = ROW_COUNT` and a `v_n <> 1 → RAISE EXCEPTION` fail-closed guard. If the row disappeared, duplicated, or any frozen metadatum drifted between preflight and mutation, the migration aborts atomically. (§7 block 1c, proof §9.)
2. **BLOCK-3 assertion K** now asserts the **complete** frozen PROGRAM POST-state including `context_requirements` and `capability_vocab`, using `IS DISTINCT FROM` for fail-closed JSONB/array equality — no partial containment. (§7 block 3.)

No architecture redesign. All v2 corrections retained (one-query projector, deterministic ACL, executable harness, exact-membership BLOCK 3, synthetic `__probe_b33__`).

## 5. UPDATED_AT DECISION (grounded from live)

**Decision: Option A — keep `updated_at = now()` as bookkeeping.**

Live evidence: `mission_control_object_registry` has **no trigger** maintaining `updated_at` (0 triggers on the table). The two most recent wiring transitions set it explicitly — `school` `updated_at = 2026-08-11 08:00:37` (= B2.2 migration `20260811080037`) and `class` `updated_at = 2026-08-12 02:31:55` (B3.x) — while earlier same-batch seeds (capsule/session) retain `created_at = updated_at`. Explicit `updated_at = now()` on a wiring transition is therefore the **established live convention**, and there is no trigger to do it automatically.

**Corrected wording:** *The only business-metadata transition is `projector_status: registered → wired`; `updated_at = now()` is bookkeeping following the established B2.2/B3.x wiring convention.*

## 6. FROZEN ARCHITECTURE CONTRACT (unchanged, ratified)

object_type `program` · source `public.programs` · kind `supporting` · scope `platform` · privacy `open` · `registered → wired` · discovery_fields EXACTLY `["name"]` · context zero `{"keys":{},"version":1,"allow_unknown":false}` · capability_vocab `{"edit":"program.edit","view":null}` · forbidden_groups `[]` · projector `admin_lookup_program(uuid)` · payload only `{id,name}` · DTO fields EXACTLY `{name}` · no slug/description/state/artistic_domain · no entitlement/scope/context/RLS/DTO/frontend/dynamic-SQL change.

Predicted delta `90/240/229/166/33/1` → `90/241/230/166/33/1`; registry wired `7→8`, registered `4→3`, none `6→6`, total 17.

## 7. FULL LITERAL 3-BLOCK MIGRATION SQL

**Migration name:** `v128_b3_3_program_context_consumer` (no live collision). **Apply tool:** `apply_migration` (atomic). **DO NOT APPLY — awaiting CTO + Owner gate.**

```sql
-- ============================================================================
-- v128_b3_3_program_context_consumer
-- BLOCK 1 — DDL / DML
-- ============================================================================

-- 1a. PROJECTOR (new; one-query identity lookup)
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
  SELECT jsonb_build_object('ok',true,
           'program', jsonb_build_object('id',pr.id,'name',pr.name))
    INTO v
    FROM public.programs pr
   WHERE pr.id = p_program_id;
  IF v IS NULL THEN
    RETURN jsonb_build_object('ok',false,'error','not_found'); END IF;
  RETURN v;
END
$function$;

-- 1b. CORE (replace; single new WHEN 'program' branch — no other semantic delta)
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

-- 1c. REGISTRY TRANSITION — exact PRE-state-bound + ROW_COUNT=1 fail-closed guard
--     Only business transition: projector_status registered -> wired.
--     updated_at = now() is bookkeeping (B2.2/B3.x wiring convention; no trigger maintains it).
DO $transition$
DECLARE v_n integer;
BEGIN
  UPDATE public.mission_control_object_registry
     SET projector_status = 'wired',
         updated_at       = now()
   WHERE object_type          = 'program'
     AND kind                 = 'supporting'
     AND scope                = 'platform'
     AND projector_status     = 'registered'
     AND privacy_policy       = 'open'
     AND discovery_fields     = ARRAY['name']::text[]
     AND context_requirements = '{"keys":{},"version":1,"allow_unknown":false}'::jsonb
     AND capability_vocab     = '{"edit":"program.edit","view":null}'::jsonb
     AND forbidden_groups     = ARRAY[]::text[];
  GET DIAGNOSTICS v_n = ROW_COUNT;
  IF v_n <> 1 THEN
    RAISE EXCEPTION 'PROGRAM_TRANSITION_GUARD_FAIL: expected exactly 1 pre-state-bound row, got %', v_n;
  END IF;
END
$transition$;

-- ============================================================================
-- BLOCK 2 — ACL HARDENING (D15 / D231: proacl resets on CREATE OR REPLACE)
-- ============================================================================

-- Projector -> authenticated, postgres(owner), service_role
REVOKE ALL ON FUNCTION public.admin_lookup_program(uuid) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.admin_lookup_program(uuid) FROM anon;
GRANT  EXECUTE ON FUNCTION public.admin_lookup_program(uuid) TO authenticated;
GRANT  EXECUTE ON FUNCTION public.admin_lookup_program(uuid) TO service_role;

-- Core re-harden -> postgres(owner), service_role only (no PUBLIC/anon/authenticated)
REVOKE ALL ON FUNCTION public._mission_control_workspace_core(text,uuid,jsonb,text) FROM PUBLIC;
REVOKE ALL ON FUNCTION public._mission_control_workspace_core(text,uuid,jsonb,text) FROM anon;
REVOKE ALL ON FUNCTION public._mission_control_workspace_core(text,uuid,jsonb,text) FROM authenticated;
GRANT  EXECUTE ON FUNCTION public._mission_control_workspace_core(text,uuid,jsonb,text) TO service_role;

-- ============================================================================
-- BLOCK 3 — STRUCTURAL VERIFIER (RAISE-on-failure -> atomic rollback)
-- ============================================================================
DO $verify$
DECLARE
  v_proj_owner text; v_proj_secdef boolean; v_proj_cfg text[];
  v_proj_acl text; v_core_acl text;
  v_core_def text; v_prog record;
  v_wired text; v_reg text; v_none text; v_total int;
  v_tables int; v_funcs int; v_secdef int; v_pol int; v_trig int; v_cron int;
BEGIN
  -- A projector exists by regprocedure
  PERFORM 'public.admin_lookup_program(uuid)'::regprocedure;

  -- B/C/D owner / secdef / proconfig
  SELECT pg_get_userbyid(proowner), prosecdef, proconfig
    INTO v_proj_owner, v_proj_secdef, v_proj_cfg
    FROM pg_proc WHERE oid = 'public.admin_lookup_program(uuid)'::regprocedure;
  IF v_proj_owner <> 'postgres' THEN RAISE EXCEPTION 'FAIL_B owner=%', v_proj_owner; END IF;
  IF NOT v_proj_secdef THEN RAISE EXCEPTION 'FAIL_C not security definer'; END IF;
  IF v_proj_cfg IS DISTINCT FROM ARRAY['search_path=""'] THEN RAISE EXCEPTION 'FAIL_D proconfig=%', v_proj_cfg; END IF;

  -- E projector ACL (deterministic order)
  SELECT string_agg(
           (CASE WHEN a.grantee=0 THEN 'PUBLIC' ELSE COALESCE(r.rolname,a.grantee::text) END)||':'||a.privilege_type,
           ',' ORDER BY (CASE WHEN a.grantee=0 THEN 'PUBLIC' ELSE COALESCE(r.rolname,a.grantee::text) END), a.privilege_type)
    INTO v_proj_acl
    FROM pg_proc p CROSS JOIN LATERAL aclexplode(coalesce(p.proacl,acldefault('f',p.proowner))) a
    LEFT JOIN pg_roles r ON r.oid=a.grantee
   WHERE p.oid='public.admin_lookup_program(uuid)'::regprocedure;
  IF v_proj_acl <> 'authenticated:EXECUTE,postgres:EXECUTE,service_role:EXECUTE' THEN
    RAISE EXCEPTION 'FAIL_E projector_acl=%', v_proj_acl; END IF;

  -- F core ACL (deterministic order)
  SELECT string_agg(
           (CASE WHEN a.grantee=0 THEN 'PUBLIC' ELSE COALESCE(r.rolname,a.grantee::text) END)||':'||a.privilege_type,
           ',' ORDER BY (CASE WHEN a.grantee=0 THEN 'PUBLIC' ELSE COALESCE(r.rolname,a.grantee::text) END), a.privilege_type)
    INTO v_core_acl
    FROM pg_proc p CROSS JOIN LATERAL aclexplode(coalesce(p.proacl,acldefault('f',p.proowner))) a
    LEFT JOIN pg_roles r ON r.oid=a.grantee
   WHERE p.oid='public._mission_control_workspace_core(text,uuid,jsonb,text)'::regprocedure;
  IF v_core_acl <> 'postgres:EXECUTE,service_role:EXECUTE' THEN
    RAISE EXCEPTION 'FAIL_F core_acl=%', v_core_acl; END IF;

  -- G core exists by regprocedure
  PERFORM 'public._mission_control_workspace_core(text,uuid,jsonb,text)'::regprocedure;

  -- H/I/J branch retention
  v_core_def := pg_get_functiondef('public._mission_control_workspace_core(text,uuid,jsonb,text)'::regprocedure);
  IF position('WHEN ''class''' IN v_core_def) = 0   THEN RAISE EXCEPTION 'FAIL_H class branch missing'; END IF;
  IF position('WHEN ''session''' IN v_core_def) = 0 THEN RAISE EXCEPTION 'FAIL_I session branch missing'; END IF;
  IF position('WHEN ''program''' IN v_core_def) = 0 THEN RAISE EXCEPTION 'FAIL_J program branch missing'; END IF;

  -- K program registry row — COMPLETE frozen POST-state (incl context + capability), fail-closed
  SELECT * INTO v_prog FROM public.mission_control_object_registry WHERE object_type='program';
  IF v_prog.projector_status <> 'wired'
     OR v_prog.kind <> 'supporting'
     OR v_prog.scope <> 'platform'
     OR v_prog.privacy_policy <> 'open'
     OR v_prog.discovery_fields     IS DISTINCT FROM ARRAY['name']::text[]
     OR v_prog.forbidden_groups     IS DISTINCT FROM ARRAY[]::text[]
     OR v_prog.context_requirements IS DISTINCT FROM '{"keys":{},"version":1,"allow_unknown":false}'::jsonb
     OR v_prog.capability_vocab     IS DISTINCT FROM '{"edit":"program.edit","view":null}'::jsonb THEN
    RAISE EXCEPTION 'FAIL_K program row drift=%', row_to_json(v_prog); END IF;

  -- L total
  SELECT count(*) INTO v_total FROM public.mission_control_object_registry;
  IF v_total <> 17 THEN RAISE EXCEPTION 'FAIL_L total=%', v_total; END IF;

  -- M/N/O exact memberships (deterministic sorted)
  SELECT string_agg(object_type,',' ORDER BY object_type) FILTER (WHERE projector_status='wired'),
         string_agg(object_type,',' ORDER BY object_type) FILTER (WHERE projector_status='registered'),
         string_agg(object_type,',' ORDER BY object_type) FILTER (WHERE projector_status='none')
    INTO v_wired, v_reg, v_none
    FROM public.mission_control_object_registry;
  IF v_wired <> 'capsule,child,class,media,person,program,school,session' THEN RAISE EXCEPTION 'FAIL_M wired=%', v_wired; END IF;
  IF v_reg   <> 'privacy_request,subscription,support_case' THEN            RAISE EXCEPTION 'FAIL_N registered=%', v_reg; END IF;
  IF v_none  <> 'badges,child_journey,family_memory,journal,raw_media,skills' THEN RAISE EXCEPTION 'FAIL_O none=%', v_none; END IF;

  -- P inventory exact predicted
  SELECT (SELECT count(*) FROM pg_tables WHERE schemaname='public'),
         (SELECT count(*) FROM pg_proc p JOIN pg_namespace n ON n.oid=p.pronamespace WHERE n.nspname='public'),
         (SELECT count(*) FROM pg_proc p JOIN pg_namespace n ON n.oid=p.pronamespace WHERE n.nspname='public' AND p.prosecdef),
         (SELECT count(*) FROM pg_policies WHERE schemaname='public'),
         (SELECT count(*) FROM pg_trigger t JOIN pg_class c ON c.oid=t.tgrelid JOIN pg_namespace n ON n.oid=c.relnamespace WHERE n.nspname='public' AND NOT t.tgisinternal),
         (SELECT count(*) FROM cron.job)
    INTO v_tables, v_funcs, v_secdef, v_pol, v_trig, v_cron;
  IF v_tables<>90 OR v_funcs<>241 OR v_secdef<>230 OR v_pol<>166 OR v_trig<>33 OR v_cron<>1 THEN
    RAISE EXCEPTION 'FAIL_P inventory=%/%/%/%/%/%', v_tables,v_funcs,v_secdef,v_pol,v_trig,v_cron; END IF;

  RAISE NOTICE 'V128-B3.3 STRUCTURAL VERIFY PASS (A-P)';
END
$verify$;

NOTIFY pgrst, 'reload schema';
```

## 8. DETERMINISTIC ACL PROOF (verify-the-verify, live v3)

The exact BLOCK-3 E/F/D expressions run live this session against known-good functions:

| function | `proconfig = ARRAY['search_path=""']` | ACL (deterministic) | ✅ |
|---|---|---|---|
| `admin_lookup_school(uuid)` (projector) | true | `authenticated:EXECUTE,postgres:EXECUTE,service_role:EXECUTE` | ✅ |
| `_mission_control_workspace_core(text,uuid,jsonb,text)` | true | `postgres:EXECUTE,service_role:EXECUTE` | ✅ |

Ordering is explicit on grantee-label then privilege. Zero PUBLIC, zero anon; core zero authenticated. Byte-identical to assertions D/E/F.

## 9. EXACT PRE-STATE TRANSITION PROOF

- **Predicate selectivity (live):** full frozen-field predicate → `pred_count = 1`.
- **Type-correct equality (live):** `context_requirements IS DISTINCT FROM {frozen}` = false; `capability_vocab IS DISTINCT FROM {frozen}` = false; `discovery_fields IS DISTINCT FROM ARRAY['name']` = false; `forbidden_groups IS DISTINCT FROM ARRAY[]` = false.
- **Guarded transition runtime (rollback-safe):** the exact block 1c `UPDATE … GET DIAGNOSTICS v_n = ROW_COUNT; IF v_n<>1 RAISE` executed live → `GUARD_OK|rows=1`, then `RAISE`-aborted (no mutation). `v_n integer` type valid, `ROW_COUNT` valid.

Fail-closed proven: if the pre-state drifts, `v_n <> 1` and the migration aborts atomically.

## 10. FULL-CORE DIFF PROOF

Live core recaptured this session. v3 core (§7 block 1b) is byte-identical to live **except one added line** after `WHEN 'session'`, before `ELSE`:

```diff
       WHEN 'session' THEN v_raw:=public.admin_lookup_session(
                              p_object_id,
                              (v_ctx->>'class_distribution_id')::uuid
                            );                                              v_source:=v_raw->'session';
+      WHEN 'program' THEN v_raw:=public.admin_lookup_program(p_object_id); v_source:=v_raw->'program';
       ELSE RETURN jsonb_build_object('ok',false,'error','dispatch_missing','object_type',p_object_type);
```

**CORE DIFF INVARIANT satisfied.** Retained verbatim: auth gate · registry gate order · 3-value scope allowlist · fail-closed context validator · B3.0 NO-OP slot · privacy/reason + audit logging · seven existing projector branches · projector error normalization · discovery allowlist · forbidden sentinel · `WorkspaceProjectionDTO/v1`. No dynamic SQL. This exact core compiled and ran in the §11 harness.

## 11. EXECUTABLE PRE/POST REGRESSION HARNESS (runtime-checked, v3)

Full v3 migration logic (projector + program-branch core + **guarded** transition) applied inside one rollback-safe `DO` block; PRE/POST captured; `RAISE`-aborted. Admin impersonation via `set_config('request.jwt.claims',…)`; reason-required consumers (child, capsule) passed a reason (audit rolled back). **Actual result:**

```
guard_rows  = 1
diffcount   = 0
diffkeys    = []
progpre     = not_available
post_ok     = true
fields      = {"name": "Cảm Thụ Âm Nhạc Dế Mèn"}
keys        = name
legacy_ok   = true
p2          = not_found
p7          = context_invalid
p4          = not_admin
```

Seven golden consumers **PRE ≡ POST, DIFFCOUNT = 0**. Capsule REAL success; CLASS retained `school_id`; SESSION retained `class_distribution_id`. PROGRAM `not_available → ok`, fields EXACTLY `{name}`. Post-run: audit residue = 0, projector ABSENT, program `registered`, registry 17.

## 12. FUNCTIONAL MATRIX P1–P14 (observed = executed rollback-safe)

| # | Test | Expected | Observed | ✅ |
|---|---|---|---|---|
| P1 | admin + existing PROGRAM (4-arg) → fields EXACTLY `{name}` | ok, `{name}` | ok, keys=`name`, `{"name":"Cảm Thụ Âm Nhạc Dế Mèn"}` | ✅ |
| P2 | nonexistent PROGRAM | `not_found` | `not_found` | ✅ |
| P3 | non-admin via wrapper | `not_authorized` | `not_authorized` | ✅ |
| P4 | non-admin direct projector | `not_admin` | `not_admin` | ✅ |
| P5 | legacy 3-arg PROGRAM | success | `legacy_ok=true` | ✅ |
| P6 | 4-arg `{}` PROGRAM | success | `post_ok=true` | ✅ |
| P7 | unknown context key (POST) | `context_invalid` | `context_invalid` | ✅ |
| P8 | CLASS correct context | unchanged success | PRE≡POST (diff 0) | ✅ |
| P9 | CLASS wrong school | `not_found` | `not_found` | ✅ |
| P10 | SESSION correct distribution | unchanged success | PRE≡POST (diff 0) | ✅ |
| P11 | SESSION wrong distribution | `not_found` | `not_found` | ✅ |
| P12 | person/child/media/capsule/school regression | PRE ≡ POST | diff 0 | ✅ |
| P13 | forbidden object (`raw_media`) | `forbidden_object` | `forbidden_object` | ✅ |
| P14 | synthetic `__probe_b33__` | `dispatch_missing` + rollback + 0 residue | §13 | ✅ |

*P7 note:* PRE-wire, PROGRAM short-circuits at the `registered → not_available` gate before context validation, so unknown-key → `not_available` PRE and `context_invalid` only POST-wire — correct fail-closed ordering.

## 13. SYNTHETIC P14 ROLLBACK PROOF (fresh v3)

Synthetic isolated row inserted in a rollback-safe `DO` harness, satisfying all live registry constraints (`kind='supporting'`, `scope='platform'`, `privacy='open'`, `projector_status='wired'`, zero-context default). No CASE dispatch exists. **Actual result:**

```
rows-in-transaction = 18   (17 + 1 synthetic)
get_object_workspace('__probe_b33__', …) → dispatch_missing
terminal RAISE → rollback
post-rollback registry total = 17
probe residue = 0
```
Real `subscription` / `support_case` / `privacy_request` rows untouched.

## 14. VERIFY-THE-VERIFY (all 10 items, live)

1. exact `proconfig = ARRAY['search_path=""']` → true (§8). ✅
2. deterministic projector ACL aggregation → `authenticated,postgres,service_role` (§8). ✅
3. deterministic core ACL aggregation → `postgres,service_role` (§8). ✅
4. exact membership aggregation → PRE sets match (§1). ✅
5. PROGRAM PRE-state predicate matches EXACTLY 1 row → `pred_count=1` (§9). ✅
6. JSONB equality (context_requirements, capability_vocab) type-correct → `IS DISTINCT FROM` = false (§9). ✅
7. text[] equality (discovery_fields, forbidden_groups) type-correct → `IS DISTINCT FROM` = false (§9). ✅
8. `GET DIAGNOSTICS ROW_COUNT` var type valid → `GUARD_OK|rows=1` (§9). ✅
9. inventory expressions compile & return baseline → `90/240/229/166/33/1` (§1). ✅
10. branch-retention `position('WHEN ''program''' …)` compiles & returns int → live 0 (absent), harness POST >0. ✅

No unexecuted expression is claimed proven.

## 15. PREDICTED INVENTORY DELTA

```
BEFORE : 90 / 240 / 229 / 166 / 33 / 1
AFTER  : 90 / 241 / 230 / 166 / 33 / 1
```
+1 function, +1 SECURITY DEFINER = `admin_lookup_program`. Core `CREATE OR REPLACE` is net-zero (same OID). Registry stays 17 rows; wired `7→8`, registered `4→3`, none `6→6`. No table/policy/trigger/cron delta. Asserted by BLOCK-3 P + K/L/M/N/O.

## 16. RISKS / UNKNOWNS

- **Pre-state binding is now strictly fail-closed:** any drift between preflight and apply → `v_n<>1` → atomic abort (block 1c), and BLOCK-3 K re-asserts complete POST-state. This closes the CTO v2 gap.
- **`proconfig` literal:** compared as `ARRAY['search_path=""']`, exactness proven live (=true).
- **ACL default-grant reset (D231):** BLOCK 2 explicitly `REVOKE … FROM authenticated` on core; without it assertion F fail-closes.
- **Apply-time gap:** evidence is point-in-time; if any object is wired/registered before apply, block 1c guard and/or BLOCK-3 M/N/O/L fail-closed → rollback. Apply promptly after audit.
- `No known blocker remains at package-author level.`

## 17. PACKAGE-AUTHOR VERDICT

All v2 corrections preserved; the sole CTO v2 governance blocker corrected and proven:
- guarded exact PRE-state-bound registry transition + `ROW_COUNT=1` fail-closed guard — runtime-verified (`GUARD_OK|rows=1`, rollback-safe);
- BLOCK-3 assertion K now asserts complete frozen POST-state incl `context_requirements` + `capability_vocab` (fail-closed `IS DISTINCT FROM`);
- `updated_at` decision grounded from live convention (Option A, corrected wording);
- full PRE/POST harness re-run green (diffcount 0, program flip, `{name}`); P1–P14 all PASS; synthetic P14 clean; every verifier expression executed live.

Literal executability audit: zero placeholder, zero pseudocode, zero omitted body, zero known compile error. Every SQL block was runtime-checked this session.

# PACKAGE v3 READY FOR CTO FINAL IMPLEMENTATION AUDIT

**HARD STOP.** No migration applied. No APPLY authorization assumed or requested. No D356 canonicalization. No B3.3 HANDOFF. No B3.4. No production mutation. PROGRAM architecture unchanged. Next action: Owner forwards PACKAGE v3 to ChatGPT/CTO for independent final implementation audit.
