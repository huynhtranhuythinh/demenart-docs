# F7 — V113F CLOSEOUT
**V113F · Design Consistency Freeze & Final UI Specification** · Planning/handoff only.
**Date:** 2026-07-16 (GMT+7) · ZERO code / route / schema / RPC / RLS / Edge / consent-path / governance / deploy / RULES append / SYSTEM_MAP bump / new HANDOFF.

---

## 1. Final design-system verdict
**`V113F CONDITIONAL PASS — CORRECTIONS REQUIRED`.**

The source-of-truth hierarchy is fixed, rejected inputs are excluded, and all surfaces map into one token/component system with desktop + mobile compositions and governance-preserving controls. It is **not** a full freeze because (a) exact core color hexes and the two font families require art-director confirmation, and (b) seven surface groups (Thành viên, Quyền riêng tư, Cài đặt, create flows, system/media states — plus notifications/support) exist only at **L4 coverage fidelity** and must be restyled to the baseline before build. None of these is a HOLD-level conflict: no two L1–L3 sources materially disagree, and no correction changes audience or authorization.

## 2. Consistency issues found (classified)

| # | Issue | Class |
|---|---|---|
| 1 | **Two Home mockups.** Image 2 (canonical, emerald/green-CTA/official logo) vs Image 6 (orange-heavy, yellow CTA, "Gia đình Hùng" botanical wordmark, heart doodle). | **REJECT Image 6** — resolved by precedence |
| 2 | **Stale nav in L4 poster.** Image 1 rail shows "Trang chủ" + 7 rail items + 5-item bottom nav incl. "Cài đặt". | **CORRECT BEFORE BUILD** — use 4-primary "Hôm nay" model |
| 3 | **Mobile 4th label drift.** Image 5 mobile shows long "Thế giới của con"; canonical mobile = "Của con". | **CORRECT BEFORE BUILD** |
| 4 | **English role words** ("Guardian") in L4 members poster. | **CORRECT BEFORE BUILD** — VN grammar |
| 5 | **Metric-before-memory risk** ("{n} ký ức" / "286 ký ức") in Family index. | **CORRECT BEFORE BUILD** — memory-first |
| 6 | **Core token hexes + font families** not pixel-confirmable from compressed mockups. | **CORRECT BEFORE BUILD** — art-director confirm (F2 §17) |
| 7 | **Gold-on-ivory text contrast** risk. | **CORRECT BEFORE BUILD** — verify ≥4.5:1 or use `--color-ink-gold` |
| 8 | **Tablet rail-collapse** strategy unspecified. | **DEFER** — art-director pick, non-blocking for phone/desktop |
| 9 | Discovery route-local child selector diverges from persisted context. | **CORRECT BEFORE BUILD** (client-only, per B4) |

No contradiction was silently normalized.

## 3. Mockups accepted unchanged
- **Image 4 — Journey "Hành trình của An"** (L2 master). ✅
- **Image 2 — Home "Hôm nay của An"** (L3). ✅
- **Image 3 — Family Archive "Gia đình Hùng"** (L3, Ký ức tab). ✅
- **Image 7 — Memory Room** (L3). ✅
- **Image 5 — Kid gateway "Thế giới của An"** (L3) — accepted **except** mobile 4th-label fix (§2.3).

## 4. Mockups requiring correction before build
- **Image 5** — mobile bottom-nav label → "Của con".
- **Image 1 (all seven poster sections)** — restyle to baseline tokens; adopt 4-primary nav; VN role grammar; memory-first; treat as **coverage/composition only**, not visual source.
- **Image 6** — **not a correction target; rejected outright.** Recorded so it cannot seed any Home token, CTA color, or logo.

## 5. Token confidence
- **System/structure:** ✅ complete and one-world (semantic names, type scale, spacing, radii, z-index, motion, states).
- **Values:** ⚠ core brand/surface/ink **hex** values and the two **font families** = `REQUIRES ART-DIRECTOR CONFIRMATION`. All estimates trace to L1–L3; rejected orange/yellow contributed nothing.

## 6. Component readiness
- **Ready (L2/L3-anchored):** Rail, BottomNav, ChildSwitcher, PageTitle, MemoryHero, MemoryCard, JourneyChapter/Rail, FamilyIdentityHeader, ArchivePeriodIndex, all Memory Room components, KidGatewayHero, KidSafetyStatus, TruthStateBlock grammar.
- **Needs baseline restyle (L4 coverage):** FamilyMembers/MemberRow/InviteRow, PrivacyGroup, SettingsGroup, Composer, VoiceRecorder, MediaPicker, TruthState *visuals*.
- **Evidence debt:** Notifications/Support list, invitation expired/revoked, audio-only/text-only Room compositions.
- **Governance:** ✅ predicates kept separate; no `canManage`; D284/D293/D298/D305 preserved.

## 7. Responsive readiness
Desktop 1440 + mobile 390 compositions specified for all primaries and Memory Room; safe-area/bottom-nav reservation, content-order remaps, media aspect reservation, layout-shift prevention all specified. **Tablet rail-collapse = one deferred art-director decision.**

## 8. Accessibility readiness
Focus-visible, ≥44px targets, contrast targets, SR labels, `aria-current`, reduced-motion, signed-media placeholders specified. **One confirm item:** gold-text-on-ivory contrast.

## 9. Unresolved visual-evidence debt
1. **Production visual baseline** — no live-UI capture (browser MCP unavailable in V113A). Close before implementation, not before this freeze.
2. **Member (non-guardian) live session** — NOT TESTABLE (no safe member session).
3. **0 audio-only / 0 text-only family cards in prod** — hand-create to capture those Room states; do not synthesize.
4. **Invitation expired/revoked** treatments — no source at any level.
5. **Discovery capsule composition** (deterministic vs generative) — confirm before "reflection" copy implies analysis (no backend change regardless).
6. **`JourneyDetail` internal Share** — unread; Share re-homing remains a product decision, out of scope.

## 10. Exact inputs for V113G (implementation planning)
1. This **F1–F7** pack (source-of-truth, tokens, screen matrix, component spec, responsive/a11y/motion, QA gates).
2. **Blocking pre-build confirmations** (feed to art director first): core hex values + two font families (F2 §17); gold-on-ivory contrast; mobile "Của con" label; VN role grammar; tablet rail-collapse pick.
3. **Restyle-to-baseline list** (L4→baseline): Thành viên, Quyền riêng tư, Cài đặt, create flows, all system/media states.
4. **Frozen invariants for planners:** 4-primary IA + labels; `Ký ức | Thành viên` via `?section=`; Home = identity + one memory + one action; Memory Room content-first order; Kid gateway hierarchy; one primary action per surface; separate governance predicates.
5. **Reuse map (F4 §9)** and **QA gates + screenshot set (F6)** as the acceptance harness for V113G build increments.
6. **Carried confirmations:** Discovery capsule no-AI; Share re-homing; production visual baseline capture.

## 11. Explicit non-actions (this pass)
No code · no source edit · no route/redirect/dead-code change · no migration/schema/RPC/RLS/Edge · no consent-semantics or governance change · no deploy · no production data mutation · no RULES append · no SYSTEM_MAP bump · no new canonical HANDOFF · no new visual direction invented · no new product features · no AI/Search/Notification-functionality/Circle/ranking · no social sharing · no Share re-home · official logo not replaced · rejected mockups not treated as sources. Fixed product decisions treated as fixed, not re-opened.

---
**Final status: `V113F CONDITIONAL PASS — CORRECTIONS REQUIRED`.**
