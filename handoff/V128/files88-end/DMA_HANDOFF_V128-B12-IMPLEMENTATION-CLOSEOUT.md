# 🧭 DMA_HANDOFF — V128-B12 · STRANGLER PHASE-3 · CLASS.ASSIGN AUTHORITY CONSUMPTION · IMPLEMENTATION CLOSEOUT

> **Milestone:** V128-B12 (Strangler Phase-3 — `assign_class_distribution` WHO-authority → resolver, consume-only)
> **Status:** ✅ **PASS** — class.assign creation authority is now RESOLVER-SOURCED; both write paths converge. Behaviour-preserving.
> **Date:** 2026-08-20
> **Supersedes endpoint:** V128-B11.2-B2-FIRST-COMMITTED-DECISION-CLOSEOUT (D374/v1.62) → now **D375 / v1.63**.
> **Canonical:** RULES **D375** · SYSTEM_MAP **v1.63** · backend tail **`20260820070120`** · FE main pin **`2.8.5`**.

---

## 0 · Boot pin (verify at next session start — hard-stop on mismatch)

| Marker | Value |
|---|---|
| RULES endpoint | **D375** |
| SYSTEM_MAP | **v1.63** |
| HANDOFF | **V128-B12-IMPLEMENTATION-CLOSEOUT** (this) |
| Backend migration tail | **`20260820070120`** (`v128_b12_assign_class_distribution_resolver_who`) |
| Decision lifecycle | **ACTIVE — decisions 1 / transitions 2** (unchanged from B11.2-B2; no new decision in B12) |
| Registry `class.assign` | **MEDIUM · active · authority_gated=false** — WHO now resolver-sourced |
| Registry `class.edit` | **LOW · active · authority_gated=true** |
| FE main pin | `2.8.5` |

**Changed anchor:** `assign_class_distribution` `03a1510bd827c03a650a3a88312fbe3a` → **`069cb93c0f7de2e5a933662b8cb9e644`**
**Frozen anchors (must match):** executor `954bcc40…` · resolver `56b5e3f5…` · authority_gate `bc5ea1a2…` · begin `54b5af57…` · commit `ce36c5fe…` · open_decision `b376edd7…` · transition `fe0eea59…` · class_edit_v1 `63f3ab5a…` · resolve `bb79a521…` · inbox `af21682d…` · **set_distribution_lead `1dcc700fb007e25d740129190e221d54`** (deferred)

---

## 1 · What this milestone did

Replaced the embedded WHO-authority block in `public.assign_class_distribution` with a **consume-only** call to `mc_internal._resolve_authority('class.assign', {school_id})`. Both the Mission Control path and the direct School-Portal path now single-source WHO through the resolver (**Resolver = WHO · Adapter = HOW**). The legacy `is_admin() OR (master/sub same-school)` idiom is gone; the external denial contract `not_authorized_for_school` is preserved. Domain safety stays in the adapter. `class.assign` stays MEDIUM · ungated (no Gate B, no committed decision); lifecycle stays **1/2**; B11.2-B2 evidence untouched.

---

## 2 · Migration

- **Name:** `v128_b12_assign_class_distribution_resolver_who` · **tail:** `20260820021437` → **`20260820070120`**
- **Shape (D92 3-block):** DDL `CREATE OR REPLACE` (WHO block → resolver consume-only; domain safety byte-preserved) → REVOKE ALL FROM PUBLIC/anon/authenticated/service_role + GRANT EXECUTE authenticated,service_role → `DO $verify$` fail-closed guard (10 assertions) → `NOTIFY pgrst`.
- **First attempt:** FAILED inside VERIFY on an `aclexplode` query typo (`s.a`) → **atomic rollback, zero residue, no tail advance**, `assign_class_distribution` stayed `03a1510b…`. Corrected re-apply PASS.

---

## 3 · Authority change

**Old:** `is_admin() OR (current_profile_role() IN ('master_admin','sub_admin') AND v_school_id = ANY(user_school_ids()))` → else `not_authorized_for_school`.
**New:** `NOT coalesce((_resolve_authority(current_profile(),'class.assign',{school_id},null)->>'eligible')::bool,false)` → `not_authorized_for_school`. Reason codes NOT surfaced. `is_admin()` role-set ≡ resolver platform-role set → **no broadening**.

---

## 4 · Verification (rolled-back rehearsals, zero residue)

**Authority (resolver the adapter consumes):** master same-school ALLOW · sub_admin same-school ALLOW by code (0 live) · cross-school DENY · teacher DENY · parent DENY · platform ALLOW.
**Domain (through migrated fn):** `class_not_found` · `subject_not_entitled` · `lead_teacher_invalid` · `distribution_exists` · fresh success + `CLASS_ASSIGNMENT_CREATED` audit · resolver-ineligible → `not_authorized_for_school`.
**MC path:** `class.assign` MEDIUM auto-execute → `ok:true, CLASS_ASSIGNMENT_CREATED, replayed:false`, **no decision opened**, `authority_gated` false, ledger unchanged.

---

## 5 · ACL / SECURITY posture (preserved)
SECURITY DEFINER · owner postgres · returns uuid · `search_path=""` · args unchanged · EXECUTE {authenticated, service_role, postgres}; 0 anon/PUBLIC leak.

## 6 · Frozen hashes & lifecycle
All 11 anchors unchanged (executor, resolver, authority_gate, begin, commit, open_decision, transition, class_edit_v1, resolve, inbox, **set_distribution_lead**). Lifecycle **1 / 2**. Proof decision `5d3b8897…` approved · proof request `b112b2b2-…-f1` completed · proof class `MC-B11.2-B2-FIXTURE-PROOF`. Residue: class_distributions 21 · class.assign action_requests 12 · no pilot mutation.

---

## 7 · Deferred — set_distribution_lead

`public.set_distribution_lead` (md5 `1dcc700f…`, UNCHANGED) still contains the **legacy embedded WHO idiom** on the lead-edit path. **KNOWN / DEFERRED.** B12 closes **class.assign creation** authority divergence ONLY — it does NOT claim full class-distribution authority convergence.

**Next-milestone candidate:** `set_distribution_lead` resolver consumption (adjacent divergence) — requires a separate CTO gate.

---

## 8 · Canonical integrity (this closeout)
- `DMA_RULES.md` — base (D374) + **D375**. Prefix-SHA proof PASS (`0bc3faa5…` == final[0:1101620]); final `1c5515df9a276df74a2c4e8790a225efe103ff02270bd0244ef0dfe1ffba344b`.
- `DMA_SYSTEM_MAP.md` — base (v1.62) + **v1.63**. Prefix-SHA proof PASS (`a5210f8b…` == final[0:607271]); final `bd9c56af2c0a608863a6f6024c1a9ffd1510e949894adc9057fd6454db1039e5`.

See `DMA_V128-B12_APPEND_ONLY_INTEGRITY_REPORT.md`.
