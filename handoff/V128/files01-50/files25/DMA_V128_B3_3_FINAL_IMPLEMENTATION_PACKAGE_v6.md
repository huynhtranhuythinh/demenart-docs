# V128-B3.3 — FINAL IMPLEMENTATION PACKAGE v6

**Scope:** FINAL RELEASE-GOVERNANCE CORRECTION ONLY. No redesign. No architecture change. No apply. No production mutation. No canonicalization. No D356. No HANDOFF B3.3. No B3.4.
**Author role:** Technical PM · Migration Package Author · Verification Harness Author · Release Evidence Collector.
**Corrects (the two Work-mode blockers of v5, nothing else):**
- **Blocker A — self-containment:** v5 §18 claimed a future applier could reproduce the drift gate, but §1 held only *recorded* results, not literal executable SQL. v6 adds **§4 FINAL DRIFT GATE** — one fail-closed `DO $drift$…$drift$` block that reproduces every re-pin assertion in literal PostgreSQL, RAISE-EXCEPTION on any mismatch, `RAISE NOTICE 'B3.3 FINAL DRIFT GATE PASS'` on success. No external reconstruction remains.
- **Blocker B — NULL-safety:** v5 functional assertions used `<>` on `jsonb ->>` extractions, which yields `NULL` (not `false`) when the field is missing, so an `IF … THEN` fail-branch is **not entered** → malformed/missing results could false-PASS. v6 converts every nullable text/`->>` assertion in the PRE harness, P1–P13, and P14 to fail-closed `IS DISTINCT FROM`; boolean gates use `NOT COALESCE(...,false)`. Integer counters sourced from `count()` (`keycount`/`diffcount`/`v_cnt`) are provably non-NULL and are left as `<>` per the deliberate-audit instruction, with P14 gaining an exact `IS DISTINCT FROM 18` row-count assertion. A **§16 negative-control** proves the correction empirically.
**Migration §9 unchanged — byte-identical to the CTO-audited v5/v4 migration** (SHA-256 `3938d3c16f38b879fe9c7c72b43ae5e8f04d369da90a1cf926bf6addb5e43463`, proof §10). Projector body, core `WHEN 'program'` branch, guarded transition, ACL, Block-3 verifier: untouched.
**Provenance:** 100% fresh live re-pin against `xcvhacymrbhdhohyylyq` (D1) this session. Migration reproduced verbatim from the audited v5 artifact and its core body cross-checked against the live core this session; zero reconstruction from memory.
**Zero-mutation attestation:** every proof below ran inside a rollback-safe (`RAISE`-abort or read-only) transaction. Final residue gate (this session): projector ABSENT, core `WHEN 'program'` absent (pos 0), program `registered`, registry 17, functions 240, tail `20260812070542`, audit residue 0, probe residue 0.

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
| `admin_lookup_program(uuid)` | ABSENT | ABSENT | ✅ |
| core `WHEN 'program'` branch | ABSENT | ABSENT (pos 0) | ✅ |

**Registry exact memberships (live):**
- **wired (7):** `capsule,child,class,media,person,school,session`
- **registered (4):** `privacy_request,program,subscription,support_case`
- **none/forbidden (6):** `badges,child_journey,family_memory,journal,raw_media,skills`

**PROGRAM PRE-state row (live, all frozen fields):**
```
object_type=program · kind=supporting · scope=platform · projector_status=registered · privacy_policy=open
discovery_fields=["name"] · context_requirements={"keys":{},"version":1,"allow_unknown":false}
capability_vocab={"edit":"program.edit","view":null} · forbidden_groups=[]
```

**Function-surface posture (live this session):**
- `_mission_control_workspace_core(text,uuid,jsonb,text)` — owner `postgres`, secdef, `proconfig={search_path=""}`, ACL `postgres:EXECUTE,service_role:EXECUTE` (internal). CLASS branch present (pos 3293), SESSION branch present (pos 3545), PROGRAM branch ABSENT (pos 0). Scope allowlist = three `IS DISTINCT FROM 'platform'/'tenant'/'assignment'` clauses.
- `admin_lookup_class(uuid,uuid)` / `admin_lookup_school(uuid)` / `admin_lookup_session(uuid,uuid)` — owner `postgres`, secdef, `search_path=""`, ACL `authenticated:EXECUTE,postgres:EXECUTE,service_role:EXECUTE`.
- `get_object_workspace(text,uuid,jsonb,text)` (4-arg) + `get_object_workspace(text,uuid,text)` (3-arg legacy) — owner `postgres`, secdef, `search_path=""`, ACL `authenticated:EXECUTE,postgres:EXECUTE,service_role:EXECUTE`.
- `validate_mission_control_object_context(text,jsonb)` — owner `postgres`, secdef, `search_path=""`, ACL `postgres:EXECUTE,service_role:EXECUTE` (internal).

---

## 2. DRIFT VERDICT

**NO DRIFT.** Every re-pinned surface matches the B3.3 architecture-pass baseline exactly; the target projector and core branch are ABSENT as required; the frozen PROGRAM contract row is exact; all wrapper/validator/sibling-projector postures are canonical. The literal **§4 FINAL DRIFT GATE** was executed live this session and **completed with no exception** (all fail-closed assertions held). Package v6 is issued for CTO final completeness audit.

---

## 3. FROZEN PROGRAM CONTRACT (ratified; unchanged from v3/v4/v5)

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

## 4. FINAL DRIFT GATE — LITERAL EXECUTABLE SQL (Blocker A fix)

**REQUIRED as apply-time STEP 1.** Run immediately before the fixture resolver / PRE harness / apply. Fail-closed: any mismatch `RAISE EXCEPTION` (aborting the apply transaction); success emits `RAISE NOTICE 'B3.3 FINAL DRIFT GATE PASS'` (non-aborting, so the apply flow continues). It requires **no old chat, no old package, no external reconstruction** — every expected value is bound literally here.

Asserts fail-closed: migration tail `20260812070542`; inventory `90/240/229/166/33/1`; registry total 17; exact wired/registered/none memberships; PROGRAM exact PRE-state (8 fields); `admin_lookup_program(uuid)` ABSENT; core exists + owner `postgres` + secdef + `search_path=""` + ACL `postgres:EXECUTE,service_role:EXECUTE` + CLASS & SESSION branches present + PROGRAM branch ABSENT + three-scope allowlist intact; validator + both `get_object_workspace` wrappers present with exact owner/secdef/`search_path`/ACL.

