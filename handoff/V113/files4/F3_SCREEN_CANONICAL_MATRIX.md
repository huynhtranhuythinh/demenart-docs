# F3 — SCREEN CANONICAL MATRIX
**V113F** · Every Parent Portal screen + major state, mapped to one visual system. Presentation/composition only — routes, authority, RPC/RLS/consent unchanged (B1–B5).

**Legend for "Gap":** ✅ approved L2/L3 source · ⚠ L4 coverage only (restyle-to-baseline required) · 🔴 no approved source (evidence debt).

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

### C1 · Quyền riêng tư — `/parent/consent`  ⚠
- **Actor:** parent of child. **Purpose:** per-child consent toggles + audience visibility.
- **Desktop:** child selector → "Ai có thể xem?" audience rows (Gia đình gần / Người thân mở rộng / Bạn bè của ba mẹ / Công khai) with allow/limit/deny + "Gia đình gần" member count panel.
- **Mobile:** child chips → audience rows → "Quản lý thành viên".
- **Primary action:** toggle consent (**write path unchanged** — direct `consents` RLS, F9 parked 🔒).
- **Empty/Denied:** not-linked → empty; write error → toast.
- **Governance:** MIN-consent rule applies; "Vì sao?" entry from Journey/media.
- **Canonical ref:** Image 1 §3 (**L4 only**). ⚠ restyle to baseline.

### C2 · Cài đặt — `/parent/settings`  ⚠
- **Actor:** parent. **Purpose:** account hub (Tài khoản / Thông báo / Thiết bị / Hỗ trợ). **Utility, demoted from primary nav.**
- **Desktop:** tabbed: Thông tin tài khoản (name/email/phone/role + Chỉnh sửa) · Bảo mật (đổi mật khẩu, 2FA, sign-out other devices) · Hỗ trợ links · Tài khoản (Xuất dữ liệu, **Xóa tài khoản** in quiet destructive zone).
- **Mobile:** grouped list rows + destructive "Đăng xuất"/"Xóa tài khoản" at bottom.
- **Primary action:** context-dependent (e.g. Chỉnh sửa). **Prohibited (per platform rules): app never enters passwords/credentials on user's behalf — user performs those.**
- **Canonical ref:** Image 1 §4 (**L4 only**). ⚠ restyle; move destructive to quiet zone.

### C3 · Thông báo — `/portal/notifications` / C4 · Hỗ trợ — `/portal/support`  🔴/⚠
- **Actor:** parent. **Utility.** No new notification functionality (🔒). Reachable via bell + account menu.
- **Canonical ref:** no dedicated approved mockup → 🔴 use baseline list grammar; **do not build features**.

---

## D. FAMILY-INTERNAL & MEMBERS

### D1 · Thành viên (section of Gia đình)  ⚠
- **Actor:** guardian (manage) / member (read-only). **Purpose:** roster + roles + invites.
- **Desktop:** roster table (Thành viên / Vai trò / Quan hệ / Quyền / Trạng thái) + "Mời thành viên" + "Quản lý" (guardian only) + "Lời mời đang chờ" with Nhắc lại / Hủy.
- **Mobile:** tabs (Tất cả / Người thân / Lời mời) → member rows → invite rows.
- **Primary action:** "Mời thành viên" (guardian only).
- **Governance:** invite/remove/pending = `invite_member`/guardian; member = read-only; `guardian_member_protected`.
- **Canonical ref:** Image 1 §2 (**L4 only**). ⚠ restyle: baseline tokens, VN role grammar (replace English "Guardian"), keep member read-only.

---

## E. CREATE FLOWS

| Screen | Actor | Primary | Data/Governance | Canonical ref | Gap |
|---|---|---|---|---|---|
| **E1 Parent create** "Ghi lại một điều về {child}" (text + Ảnh/Video + Giọng nói + Viết chữ + audience) | parent | "Tiếp tục" | `ParentMemoryComposer`; audience selector | Image 1 §5 | ⚠ restyle; one primary |
| **E2 Family create** "Gửi một ký ức gia đình" (media picker, multi-select) | member w/ `create_card` | "Gửi" | `FamilyCardComposer` | Image 1 §5 | ⚠ single create CTA |
| **E3 Text contribution** "Gửi lời bằng chữ" | member | "Gửi" | `create_card_contribution` | Image 1 §5 | ⚠ |
| **E4 Voice contribution** "Gửi voice contribution" (recorder, timer, 2-min cap) | member | "Gửi" | voice contribution | Image 1 §5 | ⚠ |
| **E5 Audience selector** "Chọn ai có thể xem" | creator | "Xác nhận" | consent audience (MIN-consent) | Image 1 §5 | ⚠ |

---

## F. SYSTEM & MEDIA STATES (TruthStateBlock family)

| State | Meaning | Behavior | Canonical ref | Gap |
|---|---|---|---|---|
| **Loading** | fetch in flight | signed-media placeholder / skeleton, no layout shift | Image 1 §6 | ⚠ restyle |
| **Empty** | no content (true empty) | warm "Chưa có nội dung nào" + create/first action | Image 1 §6 | ⚠ distinct from error |
| **Error** | fetch failed | "Đã có lỗi xảy ra" + "Thử lại"; **never** silent-empty (F01/E4) | Image 1 §6 | ⚠ distinct from empty/denied |
| **Denied** | not authorized | "Bạn không có quyền xem…" + safe fallback; generic in Memory Room (D305) | Image 1 §6 | ⚠ distinct from error |
| **Archived** | archived ≠ deleted | "Nội dung đã lưu trữ" + "Xem lưu trữ"/restore | Image 1 §6 | ⚠ restore reachable both contexts |
| **Consent waiting** | MIN-consent pending | "Đang chờ ba mẹ đồng ý…" + "Vì sao?" → consent | Image 1 §6 | ⚠ |
| **Media unavailable** | signed media fail | "Không thể tải nội dung" + "Thử lại" | Image 1 §7 | ⚠ |
| **Consent needed** | media gated | "Nội dung này cần sự đồng ý…" + "Xem chi tiết" | Image 1 §7 | ⚠ |
| **Consent granted** | approved | "Đã được đồng ý" confirmation | Image 1 §7 | ⚠ |

## G. LIFECYCLE & INVITE STATES

| State | Where | Behavior | Governance | Source |
|---|---|---|---|---|
| Preserve active / reversed / orphaned | Memory Room ⑥, Journey preserved row | Preserve is its own zone; renders even on aux error (present-not-hidden) | guardian preserve path; `reverse_preserve` | L3 (Image 7) ✅ / states ⚠ |
| Invitation pending | Thành viên | "Chờ duyệt" + Nhắc lại/Hủy | guardian | ⚠ (L4) |
| Invitation expired | Thành viên | "Hết hạn sau n ngày" → expired treatment | guardian | ⚠ (L4) |
| Invitation revoked | Thành viên | removed from roster | guardian (`revoke_family_invitation`) | 🔴 not shown → baseline pattern |

---

## H. Unresolved design gaps (rolled into F7)
1. **Thành viên, Quyền riêng tư, Cài đặt, all Create flows, all System/Media states** exist only at **L4 coverage** → restyle-to-baseline + confirm before build.
2. **Notifications / Support** have no dedicated approved mockup → baseline list grammar only; no features.
3. **Invitation expired/revoked** visual treatments not shown at any level → 🔴.
4. **0 audio-only / 0 text-only family cards in prod** → those Memory Room compositions can't be visually captured until a card is hand-created (do not synthesize).
5. **Production visual baseline** (live UI capture) still open from B6 §8.1.
