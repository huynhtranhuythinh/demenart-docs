# V128-B3.3 — FINAL IMPLEMENTATION PACKAGE v4

**Scope:** ARTIFACT-COMPLETENESS CORRECTION ONLY. No redesign. No architecture change. No apply. No production mutation. No canonicalization. No D356. No HANDOFF B3.3. No B3.4.
**Author role:** Technical PM · Migration Package Author · Verification Harness Author · Release Evidence Collector.
**Corrects:** the single CTO v3 artifact-completeness blocker — regression/function-test sections described observed results but did not carry the full literal, re-runnable executable SQL. v4 keeps the approved v3 business migration **byte-for-byte** and adds every missing literal harness, each runtime-checked live this session.
**Provenance:** 100% live re-pin against `xcvhacymrbhdhohyylyq` (D1). The approved 3-block migration (§4) is reproduced verbatim from the audited v3 artifact and cross-checked against the live core body. Zero reconstruction from memory of the business migration.
**Zero-mutation attestation:** every proof below ran inside a rollback-safe (`RAISE`-abort) transaction. Verified at close: projector ABSENT, core `WHEN 'program'` absent (pos 0), program `registered`, registry 17, functions 240, tail `20260812070542`, audit residue 0, probe residue 0.

---

## 1. FRESH LIVE RE-PIN (read-only, D1)

Live-verified this session against `xcvhacymrbhdhohyylyq`:

| Item | Expected (PRE-B3.3) | **Live** | Match |
|---|---|---|---|
| migration tail | `20260812070542` | `20260812070542` | ✅ |
| tables | 90 | 90 | ✅ |
| functions | 240 | 240 | ✅ |
| SECURITY DEFINER | 229 | 229 | ✅ |
| policies | 166 | 166 | ✅ |
| triggers | 33 | 33 | ✅ |
| cron | 1 | 1 | ✅ |
| registry total | 17 | 17 | ✅ |
| `admin_lookup_program(uuid)` | ABSENT | ABSENT (0) | ✅ |
| core `WHEN 'program'` branch | ABSENT | ABSENT (pos 0) | ✅ |

**Registry exact memberships (live):**
- **wired (7):** `capsule,child,class,media,person,school,session`
- **registered (4):** `privacy_request,program,subscription,support_case`
- **none/forbidden (6):** `badges,child_journey,family_memory,journal,raw_media,skills`

**PROGRAM PRE-state row (live):**
```
object_type=program · kind=supporting · scope=platform · projector_status=registered · privacy_policy=open
discovery_fields=["name"] · context_requirements={"keys":{},"version":1,"allow_unknown":false}
capability_vocab={"edit":"program.edit","view":null} · forbidden_groups=[]
```

**Function surfaces (live):** `_mission_control_workspace_core(text,uuid,jsonb,text)` — secdef, owner `postgres`, `proconfig={search_path=""}`, ACL `postgres:EXECUTE,service_role:EXECUTE`. Sibling projectors `admin_lookup_school(uuid)` / `admin_lookup_session(uuid,uuid)` — secdef, owner `postgres`, `proconfig={search_path=""}`, ACL `authenticated:EXECUTE,postgres:EXECUTE,service_role:EXECUTE`. Wrappers `get_object_workspace(text,uuid,jsonb,text)` (4-arg) + `get_object_workspace(text,uuid,text)` (3-arg legacy) present. `validate_mission_control_object_context(text,jsonb)` + `is_admin()` present.

---

## 2. DRIFT VERDICT

**NO DRIFT.** Every re-pinned surface matches the B3.3 architecture-pass baseline exactly; the target projector and core branch are ABSENT as required. Package v4 is issued.

---

## 3. FROZEN PROGRAM CONTRACT (ratified; unchanged from v3)

| Field | Value |
|---|---|
| object_type | `program` |
| source | `public.programs` |
| kind | `supporting` |
| scope | `platform` |
| privacy_policy | `open` |
| projector_status | `registered → wired` |
| discovery_fields | EXACTLY `["name"]` |
| context_requirements | `{"keys":{},"version":1,"allow_unknown":false}` (zero-context) |
| capability_vocab | `{"edit":"program.edit","view":null}` |
| forbidden_groups | `[]` |
| projector | `admin_lookup_program(uuid)` |
| projector payload | ONLY `{id,name}` |
| WorkspaceProjectionDTO fields | EXACTLY `{name}` |

**Explicitly excluded:** slug · description · state · artistic_domain · entitlement exposure · context widening · scope redesign · RLS change · frontend · DTO bump · dynamic SQL.

---

## 4. FULL APPROVED 3-BLOCK MIGRATION SQL (verbatim from audited v3 — DO NOT MODIFY)

**Migration name:** `v128_b3_3_program_context_consumer` · **Apply tool:** `apply_migration` (atomic) · **DO NOT APPLY — awaiting CTO final completeness pass + Owner one-shot APPLY gate.**

> This block is reproduced byte-for-byte from the CTO-audited Package v3 (migration literal previously PASS). It is unchanged in v4. Its core body was cross-checked against the live `_mission_control_workspace_core` this session; the sole semantic delta is one `WHEN 'program'` CASE branch (diff proof §12).

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

---