```sql
-- V128-B3.3 §4 FINAL DRIFT GATE (apply STEP 1; read-only; fail-closed)
DO $drift$
DECLARE
  v_tail text; v_tables int; v_funcs int; v_secdef int; v_pol int; v_trig int; v_cron int;
  v_total int; v_wired text; v_reg text; v_none text;
  v_prog record;
  v_core_owner text; v_core_secdef boolean; v_core_cfg text[]; v_core_acl text; v_core_def text;
  v_val_owner text; v_val_secdef boolean; v_val_cfg text[]; v_val_acl text;
  v_w4_owner text; v_w4_secdef boolean; v_w4_cfg text[]; v_w4_acl text;
  v_w3_owner text; v_w3_secdef boolean; v_w3_cfg text[]; v_w3_acl text;
BEGIN
  -- MIGRATION TAIL
  SELECT version INTO v_tail FROM supabase_migrations.schema_migrations ORDER BY version DESC LIMIT 1;
  IF v_tail IS DISTINCT FROM '20260812070542' THEN RAISE EXCEPTION 'DRIFT_TAIL got %', v_tail; END IF;

  -- INVENTORY 90/240/229/166/33/1
  SELECT (SELECT count(*) FROM pg_tables WHERE schemaname='public'),
         (SELECT count(*) FROM pg_proc p JOIN pg_namespace n ON n.oid=p.pronamespace WHERE n.nspname='public'),
         (SELECT count(*) FROM pg_proc p JOIN pg_namespace n ON n.oid=p.pronamespace WHERE n.nspname='public' AND p.prosecdef),
         (SELECT count(*) FROM pg_policies WHERE schemaname='public'),
         (SELECT count(*) FROM pg_trigger t JOIN pg_class c ON c.oid=t.tgrelid JOIN pg_namespace n ON n.oid=c.relnamespace WHERE n.nspname='public' AND NOT t.tgisinternal),
         (SELECT count(*) FROM cron.job)
    INTO v_tables, v_funcs, v_secdef, v_pol, v_trig, v_cron;
  IF v_tables IS DISTINCT FROM 90 OR v_funcs IS DISTINCT FROM 240 OR v_secdef IS DISTINCT FROM 229
     OR v_pol IS DISTINCT FROM 166 OR v_trig IS DISTINCT FROM 33 OR v_cron IS DISTINCT FROM 1 THEN
    RAISE EXCEPTION 'DRIFT_INVENTORY %/%/%/%/%/% expected 90/240/229/166/33/1', v_tables,v_funcs,v_secdef,v_pol,v_trig,v_cron; END IF;

  -- REGISTRY TOTAL + EXACT MEMBERSHIPS
  SELECT count(*),
         string_agg(object_type,',' ORDER BY object_type) FILTER (WHERE projector_status='wired'),
         string_agg(object_type,',' ORDER BY object_type) FILTER (WHERE projector_status='registered'),
         string_agg(object_type,',' ORDER BY object_type) FILTER (WHERE projector_status='none')
    INTO v_total, v_wired, v_reg, v_none FROM public.mission_control_object_registry;
  IF v_total IS DISTINCT FROM 17 THEN RAISE EXCEPTION 'DRIFT_TOTAL %', v_total; END IF;
  IF v_wired IS DISTINCT FROM 'capsule,child,class,media,person,school,session' THEN RAISE EXCEPTION 'DRIFT_WIRED [%]', v_wired; END IF;
  IF v_reg   IS DISTINCT FROM 'privacy_request,program,subscription,support_case' THEN RAISE EXCEPTION 'DRIFT_REGISTERED [%]', v_reg; END IF;
  IF v_none  IS DISTINCT FROM 'badges,child_journey,family_memory,journal,raw_media,skills' THEN RAISE EXCEPTION 'DRIFT_NONE [%]', v_none; END IF;

  -- PROGRAM EXACT PRE-STATE (8 fields)
  SELECT * INTO v_prog FROM public.mission_control_object_registry WHERE object_type='program';
  IF NOT FOUND THEN RAISE EXCEPTION 'DRIFT_PROGRAM_MISSING'; END IF;
  IF v_prog.kind IS DISTINCT FROM 'supporting' OR v_prog.scope IS DISTINCT FROM 'platform'
     OR v_prog.projector_status IS DISTINCT FROM 'registered' OR v_prog.privacy_policy IS DISTINCT FROM 'open'
     OR v_prog.discovery_fields IS DISTINCT FROM ARRAY['name']::text[]
     OR v_prog.context_requirements IS DISTINCT FROM '{"keys":{},"version":1,"allow_unknown":false}'::jsonb
     OR v_prog.capability_vocab IS DISTINCT FROM '{"edit":"program.edit","view":null}'::jsonb
     OR v_prog.forbidden_groups IS DISTINCT FROM ARRAY[]::text[] THEN
    RAISE EXCEPTION 'DRIFT_PROGRAM_STATE %', row_to_json(v_prog); END IF;

  -- PROJECTOR ABSENCE
  IF to_regprocedure('public.admin_lookup_program(uuid)') IS NOT NULL THEN RAISE EXCEPTION 'DRIFT_PROJECTOR_PRESENT'; END IF;

  -- CORE POSTURE + BRANCHES + SCOPE ALLOWLIST
  IF to_regprocedure('public._mission_control_workspace_core(text,uuid,jsonb,text)') IS NULL THEN RAISE EXCEPTION 'DRIFT_CORE_MISSING'; END IF;
  SELECT pg_get_userbyid(proowner), prosecdef, proconfig INTO v_core_owner, v_core_secdef, v_core_cfg
    FROM pg_proc WHERE oid='public._mission_control_workspace_core(text,uuid,jsonb,text)'::regprocedure;
  IF v_core_owner IS DISTINCT FROM 'postgres' THEN RAISE EXCEPTION 'DRIFT_CORE_OWNER %', v_core_owner; END IF;
  IF NOT COALESCE(v_core_secdef,false) THEN RAISE EXCEPTION 'DRIFT_CORE_SECDEF'; END IF;
  IF v_core_cfg IS DISTINCT FROM ARRAY['search_path=""'] THEN RAISE EXCEPTION 'DRIFT_CORE_CFG %', v_core_cfg; END IF;
  SELECT string_agg((CASE WHEN a.grantee=0 THEN 'PUBLIC' ELSE COALESCE(r.rolname,a.grantee::text) END)||':'||a.privilege_type,
           ',' ORDER BY (CASE WHEN a.grantee=0 THEN 'PUBLIC' ELSE COALESCE(r.rolname,a.grantee::text) END), a.privilege_type)
    INTO v_core_acl
    FROM pg_proc p CROSS JOIN LATERAL aclexplode(coalesce(p.proacl,acldefault('f',p.proowner))) a
    LEFT JOIN pg_roles r ON r.oid=a.grantee
   WHERE p.oid='public._mission_control_workspace_core(text,uuid,jsonb,text)'::regprocedure;
  IF v_core_acl IS DISTINCT FROM 'postgres:EXECUTE,service_role:EXECUTE' THEN RAISE EXCEPTION 'DRIFT_CORE_ACL [%]', v_core_acl; END IF;
  v_core_def := pg_get_functiondef('public._mission_control_workspace_core(text,uuid,jsonb,text)'::regprocedure);
  IF position('WHEN ''class''' IN v_core_def) = 0 THEN RAISE EXCEPTION 'DRIFT_CORE_CLASS_ABSENT'; END IF;
  IF position('WHEN ''session''' IN v_core_def) = 0 THEN RAISE EXCEPTION 'DRIFT_CORE_SESSION_ABSENT'; END IF;
  IF position('WHEN ''program''' IN v_core_def) <> 0 THEN RAISE EXCEPTION 'DRIFT_CORE_PROGRAM_PRESENT'; END IF;
  IF position('IS DISTINCT FROM ''platform''' IN v_core_def) = 0
     OR position('IS DISTINCT FROM ''tenant''' IN v_core_def) = 0
     OR position('IS DISTINCT FROM ''assignment''' IN v_core_def) = 0 THEN RAISE EXCEPTION 'DRIFT_CORE_SCOPE_ALLOWLIST'; END IF;

  -- VALIDATOR POSTURE (internal-only)
  IF to_regprocedure('public.validate_mission_control_object_context(text,jsonb)') IS NULL THEN RAISE EXCEPTION 'DRIFT_VALIDATOR_MISSING'; END IF;
  SELECT pg_get_userbyid(pp.proowner), pp.prosecdef, pp.proconfig,
         (SELECT string_agg((CASE WHEN a.grantee=0 THEN 'PUBLIC' ELSE COALESCE(r.rolname,a.grantee::text) END)||':'||a.privilege_type,
            ',' ORDER BY (CASE WHEN a.grantee=0 THEN 'PUBLIC' ELSE COALESCE(r.rolname,a.grantee::text) END), a.privilege_type)
          FROM aclexplode(coalesce(pp.proacl,acldefault('f',pp.proowner))) a LEFT JOIN pg_roles r ON r.oid=a.grantee)
    INTO v_val_owner, v_val_secdef, v_val_cfg, v_val_acl
    FROM pg_proc pp WHERE pp.oid='public.validate_mission_control_object_context(text,jsonb)'::regprocedure;
  IF v_val_owner IS DISTINCT FROM 'postgres' OR NOT COALESCE(v_val_secdef,false)
     OR v_val_cfg IS DISTINCT FROM ARRAY['search_path=""'] OR v_val_acl IS DISTINCT FROM 'postgres:EXECUTE,service_role:EXECUTE' THEN
    RAISE EXCEPTION 'DRIFT_VALIDATOR owner=% secdef=% cfg=% acl=[%]', v_val_owner,v_val_secdef,v_val_cfg,v_val_acl; END IF;

  -- WRAPPERS 4-arg + 3-arg POSTURE
  IF to_regprocedure('public.get_object_workspace(text,uuid,jsonb,text)') IS NULL THEN RAISE EXCEPTION 'DRIFT_WRAPPER4_MISSING'; END IF;
  IF to_regprocedure('public.get_object_workspace(text,uuid,text)') IS NULL THEN RAISE EXCEPTION 'DRIFT_WRAPPER3_MISSING'; END IF;
  SELECT pg_get_userbyid(pp.proowner), pp.prosecdef, pp.proconfig,
         (SELECT string_agg((CASE WHEN a.grantee=0 THEN 'PUBLIC' ELSE COALESCE(r.rolname,a.grantee::text) END)||':'||a.privilege_type,
            ',' ORDER BY (CASE WHEN a.grantee=0 THEN 'PUBLIC' ELSE COALESCE(r.rolname,a.grantee::text) END), a.privilege_type)
          FROM aclexplode(coalesce(pp.proacl,acldefault('f',pp.proowner))) a LEFT JOIN pg_roles r ON r.oid=a.grantee)
    INTO v_w4_owner, v_w4_secdef, v_w4_cfg, v_w4_acl
    FROM pg_proc pp WHERE pp.oid='public.get_object_workspace(text,uuid,jsonb,text)'::regprocedure;
  IF v_w4_owner IS DISTINCT FROM 'postgres' OR NOT COALESCE(v_w4_secdef,false)
     OR v_w4_cfg IS DISTINCT FROM ARRAY['search_path=""'] OR v_w4_acl IS DISTINCT FROM 'authenticated:EXECUTE,postgres:EXECUTE,service_role:EXECUTE' THEN
    RAISE EXCEPTION 'DRIFT_WRAPPER4 owner=% secdef=% cfg=% acl=[%]', v_w4_owner,v_w4_secdef,v_w4_cfg,v_w4_acl; END IF;
  SELECT pg_get_userbyid(pp.proowner), pp.prosecdef, pp.proconfig,
         (SELECT string_agg((CASE WHEN a.grantee=0 THEN 'PUBLIC' ELSE COALESCE(r.rolname,a.grantee::text) END)||':'||a.privilege_type,
            ',' ORDER BY (CASE WHEN a.grantee=0 THEN 'PUBLIC' ELSE COALESCE(r.rolname,a.grantee::text) END), a.privilege_type)
          FROM aclexplode(coalesce(pp.proacl,acldefault('f',pp.proowner))) a LEFT JOIN pg_roles r ON r.oid=a.grantee)
    INTO v_w3_owner, v_w3_secdef, v_w3_cfg, v_w3_acl
    FROM pg_proc pp WHERE pp.oid='public.get_object_workspace(text,uuid,text)'::regprocedure;
  IF v_w3_owner IS DISTINCT FROM 'postgres' OR NOT COALESCE(v_w3_secdef,false)
     OR v_w3_cfg IS DISTINCT FROM ARRAY['search_path=""'] OR v_w3_acl IS DISTINCT FROM 'authenticated:EXECUTE,postgres:EXECUTE,service_role:EXECUTE' THEN
    RAISE EXCEPTION 'DRIFT_WRAPPER3 owner=% secdef=% cfg=% acl=[%]', v_w3_owner,v_w3_secdef,v_w3_cfg,v_w3_acl; END IF;

  RAISE NOTICE 'B3.3 FINAL DRIFT GATE PASS';
END
$drift$;
```

