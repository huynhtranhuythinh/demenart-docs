# 🧾 DMA_HANDOFF_v39.md — NỘI THẤT SCHOOL v2 + FINISHING 3-ZONE + 4 ROUTE `/school/*` SINGLE-SOURCE (mig 060–062, D114/D115) — 2026-06-30 ~04:30 GMT+7

> **Boot phiên sau:** đọc `DMA_00_START_HERE.md` → `DMA_RULES.md` → file này. Audit live trước khi viết code (D1).
> **Phiên này = BUILD + IA** (nối v38): +2 RPC school-scope + tổ chức lại UI 3 zone + tách trang quản lý + 4 route `/school/*` single-source. KHÔNG đụng bảng/policy/Edge.

---

## ⭐ LÀM ĐƯỢC PHIÊN NÀY

Nối v38 (Tổng quan School V1). Jean yêu cầu kéo School **sát mockup "Ánh Dương"** mà vẫn trung-thực-engine, sau đó bắt **2 vấn đề kiến trúc IA** → đóng trọn. Cổng School giờ **vận hành thật, liền mạch**, demo-grade.

### 1) Nội thất School v2 + Finishing (UX/UI, không schema)
`school.index.tsx` tổ chức lại thành **3 zone** + skin premium kem-ấm:
- **ZONE 1 — Sức khỏe trường:** Welcome card (tên trường thật + check) · 6 KPI premium (icon nhất quán, số `26px`, shadow mềm, **viền honey + ring khi %<50** = cần chú ý) · **Sức khỏe triển khai (Lite)** = vòng điểm `/100` tính **CLIENT-SIDE** từ trung-bình 3 chỉ-số THẬT (tiến-độ tổng-hợp Σdone/Σtotal + nhật-ký% + media%), badge good/attention/support, ghi rõ "Bản Lite · ước tính từ chỉ số hiện có", bản đầy đủ V1.5 — **KHÔNG bịa số** (D97/D110).
- **ZONE 2 — Bức tranh thành công:** Tiến-độ-theo-lớp (bar gradient + **badge chấm-màu**: green Tốt/honey Cần-chú-ý/coral `#F2683C` Cần-hỗ-trợ/slate Chưa-bắt-đầu + CTA "Quản lý lớp") · Lịch triển khai tuần (grid, nav tuần) · Khoảnh khắc (4 ảnh signed + nhãn **🛡 Nội bộ trường** + dòng nhắc đồng-ý PH) · **Tương tác PH** = preview sang-trọng (🔒 "—", badge "Sắp ra mắt·V1.5", **KHÔNG số ước đoán** — không phải hộp gạch khoá).
- **ZONE 3 — Hỗ trợ & vận hành:** Hỗ trợ + Thông báo inline (empty-state ấm "…Mọi thứ đang ổn 🌿") · Gợi ý cho trường (3 card CTA honey-forest).
- Premium-card chung `CARD` (viền `#EAE2D0` + shadow mềm + rounded-2xl); nền ivory `#FBF8F1`; sidebar forest gradient 3-nấc + sheen (`school.tsx`).

### 2) Engine (mig 060–062) — 3 RPC school-scope
Cả 3: secdef · `search_path=''` qualify `public.` · gate **`current_school_id()`** (KHÔNG nhận `school_id` → chống lộ chéo tenant) · 3 khối D92 · re-harden D15 (REVOKE public **+ anon** riêng + GRANT authenticated/service_role) · verify aclexplode leaky=[].
- **mig 060** `get_school_overview` **REPLACE** — +field top-level `school_name` (SELECT `schools.name`). *(Bẫy D114 — xem dưới.)*
- **mig 061** `get_school_week_schedule(p_week_start date)` **MỚI** — grid distribution×7-ngày; match buổi theo `(scheduled_at AT TIME ZONE 'Asia/Ho_Chi_Minh')::date`; trả `{ok, week_start, days[7], rows[]{distribution_id,class_name,program_name,cells[7]{date,sessions[]{session_id,state,title,scheduled_at}}}}`.
- **mig 062** `get_school_moments(p_limit int default 4)` **MỚI** — moment `approved` + media-asset đầu (state active) qua **LATERAL**; trả `moments[]{moment_id,caption,theme_tag,class_name,created_at,media_id,file_type,bunny_path,bunny_storage_zone}` desc. Ảnh ký URL qua Edge `get_signed_media_url` (D74; staff bypass consent D58 → Master luôn xem được).

