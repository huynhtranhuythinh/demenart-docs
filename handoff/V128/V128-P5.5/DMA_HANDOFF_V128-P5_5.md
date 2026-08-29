# 🗂️ DMA_HANDOFF — V128-P5.5 · TEACHER ASSIGNMENT RUNTIME QA — CANONICAL CLOSEOUT

**Status:** ✅ **P5.5 RATIFIED — PASS** · Actual defects: **NONE** · Deployment: **NOT DEPLOYED (no code/DB change this phase)**
**Date:** 2026-08-29 · **Mode:** Runtime validation / Owner QA / canonicalization only
**Next phase:** **V128-P5.FINAL — TEACHER ASSIGNMENT SEMANTIC CLOSEOUT**

> ⚠️ **CANONICAL NUMBERING NOTE.** The docs-repo canonical head-of-line is **D379 / SYSTEM_MAP v1.67 / HANDOFF V128-B14-FE-IMPLEMENTATION-CLOSEOUT / backend tail `20260820122518`**. The entire **V128-P series (P5, P5.4)** shipped to the **live DB** (migrations `20260828…`) but was **never canonicalized** — undocumented materialization debt. This closeout is the **first canonical record of P5.4/P5.5**; successor numbering is therefore **D380 / v1.68**. Derived from live-DB evidence, not memory.

---

## 1. REPOSITORY STRUCTURE

- **Product repo (DO NOT MODIFY):** `~/dev/demenart` · GitHub `huynhtranhuythinh/demenart`
  - **Accepted product HEAD:** `ad30f7a789b26f844affc98d80fda3b2ba1999ef` (P5.4 repository materialization debt closed here). **Must remain unchanged — no product commit this phase.**
- **Docs repo (all canonical writes):** `~/dev/demenart-docs` · GitHub `huynhtranhuythinh/demenart-docs`
- **Retired:** `~/dev/dma`, `~/dev/dma-docs`
- **Live Supabase:** `xcvhacymrbhdhohyylyq`

---

## 2. ACCEPTED BASELINE — P5 / P5.4 MIGRATIONS (live)

Backend migration tail: **`20260828150205`**. Eight P5-series migrations (all `20260828`):

| Version | Name |
|---|---|
| 20260828074837 | v128_p5_session_responsible_assignment |
| 20260828080326 | v128_p5_staffing_consistency_hardening |
| 20260828092120 | v128_p5_teacher_start_permission_ui |
| 20260828102507 | v128_p5_makeup_start_permission_consistency |
| 20260828144320 | v128_p5_4_wp1_set_distribution_lead_fail_closed_audit |
| 20260828144953 | v128_p5_4_wp2_teacher_visibility_session_scoped |
| 20260828145844 | v128_p5_4_wp3a_taught_attribution_ledger_substrate |
| 20260828150205 | v128_p5_4_wp3b_taught_attribution_runtime_and_correction |

**Live inventory (read-only at closeout):** public **95 tables · 260 functions · 247 SECURITY DEFINER · 169 policies · 35 triggers** · `mc_internal` **9 fns**. (Δ vs D379/v1.67 snapshot: **+1 table** `session_teacher_attributions`, +7 fns, +6 secdef, +1 trigger.)

**Governance function md5 (live, canonical anchors):**
`set_distribution_lead` `19376e2ae5807a48ffd28b1d27e810dd` · `is_distribution_lead` `e8ae3bf5516972d388e51eac83f45333` · `get_teacher_classes` `16146fa13e18d2fd436dcaf415a4ed52` · `get_teacher_classes_in_school` `e62724738c8d85b7578898e2ad872c48` · `get_teacher_session_workspace` `396598bf44176ef94c5516c42663fd9b` · `is_teacher_in_school` `db0ec9edb35c88aaac0750495a90845c` · `start_session` `257f81ab15216634bf75604784d3464e` · `correct_session_taught_teacher` `c44bb21aa1be6ed922abbb42e2b3e6f7` · `submit_session_journal` `09f6b7a3bbc1dddf457832e74fc7da12`

---

## 3. FROZEN SEMANTIC MODEL (P5.4)

Six distinct roles — **MUST remain distinct**:

