# 🧭 DMA_HANDOFF — V128-B11.2-B1 · APPROVED PAYLOAD BINDING · IMPLEMENTATION CLOSEOUT

> **Milestone:** V128-B11.2-B1 (approved-payload binding — `intent_fingerprint` binds the governed class.edit payload)
> **Status:** ✅ **CLOSED** — D372.8 Flag 2 resolved; approved WHAT = executed WHAT. INERT, zero residue.
> **Date:** 2026-08-20
> **Supersedes endpoint:** V128-B11.2-A-AMENDMENT-CLOSEOUT (D372/v1.60) → now D373/v1.61.
> **Canonical:** RULES **D373** · SYSTEM_MAP **v1.61** · backend tail **`20260820021437`** · FE main pin **`2.8.5`**.

---

## 0 · Boot pin (verify at next session start — hard-stop on mismatch)

| Marker | Value |
|---|---|
| RULES endpoint | **D373** |
| SYSTEM_MAP | **v1.61** |
| HANDOFF | **V128-B11.2-B1-IMPLEMENTATION-CLOSEOUT** (this) |
| Backend migration tail | **`20260820021437`** (`v128_b112b1_bind_class_edit_payload_into_fingerprint`) |
| Decision lifecycle | **DORMANT — decisions 0 / transitions 0** (one-way door NOT opened) |
| Registry `class.edit` | **LOW · active · authority_gated=true** (NOT elevated) |
| FE main pin | `2.8.5` |

**Changed anchors:** `_mc_begin_action` `f47260ef…` → **`54b5af575f1a0aa8217e6eac979d6014`** · `execute_mission_control_action` `2228611a…` → **`954bcc4087ea0646c60c01cc28717e79`**
**Frozen anchors (must match):** commit `ce36c5fe…` · open_decision `b376edd7…` · transition `fe0eea59…` · resolver `56b5e3f5…` · gate `bc5ea1a2…` · class_edit_v1 `63f3ab5a…` · resolve `bb79a521…` · cancel `924c3f9a…` · inbox `af21682d…` · assign_class_distribution `03a1510b…`

---

## 1 · What this milestone did

Closed **D372.8 Flag 2**. Before B1, the class.edit decision fingerprint bound only `(action, object, school)` — `program_id`/`lead_teacher_id` are null for class.edit — so `name`/`age_group_id`/`level_id` were unbound and a decision approved for payload **A** could resume and execute payload **B**. Strategy **A1**: the executor builds a server-normalized `fp_input` for class.edit and passes it to `_mc_begin_action`, which folds it into the canonical `intent_fingerprint`. class.assign passes NULL and keeps its historical formula byte-for-byte. Drift now trips the **existing** executor conflict guard → `MC_ACTION_REQUEST_CONFLICT`, 0 mutation. **INERT:** class.edit stays LOW; lifecycle 0/0; Gate β not opened.

---

## 2 · Migration

- **Name:** `v128_b112b1_bind_class_edit_payload_into_fingerprint` · **tail:** `20260819182957` → **`20260820021437`**
- **Shape (atomic):** DROP+CREATE `_mc_begin_action` (8-arg, +`p_fp_input jsonb DEFAULT NULL`) → begin REVOKE/GRANT → CREATE OR REPLACE executor → executor REVOKE/GRANT → `DO $verify$` fail-closed guard → `NOTIFY pgrst`.
- **VERIFY guard asserted:** begin 8-arg signature exactly 1 · old 7-arg absent · begin SECURITY DEFINER · begin & executor ACL `{authenticated,postgres}` with 0 anon/service_role/PUBLIC leak · executor INVOKER · executor builds+passes `v_fp_input`.

---

## 3 · Normalization contract (class.edit `fp_input`)

Server-built deterministic jsonb; a key is included **only when present** in `p_input`:
- `name` → value as `class_edit_v1` consumes it (text, **untrimmed**).
- `age_group_id` / `level_id` → uuid-canonicalized (`nullif(x,'')::uuid` → canonical text or JSON null; invalid uuid guarded to raw text so the adapter still rejects unchanged).
- **absent ≠ explicit null** (clearing a field is a distinct intent). JSON key/text order irrelevant (jsonb canonical). Raw `p_input::text` never hashed; no `jsonb_strip_nulls`. Unknown keys rejected upstream by input_schema validation.

