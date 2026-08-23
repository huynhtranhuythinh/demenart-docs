# V128-B3.3 — FINAL IMPLEMENTATION PACKAGE v2

**Scope:** PACKAGE-CORRECTION ONLY. No apply. No production mutation. No canonicalization. No B3.4.
**Author role:** Technical PM / Migration Engineer / Evidence Collector.
**All runtime evidence below was produced this session via rollback-safe (`RAISE`-abort) transactions. Zero production mutation occurred** — verified at close: projector still ABSENT, program still `registered`, registry = 17, audit residue = 0.

---

## 1. FRESH LIVE RE-PIN (read-only)

| Item | Live | Expected (baseline) | Match |
|---|---|---|---|
| tables | 90 | 90 | ✅ |
| functions | 240 | 240 | ✅ |
| SECURITY DEFINER | 229 | 229 | ✅ |
| policies | 166 | 166 | ✅ |
| triggers | 33 | 33 | ✅ |
| cron | 1 | 1 | ✅ |
| migration tail | `20260812070542` | `20260812070542` | ✅ |
| registry total | 17 | 17 | ✅ |
| wired | 7 | 7 | ✅ |
| registered | 4 | 4 | ✅ |
| none | 6 | 6 | ✅ |
| `admin_lookup_program(uuid)` | ABSENT (0) | ABSENT | ✅ |

Exact PRE memberships (live):
- **wired** = `capsule,child,class,media,person,school,session`
- **registered** = `privacy_request,program,subscription,support_case`
- **none** = `badges,child_journey,family_memory,journal,raw_media,skills`

Core signature live: `_mission_control_workspace_core(text,uuid,jsonb,text)` — `prosecdef=true`, owner `postgres`, `proconfig=["search_path=\"\""]`.
Wrappers live: `get_object_workspace(text,uuid,text)` (legacy, passes `'{}'::jsonb`) + `get_object_workspace(text,uuid,jsonb,text)` — both `LANGUAGE sql`, SECURITY DEFINER, `search_path=""`. Validator `validate_mission_control_object_context(text,jsonb)` present. `is_admin()` present.
Core ACL live: `postgres:EXECUTE,service_role:EXECUTE`. Projector-family ACL live (school/class/session): `authenticated:EXECUTE,postgres:EXECUTE,service_role:EXECUTE`.

## 2. DRIFT VERDICT

**NO DRIFT.** Every re-pinned surface matches the B3.3 architecture-pass baseline exactly. Proceeding with package correction.

## 3. EXACT PROGRAM LIVE PRE-STATE (recaptured this session)

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
Source table `public.programs`: `id uuid NOT NULL`, `name text NOT NULL`, `slug text NOT NULL`, `description text NULL`, `state (enum) NOT NULL`, `created_at tstz NOT NULL`, `artistic_domain text NULL`. → `name` NOT NULL confirmed; projector must project only `{id,name}` (no slug/description/state/artistic_domain).

The migration registry UPDATE is bound to this exact PRE-state via `WHERE object_type='program' AND projector_status='registered'`; only `projector_status` is mutated.

## 4. CORRECTED FROZEN ARCHITECTURE CONTRACT (unchanged from ratified)

object_type `program` · source `public.programs` · kind `supporting` · scope `platform` · privacy `open` · `registered → wired` · discovery_fields EXACTLY `[name]` · zero-context/empty keys · capability_vocab unchanged · forbidden_groups unchanged · projector `admin_lookup_program(uuid)` · identity payload only `{id,name}` · adapter fields EXACTLY `{name}` · legacy 3-arg works · 4-arg `{}` works · no description/slug/state/artistic_domain · no entitlement exposure · no scope/context/DTO/RLS/frontend/dynamic-SQL change.

Predicted structural delta: `90/240/229/166/33/1` → `90/241/230/166/33/1`. Registry wired `7→8`, registered `4→3`, none `6→6`, total 17.

## 5. CORRECTED ONE-QUERY PROJECTOR CONTRACT (BLOCKER 3 fix)

Package-v1 used a two-statement `IF NOT EXISTS (...)` + `SELECT`. v2 uses a **single identity lookup** — self-gate → one `SELECT … INTO` → `not_found` on NULL → else `{ok,program:{id,name}}`. No existence/read race, no fallback name, no slug, no dynamic SQL. `CREATE FUNCTION` (not OR REPLACE), SECURITY DEFINER, owner postgres, `search_path=""`.

Runtime-verified behaviour (POST harness, §10/§11): existing → `{ok:true,program:{id,name}}` (`{"name":"Cảm Thụ Âm Nhạc Dế Mèn"}`); nonexistent → `not_found`; non-admin direct → `not_admin`. No additional keys.