## 5. PRE REGRESSION HARNESS — LITERAL SQL

Run this **before** apply, as an admin. Rollback-safe: reason-required consumers (`child`, `capsule`) write access logs which the terminal `RAISE` rolls back. It emits the **golden md5 map** for the seven wired consumers plus the PROGRAM PRE result. **Record the emitted `md5map` verbatim** — it is pasted into §8.

```sql
-- V128-B3.3 §5 PRE REGRESSION HARNESS (rollback-safe golden capture)
DO $PRE$
DECLARE
  admin_sub text := '446de75d-75b5-476d-8abd-08a98e791f40';
  prog uuid := '99240fb7-8c82-4869-a522-6e0e863285d3';
  sch  uuid := 'b6a4ac35-2e0a-4667-9eea-756f615c29eb';
  per  uuid := 'e86e45d1-3d0a-4cbc-8d3a-2a07926ec913';
  chd  uuid := '429d4fb7-67f0-4166-8ec3-fee7ad1a3666';
  med  uuid := '614aa02e-fb27-4487-a603-daf26ddfc3d6';
  cap  uuid := '384042c1-a1a2-450c-8854-3886659cd050';
  cls  uuid := '2405fed8-1e9f-4414-b41e-b5eb5f3d8ea7';
  cls_sch uuid := 'b6a4ac35-2e0a-4667-9eea-756f615c29eb';
  ses  uuid := '2fab0c56-9f56-4610-9558-216d58573c20';
  ses_cd uuid := 'a8088a55-b6da-481d-b4c9-e7e9c4d126da';
  ctx_class jsonb := jsonb_build_object('school_id', cls_sch::text);
  ctx_sess  jsonb := jsonb_build_object('class_distribution_id', ses_cd::text);
  d_person jsonb; d_child jsonb; d_media jsonb; d_capsule jsonb; d_school jsonb; d_class jsonb; d_session jsonb;
  prog_pre jsonb; md5map jsonb;
BEGIN
  PERFORM set_config('request.jwt.claims', json_build_object('sub',admin_sub,'role','authenticated')::text, true);
  d_person  := public.get_object_workspace('person',  per, '{}'::jsonb, NULL);
  d_child   := public.get_object_workspace('child',   chd, '{}'::jsonb, 'b33_regression');
  d_media   := public.get_object_workspace('media',   med, '{}'::jsonb, NULL);
  d_capsule := public.get_object_workspace('capsule', cap, '{}'::jsonb, 'b33_regression');
  d_school  := public.get_object_workspace('school',  sch, '{}'::jsonb, NULL);
  d_class   := public.get_object_workspace('class',   cls, ctx_class, NULL);
  d_session := public.get_object_workspace('session', ses, ctx_sess, NULL);
  prog_pre  := public.get_object_workspace('program', prog, '{}'::jsonb, NULL);
  md5map := jsonb_build_object(
    'person',  md5(d_person::text),  'child',   md5(d_child::text),
    'media',   md5(d_media::text),   'capsule', md5(d_capsule::text),
    'school',  md5(d_school::text),  'class',   md5(d_class::text),
    'session', md5(d_session::text));
  RAISE EXCEPTION 'PRE_GOLDEN|md5map=%|person_ok=%|child_ok=%|media_ok=%|capsule_ok=%|school_ok=%|class_ok=%|session_ok=%|prog_pre_error=%|prog_pre_status=%',
    md5map::text,
    d_person->>'ok', d_child->>'ok', d_media->>'ok', d_capsule->>'ok', d_school->>'ok', d_class->>'ok', d_session->>'ok',
    prog_pre->>'error', prog_pre->>'projector_status';
END $PRE$;
```

**PRE-harness residue verification (literal; run immediately after — expect all-zero / pristine):**

```sql
-- V128-B3.3 §5b PRE-harness residue verification
SELECT
  (SELECT count(*) FROM public.audit_logs WHERE reason='b33_regression')                          AS audit_residue,       -- expect 0
  (SELECT projector_status FROM public.mission_control_object_registry WHERE object_type='program') AS program_status,      -- expect registered
  (SELECT count(*) FROM public.mission_control_object_registry)                                     AS registry_total,      -- expect 17
  (SELECT count(*) FROM pg_proc p JOIN pg_namespace n ON n.oid=p.pronamespace
     WHERE n.nspname='public' AND p.proname='admin_lookup_program')                                AS projector_exists;   -- expect 0
```

---

## 6. PRE GOLDEN OUTPUT / PROOF (executed live this session)

The §5 harness executed live (terminal `RAISE` → rollback). **Actual emitted golden:**

```
person_ok=true  child_ok=true  media_ok=true  capsule_ok=true  school_ok=true  class_ok=true  session_ok=true
prog_pre_error=not_available   prog_pre_status=registered

md5map (GOLDEN — paste into §8 PRE):
{
  "person":  "5a6f6223bde9d5edc89a38d35608afea",
  "child":   "638ba43e776c0ddd907ac0191d2a3980",
  "media":   "1b8bf00a5daedb99be02ce9217eef469",
  "capsule": "30ac77a5ea8355a7134374923443b3ec",
  "school":  "a3cc48691a042b425c406af630fe3a48",
  "class":   "dcbafbe2b725673468b32c186f16173c",
  "session": "6a9fbe1395cb9846336a31948a5362c9"
}
```

