# 🧭 DMA_HANDOFF — V128-B13.2 · SET_DISTRIBUTION_LEAD AUTHORITY CONSUMPTION · IMPLEMENTATION CLOSEOUT

> **Milestone:** V128-B13.2 (lead-edit WHO → resolver, consume-only, via `class.assignment.lead.edit`)
> **Status:** ✅ **PASS** — `set_distribution_lead` authority is now RESOLVER-SOURCED; behaviour-preserving (OLD≡NEW verdicts). **Class-distribution WHO convergence COMPLETE.**
> **Date:** 2026-08-20
> **Supersedes endpoint:** V128-B13.1-IMPLEMENTATION-CLOSEOUT (D376/v1.64) → now **D377 / v1.65**.
> **Canonical:** RULES **D377** · SYSTEM_MAP **v1.65** · backend tail **`20260820092306`** · FE main pin **`2.8.5`**.

---

## 0 · Boot pin (verify at next session start — hard-stop on mismatch)

| Marker | Value |
|---|---|
| RULES endpoint | **D377** |
| SYSTEM_MAP | **v1.65** |
| HANDOFF | **V128-B13.2-IMPLEMENTATION-CLOSEOUT** (this) |
| Backend migration tail | **`20260820092306`** (`v128_b132_set_distribution_lead_resolver_who`) |
| Decision lifecycle | **1 decision / 2 transitions** (permanent; unchanged) |
| Registry rows | **4** (class.assign · class.edit · authority.probe · class.assignment.lead.edit) |
| FE main pin | `2.8.5` |

**Changed anchor:** `set_distribution_lead` `1dcc700fb007e25d740129190e221d54` → **`cd827fb288abff4f63a62305725448de`**
**Frozen anchors (must match):** resolver `56b5e3f5…` · executor `954bcc40…` · assign_class_distribution `069cb93c…` · class_edit_v1 `63f3ab5a…` · `_mc_begin_action` `54b5af57…` · `_mc_commit_action` `ce36c5fe…` · `_mc_open_decision` `b376edd7…`.

---

## 1 · What this milestone did

Replaced the embedded WHO-authority block in `public.set_distribution_lead` with a **consume-only** call to `mc_internal._resolve_authority(v_actor, 'class.assignment.lead.edit', {school_id}, null)`, consuming the B13.1 vocabulary key. Behaviour-preserving; external denial `not_authorized_for_school` and all domain reasons/ordering preserved. With B12 (`assign_class_distribution`), both class-distribution write paths now single-source WHO through the resolver → **class-distribution WHO convergence COMPLETE**. No decision opened; lifecycle stays 1/2; B11.2-B2 evidence untouched.

---

## 2 · Migration
- **Name:** `v128_b132_set_distribution_lead_resolver_who` · **tail:** `20260820070120` → **`20260820092306`**
- **Shape (D92 3-block):** DDL `CREATE OR REPLACE` (WHO → resolver consume-only; domain/audit byte-preserved; ordering unchanged) → REVOKE ALL FROM PUBLIC/anon/authenticated/service_role + GRANT EXECUTE authenticated,service_role → `DO $verify$` 14-assertion fail-closed guard → `NOTIFY pgrst`. Rehearsed rolled-back (zero residue) before apply.

---

## 3 · Authority change
**Old:** `is_admin() OR (current_profile_role() IN ('master_admin','sub_admin') AND v_school = ANY(user_school_ids()))` → else `not_authorized_for_school`.
**New:** `NOT coalesce((_resolve_authority(v_actor,'class.assignment.lead.edit',{school_id},null)->>'eligible')::bool,false)` → `not_authorized_for_school`. Reason codes NOT surfaced. `is_admin()` role-set ≡ resolver platform set → no broadening.

## 4 · set_distribution_lead OLD → NEW md5
`1dcc700fb007e25d740129190e221d54` → **`cd827fb288abff4f63a62305725448de`**.

