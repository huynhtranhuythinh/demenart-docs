# A3 — EXISTING IA & FLOW MAP
**V113A** · `OBSERVED_SOURCE` unless noted.

---

## 1. Navigation structure (as built)

**Primary nav (both desktop header + mobile bottom-nav, identical 4):**
`Trang chủ` → `/parent` · `Hành trình` → `/parent/journal` · `Gia đình` → `/parent/family` · `Cài đặt` → `/parent/settings`
Plus header-only Bell → `/portal/notifications`.

**Not in primary nav (secondary depth):**
- `/parent/consent` — reached from: Settings CardLink; journal `ConsentWaitingHint` popover; invite/share error links.
- `/parent/kid` — reached from: Settings CardLink; Home card F ("Cổng của bé").
- `/parent/discovery` — reached from: Settings CardLink ("Nhìn lại"); Home card D ("Mở phần Nhìn lại", **only when `hasData`**).

**IA verdict:** three real, non-trivial surfaces (privacy, child-access, insights) live one level below the visible nav, discoverable only through the Settings hub or conditional Home cards. `INFERRED`: consent + kid are frequent/high-intent enough that Settings-only discoverability is an IA gap.

## 2. Two shells for "the family" (structural split)

`OBSERVED_SOURCE` — The same FMN content renders in **two different products**:

| | `/parent/family` (guardian) | `/family` (member) |
|---|---|---|
| Host | ParentLayout (amber, bottom-nav) | own standalone shell (forest/cream) |
| Width | `max-w-4xl` (inside a Card, `p-6`) | `max-w-3xl` (inside a section, `p-6`) |
| Member section | full management (invite/remove/pending) | **read-only list** |
| Empty state | create-family-space flow | "Bạn chưa thuộc không gian… nhờ người thân mời" |
| Create card | archive `onCreate` + standalone button | archive `onCreate` + standalone button |
| Sign-out | shell header | own header |

Both mount the identical `FamilyArchiveNavigation` + `FamilyCardComposer`. A guardian lives in `/parent/family`; a non-guardian relative (no parent portal) lives in `/family`. **This is the "surfaces feel like separate products" split, first-class.** `UNKNOWN`: exact landing route per role is decided by `lib/home-path.ts` (`homePathForRole`), not re-read this pass.

## 3. Duplicated / overlapping concepts

`OBSERVED_SOURCE`:
1. **Retrospection appears three ways:** *Journey* (`/parent/journal`, the canonical timeline) · *"Nhìn lại"* Home card + Settings link · *"✨ Bản Khám Phá Nghệ Thuật"* (`/parent/discovery`). The same surface (#9) is labelled **"Nhìn lại"** in nav entry points but **"Bản Khám Phá Nghệ Thuật"** on its own page — a single-surface naming split, plus conceptual overlap with Journey.
2. **Two "memory" spines with different provenance grammar:** child journal memories (`get_child_journal`; parent_memory / session / creation / moment / **family_preserve**) vs family cards (`get_family_memory_stream` / archive; native / parent_memory). They connect via **Preserve** (family card/contribution → `child_journey source='family'`, currently 1 row live). A parent sees "family" content in two places (Family archive + Journey's `TimelineFamilyPreserveLeaf` / viewer preserve entries).
3. **Child selector implemented 3 ways:** global persisted `ParentChildProvider` (Home/Journey/Consent/Kid) · **independent non-persisted** copy in `/parent/discovery` · plus per-page chip rendering duplicated in each surface (not a shared `<ChildSwitcher/>`).
4. **Notifications/Support live in `/portal`**, not `/parent` — parent chrome links out to a neutral shell (intentional per D95 "hạ-tầng-toàn-App", but a visible context switch).

## 4. Key user flows (as built)

`OBSERVED_SOURCE`:

**Create a parent memory:** Home/Journey "Ghi lại" → `ParentMemoryComposer` → on save → `navigate('/parent/journal?focus=journey:{id})` (Home also `loadSummary()`). Focus param scrolls/opens the new item in the viewer.

**Open a memory (Journey):** `ParentJourneyViewer` internal rail→stage→detail (`CANONICAL` D224/D302/D305) — memory-object renderers, in-page; not a route change.

**Open a memory (Family):** `FamilyArchiveNavigation.openCard` → `navigate('/family/memory/{cardId}?origin={base}&y&m')` → **route change into cream Room** (leaves parent shell). Room resolves via `get_family_card(cardId)` (direct-entry, not stream state). Back → origin `?y&m` (period restored). `origin`/`y`/`m` are **UX-only** (validated whitelist; never authorization — D305).

**Navigate the archive:** newest-period auto-normalized into URL `?y&m` once per space (replace). Desktop = sticky 16rem rail + period pane; mobile = "Dòng thời gian" button → left Sheet.

**Family administration (guardian):** `/parent/family` → Mời (InviteDialog → `mint_family_invitation` → one-time `/family-invite#t=` link) · Gỡ (`remove_family_member`) · Thu hồi (`revoke_family_invitation`). Guardians protected from removal (`canRemove = canInvite && !is_guardian && !is_self`).

**Kid access setup:** `/parent/kid` → enable → set PIN → "Ghép thiết bị mới" → code shown → child enters at `/kid` → realtime `paired` broadcast closes the code.

**Consent:** `/parent/consent` → per-type Switch → **direct write** to `consents` (grant = insert/update `granted=true, withdrawn_at=null`; withdraw = `granted=false, withdrawn_at=now`).

## 5. Back / return / transition behavior

`OBSERVED_SOURCE` + `CANONICAL`:
- Memory Room Back → `history.back` to origin with period params (D306 M5 Return; route surface fade, no modal).
- Archive selection lives in `?y&m` (F5/paste-link safe; deterministic).
- Discovery detail lives in `?capsule=`; back clears param + `scrollTo(0)`.
- Journey deep-link lives in `?focus=journey:{id}`.
- **Cross-shell transitions have no shared chrome:** `/parent/family` (amber) → Room (cream) → back is a full surface swap. `/parent` → Bell → `/portal` (neutral) is a shell change.

## 6. Orphaned / transitional routes

`OBSERVED_SOURCE`:
- **`/parent/discovery`** — real, active surface (not orphaned/deprecated). Purpose to reassess: it is a distinct "capsule-generation" retrospection product that overlaps Journey and is buried; naming ("Nhìn lại" vs "Bản Khám Phá") is inconsistent. `generate_discovery_capsule` eligibility gating is deterministic (`not_eligible` + `failed` domains) — `INFERRED` not AI/LLM, but fit with the "no AI / no ranking" design constraint should be reassessed.
- No dead/404 parent routes found in the tree; the "orphaned" quality is **navigational** (not in nav), not structural.