### 3) Tách trang Quản lý (vá IA — Jean bắt #1)
Trước: bấm Lớp&Môn/Giáo viên/Trẻ&PH → vẫn đứng trang Tổng quan rồi cuộn xuống đáy khối CRUD → cảm giác "menu không đi đâu / chỉ là dashboard". **Sửa:** `?tab` đổi **NGUYÊN TRANG** — `SchoolManager` rẽ nhánh `DashboardView` (no-tab) vs `ManagementView` (có-tab, breadcrumb "‹ Tổng quan" + tiêu-đề-trang + Tabs 3-module + CRUD verbatim), cuộn-lên-đầu khi đổi view. CTA "Quản lý lớp" ở dashboard → `?tab=classes`. CRUD giữ **100% verbatim** từ v38.

### 4) Tích hợp 4 route `/school/*` single-source (vá IA — Jean bắt #2, D115)
Trước: Học liệu/Khoảnh khắc → `/teacher/*` (shell "Phòng Giáo viên"); Hỗ trợ/Thông báo → `/portal/*` (shell "DMA") → bấm là **văng khỏi Cổng Trường xanh** = rời rạc. **Sửa (Option A):**
- Tách thân 4 trang thành **shared component** `@/components/portal/{Curriculum,Moments,Support,Notifications}View.tsx` (`export function XView()`).
- TẠO 4 route `/school/{curriculum,moments,support,notifications}` (ssr:false) = wrapper mỏng mount view → **tự nằm trong shell xanh** (children của layout `/school`).
- ĐÈ 4 route cũ `teacher.{curriculum,moments}`·`portal.{support,notifications}` thành wrapper mỏng cùng-view → **một nguồn sự thật, không trùng lặp**. `/portal` vẫn là bản gốc trung-tính.
- Sidebar (4 link) + chuông + link "Xem tất cả" + Gợi ý → đổi sang `/school/*`. **8 mục sidebar đều ở trong Cổng Trường xanh, không-văng.**

### 🆕 2 D-RULE (đã append RULES)
- **D114 [SQL/verify]** — body-change của secdef RPC verify bằng `pg_get_functiondef`/login thật; `aclexplode` chỉ kiểm secdef+grant KHÔNG kiểm thân-hàm. *(mig 060 thân-mới `school_name` không-áp [Jean lỡ chỉ chạy khối 2+3] mà VERIFY vẫn pass → header fallback "Trường của bạn"; chẩn `position('school_name' in pg_get_functiondef(...))=0`; chạy lại khối 1 → fix. Cùng họ D2/D85/D112.)*
- **D115 [stack: Lovable/TanStack]** — nội dung dùng-chung nhiều cổng = component xuất-khẩu ở `@/components/portal/*`, route chỉ wrapper mỏng; KHÔNG copy code giữa các cây route; thứ tự áp TẠO-shared→TẠO-route→SỬA-link→ĐÈ-route-cũ. Phân biệt với rename-cổng (D95, page-thuộc-1-vai).

### Nghiệm thu login thật ĐẠT (2 trường)
- **KidsHouse** (`hieutruong.kidshouse@demo.demenart.com` / `Test@123`): tên trường + check · KPI 2/8/4/1/50%/50% · Sức khỏe Lite **44/100 "Cần hỗ trợ"** (coral, =avg 33/50/50 đúng) · Tiến-độ-lớp badge chấm-màu · Lịch tuần grid · Khoảnh khắc **3 ảnh signed** + "Nội bộ trường" · Tương tác PH preview · 4 route `/school/*` mount trong shell xanh (curriculum phát nhạc · moments tải ảnh thật "✓ Đã tải" · support gửi "Kỹ thuật"→toast xanh + "Yêu cầu của tôi" hiện ngay "Mới tiếp nhận" · notifications "Bạn đã xem hết") · sidebar active đúng từng mục.
- **Dế Mèn** (`hieutruong.demen@demo.demenart.com` / `Test@123`): thin-state OK.
- Verify mig 060–062: leaky=[] grantees {authenticated,postgres,service_role}.

