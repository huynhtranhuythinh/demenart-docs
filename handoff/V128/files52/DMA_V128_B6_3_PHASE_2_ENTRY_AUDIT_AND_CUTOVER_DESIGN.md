# V128-B6.3 — PHASE 2 ENTRY AUDIT & CUTOVER DESIGN

> **Mode:** READ-ONLY ENTRY AUDIT + CUTOVER DESIGN ONLY. **Không:** SQL/migration apply · DB mutation · code/FE edit · commit · canonical append · intent_fingerprint · Phase 3.
> **Ngày:** 2026-08-15 (GMT+7).

---

## 1. CANONICAL STATE
RULES **D361** · SYSTEM_MAP **v1.49** · HANDOFF **V128-B6.3-PHASE-1** · Phase 1 CLOSED · B6.3 NOT CLOSED · G1 PARTIAL / G2 OPEN / G3 OPEN / G4 CLOSED · tail `20260815080313`. Endpoint khớp — không STOP.

## 2. LIVE RE-PIN (D1) — **PASS, ZERO DRIFT**
Inventory `92·248·236·168·33·1` · mc_internal `2 fn / 2 secdef` · tail `20260815080313`. Registry: class.assign (active, adapter_key `class.assign.v1`, exec_mode `single_domain_rpc`, required_context+input_schema v1, label 'Assign Teacher') · class.edit (disabled, adapter_key NULL). `_mc_lookup_action` verdict 3-way + 8-field whitelist intact. `get_available_actions` predicate dispatchable-only, ACL `{postgres,service_role}`. Ledger: no `intent_fingerprint`, authenticated terminal UPDATE=0, 12 cols. execute ACL `{authenticated,postgres}`.

## 3. FROZEN PHASE 1 BASELINE (byte-exact, rollback anchor)
| Object | md5 | Posture |
|---|---|---|
| `execute_mission_control_action` | `771470473d17c31a247999a51e499094` | INVOKER · `search_path=''` · ACL {authenticated,postgres} — **WILL CHANGE (cutover)** |
| `get_mission_control_actions` | `e4fdd0138e27f40eb9c76aa4f4b6ab65` | DEFINER · ACL {authenticated,postgres} — **WILL CHANGE (reconcile)** |
| `assign_class_distribution` | `03a1510bd827c03a650a3a88312fbe3a` | DEFINER — **FREEZE** |
| `mc_internal._mc_commit_action` | `ce36c5fe109e99a919158a4482940c6a` | DEFINER completed-only — **FREEZE** |
| `mc_internal._mc_lookup_action` | `5d940037687be0a398a232cf987bfcf6` | DEFINER · ACL {authenticated,postgres} — **FREEZE** |
| `get_available_actions` | `fd874243a90e20d171058f3ddb648356` | DEFINER · dispatchable-only · ACL {postgres,service_role} — **FREEZE** |
| ledger `mission_control_action_requests` | — | no fingerprint · 0 auth terminal UPDATE — **FREEZE** |

## 4. CURRENT LITERAL EXECUTE PIPELINE (frozen body — gate precedence matters)
| # | Gate | Error | Note |
|---|---|---|---|
| 1 | `auth.uid()` null | `MC_ACTION_PERMISSION_DENIED` | |
| 2 | `current_profile()` null | `MC_ACTION_PERMISSION_DENIED` | |
| 3 | **`action_key <> 'class.assign'`** | `MC_ACTION_NOT_FOUND` | **literal dispatch — fires BEFORE object/context/input** |
| 4 | object_id ∨ request_id null | `MC_ACTION_INPUT_INVALID` | |
| 5 | context not-object ∨ missing school_id ∨ extra key ∨ school_id not-uuid | `MC_ACTION_CONTEXT_DENIED` | |
| 6 | input not-object ∨ missing program_id ∨ extra key ∨ not-uuid ∨ program_id null | `MC_ACTION_INPUT_INVALID` | |
| 7 | class→school lookup null | `MC_ACTION_OBJECT_NOT_FOUND` | |
| 8 | context.school_id ≠ class.school_id | `MC_ACTION_CONTEXT_DENIED` | |
| — | INSERT processing ON CONFLICT DO NOTHING → adapter → commit-core | β2 subtransaction | |
| — | replay/conflict branch: structural triple (action_key+object_type+object_id) | REQUEST_CONFLICT / IN_PROGRESS / stored replay | |

