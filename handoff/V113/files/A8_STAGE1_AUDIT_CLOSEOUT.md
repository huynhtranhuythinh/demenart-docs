# A8 — STAGE 1 AUDIT CLOSEOUT
**V113A · Parent Portal UX/UI Rebuild — Experience & Source Baseline Audit**
**Date:** 2026-07-16 (GMT+7)

---

## 1. Canonical / live baseline
`RULES D308 · SYSTEM_MAP v1.13 · HANDOFF v112C` (no later handoff on disk). Live inventory **matches the v112C anchor with zero drift**: 87 tables / 190 secdef / 164 policies / 1 cron · migrations 101 · edge 16 · routes 57 raw fullPaths = 52 convention · journey 37 (36+1) · preserve 5 (1a/3r/1o) · cards 16 (15a/1arch: 12 parent_memory + 3 native + 1 native-archived) · contributions 5 (3a/2w) · family_spaces 1. Space "Gia đình Hùng" `4806ff8d`; guardians Hùng `…051` / Ngân `d26e5914`; non-guardian Bà ngoại `2965d4a0`; children An `…041` / Khang `…045`. (Full detail: **A1**.)

## 2. Audit status
**TECHNICAL AUDIT PASS · VISUAL AUDIT INCOMPLETE.**
Structural / source / live-DB audit is complete (every parent surface + the FMN spine read from live source; full live inventory + actors measured). The production browser-evidence branch could **not** be obtained: the connected-browser MCP was unresponsive (4-minute timeout, flagged to repeat) → per B+ STOP rules the browser branch is stopped, all other work continued. No runtime UI/mobile captures exist.

## 3. Eight deliverables
1. `A1_CANONICAL_RUNTIME_TRUTH.md` — baseline reconciliation, actors, drift.
2. `A2_PARENT_SURFACE_MAP.md` — every surface: route/shell/component/data/mutations/actor/debt.
3. `A3_EXISTING_IA_AND_FLOW_MAP.md` — nav, two-shell split, duplicated concepts, flows, back behavior.
4. `A4_CONTENT_EMOTIONAL_HIERARCHY_AUDIT.md` — first-viewport, dominance, CTA competition, metadata density, hierarchy inversion.
5. `A5_MOBILE_EXPERIENCE_AUDIT.md` — source-intent mobile analysis + exact capture map (runtime NOT TESTABLE).
6. `A6_COMPONENT_UX_DEBT_MATRIX.md` — KEEP/REFINE/REBUILD + dead code + duplication.
7. `A7_STATE_PERMISSION_MATRIX.md` — governance mirror UI↔backend (untouchable).
8. `A8_STAGE1_AUDIT_CLOSEOUT.md` — this synthesis.

## 4. Screenshot / evidence index
- **Source evidence (OBSERVED_SOURCE):** `parent.tsx`, `parent.index.tsx`, `parent.journal.tsx`, `parent.family.tsx`, `family.tsx`, `parent.consent.tsx`, `parent.settings.tsx`, `parent.kid.tsx`, `parent.discovery.tsx`, `family_.memory.$cardId.tsx`, `parentChildContext.tsx`, `FamilyArchiveNavigation.tsx`, `FamilyMemoryPeriod.tsx`, `FamilyMemoryStream.tsx`, `memoryRoomShared.tsx`, `routeTree.gen.ts` (15 files read this pass) + `CANONICAL` `ParentJourneyViewer`/`FamilyMemoryRoom` (D224/D302/D305/D306).
- **Live DB evidence (OBSERVED_LIVE_DB):** inventory query, actor/relationship/contribution query, card-dimension query, edge-function list.
- **Screenshots (OBSERVED_LIVE_UI):** **NONE — browser unavailable.** Required capture set is fully specified in A5 §2 (deterministic filenames per `V113A_<actor>_<route>_<state>_<viewport>`) and in the visual-pass list (guardian ×19 states, member ×6 → member = `NOT TESTABLE — NO SAFE MEMBER SESSION`).

## 5. Top-10 evidence-backed findings

| # | Finding | Evidence | Sev | Conf |
|---|---|---|---|---|
| F1 | Same family experience ships as **two shells** (`/parent/family` amber `max-w-4xl` w/ full member mgmt vs `/family` cream `max-w-3xl` read-only) → "separate products" | `OBSERVED_SOURCE` | P1 | High |
| F2 | **Hierarchy inversion:** stream `MemoryItem` is media-first (metadata footer) but Memory Room `CardDetail` is metadata-first (title→creator→date→source→people→media) | `OBSERVED_SOURCE` | P1 | High |
| F3 | Parent **Home leads with 4 numeric count tiles**; child's own media absent above the fold (emoji + numbers stand in) — tension with "album, not dashboard" DNA | `OBSERVED_SOURCE` | P1 | High |
| F4 | **Dead legacy Journey view**: `viewMode` hardcoded `"journey"`, no setter → timeline-months + `Compact*Leaf` + `ParentJournalLightbox` unreachable; **moment Share wired only there** (live-viewer share reachability unknown) | `OBSERVED_SOURCE` | P1 | High |
| F5 | **Three retrospection concepts / two labels**: Journey vs "Nhìn lại" (Home/Settings) vs page H1 "✨ Bản Khám Phá Nghệ Thuật" (`/parent/discovery`) | `OBSERVED_SOURCE` | P2 | High |
| F6 | **Child selector ×3**: persisted `ParentChildProvider`, Discovery's own non-persisted copy, and per-page chip re-implementations — switching child is inconsistent across surfaces | `OBSERVED_SOURCE` | P2 | High |
| F7 | **`/parent/family` mixes archive + administration** (members/invites/pending) on one surface; two "create memory" CTAs co-exist | `OBSERVED_SOURCE` | P2 | High |
| F8 | **Consent/Kid/Discovery are not in primary nav** (Settings-hub-only / conditional Home cards) — high-intent privacy & child-access buried | `OBSERVED_SOURCE` | P2 | Med |
| F9 | **Consent writes go direct to the `consents` table** (RLS-only), unlike every other sensitive parent write (RPC/Edge) — governance-hygiene inconsistency | `OBSERVED_SOURCE` | P2 | High |
| F10 | **`FamilyMemoryStream` body dead-but-retained** (unmounted since V112C; only its exports `MemoryItem`/`ArchivedCardsSection` live) — component debt | `OBSERVED_SOURCE`+`CANONICAL` | P3 | High |