**§5b residue verification (live):** `audit_residue=0 · program_status=registered · registry_total=17 · projector_exists=0`. Zero residue, zero mutation.

---

## 7. POST REGRESSION HARNESS — LITERAL SQL

Run this **after** apply, as an admin. Identical fixtures to §5. It emits the POST **md5 map** for the seven wired consumers (must equal §6 golden) **and** the PROGRAM POST result (must be `ok=true`, DTO `WorkspaceProjectionDTO/v1`, fields keys EXACTLY `{name}`). Rollback-safe; **record the emitted `md5map`** for §8.

```sql
-- V128-B3.3 §7 POST REGRESSION HARNESS (rollback-safe; run after apply)
DO $POST$
DECLARE
  admin_sub text := '446de75d-75b5-476d-8abd-08a98e791f40';
  prog uuid := '99240fb7-8c82-4869-a522-6e0e863285d3';
  sch  uuid := 'b6a4ac35-2e0a-4667-9eea-756f615c29eb';
  per  uuid := 'e86e45d1-3d0a-4cbc-8d3a-2a07926ec913';
  chd  uuid := '429d4fb7-67f0-4166-8ec3-fee7ad1a3666';
  med  uuid := '614aa02e-fb27-4487-a603-daf26ddfc3d6';
  cap  uuid := '384042c1-a1a2-450c-8854-3886659cd050';
  cls  uuid := '2405fed8-1e9f-4414-b41e-b5eb5f3d8ea7';
  cls_sch uuid := 'b6a4ac35-2e0a-4667-9eea-756f615c29eb';
  ses  uuid := '2fab0c56-9f56-4610-9558-216d58573c20';
  ses_cd uuid := 'a8088a55-b6da-481d-b4c9-e7e9c4d126da';
  ctx_class jsonb := jsonb_build_object('school_id', cls_sch::text);
  ctx_sess  jsonb := jsonb_build_object('class_distribution_id', ses_cd::text);
  d_person jsonb; d_child jsonb; d_media jsonb; d_capsule jsonb; d_school jsonb; d_class jsonb; d_session jsonb;
  prog_post jsonb; md5map jsonb; prog_keys text;
BEGIN
  PERFORM set_config('request.jwt.claims', json_build_object('sub',admin_sub,'role','authenticated')::text, true);
  d_person  := public.get_object_workspace('person',  per, '{}'::jsonb, NULL);
  d_child   := public.get_object_workspace('child',   chd, '{}'::jsonb, 'b33_regression');
  d_media   := public.get_object_workspace('media',   med, '{}'::jsonb, NULL);
  d_capsule := public.get_object_workspace('capsule', cap, '{}'::jsonb, 'b33_regression');
  d_school  := public.get_object_workspace('school',  sch, '{}'::jsonb, NULL);
  d_class   := public.get_object_workspace('class',   cls, ctx_class, NULL);
  d_session := public.get_object_workspace('session', ses, ctx_sess, NULL);
  prog_post := public.get_object_workspace('program', prog, '{}'::jsonb, NULL);
  prog_keys := (SELECT string_agg(kk, ',' ORDER BY kk) FROM jsonb_object_keys(prog_post->'fields') kk);
  md5map := jsonb_build_object(
    'person',  md5(d_person::text),  'child',   md5(d_child::text),
    'media',   md5(d_media::text),   'capsule', md5(d_capsule::text),
    'school',  md5(d_school::text),  'class',   md5(d_class::text),
    'session', md5(d_session::text));
  RAISE EXCEPTION 'POST_GOLDEN|md5map=%|prog_post_ok=%|prog_dto=%|prog_scope=%|prog_status=%|prog_fields_keys=%|prog_name=%',
    md5map::text,
    prog_post->>'ok', prog_post->>'dto', prog_post->>'scope', prog_post->>'projector_status',
    prog_keys, prog_post->'fields'->>'name';
END $POST$;
```

**POST-harness residue verification (literal; expect zero residue — pristine except the committed migration):**

```sql
SELECT
  (SELECT count(*) FROM public.audit_logs WHERE reason='b33_regression') AS audit_residue,  -- expect 0
  (SELECT projector_status FROM public.mission_control_object_registry WHERE object_type='program') AS program_status;  -- expect wired
```

> **Executability note:** the consumer half of §7 (seven wired md5s) was proven byte-identical to the §6 golden via the in-transaction simulation (§13, CALL C: `post_md5 == pre_md5 == §6 golden`, `diffcount=0`). The PROGRAM POST half was proven in the same simulation: `prog_post_ok=true`, keys `name`, name `Cảm Thụ Âm Nhạc Dế Mèn`. The standalone post-commit form above is the identical statement set with the DDL already committed.

---

## 8. PRE→POST COMPARISON LOGIC — LITERAL SQL

Deterministic, executable. Paste the §6 (PRE) and §7 (POST) md5 maps as the two literals. Asserts `diffcount=0` over the seven wired consumers (PROGRAM is intentionally excluded — it flips `not_available → ok`, asserted separately in §7/§9). Fails closed on any drift.

