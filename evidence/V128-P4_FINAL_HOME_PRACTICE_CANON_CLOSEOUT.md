# V128-P4 FINAL — HOME PRACTICE PRODUCT VALUE CLOSEOUT CANON

**Project:** DMA — Dế Mèn Art  
**Phase:** V128-P4 — Home Practice  
**Status:** FINAL · PRODUCT VALUE PROVEN · DEPLOYED  
**Closeout date:** 2026-08-27  
**Frontend accepted HEAD:** `db58e7a5ab46c1f33c5443a7d0b4603a9c483bd6`  
**Production backend migration:** `20260826084850` — `v128_p4_1_home_practice`  
**Production site:** `https://demenart.lovable.app`

---

## 1. Canonical Product Outcome

P4 delivers one bounded capability:

> A responsible Teacher can add one simple Home Practice item during lesson closeout, and the correct Parent can see it in the existing post-session experience and later in the child Journal — without manual messaging.

P4 intentionally does **not** create a homework platform, assignment system, submission lifecycle, grading workflow, chat channel, notification engine, due-date system, or new Parent navigation section.

## 2. Product Value Gate — P4.0

**Classification:** Capability Gap Type 2 — underlying learning/session substrate existed, but Home Practice writer and presentation did not.

**Backend classification:** NEW WRITER REQUIRED  
**Standalone model/table:** NOT REQUIRED  
**Authority expansion:** NOT REQUIRED  
**New Parent portal section:** NOT REQUIRED

Approved V1 contract:

- Creator: current responsible Teacher only
- Recipient rule: child attendance `present` or `late`
- Cardinality: maximum one Home Practice per lesson session
- Optionality: lesson can close without Home Practice
- Content: plain-text `title` + `body`
- Limits: title `1–160`, body `1–1000`
- Immutability: no post-submit edit/delete in V1
- Media/material link: deferred

## 3. Backend Canon — P4.1 Phase 1

Production migration applied successfully:

- version: `20260826084850`
- name: `v128_p4_1_home_practice`
- migration count: 175 → 176 at apply time

### Persistence

`session_reports` gained:

- `home_practice_title text NULL`
- `home_practice_body text NULL`

Constraint enforces both-null/both-present and trimmed title/body bounds 1–160 / 1–1000. No standalone homework table and no backfill.

### Writer

`submit_session_journal` evolved in place to four arguments with three trailing defaults. Responsible Teacher authority is unchanged; strict JSON validation happens before mutation; `lesson_sessions` is serialized with `FOR UPDATE`; audit write is fail-closed and atomic; Home Practice is immutable after first closeout; `follow_up` stays internal.

### Read contracts

Home Practice is projected through `get_parent_session_outcomes`, `get_child_journal`, and `get_session_detail`. Parent projection independently gates attendance `present|late` and does not expose internal `summary` or `follow_up`.

### Security posture

All four evolved RPCs were verified as `SECURITY DEFINER`, owner `postgres`, `search_path=''`, with application EXECUTE allowlist limited to `authenticated` and `service_role`, and no PUBLIC/anon/unexpected grants.

### Runtime proof

Rollback-only rehearsal passed cases 1–23. Genuine concurrency case 24 was proven with two independent PostgreSQL backends plus observer in an ephemeral PostgreSQL 16 environment: waiter blocked, first-lock-holder won, second caller resumed into `home_practice_locked`, exactly one report persisted, no duplicate journey/skill/audit effects, and reversed-winner control also passed.

Backend verdict: **LIVE / PROVEN**.

## 4. Frontend Canon — P4.1 Phase 2

Accepted frontend HEAD: `db58e7a5ab46c1f33c5443a7d0b4603a9c483bd6`.

Teacher closeout now supports an optional `Luyện ở nhà` composer only during first closeout, using the same atomic RPC. Submitted Home Practice is read-only; sent sessions without Home Practice cannot reopen the composer.

