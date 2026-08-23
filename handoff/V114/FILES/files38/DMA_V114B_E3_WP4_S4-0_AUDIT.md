# DMA_V114B-E3 · WP4-S4 · S4-0 — FRONTEND AUTHORITY SURFACE AUDIT (READ-ONLY CLOSEOUT)

> Phase: **S4-0** (evidence-producing, read-only). No code / DB / migration / deploy / doc change made.
> Baseline audited: backend migration **114** live · frontend tip **d8178a55** (unchanged since 2026-07-22).
> Skew window: **OPEN** (opened 2026-07-24 16:29:21 ICT). `class_distributions.lead_teacher_id` not touched. No closure attempted.

---

## 1. EXECUTIVE VERDICT

**S4-0 PASS WITH P2 DEBT — implementation-ready.**

- The complete journal-authority surface was traced end-to-end. There is exactly **one** authority decision and **one** `submit_session_journal` call in the whole frontend, both in `StepReview` inside `teacher.session.$id.tsx`. No alternate/direct-write journal path exists.
- **Root cause confirmed (P1, expected):** the Step-4 CTA derives authority from `is_lead` via `get_teacher_classes`, **not** from `can_submit_journal`. The backend already returns all three canonical fields; the frontend `Detail` type omits them and every consumer drops them.
- The bug is **fully fail-closed at the command layer** — no cross-school/parent/admin can obtain an authorized submit through frontend logic; the server re-checks responsibility on every call. So **no Security Stop-Gate and no Owner Gate is triggered.**
- **S4 can be frontend-only.** No schema/RLS/RPC/`lead_teacher_id` change is required; the capability contract is complete and live.
- Residual P2 (non-blocking): stale copy on the admin schedule sheet, capability-unaware navigation CTAs on Today/Journal-list, and **total absence of any frontend test harness** (a build item for S4-4, not an audit blocker).

---

## 2. REPOSITORY BASELINE

| Item | Value |
|---|---|
| Frontend repo | Lovable `d9d56000-3cf9-4c46-9890-651edc53d73f` (single-writer, direct-main) |
| Frontend tip (HEAD) | `d8178a55895b64bbffdf79bb05c06e6b4313d68b` — "Lovable update", 2026-07-22 06:07:04Z |
| Prior edits | `fa52656b` (06:00:41Z), `70275984` (05:08:14Z) — all 2026-07-22; no frontend commit since |
| Matches S3A record | ✅ S3A closeout recorded frontend HEAD `d8178a55` "unchanged — backend-only". Confirmed: no drift. |
| Backend | Supabase `xcvhacymrbhdhohyylyq` · latest migration `20260724092921 v114b_e3_wp4_s3_authority_cutover` (registry 114). Verified live. |
| Framework | TanStack Start (file-based routing; several routes `ssr:false`), React 18, `@tanstack/react-router` |
| Data layer | **Raw `supabase-js` `.rpc()`/`.from()` into `useState`+`useEffect`.** No TanStack Query / React Query, **no route loaders**, no query cache. `sonner` for toasts. shadcn/ui + Tailwind. |
| Deployed commit | Cloudflare Pages CI from main; deployed tip provably = repo tip `d8178a55` (no post-cutover frontend commit). |
| Read-only confirmation | ✅ Only `list_edits`, `list_files`, `read_file` (Lovable) and `SELECT`/`pg_get_functiondef` (Supabase) were used. No write tool invoked. No files created/edited in the repo or DB. |
| Pre-existing untracked/uncommitted | N/A — Lovable model has no working-tree; tip is a committed snapshot. Nothing staged/pending. |

---

## 3. PRODUCTION ROUTE & SURFACE INVENTORY