**⭐ Precedence invariant:** gate 3 (action) fires BEFORE 4/5/6. ⇒ `class.edit`/unknown → `MC_ACTION_NOT_FOUND` **regardless** of object/context/input validity. Phase 2 must preserve this exact position.

## 5. TARGET REGISTRY-DRIVEN PIPELINE
```
1  auth.uid gate                                   → MC_ACTION_PERMISSION_DENIED
2  current_profile gate                            → MC_ACTION_PERMISSION_DENIED
3  v := mc_internal._mc_lookup_action('class', p_action_key)   [object_type constant 'class']
4  verdict:
      found=false                → MC_ACTION_NOT_FOUND
      found=true, dispatchable=false → MC_ACTION_NOT_FOUND   ← NOT MC_ACTION_DISABLED (freeze contract)
      found=true, dispatchable=true  → proceed with v.action
5  object_id ∨ request_id null                     → MC_ACTION_INPUT_INVALID
6  context validation ⟵ v.action.required_context  → MC_ACTION_CONTEXT_DENIED
7  input validation   ⟵ v.action.input_schema      → MC_ACTION_INPUT_INVALID
8  class→school lookup + context.school_id match    → OBJECT_NOT_FOUND / CONTEXT_DENIED
9  INSERT processing ON CONFLICT / replay branch    [UNCHANGED structural triple]
10 static adapter resolver: CASE v.action.adapter_key
      'class.assign.v1' → assign_class_distribution(object_id, program_id, lead_teacher_id)
      ELSE → fail-closed (MC_ACTION_EXECUTION_FAILED, currently unreachable)
11 adapter exception map                            [UNCHANGED]
12 mc_internal._mc_commit_action                    [UNCHANGED]
```
**object_type = constant `'class'`** (execute stays class-implicit exactly as today; generalizing object_type = future milestone, NOT B6.3). Equivalence: `lookup('class', k)` returns not-found for every non-class/unknown key → `MC_ACTION_NOT_FOUND`, byte-identical to literal gate 3.

## 6. DECLARATIVE VALIDATION CONTRACT (bounded interpreter for v1 — NOT generic JSON-Schema)
**CONTEXT** (from `required_context={"keys":["school_id"],"exclusive":true}`):
- `jsonb_typeof(p_context)='object'` else `CONTEXT_DENIED`
- contains every key in `.keys` else `CONTEXT_DENIED`
- if `.exclusive=true`: no key ∉ `.keys` else `CONTEXT_DENIED`
- cast each context key to its declared type (school_id→uuid); cast failure → `CONTEXT_DENIED`
  - **Gap:** current `required_context` không khai `value_type` cho school_id (literal hardcode uuid cast). **Micro-decision (§14 R2):** (a) enrich `required_context` → `{"keys":["school_id"],"exclusive":true,"types":{"school_id":"uuid"}}` (registry data update trong Phase 2 migration → validator fully declarative) ★ hoặc (b) bounded validator giữ school_id→uuid rule cho class-context. Đề xuất (a).

**INPUT** (from `input_schema` v1 fields):
- `jsonb_typeof(p_input)='object'` else `INPUT_INVALID`
- required field (program_id) present + non-empty else `INPUT_INVALID`
- no key ∉ declared fields {program_id, lead_teacher_id} else `INPUT_INVALID`
- cast each present field per `value_type=uuid`; failure → `INPUT_INVALID`
- optional+nullable (lead_teacher_id) may be absent/null
- program_id null after cast → `INPUT_INVALID`

**Constraint:** validator KHÔNG được permissive hơn literal. Equivalence bar = §10. input_schema v1 đã đủ declarative cho INPUT; CONTEXT cần micro-decision (a).

## 7. STATIC ADAPTER RESOLVER (CTO-locked: no dynamic SQL / no EXECUTE format / no name-from-registry)
```
CASE v.action.adapter_key
  WHEN 'class.assign.v1' THEN
    v_dist := public.assign_class_distribution(p_object_id, v_program_id, v_lead_teacher_id);
  ELSE
    -- fail-closed; unreachable with current data (only class.assign.v1 dispatchable)
    raise 'adapter_unresolved';  → map MC_ACTION_EXECUTION_FAILED
END CASE;
```
- **Placement (§11 decision):** ★ **inside execute (static CASE), INVOKER** — no new function, no new ACL surface, single-function rollback. Authority centralized in `_mc_lookup_action` (helper); dispatch = CASE. Separate resolver helper (Option B) adds surface without benefit at current scale.
- **Unknown adapter_key:** ★ `MC_ACTION_EXECUTION_FAILED` (server-side resolution gap, fail-closed) — currently unreachable, so equivalence-neutral. Alt: NOT_FOUND. Micro-decision.