Parent post-session and Journal surfaces render valid Home Practice content only, fail-safe on null/malformed payloads, and expose no Parent edit/submit capability.

D134 tooling invariant remained pinned: `@lovable.dev/vite-tanstack-config = 2.8.5` in both `package.json` and `bun.lock`.

## 5. UX-1 Canon — Post-submit Journal Action State Clarity

Canonical post-submit state:

- unsent → `Gửi nhật ký`
- sent + new eligible photos → re-approval available
- sent + no new eligible photos → `Nhật ký đã gửi` + `Chưa có ảnh mới cần duyệt`
- successful re-approval → `Đã cập nhật ảnh mới`
- returning to review refreshes canonical photo state and removes stale re-approval CTA

Home Practice remains immutable throughout photo re-approval.

## 6. UX-2 Canon — Contextual Re-approval Journey

### Unsent session

Step 3: `Tiếp tục hoàn tất`  
Step 4: `Gửi nhật ký`  
Success: `Nhật ký đã được gửi`

### Sent session — no new eligible photos

Step 3: normal navigation  
Step 4: `Nhật ký đã gửi`  
Support: `Chưa có ảnh mới cần duyệt`  
No active re-submit CTA.

### Sent session — new eligible photos

Step 3: `Duyệt thêm ảnh mới` — navigation only  
Step 4: `Hoàn thành` — invokes the existing re-approval path  
Success: `Đã cập nhật ảnh mới`

After success, returning to review reloads canonical state. Both Step 3 and Step 4 derive from the same eligible-photo semantics.

## 7. Owner QA Evidence

Owner QA for UX-2: **6/6 PASS**.

Verified:

1. upload new eligible photo → Step 3 becomes `Duyệt thêm ảnh mới`
2. Step 3 only navigates to Step 4
3. Step 4 becomes `Hoàn thành`
4. completion result shows `Đã cập nhật ảnh mới`
5. returning to review removes stale CTA and shows `Nhật ký đã gửi` when no pending photo remains
6. Home Practice remains read-only and unchanged

UX-2 verdict: **OWNER QA ACCEPTED**.

## 8. Deployment

Production publish was initiated after Owner QA acceptance.

- Deployment ID: `5c22997f-baf3-4afc-9ce7-1b72a878bad2`
- Production URL: `https://demenart.lovable.app`
- Lovable project remains in published state
- Latest project screenshot references preview build `db58e7a5`, matching the accepted frontend HEAD

## 9. Frozen Invariants

- Visibility ≠ Authority
- Home Practice ≠ Assignment Management System
- Practice ≠ Assessment
- Parent visibility ≠ Parent edit authority
- Teacher instruction ≠ Chat
- current responsible Teacher only creates Home Practice during first closeout
- Home Practice is immutable after successful closeout in V1
- `follow_up` remains internal school-only content
- Parent eligibility is fail-closed to attendance `present|late`
- photo re-approval never mutates Home Practice
- closeout concurrency is serialized server-side
- audit attribution is fail-closed and atomic
- Step 3/Step 4 re-approval CTA states share one canonical eligibility definition

## 10. Final Product Value Proof

Before P4, a Teacher who wanted a child to practice at home had to rely on manual communication outside DMA.

After P4:

**Teacher closes session → optionally writes one Home Practice → correct Parent sees it in DMA → the same instruction remains available in the child's Journal.**

For already-sent sessions, newly added photos can still be reviewed safely without reopening or changing Home Practice.

### Final Status

**V128-P4 — FINAL: PRODUCT VALUE PROVEN · BACKEND LIVE · FRONTEND OWNER-QA ACCEPTED · DEPLOYED**

## 11. Next Roadmap Phase

**V128-P5 — MISSION CONTROL EXPANSION**

P5 starts from this frozen P4 state and must not reopen P4 Home Practice architecture unless a new product requirement explicitly demands it.
