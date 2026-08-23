# F3 — SCREEN CANONICAL MATRIX
**V113F** · Every Parent Portal screen + major state, mapped to one visual system. Presentation/composition only — routes, authority, RPC/RLS/consent unchanged (B1–B5).

**V113F FINAL MERGE — 2026-07-17 GMT+7:** Correction Packs 1–4 approved and promoted L4 → L3 (see F1 §2b). Entries below reference the packs as canonical; gaps they covered are RESOLVED.

**Legend for "Gap":** ✅ approved L2/L3 source · ⚠ L4 coverage only (HISTORICAL definition: restyle-to-baseline required — after the 2026-07-17 final merge no Pack-covered surface remains at ⚠) · 🔴 no approved source (evidence debt).

**V113F-C locked (do not reopen):** landing = **"Hôm nay"** (no "Trang chủ"); mobile 4th nav = **"Của con"**, desktop 4th = **"Thế giới của con"**; VN role grammar in all roster/member/status copy (no English "Guardian"; use Phụ huynh chính / Người thân / Hoạt động / Đang chờ / Đã gỡ); counts render only as quiet metadata after identity/chapter labels — never before media, never as KPI cards.

---

## A. PRIMARY SCREENS

### A1 · Hôm nay — `/parent`
- **Actor:** parent with ≥1 linked child.
- **Purpose:** de-dashboarded landing; identity + one real memory + one action.
- **Desktop:** emerald rail (logo, family identity "Gia đình Hùng", ChildSwitcher, 4 primaries, utilities, account footer) + ivory content: display title → hero memory (media + serif blurb + one CTA) → two quiet context cards (upcoming / next-action) → "Ký ức gần đây" thumbnail strip + quiet "Gia đình luôn ở đây"/family-signal card + "Tạo mới".
- **Mobile:** sticky header (title, bell) → ChildSwitcher chips → hero memory → CTA → two stacked context cards → recent strip → 4-item bottom nav.
- **Primary action:** "Xem ký ức này" (open hero in Journey).
- **Secondary:** "An vừa có thêm điều mới", "Xem Hành trình của An", "Ghi lại giọng kể", "Xem tất cả", family-signal link.
- **Data:** `ParentChildProvider` + `get_child_journal` (+ `get_signed_media_url`). No ranking; newest media-bearing item; family signal = preserved `source='family'` entries.
- **Empty:** no child → Support link + "Chưa có hồ sơ con nào được liên kết"; child but no data → warm "Bắt đầu hành trình…" + record-first action.
- **Error:** child fetch error → **quiet distinct error card** (REFINE from silent-empty). Journal error → single quiet error card.
- **Denied:** n/a (own children).
- **Governance controls:** none (identity/preview). **No KPI block.**
- **Canonical ref:** **Image 2 (L3).** ✅ — Image 6 rejected.
- **Gap:** none; confirm mobile 4th label "Của con".

### A2 · Hành trình — `/parent/journal`
- **Actor:** parent of child.
- **Purpose:** content-first art journal; hosts "Nhìn lại một chặng".
- **Desktop:** rail + ivory: display title "Hành trình của {child}" + "Ghi lại một điều về {child}" → hero chapter (media + "CHƯƠNG MỚI BẮT ĐẦU" gold pill + serif chapter title + blurb + 3 gold micro-metrics) + side "Nhìn lại một chặng" reflection card ("Xem chi tiết") → "Hành trình theo thời gian" timeline of MemoryCards with domain glyphs → family-preserved full-width row.
- **Mobile:** header + ChildSwitcher → hero chapter → reflection card → "Kỷ niệm gần đây" horizontal rail → bottom nav.
- **Primary action:** "Ghi lại một điều về {child}".
- **Secondary:** "Xem chi tiết" (reflection → Discovery, scoped by shared ChildSwitcher), per-item open.
- **Data:** `get_child_journal`; Discovery via `*_discovery_capsule` (route/`?capsule` preserved).
- **Empty:** no journey data → warm empty; reflection hidden until a capsule exists.
- **Error:** quiet retry.
- **Denied:** media denial → per-reason warm copy + "Vì sao?" → consent.
- **Governance:** edit/archive only if `parent_memory && mine`.
- **Canonical ref:** **Image 4 (L2 MASTER).** ✅
- **Gap:** confirm Discovery capsule composition is deterministic before "reflection" copy implies analysis (B4 §8, carried).

