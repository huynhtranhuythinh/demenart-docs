# 🧾 DMA_HANDOFF_v40.md — TEACHER WEB WORKSPACE V1 (mirror School) + RE-SKIN 4 VIEW SÁNG + THÉP CHỜ CLASSROOM/REMOTE (D116) — 2026-06-30 ~16:55 GMT+7

> **Boot phiên sau:** đọc `DMA_00_START_HERE.md` → `DMA_RULES.md` → file này. Audit live trước khi viết code (D1).
> **Phiên này = UI/DATA thuần** (nối v39): re-skin 4 shared view, dựng Teacher Dashboard demo-grade mirror School, seed demo Teacher-hôm-nay, polish Home + thép chờ Classroom/Remote. **KHÔNG đụng bảng/policy/RLS/Edge. KHÔNG migration.**

---

## ⭐ LÀM ĐƯỢC PHIÊN NÀY

Đóng nốt **cổng demo thứ 3 (Teacher)** ở mức demo-grade → 3 cổng (Admin · School · Teacher) giờ là **một thế giới nhất quán**, sẵn pilot. Trọng tâm phiên: **Teacher = chỗ dễ chốt hợp đồng nhất** (Jean nhấn mạnh) → polish kỹ Home thành "action-oriented daily workspace".

### 1) Re-skin 4 shared view → tông sáng `#149A76` (2 lượt)
4 view `@/components/portal/{Curriculum,Moments,Support,Notifications}View.tsx` (D115, mount cả `/school`·`/teacher`·`/portal`):
- **Lượt 1:** amber → trầm `#2C5A43`/`#C28B2B` (Jean duyệt "đạt").
- **Lượt 2 (đúng cuối):** trầm → **sáng `#149A76`/`#EFA63A`** — vì D1 (tra past chat A39) lộ **School thật dùng `#149A76` sáng, KHÔNG phải trầm** (em đoán sai lượt 1). Flip `sed` toàn bộ, verify sạch hex trầm. Giữ màu mang-nghĩa (emerald=đã duyệt · rose=lỗi · sky/blue=state hỗ trợ).

### 2) Teacher shell mirror School (`teacher.tsx`)
Viết lại **y hệt `school.tsx`** (Jean thả file để snap pixel): `lg:flex` + sidebar `lg:sticky` (KHÔNG phải `sm`/`fixed` như bản em đoán đầu) · gradient `#1a916f→#15795d→#114c3a` · chữ ivory `#FBF8F1/85` · active **vạch honey pill** `#EFA63A` trái · locked div xám `cursor-not-allowed` + tooltip · **mobile = pill cuộn ngang** (`lg:hidden`, KHÔNG bottom-nav) · header `#6b6354`/`#5b7a6f` · `max-w-6xl`. Nav 3 nhóm (Lớp học / Chương trình & Media / Hỗ trợ) + locked V1.5 (Nhật ký · Hồ sơ). Bell/Hỗ trợ → `/teacher/*`. **Giữ dé-mark SVG + label "Teacher Portal" / "Cổng Giáo viên" / "Phòng Giáo viên".**

### 3) 2 route `/teacher/*` single-source (D115)
TẠO `teacher.support.tsx` + `teacher.notifications.tsx` (ssr:false) = wrapper mỏng mount `SupportView`/`NotificationsView` → giữ trong shell xanh Teacher, hết văng `/portal`. (`teacher.curriculum`/`teacher.moments` đã có từ v39.)

### 4) Teacher Dashboard V1 (`teacher.index.tsx`) — premium 2-cột, action-oriented
Engine **giữ 100%** (`get_teacher_home` + `get_teacher_todo_counts` mig 047 + `get_session_detail` cho prep label). KHÔNG bịa số (§9 "PH đã xem%"/"phản hồi" vẫn vắng đúng D110).
- **Banner mỏng** (mục 2 spec): "Dạy bằng laptop, chiếu lên TV hoặc điều khiển bằng điện thoại." + tag V1.1.
- **Card "BUỔI HỌC HÔM NAY"** (gộp Classroom actions, hết CTA trùng): badge program · lớp · bài · giờ · 4 bé · pill status · breadcrumb 4 bước · **1 primary CTA "Bắt đầu buổi học"** (→ `session/$id` flow sẵn có) · **2 nút teaser `LockedAction`** "Mở Classroom View trên TV" / "Kết nối điện thoại làm remote" — **🔒 Sắp ra mắt · V1.1**.
- **Prep card checklist label THẬT** (mục 4): fetch `get_session_detail(today.id)` → render động N item (CheckCircle2/Circle + gạch ngang khi ready) + progress + "Xem chuẩn bị". *(Data demo "Tiếng mưa rơi" 5 item 4/5 — xem §SEED.)*
- **Today Tasks state-aware** (mục 5): prep dở → "Còn N việc cần chuẩn bị trước buổi học" (honey) · đã dạy chưa gửi → "Còn nhật ký chờ gửi cho phụ huynh" · xong hết → "Mọi việc đã sẵn sàng — cô có thể bắt đầu buổi học 🌿" (forest). + danh sách 4 count khi `itemizedTotal>0`. **Hết "Mọi việc đã xong" sai khi prep 2/3.**
- Cột phải giữ: Lối tắt (4 nav route thật, hết nút chết) · Lớp tiếp theo · Cần hỗ trợ.
- EmptyToday giữ + banner vẫn hiện.

