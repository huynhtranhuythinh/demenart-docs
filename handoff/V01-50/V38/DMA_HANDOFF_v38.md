# 🧾 DMA_HANDOFF_v38.md — NỘI THẤT SCHOOL V1: "TỔNG QUAN TRƯỜNG" (mig 059, D113) — 2026-06-30 02:13 GMT+7

> **Boot phiên sau:** đọc `DMA_00_START_HERE.md` → `DMA_RULES.md` → file này. Audit live trước khi viết code (D1).
> **Phiên này = BUILD** (nhánh B): +1 RPC school-scope + 1 file UI. KHÔNG đụng bảng/policy/Edge.

---

## ⭐ LÀM ĐƯỢC PHIÊN NÀY

Nối v37 (dọn nợ repo). Jean chốt **(A) vào Nội thất School** rồi chốt nhánh **(B)**: dựng những khối CÓ engine thành "Tổng quan trường", khối chưa có engine để cửa-khoá "V1.5". Đây là **cổng thứ 3 hoàn thiện demo-grade** (sau Admin Mission Control v36 + Teacher V1), đúng thứ tự demo bán nhà trường (Admin→School→Teacher).

### Bối cảnh "Ánh Dương" (D97 + vá library)
Jean đưa lại mockup School Portal "Trường Mầm Non Ánh Dương" (sidebar emerald, 7 KPI, gauge sức khỏe, tiến độ theo lớp, khoảnh khắc, lịch tuần, báo cáo PDF, tương tác PH donut, lời cảm ơn). **Mockup này KHÔNG có trong library** (handoff/RULES/SYSTEM_MAP không ghi) — tra past chats thấy v35 là mockup "Mission Control" cho **Admin**, không phải School. ⇒ direction School "Ánh Dương" từng **rớt khỏi library** (lỗ KỶ LUẬT VÀNG). Ghi nhận tại đây để vá.

**Đối chiếu D97 (mockup ↔ engine thật) — chia 3 nhóm:**
- ✅ **CÓ engine V1:** KPI lớp/HS/GV/buổi-đã-dạy/nhật-ký%/media% · lịch buổi · tiến-độ-theo-lớp · khoảnh khắc (staff xem D58) · hỗ trợ (`support_requests`) · thông báo (`notifications`).
- ⚠️ **CHƯA có engine:** "PH đã xem %"/donut tương tác PH/lượt-xem (DMA **KHÔNG log lượt xem PH** — D110) · thả tim/Lời-cảm-ơn (reaction hook=0, chưa bảng `parent_reactions`) · gauge "Sức khỏe" (chỉ có `get_admin_school_health` admin-scope, chưa school-scope).
- ❌ **DEFER V2:** Báo cáo nhanh PDF + Recap video (post-V1 deferral).
- ⚠️ **Data mỏng:** mockup ghi 12 lớp/286 bé/24 GV; thật trường lớn nhất = 2 lớp/8 bé/4 GV ⇒ thiết kế thin-state ấm, không tô vẽ.

### Audit D1 (2 vòng) — engine/data thật cổng School
- **Vòng 1:** `/school` chỉ 3 file: `school.tsx` (shell emerald đúng) · `school.index.tsx` (toàn cổng = 1 trang 3 tab CRUD: Lớp&Môn/GV/Trẻ&PH + mời GV/PH login) · `admin.school-onboarding.tsx` (thuộc `/admin`). **School KHÔNG có RPC dashboard** (chỉ CRUD/onboard); index query bảng thẳng qua RLS same_school. **2 phát hiện:** (a) `school.index.tsx` lẫn **amber** (màu Parent) — di sản copy `parent.tsx`; (b) không có khoảnh-khắc "chào & nắm trường", vào thẳng bảng CRUD.
- **Vòng 2:** đường-nối thật — `lesson_sessions.class_distribution_id → classes.school_id` · "buổi đã dạy" = state `taught_report_pending`/`report_pending_approval`/`completed` · `cd.state`/`session_reports.state` là **text** (`'active'`/`'submitted'`, không enum) · **trường Dế Mèn d2 = 0 buổi** (ép thin-state). ⭐ **Đường media↔buổi = `learning_moments.session_id`, KHÔNG `session_media`** (bảng đó trống — D113).

### Engine (mig 059) — `get_school_overview()`
1-call gói `{ok, kpi{classes,students,teachers,sessions_done,journal_sent_pct,media_pct}, classes[]{distribution_id,class_name,program_name,progress_done,progress_total,journal_pct,status}}`. Gate `current_school_id()` (KHÔNG nhận `school_id` → chống lộ chéo). secdef · `search_path=''` qualify `public.` · 3 khối D92 · re-harden D15 (revoke anon riêng). **Mẫu số % = "buổi đã bắt đầu dạy"** (`in_progress` trở đi). `status`: ≥80 good · 50–79 attention · <50 support · 0-buổi not_started.