**Executed live this session:** completed with **no exception** → every fail-closed assertion held on current production (tail/inventory/registry/PROGRAM-state/projector-absence/core-posture/branches/scope-allowlist/validator/both-wrappers). This is the literal STEP-1 gate a future applier runs.

---

## 5. FIXTURE MANIFEST + APPLY-TIME RESOLVER

Hardcoded fixtures (audited v3/v4/v5; **re-pinned live this session — all resolve**). Bound into the frozen md5 golden (§6); per fixture policy they may **not** be silently swapped — a fixture change is a verification-artifact change requiring fresh audit.

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

Audited PRE md5 map (v3/v4/v5). Hardcoded into §7 PRE self-assert and §12 POST auto-compare. Not derived at apply time, not pasted, not a placeholder.

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

**Re-confirmed live this session:** the §7 PRE self-assert harness recomputed all seven live signatures and asserted `diffcount=0` against this exact map.

---

## 7. PRE SELF-ASSERT HARNESS — NULL-SAFE (Blocker B applied)

Run **before apply**, one `DO` block. Computes the live PRE md5 map for the seven wired consumers, compares inside the same rollback-safe block against the hardcoded frozen golden (§6), and asserts: seven keys present, `diffcount=0`, PROGRAM PRE error `not_available`, PROGRAM PRE projector_status `registered`, all seven consumers `ok`. **NULL-safe change vs v5:** the seven consumer-`ok` checks now use `IS DISTINCT FROM 'true'` (were `<>'true'`). The md5/error/status comparisons already used `IS DISTINCT FROM`. `keycount`/`diffcount` are `count()`-derived non-NULL integers, left as `<>`.

