# 🛡️ DMA_RULES.md — V128-P8.1C FINAL — CANON DELTA (append block)

> **How to apply:** This is the **P8.1C FINAL append block** for the live cumulative `~/dev/demenart-docs/canon` `DMA_RULES.md`.
> Set the block anchor to **`D‹live max + 1›`** (continue the live D-series). Sequence reference: P5.5 = D380, P6 = D381, P7 = D382 ⇒ this block resolves to **D383**. Append only; do **not** rewrite unrelated phases. Prior P7 block becomes HISTORICAL SNAPSHOT (BẤT BIẾN); this block is the new current endpoint.

## 🗂️ D‹NEXT› — V128-P8.1C · ENROLLMENT INTERVAL MODEL + LIFECYCLE — M2 (prospective lifecycle) + M3 (DB-enforced interval invariants) — CANONICALIZED (2026-09-01)

> Closes capability slice **V128-P8.1C-1 (M2)** and **V128-P8.1C-2 (M3)**. M2 froze prospective-enrollment lifecycle writers (migration 190) **and** included the School Management Children start-date frontend wiring (`src/routes/_authenticated/school.manage.tsx`) with Owner production UI QA — advancing product HEAD `cfac171…` → `76c6df40…`. M3 added database-enforced interval geometry invariants (migration 191) and was **database-only**, making no further frontend/product change (product HEAD remained `76c6df40…`). M3 applied after a fully-green pre-apply transactional rehearsal with zero residue. **Docs-only closeout — 0 product/DB mutation during closeout.**

### Enrollment interval model (durable product invariant)

- **D‹NEXT›.1 — ⭐ One enrollment row = one contiguous attendance-required interval.** `start_date` = first effective local school date attendance is required; `end_date` = last effective local school date, **inclusive**. Timezone Asia/Ho_Chi_Minh; DATE granularity is sufficient.
- **D‹NEXT›.2 — ⭐ `created_at` is never enrollment start truth; `state` is not historical membership truth.** Current row state answers "what is true now," not "what was the membership history."
- **D‹NEXT›.3 — ⭐ NULL `start_date` = historical effective start UNKNOWN.** `UNKNOWN ≠ INCOMPLETE`. A NULL-start row is a supported canonical UNKNOWN state — not evidence of corruption and not a value that may be automatically inferred or backfilled. It may be resolved to a known `start_date` only through an authorized, audited canonical correction when sufficient operator-asserted evidence exists (see V128-P8.1C-3 / M1; not all NULL-start rows require correction). **NULL `start_date` with a known `end_date` is permitted** (unknown start, known canonical end). No automatic inference or backfill of NULL start (never from `created_at`, never session-derived).

### M3 — database-enforced interval invariants (migration 191)

- **D‹NEXT›.4 — ⭐ For the same `child_id + class_id`, known intervals may not overlap.** Enforced by partial exclusion constraint `enrollments_no_overlap_excl`: `EXCLUDE USING gist (child_id WITH =, class_id WITH =, daterange(start_date, end_date, '[]') WITH &&) WHERE (start_date IS NOT NULL)`. Duplicate known intervals and a **second** open-ended known interval both reduce to overlap and are therefore forbidden by the same constraint.
- **D‹NEXT›.5 — ⭐ `end_date < start_date` is forbidden** for known geometry — CHECK `enrollments_valid_interval_chk`: `(end_date IS NULL OR start_date IS NULL OR end_date >= start_date)`. This is the ratified form; it must **not** be strengthened to force both dates NULL together.
- **D‹NEXT›.6 — ⭐ Adjacent intervals do not overlap and are allowed.** `daterange(_, _, '[]')` normalizes inclusive-upper to half-open (+1 day), so `[…,01-31]` and `[02-01,…]` are adjacent, not overlapping. Verified live.
- **D‹NEXT›.7 — ⭐ NULL-start rows are excluded from overlap enforcement.** The exclusion predicate `WHERE (start_date IS NOT NULL)` removes them from the index entirely — they are never compared, never rejected, never mutated. This is load-bearing for legacy safety (two same-class NULL-start rows would otherwise both map to `(-∞,+∞)` and collide). Fail-closed applies to **known** interval writers; genuinely unknown legacy starts are left unconstrained by design.
- **D‹NEXT›.8 — ⭐ Enforcement is database-first / database-only.** Requires `btree_gist` (installed v1.7 in the `extensions` schema for the uuid `=` gist opclass). Constraints are deterministically named, schema-unqualified `daterange`/`&&` resolving via `pg_catalog`. No RPC, trigger, RLS, grant, or frontend change was needed. Invariants hold against any buggy caller, bypass, or future lifecycle regression because they live at the storage layer.