### UI (Jean áp Lovable full paste-over D95) — `school.index.tsx`
Thêm `OverviewSection` lên đầu (lời chào + 6 KPI tile kem-ấm emerald + Tiến-độ-theo-lớp progress bar + pill status) + 3 liên-kết-nhanh (Khoảnh khắc/Hỗ trợ/Thông báo) + 2 **cửa-khoá "Sắp ra mắt·V1.5"** (Sức khỏe triển khai · Tương tác PH). Sửa **drift amber→emerald** (icon tiêu đề · thẻ active 2 chỗ · viền panel 2 chỗ · banner chỉ-đọc); GIỮ amber ở dialog mật-khẩu-tạm (cảnh báo hợp lệ). Thin-state ấm. **3 tab cũ giữ nguyên logic.** `school.tsx` KHÔNG đụng.

### 2 bug bắt trong phiên (sửa ngay, vẫn 1 RPC)
1. **media_pct 0% sai** — đo nhầm `session_media` (trống) → sửa `learning_moments.session_id` (loại rejected/archived). Login lại: 0%→**50%** ✅ (D113).
2. **status quá gắt** — Hoa Hồng/CTAN nhật-ký 50% bị "Cần hỗ trợ" (đỏ) → nới ngưỡng 80/50 → **"Cần chú ý"** (vàng) ✅.

### Nghiệm thu login thật ĐẠT (2 trường)
- **KidsHouse** (`hieutruong.kidshouse@demo.demenart.com`/`Test@123`): Lớp 2 · HS 8 · GV 4 · Buổi-đã-dạy 1 · Nhật-ký 50% · **Media 50%** · 4 dòng tiến độ status hỗn hợp (Hoa Hồng/CTAN "Cần chú ý", 3 dòng còn lại "Chưa bắt đầu"). **Mọi số khớp audit.**
- **Dế Mèn** (`hieutruong.demen@demo.demenart.com`/`Test@123`): Lớp 2 · HS 6 · GV 3 · Buổi 0 · Nhật-ký/Media "—" · 2 dòng "Chưa bắt đầu". **Thin-state hoàn hảo.**
- Verify khối 3: `prosecdef=true · search_path="" · grantees {authenticated,postgres,service_role}` (leaky=[]).

---

## 🆕 D-RULE MỚI — **D113** (append vào RULES)
**D113 — RPC dashboard-scope phải đo ĐÚNG NGUỒN; audit đường-nối thật trước khi đếm.** "Buổi có media" đo qua `session_media` cho **0% sai** vì khoảnh khắc đi qua `learning_moments.session_id` (bảng `session_media` trống). Bài học: mỗi metric tổng-hợp phải truy ra **bảng chứa data thật** (audit D1 đường-nối), KHÔNG đoán theo tên-bảng-nghe-hợp-lý. Hệ quả pattern: với mọi RPC đếm (Dashboard-LITE/aggregate), liệt kê từng metric → bảng nguồn → xác nhận có data (login thật), TRƯỚC khi tin con số. (Cùng họ D97/D99: mockup/tên gợi-ý ≠ engine thật.)

---

## 📊 TRẠNG THÁI DB
- **52 bảng · 66 hàm definer (+`get_school_overview`) · 137 policy* · mig 001→059 · seed 001→014 · 7 Edge · 3 tenant/3 master.**
  - *(*) policy: drift `notification_sounds_select_enabled` (mig 057) vẫn CHƯA chạy từ v37 → thực tế có thể **136**. Chưa đụng phiên này.*
- **SYSTEM_MAP v0.34 (BUMP — +1 hàm + route school.index Tổng quan).**
- **Routes:** sửa `_authenticated/school.index.tsx` (full paste-over). `school.tsx` KHÔNG đổi.
- **accent `/school`:** drift amber đã dọn → emerald nhất quán (trừ dialog mật-khẩu-tạm giữ amber).

---

## 🔧 VIỆC TREO

**Mới phát sinh / nối tiếp:**
- ⭐ **Nội thất School v2** = phiên kế tiếp ĐÃ CHỐT (hướng A — xem mục KẾ TIẾP: Lịch tuần + Khoảnh khắc + sidebar tỉa + tên trường + Hỗ trợ/Thông báo inline).
- 🟢 (HOÃN sau School v2) Sức khỏe triển khai school-scope → `get_school_health` (mirror admin, bỏ trụ Tương-tác-PH D110).
- 🟢 (HOÃN sau School v2) Nội thất Teacher demo-grade = cổng demo CUỐI.

**Mang theo (chưa đụng):**
- 🟡 Drift `notification_sounds_select_enabled` (mig 057 chưa chạy — xác nhận policy count 136/137 + chạy 057 khôi phục read thư viện âm cho PH/GV).
- 🟢 Admin: wire nút "Xử lý" Action Center · re-theme trang con admin sang cosmic (D111) · điền `route` ~50 module → nav data-driven (gỡ D109).
- 🟡 Tương tác PH thật (cửa V1.5 thứ hai): cần log-xem-PH + reaction "Lời cảm ơn" (`parent_reactions`) — quyết-riêng.
- 🟡 Nợ cũ: dọn seed `[v29-test]`+demo_seed · 2 PH email-null · GV/PH pilot chưa login · 2 file nhạc curriculum · Vercel dormant · **lock 1 linh vật** · blur-mặt V2 · `pwa.theme_color` `#E11D63`→brand khi chốt theme.