**Distribution Lead ≠ Planned ≠ Responsible ≠ Supporting ≠ Actual Taught ≠ Report Actor.**

- **Distribution Lead** — `class_distributions.lead_teacher_id`. Distribution/program operational lead; source for NEW session staffing snapshot; distribution-level visibility. **Does NOT rewrite historical session assignment.**
- **Planned / Responsible** — `public.session_teacher_assignments`, `assignment_type ∈ {planned, responsible}` (check `sta_type_chk`; `sta_dimension_source_chk` ELSE false). Temporal append/supersede history. **Current Responsible controls Start Session + Submit Journal.**
- **Supporting Teacher** — **separate substrate** `public.session_teachers` (cols `id, session_id, profile_id, role∈{lead,assist}, created_at`; UNIQUE(session_id,profile_id)). **NOT** `assignment_type='supporting'`. Session-scoped relationship. Live rows: **4**.
- **Actual Taught Teacher** — `public.session_teacher_attributions` (historical append/supersede ledger; partial unique `sta_attr_current_uidx (session_id, attribution_type) WHERE is_current` → exactly one current). `lesson_sessions.taught_by` = compatibility/current **projection**, not sole historical truth.
- **Report Actor** — the `session_journal_submitted` audit actor (`session_reports` has no actor column). **Immutable historical evidence; historical taught correction MUST NOT rewrite it.**

**Authority:** Responsible → Start/Submit · Supporting → session visibility only · Distribution Lead → distribution visibility · same-school master/sub_admin → controlled historical correction. **Visibility ≠ Authority.** Teacher-Portal visibility is projected through SECURITY DEFINER RPCs (`get_teacher_classes_in_school`, `get_teacher_session_workspace`) whose predicate is session-scoped — **raw `lesson_sessions` SELECT RLS (`same_school`) is NOT the projection contract.**

---

## 4. P5.5 QA RESULTS

All QA performed via JWT-impersonated runtime (`request.jwt.claims`; `current_profile() = profiles.id WHERE user_id = auth.uid()`). Only QA-A committed (authorized, reversible, restored exact). Everything else read-only or transactionally rolled back.

### QA-A — Distribution Lead · **PASS**
Sequence on cd `d224a59c…` (initial lead = null), actor admin `hieutruong.kidshouse` (`…010`):
`null → Trần Khánh Vy (…013) → Vũ Hoàng Nam (…012) → clear → restore(null)`.
- Exactly **3** effective `distribution_lead_changed` audits (actor `…010`, school `…001`, correct `lead_from/lead_to`); **restore = no-op `already=true`, no audit**.
- `session_teacher_assignments` for the distribution **before == after (byte-identical)** → no historical assignment rewrite.
- Audit is **fail-closed** (same txn as the UPDATE, not exception-swallowed) — verified by contract read.

### QA-B — Supporting Teacher · **PASS WITH FIXTURE LIMITATION**
Substrate `public.session_teachers`. Positive fixture **Đặng Mỹ Linh** (`gv.linh.kidshouse`, uid `fd9322e1…`), supported session `1a3b9e4f…` (scheduled; responsible = Lê Thảo My `…014`).
- Linh sees her supported sessions (`1a3b9e4f`, `96e2e7c0`) purely via support; workspace `1a3b9e4f` → **visible · can_start_session=false (`forbidden`) · can_submit_journal=false (`forbidden`)**.
- **Negative visibility** proven independently: **Lê Thảo My** sees **9/10** relevant KHM sessions; unrelated `96e2e7c0` is **filtered**.
- **Fixture limitation (ACCEPTED):** no pure-support teacher also has an unrelated hidden session in the same projection for a single-actor positive+negative demo (Linh is legitimately related to all 10 KHM sessions via support + current assignments). **No production fixture manufactured.**

### QA-C — Responsible Authority · **PASS**
Read-only authority matrix via `get_teacher_session_workspace`:

| Case | Actor | Result |
|---|---|---|
| A responsible | Lê Thảo My @`1a3b9e4f` | `can_start=true` |
| B support≠resp | Đặng Mỹ Linh @`1a3b9e4f` | `can_start=false` / `forbidden` |
| C dist-lead≠resp | Lê Thảo My @`aaaa…a0001` (lead of `…031`) | `can_start=false` / `forbidden` |
| D support submit | Đặng Mỹ Linh @`1a3b9e4f` | `can_submit_journal=false` / `forbidden` |

