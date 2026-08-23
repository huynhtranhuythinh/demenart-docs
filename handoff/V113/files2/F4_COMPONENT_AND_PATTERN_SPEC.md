# F4 — COMPONENT & PATTERN SPEC
**V113F** · One component system across every Parent Portal surface. Presentation contracts only — no code, no route/permission merge.

**Global rule — do NOT merge governance predicates.** `canEdit`, `canArchive`, `can_moderate` (and `create_card`, `invite_member`) stay **separate props/branches**. A generic `canManage` is prohibited (D293). Every affordance mirrors its backend authorization branch-for-branch.

**Per-component fields:** Anatomy · Variants · Responsive · States · Data deps · Governance deps · Reuse scope · Prohibited misuse.

---

## 1. NAVIGATION & SHELL

### ParentIdentityRail (desktop)
- **Anatomy:** official logo (light treatment) → family identity "Gia đình {name}" (serif) + child subtitle → **ChildSwitcher** → 4 primary items (Hôm nay/Hành trình/Gia đình/Thế giới của con) → divider → utilities (Quyền riêng tư/Cài đặt/Hỗ trợ) → account footer (avatar + "Ba {name}" + menu chevron) → sparse gold botanical.
- **Variants:** guardian; (member uses standalone shell, see FamilyExperienceShell).
- **Responsive:** desktop ≥1024 only; hidden on mobile (replaced by MobileParentHeader + ParentBottomNav).
- **States:** active item = ivory pill + gold marker; hover; focus-visible ring.
- **Data:** `ParentChildProvider`; role for landing.
- **Governance:** utilities are navigation only; no authority.
- **Reuse:** all `/parent/*` desktop.
- **Prohibited:** adding a 5th primary; putting utilities in the primary group; substituting the logo; permanent mascot.

### MobileParentHeader
- **Anatomy:** sticky top bar: page title (serif, truncating) + notification bell; on some screens a compact profile/menu affordance.
- **Responsive:** ≤400 only; respects top safe-area.
- **States:** bell dot on unread.
- **Prohibited:** stacking multiple CTAs in the header; hiding the title behind media.

### ParentBottomNav
- **Anatomy:** **exactly 4** items — Hôm nay · Hành trình · Gia đình · **Của con** — icon + label; active = gold fill/underline.
- **Responsive:** ≤400; fixed bottom; reserves safe-area inset (see F5).
- **States:** active/inactive/focus.
- **Governance:** none.
- **Prohibited:** 5 items; "Cài đặt" in the bar (it is a utility); desktop long label "Thế giới của con" on mobile (**must** read "Của con"); overlaying content without safe-area reservation.

### FamilyExperienceShell(context)
- **Anatomy:** one shell primitive rendering baseline family visual language; prop `context: 'guardian' | 'member'`.
- **Variants:** `guardian` → mounts inside Parent shell (baseline emerald rail); `member` → standalone baseline shell (no parent bottom-nav).
- **Governance:** context selects chrome + affordance gating; **routes/authz unchanged, never merged.**
- **Reuse:** `/parent/family` and `/family`.
- **Prohibited:** merging the two authorization contexts; leaking parent-only nav into member context.

---

## 2. IDENTITY

### FamilyIdentityHeader
- **Anatomy:** space name (serif h1) + subtitle + member/stat chips + child chips + avatar cluster.
- **Responsive:** desktop full row; mobile stacked.
- **Data:** `get_family_space`.
- **Prohibited:** leading with a metric ("286 ký ức") above the name.

### ChildSwitcher
- **Anatomy:** child avatar/monogram + name + age; single shared control writing through `ParentChildProvider` (persisted `selectedChildId`).
- **Variants:** rail-vertical (desktop), chip-row (mobile/Home), compact.
- **Responsive:** visible only when `children.length > 1`.
- **States:** selected = gold ring + raised chip; hover; focus.
- **Data:** `ParentChildProvider` (children, selectedChildId).
- **Governance:** none.
- **Reuse:** Home, Journey, Family, Kid, **and Discovery** (Discovery must drop its private selector and bind here — B4 §3).
- **Prohibited:** a route-local child selector that ignores the persisted context (the Discovery divergence — must be reconciled); no child avatar field exists → textual/monogram fallback, no schema change.

### PageTitle
- **Anatomy:** serif display title + optional date/age subtitle + optional inline botanical sprig.
- **Prohibited:** sans-serif title; per-route font change.

---

## 3. MEMORY PRESENTATION

### MemoryHero
- **Anatomy:** large media frame (16:9 / 4:3) + serif blurb + **one** primary CTA + optional quiet secondary link.
- **Variants:** Home hero; Journey chapter hero (adds gold "CHƯƠNG MỚI BẮT ĐẦU" pill + 3 micro-metrics).
- **Responsive:** desktop side-by-side; mobile media-over-text stacked.
- **Data:** newest media-bearing item + `get_signed_media_url`.
- **Prohibited:** more than one primary CTA; KPI tiles; count above media.

