# 🧾 DMA_HANDOFF_v41.md — BƯỚC 2 "DẠY HỌC" → LESSON PLAYER / CLASSROOM COMPANION + TÁCH TRACK DEMO "TIẾNG MƯA RƠI" + D117 (paste-đúng-file) — 2026-06-30 ~19:40 GMT+7

> **Boot phiên sau:** đọc `DMA_00_START_HERE.md` → `DMA_RULES.md` → file này. Audit live trước khi viết code/SQL (D1).
> **Phiên này:** (1) **UI thuần** — rebuild Bước 2 trong `teacher.session.$id.tsx` thành 2-cột Lesson Player + Teaching Guide. (2) **DATA live thuần** — upload audio + tách lesson_version cho buổi demo (KHÔNG migration, KHÔNG đổi bảng/policy/hàm/Edge). (3) Gỡ sự cố paste-nhầm-file → **D117**.

---

## ⭐ LÀM ĐƯỢC PHIÊN NÀY

### 1) Bước 2 "Dạy học" = Lesson Player / Classroom Companion (`teacher.session.$id.tsx`)
Thay khối Bước-2-cũ (list track + nút Phát thô) bằng **2 cột desktop** (`lg:grid-cols-[1.05fr_0.95fr]`), giữ NGUYÊN byte Bước 1/3/4, stepper, shell ivory/forest/honey:

- **Cột TRÁI — Lesson Player (engine THẬT):**
  - preview lớn gradient `#0F6E56→#149A76`; video → thẻ `<video>`, audio → icon nhạc + equalizer animation; **1 `mediaRef`** dùng chung cho cả audio/video.
  - signed URL **fetch on-demand** từ thao tác người dùng (play được phép, không bị autoplay-block): `supabase.functions.invoke("get_signed_media_url",{body:{media_id}})`.
  - custom controls: play/pause tròn · prev/next material (`SkipBack`/`SkipForward`) · timeline `<input range>` (seek) · volume popover · fullscreen (`requestFullscreen`).
  - **watermark trôi** (`wm-drift` 12s): `DMA · CTAN · <school> · <email GV> · <startedAt>` — chống chụp lén (đã nghiệm thu hiện đúng).
  - **StatusPill 5 trạng thái:** ready/playing/paused/missing/failed.
  - "Học liệu N/M" khi nhiều track · **"Chiếu lên TV" 🔒V1.1** (toggle hint) · "Báo lỗi phát" (insert `support_requests` category=curriculum).
- **Cột PHẢI — Teaching Guide:**
  - "Hoạt động N/5" + tiêu đề + **mục tiêu** (Target) + **"Cô có thể nói"** (script, MessageSquare) + **"Câu hỏi gợi mở"** (HelpCircle) + CTA "Hoạt động tiếp theo".
  - buổi chưa có guide → graceful state "Đội ngũ Dế Mèn đang biên soạn… Cô vẫn phát học liệu cột bên."
- **Dải 5 hoạt động ngang** (done/active/upcoming) — bấm chuyển activity; activity có `materialHint` (vd "mưa") → tự chọn track khớp tên.
- **Thanh điều khiển lớp nhanh:** Hoạt động trước/Tạm dừng lớp/Hoạt động tiếp · Ghi nhận nhanh (→Bước 3) · Chụp khoảnh khắc (→Bước 3 tab "photo") · Báo lỗi học liệu.
- **3 hành động dưới:** Sang bước Ghi nhận / Lưu & tạm dừng (→/teacher, pause media) / Quay lại Chuẩn bị.
- **Wiring SessionFlow:** `StepTeach` nhận `profileId` + `onCapture` (→ `goToRecord("photo")`).

### 2) ⚓ Teaching Guide = const DEMO (chưa nối DB — CÓ LÝ DO, đã chốt kiến trúc)
- `RAINDROP_GUIDE` (5 hoạt động: Khởi động · **Lắng nghe âm thanh** [text Jean verbatim] · Chọn hình ảnh · Vận động theo nhịp · Chia sẻ cảm nhận) — map theo **tên buổi** chứa "mưa" (`guideForSession`). Buổi khác → null → graceful state.
- **Player engine 100% thật**; chỉ Guide-content là const. Lý do tách const: **`lesson_versions` đã có sẵn cột `activities`/`guiding_questions`/`objectives` (jsonb) nhưng version demo đang dùng để TRỐNG** (D1 audit lộ `has_activities=false`). → ⚓ phiên sau: RPC `get_lesson_guide(lesson_version_id)` đọc thẳng jsonb, bỏ const. **KHÔNG bịa** chỗ này là Guide-demo, đánh dấu rõ trong code (`// ⚓`).