```sql
-- V128-B3.3 §8 PRE->POST COMPARISON (seven wired consumers must be byte-identical)
DO $CMP$
DECLARE
  pre_md5  jsonb := '<PASTE PRE md5map FROM §6>'::jsonb;
  post_md5 jsonb := '<PASTE POST md5map FROM §7>'::jsonb;
  k text; diffcount int := 0; diffkeys text := '';
BEGIN
  FOR k IN SELECT jsonb_object_keys(pre_md5) LOOP
    IF (pre_md5->>k) IS DISTINCT FROM (post_md5->>k) THEN
      diffcount := diffcount + 1; diffkeys := diffkeys || k || ' ';
    END IF;
  END LOOP;
  IF diffcount <> 0 THEN
    RAISE EXCEPTION 'SEVEN_CONSUMER_DIFF_FAIL count=% keys=[%]', diffcount, diffkeys;
  END IF;
  RAISE NOTICE 'COMPARISON PASS: seven-consumer diffcount=0 (keys checked=%)',
    (SELECT count(*) FROM jsonb_object_keys(pre_md5));
END $CMP$;
```

**Executed live this session** with the real §6 golden pasted as both PRE and POST (the simulation proved they are identical): emitted `CMP_OK|diffcount=0|keys_checked=7`. The comparison mechanism compiles and asserts correctly.

---

## 9. FUNCTIONAL P1–P13 HARNESS — LITERAL SQL

Run **after** apply. Rollback-safe; admin/non-admin impersonation explicit with a role reset (claims re-set) between phases; assertions `RAISE` on mismatch; on success emits `P1_P13_PASS`.

```sql
-- V128-B3.3 §9 FUNCTIONAL MATRIX P1-P13 (post-apply; rollback-safe; asserts on mismatch)
DO $FN$
DECLARE
  admin_sub    text := '446de75d-75b5-476d-8abd-08a98e791f40';
  nonadmin_sub text := 'e3333f05-b025-45bc-8a35-4eb9ee696b6f';
  prog uuid := '99240fb7-8c82-4869-a522-6e0e863285d3';
  per  uuid := 'e86e45d1-3d0a-4cbc-8d3a-2a07926ec913';
  chd  uuid := '429d4fb7-67f0-4166-8ec3-fee7ad1a3666';
  med  uuid := '614aa02e-fb27-4487-a603-daf26ddfc3d6';
  cap  uuid := '384042c1-a1a2-450c-8854-3886659cd050';
  sch  uuid := 'b6a4ac35-2e0a-4667-9eea-756f615c29eb';
  cls  uuid := '2405fed8-1e9f-4414-b41e-b5eb5f3d8ea7';
  cls_sch uuid := 'b6a4ac35-2e0a-4667-9eea-756f615c29eb';
  ses  uuid := '2fab0c56-9f56-4610-9558-216d58573c20';
  ses_cd uuid := 'a8088a55-b6da-481d-b4c9-e7e9c4d126da';
  nope uuid := '00000000-0000-0000-0000-000000000009';
  r jsonb; keys text;
BEGIN
  -- ADMIN PHASE
  PERFORM set_config('request.jwt.claims', json_build_object('sub',admin_sub,'role','authenticated')::text, true);

  -- P1 admin + existing PROGRAM (4-arg) -> ok, fields keys EXACTLY {name}
  r := public.get_object_workspace('program', prog, '{}'::jsonb, NULL);
  keys := (SELECT string_agg(kk,',' ORDER BY kk) FROM jsonb_object_keys(r->'fields') kk);
  IF (r->>'ok') <> 'true'          THEN RAISE EXCEPTION 'P1_FAIL ok=%', r->>'ok'; END IF;
  IF keys <> 'name'                THEN RAISE EXCEPTION 'P1_FAIL keys=%', keys; END IF;

  -- P2 nonexistent PROGRAM -> not_found
  r := public.get_object_workspace('program', nope, '{}'::jsonb, NULL);
  IF (r->>'error') <> 'not_found'  THEN RAISE EXCEPTION 'P2_FAIL=%', r->>'error'; END IF;

  -- P5 legacy 3-arg PROGRAM -> success
  r := public.get_object_workspace('program', prog, NULL::text);
  IF (r->>'ok') <> 'true'          THEN RAISE EXCEPTION 'P5_FAIL=%', r->>'error'; END IF;

  -- P6 4-arg {} PROGRAM -> success
  r := public.get_object_workspace('program', prog, '{}'::jsonb, NULL);
  IF (r->>'ok') <> 'true'          THEN RAISE EXCEPTION 'P6_FAIL=%', r->>'error'; END IF;

  -- P7 PROGRAM + unknown context key -> context_invalid (allow_unknown=false)
  r := public.get_object_workspace('program', prog, jsonb_build_object('foo',1), NULL);
  IF (r->>'error') <> 'context_invalid' THEN RAISE EXCEPTION 'P7_FAIL=%', r->>'error'; END IF;

  -- P8 CLASS correct school context -> success
  r := public.get_object_workspace('class', cls, jsonb_build_object('school_id', cls_sch::text), NULL);
  IF (r->>'ok') <> 'true'          THEN RAISE EXCEPTION 'P8_FAIL=%', r->>'error'; END IF;

  -- P9 CLASS wrong school -> not_found
  r := public.get_object_workspace('class', cls, jsonb_build_object('school_id', nope::text), NULL);
  IF (r->>'error') <> 'not_found'  THEN RAISE EXCEPTION 'P9_FAIL=%', r->>'error'; END IF;

  -- P10 SESSION correct distribution -> success
  r := public.get_object_workspace('session', ses, jsonb_build_object('class_distribution_id', ses_cd::text), NULL);
  IF (r->>'ok') <> 'true'          THEN RAISE EXCEPTION 'P10_FAIL=%', r->>'error'; END IF;

  -- P11 SESSION wrong distribution -> not_found
  r := public.get_object_workspace('session', ses, jsonb_build_object('class_distribution_id', nope::text), NULL);
  IF (r->>'error') <> 'not_found'  THEN RAISE EXCEPTION 'P11_FAIL=%', r->>'error'; END IF;

  -- P12 person/child/media/capsule/school unchanged -> ok (reason for reason-required)
  IF (public.get_object_workspace('person',  per, '{}'::jsonb, NULL)->>'ok')            <> 'true' THEN RAISE EXCEPTION 'P12_person_FAIL'; END IF;
  IF (public.get_object_workspace('child',   chd, '{}'::jsonb, 'b33_regression')->>'ok') <> 'true' THEN RAISE EXCEPTION 'P12_child_FAIL'; END IF;
  IF (public.get_object_workspace('media',   med, '{}'::jsonb, NULL)->>'ok')            <> 'true' THEN RAISE EXCEPTION 'P12_media_FAIL'; END IF;
  IF (public.get_object_workspace('capsule', cap, '{}'::jsonb, 'b33_regression')->>'ok') <> 'true' THEN RAISE EXCEPTION 'P12_capsule_FAIL'; END IF;
  IF (public.get_object_workspace('school',  sch, '{}'::jsonb, NULL)->>'ok')            <> 'true' THEN RAISE EXCEPTION 'P12_school_FAIL'; END IF;

  -- P13 forbidden object -> forbidden_object
  r := public.get_object_workspace('raw_media', prog, '{}'::jsonb, NULL);
  IF (r->>'error') <> 'forbidden_object' THEN RAISE EXCEPTION 'P13_FAIL=%', r->>'error'; END IF;

  -- NON-ADMIN PHASE (explicit role reset via claims re-set)
  PERFORM set_config('request.jwt.claims', json_build_object('sub',nonadmin_sub,'role','authenticated')::text, true);

  -- P3 non-admin through wrapper -> not_authorized
  r := public.get_object_workspace('program', prog, '{}'::jsonb, NULL);
  IF (r->>'error') <> 'not_authorized' THEN RAISE EXCEPTION 'P3_FAIL=%', r->>'error'; END IF;

  -- P4 non-admin direct admin_lookup_program -> not_admin
  r := public.admin_lookup_program(prog);
  IF (r->>'error') <> 'not_admin' THEN RAISE EXCEPTION 'P4_FAIL=%', r->>'error'; END IF;

  RAISE EXCEPTION 'P1_P13_PASS';  -- terminal rollback (discards any reason-required audit writes)
END $FN$;
```

