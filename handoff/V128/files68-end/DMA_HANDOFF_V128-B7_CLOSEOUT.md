# DMA_HANDOFF_V128-B7_CLOSEOUT — Decision Control Plane (Phase A/B/C)

**Date:** 2026-08-16 · **Endpoint:** RULES **D364** · SYSTEM_MAP **v1.52** · backend tail **`20260815161535`** · FE main pin **`2.8.5`**
**Disposition:** Phase A CLOSED · Phase B CLOSED · Phase C CLOSED · Decision Control Plane **technical scope COMPLETE** · **B7 milestone = PENDING OWNER** (not stamped CLOSED).

---

## 1. What V128-B7 delivered

An **approval Decision Gate** for Mission Control OS action execution. HIGH/CRITICAL-risk actions now require a same-school admin approval before the adapter runs; LOW/MEDIUM actions execute automatically as before. Built across three gated phases; all live-verified against real function bodies (never from memory).

| Phase | Migration | Tail | Scope |
|---|---|---|---|
| **A** | `v128_b7_pa_decision_foundation_table` | `20260815124454` | `mission_control_decisions` table + RLS + `select_own` policy + `intent_fingerprint` UNIQUE |
| **B** | `v128_b7_pb_decision_helpers` | `20260815151633` | mc_internal `_mc_open_decision` + `_mc_expire_decisions`; public `resolve` / `cancel` / `get_..._inbox` |
| **C** | `v128_b7_pc_execute_decision_gate` | `20260815161535` | execute decision gate (5 codes, C-1…C-4), single REPLACE |

---

## 2. CTO decisions (locked)

- **C-1 = Option A** — five new error codes: `MC_ACTION_DECISION_REQUIRED`, `_REJECTED`, `_EXPIRED`, `_CANCELLED`, `MC_ACTION_NO_ELIGIBLE_APPROVER`.
- **C-2 = Option b** — resume via same execute/request_id + explicit original-actor guard (`v_existing.actor_id IS DISTINCT FROM v_actor_id → MC_ACTION_REQUEST_CONFLICT`). Defense-in-depth: RLS `select_own` + adapter re-authz + commit boundary actor check.
- **C-3 = Option B** — approval binds to opener (RLS-enforced); a second requester on the same fingerprint is fail-closed `DECISION_REQUIRED`; single executor.
- **C-4 = Option A** — decision authoritative, ledger stays `processing` on park/terminal; no ledger finalizer; single execute replace.

---

## 3. Gate mechanics (live-verified)

- **Placement:** fresh path — after `_mc_begin_action`, before adapter CASE. Replay path — after fingerprint match, before generic in-progress handling.
- **Routing:** `v_risk` read from the whitelisted lookup `risk_level`. LOW/MEDIUM → adapter (auto). HIGH/CRITICAL → `_mc_open_decision` then read decision (INVOKER SELECT, RLS `select_own`).
- **Park / terminal states** return a **normal RETURN inside the `begin…exception` subtxn**, keeping the ledger row `processing` and the decision row (C-4). Effective-expiry is computed **read-only** (`pending ∧ now()>expires_at` treated as expired; execute never flips state — it holds no write grant on decisions, VERIFY-enforced).
- **Approved resume** falls through to the adapter (fresh path) or, on replay, passes the original-actor guard then runs adapter + `_mc_commit_action` inside a β2 subtxn.
- **`no_eligible_approver`** RAISEs → caught by `when others` → mapped `MC_ACTION_NO_ELIGIBLE_APPROVER` → subtxn rollback → fail-closed (no parked/unapprovable row).

---

## 4. Rehearsal evidence (ROLLBACK-based, D2 — zero residue)

Full C-E matrix passed inside a single `BEGIN … ROLLBACK`; post-rollback the live state was proven identical to baseline (execute md5 restored `7a526354…`, decisions 0, relocated approver + guard trigger restored).