### A3 · Gia đình — Family Archive — `/parent/family` (guardian) · `/family` (member)
- **Actor:** guardian (amber→baseline shell) / non-guardian member (cream→baseline standalone). **Two routes, two authz contexts — never merged.**
- **Purpose:** the one Family Experience System; "Ký ức | Thành viên".
- **Desktop:** rail/shell + ivory: serif family name "Gia đình Hùng" + subtitle + one create CTA "Gửi một ký ức" → member/stat chips → **tabs "Ký ức | Thành viên"** (query-backed `?section=`) → **Ký ức:** timeline index (`?y&m`) + period MemoryCards + side "Ký ức đã lưu" / "Ký ức đã lưu trữ" rails.
- **Mobile:** header + ChildSwitcher chips → tabs → year/month filter → period grid → bottom nav.
- **Primary action:** one create CTA (role-gated `create_card`).
- **Secondary:** open card → Memory Room; save/archived rails; period filter.
- **Data:** `get_family_space` / role; archive index/window; `family_card_effective_access` (D284).
- **Empty/Error/Denied:** distinct via `FamilyStateBlock` (D298) in both contexts and both sections.
- **Governance:** member sees roster **read-only**; guardian manages. Affordances mirror backend branch-for-branch (D293).
- **Canonical ref:** **Image 3 (L3).** ✅ (Ký ức tab). **Thành viên** section → see A7 (⚠).
- **Gap:** restyle "{n} ký ức" so a metric never precedes memories.

### A4 · Thế giới của con — `/parent/kid`
- **Actor:** parent of child (Parent-facing gateway — **not** a Kid dashboard / dev report).
- **Purpose:** preview child world + one action + safety status; PIN/device/window controls at depth.
- **Desktop:** rail + ivory: serif "Thế giới của {child}" + "Đổi trẻ" → large illustrative gateway media + side stack: **one** primary "Mở thế giới của {child}" → status rows (mode, paired device, time-today, PIN on, play-window) → three quiet panels (Giới hạn & Thiết bị / Nội dung phù hợp / Hoạt động hôm nay) → reassurance footer.
- **Mobile:** header + ChildSwitcher → gateway media → primary action → 2×2 status grid → collapsible control rows → bottom nav.
- **Primary action:** "Mở thế giới của {child}".
- **Secondary (at depth):** enable/PIN/pair/window controls.
- **Data:** `kid_access` / `kid_devices` reads; `kid_update_access`/`kid_set_pin`/`kid_create_pairing_code`/`kid_revoke_device`.
- **Empty:** disabled → enable-first framing. **Error/Denied:** `{ok,reason}` verdicts (`not_enabled`, `invalid_pin_format`) → toast.
- **Governance:** safety status surfaced; authority unchanged; controls at secondary depth.
- **Canonical ref:** **Image 5 (L3).** ✅
- **Gap:** align **mobile** bottom-nav 4th label to "Của con" (Image 5 mobile shows long label).

---

## B. DEEP / SHARED SCREENS

### B1 · Memory Room — `/family/memory/:cardId`
- **Actor:** EA-authorized space member (guardian or member) via direct-entry auth.
- **Purpose:** single memory, content-first.
- **Order (fixed):** ① return context ("Quay lại Ký ức · Tháng…") → ② media/memory (large player) → ③ serif title + story → ④ provenance (creator/date/location/type/mã ký ức) → ⑤ family voices (contributions, reactions, audio) → ⑥ Preserve ("Giữ vào Hành trình") → ⑦ quiet lifecycle ("Quản trị ký ức": Sửa / Lưu trữ / Xuất bản riêng / Xóa).
- **Desktop:** rail + two-column (media+story+voices left; Preserve + provenance + lifecycle right).
- **Mobile:** single scroll: return → media → title/story → collapsible sections (voices, preserve, provenance, admin) → bottom nav.
- **Primary action:** contextual (Preserve for guardian; contribute/react per capability).
- **Governance (branch-for-branch, D293):** `Sửa` = creator only; `Lưu trữ` = creator **or** guardian; `Ẩn/Hiện` = guardian moderator; own-contribution `Sửa/Rút lại` = author. **Never fuse into "Quản lý".**
- **Denied:** not-found = not-authorized = **one** generic string (D305); no enumeration; return-context must not leak existence before auth resolves.
- **Aux error (D298):** engagement/preserve read error → quiet notice + retry; control **present, not hidden**.
- **Canonical ref:** **Image 7 (L3).** ✅

