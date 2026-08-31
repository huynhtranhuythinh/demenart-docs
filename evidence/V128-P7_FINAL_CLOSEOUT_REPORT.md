# V128-P7 — FINAL CLOSEOUT EVIDENCE REPORT

Capability: **POST-SESSION CHILD FOLLOW-UP**
Date: 2026-08-31
Gate outcome (Owner authority): **V128-P7 — CLOSED — RELEASED — PRODUCTION VALIDATED**

Provenance legend: **[CV]** = independently verified by Claude on live production Supabase (`xcvhacymrbhdhohyylyq`); **[OA]** = Owner-attested; **[NE]** = not exercisable (no fabricated PASS); **[LIM]** = evidence limitation.

---

## 1. IMPLEMENTATION HISTORY

- **P7.0** capability discovery → POST-SESSION CHILD FOLLOW-UP.
- **P7.1** semantic contract frozen · **P7.2** physical contract frozen.
- **P7.3 M1** `20260831014856 v128_p7_3_child_follow_up_substrate` — first attempt **rolled back atomically** (default privileges left `authenticated` direct mutation); corrected M1 applied.
- **P7.3 M1.1** `20260831021632 v128_p7_3_1_follow_up_authority_fail_closed` — SQL 3-valued-logic bypass on NULL `lead_teacher_id` found in rehearsal; fixed via COALESCE→false + resolve guard IS NOT TRUE; behavioral rehearsal passed.
- **P7.3 M2** `20260831023113 v128_p7_3_2_teacher_todo_follow_up_count` — `counts.open_follow_up_count` from RESOLVE authority.
- **P7.3 FE** `cfac171cdd1023bbf780688cab50ab3544f0fcce` — followUpModel/TeacherFollowUpSection/test/teacher.index.
- **P7.3.3** `20260831055744 v128_p7_3_3_follow_up_rpc_anon_revoke` — release-rehearsal ACL correction (below).

**[CV]** P7 lineage present & ordered on live DB: the four migrations above, `migrations_after_M3 = 0`.

---

## 2. P7.3.3 ACL CORRECTION — FULL EVIDENCE

**Pre-pin [CV]:** count 188 / tail M2; three functions single-overload, SECDEF, ACL `anon; authenticated; postgres; service_role`; bodies `b96ba874…` / `50a202a2…` / `abf65603…`; CFA 2·0·2.

**Migration [CV]:** applied via `apply_migration` as `v128_p7_3_3_follow_up_rpc_anon_revoke` (recorded in `schema_migrations`). D92 3-block: (1) `REVOKE EXECUTE … FROM PUBLIC, anon`; (2) `GRANT EXECUTE … TO authenticated, service_role, postgres`; (3) VERIFY DO-block rollback guard asserting anon∅ / PUBLIC∅ / three roles present / **hard-coded body-md5 unchanged** / CFA=2; then `NOTIFY pgrst, 'reload schema'`. No CREATE OR REPLACE (bodies untouched by construction).

**Post-verify [CV] (independent re-read):**

| Function | authenticated | service_role | postgres | anon | PUBLIC | body md5 unchanged |
|---|---|---|---|---|---|---|
| `follow_up_distribution_authority(uuid)` | ✓ | ✓ | ✓ | ✗ | ✗ | ✓ `b96ba874…` |
| `resolve_child_follow_up(uuid)` | ✓ | ✓ | ✓ | ✗ | ✗ | ✓ `50a202a2…` |
| `get_teacher_open_follow_ups()` | ✓ | ✓ | ✓ | ✗ | ✗ | ✓ `abf65603…` |
| `get_teacher_todo_counts()` (untouched) | ✓ | ✓ | ✓ | ✗ | ✗ | ✓ `015279e2…` |

Signatures unchanged · RLS unchanged (`child_follow_up_actions`, `session_reports` both on) · `session_reports` trigger unchanged (1× `create_follow_up_actions`) · **0 data mutation** (CFA 2·0·2) · **0 frontend change** (RPC names/signatures identical → FE `cfac171` valid).

---

## 3. OWNER / PRE-RELEASE FULL-LOOP QA (preview)

**[OA]** 2 open → resolve#1 (2→1) → resolve#2 (1→0); item disappears on resolve; badge decrements once per resolve; quiet empty state; labels correct.
**[OA/DB]** both QA actions `state=resolved`; correct `resolved_by`; `resolved_at` matched QA timing; **exactly 2 `child_follow_up_resolved` audit events** (one per resolve, no duplicate); no observation-truth rewrite; open=0.

---

## 4. PRODUCTION RELEASE VALIDATION

Production: `https://demenart.com`. Deploy mechanism: `main`→Cloudflare auto-deploy (D105/D309.1). **[OA]** Owner confirmed deployment.

**[OA] PASS:** Teacher Home loads · "Bé cần theo dõi tiếp" renders · empty state "Hiện không có bé nào cần theo dõi tiếp." · zero-actionable UI agrees with backend open=0 · Teacher Schedule / Classes / Media load · Appreciation visible · no obvious route/layout regression.

**[NE]** Production behavioral cases requiring an OPEN fixture: backend was total=2 / open=0 / resolved=2 → no safe open item. Destructive resolve smoke intentionally not recreated on production. **No fabricated PASS.**

**[LIM]** No independent production asset-SHA fingerprint captured from the release-orchestration runtime; production identity rests on **[OA]** + auto-deploy convention.

Accepted evidence chain: preview full-loop behavioral proof **[OA/DB]** + DB/audit cross-check **[OA/DB]** + production deployment **[OA]** + production zero-state/runtime consistency **[OA]** + regression smoke **[OA]**.

---

## 5. FINAL PINS

- **[CV]** Backend: count **189** · tail `20260831055744 v128_p7_3_3_follow_up_rpc_anon_revoke` · prev `20260831023113 v128_p7_3_2_teacher_todo_follow_up_count` · no 190+.
- Frontend (accepted): Product SHA `cfac171cdd1023bbf780688cab50ab3544f0fcce` · main pin `@lovable.dev/vite-tanstack-config = 2.8.5`. **[LIM]** product-repo HEAD/worktree/divergence + package.json/bun.lock pin were **not** re-pinned from this runtime (no repo access) — Owner-side verification.

---

## 6. DEFERRED

- `get_teacher_todo_counts` `search_path='public'` — non-blocking hardening debt; **no migration 190** in P7.
- Parent P7 visibility: none (by design). School/admin follow-up projection: fast-follow. Notifications: out of P7 core.

---

## 7. STATUS

**V128-P7 — CLOSED — RELEASED — PRODUCTION VALIDATED** (Owner authority; provenance as tagged above). Hard stop: no P8, no school fast-follow, no migration 190, no further product/DB mutation.
