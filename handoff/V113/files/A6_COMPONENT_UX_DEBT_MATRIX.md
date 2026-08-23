# A6 — COMPONENT & UX-DEBT MATRIX
**V113A** · `OBSERVED_SOURCE` unless noted. Verdicts are for the *future* rebuild (audit-only; nothing changed here). Backend contracts are **KEEP** by constraint (D14/§14) unless evidence proves a gap.

---

## 1. Reuse / rebuild matrix

| Area | Component(s) | Verdict | Reason (evidence) |
|---|---|---|---|
| Backend/data contracts | all RPCs/Edge | **KEEP** | Verified live, additive-only history; single-truth access (D284). No evidence of a data gap. |
| Parent shell | `parent.tsx` (`ParentLayout`) | **REFINE** | Solid amber shell + bottom-nav; 4-item nav omits consent/kid/discovery; Bell exits to `/portal`. IA-level refine, not rebuild. |
| Family shell duplication | `family.tsx` own shell vs `parent.family.tsx` in ParentLayout | **REBUILD (unify)** | Same FMN content in two shells/widths with divergent member affordances → "separate products" split. Needs one canonical family experience + role-conditioned chrome. |
| Parent Home | `parent.index.tsx` | **REFINE→REBUILD (hierarchy)** | Count-tile-forward, no child media above fold, Discovery/Kid buried in cards D/F. Content hierarchy needs rethink; data plumbing (`get_child_journal`) KEEP. |
| Journey viewer | `ParentJourneyViewer` (+ stage/detail/fullscreen, `useJourneySigning`) | **KEEP→REFINE** | `CANONICAL` D224/D302/D305 — memory-object system, TTL-cached signing, reduced-motion. Mature. Refine only. |
| Journey route legacy view | timeline-months branch + `CompactMomentLeaf`/`CompactCreationLeaf`/`TimelineSessionLeaf`/`TimelineParentMemoryLeaf`/`TimelineFamilyPreserveLeaf`/`ParentJournalLightbox` in `parent.journal.tsx` | **REBUILD (remove dead)** | `viewMode` hardcoded `"journey"`, no setter → **entire branch unreachable**. Large dead surface incl. the only `ShareMomentButton` wiring. Remove or re-home share. |
| Family archive nav | `FamilyArchiveNavigation` + `FamilyArchiveIndex` + `FamilyMemoryPeriod` | **KEEP** | V112C Living-Archive spine: single-scroll, sticky rail / mobile Sheet, keyset window, deterministic. Clean. |
| Memory stream (legacy) | `FamilyMemoryStream` (the chaptered stream function) | **REBUILD (remove dead)** | `OBSERVED_SOURCE` + `CANONICAL` V112C: exported but **no longer mounted** (Archive Nav replaced it). Only its exports `MemoryItem` + `ArchivedCardsSection` are live. Extract the live exports; retire the stream body. |
| Memory card | `MemoryItem` | **KEEP→REFINE** | Composition-driven (text/audio/media), reserved 4:3 media, quiet metadata footer. Good. Refine only (see hierarchy note vs Room). |
| Memory Room content | `CardDetail` + `EngagementSection` + `ContributionItem` + `PreserveControl` + `MediaTile` + `AudioPlayer` (all `memoryRoomShared.tsx`) | **KEEP→REFINE** | Governance-correct (D293/D305), fail-closed aux (D298), iOS-safe audio (D224). One monolith file (~1k lines) mixing content + governance + recorder + preserve → **REFINE: split for maintainability**. Header hierarchy metadata-first vs stream media-first → **REFINE for consistency**. |
| Archived section | `ArchivedCardsSection` | **KEEP** | Collapsible restore surface, reachable desktop-rail + mobile-bottom. Fine. |
| Composers | `ParentMemoryComposer`, `FamilyCardComposer`, contribution dialogs | **KEEP→REFINE** | shadcn Dialog-based; recorder mp4-preferred (D224). Not opened in audit; refine for mobile keyboard/height (A5). |
| Member/invite | `InviteDialog` + member/pending cards (in `parent.family.tsx`) | **REFINE** | Works; lives inline in the route file (coupling). One-time link + relationship labels good. Extract + reconcile guardian-only affordances between `/family` (read-only) and `/parent/family`. |
| Consent | `parent.consent.tsx` | **REFINE (security)** | Sole parent write done via **direct `consents` table** insert/update (RLS-only) vs RPC/Edge everywhere else. Refine to RPC for parity + auditability. |
| Kid access | `parent.kid.tsx` | **KEEP→REFINE** | Fully built (contradicts "reserved" docs). Uses shared child context. Refine discoverability (not in nav). |
| Discovery | `parent.discovery.tsx` + `features/discovery/*` | **REFINE (reconcile)** | Own non-persisted child selector (ignores `ParentChildProvider`); label split ("Nhìn lại" vs "Bản Khám Phá"); concept overlap with Journey. Reconcile concept + selector; reassess fit vs no-AI/no-ranking constraint. |
| Child selector | `parentChildContext` (global) vs Discovery's private copy vs per-page chip rendering | **REBUILD (single component)** | Three implementations. Extract one `<ChildSwitcher/>` bound to the persisted context; delete duplicates. |
| Truth-state blocks | `FamilyStateBlock` + `familyExperienceGrammar` (`classifyRpcOutcome`/`outcomeToLoadState`/copy) | **KEEP** | Strong, consistent, actor-correct. Reuse everywhere (Home still hand-rolls its states — could adopt). |
| Tokens | `styles.css` FMN token layer + `--font-memory` | **KEEP** | oklch token layer, reduced-motion gate. Parent (amber) vs FMN (cream/forest) are two palettes — reconcile at rebuild, not remove. |