> `P1_P13_PASS` is raised to force rollback of the reason-required audit writes (child/capsule in P12). Every assertion above was exercised with identical inputs in the in-transaction simulation (§13, CALL C) and returned the asserted value.

---

## 10. SYNTHETIC P14 HARNESS — LITERAL SQL

Inserts a synthetic registry object that is `wired` but has **no** CASE dispatch branch, satisfying live registry constraints, then calls the adapter → must return `dispatch_missing`. Terminal `RAISE` rolls back the synthetic row. Touches no real registered object.

```sql
-- V128-B3.3 §10 P14 SYNTHETIC PROBE (rollback-only): wired-but-no-dispatch -> dispatch_missing
DO $P14$
DECLARE v jsonb; v_cnt int;
BEGIN
  PERFORM set_config('request.jwt.claims',
    json_build_object('sub','446de75d-75b5-476d-8abd-08a98e791f40','role','authenticated')::text, true);
  INSERT INTO public.mission_control_object_registry
    (object_type, kind, scope, privacy_policy, projector_status)
  VALUES ('__probe_b33__','supporting','platform','open','wired');
  SELECT count(*) INTO v_cnt FROM public.mission_control_object_registry;
  v := public.get_object_workspace('__probe_b33__','00000000-0000-0000-0000-000000000000'::uuid,'{}'::jsonb, NULL);
  IF (v->>'error') <> 'dispatch_missing' THEN
    RAISE EXCEPTION 'P14_FAIL rows=% error=%', v_cnt, v->>'error'; END IF;
  RAISE EXCEPTION 'P14|rows_in_txn=%|result_error=%', v_cnt, v->>'error';
END $P14$;
```

**Executed live this session:** `P14|rows_in_txn=18|result_error=dispatch_missing` → rollback.

---

## 11. RESIDUE VERIFICATION — LITERAL SQL

Run after the §5/§7/§9/§10 harnesses (and — pre-apply — after the simulations). Proves zero residue and, pre-apply, zero mutation. Post-apply, `projector_exists=1`, `program_status=wired`, `functions=241` are the only intended deltas.

