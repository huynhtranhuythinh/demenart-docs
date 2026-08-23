# DMA_HANDOFF_v85.md
**Sprint:** V85 — Teacher Multi-media Moment Creation Workflow Audit
**Ngày:** 2026-07-10 00:41 GMT+7 (Asia/Ho_Chi_Minh)
**Vai trò:** ChatGPT = CTO Advisor · Claude = PM + Prompt Operator + Builder · Lovable = build
**Trạng thái:** ✅ ĐÓNG SỔ — **AUDIT-ONLY** · 0 code · 0 DB/RPC/Edge/migration · Nghiệm thu **audit-only PASS** · CTO chốt **C3 = B (Partially operational)**
**File code bị đụng:** **NONE** (0 code). DB/RPC/Edge/migration: **NONE.**

---

## 0. TL;DR

V85 là **sprint audit workflow/data-source** (KHÔNG kiến trúc, KHÔNG code, KHÔNG DB). Câu hỏi: Parent gallery (V80/V81) đã chạy — vậy **GV/Admin tạo `learning_moment` NHIỀU-ẢNH bằng cách nào** để nội dung gallery trở nên vận hành thật, an toàn với ranh giới trẻ + consent?

- **C1 audit LIVE (read-only):** endpoint (D216/v0.77/v84) khớp đĩa **0 drift** · DB sống + code sống + Edge sống xác nhận trạng thái V84 nguyên vẹn.
- **C3 phân loại — CTO chốt B (Partially operational):** luồng Teacher **1-ảnh operational trọn** + Parent gallery multi-media **operational downstream**, NHƯNG Teacher UI **KHÔNG có workflow first-class** để tạo 1 moment với NHIỀU media.
- **Quyết định:** **KHÔNG build V85** · đóng **audit-only** · **chuẩn bị V86 = Teacher Multi-media Upload MVP** (Flow A, frontend-only).
- **Nghiệm thu:** audit-only PASS — 0 frontend code · 0 DB/RPC/Edge/migration · Parent/summary/timeline KHÔNG đụng. KHÔNG thêm code chỉ để có commit (D214/D216 nguyên tắc).

**⭐ Endpoint sau V85:** RULES **D217** · SYSTEM_MAP **v0.78** · Handoff **v85**.

---

## 1. Canonical đã đọc — endpoint verify (đầu phiên)

Topic V85 mới mở. **KHÔNG dựa memory**, đọc canonical thật trên đĩa:
- `DMA_HANDOFF_v84.md` · `DMA_00_START_HERE.md` · `DMA_RULES.md` · `DMA_SYSTEM_MAP.md`.

**Endpoint đầu phiên (verify LIVE trên đĩa):** RULES **D216** (D-rule cao nhất) · SYSTEM_MAP **v0.77** (header dòng 1) · Handoff **v84** — **khớp brief cả 3** ✔ · **0 drift đĩa**.

---

## 2. C1 — Audit LIVE (read-only, kết quả)

**DB (`xcvhacymrbhdhohyylyq`, Supabase MCP read-only):**
1. **Inventory = V84 y hệt → 0 DB drift:** **63 bảng · 105 definer · 155 policy · 1 cron.**
2. Summary An (`d1…041`): drawing **6** · recording **2** · moments-có-media-active **4** = **6/2/4** ✔.
3. `f51039be`: state=**approved** · caption=**null** · tagged **3** (An/Bình/Chi — cả 3 `group_moment_in_class` **granted** → MIN-consent qua) · **2 media active** (`image/jpeg`, cover `3ca6c3dd…e909` 29/6 → `b2d5d20a…b22c` 30/6, ORDER BY created_at ASC) · uploaded_by …011 (GV Mỹ Linh) · session a0001.
4. **Multi-media moment n=1 toàn hệ** (chỉ `f51039be`). Phân bố media active/moment: **0→3 · 1→7 · 2→1** ⇒ hình dạng chuẩn = **1 ảnh / 1 khoảnh khắc**; `f51039be` là ngoại lệ duy nhất.
5. **⭐ Chi tiết then chốt:** 2 media của `f51039be` nạp **cách ~26h, bởi 2 người khác nhau** (…011 GV Mỹ Linh 29/6 → …010 master KHM 30/6), cùng path `upload_media` `/moments/{id}/`. Media thứ 2 gắn vào moment **CÓ SẴN** vào ngày khác — **không phải sản phẩm của luồng upload-nhiều-ảnh liền mạch.**
6. `get_child_journal`: SECURITY DEFINER · `search_path=""` · **0 field signed_url** (1 match = comment "…0 signed_url") · gallery fields đủ (coverMediaId/mediaCount/hasGallery/galleryItems/media_id) · grants = **authenticated + service_role + postgres** (0 anon/PUBLIC — D15).
7. `get_session_moments`: **aggregate MỌI media active/moment** (jsonb_agg, **KHÔNG LIMIT 1**, có ORDER BY) → plumbing đọc đã hỗ trợ nhiều ảnh.
8. `learning_moments` schema: state default **`draft`** · **KHÔNG** cột `cover_media_id`/`sort_order` (cover = created_at ASC LIMIT 1 trong RPC).

