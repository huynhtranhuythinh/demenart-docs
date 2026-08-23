# 🛰️ DMA_HANDOFF_v36.md — ADMIN DASHBOARD V1 "MISSION CONTROL"

> **Boot phiên sau:** đọc file này → `DMA_00_START_HERE.md` → `DMA_RULES.md`. Audit live trước khi viết code (D1).
> **Phiên này (2026-06-29 ~20:30 GMT+7):** Build trọn **Admin Dashboard V1 — "DMA Mission Control"** (5 RPC aggregate + 2 file UI). Nghiệm thu login thật super_admin ĐẠT toàn bộ 3 màn.

---

## ⭐ LÀM ĐƯỢC PHIÊN NÀY

### Bối cảnh & quyết định thiết kế (trước khi build)
Pass **Nội thất Admin** (đổi thứ tự từ Parent-first của v35 → **Admin → School → Teacher**, vì demo đầu bán cho nhà trường). Qua nhiều vòng react với Jean, chốt:
- **Hướng (I) lai:** xương DMWS (work-queue thực dụng) + da **tối-vũ-trụ** Mission Control + accent **honey `#EFA63A`** / xanh-rừng `#5DCAA5`. **Admin có bản sắc riêng — TÁCH hệ kem-ấm `#FBF8F1` của cổng khách** (Parent/School/Teacher). Buồng-lái của Jean, khách-cuối không thấy.
- **D97 sống:** mockup Mission Control gốc ~60% là khát vọng (tài chính/phễu/AI chưa có engine) → chỉ thắp card **có engine thật**, phần chưa có → **cửa khoá "Sắp ra mắt".**
- Mockup HTML duyệt: `DMA_Mission_Control_V1_polished.html` (design doc, KHÔNG phải production — D97).

### 2 quyết định product (chốt sau audit D1)
1. **DMA Pulse §5:** Admin chỉ thấy media **`demen_marketing`** granted (PH cho phép truyền thông) — ảnh nội-bộ/private KHÔNG hiện (tôn D48). Hiện data = 0 → **empty-state ấm** "Chưa có khoảnh khắc được phép truyền thông". KHÔNG cần RPC (xây engine cho 0 data = phạm D97); thêm `get_admin_pulse` khi có data.
2. **RPC tách nhỏ** (5 hàm độc lập, mỗi khối loading/error riêng — progressive).

### Engine — mig 058 (5 RPC aggregate admin-scope) ⭐
> Số mig: **058** (tiếp nối v35; nếu v35 = mig 057 thì đúng 058 — xác nhận từ HANDOFF_v35).

Cả 5: `SECURITY DEFINER` · `SET search_path = ''` qualify `public.` đầy đủ · gate `IF NOT public.is_admin()` (else `not_platform_admin`) · bypass-RLS đọc · **CHỈ trả số/tỉ-lệ ẩn-danh (D48 — KHÔNG tên/ảnh trẻ)** · 3-khối D92 · re-harden D15 (`REVOKE FROM PUBLIC, anon` riêng + `GRANT authenticated, service_role`).

1. **`get_admin_health_score()`** → `{total, status, pillars:{ops,media,support,growth}, parent_pillar:'v1_5_pending'}`. **4 trụ** (Ops 35% · Media 30% · Hỗ trợ 20% · Tăng trưởng 15%) — **trụ Phụ huynh BỎ** (audit lộ KHÔNG có log "PH xem nhật ký": không bảng view/read, không cột viewed/read_at/seen) → hoãn V1.5, chuẩn-hoá lại trọng số 4 trụ. Ops = avg(journal-sent ratio, distribution-lead ratio); Media = 100 − tồn-đọng×5; Support = 100 − overdue×15; Growth = avg(enroll-active%, school-active%). status ≥80 Tốt / ≥60 Khá / else Cần chú ý.
2. **`get_admin_vitals()`** → 7 số: schools_active · classes_active · enroll_active · sessions_this_week · journal_sent_pct (buổi đã-dạy đã-submit / đã-dạy) · media_pct · tickets_overdue.
3. **`get_admin_action_center()`** → `{total, items[5]}` mỗi item {key,label,count,severity,owner,sla_hint}. **"File lỗi phát" → "Ticket học liệu"** (media_assets KHÔNG có cờ lỗi-phát; suy từ `support_requests.category='curriculum'`).
4. **`get_admin_school_health()`** → mảng trường {school_id,name,classes,tickets,journal_pct,score,risk}. Path school: `lesson_sessions.class_distribution_id → class_distributions.class_id → classes.school_id`. Ticket theo trường qua `support_requests → profiles.school_id` (xác nhận có cột).
5. **`get_admin_media_privacy()`** → {pending_consent, untagged, private_only, marketing_approved, curriculum_tickets, bunny_private_zone:'unknown'}. Bunny zone health = client/Edge ping, KHÔNG từ DB.

