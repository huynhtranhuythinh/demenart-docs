# DMA_HANDOFF — V114B-E3 · WP4-S4 · FRONTEND SESSION-CAPABILITY AUTHORITY ALIGNMENT
**Milestone closeout · 2026-07-24 · WP4-S4 FINAL PASS**

Canonical endpoint after this milestone: **D325 · SYSTEM_MAP v1.17 · HANDOFF V114B-E3-WP4-S4**
Accepted implementation tip (production `main`): **`5d28ee67386dcaa3b5f627c6939fda4be23cb470`**

---

## 1. OBJECTIVE & SCOPE
Align the frontend teacher-session surface with the D324 backend authority cutover: the UI must derive journal-submit authority **only** from server capability (`get_session_detail.can_submit_journal`), never from class-lead / role / identity / local state. Single authored file:
`src/routes/_authenticated/teacher.session.$id.tsx`. No backend, schema, RPC, RLS, data, migration, or dependency change.

## 2. FINAL IMPLEMENTATION TIP & LINEAGE
- `645fad7d` — S4-1/2 (initial capability wiring; type + props + CTA from `can_submit_journal`).
- `7df9621c` — **Owner manual edit** (Lovable Code Editor): landing Parent card "Sắp ra mắt"→"Đang hoạt động" (`src/routes/index.tsx`) + re-add of `routeTree.gen.ts` `@tanstack/react-start` Register block. Unrelated to teacher-session; **not rolled back**.
- **`5d28ee67`** — **S4-3D controlled apply (accepted tip)**: the mechanically-validated stale-capability-recovery patch. Committed via Lovable agent (`send_message`, 10 verbatim find/replace) → auto-deploy Cloudflare `main`.
- No commit after `5d28ee67`. Backend migration registry **114** (`latest 20260724092921` = S3 authority cutover) — unchanged during S4.

## 3. AUTHORITY PRESENTATION CONTRACT (D325)
- CTA "gửi nhật ký" opens **iff** `detail.can_submit_journal === true`; otherwise blocked span with `blockReasonCopy(submit_block_reason)`.
- "Giáo viên phụ trách buổi" renders `responsible_teacher.display_name` only (never `assignment_source`/`evidence_grade`/`valid_from`).
- No frontend derivation from class-lead, planned teacher, `taught_by`, actor identity, teacher/admin role, local session state, or the `start_session` response. `is_lead` / `get_teacher_classes` derivation removed.
- Backend authority unchanged (D324): session-responsibility is sole authority; responsible assignment born at first `start_session`; `submit_session_journal` uses it; admin/Master do not bypass.

## 4. START / SUBMIT PENDING-GUARDS & REFRESH CONTRACT
- **Shared refresh coordination (parent-owned):** monotonic `detailSeqRef` + latest-in-flight `detailInflightRef`. A superseded caller `await`s the newest authoritative promise and inherits its outcome; only the latest seq calls `setDetail`. Result contract: **`applied` / `failed` / `cancelled`**.
- **Start:** synchronous `startLockRef` (not React state) → one `start_session`; advance **only** on `applied`; never re-start after success; refresh failure → route error (fail-closed); no endless spinner.
- **Submit rejection:** `setRecovering(true)` **before** releasing `submitting` (no enabled-CTA window); synchronous `submitLockRef` held until `applied`; `failed`/`cancelled` stay fail-closed; **no auto-retry**.
- **Refresh-before-success / capability:** `loadDetail` calls `setErr(null)` on success (clears recoverable route error). CTA only re-enables on refreshed `can_submit_journal === true`.
- **Strict-Mode-safe lifetime guards:** `detailAliveRef` / `spAliveRef` / `aliveRef` use `useEffect(() => { ref.current = true; return () => { ref.current = false; }; }, [])` — safe under setup→cleanup→setup.

