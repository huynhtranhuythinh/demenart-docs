# V128-B3.3 — FINAL IMPLEMENTATION PACKAGE v8.1

> **Fixture-only correction of Package v8 after a pre-apply STOP.** No redesign · no architecture change · no migration business-logic change · no apply · no production mutation · no D356 canonicalization · no HANDOFF B3.3 · no B3.4.
> **Author role:** Technical PM · Verification Artifact Maintainer · PostgreSQL/Supabase Evidence Collector. **CTO:** independent final auditor. **Owner:** authorizes production APPLY.
> **Base artifact:** Package v8, SHA-256 `3e24d14f62581d490dff6657b638568f9577ef3225daa7b5c8e1135c6627fae0` (verified byte-identical on the uploaded file this session).
> **Provenance:** 100% fresh live re-pin + fixture discovery + rollback-safe harness re-runs against `xcvhacymrbhdhohyylyq` this session. Zero reconstruction from memory. Migration reproduced verbatim; its SHA-256 re-verified identical.

---

## v8.1-A. INCIDENT / STOP RECORD

- Owner issued a one-shot `AUTHORIZED — APPLY V128-B3.3`; execution ran the v8 apply protocol (body §22).
- **STEP 1 FINAL DRIFT GATE (body §4): PASS.**
- **STEP 2 fixture resolution: STOPPED** — a non-admin fixture identity resolved `NULL`.
- Per body §22 execution protocol (fixture failure → STOP; no silent substitute; no patch-forward; no improvise): **migration was NOT run.**
- Post-STOP production re-check: tail `20260812070542` · functions 240 · registry 17 · PROGRAM `registered` · `admin_lookup_program(uuid)` ABSENT · core PROGRAM branch ABSENT → **ZERO PRODUCTION MUTATION.**
- The prior Owner authorization is **consumed and invalid** for v8.1.

**Incident-record accuracy correction (Owner-ratified).** The STOP was described against historical identity `e3333f05-4f56-41a1-80a0-b698e1f94d4f`. Live audit this session establishes the precise facts:

| Identity | in `auth.users` | `profiles` rows | role | `is_admin()` | in exact v8 artifact |
|---|---|---|---|---|---|
| `e3333f05-4f56-41a1-80a0-b698e1f94d4f` (incident-named) | **NO** | 0 | — | false | **0 occurrences** |
| `e3333f05-b025-45bc-8a35-4eb9ee696b6f` (**actually frozen in v8**) | YES | 1 | primary_parent | **false** | 2 (§5 manifest, §13) |
| `eb94304a-8451-44d7-88a7-fe9e26ab0b1c` (**new frozen fixture**) | YES | 1 | primary_parent | **false** | — |

- `…-4f56-…` is a **historical, now-dead** identity (absent from `auth.users` and `profiles`) → any resolver keyed on it returns NULL. It does **not** appear literally anywhere in the frozen v8 artifact.
- The identity **actually frozen** as v8's non-admin fixture is `…-b025-…` (`parent.demo@demenart.com`), which currently **resolves** and is `is_admin()=false`.
- Both are historical `user_id`s of the **same churn-prone demo subject** `parent.demo` (shared `e3333f05` prefix; the account has demonstrably been auth-recreated).
- **Therefore v8.1 is NOT a literal find-replace of `…-4f56-…` in v8.** It is a proactive hardening of the non-admin verification fixture **off the churn-prone subject entirely**, onto a seeded canonical pilot. This distinction is recorded here to keep the incident narrative exact.

## v8.1-B. CORRECTION SCOPE (Owner-ratified — option A)

Replace the non-admin verification fixture **actually frozen in v8**:

```
e3333f05-b025-45bc-8a35-4eb9ee696b6f   (parent.demo@demenart.com)
      → eb94304a-8451-44d7-88a7-fe9e26ab0b1c   (ph.hung.kidshouse@demo.demenart.com)
```

**Rationale.** parent.demo has proven auth-user churn (its `…-4f56-…` incarnation is dead); the currently-live `…-b025-…` incarnation retains that durability risk. `ph.hung` is a seeded canonical pilot (`profile_id = d1000000-0000-4000-8000-000000000051`), `primary_parent`, empirically `is_admin()=false` — a durable frozen verification fixture.

**Untouched (verified):** migration block · frozen PRE golden (§6) · PROGRAM contract (§3) · every other fixture · harness semantics · drift-gate semantics (§4) · POST harness semantics (§12) · P14 (§14) · structural verifier (§11).

## v8.1-C. FRESH LIVE RE-PIN + DRIFT VERDICT (this session, read-only)

| Pin | Expected (PRE-B3.3) | Live | ✓ |
|---|---|---|---|
| inventory tables/functions/secdef/policies/triggers/cron | 90/240/229/166/33/1 | 90/240/229/166/33/1 | ✅ |
| migration tail | `20260812070542` | `20260812070542` | ✅ |
| registry total · wired · registered · none | 17 · 7 · 4 · 6 | 17 · 7 · 4 · 6 | ✅ |
| PROGRAM projector_status | registered | registered | ✅ |
| `admin_lookup_program(uuid)` | ABSENT | ABSENT | ✅ |
| core dispatch branches | `{person,child,media,capsule,school,class,session}` (no `program`) | idem | ✅ |

**DRIFT VERDICT: NO MATERIAL DRIFT — v8.1 ISSUED.** (Gate `DRIFT — v8.1 NOT ISSUED` not triggered.)

## v8.1-D. NEW NON-ADMIN FIXTURE EVIDENCE (empirical, this session)

| Field | Value |
|---|---|
| profile_id | `d1000000-0000-4000-8000-000000000051` |
| **nonadmin_uid** | `eb94304a-8451-44d7-88a7-fe9e26ab0b1c` |
| role | `primary_parent` |
| email | `ph.hung.kidshouse@demo.demenart.com` |
| in `auth.users` / `profiles` | yes / 1 row |
| `auth.uid()` under JWT impersonation | equals fixture ✓ |
| **`public.is_admin()`** (proven under impersonation, not assumed) | **`false`** |

`is_admin()` reads `public.profiles.role ∈ {super_admin, content_admin, senior_content_admin, operation_admin, sales_admin, support_admin}`; `primary_parent` ∉ that set ⇒ `false`.

## v8.1-E. MIGRATION HASH IDENTITY PROOF (STEP 4)

| Artifact | SHA-256 | Bytes | Status |
|---|---|---|---|
| v8 whole artifact | `3e24d14f62581d490dff6657b638568f9577ef3225daa7b5c8e1135c6627fae0` | 85,720 | verified on upload |
| **v8 migration block** (body §9 fenced, incl. trailing newline) | `77879867f43de276321443ca87593b4baab56bf3f1a1faa0335e23b63bf2c214` | 14,722 | verified |
| **v8.1 migration block** (post-patch) | `77879867f43de276321443ca87593b4baab56bf3f1a1faa0335e23b63bf2c214` | 14,722 | **IDENTICAL — `cmp` byte-for-byte** |

The migration block contains **zero** fixture UIDs (`grep e3333f05` → none), so the fixture swap is structurally incapable of altering it. `MIGRATION BYTE DRIFT — v8.1 NOT ISSUED` **not triggered.**

## v8.1-F. v8 → v8.1 ARTIFACT DIFF PROOF (STEP 8)

**Verification-substance diff = exactly two lines, both UID-only** (unified diff, reproduced body):

