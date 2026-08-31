# V128-P6 — NEXT PRODUCT VALUE CAPABILITY GATE — FINAL REPORT

**Mode:** Product Value Discovery (khám phá giá trị sản phẩm) / Audit-first (kiểm tra trước) / Read-only (chỉ đọc) / No implementation (không triển khai)

**Date:** 2026-08-29

**Final verdict:** **B — NEXT CAPABILITY CONFIRMED — DISCOVERY/DESIGN NEEDED FIRST**

**Selected capability:** **V128-P6.1 — PARENT SESSION PARTICIPATION CONTRACT DESIGN GATE**

---

## 1. Canonical pins

| Canonical item | Verified value | Verdict |
|---|---|---|
| Product repository | `huynhtranhuythinh/demenart` | Read-only |
| Product HEAD | `ad30f7a789b26f844affc98d80fda3b2ba1999ef` | Matches accepted HEAD |
| Docs repository | `huynhtranhuythinh/demenart-docs` | Read-only |
| Docs HEAD | `f4384d10e44810c911ec189d6527c9b57c131f32` | Matches accepted HEAD |
| Supabase project | `xcvhacymrbhdhohyylyq` | Read-only |
| Live migration tail | `20260828150205 — v128_p5_4_wp3b_taught_attribution_runtime_and_correction` | Matches accepted tail |

No repository, database, documentation, deployment, or production data mutation occurred.

---

## 2. Completed capability baseline

- P1/P2 remain accepted predecessor capabilities. Current runtime exposes school weekly scheduling/session operations and school attendance rollup.
- P3 — School Announcement: school-admin sender, same-school parent resolution, in-app delivery, receipt, unread/read behavior.
- P4 — Home Practice: teacher authoring during closeout, immutable after submission, parent outcome and journal presentation.
- P5 — Teacher Assignment: responsible/planned/supporting/taught/report-actor distinctions, session-scoped visibility, controlled historical attribution. **Closed.**

P5 was not reopened. No P5 authority, visibility, or historical-attribution defect was found.

---

## 3. Audited operating workflow map

| Actor / job | UI route | Frontend contract | Backend / tables | Authority | End-to-end verdict |
|---|---|---|---|---|---|
| School — know what needs attention today | `/school/manage` | `useSchoolTodayOperations` | `get_school_today_operations`; `lesson_sessions`, `session_teacher_assignments`, `enrollments`, `child_observations`, `session_reports`, `learning_moments` | `master_admin` / `sub_admin`, server-resolved same school | Present. Detects missing responsible teacher, overdue start, incomplete attendance, and unsubmitted journal. Detail is read-only and remediation is fragmented. |
| School — create/update/cancel/staff sessions | `/school/schedule` | weekly schedule + planned-teacher projection | `get_school_week_schedule`, `get_school_week_planned_teachers`, `create_lesson_session_with_responsible`, `update_lesson_session_with_staffing`, `cancel_lesson_session`; session/staffing tables | global admin or same-school `master_admin` / `sub_admin` | Present. Real intended actor can create, edit, cancel, select lesson, responsible teacher, and supporting teachers. |
| School — understand attendance | `/school/attendance` | `useSchoolAttendanceRollup` | `get_school_attendance_rollup`; `child_observations` | School operations context | Present as aggregate operational rollup; not a parent-facing attendance record. |
| Teacher — know today, prepare, start, record, finish | `/teacher`, `/teacher/schedule`, `/teacher/journal`, `/teacher/session/:id` | teacher home/classes/workspace/journal contracts | `get_teacher_home_in_school`, `get_teacher_classes_in_school`, `get_teacher_journals_in_school`, `get_teacher_session_workspace`, `start_session`, `teacher_upsert_child_observation`, `submit_session_journal` | Teacher-in-school visibility; Responsible Teacher exclusively starts and submits journal | Present and actionable. Daily timeline, preparation, start permission, attendance, observations, media, completion queue, journal and Home Practice are wired. |
| School → Teacher handoff | Teacher home/schedule/classes | assignment-scoped reads | `get_teacher_classes_in_school` and workspace projection | Lead sees distribution; supporting teacher sees assigned sessions; responsible authority remains exclusive | Present. New staffing becomes visible without a separate acknowledgment ceremony. No evidence proves acknowledgment is needed. |
| Parent — understand the latest session | `/parent`, `/parent/journal` | `get_parent_session_outcomes`, `get_child_journal` | `child_journey`, `child_observations`, `session_reports`, `learning_moments`, media, appreciation | `is_child_parent(p_child_id)` fail-closed | Partially present. Outcome, skills, approved media, Home Practice and appreciation exist. Attendance is not projected or displayed; absent sessions have no journey and therefore disappear from this surface. |
| School — communicate with parents | `/school/notifications` → parent notifications | announcement composer + notification presenter | `send_school_announcement`, `notifications` | same-school school admin | Present for school-wide in-app announcements. Class targeting and sent history are absent but not proven pilot blockers. |

