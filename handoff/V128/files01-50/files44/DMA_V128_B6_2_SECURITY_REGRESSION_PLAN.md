# DMA_V128_B6_2 — SECURITY & REGRESSION PLAN

> **Scope:** M3 (Governed execution finalization correction) — reframed per CTO Option 1.
> **Acceptance (replaces "byte-identical"):** (a) postgres-context compatibility PASS · (b) **REAL AUTHENTICATED EXECUTION PASS required**.
> **Method:** SQL rollback-safe simulation (`DO … RAISE EXCEPTION`) for structural/impersonation + **real login** (6 demo accounts) for the authenticated gate (D2/D3). 0 apply until Owner Gate.

---

## 0. REAL AUTHENTICATED EXECUTION BASELINE (new — the core of M3)

**Live fact (M0 capture, definitive):**
- `has_table_privilege('authenticated', mission_control_action_requests, 'UPDATE') = FALSE`. relacl `authenticated=ar/postgres` (INSERT+SELECT only). anon/service_role UPDATE also FALSE.
- `finish_own` UPDATE policy is therefore **unreachable** (no base UPDATE privilege to filter) → it was **not an exploitable forge**; it is a dead policy.
- `execute_mission_control_action` is **INVOKER** → runs as `authenticated` → its inline finalize `UPDATE … completed/failed` is **permission-denied under a real authenticated caller** → whole transaction rolls back → **class.assign cannot complete under real login**.
- The 5 completed / 3 failed ledger rows were written under **role=postgres** (impersonation with JWT claim set but no `SET ROLE authenticated`), not under real authenticated.

**Pre-M3 baseline to record (prove the defect exists):**

| Context | Expected pre-M3 |
|---|---|
| SQL editor as postgres + JWT-claim impersonation (no `SET ROLE`) | class.assign completes (ledger→completed) — **misleading pass** |
| **Real authenticated login** (PostgREST) | class.assign **FAILS at finalize** → 500 / txn rollback → NO distribution, NO completed row |

**Post-M3 target:**

| Context | Expected post-M3 |
|---|---|
| SQL editor as postgres | still completes (compatibility preserved) |
| **Real authenticated login** | class.assign **COMPLETES** (distribution + audit + ledger→completed) — **the fix** |

**Baseline capture protocol (before applying M3):**
1. Real login as `hieutruong.kidshouse@demo.demenart.com` / `Test@123` (master_admin, Kids House).
2. Trigger class.assign for a Kids House class via the real client (FE / authenticated PostgREST RPC), fresh `request_id`.
3. Record: does it complete? Inspect ledger row status + whether a `class_distributions` row was created. Expected pre-M3: FAIL/rollback.
4. Screenshot/log as the "before" evidence. This is what M3 must flip to PASS.

---

## 1. AUTHORIZATION TESTS (post-M3, real login unless noted)

**Test A — master_admin + same school → ALLOW**
- Account: `hieutruong.kidshouse@demo.demenart.com` / `Test@123`.
- Action: class.assign on a Kids House class; valid `program_id`; `context.school_id` = Kids House.
- Expected: `ok:true`; **class_distribution created**; **audit `CLASS_ASSIGNMENT_CREATED`**; **ledger status=completed** (completed_at + result set); result DTO shape unchanged.

**Test B — master_admin + wrong school → DENY**
- Account: `hieutruong.kidshouse@demo.demenart.com` (Kids House) targeting a **Dế Mèn** class.
- Expected: `ok:false`, `MC_ACTION_PERMISSION_DENIED` (adapter `not_authorized_for_school`); ledger status=failed; NO distribution. *(Shadow M4: evaluate also returns scope-deny.)*

**Test C — teacher role → DENY**
- Account: `gv.linh.kidshouse@demo.demenart.com` / `Test@123` (lead_teacher).
- Action: class.assign on any class.
- Expected: `ok:false`, `MC_ACTION_PERMISSION_DENIED` (adapter role check); ledger failed; NO distribution.

**Test D — replay same request_id → replay behavior unchanged**
- Account: Test A account. Re-send with the **same** `request_id` used in a completed A run.
- Expected: returns the prior result with `replayed:true`; **no second** distribution; ledger unchanged.
- Also: in-progress replay (concurrent) → `MC_ACTION_REQUEST_IN_PROGRESS`.

---

## 2. FORGE / INTEGRITY TESTS (corrected framing)

**Test E — client direct ledger finalize (forge attempt) → DENIED at grant level**
- Real authenticated client attempts `PATCH mission_control_action_requests SET status='completed', result_payload=…` (PostgREST) on own processing row.
- Expected: **permission denied for table** — because `authenticated` has **no UPDATE privilege** (verified `has_table_privilege=false`), independent of RLS. Post-M3, `finish_own` is also dropped (belt-and-suspenders / dead-policy cleanup).
- Note: this test documents that the "forge" was blocked by the base grant even pre-M3; M3 does not weaken it.

**Test F — client direct commit-core call → cannot forge actor / result / completion**
- Real authenticated client attempts to call `mc_internal._mc_commit_action(...)`.
- Expected primary: **not reachable via PostgREST** (mc_internal not in `PGRST_DB_SCHEMAS`) → no RPC endpoint.
- Expected even if reachable internally: commit-core (i) derives actor from `current_profile()` (cannot pass a forged actor), (ii) guards ownership+status of the ledger row (can only touch own processing rows), (iii) derives result from the adapter (cannot inject `result_payload`/`status`/`completed_at`). → a direct call is at most a legitimate self-execution, never a forgery.

**Test G — evaluator not client-callable (M2/M4 context)**
- Real authenticated direct call to `mc_internal.evaluate_action_policy(...)` → denied (internal-only ACL; not PGRST-exposed).

---

## 3. STRUCTURAL VERIFY (in-migration BLOCK-3, RAISE→rollback)
- `execute` `prosecdef=false` (INVOKER preserved) + signature intact.
- commit-core exists, DEFINER, owner=postgres, `search_path=''`, no anon grant.
- `finish_own` absent; `insert_own_processing` + `select_own` present.
- `has_table_privilege('authenticated', ledger, 'UPDATE') = false` (finalization stays server-side).

## 4. POSTGRES-CONTEXT COMPATIBILITY (sim, impersonation)
- With JWT claim (master_admin) under postgres role: class.assign completes, distribution+audit+ledger identical shape to pre-M3 postgres-context run. Confirms no compatibility regression for existing tooling/tests.

---

## 5. ACCEPTANCE MATRIX

| Gate | Method | Must |
|---|---|---|
| Structural | in-migration verify | PASS (else rollback) |
| Postgres-context compatibility | sim | PASS |
| **Real authenticated execution** | **real login (Test A)** | **PASS (was failing pre-M3)** |
| Authorization denies (B, C) | real login | PASS |
| Replay (D) | real login | PASS |
| Forge/integrity (E, F, G) | real login + config check | PASS |
| No new inventory drift | post-apply audit | 92→92 tables; functions +N expected; policies −1 (finish_own) |

**M3 is accepted only when the real-authenticated Test A flips from pre-M3 FAIL to post-M3 PASS, and B–G hold.**

---

## 6. NOTES
- Real-login is a **hard gate**, not optional — the entire defect (and its fix) is invisible to postgres-context testing (D2/D3).
- Use fresh `request_id` per run to avoid replay masking.
- Capture ledger row (status, completed_at, error_code) + `class_distributions` delta + `audit_logs` `CLASS_ASSIGNMENT_CREATED` delta for each test as evidence.
