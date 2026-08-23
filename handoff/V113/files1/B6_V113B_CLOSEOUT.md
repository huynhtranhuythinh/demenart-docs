# B6 — V113B CLOSEOUT
**V113B · Parent Portal UX Strategy & IA Feasibility Pack** · Source-aware planning only.
**Date:** 2026-07-16 (GMT+7) · ZERO code / migration / route / redirect / schema / RPC / RLS / Edge / consent-path / governance / deploy / RULES / SYSTEM_MAP / HANDOFF change.

---

## 1. Feasibility verdict
**`V113B PASS — READY FOR WIREFRAMES`.** The approved V4 direction and the fixed IA decisions are **feasible against current routes, contracts, and governance with zero backend change.** All PASS gates (§7 of the brief) are met. Carried-forward debt (production visual baseline + two confirmation items) is **visible, non-blocking** for wireframing.

## 2. Decisions confirmed (fixed by Product Owner / ChatGPT — not re-opened)
1. Four primaries: **Hôm nay / Hành trình / Gia đình / Của con** (`/parent`, `/parent/journal`, `/parent/family`, `/parent/kid`); desktop "Thế giới của con". Settings demoted to utility.
2. Discovery = contextual **"Nhìn lại một chặng"** in Journey (+ optional Home preview); not a 5th primary; route/contracts preserved.
3. Family = **one experience system, two entry contexts**; unify components, **not** routes/authz.
4. Family internal split **`Ký ức | Thành viên`**.
5. Home is **not a dashboard** (identity + one memory + one action).
6. Memory Room **content-first**; D284/D293/D305 unchanged.
7. Kid = parent→child **gateway**; controls at depth; Kid authority unchanged.
8. Consent write-path **not** changed in V113B (F9 parked for separate security review).

## 3. Contradictions found
- **None material.** One documentation-vs-live drift re-confirmed (`OBSERVED_SOURCE`): Kid Portal is **built** (not "reserved") — which is exactly why "Của con" as primary #4 is feasible today. Not a blocker; a doc-reconciliation item.
- The V113A **F9** (direct consent write) is **explicitly out of scope** here per PO 🔒 — recorded, not actioned.

## 4. No-backend feasibility result
🔧 **Confirmed buildable with existing contracts, no schema/RPC/Edge change:**
- **Home** — all 6 modules from `ParentChildProvider` + `get_child_journal` (+ existing `get_signed_media_url`); no ranking/recommendation. Two no-schema fallbacks noted (textual identity; family-signal scoped to preserved entries). (B2)
- **Family unification** — presentation/component-level only; `get_family_space`/role contracts intact. (B3)
- **`Ký ức | Thành viên`** — query-backed `?section=` (mirrors existing `?y&m`); no route tree change. (B1 §3)
- **Discovery-in-Journey** — entry points + bind to shared ChildSwitcher; `*_discovery_capsule` + `?capsule` route preserved. (B4)
- **Kid gateway** — recompose hierarchy over existing `kid_*` contracts. (B1, B5)
- **Room content-first** — presentation reorder; governance branches unchanged. (B5)

## 5. Routes that remain unchanged
`/parent`, `/parent/journal`, `/parent/family`, `/parent/kid`, `/parent/consent`, `/parent/settings`, `/parent/discovery`, `/family`, `/family/memory/:cardId`, `/portal/notifications`, `/portal/support`, `/family-invite`, `/share/:token`, `/kid` — **all retained** (`OBSERVED_SOURCE`). Only nav **labels/targets** and internal **section state** change; no route added/removed/redirected.

## 6. Components safe to reuse (KEEP)
`FamilyArchiveNavigation`, `FamilyArchiveIndex`, `FamilyMemoryPeriod`, `MemoryItem`, `ArchivedCardsSection`, `FamilyStateBlock` + `familyExperienceGrammar` (truth-state grammar), `ParentJourneyViewer` + `JourneyStage/Detail/Rail` + `useJourneySigning`, `ParentChildProvider`, all Discovery `*_capsule` contracts, all Kid `kid_*` contracts, FMN tokens, governance predicates in `memoryRoomShared`.

## 7. Components requiring recomposition / extraction
- **EXTRACT:** `FamilyExperienceShell(context)`, `FamilyIdentityHeader`, `FamilyMembers(role)`, role→affordance mapping, member-subtitle helper (de-dupe), live exports (`MemoryItem`/`ArchivedCardsSection`) out of the dead stream body.
- **RECOMPOSE:** Home (de-dashboard), `Ký ức|Thành viên` split, single create CTA, Memory Room (content-first + surfaced return context), Kid gateway hierarchy, Discovery entry + shared ChildSwitcher binding.
- **REFINE:** period count-line, `MemoryItem`→V4 large media, Home error-vs-empty to shared grammar, split the ~1k-line `memoryRoomShared`.
- **RETIRE (deferred, not in V113B):** dead `parent.journal` timeline branch + `ParentJournalLightbox`; unmounted `FamilyMemoryStream` body.

## 8. Open evidence gaps (visible, non-blocking)
1. **Production visual baseline** — no `OBSERVED_LIVE_UI` (browser MCP unavailable in V113A). Capture set = A5 §2. Must be closed **before production implementation**, not before wireframes.
2. **`JourneyDetail` internal share** — not read; whether the live viewer surfaces any Share is `UNKNOWN`. Confirm before deciding Share re-homing.
3. **Discovery capsule composition** — deterministic aggregation vs any generative step not inspected at SQL level (`UNKNOWN`); confirm no-AI before "reflection" copy implies analysis. No backend change proposed regardless.
4. **Member (non-guardian) live session** — `NOT TESTABLE — NO SAFE MEMBER SESSION` (unchanged from V113A).
5. **`homePathForRole`** landing per role — not re-read.
6. **0 audio-only / 0 text-only family cards** in prod → text/audio Room states need a hand-created card to capture (do not synthesize).

## 9. Inputs required for ChatGPT wireframes
- This B1–B5 pack (target IA, route table, 5 Mermaid diagrams; Home content contract; Family component map; Discovery integration; governance/state overlay).
- Fixed: four-primary model + labels; `Ký ức|Thành viên`; Home = identity + one memory + one action; Room content-first order (return→media→title/story→provenance→voices→Preserve→lifecycle); Kid gateway hierarchy.
- Constraints for wireframes: V4 traits **without** board decorations (no slogan panel/mascot/flowers/KPI cards/bordered-box grid/mini-gallery); large child media; quiet governance; desktop identity rail; 4-item mobile bottom-nav; **one** primary action per surface.
- Deterministic-data reality (B2): no child avatar field; family signal = preserved entries; single-signal Journey/skill by recency or `signal_count` (not ranking).
- Governance placement constraints (B5): keep `Sửa`/`Lưu trữ`/`Ẩn` separate; Preserve present-not-hidden; generic denial; consent "Vì sao?" entry.

## 10. Explicit non-actions (this pass)
No code / route / redirect / dead-code deletion / schema / migration / RPC / RLS / Edge / consent-path / governance change; no production mutation; no deploy; no RULES append / SYSTEM_MAP bump / new HANDOFF; no high-fidelity mockups; no font/color selection; no V112C reopen; no V113A re-run; no AI / Search / Notification-functionality / Circle / ranking added. Fixed product decisions were treated as fixed, not re-opened.

---
**Final status: `V113B PASS — READY FOR WIREFRAMES`** (with visible, non-blocking production-visual-baseline debt + three confirmation items in §8).
