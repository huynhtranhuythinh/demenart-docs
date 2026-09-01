# 🗂️ DMA_HANDOFF_V128-P8.1C — ENROLLMENT INTERVAL MODEL + LIFECYCLE — FINAL CLOSEOUT

> Capability slice **V128-P8.1C-1 (M2 — prospective lifecycle writers)** and **V128-P8.1C-2 (M3 — DB-enforced interval invariants)** closed.
> **M2** = DB migration 190 **+ frontend change** (`src/routes/_authenticated/school.manage.tsx` start-date wiring) with Owner production UI QA — product HEAD advanced `cfac171…` → `76c6df40…`. **M3** = database-only (migration 191), no further frontend/product change; product HEAD remained `76c6df40…`. **This closeout is docs-only** — 0 product mutation · 0 DB mutation performed during the closeout.
> Final runtime pin is **191 / M3**, tail `20260901035741 v128_p8_1c_m3_enrollment_interval_invariants`.
>
> **Endpoint (fill RULES/SYSTEM_MAP anchors against live):**
> RULES **D‹live max +1› (→ D383)** · SYSTEM_MAP **v‹live +1› (→ v1.71)** · HANDOFF **V128-P8.1C** ·
> backend count **191** · backend tail `20260901035741 v128_p8_1c_m3_enrollment_interval_invariants` ·
> product HEAD `76c6df40ccf252a5733214f3007bd5a46c9b3b27` · Supabase `xcvhacymrbhdhohyylyq` · M2 FE landed at `76c6df40…` (from `cfac171…`); M3 no further FE · agent pin `2.8.5`.

---

## 0. VERDICT & PROVENANCE (honest record)

Gate outcome (Owner + independent CTO authority): **V128-P8.1C (M2 + M3) — CLOSED — PRODUCTION VALIDATED.**

Evidence provenance:

- **[Independently verified — Claude, live production Supabase, this session]** — M3 migration apply + verify; count/tail; `btree_gist` v1.7 in `extensions`; both constraint definitions; live overlap = 0; enrollments total = 18 with 3 NULL-start + 15 known open-ended; 3 legacy fingerprints byte-identical pre/post apply; all six M2 writer bodies present, SECDEF, `search_path=''`, md5 unchanged; full T1–T10 pre-apply rehearsal (rolled back, zero residue).
- **[Independently verified — CTO]** — live re-verification confirmed count 191, tail, extension, both constraint definitions, overlap 0, total 18, legacy 3 → PASS.
- **[Owner-attested — M2 production UI QA: PASS]** — School Management → create-child: "Ngày bắt đầu học *" field visible and initially blank; missing start date **blocked** (fail-closed client validation); create-child **succeeded** after explicit date selection; live DB confirmed the created enrollment `start_date = 2026-09-01`, `end_date = NULL`, `state = active`. M2 FE callsite `src/routes/_authenticated/school.manage.tsx` → `create_child_and_enroll(… p_start_date …)`; product HEAD advanced `cfac171…` → `76c6df40…`.
- **[M3 — no UI surface]** — M3 was database-only; no frontend surface required or shipped; product HEAD unchanged at `76c6df40…`.
- **[No NOT-EXERCISABLE gaps]** — every M3 invariant and every lifecycle writer was exercisable and exercised in the rolled-back rehearsal.

---

## 1. CAPABILITY

Enrollment is per-school; the child journey is global. This slice makes the enrollment **interval** canonical and self-defending:

- **M2** froze the prospective-enrollment lifecycle: pause / resume / class-transfer / school-transfer / end / graduate — each an explicit, audited writer that requires a known `start_date` and serializes the source transition. It replaced any implicit or generic mutation of enrollment dates.
- **M3** put the interval geometry rules into the database itself, so invalid geometry is rejected regardless of caller correctness — even if a future RPC is buggy, a caller bypasses the frontend, or lifecycle code regresses later.

---

## 2. IMPLEMENTATION LINEAGE (M2 → M3)

| Phase | Migration | What |
|---|---|---|
| P8.1C-1 **M2** | `20260831125927 v128_p8_1c_m2_enrollment_lifecycle_writers` (count 190) | Explicit required `start_date` for prospective enrollment; pause/resume/class-transfer/school-transfer/end/graduate writers; `FOR UPDATE OF e` serialization; same-school authority + independent destination-school authority for school transfer; audit policy labels; no raw `school_student_code` duplication; three legacy NULL-start rows untouched. **Frontend:** `school.manage.tsx` start-date wiring (explicit `cStartDate`, required "Ngày bắt đầu học *" input, blank-date fail-closed validation, named `p_start_date`, reset-after-create, start_date error mapping) → product HEAD `cfac171…` → `76c6df40…`; Owner production UI QA PASS. (Prior session; DB lineage verified live this session; FE + QA Owner-attested.) |
| P8.1C-2 **M3** | `20260901035741 v128_p8_1c_m3_enrollment_interval_invariants` (count 191) | `btree_gist` (extensions); `CHECK enrollments_valid_interval_chk`; partial `EXCLUDE enrollments_no_overlap_excl`. Applied after a fully-green pre-apply transactional rehearsal; verified live. |

