# V128-B7 PHASE B — DECISION HELPER DESIGN PACKAGE

> **Mode:** DESIGN ONLY. No SQL · no migration · no mutation · no execute integration · no canonical append.
> **Sources:** canonical files on disk + live read-only audit (`xcvhacymrbhdhohyylyq`) + real function signatures. 2026-08-15.
> **Status:** DESIGN ONLY — STOP after package. No implementation authorized.

---

## STEP 0 · Canonical boot

- Endpoint: RULES **D363** · SYSTEM_MAP **v1.51** · backend tail **`20260815124454`** (Phase A applied) · FE pin `2.8.5`.
- V128-B6.3 CLOSED (G1–G4). Phase A CLOSED: `mission_control_decisions` exists (dormant, 0 rows, client SELECT-only). Canonical (RULES/MAP) not yet bumped for Phase A — deferred to Phase D.
- Frozen invariants carried: execute INVOKER · begin/commit DEFINER ledger seal · registry = WHAT · adapter = HOW · school sovereignty · **G-E:** cancel = requester OR same-school `master_admin`/`sub_admin` (no platform silent override).

## STEP 1 · Live re-pin — NO DRIFT

tail `20260815124454` · tables **93** · fns **248** · secdef **236** · policies **168** · `mc_internal` **3** · `mission_control_decisions` present, **0 rows**. Matches Phase A post-apply exactly.

**Grounding facts (live):**
- `public.current_profile()` → `uuid` (`select id from profiles where user_id=auth.uid()`; STABLE, DEFINER, `search_path=''`).
- `public.current_profile_role()` → `profile_role`; `is_school_admin()` = role ∈ {`master_admin`,`sub_admin`}.
- Ledger `mission_control_action_requests` columns include `action_key, object_type, object_id, actor_id, intent_fingerprint, intent_hash_version`.
- `classes` = `{id, school_id}`.
- `mc_internal._mc_lookup_action(p_object_type text, p_action_key text)` → registry authority incl `risk_level`.
- **`mc_internal` unexposed to PostgREST** (internal helpers are not API-callable).

## STEP 2 · Helper design audit (five helpers, grounded)

**Schema-placement principle (derived from the PostgREST seal):** helpers invoked *by execute* stay sealed in `mc_internal`; helpers invoked *by humans/cron* must be **public** DEFINER RPCs (clients cannot call `mc_internal`). The state-machine mutation stays DEFINER-exclusive either way (the table is client SELECT-only from Phase A).

| Helper | Schema | Caller | Role |
|---|---|---|---|
| `_mc_open_decision` | `mc_internal` | execute gate (Phase C) | sole INSERT owner |
| `_mc_expire_decisions` | `mc_internal` | inbox RPC (lazy) + optional cron | sole expiry writer |
| `resolve_mission_control_decision` | `public` | approver (client) | approve/reject transition |
| `cancel_mission_control_decision` | `public` | requester / school authority | cancel transition |
| `get_mission_control_decision_inbox` | `public` | approver (client) | approver read surface |

