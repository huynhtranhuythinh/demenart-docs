# V128-B7 PHASE C — EXECUTION INTEGRATION DESIGN REPORT
**Decision Gate → Execute Pipeline Integration · DESIGN ONLY**

> STATUS: **DESIGN ONLY — WAITING CTO APPROVAL**
> Mode: READ-ONLY AUDIT + DESIGN. No migration applied · no DB mutation · no execute replace · no FE · no canonical append.
> Author role: Builder / Runtime Security Auditor. Gate: ChatGPT (CTO/CPO).

---

## 1. Canonical / live state (STEP 0 re-pin)

**Canonical (files read directly):** RULES **D363** · SYSTEM_MAP **v1.51** · B6.3 **CLOSED** (G1·G2·G3·G4 all closed). *(Note: the `DMA_SYSTEM_MAP.md` snapshot in the project library lags — header v1.32, current-endpoint block D358/v1.46, stale inventory 89·215·204 — but RULES D363 authoritatively pins v1.51. Live audit is authority per D1.)*

**Live re-pin (measured, not remembered):**

| Check | Expected | Live | Verdict |
|---|---|---|---|
| Migration tail | `20260815151633` | `20260815151633` | ✅ |
| Inventory (tables·fns·secdef·policies·triggers·cron) | 93·251·239·168·33·1 | 93·251·239·168·33·1 | ✅ (`policies_all`=170: 2 outside `public`, not in convention) |
| `mc_internal` fns / secdef | 5 / 5 | 5 / 5 | ✅ |
| `mission_control_decisions` rows | 0 | 0 | ✅ |
| `class.assign` | active / MEDIUM / `class.assign.v1` | active / MEDIUM / `class.assign.v1` | ✅ |
| `class.edit` | disabled / LOW / null adapter | disabled / LOW / null | ✅ |
| `execute` md5 | `7a526354c820ab5f767ee7403c6e917d` (INVOKER, sp='') | match, `prosecdef=false`, sp='' | ✅ |
| `_mc_begin_action` md5 | `f47260ef3f06811ac2e83807989b26c7` | match | ✅ |
| `_mc_commit_action` md5 | `ce36c5fe109e99a919158a4482940c6a` | match | ✅ |
| `_mc_lookup_action` md5 | `5d940037687be0a398a232cf987bfcf6` | match | ✅ |

**5 Phase-B decision helpers — all live, SECURITY DEFINER, `search_path=''`:**
- `mc_internal._mc_open_decision(p_request_id uuid)` — ACL `{authenticated, postgres}`
- `mc_internal._mc_expire_decisions()` — ACL `{authenticated, postgres}`
- `public.resolve_mission_control_decision(uuid, text, text)` — ACL `{authenticated, postgres, service_role}`
- `public.cancel_mission_control_decision(uuid, text)` — ACL `{authenticated, postgres, service_role}`
- `public.get_mission_control_decision_inbox()` — ACL `{authenticated, postgres, service_role}`

**Decision table (`public.mission_control_decisions`) — 0 rows, SELECT-only for clients:**
- Cols: `id`, `action_request_id`(FK→ledger.request_id), `intent_fingerprint`(**UNIQUE**), `intent_hash_version`, `action_key`, `object_type`, `object_id`, `risk_level`{LOW,MEDIUM,HIGH,CRITICAL}, `state`{**pending,approved,rejected,expired,cancelled**} default `pending`, `requested_by`, `decided_by`(null), `decision_reason`(null), `expires_at`, `created_at`, `updated_at`.
- Indexes: PK(id) · UNIQUE(intent_fingerprint) · (state,expires_at) · (object_type,object_id).
- RLS **enabled**; single policy `select_own` (SELECT, authenticated, `requested_by IN (my profile ids)`).
- Grants: `authenticated:SELECT` only; `postgres`/`service_role` full. **No client INSERT/UPDATE/DELETE** → decision writes are SECDEF-exclusive.