**Library:**
- ✅ Bản `DMA_RULES.md` snapshot phiên này kết footer ở **v37** (đủ D108–D112) — KHÔNG tụt. Phiên này append v38+D113.
- ⭐ Direction School "Ánh Dương" nay đã ghi vào handoff (vá lỗ rớt-library). Mockup = north-star, bản build V1 trung-thực-engine (cửa-khoá khối chưa có data).

---

## ▶️ KẾ TIẾP — ⭐ **"NỘI THẤT SCHOOL v2" (hướng A đã CHỐT cuối phiên v38)**

> **Bối cảnh:** sau nghiệm thu, Jean đối chiếu bản build V1 với mockup "Ánh Dương" và thấy build **gọn hơn nhiều** (thiếu sidebar, Khoảnh khắc nổi bật, lịch tuần…). Làm rõ: đó là **chủ ý nhánh B** (khối có-engine dựng thật, khối chưa-engine cửa-khoá), KHÔNG phải sót. Jean chốt mở **phiên build mới** kéo bản School **sát mockup** mà vẫn trung-thực-engine (không bịa số). Phân loại D97 dưới đây là scope phiên sau:

**① THÊM — đều CÓ engine thật, làm được V1 (trọng tâm phiên sau):**
- **Lịch triển khai tuần** (grid lớp × ngày) — khối mạnh nhất mockup; engine đủ (`lesson_sessions.scheduled_at`+`state`). → cần **RPC mới** `get_school_week_schedule(p_week_start date)` (hoặc gói vào overview có tham số tuần). Trạng thái ô: hoàn thành / sắp diễn ra / đổi lịch (rescheduled/makeup) / thiếu nhật ký (taught_report_pending) / không có lịch.
- **Khoảnh khắc nổi bật** (4 ảnh play) — `learning_moments` approved, staff xem (D58). → **build khối riêng** + tái dùng **Edge ký URL media private** (đã có ở Teacher/Parent — D-rule media: private không URL vĩnh viễn). KHÔNG nhét vào RPC overview.
- **Hỗ trợ + Thông báo dạng list inline** (giờ mới là link-nhanh) — `support_requests`/`notifications` query thẳng RLS.
- **Tên trường thật** ở header (giờ ghi cứng "Quản lý Trường") — thêm `schools.name` vào `get_school_overview` (1 field).
- **Gợi ý cho trường** (3 card) — nội dung tĩnh, thuần UI.

**② ĐỂ CỬA-KHOÁ tiếp (CHƯA engine — đừng build vội):**
- Sức khỏe 82/100 → cần `get_school_health` school-scope (mirror admin, bỏ trụ Tương-tác-PH D110).
- Donut Tương tác PH + Lời cảm ơn PH + cột "PH xem %" → KHÔNG log-xem-PH (D110) + reaction chưa bảng `parent_reactions`.
- Delta "↑ so tuần trước" mỗi KPI → cần snapshot lịch-sử-tuần (chưa có) → tạm bỏ, KHÔNG bịa.
- Báo cáo PDF / Recap video → DEFER V2.

**③ SIDEBAR — quyết định KIẾN TRÚC, không chỉ thẩm mỹ:**
Mockup có sidebar ~14 mục nhưng **phần lớn trỏ trang chưa tồn tại** (Lịch triển khai, Nhật ký lớp, Media&Tác phẩm, Tương tác PH, Phụ huynh, Báo cáo…). Làm full = 10 mục "sắp ra mắt" → vỏ rỗng, phản tác dụng demo. **Khuyến nghị: sidebar TỈA GỌN** — chỉ mục có thật (Tổng quan · Lớp&Môn · Giáo viên · Trẻ&PH · Khoảnh khắc · Hỗ trợ) + 2-3 mục khoá mờ "V1.5". (Thay top-nav hiện tại bằng sidebar trái emerald — cần đụng `school.tsx` shell lần này, khác v38.) Surface cho Jean chọn: sidebar-tỉa vs giữ top-nav, TRƯỚC khi build.

**Việc kỹ thuật dự kiến phiên sau:** (a) `get_school_overview` +field `school_name`; (b) RPC lịch tuần mới (3 khối D92); (c) khối Khoảnh khắc + Edge ký media (tái dùng); (d) `school.tsx` → sidebar tỉa gọn; (e) Hỗ trợ/Thông báo inline. **Audit D1 trước:** xác nhận Edge ký-media nào tái dùng được + cột `lesson_sessions` cho lịch tuần (đã có scheduled_at/state/title từ audit v38).

*Boot phiên sau → audit D1 (Edge media + lịch tuần) → đề xuất 3 hướng layout sidebar (D98) → build từng khối, nghiệm thu login thật 2 trường (D2/D3, KidsHouse có-data + Dế Mèn thin-state) → HANDOFF v39. Đo đúng nguồn (D113). Cập nhật "tới đâu ghi tới đó" (KỶ LUẬT VÀNG).*

> **Hoãn lại (không mất):** Nội thất Teacher demo-grade (cổng cuối) + `get_school_health` → sau Nội thất School v2.