---

## 4. Concrete runtime evidence for the winning gap

### Source and live contract

1. Parent frontend source contains no attendance field or attendance presentation anywhere in the parent feature/routes audited.
2. `get_parent_session_outcomes` starts from `child_journey`, not from recorded session participation.
3. `submit_session_journal` intentionally creates `child_journey` only for attendance in `('present','late')`.
4. Authoritative attendance already exists in `child_observations.attendance` with `present`, `late`, and `absent`.
5. Parent authority is already known and fail-closed: `get_parent_session_outcomes` rejects unless `is_child_parent(p_child_id)` is true.

### Production aggregate (no identities read)

| Attendance | Observation rows | Visible as parent session outcome | Session has report |
|---|---:|---:|---:|
| `present` | 6 | 6 | 6 |
| `late` | 4 | 4 | 4 |
| `absent` | 3 | **0** | 3 |

Therefore, three real recorded absences belong to sessions with reports but are invisible as parent session records. This is a proven product gap, not a hypothetical enhancement.

---

## 5. Candidate gaps and product value scoring

Scoring: Frequency + Operational Pain + User Value + Substrate Leverage + Implementation Risk (5 = low risk), maximum 25.

| Rank | Capability | Actor | Exact gap | Type | Freq. | Pain | Value | Leverage | Risk | Total | Recommendation |
|---:|---|---|---|---|---:|---:|---:|---:|---:|---:|---|
| 1 | Parent Session Participation Visibility | Parent | Parent cannot see present/late/absent as session truth; absent sessions disappear because no journey is created | **Type 1 — Presentation/read-projection gap** | 5 | 4 | 5 | 5 | 4 | **23** | **BUILD, after contract design** |
| 2 | School Today Direct Resolution | School admin | Exceptions are detected, but detail is read-only and routes to generic management rather than the exact authorized remediation | **Type 4 — Workflow orchestration gap** | 5 | 3 | 4 | 5 | 4 | **21** | DEFER; detection already solves most of the immediate job |
| 3 | Class-targeted Parent Announcement | School admin / parent | Current writer always resolves all eligible parents in the school; no class/distribution target exists | **Type 2 — Writer/mutation gap** | 3 | 3 | 4 | 4 | 3 | **17** | DEFER until pilot use proves school-wide messaging insufficient |
| 4 | Sent Announcement History | School admin | Sender receives only the immediate receipt and cannot revisit a sent announcement list | **Type 1 — Presentation gap** | 3 | 2 | 3 | 4 | 5 | **17** | DEFER; no operational failure proven |
| 5 | Teacher Assignment Acknowledgment | School / teacher | No acknowledgment state after staffing | **Type 3 — Semantic/domain gap** | 4 | 1 | 2 | 2 | 3 | **12** | REJECT; automatic visibility works and no need for ceremony is proven |

### Evaluated as no-gap / not shortlisted for build

- School weekly scheduling/session planning: **Type 0 — no product gap** for the core create/update/cancel/staff job.
- Teacher daily workflow: **Type 0 — no product gap** for the core today/prepare/start/record/journal job.
- Generic richer parent UI: rejected as cosmetic unless tied to a missing user job.
- P5 audit richness: frozen non-blocking debt; not eligible for P6.

---

## 6. Winner deep validation

| Validation | Result | Evidence |
|---|---|---|
| A. Genuinely incomplete | PASS | No parent attendance contract or UI exists. |
| B. Intended actor cannot complete the job | PASS | Parent cannot see attendance; 3 recorded absences produce 0 parent outcomes. |
| C. No duplication | PASS | School rollup and teacher capture exist, but neither is parent-facing. |
| D. Authority known | PASS | Existing parent contract uses fail-closed `is_child_parent(p_child_id)`. |
| E. Data source known | PASS | `child_observations.attendance` is authoritative; no new attendance writer/table is needed. |
| F. Bounded implementation possible | PASS WITH DESIGN GATE | Add a parent-safe participation read projection and presentation; keep existing journey/outcome contracts intact. |
| G. Concrete product value | PASS | Parent can know whether the child attended, was late, or was absent for each completed/reported session. |

