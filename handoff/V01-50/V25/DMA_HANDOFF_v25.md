# 🤝 DMA_HANDOFF_v25.md — BÀN GIAO PHIÊN (NGÃ A — TÁCH CỔNG `/teacher` + `/school` + VÁ DEAD-LINK v24 — 2026-06-28 00:08 GMT+7)

> **Cách dùng:** File này = ảnh chụp trạng thái cuối phiên v25. Boot phiên sau:
> `00_START_HERE` → `RULES` → file này. Rồi audit DB/code thật trước khi viết.
> **Naming:** DMA = nền tảng; CTAN = sản phẩm đầu. Không "DMMA".

---

## 1. LÀM GÌ PHIÊN NÀY

**Ngã A tiếp (sau slice 1 `/parent` ở v24) — tách thêm 2 cổng trong 1 phiên: `/teacher` rồi `/school`.** Khuôn `parent.tsx` (v24, D95) đã chứng minh → phiên này nhân khuôn 2 lần nữa, mỗi slice nghiệm thu login thật xong mới sang slice kế. **Phiên thuần UI/IA — KHÔNG mig, KHÔNG Edge.**

- **Slice 2 — Cổng Giáo viên `/teacher`** (accent **sky**, "Phòng Giáo viên", `max-w-5xl`): dời `curriculum`+`moments` (staff-thuần) sang `/teacher`; routing `lead_teacher`/`assistant_teacher`→`/teacher/curriculum`. Tiện tay **gỡ nút "Bảng Test RLS"** tàn dư trong `portal.index.tsx` (route `rls-test` xóa v21 → Not Found — nợ từ v24).
- **Slice 3 — Cổng Trường `/school`** (accent **emerald**, "Quản lý Trường", `max-w-6xl`): dời `portal.school` (3 tab) sang `/school` làm **index** (master vào thấy ngay, đỡ 1 hop redirect); routing `master_admin`/`sub_admin`→`/school`.
- **⭐ Cầu "2 portal thông nhau" (D45) 2-chiều:** shell `/school` link Học liệu·Khoảnh khắc→`/teacher/*` (master xem được); shell `/teacher` thêm link **Trường**→`/school` (GV vào **read-only** — `canManage` đã gating sẵn).
- **⭐ Vá bug v24 phát hiện trong audit:** `portal.tsx` còn 2 icon **BookHeart→`/portal/journal`** + **ShieldCheck→`/portal/consent`** — 2 route đó đã rename sang `/parent/*` ở v24 → **route chết** (staff bấm ra Not Found) + journal/consent là PH-thuần (không thuộc nav staff). → gỡ 2 icon (đúng D95 "phân loại page thuộc vai").

---

## 2. TRẠNG THÁI THẬT CUỐI PHIÊN

- **DB cấu trúc — KHÔNG ĐỔI:** **46 bảng · 50 hàm SECURITY DEFINER · 125 RLS policy · mig 001→044 · seed 001→012.** SYSTEM_MAP **v0.25** (bump vì IA/route đổi, schema KHÔNG đổi). **Phiên thuần UI/IA.**
- **Edge Functions (6 — KHÔNG đổi):** `get_signed_media_url` · `upload_media` · `resolve_share_link` · `invite_master` · `invite_staff` · `invite_parent`.
- **3 tenant / 3 master** (DEMO-001 · KHM-DN · MNDM-DN).

### Routes app — sau phiên này (5 cổng, 3/5 đã tách)
- **CỔNG PH `/parent`** (v24): shell `parent.tsx` (amber) + `parent.index`→journal + `parent.journal` + `parent.consent`.
- **CỔNG GV `/teacher`** (MỚI v25): shell `teacher.tsx` (sky, "Phòng Giáo viên") + `teacher.index`→curriculum + `teacher.curriculum` + `teacher.moments`. Nav: Học liệu·Khoảnh khắc·**Trường**(`/school`)·Hỗ trợ·🔔.
- **CỔNG TRƯỜNG `/school`** (MỚI v25): shell `school.tsx` (emerald, "Quản lý Trường") + `school.index` (= 3 tab cũ, **`ssr:false` giữ nguyên**, route-id `/_authenticated/school/`). Nav: Học liệu(`/teacher/curriculum`)·Khoảnh khắc(`/teacher/moments`)·Hỗ trợ·🔔.
- **CỔNG STAFF/ADMIN `/portal/*`** (THU GỌN): shell `portal.tsx` nav giờ = Quản lý Trường(`/school`)·Music(`/teacher/curriculum`)·Camera(`/teacher/moments`)·Hỗ trợ·🔔 (**đã gỡ journal/consent chết**). Pages còn lại: `notifications`·`support`·`school-onboarding`·`sensitive-access`·`curriculum-admin`·`modules`·`index`.
- **Public ngoài shell:** `/share/$token` (KHÔNG đụng).
- **Routing vào app:** `index.tsx` + `auth.tsx` → `homePathForRole(role)`: PH→`/parent/journal` · `master_admin`/`sub_admin`→`/school` · `lead_teacher`/`assistant_teacher`→`/teacher/curriculum` · else (admin nền tảng)→`/portal`.

