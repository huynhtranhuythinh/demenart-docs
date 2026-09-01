# 🗺️ DMA_SYSTEM_MAP.md — V128-P8.1C FINAL — CANON DELTA (append block)

> **How to apply:** Append to the live cumulative `DMA_SYSTEM_MAP.md`; **bump version to v‹live +1›** (sequence: P6 = v1.69, P7 = v1.70 ⇒ this block resolves to **v1.71**). Append only — do not rewrite unrelated subsystems.
> **Scope of assertions:** every item below was **independently verified on live production Supabase** during the M3 apply/verify this session, or exercised in the rolled-back pre-apply rehearsal.

## SUBSYSTEM — Enrollment interval model & lifecycle (V128-P8.1C)

### Backend runtime pin
- Migration count **191** · tail `20260901035741 v128_p8_1c_m3_enrollment_interval_invariants` · prev `20260831125927 v128_p8_1c_m2_enrollment_lifecycle_writers`.
- Extension: `btree_gist` **v1.7**, schema **`extensions`** (provides the uuid `=` gist operator class used by the exclusion constraint).

### Table — `public.enrollments`
- Columns: `id uuid PK`, `child_id uuid NOT NULL` (FK→`children(id)` ON DELETE CASCADE), `class_id uuid NOT NULL` (FK→`classes(id)` ON DELETE CASCADE), `school_student_code text`, `state enrollment_state NOT NULL default 'active'`, `start_date date`, `end_date date`, `created_at`, `updated_at`. **RLS: enabled.**
- `enrollment_state` ∈ { active, paused, transferred_class, transferred_school, ended, graduated }.
- **Constraints (M3, migration 191):**
  - `enrollments_valid_interval_chk` — `CHECK ((end_date IS NULL) OR (start_date IS NULL) OR (end_date >= start_date))`.
  - `enrollments_no_overlap_excl` — `EXCLUDE USING gist (child_id WITH =, class_id WITH =, daterange(start_date, end_date, '[]') WITH &&) WHERE ((start_date IS NOT NULL))`.
- Live geometry at closeout: total **18** = 3 NULL-start (legacy) · 15 known open-ended `[start, ∞)` · 0 closed · 0 `end<start` · **0 overlapping pairs** (15 known rows on 15 distinct child+class pairs).

### Interval semantics
- One row = one contiguous attendance-required interval; `start_date` inclusive first date, `end_date` inclusive last date. `daterange(start,end,'[]')` normalizes inclusive-upper to half-open (+1 day) → adjacent intervals do **not** overlap; two open-ended known intervals always overlap (forbidden); duplicate reduces to overlap (forbidden).
- NULL `start_date` = historical start UNKNOWN; excluded from the exclusion index by the partial predicate. NULL-start + known-end permitted. No auto-inference/backfill.

### Lifecycle writers (M2, migration 190) — verified live: SECDEF · `search_path=''` · body md5
| Function | signature | SECDEF | search_path | body md5 | geometry effect |
|---|---|---|---|---|---|
| `pause_enrollment` | `(p_enrollment_id uuid, p_effective_date date)` | ✓ | `''` | `1a9f459a5a368e83a1b18f19349d99ba` | close source at D−1 → `paused` |
| `resume_enrollment` | `(p_enrollment_id uuid, p_effective_date date)` | ✓ | `''` | `caa545b6722e7c0c300fe21405c229af` | new open interval at D, same class (adjacent) |
| `transfer_enrollment_class` | `(p_enrollment_id uuid, p_destination_class_id uuid, p_effective_date date)` | ✓ | `''` | `43a52074846be11af966fd4f2eab1d6a` | close source D−1; open dest at D (different class, same school) |
| `transfer_enrollment_school` | `(p_enrollment_id uuid, p_destination_class_id uuid, p_effective_date date)` | ✓ | `''` | `602f8d6ac4ac5de43ed4e41bd4cbdb4e` | close source D−1; open dest at D (different school; dual authority) |
| `end_enrollment` | `(p_enrollment_id uuid, p_last_date date)` | ✓ | `''` | `624cdff6bf59c16e3f6403b4e8112c56` | single-row close → `ended` |
| `graduate_enrollment` | `(p_enrollment_id uuid, p_last_date date)` | ✓ | `''` | `c6bf1aaaed1de7e529e50c1e1ed12d56` | single-row close → `graduated` |

- All six exercised under the live M3 constraints in the rolled-back rehearsal (T10) — every one PASS, none produced overlap/duplicate/multi-open/invalid geometry. M2 writers are **M3-safe by construction**.
- Serialization: `SELECT … FOR UPDATE OF e` on the source enrollment. School derived from `classes.school_id` (never client-supplied).

### Authority model (lifecycle)
- Gate = `is_admin()` OR (`current_profile_role() ∈ {master_admin, sub_admin}` AND source school ∈ `user_school_ids()`). School transfer additionally requires destination school under the actor's authority. `is_admin()` (platform super/content/operation/sales/support admin) bypasses school gates. NULL-start rows refused pre-authority-independent (`refusing lifecycle transition`).
- Auth resolution: all helpers key on `auth.uid()` → `profiles.user_id`.

### Frontend (M2 — Owner-attested; not independently re-verified this session)
- Callsite `src/routes/_authenticated/school.manage.tsx` (School Management → create child) → `create_child_and_enroll(… p_start_date …)`. Required "Ngày bắt đầu học *" date input; explicit `cStartDate` state (no implicit today default); blank-date fail-closed client validation; reset after successful create; start_date error mapping. Landed at product HEAD `76c6df40…` (from `cfac171…`). Owner production QA PASS (field blank by default, missing date blocked, create succeeded, live DB `start_date=2026-09-01 / end_date=NULL / state=active`). **M3 added no frontend surface.**

### Legacy / deferred
- 3 legacy NULL-start rows (Bé Jenny Demo, Bé Jimmy Demo, Trần Tuệ Linh) — intentionally untouched; byte-identical across M3 apply; inert to lifecycle writers; excluded from overlap enforcement. Resolution deferred to **V128-P8.1C-3 (M1)**.
- Forward sequence M1 → M4 → M5 → M6. **P8.2 prohibited.** `/kid` namespace unaffected.

**Version:** bump to **v‹live +1› (→ v1.71)** (P8.1C FINAL). Endpoint: HANDOFF **V128-P8.1C** · backend count **191** · tail `20260901035741` · product HEAD `76c6df40…` · M2 frontend landed at product HEAD `76c6df40…` (from `cfac171…`); M3 made no further frontend/product change · agent pin `2.8.5`.
