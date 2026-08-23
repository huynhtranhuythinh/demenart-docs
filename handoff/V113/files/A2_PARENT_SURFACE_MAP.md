# A2 — PARENT SURFACE MAP
**V113A** · Evidence tags: `OBSERVED_SOURCE` unless noted. Runtime layout not browser-confirmed (browser branch unavailable — see A5).

---

## 1. Shell / chrome

`OBSERVED_SOURCE` `src/routes/_authenticated/parent.tsx` — **ParentLayout**
- Amber shell (`bg-gradient from-amber-50/60`), `max-w-4xl`, header + `<Outlet/>` + mobile bottom-nav. Wraps everything in **`ParentChildProvider`** (global child context).
- **Desktop header nav (4):** Trang chủ `/parent` · Hành trình `/parent/journal` · Gia đình `/parent/family` · Cài đặt `/parent/settings` + Bell → **`/portal/notifications`** (leaves amber shell) + name + Đăng xuất.
- **Mobile bottom-nav (4, `sm:hidden`, `grid-cols-4`, `min-h-[56px]`):** same 4 items.
- **Absent from all nav:** `/parent/consent`, `/parent/kid`, `/parent/discovery` (reachable only via Settings hub and/or Home cards — see A3).
- `main` `pb-28 sm:pb-8` reserves space for bottom-nav on mobile. `InAppBrowserNotice` at top of main.

The **flat `/family`** and **`/family/memory/$cardId`** routes are **outside** ParentLayout — each has its own standalone shell (see below).

## 2. Surface table

| # | Surface | Route | Shell | Component(s) | Primary data | Mutations | Actor | Purpose | UX debt (source-level) |
|---|---|---|---|---|---|---|---|---|---|
| 1 | Parent Home | `/parent` (`parent.index.tsx`) | ParentLayout | inline (Hero/Summary/Recent/Nhìn-lại/Tips/Kid-link) + `ParentMemoryComposer` | `get_child_journal` (1 call) → `summarizeChildJournal` | create (composer) | Parent/guardian | Landing; child summary + entry to journey/create | 6 stacked cards; **4 count tiles** dominate; child media not above fold (emoji+numbers); Discovery & Kid reachable only here (cards D/F); child chips only if >1 child |
| 2 | Journey ("Hành trình") | `/parent/journal` | ParentLayout | **`ParentJourneyViewer`** (live) + `ParentMemoryComposer`; **dead legacy timeline branch present** | `get_child_journal` (same as Home) | `archive_parent_memory`/`restore_parent_memory`, edit via composer | Parent/guardian | Child art journal timeline (memory-object viewer) | `viewMode` hardcoded `"journey"` → entire timeline-months + `Compact*Leaf` + `ParentJournalLightbox` **unreachable dead code**; share (`ShareMomentButton`) wired only in dead branch → live-viewer share reachability UNKNOWN |
| 3 | Family (guardian) | `/parent/family` | ParentLayout | `FamilyArchiveNavigation` + `FamilyCardComposer` + inline member mgmt + `InviteDialog` | `get_family_space` → spaces[] | `create_family_space`, `mint/revoke_family_invitation`, `remove_family_member`, (+card via composer/archive) | Guardian | Living Archive **+** family administration | Composite surface: archive + create + members + pending-invites + dialogs on one page; **two create affordances** (archive `onCreate` + standalone "Tạo kỷ niệm"); management shares page with memory stream |
| 4 | Family (member) | `/family` (`family.tsx`) | **own standalone shell** (forest/cream, `max-w-3xl`, own header+sign-out) | `FamilyArchiveNavigation` + `FamilyCardComposer` + **read-only** member list | `get_family_space` | card via composer/archive only | Non-guardian member | Living Archive for invited relatives | Same FMN content as #3 in a **different shell/width**, member list **read-only** (no invite/remove), different empty copy → "separate products" split (see A3/A4) |
| 5 | Memory Room | `/family/memory/$cardId` (`family_.memory.$cardId.tsx`) | **own cream full-screen** (no parent nav) | `FamilyMemoryRoom` → `CardDetail` (`memoryRoomShared`) | `get_family_card` (`CANONICAL` D305 direct-entry) + `get_family_card_engagement` + `get_card_preserve_context` + `get_family_space_role` | edit/archive card, ack, contribute (text/voice), hide/unhide, preserve/reverse | Space member (backend-gated) | Single memory detail (route-backed, direct-entry) | Header order **metadata-first** (title→creator→date→source→people→media) — inverse of stream card; opening from `/parent/family` exits amber shell to bare cream Room |
| 6 | Consent | `/parent/consent` | ParentLayout | inline (4+1 grouped Switch cards) | `consents` table (direct `select`) | **direct table** `insert`/`update` on `consents` (RLS-gated, no RPC) | Parent | Per-child privacy toggles (9 consent types) | Only sensitive write in parent portal done via **direct table write** (not RPC/Edge) — architectural inconsistency; not in nav |
| 7 | Settings | `/parent/settings` | ParentLayout | inline (4 CardLinks + child roster + PasswordCard) | `useParentChild` (roster) | `supabase.auth.updateUser({password})` | Parent | Account hub → consent/kid/discovery/support | Hub for the 3 non-nav surfaces; Discovery labelled **"Nhìn lại"** here but page H1 is "✨ Bản Khám Phá Nghệ Thuật" (naming split) |
| 8 | Kid access | `/parent/kid` | ParentLayout | inline (enable/window/PIN/devices) | `kid_access`, `kid_devices` (direct select) + realtime `kid_pair:{id}` | `kid_update_access`, `kid_set_pin`, `kid_create_pairing_code`, `kid_revoke_device` | Parent | Configure child PIN/device/time-window access | **Fully built** (contradicts CANONICAL "reserved"); not in nav; PIN entry via `InputOTP` |
| 9 | Discovery ("Nhìn lại") | `/parent/discovery` | ParentLayout | `ReadinessPanel`/`CapsuleCard`/`CapsuleDetail` (`features/discovery/*`) | `get_child_evidence_readiness`, `list_discovery_capsules`, `get_discovery_capsule` | `generate_discovery_capsule` | Parent | "Art Discovery Capsule" retrospective insights (V98C) | **Own child-selector** (re-fetches `child_parents`, ignores `ParentChildProvider`, non-persisted) → selector inconsistency; concept overlaps Journey/"Nhìn lại"; not in nav |

