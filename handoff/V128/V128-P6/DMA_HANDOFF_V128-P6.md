# 🗂️ DMA_HANDOFF — V128-P6 · PARENT SESSION PARTICIPATION VISIBILITY — BUILD + SHIP CLOSEOUT

**Status:** ✅ **P6 COMPLETE — SHIPPED TO PRODUCTION** · Live defects: **NONE** · Deployment: **`demenart.com` (Cloudflare Pages), FE HEAD `c010edda`**
**Date:** 2026-08-30 · **Mode:** Discovery → bounded backend build → bounded FE build → repo canonicalization → placement fix → deploy
**Next phase:** open (P7 / follow-on). *Principal Action Loop* = ranked-#2 DEFER.

> Endpoint after this closeout: **RULES D381 · SYSTEM_MAP v1.69 · HANDOFF V128-P6-BUILD-SHIP-CLOSEOUT · backend tail `20260830050025` · migration count 185 · product-repo FE HEAD `c010edda` · FE main pin `2.8.5`.** Prior endpoint (D380 / v1.68 / V128-P5.5-CANONICAL-CLOSEOUT) = HISTORICAL SNAPSHOT (BẤT BIẾN). Permanent lifecycle baseline unchanged: **1 decision / 2 transitions** (P6 opened no Mission-Control decision).

---

## 1. REPOSITORY / BACKEND STATE

- **Product repo:** `~/dev/demenart` · GitHub `huynhtranhuythinh/demenart`. Baseline before P6 FE: `ad30f7a789b26f844affc98d80fda3b2ba1999ef`. **Current FE HEAD:** `c010edda0e24b6d33fbd5ce6badf7dab668a7d30` (P6.3 + P6.3.1 canonicalization + P6.3.2 placement).
- **Docs repo:** `~/dev/demenart-docs` · HEAD `f4384d10e44810c911ec189d6527c9b57c131f32` (no drift at closeout).
- **Live Supabase:** `xcvhacymrbhdhohyylyq` · migration tail **`20260830050025`** · count **185**.
- **Repo migration file materialized (P6.3.1):** `supabase/migrations/20260830050025_v128_p6_2_parent_session_participation.sql` (exact applied bytes; NOT re-applied).
- **Tooling pin:** `@lovable.dev/vite-tanstack-config` = `2.8.5` (float detected + restored twice; `bun.lock` md5 `79bf3f6026fae0912df939cf2b827f08` = baseline byte-identical).

---

## 2. PHASE LOG

| Phase | What | Result |
|---|---|---|
| **P6.1** | Product Value Gate discovery. Audited school/teacher/parent loops end-to-end (live DB + repo). | Winner = **Parent Session Participation Visibility** (TYPE 1 read-projection). *Principal Action Loop* reclassified **DEFER #2** — no runtime evidence (`today_sessions=0`, `all_missing_responsible=0`). Prior "attendance done" claim corrected: absent sessions were invisible to parents. |
| **P6.2** | Backend build (1 migration). `get_parent_session_participation`. | Applied `20260830050025` (184→185). Behavioral evidence via JWT impersonation PASS. Zero `child_journey` mutation (44/19). |
| **P6.3** | FE build (agent, auto-app). model + hook + component + Home/Journal integration + materialized migration file. | Landed; typecheck/build PASS (agent env); pin float restored. |
| **P6.3.1** | Repo canonicalization. `bun.lock` transitive drift + missing migration file. | `bun.lock` restored byte-exact (md5 baseline); `package.json` 2.8.5; migration file materialized. Commit `f46e1720`. |
| **P6.3.2** | Home placement fix (paste-mode). Participation was buried at section bottom. | Moved above learning-outcome heading. First paste mis-landed (formatting revert, then duplicate `{latest && (`); fixed. Commit `c010edda`. |
| **Ship** | Owner deploy. | Production `demenart.com/parent` re-QA **PASS**. |

---

## 3. FROZEN CONTRACT (see D381 for full rules)

**`public.get_parent_session_participation(p_child_id uuid, p_limit integer default 10) returns jsonb`** — STABLE · SECURITY DEFINER · `search_path=''` · md5 `69058495309f6f8dbb44a31113fbe604` · ACL `authenticated`+`service_role` (no anon/PUBLIC).

