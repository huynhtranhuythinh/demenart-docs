# DMA_HANDOFF_v61.md — GIAO CA PHIÊN

> **Đọc kèm:** `DMA_00_START_HERE.md` → `DMA_RULES.md` (đến **D188**) → `DMA_SYSTEM_MAP.md` (**v0.56**). Đây là handoff mới nhất.
> **Phiên này:** dựng **2 bộ mặt công khai** của DMA — **Landing / Cổng chính** (`/`) và **Login nâng cấp** (`/auth`) — rồi **đóng nợ sổ sách** (nối RULES/SYSTEM_MAP bản sống + xác nhận backup đã commit). **Ngày:** 2026-07-07 (GMT+7).
> **✅ Sổ sách đã KHỚP:** phiên này Jean gửi bản SỐNG RULES(v58/D180)+SYSTEM_MAP(v0.53), Claude nối trọn → từ nay snapshot khớp bản sống, HẾT cảnh nối tay delta (chấm dứt vướng v55/v0.50 kéo dài).

---

## 1. LÀM GÌ PHIÊN NÀY (tóm tắt 1 câu)

Thay placeholder `/` bằng **Landing cổng chính** (5 portal + Kid gate, gateway visual CSS/SVG, ảnh watercolor), **nâng cấp Login** `/auth` (hero logo đứng + card premium + eye toggle + error banner + 2 modal, giữ nguyên auth logic), và **đóng nợ sổ sách** (nối RULES→D188 + SYSTEM_MAP→v0.56 bản sống; backup 093–102 + 103–104 đã commit GitHub).

---

## 2. ĐÃ SHIP (production qua Cloudflare demenart.com, nghiệm thu Jean)

### 2.1. Landing / Cổng chính V1 (`src/routes/index.tsx`, 0 mig)
- Thay placeholder cũ (chỉ title + 1 nút) bằng **CỔNG CHÍNH CÔNG KHAI** (route `/`, ngoài `_authenticated`).
- **Header:** logo-banner (ảnh) · "Tôi có mã mời" (→`/auth` tạm) · "Hỗ trợ" (mailto) · nút "Đăng nhập" / "Vào cổng của bạn" (`homePathForRole` khi đã login).
- **Hero:** tiêu đề + microcopy + 3 chip giá trị · **Gateway visual CSS/SVG** — hệ sinh thái 5 node (node giữa = logo-ring, 5 node vệ tinh = 5 portal, đường nối chấm), KHÔNG phụ thuộc ảnh nặng.
- **5 card cổng:** Nhà trường→`/school` · Giáo viên→`/teacher` · Phụ huynh→`/parent` · Thế giới của bé→`/kid` · Dế Mèn Team→`/admin`. Mỗi card: **ảnh watercolor** + **status badge** (Đang hoạt động / Sắp ra mắt / Cần mã PIN / Nội bộ) + CTA màu-theo-portal (green/honey/honey-pink/teal/navy). Kid: lock icon + note mở khoá. Card link cố định portal đích; guard `_authenticated` tự đẩy chưa-login→/auth; /kid tự vào PIN gate.
- **Trust strip** 4 mục warm + **footer** (© 2026 · hotline 1900 636 002 · support@demenart.com · 3 link chính sách tĩnh).
- **Brand hardcode hex** (cream/forest/honey) — theme Tailwind repo = shadcn default không có brand token (D187).

### 2.2. Login nâng cấp (`src/routes/auth.tsx`, 0 mig)
- **GIỮ NGUYÊN 100% auth logic:** `signInWithPassword` → `resolveHome` → redirect theo role; `useEffect` session-check. Chỉ thay UI (D95).
- **Hero:** logo-standing (logo đứng "DẾ MÈN / ART GARDEN") + "Chào mừng trở lại ✨" + subtitle + trang trí lá/sparkle CSS · nền gradient cream.
- **Card** (fix z-index D188 — `relative z-10` để hero không cắt góc bo trên): tiêu đề "Đăng nhập" + gạch honey · form icon-in-input (mail/lock) + **eye toggle** (aria-label, a11y) · Ghi nhớ (checkbox UI, KHÔNG đổi persist session) + Quên mật khẩu→modal hỗ trợ · CTA forest + loading "Đang đăng nhập…" + disabled · **error banner thân thiện** "Email hoặc mật khẩu chưa đúng…" (KHÔNG raw error) + validation empty · divider "hoặc" + 2 nút outline "Tôi có mã mời"/"Cần hỗ trợ".
- **2 modal (shadcn Dialog):** Nhập mã mời (placeholder — chưa backend invite) · Hỗ trợ (hotline+email + "Gửi yêu cầu hỗ trợ"). Security notice + support footer.

### 2.3. Đóng nợ sổ sách
- **Backup GitHub:** Jean xác nhận đã commit `DMA_repo_backup_093-102.zip` + `DMA_repo_backup_103-104.zip` → 🟡 nợ backup **SẠCH**.
- **RULES/SYSTEM_MAP:** Jean gửi bản SỐNG (RULES v58/D180 · MAP v0.53) → Claude nối trọn: RULES +**D181–D188** (v59/v60/v61) → **D188**; SYSTEM_MAP +**v0.54/v0.55/v0.56** → **v0.56**. Xuất **2 file trọn** (đúng D95). Từ nay snapshot khớp bản sống — hết delta nối tay.