### 5) ⚓ THÉP CHỜ Classroom/Remote (làm PHIÊN SAU — đã chốt kiến trúc với Jean)
- **Bối cảnh thật (Jean):** lớp nghệ thuật cần **TV lớn** thị phạm. CTAN = GV tương tác chính, TV chỉ chiếu clip/slide mẫu (vd khởi động nhảy theo nhạc). **TV sáng liên tục → trẻ mất tập trung vào GV** → cần nút **TẮT màn hình**. **Phone = remote, TV = monitor.**
- **Kịch bản vận hành:** GV mở laptop Chrome → Teacher Dashboard → vào tiết → "mở monitor" → kéo màn 2 sang TV → **F11 full-screen** → điện-thoại-hoặc-laptop mở Remote điều khiển. **1 tiết = 1 laptop (giáo án+học liệu) + 1 TV/projector + phone KHÔNG bắt buộc (laptop tự remote được).**
- **Kiến trúc chốt = (A) same-laptop BroadcastChannel** (Jean đã build Le PARIS, chạy mượt). Monitor + Remote 2 route, đồng bộ `BroadcastChannel` (same-browser). Bọc qua **1 lớp truyền-tin trừu tượng** (`postState`/`onState`) → phiên sau nâng **Supabase Realtime** (phone khác máy) KHÔNG viết lại UI.
- **Comment ⚓ đã cắm sẵn** trong `teacher.index.tsx` (HeroCard) trỏ route tương lai `/teacher/classroom` + `/teacher/remote`.

---

## 🌱 SEED DEMO TEACHER (CHỈ LIVE — KHÔNG ghi seed file)

Lý do không ghi seed file: kéo ngày "hôm nay" **động** (`date_trunc('day', now())`), không hợp seed cố định.
- **`lesson_sessions`** (UPDATE, lớp Hoa Hồng cd `…031`, lead = cô Linh):
  - `a0001` "Tiếng mưa rơi" → hôm nay 09:30, `scheduled` → **HeroCard**
  - `a0002` "Vương quốc âm thanh" → mai 09:00, `scheduled` → Lớp tiếp theo
  - `a0003` "Chú Vịt Con" `in_progress` (dọn nhãn `[v29-test]`)
- **`prep_items` a0001** re-theme "Tiếng mưa rơi" 5 item (4 ready): Loa/thiết bị · Audio "Tiếng mưa rơi" · ⬜Thẻ hình mưa/mây/ô · Khăn voan xanh · Không gian ngồi vòng tròn → **4/5**.
- `lesson_sessions` chỉ có `trg_lesson_sessions_updated_at` (KHÔNG guard) → **D85 n/a**; prep_items bọc `replica` phòng hờ.

---

## 🆕 D-RULE (đã append RULES)

**D116 [stack: Lovable/mirror-cổng] — MIRROR CỔNG PHẢI AUDIT FILE GỐC THẬT TRƯỚC, KHÔNG ĐOÁN TOKEN/BREAKPOINT/CẤU TRÚC.** Phiên này em đoán-sai **2 lần** khi "mirror School" mà chưa có `school.tsx`: (1) hex forest trầm `#2C5A43` thay vì sáng `#149A76` thật; (2) breakpoint `sm`+layout `fixed`+`pl-64`+bottom-nav thay vì `lg`+`flex`+`sticky`+pill-cuộn-ngang. Bắt được nhờ tra past chat (A39) + Jean thả `school.tsx`. **Luật:** trước khi "mirror/đồng bộ" một cổng/component, PHẢI đọc file nguồn thật (hoặc past-chat nguồn D1) để lấy ĐÚNG token màu, breakpoint, cây layout — KHÔNG dựng lại từ ảnh/trí nhớ. Cùng họ D1/D114 (một phép-mirror mong-manh "nhìn cũng xanh" ≠ khớp thật).

---

## 📊 TRẠNG THÁI DB (KHÔNG ĐỔI phiên này)
- **52 bảng · 68 hàm definer · 137 policy* · mig 001→062 · seed 001→014 · 7 Edge · 3 tenant/3 master.**
  - *(*) drift `notification_sounds_select_enabled` (mig 057) chưa chạy → thực tế có thể **136**. Chưa đụng.*
