# V128-P2 — Attendance Rollup Product Value Evidence

**Capability:** School Attendance Rollup  
**Surface:** `/school/attendance`  
**Final status:** **PRODUCT VALUE PROVEN ✅**  
**Environment verified:** Production (`demenart.com`)  
**Evidence date:** 2026-08-25

## 1. Product outcome

A School Master / Principal can now open the School Portal, select **Điểm danh**, choose a reporting period, and see attendance totals by class without opening and manually counting individual lesson sessions.

The V1 surface reports raw operational counts only:

- Sessions observed (`sessions_observed`)
- Present
- Late
- Absent
- Marked total (`marked_total`)

It intentionally does **not** calculate or display attendance percentages, rankings, scores, class quality labels, or teacher evaluations.

## 2. Value-gate findings

The audit established that the underlying attendance data was sufficient, but the school-level period rollup did not already exist.

### Data truth

- `child_observations.attendance` is nullable text.
- Live attendance values are `present`, `late`, and `absent`, plus null/unrecorded values.
- The unique `(session_id, child_id)` relationship yields one observation row per child per session.
- Attendance can be joined through session → distribution → class → school.

### Existing capability audit

- `get_school_today_operations` already aggregated attendance completeness at school level, but only for one day.
- That existing contract exposed recorded/total completeness, not a `present` / `late` / `absent` breakdown and not a period rollup.
- `get_school_overview` did not aggregate attendance.
- The existing School UI showed whether today's attendance was complete, while detailed attendance remained inside the teacher workflow.
- No existing school surface or read contract exposed attendance totals by class across a selectable period.

**Value-gate conclusion:** the P2 gap was genuine. Raw data existed, but the school-level read contract and summary surface required to turn it into operational value did not.

## 3. Authorized product decisions

- Build a school-level read contract for period attendance rollup.
- Use **raw counts only** in V1 because the product meaning of `late` within an attendance rate had not been formally defined.
- Add a dedicated route: `/school/attendance`.
- Do not add percentage, ranking, scoring, or evaluative language.

## 4. Implementation path

The capability was delivered backend-first and then surfaced in the School Portal:

1. A school-scoped read contract aggregated attendance by class and period.
2. The School Portal gained a dedicated **Điểm danh** navigation item and `/school/attendance` page.
3. The UI presented sessions observed and raw `present` / `late` / `absent` / `marked_total` counts.
4. The initial 7-day and 30-day period choices were extended with the bonus **Tuỳ chọn** and **Tất cả** options.
5. Tooling governance was checked after agent application. The unintended `@lovable.dev/vite-tanstack-config` drift from `2.8.5` to `2.13.1` was detected and reverted to the required `2.8.5` pin before release.
6. The completed implementation was deployed and verified on production.

## 5. Production QA evidence

Production QA confirmed that the **Tất cả** period loaded correctly and reconciled exactly with the independently verified backend result.

### School totals shown in the UI

| Metric | Production UI |
|---|---:|
| Present | 4 |
| Late | 5 |
| Absent | 3 |
| Marked total | 12 |

Reconciliation:

`marked_total = present + late + absent = 4 + 5 + 3 = 12`

### Class-level evidence

| School / Class | Sessions observed | Present | Late | Absent | Marked total |
|---|---:|---:|---:|---:|---:|
| Cảm Thụ Âm Nhạc Dế Mèn / Hoa Hồng | 3 | 4 | 5 | 3 | 12 |

Backend verification for **Hoa Hồng** was:

`sessions_observed=3, present=4, late=5, absent=3, marked_total=12`

The production table matched these values **100%**.

### QA gates closed

- Attendance surface exists and loads on production: **PASS**
- Period selection works, including **Tất cả**: **PASS**
- Production totals reconcile with the backend verification result: **PASS**
- Class-level values for Hoa Hồng reconcile exactly: **PASS**
- No attendance percentage is displayed: **PASS**
- No ranking, score, or teacher/class evaluation is displayed: **PASS**

## 6. Product value proof

The verified end-to-end value is:

> Attendance recorded through the teaching workflow is now available to school leadership as an accurate, class-level period summary, without requiring them to open every session or count children manually.

The production result proves that the feature is not merely implemented or deployed: it transforms existing attendance records into a usable school operations view and preserves the approved raw-count semantics.

## 7. Final closure

```text
V128-P2 — ATTENDANCE ROLLUP

Value gate confirmed       ✅
Read contract implemented  ✅
School UI implemented      ✅
Tooling pin contained      ✅
Production deployed        ✅
Production QA reconciled   ✅
No percentage/ranking      ✅
Bonus "Tất cả" period      ✅

FINAL STATUS:
PRODUCT VALUE PROVEN ✅
```

P2 is closed. The next roadmap capability may begin only as a separate value-gated priority.
