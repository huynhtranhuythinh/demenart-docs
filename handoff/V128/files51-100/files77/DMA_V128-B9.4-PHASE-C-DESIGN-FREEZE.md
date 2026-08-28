# V128-B9.4 — AUTHORITY RESOLVER CONSUMPTION FOUNDATION
# PHASE-C DESIGN FREEZE (Authority-Gate + class.edit governed path)

**Mode:** DESIGN FREEZE ONLY · consolidated A/B/C consumption design.
**Implementation:** 0 · **Migration:** 0 · **SQL executed:** 0 · **DB mutation:** 0 · **FE/UI:** 0 · **Canonical append:** 0 · **Invariant minted:** 0.
**Date:** 2026-08-16
**Status:** Design frozen. Ready for implementation authorization. **Next milestone (V128-B9.4 IMPLEMENTATION · Migration A) requires a separate explicit APPLY command.**

---

## STEP 0 — CANONICAL BOOT + LIVE PREMISE RE-PIN (zero drift)

Read directly from canonical (not memory). Endpoint verified:

| Check | Required | Live | Status |
|---|---|---|---|
| `DMA_RULES.md` endpoint | D367 | D367 (B9.3 reconciliation block) | ✓ |
| `DMA_SYSTEM_MAP.md` endpoint | v1.55 | v1.55 | ✓ |
| B9.3 reconciliation record | D367 / v1.55 | canonical (handoff file absent on disk; D363 → RULES is authority source) | ✓ |
| Backend tail | `20260815201925` | `20260815201925` | ✓ |
| FE main pin | `2.8.5` | `2.8.5` | ✓ |

**Live premise re-pin (design rests on these — confirmed at freeze time, read-only, 0 DML):**

| Premise the design depends on | Live evidence |
|---|---|
| Executor is the untouched B9.3 baseline (G1 seam premise) | `execute_mission_control_action` md5 **`09ef5f48f3318bfb53e126f3bc81d40a`** — UNCHANGED |
| Transition controller untouched | `_mc_transition_decision` md5 **`fe0eea599db711fb8472b37a72fa25e4`** — UNCHANGED |
| Resolver is a locked read-only primitive | `_resolve_authority` = DEFINER · STABLE · ACL **{postgres} only** |
| Resolver consumed only by the probe harness today | caller-set = **`{public.execute_authority_probe}`** |
| `authority_gated` flag not yet present (Mig-A premise) | column **absent** on `mission_control_action_registry` |
| First action is dark; live action unchanged | `class.edit` = **disabled** · `class.assign` = **active** |
| Decision lifecycle dormant (LOW path never opens a decision) | `mission_control_decisions` 0 · `mission_control_decision_transitions` 0 |

No drift → freeze is valid against current live state.

---

## LINEAGE

| Milestone | Outcome |
|---|---|
| **B9.1** | Authority Resolver Contract — Design Freeze (conceptual; capability=PRIMARY input; single-source *verdict*; Strangler 4-phase; Identity Option A). |
| **B9.2** | Foundation Contract Ratification (D366 / v1.54; vocabulary DRAFT-only, no enum mint). |
| **B9.3** | Authority Resolver Skeleton Reconcile (D367 / v1.55; `_resolve_authority` live, probe-isolated, 8/8 matrix, zero legacy touch). |
| **B9.4 / A** | Consumption boundary approved: **executor seam**; first action **class.edit**; gate pattern **O1**. |
| **B9.4 / B** | Containment **G1**; deny semantics (structured error, zero mutation, zero ledger); self-decision → resolver-tier only. |
| **B9.4 / C** | This freeze: full gate contract + executor transition + adapter contract + verify matrix + migration decomposition; **D1 = OPTION A**. |

---

## APPROVED DECISIONS (A + B + C, consolidated)

1. **OD-01 Consumption boundary = executor seam** (Candidate A). Verdict consumed after object-context resolution, before mutation. Candidate B (decision lifecycle) deferred to Strangler Phase-2; Candidate C (both) is the eventual end-state, not Phase-1.
2. **OD-02 First governed action = `class.edit`.** Currently disabled, no production mutation path, reuses proven `class` + `school_id` object context, simple rollback, clear audit event `CLASS_UPDATED`. Explicitly NOT `class.assign` (live path → Strangler Phase-3), NOT `child.transfer`.
3. **OD-03 Consumption pattern = O1 (DEFINER authority-gate boundary).** Resolver ACL stays {postgres}; the gate (DEFINER) is the only new caller. Do NOT grant resolver to `authenticated`; do NOT embed authority in the adapter; do NOT duplicate resolver policy in the executor.
4. **Containment = G1** (additive branch inside the existing executor). No duplicated executor, no full router refactor, no `class.assign` rewrite.
5. **Deny semantics** = authority-denied → structured rejection (`MC_ACTION_PERMISSION_DENIED` + `reason_codes`) → zero mutation → zero action-ledger commit. Gate placed **before** `_mc_begin_action`.
6. **Self-decision** (`self_decision_forbidden`) = verified at resolver tier only (synthetic `decision_context`); reserved for Phase-2 decision-lifecycle adoption. NOT claimed as class.edit integration coverage (LOW direct-execute has no approval phase).
7. **D1 Idempotency fingerprint = OPTION A.** `_mc_begin_action` untouched; class.edit passes `program_id=NULL, lead_teacher_id=NULL`. `request_id` uniqueness is the idempotency key. Payload-aware fingerprinting deferred (revisit at 2nd edit-family action).

