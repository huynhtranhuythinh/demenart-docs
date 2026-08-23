# 🤝 DMA_HANDOFF_v26.md — BÀN GIAO PHIÊN (NGÃ A KHÉP — TÁCH CỔNG CUỐI `/admin` · 4/5 CỔNG V1 — 2026-06-28 08:46 GMT+7)

> **Cách dùng:** File này = ảnh chụp trạng thái cuối phiên v26. Boot phiên sau:
> `00_START_HERE` → `RULES` → file này. Rồi audit DB/code thật trước khi viết.
> **Naming:** DMA = nền tảng; CTAN = sản phẩm đầu. Không "DMMA".

---

## 1. LÀM GÌ PHIÊN NÀY

**Ngã A — slice cuối: tách cổng Admin `/admin` (nhân khuôn `school.tsx`/`parent.tsx`/`teacher.tsx`).** Carve 4 trang admin-thuần ra namespace riêng → **KHÉP Ngã A 4/5 cổng V1** (`/kid` reserved V2). **Phiên thuần UI/IA — KHÔNG mig, KHÔNG Edge, schema KHÔNG đổi.**

- **Cổng Admin `/admin`** (accent **slate**, "Quản trị Dế Mèn", `max-w-6xl`, brand icon LayoutDashboard): dời 4 trang admin-thuần `school-onboarding`·`sensitive-access`·`curriculum-admin`·`modules` từ `portal.X`→`admin.X`.
- **⭐ `/portal` KHÔNG biến mất — chuyển vai thành SHELL HẠ-TẦNG TRUNG TÍNH** chỉ còn ôm `notifications`+`support` (D95 gốc: 2 page hạ-tầng-toàn-App, mọi cổng LINK tới, KHÔNG nhân đôi). `portal.tsx` tỉa sạch cầu staff (Music/Camera/Quản-lý-Trường) + brand thành `<span>` không-link + xóa `portal.index.tsx`.
- **⭐ Routing FLIP nhánh `else`:** 4 nhánh trước (`homePathForRole`) đã bắt hết vai non-admin → chỉ đổi `else` `/portal`→**`/admin`**, KHÔNG cần liệt kê 4 role admin (`super_admin`/`content_admin`/`operation_admin`/`sales_admin`). Role null-chưa-kích-hoạt cũng rơi else→`/admin` và thấy đúng card "Tài khoản chưa kích hoạt" (guard bê theo dashboard).
- **⭐ `admin.index` = DASHBOARD thật** (khác `/school` index-1-màn, khác `/parent`+`/teacher` index-redirect): route-id `/_authenticated/admin/`, = card profile + nút Danh mục module. **Nav shell = 4 công cụ-của-vai thẳng** (khác cầu-chéo staff): admin cần với tới 4 tool ngay.

---

## 2. TRẠNG THÁI THẬT CUỐI PHIÊN

- **DB cấu trúc — KHÔNG ĐỔI:** **46 bảng · 50 hàm SECURITY DEFINER · 125 RLS policy · mig 001→044 · seed 001→012.** SYSTEM_MAP **v0.26** (bump vì route/IA, schema KHÔNG đổi). **Phiên thuần UI/IA.**
- **Edge Functions (6 — KHÔNG đổi):** `get_signed_media_url` · `upload_media` · `resolve_share_link` · `invite_master` · `invite_staff` · `invite_parent`.
- **3 tenant / 3 master** (DEMO-001 · KHM-DN · MNDM-DN).