**Ledger status invariant (verified):** `mission_control_action_requests.status ∈ {received, processing, completed, failed}`. **No `awaiting_decision` status** — G-C locked invariant holds. Terminal check constraint intact (processing ⇒ payload/error/completed_at all NULL). Intent check: `(hash_version NULL ∧ fp NULL) ∨ (hash_version=1 ∧ fp NOT NULL ∧ len=64)`.

**Expiry is lazy, NOT cron-driven.** The only cron job is `purge-drive-trash-nightly`. Decisions transition `pending → expired` only when touched: inside `get_mission_control_decision_inbox()` (calls `_mc_expire_decisions()`) and inline in `resolve`/`cancel` (`state='pending' ∧ now()>expires_at`). **Consequence:** a decision past `expires_at` may still physically read `state='pending'`. The gate must compute **effective expiry** on read.

**STOP condition:** none triggered. Proceed to design.

---

## 2. Current execute pipeline (exact, from live body — not memory)

`public.execute_mission_control_action(p_action_key text, p_object_id uuid, p_context jsonb, p_input jsonb, p_request_id uuid) → jsonb`, **SECURITY INVOKER**, `search_path=''`.

Precedence, exactly as it runs:

1. **auth** — `auth.uid() IS NULL` → `MC_ACTION_PERMISSION_DENIED`.
2. **profile** — `current_profile() IS NULL` → `MC_ACTION_PERMISSION_DENIED`.
3. **registry lookup** — `v_verdict := mc_internal._mc_lookup_action('class', p_action_key)`; not found/dispatchable → `MC_ACTION_NOT_FOUND`. Extracts `v_action`, `v_adapter_key`, `v_required_context`, `v_input_schema`. **`risk_level` is present in the 8-field whitelist but currently NOT read into a variable.**
4. **null guard** — `p_object_id IS NULL OR p_request_id IS NULL` → `MC_ACTION_INPUT_INVALID`.
5. **context validation** — non-object → `CONTEXT_DENIED`; missing required key → `CONTEXT_DENIED`; exclusive extra key → `CONTEXT_DENIED`; non-uuid declared type → `EXECUTION_FAILED` (control-plane guard); `school_id` cast → `CONTEXT_DENIED`.
6. **input validation** — schema version ≠ v1 → `EXECUTION_FAILED`; non-object → `INPUT_INVALID`; undeclared key → `INPUT_INVALID`; missing required → `INPUT_INVALID`; `program_id`/`lead_teacher_id` cast → `INPUT_INVALID`; `program_id` null → `INPUT_INVALID`.
7. **object lookup** — `select school_id from classes where id=object_id`; null → `MC_ACTION_OBJECT_NOT_FOUND` (RLS-filtered; INVOKER ⇒ E2b: out-of-scope class invisible → OBJECT_NOT_FOUND, per D362.7).
8. **context/object match** — `v_context_school_id ≠ v_school_id` → `CONTEXT_DENIED`.
9. **subtransaction** `BEGIN … EXCEPTION`:
   - **`_mc_begin_action(...)`** → `{inserted, intent_hash_version, intent_fingerprint}`; sets `v_fp`, `v_inserted`.
   - **`IF v_inserted`** (fresh): static CASE `WHEN 'class.assign.v1' → assign_class_distribution(...) ELSE raise adapter_unresolved`; build success `v_result`; **`_mc_commit_action(request_id, v_result)`**.
   - **EXCEPTION**: `unique_violation → MC_ACTION_CONFLICT`; `when others` maps domain messages (`not_authorized_for_school→PERMISSION_DENIED`, `distribution_exists→CONFLICT`, `class_not_found→OBJECT_NOT_FOUND`, `subject_not_entitled/lead_teacher_invalid→INPUT_INVALID`, else→`EXECUTION_FAILED`); sets `v_failed`.