| ID | Route / surface | Audience | Entry path | Session-detail source | Journal affordance | Responsive variants | Status |
|---|---|---|---|---|---|---|---|
| R-1 | `/_authenticated/teacher/session/$id` (`teacher.session.$id.tsx`) — 4-step flow | Teacher | Today CTA, Journal-list card, back/deep-link | `get_session_detail` (imperative, on mount) | **YES — the only submit path** (`StepReview.submit` → `submit_session_journal`); the only authority decision (`StepReview.canSubmit`) | single component, `sm:`/`lg:` classes — **shared logic, no separate authority per breakpoint** | **AUTHORITY SURFACE** |
| R-2 | `/_authenticated/teacher/` (`teacher.index.tsx`) — Today | Teacher | Home | `get_session_detail` (prep labels only) | Navigation CTA "Hoàn tất & gửi nhật ký" → routes to R-1 (no gate here) | shared responsive grid | Presentation/nav only |
| R-3 | `/_authenticated/teacher/journal` (`teacher.journal.tsx`) — journal list | Teacher | Home/nav | `get_teacher_journals` (list, server-computed `journal_status`) | Cards are `<Link>` to R-1; "Ghi nhận ngay" is nav | shared | Presentation/nav only |
| R-4 | `/_authenticated/school/schedule` (`school.schedule.tsx`) — week grid + detail Sheet | Master/sub admin, lead/assistant teacher | `/school/manage` → schedule | Detail Sheet reads `lesson_sessions`+`session_teachers` directly | **NONE** — ops only (`update_lesson_session`, `set_session_teachers`, `cancel_lesson_session`) | Sheet + horiz-scroll grid, shared logic | Ops surface, **no journal CTA** |

**Not journal-authority surfaces (confirmed):** `teacher.classes`, `teacher.classroom`, `teacher.curriculum`, `teacher.media`, `teacher.moments`, `school.manage`, `parent.*`, `admin.*`. None call `submit_session_journal`.

---

## 4. END-TO-END AUTHORITY DATA FLOW (R-1, the only authority path)

```
Route /_authenticated/teacher/session/$id  (SessionFlow)
  → loadDetail(): supabase.rpc("get_session_detail" as never, {p_session_id})
      RPC (SECURITY DEFINER, search_path=public):
        returns { ok, can_submit_journal, submit_block_reason, responsible_teacher, session{…}, prep_items[] }
  → type Detail = { ok; reason?; session; prep_items }   ⟵ ❌ DROPS all 3 canonical fields
  → SessionFlow renders Stepper; Step 4 = StepReview
      StepReview.load():
        Promise.all([ get_session_roster, get_session_moments, get_teacher_classes ])
        canSubmit := rows.some(c.is_lead && c.sessions.includes(session.id))   ⟵ ❌ AUTHORITY FROM is_lead
      CTA render:
        canSubmit===null → "Đang kiểm tra quyền gửi…" (spinner)
        canSubmit===true → enabled "Hoàn tất & gửi nhật ký"
        canSubmit===false→ hidden CTA + "Chỉ giáo viên phụ trách buổi mới gửi được…"
  → StepReview.submit(): guard `if (canSubmit !== true) return;`
        supabase.rpc("submit_session_journal" as never, {p_session_id,p_summary,p_follow_up})
        RPC gate (independent, authoritative): actor==responsible ∧ same_school ∧ state ∈ submit-states
  → onError: string-match reason → forbidden / bad_state / (else generic)
  → onSuccess: setResult(...) → "Đã gửi" screen; parent onSent()→loadDetail() refetch
```

**The command layer (`submit_session_journal`) is the true authority and is correct.** The frontend gate is a *presentation mirror derived from the wrong source* (`is_lead`), which the backend overrides.

---

## 5. CLASSIFIED FINDINGS

