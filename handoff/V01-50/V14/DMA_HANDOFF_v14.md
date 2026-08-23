# 🤝 DMA_HANDOFF_v14.md — BÀN GIAO PHIÊN (ĐÓNG MA TRẬN MEDIA 2 ZONE × 2 CHIỀU + MIN-MULTI-CHILD LIVE)

> **Cách dùng:** File này = ảnh chụp trạng thái cuối phiên v14. Boot phiên sau:
> `00_START_HERE` → `RULES` → file này. Rồi audit DB/code thật trước khi viết.
> **Naming:** DMA = nền tảng; CTAN = sản phẩm đầu. Không "DMMA".

---

## 1. LÀM GÌ PHIÊN NÀY

Đi **2 ngã liên tiếp**, cùng đóng phần media + linh hồn consent ở tầng LIVE:

- **🎯 Ngã A — B2: upload HỌC LIỆU zone `dma-learning` (admin nội dung).** Đóng **ô cuối** của ma trận media: trước v14 có đọc-cả-2-zone + ghi-ảnh-trẻ, thiếu **ghi-học-liệu**. Giờ Edge `upload_media` **route theo field FormData**: `moment_id`→nhánh ảnh trẻ (cũ) · `lesson_version_id`→**nhánh học liệu mới**. Gate **`check_curriculum_upload_access`** (mig 033, secdef nhận-tham-số) = chỉ **admin nội dung Dế Mèn** (`super_admin`/`content_admin`/`senior_content_admin`); GV/master/PH → `not_curriculum_admin` (học liệu = IP Dế Mèn, KHÔNG của trường). PUT zone `dma-learning` bằng `BUNNY_LEARNING_STORAGE_KEY` (storage-key per-zone D77). Insert `media_assets` `private_curriculum`/watermark on/stream-only/`linked_school_id=NULL` (IP toàn cục). Màn Lovable mới `/portal/curriculum-admin`.
  - **🩹 Bẫy bắt được:** query Lovable embed `lesson:lessons(...)` lỗi **PGRST201 ambiguous** — `lesson_versions` có **2 FK** tới `lessons` (`lesson_id` + `current_version_id`) → PostgREST không biết chọn FK nào. Vá bằng **RPC `list_lesson_versions_for_admin()`** (mig 034) JOIN tường minh `lesson_id`, trả `{items:[{id,label:"Tên — vN",program_id}]}`.
- **🎯 Ngã B — MIN-multi-child LIVE.** Chứng luật consent cốt lõi (D71) trên giao diện thật, không chỉ SQL. **D1 bắt: DB demo CHỈ có Bé Jenny** → phải seed thêm trẻ. seed_009: +**Bé Jimmy** + enroll lớp Mầm A + link PH chung `parent.demo` + 1 **moment NHÓM** approved tag Jenny&Jimmy + consent Jimmy **cố ý thiếu** `group_moment_in_class`. → Engine: child=2 → required `group_moment_in_class`; Jenny đã đồng ý NHƯNG Jimmy chưa → `blocking_children=[Jimmy]` → chặn CẢ ảnh nhóm. Cấp Jimmy → mở.
- **Lock library:** RULES mở rộng D77 (nhánh ghi học liệu) + D71 (multi-child LIVE) +footer v14 · SYSTEM_MAP v0.15 (+mig 033/034 +seed_009 +route +38 hàm definer). **Xuất repo phiên này:** `033_check_curriculum_upload_access.sql` + `034_list_lesson_versions_for_admin.sql` + `seed_009_group_moment.sql` + Edge `upload_media/index.ts` (bản 2-nhánh).

---

## 2. TRẠNG THÁI THẬT CUỐI PHIÊN

- **DB:** **46 bảng** (KHÔNG đổi) · **38 hàm SECURITY DEFINER** (+`check_curriculum_upload_access` mig 033, +`list_lesson_versions_for_admin` mig 034) · **125 RLS policy** (KHÔNG đổi) · mig **001→034** · seed **001→009**.
- **Media — MA TRẬN ĐẦY ĐỦ 2 ZONE × 2 CHIỀU:**
  | | ĐỌC (serving) | GHI (upload) |
  |---|---|---|
  | **`dma-learning`** (học liệu) | ✅ player Portal GV (mig 031 + Edge `get_signed_media_url`, watermark) | ✅ admin upload (mig 033/034 + Edge `upload_media` nhánh học liệu) ← **MỚI v14** |
  | **`dma-private`** (ảnh trẻ) | ✅ journal có ảnh (mig 030 + consent D71) | ✅ GV upload (mig 032 + Edge `upload_media` nhánh ảnh) |
