# V128-B3.3 — FINAL IMPLEMENTATION PACKAGE v5

**Scope:** ARTIFACT-COMPLETENESS CORRECTION ONLY. No redesign. No architecture change. No apply. No production mutation. No canonicalization. No D356. No HANDOFF B3.3. No B3.4.
**Author role:** Technical PM · Migration Package Author · Verification Harness Author · Release Evidence Collector.
**Corrects (single v4 blocker):** the PRE→POST comparison in v4 §8 carried two executable placeholders (`<PASTE PRE md5map …>` / `<PASTE POST md5map …>`), so the exact post-apply comparison artifact was not self-contained. v5 removes the standalone paste-comparison entirely and folds the comparison into the harnesses: the **PRE harness self-asserts** the live signatures against a **hardcoded frozen golden**, and the **POST harness auto-compares** the live POST signatures against the **same hardcoded frozen golden** inline. There is **zero executable placeholder** anywhere in this package.
**Unchanged from v4:** the approved 3-block business migration (§4) is retained **byte-for-byte**. Projector body, core PROGRAM branch, registry transition, updated_at bookkeeping, ACL grants/revokes, Block-3 verifier, context, discovery, scope, capabilities, exact memberships, and inventory assertions are untouched.
**Provenance:** 100% live re-pin against `xcvhacymrbhdhohyylyq` (D1). Zero reconstruction of the business migration from memory — §4 is reproduced verbatim from the CTO-audited v4 artifact and cross-checked against the live core body this session.
**Zero-mutation attestation:** every proof below ran inside a rollback-safe (`RAISE`-abort) transaction. Verified at close (3× residue gate): projector ABSENT, core `WHEN 'program'` absent (pos 0), program `registered`, registry 17, functions 240, tail `20260812070542`, audit residue 0, probe residue 0.

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

**Function surfaces (live, verify-the-verify this session):** `_mission_control_workspace_core(text,uuid,jsonb,text)` — secdef, owner `postgres`, `proconfig={search_path=""}`, ACL `postgres:EXECUTE,service_role:EXECUTE`. Sibling projectors `admin_lookup_school(uuid)` / `admin_lookup_session(uuid,uuid)` — secdef, owner `postgres`, `proconfig={search_path=""}`, ACL `authenticated:EXECUTE,postgres:EXECUTE,service_role:EXECUTE`. These are the exact strings BLOCK-2 grants produce and BLOCK-3 E/F assert for `admin_lookup_program` and the core.

---

## 2. DRIFT VERDICT

**NO DRIFT.** Every re-pinned surface matches the B3.3 architecture-pass baseline exactly; the target projector and core branch are ABSENT as required; the frozen PROGRAM contract row is exact. Package v5 is issued.

---

## 3. FROZEN PROGRAM CONTRACT (ratified; unchanged from v3/v4)

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
| projector raw payload | ONLY `{id,name}` |
| WorkspaceProjectionDTO fields | EXACTLY `{name}` |

**Explicitly excluded:** slug · description · state · artistic_domain · entitlement exposure · context widening · scope redesign · RLS change · frontend · DTO bump · dynamic SQL.

---

## 4. FULL APPROVED 3-BLOCK MIGRATION SQL (verbatim from audited v4/v3 — DO NOT MODIFY)

**Migration name:** `v128_b3_3_program_context_consumer` · **Apply tool:** `apply_migration` (atomic) · **DO NOT APPLY — awaiting CTO final completeness pass + Owner one-shot APPLY gate.**

> Reproduced byte-for-byte from the CTO-audited Package v4 (migration literal previously PASS). Unchanged in v5. Its core body was cross-checked against the live `_mission_control_workspace_core` this session; the sole semantic delta is one `WHEN 'program'` CASE branch (diff proof §13).

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

## 5. FIXTURE MANIFEST + APPLY-TIME RESOLVER

Hardcoded fixtures (audited in v3/v4; **re-pinned live this session — all resolve**). These are the same IDs bound into the frozen md5 golden (§6); per STEP 11 fixture policy, **they may not be silently swapped** — a fixture change is a verification-artifact change requiring a fresh audit.

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
| nonexistent (negative) | `00000000-0000-0000-0000-000000000009` | P2/P9/P11 wrong-key + not_found |

**Apply-time fixture resolver (run before apply; every value must resolve — else STOP, do not swap IDs):**

