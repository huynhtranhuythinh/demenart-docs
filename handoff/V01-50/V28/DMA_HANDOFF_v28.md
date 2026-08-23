# 🤝 DMA_HANDOFF_v28.md — BÀN GIAO PHIÊN (VÁ ROUGH EDGE GV + CHỐT DESIGN NORTH-STAR + LỘ TRÌNH V1/V2/V3 + KHOÁ V1 SCOPE — 2026-06-28 09:48 GMT+7)

> **Cách dùng:** File này = ảnh chụp trạng thái cuối phiên v28. Boot phiên sau:
> `00_START_HERE` → `RULES` → file này. Rồi audit DB/code thật trước khi viết.
> **Naming:** DMA = nền tảng; CTAN = sản phẩm đầu. Không "DMMA".

---

## 1. LÀM GÌ PHIÊN NÀY

Phiên **bản lề**: 1 vá engine nhỏ + 1 dọn dead-link + **rất nhiều quyết định chiến lược định hình cả chặng tiếp theo (V1 nội thất → pilot)**.

**(A) Engine — mig 045 (D92/D45/D94): vá rough edge GV read-only.**
- Nới gate RPC `get_child_parents` thêm `lead_teacher`/`assistant_teacher` same-school (read-only), giữ điều kiện `v_school_id = any(user_school_ids())`. GV cùng-trường giờ THẤY nhãn PH (read-only, Quyết B sống); GV trường khác vẫn chặn.
- 3 khối tách (D92): CREATE → HARDEN REVOKE/GRANT → VERIFY-soi-proacl. **Nghiệm thu login thật ĐẠT** (GV KHM Mỹ Linh bấm bé An → panel PH hiện "Nguyễn Văn Hùng"+email, banner chỉ-đọc còn, hết toast lỗi).
- DB cấu trúc KHÔNG đổi (CREATE OR REPLACE 1 hàm sẵn): **46 bảng · 50 hàm definer · 125 policy.** Chỉ mig 044→**045**.

**(B) Dọn 2 dead-link/cosmetic `/admin`** (nợ §6 v26 — Jean đã áp Lovable): nút "← Quay lại" `admin.modules.tsx` `to="/portal"`→`/admin` + text "/portal/curriculum"→"/teacher/curriculum" trong `admin.curriculum-admin.tsx`.

**(C) ⭐ CHỐT CHIẾN LƯỢC (output quan trọng nhất phiên — xem §8 chi tiết):**
1. **V1-nội-thất-TRƯỚC → mở pilot; `/kid` để V2 sau** (cửa khoá "Sắp ra mắt" để sẵn ở tầng UI).
2. **Design north-star = bộ 6 mockup KTS** Jean cung cấp (gate/parent/school/teacher/admin/kid). Đẹp, bắt đúng hồn → giữ làm ĐÍCH. Gu chốt: **"album con / vui trẻ thơ"**, neo **màu thương hiệu `#149A76`** (sample từ logo thật) + linh vật dế.
3. **Lộ trình V1/V2/V3 xếp lớp** + **Miu Nắng (AI bạn-đồng-hành) tách thành QUYẾT-ĐỊNH-RIÊNG** (V3, chỉ chừa hook — KHÔNG hấp thụ qua mockup).
4. **Audit DB thật (D1 → D97) khoá V1 scope:** 9/12 khối lõi V1 engine ĐÃ CÓ (chỉ chờ nội thất); Dashboard cần RPC đếm nhẹ; reaction (flex, em quyết lúc build); chat/hẹn-giờ/xuất-PDF/AI = dồn V2/V3.

> **D97 MỚI (bài học vàng phiên này):** *mockup/phối cảnh đẹp ≠ engine có; audit DB thật trước khi để hình định nghĩa scope.*

---

## 2. TRẠNG THÁI THẬT CUỐI PHIÊN

- **DB cấu trúc:** **46 bảng · 50 hàm SECURITY DEFINER · 125 RLS policy · mig 001→045 · seed 001→012.** SYSTEM_MAP **v0.26** (KHÔNG bump — vá 1 hàm, schema/route KHÔNG đổi).
- **mig 045** = CREATE OR REPLACE `get_child_parents` (gate nới GV same-school read-only). KHÔNG bảng/hàm/policy mới.
- **Edge Functions (6 — KHÔNG đổi):** `get_signed_media_url` · `upload_media` · `resolve_share_link` · `invite_master` · `invite_staff` · `invite_parent`.
- **Routes app KHÔNG đổi** (từ v26): 5 cổng `/parent`(amber)·`/teacher`(sky)·`/school`(emerald)·`/admin`(slate) đã tách + `/portal` shell hạ-tầng trung tính + `/kid` reserved V2. `/share/$token` public.
- **3 tenant / 3 master** (DEMO-001 · KHM-DN · MNDM-DN).

---

## 3. FILE PHIÊN NÀY

**MỚI lưu repo (Jean lưu tay):**
- `045_widen_get_child_parents_gate.sql` (migration — 3 khối CREATE/HARDEN/VERIFY; đã chạy live, dump trung thực D90).