- **Edge sống:** `get_signed_media_url` (2 nhánh đọc) · `upload_media` (**2 nhánh ghi**: route `moment_id`→`dma-private` / `lesson_version_id`→`dma-learning`; Verify JWT OFF). **⚠️ Còn sống cần xóa:** `bunny-sign-test` (ký bừa, không gate).
- **Bunny secrets (Edge):** `BUNNY_LEARNING_*` + `BUNNY_PRIVATE_*` (host + token-key + storage-key) đã set đủ.
- **App routes thật:** `/portal/{notifications, consent, support, journal, curriculum, curriculum-admin, moments}` + landing/auth/modules/rls-test.
- **Demo data:** +Bé Jimmy (children, lớp Mầm A, PH=`parent.demo` chung với Jenny) + moment nhóm `2222…2222` approved tag 2 trẻ + ảnh nhóm thật.

---

## 3. NGHIỆM THU v14 (bằng chứng thật)

| Lớp | Bằng chứng |
|---|---|
| **A — gate (SQL)** | mig 033 verify: super_admin→`allowed/ok` zone `dma-learning` · master/teacher/parent→`not_curriculum_admin` · bad→`lesson_version_not_found` · D15 `[]`. mig 034 verify: editor→`not_authenticated` (D2), raw_join 2 bài đúng label, D15 `[]`. |
| **A — admin upload** | Login `info@demenart.com` `/portal/curriculum-admin` → chọn "Bài 1: Lắng nghe âm thanh — v1" (CTAN) + tên "Chú Vịt Con" + `Chu_Vit_Con.mp3` → **"✓ Đã tải học liệu" + media_id `93ddea79…`**. Row verify: `private_curriculum`/zone `dma-learning`/`bunny_path=/curriculum/47c5…/…mp3`/watermark on/`linked_school_id=NULL`/title đúng/program=CTAN. |
| **A — GV thấy (vòng khép)** | Login `teacher.demo` `/portal/curriculum` → **2 track** ("Chú Vịt Con" + "Chú Vịt Con (demo CTAN)") → phát track mới **0:01/1:11** + watermark trôi "DMA·CTAN·Trường Demo Dế Mèn·teacher.demo@…". |
| **A — PH rỗng** | PH `/portal/curriculum` → "Chưa có học liệu nào được kích hoạt" (school NULL, IP trường). |
| **B — engine MIN (SQL)** | seed_009: child_count=2 → required `group_moment_in_class`; Jimmy thiếu → `blocking_children=[Jimmy]` (Jenny đã đồng ý nhưng vẫn chặn); staff bypass `school_staff`. |
| **B — GV upload nhóm** | `teacher.demo` `/portal/moments` → moment nhóm approved → upload ảnh → "✓ Đã tải" + ảnh hiện (school_staff). |
| **B — PH negative (LIVE, linh hồn)** | `parent.demo` `/portal/journal` → card "Jenny & Jimmy biểu diễn nhóm" ảnh = **"Đang chờ ba mẹ đồng ý cho xem ảnh này"** (vì Jimmy) — moment đơn vẫn hiện ảnh. |
| **B — positive (SQL+LIVE)** | Cấp Jimmy `group_moment_in_class` → engine `ok` blocking `[]` → PH reload → **ảnh nhóm hiện thật** (2 bé + cô). Vòng chặn→cấp→mở khép kín. |

---

## 4. VIỆC TREO (dọn — gộp nợ cũ + mới)

1. **⭐ XÓA Edge `bunny-sign-test`** (ký bất kỳ path cho bất kỳ ai có anon key — bypass gate). Càng gần go-live càng nên xóa.
2. **⭐ ẢNH TEST DMWS móc nhầm.** Moment "Bé Jenny vẽ tranh mùa xuân" (approved) đang gắn **screenshot DMWS "Gia đình Vịt Con"** (lộ rõ ở màn `/portal/journal` v14) → 1 `media_assets` row rác + 1 object Bunny `dma-private/moments/ee2f63…/…`. Xóa row + object cho demo sạch.
3. **Lưu migration vào repo:** mig **033/034** + seed **009** + Edge `upload_media` (bản 2-nhánh) đã xuất phiên này. Vẫn nợ **mig 026–032** (`.sql`) + Edge `get_signed_media_url/index.ts` cùng 001–025.
4. **Caption "[seed]"** còn ở moment thật trong DB (UI strip ở client). Cosmetic. *(seed_009 cũng dùng caption "[seed] Jenny & Jimmy biểu diễn nhóm".)*
5. **Sửa file `seed_007_ops_config` repo:** `body_template` bỏ "Bé " thừa (đã UPDATE live).
6. **Xác nhận đã `drop function public._neg_test();`** (helper tạm test consent v9).
7. **Row test treo:** `child_observations.note`/`child_journey.entry_type`='WRITE-BLOCK TEST (panel)' + `learning_moments.caption='[panel] write-block test'` + License nếu admin từng bấm. Không gấp.

---

## 5. NGÃ KẾ (chọn đầu phiên sau)