**Code/Edge sống (Lovable `read_file` + Supabase `get_edge_function`):**
- `upload_media` v12 nhánh A (ảnh trẻ): nhận **1 file/lần** + `moment_id` có sẵn → PUT `/moments/{momentId}/` → insert `media_assets.linked_moment_id`. **Không tạo moment, không batch file.** ⇒ nhiều-ảnh-1-moment chỉ có được nếu **client** tạo 1 moment rồi loop upload cùng moment_id.
- `teacher.session.$id.tsx` **PhotoTab** (Bước 3 · Ảnh): `onFile` = **mỗi ảnh → INSERT `learning_moments` (draft) mới + 1 upload_media** (1:1). Input `accept` ảnh, **KHÔNG `multiple`** (lấy `files[0]`). Card render **`media[0]`** (giả định 1 ảnh/moment). Có tag `moment_children` + sửa caption per-moment; **KHÔNG** xoá-1-media / đổi-cover / sắp-thứ-tự.
- `MomentsView` (`/teacher/moments`·`/school/moments`): **chỉ list moment có sẵn** (không có nút tạo). Single-file input; có thể upload lặp vào cùng 1 card → thêm media vào cùng moment_id, nhưng **không tạo được moment**.
- `StepReview` → `submit_session_journal`: draft→approved (publish, gate is_session_lead). Consent gác downstream ở ký (`get_signed_media_url`→`media_consent_check`, MIN-multi-child).

**Smoke (C1.7):** V84 vừa PASS + audit trên xác nhận 0 drift DB+code+Edge ⇒ production đang đúng trạng thái V84 (parent summary 6/2/4, timeline, gallery `f51039be` 2 media). Vì chốt audit-only (0 code) nên KHÔNG cần smoke lại (không có gì thay đổi để verify). *(Smoke Parent tay của Jean vẫn là đường tin cậy nếu muốn xác nhận thị giác.)*

---

## 3. C2 — Bản đồ luồng tạo hiện tại (16 câu, có bằng chứng)

1. **Tạo moment:** client INSERT `learning_moments` qua RLS `same_school`, từ PhotoTab. **1 INSERT / 1 ảnh.**
2. **Ai tạo:** nhân sự trường (GV lead/assistant · master). PH & admin nền tảng chặn.
3. **State đầu:** `draft` (default cột).
4. **Gắn bé:** `moment_children` insert/delete qua RLS same_school (chip PhotoTab).
5. **Upload media:** Edge `upload_media` nhánh A — **1 file/lần**, PUT `/moments/{id}/`, insert `media_assets.linked_moment_id`.
6. **Media↔moment:** qua `linked_moment_id` (Edge tự set).
7. **⭐ UI upload NHIỀU ảnh vào 1 moment?** → **KHÔNG.** PhotoTab 1 ảnh = 1 moment; input không `multiple`; card render media[0]. MomentsView upload lặp được vào moment cũ nhưng không tạo moment. Không có UI multi-media first-class.
8. **Publish/approve?** → **CÓ.** StepReview → `submit_session_journal` (draft→approved).
9. **Có bước duyệt?** → **CÓ.** Moment giữ draft tới submit; PH chỉ thấy khi approved (gate 2 tầng). Không hiện tức thì.
10. **`source='teacher_upload'`?** → `media_assets.metadata.source='teacher_upload'` (nhánh A). Cột `source` (mig068) KHÔNG set ở nhánh A → nợ taxonomy nhỏ.
11. **Giữ consent?** → **CÓ.** Consent downstream ở ký (MIN-multi-child). Tạo/upload không bypass.
12. **Sửa caption?** → **CÓ** (PhotoTab `saveCaption`).
13. **Xoá 1 media khỏi moment?** → **KHÔNG** (không có UI cho moment child-media).
14. **Đổi cover / sắp thứ tự?** → **KHÔNG.** Cover = created_at ASC LIMIT 1 (RPC).
15. **1 bé thiếu consent (ảnh nhóm)?** → MIN chặn cả media ở ký; PH thấy "đang chờ" + "Vì sao?".
16. **PH visibility downstream state+consent+media?** → **CÓ, hoàn toàn.**

---

## 4. C3 — Phân loại gap: **B (Partially operational)** — CTO chốt

- Luồng moment **1-ảnh**: **operational trọn** (tạo→tag→publish→PH xem→consent giữ).
- Luồng moment **nhiều-ảnh**: **thiếu đúng 1 mảnh = UI TẠO.** Plumbing (upload_media link theo moment_id · get_session_moments aggregate · get_child_journal gallery enrich · Parent lightbox V80/V81) **đã đủ**; chỉ thiếu cách để GV **thêm nhiều ảnh vào cùng 1 moment**.
- `f51039be` chứng minh **data/display path chạy**, nhưng ra đời từ **đường vòng** (upload lặp qua MomentsView, 2 người/2 ngày) — KHÔNG phải UI multi-media sạch. Đúng như ghi chú "chưa chứng minh workflow hoàn chỉnh".
- **Không** mục D (unsafe): mọi ranh giới consent/RLS/security còn nguyên.