## 6. EXACT REGISTRY PRE→POST

| status | PRE | POST |
|---|---|---|
| wired | `capsule,child,class,media,person,school,session` (7) | `capsule,child,class,media,person,program,school,session` (8) |
| registered | `privacy_request,program,subscription,support_case` (4) | `privacy_request,subscription,support_case` (3) |
| none | `badges,child_journey,family_memory,journal,raw_media,skills` (6) | *(unchanged)* (6) |
| total | 17 | 17 |

Only `program.projector_status` changes (`registered → wired`). All other PROGRAM metadata columns (kind/scope/privacy/discovery_fields/context_requirements/capability_vocab/forbidden_groups) untouched.

## 7. FULL LITERAL 3-BLOCK MIGRATION SQL

**Migration name:** `v128_b3_3_program_context_consumer` (no live collision — confirmed).
**Apply tool:** `apply_migration` (atomic; BLOCK 3 `RAISE` rolls back the whole migration). **DO NOT APPLY — awaiting CTO + Owner gate.**

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

-- 1c. REGISTRY UPDATE (pre-state-bound; only projector_status mutated)
UPDATE public.mission_control_object_registry
   SET projector_status = 'wired',
       updated_at       = now()
 WHERE object_type = 'program'
   AND projector_status = 'registered';

-- ============================================================================
-- BLOCK 2 — ACL HARDENING (D15 / D231: proacl resets on CREATE OR REPLACE)
-- ============================================================================

-- Projector → authenticated, postgres(owner), service_role
REVOKE ALL ON FUNCTION public.admin_lookup_program(uuid) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.admin_lookup_program(uuid) FROM anon;
GRANT  EXECUTE ON FUNCTION public.admin_lookup_program(uuid) TO authenticated;
GRANT  EXECUTE ON FUNCTION public.admin_lookup_program(uuid) TO service_role;

-- Core re-harden → postgres(owner), service_role only (no PUBLIC/anon/authenticated)
REVOKE ALL ON FUNCTION public._mission_control_workspace_core(text,uuid,jsonb,text) FROM PUBLIC;
REVOKE ALL ON FUNCTION public._mission_control_workspace_core(text,uuid,jsonb,text) FROM anon;
REVOKE ALL ON FUNCTION public._mission_control_workspace_core(text,uuid,jsonb,text) FROM authenticated;
GRANT  EXECUTE ON FUNCTION public._mission_control_workspace_core(text,uuid,jsonb,text) TO service_role;

-- ============================================================================
-- BLOCK 3 — STRUCTURAL VERIFIER (RAISE-on-failure → atomic rollback)
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

  -- K program registry row exact approved POST-state
  SELECT * INTO v_prog FROM public.mission_control_object_registry WHERE object_type='program';
  IF v_prog.projector_status <> 'wired'
     OR v_prog.kind <> 'supporting'
     OR v_prog.scope <> 'platform'
     OR v_prog.privacy_policy <> 'open'
     OR v_prog.discovery_fields <> ARRAY['name']::text[]
     OR v_prog.forbidden_groups <> ARRAY[]::text[] THEN
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

## 8. CORRECTED DETERMINISTIC ACL PROOF (BLOCKER 2 fix) — VERIFY-THE-VERIFY, live

Ordering is now explicit on the generated grantee label then privilege (not `ORDER BY 1`). The EXACT catalog expression above was run live this session against known-good functions:

| function | ACL (v2 deterministic expression) | expected | ✅ |
|---|---|---|---|
| `admin_lookup_school(uuid)` | `authenticated:EXECUTE,postgres:EXECUTE,service_role:EXECUTE` | projector set | ✅ |
| `admin_lookup_class(uuid,uuid)` | `authenticated:EXECUTE,postgres:EXECUTE,service_role:EXECUTE` | projector set | ✅ |
| `admin_lookup_session(uuid,uuid)` | `authenticated:EXECUTE,postgres:EXECUTE,service_role:EXECUTE` | projector set | ✅ |
| `_mission_control_workspace_core(text,uuid,jsonb,text)` | `postgres:EXECUTE,service_role:EXECUTE` | core set | ✅ |

Zero PUBLIC, zero anon; core has zero authenticated. The expression is byte-identical to BLOCK-3 assertions E/F. **No false-failure risk from ordering.**

## 9. FRESH FULL-CORE DIFF PROOF

Live core recaptured this session via `pg_get_functiondef`. The v2 core (§7 block 1b) is byte-identical **except one added line** inside the `CASE`, placed after `WHEN 'session'` and before `ELSE`:

