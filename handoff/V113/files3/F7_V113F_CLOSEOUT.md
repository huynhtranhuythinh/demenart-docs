# F7 — V113F CLOSEOUT
**V113F · Design Consistency Freeze & Final UI Specification** · Planning/handoff only.
**Date:** 2026-07-16 (GMT+7) · ZERO code / route / schema / RPC / RLS / Edge / consent-path / governance / deploy / RULES append / SYSTEM_MAP bump / new HANDOFF.

---

> **PATCHED BY V113F-C (2026-07-16, GMT+7).** Art director resolved the open decisions: core color tokens + fonts CONFIRMED, tablet = top bar + drawer, labels/VN-roles/metric-hierarchy locked, gold-contrast rule set. **No corrected mockup packs were attached in V113F-C** → the four L4 screens remain coverage-only and the status does **not** advance to PASS.

## 1. Final design-system verdict
**`V113F CONDITIONAL PASS — REMAINING MOCKUP CORRECTIONS`.**

The source-of-truth hierarchy is fixed, rejected inputs are excluded, and all surfaces map into one token/component system with desktop + mobile compositions and governance-preserving controls. Core **color tokens and both fonts are now confirmed and frozen (V113F-C)**; tablet strategy, nav labels, VN role grammar, metric hierarchy, and the gold-text contrast rule are locked. The **sole remaining blocker to full PASS** is that four surface groups (Family Members, Privacy, Settings/Account, Create Flows + System/Media/Consent states) still exist only at **L4 coverage fidelity** — their corrected standalone mockup packs were not attached in V113F-C. No HOLD-level conflict exists: no two L1–L3 sources materially disagree, and no correction changes audience or authorization.

## 2. Consistency issues found (classified)

| # | Issue | Class |
|---|---|---|
| 1 | **Two Home mockups.** Image 2 (canonical, emerald/green-CTA/official logo) vs Image 6 (orange-heavy, yellow CTA, "Gia đình Hùng" botanical wordmark, heart doodle). | **REJECT Image 6** — resolved by precedence |
| 2 | **Stale nav in L4 poster.** Image 1 rail shows "Trang chủ" + 7 rail items + 5-item bottom nav incl. "Cài đặt". | **CORRECT BEFORE BUILD** — use 4-primary "Hôm nay" model |
| 3 | **Mobile 4th label drift.** Image 5 mobile shows long label; canonical mobile = "Của con". | ✅ **RESOLVED (V113F-C)** — locked "Của con" |
| 4 | **English role words** ("Guardian") in L4 members poster. | ✅ **RESOLVED (V113F-C)** — VN role grammar locked |
| 5 | **Metric-before-memory risk** ("{n} ký ức" / "286 ký ức") in Family index. | ✅ **RESOLVED (V113F-C)** — counts = quiet metadata after labels only |
| 6 | **Core token hexes + font families** not pixel-confirmable. | ✅ **RESOLVED (V113F-C)** — confirmed & frozen (F2) |
| 7 | **Gold-on-ivory text contrast** risk. | ✅ **RESOLVED (V113F-C)** — gold text = `--color-ink-gold` `#806A35`; champagne decorative-only |
| 8 | **Tablet rail-collapse** strategy unspecified. | ✅ **RESOLVED (V113F-C)** — top bar + navigation drawer, no icon rail |
| 9 | Discovery route-local child selector diverges from persisted context. | **CARRY TO V113G** (client-only refactor, per B4) |
| 10 | **Nav model** — L4 poster still shows "Trang chủ" + 7 rail items + 5-item bar. | ✅ **RESOLVED (V113F-C)** — 4-primary "Hôm nay" model locked |

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
- **System/structure:** ✅ complete and one-world.
- **Values:** ✅ **CONFIRMED & FROZEN (V113F-C)** — core brand/surface/ink hexes and both fonts (Playfair Display + Be Vietnam Pro) are locked in F2. Champagne `#C8AA6A` decorative-only; gold text `#806A35`. Only non-blocking micro-tuning (some border/shadow opacities, exact 16/20 radii) remains. Vietnamese diacritic rendering is a build QA gate, not a token uncertainty.