```diff
@@ §5 FIXTURE MANIFEST (line 238) @@
-| non-admin uid | `e3333f05-b025-45bc-8a35-4eb9ee696b6f` | `is_admin()` → false |
+| non-admin uid | `eb94304a-8451-44d7-88a7-fe9e26ab0b1c` | `is_admin()` → false |

@@ §13 P1–P13 HARNESS (line 817) @@
-  nonadmin_sub text := 'e3333f05-b025-45bc-8a35-4eb9ee696b6f';
+  nonadmin_sub text := 'eb94304a-8451-44d7-88a7-fe9e26ab0b1c';
```

- Reproduced-body line-count parity: **1127 = 1127** (no lines added/removed).
- Migration / business / PROGRAM-contract / PRE-golden / harness-semantic delta: **NONE**.
- Additional (expected, non-substantive): version label `v8 → v8.1` and this additive v8.1 correction front-matter.
- **Semantic diff = verification fixture only.**

## v8.1-G. RE-RUN EVIDENCE MATRIX (this session — rollback-safe / read-only, zero mutation)

| # | Check | Method | Observed |
|---|---|---|---|
| 1 | §5 fixture resolver | read-only SELECT | program/class/session/school/person/child/media/capsule + **new nonadmin** all resolve non-NULL |
| 2 | new UID `is_admin()` | JWT impersonation (CTE-ordered `set_config`) | **false** |
| 3 | §7 PRE self-assert (frozen golden) | rollback-safe `DO` | `PRE_SELFCHECK_PASS \| keycount=7 \| diffcount=0 \| not_available/registered` |
| 4 | **Full P1–P13** with new fixture | in-tx simulated POST (projector+core+transition via `EXECUTE`, terminal RAISE) | **`V81_SIM_P1_P13_PASS`** (all 13; P3=`not_authorized`, P4=`not_admin`) |
| 5 | Focused P3/P4 with new fixture | in-tx projector, terminal RAISE | `V81_P3_P4_PASS \| is_admin=f \| P3=not_authorized \| P4=not_admin` |
| 6 | §14 P14 assignment probe | synthetic row, terminal RAISE | `P14_ASSIGNMENT \| rows_in_txn=18 \| dispatch_missing` |
| 7 | §15 residue / mutation gate | read-only | `audit=0 · probe=0 · program=registered · registry=17 · projector=0 · core_pos=0 · functions=240 · tail 20260812070542` |

All simulations rolled back via terminal `RAISE`; `apply_migration` **never** called.

## v8.1-H. PREDICTED STRUCTURAL DELTA (apply-time — unchanged from v8; see body §11/§19)

`+1` function (`admin_lookup_program(uuid)`) · core `CREATE OR REPLACE` (+1 `WHEN 'program'` branch, no other semantic delta) · registry `program` `registered → wired`. Inventory `90/240/229/166/33/1 → 90/241/230/166/33/1`. FE 0 · Edge 0 · Bunny 0.

## v8.1-I. SELF-CONTAINMENT PROOF (STEP 9)

v8.1 = this correction front-matter **+** the Package v8 verification body reproduced verbatim below (sole substantive change: the non-admin fixture UID at §5 + §13). An applier holding **only** v8.1 can run, in order: final drift gate (§4) → fixture resolver (§5) → PRE self-check (§7) → PRE residue (§8) → exact migration (§9) → structural verify (§11) → POST self-compare (§12) → P1–P13 (§13) → P14 (§14) → residue (§15) → STOP. The new non-admin fixture is frozen in §5 and §13; **no manual UID substitution is required or permitted.** No old v8 file, no old chat needed.

## v8.1-J. APPLY-TIME EXECUTION PROTOCOL (delta over body §22)

Body §22 governs, with two overrides: **(1)** the non-admin fixture is now `eb94304a-8451-44d7-88a7-fe9e26ab0b1c`; **(2)** the prior Owner authorization is **consumed** — a **new** one-shot `AUTHORIZED — APPLY V128-B3.3` is required, and only after CTO returns `FINAL IMPLEMENTATION PASS` on this v8.1. Apply-time sequence unchanged: fresh §1 re-pin + §4 drift gate + §5 resolver immediately before `apply_migration` §9; on any drift/NULL → STOP.

## v8.1-K. PACKAGE-AUTHOR VERDICT

Every required artifact is present and self-contained; the migration business SQL is byte-identical to v8 (SHA `77879867…`); the only verification change is the non-admin fixture UID (fixture-only diff proven); the new fixture is empirically `is_admin()=false`; the exact resolver returns every fixture non-NULL; PRE, full P1–P13 (incl. P3/P4 with the new fixture), and P14 pass; production remains pristine.

# PACKAGE v8.1 READY FOR CTO FINAL FIXTURE-CORRECTION AUDIT

**HARD STOP.** No migration applied. No APPLY authorization assumed or requested (prior one-shot consumed & invalid). No D356 canonicalization. No HANDOFF B3.3. No B3.4. PROGRAM architecture unchanged.
**Only next action:** Owner forwards Package v8.1 to CTO for a narrow independent audit of — new non-admin fixture validity · v8→v8.1 fixture-only diff · unchanged migration hash · P3/P4 behavior · full verification regression. After CTO returns `FINAL IMPLEMENTATION PASS`, Owner may issue a new one-shot `AUTHORIZED — APPLY V128-B3.3`.

---
---

# ⟦ PACKAGE v8 VERIFICATION BODY — reproduced verbatim below; sole substantive change: non-admin fixture UID (§5 manifest + §13), proven fixture-only above ⟧

**v8 delta (this revision):** surgical NULL-safety hardening of the in-migration **BLOCK-3 structural verifier only** — 17 `<> → IS DISTINCT FROM` swaps, 1 `NOT v_proj_secdef → NOT COALESCE(v_proj_secdef,false)`, and 2 added fail-closed guards (`IF v_core_def IS NULL …`, and `IF NOT FOUND …` immediately after the PROGRAM POST-state `SELECT`). Verifier-only, non-mutating; **BLOCK-1 / BLOCK-2 / NOTIFY / projector body / core `WHEN 'program'` branch / guarded transition / ACL grants are byte-identical to v7** (machine diff proof §10). Migration business semantics unchanged; migration SHA-256 changes solely because verifier bytes changed (old `3938d3c…` SUPERSEDED → new `77879867…` §10). Fresh full live regression this session (rollback-safe, zero mutation): NC1–NC4 fail-closed, corrected BLOCK-3 A–P simulated-POST PASS, PRE/POST/P1–P14 green.