No migration 192+.

---

## 3. FROZEN SEMANTIC TRUTHS (P8.1C)

1. One enrollment row = one contiguous attendance-required interval. `start_date` inclusive first date; `end_date` inclusive last date; Asia/Ho_Chi_Minh; DATE granularity.
2. `created_at` is never enrollment start truth; `state` is not historical membership truth.
3. NULL `start_date` = historical start UNKNOWN. `UNKNOWN ≠ INCOMPLETE`. NULL-start + known-end is permitted. No auto inference/backfill; never from `created_at`; never session-derived.
4. Known intervals for the same `child_id + class_id` may not overlap. Duplicate known intervals forbidden. More than one open-ended known interval forbidden. (All enforced by one partial exclusion constraint.)
5. `end_date < start_date` forbidden (CHECK); the CHECK is **not** strengthened to force both dates NULL together.
6. Adjacent intervals are allowed.
7. NULL-start rows are excluded from overlap enforcement (partial predicate `start_date IS NOT NULL`).
8. Lifecycle writers refuse NULL-start rows (`refusing lifecycle transition`).
9. pause closes at D−1; resume opens a new interval at D (same class, adjacent); class/school transfer close source at D−1 and open destination at D; end/graduate set the final attendance date. **Old intervals are never reopened.**
10. Lifecycle writers serialize source transitions with `FOR UPDATE OF e`; school is derived from `classes.school_id`, never client-supplied.

---

## 4. M3 — PRE-APPLY TRANSACTIONAL REHEARSAL (recorded in full)

Because MCP `execute_sql` is autocommit-per-call, the rehearsal was expressed as a single atomic `DO` block (impersonate super_admin → install extension + both constraints → isolated QA fixtures → T1–T10 → legacy fingerprint check → terminal `RAISE` forces total rollback). Isolation identical to `BEGIN…ROLLBACK`. (Methodology detail in the evidence file; **not** promoted to DMA_RULES.)

| # | Case | Result |
|---|---|---|
| T1 | valid closed interval insert | PASS |
| T2 | adjacent interval (end 01-31 → start 02-01) | PASS (2 rows coexist) |
| T3 | overlapping closed interval | REJECT (exclusion) |
| T4 | duplicate interval | REJECT (exclusion) |
| T5 | second open-ended interval | REJECT (exclusion) |
| T6 | open-ended overlapping a closed interval | REJECT (exclusion) |
| T7 | `end_date < start_date` | REJECT (CHECK) |
| T8 | NULL-start rows (incl. NULL-start + known-end) | PASS (2 null-start rows) |
| T9 | 3 protected NULL-start fingerprints | UNCHANGED |
| T10 | pause+resume · end · graduate · class-transfer · school-transfer | ALL PASS |

Constraints installed successfully **against live rows** inside the rehearsal (proves the real ADD could not fail on current data). Post-rollback: migrations back to 190, `btree_gist` absent, both constraints absent, enrollments = 18, QA residue = 0, 3 legacy fingerprints byte-identical. **Zero residue.**

---

## 5. M3 — POST-APPLY VERIFICATION (verified live at closeout)

- migration count **191**; tail `20260901035741 v128_p8_1c_m3_enrollment_interval_invariants`; prev `20260831125927`.
- `btree_gist` v1.7 installed in `extensions`.
- `enrollments_valid_interval_chk` = `CHECK ((end_date IS NULL) OR (start_date IS NULL) OR (end_date >= start_date))`.
- `enrollments_no_overlap_excl` = `EXCLUDE USING gist (child_id WITH =, class_id WITH =, daterange(start_date, end_date, '[]') WITH &&) WHERE ((start_date IS NOT NULL))`.
- live overlap violations = **0**; enrollments total = **18**; legacy NULL-start = **3** (byte-identical).
- 6 lifecycle writers present, SECDEF, `search_path=''`, bodies unchanged (md5 in SYSTEM_MAP).

---

## 6. CARRY-FORWARD DEBT / NEXT SLICE

Three legacy NULL-start enrollments remain **unresolved and intentionally untouched**: Bé Jenny Demo, Bé Jimmy Demo, Trần Tuệ Linh. They are inert to lifecycle writers and excluded from overlap enforcement.

Next authorized capability: **V128-P8.1C-3 — M1 LEGACY MANUAL CANONICAL RECOVERY** — a narrow, audited, manual correction path only. **No** auto-backfill · **no** `created_at` inference · **no** session-derived automatic inference · **no** generic enrollment UPDATE surface. Not designed or started in this closeout.

Hard forward sequence: **M1 → M4 → M5 → M6**.

---

## 7. HARD STOP

P8.1C (M2 + M3) closed. **Do NOT start M1.** Do NOT start M4 / M5 / M6. **Do NOT start P8.2.** Do NOT mutate product or DB.