```sql
-- V128-B3.3 §7 PRE SELF-ASSERTING REGRESSION HARNESS (NULL-safe; rollback-safe)
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
  FOR k IN SELECT jsonb_object_keys(frozen_golden) LOOP
    keycount := keycount + 1;
    IF (live_md5->>k) IS DISTINCT FROM (frozen_golden->>k) THEN
      diffcount := diffcount + 1; diffkeys := diffkeys || k || ' ';
    END IF;
  END LOOP;
  IF keycount <> 7 THEN RAISE EXCEPTION 'PRE_FAIL_KEYCOUNT expected 7 got %', keycount; END IF;
  IF diffcount <> 0 THEN RAISE EXCEPTION 'PRE_FIXTURE_BEHAVIOR_DRIFT count=% keys=[%] live=%', diffcount, diffkeys, live_md5::text; END IF;
  IF (prog_pre->>'error') IS DISTINCT FROM 'not_available' THEN RAISE EXCEPTION 'PRE_PROGRAM_ERROR_FAIL got=%', prog_pre->>'error'; END IF;
  IF (prog_pre->>'projector_status') IS DISTINCT FROM 'registered' THEN RAISE EXCEPTION 'PRE_PROGRAM_STATUS_FAIL got=%', prog_pre->>'projector_status'; END IF;
  IF (d_person->>'ok')  IS DISTINCT FROM 'true' OR (d_child->>'ok')   IS DISTINCT FROM 'true'
     OR (d_media->>'ok') IS DISTINCT FROM 'true' OR (d_capsule->>'ok') IS DISTINCT FROM 'true'
     OR (d_school->>'ok') IS DISTINCT FROM 'true' OR (d_class->>'ok')  IS DISTINCT FROM 'true'
     OR (d_session->>'ok') IS DISTINCT FROM 'true' THEN
    RAISE EXCEPTION 'PRE_CONSUMER_OK_FAIL p=% c=% m=% cap=% s=% cl=% se=%',
      d_person->>'ok', d_child->>'ok', d_media->>'ok', d_capsule->>'ok', d_school->>'ok', d_class->>'ok', d_session->>'ok'; END IF;
  RAISE EXCEPTION 'PRE_SELFCHECK_PASS|keycount=%|diffcount=0|prog_error=%|prog_status=%',
    keycount, prog_pre->>'error', prog_pre->>'projector_status';
END $PRE$;
```

**Executed live this session (rollback-safe):**
`ERROR: PRE_SELFCHECK_PASS|keycount=7|diffcount=0|prog_error=not_available|prog_status=registered` → live PRE md5 map equals the frozen golden (§6), program correctly gated, transaction rolled back.

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

## 9. FULL APPROVED 3-BLOCK MIGRATION SQL (verbatim; byte-identical to v4/v5 — DO NOT MODIFY)

**Migration name:** `v128_b3_3_program_context_consumer` · **Apply tool:** `apply_migration` (atomic) · **DO NOT APPLY — awaiting CTO FINAL IMPLEMENTATION PASS + Owner one-shot APPLY gate.**

> Reproduced byte-for-byte from the CTO-audited v5/v4 migration; SHA-256 proof in §10. Core body cross-checked against the live `_mission_control_workspace_core` this session; the sole semantic delta is one `WHEN 'program'` CASE branch (§11/§18). BLOCK 3 is the in-migration structural verifier (A–P), atomic rollback on any failure.

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

## 10. MIGRATION BYTE-IDENTITY PROOF

The §9 fenced migration SQL was extracted from this artifact and SHA-256 hashed:

```
extracted-migration SHA-256 : 3938d3c16f38b879fe9c7c72b43ae5e8f04d369da90a1cf926bf6addb5e43463
expected (v5/v4 audited)     : 3938d3c16f38b879fe9c7c72b43ae5e8f04d369da90a1cf926bf6addb5e43463
verdict                      : ✅ BYTE-IDENTICAL — MATCH
extracted-migration bytes    : 14307
```

The v6 migration is byte-for-byte identical to the CTO-audited v5/v4 migration. No content drift; the only v6 changes are the new §4 drift gate and the NULL-safe functional harnesses (§7/§13/§14/§16) — the migration itself is untouched. (Provenance note in §20.)

---

## 11. POST-COMMIT STRUCTURAL / ACL / INVENTORY SQL

**In-migration (part of §9 BLOCK 3):** asserts A–P and rolls back atomically on any failure — projector existence/owner/secdef/proconfig (A–D), projector ACL (E), core ACL (F), core existence (G), class/session/program branch retention (H/I/J), complete frozen PROGRAM POST-state incl. context + capability (K), registry total (L), exact wired/registered/none memberships (M/N/O), exact inventory `90/241/230/166/33/1` (P).

**Post-commit ACL / proconfig (literal; run after apply):**

```sql
-- V128-B3.3 §11 post-commit projector + core ACL / proconfig exactness
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

-- V128-B3.3 §11 post-commit inventory / registry re-pin
SELECT
  (SELECT count(*) FROM pg_tables WHERE schemaname='public') AS tables,                          -- 90
  (SELECT count(*) FROM pg_proc p JOIN pg_namespace n ON n.oid=p.pronamespace WHERE n.nspname='public') AS functions, -- 241
  (SELECT count(*) FROM pg_proc p JOIN pg_namespace n ON n.oid=p.pronamespace WHERE n.nspname='public' AND p.prosecdef) AS secdef, -- 230
  (SELECT count(*) FROM pg_policies WHERE schemaname='public') AS policies,                       -- 166
  (SELECT count(*) FROM pg_trigger t JOIN pg_class c ON c.oid=t.tgrelid JOIN pg_namespace n ON n.oid=c.relnamespace WHERE n.nspname='public' AND NOT t.tgisinternal) AS triggers, -- 33
  (SELECT count(*) FROM cron.job) AS cron,                                                        -- 1
  (SELECT count(*) FROM public.mission_control_object_registry) AS registry_total,               -- 17
  (SELECT string_agg(object_type,',' ORDER BY object_type) FILTER (WHERE projector_status='wired') FROM public.mission_control_object_registry) AS wired, -- capsule,child,class,media,person,program,school,session
  (SELECT string_agg(object_type,',' ORDER BY object_type) FILTER (WHERE projector_status='registered') FROM public.mission_control_object_registry) AS registered; -- privacy_request,subscription,support_case
```

