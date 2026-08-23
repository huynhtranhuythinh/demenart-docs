# DMA_V128_B6_2 — REAL LOGIN TEST SHEET

> Execution-evidence template for the M3 acceptance gate. All tests via **real login** (PostgREST/FE), not SQL editor. Password `Test@123`. Use a **fresh `request_id`** per run.

## Accounts

| # | Role | Account | School |
|---|---|---|---|
| 1 | master_admin (same school) | `hieutruong.kidshouse@demo.demenart.com` | Kids House Montessori ĐN |
| 2 | master_admin (wrong school) | `hieutruong.kidshouse@demo.demenart.com` → target a **Dế Mèn** class | (cross-tenant) |
| 3 | teacher | `gv.linh.kidshouse@demo.demenart.com` | Kids House (lead_teacher) |

*(Alt master for school 2: `hieutruong.demen@demo.demenart.com` targeting a Kids House class.)*

---

## Test matrix

| Test | Account | Action | Expected | Actual | Evidence |
|---|---|---|---|---|---|
| **BASELINE (pre-M3)** | 1 | class.assign, own Kids House class | **FAIL** — finalize permission-denied → rollback; no distribution; ledger not completed | | ledger row + no class_distributions delta |
| **A · allow** | 1 | class.assign, own Kids House class, valid program_id, context.school_id=Kids House | **ALLOW** — ok:true; class_distribution created; audit `CLASS_ASSIGNMENT_CREATED`; ledger=completed | | ledger(status,completed_at) + dist id + audit delta |
| **B · wrong scope** | 2 | class.assign on a Dế Mèn class | **DENY** `MC_ACTION_PERMISSION_DENIED`; ledger=failed; no distribution | | ledger(status,error_code) |
| **C · teacher deny** | 3 | class.assign on any class | **DENY** `MC_ACTION_PERMISSION_DENIED`; ledger=failed; no distribution | | ledger(status,error_code) |
| **D · replay** | 1 | re-send Test A’s **same** request_id | `replayed:true`; **no** second distribution; ledger unchanged | | prior result echoed; dist count stable |
| **E · ledger forge** | 1 | direct PostgREST PATCH ledger row → status='completed', result_payload=… | **DENIED** (authenticated has no UPDATE; finish_own dropped) | | 401/403 / permission denied |
| **F · commit-core isolation** | 1 | direct RPC call `mc_internal._mc_commit_action(...)` | **Not reachable** (mc_internal not PGRST-exposed); if internal, cannot forge actor/result/completion | | 404 / no endpoint |
| **G · evaluator isolation** | 1 | direct RPC call `mc_internal.evaluate_action_policy(...)` | **Denied / not exposed** (internal-only ACL) | | 404 / permission denied |

---

## Post-M3 acceptance (sign-off)

- [ ] BASELINE recorded as FAIL (before applying M3).
- [ ] Test A flips to SUCCESS after M3 (the fix).
- [ ] B, C deny with `MC_ACTION_PERMISSION_DENIED`.
- [ ] D replay stable.
- [ ] E, F, G isolation confirmed.
- [ ] No inventory drift except policies −1 (finish_own).

**Signed (Owner):** __________  **Date:** __________