## 6. Component readiness
- **Ready (L2/L3-anchored):** Rail, BottomNav, ChildSwitcher, PageTitle, MemoryHero, MemoryCard, JourneyChapter/Rail, FamilyIdentityHeader, ArchivePeriodIndex, all Memory Room components, KidGatewayHero, KidSafetyStatus, TruthStateBlock grammar.
- **Needs baseline restyle (L4 coverage):** FamilyMembers/MemberRow/InviteRow, PrivacyGroup, SettingsGroup, Composer, VoiceRecorder, MediaPicker, TruthState *visuals*.
- **Evidence debt:** Notifications/Support list, invitation expired/revoked, audio-only/text-only Room compositions.
- **Governance:** ✅ predicates kept separate; no `canManage`; D284/D293/D298/D305 preserved.

## 7. Responsive readiness
Desktop 1440 + mobile 390 compositions specified for all primaries and Memory Room; safe-area/bottom-nav reservation, content-order remaps, media aspect reservation, layout-shift prevention all specified. **Tablet = top bar + navigation drawer, no icon rail, sidebars below content, no dense mode — ✅ LOCKED (V113F-C).** Responsive readiness now complete.

## 8. Accessibility readiness
Focus-visible, ≥44px targets, contrast targets, SR labels, `aria-current`, reduced-motion, signed-media placeholders specified. **Gold-text contrast resolved (V113F-C):** all gold text uses `--color-ink-gold` `#806A35`; decorative champagne never used as text. Remaining a11y work is verification-in-build (contrast + diacritic QA), not open design questions.

## 9. Unresolved visual-evidence debt
1. **Production visual baseline** — no live-UI capture (browser MCP unavailable in V113A). Close before implementation, not before this freeze.
2. **Member (non-guardian) live session** — NOT TESTABLE (no safe member session).
3. **0 audio-only / 0 text-only family cards in prod** — hand-create to capture those Room states; do not synthesize.
4. **Invitation expired/revoked** treatments — no source at any level.
5. **Discovery capsule composition** (deterministic vs generative) — confirm before "reflection" copy implies analysis (no backend change regardless).
6. **`JourneyDetail` internal Share** — unread; Share re-homing remains a product decision, out of scope.

## 10. Exact inputs for V113G (implementation planning)
1. This **F1–F7** pack (source-of-truth, tokens, screen matrix, component spec, responsive/a11y/motion, QA gates).
2. **Blocking pre-build confirmations — ✅ NOW RESOLVED (V113F-C):** core hexes + fonts frozen; gold contrast rule set; "Của con"/"Thế giới của con"/"Hôm nay" labels locked; VN role grammar locked; tablet = top bar + drawer. Nothing in this line still blocks.
3. **Sole remaining blocker to PASS — four corrected mockup packs** (not yet attached): (1) Family Members desktop+mobile, (2) Privacy desktop+mobile, (3) Settings/Account Utility desktop+mobile, (4) Create Flows + System/Media/Consent states. On attach: promote L4→L3, update F1 source table, clear "L4 restyle required" for those screens, update F3/F4/F6/F7, keep the combined poster as coverage-history only.
4. **Frozen invariants for planners:** 4-primary IA + labels; `Ký ức | Thành viên` via `?section=`; Home = identity + one memory + one action; Memory Room content-first order; Kid gateway hierarchy; one primary action per surface; separate governance predicates.
5. **Reuse map (F4 §9)** and **QA gates + screenshot set (F6)** as the acceptance harness for V113G build increments.
6. **Carried confirmations:** Discovery capsule no-AI; Share re-homing; production visual baseline capture.

## 11. Explicit non-actions (this pass)
No code · no source edit · no route/redirect/dead-code change · no migration/schema/RPC/RLS/Edge · no consent-semantics or governance change · no deploy · no production data mutation · no RULES append · no SYSTEM_MAP bump · no new canonical HANDOFF · no new visual direction invented · no new product features · no AI/Search/Notification-functionality/Circle/ranking · no social sharing · no Share re-home · official logo not replaced · rejected mockups not treated as sources. Fixed product decisions treated as fixed, not re-opened.

---
**Final status: `V113F CONDITIONAL PASS — REMAINING MOCKUP CORRECTIONS`.**
Advances to `V113F PASS — DESIGN SYSTEM FROZEN` once the four corrected mockup packs are attached, reviewed, and promoted L4→L3 (all other V113F-C conditions — tokens, fonts, tablet, labels, VN roles, gold contrast — are now met).