---

## C. UTILITY SCREENS

### C1 · Quyền riêng tư — `/parent/consent`  ✅
- **Actor:** parent of child. **Purpose:** per-child consent choices over the **9 existing consent types**, presented as 4 editorial groups (Trong hành trình của con · Gia đình và chia sẻ riêng tư · Nhà trường và Dế Mèn · Xác nhận quyền riêng tư). No internal keys shown; no new audience or consent type.
- **Desktop 1440:** rail (Quyền riêng tư active in utilities) → serif title "Quyền riêng tư của con" + supporting copy → semantic ChildSwitcher (button + `aria-pressed`) → two-column: consent groups (row = plain-language title + description + state label "Đang cho phép"/"Chưa cho phép" + accessible switch + inline "Đã lưu"/"Chưa lưu thay đổi · Thử lại") + two quiet explanatory cards (per-content privacy / family-space scope, quiet link "Xem thành viên gia đình").
- **Mobile 390:** emerald header "Quyền riêng tư" + child chips → single column, all 4 groups / 9 rows, sensitive rows champagne tint (non-red), MIN-consent note, inline feedback in the affected row; bottom nav = 4 items, none active (utility surface).
- **Primary action:** per-row toggle (**write path unchanged** — direct `consents` RLS, F9 parked 🔒). **No page-level Save / sticky Save bar.** Failed write shows last persisted value (no optimistic ON).
- **Empty/Denied:** not-linked → empty; write error → inline row feedback with retry.
- **Governance:** MIN-consent rule stated in-context; `family_space_display` default-off semantics; "Vì sao?" entry from Journey/media.
- **Canonical ref:** **Correction Pack 2 (L3).** ✅ Gap RESOLVED (final merge 2026-07-17).

### C2 · Cài đặt — `/parent/settings`  ✅
- **Actor:** parent. **Purpose:** account + utility hub over the **existing contract only**: read-only account identity, password update, read-only child roster, links to existing utility surfaces, sign out. **Utility, not primary nav.**
- **Desktop 1440:** rail (Cài đặt active in utilities) → serif "Cài đặt" + identity line "Ba Hùng · Phụ huynh chính" → main column: Tài khoản của bạn (read-only summary: name/masked email/role/Đang hoạt động) · Bảo mật (PasswordCard: **Mật khẩu mới + Xác nhận mật khẩu mới only**, show/hide with accessible name, `autocomplete="new-password"`, one inline success or validation state) · Các bé trong gia đình (read-only roster An/Khang + quiet links Quyền riêng tư / Thế giới của con) → supporting column: utility link cards (Quyền riêng tư `/parent/consent` · Thế giới của con `/parent/kid` · Nhìn lại một chặng `/parent/discovery` · Thông báo `/portal/notifications` · Hỗ trợ `/portal/support`) → quiet session zone **Đăng xuất** (restrained destructive label only).
- **Mobile 390:** header "Cài đặt" (context Ba Hùng · Phụ huynh chính) → order: Tài khoản → Các bé → Dành cho gia đình → Bảo mật (inline expand) → Trợ giúp → Đăng xuất; bottom nav = 4 items, none active; page scrolls fully.
- **Primary action:** exactly one filled CTA — **"Cập nhật mật khẩu"**. **Prohibited (platform rule): app never enters passwords/credentials on user's behalf — user performs those; no prefilled password values.**
- **Not present (not in current contract):** 2FA, sign-out other devices, phone editing, profile-photo upload, data export, account deletion, billing, notification preferences.
- **Canonical ref:** **Correction Pack 3 (L3).** ✅ Gap RESOLVED (final merge 2026-07-17).