10. **`IF v_failed`** → error envelope (with request_id/action_key/object_type/object_id).
11. **`IF NOT v_inserted`** (replay): fetch existing (RLS owner-scoped ⇒ non-owner → not found → `REQUEST_CONFLICT`); structural triple mismatch → `REQUEST_CONFLICT`; `intent_fingerprint NULL` → `REQUEST_CONFLICT`; `hash_version≠1` → `REQUEST_CONFLICT`; **fp mismatch → `REQUEST_CONFLICT`**; `status IN (received,processing)` → `replayed:true` `REQUEST_IN_PROGRESS`; else terminal → stored `result_payload` + `{replayed:true}`.
12. `return v_result`.

**Subtransaction semantics (load-bearing):** the `BEGIN…EXCEPTION` block is a savepoint. A **normal RETURN** inside it *retains* its writes (ledger row, any decision row). A **caught exception** *rolls back* to the savepoint (β2: no orphan processing row).

---

## 3. Exact insertion seam

CTO-locked placement: **after `_mc_begin_action`, before the adapter resolver.** Rationale confirmed by the helper: `_mc_open_decision` reads the ledger row by `request_id` and requires `intent_fingerprint IS NOT NULL` — so the forge (`_mc_begin_action`) must have run first.

**Seam = inside step 9's `IF v_inserted` branch, between `_mc_begin_action` and the `CASE v_adapter_key` dispatch**, gated by `v_risk IN ('HIGH','CRITICAL')`. A parallel evaluation is inserted in the step 11 replay branch, **after fp-match and before the generic in-progress/terminal handling** (STEP 4). No unrelated error precedence (auth→profile→lookup→null→context→input→object→match) is touched; the gate lives strictly after `begin` returns.

**One new variable** `v_risk text := v_action->>'risk_level'` is read at step 3 (from the already-whitelisted field — no lookup change).

---

## 4. Auto-path preservation (STEP 2 — primary regression invariant)

`class.assign = MEDIUM`. The gate is a single conditional `IF v_risk IN ('HIGH','CRITICAL')`. For LOW/MEDIUM the branch is **not entered** ⇒ control flows exactly as today: `begin → adapter CASE → build result → commit`. No decision row, no extra DB write, no envelope change, `replayed:false`. Byte-identical.

**Live-data corollary — governed path is DORMANT.** The only dispatchable action is `class.assign` (MEDIUM); `class.edit` is disabled. **No HIGH/CRITICAL dispatchable action exists in production.** Therefore the governed branch is unreachable with current data — Phase C ships inert governance machinery. Regression surface against real traffic is effectively nil; governed-path QA must use a ROLLBACK-scoped risk-elevation fixture (see §10).

---

## 5. Governed-path state machine (HIGH/CRITICAL)

Fresh path (`v_inserted=true`, inside subtransaction), after `_mc_begin_action`:

```
v_open := mc_internal._mc_open_decision(p_request_id);     -- SECDEF; may RAISE no_eligible_approver
-- read decision (INVOKER SELECT, RLS select_own) by intent_fingerprint = v_fp
SELECT id, state, expires_at, decision_reason INTO v_dec
  FROM public.mission_control_decisions WHERE intent_fingerprint = v_fp;
```

Branch on **effective** state (treat `pending ∧ now()>expires_at` as EXPIRED; **no mutation** — execute is INVOKER, cannot write decisions):

| Effective state | Behaviour | Adapter | Commit | Return |
|---|---|---|---|---|
| readable **pending** | park | ✗ | ✗ | `MC_ACTION_DECISION_REQUIRED` + `decision{id,state,expires_at}`; **normal RETURN keeps ledger+decision rows** |
| **not readable** (RLS-hidden: decision owned by another requester on same fingerprint) | fail-closed park | ✗ | ✗ | `MC_ACTION_DECISION_REQUIRED` + `decision{id}` |
| readable **approved** | resume | ✓ (fall through to CASE) | ✓ | success envelope |
| readable **rejected** | terminal | ✗ | ✗ | `MC_ACTION_DECISION_REJECTED` + `decision{…,reason}` |
| readable **expired** (or effective) | terminal | ✗ | ✗ | `MC_ACTION_DECISION_EXPIRED` + `decision{…}` |
| readable **cancelled** | terminal | ✗ | ✗ | `MC_ACTION_DECISION_CANCELLED` + `decision{…,reason}` |
| `_mc_open_decision` RAISED `no_eligible_approver` | fail-closed | ✗ | ✗ | caught by `when others` → **new map** → `MC_ACTION_NO_ELIGIBLE_APPROVER`; subtransaction **rolls back** ⇒ no parked ledger row, no decision row |