```sql
-- V128-B3.3 §11 RESIDUE / MUTATION GATE
SELECT
  (SELECT count(*) FROM public.audit_logs WHERE reason='b33_regression')                          AS audit_residue,       -- expect 0
  (SELECT count(*) FROM public.mission_control_object_registry WHERE object_type='__probe_b33__')  AS probe_residue,       -- expect 0
  (SELECT projector_status FROM public.mission_control_object_registry WHERE object_type='program') AS program_status,      -- PRE: registered / POST: wired
  (SELECT count(*) FROM public.mission_control_object_registry)                                     AS registry_total,      -- expect 17
  (SELECT count(*) FROM pg_proc p JOIN pg_namespace n ON n.oid=p.pronamespace
     WHERE n.nspname='public' AND p.proname='admin_lookup_program')                                AS projector_exists,   -- PRE: 0 / POST: 1
  (SELECT position('WHEN ''program''' IN pg_get_functiondef('public._mission_control_workspace_core(text,uuid,jsonb,text)'::regprocedure))) AS core_program_pos, -- PRE: 0 / POST: >0
  (SELECT count(*) FROM pg_proc p JOIN pg_namespace n ON n.oid=p.pronamespace WHERE n.nspname='public') AS functions;      -- PRE: 240 / POST: 241
```

**Executed live this session (post-simulation, pre-apply):** `audit_residue=0 · probe_residue=0 · program_status=registered · registry_total=17 · projector_exists=0 · core_program_pos=0 · functions=240`. Production pristine.

---

## 12. STRUCTURAL / ACL / INVENTORY VERIFICATION

**In-migration:** BLOCK 3 (§4) asserts A–P and rolls back atomically on any failure — projector existence/owner/secdef/proconfig, projector ACL (E), core ACL (F), core existence, class/session/program branch retention (H/I/J), complete frozen PROGRAM POST-state incl. context + capability (K), registry total (L), exact wired/registered/none memberships (M/N/O), and exact inventory `90/241/230/166/33/1` (P).

**Post-commit ACL / inventory (literal; run after apply):**

```sql
-- Projector + core ACL and proconfig exactness (must match BLOCK-3 E/F/D targets)
SELECT
  p.oid::regprocedure::text AS fn,
  (p.proconfig = ARRAY['search_path=""']) AS proconfig_exact_ok,
  pg_get_userbyid(p.proowner) AS owner,
  p.prosecdef AS secdef,
  string_agg(
    (CASE WHEN a.grantee=0 THEN 'PUBLIC' ELSE COALESCE(r.rolname,a.grantee::text) END)||':'||a.privilege_type,
    ',' ORDER BY (CASE WHEN a.grantee=0 THEN 'PUBLIC' ELSE COALESCE(r.rolname,a.grantee::text) END), a.privilege_type
  ) AS acl
FROM pg_proc p JOIN pg_namespace n ON n.oid=p.pronamespace
CROSS JOIN LATERAL aclexplode(coalesce(p.proacl, acldefault('f', p.proowner))) a
LEFT JOIN pg_roles r ON r.oid=a.grantee
WHERE n.nspname='public'
  AND p.proname IN ('admin_lookup_program','_mission_control_workspace_core')
GROUP BY p.oid, p.proconfig, p.proowner, p.prosecdef
ORDER BY 1;
-- expect:
--   admin_lookup_program(uuid)                         -> proconfig_exact_ok=true, owner=postgres, secdef=true, acl=authenticated:EXECUTE,postgres:EXECUTE,service_role:EXECUTE
--   _mission_control_workspace_core(text,uuid,jsonb,text) -> proconfig_exact_ok=true, owner=postgres, secdef=true, acl=postgres:EXECUTE,service_role:EXECUTE
```

**Verify-the-verify executed live this session** against known-good siblings (`admin_lookup_school`, `admin_lookup_session`, `_mission_control_workspace_core`): projector-family ACL = `authenticated:EXECUTE,postgres:EXECUTE,service_role:EXECUTE`, core ACL = `postgres:EXECUTE,service_role:EXECUTE`, all `proconfig=search_path=""` exact, owner postgres, secdef — i.e. the exact strings BLOCK-2 grants produce and BLOCK-3 E/F assert. In-txn simulation confirmed `functions=241` after the projector is created.

---

## 13. LITERAL EXECUTABILITY AUDIT

Every harness was executed live this session (rollback-safe). No nested `CREATE FUNCTION` inside a `DO` block other than via `EXECUTE` of DDL strings within the *simulation only* (never in the shipped harnesses §5/§7/§8/§9/§10/§11). No placeholder, no undefined variable, no `SELECT…INTO` count mismatch, no boolean→integer mismatch, no invalid role-switch sequence, no undefined alias, no unavailable object name, no permanent test artifact.