```sql
-- V128-B3.3 §5 FIXTURE RESOLVER (read-only; every field must resolve)
SELECT
  (SELECT jsonb_build_object('id',id,'name',name) FROM public.programs WHERE id='99240fb7-8c82-4869-a522-6e0e863285d3') AS program,
  (SELECT jsonb_build_object('id',id,'school_id',school_id) FROM public.classes WHERE id='2405fed8-1e9f-4414-b41e-b5eb5f3d8ea7') AS class_row,
  (SELECT jsonb_build_object('id',id,'class_distribution_id',class_distribution_id) FROM public.lesson_sessions WHERE id='2fab0c56-9f56-4610-9558-216d58573c20') AS session_row,
  (SELECT count(*) FROM public.schools           WHERE id='b6a4ac35-2e0a-4667-9eea-756f615c29eb') AS school_ok,
  (SELECT count(*) FROM public.profiles          WHERE id='e86e45d1-3d0a-4cbc-8d3a-2a07926ec913') AS person_ok,
  (SELECT count(*) FROM public.children          WHERE id='429d4fb7-67f0-4166-8ec3-fee7ad1a3666') AS child_ok,
  (SELECT count(*) FROM public.media_assets      WHERE id='614aa02e-fb27-4487-a603-daf26ddfc3d6') AS media_ok,
  (SELECT count(*) FROM public.discovery_capsules WHERE id='384042c1-a1a2-450c-8854-3886659cd050') AS capsule_ok;
```
**Live result this session:** program name `Cảm Thụ Âm Nhạc Dế Mèn`; class school_id `b6a4ac35…`; session class_distribution_id `a8088a55…`; school/person/child/media/capsule all `=1`. All fixtures resolve.

---

## 6. FROZEN PRE GOLDEN MAP (frozen verification input — do not regenerate)

This is the audited PRE md5 map (v3/v4). It is hardcoded directly into the §7 PRE self-assert harness and the §9 POST auto-compare harness. It is **not** derived at apply time, **not** pasted, **not** a placeholder.

```json
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

**Re-confirmed live this session:** the §7 PRE self-assert harness recomputed all seven live signatures and asserted `diffcount=0` against this exact map (see §7 result).

---

## 7. PRE REGRESSION HARNESS — FULLY LITERAL + SELF-ASSERTING

Run **before apply**, as one `DO` block. It computes the live PRE md5 map for the seven wired consumers, compares it **inside the same rollback-safe block** against the hardcoded frozen golden (§6), and asserts: all seven keys present, `diffcount=0`, `program` PRE error `not_available`, `program` PRE projector_status `registered`, and all seven consumers `ok=true`. On mismatch it RAISEs a descriptive failure (`PRE_FIXTURE_BEHAVIOR_DRIFT`). On success it RAISEs `PRE_SELFCHECK_PASS`, which also forces rollback of the `child`/`capsule` reason-required audit writes. **No manual comparison. No paste. No placeholder.**

```sql
-- V128-B3.3 §7 PRE SELF-ASSERTING REGRESSION HARNESS (rollback-safe)
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
  frozen_golden jsonb := jsonb_build_object(
    'person',  '5a6f6223bde9d5edc89a38d35608afea',
    'child',   '638ba43e776c0ddd907ac0191d2a3980',
    'media',   '1b8bf00a5daedb99be02ce9217eef469',
    'capsule', '30ac77a5ea8355a7134374923443b3ec',
    'school',  'a3cc48691a042b425c406af630fe3a48',
    'class',   'dcbafbe2b725673468b32c186f16173c',
    'session', '6a9fbe1395cb9846336a31948a5362c9');
  d_person jsonb; d_child jsonb; d_media jsonb; d_capsule jsonb; d_school jsonb; d_class jsonb; d_session jsonb;
  prog_pre jsonb; live_md5 jsonb;
  k text; diffcount int := 0; diffkeys text := ''; keycount int := 0;
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
  live_md5 := jsonb_build_object(
    'person',  md5(d_person::text),  'child',   md5(d_child::text),
    'media',   md5(d_media::text),   'capsule', md5(d_capsule::text),
    'school',  md5(d_school::text),  'class',   md5(d_class::text),
    'session', md5(d_session::text));
  -- self-assert against hardcoded frozen golden (§6)
  FOR k IN SELECT jsonb_object_keys(frozen_golden) LOOP
    keycount := keycount + 1;
    IF (live_md5->>k) IS DISTINCT FROM (frozen_golden->>k) THEN
      diffcount := diffcount + 1; diffkeys := diffkeys || k || ' ';
    END IF;
  END LOOP;
  IF keycount <> 7 THEN
    RAISE EXCEPTION 'PRE_FAIL_KEYCOUNT expected 7 got %', keycount; END IF;
  IF diffcount <> 0 THEN
    RAISE EXCEPTION 'PRE_FIXTURE_BEHAVIOR_DRIFT count=% keys=[%] live=%', diffcount, diffkeys, live_md5::text; END IF;
  IF (prog_pre->>'error') IS DISTINCT FROM 'not_available' THEN
    RAISE EXCEPTION 'PRE_PROGRAM_ERROR_FAIL got=%', prog_pre->>'error'; END IF;
  IF (prog_pre->>'projector_status') IS DISTINCT FROM 'registered' THEN
    RAISE EXCEPTION 'PRE_PROGRAM_STATUS_FAIL got=%', prog_pre->>'projector_status'; END IF;
  IF (d_person->>'ok')<>'true' OR (d_child->>'ok')<>'true' OR (d_media->>'ok')<>'true'
     OR (d_capsule->>'ok')<>'true' OR (d_school->>'ok')<>'true' OR (d_class->>'ok')<>'true'
     OR (d_session->>'ok')<>'true' THEN
    RAISE EXCEPTION 'PRE_CONSUMER_OK_FAIL p=% c=% m=% cap=% s=% cl=% se=%',
      d_person->>'ok', d_child->>'ok', d_media->>'ok', d_capsule->>'ok', d_school->>'ok', d_class->>'ok', d_session->>'ok'; END IF;
  RAISE EXCEPTION 'PRE_SELFCHECK_PASS|keycount=%|diffcount=0|prog_error=%|prog_status=%',
    keycount, prog_pre->>'error', prog_pre->>'projector_status';