```diff
       WHEN 'session' THEN v_raw:=public.admin_lookup_session(
                              p_object_id,
                              (v_ctx->>'class_distribution_id')::uuid
                            );                                              v_source:=v_raw->'session';
+      WHEN 'program' THEN v_raw:=public.admin_lookup_program(p_object_id); v_source:=v_raw->'program';
       ELSE RETURN jsonb_build_object('ok',false,'error','dispatch_missing','object_type',p_object_type);
```

**CORE DIFF INVARIANT satisfied.** Preserved verbatim: auth gate · registry gate order (forbidden/none → registered/not_available → 3-value scope allowlist) · fail-closed context validator · B3.0 NO-OP context-authorization slot · privacy/reason + audit logging · all seven existing projector branches · projector error normalization · discovery allowlist (`ADAPTER_ALLOWLIST_VIOLATION`) · forbidden leak sentinel (`ADAPTER_FORBIDDEN_LEAK`) · `WorkspaceProjectionDTO/v1`. No dynamic SQL. This same core body compiled and ran in the harness (§10).

## 10. EXECUTABLE PRE/POST REGRESSION HARNESS (runtime-checked)

The complete migration logic (projector + program-branch core + registry flip) was applied inside a single rollback-safe `DO` block, PRE and POST captured, then `RAISE`-aborted. Admin impersonation via `set_config('request.jwt.claims', …)`. Reason-required consumers (child, capsule) passed a reason (audit writes rolled back). **Actual returned result:**

```
diffcount   = 0
diffkeys    = []
progpre     = not_available
post_ok     = true
post_fields = {"name": "Cảm Thụ Âm Nhạc Dế Mèn"}
keys        = name
legacy_ok   = true
p2          = not_found
p7          = context_invalid
p4          = not_admin
```

- Seven golden consumers (person, child, media, capsule, school, class, session) **PRE ≡ POST, DIFFCOUNT = 0.**
- Capsule remained a REAL success fixture; CLASS retained bound `school_id`; SESSION retained bound `class_distribution_id`.
- PROGRAM flipped `not_available → ok`; POST fields **EXACTLY `{name}`** (single key).
- Reason-writing rollback-safe: post-run `audit_logs WHERE reason='b33_regression'` = **0 residue**; projector still ABSENT; program still `registered`; registry 17.

## 11. FUNCTIONAL MATRIX P1–P14

| # | Test | Expected | Observed | ✅ |
|---|---|---|---|---|
| P1 | admin + existing PROGRAM (4-arg) → fields EXACTLY `{name}` | ok, `{name}` | ok, keys=`name`, `{"name":"Cảm Thụ Âm Nhạc Dế Mèn"}` | ✅ |
| P2 | nonexistent PROGRAM | `not_found` | `not_found` | ✅ |
| P3 | non-admin via wrapper | `not_authorized` | `not_authorized` | ✅ |
| P4 | non-admin direct projector | `not_admin` | `not_admin` | ✅ |
| P5 | legacy 3-arg PROGRAM | success | `legacy_ok=true` | ✅ |
| P6 | 4-arg `{}` PROGRAM | success | `post_ok=true` | ✅ |
| P7 | unknown context key | `context_invalid` | `context_invalid` (reachable only POST-wire) | ✅ |
| P8 | CLASS correct context | unchanged success | PRE≡POST (diffcount 0) | ✅ |
| P9 | CLASS wrong school | `not_found` | `not_found` | ✅ |
| P10 | SESSION correct distribution | unchanged success | PRE≡POST (diffcount 0) | ✅ |
| P11 | SESSION wrong distribution | `not_found` | `not_found` | ✅ |
| P12 | person/child/media/capsule/school regression | PRE ≡ POST | diffcount 0 | ✅ |
| P13 | forbidden object (`raw_media`) | `forbidden_object` | `forbidden_object` | ✅ |
| P14 | synthetic `__probe_b33__` | `dispatch_missing` + rollback + 0 residue | see §12 | ✅ |

**Note (P7 ordering insight):** PRE-wire, PROGRAM short-circuits at the `registered → not_available` gate before context validation, so an unknown key returns `not_available` PRE and `context_invalid` only POST-wire. This is correct fail-closed ordering, not a regression.

## 12. SYNTHETIC `__probe_b33__` ROLLBACK PROOF (CTO advisory fix)