## 3. Cross-surface / secondary surfaces reached from parent

`OBSERVED_SOURCE` — Not parent-owned but reached from parent chrome:
- **`/portal/notifications`** — Bell target; **neutral `/portal` shell** (not amber). Cross-shell jump.
- **`/portal/support`** — reached from Settings, Home empty state, journal empty state. Neutral shell.
- **`/family-invite#t={token}`** — invite acceptance (public); token in URL **fragment** (not query). One-time, 7-day.
- **`/share/$token`** — public share-link consumption (from journal `ShareMomentButton`, currently dead-branch only).
- **`/kid`** (public) — child PIN entry / device pairing target for `/parent/kid`.

## 4. Composer / dialog / sheet inventory (entry surfaces, no submit in this audit)

`OBSERVED_SOURCE`:
- **`ParentMemoryComposer`** (Dialog) — Home + Journey "Ghi lại" / edit. (Not opened/submitted in audit.)
- **`FamilyCardComposer`** (Dialog) — `/family` + `/parent/family` "Tạo kỷ niệm".
- **`InviteDialog`** (Dialog, `/parent/family`) — mint invite → shows one-time link.
- **Remove-member / Revoke-invite** (AlertDialog, `/parent/family`).
- **Memory Room dialogs** (`memoryRoomShared`): edit card (Dialog), archive (AlertDialog), `WriteContributionDialog`/`RecordContributionDialog`/`EditContributionDialog` (Dialog), withdraw (AlertDialog), Preserve picker (Dialog) + confirm/reverse (AlertDialog).
- **Archived section** (`ArchivedCardsSection`) — collapsible chip → list → restore (AlertDialog).
- **Timeline Sheet** (`FamilyArchiveNavigation`, mobile) — left `Sheet` for the year/month index.

## 5. Media handling per surface

`OBSERVED_SOURCE`:
- **Stream card `MemoryItem`:** lead media in reserved **`aspect-ratio 4/3`** frame, `object-contain` (no crop); up to 2 glimpse thumbnails (64×64); audio-only → title + `AudioPlayer`; text-only → letter-paper card.
- **Memory Room `MediaTile`:** images in **`aspect-video` (16:9)** reserved frame (`object-cover`); video `<video controls preload=metadata>` in black-bordered frame (intrinsic height); audio → `AudioPlayer` bar; 0-media → letter-paper block (`min-h-[220px]`).
- **Journey (live viewer):** signed media via `useJourneySigning` (TTL cache + IntersectionObserver lazy-sign per RULES D224). Denial states map to warm copy ("Đang chờ ba mẹ đồng ý…") with "Vì sao?"→consent link.
- All private media signed on-demand via `get_signed_media_url` Edge; no raw Bunny URLs; consent re-checked at sign time.