*(Naming maps to scope's `_mc_resolve_decision`/`_mc_cancel_decision`: the mutation is human-facing so it lives in `public` to be reachable; the `_mc_` internal-prefix is reserved for the two execute/cron-facing helpers. Schema placement is CTO gate B-1 below.)*

---

### 2.1 · `mc_internal._mc_open_decision(p_request_id uuid) → jsonb`
DEFINER · `search_path=''` · plpgsql. **Sole decision INSERT owner.** Called by the execute gate (Phase C) only when tier ∈ {HIGH, CRITICAL} and no decision exists for the fingerprint.

Logic:
1. Load ledger row `L` by `request_id` → source `action_key, object_type, object_id, actor_id, intent_fingerprint, intent_hash_version` (all **server truth**, never caller-passed). Guard: row exists (`ledger_row_not_found`); `intent_fingerprint IS NOT NULL` (`intent_not_forged`); `intent_hash_version = 1`.
2. `risk := _mc_lookup_action(L.object_type, L.action_key).risk_level` (registry authority, reuses G1). Defensive guard: `risk ∈ {HIGH,CRITICAL}` else `decision_not_required`.
3. Resolve authority school `S`: `object_type='class'` → `S := (select school_id from classes where id = L.object_id)`; else `object_scope_unsupported` (v1 = class only).
4. **Eligible-approver existence** (Risk #1 deadlock): `count(profiles where role ∈ {master_admin,sub_admin} AND school_id = S AND id <> L.actor_id) ≥ 1`; if 0 → raise `no_eligible_approver` (fail-closed — no un-approvable row created).
5. `expires_at := now() + TTL` (design constant, propose **72h**; CTO gate B-2).
6. INSERT decision (`action_request_id=request_id`, fingerprint + hash_version, action_key, object_type, object_id, `risk_level` **snapshot**, `state='pending'`, `requested_by=L.actor_id`, expires_at) `ON CONFLICT (intent_fingerprint) DO NOTHING RETURNING id` (Q3 dedup, concurrency-safe).
7. Return `{opened: <inserted>, decision_id, state, intent_fingerprint}`; on conflict, return the existing row's `{opened:false, decision_id, state}`.

`requested_by` is sourced from `ledger.actor_id`, not the caller — immune to caller spoofing.

### 2.2 · `public.resolve_mission_control_decision(p_decision_id uuid, p_verdict text, p_reason text) → jsonb`
DEFINER · `search_path=''` · plpgsql. `p_verdict ∈ {approve, reject}`. **Sole approve/reject writer.**

Logic:
1. `caller := current_profile()` (guard not null → `actor_unresolved`); `caller_role := current_profile_role()`; `caller_school := (select school_id from profiles where id=caller)`.
2. Load decision `D` by id (guard exists). **Lazy expiry:** if `D.state='pending' AND now() > D.expires_at` → set `expired`, return `decision_expired`. Guard `D.state='pending'` else `decision_not_pending` (terminal immutable).
3. Resolve `S` from `D.object_id` (class → `classes.school_id`).
4. **Eligibility:** `caller_role ∈ {master_admin,sub_admin} AND caller_school = S` else `not_authorized_to_decide`.
5. **Separation of duties (HARD):** `caller <> D.requested_by` else `self_decision_forbidden`.
6. Transition `WHERE id=D.id AND state='pending'`: `state := (approve→'approved' | reject→'rejected')`, `decided_by := caller`, `decision_reason := p_reason`, `updated_at := now()`.
7. Return `{decision_id, state, decided_by}`.

### 2.3 · `public.cancel_mission_control_decision(p_decision_id uuid, p_reason text) → jsonb`
DEFINER · `search_path=''` · plpgsql. **Sole cancel writer. Enforces G-E.**

Logic:
1. `caller`, `caller_role`, `caller_school` as above.
2. Load `D`; lazy-expire; guard `state='pending'`.
3. Resolve `S` from `D.object_id`.
4. **Cancel authority (G-E):** `caller = D.requested_by` (self) **OR** (`caller_role ∈ {master_admin,sub_admin} AND caller_school = S`). **No platform-admin branch.** Else `not_authorized_to_cancel`.
5. Transition: `state='cancelled'`, `decided_by := caller` (audit — who cancelled), `decision_reason := p_reason`, `updated_at := now()`. *(SoD `<>requester` does NOT apply to cancel — self-cancel is the point.)*
6. Return `{decision_id, state:'cancelled'}`.

### 2.4 · `mc_internal._mc_expire_decisions() → integer`
DEFINER · `search_path=''`. Idempotent sweep: `UPDATE decisions SET state='expired', updated_at=now() WHERE state='pending' AND now() > expires_at` → returns affected count. Called lazily by the inbox RPC and optionally by cron (CTO gate B-3).

### 2.5 · `public.get_mission_control_decision_inbox() → setof jsonb/row`
DEFINER · `search_path=''`. Approver read surface (RLS `_select_own` only covers the requester's own rows; approvers need cross-row visibility scoped to their school — served here, not via a recursive RLS predicate).

Logic:
1. `caller`, `caller_role`, `caller_school`. If `caller_role ∉ {master_admin,sub_admin}` → return empty (not an approver).
2. Lazy expiry: `_mc_expire_decisions()`.
3. Return `pending` decisions `D` where `D.object_type='class' AND (classes.school_id where id=D.object_id) = caller_school AND D.requested_by <> caller` (own requests excluded — cannot self-approve), ordered by `created_at`.

## STEP 3 · Security boundary design

- **Posture (all five):** SECURITY DEFINER · `search_path=''` · explicit `REVOKE ALL FROM PUBLIC, anon, authenticated` then targeted `GRANT EXECUTE` (D15 re-harden after every CREATE OR REPLACE). ACL verified via `aclexplode(coalesce(proacl, acldefault(...)))`.
- **Grants:**
  - `mc_internal._mc_open_decision`, `_mc_expire_decisions` → EXECUTE `{authenticated, postgres}` (authenticated reaches them only through execute/inbox; `mc_internal` unexposed to PostgREST blocks direct client calls).
  - `public.resolve_… / cancel_… / get_…_inbox` → EXECUTE `{authenticated, postgres}` (client entry points).
  - `anon` → EXECUTE on **none**.
- **Mutation seal preserved:** the table stays client **SELECT-only** (Phase A). Every state transition flows through a DEFINER helper enforcing authz. No client `INSERT/UPDATE/DELETE` path exists.
- **Separation of duties:** `resolve` enforces `caller <> requested_by` (hard). `open` enforces `eligible-approver ≠ requester` exists at open-time.
- **School sovereignty:** approver/canceller must be same-school `master_admin`/`sub_admin`. **Platform admins are excluded** from decide and cancel (G-E + D48). No platform override path.
- **No privilege elevation:** a decision only gates *whether* execution proceeds; on resume (Phase C) the adapter re-runs WHO-authz against the original actor (D362.5). Approval ≠ execution grant.
- **Frozen invariants untouched by Phase B:** execute body **unchanged** (INVOKER, md5 `7a526354…`) — Phase B adds functions but **does not wire any into execute** (that is Phase C). `_mc_begin_action`/`_mc_commit_action` unchanged; ledger schema/grants/policies unchanged; registries unchanged; FE unchanged.
- **Dormancy in Phase B:** `_mc_open_decision` is the only producer of rows and it is called **only by execute**, which Phase B does **not** modify → no decision rows can be created yet → resolve/cancel/inbox operate on an empty set. **No live behavior change.**

## STEP 4 · Rehearsal plan (design of the future rehearsal — no SQL now)

The Phase-B rehearsal will follow the Phase-A abort-with-evidence discipline: a single transaction that CREATEs the five functions + REVOKE/GRANT, runs VERIFY, then `RAISE`-rolls-back — **nothing committed**. Two layers:

**A · Structural VERIFY (must prove):**
- All 5 functions exist; each `prosecdef=true` and `search_path=''`.
- Schema placement correct (2 in `mc_internal`, 3 in `public`).
- ACL: public RPCs EXECUTE = {authenticated, postgres}; `mc_internal` helpers not granted to `anon`; no `anon` EXECUTE anywhere.
- **execute md5 UNCHANGED `7a526354…`** (proves zero execute wiring) · begin/commit/lookup/adapter/gaa md5 unchanged.
- `mission_control_decisions` schema/grants/policies unchanged (still SELECT-only, 1 policy).
- Ledger unchanged (`authenticated` = SELECT-only).
- Inventory delta: fns **+5**, secdef **+5**, `mc_internal` **3→5**; tables Δ0, policies Δ0, triggers Δ0.

**B · Behavioral VERIFY (JWT impersonation, D333, inside BEGIN…ROLLBACK):**
Seed one synthetic `pending` decision (as postgres) for a class in a known demo school (KHM), then impersonate real profiles (`sub=profiles.user_id`, `SET LOCAL ROLE authenticated`) and assert:

| Actor (demo) | Call | Expected |
|---|---|---|
| same-school `master_admin` (`hieutruong.kidshouse`), ≠ requester | resolve approve | `approved` |
| the requester | resolve | `self_decision_forbidden` |
| different-school `master_admin` (`hieutruong.demen`) | resolve | `not_authorized_to_decide` |
| same-school `lead_teacher` (`gv.linh.kidshouse`) | resolve | `not_authorized_to_decide` |
| requester | cancel | `cancelled` |
| platform `super_admin` | cancel | `not_authorized_to_cancel` (G-E — no override) |
| — (open with school having no eligible approver) | `_mc_open_decision` | `no_eligible_approver` |
| — (pending past `expires_at`) | `_mc_expire_decisions` | row → `expired` |
| same-school master | inbox | sees pending (not own); teacher → empty |

All impersonation via `set_config('request.jwt.claims', …)` + `SET LOCAL ROLE authenticated`; entire block `ROLLBACK` — no persisted rows.

## CTO gates (before Phase-B rehearsal/apply)

- **B-1 — Schema placement.** Approve: `_mc_open_decision`/`_mc_expire_decisions` in `mc_internal` (sealed); `resolve`/`cancel`/`inbox` in `public` (client-reachable, DEFINER-authz). ⭐ *Recommend approve* (forced by PostgREST seal on `mc_internal`).
- **B-2 — TTL.** Approve `expires_at = now() + 72h` (design default; tunable). ⭐ *Recommend 72h.*
- **B-3 — Expiry mechanism.** Lazy-on-read (inbox + Phase-C gate call `_mc_expire_decisions`) + **optional** cron. ⭐ *Recommend lazy + optional cron (defer cron to Phase C/D).*
- **B-4 — Cancel audit field.** Set `decided_by = caller` on cancel (records who cancelled) vs leave null. ⭐ *Recommend set (audit).*

---

## STATUS

**DESIGN ONLY — STOP.**
Five helpers designed and grounded; zero SQL/mutation. execute remains INVOKER + unwired; ledger sealed; registries untouched; school sovereignty + G-E enforced in design. No decision rows can exist until Phase C wires `_mc_open_decision` into execute.

Awaiting CTO decision on B-1…B-4. On approval, next step is the **Phase-B rehearsal** (abort-with-evidence, structural + JWT-impersonation behavioral), then a separate APPLY authorization — mirroring Phase A.

*Endpoint: RULES **D363** · SYSTEM_MAP **v1.51** · backend tail `20260815124454` · FE pin `2.8.5`.*