| ID | Sev | Class | File · symbol | Current behavior | Authority source | Safe / unsafe | Slice | Correction |
|---|---|---|---|---|---|---|---|---|
| F1 | **P1** | **A** | `teacher.session.$id.tsx` · `StepReview.load()`/`canSubmit` | Submit CTA gated by `is_lead` from `get_teacher_classes` | `is_lead` (class lead) — **wrong post-S3A** | Fail-closed (server denies), but **misroutes the legitimate user**; violates D290 | S4-1/S4-2 | Gate on `can_submit_journal` from `get_session_detail`; delete `get_teacher_classes`/`is_lead` derivation |
| F2 | **P1** | **C** | `teacher.session.$id.tsx` · `type Detail` + `loadDetail` | `Detail` omits `can_submit_journal`/`submit_block_reason`/`responsible_teacher`; runtime drops them | n/a (transport) | Enabling gap for F1 | S4-1 | Add fields to type; read them; thread to StepReview |
| F3 | P2 | C | `teacher.index.tsx` · Today `get_session_detail` | Consumes only `prep_items`; drops capability | n/a | Prep-only use, no authority | S4-1 (opt) | Optionally consume `can_submit_journal` to make Today CTA capability-aware |
| F4 | P2 | B | `teacher.index.tsx` · `HeroCard` CTA "Hoàn tất & gửi nhật ký" | Shown from `readiness.status=report_pending`; navigates to R-1 | session state, not responsibility | Fail-closed at R-1 | S4-2 (opt) | Reflect capability so non-responsible sees "xem lại" not "gửi" |
| F5 | P2 | B | `teacher.journal.tsx` · "Cần ghi nhận"/"Ghi nhận ngay" | Grouped by `journal_status`; `<Link>` only | server status | Fail-closed at R-1 | — | Acceptable; optional capability hint |
| F6 | P2 | B | `school.schedule.tsx` · copy "Người gửi nhật ký … là Giáo viên chính của môn" | States journal sender = subject lead | copy (stale) | Misleading post-S3A (sender = responsible teacher) | S4-2 | Reword to "giáo viên phụ trách buổi (người bắt đầu buổi)" |
| F7 | P2 | E | `school.schedule.tsx` · `plannedLine`, `get_school_week_planned_teachers`, `has_planned_assignment`, `evidence_grade` | Displays "Giáo viên dự kiến" with evidence grade | planned assignment (labeled) | **Safe** — planning display, never asserts journal authority | — | None (keep) |
| F8 | P2 | E | `school.schedule.tsx` · `ActiveDistribution.lead_teacher_id` selected in `loadRefs` | Fetched, **not consumed** in render/authority | n/a | Safe (dead field) | — | Optional cleanup |
| F9 | P2 | B/D | `teacher.session.$id.tsx` · `StepReview.submit` error map | Handles `forbidden`,`bad_state`, else generic | string-match | Misses `session_not_found`, `no_responsible_assignment` → generic copy | S4-2/S4-3 | Structured code→copy map incl. all reasons + unknown→fail-closed |
| F10 | P2 | D | `teacher.session.$id.tsx` · `start_session` success | `onStart()`→step 2, **no detail refetch** | n/a | Responsibility birth not reflected until remount | S4-3 | Refetch `get_session_detail` after `start_session` ok |
| F11 | P1(QA) | F | repo-wide | **No test/mock/fixture/story/e2e files exist anywhere** | n/a | Blocks Q1–Q15 evidence | S4-4 | Stand up vitest + testing-library (+ Playwright for E2E) |

**Direct table writes (record surface, classified E — not journal authority, RLS-guarded, in-scope-correct per V114A §3.2):** `prep_items`, `child_observations`, `session_marks`, `moment_children`, `learning_moments`, `support_requests`. None is a journal command; none writes `session_reports`.

---

## 6. LEGACY-LEAD SEARCH ACCOUNTING

| Category | Count | Items |
|---|---|---|
| Total relevant hits reviewed | 11 | F1–F11 above + direct-write cluster |
| Authority-affecting | **1** | F1 (`StepReview.canSubmit` via `is_lead`) |
| Presentation-only | 4 | F4, F5, F6, F9 |
| Legitimate non-authority lead/planned use | 2 | F7 (planned teacher display), F8 (unused `lead_teacher_id`) |
| Transport (drops canonical fields) | 2 | F2, F3 |
| Test/mock/fixture | 0 present (F11 = absence) | — |
| **UNRESOLVED** | **0** | — |