### MemoryCard (= `MemoryItem`, KEEP→REFINE)
- **Anatomy:** reserved media frame (4:3, composition-driven: media / audio-waveform / text-only) + title + short body + quiet footer (date · contributor · bookmark) + kebab (governed).
- **Variants:** media / audio-only / text-only / video (duration badge) / family-preserved.
- **Responsive:** grid on desktop, single-column/rail on mobile.
- **States:** loading (media placeholder), error, archived badge.
- **Data:** journal/family payload; signed media.
- **Governance:** kebab actions gated (edit/archive per predicate) — never a generic "manage".
- **Reuse:** Journey timeline, Family periods, Home strip.
- **Prohibited:** collapsing text-only/audio-only into a broken empty frame; metric line above the card.

### JourneyChapter / JourneyMemoryRail
- **JourneyChapter:** hero chapter block (media + gold pill + serif title + blurb + metrics). **JourneyMemoryRail:** horizontal timeline of MemoryCards with domain glyphs + window markers.
- **Governance:** edit/archive only if `parent_memory && mine`.
- **Prohibited:** turning the rail into a dashboard grid; inserting Discovery inline into the stable stage (keep as header/rail entry, D224-B).

---

## 4. FAMILY ARCHIVE

### FamilySectionSwitch
- **Anatomy:** two-tab switch "Ký ức | Thành viên", query-backed `?section=` (mirrors `?y&m`).
- **States:** active/inactive; direct-entry addressable.
- **Governance:** member sees both tabs; Thành viên read-only by role.
- **Prohibited:** one continuous page (archive→members must be separated); nested route restructure (out of scope).

### ArchivePeriodIndex (= `FamilyArchiveNavigation`, KEEP)
- **Anatomy:** desktop timeline rail (year/month, keyset window, `?y&m`); mobile Sheet + year chips.
- **Reuse:** both contexts, verbatim (V112C spine).
- **Prohibited:** re-implementing per host; restyle-only later.

### FamilyMembers / MemberRow / InviteRow (EXTRACT)
- **FamilyMembers:** roster component, one implementation, both contexts, affordances **role-gated**.
- **MemberRow:** avatar + name + role(VN) + relation + status.
- **InviteRow:** invitee + relation + expiry + Nhắc lại/Hủy (guardian only).
- **Governance:** invite/remove/pending = `invite_member`/guardian; member = read-only; `guardian_member_protected`.
- **Prohibited:** English role words in UI; showing management controls to members; merging invite/remove into one control without separate predicates.

---

## 5. MEMORY ROOM

### MemoryRoomMedia
- **Anatomy:** large dignified player (video/audio/image); controls; fullscreen.
- **States:** loading placeholder (no shift), media-unavailable (retry), consent-gated.
- **Prohibited:** shrinking media below hero prominence; autoplay.

### MemoryProvenance
- **Anatomy:** "Nguồn gốc ký ức" rows — loại / ghi lại bởi / thời gian / địa điểm / mã ký ức + creator chip.
- **Data:** `family_display_name` for creator.
- **Prohibited:** leaking existence before auth resolves (D305).

### FamilyVoices
- **Anatomy:** "Tiếng nói gia đình (n)" — contributions (text/audio-waveform) + reactions (💛 count) + per-item kebab.
- **Governance (branch-for-branch):** own contribution → Sửa/Rút lại (`mine`); guardian → Ẩn/Hiện (`can_moderate`); react/contribute per capability.
- **Aux (D298):** load error → quiet notice + retry, control present-not-hidden.
- **Prohibited:** fusing author-edit and moderator-hide.

### PreservePanel
- **Anatomy:** "Giữ vào Hành trình" — status (Đã lưu vào Hành trình của {child} + date + who) + child chips + toggle "Gỡ khỏi Hành trình".
- **Variants:** none / preserved(single) / preserved(n of m) / reversed / orphaned.
- **Governance:** guardian preserve path only; `preserve_/reverse_preserve`.
- **Aux (D298):** read error → **render zone anyway** with quiet notice + retry.
- **Prohibited:** hiding the panel on error; showing to non-guardians as actionable.

### LifecycleMenu (= "Quản trị ký ức")
- **Anatomy:** quiet bottom zone: Sửa thông tin · Lưu trữ · Xuất bản riêng · Xóa ký ức (destructive).
- **Governance (SEPARATE):** Sửa = creator; Lưu trữ = creator **or** guardian; Xóa = per predicate. Distinct controls.
- **Prohibited:** a single "Quản lý" button; destructive control styled as primary.

---

## 6. KID GATEWAY

### KidGatewayHero
- **Anatomy:** large illustrative gateway media + serif "Thế giới của {child}" + subtitle + "Đổi trẻ".
- **Prohibited:** rendering a Kid dashboard or a development report; more than one primary action.