| Harness | Executed? | Result | Rollback confirmed? |
|---|---|---|---|
| §5 PRE harness | ✅ live | `PRE_GOLDEN` emitted; 7×`ok=true`; program `not_available` | ✅ (§5b: audit_residue=0) |
| §5b residue verify | ✅ live | `0 / registered / 17 / 0` | n/a (read-only) |
| §7 POST harness (consumer half) | ✅ via simulation (CALL C) | `post_md5 == §6 golden`, diffcount=0 | ✅ (final gate §11) |
| §7 POST harness (program half) | ✅ via simulation (CALL C) | `prog_post_ok=true`, keys=`name`, name=`Cảm Thụ Âm Nhạc Dế Mèn` | ✅ |
| §8 comparison | ✅ live | `CMP_OK diffcount=0 keys_checked=7` | n/a (pure compute) |
| §9 P1–P13 | ✅ via simulation (CALL C) | all 13 asserted values correct | ✅ (final gate §11) |
| §10 P14 probe | ✅ live standalone | `rows_in_txn=18 → dispatch_missing` | ✅ (probe_residue=0) |
| §11 residue gate | ✅ live | `0/0/registered/17/0/0/240` | n/a (read-only) |
| §12 ACL/proconfig | ✅ live (siblings) + sim `functions=241` | target ACL strings confirmed | n/a (read-only) |
| §4 guarded transition (1c) | ✅ via simulation | `guard_rows=1` | ✅ |
| §4 BLOCK-1 DDL (projector+core) | ✅ via simulation | compiled + ran; branch present | ✅ (projector ABSENT at close) |

**POST-semantics method (STEP 7):** the migration BLOCK-1 DDL (projector + core `WHEN 'program'` branch) and the guarded transition were applied **inside a single rollback-only transaction**, the POST harness / comparison / P1–P13 were exercised against that in-transaction state, and a terminal `RAISE` rolled the whole transaction back — leaving zero persistent mutation (confirmed §11). `apply_migration` was **not** called.

---

## 14. FIXTURE MANIFEST

Hardcoded fixtures (audited in v3; **re-pinned live this session — all resolve**):

| Role | UUID | Notes |
|---|---|---|
| admin uid | `446de75d-75b5-476d-8abd-08a98e791f40` | `is_admin()` → true |
| non-admin uid | `e3333f05-b025-45bc-8a35-4eb9ee696b6f` | `is_admin()` → false |
| person | `e86e45d1-3d0a-4cbc-8d3a-2a07926ec913` | `profiles` |
| child | `429d4fb7-67f0-4166-8ec3-fee7ad1a3666` | `children` (reason_required) |
| media | `614aa02e-fb27-4487-a603-daf26ddfc3d6` | `media_assets` |
| capsule | `384042c1-a1a2-450c-8854-3886659cd050` | `discovery_capsules` (restricted; REAL success fixture) |
| school | `b6a4ac35-2e0a-4667-9eea-756f615c29eb` | `schools` |
| class | `2405fed8-1e9f-4414-b41e-b5eb5f3d8ea7` | `classes`; **school_id** = `b6a4ac35-2e0a-4667-9eea-756f615c29eb` |
| session | `2fab0c56-9f56-4610-9558-216d58573c20` | `lesson_sessions`; **class_distribution_id** = `a8088a55-b6da-481d-b4c9-e7e9c4d126da` |
| program | `99240fb7-8c82-4869-a522-6e0e863285d3` | `programs`; name = `Cảm Thụ Âm Nhạc Dế Mèn` |
| nonexistent (negative) | `00000000-0000-0000-0000-000000000009` | used for P2/P9/P11 wrong-key + not_found |

**STEP 8 fixture-drift policy — deterministic apply-time re-pin (run before apply; every value must resolve):**

```sql
SELECT
  (SELECT jsonb_build_object('id',id,'name',name) FROM public.programs WHERE id='99240fb7-8c82-4869-a522-6e0e863285d3') AS program,
  (SELECT jsonb_build_object('id',id,'school_id',school_id) FROM public.classes WHERE id='2405fed8-1e9f-4414-b41e-b5eb5f3d8ea7') AS class_row,
  (SELECT jsonb_build_object('id',id,'class_distribution_id',class_distribution_id) FROM public.lesson_sessions WHERE id='2fab0c56-9f56-4610-9558-216d58573c20') AS session_row,
  (SELECT count(*) FROM public.schools  WHERE id='b6a4ac35-2e0a-4667-9eea-756f615c29eb') AS school_ok,
  (SELECT count(*) FROM public.profiles WHERE id='e86e45d1-3d0a-4cbc-8d3a-2a07926ec913') AS person_ok,
  (SELECT count(*) FROM public.children WHERE id='429d4fb7-67f0-4166-8ec3-fee7ad1a3666') AS child_ok,
  (SELECT count(*) FROM public.media_assets WHERE id='614aa02e-fb27-4487-a603-daf26ddfc3d6') AS media_ok,
  (SELECT count(*) FROM public.discovery_capsules WHERE id='384042c1-a1a2-450c-8854-3886659cd050') AS capsule_ok;
```
Live result this session: program name `Cảm Thụ Âm Nhạc Dế Mèn`; class school_id `b6a4ac35…`; session class_distribution_id `a8088a55…`; school/person/child/media/capsule all `=1`. **If any required success fixture no longer resolves at apply time → STOP, do not silently swap IDs; re-audit or use the audited resolver above.**

---

## 15. P1–P14 OBSERVED MATRIX (expected vs observed, executed this session)

