# 🗂️ DMA_HANDOFF_V128-P7 — POST-SESSION CHILD FOLLOW-UP — FINAL CLOSEOUT

> Capability **V128-P7 — POST-SESSION CHILD FOLLOW-UP** closed and released to production.
> **Docs-only closeout.** 0 product mutation · 0 DB mutation performed during this closeout.
> Final runtime pin is **189 / M3**, NOT 188 / M2. M2 remains documented as the TODO-count integration migration.
>
> **Endpoint (fill RULES/SYSTEM_MAP anchors against live tail):**
> RULES **D‹live max +1›** · SYSTEM_MAP **v‹live +1›** · HANDOFF **V128-P7** ·
> backend count **189** · backend tail `20260831055744 v128_p7_3_3_follow_up_rpc_anon_revoke` ·
> FE Product SHA `cfac171cdd1023bbf780688cab50ab3544f0fcce` · FE main pin `2.8.5`.

---

## 0. VERDICT & PROVENANCE (honest record)

Gate outcome (Owner authority): **V128-P7 — CLOSED — RELEASED — PRODUCTION VALIDATED.**

Evidence provenance split — recorded so nothing is over-claimed:

- **[Independently verified — Claude, live production Supabase]** — backend migration lineage, ACL least-privilege end-state, function body-hash invariance, trigger count, RLS, CFA fixture state.
- **[Owner-attested]** — production deployment to `demenart.com` and production UI screenshots (teacher home + zero-state + regression surfaces).
- **[NOT EXERCISABLE / not fabricated]** — production behavioral follow-up cases requiring an OPEN fixture (open=0 in production), and the destructive resolve smoke. Recorded as NOT EXERCISABLE, **no fabricated PASS**.
- **[Limitation]** — no independent production asset-SHA fingerprint was captured from the release-orchestration runtime; production identity rests on Owner attestation + `main`→Cloudflare auto-deploy convention (D105/D309.1).

---

## 1. CAPABILITY

Post-session child follow-up: when a teacher closes out a session, an authoritative closeout observation signal (needs_support / follow_up_needed) on a present/late child creates a narrow follow-up **action** that the responsible teacher can later RESOLVE. Observation truth and action state are separate lifecycles; the child's pedagogical record is never rewritten by resolution. Parent has no P7 visibility; school/admin projection is deferred.

---

## 2. IMPLEMENTATION LINEAGE (P7.0 → P7.3.3)

| Phase | Migration / SHA | What |
|---|---|---|
| P7.0 | — | Capability discovery selected POST-SESSION CHILD FOLLOW-UP. |
| P7.1 | — | Semantic contract frozen. |
| P7.2 | — | Physical contract frozen. |
| P7.3 M1 | `20260831014856 v128_p7_3_child_follow_up_substrate` | Substrate. First M1 attempt **rolled back atomically** because default privileges left `authenticated` direct mutation access; corrected M1 then applied cleanly. |
| P7.3 M1.1 | `20260831021632 v128_p7_3_1_follow_up_authority_fail_closed` | Security rehearsal found a SQL three-valued-logic bypass on NULL `lead_teacher_id`. Fix: **COALESCE authority → false**; resolve guard uses **IS NOT TRUE**. Behavioral rehearsal passed after fix. |
| P7.3 M2 | `20260831023113 v128_p7_3_2_teacher_todo_follow_up_count` | Added canonical `counts.open_follow_up_count`, derived from **RESOLVE authority**, not READ visibility. |
| P7.3 FE | `cfac171cdd1023bbf780688cab50ab3544f0fcce` | `followUpModel.ts` · `TeacherFollowUpSection.tsx` · `followUpModel.test.ts` · `teacher.index.tsx` wiring. |
| **P7.3.3** | `20260831055744 v128_p7_3_3_follow_up_rpc_anon_revoke` | **Release-rehearsal ACL correction** (see §4). ACL-only; no body/signature/RLS/trigger/data/frontend change. |

Backend lineage verified live (this closeout), all four P7 migrations present and ordered; no migration 190+.

---

## 3. FROZEN SEMANTIC TRUTHS (P7)

1. **Observation Truth ≠ Action State.** Historical `child_observations` remain pedagogical observation records.
2. P7 action is created only from an **authoritative closeout observation signal**. Creation predicate: `attendance IN ('present','late')` AND (`needs_support = true` OR `follow_up_needed = true`).
3. **Absent child does NOT create** a P7 pedagogical follow-up action.
4. Lifecycle is intentionally narrow: **open → resolved**. No reopen, escalation, comments, assignment queue, or case-management states in P7.
5. `source_signal` snapshot ∈ { needs_support, follow_up_needed, both }.
6. Historical observation truth is **not mutated** when an action resolves.
7. **READ authority:** source observer OR current P7 distribution authority.
8. **RESOLVE authority:** current P7 distribution authority **only**. A historical source teacher does not retain resolve merely for having created the observation.
9. **Distribution authority:** lead teacher, OR temporal responsible-teacher precedence — in_progress first, else nearest upcoming session, else most-recent past/overdue — excluding cancelled / rescheduled.
10. Authority helper is **fail-closed**: `COALESCE(…, false)`.
11. Resolve boundary is **fail-closed**: `authority IS NOT TRUE ⇒ forbidden`.
12. Teacher TODO count = OPEN actions the caller can RESOLVE. **Not** derived from readable-item count.
13. Source-observer read-only items do **not** inflate the actionable TODO badge.
14. Parent has **no** P7 follow-up visibility.
15. School/admin follow-up projection is **deferred**.
16. **No notification** requirement in P7 core.