## 8. REPLAY / LEDGER FREEZE (§7 brief)
Preserve EXACTLY: INSERT processing `ON CONFLICT(request_id) DO NOTHING` · replay/conflict branch comparing **structural triple only** (action_key+object_type+object_id) · in-progress → `MC_ACTION_REQUEST_IN_PROGRESS` · completed → stored replay (`replayed=true`) · adapter conflict → β2 rollback-only (no orphan/no failed persist). **NO intent comparison. NO fingerprint. NO lifecycle change.** Ledger schema/policies/grants untouched.

## 9. FE-FACING DISCOVERY RECONCILIATION (get_mission_control_actions, under E12)
Current: gate on `get_available_actions`(class.assign present) → hardcoded descriptor + dynamic options.
**Target — authority/presentation split (★ Option B):**
- **From registry** (authority/structure): `action_key`, `risk_level`, `input_schema` field STRUCTURE (key/control/required/nullable/value_type).
- **Server presentation (kept server-side, NOT registry):** action `label` ('Assign Program'), `description` ('Create a class-program distribution'), per-field labels ('Program'/'Lead teacher'), and **dynamic options** (programs/teachers, hydrated + ordered).
- **Label divergence resolution:** registry label 'Assign Teacher' **stays DEAD** (presentation is server-owned). ⇒ **byte-equivalent FE with ZERO registry data mutation, ZERO label in `_mc_lookup_action` whitelist (A9 unchanged).**
- **Why B over A:** registry = authority (what/structure/risk); server = presentation (labels/desc/options, locale/UX-dependent). A (align registry label + add label to whitelist) mixes authority+presentation, expands A9 surface, mutates data — worse. Micro-decision but strongly ★ B.
- Preserve: 1 item, key class.assign, description, v1 version, field structure+labels, program/teacher options **+ order**, item envelope.
- **md5 WILL change** (no longer frozen at `e4fdd013…`); equivalence = E12 functional, not md5.

## 10. BYTE-EQUIVALENCE DEFINITION
- **execute:** equivalence = **semantic jsonb equality** on the return envelope (`ok, replayed, request_id, action_key, object_type, object_id, result, audit, error.code`) + identical side-effects (ledger row state, distribution, audit) + identical ledger terminal state. Rationale: return is `jsonb` (key-order non-semantic in PG) and FE `parseExecuteResult` reads **by key**, not position. Semantic jsonb `=` is the meaningful contract.
- **get_mission_control_actions:** semantic jsonb equality **with array order preserved** for `items`, `fields`, and `options` (FE `parseClassActions` iterates in order; Select renders option array order). So: item count=1, key, label, description, risk_level, schema version, field order + per-field labels/controls/required, option values **+ order**.

## 11. MIGRATION DESIGN (DESIGN ONLY)
**Touched:**
- CREATE OR REPLACE `public.execute_mission_control_action` (registry-driven pipeline §5 + declarative validators §6 + static resolver §7). md5 changes.
- CREATE OR REPLACE `public.get_mission_control_actions` (authority/presentation split §9). md5 changes.
- *(Micro-decision a)* UPDATE registry `class.assign.required_context` += `types` (small data enrich) — if chosen.
- BLOCK 2 re-harden: execute ACL `{authenticated,postgres}`; get_mc_actions ACL `{authenticated,postgres}` (D15, proacl reset on replace).
- BLOCK 3 VERIFY: frozen md5 (commit/adapter/lookup/gaa) unchanged; ledger unchanged; registry authority intact; equivalence smoke.
**Untouched:** `assign_class_distribution`, `_mc_commit_action`, `_mc_lookup_action`, `get_available_actions`, ledger, registry structure.
**Resolver placement:** inside execute (no new function).