**Verify-the-verify executed live this session** against known-good siblings (`admin_lookup_school(uuid)`, `admin_lookup_session(uuid,uuid)`, `admin_lookup_class(uuid,uuid)`, both `get_object_workspace` wrappers, validator, core): projector-family ACL = `authenticated:EXECUTE,postgres:EXECUTE,service_role:EXECUTE`, core/validator ACL = `postgres:EXECUTE,service_role:EXECUTE`, all `proconfig=search_path=""` exact, owner postgres, secdef — the exact strings BLOCK-2 grants produce and BLOCK-3 E/F/D assert for the new projector and core.

---

## 12. POST SELF-COMPARE HARNESS — NULL-SAFE

Run **after apply**, one `DO` block. Computes the live POST md5 map for the seven wired consumers, auto-compares inside the same block against the hardcoded frozen PRE golden (§6) — seven keys, `diffcount=0` — then calls PROGRAM and asserts `ok=true`, `dto=WorkspaceProjectionDTO/v1`, `object_type=program`, `scope=platform`, `projector_status=wired`, fields keys EXACTLY `name`. **Already fully NULL-safe in v5 and retained verbatim** (all `IS DISTINCT FROM`); integer `keycount`/`diffcount` non-NULL, left as `<>`.

```sql
-- V128-B3.3 §12 POST SELF-COMPARING REGRESSION HARNESS (NULL-safe; rollback-safe; run after apply)
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
  FOR k IN SELECT jsonb_object_keys(frozen_golden) LOOP
    keycount := keycount + 1;
    IF (post_md5->>k) IS DISTINCT FROM (frozen_golden->>k) THEN
      diffcount := diffcount + 1; diffkeys := diffkeys || k || ' ';
    END IF;
  END LOOP;
  IF keycount <> 7 THEN RAISE EXCEPTION 'POST_FAIL_KEYCOUNT expected 7 got %', keycount; END IF;
  IF diffcount <> 0 THEN RAISE EXCEPTION 'POST_SEVEN_CONSUMER_DIFF count=% keys=[%] post=%', diffcount, diffkeys, post_md5::text; END IF;
  prog_keys := (SELECT string_agg(kk,',' ORDER BY kk) FROM jsonb_object_keys(prog_post->'fields') kk);
  IF (prog_post->>'ok') IS DISTINCT FROM 'true' THEN RAISE EXCEPTION 'POST_PROGRAM_OK_FAIL got=%', prog_post->>'ok'; END IF;
  IF (prog_post->>'dto') IS DISTINCT FROM 'WorkspaceProjectionDTO/v1' THEN RAISE EXCEPTION 'POST_PROGRAM_DTO_FAIL got=%', prog_post->>'dto'; END IF;
  IF (prog_post->>'object_type') IS DISTINCT FROM 'program' THEN RAISE EXCEPTION 'POST_PROGRAM_OBJTYPE_FAIL got=%', prog_post->>'object_type'; END IF;
  IF (prog_post->>'scope') IS DISTINCT FROM 'platform' THEN RAISE EXCEPTION 'POST_PROGRAM_SCOPE_FAIL got=%', prog_post->>'scope'; END IF;
  IF (prog_post->>'projector_status') IS DISTINCT FROM 'wired' THEN RAISE EXCEPTION 'POST_PROGRAM_STATUS_FAIL got=%', prog_post->>'projector_status'; END IF;
  IF prog_keys IS DISTINCT FROM 'name' THEN RAISE EXCEPTION 'POST_PROGRAM_FIELDS_FAIL keys=%', prog_keys; END IF;
  RAISE EXCEPTION 'POST_SELFCOMPARE_PASS|keycount=%|diffcount=0|prog_ok=%|prog_dto=%|prog_scope=%|prog_status=%|prog_keys=%|prog_name=%',
    keycount, prog_post->>'ok', prog_post->>'dto', prog_post->>'scope', prog_post->>'projector_status', prog_keys, prog_post->'fields'->>'name';
END $POST$;
```

**Executed live this session** via rollback-only in-tx POST simulation (BLOCK-1 DDL projector + core `WHEN 'program'` + guarded transition applied in one transaction via `EXECUTE`, this exact body run against that in-tx state, terminal `RAISE` rolled all back; `apply_migration` NOT called):
`ERROR: POST_SELFCOMPARE_PASS|keycount=7|diffcount=0|prog_ok=true|prog_dto=WorkspaceProjectionDTO/v1|prog_scope=platform|prog_status=wired|prog_keys=name|prog_name=Cảm Thụ Âm Nhạc Dế Mèn`
→ simulated POST md5 map for all seven wired consumers is byte-identical to the frozen PRE golden (§6), `diffcount=0`; PROGRAM projects exactly `{name}`.

---

## 13. P1–P13 FUNCTIONAL HARNESS — NULL-SAFE (Blocker B applied)

Run **after apply**, one `DO` block. Rollback-safe; admin/non-admin impersonation explicit with a claims re-set between phases; on success RAISEs `P1_P13_PASS`. **NULL-safe change vs v5:** every `(r->>'…') <> '…'` and `keys <> 'name'` assertion converted to `IS DISTINCT FROM` — so a missing/NULL field forces the fail branch instead of silently skipping it.