> **Auto-synced Lovable→GitHub** (không lưu tay). Migration/Edge KHÔNG phát sinh phiên này.

---

## 3. FILE UI PHIÊN NÀY (Lovable editor, áp tay — KHÔNG nhờ AI Lovable, D5/D14)

**Slice 2 — `/teacher` (TẠO):** `_authenticated/teacher.tsx` · `teacher.index.tsx` (redirect→curriculum) · `teacher.curriculum.tsx` (= `portal.curriculum` đổi route-id) · `teacher.moments.tsx` (= `portal.moments` đổi route-id).
**Slice 2 — SỬA:** `lib/home-path.ts` (+nhánh GV) · `portal.tsx` (Music/Camera→`/teacher/*`) · `portal.index.tsx` (gỡ nút rls-test).
**Slice 2 — XÓA:** `portal.curriculum.tsx` · `portal.moments.tsx`.

**Slice 3 — `/school` (TẠO):** `_authenticated/school.tsx` (shell emerald) · `school.index.tsx` (= `portal.school` đổi route-id→`/_authenticated/school/`, **giữ `ssr:false`**).
**Slice 3 — SỬA:** `lib/home-path.ts` (+nhánh master/sub→`/school`) · `teacher.tsx` (+link Trường) · `portal.tsx` (Quản lý Trường→`/school`, **gỡ 2 icon journal/consent chết**).
**Slice 3 — XÓA:** `portal.school.tsx`.

> **TẤT CẢ = FULL paste-over** (Cmd+A dán đè — D95). 2 page dời chỉ đổi đúng dòng `createFileRoute(...)`, không có `<Link to="/portal/...">` nội-page. **Thứ tự áp: TẠO route mới + SỬA → XÓA route cũ SAU CÙNG** (xóa trước = nháy đỏ routeTree).

---

## 4. NGHIỆM THU LOGIN THẬT (D2/D3) — ĐẠT (Preview/live, tab ẩn danh)

**Slice 2:**
- GV **Đặng Mỹ Linh** (`gv.linh.kidshouse@demo.demenart.com`/`Test@123`) → `/teacher/curriculum` shell sky, 2 track CTAN phát + watermark trôi. ✅
- PH **Hùng** → vẫn `/parent/journal` amber, hành trình đa-môn CTAN+Ballet, không dính `/teacher`. ✅
- Master **Nguyệt Thi** → vẫn `/portal` không vỡ; **nút "Bảng Test RLS" biến mất**; bấm icon Music → `/teacher/curriculum` xem track (cầu D45). ✅

**Slice 3:**
- Master **Nguyệt Thi** (`hieutruong.kidshouse@…`) → thẳng `/school` shell emerald; 3 tab đủ: Lớp&Môn (Hoa Hồng/Hướng Dương) · Giáo viên (Mỹ Linh+Thảo My "Đã đăng nhập", Khánh Vy+Hoàng Nam "Mời đăng nhập") · Trẻ&PH (4 bé KH-HH-01..04). ✅
- Master bắc cầu: /school → Học liệu → `/teacher/curriculum` phát nhạc, nav có **Trường**. ✅
- GV **Mỹ Linh** read-only: `/teacher` → **Trường** → `/school` banner "Bạn đang xem ở chế độ chỉ đọc" + chỉ Danh sách lớp, KHÔNG form. ✅
- PH **Hùng** → `/parent/journal` amber, journal sống, card có nút Chia sẻ. ✅

> Routing theo vai **4 nhánh** sống (PH→parent · master/sub→school · GV→teacher · admin→portal). Engine v3–v14 + 8 cụm RLS + 50 hàm definer KHÔNG sửa 1 dòng.

---

## 5. ⭐ BẢNG TÀI KHOẢN TEST (mỗi lần nhờ test PHẢI ghi email kèm)

> Tất cả `@demo.demenart.com`, password **`Test@123`** (auto-confirm), trừ 2 login giữ-từ-v22 dùng password tạm.

| Vai | Email | Người / Trường | Land sau login (v25) |
|---|---|---|---|
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

1. 🔴 **Lưu repo (nợ dồn):** Edge `invite_staff.ts` + `invite_parent.ts` (nợ v22) **+** `044_revoke_share_link.sql` (nợ v23). Dump trung thực từ live (D90). *Phiên v24/v25 KHÔNG phát sinh file SQL/Edge mới — UI auto-synced.*
2. **Tách nốt 2 cổng còn lại** (Ngã A hoàn tất): `/admin` (gom `school-onboarding`·`sensitive-access`·`curriculum-admin`·`modules` — đang ở `_authenticated/portal.*`) · `/kid` reserved (V2). Mẫu `parent.tsx`/`teacher.tsx`/`school.tsx` đã là khuôn vững.
3. 🟡 **Rough edge GV read-only (KHÔNG do v25):** GV ở `/school` tab Trẻ&PH bấm chọn 1 bé → `ParentsPanel` gọi `get_child_parents` mà RPC gate master/sub (D92) → GV thấy toast "không có quyền" + danh sách PH rỗng. Hành vi cũ từ `/portal/school`. **Sửa sau:** hoặc nới gate `get_child_parents` cho lead/assistant same-school (read-only), hoặc ẩn panel PH khi `!canManage`.
4. 🧹 **Dọn `/portal` cho thuần admin (để dành slice `/admin`):** sau khi master/sub land `/school` và GV land `/teacher`, `/portal` chỉ còn admin nền tảng land — nhưng nav `/portal` vẫn còn Music/Camera/Quản-lý-Trường (vô dụng với admin school_id=NULL, vô hại). Tỉa khi làm `/admin`.
5. **GV/PH pilot còn lại chưa login** (4 GV + 9 PH) → mời nốt qua app khi cần (engine D93 đủ).
6. **2 file curriculum media chưa có nguồn lưu** · **Vercel project dormant** xóa được · **`seed_007` repo** body_template "Bé " thừa (đã UPDATE live, chỉ lệch file repo).