**Phân biệt 3 tầng (D217-nguyên-tắc):** plumbing (đủ) · display (đủ) · creation UI (thiếu). "1 artifact tồn tại" ≠ "workflow vận hành".

---

## 5. C4 — Bước tối thiểu kế tiếp: **V86 Teacher Multi-media Upload MVP** (CTO chốt)

**Loại:** frontend-only (nếu được). **Target chính:** `teacher.session.$id.tsx` **PhotoTab**.
**UX = Flow A (multi-select khi tạo MỘT moment):**
- Multi-select nhiều file → tạo **1** draft `learning_moment` → tag bé đã chọn **1 lần** → **loop `upload_media` N lần cùng `moment_id`**.
- Giữ state **draft tới `submit_session_journal`**.

**KHÔNG (khoá scope):**
- KHÔNG đổi Parent UI · KHÔNG đổi DB/RPC/Edge · KHÔNG migration cover/sort · KHÔNG Edge batch-sign · KHÔNG media manager.
- Cover **giữ created_at ASC**; consent **giữ downstream** qua `get_signed_media_url`/`media_consent_check`.

**Ghi chú phụ (cân nhắc lúc build, không bắt buộc MVP):** card PhotoTab hiện render `media[0]` → moment nhiều-ảnh sẽ chỉ hiện ảnh đầu ở GV UI (đủ cho MVP tạo; thumbnail nhiều-ảnh có thể defer). Verify đúng file đích `createFileRoute(".../teacher/session/$id")` trước khi paste (D117); scope guards (D95).

---

## 6. Nghiệm thu — audit-only PASS

- ✅ 0 frontend code · 0 DB/RPC/Edge/migration
- ✅ `/parent` summary vẫn **6/2/4**; home/timeline/gallery/lightbox KHÔNG đụng
- ✅ 0 signed_url ở RPC · 0 ký adapter · 0 Edge batch-sign · 0 raw Bunny
- ✅ consent guard V72 (MIN-multi-child) + badge dedup V73 giữ · 0 hardcode `f51039be`
- ✅ Teacher/Admin workflow map documented (16 câu, có bằng chứng) · gap classification **B** rõ · minimal next step (**V86 Flow A**) rõ

**Guard chuỗi giữ nguyên:** summary V69(6/2/4) · /kid V70 · Lightbox V71 · consent V72 · badge V73 · adapter V74 · compact V75 · detail V76 · home V77 · data V78 · RPC enrich V79 · gallery UI V80 · polish V81 · stability V82 · warmth V83 · filter/month-nav audit V84.

---

## 7. Rollback

**Không cần** — 0 thay đổi code/DB/Edge/migration. Chỉ cập nhật library (handoff v85 + RULES D217 + SYSTEM_MAP v0.78). Không có diff/commit để revert.

---

## 8. Endpoint & Backlog sau V85

**Endpoint:** RULES **D217** · SYSTEM_MAP **v0.78** · Handoff **v85**.

**Backlog:**
- 🔵 **V86 — Teacher Multi-media Upload MVP** (Flow A, frontend-only, target PhotoTab) — chờ phiên build
- 🟠 re-sync project library (RULES D217 + SYSTEM_MAP v0.78) · lưu repo V85
- 🟠 (nợ taxonomy) `upload_media` nhánh A KHÔNG set cột `source` (mig068) → media child = default
- 🟠 (hoãn) filter chip / month-jump nav — bung khi đạt ngưỡng revisit (D216 §)
- 🟠 (hoãn) timeline affordance "X ảnh" khi n≥2 moment gallery HOẶC user-testing PH miss gallery
- 🟠 (tùy) migration `cover_media_id`/`sort_order` nếu cần chọn cover thủ công/sắp thứ tự (V86+ nếu MVP đòi)
- 🟠 (tùy) Edge batch-sign nếu gallery nhiều ảnh gây waterfall
- 🟠 smoke mobile viewport hẹp · favicon 404 (nợ vặt pre-existing)
- (kế thừa) 🟠 Parent Dashboard/Radar/AI Review THẬT · 🟠 Phương án B RPC `get_child_journey_service` · 🟠 rename `kidJourneyModel.ts` · 🟠 enrichment `child_journey` · 🔴 Coloring schema · 🔴 Moment media taxonomy

---

*V85 đóng sổ. Audit-only, 0 code, 0 DB. CTO chốt C3 = B (Partially operational): luồng Teacher 1-ảnh + Parent gallery downstream operational, thiếu UI first-class tạo moment nhiều-ảnh. KHÔNG build V85 → chuẩn bị V86 Teacher Multi-media Upload MVP (Flow A, frontend-only). Guard chuỗi V69→V84 giữ nguyên.*