END $PRE$;
```

**Executed live this session (rollback-safe):**
`ERROR: PRE_SELFCHECK_PASS|keycount=7|diffcount=0|prog_error=not_available|prog_status=registered` → live PRE md5 map equals the frozen golden (§6), program correctly gated at `not_available`, transaction rolled back.

---

## 8. PRE RESIDUE VERIFICATION

Run immediately after §7 (expect pristine):

```sql
-- V128-B3.3 §8 PRE-harness residue verification (read-only)
SELECT
  (SELECT count(*) FROM public.audit_logs WHERE reason='b33_regression')                          AS audit_residue,     -- expect 0
  (SELECT projector_status FROM public.mission_control_object_registry WHERE object_type='program') AS program_status,    -- expect registered
  (SELECT count(*) FROM public.mission_control_object_registry)                                     AS registry_total,    -- expect 17
  (SELECT count(*) FROM pg_proc p JOIN pg_namespace n ON n.oid=p.pronamespace
     WHERE n.nspname='public' AND p.proname='admin_lookup_program')                                AS projector_exists; -- expect 0
```
**Live result this session:** `audit_residue=0 · program_status=registered · registry_total=17 · projector_exists=0`. Zero residue, zero mutation.

---

## 9. POST REGRESSION HARNESS — FULLY LITERAL + AUTOMATIC PRE-GOLDEN COMPARISON

Run **after apply**, as one `DO` block. It computes the live POST md5 map for the seven wired consumers, **auto-compares it inside the same block against the hardcoded frozen PRE golden (§6)** — asserting exactly seven keys checked and `diffcount=0` — then calls PROGRAM and asserts `ok=true`, `dto=WorkspaceProjectionDTO/v1`, `object_type=program`, `scope=platform`, `projector_status=wired`, and fields keys EXACTLY `name`. On success it RAISEs `POST_SELFCOMPARE_PASS`, forcing rollback of the reason-required audit writes. **The entire PRE→POST comparison happens inside this one harness. No separate paste step. No placeholder. No future artifact mutation.**

```sql
-- V128-B3.3 §9 POST SELF-COMPARING REGRESSION HARNESS (rollback-safe; run after apply)
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
  frozen_golden jsonb := jsonb_build_object(
    'person',  '5a6f6223bde9d5edc89a38d35608afea',
    'child',   '638ba43e776c0ddd907ac0191d2a3980',
    'media',   '1b8bf00a5daedb99be02ce9217eef469',
    'capsule', '30ac77a5ea8355a7134374923443b3ec',
    'school',  'a3cc48691a042b425c406af630fe3a48',
    'class',   'dcbafbe2b725673468b32c186f16173c',
    'session', '6a9fbe1395cb9846336a31948a5362c9');
  d_person jsonb; d_child jsonb; d_media jsonb; d_capsule jsonb; d_school jsonb; d_class jsonb; d_session jsonb;
  prog_post jsonb; post_md5 jsonb; prog_keys text;
  k text; diffcount int := 0; diffkeys text := ''; keycount int := 0;
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
  post_md5 := jsonb_build_object(
    'person',  md5(d_person::text),  'child',   md5(d_child::text),
    'media',   md5(d_media::text),   'capsule', md5(d_capsule::text),
    'school',  md5(d_school::text),  'class',   md5(d_class::text),
    'session', md5(d_session::text));
  -- auto-compare live POST md5 map directly against hardcoded frozen PRE golden (§6)
  FOR k IN SELECT jsonb_object_keys(frozen_golden) LOOP
    keycount := keycount + 1;
    IF (post_md5->>k) IS DISTINCT FROM (frozen_golden->>k) THEN
      diffcount := diffcount + 1; diffkeys := diffkeys || k || ' ';
    END IF;
  END LOOP;
  IF keycount <> 7 THEN
    RAISE EXCEPTION 'POST_FAIL_KEYCOUNT expected 7 got %', keycount; END IF;
  IF diffcount <> 0 THEN
    RAISE EXCEPTION 'POST_SEVEN_CONSUMER_DIFF count=% keys=[%] post=%', diffcount, diffkeys, post_md5::text; END IF;
  -- PROGRAM POST assertions
  prog_keys := (SELECT string_agg(kk,',' ORDER BY kk) FROM jsonb_object_keys(prog_post->'fields') kk);
  IF (prog_post->>'ok') IS DISTINCT FROM 'true' THEN
    RAISE EXCEPTION 'POST_PROGRAM_OK_FAIL got=%', prog_post->>'ok'; END IF;
  IF (prog_post->>'dto') IS DISTINCT FROM 'WorkspaceProjectionDTO/v1' THEN
    RAISE EXCEPTION 'POST_PROGRAM_DTO_FAIL got=%', prog_post->>'dto'; END IF;
  IF (prog_post->>'object_type') IS DISTINCT FROM 'program' THEN
    RAISE EXCEPTION 'POST_PROGRAM_OBJTYPE_FAIL got=%', prog_post->>'object_type'; END IF;
  IF (prog_post->>'scope') IS DISTINCT FROM 'platform' THEN
    RAISE EXCEPTION 'POST_PROGRAM_SCOPE_FAIL got=%', prog_post->>'scope'; END IF;
  IF (prog_post->>'projector_status') IS DISTINCT FROM 'wired' THEN
    RAISE EXCEPTION 'POST_PROGRAM_STATUS_FAIL got=%', prog_post->>'projector_status'; END IF;
  IF prog_keys IS DISTINCT FROM 'name' THEN
    RAISE EXCEPTION 'POST_PROGRAM_FIELDS_FAIL keys=%', prog_keys; END IF;
  RAISE EXCEPTION 'POST_SELFCOMPARE_PASS|keycount=%|diffcount=0|prog_ok=%|prog_dto=%|prog_scope=%|prog_status=%|prog_keys=%|prog_name=%',
    keycount, prog_post->>'ok', prog_post->>'dto', prog_post->>'scope', prog_post->>'projector_status', prog_keys, prog_post->'fields'->>'name';
