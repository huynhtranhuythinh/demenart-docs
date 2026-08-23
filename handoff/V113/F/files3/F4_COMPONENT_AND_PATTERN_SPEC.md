# F4 — COMPONENT & PATTERN SPEC
**V113F** · One component system across every Parent Portal surface. Presentation contracts only — no code, no route/permission merge.

**Global rule — do NOT merge governance predicates.** `canEdit`, `canArchive`, `can_moderate` (and `create_card`, `invite_member`) stay **separate props/branches**. A generic `canManage` is prohibited (D293). Every affordance mirrors its backend authorization branch-for-branch.

**Per-component fields:** Anatomy · Variants · Responsive · States · Data deps · Governance deps · Reuse scope · Prohibited misuse.

**V113F FINAL MERGE — 2026-07-17 GMT+7:** the components previously at L4 coverage are now **Ready · L3-anchored** against Correction Packs 1–4 (F1 §2b). Only approved presentation contracts were incorporated; no backend prop is inferred from mockup-only ARIA/presentation states.

**V113F-C locked (do not reopen):** ParentBottomNav mobile 4th label = **"Của con"** / desktop rail 4th = **"Thế giới của con"** / landing = **"Hôm nay"** (no "Trang chủ"). MemberRow role field uses VN grammar (Phụ huynh chính / Phụ huynh / Người thân + relationship Ba/Mẹ/Ông/Bà/Cô/Chú; status Hoạt động / Đang chờ / Đã gỡ) — English "Guardian" prohibited in UI; backend names unchanged. Any count in MemoryCard/FamilyIdentityHeader/JourneyChapter is quiet metadata only — never a KPI card, never above media. Tablet chrome = top bar + navigation drawer (no icon rail).

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

### FamilyMembers / MemberRow / InviteRow (EXTRACT) — **Ready · L3-anchored (Correction Pack 1)**
- **FamilyMembers:** roster component, one implementation, both contexts, affordances **role-gated**. Editorial roster (not an admin table); counts as quiet metadata ("5 thành viên · 1 lời mời đang chờ" — pending invites never counted as members); one primary CTA "Mời thành viên" (guardian only).
- **MemberRow:** warm monogram + serif name + role(VN) + relation + status "Hoạt động"; protected guardian row exposes **no** invalid remove action (quiet lock hint instead of kebab).
- **InviteRow:** dashed treatment, invitee + relation + sent date + status "Đang chờ" + Gửi lại / Thu hồi (guardian only).
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

### PrivacyGroup — **Ready · L3-anchored (Correction Pack 2)**
- **Anatomy:** semantic ChildSwitcher (buttons + `aria-pressed`) + the **9 existing consent types** rendered as 4 editorial groups; consent row = plain-language title + one-line description + state label ("Đang cho phép" / "Chưa cho phép") + accessible switch (`role="switch"`, labelled, ≥44px, champagne focus) + inline feedback in-row ("Đã lưu" / "Chưa lưu thay đổi · Thử lại" with icon + text); MIN-consent note (sage) inside the group-moment group; privacy_ack rendered as confirmation (check + date), never as marketing consent.
- **Variants:** default row · sensitive optional row (champagne/sage tint, never red) · acknowledgment row.
- **Responsive:** desktop two-column (groups + two quiet explanatory cards); mobile single column, all 9 rows discoverable.
- **States:** enabled · disabled · saved-inline · write-error-inline (UI shows **last persisted value** after a failed write — no optimistic ON) · `family_space_display` illustrated off (default-off semantics).
- **Data deps:** per-child consents.
- **Governance:** MIN-consent; **write path unchanged** (F9 parked 🔒); per-toggle direct save — **no page-level Save**.
- **Prohibited:** changing consent semantics/write path; new consent type or audience; exposing internal keys; page-level/sticky Save; red styling on optional consents; hiding "Vì sao?" entry.

### SettingsGroup — **Ready · L3-anchored (Correction Pack 3)**
- **Anatomy:** utility hub over the existing contract only — **account identity summary** (read-only: name, masked email, role VN, status "Đang hoạt động") · **PasswordCard** (fields **Mật khẩu mới + Xác nhận mật khẩu mới** only, no current-password field, show/hide toggle with accessible name + `aria-pressed`, `autocomplete="new-password"`, no prefilled values, quiet requirements copy, one inline success **or** validation state) · **read-only child roster** (quiet ≥44px links to Quyền riêng tư / Thế giới của con) · utility link rows to existing surfaces · **quiet session zone "Đăng xuất"** (restrained destructive label, separated, never primary).
- **Variants:** desktop two-column · mobile grouped rows (order: Tài khoản → Các bé → Dành cho gia đình → Bảo mật inline-expand → Trợ giúp → Đăng xuất).
- **States:** password success ("Mật khẩu đã được cập nhật", `role="status"`, inputs cleared post-submit) or validation error connected to the field — never both at once.
- **Governance:** password update preserves the existing auth contract.
- **Prohibited:** the app entering passwords/credentials on the user's behalf (platform rule — user performs those); prefilled password values; destructive as primary; **inventing 2FA, sign-out-all-devices, phone editing, photo upload, data export, account deletion, billing or notification preferences** (not in current contract); a global Save button; a second filled CTA.