---

## 4. P7.3.3 — ACL LEAST-PRIVILEGE CORRECTION (recorded in full)

**Discovery:** during release rehearsal, three P7 RPC/helper functions were found to carry unintended `anon` (and defensively `PUBLIC`) EXECUTE. The fail-closed function bodies would have rejected an anon call (NULL `auth.uid()` → authority false), so no data-integrity invariant was broken; the exposure was a least-privilege / defense-in-depth gap on the outer ACL layer.

**Correction (migration `20260831055744`, D92 3-block, ACL-only):**
- `REVOKE EXECUTE … FROM PUBLIC, anon` on the three functions.
- `GRANT EXECUTE … TO authenticated, service_role, postgres`.
- VERIFY block (rollback guard) asserted: anon∅, PUBLIC∅, authenticated/service_role/postgres present, **body md5 unchanged** (hard-coded baselines), CFA row count = 2.
- `NOTIFY pgrst, 'reload schema'` (D289).

**Proven end-state (independent read-only re-verify at closeout):**

| Function | authenticated | service_role | postgres | anon | PUBLIC | body md5 |
|---|---|---|---|---|---|---|
| `follow_up_distribution_authority(uuid)` | ✓ | ✓ | ✓ | ✗ | ✗ | `b96ba8742b469129e3e9e07e86a06fc4` (unchanged) |
| `resolve_child_follow_up(uuid)` | ✓ | ✓ | ✓ | ✗ | ✗ | `50a202a256243b20077c46ff5155a8a1` (unchanged) |
| `get_teacher_open_follow_ups()` | ✓ | ✓ | ✓ | ✗ | ✗ | `abf65603abea9aecaeb3cfefd0961cd6` (unchanged) |
| `get_teacher_todo_counts()` *(guard, untouched)* | ✓ | ✓ | ✓ | ✗ | ✗ | `015279e217f4de96d958a3d1904b350b` (unchanged) |

No signature change. No RLS change. `session_reports` trigger remained exactly one (`create_follow_up_actions`). No data mutation. No frontend change → accepted FE SHA `cfac171…` remains valid (RPC names/signatures unchanged).

---

## 5. OWNER / PRE-RELEASE FULL-LOOP QA (accepted preview evidence)

Initial 2 open actionable follow-ups → resolve #1 (2→1) → resolve #2 (1→0). Observed: item disappears after successful resolve, canonical badge decrements once per resolve, quiet empty state appears, labels render. DB cross-check: both QA actions `state=resolved`; correct `resolved_by`; `resolved_at` matched QA timing; **exactly 2 `child_follow_up_resolved` audit events** (one per resolve, no duplicate); no observation-truth rewrite; open=0.

---

## 6. PRODUCTION RELEASE VALIDATION

Production URL: `https://demenart.com`. Deploy confirmed by Owner (via `main`→Cloudflare auto-deploy, D105/D309.1).

**[Owner-attested — PASS]** Teacher Home loads · "Bé cần theo dõi tiếp" section renders · empty state "Hiện không có bé nào cần theo dõi tiếp." · zero-actionable UI agrees with backend open=0 · Teacher Schedule / Classes / Media load · Appreciation visible · no obvious route/layout regression.

**[NOT EXERCISABLE]** Production cases requiring an OPEN follow-up fixture — backend was already total=2 / open=0 / resolved=2, so no safe open item existed. The destructive resolve smoke was intentionally not recreated on production. **No fabricated PASS.**

Accepted evidence chain: preview full-loop behavioral proof + DB/audit cross-check + production deployment + production zero-state/runtime consistency + regression smoke.

---

## 7. FINAL BACKEND PIN (verified live at closeout)

- migration count **189**; tail `20260831055744 v128_p7_3_3_follow_up_rpc_anon_revoke`; prev `20260831023113 v128_p7_3_2_teacher_todo_follow_up_count`; **no migration 190+**.
- CFA fixture: total=2 · open=0 · resolved=2.
- RLS on `child_follow_up_actions` and `session_reports`: enabled. `session_reports` follow-up trigger: exactly 1.

---

## 8. DEFERRED HARDENING DEBT

`get_teacher_todo_counts()` is SECURITY DEFINER and currently preserves `SET search_path TO 'public'` (vs the `''` convention). Deliberately left unchanged in P7. **NON-BLOCKING** — no exploit or P7 semantic contradiction proven; object references qualified in accepted implementation. **Do NOT create migration 190 to change this in the P7 closeout.**

Also deferred (per truths 14/15/16): parent P7 visibility (none), school/admin follow-up projection (fast-follow), notifications (out of P7 core).

---

## 9. HARD STOP

P7 closed. Do NOT start P8. Do NOT start school follow-up fast-follow. Do NOT mutate product or DB.