### Why design first

An absent child correctly has no learning journey, skills, media, appreciation, or Home Practice outcome. Simply making `journey_id` nullable inside the existing outcome model would blur two different truths:

- **Participation truth:** present / late / absent.
- **Learning outcome truth:** what the child experienced and what the teacher sent.

P6.1 must define an additive contract that can show an absence without manufacturing a learning outcome or weakening current parent privacy.

---

## 7. Owner value explanation

**Sau P6.1 và build tiếp theo, phụ huynh sẽ biết con có đi học, đi trễ hay vắng ở từng buổi — kể cả khi buổi vắng không có ảnh, kỹ năng hay nhật ký học tập.**

Concrete scenario (tình huống cụ thể):

> Bé nghỉ buổi Ballet chiều thứ Ba. Hiện tại buổi đó biến mất khỏi màn hình phụ huynh vì hệ thống không tạo learning journey cho trẻ vắng. Sau capability này, ba mẹ vẫn thấy “Buổi Ballet · Vắng”, đồng thời hệ thống không hiển thị kỹ năng, ảnh hay Home Practice như thể bé đã tham gia.

---

## 8. Non-blocking defect found during audit

`/school/schedule` labels every `taught_report_pending` session as **“Thiếu nhật ký”**, while live writer `submit_session_journal` sets the session to `taught_report_pending` immediately after inserting a `session_reports.state='submitted'` row.

Live aggregate: 5 sessions are `taught_report_pending`; all 5 have submitted reports. They date from 2026-06-28 to 2026-07-23.

This is a real status-label defect but not a P6 HOLD-level defect because:

- no data, authority, security, or attribution corruption exists;
- School Today checks report existence directly and does not flag these five as missing journal;
- Teacher journal correctly treats the submitted report as submitted;
- the impact is confined to a misleading schedule badge when viewing those historical weeks.

Disposition: bounded corrective debt, separate from the selected product capability. Do not silently fold it into P6.1.

---

## 9. Final P6 decision

**B — NEXT CAPABILITY CONFIRMED — DISCOVERY/DESIGN NEEDED FIRST**

### V128-P6.1 — PARENT SESSION PARTICIPATION CONTRACT DESIGN GATE

- **Actor:** Parent.
- **Job-to-be-done (công việc cần hoàn thành):** Understand whether the child participated in each recent session and distinguish participation from learning outcome.
- **Existing substrate:** `child_observations.attendance`, lesson/session metadata, parent-child authority helper, parent outcomes and journal surfaces.
- **Missing capability:** Parent-safe recent-session participation read contract and UI semantics for present/late/absent, including absence-only sessions.
- **Scope boundary:** Read projection + parent presentation only; no attendance writer change.
- **Authority boundary:** A parent may read participation only for a child accepted by `is_child_parent`; no school-wide or cross-child access.
- **Explicit non-goals:** attendance editing; teacher workflow changes; school rollup redesign; notifications; absence explanations; Home Practice for absent children; synthetic journeys; AI summaries; P5 changes; schedule-status label correction.

### Acceptance criteria for the eventual build

1. A parent sees `Có mặt`, `Đi trễ`, or `Vắng` for a recorded recent session.
2. A present/late session retains the existing outcome, skills, approved media, Home Practice and appreciation behavior.
3. An absent session appears as participation truth without creating/faking a `child_journey` or learning outcome.
4. Absent/unmarked children never receive Home Practice through this capability; current present/late eligibility remains fail-closed.
5. No raw teacher-only summary, internal follow-up, other child, or other family data is exposed.
6. Child switching and response sequencing remain child-scoped and stale-response safe.
7. Existing parent outcome ordering, media signing, consent behavior and appreciation remain regression-free.
8. Backend authority is enforced server-side; frontend visibility is not treated as authorization.

---

## 10. Ready-to-send next-phase prompt