## 12. EXPECTED STRUCTURAL DELTA
Tables 0 · functions **net 0** (2 REPLACE) · secdef 0 · policies 0 · triggers 0 · cron 0. **Public inventory BẤT BIẾN `92·248·236·168·33·1`**; mc_internal {2/2} unchanged. Optional registry data update (required_context enrich). Migration tail advances once. FE/Edge/Bunny 0.

## 13. ACCEPTANCE CRITERIA P2-A1…A20
| # | Criterion | Verify |
|---|---|---|
| P2-A1 | execute public signature unchanged | `pg_get_function_arguments` identical |
| P2-A2 | execute remains SECURITY INVOKER | `prosecdef=false` |
| P2-A3 | registry drives executable action selection | execute references `_mc_lookup_action`; no literal `class.assign` gate |
| P2-A4 | static allowlist only, no dynamic SQL | body has no `EXECUTE format`; CASE only |
| P2-A5 | class.assign success equivalent | E1 semantic-jsonb equal + side-effects |
| P2-A6 | class.edit still `MC_ACTION_NOT_FOUND` | E5/E11 (verdict disabled→NOT_FOUND) |
| P2-A7 | unknown action still `MC_ACTION_NOT_FOUND` | E5 |
| P2-A8 | context validation equivalent | E3/E3b full matrix |
| P2-A9 | input validation equivalent | E4 full matrix |
| P2-A10 | adapter exception mapping equivalent | E2b/E9 |
| P2-A11 | replay/in-progress unchanged | E7/E8 |
| P2-A12 | rollback-only conflict unchanged | E9 |
| P2-A13 | ledger unchanged | structural re-pin |
| P2-A14 | commit-core md5 unchanged | `ce36c5fe…` |
| P2-A15 | adapter md5 unchanged | `03a1510b…` |
| P2-A16 | get_mc_actions FE equivalence PASS | E12 semantic+order |
| P2-A17 | registry client-inaccessible | grants `{service_role:SELECT}`, RLS ON |
| P2-A18 | `_mc_lookup_action` A9 whitelist intact | md5 `5d940037…` + 8-field |
| P2-A19 | 0 intent_fingerprint | ledger col absent |
| P2-A20 | 0 FE/code change | none |

## 14. E1–E12 EQUIVALENCE BASELINE CAPTURE PLAN (run at Phase 2 apply, BEFORE cutover, then re-run after)
Method: JWT-impersonation real-login (D2/D360), `BEGIN…ROLLBACK` per side-effecting case (no persistent QA data). Fixture: class `eeeeeeee-…0005` @ school `b6a4ac35`, actor master.demo (`2fee5a07…`, jwt sub `5396961a…`). Fresh-success needs an unassigned (class,program) pair prepared in-tx.

| Case | Input / precondition | Expected code | Δ ledger/dist/audit |
|---|---|---|---|
| E1 Success | valid class.assign, fresh | ok:true | +1/+1/+1 (then ROLLBACK) |
| E2 Perm — no auth | auth.uid null | PERMISSION_DENIED | 0 |
| E2b Perm — adapter | actor sans school right | PERMISSION_DENIED (adapter `not_authorized_for_school`) | 0, β2 |
| E3 Context bad | non-obj / extra key / school_id not-uuid | CONTEXT_DENIED | 0 |
| E3b Context mismatch | context.school_id ≠ class.school_id | CONTEXT_DENIED | 0 |
| E4 Input invalid | missing program_id / bad uuid / extra key / nullable teacher behavior | INPUT_INVALID | 0 |
| E5 Not found | unknown key **and** class.edit (disabled) | NOT_FOUND (both) | 0 |
| E6 Object not found | bogus object_id | OBJECT_NOT_FOUND | 0 |
| E7 Replay | same request_id, same intent | ok:true, replayed:true | Δ=0 |
| E8 In progress | request still processing | REQUEST_IN_PROGRESS | 0 |
| E9 Conflict | new request_id, existing distribution | MC_ACTION_CONFLICT | 0, β2 rollback-only |
| E10 Audit | E1 success | — | audit CLASS_ASSIGNMENT_CREATED |
| E11 Non-dispatchable row | class.edit registry row | get_available_actions no-advertise · get_mc_actions no-emit · execute NOT_FOUND | 0 |
| E12 FE projection | get_mission_control_actions(fixture) before/after | semantic+order equal: 1 item class.assign, label 'Assign Program', v1, dynamic options | — |

**Baseline capture BEFORE execute replace; re-run AFTER; diff must be empty (semantic per §10).**

