# 🧾 DMA_HANDOFF_v42.md — GET_LESSON_GUIDE DB-BACKED + GÁN HỌC LIỆU THEO PHẦN (CÁCH B — BẢNG NỐI `lesson_activity_media`) + PLAYER-THEO-MIME — 2026-07-01 ~07:10 GMT+7

> **Boot phiên sau:** đọc `DMA_00_START_HERE.md` → `DMA_RULES.md` → file này. Audit live trước khi viết code/SQL (D1).
> **Phiên này:** 2 mạch DB→UI liên tiếp. **(1)** Bỏ const `RAINDROP_GUIDE`, `get_lesson_guide` đọc giáo án jsonb thật (mig 063). **(2)** Kiến trúc **gán học liệu vào TỪNG PHẦN của giáo án bằng `media_id`** qua bảng nối FK (mig 064 + `get_lesson_guide` replace mig 065), player render **theo MIME** (audio/video/image). Bỏ SẠCH cơ chế khớp-tên `materialHint`.

---

## ⭐ LÀM ĐƯỢC PHIÊN NÀY

### Mạch 1 — `get_lesson_guide` DB-backed (mig 063, bỏ const `RAINDROP_GUIDE`)
Đóng ⚓ treo từ v41. Audit D1 (`lesson_versions`): cột `activities` jsonb **free-form KHÔNG check-constraint** → mình tự chốt shape. Demo `ac0a5c13` + Bài 1 gốc `47c52596` đều `activities=NULL` nhưng `objectives` đã có sẵn.
- **mig 063** = `get_lesson_guide(p_session_id uuid)` secdef, `search_path=''`, **mirror gate `get_session_curriculum`** (`session_school_id()` → `is_admin() OR same_school()`) — KHÔNG gate chặt hơn (cùng Bước 2, cùng quyền xem). Gate **theo session** không theo lesson_version_id (Bước 2 luôn có `id` sẵn trong URL, an toàn người-trong-phòng, không cần gate entitlement mới).
- **Seed** `activities` cho `ac0a5c13` = 5 hoạt động "Tiếng mưa rơi" **verbatim từ const** (dollar-quote `$json$`).
- **UI** `teacher.session.$id.tsx`: `guide` từ `useMemo(guideForSession)` → **state + fetch** `get_lesson_guide`; thêm `guideLoading` (spinner cột phải); buổi chưa biên soạn (`activities` null/rỗng) → RPC trả `guide:null` → graceful "đang biên soạn".
- **Nghiệm thu ĐẠT** (4 ảnh): "Hoạt động 1/5 Khởi động" + mục tiêu + "Cô có thể nói" + câu hỏi từ DB; chuyển hoạt động mượt; nội dung khớp seed 100%.

### Mạch 2 — Gán học liệu THEO PHẦN (Cách B — bảng nối FK) + player-theo-MIME (mig 064–065)
**Bối cảnh (Jean làm rõ mô hình đúng):** giáo án mỗi Phần gán **1 hoặc nhiều học liệu** từ **kho** (`media_assets`), gán bằng **tham chiếu media_id KHÔNG bằng tên** (1 file dùng lại cho nhiều tiết/nhiều mục đích — tên file vô nghĩa với "thuộc Phần nào"). Player chọn theo **loại file** của media được gán. Phần không học liệu → không player.

**🆕 D118 — quyết kiến trúc:** cơ chế khớp-tên `materialHint` (so substring tên track) là **thiết kế tạm-chắp-vá của demo, SAI** — giáo án const + track DB không có liên kết thật nên phải đoán. **Bỏ hoàn toàn.** Thay bằng **Cách B — bảng nối `lesson_activity_media`** (FK thật).