**`_mc_open_decision` raise mapping.** It raises before the decision INSERT on: `ledger_row_not_found`, `intent_not_forged`, `decision_not_required`, `object_scope_unsupported`, `no_eligible_approver`. Of these, only **`no_eligible_approver`** is reachable in the class-only INVOKER path (gate only calls it for HIGH/CRITICAL ⇒ `decision_not_required` unreachable; object_type constant `'class'` ⇒ `object_scope_unsupported` unreachable; row just forged ⇒ others unreachable). Add exactly one explicit branch mapping `no_eligible_approver → MC_ACTION_NO_ELIGIBLE_APPROVER`; the rest safely fall to `EXECUTION_FAILED` as control-plane guards.

**RLS-as-binding (structural finding).** Because execute is INVOKER and the decision `select_own` policy scopes to `requested_by = caller`, only the requester who *opened* the decision can ever read `state='approved'` and resume. A second requester sharing a fingerprint (STEP 7) opens nothing new (`ON CONFLICT DO NOTHING`), cannot read the other's decision, and is fail-closed to `DECISION_REQUIRED`. This delivers resume/approval semantics without any helper change.

---

## 6. Replay / park semantics (STEP 4)

Replay branch (`v_inserted=false`) precedence — additions in **bold**, existing order preserved:

1. existing not found (RLS non-owner) → `MC_ACTION_REQUEST_CONFLICT` *(unchanged; replay is inherently owner-only)*
2. structural triple mismatch → `MC_ACTION_REQUEST_CONFLICT` *(unchanged)*
3. fp NULL / hash_version≠1 / **fp mismatch** → `MC_ACTION_REQUEST_CONFLICT` *(unchanged — legacy/forge/intent guard runs first)*
4. **fp matches → inspect decision BEFORE generic in-progress/terminal:**
   - read decision (INVOKER, owner-readable since replay is owner-only) by `intent_fingerprint`.
   - **no readable decision** → preserve current: `processing`→`REQUEST_IN_PROGRESS`; terminal→stored payload `{replayed:true}` *(covers all LOW/MEDIUM replays — they never open a decision)*.
   - **pending** → `MC_ACTION_DECISION_REQUIRED` `{replayed:true}`
   - **effective expired** → `MC_ACTION_DECISION_EXPIRED` `{replayed:true}`
   - **rejected** → `MC_ACTION_DECISION_REJECTED` `{replayed:true}`
   - **cancelled** → `MC_ACTION_DECISION_CANCELLED` `{replayed:true}`
   - **approved** → **RESUME** (see §7): adapter + commit, wrapped in a fresh subtransaction with the verbatim domain-error map; success envelope `{replayed:true}`.

**No-bypass / no-duplicate proof.** The parked ledger row is `status='processing'`; `_mc_commit_action` only flips `processing→completed` and requires `actor_id = current_profile()`. On resume the caller is the owner (RLS), so commit is authorized and idempotent once completed (a subsequent replay reads terminal → stored payload). A non-owner cannot reach this branch (ledger read is owner-scoped). The decision override applies **only when a decision exists and fingerprint matches** — outside that, current in-progress semantics are untouched.

---

## 7. Resume actor semantics (STEP 5 + STEP 6)

**Recommendation: Option A** — same `execute_mission_control_action` call, same `request_id`, same intent, by the **original requester**. No new resume RPC.

Why it is safe by construction (STEP 6 — approval ≠ execution rights, three independent guards):

