# DMA HANDOFF — V128-B10.1 · DECISION AUTHORITY RESOLUTION STRANGLER — IMPLEMENTATION CLOSEOUT

**Milestone:** V128-B10.1 IMPLEMENTATION — Strangler **Phase-2**. Approver-side Decision Authority (resolve/reject/cancel) migrated from embedded decision-RPC checks into **Authority Resolver consumption**. Requester-side (Gate A) unchanged.
**Mode:** IMPLEMENTATION (applied) + CANONICALIZED. 1 migration (D92 3-block atomic). Verified by resolver-direct matrix + JWT-impersonated rolled-back RPC rehearsal (zero residue).
**Date:** 2026-08-19
**Status:** ✅ **IMPLEMENTATION: CLOSED — LIVE + VERIFIED + CANONICALIZED.** Governed decision lifecycle remains **DORMANT** (0/0).
**Canonical endpoint after append:** RULES **D370** · SYSTEM_MAP **v1.58** · HANDOFF **V128-B10.1-IMPLEMENTATION-CLOSEOUT** · backend tail **`20260819043435`** · FE main pin `2.8.5`.

---

## Milestone identity

Implementation of the D369-ratified B10.1 design freeze. Two authority questions now answered by ONE primitive `_resolve_authority`: requester authority (Gate A, unchanged since D368) + approver authority (resolve/reject/cancel, migrated here). Single-source policy verdict (D366.4); RLS + lifecycle controller still enforce independently.

---

## Implementation status

**CLOSED.** Applied via migration `20260819043435` `v128_b101_decision_authority_resolver_consumption` (D92 3-block: DDL → REVOKE/GRANT → VERIFY fail-closed guard → NOTIFY pgrst). VERIFY guard included executor/transition/resolver md5 regression assertions (all passed; no rollback). Canonicalized to RULES D370 · SYSTEM_MAP v1.58 (append-only, byte-prefix proven).

---

## Changed objects

| Object | md5 BEFORE → AFTER | Change |
|---|---|---|
| `public.resolve_mission_control_decision(uuid,text,text)` | `c6208c6dbd8b1dac946735629e52d7d0` → `bb79a5217c3a739e08986e2ec7d62bc0` | embedded `role IN(master/sub) AND same-school` + self-check → `_resolve_authority(caller, D.action_key, {school_id}, {requester_id, phase:'resolve'})`; residual role/school computation removed |
| `public.cancel_mission_control_decision(uuid,text)` | `4c4eecc55eb9467aee6c88f41ed6f0b6` → `924c3f9ac9b80cfab6a65c00c927db0b` | opener fast-path retained (ownership); third-party branch → `_resolve_authority(..., phase:'cancel')`; residual role/school removed |

ACL preserved on both: `{authenticated,postgres,service_role}` (anon absent).

---

## Unchanged anchors (regression-proven)

| Object | md5 | Verdict |
|---|---|---|
| `execute_mission_control_action` | `da733e9a636e9efd4457123e923057dd` | ✅ frozen |
| `mc_internal._mc_transition_decision` | `fe0eea599db711fb8472b37a72fa25e4` | ✅ frozen |
| `mc_internal._resolve_authority` | `56b5e3f5a14360990b51c080ff1da1cb` | ✅ frozen (consume-only, D369.7) |

Adapters · registry · policies · triggers · tables — **no schema change** (function-body-only migration). Inventory: public tables 94 · fns 253 · secdef 241 · policies 169 · triggers 34 · cron 1; `mc_internal` {9 fn / 8 secdef} + 1 table.

---

## Verification evidence

**Resolver-direct matrix (10/10):** master same-school → `organization_role/authority_granted` · master SELF approve & resolve → `self_decision_forbidden` · cross-school → `organization_scope_mismatch` · teacher/parent → `role_not_eligible` · platform → `platform_role/authority_granted` · master self-cancel → not-forbidden (asymmetry) · teacher cross-cancel → `role_not_eligible`.

**RPC rehearsal (7/7, JWT-impersonated, sentinel-rollback, 0 residue):** R1 master approve → OK/approved · R2 cross approve → DENY/`organization_scope_mismatch` · R3 opener self-approve → DENY/`self_decision_forbidden` · R4 opener self-**reject** → DENY/`self_decision_forbidden` (phase='resolve' covers reject) · C1 opener self-cancel → OK/cancelled (ownership) · C2 cross third-party cancel → DENY/`organization_scope_mismatch` · C3 admin same-school cancel → OK/cancelled.

**Freeze STEP-4 matrix satisfied:** approve=DENIED · reject=DENIED · cancel=ALLOWED · reason `self_decision_forbidden`. Regression: executor + transition controller BEFORE==AFTER. Lifecycle: transitions/terminal-protection/append-only intact. Scope: no HIGH action activated; no committed decision; decisions/transitions **0/0**; rehearsal residue **0**.

**Honest boundary (NO over-claim):** verified **through rehearsal + runtime verification only** — NOT through committed production decisions (none exist; lifecycle dormant). Same discipline as B7/B8/B9.4.

---

## Semantic findings (surfaced at STEP 2, accepted by CTO APPLY)

1. **Platform-role broadening** — resolver grants `platform_role` (embedded logic did not); platform admins now eligible to decide/cancel (intended Risk-3 divergence fix). Zero production impact (dormant).
2. **Phase-token convention** — `resolve` passes `phase='resolve'` (not the verdict) so approve+reject both self-forbidden; no resolver vocabulary change.
3. **Opener-cancel = ownership** — retained as a fast-path (RLS-like), not authority; only third-party cancel consults the resolver.

**No duplicated authority ownership** remains in resolve/cancel; verdict fully resolver-sourced.

---

## Rollback assessment

Function-body-only, fully reversible: `CREATE OR REPLACE` both RPCs → B8 md5 (`c6208c6d…` / `4c4eecc5…`) + re-assert ACL `{authenticated,service_role}` + `NOTIFY pgrst`. **0 data-repair** (decisions/transitions 0/0; resolver/executor/transition controller untouched).

---

## Deferred scope (NOT authorized by B10.1)

Inbox resolver-consistency (`get_mission_control_decision_inbox` still embedded; diverges on `platform_role`) · arming Gate B / first committed decision (contained reversible HIGH action) · `child.transfer` / object-scope expansion · multi-approver/quorum · enum/taxonomy mint · `UNIQUE(user_id)` · delegation · notification · inbox UI · FE wiring · Strangler Phase-3 (`assign_class_distribution`) · Phase-4 (legacy admin RPCs).

---

## Boot pointer (next session)

Read canonical directly (never memory): `DMA_RULES.md` (→ **D370**) · `DMA_SYSTEM_MAP.md` (→ **v1.58**) · this handoff. **Re-pin endpoint:** RULES **D370** · SYSTEM_MAP **v1.58** · HANDOFF **V128-B10.1-IMPLEMENTATION-CLOSEOUT** · backend tail **`20260819043435`** · FE main pin `2.8.5`. Live anchors: executor `da733e9a…` (frozen) · transition `fe0eea59…` (frozen) · resolver `56b5e3f5…` (consume-only, frozen) · resolve `bb79a521…` · cancel `924c3f9a…` · decisions/transitions 0/0 · registry class.edit gated / class.assign ungated. Block D369/v1.57 (B10.1 design-freeze ratification) = HISTORICAL SNAPSHOT (BẤT BIẾN).