END $POST$;
```

**Executed live this session** via the STEP-9 rollback-only in-transaction simulation: BLOCK-1 DDL (projector + core `WHEN 'program'`) and the guarded transition were applied inside a single rollback-only `DO` block, the **exact body above** was executed against that in-transaction state, and a terminal `RAISE` rolled the whole transaction back. Emitted:
`ERROR: POST_SELFCOMPARE_PASS|keycount=7|diffcount=0|prog_ok=true|prog_dto=WorkspaceProjectionDTO/v1|prog_scope=platform|prog_status=wired|prog_keys=name|prog_name=Cảm Thụ Âm Nhạc Dế Mèn`
→ the simulated POST md5 map for all seven wired consumers is byte-identical to the frozen PRE golden (§6), `diffcount=0`; PROGRAM projects exactly `{name}` with the correct DTO/scope/status. `apply_migration` was **not** called.

**POST residue verification (run after §9 post-apply; expect pristine except the committed migration):**

```sql
SELECT
  (SELECT count(*) FROM public.audit_logs WHERE reason='b33_regression') AS audit_residue,  -- expect 0
  (SELECT projector_status FROM public.mission_control_object_registry WHERE object_type='program') AS program_status;  -- expect wired
```

---

## 10. P1–P13 FUNCTIONAL HARNESS — LITERAL SQL

Run **after apply** as one `DO` block. Rollback-safe; admin/non-admin impersonation explicit with a claims re-set between phases; assertions `RAISE` on mismatch; on success RAISEs `P1_P13_PASS` (terminal rollback of P12 child/capsule audit writes). Unchanged from v4.

```sql
-- V128-B3.3 §10 FUNCTIONAL MATRIX P1-P13 (post-apply; rollback-safe; asserts on mismatch)
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