1. **RLS visibility.** Only `requested_by = caller` can read `state='approved'` ⇒ only the original requester can *enter* the resume branch.
2. **Adapter WHO-authz.** On resume, `assign_class_distribution` re-evaluates the *current caller* (`is_admin ∨ role∧school`), not the ledger actor. Original requester is re-authorized live.
3. **Commit ownership boundary.** `_mc_commit_action` raises `commit_core_not_owned` unless `ledger.actor_id = current_profile()`. Terminal completion is impossible for any non-original actor.

**Recommended hardening (C-2).** Even though (1)–(3) already prevent a wrong-actor completion, add an **explicit original-actor guard at the top of the resume branch** — `IF existing.actor_id IS DISTINCT FROM current_profile() THEN return MC_ACTION_REQUEST_CONFLICT` — so a wrong caller is rejected *before* any adapter side-effect-then-rollback, giving a deterministic contract rather than relying on emergent rollback. (In practice unreachable because replay is already owner-scoped, but it makes "only the original requester resumes" explicit and audit-legible.)

Approvers never call `execute`; they call `resolve_mission_control_decision`. Approval mutates only the decision row; it never touches the ledger and confers no execution capability.

---

## 8. Shared-decision concurrency (STEP 7)

Setup: two request_ids R1(actor A), R2(actor B), byte-identical intent ⇒ same fingerprint FP ⇒ **UNIQUE(intent_fingerprint) converges on ONE decision D** (opened by whoever inserts first; `D.requested_by` = that opener; `D.action_request_id` = that request).

Decision dedup does **not** imply execution dedup. Options:

- **Option A — shared approval, independent attempts, adapter-guarded.** Both may attempt on approval; `assign_class_distribution` business-key guard (`distribution_exists`) makes the loser `CONFLICT`. Relies on adapter idempotency; leaves a parked orphan row for the loser.
- **Option B ★ — approval binds to the opener (RLS-enforced, zero new code).** Only `D.requested_by` can read `state='approved'` and resume; any other requester on FP is fail-closed to `DECISION_REQUIRED` and **never reaches the adapter**. Execution dedup is structural, not dependent on adapter idempotency. Second request's ledger row parks (see §9/STEP 8).
- **Option C — decision execution latch** (add `executed`/`executed_by` to decision). Rejected for Phase C: mutates decision schema (out of scope).

**Recommendation ★ Option B.** It is what the INVOKER + `select_own` architecture already yields — no code beyond the gate, no reliance on business-key coincidence, single business side-effect guaranteed, and it composes with §6/§7 (single executor = the opener). Duplicate business effects are impossible because only one actor can ever resume. Documented consequence: the redundant second request remains a parked `processing` row governed by §9.

---

## 9. Ledger interaction (STEP 8 — terminal decision vs processing row)

G-C locked: **no `awaiting_decision` ledger status.** A governed request that is parked (pending) or governance-terminal (rejected/expired/cancelled) has ledger `status='processing'` indefinitely, because completion requires the `_mc_commit_action` boundary (completed-only) which is never called on those paths.

Options:

- **A ★ — Decision is authoritative; leave ledger `processing`.** No ledger mutation. Replay is deterministic from decision state (§6): a parked/terminal request always re-derives the correct governance envelope; it never completes. Orphan `processing` rows are inert and monitorable.
- **B — server-side ledger finalization.** A DEFINER finalizer flips governance-terminal rows to `failed`. But `failed` requires `result_payload NOT NULL ∧ error_code NOT NULL ∧ completed_at NOT NULL` and introduces a *new* terminal writer beside `_mc_commit_action` — reopening the G4 commit boundary. Higher surface; deferred.
- **C — replay-time finalization.** Couples execute to ledger terminal writes beyond commit; also reopens G4. Rejected for this phase.

**Recommendation ★ Option A.** Keeps Phase C to a single `execute` replace with zero schema change and preserves the G4 commit boundary verbatim. Ledger `processing` = "intent forged, governance/execution not yet terminalised in the ledger"; the **decision row is the authoritative governance terminal**. Provide an operational monitoring query (not a migration):