### 3) 🌱 Tách track demo "Tiếng mưa rơi" (DATA LIVE — Cách A, KHÔNG migration)
**Vấn đề:** session a0001 "Tiếng mưa rơi" mượn `lesson_version 47c52596` (của lesson **"Bài 1: Lắng nghe âm thanh"**) → Bước 2 hiện track "Chú Vịt Con" (2 audio cũ), lệch tên buổi.

**Audit live (D1) phát hiện engine `get_session_curriculum`** (đọc body — D114):
- lấy media theo `m.linked_lesson_version_id = session.lesson_version_id`
- lọc `access_level='private_curriculum' AND state='active'` + entitlement theo `lesson.program_id`
- **title track = `m.metadata->>'title'`** (KHÔNG phải cột riêng).

**Quy trình build (media → trỏ session, đúng thứ tự):**
1. Upload audio Tiếng mưa rơi qua UI **`/admin/curriculum-admin`** ("Tải học liệu lên kho CTAN", super_admin `info@demenart.com`) → tạo `media_assets` chuẩn:
   - `media_id` **`34ad7ff4-9604-4aef-8fcd-c3ae1265df98`**
   - `bunny_path` `/curriculum/47c52596…/1269dc34-…mp3`, zone `dma-learning`, `watermark=true`, `access_level='private_curriculum'`, `state='active'`, `metadata.title='Lắng Nghe Tiếng Mưa'` (UI tự set đủ — KHÔNG cần vá tay).
   - ⚠️ UI gắn media vào **version đang chọn** ("Bài 1 — v1" = `47c52596`) → tạm thời version đó có **3 media**.
2. **SQL Cách A** (1 transaction `DO $$`): tạo `lesson_version` mới **`ac0a5c13-aad4-4c66-a7e0-d32ce1d749ab`** (clone từ `47c52596`, `version_no` kế tiếp, state `published`) → `UPDATE media_assets SET linked_lesson_version_id=ac0a5c13` cho media mưa → `UPDATE lesson_sessions SET lesson_version_id=ac0a5c13` cho a0001.
3. **Verify (đọc thẳng data theo logic hàm — D113):** `tracks_buoi_mua=["Lắng Nghe Tiếng Mưa"]` (đúng 1) · `tracks_bai1_goc=["Chú Vịt Con (demo CTAN)","Chú Vịt Con"]` (Bài 1 nguyên vẹn).
4. **Nghiệm thu login thật (D2/D3)** — GV Mỹ Linh: track "Lắng Nghe Tiếng Mưa" · pill "Đang phát" · timeline 0:03/9:59 chạy · tab title 🔊 · **watermark trôi đúng** (school + email GV). DEMO-READY.

> **Hiệu ứng phụ kiến trúc:** lesson "Bài 1: Lắng nghe âm thanh" giờ có **2 version** (v1 = 2 track Chú Vịt Con; v2 `ac0a5c13` = 1 track mưa, gắn riêng session demo). `lesson.current_version_id` KHÔNG đổi (vẫn trỏ v1) — chỉ session a0001 trỏ v2. Không ảnh hưởng buổi/khác.

---

## 🆕 D-RULE (đã append RULES)