### Routes app — sau phiên này (5 cổng, **4/5 đã tách**)
- **CỔNG PH `/parent`** (v24, amber): shell `parent.tsx` + `parent.index`→journal + `parent.journal` + `parent.consent`.
- **CỔNG GV `/teacher`** (v25, sky, "Phòng Giáo viên"): shell `teacher.tsx` + `teacher.index`→curriculum + `teacher.curriculum` + `teacher.moments`. Nav: Học liệu·Khoảnh khắc·**Trường**(`/school`)·Hỗ trợ·🔔.
- **CỔNG TRƯỜNG `/school`** (v25, emerald, "Quản lý Trường"): shell `school.tsx` + `school.index` (3 tab, **`ssr:false`**). Nav: Học liệu(`/teacher/curriculum`)·Khoảnh khắc(`/teacher/moments`)·Hỗ trợ·🔔.
- **CỔNG ADMIN `/admin`** (MỚI v26, slate, "Quản trị Dế Mèn"): shell `admin.tsx` + `admin.index` (dashboard) + `admin.school-onboarding` + `admin.sensitive-access` + `admin.curriculum-admin` + `admin.modules`. Nav: Onboard trường·Kho giáo trình·Quyền nhạy cảm·Module·Hỗ trợ(`/portal/support`)·🔔(`/portal/notifications`).
- **SHELL HẠ-TẦNG `/portal`** (TRUNG TÍNH — v26): shell `portal.tsx` brand "DMA" (không-link), nav = Hỗ trợ·🔔 thuần. Pages còn lại: `notifications`·`support`. **(Đã xóa `portal.index` + 4 trang admin đã dời.)**
- **Public ngoài shell:** `/share/$token` (KHÔNG đụng).
- **Routing vào app:** `index.tsx` + `auth.tsx` → `homePathForRole(role)`: PH→`/parent/journal` · master/sub→`/school` · lead/assistant→`/teacher/curriculum` · **else (admin nền tảng + chưa-kích-hoạt)→`/admin`**.

> **Auto-synced Lovable→GitHub** (không lưu tay). Migration/Edge KHÔNG phát sinh phiên này.

---

## 3. FILE UI PHIÊN NÀY (Lovable editor, áp tay — KHÔNG nhờ AI Lovable, D5/D14)

**TẠO:** `_authenticated/admin.tsx` (shell slate) · `admin.index.tsx` (dashboard, route-id `/_authenticated/admin/`, link Module→`/admin/modules`) · `admin.school-onboarding.tsx` · `admin.sensitive-access.tsx` · `admin.curriculum-admin.tsx` · `admin.modules.tsx` (4 trang = copy `portal.X` đổi route-id `/_authenticated/portal/X`→`/_authenticated/admin/X`).
**SỬA (FULL paste-over):** `lib/home-path.ts` (else→`/admin`) · `portal.tsx` (tỉa cầu staff, brand không-link, chỉ Hỗ trợ+🔔).
**XÓA (sau cùng):** `portal.index.tsx` · `portal.school-onboarding.tsx` · `portal.sensitive-access.tsx` · `portal.curriculum-admin.tsx` · `portal.modules.tsx`.

> **TẤT CẢ = FULL paste-over** (Cmd+A dán đè — D95). 4 trang dời chỉ đổi đúng dòng `createFileRoute(...)`. **Thứ tự áp: TẠO `admin.*` + SỬA → XÓA route cũ SAU CÙNG.** **⚠️ Bẫy v26:** paste-over `admin.index` không ăn lần đầu → TanStack sinh stub "Hello /_authenticated/admin/!" → dán đè lại đúng content thì ra dashboard.

---

## 4. NGHIỆM THU LOGIN THẬT (D2/D3) — ĐẠT (live `demenart.com`, tab ẩn danh)

- **super_admin Quản trị viên Test** (`info@demenart.com` / *password của Jean*) → thẳng **`/admin`** shell slate "Quản trị Dế Mèn"; dashboard "Xin chào, Quản trị viên Test · super_admin" + nút "Danh mục module". ✅
- 4 công cụ render đủ: `/admin/school-onboarding` (form onboard) · `/admin/curriculum-admin` (tải học liệu CTAN) · `/admin/sensitive-access` (tra cứu định danh trẻ) · `/admin/modules` (registry rỗng). ✅
- `/portal/support` + `/portal/notifications` → shell trung tính "DMA", **đã tỉa** Music/Camera/Quản-lý-Trường. ✅
- **Hồi quy non-admin:** master Nguyệt Thi (`hieutruong.kidshouse@demo.demenart.com`/`Test@123`) → vẫn `/school` emerald "Quản lý Trường" 3 tab + lớp Hoa Hồng/Hướng Dương active, KHÔNG vỡ (nhánh else không đụng 3 nhánh kia). ✅

> Routing theo vai **4 nhánh** sống. Engine v3–v14 + 8 cụm RLS + 50 hàm definer KHÔNG sửa 1 dòng.