```sql
-- parked / governance-terminal orphans (processing ledger rows whose decision is non-pending or expired)
SELECT r.request_id, r.status, d.state, d.expires_at
FROM public.mission_control_action_requests r
JOIN public.mission_control_decisions d ON d.action_request_id = r.request_id
WHERE r.status = 'processing'
  AND (d.state IN ('rejected','expired','cancelled') OR (d.state='pending' AND now()>d.expires_at));
```

A server-side ledger finalization path (Option B) can be a **future bounded phase** if operational monitoring shows orphan accumulation matters. Not needed for correctness.

---

## 10. Public contract (STEP 9)

Signature **unchanged**. Existing envelope fields **unchanged and stable** (`ok`, `replayed`, `request_id`, `action_key`, `object_type`, `object_id`, `result`, `audit`, `error.code`). Auto-path (LOW/MEDIUM) never emits the new field ⇒ byte-compatible.

**Minimal additive:** one new optional top-level key `decision`, present **only** on governed-path responses:

```jsonc
{
  "ok": false,
  "replayed": false,           // true on governed replay/resume
  "request_id": "…",
  "action_key": "…",
  "object_type": "class",
  "object_id": "…",
  "error": { "code": "MC_ACTION_DECISION_REQUIRED" },   // or REJECTED / EXPIRED / CANCELLED / NO_ELIGIBLE_APPROVER
  "decision": {                 // omitted for NO_ELIGIBLE_APPROVER (no row created)
    "id": "…",
    "state": "pending",         // pending | approved | rejected | expired | cancelled
    "expires_at": "…",
    "reason": "…"               // included only for rejected / cancelled (admin-supplied)
  }
}
```

Governed **success** (approved-resume) uses the standard success envelope with `replayed:true`; no `decision` block required (optional to include `decision.state='approved'` — recommend omit to keep success shape identical to auto-path). `NO_ELIGIBLE_APPROVER` carries `error.code` only (no decision row exists).

**New error codes (C-1)** — vocabulary audit shows the `MC_ACTION_*` family has no decision code; these are the smallest additive set that maps cleanly:

- `MC_ACTION_DECISION_REQUIRED`
- `MC_ACTION_DECISION_REJECTED`
- `MC_ACTION_DECISION_EXPIRED`
- `MC_ACTION_DECISION_CANCELLED`
- `MC_ACTION_NO_ELIGIBLE_APPROVER` *(alternative: fold into existing `MC_ACTION_PERMISSION_DENIED`; recommend distinct code for FE messaging clarity)*

---

## 11. C-E1…C-E18 QA matrix (STEP 10)

**Governed tests (C-E6…C-E18) require a ROLLBACK-scoped fixture** that elevates a dispatchable action to HIGH (no HIGH/CRITICAL dispatchable action exists in production). Pattern: `BEGIN; UPDATE registry SET risk_level='HIGH' WHERE action_key='class.assign'; …exercise…; ROLLBACK;` under JWT impersonation (D2/D333). Enumerate side-effects on: **ledger · decision rows · distribution · audit** for every case.

**AUTO REGRESSION (PRE == POST):**

| ID | Scenario | Expected | Side-effects |
|---|---|---|---|
| C-E1 | MEDIUM `class.assign` success | identical success envelope, `replayed:false` | ledger +1(completed), dist +1, audit +1, decision 0 |
| C-E2 | identical replay | stored payload `{replayed:true}` | Δ=0 all |
| C-E3 | conflict rollback (existing dist, new request_id) | `MC_ACTION_CONFLICT`, β2 | ledger 0, dist 0, audit 0, decision 0 |
| C-E4 | bad context/input/action/object precedence | identical codes, same order | Δ=0 |
| C-E5 | FE `get_mission_control_actions` | byte-compatible (label 'Assign Program', v1 schema, dynamic options) | Δ=0 |

**GOVERNED PATH:**