(Secondary, recorded across A-docs: doc-vs-live Kid drift [built, not "reserved"]; Bell exits amber shell to `/portal`; video-height layout-shift risk in Room; `memoryRoomShared` monolith; member-subtitle helper duplicated in both family route files.)

## 6. Rebuild-depth verdict
- **REBUILD:** family-shell unification (F1); Home content hierarchy (F3); single `<ChildSwitcher/>` (F6); remove dead Journey legacy view + FamilyMemoryStream body (F4/F10).
- **REFINE:** parent shell/IA (nav for consent/kid/discovery — F8); Memory Room hierarchy + split `memoryRoomShared` (F2); `/parent/family` archive-vs-admin separation + single create CTA (F7); Discovery concept/label reconcile (F5); consent-write-via-RPC (F9).
- **KEEP (do not touch):** all backend contracts; governance predicates (D284/D293/D305); `FamilyArchiveNavigation` spine; `ParentJourneyViewer`; `useJourneySigning`; truth-state grammar; FMN tokens; Kid PIN/device RPCs; consent semantics.

## 7. Duplicated-concept findings
Two family shells (F1) · three retrospection surfaces/two labels (F5) · child selector ×3 (F6) · "create memory" CTA ×2 per family surface (F7) · member-subtitle helper duplicated · child journal vs family card "memory" spines linked only by Preserve (conceptual, keep).

## 8. Mobile verdict
**INCOMPLETE — browser evidence unavailable.** Source intent is coherent (single-scroll archive, Sheet timeline index, reserved 4:3/16:9 media frames, 56px bottom-nav, reduced-motion gating). Unconfirmed runtime risks: fixed bottom-nav vs iOS safe-area/Safari bars; Journey stage fit after header at 390px; family archive legibility inside a Card at 390px; video-height layout shift in the Room; dialog/sheet/keyboard behavior; sub-44px tap targets (member-remove X, contribution row buttons, preserve "Bỏ giữ" link, consent Switch). Exact capture map in A5 §2.

## 9. Governance risks
No governance breach found; authority is correctly mirrored UI↔backend (A7). Watch-items for the rebuild: (a) keep `canEdit`/`canArchive`/`can_moderate` **separate** (never merge to `canManage` — D293); (b) keep aux reads **fail-closed-and-present** (D298); (c) preserve generic non-enumerating denial (D305 §2); (d) **F9** — route consent writes through an RPC for audit/parity; (e) never let `navOriginHint`/`?y&m` influence authorization (UX only — D305).

## 10. Open evidence gaps
- All `OBSERVED_LIVE_UI` (desktop + mobile) — browser unavailable this pass. Required set: A5 §2 + the guardian ×19 / member ×6 visual-pass list.
- **Member (non-guardian) surfaces** — `NOT TESTABLE — NO SAFE MEMBER SESSION` (audit must not manufacture one).
- **Live-viewer Share reachability** — `ParentJourneyViewer` not read this pass; share currently wired only in dead code (F4) → confirm by source read or capture.
- `homePathForRole` landing per role (which shell a guardian vs member lands in) — not re-read.
- QA card variety in production: 15 active = 12 parent_memory + 3 native; **0 audio-only / 0 text-only** family cards currently exist (per A1) → text/audio Room states need a hand-created card to capture (do not synthesize during audit).

## 11. Mockup-readiness verdict
**READY FOR STRUCTURAL/IA MOCKUP; NOT YET READY FOR FINAL VISUAL SIGN-OFF.** The structural truth (surfaces, IA, data contracts, governance, component debt, duplicated concepts) is fully established and sufficient for V113B (UX Strategy & IA) and for art-direction exploration by ChatGPT / the Product Owner. Final visual readiness requires the production capture pass (A5 §2) to confirm first-viewport dominance, layout shift, mobile fit, and the governance visual matrix — currently blocked on browser availability.

## 12. Non-mutation confirmation
- **Zero code** ✓  · **Zero migration** ✓  · **Zero data mutation** ✓  · **Zero deploy** ✓  · **Zero canonical append** ✓
All DB access was read-only SELECT; all repo access was read-only; no Lovable/edge write or deploy; no `DMA_RULES`/`SYSTEM_MAP`/`HANDOFF` file was appended or bumped.

## 13. Recommended next step
**V113B — Parent Portal UX Strategy & Information Architecture** (stages only, no code): unify the family experience (F1), resolve retrospection concept/labels (F5), define a single child-switcher (F6), promote privacy/child-access into IA (F8), and set the Home content hierarchy direction (F3) — with the production capture pass (A5 §2) run first to close the visual evidence gap.
