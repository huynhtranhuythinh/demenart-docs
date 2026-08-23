# F7 — V113F CLOSEOUT
**V113F · Design Consistency Freeze & Final UI Specification** · Planning/handoff only.
**Date:** 2026-07-17 (GMT+7) · ZERO code / route / schema / RPC / RLS / Edge / consent-path / governance / deploy / RULES append / SYSTEM_MAP bump / new HANDOFF.

---

> **HISTORICAL — SUPERSEDED.** V113F-C (2026-07-16) had recorded: art director confirmed core tokens + fonts, tablet = top bar + drawer, labels/VN-roles/metric-hierarchy locked, gold-contrast rule set, but *no corrected mockup packs were attached*, so the status then was `V113F CONDITIONAL PASS — REMAINING MOCKUP CORRECTIONS`. **Resolution (V113F FINAL MERGE — 2026-07-17 GMT+7):** all four correction packs were subsequently produced, reviewed and **approved by the Product Owner**, promoted **L4 → L3**, and merged into F1/F3/F4/F6. That conditional status is no longer current — see §1.

## 1. Final design-system verdict
**`V113F PASS — DESIGN SYSTEM FROZEN`.**

- Correction packs approved: **4 / 4** (Pack 1 Thành viên gia đình · Pack 2 Quyền riêng tư · Pack 3 Cài đặt / Account Utility · Pack 4 Create Flows + System/Media/Consent states — each including its final QA patch; Pack 4 also passed its final accessibility patch: retry targets ≥44×44, `aria-pressed` on selectable media, non-selectable semantic unavailable tiles, labelled status/alert Truth-State semantics).
- Remaining mockup blockers: **0**.
- Core design decisions resolved: **100%** (tokens, fonts, tablet strategy, labels, VN role grammar, gold contrast, metric hierarchy — all V113F-C; surface coverage — final merge).
- **F1–F7 canonical merge complete** (F1/F3/F4/F6/F7 updated; F2/F5 byte-identical to V113F-C).
- **Implementation has not started.** F6 remains the open acceptance harness for V113G (design source ready ≠ implementation QA run).
- **No backend, route, schema, consent or governance changes occurred** at any point in V113F, the correction packs, or this merge.

Canonical L3 pack sources (clean filenames — browser suffixes are never canonical):
`DMA_Correction_Pack_1_Thanh_vien_gia_dinh.html` · `DMA_Correction_Pack_2_Quyen_rieng_tu.html` · `DMA_Correction_Pack_3_Cai_dat_Account_Utility.html` · `DMA_Correction_Pack_4_Create_Flows_States.html`.

## 2. Consistency issues found (classified — full history preserved)

| # | Issue | Class |
|---|---|---|
| 1 | **Two Home mockups.** Image 2 (canonical, emerald/green-CTA/official logo) vs Image 6 (orange-heavy, yellow CTA, "Gia đình Hùng" botanical wordmark, heart doodle). | **REJECT Image 6** — resolved by precedence; still rejected |
| 2 | **Stale nav in L4 poster.** Image 1 rail shows "Trang chủ" + 7 rail items + 5-item bottom nav incl. "Cài đặt". | ✅ RESOLVED — poster demoted to coverage-history; 4-primary "Hôm nay" model canonical everywhere |
| 3 | **Mobile 4th label drift.** Image 5 mobile shows long label; canonical mobile = "Của con". | ✅ RESOLVED (V113F-C) — locked "Của con" |
| 4 | **English role words** ("Guardian") in L4 members poster. | ✅ RESOLVED (V113F-C) — VN role grammar locked; Pack 1 conforms |
| 5 | **Metric-before-memory risk** ("{n} ký ức" / "286 ký ức") in Family index. | ✅ RESOLVED (V113F-C) — counts = quiet metadata after labels only |
| 6 | **Core token hexes + font families** not pixel-confirmable. | ✅ RESOLVED (V113F-C) — confirmed & frozen (F2) |
| 7 | **Gold-on-ivory text contrast** risk. | ✅ RESOLVED (V113F-C) — gold text = `--color-ink-gold` `#806A35`; champagne decorative-only |
| 8 | **Tablet rail-collapse** strategy unspecified. | ✅ RESOLVED (V113F-C) — top bar + navigation drawer, no icon rail |
| 9 | Discovery route-local child selector diverges from persisted context. | **CARRY TO V113G** (client-only refactor, per B4) |
| 10 | **Nav model** — L4 poster still shows "Trang chủ" + 7 rail items + 5-item bar. | ✅ RESOLVED (V113F-C) — 4-primary "Hôm nay" model locked |
| 11 | *(HISTORICAL)* Four surface groups existed only at L4 coverage fidelity with their packs not yet attached. | ✅ RESOLVED (FINAL MERGE 2026-07-17) — Packs 1–4 approved and promoted L4 → L3 |

No contradiction was silently normalized.

## 3. Mockups accepted (canonical set)
- **Image 4 — Journey "Hành trình của An"** (L2 master). ✅
- **Image 2 — Home "Hôm nay của An"** (L3). ✅
- **Image 3 — Family Archive "Gia đình Hùng"** (L3, Ký ức tab). ✅
- **Image 7 — Memory Room** (L3). ✅
- **Image 5 — Kid gateway "Thế giới của An"** (L3) — accepted with the mobile 4th-label fix locked (§2.3).
- **Correction Pack 1 — Thành viên gia đình** (L3, final merge). ✅
- **Correction Pack 2 — Quyền riêng tư** (L3, final merge). ✅
- **Correction Pack 3 — Cài đặt / Account Utility** (L3, final merge). ✅
- **Correction Pack 4 — Create Flows + System/Media/Consent states** (L3, final merge, incl. final accessibility patch). ✅