**D117 [stack: Lovable/apply] — PASTE-OVER PHẢI VERIFY ĐÚNG FILE ĐÍCH (KIỂM `createFileRoute` PATH TRƯỚC KHI DÁN); PASTE NHẦM FILE = LỖI RUNTIME GIẢ DẠNG LỖI DB.** Phiên này: apply Bước-2-mới nhưng **dán đè nội dung `teacher.session.$id.tsx` LÊN `teacher.index.tsx`** (Home). Hệ quả: `/teacher` khớp route Home nhưng file khai báo `createFileRoute("/_authenticated/teacher/session/$id")` + `component: SessionFlow` → `SessionFlow` chạy ở Home, `useParams().id=undefined` → `get_session_detail()` body rỗng → **404 PGRST202 "Could not find function … WITHOUT PARAMETERS"**. Chẩn đoán lạc 5+ bước (nghi DB/cache/UTC) vì lỗi *trông như* DB. **Bản chất: DB hoàn hảo, code đúng — chỉ sai-file-đích khi paste.** Triệu chứng nhận dạng nhanh: import-list của file Home bỗng chứa icon player (Pause/SkipBack/Volume2/Tv…) hoặc `RAINDROP_GUIDE`. **Luật:** trước khi Cmd+A-paste-over một file trong Lovable, **đọc dòng `createFileRoute(...)`** xác nhận đúng route đích; sau khi dán, **đọc lại dòng đó** chưa bị đổi. Nếu lỗi DB vô lý (hàm tồn tại + grant đúng + secdef đúng mà vẫn 404/empty-param) → **nghi paste-nhầm-file TRƯỚC khi nghi DB**. Khôi phục: Lovable History → mốc tốt → **"View file"** (xem nội dung KHÔNG cần restore-toàn-project) → copy → dán lại đúng file. Cùng họ D5/D14/D116 (một thao-tác-apply mong-manh "build vẫn chạy" ≠ apply đúng chỗ).

---

## 📊 TRẠNG THÁI DB

- **52 bảng · 68 hàm definer · 137 policy* · mig 001→062 · seed 001→014 · 7 Edge · 3 tenant/3 master.**
  - **CẤU TRÚC KHÔNG ĐỔI** phiên này (KHÔNG migration). Thay đổi DUY NHẤT = **data live**: +1 row `lesson_versions` (`ac0a5c13`), +1 row `media_assets` (`34ad7ff4`, qua UI admin), 2 UPDATE (media link + session version).
  - *(*) drift `notification_sounds_select_enabled` (mig 057) chưa chạy → thực tế có thể 136. Chưa đụng.*
- **SYSTEM_MAP v0.37 (BUMP — Bước 2 = Lesson Player 2-cột trong `teacher.session.$id.tsx`; data demo "Tiếng mưa rơi" tách version).**
- **Routes:** SỬA `_authenticated/teacher.session.$id.tsx` (Bước 2 rebuild; Bước 1/3/4 + stepper giữ nguyên). KHÔNG tạo route mới.

---

## 🔧 VIỆC TREO

**Bước 2 / Lesson Player — nâng cấp tiếp:**
- 🟢 **`get_lesson_guide(lesson_version_id)` DB-backed** — đọc `lesson_versions.activities`/`guiding_questions`/`objectives` (jsonb đã có cột), bỏ const `RAINDROP_GUIDE`. Cần: định hình schema jsonb cho activities (title/objective/script/questions[]/materialHint) + seed cho version `ac0a5c13` + 1 RPC secdef gate `same_school`/entitlement.
- 🟡 **Branch VIDEO Bước 2 CHƯA test data thật** — code `isVideoType`→`<video>` đã viết nhưng demo chỉ có audio. Trước khi tin: upload 1 mp4 curriculum (qua `/admin/curriculum-admin` nếu UI nhận video, hoặc Bunny Stream) gắn 1 version → test thẻ video + watermark-trên-video + fullscreen-video.
- 🟡 **pptx/pdf/slide viewer** — player hiện chỉ `<audio>`/`<video>`. Học liệu slide cần viewer riêng (slide-by-slide / render PDF) = **việc tương lai**, KHÔNG nhồi vào player hiện tại (tránh scope creep). jpg/png KHÔNG thuộc Bước 2 (đã có luồng ảnh khoảnh khắc ở Bước 3).
- 🟢 "Chiếu lên TV" hiện chỉ hint V1.1 → nối cụm Classroom/Remote (dưới).