Zero unresolved hits. Every `lead`/`is_lead`/`planned`/`taught_by` reference is classified with evidence.

---

## 7. CANONICAL FIELD CONTRACT

Verified from live `pg_get_functiondef(get_session_detail)`.

| Field | Backend evidence | Frontend type | Runtime transport | Drop risk | Consuming surfaces | Current fallback |
|---|---|---|---|---|---|---|
| `can_submit_journal` (bool) | Returned on `ok:true`; computed by same gate as submit | **None** (not in generated types; RPC called `as never`; hand-written `Detail` omits it) | Present in JSON, never read | **Dropped by every consumer** | **0** (R-1 uses `is_lead` instead; R-2 ignores) | CTA falls back to `is_lead` → F1 |
| `submit_block_reason` (text\|null) | Values: `forbidden` · `no_responsible_assignment` · `bad_state` · `null` | None | Present, never read | Dropped | 0 | Submit-time string-match only (F9) |
| `responsible_teacher` (jsonb\|null) | `{profile_id, display_name, assignment_source, evidence_grade, valid_from}` | None | Present, never read | Dropped | 0 | **Never displayed** anywhere |

Detail capability logic (authoritative mirror of submit): `actor null / ¬same_school → forbidden`; `responsible null → no_responsible_assignment`; `responsible≠actor → forbidden`; `state ∉ {in_progress, taught_report_pending, report_pending_approval, completed} → bad_state`; else `can_submit=true`.

---

## 8. SUBMIT_BLOCK_REASON INVENTORY

Not a Postgres enum — computed strings. Full observed set (no invented values):

| Value | Evidence location | Current UI handling | Target UX category | Unknown/fallback |
|---|---|---|---|---|
| `forbidden` | `get_session_detail` + `submit_session_journal` defs | Submit→"Chỉ GV phụ trách buổi mới gửi"; detail path: **not consumed** (CTA hidden via wrong `is_lead`) | Absent/disabled CTA + "bạn không phải GV phụ trách buổi này" | fail-closed |
| `no_responsible_assignment` | both defs | Submit→**generic** "Không gửi được…"; detail: not consumed | Disabled CTA + "buổi chưa có GV phụ trách" | fail-closed |
| `bad_state` | both defs | Submit→"Buổi chưa ở trạng thái có thể gửi"; detail: not consumed | Disabled CTA + session-state explanation | fail-closed |
| `null` (can_submit=true) | `get_session_detail` def | Not consumed | Enabled CTA | n/a |
| `session_not_found` | `submit_session_journal` def **only** (detail uses `not_found`) | Submit→**generic**; not distinguished | Not-found/recovery, drop CTA | fail-closed |

> **Contract asymmetry to encode in S4:** detail not-found = `not_found`; submit not-found = `session_not_found`. `loadDetail` already matches `not_found` correctly; the submit handler must additionally recognise `session_not_found`.

---

## 9. MUTATION & FRESHNESS AUDIT

- **Data architecture:** imperative `supabase-js` into `useState` via `useEffect`. **No query cache, no queryKeys, no `invalidateQueries`, no `staleTime`/`gcTime`/`placeholderData`/`initialData`, no persisted cache, no route loaders.**
- **Submit path:** `StepReview.submit` → `submit_session_journal` (only journal command).
- **Lifecycle-changing mutations:** `start_session` (responsibility birth; StepPrep), `submit_session_journal` (StepReview), plus ops mutations on R-4 (`create/update/cancel_lesson_session`, `set_session_teachers`) — none of which touch `class_distributions.lead_teacher_id`.
- **Invalidation/refetch:**
  - submit **success** → `onSent()` → parent `loadDetail()` refetches `get_session_detail`. ✔
  - submit **error** → toast only; **no forced re-load of server truth** (F9/S4-3 gap).
  - `start_session` success → step advance, **no detail refetch** (F10/S4-3 gap: `responsible_teacher`/`can_submit` not refreshed until remount).