## 15. ROLLBACK PLAN
- Restore `execute` → Phase 1 md5 `771470473d17c31a247999a51e499094` + re-harden ACL `{authenticated,postgres}`.
- Restore `get_mission_control_actions` → Phase 1 md5 `e4fdd0138e27f40eb9c76aa4f4b6ab65` + re-harden ACL `{authenticated,postgres}`.
- Revert registry `required_context` enrich if applied.
- Drop any Phase 2-only helper (none if resolver = CASE-in-execute).
- **No** ledger/adapter/commit repair; **no** Phase 1 column rollback. `NOTIFY pgrst`.

## 16. RISKS
- **R1 Gate-order drift → error precedence.** Mitigate: pipeline §5 preserves exact order (lookup at gate-3 position; validators at 6/7); E-matrix asserts precedence (e.g. class.edit + null object → NOT_FOUND).
- **R2 Validator more permissive.** Mitigate: bounded v1 interpreter, no generic engine; required_context type gap → enrich (§6a); E3/E4 full matrix incl bad-cast/extra-key.
- **R3 Unknown adapter_key fail-open.** Mitigate: CASE ELSE fail-closed → EXECUTION_FAILED; VERIFY asserts no path executes without allowlist match.
- **R4 Disabled row leaks existence via new error.** Mitigate: both not-found & disabled → `MC_ACTION_NOT_FOUND` → class.edit indistinguishable from absent (identical to today). No DISABLED code introduced.
- **R5 FE label/schema drift.** Mitigate: authority/presentation split (§9); presentation server-owned; E12 semantic+order.
- **R6 Option hydration order.** Mitigate: preserve exact ORDER BY (programs name/id, teachers name/id); E12 asserts option order.
- **R7 CREATE OR REPLACE resets grants.** Mitigate: BLOCK 2 D15 re-REVOKE/GRANT for execute + get_mc_actions; VERIFY ACL.
- **R8 Registry lookup becomes authz substitute.** **MUST NOT.** `_mc_lookup_action` = authority (WHAT can execute), not authz (WHO). Adapter (`assign_class_distribution`) keeps its own `is_admin ∨ role∧school` authz; execute still runs adapter authz. VERIFY: E2b still denies via adapter.
- **R9 Replay semantics change before G3.** Mitigate: §8 freeze; structural triple only; E7/E8/E9 unchanged.
- **R10 Resolver → future dynamic-code temptation.** Mitigate: static CASE doctrine (D350.2) documented; adding action = registry row + reviewed CASE arm, never runtime name execution.

## 17. CTO MICRO-DECISIONS REQUIRED
1. **Resolver placement:** ★ CASE-in-execute (INVOKER) vs separate helper.
2. **Unknown adapter_key error:** ★ `MC_ACTION_EXECUTION_FAILED` (unreachable, fail-closed) vs `MC_ACTION_NOT_FOUND`.
3. **get_mc_actions label:** ★ Option B (server presentation, registry label stays dead, no whitelist change) vs A (align registry label + add to whitelist).
4. **required_context type enrich:** ★ (a) add `types:{school_id:uuid}` (fully declarative validator) vs (b) bounded school_id→uuid rule in validator.
5. **object_type in lookup:** ★ constant `'class'` (execute class-implicit) vs derive from action_key.
6. **get_mc_actions reconcile scope:** ★ reconcile in Phase 2 (per brief, E12) vs defer to Phase 2b.

## 18. RECOMMENDATION
Proceed to Phase 2 as **execute cutover + get_mc_actions authority/presentation reconcile**, closing G1 (execution-side) + G2 (adapter seam), **without** touching G3/ledger/adapter/commit. Resolver = static CASE in execute (INVOKER); authority via frozen `_mc_lookup_action`; validators = bounded v1 interpreter reproducing literal gates in exact precedence; class.edit/unknown → `MC_ACTION_NOT_FOUND` (no DISABLED); FE byte-equivalent via presentation split (registry label stays dead). Gate apply behind full E1–E12 baseline-vs-cutover diff (semantic+order). Rollback = restore two md5s + ACL, no repair.

---

## PHASE 2 DESIGN READY FOR CTO APPROVAL

*(Read-only entry audit + cutover design. No SQL/migration/mutation/code/FE/commit/canonical. Phase 2 APPLY only after CTO review.)*