**Executed live this session** via the STEP-9 rollback-only simulation (BLOCK-1 DDL + guarded transition applied in-txn, this exact body executed, terminal rollback): emitted `ERROR: P1_P13_PASS` — all thirteen assertions passed.

---

## 11. SYNTHETIC P14 HARNESS — LITERAL SQL

Inserts a synthetic registry object that is `wired` but has **no** CASE dispatch branch, satisfying live registry constraints, then calls the adapter → must return `dispatch_missing`. Terminal `RAISE` rolls back the synthetic row. Touches no real registered object (subscription/support/privacy untouched). Unchanged from v4.

```sql
-- V128-B3.3 §11 P14 SYNTHETIC PROBE (rollback-only): wired-but-no-dispatch -> dispatch_missing
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

**Executed live this session (standalone):** `ERROR: P14|rows_in_txn=18|result_error=dispatch_missing` → rollback. **Residue verification separately:** total registry rows = 17, probe residue = 0 (see §12).

---

## 12. RESIDUE VERIFICATION — LITERAL SQL

Run after §7/§9/§10/§11 (and, pre-apply, after the simulations). Proves zero residue and, pre-apply, zero mutation. Post-apply, `projector_exists=1`, `program_status=wired`, `functions=241` are the only intended deltas.

```sql
-- V128-B3.3 §12 RESIDUE / MUTATION GATE
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

**Executed live this session (3×, after each simulation batch — pre-apply):** `audit_residue=0 · probe_residue=0 · program_status=registered · registry_total=17 · projector_exists=0 · core_program_pos=0 · functions=240 · tail 20260812070542`. Production pristine.

---

## 13. POST-COMMIT ACL / STRUCTURAL / INVENTORY VERIFICATION

**In-migration:** BLOCK 3 (§4) asserts A–P and rolls back atomically on any failure — projector existence/owner/secdef/proconfig (A–D), projector ACL (E), core ACL (F), core existence (G), class/session/program branch retention (H/I/J), complete frozen PROGRAM POST-state incl. context + capability (K), registry total (L), exact wired/registered/none memberships (M/N/O), and exact inventory `90/241/230/166/33/1` (P).