### M2 — prospective lifecycle semantics (migration 190)

- **D‹NEXT›.9 — ⭐ Prospective enrollment requires an explicit `start_date`.** Lifecycle transitions **refuse** to operate on a NULL-start row (`'enrollment has no start_date; refusing lifecycle transition'`). Legacy NULL-start rows are therefore inert to the lifecycle writers — they cannot be paused/ended/transferred until start is canonically recovered (see M1).
- **D‹NEXT›.10 — ⭐ Lifecycle writer geometry (all M3-safe by construction):**
  - **pause** closes the interval at `effective_date − 1` (guarded `effective > start` ⇒ `end ≥ start`), sets `paused`.
  - **resume** opens a **new** interval at `effective_date` in the **same class** (guarded `effective > paused end_date` ⇒ adjacent, non-overlapping).
  - **class transfer** closes the source at `effective_date − 1`, opens the destination at `effective_date` in a **different class** (same school; dest ≠ src enforced).
  - **school transfer** closes the source at `effective_date − 1`, opens the destination at `effective_date` in a different school's class (independent destination-school authority required).
  - **end / graduate** set the final attendance date (`last_date ≥ start`), single-row close.
  - **Old intervals are never reopened.** Reactivation always creates a new row.
- **D‹NEXT›.11 — ⭐ Lifecycle writers serialize source transitions with `FOR UPDATE OF e`** and derive school from `classes.school_id` (never a client-supplied school_id). Same-school authority = `is_admin()` OR (`current_profile_role() ∈ {master_admin, sub_admin}` AND source school ∈ `user_school_ids()`); school transfer additionally requires the **destination** school under the actor's authority. Audit labels carry prior/result start/end/state; no raw `school_student_code` duplication (cleared cross-school, preserved same-school).

### Carry-forward & sequence

- **D‹NEXT›.12 — ⭐ Three legacy NULL-start enrollments remain intentionally unresolved and untouched:** Bé Jenny Demo, Bé Jimmy Demo, Trần Tuệ Linh. Byte-identical across M3 apply (verified). They are inert to lifecycle writers (D‹NEXT›.9) and excluded from overlap enforcement (D‹NEXT›.7).
- **D‹NEXT›.13 — ⭐ Next authorized capability = V128-P8.1C-3 — M1 LEGACY MANUAL CANONICAL RECOVERY.** A narrow, audited, manual correction path only. **No** auto-backfill, **no** `created_at` inference, **no** session-derived automatic inference, **no** generic enrollment UPDATE surface. Hard forward sequence: **M1 → M4 → M5 → M6**. **P8.2 remains prohibited.** M1/M4/M5/M6 not designed or started in this closeout.

**Delta:** **2 migrations across the slice** — `190 v128_p8_1c_m2_enrollment_lifecycle_writers` (M2, prior session) + `191 v128_p8_1c_m3_enrollment_interval_invariants` (M3, this session). **M3 changed:** `+CREATE EXTENSION btree_gist` (extensions schema), `+CHECK enrollments_valid_interval_chk`, `+EXCLUDE enrollments_no_overlap_excl`. **Frozen (verified UNCHANGED):** 6 lifecycle writer bodies (md5 recorded in SYSTEM_MAP), 3 legacy NULL-start fingerprints, RLS on `enrollments`, PK/FK. **Data:** enrollments total = 18 (3 NULL-start · 15 known open-ended · 0 closed · 0 overlap · 0 invalid); **0 mutation** by M3. **FE:** M2 landed the `school.manage.tsx` start-date wiring at product HEAD `76c6df40…` (Owner UI QA PASS); M3 = 0 further FE/product change; agent pin `2.8.5` untouched. Backend count **190 → 191**; tail `20260901035741 v128_p8_1c_m3_enrollment_interval_invariants`. Endpoint: RULES **D‹NEXT› (→ D383)** · SYSTEM_MAP **v‹live +1› (→ v1.71)** · HANDOFF **V128-P8.1C** · product HEAD `76c6df40ccf252a5733214f3007bd5a46c9b3b27`. Prior P7 block = HISTORICAL SNAPSHOT (BẤT BIẾN).
