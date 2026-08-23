# DMA HANDOFF — V128-B10.1 · DECISION AUTHORITY RESOLUTION STRANGLER — IMPLEMENTATION CLOSEOUT

**Milestone:** V128-B10.1 IMPLEMENTATION — Strangler **Phase-2**. Approver-side Decision Authority (resolve/reject/cancel) migrated from embedded decision-RPC checks into **Authority Resolver consumption**. Requester-side (Gate A) unchanged.
**Mode:** IMPLEMENTATION (applied). 1 migration, D92 3-block atomic. Verified by resolver-direct matrix + JWT-impersonated rolled-back RPC rehearsal (zero residue).
**Date:** 2026-08-19
**Status:** ✅ **LIVE + VERIFIED.** Governed decision lifecycle remains **DORMANT** (0/0). **No canonical append performed** (separate CTO authorization required).

---

## Boot verification (STEP 0)

| Check | Required | Live at start | Status |
|---|---|---|---|
| `DMA_RULES.md` | D369 | D369 | ✅ |
| `DMA_SYSTEM_MAP.md` | v1.57 | v1.57 | ✅ |
| Handoff | V128-B10.1-DESIGN-FREEZE | present | ✅ |
| Backend tail at start | `20260816094225` | matched | ✅ |
| Executor md5 | `da733e9a…` | matched | ✅ |
| Transition controller md5 | `fe0eea59…` | matched | ✅ |
| FE main pin | `2.8.5` | matched | ✅ |

STOP conditions checked at STEP 0: canonical drift ✗ · resolver contract mismatch ✗ · unexpected executor change ✗ · transition controller change ✗. Policy/trigger raw counts (171/40) reconciled to app-scope 169/34 (delta = cron/realtime/storage schemas); migration-tail invariance proved zero schema change.

**⭐ D369.7 assumption CONFIRMED at audit:** live `_resolve_authority` body already branches on `p_decision_context` (`requester_id` + `phase`), emitting `self_decision_forbidden` when `requester_id=actor AND phase IN ('approve','resolve')`. Therefore B10.1 = **true consume-only**; resolver body byte-unchanged.

---

## What was applied (1 migration)

| tail | migration | scope |
|---|---|---|
| `20260819043435` | `v128_b101_decision_authority_resolver_consumption` | REPLACE `resolve_mission_control_decision` + `cancel_mission_control_decision` bodies → single `_resolve_authority(...)` consumption; D15/D231 REVOKE/GRANT re-assert; VERIFY fail-closed guard (incl. executor/transition/resolver md5 regression); NOTIFY pgrst |

**In-migration VERIFY guard (fail-closed, atomic):** resolver-consumption present in both fns · phase tokens `'resolve'`/`'cancel'` present · **no residual `master_admin`/`sub_admin` literals** · SECDEF + `search_path` pinned · anon has NO execute · executor md5 == `da733e9a…` · transition md5 == `fe0eea59…` · resolver md5 == `56b5e3f5…`. All passed (no rollback).

---

## Changed object list

| Object | Change |
|---|---|
| `public.resolve_mission_control_decision(uuid,text,text)` | Body REPLACE — embedded `role IN(master/sub) AND same-school` + `self=requested_by` → `_resolve_authority(caller, D.action_key, {school_id:v_school}, {requester_id:D.requested_by, phase:'resolve'})`; deny raises `reason_codes[0]`. Residual `v_role`/`v_cschool` computation **removed** (authority 100% resolver-owned). |
| `public.cancel_mission_control_decision(uuid,text)` | Body REPLACE — opener fast-path retained (`v_caller=D.requested_by` = ownership, not authority); third-party branch → `_resolve_authority(..., phase:'cancel')`. Residual role/school computation removed. |

**NOT modified (regression-proven UNCHANGED):** `execute_mission_control_action` · `mc_internal._mc_transition_decision` · `mc_internal._resolve_authority` (body+ACL) · `_mc_open_decision` · `_mc_expire_decisions` · adapters · registry · policies · triggers · tables.
**NOT modified (deferred sub-item):** `get_mission_control_decision_inbox` — still embedded master/sub+same-school+not-self projection; diverges from resolver on `platform_role` (platform admins do not see inbox). Recorded as open follow-on (STEP 2 recommendation = defer; CTO APPLY accepted).

---

## Hash comparison

| Function | BEFORE | AFTER | Verdict |
|---|---|---|---|
| `resolve_mission_control_decision` | `c6208c6dbd8b1dac946735629e52d7d0` | `bb79a5217c3a739e08986e2ec7d62bc0` | CHANGED (intended) |
| `cancel_mission_control_decision` | `4c4eecc55eb9467aee6c88f41ed6f0b6` | `924c3f9ac9b80cfab6a65c00c927db0b` | CHANGED (intended) |
| `execute_mission_control_action` | `da733e9a636e9efd4457123e923057dd` | `da733e9a636e9efd4457123e923057dd` | ✅ UNCHANGED |
| `_mc_transition_decision` | `fe0eea599db711fb8472b37a72fa25e4` | `fe0eea599db711fb8472b37a72fa25e4` | ✅ UNCHANGED |
| `_resolve_authority` | `56b5e3f5a14360990b51c080ff1da1cb` | `56b5e3f5a14360990b51c080ff1da1cb` | ✅ UNCHANGED (consume-only) |