**Post-commit ACL / proconfig (literal; run after apply):**

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
--   admin_lookup_program(uuid)                            -> proconfig_exact_ok=true, owner=postgres, secdef=true, acl=authenticated:EXECUTE,postgres:EXECUTE,service_role:EXECUTE
--   _mission_control_workspace_core(text,uuid,jsonb,text) -> proconfig_exact_ok=true, owner=postgres, secdef=true, acl=postgres:EXECUTE,service_role:EXECUTE
```

**Verify-the-verify executed live this session** against known-good siblings (`admin_lookup_school(uuid)`, `admin_lookup_session(uuid,uuid)`, `_mission_control_workspace_core(text,uuid,jsonb,text)`): projector-family ACL = `authenticated:EXECUTE,postgres:EXECUTE,service_role:EXECUTE`, core ACL = `postgres:EXECUTE,service_role:EXECUTE`, all `proconfig=search_path=""` exact, owner postgres, secdef — i.e. the exact strings BLOCK-2 grants produce and BLOCK-3 E/F assert. The in-txn simulation confirmed `functions=241` while the projector existed inside the transaction.

---

## 14. LITERAL EXECUTABILITY AUDIT

Every SQL block was checked for: no nested PL/pgSQL function declaration except via `EXECUTE` of DDL strings inside the *simulation only* (never in the shipped harnesses §7/§9/§10/§11/§12); no undefined variable; no `SELECT…INTO` count mismatch; no boolean→integer mismatch; no invalid role switching; no undefined alias; no missing table/function; no manual data substitution; no permanent helper; no permanent test artifact; no pseudo-SQL; and **no executable placeholder anywhere** (see §18).

| Block | Executed this session? | Observed result | Rollback confirmed? |
|---|---|---|---|
| §4 BLOCK-1 DDL (projector + core) | ✅ via simulation (EXECUTE) | compiled + ran; `WHEN 'program'` present; `functions=241` in-txn | ✅ (projector ABSENT at close, §12) |
| §4 1c guarded transition | ✅ via simulation | `guard_rows=1` | ✅ (program `registered` at close) |
| §5 fixture resolver | ✅ live | program name + class/session correlated IDs + 5×count=1 all resolve | n/a (read-only) |
| §7 PRE self-assert harness | ✅ live standalone | `PRE_SELFCHECK_PASS keycount=7 diffcount=0 not_available/registered` | ✅ (§8: audit_residue=0) |
| §8 PRE residue verify | ✅ live | `0 / registered / 17 / 0` | n/a (read-only) |
| §9 POST self-compare harness (exact body) | ✅ via simulation | `POST_SELFCOMPARE_PASS keycount=7 diffcount=0 prog ok/dto/platform/wired/name` | ✅ (§12 gate) |
| §10 P1–P13 | ✅ via simulation | `P1_P13_PASS` (all 13 asserted values correct) | ✅ (§12 gate) |
| §11 P14 probe | ✅ live standalone | `rows_in_txn=18 → dispatch_missing` | ✅ (probe_residue=0) |
| §12 residue gate | ✅ live (3×) | `0/0/registered/17/0/0/240` | n/a (read-only) |
| §13 ACL/proconfig verify-the-verify | ✅ live (siblings + core) | target ACL strings + proconfig exact confirmed | n/a (read-only) |

**POST-semantics method (STEP 9):** the migration BLOCK-1 DDL and guarded transition were applied inside a single rollback-only `DO` block, the **exact** §9 POST harness body and §10 P1–P13 body were executed against that in-transaction state, and a terminal `RAISE` rolled the whole transaction back — leaving zero persistent mutation (confirmed §12). `apply_migration` was **not** called.

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
| P12 | person/child/media/capsule/school | PRE ≡ POST | seven-consumer diffcount = 0 (§7 & §9) | ✅ |
| P13 | forbidden object (`raw_media`) | `forbidden_object` | `forbidden_object` | ✅ |
| P14 | synthetic `__probe_b33__` | `dispatch_missing` + rollback + 0 residue | `rows=18 → dispatch_missing`, residue 0 | ✅ |

*P7 note:* pre-wire, PROGRAM short-circuits at the `registered → not_available` gate before context validation, so an unknown key returns `not_available` PRE and `context_invalid` only POST-wire — correct fail-closed ordering, matching §7 PRE (`not_available`) vs P7 POST (`context_invalid`).

---

## 16. PREDICTED STRUCTURAL DELTA

```
PRE  : 90 / 240 / 229 / 166 / 33 / 1
POST : 90 / 241 / 230 / 166 / 33 / 1
```
Delta = **+1 function**, **+1 SECURITY DEFINER** (`admin_lookup_program`). Core `CREATE OR REPLACE` is net-zero (same OID). tables / policies / triggers / cron unchanged. Registry stays **17 rows**; **wired 7→8** · **registered 4→3** · **none 6→6**. Asserted in-migration by BLOCK-3 P (inventory) + K/L/M/N/O (registry).

---

## 17. RISKS / UNKNOWNS

- **Migration provenance:** §4 is reproduced verbatim from the CTO-audited v4 artifact (itself recovered from the v3 authoring session) and cross-checked against the live core body this session. CTO should byte-diff §4 against its retained v4 copy as part of the final completeness pass; the sole intended core delta is one `WHEN 'program'` branch (§13 H/I/J + §16).
- **Pre-state binding is strictly fail-closed:** any drift between preflight and apply → block 1c `v_n<>1` → atomic abort; BLOCK-3 K re-asserts the complete frozen POST-state. Apply promptly after the final gate.
- **Apply-time gap:** all evidence is point-in-time. If any object is wired/registered or any fixture is deleted between now and apply, block 1c and/or BLOCK-3 K/L/M/N/O/P fail closed → rollback. Re-run §1 re-pin + §5 fixture resolver + §7 PRE self-assert immediately before apply.
- **Frozen-golden binding (STEP 3/11):** the §6 golden is hardcoded into §7 and §9. Because md5 signatures are frozen, fixtures may **not** be silently swapped — any fixture change is a verification-artifact change requiring a fresh audit. If §7 PRE self-assert RAISEs `PRE_FIXTURE_BEHAVIOR_DRIFT`, **STOP — do not apply.**
- **ACL default-grant reset (D231):** BLOCK 2 explicitly `REVOKE … FROM authenticated` on the core after `CREATE OR REPLACE`; without it assertion F fails closed.
- **`proconfig` literal:** asserted as `ARRAY['search_path=""']`; exactness confirmed live against three known-good siblings this session (§13).
- **Reason-required audit writes:** §7/§9/§10 touch `child`/`capsule` (reason `b33_regression`); every shipped harness is terminated by `RAISE` so those writes roll back — proven residue 0 (§8/§12). An applier must run each as a single `DO` block (not split), or the audit writes will commit.
- No known blocker remains at package-author level.

---

## 18. ARTIFACT SELF-CONTAINMENT PROOF

A future applier holding **only this file** (no old package, no old chat, no manual paste) can execute the entire flow:

1. **Final drift gate** — §1 re-pin queries + §2 verdict criteria.
2. **Fixture resolver** — §5 (every value must resolve).
3. **PRE golden self-check** — §7 (self-asserts live signatures against the §6 golden hardcoded in the block; RAISEs `PRE_SELFCHECK_PASS` or `PRE_FIXTURE_BEHAVIOR_DRIFT`).
4. **Migration** — §4 via `apply_migration` (only after CTO PASS + Owner APPLY gate).
5. **In-tx structural verify** — BLOCK 3 A–P (part of §4; atomic rollback on any failure).
6. **POST self-comparison** — §9 (auto-compares live POST signatures against the same §6 golden hardcoded in the block; RAISEs `POST_SELFCOMPARE_PASS` or a diff failure).
7. **P1–P13** — §10.
8. **P14** — §11.
9. **Residue checks** — §8 / §12.
10. **ACL / inventory / security verification** — §13 (+ BLOCK-3 E/F/P).

**Placeholder audit (STEP 6):** the entire package was searched for `<PASTE`, `PASTE`, `<...>`, `same as previous`, `same as v4`, `insert output here`, and manual-substitution instructions. **Result: zero executable placeholder.** The frozen golden appears only as a hardcoded `jsonb_build_object(...)` literal inside §7 and §9. The comparison logic runs inside those harnesses — there is no standalone paste-comparison step and no runtime artifact rewriting.

Explicit statements:
- **No external file needed.**
- **No old package needed.**
- **No old chat needed.**
- **No manual paste needed.**
- **No runtime artifact rewriting needed.**

---

## 19. PACKAGE-AUTHOR VERDICT

Every required literal artifact is present, self-contained, and runtime-verified live this session (rollback-safe, zero production mutation): §4 full approved 3-block migration (verbatim, unchanged) · §5 fixture manifest + resolver · §6 frozen PRE golden · §7 PRE self-asserting harness · §8 PRE residue verify · §9 POST self-comparing harness (auto-compares against the frozen golden inline) · §10 P1–P13 · §11 P14 · §12 residue gate · §13 post-commit ACL/structural/inventory verification. The single v4 blocker — placeholder-bearing PRE→POST comparison — is eliminated: the comparison is folded into §7/§9 with the frozen golden hardcoded, and there is zero executable placeholder.

# PACKAGE v5 READY FOR CTO FINAL COMPLETENESS AUDIT

**HARD STOP.** No migration applied. No APPLY authorization assumed or requested. No production mutation. No D356 canonicalization. No HANDOFF B3.3. No B3.4. PROGRAM architecture unchanged.

**Only next action:** Owner forwards Package v5 to ChatGPT/CTO for final completeness audit. After — and only after — CTO returns `FINAL IMPLEMENTATION PASS`, Owner may separately issue `AUTHORIZED — APPLY V128-B3.3` as a one-shot production authorization; only then is `apply_migration` (§4) + post-commit verification (§9/§10/§11/§12/§13) executed.