**Đã áp Lovable (auto-sync GitHub, KHÔNG lưu tay):**
- `admin.modules.tsx` (`to="/admin"`) · `admin.curriculum-admin.tsx` (text `/teacher/curriculum`).

> **KHÔNG mockup nào là code production** — bộ 6 hình + 2 file HTML mockup phiên này (`dma_mockup_3ban.html`, `dma_banB_hoanthien.html`) là **tài liệu hướng thiết kế**, KHÔNG bê thẳng vào app (D97 — hình ≠ engine; nền full-bleed hại đọc/tải mobile sẽ phải tiết chế khi build thật).

---

## 4. NGHIỆM THU

**Login thật (mig 045 — D2/D3):** GV KHM **Đặng Mỹ Linh** (`gv.linh.kidshouse@demo.demenart.com`) → `/school` tab Trẻ&PH → bé An → panel "Phụ huynh của bé" hiện **Nguyễn Văn Hùng + email + badge primary + Đã đăng nhập**; banner "Bạn đang xem ở chế độ chỉ đọc" còn (Quyết B); hết toast "không có quyền". Isolation: gate same-school qua `user_school_ids()` giữ — GV không thấy PH trường khác. ✅

**Verify proacl (khối 3):** `grantees=[authenticated,postgres,service_role]` · `leaky=[]` · `gate_has_teacher=true`. ✅

**Audit V1 (D1 → khoá scope) — đối chiếu mockup ↔ DB thật:**
- ✅ Điểm danh = cột `child_observations.attendance` (KHÔNG bảng riêng — `has_attendance=0` đánh lừa).
- ✅ Lesson Player có nội dung = `lesson_versions.{activities,guiding_questions,objectives,materials,checklist,observation_criteria}`.
- ✅ Ghi nhận/tag bé = `child_observations` (skills_observed/is_highlight/needs_support/linked_moment_ids).
- ✅ PH journal/hành trình/kho ký ức = `get_child_journal` {journey,skills,badges,moments} + media Edge.
- ❌ **Thiếu thật:** reaction (`has_reactions=0`) · chat PH↔GV (`has_messages=0`) · dashboard tổng hợp (`public_views=[]`, không hàm `*_stats`).

---

## 5. ⭐ BẢNG TÀI KHOẢN TEST (mỗi lần nhờ test PHẢI ghi email kèm)

> Tất cả `@demo.demenart.com`, password **`Test@123`** (auto-confirm), trừ super_admin (password của Jean) + 2 login giữ-từ-v22 dùng password tạm.

| Vai | Email | Người / Trường | Land sau login |
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

> **DEMO-001 (sandbox, login chưa gắn — `user_id` NULL trong seed):** master `master.demo@demenart.com` · GV `teacher.demo@demenart.com` · PH `parent.demo@demenart.com` (Bé Jenny/Jimmy).

---

## 6. VIỆC TREO (ưu tiên giảm dần)

1. 🟡 **CHỐT 1 LINH VẬT trước khi build UI** (phát sinh v28): đang có **3 phiên bản** — dế sắc-cạnh (logo gốc) · dế tròn-cute (mockup KTS) · Miu Nắng tóc-tím (AI, V3). Loạn nhận diện nếu không chốt. → Quyết trong pass nội thất.
2. **GV/PH pilot còn lại chưa login** (4 GV + 9 PH) → mời nốt qua app khi cần (engine D93 đủ).
3. **2 file nhạc curriculum gốc chưa nguồn lưu** (`.mp3` thật, KHÔNG phải SQL) · **Vercel project dormant** xóa được.

> ✅ **Đã gạch phiên này:** mig 045 vá rough edge GV read-only (nghiệm thu login thật) · 2 dead-link/cosmetic `/admin` · chốt design north-star + lộ trình + khoá V1 scope.
> ✅ **Đóng từ trước:** Ngã A 4/5 cổng tách (v24–26) · giỏ nợ repo SẠCH (v27 — `044`+2 Edge+seed theo phạm vi).

---

## 7. NGÃ KẾ — ĐỀ XUẤT

**Vào pass NỘI THẤT V1 (đã chốt là phase kế).** Jean dẫn gu; Claude đề-xuất-trước rồi Jean layer ý vào bản sau.

- **⭐ A — Pass nội thất V1 (UI/UX polish có định hướng):** chốt design direction từ bản B mockup ("album con / vui trẻ thơ", `#149A76`, dế) → áp nhất quán 5 cổng: accent nội-thân (vd `school.index` amber→emerald) + **mobile nav** (4 cổng `hidden sm:inline-flex` → mobile mất nav — lỗi thật) + cánh cửa `/kid` khoá ("Sắp ra mắt" ở `/parent`) + chốt 1 linh vật (§6.1). *Polish cái-đã-có → ra pilot được.*
- **B — Dashboard LITE (thêm engine nhẹ):** vài RPC đếm thật (lớp/HS/GV/% PH-xem) cho `/school` — phần duy nhất trong V1 cần thêm engine.
- **C — Reaction (flex):** thêm 1 bảng + RPC "thả tim/cảm ơn" nếu hợp lúc build (em nghiêng thêm — hợp hồn PH↔GV).