**Verify (3a/3b login thật):** cả 5 grantees `{authenticated,postgres,service_role}` · leaky=[] · A0 `profiles.school_id` có. **KHÔNG test bằng gọi hàm trong SQL Editor** (uid=NULL→is_admin()=false, D2) — test bằng login.

### UI — 2 file (Jean áp Lovable full paste-over D5)
- **`_authenticated/admin.tsx`** — shell **dark cosmic + sidebar trái** (thay header ngang sáng cũ). Nav **hardcode khớp route THẬT** (Vận hành: onboard/giáo trình/sensitive/modules · Hệ thống: reference/notifications/sounds/settings · Hạ tầng: support/notifications) + 3 cửa khoá (Tài chính V1.5 · Kid V2 · Bạn Đồng Hành AI V3). Drawer mobile · unread badge + sign-out chân sidebar. **D-mới: KHÔNG drive nav thuần từ `admin_modules.route`** vì route registry phần lớn rỗng (nợ v34) → hardcode + registry chỉ drive status/locked.
- **`_authenticated/admin.index.tsx`** — dashboard Mission Control: wire 5 RPC qua `supabase.rpc` + react-query (`useQuery` mỗi hàm). Health hero (vòng + 4 trụ + Phụ huynh "soon") + modal "Cách tính" · Vitals 8 ô · Action Center (filter Tất cả/Cao/TB/Thấp/Quá hạn + owner/SLA + nút Xử lý disable khi count=0 + empty "Mọi việc đã xong 🎉") · School Health **table desktop / card mobile** · Media & Privacy 6 tile · Pulse empty-state §5 · Roadmap khoá · **Focus Mode** (ẩn Pulse/Roadmap/Media, School chỉ rủi ro). Bẫy vấp: 2 import lucide sai (`PhotoIcon`/`PhotoOff` → `Image`/`ImageOff`) + gỡ import thừa.

### Nghiệm thu login thật ĐẠT (super_admin, 3 màn)
Health **94 "Tốt"** (Ops 83·Media 100·Hỗ trợ 100·Tăng trưởng 100·Phụ huynh soon) · Vitals 3 trường/5 lớp/16 HS/0 buổi-tuần/67% nhật ký/33% media/0 ticket · Action Center 5 việc (Ticket học liệu=1, còn lại 0) · School Health 3 trường table (Kids House 50 "Rủi ro"·2 Dế Mèn 100 "Tốt") · Media 7 chỉ-private/Bunny "OK" · **Pulse empty-state đúng D48** · Roadmap khoá đúng. **Mọi số khớp audit D1.**

---

## 📊 TRẠNG THÁI DB (tiếp nối v35 — xác nhận tuyệt đối từ HANDOFF_v35)
- **Delta phiên này (chắc chắn):** +5 hàm definer (admin aggregate) · +1 migration (058) · **bảng KHÔNG đổi · policy KHÔNG đổi · Edge KHÔNG đổi · seed KHÔNG đổi.**
- **Tuyệt đối (nếu v35 = 60 hàm / mig 057 / 137 policy / 7 Edge):** 52 bảng · **65 hàm definer** · 137 policy · **mig 001→058** · 7 Edge · 3 tenant/3 master.
- SYSTEM_MAP **bump v0.33** (+5 hàm + shell admin cosmic).