**ACL preserved:** `resolve` + `cancel` = `{authenticated,postgres,service_role}` (anon absent). Migration tail `20260816094225` → `20260819043435`. FE main pin `2.8.5`, 0 change.

---

## Verification report

**A/B — Resolver verdict matrix (10/10, read-only direct):** master same-school resolve → `organization_role/authority_granted` · master **SELF** approve & resolve → `self_decision_forbidden` · master cross-school → `organization_scope_mismatch` · teacher/parent → `role_not_eligible` · **platform → `platform_role/authority_granted`** · master self-**cancel** → NOT forbidden (asymmetry correct) · teacher cross cancel → `role_not_eligible`.

**RPC rehearsal (7/7, JWT-impersonated, sentinel-rollback, 0 residue):**
- R1 master same-school non-self approve → `OK/approved`
- R2 master cross-school approve → `DENY/organization_scope_mismatch`
- R3 opener self-approve → `DENY/self_decision_forbidden`
- R4 opener self-**reject** → `DENY/self_decision_forbidden` (proves `phase='resolve'` covers reject)
- C1 opener self-cancel → `OK/cancelled` (ownership fast-path)
- C2 cross-school third-party cancel → `DENY/organization_scope_mismatch`
- C3 admin same-school third-party cancel → `OK/cancelled`

**C — Regression:** executor + transition controller md5 BEFORE==AFTER ✅.
**D — Lifecycle:** transitions unchanged; terminal protection + append-only intact (`_mc_transition_decision` md5-frozen; 0 writes committed).
**E — Scope:** no HIGH/CRITICAL action activated (registry: class.edit gated / class.assign ungated / authority.probe ungated); no committed production decision; decisions/transitions **0/0**; rehearsal residue **0**.

**Freeze STEP-4 matrix satisfied end-to-end:** approve=DENIED · reject=DENIED · cancel=ALLOWED · reason `self_decision_forbidden`.

---

## Semantic findings realized (surfaced at STEP 2, accepted by CTO APPLY)

1. **Platform-role broadening (decide side).** Embedded logic granted only master/sub same-school; resolver also grants `platform_role`. Single-source now lets platform admins decide/cancel (Risk-3 divergence fix). Proven at resolver matrix case 7 + verbatim consumption. **Zero production impact** (lifecycle dormant). No committed decision exists.
2. **Phase-token convention.** RPC passes `phase='resolve'` (not the verdict) so both approve AND reject are self-forbidden by the resolver's `('approve','resolve')` branch — no resolver vocabulary change. Proven by R4.
3. **Opener-cancel = ownership, not authority.** Retained locally as a fast-path (analogous to RLS `select_own`); only third-party cancel consults the resolver. Proven by C1 (allow) vs C2/C3.

**No duplicated authority ownership remains** in resolve/cancel: verdict fully resolver-sourced; RPCs retain only identity (`current_profile`), object-context (`v_school`), lifecycle guards, and the cancel ownership fast-path.

**Honest epistemics (no over-claim):** the migrated approver path is proven by resolver-direct matrix + rolled-back RPC rehearsal, **not** by committed production decisions (none exist; lifecycle dormant). Same discipline as B7/B8/B9.4.

---

## Rollback assessment

**Rollback (if Owner reverts B10.1 — NOT performed here):**
1. `CREATE OR REPLACE public.resolve_mission_control_decision(uuid,text,text)` → B8 body (md5 `c6208c6dbd8b1dac946735629e52d7d0`).
2. `CREATE OR REPLACE public.cancel_mission_control_decision(uuid,text)` → B8 body (md5 `4c4eecc55eb9467aee6c88f41ed6f0b6`).
3. Re-assert ACL: `REVOKE ALL … FROM PUBLIC,anon,authenticated,service_role` → `GRANT EXECUTE … TO authenticated,service_role`.
4. `NOTIFY pgrst, 'reload schema'`.

**Data-repair: none** — decisions/transitions 0/0; no committed decision; resolver/executor/transition controller untouched. Fully reversible, function-body-only.

---

## Deferred (NOT authorized by B10.1 implementation)

- **Canonical closeout** (RULES D-append + SYSTEM_MAP bump) — requires separate CTO authorization.
- Inbox resolver-consistency (`get_mission_control_decision_inbox` platform-role divergence).
- Arming Gate B / first committed decision (contained reversible HIGH action) — first lifecycle run on committed data.
- Object-scope expansion (`child.transfer`, session, school) · multi-approver/quorum · enum/taxonomy mint · `UNIQUE(user_id)` · delegation · notification · inbox UI · FE wiring · Strangler Phase-3 (`assign_class_distribution`) · Phase-4 (legacy admin RPCs).

---

## Boot pointer (next session)

Read canonical directly (never memory): `DMA_RULES.md` (→ D369) · `DMA_SYSTEM_MAP.md` (→ v1.57) · design-freeze handoff · this implementation closeout. **Live re-pin:** backend tail **`20260819043435`** · executor `da733e9a…` (frozen) · transition `fe0eea59…` (frozen) · resolver `56b5e3f5…` (consume-only, frozen) · resolve `bb79a521…` · cancel `924c3f9a…` · decisions/transitions 0/0 · registry class.edit gated / class.assign ungated. **Canonical still at D369/v1.57** (implementation applied but NOT yet canonicalized — awaits CTO canonical-closeout authorization).