### KidSafetyStatus
- **Anatomy:** status rows/grid — mode ("Khám phá tự do"), paired device, time-today, PIN state, play-window; three quiet panels (Giới hạn & Thiết bị / Nội dung phù hợp / Hoạt động hôm nay); reassurance footer.
- **Data:** `kid_access`/`kid_devices` reads.
- **Governance:** PIN/device/window controls at **secondary depth**; verdicts `{ok,reason}` → toast; authority unchanged.
- **Prohibited:** promoting controls above the single "Mở thế giới của {child}" action.

---

## 7. UTILITY & FORM

### PrivacyGroup
- **Anatomy:** child selector + "Ai có thể xem?" audience rows (allow/limit/deny) + "Gia đình gần" count.
- **Governance:** MIN-consent; **write path unchanged** (F9 parked 🔒).
- **Prohibited:** changing consent semantics/write path; hiding "Vì sao?" entry.

### SettingsGroup
- **Anatomy:** grouped rows (Tài khoản/Bảo mật/Hỗ trợ/Tài khoản) + destructive quiet zone (Xuất dữ liệu, Xóa tài khoản).
- **Prohibited:** the app entering passwords/credentials on the user's behalf (platform rule — user performs those); destructive as primary.

### Composer (ParentMemoryComposer / FamilyCardComposer)
- **Anatomy:** title/story fields + attach row (Ảnh/Video · Giọng nói · Viết chữ) + audience selector + one primary submit ("Tiếp tục"/"Gửi").
- **Variants:** parent memory; family card; text contribution.
- **Prohibited:** duplicate create CTAs (collapse to one within "Ký ức").

### VoiceRecorder
- **Anatomy:** record button + timer + 2-min cap indicator + submit.
- **States:** idle/recording/review; reduced-motion respects no pulsing.
- **Prohibited:** autoplay of recordings.

### MediaPicker
- **Anatomy:** multi-select grid of media + "Thêm mở tả…" + audience + submit.
- **Data:** signed media.
- **Prohibited:** submitting a form reached via untrusted link (platform privacy rule).

### TruthStateBlock (= `FamilyStateBlock` grammar)
- **Anatomy:** icon + heading + supporting line + one action; one variant per state.
- **Variants:** loading · empty · error · denied · archived · consent-waiting · media-unavailable · consent-needed · consent-granted.
- **Governance:** error ≠ denied ≠ empty are **visually distinct**; Memory Room denied = generic string (D305); aux fail-closed-and-present (D298).
- **Reuse:** every surface, both sections, both contexts.
- **Prohibited:** collapsing error/denied to empty (F01/E4); silent-empty.

---

## 8. Illustration & action patterns (cross-cutting)
- **Botanical:** low-contrast gold/sage sprigs, sparse, corner-anchored, non-interactive, never behind essential text, never on every card. Mascot never permanently visible on Parent surfaces.
- **Action hierarchy per surface:** exactly one primary; limited secondaries; lifecycle/admin in a quiet zone; no duplicate/competing CTAs.

## 9. Reuse-scope summary

| Component | Home | Journey | Family (G/M) | Room | Kid | Utility |
|---|---|---|---|---|---|---|
| ParentIdentityRail / BottomNav | ✅ | ✅ | ✅ (guardian) | ✅ | ✅ | ✅ |
| FamilyExperienceShell | — | — | ✅ both | — | — | — |
| ChildSwitcher | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ (consent) |
| MemoryHero / MemoryCard | ✅ | ✅ | ✅ | — | — | — |
| FamilySectionSwitch / ArchivePeriodIndex / FamilyMembers | — | — | ✅ | — | — | — |
| Memory Room set (Media/Provenance/Voices/Preserve/Lifecycle) | — | — | — | ✅ | — | — |
| KidGatewayHero / KidSafetyStatus | — | — | — | — | ✅ | — |
| Composer / VoiceRecorder / MediaPicker | ✅ create | ✅ create | ✅ create | ✅ contribute | — | — |
| TruthStateBlock | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |

## 10. Component readiness

| Readiness | Components |
|---|---|
| **Ready (L2/L3 anchored)** | Rail, BottomNav, ChildSwitcher, PageTitle, MemoryHero, MemoryCard, JourneyChapter/Rail, FamilyIdentityHeader, ArchivePeriodIndex, all Memory Room components, KidGatewayHero, KidSafetyStatus, TruthStateBlock (baseline grammar) |
| **Needs baseline restyle (L4 coverage only)** | FamilyMembers/MemberRow/InviteRow, PrivacyGroup, SettingsGroup, Composer, VoiceRecorder, MediaPicker, TruthStateBlock *state visuals* |
| **Evidence debt (no source)** | Notifications/Support list, invitation expired/revoked treatment, audio-only/text-only Room compositions (no prod card) |