---

## 5. ⭐ BẢNG TÀI KHOẢN TEST (mỗi lần nhờ test PHẢI ghi email kèm)

> Tất cả `@demo.demenart.com`, password **`Test@123`** (auto-confirm), trừ super_admin (password của Jean) + 2 login giữ-từ-v22 dùng password tạm.

| Vai | Email | Người / Trường | Land sau login (v26) |
|---|---|---|---|
| **Admin nền tảng** | `info@demenart.com` | Quản trị viên Test · super_admin | **`/admin`** |
| **Master KHM** | `hieutruong.kidshouse@demo.demenart.com` | Huỳnh Trần Nguyệt Thi · KHM | `/school` |
| **GV KHM** | `gv.linh.kidshouse@demo.demenart.com` | Đặng Mỹ Linh · KHM | `/teacher/curriculum` |
| **PH KHM** (2-con An+Khang) | `ph.hung.kidshouse@demo.demenart.com` | Nguyễn Văn Hùng · school NULL | `/parent/journal` |
| **Master MNDM** | `hieutruong.demen@demo.demenart.com` | Mai Phương Dung · MNDM | `/school` |
| **GV MNDM** | `gv.han.demen@demo.demenart.com` | Bùi Ngọc Hân · MNDM | `/teacher/curriculum` |
| **PH MNDM** (2-con Hà+Phúc) | `ph.thanh.demen@demo.demenart.com` | Đặng Văn Thành · school NULL | `/parent/journal` |
| GV KHM (giữ v22, password tạm) | `gv.my.kidshouse@demo.demenart.com` | Lê Thảo My · KHM | `/teacher/curriculum` |
| PH KHM (giữ v22, password tạm) | `ph.toan.kidshouse@demo.demenart.com` | Trần Quốc Toản · KHM | `/parent/journal` |

---

## 6. VIỆC TREO (ưu tiên giảm dần)

1. 🔴 **Lưu repo (nợ dồn):** Edge `invite_staff.ts` + `invite_parent.ts` (nợ v22) **+** `044_revoke_share_link.sql` (nợ v23). Dump trung thực từ live (D90). *Phiên v24–v26 KHÔNG phát sinh file SQL/Edge mới — UI auto-synced.*
2. 🟡 **Dead-link nhẹ:** nút "← Quay lại" trong `admin.modules.tsx` còn `to="/portal"` → bare `/portal` (index đã xóa → outlet rỗng). Vá 1 dòng `to="/portal"`→`to="/admin"`.
3. 🟡 **Cosmetic:** đoạn lưu-ý cuối `admin.curriculum-admin.tsx` còn chữ "mở /portal/curriculum" → đổi thành "/teacher/curriculum" (chỉ text, không phải link).
4. 🟡 **Rough edge GV read-only (KHÔNG do v26):** GV ở `/school` tab Trẻ&PH bấm 1 bé → `ParentsPanel` gọi `get_child_parents` gate master/sub (D92) → GV thấy toast "không có quyền" + PH rỗng. **Sửa sau:** nới gate cho lead/assistant same-school (read-only) HOẶC ẩn panel khi `!canManage`.
5. **GV/PH pilot còn lại chưa login** (4 GV + 9 PH) → mời nốt qua app khi cần (engine D93 đủ).
6. **2 file curriculum media chưa có nguồn lưu** · **Vercel project dormant** xóa được · **`seed_007` repo** body_template "Bé " thừa (đã UPDATE live, chỉ lệch file repo).

> ✅ **Đã gạch phiên này:** tách cổng Admin `/admin` (shell slate + dashboard + 4 trang) · `/portal` chuyển vai shell hạ-tầng trung tính (tỉa cầu staff + xóa index) · routing FLIP else→`/admin` · **KHÉP NGÃ A 4/5 cổng V1.**

---

## 7. NGÃ KẾ — ĐỀ XUẤT

