# V128-B8 CLOSEOUT — Decision Workflow Foundation (I1: Decision Lifecycle Foundation)

**Date:** 2026-08-16 · **Endpoint:** RULES **D365** · SYSTEM_MAP **v1.53** · backend tail **`20260815182235`** · FE main pin **`2.8.5`**
**Prior endpoint:** RULES D364 · SYSTEM_MAP v1.52 · tail `20260815161535` (B7 Decision Control Plane — HISTORICAL SNAPSHOT, BẤT BIẾN).

---

## Status

**TECHNICAL COMPLETE.** V128-B8-I1 implemented, applied atomically, verified (structural + security + lifecycle rehearsal + zero residue). One follow-up carried as **PENDING** (two-session concurrency rehearsal). Governed path remains **DORMANT** (class.assign MEDIUM → auto; no HIGH/CRITICAL action registered).

---

## Objective

Decision Workflow Foundation — add a governance layer over the existing B7 Decision Control Plane: make the decision lifecycle **evidenced, centrally controlled, and terminally protected**, without introducing execution semantics into the Decision layer.

Architectural invariant preserved: **Registry = WHAT · Adapter = HOW · Decision = WHETHER · Ledger = execution truth · Memory = downstream projection.** Decision state domain UNCHANGED `{pending, approved, rejected, expired, cancelled}` — **no `executing`/`completed`/`failed`** (those stay in the ledger).

---

## Delivered

1. **Decision lifecycle evidence** — `public.mission_control_decision_transitions`, append-only immutable history (`from_state`/`to_state`/`actor_id`/`reason`/`created_at`). No denormalization; Decision remains source of truth. Closed edge-set CHECK; RLS `select_own`; DB-enforced append-only (trigger blocks UPDATE/DELETE for **all roles incl. service_role**).
2. **Centralized transition controller** — `mc_internal._mc_transition_decision(...)`, the single state-mutation boundary: `FOR UPDATE` lock + allowed-edge validation + terminal protection + `ROW_COUNT` assertion + evidence insert.
3. **Terminal state protection** — `*→pending` reopen blocked (`invalid_target_state`); writes to non-pending blocked (`decision_not_pending`); enforced centrally + at the table CHECK.
4. **Lifecycle audit trail** — every transition (create, approve, reject, cancel, expire) writes one immutable evidence row with actor identity (profile-id; NULL for system expiry).

---

## Backend Change

**Migration:** `v128_b8_i1_decision_lifecycle_foundation` (tail `20260815161535` → **`20260815182235`**). D92 3-block atomic (DDL → REVOKE/GRANT → VERIFY fail-closed) + `NOTIFY pgrst`.

**New:**
- Table `public.mission_control_decision_transitions` (+ index `(decision_id, created_at)`, CHECK `mcdt_to_state_check` + `mcdt_edge_check`, FK→`mission_control_decisions(id)` **ON DELETE NO ACTION**, RLS + policy `mission_control_decision_transitions_select_own`).
- `mc_internal._mc_transition_decision(uuid,text,uuid,text)` — SECURITY DEFINER, `search_path=''`, ACL `{postgres}` only. md5 `fe0eea599db711fb8472b37a72fa25e4`.
- `mc_internal._mc_block_transition_mutation()` + trigger `trg_block_decision_transition_mutation` (BEFORE UPDATE/DELETE). Block-fn non-DEFINER, `search_path=''`. md5 `f53eed4ddcc958faaad487232fb1392e`.

**Modified (delegation; public contract preserved; md5 after):**
- `mc_internal._mc_open_decision` — records `NULL→pending` evidence on genuine create only (idempotent conflict = no dup). `b376edd70cc6fe4e83bf000dfa456954`.
- `mc_internal._mc_expire_decisions` — bulk-safe `UPDATE…RETURNING → INSERT evidence` (no loop), actor NULL. `c57c40b88b77e838da137dd3e9cf59e7`.
- `public.resolve_mission_control_decision` — authz unchanged; write delegated to controller; dead lazy-expire write removed (C4). `c6208c6dbd8b1dac946735629e52d7d0`.
- `public.cancel_mission_control_decision` — authz unchanged; write delegated. `4c4eecc55eb9467aee6c88f41ed6f0b6`.