P14 no longer mutates the real `subscription` row. A synthetic isolated probe is inserted inside a rollback-safe `DO` harness, satisfying all live registry constraints (`kind∈{core,supporting,future,forbidden}`, `scope∈{platform,tenant,assignment}` non-null for non-forbidden, `privacy∈{open,reason_required,restricted}`, `projector_status∈{wired,registered,none}`, context-shape check): `object_type='__probe_b33__', kind='supporting', scope='platform', privacy='open', projector_status='wired'`, zero-context default. No CASE dispatch exists for it. **Actual result:**

```
rows-in-transaction = 18   (17 + 1 synthetic)
get_object_workspace('__probe_b33__', …) → dispatch_missing
terminal RAISE → rollback
post-rollback registry total = 17
probe residue = 0
```

Real `subscription` / `support_case` / `privacy_request` rows untouched. Registry constraints admit the synthetic row — **no constraint blocker.**

## 13. VERIFY-THE-VERIFY RESULTS (exact v2 expressions, live)

- **ACL aggregation** (BLOCK-3 E/F expression) — run live: projector-family = `authenticated:EXECUTE,postgres:EXECUTE,service_role:EXECUTE`; core = `postgres:EXECUTE,service_role:EXECUTE`. ✅
- **Membership aggregation** (BLOCK-3 M/N/O expression, deterministic in-aggregate `ORDER BY object_type`) — run live against PRE state:
  - wired = `capsule,child,class,media,person,school,session` ✅ (matches PRE expected)
  - registered = `privacy_request,program,subscription,support_case` ✅
  - none = `badges,child_journey,family_memory,journal,raw_media,skills` ✅
  - total = 17 ✅
  The membership-logic verify-the-verify uses PRE expected sets, proving the assertion query is sound before it is retargeted to POST expected sets in the migration.

## 14. PREDICTED INVENTORY DELTA

```
BEFORE : 90 / 240 / 229 / 166 / 33 / 1
AFTER  : 90 / 241 / 230 / 166 / 33 / 1
         (+1 function, +1 security-definer = admin_lookup_program)
registry: wired 7→8 · registered 4→3 · none 6→6 · total 17
```
Asserted by BLOCK-3 P (inventory) and M/N/O/L (registry).

## 15. RISKS / UNKNOWNS

- **Plan-cache / OID:** `CREATE OR REPLACE` keeps core OID stable; wrappers reference core by OID and pick up the new body. Verified in-harness (POST calls used the program branch). Low risk.
- **`proconfig` literal (assertion D):** compared as `ARRAY['search_path=""']`. Confirmed live-format `["search_path=\"\""]`. Low risk.
- **ACL default-grant reset (D231):** BLOCK 2 explicitly `REVOKE … FROM authenticated` on core because `ALTER DEFAULT PRIVILEGES` re-grants on replace; without it, assertion F would (correctly) fail-closed. Handled.
- **Apply-time gap:** evidence is a point-in-time re-pin. If any object is wired/registered between now and apply, BLOCK-3 M/N/O/L will fail-closed and roll back — safe by design. CTO/Owner should apply promptly after audit.
- **No unknowns block issuance.**

## 16. ZERO-DELTA SURFACES (unchanged by this migration)

tables · policies · triggers · cron · roles · permission model · context validator · scope vocabulary · DTO version · discovery semantics · forbidden semantics · all non-PROGRAM registry metadata · PROGRAM discovery_fields/scope/privacy_policy/capability_vocab/context_requirements/forbidden_groups · subscription · support_case · privacy_request · entitlements · frontend · Edge Functions · Bunny · curriculum content.

## 17. LITERAL EXECUTABILITY AUDIT + FINAL PACKAGE-AUTHOR VERDICT

Every SQL artifact in §7 was checked as copy-paste-into-Postgres:
- Projector body — compiled & ran (harness + probe). ✅
- Core body (with program branch) — compiled & ran (harness). ✅
- BLOCK-2 ACL grants — pattern matches live known-good posture; deterministic verifier confirms target ACL strings. ✅
- BLOCK-3 verifier — deterministic ACL + exact-membership + inventory expressions all executed live this session against real state and returned the asserted literals. ✅
- No nested-function placeholder (BLOCKER 1 removed); only inline `jsonb_build_object` / `jsonb_object_keys` / deterministic aggregation. ✅
- Zero placeholder · zero pseudocode · zero illustrative-only code · zero known compile errors.

All four BLOCKERs corrected; CTO advisory (synthetic probe) implemented.

# PACKAGE v2 READY FOR CTO FINAL IMPLEMENTATION AUDIT

**HARD STOP.** No migration applied. No APPLY authorization assumed. No D356 canonicalization. No B3.3 HANDOFF. No B3.4. Owner APPLY authorization remains a separate one-shot gate after independent CTO review.