---

## PART 1 — AUTHORITY-GATE CONTRACT

```
mc_internal._mc_authority_gate(
    p_actor_id        uuid,   -- = public.current_profile() (profiles.id, D88)
    p_action_key      text,   -- PRIMARY authority anchor (B9.1 Part 2)
    p_object_context  jsonb,  -- resolved+validated, e.g. { "school_id": <uuid> }
    p_decision_context jsonb  -- NULL for direct-execute; present only on decision paths
)  RETURNS jsonb              -- { eligible, authority_source, reason_codes }
```

| Property | Specification |
|---|---|
| Security | `SECURITY DEFINER`, `STABLE`, `SET search_path = ''` |
| ACL | `REVOKE ALL FROM PUBLIC, anon, authenticated` (D231) → `GRANT EXECUTE TO authenticated` (mirrors the probe; the INVOKER executor runs as `authenticated` and must reach the gate) |
| Body | Calls `mc_internal._resolve_authority(actor, action_key, object_context, decision_context)` and **passes the verdict through**. No independent policy, no role/school logic, no side effects. |
| Ownership | Gate owns: **invocation** of the resolver · **mutation-ordering protection** (verdict obtained before any write). Gate does NOT own the verdict (resolver) or the mutation (adapter). |
| Deny handling | Gate **returns** the verdict. The **executor** translates `eligible=false` into `MC_ACTION_PERMISSION_DENIED` and surfaces `reason_codes`. The gate does not raise. |
| Resolver impact | `_resolve_authority` body and ACL **unchanged**. Resolver caller-set becomes `{execute_authority_probe, _mc_authority_gate}` (+1). |

---

## PART 2 — EXECUTOR TRANSITION SPEC (G1, additive)

Single public entry `public.execute_mission_control_action(p_action_key, p_object_id, p_context, p_input, p_request_id)` (INVOKER, `search_path=''`) remains the sole dispatch point. G1 inserts additive branches; the `class.assign` executed code-path stays logically identical.

| Stage | Current (class.assign only) | Target (G1) |
|---|---|---|
| actor | `v_actor_id := current_profile()` | unchanged |
| registry lookup | `_mc_lookup_action('class', action_key)` | `_mc_lookup_action` **MODIFIED** to surface `authority_gated` into the returned `action` json |
| context validation | inline required_context (keys / exclusive / uuid) + school parse | unchanged (shared) |
| input parse | hard-parse `program_id` (mandatory) + `lead_teacher_id` (assign-shaped) | **branch by adapter_key**: `class.assign.v1` → parse program/lead; `class.edit.v1` → parse edit payload (no program/lead) |
| object resolve | `select school_id from public.classes where id = object_id`; context-school match | unchanged (shared) |
| **AUTHORITY GATE** | — | **NEW**: `if (v_action->>'authority_gated')::bool then v := _mc_authority_gate(v_actor_id, action_key, jsonb_build_object('school_id', v_school_id), NULL); if not (v->>'eligible')::bool then return MC_ACTION_PERMISSION_DENIED + reason_codes;` — placed **before** `_mc_begin_action` (zero ledger, zero mutation on deny) |
| begin (idempotency) | `_mc_begin_action(..., program_id, lead_teacher_id)` | class.edit path passes `program_id=NULL, lead_teacher_id=NULL` (D1=A) |
| risk route | HIGH/CRITICAL → `_mc_open_decision`; else direct-execute | unchanged (class.edit is LOW → direct-execute; never opens a decision) |
| adapter dispatch | `case adapter_key when 'class.assign.v1' then assign_class_distribution(...)` | + `when 'class.edit.v1' then public.class_edit_v1(object_id, p_input)` |
| audit / result | `CLASS_ASSIGNMENT_CREATED` / `class_distribution_id` | + edit arm: `CLASS_UPDATED` / `{ class_id, changed_fields }` |
| commit | `_mc_commit_action(request_id, result)` | unchanged (shared) |