**Frozen (unchanged, md5):** `execute_mission_control_action` `09ef5f48f3318bfb53e126f3bc81d40a` (INVOKER, reads decisions only) · `get_mission_control_decision_inbox` `47ca0947e7334ca8804a5c65c7b5f538` · `_mc_begin_action` `f47260ef3f06811ac2e83807989b26c7` · `_mc_commit_action` `ce36c5fe109e99a919158a4482940c6a` · `_mc_lookup_action` `5d940037687be0a398a232cf987bfcf6` · `assign_class_distribution` `03a1510bd827c03a650a3a88312fbe3a`. Registry: class.assign active/MEDIUM · class.edit disabled/LOW. FE pin `2.8.5`, 0 change.

**Inventory (live measured):** tables 93→**94** · public fns **251** (net 0) · public secdef **239** (net 0) · policies 168→**169** · triggers 33→**34** · cron 1; `mc_internal` {5→**7** fn / 5→**6** secdef}. `mission_control_decision_transitions`: RLS on, 1 policy, append-only trigger, **0 rows**. `mission_control_decisions`: unchanged, **0 rows**.

---

## Verification

- **Structural verification PASS** — in-migration VERIFY (fail-closed): table exists · RLS enabled · policy correct · no client write leak · controller SECURITY DEFINER + `search_path=""` + no client execute · append-only trigger present · block-fn `search_path` pinned.
- **Security PASS** — authenticated INSERT evidence denied; authenticated UPDATE `decisions.state` denied; **service_role UPDATE/DELETE evidence blocked by trigger** (`transition_evidence_is_append_only`, D89); controller ACL `{postgres}` only.
- **Lifecycle rehearsal PASS (14/14)** — ROLLBACK-based (D2), fixtures in-txn (D364.7 method): create `NULL→pending` (actor=requester) · idempotent re-open (no dup) · approve · reject · cancel (actor=caller) · expire (actor NULL, bulk return=1) · `invalid_target_state` (`*→pending`) · `decision_not_pending` (expired→approved & terminal reopen) · `mcdt_edge_check` (bad direct insert) · client-mutation blocked · service_role blocked.
- **Zero residue PASS** — post-rollback: decisions 0 · transitions 0 · registry class.assign restored MEDIUM · tail `20260815182235` · inventory 94/169/34/7.

**Apply note:** first apply attempt failed fail-closed on a wrong VERIFY assertion (`proconfig` stores `search_path=""`, not `search_path=`) — zero partial state (D92 guard held); fixed the single VERIFY line only (DDL untouched); re-applied clean. Recorded as D365.6.

---

## Deferred (explicit — NOT in B8-I1; each is a new milestone)

- Authority resolver full expansion
- Delegation
- Notification
- Inbox UI
- Workflow builder
- AI recommendation
- child.transfer
- Object-scope beyond `class`

---

## Pending Follow-up

- **Two-session concurrency rehearsal — PENDING (not claimed complete).** `FOR UPDATE` + `ROW_COUNT` assertion are in the committed controller body and the logical no-false-success case passed, but a true parallel two-connection race has not yet been exercised. Carry as an open verification item.

---

## Rollback

CREATE OR REPLACE `_mc_open_decision`/`_mc_expire_decisions`/`resolve`/`cancel` back to B7 md5 (`e5b12a96…`/`2f6ca505…`/`bfcc7203…`/`315b5bbf…`) + re-apply prior ACLs → DROP TRIGGER `trg_block_decision_transition_mutation` → DROP FUNCTION `mc_internal._mc_block_transition_mutation()` → DROP FUNCTION `mc_internal._mc_transition_decision(uuid,text,uuid,text)` → DROP TABLE `public.mission_control_decision_transitions` (cascade policy) → `NOTIFY pgrst`. **0 data-repair** (transitions/decisions 0 rows, governed path dormant).

---

## Boot pointer (next session)

Read canonical directly (never memory): `DMA_RULES.md` (→ D365), `DMA_SYSTEM_MAP.md` (→ v1.53), this handoff. Then read-only live DB audit before any design/implementation. Re-pin endpoint: backend tail `20260815182235` · execute `09ef5f48…` (frozen) · controller `fe0eea59…` · transitions/decisions 0 rows · class.assign MEDIUM (dormant). **Do not open B8.2 / authority resolver / FE / Lovable** — await CTO next-milestone decision.
