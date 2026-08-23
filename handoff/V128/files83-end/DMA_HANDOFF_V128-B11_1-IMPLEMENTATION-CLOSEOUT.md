# DMA HANDOFF — V128-B11.1 · DECISION INBOX AUTHORITY RECONCILIATION — IMPLEMENTATION CLOSEOUT

**Milestone:** V128-B11.1 IMPLEMENTATION — Decision **inbox visibility** migrated from embedded inbox authority (role-list early gate + caller-school predicate) into **Authority Resolver consumption** (phase='resolve'). Closes the last decision-path authority divergence (inbox vs resolve; `platform_role` Risk-3). Requester (Gate A) + approver (resolve/cancel) authority unchanged.
**Mode:** IMPLEMENTATION (applied) + CANONICALIZED. 1 migration (D92 3-block atomic). Verified by resolver-direct matrix + JWT-impersonated inbox↔resolver equivalence rehearsal (zero residue).
**Date:** 2026-08-19
**Status:** ✅ **IMPLEMENTATION: CLOSED — LIVE + VERIFIED + CANONICALIZED.** Governed decision lifecycle remains **DORMANT** (0/0).
**Canonical endpoint after append:** RULES **D371** · SYSTEM_MAP **v1.59** · HANDOFF **V128-B11.1-IMPLEMENTATION-CLOSEOUT** · backend tail **`20260819092150`** · FE main pin `2.8.5`.

---

## Milestone identity

Implementation of the CTO-approved B11.1 design (Option A of the B11 gate). After B10.1, requester authority (Gate A) and approver authority (resolve/cancel) were resolver-backed, but **inbox visibility** still re-derived authority with an embedded predicate — a parallel authority engine (Risk-1) diverging from the resolver on `platform_role` (Risk-3). B11.1 makes inbox eligibility consume the same `_resolve_authority` primitive, so all three decision-path authority questions are single-source. Consume-only: resolver body byte-unchanged; only the inbox function is modified.

---

## Implementation status

**CLOSED.** Applied via migration `20260819092150` `v128_b111_decision_inbox_authority_resolver_consumption` (D92 3-block: DDL → REVOKE/GRANT re-harden → VERIFY fail-closed guard → NOTIFY pgrst). VERIFY guard included executor/transition/resolver/resolve/cancel md5 regression + expire-dependency md5 + anon/ACL assertions (all passed; no rollback). Canonicalized to RULES D371 · SYSTEM_MAP v1.59 (append-only, byte-prefix proven).

---

## Changed object

| Object | md5 BEFORE → AFTER | Change |
|---|---|---|
| `public.get_mission_control_decision_inbox()` | `47ca0947e7334ca8804a5c65c7b5f538` → `af21682de9aac3415d51231d83dc14e7` | embedded role-list early gate (`role IN (master_admin,sub_admin)` → `[]`) + caller-school predicate (`c.school_id = caller.school_id`) → per-candidate `_resolve_authority(caller, d.action_key, {school_id: c.school_id}, {requester_id: d.requested_by, phase:'resolve'})` eligibility filter; mirrors `resolve` byte-for-byte |

ACL preserved: `{authenticated,postgres,service_role}` (anon absent). Zero-arg signature + `jsonb` return contract unchanged. Coarse row-selection (`state='pending'` · `object_type='class'` · JOIN classes · `_mc_expire_decisions()` sweep · `ORDER BY created_at` · `[]` fallback) + self-exclusion (`requested_by <> caller`) preserved.

---

## Frozen objects (regression-proven UNCHANGED)

| Object | md5 | Verdict |
|---|---|---|
| `execute_mission_control_action` | `da733e9a636e9efd4457123e923057dd` | ✅ frozen (INVOKER) |
| `mc_internal._mc_transition_decision` | `fe0eea599db711fb8472b37a72fa25e4` | ✅ frozen |
| `mc_internal._resolve_authority` | `56b5e3f5a14360990b51c080ff1da1cb` | ✅ frozen (consume-only, STABLE) |
| `resolve_mission_control_decision` | `bb79a5217c3a739e08986e2ec7d62bc0` | ✅ frozen |
| `cancel_mission_control_decision` | `924c3f9ac9b80cfab6a65c00c927db0b` | ✅ frozen |
| `mc_internal._mc_expire_decisions` | `c57c40b88b77e838da137dd3e9cf59e7` | ✅ frozen (PERFORMed, not modified) |