**Preserved (must not regress):** `class.assign` runtime behavior (`authority_gated=false` ⇒ gate branch never entered); decision lifecycle; resolver contract; probe harness. Executor **md5 will change** (from `09ef5f48…`) — this is expected and explicitly authorized at Phase-1 consumption; the legacy-isolation claim of D367.4 shifts and must be stated honestly at implementation closeout.

---

## PART 3 — class.edit.v1 ADAPTER CONTRACT

```
public.class_edit_v1(p_class_id uuid, p_input jsonb) RETURNS jsonb   -- { class_id, changed_fields }
    SECURITY DEFINER · VOLATILE · SET search_path = ''
    REVOKE ALL FROM PUBLIC, anon, authenticated → GRANT EXECUTE TO authenticated   (D15 / D231)
```

| Concern | Specification |
|---|---|
| Editable (whitelist) | `name` (text, non-empty), `age_group_id` (uuid \| null), `level_id` (uuid \| null) |
| Forbidden (reject) | `id`, `school_id` (tenancy anchor), `state` (lifecycle → `class.archive`, not edit), `created_at`, `updated_at`, and any unknown key → `MC_ACTION_INPUT_INVALID` |
| Domain-safety (KEEP — defense-in-depth) | class exists (`class_not_found`); at least one editable field present (`no_editable_fields`); FK validity of `age_group_id` / `level_id` when supplied; sets `updated_at = now()` |
| Authority (DROP) | **No** `not_authorized_for_school`, no role check, no school-scope check. Authority is owned by the gate/resolver. This is the deliberate contrast with the legacy `assign_class_distribution`, which still embeds `is_admin() OR (role IN (master/sub) AND school ∈ user_school_ids)` (Strangler Phase-3 target). class.edit is born at the end-state adapter shape. |
| Mutation | `UPDATE public.classes SET <whitelisted fields> WHERE id = p_class_id` |
| Audit | `public.write_audit_log('CLASS_UPDATED', jsonb_build_object('actor_id', current_profile(), 'entity_type','class', 'entity_id', p_class_id, 'school_id', <resolved>, 'metadata', jsonb_build_object('changed_fields', <keys>, 'kind','edit')))` — transactionally bound to the mutation (D88: actor = `profiles.id`) |

---

## PART 4 — VERIFY MATRIX SPECIFICATION

**Tier-1 — Resolver primitive (unit; direct `_resolve_authority`; synthetic `decision_context`; 0 write).** Re-confirm the B9.3 8/8, including case 8 (`self_decision_forbidden`).

**Tier-2 — Governed path (integration; real class.edit; executor → gate → `class_edit_v1`).** UUIDs pinned live at execution (never guessed).

| # | Actor (demo) | object_context | Resolver expected | Mutation expected | Audit expected |
|---|---|---|---|---|---|
| 1 | platform `super_admin` (`info@demenart.com`) | `{school: KHM}` | `true / platform_role / authority_granted` | `classes` UPDATE ✓ | `CLASS_UPDATED` ✓ |
| 2 | master KHM (`hieutruong.kidshouse`) | `{school: KHM}` | `true / organization_role / authority_granted` | UPDATE ✓ | ✓ |
| 3 | master KHM | `{school: MNDM}` (cross) | `false / none / organization_scope_mismatch` | **0** | none |
| 4 | lead_teacher KHM (`gv.linh.kidshouse`) | `{school: KHM}` | `false / none / role_not_eligible` | **0** | none |
| 5 | parent KHM (`ph.hung.kidshouse`) | `{school: KHM}` | `false / none / role_not_eligible` | **0** | none |
| 6 | master KHM | `{}` (missing school) | `false / none / object_context_mismatch` | **0** | none |
| 7 | unknown uuid | `{school: KHM}` | `false / none / actor_unresolved` | **0** | none |
| +A | master KHM (happy path) | `{school: KHM}` | granted | **real row change** (name before ≠ after) | `audit_logs` +1 |
| +B | lead_teacher (deny path) | `{school: KHM}` | role_not_eligible | **`classes` row-hash invariant** | `audit_logs` +0 |
| 8 | self-approval (synthetic dc) | — | `false / none / self_decision_forbidden` | **N/A** (direct-execute) | **N/A** — reserved Phase-2 |

School KHM = `d1…0001` (KHM-DN); cross-tenant = MNDM-DN. Demo password `Test@123`.

**Case 8 disposition (honest):** not reachable in class.edit LOW direct-execute (no approval phase, `decision_context=NULL`); asserted only at Tier-1. No integration-coverage claim.