```sql
-- V128-B3.3 §13 FUNCTIONAL MATRIX P1-P13 (post-apply; NULL-safe; rollback-safe)
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
  IF (r->>'ok') IS DISTINCT FROM 'true' THEN RAISE EXCEPTION 'P1_FAIL ok=%', r->>'ok'; END IF;
  IF keys IS DISTINCT FROM 'name'       THEN RAISE EXCEPTION 'P1_FAIL keys=%', keys; END IF;

  -- P2 nonexistent PROGRAM -> not_found
  r := public.get_object_workspace('program', nope, '{}'::jsonb, NULL);
  IF (r->>'error') IS DISTINCT FROM 'not_found' THEN RAISE EXCEPTION 'P2_FAIL=%', r->>'error'; END IF;

  -- P5 legacy 3-arg PROGRAM -> success
  r := public.get_object_workspace('program', prog, NULL::text);
  IF (r->>'ok') IS DISTINCT FROM 'true' THEN RAISE EXCEPTION 'P5_FAIL=%', r->>'error'; END IF;

  -- P6 4-arg {} PROGRAM -> success
  r := public.get_object_workspace('program', prog, '{}'::jsonb, NULL);
  IF (r->>'ok') IS DISTINCT FROM 'true' THEN RAISE EXCEPTION 'P6_FAIL=%', r->>'error'; END IF;

  -- P7 PROGRAM + unknown context key -> context_invalid (allow_unknown=false)
  r := public.get_object_workspace('program', prog, jsonb_build_object('foo',1), NULL);
  IF (r->>'error') IS DISTINCT FROM 'context_invalid' THEN RAISE EXCEPTION 'P7_FAIL=%', r->>'error'; END IF;

  -- P8 CLASS correct school context -> success
  r := public.get_object_workspace('class', cls, jsonb_build_object('school_id', cls_sch::text), NULL);
  IF (r->>'ok') IS DISTINCT FROM 'true' THEN RAISE EXCEPTION 'P8_FAIL=%', r->>'error'; END IF;

  -- P9 CLASS wrong school -> not_found
  r := public.get_object_workspace('class', cls, jsonb_build_object('school_id', nope::text), NULL);
  IF (r->>'error') IS DISTINCT FROM 'not_found' THEN RAISE EXCEPTION 'P9_FAIL=%', r->>'error'; END IF;

  -- P10 SESSION correct distribution -> success
  r := public.get_object_workspace('session', ses, jsonb_build_object('class_distribution_id', ses_cd::text), NULL);
  IF (r->>'ok') IS DISTINCT FROM 'true' THEN RAISE EXCEPTION 'P10_FAIL=%', r->>'error'; END IF;

  -- P11 SESSION wrong distribution -> not_found
  r := public.get_object_workspace('session', ses, jsonb_build_object('class_distribution_id', nope::text), NULL);
  IF (r->>'error') IS DISTINCT FROM 'not_found' THEN RAISE EXCEPTION 'P11_FAIL=%', r->>'error'; END IF;

  -- P12 person/child/media/capsule/school unchanged -> ok (reason for reason-required)
  IF (public.get_object_workspace('person',  per, '{}'::jsonb, NULL)->>'ok')            IS DISTINCT FROM 'true' THEN RAISE EXCEPTION 'P12_person_FAIL'; END IF;
  IF (public.get_object_workspace('child',   chd, '{}'::jsonb, 'b33_regression')->>'ok') IS DISTINCT FROM 'true' THEN RAISE EXCEPTION 'P12_child_FAIL'; END IF;
  IF (public.get_object_workspace('media',   med, '{}'::jsonb, NULL)->>'ok')            IS DISTINCT FROM 'true' THEN RAISE EXCEPTION 'P12_media_FAIL'; END IF;
  IF (public.get_object_workspace('capsule', cap, '{}'::jsonb, 'b33_regression')->>'ok') IS DISTINCT FROM 'true' THEN RAISE EXCEPTION 'P12_capsule_FAIL'; END IF;
  IF (public.get_object_workspace('school',  sch, '{}'::jsonb, NULL)->>'ok')            IS DISTINCT FROM 'true' THEN RAISE EXCEPTION 'P12_school_FAIL'; END IF;

  -- P13 forbidden object -> forbidden_object
  r := public.get_object_workspace('raw_media', prog, '{}'::jsonb, NULL);
  IF (r->>'error') IS DISTINCT FROM 'forbidden_object' THEN RAISE EXCEPTION 'P13_FAIL=%', r->>'error'; END IF;

  -- NON-ADMIN PHASE (explicit role reset via claims re-set)
  PERFORM set_config('request.jwt.claims', json_build_object('sub',nonadmin_sub,'role','authenticated')::text, true);

  -- P3 non-admin through wrapper -> not_authorized
  r := public.get_object_workspace('program', prog, '{}'::jsonb, NULL);
  IF (r->>'error') IS DISTINCT FROM 'not_authorized' THEN RAISE EXCEPTION 'P3_FAIL=%', r->>'error'; END IF;

  -- P4 non-admin direct admin_lookup_program -> not_admin
  r := public.admin_lookup_program(prog);
  IF (r->>'error') IS DISTINCT FROM 'not_admin' THEN RAISE EXCEPTION 'P4_FAIL=%', r->>'error'; END IF;

  RAISE EXCEPTION 'P1_P13_PASS';  -- terminal rollback (discards any reason-required audit writes)
END $FN$;
```

**Executed live this session** via the rollback-only POST simulation (BLOCK-1 DDL + guarded transition applied in-tx, this exact body executed, terminal rollback): emitted `ERROR: P1_P13_PASS` — all thirteen assertions passed under NULL-safe semantics.

---

## 14. P14 SYNTHETIC HARNESS — NULL-SAFE (Blocker B applied)

Inserts a synthetic registry object `wired` with **no** CASE dispatch branch, then calls the adapter → must return `dispatch_missing`. Terminal `RAISE` rolls back the synthetic row. **NULL-safe change vs v5:** the error check uses `IS DISTINCT FROM 'dispatch_missing'`, and an **exact fail-closed row-count assertion** `v_cnt IS DISTINCT FROM 18` was added (17 live rows + 1 probe).

```sql
-- V128-B3.3 §14 P14 SYNTHETIC PROBE (NULL-safe; rollback-only): wired-but-no-dispatch -> dispatch_missing
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
  IF v_cnt IS DISTINCT FROM 18 THEN RAISE EXCEPTION 'P14_ROWCOUNT_FAIL rows=%', v_cnt; END IF;
  IF (v->>'error') IS DISTINCT FROM 'dispatch_missing' THEN RAISE EXCEPTION 'P14_FAIL rows=% error=%', v_cnt, v->>'error'; END IF;
  RAISE EXCEPTION 'P14|rows_in_txn=%|result_error=%', v_cnt, v->>'error';
END $P14$;
```

**Executed live this session (standalone):** `ERROR: P14|rows_in_txn=18|result_error=dispatch_missing` → exact row-count 18 asserted, dispatch_missing returned, rollback. Residue verification §15.

---

## 15. P14 / AUDIT RESIDUE VERIFICATION

Run after §7/§12/§13/§14 (and, pre-apply, after the simulations). Post-apply, `projector_exists=1`, `program_status=wired`, `functions=241`, `core_program_pos>0` are the only intended deltas.