- **Committed real Start side-effect (state→in_progress + `runtime_start` attribution) NOT performed** — no safe Owner fixture/account. **DEFERRED QA, not a defect.** `start_session` transition already exercised in controlled P5.4 rehearsal + static contract.

### QA-D — Historical Taught Correction · **PASS — ROLLED-BACK REAL-RPC REHEARSAL**
Fixture `3bfb9730…` (before: taught = Đặng Mỹ Linh `…011`). Real RPC `public.correct_session_taught_teacher('3bfb9730…', Vy `…013`, 'QA-P5.5 historical correction')` executed inside an impersonated same-school-admin subtransaction, evidence captured, then rolled back.
- **In-txn:** old attribution `c67a692d` preserved, `is_current=false`, `valid_to` set, `superseded_by` = new; **new attribution** teacher=Vy, `attribution_source=historical_correction`, `is_current=true`, `valid_to=null`, reason persisted, `recorded_by` = admin `…010`; `lesson_sessions.taught_by` synchronized to Vy; **exactly ONE current attribution**; audit `session_taught_teacher_corrected` present (actor/school/session/`taught_from`/`taught_to`/reason).
- **Immutable (all TRUE):** planned history · responsible history · session report · `session_started` audit · `session_journal_submitted` actor · learning moments · child observations.
- **Rollback → ZERO RESIDUE:** `taught_by` restored to Linh; old attribution current again (`superseded_by`/`valid_to` null); no `historical_correction` row; no correction audit; global multi-current taught = 0.
- **Permanent Owner correction: DEFERRED — no real historical error requires correction (append-only).** Not a defect.

### Negative Authority · **PASS** (all reject before any write; integrity: 0 residue)
`reason_required` · `teacher_invalid` · `bad_state` · same-teacher no-op `already=true` (no supersession) · `lead_teacher` `not_authorized_for_school` · `assistant_teacher` `not_authorized_for_school` · **cross-school master_admin `not_authorized_for_school`** (school-scope, not role-only).

---

## 5. NON-BLOCKING CONTRACT DEVIATION (recorded)

Audit `session_taught_teacher_corrected` metadata = `{taught_from, taught_to, reason}` only. The earlier P5.4 design language also listed `previous_attribution_id` / `new_attribution_id`; those two IDs are **not** in audit metadata. Lineage is deterministically preserved in `session_teacher_attributions.superseded_by`.
→ Classification: **NON-BLOCKING AUDIT RICHNESS DEBT** — NOT a historical-integrity defect, NOT a P5.5 blocker. No backend change in this phase. Future hardening may add the IDs.

---

## 6. DEFERRED — NOT DEFECTS

1. **Committed Owner QA of real `start_session`** (state→in_progress + `runtime_start` attribution) — no safe Owner fixture / responsible account (responsible on the only start-eligible session = Lê Thảo My, temp password; NOT reset per ruling).
2. **Owner UI historical-correction flow** — backend-first capability exists; no genuine historical error required correction; correction is append-only. Absence of an Admin correction UI does **not** fail P5.5 (backend-first by design).

---

## 7. DEPLOYMENT / PRODUCT STATUS

No code changes · no migration · no DB mutation · no deployment this phase. Backend P5/P5.4 migrations already live (tail `20260828150205`). Frontend deployment unchanged (pin `@lovable.dev/vite-tanstack-config` `2.8.5`). Product HEAD stays `ad30f7a…`.

---

## 8. ENDPOINT

RULES **D380** · SYSTEM_MAP **v1.68** · HANDOFF **V128-P5.5-CANONICAL-CLOSEOUT** · backend tail **`20260828150205`** · product HEAD **`ad30f7a…`** · FE main pin **`2.8.5`**.
Prior endpoint (real docs tail) becomes HISTORICAL SNAPSHOT (BẤT BIẾN). **Permanent lifecycle baseline unchanged: 1 decision / 2 transitions** (P5.5 opened no decision).