## 5. PRODUCTION BROWSER QA EVIDENCE (S4-4 — PASS WITH P2; Owner Cloud Browser, 24/07)
- **Responsible teacher (Đặng Mỹ Linh):** portal + session route `aaaa0000-…-0a0003` load clean (no blank/404/error-boundary); "Giáo viên phụ trách buổi: Đặng Mỹ Linh"; CTA available; canonical refresh completes before CTA opens; rapid double-tap Start & Submit → locks immediately, one transition, reload keeps canonical (`in_progress` / submitted).
- **Master/admin (Huỳnh Trần Nguyệt Thi):** opens route; responsible still shows Đặng Mỹ Linh; **no** submit CTA; shows "Bạn không phải giáo viên phụ trách buổi học này nên không thể gửi nhật ký."; `3bfb9730…` `in_progress` still blocks journal step. Role does not confer authority.
- **Console/keyboard:** 0 application errors (only Cloud Browser extension metadata error); Tab traversal works.
- **Two valid demo mutations (do not repeat):** Start `3bfb9730-193f-40c1-a285-d515bca01404`; Submit `aaaa0000-0000-4000-8000-0000000a0003`.
- **Safe rejection/failure injection: NOT EXECUTED** — not forced on production; non-blocking because success, authority-denial, canonical-reload, and idempotent-interaction paths passed directly.

## 6. RESPONSIVE MATRIX
| Viewport | Result | Notes |
|---|---|---|
| 375 × 812 | PASS | no horizontal overflow; CTA/blocked/responsible legible |
| 430 × 932 | PASS | Owner-relevant mobile |
| 768 × 1024 | PASS (P2) | core workflow intact; right-edge nav partly clipped (discoverability P2) |
| 1440 × 900 | PASS | desktop sidebar correct |

## 7. ROUTETREE RUNTIME DISPOSITION — CLOSED
`routeTree.gen.ts` removal of the type-only `@tanstack/react-start` Register block (build-regenerated in `5d28ee67`) caused **no observable runtime routing/navigation regression**: authenticated Teacher Portal + direct session route + hard reload all loaded in production browser QA; `routeTree` object and `react-router` `FileRoutesByPath` augmentation intact. Retained as **accepted P2 generated-file deviation**; no separate correction required.

## 8. SKEW-WINDOW DISPOSITION — CLOSED
Opened 2026-07-24 16:29:21 ICT (D324 cutover). **CLOSED at WP4-S4 (S4-5 governance disposition).** All closing conditions met: backend cutover live; frontend consumes capability live; responsible-teacher presentation live; admin counterfactual blocked (browser); Start/Submit canonical behavior verified; responsive 4/4; zero application runtime error. Production was **not** modified merely to close the window (governance-only). No blocker justified keeping it OPEN (safe-failure-injection being unexecuted is explicitly non-blocking).

## 9. P2 DEBT REGISTER
1. Recovery-error presentation: definitive recovery-refresh failure may replace friendly submit-error copy with route-level error.
2. 768px shell-navigation discoverability (right-edge clip).
3. `routeTree.gen.ts` generated-file deviation — runtime PASS, retained as P2.

## 10. RESIDUAL GATES / DEBT (unchanged, not closed here)
E3-SG-01 **OPEN** · E3-SG-02 **CONTAINED** · R21 **ACTIVE** · `session_reports` containment **unresolved** · responsibility-transfer RPC absent · `pg_default_acl` debt · sub_admin QA debt · Vũ Hoàng Nam + Trần Khánh Vy auth-persona debt. **E3 candidate rules D310–D323-cand + D-A2-1 remain held** for the separate E3 milestone closeout (after WP4-S4).

## 11. CHANGE / ACTION ACCOUNTING (WP4-S4 total)
- Authored frontend files: **1** (`teacher.session.$id.tsx`).
- Generated files: **1** (`routeTree.gen.ts`, build-regenerated).
- Documentation files canonicalized (S4-5): DMA_RULES.md (append D325), DMA_SYSTEM_MAP.md (v1.17 + section), this HANDOFF.
- Backend / schema / RPC / RLS / data / migration / dependency changes: **0**.
- Production code commits (S4): `645fad7d`, `5d28ee67` (+ Owner `7df9621c`). Deployments: Cloudflare auto on `main`.
- S4-5 production code/backend mutations: **0**.

## 12. WP4-S4 FINAL VERDICT
**WP4-S4 FINAL PASS.** Frontend session-capability authority alignment is live, production-verified, canonicalized (D325 / v1.17), skew window closed, residual debts documented.

## 13. NEXT
Recommended next workstream: **E3 milestone closeout** — canonicalize D310–D323-cand + D-A2-1 and dispose remaining E3 residuals (`session_reports` containment, responsibility-transfer RPC, E3-SG-01). Do not open new build scope from this closeout.