### 2.4. Asset thương hiệu (Bunny dma-public/landing/)
- **9 webp (~190KB):** logo-banner · logo-ring · logo-mascot · **logo-standing** (mới phiên này) · card-school · card-teacher · card-parent · card-kid · card-team. Claude tối ưu webp (card ~640px q82; logo giữ alpha) → Jean upload dma-public (Claude không upload Bunny được — network chặn, D187).

---

## 3. TRẠNG THÁI DB (audit live cuối phiên)

**63 bảng · 105 SECURITY DEFINER · 155 policy · mig 001→104 · Edge 14 · cron 1 active · 3 trường.**

So v60: **KHÔNG đổi gì** (phiên thuần UI công khai + asset + sổ sách). Không mig/bảng/hàm/policy/Edge/data. `kid_gate` giữ v6.

---

## 4. VIỆC TAY JEAN (⚠️ chưa xong)

- 🟠 **Ghi đè bản sống:** tải `DMA_RULES.md` (→D188) + `DMA_SYSTEM_MAP.md` (→v0.56) mới nhất phiên này ghi đè bản sống của anh. **(Dùng bản v61 này — nó bao trùm bản đưa giữa phiên; 2 file delta rời bỏ đi được.)**
- 🟡 **Upload asset:** `logo-standing.webp` lên `dma-public/landing/logo-standing.webp` (nếu chưa) — hero login cần nó.
- 🟢 (nếu chưa) **Nghiệm thu login thật** bản auth mới trên production: đăng nhập + redirect theo role còn chạy (vd Master KHM `hieutruong.kidshouse@demo.demenart.com`/`Test@123`).

---

## 5. VIỆC TREO (ngã kế)

- **Landing hero:** hiện dùng gateway visual CSS. Nếu muốn thay bằng tranh watercolor → gửi 1 ảnh ngang, ráp qua `LANDING_ASSETS` (slot để ngỏ).
- **Mã mời (invite) backend:** "Tôi có mã mời" đang là modal placeholder — cần thiết kế backend invite-code nếu muốn thật.
- **Trò cảm thụ / Parent đào sâu:** thêm loại trò (category sẵn), UX consent trên card, lọc theo tier (mang từ v60).
- **Video Stream V2:** đẩy video drive qua Bunny Stream để có poster + HLS thật (mang từ v60).
- 🔴 **"Try to fix all" Lovable — ĐỪNG BẤM** (D5/D14).
- Kid V2 nội dung (thêm game item mood/instrument qua admin) · Bunny cleanup nếu còn — mang từ trước.

---

## 6. NGÃ KẾ (chọn đầu phiên sau)

1. **Polish công khai tiếp:** ảnh hero watercolor cho landing · trang Giới thiệu/Tin tức/Hỗ trợ công khai · i18n đổi ngữ.
2. **Invite backend:** thiết kế mã mời thật (school/DMA cấp → onboard).
3. **Trò cảm thụ / Parent** đào sâu (thêm loại trò, UX consent trên card, lọc theo tier).
4. **Video Stream V2:** poster + HLS thật cho video drive.

---

## 7. KỶ LUẬT — D-RULE MỚI PHIÊN NÀY (đã nối vào RULES bản sống, sau D186)

**D187 MỚI [landing · cổng công khai & asset thương hiệu]:** (a) Theme Tailwind repo = shadcn DEFAULT (slate), KHÔNG chứa brand token → brand color (cream `#FBF8F1`·forest `#149A76`·forest-dark `#0F6E56`·honey `#EFA63A`) phải **hardcode hex**, `bg-primary` ra slate. (b) Asset landing = system/brand → zone `dma-public` (token-auth OFF, URL public vĩnh viễn) path `/landing/`; `const CDN` + object `LANDING_ASSETS`, key rỗng→fallback gradient+icon. (c) **Claude KHÔNG upload Bunny được** (network chặn ngoài github/npm) → Claude tối ưu webp → Jean upload → Claude ráp URL; ảnh Jean nghiệm thu. (d) Sau deploy Cloudflare: tab cũ trỏ CSS hash cũ → trắng style → hard-refresh/tab mới. (e) Card cổng link cố định; guard `_authenticated` tự đẩy chưa-login→/auth; /kid tự vào PIN gate.

**D188 MỚI [ui · paint order positioned đè static]:** Phần tử `position:relative/absolute` LUÔN vẽ đè lên sibling **tĩnh (static)** bất kể thứ tự DOM. Card dùng negative margin (`-mt-*`) đè lên hero `relative` sẽ bị hero cắt góc/cạnh (hero vẽ sau) → mất bo góc trên. Fix: cho card `relative z-10`. Cùng họ D172 (overflow-hidden nuốt UI).

**Giữ nguyên (nhắc nhanh):** D1 audit live · D2/D3 verify login thật · D5/D14 KHÔNG "Try fix all" · D15 re-grant + aclexplode · D48 nhật ký/ảnh trẻ thuộc trẻ+gia đình · D90/D112 dump-từ-live + reconcile · D92 3-khối · D95 file trọn khi close · D116/D117 đọc source thật trước mirror/paste · D134 auto-áp + get_diff từng lượt · D181 field mới trôi qua spread · D182 proacl gốc trước REVOKE · D183 nhãn riêng tư moment · D184 2 media-pool tách · D185 tile video không `<video>` inline · D186 hard-delete FK con→cha · D187 landing/brand-hex · D188 z-index card.

*Handoff v61 — 2026-07-07 GMT+7. Nguồn: v60 + bản sống RULES/MAP của Jean + live audit + nghiệm thu production. Cập nhật "tới đâu ghi tới đó" (KỶ LUẬT VÀNG).*