---

## 📊 TRẠNG THÁI DB
- **52 bảng · 68 hàm definer (+`get_school_week_schedule`/+`get_school_moments`; `get_school_overview` replace-thân) · 137 policy* · mig 001→062 · seed 001→014 · 7 Edge · 3 tenant/3 master.**
  - *(*) policy: drift `notification_sounds_select_enabled` (mig 057) vẫn CHƯA chạy từ v37 → thực tế có thể **136**. Chưa đụng phiên này.*
- **SYSTEM_MAP v0.35 (BUMP — +2 hàm + shell `school.tsx` + 4 route `/school/*` + 4 shared component).**
- **Routes:** TẠO `_authenticated/school.{curriculum,moments,support,notifications}.tsx` + `@/components/portal/{Curriculum,Moments,Support,Notifications}View.tsx`; SỬA `school.tsx`·`school.index.tsx`·`teacher.{curriculum,moments}.tsx`·`portal.{support,notifications}.tsx`.

---

## 🔧 VIỆC TREO

**Nội thất / polish (nối tiếp):**
- 🟢 **Re-skin 4 view** `/school/*` sang hệ ivory/forest/honey (giờ giữ accent **amber** gốc — hợp tông honey nên không chỏi, nhưng chưa premium-card xanh như dashboard).
- 🟢 `get_school_health` school-scope (mở cửa V1.5 thứ nhất; mirror admin, bỏ trụ Tương-tác-PH D110).
- 🟢 Nội thất Teacher demo-grade (cổng demo CUỐI: desktop-nav + cửa khoá đúng-chủ-đích).

**Engine/data (cần audit D1 trước):**
- 🟡 **Nhãn ảnh 3-mức** Consent OK / Marketing-approved (giờ chỉ "Nội bộ trường") → cần thêm field consent/sharing vào `get_school_moments` (1 mig nhỏ + audit cột `learning_moments`/`consents`).
- 🟡 **Tương tác PH thật** (cửa V1.5 thứ hai): cần log-xem-PH + reaction "Lời cảm ơn" (`parent_reactions`) — quyết-riêng.

**Repo / nợ cũ:**
- 🟡 **Lưu repo mig 060–062** dump-từ-live (D90).
- 🟡 Drift `notification_sounds_select_enabled` (mig 057 chưa chạy — xác nhận policy count 136/137 + chạy khôi phục read thư viện âm).
- 🟢 Admin `/admin`: wire nút "Xử lý" · re-theme trang con cosmic (D111) · điền `route` ~50 module → nav data-driven (D109).
- 🟡 Nợ cũ mang theo: dọn seed `[v29-test]`+demo_seed · 2 PH email-null · GV/PH pilot chưa login · 2 file nhạc curriculum · Vercel dormant · **lock 1 linh vật** (rồi thay 🌱 footer sidebar bằng illustration thật) · blur-mặt V2 · `pwa.theme_color` `#E11D63`→brand.

---

## ▶️ KẾ TIẾP — chọn 1
1. **Re-skin 4 view `/school/*`** sang ivory/forest/honey (đồng bộ tuyệt đối shell xanh) — nhẹ, đóng nốt cảm-giác-premium School.
2. **`get_school_health` school-scope** — mở cửa V1.5 thứ nhất (gauge thật thay Lite).
3. **Nội thất Teacher demo-grade** — cổng demo cuối, chuẩn bị pilot.

*Boot phiên sau → audit D1 (cột consent/sharing nếu làm nhãn ảnh; hoặc Edge/route nếu re-skin) → đề xuất hướng (D98) → build → nghiệm thu login thật 2 trường (D2/D3) → verify đúng-nguồn (D113) + verify thân-hàm nếu REPLACE (D114) → HANDOFF v40. Cập nhật registry khi đóng (D106). "Tới đâu ghi tới đó" (KỶ LUẬT VÀNG).*

> **Hoãn lại (không mất):** nhãn ảnh 3-mức · Tương tác PH thật · re-theme Admin cosmic · `/kid` V2.