## 2. Component-classification summary

`OBSERVED_SOURCE`:
- **Reusable / mature:** `FamilyArchiveNavigation` family, `ParentJourneyViewer`, `useJourneySigning`, `FamilyStateBlock`/grammar, `ParentChildProvider`, FMN tokens.
- **Oversized / mixed-concern:** `memoryRoomShared.tsx` (content + governance + recorder + preserve in one file); `parent.family.tsx` (archive + member mgmt + invite + dialogs); `parent.journal.tsx` (live viewer host + full dead legacy view).
- **Duplicated:** family shell (`/family` vs `/parent/family`); child selector (×3); "Tạo kỷ niệm" create affordance (×2 per family surface); member-subtitle helper copy-pasted into both family route files.
- **Route-specific / tightly coupled:** `InviteDialog`, `EmptyState`/`SpaceView` inline in `parent.family.tsx`; `ShareMomentButton`/`ConsentWaitingHint`/`Compact*Leaf` inline in `parent.journal.tsx`.
- **Legacy / dead:** `FamilyMemoryStream` (stream body, unmounted); the entire `viewMode!=="journey"` branch of `parent.journal.tsx` + `ParentJournalLightbox` (unreachable). `JourneyViewToggle` imported but toggle not rendered.
- **Domain-safe (do not touch):** all governance predicates in `CardDetail`/`EngagementSection`/`PreserveControl` (mirror D284/D293/D305); Kid PIN/device RPCs; consent semantics.

## 3. Coupling / duplication risks for the rebuild

`INFERRED`:
1. Retiring the `parent.journal.tsx` dead branch must **re-home `ShareMomentButton`** (moment share) if share is intended to remain reachable — it is currently only wired in the dead branch (live-viewer share = `UNKNOWN`, needs `ParentJourneyViewer` read/capture).
2. Unifying the two family shells must preserve the **member vs guardian affordance difference** at the component level (read-only list vs full management) rather than at the route level.
3. Extracting `memoryRoomShared` must keep the governance split intact (never merge `canEdit`/`canArchive`/`can_moderate` — D293) and the fail-closed aux boundaries (D298).
4. A single `<ChildSwitcher/>` must write through `ParentChildProvider` (persisted) — Discovery's separate selection is the current divergence.