---

## 🆕 D-RULES MỚI (đánh số tiếp D107 — nếu v35 đã dùng D108 thì dịch lên)
- **D108 — Admin-aggregate RPC pattern:** Dashboard admin cần tầng RPC tổng-hợp RIÊNG (RPC cũ đều scope GV/PH/trường, KHÔNG có admin-wide). Mỗi hàm: secdef · gate `is_admin()` · bypass-RLS · **CHỈ số/tỉ-lệ ẩn-danh (D48)** · `search_path=''` qualify · 3-khối D92 · test-bằng-login (editor uid=NULL không gọi được). Tên trường KHÔNG phải PII trẻ → School Health hiện tên trường OK.
- **D109 — Registry route sparse → nav hardcode:** `admin_modules.route` phần lớn rỗng (nợ điền route) → KHÔNG drive nav thuần từ registry (mất link công cụ đang chạy). Hardcode nav khớp route thật + registry CHỈ drive `status`/locked. Điền route đủ → mới chuyển data-driven.
- **D110 — Health-score thiếu-engine-thì-hoãn-trụ:** trụ multi-pillar mà engine chưa có nguồn (vd log-xem PH) → HOÃN trụ đó (badge V1.5) + **chuẩn-hoá lại trọng số các trụ còn lại**, KHÔNG bịa số. Audit D1 quyết trụ nào tính được (D97).
- **D111 — Admin cosmic tách hệ kem-ấm:** `/admin` = bản sắc tối-vũ-trụ riêng (honey/forest/slate) cho buồng-lái founder; cổng khách (Parent/School/Teacher) giữ kem-ấm `#FBF8F1`. Hai ngôn ngữ song song CỐ Ý. (Hệ quả: trang con admin sáng cũ nằm trong shell tối = "card sáng trên nền tối", re-theme là Nội thất tiếp.)

---

## 🔧 VIỆC TREO
**Của Admin Dashboard (mới):**
- 🟢 nút "Xử lý" Action Center chưa wire `onClick` → điều hướng tới công cụ (media-consent/onboard/support/curriculum-admin).
- 🟢 re-theme trang con admin (notifications/settings/onboarding/curriculum-admin/sensitive-access/modules/reference: sáng→cosmic) — Nội thất Admin tiếp.
- 🟢 điền `route` registry ~50 module → nav data-driven thật (gỡ hardcode D109).
- 🟡 tinh chỉnh ngưỡng risk School Health (Kids House 50 = "Rủi ro" hơi gắt — journal 50% + 1 ticket).
- 🟡 `get_admin_pulse` + có thể bảng `parent_reactions` khi có `demen_marketing` data / reaction "Lời cảm ơn" (đang building registry).
- 🟡 global search ô tĩnh — wire sau (V1.5+).

**Repo (đỏ — lưu ngay):** mig 058 + `admin.tsx` + `admin.index.tsx` · nợ cũ: mig 045/051-057 + seed 013/014 + Edge `invite_staff`/`invite_parent`/`upload_notification_sound`.

**Registry (D106):** cập nhật `dashboard`/`mission-control` (building→ "Mission Control V1 sống") khi đóng; điền route admin.index.

**Mang theo:** dọn seed `[v29-test]`+demo_seed · GV/PH pilot chưa login · 2 file nhạc curriculum · Vercel dormant · lock 1 linh vật · blur-mặt V2 · 2 PH email-null.

---

## ▶️ KẾ TIẾP (đề xuất)
Theo thứ tự demo Jean chốt: **School → Teacher** (Nội thất hoàn-thiện demo-grade, mặt khách ký license) — mở rộng ngôn ngữ kem-ấm đã chốt. Parent sau. HOẶC dọn nợ repo 1 phiên gọn trước pilot.

*Nguồn: Tài liệu A–G UPDATED + tầm nhìn founder + DMWS v170. Cập nhật "tới đâu ghi tới đó" (KỶ LUẬT VÀNG). Mockup HTML = tài liệu hướng thiết kế, KHÔNG phải code (D97).*