**Cụm "Classroom & Journal V1.1" (PHIÊN SAU — từ v40, chưa làm):**
- 🟢 **Classroom View** `/teacher/classroom` (monitor TV full-screen, no-chrome, large activity title, **nút TẮT-màn-hình** cho trẻ tập trung).
- 🟢 **Mobile Remote** `/teacher/remote` (control 1-tay: play/pause · next/back · audio/video/slide · điểm danh nhanh · chụp khoảnh khắc · quick observation · end lesson).
- 🟢 Đồng bộ **BroadcastChannel** same-laptop (pattern Le PARIS) → bọc hook `useSessionChannel` để sau nâng Supabase Realtime (phone khác máy) KHÔNG viết lại UI.
- 🟡 **RESEARCH render giáo án per-session** cho monitor/remote (monitor chạy CẢ giáo-án-buổi VÀ kho-học-liệu-tự-do để dạy thử ngoài buổi).
- 🟢 **Route Nhật ký** `/teacher/journal` (nháp/chờ-gửi/đã-gửi) + mở khoá sidebar — audit `lesson_sessions.state` → có thể RPC `get_teacher_journals` mới.

**Engine/bug (audit D1 trước):**
- 🟡 **BUG UTC-không-HCM** (`get_teacher_home`/`get_teacher_classes` lọc `date_trunc('day', now())` theo **UTC**) → buổi 09:30 hôm nay lọt nhánh "Sắp tới", thứ tự ngày lệch. Sửa = `(now() AT TIME ZONE 'Asia/Ho_Chi_Minh')::date`.

**Repo / nợ cũ (mang theo):**
- 🟡 Lưu repo mig 060–062 dump-từ-live (D90) — nợ từ v39.
- 🟡 **Lưu repo SQL "tách track Tiếng mưa rơi"** (data-fix v41, không phải migration nhưng nên có trong seed/ops log để tái dựng demo).
- 🟡 Drift `notification_sounds_select_enabled` (mig 057 chưa chạy — xác nhận policy 136/137).
- 🟢 Admin `/admin`: wire "Xử lý" · re-theme cosmic (D111) · điền `route` ~50 module (D109).
- 🟡 Nợ cũ: dọn seed `[v29-test]`+demo_seed · 2 PH email-null · GV/PH pilot khác chưa login · Vercel dormant · **lock 1 linh vật** (thay 🌱 footer) · blur-mặt V2 · `pwa.theme_color` `#E11D63`→brand · 2 file nhạc Chú Vịt Con (giờ +1 file Tiếng mưa rơi) cần ghi nguồn lưu.

---

## ▶️ KẾ TIẾP — chọn 1
1. **`get_lesson_guide` DB-backed** — bỏ const `RAINDROP_GUIDE`, đọc jsonb thật → Teaching Guide bền vững cho mọi buổi (mở đường nhập giáo án qua admin). Gọn, giá trị cao, nối thẳng việc vừa làm.
2. **Cụm Classroom & Journal V1.1** — Classroom View + Remote + BroadcastChannel + route Nhật ký (cổng GV = chỗ chốt hợp đồng, Jean ưu tiên). Lớn, cần research render giáo án.
3. **Fix bug UTC-không-HCM** + test branch video Bước 2 — nhanh, vá lệch ngày + đóng lỗ hổng video trước pilot.

*Boot phiên sau → audit D1 (`pg_get_functiondef` nếu đụng RPC; route/Edge nếu Classroom) → đề xuất hướng có recommendation (D98) → build (DB→Edge→UI nếu có) → nghiệm thu login thật (D2/D3) → verify đúng-nguồn (D113/D114) → HANDOFF v42. Cập nhật registry khi đóng (D106). "Tới đâu ghi tới đó" (KỶ LUẬT VÀNG).*

> **Hoãn lại (không mất):** get_lesson_guide DB · video/pptx Bước 2 · Classroom View · Mobile Remote · route Nhật ký · bug UTC · re-theme Admin cosmic · `/kid` V2 · lock linh vật · lưu repo mig 060–062 + SQL tách-track.

---

## 🔑 LOGIN DEMO (luôn ghi đủ email+pass — D-style Jean)
- GV CTAN: `gv.linh.kidshouse@demo.demenart.com` / `Test@123` → `/teacher` → "Tiếp tục buổi học" → Bước 2 Lesson Player "Tiếng mưa rơi".
- Admin curriculum upload: `info@demenart.com` (super_admin) → `/admin/curriculum-admin`.
- Buổi demo: session **`aaaa0000-0000-4000-8000-0000000a0001`** (lớp Hoa Hồng, "Tiếng mưa rơi", hôm nay 09:30, in_progress).