- **⭐ A — Dọn nợ repo** (2 Edge v22 + `044` v23) — phiên hạ tầng thuần, dump trung thực D90. *(Nợ đỏ lâu nhất, nên trả.)*
- **B — Vá rough edge GV read-only** (§6.4) + pass nhỏ nới `get_child_parents` cho lead/assistant same-school read-only.
- **C — UI/UX polish pass** (đã hoãn tới khi xong engine V1 — giờ Ngã A đã khép): thống nhất accent nội-thân từng cổng (vd `school.index` đang amber → emerald); mượt **mobile nav** (hiện 4 cổng đều `hidden sm:inline-flex` → mobile mất nav); vá 2 dead-link/cosmetic §6.2–6.3.
- **D — Khởi động `/kid` V2** (trẻ vào bằng PIN, ba mẹ duyệt) — thép chờ #2 đã để ngỏ `children.identity_user_id`; namespace `/kid` đã reserved. *(Bước lớn, sang "tầng 2".)*

**Boot phiên sau:** đọc HANDOFF v26 → audit live route tree (D1) thật trước khi viết.

---

## 8. DATA STATE CẦN NHỚ (bẫy cho phiên sau — GIỮ từ v23/v24)

- **KHM-DN `sharing_mode=private_share_link`** (KHÔNG phải `no_external_sharing`).
- **Consent An `private_share_link` (`d1…e1`) = GRANTED** (đổi WITHDRAWN→GRANTED ở v23 để test, để vậy) **+ download consent An bật.**
- **3 tenant / 3 master** (DEMO-001 1lớp/2trẻ · KHM 2/8 · MNDM 2/6 = 5 lớp/16 trẻ).
- **PH 051 mỗi trường = 2-con-xuyên-lớp** (persona multi-child, CÙNG-trường, KHÔNG xuyên-trường).
- **Role PH thật trong DB = `primary_parent`** (13 dòng; KHÔNG có `secondary_parent` hiện tại — nhưng `homePathForRole` để ngỏ cả hai).
- **profile_role 12 giá trị:** admin Dế Mèn (6) `super_admin`·`content_admin`·`senior_content_admin`·`operation_admin`·`sales_admin`·`support_admin` → tất cả land `/admin` (nhánh else); nhà trường&GV (4) `master_admin`·`sub_admin`·`lead_teacher`·`assistant_teacher`; PH (2) `primary_parent`·`secondary_parent`.
- **2 login giữ từ v22:** GV Lê Thảo My + PH Trần Quốc Toản.
- **`link_role` lưu CODE** `mother`/`father`/`guardian`; legacy seed = `primary`/`secondary` (UI render cả hai).
- **`master_admin` ∈ `is_school_admin()`**; PH `school_id=NULL` cần RPC curated cho ghi (D29) lẫn đọc (D92).
- **`school.index` giữ `ssr:false`** — màn auth-gated nhiều fetch client-side; shell `{admin,school,teacher,parent}.tsx` KHÔNG đặt ssr:false (kế thừa guard pathless `_authenticated/route.tsx`).
- **`/portal` giờ = shell hạ-tầng** (notifications+support); KHÔNG vai nào land thẳng (else→`/admin`). Brand không-link; bare `/portal` không index → outlet rỗng (chấp nhận, không truy cập qua UI trừ nút "Quay lại" modules còn nợ).
- **Engine media-nhạy-cảm = 5 gate secdef nhận-tham-số:** consent ảnh trẻ (D71) · entitlement học liệu (D75) · upload (D77) · share (D87) · revoke (D94).

---

> **KỶ LUẬT VÀNG:** đã cập nhật **RULES** (mở rộng D95 — slice `/admin`: `/portal` chuyển-vai-shell-hạ-tầng, routing-flip-else, index-dashboard-thật + bẫy-stub, nav-công-cụ-của-vai; footer v26) + **SYSTEM_MAP** (bump v0.26, dòng route 4/5 cổng tách + routing 4 nhánh, dòng nghiệm thu v26) trong phiên này. **3 file xuất kèm:** `DMA_HANDOFF_v26.md` · `DMA_RULES.md` · `DMA_SYSTEM_MAP.md`. **KHÔNG file SQL/Edge mới** (phiên thuần UI, auto-synced). **START_HERE: KHÔNG đổi** (§2 "Năm cổng" đã đúng từ v24). **Tài liệu A–G, BUILD_PATH, DMWS_REFERENCE: KHÔNG đổi.**