**Scope:** FINAL RELEASE-GOVERNANCE / TWO-POINT + BLOCK-3 NULL-SAFETY VERIFICATION CORRECTION ONLY. No redesign. No architecture change. No migration business-logic change. No apply. No production mutation. No canonicalization. No D356. No HANDOFF B3.3. No B3.4.
**Author role:** Technical PM · Migration Package Author · Verification Harness Author · Release Evidence Collector.
**Corrects (the two Work-mode blockers of the v6 audit, nothing else):**
- **Blocker 1 — final drift gate did not verify sibling projector posture.** v6 §4 claimed canonical posture for `admin_lookup_school(uuid)` / `admin_lookup_class(uuid,uuid)` / `admin_lookup_session(uuid,uuid)` but the literal gate did not check them. v7 extends **§4 FINAL DRIFT GATE** with a sibling-projector block that, for each of the three, asserts (via exact `regprocedure` pins, not `proname`-only): exact existence · owner `postgres` · SECURITY DEFINER true · `proconfig` EXACTLY `ARRAY['search_path=""']::text[]` · exact EXECUTE ACL `authenticated,postgres,service_role` · NO PUBLIC · NO anon. Any sibling-posture drift RAISEs and aborts before apply. Executed live this session → **completed with no exception.**
- **Blocker 2 — P14 tested only platform scope.** v6 §14 used `scope='platform'`, proving only platform-wired/no-dispatch. The regression requirement is to preserve the **generic assignment-scope path** introduced in B3.1.5. v7 §14 uses `scope='assignment'` (kind `supporting`, privacy_policy `open`, projector_status `wired`, valid zero-context requirements, no matching core CASE branch, probe name `__probe_b33__`), called as authenticated admin. It proves: assignment scope → passes status gate → passes scope gate → clears zero-context validation → reaches static dispatch → missing CASE → **`dispatch_missing`** → fail-closed. Assertions: in-txn registry rows = 18 · `result.error IS DISTINCT FROM 'dispatch_missing' → fail` · terminal rollback · post-rollback registry total = 17 · probe residue = 0. Executed live this session (rollback-safe) → **`rows_in_txn=18 | scope=assignment | dispatch_missing`.**
**Migration §9 — BLOCK-1/BLOCK-2 business semantics byte-identical to the CTO-audited v6/v5/v4 migration; BLOCK-3 verifier NULL-safe-corrected in v8.** Projector body, core `WHEN 'program'` branch, guarded transition, ACL grants: **untouched (byte-identical)**. BLOCK-3 structural verifier: **NULL-safe hardened** (17 `<>→IS DISTINCT FROM`, 1 `COALESCE`, 2 added guards; non-mutating). Old migration SHA-256 `3938d3c…` (14,307 B) SUPERSEDED → new v8 SHA-256 `77879867…` (14,722 B). BLOCK-3-only machine-diff proof §10.
**All prior v6 fixes retained:** literal self-contained drift gate · NULL-safe PRE/POST/P1–P13/P14 · frozen PRE golden · auto PRE→POST comparison · no manual paste · no placeholders · exact migration hash · deterministic ACL aggregation · exact registry-membership checks · exact PROGRAM pre-state guard · synthetic-probe-only · zero residue · §16 NULL-safety negative control.
**Provenance:** 100% fresh live re-pin against `xcvhacymrbhdhohyylyq` (D1) this session; sibling projector postures and assignment-scope dispatch verified live this session; migration reproduced verbatim and its SHA-256 re-verified this session. Zero reconstruction from memory.
**Zero-mutation attestation:** every proof below ran inside a rollback-safe (`RAISE`-abort or read-only) transaction. Final residue gate (this session): projector ABSENT, core `WHEN 'program'` absent (pos 0), program `registered`, registry 17, functions 240, tail `20260812070542`, audit residue 0, probe residue 0.

**Required-section map (CTO checklist → this artifact):** (1) Fresh Live Re-pin → §1 · (2) Drift Verdict → §2 · (3) Frozen PROGRAM Contract → §3 · (4) FINAL DRIFT GATE incl. sibling projectors → §4 · (5) Fixture Manifest → §5 · (6) Frozen PRE Golden → §6 · (7) PRE Harness → §7 · (8) Full Approved Migration → §9 · (9) Migration Hash Proof → §10 · (10) POST Harness → §12 · (11) P1–P13 → §13 · (12) P14 assignment-scope → §14 · (13) Residue Verification → §8/§15 · (14) Post-commit Security/Inventory → §11 · (15) Verify-the-Verify → §17 · (16) Observed P1–P14 Matrix → §18 · (17) Artifact Self-Containment Proof → §21 · (18) Package-Author Verdict → §23.

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

**Function-surface posture (live this session — all seven bound in §4 drift gate):**
- `_mission_control_workspace_core(text,uuid,jsonb,text)` — owner `postgres`, secdef, `proconfig={search_path=""}`, ACL `postgres:EXECUTE,service_role:EXECUTE` (internal). CLASS + SESSION branches present, PROGRAM branch ABSENT. Scope allowlist = three `IS DISTINCT FROM 'platform'/'tenant'/'assignment'` clauses.
- **`admin_lookup_school(uuid)` / `admin_lookup_class(uuid,uuid)` / `admin_lookup_session(uuid,uuid)`** (sibling projectors) — each: owner `postgres`, secdef, `proconfig={search_path=""}`, ACL EXACTLY `authenticated:EXECUTE,postgres:EXECUTE,service_role:EXECUTE` (no PUBLIC, no anon). **Verified live this session.**
- `get_object_workspace(text,uuid,jsonb,text)` (4-arg) + `get_object_workspace(text,uuid,text)` (3-arg legacy) — owner `postgres`, secdef, `search_path=""`, ACL `authenticated:EXECUTE,postgres:EXECUTE,service_role:EXECUTE`.
- `validate_mission_control_object_context(text,jsonb)` — owner `postgres`, secdef, `search_path=""`, ACL `postgres:EXECUTE,service_role:EXECUTE` (internal).

---

## 2. DRIFT VERDICT