## 4. Superseded and rejected inputs
- **Image 1 (combined poster)** — **L4 COVERAGE-HISTORY ONLY.** Historical element inventory; no longer the canonical visual source for any surface now covered by Packs 1–4.
- **Image 6** — **rejected outright** (unchanged). Must not seed any Home token, CTA color, or logo.

## 5. Token confidence
- **System/structure:** ✅ complete and one-world.
- **Values:** ✅ CONFIRMED & FROZEN (V113F-C) — core brand/surface/ink hexes and both fonts (Playfair Display + Be Vietnam Pro) locked in F2 (byte-identical in this merge). Champagne `#C8AA6A` decorative-only; gold text `#806A35`. Only non-blocking micro-tuning remains. Packs 1–4 were verified to conform to F2 (no teal/mint/blue/orange drift; two fonts only).

## 6. Component readiness
- **Ready (L2/L3-anchored):** Rail, BottomNav, ChildSwitcher, PageTitle, MemoryHero, MemoryCard, JourneyChapter/Rail, FamilyIdentityHeader, ArchivePeriodIndex, all Memory Room components, KidGatewayHero, KidSafetyStatus, TruthStateBlock grammar — **plus (final merge):** FamilyMembers/MemberRow/InviteRow (Pack 1), PrivacyGroup + consent row/switch grammar (Pack 2), SettingsGroup + account identity summary + read-only child roster + PasswordCard (Pack 3), ParentMemoryComposer/FamilyCardComposer + family contribution entry, VoiceRecorder, MediaPicker, TruthState visuals (Pack 4).
- **Needs baseline restyle:** *(none — list emptied by the final merge; no independently documented blocker exists).*
- **Evidence debt (non-blocking, unchanged):** Notifications/Support list, invitation expired/revoked, audio-only/text-only Room compositions.
- **Governance:** ✅ predicates kept separate; no `canManage`; D284/D293/D298/D305 preserved throughout the packs and the merge.

## 7. Responsive readiness
Desktop 1440 + mobile 390 compositions specified for all primaries, Memory Room, and (final merge) Thành viên, Quyền riêng tư, Cài đặt, both composers, recorder and media picker; safe-area/bottom-nav reservation, content-order remaps, media aspect reservation, layout-shift prevention all specified. **Tablet = top bar + navigation drawer, no icon rail, sidebars below content, no dense mode — ✅ LOCKED (V113F-C).** Responsive readiness complete.

## 8. Accessibility readiness
Focus-visible, ≥44px targets, contrast targets, SR labels, `aria-current`, reduced-motion, signed-media placeholders specified. Gold-text contrast resolved (V113F-C). The final Pack 4 accessibility patch additionally locked: ≥44×44 retry targets in unavailable media, `aria-pressed` selection semantics in MediaPicker, semantic non-selectable unavailable tiles, and Truth-State `aria-labelledby`/`aria-describedby` + status/alert roles. Remaining a11y work is verification-in-build (contrast + diacritic QA), not open design questions.

## 9. Unresolved visual-evidence debt (non-blocking — preserved, six items)
1. **Production visual baseline** — no live-UI capture (browser MCP unavailable in V113A). Close before implementation, not before this freeze.
2. **Member (non-guardian) live session** — NOT TESTABLE (no safe member session).
3. **0 audio-only / 0 text-only family cards in prod** — hand-create to capture those Room states; do not synthesize.
4. **Invitation expired/revoked** treatments — no source at any level.
5. **Discovery capsule composition** (deterministic vs generative) — confirm before "reflection" copy implies analysis (no backend change regardless).
6. **`JourneyDetail` internal Share** — unread; Share re-homing remains a product decision, out of scope.

## 10. Exact inputs for V113G (implementation planning)
1. This **final F1–F7 package** (source-of-truth incl. §2b promotion, frozen tokens, updated screen matrix, updated component spec, responsive/a11y/motion, QA gates).
2. The **four approved L3 correction packs** (canonical filenames in §1) including the final Pack 4 accessibility patch.
3. **Frozen tokens and labels:** F2 hexes + Playfair Display / Be Vietnam Pro; 4-primary IA; "Hôm nay" / "Của con" / "Thế giới của con"; VN role grammar; gold text `#806A35`; tablet top bar + drawer.
4. **F4 reuse map (§9)** and component contracts (now fully L2/L3-anchored).
5. **F6 as the implementation acceptance harness** — DESIGN SOURCE READY: PASS · IMPLEMENTATION QA: NOT YET RUN; all route-by-route build gates open.
6. **Carried evidence debt and product confirmations:** the six §9 items; Discovery capsule no-AI; Share re-homing; Discovery child-selector reconciliation (§2.9).
7. **Frozen invariants for planners:** `Ký ức | Thành viên` via `?section=`; Home = identity + one memory + one action; Memory Room content-first order; Kid gateway hierarchy; one primary action per surface; separate governance predicates; consent write path unchanged (F9 parked 🔒).

*(This section lists inputs only. No V113G build plan is produced in this task.)*

## 11. Explicit non-actions (this pass)
No code · no source edit · no route/redirect/dead-code change · no migration/schema/RPC/RLS/Edge · no consent-semantics or governance change · no deploy · no production data mutation · no RULES append · no SYSTEM_MAP bump · no new canonical HANDOFF · no new visual direction invented · no new product features · no AI/Search/Notification-functionality/Circle/ranking · no social sharing · no Share re-home · official logo not replaced · rejected mockups not treated as sources · no V113G implementation planning. Fixed product decisions treated as fixed, not re-opened.

---
V113F PASS — DESIGN SYSTEM FROZEN