| ID | Scenario | Expected | Side-effects |
|---|---|---|---|
| C-E6 | HIGH fresh intent | `MC_ACTION_DECISION_REQUIRED` + decision block; **adapter NOT called** | ledger +1(processing), decision +1(pending), dist 0, audit 0 |
| C-E7 | HIGH pending replay | same decision, `DECISION_REQUIRED {replayed:true}`; **no 2nd decision** | Δ=0 (UNIQUE fp holds) |
| C-E8 | approve → original requester replays | success **once**; commit ownership passes | ledger→completed, dist +1, audit +1, decision→approved (from resolve) |
| C-E9 | rejected → replay | `MC_ACTION_DECISION_REJECTED`; adapter never called | ledger stays processing, dist 0, audit 0 |
| C-E10 | expired (effective or flipped) → replay | `MC_ACTION_DECISION_EXPIRED`; adapter never called | ledger stays processing, dist 0 |
| C-E11 | cancelled → replay | `MC_ACTION_DECISION_CANCELLED`; adapter never called | ledger stays processing, dist 0 |
| C-E12 | self-approval blocked | `resolve` by requester → `self_decision_forbidden` (helper invariant, execute uninvolved) | decision unchanged |
| C-E13 | different-school approver | `resolve` → `not_authorized_to_decide` | decision unchanged |
| C-E14 | platform cancel blocked | `cancel` by platform admin (no school, not requester) → `not_authorized_to_cancel` | decision unchanged |
| C-E15 | no eligible approver | `MC_ACTION_NO_ELIGIBLE_APPROVER`; **fail-closed** | ledger 0 (rolled back), decision 0 |
| C-E16 | approval + changed intent (replay w/ different input) | fp mismatch → `MC_ACTION_REQUEST_CONFLICT` before decision inspection; **no approval reuse** | Δ=0 |
| C-E17 | concurrent same fp / different request_id (STEP 7) | **Option B**: only opener resumes on approve; 2nd requester fail-closed `DECISION_REQUIRED`, adapter never reached | 1 decision, 2 ledger processing rows, ≤1 dist, ≤1 audit |
| C-E18 | terminal decision + ledger-processing (STEP 8) | **Option A**: ledger stays `processing`; replay returns governance-terminal deterministically; monitoring query surfaces orphan | ledger processing (unchanged), decision terminal |

---

## 12. Migration design (STEP 11 — DESIGN ONLY)

**One object replaced:** `public.execute_mission_control_action` (INVOKER, `search_path=''`, signature + envelope preserved). D92 three-block:

1. **DDL** — `CREATE OR REPLACE FUNCTION public.execute_mission_control_action(...)` with the gate (read `v_risk`; §5 fresh-path gate; §6 replay-path branch; §7 resume guard; `no_eligible_approver` map).
2. **REVOKE/GRANT** — re-harden ACL `{authenticated, postgres}` (D15: `proacl` resets on replace).
3. **VERIFY** — `DO` block, fail-closed: assert `prosecdef=false`, `search_path=''`, ACL exact, new codes present in body, **no** reference to decision-table writes (INVOKER cannot write), frozen helper md5s unchanged. Never call the gated function inside VERIFY (`auth.uid()` NULL in SQL editor).

**NOT touched:** decision table · all 5 helpers · ledger schema · registry · adapter (`assign_class_distribution`) · `_mc_commit_action` · `_mc_begin_action` · `_mc_lookup_action` · `get_mission_control_actions` · FE.

**Inventory expected net-zero:** 93·251·239·168·33·1 unchanged; `mc_internal` 5/5 unchanged. Signature unchanged ⇒ PostgREST reload not strictly required; issue `NOTIFY pgrst` per D289 habit.

---

## 13. Rollback

`CREATE OR REPLACE FUNCTION public.execute_mission_control_action(...)` restored to md5 **`7a526354c820ab5f767ee7403c6e917d`** (current frozen body) + re-harden ACL `{authenticated, postgres}` + `NOTIFY pgrst`. Zero data repair (no ledger/decision/adapter/commit mutation in this phase). Any decision rows created during governed exercise are inert under the restored literal auto-path (execute reverts to no-gate behaviour; decisions simply stop being read).

