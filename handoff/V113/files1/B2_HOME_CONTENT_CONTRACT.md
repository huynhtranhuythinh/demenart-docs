# B2 — HOME CONTENT CONTRACT
**V113B** · Can the approved (de-dashboarded) Home be built from **existing** contracts, no schema/RPC change? · `OBSERVED_SOURCE` unless noted. No invented data, no recommendation engine, no ranking.

---

## 1. Data substrate (existing, no backend change)

`OBSERVED_SOURCE`:
- **`ParentChildProvider`** → `children[] {id, full_name, nickname}`, persisted `selectedChildId` (`localStorage dma-parent-child:{profileId}`).
- **`get_child_journal(p_child_id)`** → `{ journey[], skills[], badges[], moments[], creations[] }` (single call; already used by both Home and Journey).
  - `journey[]`: `entry_type ∈ {session, badge, parent_memory}`; `parent_memory {memory_id,title,story,galleryItems,artistic_domain,mine,memory_type}`; **family_preserve** entries (`isFamilyPreserve`, `source='family'`) `{target_type, card_title, card_story, contributor_name, preserved_by_name, contribution_kind, contribution_body}`.
  - `skills[] {skill, signal_count}` · `badges[] {title, description}` · `moments[] {moment_id, media_id, caption, created_at, tagged_count, galleryItems}` · `creations[] {creation_id, kind('drawing'|'recording'), caption, created_at, media_id}`.
- **`summarizeChildJournal(data)`** (client lib) → `works, voice, moments, badges, topSeed, parentSaved, visibleTotal, hasAnyJourneyData`.
- **`buildPreview(data)`** (already in `parent.index.tsx`) → newest 3 leaves (emoji/label/text/day-month).
- **`get_signed_media_url` (Edge)** → consent-gated signed URL for any `media_id` (existing; used for thumbnails).

**Key fact for feasibility:** family activity for a child is **already present inside `get_child_journal`** as `family_preserve` entries (child-scoped `source='family'`). A Home "family signal" needs **no** space-scoped query.

## 2. Module-by-module contract

### Module 1 — Identity + ChildSwitcher 🔒
- **Purpose:** family/child identity anchor at the top of the first viewport (replaces eyebrow+greeting-as-hero).
- **Source:** `ParentChildProvider` (`children`, `selectedChildId`, `setSelectedChildId`). `OBSERVED_SOURCE`
- **Field availability:** name/nickname ✅; **no avatar/photo field** on `children` `OBSERVED_SOURCE` → identity is textual unless a media field is added (❌ backend to add photo — out of scope).
- **Context:** child-scoped; ChildSwitcher visible only when `children.length > 1`.
- **Empty:** no children → "Chưa có hồ sơ con nào được liên kết" + Support link (existing copy).
- **Error:** children fetch error → context sets `children=[]`; show retry/support (currently silent-empty `OBSERVED_SOURCE` → 🔧 REFINE to distinguish error from empty).
- **Primary action:** none (identity, not action).
- **Backend required:** **No** for text identity. **Yes** only if a child avatar is desired (not requested).

### Module 2 — Meaningful recent memory 🔒
- **Purpose:** one real child memory with actual media as the emotional centre (replaces count tiles).
- **Source:** `get_child_journal` → newest media-bearing item across `creations`/`moments`/`parent_memory` (reuse `buildPreview` logic, take top 1 with media) + `get_signed_media_url` for the thumbnail. `OBSERVED_SOURCE`
- **Field availability:** media_id/galleryItems ✅, caption/title/story ✅, date ✅. Signed URL via existing Edge ✅.
- **Context:** child-scoped.
- **Empty:** no media items → fall back to Module 3 signal or the warm "Bắt đầu hành trình…" empty (existing copy).
- **Error:** journal error → single quiet error card (reuse grammar).
- **Primary action:** open in Journey (`/parent/journal?focus=…`) — existing focus param `OBSERVED_SOURCE`.
- **Backend required:** **No.** Deterministic = "newest item that has media" (a date sort, not ranking).