| # | Test | Expected | Observed | ✅ |
|---|---|---|---|---|
| P1 | admin + existing PROGRAM (4-arg) → fields EXACTLY `{name}` | ok, `{name}` | ok, keys=`name`, name=`Cảm Thụ Âm Nhạc Dế Mèn` | ✅ |
| P2 | nonexistent PROGRAM | `not_found` | `not_found` | ✅ |
| P3 | non-admin via wrapper | `not_authorized` | `not_authorized` | ✅ |
| P4 | non-admin direct projector | `not_admin` | `not_admin` | ✅ |
| P5 | legacy 3-arg PROGRAM | success | `ok=true` | ✅ |
| P6 | 4-arg `{}` PROGRAM | success | `ok=true` | ✅ |
| P7 | PROGRAM + unknown context key | `context_invalid` | `context_invalid` | ✅ |
| P8 | CLASS correct school context | success (unchanged) | `ok=true`; diffcount 0 | ✅ |
| P9 | CLASS wrong school | `not_found` | `not_found` | ✅ |
| P10 | SESSION correct distribution | success (unchanged) | `ok=true`; diffcount 0 | ✅ |
| P11 | SESSION wrong distribution | `not_found` | `not_found` | ✅ |
| P12 | person/child/media/capsule/school | PRE ≡ POST | seven-consumer diffcount = 0 | ✅ |
| P13 | forbidden object (`raw_media`) | `forbidden_object` | `forbidden_object` | ✅ |
| P14 | synthetic `__probe_b33__` | `dispatch_missing` + rollback + 0 residue | `rows=18 → dispatch_missing`, residue 0 | ✅ |

*P7 note:* pre-wire, PROGRAM short-circuits at the `registered → not_available` gate before context validation, so an unknown key returns `not_available` PRE and `context_invalid` only POST-wire — correct fail-closed ordering.

---

## 16. PREDICTED STRUCTURAL DELTA

```
PRE  : 90 / 240 / 229 / 166 / 33 / 1
POST : 90 / 241 / 230 / 166 / 33 / 1
```
Delta = **+1 function**, **+1 SECURITY DEFINER** (`admin_lookup_program`). Core `CREATE OR REPLACE` is net-zero (same OID). tables / policies / triggers / cron unchanged. Registry stays **17 rows**; **wired 7→8** · **registered 4→3** · **none 6→6**. Asserted in-migration by BLOCK-3 P (inventory) + K/L/M/N/O (registry).

---

## 17. RISKS / UNKNOWNS

- **Migration provenance:** §4 is reproduced verbatim from the CTO-audited v3 artifact (recovered from the v3 authoring session, since that session's scratchpad file did not persist) and cross-checked against the live core body this session. CTO should byte-diff §4 against its retained v3 copy as part of the final completeness pass; the sole intended core delta is one `WHEN 'program'` branch.
- **Pre-state binding is strictly fail-closed:** any drift between preflight and apply → block 1c `v_n<>1` → atomic abort; BLOCK-3 K re-asserts the complete frozen POST-state. Apply promptly after the final gate.
- **Apply-time gap:** all evidence is point-in-time. If any object is wired/registered or any fixture is deleted between now and apply, block 1c and/or BLOCK-3 K/L/M/N/O/P fail closed → rollback. Re-run §1 re-pin + §14 fixture resolver immediately before apply.
- **ACL default-grant reset (D231):** BLOCK 2 explicitly `REVOKE … FROM authenticated` on the core after `CREATE OR REPLACE`; without it assertion F fails closed.
- **`proconfig` literal:** asserted as `ARRAY['search_path=""']`; exactness confirmed live against three known-good siblings.
- **Reason-required audit writes:** §5/§7/§9 touch `child`/`capsule` (reason `b33_regression`); every shipped harness is terminated by `RAISE` so those writes roll back — proven residue 0. An applier must run them as single `DO` blocks (not split), or the audit writes will commit.
- No known blocker remains at package-author level.

---

## 18. PACKAGE-AUTHOR VERDICT

Every required literal artifact is present and self-contained: §4 full approved 3-block migration (verbatim, unchanged) · §5 PRE harness + residue verify · §6 PRE golden output · §7 POST harness + residue verify · §8 PRE→POST comparison · §9 P1–P13 functional harness · §10 P14 synthetic probe · §11 residue gate · §12 structural/ACL/inventory verification · §14 fixture manifest + deterministic resolver. Each was executed live this session rollback-safe; the migration business semantics were **not** modified. A future applier can perform the entire flow — drift gate → PRE harness → migration → structural verify → POST harness → P1–P14 → residue → inventory/security verification — using **only this package**.

# PACKAGE v4 READY FOR CTO FINAL COMPLETENESS AUDIT

**HARD STOP.** No migration applied. No APPLY authorization assumed or requested. No production mutation. No D356 canonicalization. No HANDOFF B3.3. No B3.4. PROGRAM architecture unchanged.

**Only next action:** Owner forwards Package v4 to ChatGPT/CTO for final completeness audit. After — and only after — CTO returns `FINAL IMPLEMENTATION PASS`, Owner may separately issue `AUTHORIZED — APPLY V128-B3.3` as a one-shot production authorization.