| Case | Result |
|---|---|
| CE1/E3 MEDIUM auto-path | `MC_ACTION_CONFLICT`, `is_decision=false`, decisions Δ0 |
| CE6 HIGH fresh | `DECISION_REQUIRED`, decision +1 pending, adapter not reached, ledger processing |
| CE7 pending replay | `DECISION_REQUIRED` replayed, same decision (no 2nd) |
| CE8 approve(B) → resume(A) | `ok=true`, dist +1, ledger completed, decision approved |
| CE12 self-approve | `self_decision_forbidden` |
| CE13 cross-school approver | `not_authorized_to_decide` |
| CE15 no eligible approver | `MC_ACTION_NO_ELIGIBLE_APPROVER`, ledger rolled back, decisions 0 |
| CE16 changed intent | `MC_ACTION_REQUEST_CONFLICT` |

**Fixture note:** every school has exactly one admin, so the approver was built by an **in-transaction school relocation** with the `trg_guard_profiles_protected` trigger temporarily disabled — inside the rolled-back transaction only. Post-apply, only the MEDIUM path was live-confirmed (rolled back). **No over-claim of "proven in production":** the governed path is dormant and no positive governed decision exists on committed data.

---

## 5. Post-apply verification (committed)

- Migration `20260815161535` recorded.
- Execute md5 `7a526354…` → **`09ef5f48f3318bfb53e126f3bc81d40a`**; signature unchanged; SECURITY INVOKER; `search_path=''`; ACL `{authenticated,postgres}` (anon/PUBLIC absent).
- Frozen unchanged: `_mc_begin_action` `f47260ef…`, `_mc_commit_action` `ce36c5fe…`, `_mc_lookup_action` `5d940037…`, `assign_class_distribution` `03a1510b…`.
- Ledger status domain unchanged {received,processing,completed,failed} — no `awaiting_decision`.
- Registry unchanged: class.assign active/MEDIUM · class.edit disabled/LOW.
- Live MEDIUM confirm (rolled back): `is_decision=false`, decision rows Δ0.

**Inventory:** tables 92→**93** · fns 248→**251** · secdef 236→**239** · policies 167→**168** · triggers **33** · cron **1**; `mc_internal` 3→**5**. Decisions table: RLS on, 1 policy (`select_own`), **0 rows**, `intent_fingerprint` UNIQUE.

**Decision-helper md5 baseline (go-forward):** open `e5b12a96…` · expire `2f6ca505…` · resolve `bfcc7203…` · cancel `315b5bbf…` · inbox `47ca0947…`.

---

## 6. Disposition & what's next (NOT authorized here)

- Phase A/B/C **CLOSED**; Decision Control Plane **technical scope COMPLETE**.
- **B7 milestone = PENDING OWNER.** Not auto-stamped CLOSED. **B8 not opened.**
- Governed path is **dormant** — no HIGH/CRITICAL dispatchable action is registered, so the gate does not fire on any current production traffic (class.assign stays MEDIUM/auto).
- **Deferred (out-of-scope, documented):** register an action at HIGH+ to arm the gate · decision inbox FE · notification wiring · multi-approver quorum · decision analytics · generic object decision expansion.
- **Latent debt:** FE `ClassWorkspaceScreen` class.assign-specific submit path (D363 carry-over, not fixed).

---

## 7. Rollback

- **Phase C only:** `CREATE OR REPLACE execute_mission_control_action` → md5 `7a526354c820ab5f767ee7403c6e917d` (B6.3 body) + re-harden ACL `{authenticated,postgres}` + `NOTIFY pgrst`.
- **Full B7:** additionally DROP `resolve_mission_control_decision` / `cancel_mission_control_decision` / `get_mission_control_decision_inbox` → DROP `mc_internal._mc_open_decision` / `_mc_expire_decisions` → DROP TABLE `mission_control_decisions` (cascade policy).
- **Data repair: none** — decisions table holds 0 rows; no ledger/adapter/column change in Phase C.

---

## 8. Boot pointer (next session)

Read canonical directly (never memory): `DMA_RULES.md` (→ D364), `DMA_SYSTEM_MAP.md` (→ v1.52), this handoff. Then read-only live DB audit before any design/implementation. Endpoint to re-pin: backend tail `20260815161535` · execute `09ef5f48f3318bfb53e126f3bc81d40a` · decisions 0 · class.assign MEDIUM · frozen begin/commit/lookup/open/expire + resolve/cancel/inbox.