- **Optimistic behavior:** only `saveObs` (observations) is optimistic — **not** authority/journal. No optimistic submit-success, no optimistic authority grant. ✔
- **Stale-capability risk:** **Low across navigation** — every mount refetches; **deep-link ≡ in-app nav ≡ hard reload** (all mount fresh, same `useEffect`). Residual risk is only *intra-mount* (capability changed server-side while page open) — mitigated because submit re-checks server-side (fail-closed). Post-S4, capability comes from the mount-time `get_session_detail`.
- **Recovery from command errors (current):** `forbidden`/`bad_state` → inline copy, CTA remains (stale-enabled) until user leaves; `no_responsible_assignment`/`session_not_found` → generic; **no automatic server-truth refresh** on error.

---

## 10. CURRENT UX JOURNEY ("Hôm nay tôi cần làm gì?")

| Persona | What they see | What they believe | What server authorizes | Mismatch |
|---|---|---|---|---|
| **Responsible teacher** (is responsible; state in_progress) | If also lead: enabled CTA → submits OK. If **not** lead: CTA **hidden** + "chỉ GV phụ trách" | "I can't send" (when not lead) | **Allowed** | ❌ **Legitimate teacher blocked when responsible-but-not-lead** (P1) |
| **Same-school non-responsible teacher** (is lead) | Enabled CTA | "I can send" | **Forbidden** | ❌ **Enabled door → forbidden** (D290, P1) |
| **Same-school admin** (not responsible) | `get_teacher_classes` returns no lead-of-this → CTA hidden | "I can't send here" | Forbidden | ✔ fail-closed, but *incidental* (not principled) |
| **Parent** | R-1 is teacher-namespaced; `get_session_detail` forbids non-same-school; parent has `school_id=NULL` → detail `forbidden` → "Cô không có quyền xem" | "No access" | Forbidden | ✔ |
| **My / Linh counterfactual** | My (lead, ¬resp): enabled → server forbidden. Linh (¬lead, resp): hidden → server would allow. | Inverted from truth | Truth = responsibility | ❌ **Exactly inverted** — this is the S4 target |

**`responsible_teacher` is displayed nowhere.** No teacher identity/badge appears on R-1 at all; R-4 shows only *planned* teacher.

---

## 11. QA COVERAGE MATRIX Q1–Q15

**Current coverage: ZERO for all rows (no test files exist).** Fixtures should be synthetic/seeded (do **not** mutate production to create personas — V114A discipline). Demo personas for manual smoke: responsible=Đặng Mỹ Linh `gv.linh.kidshouse`; lead-not-responsible=Lê Thảo My `gv.my.kidshouse`; admin=`hieutruong.kidshouse`; parent=`ph.hung.kidshouse`; cross-school=`gv.han.demen` (all `Test@123` except temp-password accounts).