- **Enumeration:** `child_observations` only, `attendance ∈ {present,late,absent}`, `ls.scheduled_at IS NOT NULL`, `ls.state ∈ {taught_report_pending, report_pending_approval, completed}`. `DISTINCT ON (session_id)`.
- **Provenance:** `outcome_available`/`journey_id` from `child_journey` (child + `ref_id=session_id` + `entry_type='session'` + `source='demen'`) only. Absent ⇒ null/false; **never mint child_journey**.
- **Order/paging:** `scheduled_at DESC NULLS LAST, session_id DESC`; clamp `1..20`; `has_more` via `+1`.
- **Authority:** `is_child_parent` fail-closed; unauth/unrelated/nonexistent = `{ok:false, reason:'not_authorized', participation:[], has_more:false}`.
- **Row:** `{session_id, scheduled_at, session_title, program_name, attendance, outcome_available, journey_id}` (7-key allowlist).

**Invariant:** Participation Truth (Có mặt/Đi trễ/Vắng) ⟂ Learning-Outcome Truth. `get_parent_session_outcomes` / `get_child_journal` / `submit_session_journal` UNCHANGED.

---

## 4. FRONTEND

`src/features/parent/session-participation/`: `parentSessionParticipationModel.ts` (pure; never infers absent), `useParentSessionParticipation.ts` (stale-guard mirror of `useParentSessionOutcomes`), `ParentSessionParticipation.tsx` (`ParentParticipationLatest` Home, `ParentParticipationList` Journal).
- **Home** `/parent` (`ParentSessionOutcomeSection`): *Tham gia gần nhất* rendered ABOVE "Lần gần nhất của con"; absence never replaces an outcome.
- **Journal** `/parent/journal`: "Tham gia buổi học" — separate stream, no timeline injection.
- Labels: present=Có mặt · late=Đi trễ · absent=Vắng.

---

## 5. QA / EVIDENCE

- **Backend (JWT impersonation, live):** present→Có mặt (+ outcome intact) · late→Đi trễ · absent→exactly one participation-only row, `journey_id=null`, `outcome_available=false` (relational-equivalent, no absent-linked auth parent) · unauthorized child → not_authorized (no leak) · limit 1/999/null clamp · ordering deterministic · demen provenance (non-demen session journeys=0) · **Δchild_journey = 0**.
- **FE (Owner, production):** `/parent` placement + Có mặt/Đi trễ label mapping PASS (screenshot 2026-08-30). Independence: participation + learning outcome shown side-by-side.
- **QA accounts:** `ph.hung.kidshouse@demo.demenart.com` / `Test@123` (child Nguyễn Hoàng An: present×1, late×2) · `ph.toan.kidshouse@demo.demenart.com` / `Test@123` (Trần Thanh Bình: present×2, late×1).

---

## 6. DEFERRED / DEBT (not defects)

1. **Absent-case live UI QA** — no absent-observation child has an auth-linked parent in pilot data; proven via RPC evidence + component logic instead.
2. **Principal Action Loop (ranked #2)** — legitimate TYPE-4 orchestration gap (School "Hôm nay" attention panel is read-only) but not built: no current runtime exception exercises it; revisit when future sessions exist.
3. **Tooling standing hazards (now canon, D381.8–D381.11):** `get_diff` hides bun.lock · platform pin re-float after every agent dispatch · agent blocks `supabase/migrations/` writes + `git checkout`/`git add` · paste-mode mis-land.

---

## 7. DEPLOYMENT / PRODUCT STATUS

FE shipped to production `demenart.com` (Cloudflare Pages, `main → c010edda`). Backend RPC live (tail `20260830050025`, count 185). Pin `2.8.5`, `bun.lock` baseline-identical. Repo migration file materialized. No DB mutation beyond the one authorized migration; no data mutation; Mission-Control registry unchanged (4 rows); lifecycle unchanged (1 decision / 2 transitions).

---

## 8. ENDPOINT

RULES **D381** · SYSTEM_MAP **v1.69** · HANDOFF **V128-P6-BUILD-SHIP-CLOSEOUT** · backend tail **`20260830050025`** · migration count **185** · FE HEAD **`c010edda`** · FE main pin **`2.8.5`**. Prior (D380/v1.68/V128-P5.5) = HISTORICAL SNAPSHOT (BẤT BIẾN).