- **Audit D1:** `media_assets` — `file_type` lưu dạng **MIME** (`audio/mpeg`, `image/jpeg`); cột sẵn `bunny_stream_video_id` (cho video Stream tương lai). Kho hiện: **3 audio curriculum** (mưa `34ad7ff4` · Chú Vịt Con `93ddea79` · Chú Vịt Con demo `bb9cd504`) + nhiều ảnh `private_child_media` (ảnh trẻ — KHÔNG gán được, D48). **CHƯA có video/ảnh-curriculum trong kho.**
- **mig 064** = bảng `lesson_activity_media (id, lesson_version_id FK→CASCADE, activity_key text, media_id FK→RESTRICT, sort_order, created_at, UNIQUE(version,key,media))` + index `(version,key)` + RLS admin-only (`is_admin()` all). **GV đọc qua RPC secdef, KHÔNG query bảng trực tiếp** (giáo án = IP Dế Mèn, D75). FK media = **RESTRICT** (không xoá nhầm file đang dùng trong giáo án).
- **Seed `key` ổn định** vào 5 Phần jsonb (bảng nối cần khoá trỏ vào) + **bỏ `materialHint`**: `warmup · listen · pick_image · move · share`.
- **Gán test 2 audio:** `listen`→mưa `34ad7ff4` · `move`→Chú Vịt Con `93ddea79` (test nhảy track audio→audio).
- **mig 065** = `get_lesson_guide` REPLACE: mỗi Phần `+= media[]` gán qua bảng nối theo `activity_key`, giữ thứ tự phần gốc (`jsonb_array_elements WITH ORDINALITY`). Re-harden grant (D15 — REPLACE reset).
- **UI `teacher.session.$id.tsx` — rework `StepTeach`** (giữ NGUYÊN Bước 1/3/4/stepper/SessionFlow): `guide` giờ `GuideActivity[]` mỗi phần có `media: GuideMedia[]`. Player render **media của Phần đang chọn** (`act.media`); nhiều media → prev/next trong phần; Phần không media → "Phần này không dùng học liệu trình diễn". **Chuyển Phần → tự đổi media + tự phát** (audio/video autoPlay; ảnh chỉ hiển thị). Render theo **MIME** (`kindOf`): `audio/`→player audio, `video/`→`<video>`, `image/`→`<img>` (ảnh không timeline/play). StatusPill +`image`, đổi `missing`→"Không học liệu" (xám, không đỏ — không phải lỗi).
- **Nghiệm thu login thật ĐẠT** (GV Mỹ Linh, 5 ảnh): Phần 1 Khởi động không-media → "Không học liệu" · Phần 2 → tự phát "Lắng Nghe Tiếng Mưa" chip "1 học liệu" · Phần 3 chưa gán → "Không học liệu" · **Phần 4 → tự nhảy sang "Chú Vịt Con" + tự phát (test chính ĐẠT)** · Phần 5 "Hoạt động cuối" · dải dưới hiện icon nhạc phần-có-media · watermark trôi đúng. **Cơ chế gán-phát theo media_id chạy đúng hoàn toàn.**

### 🆕 D119 — `upload_media` (Edge V1) CHỈ NHẬN AUDIO (giới hạn đã biết)
Test video/image player **chưa chạy được** vì Edge `upload_media` reject non-audio. Ảnh chụp: upload video 80MB → "Đang tải…" ~5 phút (KHÔNG treo vô hạn — Edge nhận stream rồi reject validate MIME, UI cũ thiếu timeout/progress nên trông như treo) → lỗi "Định dạng không hỗ trợ — học liệu V1 chỉ nhận audio". Ô upload ảnh: `accept` hardcode audio → không chọn được.
**Bản chất:** UI player đã sẵn cả 3 loại; **thiếu ĐƯỜNG NẠP video/image vào kho.** Nâng `upload_media` nhận video/image là **sprint riêng** (Edge whitelist MIME + **video lớn phải đi Bunny Stream** `bunny_stream_video_id` không đi Storage/Edge-payload + UI admin mở `accept`) → **gộp vào sprint Media Library Manager** (đã hẹn làm sau). Engine gán-phát KHÔNG nợ gì — chỉ chờ có file trong kho.

---

## 🗂️ TRẠNG THÁI DB SAU v42

**53 bảng** (+`lesson_activity_media`) · **68 hàm definer** (`get_lesson_guide` mig 063 tạo mới rồi mig 065 replace-thân — net +1 so v41=68? **XÁC NHẬN:** v41=68 hàm KHÔNG có `get_lesson_guide` → v42 **+1 = 69 hàm definer**) · **138 policy\*** (+1: `lesson_activity_media_admin_all`; \*drift mig057 vẫn treo → thực có thể 137) · **+2 FK** (version CASCADE, media RESTRICT) · mig **001→065** · seed 001→014 · 7 Edge · 3 tenant/3 master.