Adapters · registry · policies · triggers · tables — **no schema change** (function-body-only migration). Inventory: public tables 94 · fns 253 · secdef 241 · policies 169 · triggers 34 · cron 1; `mc_internal` {9 fn / 8 secdef} + 1 table.

---

## Verification evidence

**Resolver-direct matrix (5/5):** master same-school → `authority_granted` · master cross-school → `organization_scope_mismatch` · platform super_admin → `authority_granted` · teacher self-requester → `self_decision_forbidden` · parent → `role_not_eligible`. (object_context `{school_id: class.school_id}`, decision_context `{requester_id, phase:'resolve'}` — identical to `resolve`.)

**Inbox↔resolver equivalence rehearsal (5/5, JWT-impersonated live inbox call, sentinel-rollback, 0 residue):** sentinel pending HIGH class decision seeded (requester = teacher), each caller impersonated via `request.jwt.claims`, actual `get_mission_control_decision_inbox()` called, membership compared to resolver verdict — `inbox_contains == resolver_eligible` for **every** caller: master-same=true/true · master-cross=false/false · **platform=true/true (flips false→true vs pre-migration, divergence fix)** · self=false/false · parent=false/false. RAISE-EXCEPTION rollback → sentinel decision + action_request residue **0**; decisions/transitions **0/0**.

**Structural regression:** inbox md5 changed `47ca0947…`→`af21682d…`; 5 frozen anchors + expire-dependency BEFORE==AFTER; ACL `{authenticated,postgres,service_role}`, anon absent; backend tail `20260819043435`→`20260819092150`.

**Honest boundary (NO over-claim):** verified **through resolver matrix + rolled-back rehearsal + runtime verification only** — NOT through committed production decisions (none exist; lifecycle dormant). Same discipline as B7/B8/B9.4/B10.1.

---

## Semantic finding (surfaced at implementation-D1, accepted by CTO APPLY)

**Platform-role inbox visibility** — post-migration, platform admins now SEE pending class decisions cross-tenant in their inbox. This is the projection catching up to enforcement (resolve already grants `platform_role` since B10.1/D370.5). **Zero enforcement privilege added**; zero production impact (lifecycle dormant). The `platform_role` divergence had two causes (role-list early gate + caller-school NULL-trap); both removed. Self-decision exclusion was already present pre-migration (`requested_by <> caller`) and is preserved (resolver `self_decision_forbidden` reproduces it) — no self-behavior change.

---

## Rollback assessment

Function-body-only, fully reversible: `CREATE OR REPLACE` inbox → B10.1 md5 (`47ca0947e7334ca8804a5c65c7b5f538`) + re-assert ACL `{authenticated,service_role}` + `NOTIFY pgrst`. **0 data-repair** (decisions/transitions 0/0; resolver/executor/transition/resolve/cancel untouched). No schema change to revert.

---

## Deferred scope (NOT authorized by B11.1)

First committed Gate B decision (arm contained reversible HIGH action) · Strangler Phase-3 (`assign_class_distribution` / class.assign executor authority — last ungated MEDIUM, dual-path MC + School Portal) · `child.transfer` / object-scope expansion · multi-approver/quorum · notification · inbox UI/FE · enum/taxonomy mint · `UNIQUE(user_id)` · delegation · Phase-4 (legacy admin RPCs).

---

## Boot pointer (next session)

Read canonical directly (never memory): `DMA_RULES.md` (→ **D371**) · `DMA_SYSTEM_MAP.md` (→ **v1.59**) · this handoff. **Re-pin endpoint:** RULES **D371** · SYSTEM_MAP **v1.59** · HANDOFF **V128-B11.1-IMPLEMENTATION-CLOSEOUT** · backend tail **`20260819092150`** · FE main pin `2.8.5`. Live anchors: executor `da733e9a…` (frozen) · transition `fe0eea59…` (frozen) · resolver `56b5e3f5…` (consume-only, frozen) · resolve `bb79a521…` · cancel `924c3f9a…` · inbox `af21682d…` (reconciled) · expire `c57c40b8…` · decisions/transitions 0/0 · registry class.edit gated / class.assign ungated / authority.probe. Next candidate: Strangler Phase-3 (class.assign executor) OR arm Gate B (first committed decision) — each needs explicit CTO authorization. Block D370/v1.58 (B10.1 decision authority implementation) = HISTORICAL SNAPSHOT (BẤT BIẾN).