### Composer (ParentMemoryComposer / FamilyCardComposer) — **Ready · L3-anchored (Correction Pack 4)**
- **Anatomy:** title/story fields + content-kind chips (Ảnh/Video · Giọng nói · Viết chữ — quiet outlined selection, not competing primaries) + audience section + one primary submit. Parent: "Ghi lại một điều về {child}" → audience = existing private contexts only (Chỉ phụ huynh / Gia đình được mời), primary **"Tiếp tục"**, quiet "Hủy". Family: "Gửi một ký ức" → Tiêu đề ký ức · Câu chuyện · Thời điểm · Người liên quan; audience fixed **"Gia đình được mời"**; primary **"Gửi ký ức"**, quiet "Để sau".
- **Variants:** parent memory (Parent shell) · family card (guardian, Parent shell allowed) · **family contribution entry** ("Thêm tiếng nói vào ký ức này" — Viết vài dòng / Gửi giọng nói; member = standalone Family shell, no Parent bottom nav, no guardian utilities; entry stays secondary to the memory, never a comment feed).
- **States:** create action appears only when `create_card` allowed; unauthorized controls are not rendered.
- **Governance:** `create_card`, `canEdit`, `canArchive`, `can_moderate`, `invite_member` remain separate; member context never inherits guardian-only administrative controls.
- **Prohibited:** duplicate create CTAs; "Tiếp tục" and "Gửi" together on one step; public/social audience; new audience or consent type.

### VoiceRecorder — **Ready · L3-anchored (Correction Pack 4)**
- **Anatomy:** sheet with context title/line + central record control (≥44px, accessible name) + timer + cap note + review player + one primary submit.
- **States (canonical, three):** **Idle** ("Chạm để bắt đầu" · "Tối đa 2 phút") · **Recording** (elapsed timer, cap "Tối đa 02:00", clear "Dừng ghi", quiet "Hủy"; any waveform is static/decorative, never fake live data) · **Review** (duration, semantic play control — **no autoplay** — quiet "Ghi lại" / "Xóa bản ghi", one filled primary "Gửi giọng nói"). Recording and final submit are never competing primaries in one state. Reduced-motion: no pulsing ring.
- **A11y:** record/stop/play/submit ≥44px with accessible names; state communicated by text, not color alone.
- **Prohibited:** autoplay of recordings; fake progress percentage; exceeding/removing the 2-minute cap indicator.

### MediaPicker — **Ready · L3-anchored (Correction Pack 4)**
- **Anatomy:** multi-select grid (reserved aspect-ratio frames — no layout shift) + "Thêm mô tả…" field + audience summary ("Gia đình được mời") + one primary "Tiếp tục" + quiet "Quay lại".
- **States:** selected = border + check badge **+ `aria-pressed="true"`** (never color alone); unselected = `aria-pressed="false"`; **unavailable thumbnail stays present** (semantic `role="group"` container, "Chưa thể mở" + ≥44px retry with accessible name) — never removed silently, never selectable.
- **Data:** signed media.
- **Prohibited:** public share; fake upload percentage; autoplay video; real child media in mockups; submitting a form reached via untrusted link (platform privacy rule).

### TruthStateBlock (= `FamilyStateBlock` grammar) — **Ready · L3-anchored (Correction Pack 4, incl. state visuals)**
- **Anatomy:** icon + serif heading + supporting line + zero-or-one action; one variant per state; titles/descriptions carry stable IDs wired via `aria-labelledby`/`aria-describedby`.
- **Variants (nine, visually + semantically distinct):** loading (sage skeleton, no percentage; `role="status"` polite + `aria-busy`) · empty (warm invitational; create action only in create-authorized context) · error (restrained error accent + retry; `role="alert"`) · denied (denied-brown protected tone + shield/lock; **generic non-enumerating copy**; `role="alert"`) · archived (quiet metadata tone + archive icon; ≠ denied) · consent-waiting (champagne/sage informational; ≠ consent-needed; polite status) · media-unavailable (reserved media frame + retry; `role="alert"`) · consent-needed (protective champagne + guardian action; polite status) · consent-granted (success green + check + text; never promises universal display; polite status).
- **Governance:** error ≠ denied ≠ empty are **visually distinct**; Memory Room denied = generic string (D305); aux fail-closed-and-present (D298).
- **Reuse:** every surface, both sections, both contexts.
- **Prohibited:** collapsing error/denied to empty (F01/E4); silent-empty; one generic alert card for all states; redundant `role="alert"` + `aria-live` on the same panel.

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
| **Ready (L2/L3 anchored)** | Rail, BottomNav, ChildSwitcher, PageTitle, MemoryHero, MemoryCard, JourneyChapter/Rail, FamilyIdentityHeader, ArchivePeriodIndex, all Memory Room components, KidGatewayHero, KidSafetyStatus, TruthStateBlock (baseline grammar) — **plus, since the 2026-07-17 final merge (Ready · L3-anchored):** FamilyMembers/MemberRow/InviteRow (Pack 1), PrivacyGroup + consent row/switch grammar (Pack 2), SettingsGroup + account identity summary + read-only child roster + PasswordCard (Pack 3), ParentMemoryComposer/FamilyCardComposer + family contribution entry, VoiceRecorder, MediaPicker, TruthStateBlock *state visuals* (Pack 4) |
| **Needs baseline restyle (L4 coverage only)** | *(none — emptied by the 2026-07-17 final merge)* |
| **Evidence debt (no source)** | Notifications/Support list, invitation expired/revoked treatment, audio-only/text-only Room compositions (no prod card) |