> ⚠️ **Đếm hàm cần double-check phiên sau:** v41 handoff ghi "68 hàm" là trạng thái TRƯỚC khi có `get_lesson_guide`. mig 063 CREATE (thành 69), mig 065 REPLACE (giữ 69). Nếu audit đếm khác → tin audit (D112 drift).

**Data live thêm:** 5 Phần `ac0a5c13` có `key` + `activities` seed đầy · 2 row `lesson_activity_media` (listen→mưa, move→vịt con).

---

## 📍 SYSTEM_MAP → **v0.38** (BUMP)
- +bảng `lesson_activity_media` (bảng nối giáo án×học liệu, Cách B)
- +hàm `get_lesson_guide` (secdef, trả guide[] mỗi phần kèm media[])
- `teacher.session.$id.tsx` Bước 2: player-theo-MIME gắn-theo-Phần (bỏ khớp-tên)

**Routes:** SỬA `_authenticated/teacher.session.$id.tsx` (StepTeach rework; 1/3/4+stepper giữ nguyên byte).

---

## 🔜 VIỆC TREO

**Nhóm học liệu / Media (ưu tiên khi mở Media Manager):**
- 🟢 **Media Library Manager V1** (Finder kho học liệu trong `/admin`) — grid + lọc theo loại/môn + upload đa-file + xem chi tiết + **"dùng ở giáo án nào"** (đọc chính `lesson_activity_media`). Đây là cổng vào để admin soạn giáo án nghiêm túc (chọn media từ kho thay hardcode).
- 🟢 **Nâng `upload_media` nhận video + image-curriculum** (D119) — Edge whitelist MIME + **Bunny Stream cho video lớn** (`bunny_stream_video_id`) + UI admin mở `accept`. Gộp với Media Manager.
- 🟡 Test **video player + image player** Bước 2 — code ĐÃ sẵn (kindOf video/image), chỉ chờ có file trong kho sau khi nâng upload.
- 🟡 pptx/pdf viewer Bước 2 (mỗi loại 1 mảng kỹ thuật riêng — sau audio/video/image).
- 🟡 Gán học liệu qua UI (thay vì SQL tay) — form admin chọn media từ kho gán vào Phần (đọc/ghi `lesson_activity_media`).

**Nhóm cũ mang theo:**
- cụm **Classroom & Journal V1.1** (Classroom View `/teacher/classroom` + Mobile Remote `/teacher/remote` + BroadcastChannel hook + route Nhật ký `/teacher/journal`, từ v40) · research render giáo-án per-session.
- 🟡 **BUG UTC-không-HCM** (`get_teacher_home`/`get_teacher_classes` lọc `date_trunc('day',now())` UTC → buổi 09:30 lọt "Sắp tới"; sửa `(now() AT TIME ZONE 'Asia/Ho_Chi_Minh')::date`).
- 🟡 lưu repo mig **060–062** (D90) + **SQL tách-track v41** + **mig 063/064/065 + seed key/gán v42** (dump-từ-live).
- 🟡 drift `notification_sounds_select_enabled` (mig 057 chưa chạy — xác nhận policy 137/138).
- Admin `/admin` route rỗng (wire "Xử lý" + re-theme cosmic + điền route ~50 module, D109/D111).
- Tương tác PH thật (log-xem + `parent_reactions`, cửa V1.5).
- nợ cũ: dọn seed test/demo_seed · 2 PH email-null · GV/PH pilot chưa login · Vercel dormant · lock 1 linh vật · pwa.theme_color.

---

## ▶️ KẾ TIẾP — chọn 1
1. **Media Library Manager V1** (Finder kho) — mở cổng quản trị học liệu + nâng `upload_media` video/image → test nốt 2 player còn lại. **Nền đã sẵn (`lesson_activity_media` cho "dùng ở đâu").**
2. **Cụm Classroom & Journal V1.1** — Classroom View + Remote + BroadcastChannel + route Nhật ký (điểm bán school owner/GV).
3. **Fix bug UTC + dọn nợ repo** (lưu mig 060–065 + SQL tách-track) — nhẹ, đóng nợ trước pilot.

> **Hoãn (không mất):** pptx/pdf viewer · gán-media-qua-UI · video/image player test · re-theme Admin cosmic · `/kid` V2 · lock linh vật.

Nguồn: Tài liệu A–G + tầm nhìn founder + DMWS v170. Cập nhật "tới đâu ghi tới đó" (KỶ LUẬT VÀNG).