```sql
-- V128-B3.3 §15 RESIDUE / MUTATION GATE
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

**Executed live this session (final gate, after all simulations — pre-apply):** `audit_residue=0 · probe_residue=0 · program_status=registered · registry_total=17 · projector_exists=0 · core_program_pos=0 · functions=240 · tail 20260812070542`. Production pristine, zero mutation.

---

## 16. NULL-SAFETY NEGATIVE-CONTROL PROOF (verify-the-verify for Blocker B)

Because Blocker B exists specifically to prevent NULL false-pass, the correction is demonstrated empirically: on a malformed response (`'{}'::jsonb`, so `r->>'error' IS NULL`), the old `<>` predicate evaluates to `NULL` (an `IF NULL THEN` fail-branch is **not** entered → false-PASS), while the new `IS DISTINCT FROM` evaluates to `true` (fail-branch **fires** → fail-closed). Read-only; terminal `RAISE`.

```sql
-- V128-B3.3 §16 NULL-SAFETY NEGATIVE CONTROL (read-only; proves <> false-passes, IS DISTINCT FROM fails closed)
DO $neg$
DECLARE
  r jsonb := '{}'::jsonb;              -- malformed/missing-field response (r->>'error' IS NULL)
  old_expr boolean;                    -- old  <>              semantics
  new_expr boolean;                    -- new  IS DISTINCT FROM semantics
  old_branch_entered boolean := false;
  new_branch_entered boolean := false;
BEGIN
  old_expr := ((r->>'error') <> 'not_found');                 -- NULL <> 'x' => NULL
  new_expr := ((r->>'error') IS DISTINCT FROM 'not_found');   -- NULL IS DISTINCT FROM 'x' => true
  IF ((r->>'error') <> 'not_found') THEN old_branch_entered := true; END IF;              -- IF NULL => NOT entered
  IF ((r->>'error') IS DISTINCT FROM 'not_found') THEN new_branch_entered := true; END IF; -- => entered
  IF old_expr IS NOT NULL THEN RAISE EXCEPTION 'NEG_UNEXPECTED old_expr should be NULL, got %', old_expr; END IF;
  IF old_branch_entered THEN RAISE EXCEPTION 'NEG_UNEXPECTED old <> branch was entered (should NOT be)'; END IF;
  IF NOT new_expr THEN RAISE EXCEPTION 'NEG_FAIL new IS DISTINCT FROM did not evaluate true on NULL'; END IF;
  IF NOT new_branch_entered THEN RAISE EXCEPTION 'NEG_FAIL new fail-branch was NOT entered on NULL'; END IF;
  RAISE EXCEPTION 'NEG_CONTROL_PASS|old_expr_is_null=%|old_branch_entered=%|new_expr=%|new_branch_entered=%',
    (old_expr IS NULL), old_branch_entered, new_expr, new_branch_entered;