---

## PART 5 — MIGRATION DECOMPOSITION (NO APPLY)

Three phase-gated migrations, each following the D92 three-block pattern (DDL → REVOKE/GRANT → VERIFY inside one atomic `apply_migration`), each independently rollback-able. D289: `NOTIFY pgrst, 'reload schema'` after any function/policy/registry change.

### Migration A — schema preparation (inert)
- `ALTER TABLE public.mission_control_action_registry ADD COLUMN authority_gated boolean NOT NULL DEFAULT false;` → `class.assign` auto = `false`.
- **Affected:** registry table only. **Rollback:** `DROP COLUMN authority_gated`. **Verify:** column exists · `class.assign` flag = false · `class.edit` still disabled · **no behavioral change (inert)**.

### Migration B — gate + adapter functions (dormant)
- **NEW** `mc_internal._mc_authority_gate(...)` (Part 1).
- **NEW** `public.class_edit_v1(...)` (Part 3).
- **MODIFY** `mc_internal._mc_lookup_action(...)` to surface `authority_gated`.
- **MODIFY** `public.execute_mission_control_action(...)` (Part 2 G1 branches).
- Each `CREATE OR REPLACE` re-applies REVOKE/GRANT (D15 grant-reset guard).
- **Affected:** 2 new + 2 modified functions. **Rollback:** DROP the 2 new; restore the 2 modified to prior md5 (executor → `09ef5f48…`, lookup → prior). **Verify:** Tier-1 8/8 (direct resolver) · **class.assign regression green** (happy + replay == baseline) · resolver caller-set = `{execute_authority_probe, _mc_authority_gate}` · **class.edit still disabled ⇒ whole path dormant**.

### Migration C — activation
- `UPDATE public.mission_control_action_registry SET status='active', adapter_key='class.edit.v1', execution_mode='single_domain_rpc', required_context='{"keys":["school_id"],"types":{"school_id":"uuid"},"exclusive":true}'::jsonb, input_schema='{"version":"MissionActionInputSchema/v1","fields":[{"key":"name","required":false},{"key":"age_group_id","required":false},{"key":"level_id","required":false}]}'::jsonb, authority_gated=true, disabled_reason=NULL WHERE action_key='class.edit';`
- **Affected:** 1 registry row. **Rollback:** revert row → disabled / null / `authority_gated=false`. **Verify:** Tier-2 full matrix (1–7 + A/B) · class.assign still green.

**Rollback boundary (whole feature):** disable class.edit → flag=false → DROP `class_edit_v1` → DROP `_mc_authority_gate` → restore `_mc_lookup_action` + executor md5 `09ef5f48…` → (optional) DROP `authority_gated` column. Clean; `class.assign` untouched throughout.

---

## PART 6 — INVARIANTS PRESERVED (explicit untouched set)

- `mc_internal._resolve_authority` — **body + ACL unchanged**; caller-set gains `_mc_authority_gate` only.
- Decision lifecycle — `_mc_open_decision`, `_mc_transition_decision`, `resolve_mission_control_decision`, `cancel_mission_control_decision`, `get_mission_control_decision_inbox` — untouched (class.edit is LOW; no decision opened).
- `class.assign` runtime behavior — logically unchanged (`authority_gated=false`).
- `child.transfer` and all other production actions — untouched.
- Probe harness — `execute_authority_probe`, `mc_internal.authority_probe_log` — untouched.
- Vocabulary — no pg-enum / taxonomy mint (continues D366.6 / D367.6; controlled-text only).

---

## LIVE-STATE SNAPSHOT AT FREEZE (evidence, read-only)

Backend tail `20260815201925`. Executor md5 `09ef5f48f3318bfb53e126f3bc81d40a` (unchanged). Transition controller md5 `fe0eea599db711fb8472b37a72fa25e4` (unchanged). Resolver DEFINER · STABLE · ACL {postgres}; caller-set `{execute_authority_probe}`. `authority_gated` column absent. Action registry: `class.assign` MEDIUM active (`class.assign.v1`), `authority.probe` LOW active (`authority.probe.v1`), `class.edit` LOW **disabled**. `classes` editable columns = {name, age_group_id, level_id}. Decisions 0 · transitions 0 · action_requests 12 · authority_probe_log 1. FE main pin `2.8.5`.

---

## STRICT STOP

No implementation, SQL, migration, DB mutation, FE, or canonical append was performed to produce this freeze. Design is frozen against confirmed live state.

**Next milestone — `V128-B9.4 IMPLEMENTATION · Migration A` — requires a separate explicit APPLY command.** Standing discipline: hard STOP at this boundary; each migration (A → B → C) is authorized and verified independently.