> ✅ **Đã gạch phiên này:** tách cổng GV `/teacher` (shell sky + 2 page) · tách cổng Trường `/school` (shell emerald + 3 tab index) · routing theo vai 4 nhánh · cầu staff↔teacher↔school 2-chiều · gỡ nút rls-test tàn dư · **vá 2 dead-link journal/consent ở portal.tsx**.

---

## 7. NGÃ KẾ — ĐỀ XUẤT

- **⭐ A — Tách cổng Admin `/admin`** (gom `school-onboarding`·`sensitive-access`·`curriculum-admin`·`modules`) theo khuôn 3 shell đã có; routing admin nền tảng (super/content/operation/sales)→`/admin`; tỉa nav `/portal` → chỉ còn không gian admin. **HOÀN TẤT Ngã A 4/4 cổng V1** (`/kid` để reserved). *(Slice kế tự nhiên, khép Ngã A.)*
- **B — Dọn nợ repo** (2 Edge v22 + `044` v23) — phiên hạ tầng thuần, dump trung thực D90.
- **C — Vá rough edge GV read-only** (§6.3) + pass nhỏ nới `get_child_parents`.
- **D — UI/UX polish pass** (đã hoãn tới khi xong engine V1) — thống nhất accent nội-thân `school.index` (đang amber) theo shell emerald; mượt mobile nav (hiện `hidden sm:inline-flex`).

**Boot phiên sau:** đọc HANDOFF v25 → audit live route tree (D1) thật trước khi viết.

---

## 8. DATA STATE CẦN NHỚ (bẫy cho phiên sau — GIỮ từ v23/v24)

- **KHM-DN `sharing_mode=private_share_link`** (KHÔNG phải `no_external_sharing`).
- **Consent An `private_share_link` (`d1…e1`) = GRANTED** (đổi WITHDRAWN→GRANTED ở v23 để test, để vậy) **+ download consent An bật.**
- **3 tenant / 3 master** (DEMO-001 1lớp/2trẻ · KHM 2/8 · MNDM 2/6 = 5 lớp/16 trẻ).
- **PH 051 mỗi trường = 2-con-xuyên-lớp** (persona multi-child, CÙNG-trường, KHÔNG xuyên-trường).
- **Role PH thật trong DB = `primary_parent`** (13 dòng; KHÔNG có `secondary_parent` hiện tại — nhưng `homePathForRole` để ngỏ cả hai).
- **2 login giữ từ v22:** GV Lê Thảo My + PH Trần Quốc Toản.
- **`link_role` lưu CODE** `mother`/`father`/`guardian`; legacy seed = `primary`/`secondary` (UI render cả hai).
- **`master_admin` ∈ `is_school_admin()`**; PH `school_id=NULL` cần RPC curated cho ghi (D29) lẫn đọc (D92).
- **`school.index` giữ `ssr:false`** — màn auth-gated nhiều fetch client-side; shell `school.tsx`/`teacher.tsx`/`parent.tsx` KHÔNG đặt ssr:false (kế thừa guard pathless `_authenticated/route.tsx`).
- **Engine media-nhạy-cảm = 5 gate secdef nhận-tham-số:** consent ảnh trẻ (D71) · entitlement học liệu (D75) · upload (D77) · share (D87) · revoke (D94).

---

> **KỶ LUẬT VÀNG:** đã cập nhật **RULES** (mở rộng D95 — khuôn tách cổng nhân 3 lần, accent-per-cổng amber/sky/emerald, cầu 2-chiều staff↔teacher↔school, vá-dead-link-sau-rename là bước bắt buộc của slice, index-route thay redirect-hop; footer v25) + **SYSTEM_MAP** (bump v0.25, dòng nghiệm thu v25, route map 4 cổng tách + `/kid` reserved, routing 4 nhánh) trong phiên này. **3 file xuất kèm:** `DMA_HANDOFF_v25.md` · `DMA_RULES.md` · `DMA_SYSTEM_MAP.md`. **KHÔNG file SQL/Edge mới** (phiên thuần UI, auto-synced). **START_HERE: KHÔNG đổi** (§2 "Năm cổng" đã đúng từ v24). **Tài liệu A–G, BUILD_PATH, DMWS_REFERENCE: KHÔNG đổi.**