### C3 · Thông báo — `/portal/notifications` / C4 · Hỗ trợ — `/portal/support`  🔴/⚠
- **Actor:** parent. **Utility.** No new notification functionality (🔒). Reachable via bell + account menu.
- **Canonical ref:** no dedicated approved mockup → 🔴 use baseline list grammar; **do not build features**.

---

## D. FAMILY-INTERNAL & MEMBERS

### D1 · Thành viên (section of Gia đình)  ✅
- **Actor:** guardian (manage) / member (read-only). **Purpose:** roster + roles + invites.
- **Desktop 1440:** family identity + tabs "Ký ức | Thành viên" (Thành viên active) → **editorial roster** (not an admin table): MemberRow = warm monogram + serif name + VN role grammar ("Phụ huynh chính · Ba", "Người thân · Bà") + status "Hoạt động" + quiet guardian-only controls; counts as quiet metadata ("5 thành viên · 1 lời mời đang chờ" — pending invite never counted as a member); **1 pending InviteRow** (dashed, "Đang chờ", Gửi lại / Thu hồi); protected guardian row exposes no invalid remove action.
- **Mobile 390:** header "Thành viên" in Gia đình context → tabs → tappable member rows (≥44px) → pending invite last → full-width CTA; bottom nav 4 items.
- **Primary action:** "Mời thành viên" (guardian/`invite_member` only — one CTA).
- **Governance:** invite/remove/pending = `invite_member`/guardian; member = read-only; `guardian_member_protected`; copy "Chỉ phụ huynh có quyền mời mới có thể quản lý thành viên."
- **Canonical ref:** **Correction Pack 1 (L3).** ✅ Gap RESOLVED (final merge 2026-07-17); VN role grammar throughout (no English role words).

---

## E. CREATE FLOWS

| Screen | Actor | Primary | Data/Governance | Canonical ref | Gap |
|---|---|---|---|---|---|
| **E1 Parent create** "Ghi lại một điều về {child}" (Tiêu đề + Câu chuyện + content-type chips Ảnh/Video · Giọng nói · Viết chữ + private-context audience Chỉ phụ huynh / Gia đình được mời) | parent | "Tiếp tục" (one filled CTA; quiet "Hủy") | `ParentMemoryComposer`; audience selector (existing private contexts only) | **Correction Pack 4 (L3)** — desktop 1440 + mobile 390 | ✅ RESOLVED |
| **E2 Family create** "Gửi một ký ức" (Tiêu đề ký ức · Câu chuyện · Thời điểm · Người liên quan + content kinds; audience fixed "Gia đình được mời") | guardian/member w/ `create_card` | "Gửi ký ức" (one filled CTA; quiet "Để sau") | `FamilyCardComposer`; create action visible only when `create_card` allowed | **Correction Pack 4 (L3)** — desktop 1440 + mobile 390 | ✅ RESOLVED |
| **E3 Text contribution** — "Thêm tiếng nói vào ký ức này → Viết vài dòng" (contextual entry inside Memory Room; secondary to the memory; standalone Family shell for members) | member | contextual (quiet entry) | `create_card_contribution` | **Correction Pack 4 (L3)** — contribution entry frame | ✅ RESOLVED |
| **E4 Voice contribution** — VoiceRecorder Idle / Recording / Review (timer, **2-min cap**, no autoplay; Review primary "Gửi giọng nói") | member | "Gửi giọng nói" (Review state only) | voice contribution | **Correction Pack 4 (L3)** — three 390px recorder frames | ✅ RESOLVED |
| **E5 Audience selector** — in-composer audience section ("Ai có thể xem?" — existing private contexts; MIN-consent applies downstream) | creator | part of composer step (no separate route) | consent audience (MIN-consent) | **Correction Pack 4 (L3)** — inside E1/E2 compositions | ✅ RESOLVED (contextual step, not an independent route) |