**NO DRIFT.** Every re-pinned surface matches the B3.3 architecture-pass baseline exactly; the target projector and core branch are ABSENT as required; the frozen PROGRAM contract row is exact; all wrapper/validator/**sibling-projector** postures are canonical. The literal **§4 FINAL DRIFT GATE** (now including the three sibling projectors) was executed live this session and **completed with no exception** (all fail-closed assertions held). Package v7 is issued for CTO final completeness audit.

---

## 3. FROZEN PROGRAM CONTRACT (ratified; unchanged from v3–v6)

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

## 4. FINAL DRIFT GATE — LITERAL EXECUTABLE SQL (Blocker 1 fix: + sibling projectors)

**REQUIRED as apply-time STEP 1.** Run immediately before the fixture resolver / PRE harness / apply. Fail-closed: any mismatch `RAISE EXCEPTION` (aborting the apply transaction); success emits `RAISE NOTICE 'B3.3 FINAL DRIFT GATE PASS'` (non-aborting). Requires **no old chat, no old package, no external reconstruction** — every expected value is bound literally here.

Asserts fail-closed: migration tail `20260812070542`; inventory `90/240/229/166/33/1`; registry total 17; exact wired/registered/none memberships; PROGRAM exact PRE-state (8 fields); `admin_lookup_program(uuid)` ABSENT; core exists + owner `postgres` + secdef + `search_path=""` + ACL `postgres:EXECUTE,service_role:EXECUTE` + CLASS & SESSION branches present + PROGRAM branch ABSENT + three-scope allowlist intact; validator + both `get_object_workspace` wrappers exact posture; **and — new in v7 — each of the three sibling projectors `admin_lookup_school(uuid)`, `admin_lookup_class(uuid,uuid)`, `admin_lookup_session(uuid,uuid)`: exact regprocedure exists, owner `postgres`, secdef, `proconfig` EXACTLY `ARRAY['search_path=""']`, EXECUTE ACL EXACTLY `authenticated,postgres,service_role` (⇒ no PUBLIC, no anon).**

```sql
-- V128-B3.3 §4 FINAL DRIFT GATE (apply STEP 1; read-only; fail-closed) — v7: + sibling projector posture
DO $drift$
DECLARE
  v_tail text; v_tables int; v_funcs int; v_secdef int; v_pol int; v_trig int; v_cron int;
  v_total int; v_wired text; v_reg text; v_none text;
  v_prog record;
  v_core_owner text; v_core_secdef boolean; v_core_cfg text[]; v_core_acl text; v_core_def text;
  v_val_owner text; v_val_secdef boolean; v_val_cfg text[]; v_val_acl text;
  v_w4_owner text; v_w4_secdef boolean; v_w4_cfg text[]; v_w4_acl text;
  v_w3_owner text; v_w3_secdef boolean; v_w3_cfg text[]; v_w3_acl text;
  -- Blocker-1 (v7): sibling projector posture
  v_sib text; v_oid oid; v_s_owner text; v_s_secdef boolean; v_s_cfg text[]; v_s_acl text;
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

  -- ==== BLOCKER-1 (v7): SIBLING PROJECTOR POSTURE (exact regprocedure pins; no proname-only) ====
  FOREACH v_sib IN ARRAY ARRAY[
      'public.admin_lookup_school(uuid)',
      'public.admin_lookup_class(uuid,uuid)',
      'public.admin_lookup_session(uuid,uuid)'
    ] LOOP
    v_oid := to_regprocedure(v_sib);
    IF v_oid IS NULL THEN RAISE EXCEPTION 'DRIFT_SIBLING_MISSING %', v_sib; END IF;
    SELECT pg_get_userbyid(pp.proowner), pp.prosecdef, pp.proconfig,
           (SELECT string_agg((CASE WHEN a.grantee=0 THEN 'PUBLIC' ELSE COALESCE(r.rolname,a.grantee::text) END)||':'||a.privilege_type,
              ',' ORDER BY (CASE WHEN a.grantee=0 THEN 'PUBLIC' ELSE COALESCE(r.rolname,a.grantee::text) END), a.privilege_type)
            FROM aclexplode(coalesce(pp.proacl,acldefault('f',pp.proowner))) a LEFT JOIN pg_roles r ON r.oid=a.grantee)
      INTO v_s_owner, v_s_secdef, v_s_cfg, v_s_acl
      FROM pg_proc pp WHERE pp.oid = v_oid;
    IF v_s_owner IS DISTINCT FROM 'postgres' THEN RAISE EXCEPTION 'DRIFT_SIBLING_OWNER % owner=%', v_sib, v_s_owner; END IF;
    IF NOT COALESCE(v_s_secdef,false) THEN RAISE EXCEPTION 'DRIFT_SIBLING_SECDEF %', v_sib; END IF;
    IF v_s_cfg IS DISTINCT FROM ARRAY['search_path=""'] THEN RAISE EXCEPTION 'DRIFT_SIBLING_CFG % cfg=%', v_sib, v_s_cfg; END IF;
    IF v_s_acl IS DISTINCT FROM 'authenticated:EXECUTE,postgres:EXECUTE,service_role:EXECUTE' THEN
      RAISE EXCEPTION 'DRIFT_SIBLING_ACL % acl=[%]', v_sib, v_s_acl; END IF;
  END LOOP;

  RAISE NOTICE 'B3.3 FINAL DRIFT GATE PASS';
END
$drift$;
```

**Executed live this session:** completed with **no exception** → every fail-closed assertion held on current production, including the three sibling projector postures (owner/secdef/`search_path=""`/exact ACL `authenticated,postgres,service_role` — no PUBLIC, no anon). This is the literal STEP-1 gate a future applier runs.

---

## 5. FIXTURE MANIFEST + APPLY-TIME RESOLVER

Hardcoded fixtures (audited v3–v6; **re-pinned live this session — all resolve**). Bound into the frozen md5 golden (§6); a fixture change is a verification-artifact change requiring fresh audit — do not silently swap.

| Role | UUID | Notes |
|---|---|---|
| admin uid | `446de75d-75b5-476d-8abd-08a98e791f40` | `is_admin()` → true |
| non-admin uid | `eb94304a-8451-44d7-88a7-fe9e26ab0b1c` | `is_admin()` → false |
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

Audited PRE md5 map (v3–v6). Hardcoded into §7 PRE self-assert and §12 POST auto-compare. Not derived at apply time, not pasted, not a placeholder.

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

## 7. PRE SELF-ASSERT HARNESS — NULL-SAFE

Run **before apply**, one `DO` block. Computes the live PRE md5 map for the seven wired consumers, compares inside the same rollback-safe block against the hardcoded frozen golden (§6), and asserts: seven keys present, `diffcount=0`, PROGRAM PRE error `not_available`, PROGRAM PRE projector_status `registered`, all seven consumers `ok`. NULL-safe: the seven consumer-`ok` checks use `IS DISTINCT FROM 'true'`; md5/error/status comparisons use `IS DISTINCT FROM`. `keycount`/`diffcount` are `count()`-derived non-NULL integers, left as `<>`.

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

## 9. FULL APPROVED 3-BLOCK MIGRATION SQL (v8: BLOCK-3 verifier NULL-safe-corrected; BLOCK-1/BLOCK-2 byte-identical to v4/v5/v6)

**Migration name:** `v128_b3_3_program_context_consumer` · **Apply tool:** `apply_migration` (atomic) · **DO NOT APPLY — awaiting CTO FINAL IMPLEMENTATION PASS + Owner one-shot APPLY gate.**

> BLOCK-1 (projector + core `WHEN 'program'` branch + guarded transition) and BLOCK-2 (ACL) are reproduced byte-for-byte from the CTO-audited v6/v5/v4 migration (business-semantics identity proven §10). The sole v8 change is inside **BLOCK-3**, the in-migration structural verifier (A–P): every assertion is made NULL-safe / fail-closed (`IS DISTINCT FROM`, `COALESCE`, explicit `IS NULL` / `NOT FOUND` guards) so a NULL / malformed structural read RAISEs instead of false-passing. BLOCK-3 performs no mutation; atomic rollback on any failure. New migration SHA-256 + BLOCK-3-only diff in §10.

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
  IF v_proj_owner IS DISTINCT FROM 'postgres' THEN RAISE EXCEPTION 'FAIL_B owner=%', v_proj_owner; END IF;
  IF NOT COALESCE(v_proj_secdef,false) THEN RAISE EXCEPTION 'FAIL_C not security definer'; END IF;
  IF v_proj_cfg IS DISTINCT FROM ARRAY['search_path=""'] THEN RAISE EXCEPTION 'FAIL_D proconfig=%', v_proj_cfg; END IF;

  -- E projector ACL (deterministic order)
  SELECT string_agg(
           (CASE WHEN a.grantee=0 THEN 'PUBLIC' ELSE COALESCE(r.rolname,a.grantee::text) END)||':'||a.privilege_type,
           ',' ORDER BY (CASE WHEN a.grantee=0 THEN 'PUBLIC' ELSE COALESCE(r.rolname,a.grantee::text) END), a.privilege_type)
    INTO v_proj_acl
    FROM pg_proc p CROSS JOIN LATERAL aclexplode(coalesce(p.proacl,acldefault('f',p.proowner))) a
    LEFT JOIN pg_roles r ON r.oid=a.grantee
   WHERE p.oid='public.admin_lookup_program(uuid)'::regprocedure;
  IF v_proj_acl IS DISTINCT FROM 'authenticated:EXECUTE,postgres:EXECUTE,service_role:EXECUTE' THEN
    RAISE EXCEPTION 'FAIL_E projector_acl=%', v_proj_acl; END IF;

  -- F core ACL (deterministic order)
  SELECT string_agg(
           (CASE WHEN a.grantee=0 THEN 'PUBLIC' ELSE COALESCE(r.rolname,a.grantee::text) END)||':'||a.privilege_type,
           ',' ORDER BY (CASE WHEN a.grantee=0 THEN 'PUBLIC' ELSE COALESCE(r.rolname,a.grantee::text) END), a.privilege_type)
    INTO v_core_acl
    FROM pg_proc p CROSS JOIN LATERAL aclexplode(coalesce(p.proacl,acldefault('f',p.proowner))) a
    LEFT JOIN pg_roles r ON r.oid=a.grantee
   WHERE p.oid='public._mission_control_workspace_core(text,uuid,jsonb,text)'::regprocedure;
  IF v_core_acl IS DISTINCT FROM 'postgres:EXECUTE,service_role:EXECUTE' THEN
    RAISE EXCEPTION 'FAIL_F core_acl=%', v_core_acl; END IF;

  -- G core exists by regprocedure
  PERFORM 'public._mission_control_workspace_core(text,uuid,jsonb,text)'::regprocedure;

  -- H/I/J branch retention
  v_core_def := pg_get_functiondef('public._mission_control_workspace_core(text,uuid,jsonb,text)'::regprocedure);
  IF v_core_def IS NULL THEN RAISE EXCEPTION 'FAIL_core_def_null'; END IF;
  IF position('WHEN ''class''' IN v_core_def) = 0   THEN RAISE EXCEPTION 'FAIL_H class branch missing'; END IF;
  IF position('WHEN ''session''' IN v_core_def) = 0 THEN RAISE EXCEPTION 'FAIL_I session branch missing'; END IF;
  IF position('WHEN ''program''' IN v_core_def) = 0 THEN RAISE EXCEPTION 'FAIL_J program branch missing'; END IF;

  -- K program registry row — COMPLETE frozen POST-state (incl context + capability), fail-closed
  SELECT * INTO v_prog FROM public.mission_control_object_registry WHERE object_type='program';
  IF NOT FOUND THEN RAISE EXCEPTION 'FAIL_K program row missing'; END IF;
  IF v_prog.projector_status IS DISTINCT FROM 'wired'
     OR v_prog.kind IS DISTINCT FROM 'supporting'
     OR v_prog.scope IS DISTINCT FROM 'platform'
     OR v_prog.privacy_policy IS DISTINCT FROM 'open'
     OR v_prog.discovery_fields     IS DISTINCT FROM ARRAY['name']::text[]
     OR v_prog.forbidden_groups     IS DISTINCT FROM ARRAY[]::text[]
     OR v_prog.context_requirements IS DISTINCT FROM '{"keys":{},"version":1,"allow_unknown":false}'::jsonb
     OR v_prog.capability_vocab     IS DISTINCT FROM '{"edit":"program.edit","view":null}'::jsonb THEN
    RAISE EXCEPTION 'FAIL_K program row drift=%', row_to_json(v_prog); END IF;

  -- L total
  SELECT count(*) INTO v_total FROM public.mission_control_object_registry;
  IF v_total IS DISTINCT FROM 17 THEN RAISE EXCEPTION 'FAIL_L total=%', v_total; END IF;

  -- M/N/O exact memberships (deterministic sorted)
  SELECT string_agg(object_type,',' ORDER BY object_type) FILTER (WHERE projector_status='wired'),
         string_agg(object_type,',' ORDER BY object_type) FILTER (WHERE projector_status='registered'),
         string_agg(object_type,',' ORDER BY object_type) FILTER (WHERE projector_status='none')
    INTO v_wired, v_reg, v_none
    FROM public.mission_control_object_registry;
  IF v_wired IS DISTINCT FROM 'capsule,child,class,media,person,program,school,session' THEN RAISE EXCEPTION 'FAIL_M wired=%', v_wired; END IF;
  IF v_reg   IS DISTINCT FROM 'privacy_request,subscription,support_case' THEN            RAISE EXCEPTION 'FAIL_N registered=%', v_reg; END IF;
  IF v_none  IS DISTINCT FROM 'badges,child_journey,family_memory,journal,raw_media,skills' THEN RAISE EXCEPTION 'FAIL_O none=%', v_none; END IF;

  -- P inventory exact predicted
  SELECT (SELECT count(*) FROM pg_tables WHERE schemaname='public'),
         (SELECT count(*) FROM pg_proc p JOIN pg_namespace n ON n.oid=p.pronamespace WHERE n.nspname='public'),
         (SELECT count(*) FROM pg_proc p JOIN pg_namespace n ON n.oid=p.pronamespace WHERE n.nspname='public' AND p.prosecdef),
         (SELECT count(*) FROM pg_policies WHERE schemaname='public'),
         (SELECT count(*) FROM pg_trigger t JOIN pg_class c ON c.oid=t.tgrelid JOIN pg_namespace n ON n.oid=c.relnamespace WHERE n.nspname='public' AND NOT t.tgisinternal),
         (SELECT count(*) FROM cron.job)
    INTO v_tables, v_funcs, v_secdef, v_pol, v_trig, v_cron;
  IF v_tables IS DISTINCT FROM 90 OR v_funcs IS DISTINCT FROM 241 OR v_secdef IS DISTINCT FROM 230 OR v_pol IS DISTINCT FROM 166 OR v_trig IS DISTINCT FROM 33 OR v_cron IS DISTINCT FROM 1 THEN
    RAISE EXCEPTION 'FAIL_P inventory=%/%/%/%/%/%', v_tables,v_funcs,v_secdef,v_pol,v_trig,v_cron; END IF;

  RAISE NOTICE 'V128-B3.3 STRUCTURAL VERIFY PASS (A-P)';
END
$verify$;

NOTIFY pgrst, 'reload schema';
```

---

## 10. MIGRATION SHA-256 + v7→v8 BLOCK-3-ONLY DIFF PROOF

The §9 fenced migration SQL was extracted and SHA-256 hashed this session using the canonical v4/v5/v6 extraction convention (fenced body incl. trailing newline) — validated by reproducing the v7/v6/v5/v4 hash byte-for-byte before hashing v8:

```
OLD migration (v7 = v6/v5/v4)  SHA-256 : 3938d3c16f38b879fe9c7c72b43ae5e8f04d369da90a1cf926bf6addb5e43463  (14,307 B)  — SUPERSEDED
NEW migration (v8, THIS file)  SHA-256 : 77879867f43de276321443ca87593b4baab56bf3f1a1faa0335e23b63bf2c214  (14,722 B)  — CURRENT
delta                                  : +415 bytes, entirely inside BLOCK-3 (structural verifier)
```

**Why the hash changed while business semantics did NOT.** A machine unified-diff of the v7 vs v8 §9 migration confirms every changed line lies strictly between the `BLOCK 3 — STRUCTURAL VERIFIER` marker and the terminal `NOTIFY pgrst, 'reload schema'`:

```
BLOCK-1 + BLOCK-2 head (projector body · core WHEN 'program' branch · guarded transition · ACL grants) : v7 == v8  BYTE-IDENTICAL
NOTIFY tail                                                                                             : v7 == v8  BYTE-IDENTICAL
BLOCK-3 verifier body                                                                                   : 13 lines removed / 15 added (+2 = the 2 added guards)
```

BLOCK-3 changes (verifier-only, zero mutation): **B** `<>→IS DISTINCT FROM` (owner) · **C** `NOT v_proj_secdef → NOT COALESCE(v_proj_secdef,false)` · **E/F** ACL `<>→IS DISTINCT FROM` · **ADDED** `IF v_core_def IS NULL THEN RAISE 'FAIL_core_def_null'` (guards H/I/J) · **ADDED** `IF NOT FOUND THEN RAISE 'FAIL_K program row missing'` after the PROGRAM POST-state `SELECT` (fail-closed row existence) · **K** four scalar `<>→IS DISTINCT FROM` · **L / M / N / O / P** `<>→IS DISTINCT FROM`. No projector, core, transition, ACL, or NOTIFY byte changed. The CTO may independently reproduce both hashes and byte-diff §9 to confirm BLOCK-1/BLOCK-2 identity and BLOCK-3-only scope.

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

**Verify-the-verify executed live this session** against known-good siblings (`admin_lookup_school(uuid)`, `admin_lookup_session(uuid,uuid)`, `admin_lookup_class(uuid,uuid)`, both `get_object_workspace` wrappers, validator, core): projector-family ACL = `authenticated:EXECUTE,postgres:EXECUTE,service_role:EXECUTE`, core/validator ACL = `postgres:EXECUTE,service_role:EXECUTE`, all `proconfig=search_path=""` exact, owner postgres, secdef — the exact strings BLOCK-2 grants produce and BLOCK-3 E/F/D assert for the new projector and core, and the strings the §4 sibling block re-asserts.

---

## 12. POST SELF-COMPARE HARNESS — NULL-SAFE

Run **after apply**, one `DO` block. Computes the live POST md5 map for the seven wired consumers, auto-compares inside the same block against the hardcoded frozen PRE golden (§6) — seven keys, `diffcount=0` — then calls PROGRAM and asserts `ok=true`, `dto=WorkspaceProjectionDTO/v1`, `object_type=program`, `scope=platform`, `projector_status=wired`, fields keys EXACTLY `name`. Fully NULL-safe (all `IS DISTINCT FROM`); integer `keycount`/`diffcount` non-NULL, left as `<>`.

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
`ERROR: POST_SELFCOMPARE_PASS|keycount=7|diffcount=0|prog_ok=true|prog_scope=platform|prog_status=wired|prog_keys=name|prog_name=Cảm Thụ Âm Nhạc Dế Mèn`
→ simulated POST md5 map for all seven wired consumers is byte-identical to the frozen PRE golden (§6), `diffcount=0`; PROGRAM projects exactly `{name}`.

---

## 13. P1–P13 FUNCTIONAL HARNESS — NULL-SAFE

Run **after apply**, one `DO` block. Rollback-safe; admin/non-admin impersonation explicit with a claims re-set between phases; on success RAISEs `P1_P13_PASS`. Every `(r->>'…')`/`keys` assertion uses `IS DISTINCT FROM` — a missing/NULL field forces the fail branch.

```sql
-- V128-B3.3 §13 FUNCTIONAL MATRIX P1-P13 (post-apply; NULL-safe; rollback-safe)
DO $FN$
DECLARE
  admin_sub    text := '446de75d-75b5-476d-8abd-08a98e791f40';
  nonadmin_sub text := 'eb94304a-8451-44d7-88a7-fe9e26ab0b1c';
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

## 14. P14 SYNTHETIC HARNESS — ASSIGNMENT SCOPE (Blocker 2 fix)

Inserts a synthetic registry object with **`scope='assignment'`** (kind `supporting`, privacy_policy `open`, projector_status `wired`, valid zero-context requirements) and **no** CASE dispatch branch, then calls the adapter as authenticated admin → must return `dispatch_missing`. This proves the generic **assignment-scope** path (introduced B3.1.5) survives B3.3: assignment passes the status gate, passes the scope gate (`assignment` is in the three-value allowlist), clears zero-context validation, reaches static dispatch, hits no matching CASE, and fails closed. Terminal `RAISE` rolls back the synthetic row. Assertions: exact in-txn row-count `18` (`IS DISTINCT FROM 18 → fail`), `error IS DISTINCT FROM 'dispatch_missing' → fail`.

```sql
-- V128-B3.3 §14 P14 SYNTHETIC PROBE — ASSIGNMENT SCOPE (NULL-safe; rollback-only)
-- assignment-scope wired-but-no-dispatch -> dispatch_missing (fail-closed)
DO $P14$
DECLARE v jsonb; v_cnt int;
BEGIN
  PERFORM set_config('request.jwt.claims',
    json_build_object('sub','446de75d-75b5-476d-8abd-08a98e791f40','role','authenticated')::text, true);
  -- synthetic assignment-scope object: passes status+scope gate, valid zero-context, NO core CASE branch
  INSERT INTO public.mission_control_object_registry
    (object_type, kind, scope, privacy_policy, projector_status, context_requirements)
  VALUES ('__probe_b33__','supporting','assignment','open','wired',
          '{"keys":{},"version":1,"allow_unknown":false}'::jsonb);
  SELECT count(*) INTO v_cnt FROM public.mission_control_object_registry;
  v := public.get_object_workspace('__probe_b33__','00000000-0000-0000-0000-000000000000'::uuid,'{}'::jsonb, NULL);
  IF v_cnt IS DISTINCT FROM 18 THEN RAISE EXCEPTION 'P14_ROWCOUNT_FAIL rows=%', v_cnt; END IF;
  IF (v->>'error') IS DISTINCT FROM 'dispatch_missing' THEN RAISE EXCEPTION 'P14_FAIL rows=% scope=assignment error=%', v_cnt, v->>'error'; END IF;
  RAISE EXCEPTION 'P14_ASSIGNMENT|rows_in_txn=%|scope=assignment|result_error=%', v_cnt, v->>'error';
END $P14$;
```

**Executed live this session (standalone, rollback-only):** `ERROR: P14_ASSIGNMENT|rows_in_txn=18|scope=assignment|result_error=dispatch_missing` → exact row-count 18 asserted, assignment scope admitted through status+scope gate, `dispatch_missing` returned at static dispatch, terminal rollback. Post-rollback residue verified §15 (`probe_residue=0`, registry total back to 17).

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

**Executed live this session (post-P14-assignment rollback, and final gate — pre-apply):** `audit_residue=0 · probe_residue=0 · program_status=registered · registry_total=17 · projector_exists=0 · core_program_pos=0 · functions=240 · tail 20260812070542`. Production pristine, zero mutation.

---

## 16. NULL-SAFETY NEGATIVE-CONTROL PROOF

On a malformed response (`'{}'::jsonb`, so `r->>'error' IS NULL`), the old `<>` predicate evaluates to `NULL` (an `IF NULL THEN` fail-branch is **not** entered → false-PASS), while the new `IS DISTINCT FROM` evaluates to `true` (fail-branch **fires** → fail-closed). Read-only; terminal `RAISE`.

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

**Executed live this session:** `ERROR: NEG_CONTROL_PASS|old_expr_is_null=t|old_branch_entered=f|new_expr=t|new_branch_entered=t` → old `<>` yields NULL and its `IF` branch is not entered (would false-PASS); new `IS DISTINCT FROM` yields true and its fail branch fires (fail-closed).

### §16b — BLOCK-3 CORRECTED-STYLE NEGATIVE CONTROLS (NC1–NC4, v8)

Direct proof that each *corrected* BLOCK-3 comparison style — plus the two added guards — is fail-closed on NULL, while the *old* `<>` / `NOT` style false-passes. Read-only SELECT of predicate values: for each pair, `*_old_isnull_falsepass=true` means the OLD `IF <expr> THEN` branch is **not** entered on NULL (false-PASS), and `*_new_fires=true` means the CORRECTED `IF <expr> THEN` branch **is** entered (fail-closed).

```sql
-- v8 §16b NC1-NC4 (read-only; proves corrected BLOCK-3 forms fail-closed on NULL)
SELECT
  (NULL::text <> 'authenticated:EXECUTE,postgres:EXECUTE,service_role:EXECUTE') IS NULL      AS nc1_old_isnull_falsepass,  -- E/F ACL aggregate
  (NULL::text IS DISTINCT FROM 'authenticated:EXECUTE,postgres:EXECUTE,service_role:EXECUTE') AS nc1_new_fires,
  (NULL::text <> 'wired')                IS NULL AS nc2_old_isnull_falsepass,                                             -- K scalar field
  (NULL::text IS DISTINCT FROM 'wired')          AS nc2_new_fires,
  (NULL::text <> 'capsule,child,class,media,person,program,school,session') IS NULL      AS nc3_old_isnull_falsepass,     -- M/N/O membership agg
  (NULL::text IS DISTINCT FROM 'capsule,child,class,media,person,program,school,session') AS nc3_new_fires,
  (NOT NULL::boolean)              IS NULL AS nc4_old_isnull_falsepass,                                                   -- C secdef boolean
  (NOT COALESCE(NULL::boolean,false))      AS nc4_new_fires,
  (NULL::text IS NULL)                     AS defnull_guard_fires,                                                        -- ADDED guard (H/I/J def-null)
  (NULL::text IS DISTINCT FROM 'wired')    AS notfound_guard_effect;                                                     -- ADDED guard (K NOT FOUND)
```

**Executed live this session:** all ten booleans `true` —
`nc1_old_isnull_falsepass=t · nc1_new_fires=t · nc2=t/t · nc3=t/t · nc4=t/t · defnull_guard_fires=t · notfound_guard_effect=t`.
Every corrected form (ACL E/F, scalar K, membership M/N/O, secdef C) and both added guards fail closed on NULL; every corresponding OLD form would have false-passed. This is the exact class of defect the v8 correction closes.

---

## 17. VERIFY-THE-VERIFY (live this session; rollback-safe / read-only)

Every shipped SQL block was runtime-checked this session; the two v7 corrected surfaces were re-proven empirically. **v8 addition:** the NULL-safe-corrected BLOCK-3 verifier was proven **both directions** this session — it PASSES A–P on a correct simulated POST state (no false-negative) and fail-closes on NULL structural reads (NC1–NC4), all rollback-safe with zero mutation.

**A. Sibling projector posture (Blocker 1):** the §4 drift gate — with the sibling block for `admin_lookup_school(uuid)`, `admin_lookup_class(uuid,uuid)`, `admin_lookup_session(uuid,uuid)` — was executed live and **completed with no exception**; each sibling's exact existence, owner `postgres`, secdef, `proconfig=ARRAY['search_path=""']`, and exact ACL `authenticated,postgres,service_role` (no PUBLIC, no anon) held. A direct read-only posture pull of all three siblings this session returned the identical strings the gate asserts.

**B. Assignment-scope P14 (Blocker 2):** the §14 probe was executed live standalone — synthetic assignment-scope row inserted (`rows_in_txn=18`), scope admitted through the status+scope gate, `dispatch_missing` returned at static dispatch, terminal rollback succeeded, post-rollback registry total `17`, `probe_residue=0`.

**C. Existing drift gate + harnesses still pass:** the full §4 gate (all original tail/inventory/registry/PROGRAM-state/projector-absence/core-posture/branches/scope-allowlist/validator/both-wrappers checks) passed alongside the new sibling block; §7 PRE, §12 POST simulation, §13 P1–P13, and §16 negative control all re-ran green this session.

| Block | Executed this session? | Observed result | Rollback / read-only |
|---|---|---|---|
| §4 FINAL DRIFT GATE (+ sibling projectors) | ✅ live | completed with NO exception (all fail-closed asserts held incl. 3 siblings) | read-only |
| §5 fixture resolver | ✅ live | program name + class/session correlated IDs + 5 fixtures resolve | read-only |
| §7 PRE self-assert (NULL-safe) | ✅ live standalone | `PRE_SELFCHECK_PASS keycount=7 diffcount=0 not_available/registered` | ✅ rollback (§8 residue 0) |
| §8 PRE residue verify | ✅ live | `0 / registered / 17 / 0` | read-only |
| §9 BLOCK-1 DDL + 1c transition | ✅ via in-tx simulation (EXECUTE) | compiled + ran; `WHEN 'program'` active in-tx; guard_rows=1 | ✅ rollback (projector ABSENT at close) |
| §12 POST self-compare (NULL-safe) | ✅ via simulation | `POST_SELFCOMPARE_PASS keycount=7 diffcount=0 prog ok/dto/platform/wired/name` | ✅ rollback (§15 gate) |
| §13 P1–P13 (NULL-safe) | ✅ via simulation | `P1_P13_PASS` (all 13 asserted) | ✅ rollback (§15 gate) |
| §14 P14 probe — **assignment scope** | ✅ live standalone | `rows_in_txn=18 → dispatch_missing` (scope=assignment) | ✅ rollback (probe_residue=0) |
| §15 residue gate | ✅ live | `0/0/registered/17/0/0/240` tail unchanged | read-only |
| §16 NULL-safety negative control | ✅ live | `NEG_CONTROL_PASS old_null=t/branch=f, new=t/branch=t` | ✅ rollback |
| §16b NC1–NC4 (corrected BLOCK-3 styles) | ✅ live | all 10 booleans `true` — ACL/scalar/membership/secdef + both guards fail-closed on NULL | read-only |
| §9 BLOCK-3 **CORRECTED** A–P (simulated POST) | ✅ via in-tx simulation | `SIM_STRUCT_VERIFY_PASS\|A-P\|corrected\|funcs=241\|secdef=230\|total=17\|wired=capsule,child,class,media,person,program,school,session` | ✅ rollback (residue 0) |
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
| P14 | synthetic `__probe_b33__` **scope=assignment** | `dispatch_missing` + rollback + 0 residue | `rows=18 → dispatch_missing` (assignment), residue 0 | ✅ |

*P7 note:* pre-wire, PROGRAM short-circuits at the `registered → not_available` gate before context validation, so an unknown key returns `not_available` PRE and `context_invalid` only POST-wire — correct fail-closed ordering (matches §7 PRE `not_available` vs P7 POST `context_invalid`).

*P14 note (v7):* the probe now uses `scope='assignment'` (was `platform` in v6). Assignment is admitted by the three-value scope allowlist and then fails closed at the missing CASE — proving the generic assignment-scope path (B3.1.5) is preserved by B3.3, not only the platform path.

---

## 19. PREDICTED STRUCTURAL DELTA

```
PRE  : 90 / 240 / 229 / 166 / 33 / 1
POST : 90 / 241 / 230 / 166 / 33 / 1
```
Delta = **+1 function**, **+1 SECURITY DEFINER** (`admin_lookup_program`). Core `CREATE OR REPLACE` is net-zero (same OID). tables / policies / triggers / cron unchanged. Registry stays **17 rows**; **wired 7→8** · **registered 4→3** · **none 6→6**. Asserted in-migration by BLOCK-3 P (inventory) + K/L/M/N/O (registry).

---

## 20. RISKS / UNKNOWNS

- **Migration provenance (byte-identity):** §9 is reproduced from the CTO-audited v6/v5/v4 migration; its extracted SHA-256 equals the recorded `3938d3c…` (§10), byte-identity proven, not asserted. The sole intended core delta is one `WHEN 'program'` branch. CTO may independently byte-diff §9 against its retained copy.
- **Sibling projector posture is now gated (Blocker 1 closed):** any pre-apply drift in `admin_lookup_school/class/session` owner/secdef/`search_path`/ACL → §4 `DRIFT_SIBLING_*` RAISE → apply aborts before any DDL. The three postures are re-pinned identical this session.
- **Assignment-scope path is now regression-covered (Blocker 2 closed):** §14 exercises `scope='assignment'` end-to-end to `dispatch_missing`; if a future core change breaks assignment admission or dispatch fail-closure, §14 fails. Platform/tenant paths remain exercised by the wired-consumer diff (P8/P10/P12).
- **Pre-state binding is strictly fail-closed:** any drift between the §4 gate / preflight and apply → block 1c `v_n<>1` → atomic abort; BLOCK-3 K re-asserts the complete frozen POST-state. Apply promptly after the final gate.
- **Apply-time gap:** all evidence is point-in-time. Re-run §4 gate + §5 resolver + §7 PRE immediately before apply.
- **Frozen-golden binding:** §6 golden is hardcoded into §7 and §12; fixtures may not be silently swapped. If §7 RAISEs `PRE_FIXTURE_BEHAVIOR_DRIFT`, **STOP — do not apply.**
- **ACL default-grant reset (D231):** BLOCK 2 explicitly `REVOKE … FROM authenticated` on the core; without it assertion F fails closed.
- **Reason-required audit writes:** §7/§12/§13 touch `child`/`capsule` (reason `b33_regression`); every shipped harness is terminated by `RAISE` so those writes roll back — proven residue 0 (§8/§15). Run each as a single `DO` block.
- No known blocker remains at package-author level.

---

## 21. ARTIFACT SELF-CONTAINMENT PROOF

A future applier holding **only this file** (no old package, no old chat, no manual paste) can execute the entire flow. **Placeholder audit:** searched for `<PASTE`, `PASTE`, `<...>`, `same as previous`, `same as v5`, `same as v6`, `use old chat`, `insert output`, and manual-substitution instructions — **zero found.** The frozen golden appears only as hardcoded `jsonb_build_object(...)` literals inside §7/§12; the drift gate (§4, including the sibling-projector block) is literal executable SQL; the migration (§9) is literal and byte-verified (§10); the assignment-scope P14 (§14) is literal. Explicit: **No external file needed. No old package needed. No old chat needed. No manual paste needed. No runtime artifact rewriting needed.**

---

## 22. APPLY-TIME EXECUTION PROTOCOL (explicit order; STOP-on-fail)

The future applier runs, in this exact order:

1. **§4 FINAL DRIFT GATE** (incl. sibling projectors) — must complete with no exception (`RAISE NOTICE 'B3.3 FINAL DRIFT GATE PASS'`).
2. **§5 fixture resolver** — every value must resolve.
3. **§7 PRE self-check** — must RAISE `PRE_SELFCHECK_PASS` (not `PRE_FIXTURE_BEHAVIOR_DRIFT`).
4. **§8 PRE residue** — must be `0 / registered / 17 / 0`.
5. **Apply §9 migration** via `apply_migration` (name `v128_b3_3_program_context_consumer`). BLOCK 3 A–P must pass (else atomic rollback).
6. **Confirm BLOCK-3 committed** — migration returns success + `V128-B3.3 STRUCTURAL VERIFY PASS (A-P)`.
7. **§11 post-commit structural/ACL/inventory re-pin** — projector/core ACL + proconfig exact; inventory `90/241/230/166/33/1`; registry wired 8 / registered 3.
8. **§12 POST self-compare** — must RAISE `POST_SELFCOMPARE_PASS` (diffcount=0, PROGRAM `{name}`).
9. **§13 P1–P13** — must RAISE `P1_P13_PASS`.
10. **§14 P14 (assignment scope)** — `rows_in_txn=18 → dispatch_missing` + rollback.
11. **§15 residue verification** — post-apply intended deltas only (`projector_exists=1`, `program=wired`, `functions=241`, `core_program_pos>0`), `audit_residue=0`, `probe_residue=0`.
12. **Confirm final inventory/registry/security** — §11 re-pin + BLOCK-3 E/F/P.
13. **STOP.**

If any step fails: **STOP. Do not patch forward. Do not improvise. Report failure.**

---

## 23. PACKAGE-AUTHOR VERDICT

Both v6-audit Work-mode blockers remain empirically closed; the **v8** revision additionally closes the Work-mode **BLOCK-3 NULL-safety** blocker — migration business semantics untouched, and no other change made:
- **Blocker 1 (final drift gate — sibling projectors):** §4 now asserts, via exact regprocedure pins, the full posture of `admin_lookup_school(uuid)` / `admin_lookup_class(uuid,uuid)` / `admin_lookup_session(uuid,uuid)` — existence, owner `postgres`, secdef, `proconfig=ARRAY['search_path=""']`, exact ACL `authenticated,postgres,service_role`, no PUBLIC, no anon. Executed live → no exception.
- **Blocker 2 (P14 assignment scope):** §14 uses `scope='assignment'` with valid zero-context, proving assignment → status gate → scope gate → dispatch → `dispatch_missing` fail-closed; `rows_in_txn=18`, terminal rollback, post-rollback total 17, probe residue 0. Executed live → PASS.
- **BLOCK-3 verifier NULL-safe-corrected (v8):** every BLOCK-3 assertion is fail-closed (`IS DISTINCT FROM` / `COALESCE` / explicit `IS NULL` + `NOT FOUND` guards); proven both directions live this session — A–P PASS on correct simulated POST (`SIM_STRUCT_VERIFY_PASS`), NC1–NC4 fail-closed on NULL. BLOCK-1/BLOCK-2 business SQL byte-identical to v6/v5/v4 (`3938d3c…`); new migration SHA-256 `77879867…` (14,722 B); BLOCK-3-only machine-diff §10.
- **All prior v6 fixes retained:** literal self-contained drift gate · NULL-safe PRE/POST/P1–P14 · frozen PRE golden · auto PRE→POST comparison · deterministic ACL · exact registry membership · exact PROGRAM pre-state guard · synthetic-probe-only · §16 negative control · zero residue.

Every required literal artifact is present, self-contained, and runtime-verified live this session (rollback-safe, zero production mutation): §4 drift gate (+siblings) · §5 resolver · §6 golden · §7 PRE · §8 PRE residue · §9 migration (byte-identical) · §11 post-commit ACL/inventory · §12 POST · §13 P1–P13 · §14 P14 (assignment) · §15 residue · §16 negative control · §16b NC1–NC4 · §9 BLOCK-3 corrected A–P simulated-POST · §17 verify-the-verify.

# PACKAGE v8 READY FOR CTO FINAL COMPLETENESS AUDIT

**HARD STOP.** No migration applied. No APPLY authorization assumed or requested. No production mutation. No migration business-logic change. No D356 canonicalization. No HANDOFF B3.3. No B3.4. PROGRAM architecture unchanged.

**Only next action:** Owner forwards Package v8 to ChatGPT/Work for the final exact-artifact audit. After — and only after — CTO returns `FINAL IMPLEMENTATION PASS`, Owner may separately issue `AUTHORIZED — APPLY V128-B3.3` as a one-shot production authorization; only then is `apply_migration` (§9) + post-commit verification (§11/§12/§13/§14/§15) executed in the §22 order.