| Q | Scenario | Fixture payload (`get_session_detail`) | Expect CTA vis | Expect enabled | Resp-teacher shown | Copy category | Command | Refresh/recovery | Missing coverage → layer |
|---|---|---|---|---|---|---|---|---|---|
| Q1 | Responsible, valid state | can_submit=true, reason=null, responsible={self} | visible | **enabled** | yes | — | ok | refetch on success | Component + E2E |
| Q2 | Same-school non-responsible teacher | can_submit=false, forbidden | visible | disabled | yes(other) | "not responsible" | forbidden | — | Component |
| Q3 | Same-school admin (not resp) | can_submit=false, forbidden | absent/disabled | disabled | yes(other) | "not responsible" | forbidden | — | Component |
| Q4 | Cross-school actor | detail `forbidden` | error surface | n/a | n/a | no-access | forbidden | — | Integration |
| Q5 | Parent | detail `forbidden` | error surface | n/a | n/a | no-access | forbidden | — | Integration |
| Q6 | No responsible assignment | can_submit=false, no_responsible_assignment, responsible=null | visible | disabled | "chưa có GV phụ trách" | no-responsible | (submit) no_responsible_assignment | — | Component |
| Q7 | Bad session state | can_submit=false, bad_state | visible | disabled | yes | state explanation | bad_state | — | Component |
| Q8 | Stale cap: UI allowed → cmd forbidden | mount true, server flips | enabled→ | on submit forbidden | yes | recover | forbidden | **must refresh + drop CTA** | Integration |
| Q9 | Stale lifecycle → bad_state | mount true, state changed | enabled→ | on submit bad_state | yes | recover | bad_state | refresh | Integration |
| Q10 | session_not_found after deep-link | detail ok then gone | → not-found | — | — | not-found | session_not_found | drop CTA | Integration/E2E |
| Q11 | **Lead-change counterfactual** | My: false/forbidden · Linh: true/null | My disabled; Linh enabled | per capability | yes | — | My forbidden; Linh allowed | — | **E2E (primary)** |
| Q12 | Unknown/missing submit_block_reason | can_submit=false, reason="???" | disabled | disabled | maybe | generic fail-closed + report | (n/a) | — | Component |
| Q13 | Partial payload (field missing) | field absent | disabled (fail-closed) | disabled | — | generic | — | — | Component |
| Q14 | Mutation pending / double-activate | can_submit=true | enabled, disabled-while-pending | pending guards | yes | — | single submit | — | Component |
| Q15 | Successful submit → canonical refresh | true → success | success screen | — | — | success | ok | **invalidate detail + dependent surfaces** | Integration + E2E |

**Responsive strategy (no triplication):** R-1 uses one shared component with Tailwind breakpoints — prove capability logic **once** at component/integration layer (breakpoint-independent), then a **single viewport-smoke** (mobile/tablet/desktop) asserting render parity of the CTA/reason/`responsible_teacher` block. E2E counterfactual (Q11) run once desktop + once mobile.

---

## 12. FILE-LEVEL IMPLEMENTATION PLAN

**S4-1 — Canonical capability consumption**
- `src/routes/_authenticated/teacher.session.$id.tsx`: extend `type Detail` with `can_submit_journal: boolean`, `submit_block_reason: string | null`, `responsible_teacher: {profile_id; display_name; assignment_source; evidence_grade; valid_from} | null`; read them in `loadDetail`; thread into `StepReview` via props. **Remove** the `get_teacher_classes`/`is_lead` derivation.
- (optional) `src/integrations/supabase/*`: add a typed wrapper (or regenerate types) for `get_session_detail`/`submit_session_journal` to retire `as never`/`as any` on this path.
- (optional) `teacher.index.tsx`: read `can_submit_journal` if Today CTA is made capability-aware (else leave; prep-only use is harmless).
- Behavior changed: authority source moves lead→capability. Tests: type + transport unit. Risk: low. Rollback boundary: single file revert.

**S4-2 — Journal action UX**
- `teacher.session.$id.tsx` `StepReview`: CTA driven by `can_submit_journal`; `submit_block_reason`→copy map (`forbidden` / `no_responsible_assignment` / `bad_state` / unknown→fail-closed); render `responsible_teacher` (display_name + `evidence_grade` chip) in header and review; loading uses `can_submit===undefined`. Structured submit-error handler incl. `session_not_found`.
- `school.schedule.tsx`: reword F6 copy.
- Tests: component states Q1–Q3,Q6,Q7,Q12,Q13,Q14. Risk: low. Rollback: per-file.

**S4-3 — Freshness & lifecycle integrity**
- `teacher.session.$id.tsx`: refetch `get_session_detail` after `start_session` success (F10); on submit error (`forbidden`/`bad_state`/`no_responsible_assignment`/`session_not_found`) re-load detail and drop enabled CTA (F9/Q8–Q10); confirm deep-link/reload parity (already equivalent — add regression guard).
- Tests: Q8,Q9,Q10,Q15 integration. Risk: low. Rollback: per-file.