- **SYSTEM_MAP v0.36 (BUMP — +shell `teacher.tsx` mirror + 2 route `/teacher/{support,notifications}` + Teacher Dashboard V1 + khối Classroom thép chờ).**
- **Routes:** TẠO `_authenticated/teacher.{support,notifications}.tsx`; SỬA `teacher.tsx`(viết lại mirror School)·`teacher.index.tsx`(Dashboard V1 premium)·4 view `@/components/portal/*`(flip sáng).

---

## 🔧 VIỆC TREO

**Cụm "Classroom & Journal V1.1" (PHIÊN SAU — Jean cần research):**
- 🟢 **Classroom View** `/teacher/classroom` (monitor TV full-screen, no-chrome, no-sidebar, large activity title, nút TẮT-màn-hình cho trẻ tập trung).
- 🟢 **Mobile Remote** `/teacher/remote` (control 1-tay, nút to: play/pause · next/back · audio/video/slide · điểm danh nhanh · chụp khoảnh khắc · quick observation · end lesson).
- 🟢 Đồng bộ **BroadcastChannel** same-laptop (pattern Le PARIS) → bọc hook `useSessionChannel` để sau nâng Realtime.
- 🟡 **RESEARCH cách render giáo án từng tiết** cho monitor/remote (Jean: cần nghiên cứu — monitor chạy CẢ 2 nguồn: giáo-án-của-buổi VÀ kho-học-liệu-tự-do để dạy thử/tập luyện ngoài buổi).
- 🟢 **Route Nhật ký** `/teacher/journal` (nháp/chờ-gửi/đã-gửi) + mở khoá sidebar — cần audit `lesson_sessions.state` → có thể RPC `get_teacher_journals` mới.
- 🟡 Lesson Player / session flow **nâng cấp** (bản hiện chạy được từ v32/v33, KHÔNG xây lại phiên này).
- 🟡 "Học liệu có vấn đề" trong Today Tasks — cần engine count (giờ chỉ có lối "Học liệu bị lỗi" ở box Hỗ trợ).

**Engine/bug (audit D1 trước):**
- 🟡 **BUG UTC-không-HCM** (`get_teacher_home`/`get_teacher_classes` lọc `date_trunc('day', now())` theo **UTC**) → buổi 09:30 hôm nay lọt nhánh "Sắp tới", thứ tự ngày lệch ở "Lớp của tôi". Sửa = đổi sang `(now() AT TIME ZONE 'Asia/Ho_Chi_Minh')::date`. Cùng họ D113/seed.
- 🟢 re-gộp duplicate "Xem chuẩn bị"/checklist giữa Home preview ↔ session (chấp nhận được, không gấp).

**Repo / nợ cũ:**
- 🟡 Lưu repo mig 060–062 dump-từ-live (D90) — nợ từ v39.
- 🟡 Drift `notification_sounds_select_enabled` (mig 057 chưa chạy — xác nhận policy count 136/137 + chạy khôi phục read âm).
- 🟢 Admin `/admin`: wire "Xử lý" · re-theme con cosmic (D111) · điền `route` ~50 module (D109).
- 🟡 Nợ cũ mang theo: dọn seed `[v29-test]`+demo_seed · 2 PH email-null · GV/PH pilot khác chưa login · 2 file nhạc curriculum · Vercel dormant · **lock 1 linh vật** (thay 🌱 footer sidebar) · blur-mặt V2 · `pwa.theme_color` `#E11D63`→brand.

---

## ▶️ KẾ TIẾP — chọn 1
1. **Cụm Classroom & Journal V1.1** — Classroom View + Remote + BroadcastChannel + route Nhật ký + research render giáo án (cổng GV = chỗ chốt hợp đồng, Jean ưu tiên).
2. **Fix bug UTC-không-HCM** (`get_teacher_home`/`get_teacher_classes`) — nhanh, sửa lệch ngày trước pilot.
3. **Dọn nợ repo 1 phiên** (mig 060–062 dump-live + drift mig057) trước pilot.

*Boot phiên sau → audit D1 (route/Edge nếu Classroom; hoặc `pg_get_functiondef` nếu fix UTC) → đề xuất hướng (D98) → build → nghiệm thu login thật (D2/D3) → verify đúng-nguồn (D113) → HANDOFF v41. Cập nhật registry khi đóng (D106). "Tới đâu ghi tới đó" (KỶ LUẬT VÀNG).*

> **Hoãn lại (không mất):** Classroom View · Mobile Remote · route Nhật ký · "Học liệu có vấn đề" count · bug UTC · re-theme Admin cosmic · `/kid` V2 · lock linh vật.