```text
# V128-P6.1 — PARENT SESSION PARTICIPATION CONTRACT DESIGN GATE BOOT

MODE:
READ-ONLY / CONTRACT DESIGN / AUDIT-FIRST / NO IMPLEMENTATION

ROLE MODEL:
Owner = final product authority
ChatGPT = CTO / Architecture Coordinator
Claude = PM / Technical Coordinator / Design Orchestrator
Lovable = Builder only after P6.1.Final and separate Owner build authorization

==================================================
0. OBJECTIVE
==================================================

Design the minimum parent-safe contract that lets a parent understand whether
their child was present, late, or absent for each recent reported/completed
session, without manufacturing a learning outcome for an absent child.

P6 winner:
PARENT SESSION PARTICIPATION VISIBILITY

Proven current gap:

- `child_observations.attendance` already stores present / late / absent.
- `get_parent_session_outcomes` begins from `child_journey`.
- `submit_session_journal` creates `child_journey` only for present / late.
- Parent frontend has no attendance field or attendance presentation.
- Live aggregate at P6 closeout:
  - present: 6 observations, 6 parent outcomes
  - late: 4 observations, 4 parent outcomes
  - absent: 3 observations, 0 parent outcomes
  - all 3 absent observations belong to sessions with reports

This phase is NOT implementation.

==================================================
1. CANONICAL PINS
==================================================

Product repo:
~/dev/demenart
GitHub: huynhtranhuythinh/demenart
Accepted HEAD:
ad30f7a789b26f844affc98d80fda3b2ba1999ef

Docs repo:
~/dev/demenart-docs
GitHub: huynhtranhuythinh/demenart-docs
Accepted HEAD:
f4384d10e44810c911ec189d6527c9b57c131f32

Supabase project:
xcvhacymrbhdhohyylyq
Accepted migration tail:
20260828150205

Retired paths MUST NOT be used:
~/dev/dma
~/dev/dma-docs

Re-pin all three canonical markers before analysis.

==================================================
2. REQUIRED DESIGN QUESTIONS
==================================================

1. What is the canonical distinction between:
   - participation truth
   - learning outcome truth
2. Should the read model be:
   A. additive fields/array in `get_parent_session_outcomes`
   B. a new parent recent-session participation RPC
   C. another bounded option proven safer
3. How should present/late outcomes and absence-only sessions be chronologically merged?
4. What stable identity is used for an absence-only row when no `journey_id` exists?
5. Which session states qualify for parent visibility?
6. How are unmarked attendance records handled fail-closed?
7. How is current Home Practice eligibility preserved exactly for present/late only?
8. Which fields are explicitly prohibited from parent projection?
9. How are child switching, request sequencing and pagination kept correct?
10. Can the build remain additive and migration-bounded without changing writers?

==================================================
3. AUTHORITY BOUNDARY
==================================================

Preserve server-side parent-child authority:

- only a parent accepted by `is_child_parent(p_child_id)` may read participation;
- no cross-child, cross-family, or school-wide projection;
- frontend visibility is never authorization;
- do not expose internal teacher summary, follow-up, support flags, other children,
  unapproved media, or private observations.

==================================================
4. REQUIRED USER SEMANTICS
==================================================

The eventual parent UI must distinguish:

- Có mặt
- Đi trễ
- Vắng

For an absent child:

- show session identity/date/program and `Vắng`;
- do not invent skills, media, appreciation, Home Practice, or learning journey;
- do not create a `child_journey` row merely for presentation.

For present/late:

- preserve existing outcome, media signing, consent, Home Practice and appreciation;
- add participation truth without changing the meaning of the outcome.

==================================================
5. EXPLICIT NON-GOALS
==================================================

- no frontend/backend edits
- no migrations
- no production mutation
- no attendance writer changes
- no school attendance redesign
- no teacher workflow changes
- no notifications or absence explanation workflow
- no AI summary
- no P5 changes
- do not absorb the separate `/school/schedule` status-label defect

==================================================
6. REQUIRED FINAL RETURN
==================================================

Return:

1. Re-pinned Product HEAD, Docs HEAD and migration tail
2. Current parent outcome and attendance lineage
3. Canonical participation-vs-outcome semantic model
4. Options A/B/C with trade-offs
5. Selected contract shape with exact JSON example
6. Stable identity and chronology rules
7. Authority and privacy proof
8. State eligibility and fail-closed rules
9. Frontend presentation states
10. Migration/build impact assessment
11. Acceptance tests
12. P6.1.Final verdict:
    A. CONTRACT READY — RECOMMEND BOUNDED BUILD
    B. OWNER DECISION REQUIRED
    C. CAPABILITY NOT SAFE / STOP
13. If A, a ready-to-send bounded build prompt; do not implement until Owner separately authorizes it

BEGIN V128-P6.1 — PARENT SESSION PARTICIPATION CONTRACT DESIGN GATE.
```

---

## 11. Audit closeout

- Product code changes: `0`
- Docs changes: `0`
- Migrations applied: `0`
- Production data mutations: `0`
- Deployments: `0`
- Final status: **P6 CLOSED — P6.1 DESIGN GATE RECOMMENDED**