---

## F. SYSTEM & MEDIA STATES (TruthStateBlock family)

| State | Meaning | Behavior (canonical visuals + semantics per Pack 4) | Canonical ref | Gap |
|---|---|---|---|---|
| **Loading** | fetch in flight | sage/neutral skeleton, no percentage, no layout shift; `role="status"` + `aria-live="polite"` + `aria-busy` | **Correction Pack 4 (L3)** | ✅ RESOLVED |
| **Empty** | no content (true empty) | warm invitational panel; create action **only** in create-authorized context (two canonical variants: guardian w/ CTA "Gửi một ký ức" · member read-only w/o CTA) | **Correction Pack 4 (L3)** | ✅ RESOLVED — distinct from error |
| **Error** | fetch failed | restrained error accent + "Thử lại"; **never** silent-empty (F01/E4); `role="alert"` | **Correction Pack 4 (L3)** | ✅ RESOLVED — distinct from empty/denied |
| **Denied** | not authorized | denied-brown protected tone + shield/lock + **generic** copy (no existence/owner/child enumeration); optional "Quay lại Gia đình"; `role="alert"`; generic in Memory Room (D305) | **Correction Pack 4 (L3)** | ✅ RESOLVED — distinct from error |
| **Archived** | archived ≠ deleted | quiet metadata tone + archive icon + "Quay lại Gia đình"; restore/edit only for authorized actor | **Correction Pack 4 (L3)** | ✅ RESOLVED — visually ≠ denied |
| **Consent waiting** | MIN-consent pending | champagne/sage informational tone + quiet "Tìm hiểu vì sao"; no alarm-red; `role="status"` polite | **Correction Pack 4 (L3)** | ✅ RESOLVED — ≠ consent-needed |
| **Media unavailable** | signed media fail | **reserved media frame** (no collapse/jump) + broken-media icon + "Thử lại" (≥44px, accessible name); `role="alert"` | **Correction Pack 4 (L3)** | ✅ RESOLVED |
| **Consent needed** | media gated (guardian context) | protective champagne treatment + "Xem quyền riêng tư"; `role="status"` polite | **Correction Pack 4 (L3)** | ✅ RESOLVED |
| **Consent granted** | approved | success green + check + text (never color alone); copy does **not** promise universal display (MIN-consent / other families' settings may still apply); `role="status"` polite | **Correction Pack 4 (L3)** | ✅ RESOLVED |

## G. LIFECYCLE & INVITE STATES

| State | Where | Behavior | Governance | Source |
|---|---|---|---|---|
| Preserve active / reversed / orphaned | Memory Room ⑥, Journey preserved row | Preserve is its own zone; renders even on aux error (present-not-hidden) | guardian preserve path; `reverse_preserve` | L3 (Image 7) ✅ / states ⚠ |
| Invitation pending | Thành viên | Dashed InviteRow "Đang chờ" + Gửi lại / Thu hồi | guardian | **Correction Pack 1 (L3)** ✅ |
| Invitation expired | Thành viên | "Hết hạn sau n ngày" → expired treatment | guardian | ⚠ (L4) |
| Invitation revoked | Thành viên | removed from roster | guardian (`revoke_family_invitation`) | 🔴 not shown → baseline pattern |

---

## H. Unresolved design gaps (rolled into F7)
1. *(SUPERSEDED — RESOLVED by the 2026-07-17 final merge.)* ~~Thành viên, Quyền riêng tư, Cài đặt, all Create flows, all System/Media states exist only at L4 coverage~~ → all now **L3 canonical via Correction Packs 1–4**; no restyle gap remains for these surfaces.
2. **Notifications / Support** have no dedicated approved mockup → baseline list grammar only; no features.
3. **Invitation expired/revoked** visual treatments not shown at any level → 🔴.
4. **0 audio-only / 0 text-only family cards in prod** → those Memory Room compositions can't be visually captured until a card is hand-created (do not synthesize).
5. **Production visual baseline** (live UI capture) still open from B6 §8.1.