**S4-4 — Counterfactual & responsive QA**
- New: test harness (`vitest`, `@testing-library/react`, `@testing-library/jest-dom`; `@playwright/test` for E2E) + config; component/integration/E2E specs per §11; synthetic fixtures/mocks for each payload; Q11 counterfactual E2E; viewport-parity smoke.
- Risk: infra addition only; no production behavior change. Rollback: delete test dirs/config.

**S4-5 — Production release & skew-window closure**
- Build/typecheck; deploy via Cloudflare CI (direct-main); production smoke (responsible submits; non-responsible blocked-with-reason; responsible-not-lead **can** submit; lead-not-responsible blocked); capture post-deploy counterfactual evidence; **verify `class_distributions.lead_teacher_id` unchanged**; **then** close skew window with evidence. Rollback: revert frontend commit; skew window stays OPEN if smoke fails.

---

## 13. GATES & RISKS

| Gate / risk | Status |
|---|---|
| **Security Stop-Gate** | **NOT triggered.** No direct-write/alternate submit path; no cross-school/parent enabled action (server fail-closed); required capability is present in backend; frontend never writes `session_reports`; backend contract consistent with S3A; fix needs no schema/RLS/RPC/`lead_teacher_id` change; no service-role/secret in the journal path. |
| **Owner Gate** | **NOT triggered.** Fix = "consume existing `can_submit_journal`." No responsibility-transfer UI, admin override, class-assignment redesign, new role model, `session_reports` containment, or data migration. |
| **Milestone Review** | This is the S4-0 deliverable — awaiting CTO verdict before any edit. |
| E3-SG-01 | **OPEN** (unchanged; not proven closed here). |
| E3-SG-02 | **CONTAINED** (authenticated/anon user-JWT path). |
| R21 | **ACTIVE.** |
| `session_reports` containment | **Unresolved** (retained residual; not an S4 frontend concern — frontend never writes/reads `session_reports` directly). |
| `pg_default_acl` debt | Open (unchanged). |
| sub_admin QA debt | Open (unchanged). |
| Vũ Hoàng Nam auth-persona debt | Open (unchanged). |
| Trần Khánh Vy auth-persona debt | Open (unchanged). |

No residual debt marked closed.

---

## 14. SKEW-WINDOW STATUS

- **OPEN.**
- Opened **2026-07-24 16:29:21 ICT**.
- `class_distributions.lead_teacher_id` **unchanged** (only catalog/`SELECT` reads performed; no frontend path in the journal flow mutates it).
- **Closure criteria (future, S4-5):** S4 deployed to production **and** post-deploy verification PASS (responsible-not-lead can submit; lead-not-responsible blocked-with-reason; counterfactual evidence captured) **and** `lead_teacher_id` confirmed unchanged.
- **No closure attempted in S4-0.**

---

## 15. RECOMMENDED NEXT EXECUTION PROMPT BOUNDARY

**Next approved action: S4-1 + S4-2 as one bounded vertical slice** (single file, `teacher.session.$id.tsx`, with the F6 copy touch in `school.schedule.tsx`).

Rationale: capability consumption (S4-1) and the CTA/reason/`responsible_teacher` UX (S4-2) are inseparable in the same component — shipping S4-1 alone would leave a typed-but-unrendered capability and still route through the old CTA. Combining them is the smallest change that flips the authority source and makes it visible, with a one-file rollback boundary. S4-3 (freshness) should follow as its own slice; S4-4/S4-5 gated after.

Exact scope of the S4-1+S4-2 slice: extend `Detail` type + `loadDetail`; delete `get_teacher_classes`/`is_lead` gate; drive CTA from `can_submit_journal`; map `submit_block_reason` → copy (all four values + unknown fail-closed); render `responsible_teacher`; reword F6. **No** freshness/lifecycle refetch changes (that is S4-3). **No** tests yet (S4-4). **No** deploy (S4-5).

*Await CTO verdict and implementation prompt. No code edited in S4-0.*