**Boot phiên sau:** đọc HANDOFF v28 → audit live DB/route thật (D1) trước khi viết.

---

## 8. ⭐ QUYẾT ĐỊNH CHIẾN LƯỢC + DATA STATE CẦN NHỚ

### 8a. Lộ trình V1 / V2 / V3 (xếp lớp từ bộ 6 mockup — D97)

- **🟢 V1 (nội thất + pilot):** Gate/login/mời (✅) · PH nhật ký+kho ký ức+hành trình gọn (✅ `get_child_journal`) · GV Hôm nay/Lesson Player/điểm danh/ghi nhận/gửi-PH ngay+nháp (✅ `lesson_versions`+`child_observations`+moments) · Admin quản lý+ticket (✅) · **Dashboard LITE** (⚠️ thêm RPC đếm) · **reaction** (flex) · mobile nav+design system (❌ làm pass này) · cửa `/kid` khoá (✅ reserved).
- **🟡 V2 (cổng `/kid`):** trang chủ bé + PIN (ba mẹ duyệt — thép chờ #2 `children.identity_user_id`) · kho báu/huy hiệu cho bé · age modes 0–3/4–6/7–12 (mới).
- **🔴 V3 (sản phẩm mới — đừng để định nghĩa lại V1):** gamify sâu (bản đồ/quest/mini-game) · xuất PDF/video recap/số nghệ thuật · tài chính/công nợ/doanh thu (Mission Control) · AI insights/gợi-ý-nhật-ký/ghi-giọng-nói · ngôi-nhà/căn-phòng đôi bạn.
- **⚠️ Miu Nắng (AI bạn-đồng-hành) = QUYẾT-ĐỊNH-RIÊNG, KHÔNG xếp V-nào tới khi Jean quyết có/không.** Là SẢN PHẨM riêng (AI chat với trẻ 3–6: an toàn trẻ em, kiểm duyệt, chi phí, pháp lý). Engine 0 mảnh. Đề xuất: V3, chỉ chừa hook ở V1/V2.

### 8b. Design tokens chốt
- **Màu thương hiệu = `#149A76`** (xanh ngọc Dế Mèn — sample trực tiếp từ logo `De_Men_logo_-_Web_logo.png`, đồng nhất 2 file). Linh vật = dế.
- **Gu = "album con / vui trẻ thơ"** (nghiêng vui-sắc-màu-trẻ-thơ, vẫn ấm-tinh-tế theo linh hồn); cảm giác chủ đạo **hướng phụ huynh**.
- **Ràng buộc:** giữ màu/logo Dế Mèn. Cửa `/kid` luôn để dạng "nhìn thấy nhưng khoá" (thép chờ tầng UI).

### 8c. Data state (bẫy — GIỮ từ v23/v24)
- **KHM-DN `sharing_mode=private_share_link`** · **DEMO-001 `no_external_sharing`**.
- **Consent An `private_share_link` (`d1…e1`) = GRANTED** (v23 test) + download consent An bật.
- **DEMO-001 trung thực D90:** 1 moment `draft` · consent `demen_marketing granted=false` · 2 media `bunny_path` (re-upload sau phục hồi).
- **DEMO-001 UUID NGẪU NHIÊN** (`b6a4ac35…`) KHÔNG prefix → lọc tenant FK-ngược (D96).
- **PH 051 mỗi trường = 2-con-xuyên-lớp.** **Role PH thật = `primary_parent`.**
- **`master_admin` ∈ `is_school_admin()`**; PH `school_id=NULL` cần RPC curated cả ghi (D29) lẫn đọc (D92 — nay nới GV same-school read-only, mig 045).
- **`school.index` giữ `ssr:false`**; shell `{admin,school,teacher,parent}.tsx` KHÔNG đặt ssr:false (kế thừa guard pathless).
- **`/portal` = shell hạ-tầng** (notifications+support); else→`/admin`.
- **Engine media-nhạy-cảm = 5 gate secdef:** consent (D71) · entitlement (D75) · upload (D77) · share (D87) · revoke (D94).
- **Repo dump trung thực (D90/D96):** mọi backup từ live; seed theo phạm vi (global→tenant), phục hồi global-TRƯỚC.

---

> **KỶ LUẬT VÀNG:** đã cập nhật **RULES** (thêm **D97** — mockup đẹp ≠ engine có, audit DB thật trước khi để hình định nghĩa scope; ghi nghiệm thu v28 vào **D92** — gate `get_child_parents` nới GV same-school read-only; footer v28) + **SYSTEM_MAP** (footer v28, mig→045, **KHÔNG bump v0.26** — vá 1 hàm) trong phiên này. **3 file xuất kèm:** `DMA_HANDOFF_v28.md` · `DMA_RULES.md` · `DMA_SYSTEM_MAP.md`. **1 file repo Jean lưu tay:** `045_widen_get_child_parents_gate.sql`. **START_HERE: KHÔNG đổi.** **Tài liệu A–G, BUILD_PATH, DMWS_REFERENCE: KHÔNG đổi.** **Mockup HTML = tài liệu hướng thiết kế, KHÔNG phải code production (D97).**