---

## 14. Risks

1. **Governed path dormant in production.** No HIGH/CRITICAL dispatchable action exists; the governed branch is unreachable until an action is registered HIGH/CRITICAL. Positive-path governed proof is ROLLBACK-fixture-based (consistent with D363's fingerprint posture) — **do not over-claim "governed execution proven in production."**
2. **Lazy expiry read.** Execute computes *effective* expiry on read and cannot mutate (`INVOKER`, SELECT-only grant). A `pending`-but-past-`expires_at` decision reads as EXPIRED to execute but stays physically `pending` until `inbox`/`resolve`/`cancel` flips it. Envelopes are consistent; the physical flip is deferred. Acceptable; documented.
3. **Orphan `processing` rows** for parked/governance-terminal requests (STEP 8 Option A) and redundant second requests (STEP 7 Option B). Inert and monitorable; server-side finalization deferred.
4. **Subtransaction discipline.** The DECISION_REQUIRED return must be a **normal RETURN inside** the begin-block to retain the ledger+decision rows; `no_eligible_approver` must **raise** to roll back. Getting these two control-flow directions right is the core implementation risk — VERIFY and C-E6/C-E15 pin them.
5. **New error codes** are additive; FE currently has no handler for `decision`/new codes. Since the path is dormant, no FE regression, but FE decision-inbox/park UX is a separate (deferred) workstream.

---

## 15. CTO decisions required

**C-1 — Public decision error codes.**
- Options: (a) five new `MC_ACTION_DECISION_{REQUIRED,REJECTED,EXPIRED,CANCELLED}` + `MC_ACTION_NO_ELIGIBLE_APPROVER`; (b) fold `NO_ELIGIBLE_APPROVER` into existing `MC_ACTION_PERMISSION_DENIED`.
- Security: distinct codes leak only governance state to the requester (who is authorized to know); no cross-tenant leak (RLS-scoped).
- Compatibility: additive; auto-path never emits them.
- **★ Recommend (a)** — clean FE messaging; `NO_ELIGIBLE_APPROVER` is a distinct fail-closed governance state, not a permission denial.

**C-2 — Resume caller / original-actor semantics.**
- Options: (a) Option A resume via same `execute`/`request_id`, relying on RLS + adapter + commit boundary; (b) Option A **plus explicit original-actor guard** at the resume branch head; (c) new dedicated resume RPC.
- Security: (b) makes "only the original requester resumes" explicit and prevents any adapter side-effect-then-rollback for a wrong caller; (c) adds public surface for no gain (request_id + fingerprint already identify intent; adapter re-authz already runs).
- **★ Recommend (b)** — Option A + explicit original-actor guard; no new RPC.

**C-3 — Same fingerprint + multiple request_ids execution semantics.**
- Options: A (shared approval, independent adapter-guarded attempts); **B (approval binds to opener, RLS-enforced, single executor)**; C (execution latch column).
- Security: B guarantees a single business side-effect structurally, independent of adapter idempotency; A relies on the adapter business-key guard; C mutates decision schema (out of scope).
- Compatibility: B is emergent from the INVOKER + `select_own` design — zero extra code.
- **★ Recommend B.**

**C-4 — Terminal decision vs processing ledger row.**
- Options: **A (decision authoritative; leave ledger processing; monitor)**; B (server-side ledger finalizer → `failed`); C (replay-time finalization).
- Security/compat: A preserves the G4 commit boundary and keeps Phase C to one function replace, zero schema change; B/C reopen the terminal-writer boundary.
- **★ Recommend A** for Phase C; server-side finalizer as a possible future bounded phase if orphan monitoring warrants.

---

**STATUS: DESIGN ONLY — WAITING CTO APPROVAL.**
No migration. No SQL apply. No execute replace. No canonical append. STOP.