---

## 4 · Verification matrix (rolled-back, JWT-impersonated, zero residue)

| | Test | Result |
|---|---|---|
| A1 | class.assign existing-pair conflict | ✅ `MC_ACTION_CONFLICT` |
| A2 | class.assign fresh free-pair | ✅ `ok:true, CLASS_ASSIGNMENT_CREATED` |
| A3 | class.assign fingerprint pre/post | ✅ **byte-identical** (`7cb4a821f813…`) |
| E1 | class.edit identical resume | ✅ `ok:true, CLASS_UPDATED` |
| E2 | changed governed value (Alpha→Beta) | ✅ `MC_ACTION_REQUEST_CONFLICT`, 0 mutation |
| E3 | reordered JSON keys | ✅ `ok:true` (same fp) |
| E4 | one governed field changed (age X→Y) | ✅ `MC_ACTION_REQUEST_CONFLICT`, 0 mutation |
| E5 | unknown field | ✅ `MC_ACTION_INPUT_INVALID` |
| E6 | absent vs explicit-null | ✅ different fingerprints |
| E7 | adapter validation (identical `{}` resume) | ✅ `MC_ACTION_INPUT_INVALID` (no_editable_fields), class unchanged |
| Flag 1 | replay (same reqid + same payload) | ✅ no duplicate effective mutation |

---

## 5 · class.assign compatibility

class.assign passes `p_fp_input = NULL` → begin reproduces the exact pre-B1 canonical `input:{program_id, lead_teacher_id}`. A3 confirmed the recomputed fingerprint equals the pre-B1 formula byte-for-byte, so the 12 existing assign ledger rows and assign replays are intact.

---

## 6 · Rollback (fully reversible; NOT performed)

DROP+CREATE `_mc_begin_action` back to `f47260ef…` (drop `p_fp_input`) + re-ACL; CREATE OR REPLACE executor back to `2228611a…` + re-ACL; `NOTIFY pgrst`. **0 data-repair** (lifecycle 0/0; no schema change; class.edit had 0 ledger/decision rows). Reverting reopens the (dormant, LOW-shielded) Flag-2 gap.

---

## 7 · Zero-residue state (live, post-rollback)

class.edit **LOW** · decisions **0** · transitions **0** · class.edit action_requests **0** · QA + demo class names original · total action_requests **12** · no registry residue · **no committed one-way-door evidence**.

---

## 8 · Gate β status & next milestone

**Gate β REMAINS CLOSED.** Both D372.8 preconditions are now resolved — Flag 1 (approved-resume idempotency) CLOSED/PASS, Flag 2 (approved payload binding) CLOSED/PASS — so the technical preconditions for the first committed governed decision are met.

**Next milestone → V128-B11.2-B2 · FIRST COMMITTED DECISION ACTIVATION (Gate β)** — separate CTO re-gate: seed dedicated synthetic fixture (G4; pilots off-limits) · registry class.edit **LOW→HIGH** · **first COMMITTED decision** (permanently opens the one-way door 0/0 → 1/2) · data rollback + disarm + Gate β canonical closeout. **NOT authorized by this milestone.**

---

## 9 · Canonical sync (this session — FULL files assembled, append-only proven)

- [x] `DMA_RULES.md` — base (D372) + **D373**. Prefix-SHA proof PASS (`7e54fc4f…` == final[0:1078487]); final `c5c92948…`.
- [x] `DMA_SYSTEM_MAP.md` — base (v1.60) + **v1.61**. Prefix-SHA proof PASS (`37bbfa0c…` == final[0:596235]); final `75ef1c4f…`.
- [x] `DMA_HANDOFF_V128-B11_2-B1-IMPLEMENTATION-CLOSEOUT.md` (this).
- [x] `DMA_V128-B11.2-B1_APPEND_ONLY_INTEGRITY_REPORT.md`.

*Byte-safe append-only: content through D372 / v1.60 is byte-identical to base; no history rewrite, no renumbering. Files NOT uploaded to Project Knowledge.*