## 5 · Authority-equivalence matrix (rolled-back rehearsal; OLD verdict == NEW verdict, EQUIV:true)
AUTH-1 master same-school **ALLOW** · AUTH-2 sub_admin same-school **ALLOW** (resolver code branch; 0 live fixture — epistemic limit) · AUTH-3 cross-school master **DENY** `not_authorized_for_school` · AUTH-4 teacher **DENY** · AUTH-5 parent **DENY** · AUTH-6 platform admin (exact `is_admin` role-set) **ALLOW**. No broadening / narrowing.

## 6 · Domain regression (rolled-back)
D1 `distribution_not_found` · D4 cross-school lead → `lead_teacher_invalid` · D5 valid change → `{ok:true}`, row updated in-txn + `distribution_lead_changed` audit (delta 1) · D6 idempotent → `{ok:true, already:true}`. D2 orphaned / D3 inactive: no live fixture → byte-preserved structural.

## 7 · Caller-contract regression
Direct RPC jsonb contract + error strings unchanged. **No ledger row · no request_id · no decision opened · vocabulary row not dispatched.** No FE change (exact FE hook not enumerated this run; contract-preserving).

## 8 · ACL / SECURITY posture (preserved)
SECURITY DEFINER · owner postgres · `search_path=""` · returns jsonb · args unchanged · EXECUTE {authenticated, postgres, service_role}; 0 anon/PUBLIC leak.

## 9 · Frozen hashes & lifecycle
Resolver `56b5e3f5…` · executor `954bcc40…` · assign `069cb93c…` · class_edit `63f3ab5a…` · begin `54b5af57…` · commit `ce36c5fe…` · open_decision `b376edd7…` — UNCHANGED. Registry `class.assignment.lead.edit` unchanged (non-dispatch). Lifecycle **1 / 2**. B11.2-B2: decision `5d3b8897…` approved · request `b112b2b2-…-f1`.

## 10 · Class-distribution WHO convergence — COMPLETE
Creation (`assign_class_distribution`, D375) + lead-edit (`set_distribution_lead`, D377) both resolver-sourced.

## 11 · Known adjacent authority debt (OUTSIDE B13)
Six public RPCs still carry the legacy `user_school_ids() + not_authorized_for_school` idiom: `cancel_lesson_session`, `create_lesson_session`, `update_lesson_session`, `set_session_teachers`, `get_child_parents`, `provision_parent_and_link`. Each needs its own CTO gate. **Not full DMA-RPC authority convergence.**

## 12 · Rollback (recorded; NOT performed)
`CREATE OR REPLACE public.set_distribution_lead` back to md5 `1dcc700f…` + re-assert ACL `{authenticated,service_role}` (owner postgres) + `NOTIFY pgrst`. 0 data-repair.

---

## 13 · NEXT (recommendation)
**➡ VISIBLE FE BUILD — Class Workspace / `class.edit` slice.** Backend authority foundations for the class surface are now converged and stable; the highest-leverage next step is user-visible: wire the School/Teacher Class Workspace and the `class.edit` action into the FE (`class.edit` remains LOW · authority_gated=true, adapter live). Defer further backend authority sweeps (the 6 legacy RPCs) to dedicated gates.

---

## 14 · Canonical integrity (this closeout)
- `DMA_RULES.md` — base (D376) + **D377**. Prefix-SHA proof PASS (`1df45c26…` == final[0:1122596]); final `48b5a2a32b0b86dc4853972bc7115e5140d39c681974214479c65e7ca39aacad`.
- `DMA_SYSTEM_MAP.md` — base (v1.64) + **v1.65**. Prefix-SHA proof PASS (`288dd22d…` == final[0:618452]); final `7f7cddcf3414db8f28543e707b49dcc8514ff52f1720ff6e2284c0ffb21bea74`.

See `DMA_V128-B13_2_APPEND_ONLY_INTEGRITY_REPORT.md`.