- **A. Tách 4 portal / deploy** `dma.vercel.app` → `demenart.com` (Vercel + GoDaddy DNS). Việc hạ tầng — làm trọn một mạch một phiên.
- **B. `request_sensitive_access`** (admin xem PII trẻ CÓ AUDIT — D48 carve-out). Engine mới vừa phải; mở "cửa có kiểm soát" cho Dế Mèn xử lý yêu cầu data trẻ.
- **C. `create/resolve_private_share_link`** (share ảnh khoảnh khắc cho PH/ông bà ngoài app — D55/D66). Token nội bộ DMA + expiry + scope; resolve-by-token = Edge public bypass RLS.
- **D. Dọn §4** (ưu tiên xóa `bunny-sign-test` + ảnh test DMWS rác) — nhẹ, gọn demo trước khi deploy.

> **Gợi ý nhịp:** Media + consent core giờ đã đóng trọn (đọc/ghi cả 2 zone + MIN-multi-child LIVE). **Nên dọn §4 (D) trước rồi deploy (A)** để có bản demo sạch lên domain thật. **B/C** là tính năng admin/share — làm sau khi pilot có data thật.

---

## 6. KỶ LUẬT GIỮ NGUYÊN (nhắc nhanh)

- **Audit DB/code thật trước khi viết** (D1) — phiên này bắt 3 delta nhờ audit: (a) `lesson_versions` 2 FK→`lessons` gây embed ambiguous → RPC; (b) DB demo chỉ có Jenny, không Jimmy → phải seed; (c) `enrollments.state`/`child_parents` không có cột em đoán → audit cột thật trước seed.
- **Engine-per-media-type, hai chiều (D71/D75/D77):** mỗi loại media có gate secdef nhận-tham-số (test SQL) cho CẢ đọc lẫn ghi; Edge chỉ điều phối+ký/PUT+audit. ảnh trẻ=consent/same_school · học liệu=entitlement(đọc)/admin-nội-dung(ghi).
- **Storage-key ≠ token-key, secret-per-zone (D77/D74):** PUT Storage = "Password" read-write per-zone (`BUNNY_LEARNING_STORAGE_KEY`/`BUNNY_PRIVATE_STORAGE_KEY`); ký CDN = token-key. Endpoint Storage region `sg.storage.bunnycdn.com`. Secret CHỈ ở Edge (D63).
- **Embed ambiguous (PostgREST):** bảng có ≥2 FK tới cùng bảng đích → `from(...).select('rel:other(...)')` lỗi PGRST201 → **dùng RPC curated JOIN tường minh** thay vì cú pháp disambiguation mong manh (gương `list_lesson_versions_for_admin`).
- **Seed trẻ cần `session_replication_role=replica` (D30):** `children` có guard `guard_children_protected_cols` (D28) → SQL Editor không có `auth.uid()` → guard ghim cột → phải tắt user-trigger tạm. `enrollments`/`consents`/`moment_children` không guard nhưng để chung khối replica an toàn.
- **CORS `functions.invoke` (D76):** allow `x-client-info`; `reason` thật ở `error.context.json()`. FormData body cho upload (cả ảnh trẻ lẫn học liệu).
- **No-download/no-claim (D65/D68):** học liệu watermark on (răn đe — yếu trên audio, cắn khi video); ảnh con-mình watermark off. KHÔNG tuyên bố chống quay 100%.
- **Lovable (D5/D11/D13/D14):** SCHEMA OWNERSHIP đầu prompt; fetch auth-gated client-side; KHÔNG "Try to fix all"; REPLACE-entire-screen NOTE chống double route.
- **Library + Tra Cứu update cùng nhịp** — đã làm v14 (media + consent tầng Edge/engine, KHÔNG module Tra Cứu riêng → chỉ update RULES/SYSTEM_MAP).

---

*Handoff v14 — 2026-06-25 19:34 GMT+7. ✅ ĐÓNG MA TRẬN MEDIA 2 ZONE × 2 CHIỀU + MIN-MULTI-CHILD LIVE. Ngã A (B2): upload học liệu `dma-learning` (mig 033 `check_curriculum_upload_access` = admin nội dung + mig 034 `list_lesson_versions_for_admin` né embed PGRST201 + Edge `upload_media` nhánh học liệu route theo `lesson_version_id` + Lovable `/portal/curriculum-admin`). Ngã B: MIN-multi-child LIVE (seed_009 +Bé Jimmy + moment nhóm; PH chặn-vì-Jimmy "đang chờ"→cấp Jimmy→ảnh hiện). RULES mở rộng D77+D71; SYSTEM_MAP v0.15. Nghiệm thu login thật toàn bộ: admin upload→GV nghe+watermark/PH rỗng · engine MIN blocking=[Jimmy]→cấp→mở LIVE. **46 bảng · 38 hàm definer · 125 policy · mig 001→034 · seed 001→009.** Xuất repo: mig 033/034 + seed_009 + Edge `upload_media` (2 nhánh). Kế: dọn §4 (bunny-sign-test + ảnh DMWS rác) → deploy 4 portal · hoặc request_sensitive_access · share link. Nguồn: A–G + RULES v14 + SYSTEM_MAP v0.15.*