END $neg$;
```

**Executed live this session:** `ERROR: NEG_CONTROL_PASS|old_expr_is_null=t|old_branch_entered=f|new_expr=t|new_branch_entered=t`
→ empirically: old `<>` yields NULL and its `IF` branch is **not** entered (would false-PASS); new `IS DISTINCT FROM` yields true and its fail branch **fires** (fail-closed). The Blocker-B correction is proven to change behavior exactly where it must.

---

## 17. LITERAL EXECUTABILITY AUDIT

Every shipped SQL block checked for: no undefined variable; no `SELECT…INTO` arity mismatch; no boolean→integer mismatch; no invalid role switch; no undefined alias; no missing table/function; no nested PL/pgSQL function declaration except via `EXECUTE` of DDL strings inside the *simulation only* (never in shipped §7/§12/§13/§14/§16); no permanent helper; no permanent test artifact; **no NULL-unsafe assertion remaining in any functional harness**; and **no placeholder anywhere** (see §21).

| Block | Executed this session? | Observed result | Rollback / read-only |
|---|---|---|---|
| §4 FINAL DRIFT GATE | ✅ live | completed with NO exception (all fail-closed asserts held) | read-only |
| §5 fixture resolver | ✅ live | program name + class/session correlated IDs + 5×count=1 all resolve | read-only |
| §7 PRE self-assert (NULL-safe) | ✅ live standalone | `PRE_SELFCHECK_PASS keycount=7 diffcount=0 not_available/registered` | ✅ rollback (§8: residue 0) |
| §8 PRE residue verify | ✅ live | `0 / registered / 17 / 0` | read-only |
| §9 BLOCK-1 DDL + 1c transition | ✅ via in-tx simulation (EXECUTE) | compiled + ran; `WHEN 'program'` active in-tx; guard_rows=1 | ✅ rollback (projector ABSENT at close) |
| §12 POST self-compare (NULL-safe, exact body) | ✅ via simulation | `POST_SELFCOMPARE_PASS keycount=7 diffcount=0 prog ok/dto/platform/wired/name` | ✅ rollback (§15 gate) |
| §13 P1–P13 (NULL-safe) | ✅ via simulation | `P1_P13_PASS` (all 13 asserted) | ✅ rollback (§15 gate) |
| §14 P14 probe (NULL-safe + exact rowcount) | ✅ live standalone | `rows_in_txn=18 → dispatch_missing` | ✅ rollback (probe_residue=0) |
| §15 residue gate | ✅ live | `0/0/registered/17/0/0/240` tail unchanged | read-only |
| §16 NULL-safety negative control | ✅ live | `NEG_CONTROL_PASS old_null=t/branch=f, new=t/branch=t` | ✅ rollback |
| §11 ACL/proconfig verify-the-verify | ✅ live (siblings + core + wrappers + validator) | target ACL strings + proconfig exact confirmed | read-only |

**POST-semantics method:** the migration BLOCK-1 DDL (projector + core-with-program-branch) and the guarded transition were applied inside a single rollback-only `DO` block (via `EXECUTE`), the exact §12 POST body and §13 P1–P13 body were run against that in-transaction state, and a terminal `RAISE` rolled the whole transaction back — zero persistent mutation (confirmed §15). `apply_migration` was **not** called.

---

## 18. P1–P14 OBSERVED MATRIX (expected vs observed, executed this session)

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
| P12 | person/child/media/capsule/school | PRE ≡ POST | seven-consumer diffcount = 0 (§7 & §12) | ✅ |
| P13 | forbidden object (`raw_media`) | `forbidden_object` | `forbidden_object` | ✅ |
| P14 | synthetic `__probe_b33__` | `dispatch_missing` + rollback + 0 residue | `rows=18 → dispatch_missing`, residue 0 | ✅ |

*P7 note:* pre-wire, PROGRAM short-circuits at the `registered → not_available` gate before context validation, so an unknown key returns `not_available` PRE and `context_invalid` only POST-wire — correct fail-closed ordering (matches §7 PRE `not_available` vs P7 POST `context_invalid`).

---

## 19. PREDICTED STRUCTURAL DELTA

```
PRE  : 90 / 240 / 229 / 166 / 33 / 1
POST : 90 / 241 / 230 / 166 / 33 / 1
```
Delta = **+1 function**, **+1 SECURITY DEFINER** (`admin_lookup_program`). Core `CREATE OR REPLACE` is net-zero (same OID). tables / policies / triggers / cron unchanged. Registry stays **17 rows**; **wired 7→8** · **registered 4→3** · **none 6→6**. Asserted in-migration by BLOCK-3 P (inventory) + K/L/M/N/O (registry).

---

## 20. RISKS / UNKNOWNS

- **Migration provenance (resolved to byte-identity):** §9 is reproduced from the CTO-audited v5 artifact; its extracted SHA-256 equals the recorded `3938d3c…` (§10), so byte-identity is proven, not merely asserted. The sole intended core delta is one `WHEN 'program'` branch (§11 H/I/J + §19). CTO may independently byte-diff §9 against its retained v5 copy as belt-and-suspenders.
- **Pre-state binding is strictly fail-closed:** any drift between the §4 gate / preflight and apply → block 1c `v_n<>1` → atomic abort; BLOCK-3 K re-asserts the complete frozen POST-state. Apply promptly after the final gate.
- **Apply-time gap:** all evidence is point-in-time. If any object is wired/registered or any fixture deleted between now and apply, the §4 gate and/or block 1c and/or BLOCK-3 K/L/M/N/O/P fail closed → rollback. Re-run §4 gate + §5 resolver + §7 PRE immediately before apply.
- **Frozen-golden binding:** §6 golden is hardcoded into §7 and §12. Because md5 signatures are frozen, fixtures may **not** be silently swapped — any fixture change is a verification-artifact change requiring fresh audit. If §7 RAISEs `PRE_FIXTURE_BEHAVIOR_DRIFT`, **STOP — do not apply.**
- **ACL default-grant reset (D231):** BLOCK 2 explicitly `REVOKE … FROM authenticated` on the core after `CREATE OR REPLACE`; without it assertion F fails closed.
- **`proconfig` literal:** asserted as `ARRAY['search_path=""']`; exactness confirmed live this session against core, both wrappers, validator, and three sibling projectors.
- **Reason-required audit writes:** §7/§12/§13 touch `child`/`capsule` (reason `b33_regression`); every shipped harness is terminated by `RAISE` so those writes roll back — proven residue 0 (§8/§15). An applier must run each as a single `DO` block (not split), or the audit writes will commit.
- **NULL-safety scope note:** operators were converted deliberately, not mechanically. Integer counters (`keycount`,`diffcount`,`v_cnt`) sourced from `count()`/loop increments are provably non-NULL and intentionally retained as `<>`; the negative control (§16) targets the `->>`-extraction case where NULL is the actual risk.
- No known blocker remains at package-author level.

---

## 21. ARTIFACT SELF-CONTAINMENT PROOF

A future applier holding **only this file** (no old package, no old chat, no manual paste) can execute the entire flow. **Placeholder audit:** the artifact was searched for `<PASTE`, `PASTE`, `<...>`, `same as previous`, `same as v5`, `use old chat`, `insert output`, and manual-substitution instructions — **zero found.** The frozen golden appears only as hardcoded `jsonb_build_object(...)` literals inside §7/§12; the drift gate (§4) is literal executable SQL; the migration (§9) is literal and byte-verified (§10). Explicit statements: **No external file needed. No old package needed. No old chat needed. No manual paste needed. No runtime artifact rewriting needed.**

---

## 22. APPLY-TIME EXECUTION PROTOCOL (explicit order; STOP-on-fail)

The future applier runs, in this exact order:

1. **§4 FINAL DRIFT GATE** — must complete with no exception (`RAISE NOTICE 'B3.3 FINAL DRIFT GATE PASS'`).
2. **§5 fixture resolver** — every value must resolve.
3. **§7 PRE self-check** — must RAISE `PRE_SELFCHECK_PASS` (not `PRE_FIXTURE_BEHAVIOR_DRIFT`).
4. **§8 PRE residue** — must be `0 / registered / 17 / 0`.
5. **Apply §9 migration** via `apply_migration` (name `v128_b3_3_program_context_consumer`). BLOCK 3 A–P must pass (else atomic rollback).
6. **Confirm BLOCK-3 committed** — migration returns success + `V128-B3.3 STRUCTURAL VERIFY PASS (A-P)`.
7. **§11 post-commit structural/ACL/inventory re-pin** — projector/core ACL + proconfig exact; inventory `90/241/230/166/33/1`; registry wired 8 / registered 3.
8. **§12 POST self-compare** — must RAISE `POST_SELFCOMPARE_PASS` (diffcount=0, PROGRAM `{name}`).
9. **§13 P1–P13** — must RAISE `P1_P13_PASS`.
10. **§14 P14** — `rows_in_txn=18 → dispatch_missing` + rollback.
11. **§15 residue verification** — post-apply intended deltas only (`projector_exists=1`, `program=wired`, `functions=241`, `core_program_pos>0`), `audit_residue=0`, `probe_residue=0`.
12. **Confirm final inventory/registry/security** — §11 re-pin + BLOCK-3 E/F/P.
13. **STOP.**

If any step fails: **STOP. Do not patch forward. Do not improvise. Report failure.**

---

## 23. PACKAGE-AUTHOR VERDICT

Both Work-mode blockers are closed and nothing else changed:
- **Blocker A (self-containment):** §4 FINAL DRIFT GATE is literal executable fail-closed PostgreSQL, executed live with no exception; no external reconstruction remains (§21).
- **Blocker B (NULL-safety):** every nullable `->>` assertion in §7/§13/§14 converted to `IS DISTINCT FROM` (booleans via `NOT COALESCE(...,false)`), integer counters deliberately retained, P14 given an exact fail-closed row-count assertion; proven empirically by the §16 negative control.
- **Migration §9 unchanged:** extracted SHA-256 = `3938d3c…` = recorded target (§10) — byte-identical.

Every required literal artifact is present, self-contained, and runtime-verified live this session (rollback-safe, zero production mutation): §4 drift gate · §5 resolver · §6 golden · §7 PRE (NULL-safe) · §8 PRE residue · §9 migration (byte-identical) · §11 post-commit ACL/inventory · §12 POST (NULL-safe) · §13 P1–P13 (NULL-safe) · §14 P14 (NULL-safe) · §15 residue · §16 negative control.

# PACKAGE v6 READY FOR CTO FINAL COMPLETENESS AUDIT

**HARD STOP.** No migration applied. No APPLY authorization assumed or requested. No production mutation. No D356 canonicalization. No HANDOFF B3.3. No B3.4. PROGRAM architecture unchanged.

**Only next action:** Owner forwards Package v6 to ChatGPT/CTO for the final completeness audit. After — and only after — CTO returns `FINAL IMPLEMENTATION PASS`, Owner may separately issue `AUTHORIZED — APPLY V128-B3.3` as a one-shot production authorization; only then is `apply_migration` (§9) + post-commit verification (§11/§12/§13/§14/§15) executed in the §22 order.