### Module 3 — Journey signal 🔒
- **Purpose:** one meaningful development signal (not KPI tiles).
- **Source:** `get_child_journal` → `skills[]` (`signal_count`) and/or newest `badge`/`session`. `OBSERVED_SOURCE`
- **Field availability:** skills + signal_count ✅; badges ✅; sessions (teacher_note) ✅.
- **Context:** child-scoped.
- **Empty:** no skills/badges → omit module (do not fabricate).
- **Error:** inherits journal error.
- **Primary action:** open Journey.
- **Backend required:** **No.** Deterministic = "top skill by signal_count" or "newest badge/session" (a max/sort, **not** relevance/ranking).
- 🔧 **No-ranking check:** presenting a single signal by an existing numeric `signal_count` or recency is deterministic ordering, **not** a relevance engine — compliant.

### Module 4 — Family contribution / preserve signal 🔒
- **Purpose:** surface that the family added/preserved something for the child ("Bà đã góp một ký ức", "Được giữ vào Hành trình").
- **Source:** `get_child_journal` → `journey[]` filtered by `isFamilyPreserve` (child-scoped `source='family'`). `OBSERVED_SOURCE` — **no space query needed.**
- **Field availability:** `contributor_name`, `preserved_by_name`, `card_title/story`, `contribution_kind/body` ✅.
- **Context:** child-scoped (only family activity that reached this child via Preserve).
- **Empty:** no family_preserve entries → omit module (common: only 1 such row exists live per A1).
- **Error:** inherits journal error.
- **Primary action:** open the preserved item in Journey; (optionally deep-link to Family archive — existing routes).
- **Backend required:** **No** for child-scoped preserved signal. 🔧 **Caveat:** *pending* family activity **not yet preserved** to this child is **not** in `get_child_journal` (it lives space-scoped) → showing "unpreserved" family activity on Home would need a space query. **Smallest no-schema fallback:** scope the Home family signal to **preserved** family entries only (already in payload); richer "family is active" teasers are deferred (would reuse `get_family_space`/`get_family_stream_presence`, still no schema change, but adds a call — defer).

### Module 5 — Contextual next action 🔒
- **Purpose:** exactly one primary action, state-dependent (no competing CTAs).
- **Source:** derived from journal state (no data source). `INFERRED`
- **Logic (deterministic):** no child → "Liên hệ nhà trường/Hỗ trợ"; child but no data → "Ghi lại điều đầu tiên về {child}"; has data → "Ghi lại một điều" *or* "Xem hành trình" (pick one primary; the other becomes a quiet link).
- **Empty/Error:** action maps to the state itself.
- **Primary action:** opens `ParentMemoryComposer` or navigates Journey (existing).
- **Backend required:** **No.**

### Module 6 — Recent-memory preview 🔒
- **Purpose:** a short, quiet strip of the latest few memories (not a module grid).
- **Source:** `buildPreview(get_child_journal)` → newest 3 leaves (already implemented). `OBSERVED_SOURCE`
- **Field availability:** emoji/label/text/date ✅; 🔧 REFINE to show **thumbnails** (via `get_signed_media_url`) instead of emoji, matching V4 "large child media" spirit.
- **Context:** child-scoped.
- **Empty:** omit when no items.
- **Error:** inherits journal error.
- **Primary action:** each item → Journey focus; strip footer → "Xem toàn bộ hành trình".
- **Backend required:** **No** (thumbnails use existing signing Edge).

## 3. Feasibility verdict (Home)

🔧 **The approved Home is fully buildable from existing contracts with ZERO backend change.** All six modules derive from **`ParentChildProvider` + `get_child_journal` (+ existing `get_signed_media_url`)**. No new RPC, no schema, no recommendation engine, no ranking — the only ordering used is deterministic recency / existing `signal_count` max.

**Marked limitations (smallest no-schema fallbacks):**
1. **Child identity is textual** — no avatar field on `children`. Fallback: initial/monogram or the child's newest media as the identity image (no schema change). Adding a real avatar = backend, out of scope.
2. **Home "family signal" is limited to *preserved* family activity** (in-payload). Fallback: scope to preserved entries; richer "family active" teaser deferred to an optional `get_family_space` call (no schema).
3. **Home error vs empty** currently hand-rolled and partly silent for the children fetch → REFINE to the shared truth-state grammar (no backend).

**No STOP condition triggered** (no module needs invented data or ranking).
