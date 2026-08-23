# 🤝 DMA_HANDOFF_v13.md — BÀN GIAO PHIÊN (ĐÓNG KHỐI MEDIA ĐỐI XỨNG: ĐỌC + GHI)

> **Cách dùng:** File này = ảnh chụp trạng thái cuối phiên v13. Boot phiên sau:
> `00_START_HERE` → `RULES` → file này. Rồi audit DB/code thật trước khi viết.
> **Naming:** DMA = nền tảng; CTAN = sản phẩm đầu. Không "DMMA".

---

## 1. LÀM GÌ PHIÊN NÀY

Đi **2 ngã liên tiếp**, đóng **khối media thành đối xứng**: trước đó chỉ có ĐỌC nhánh ảnh trẻ + ĐỌC nhánh học liệu thiếu player; giờ **cả 2 zone × cả 2 chiều (đọc serving + ghi upload)** đều có engine + Edge + UI, nghiệm thu login thật.

- **🎯 Ngã A — Player học liệu Portal GV.** D1 bắt: `media_assets` Edge-only (D58) → client KHÔNG query trực tiếp để liệt kê track. → **mig 031 `list_curriculum_media()`** (curated-read, gương D73): trả track entitled của trường caller (`media_id`+`title`+flags), PH/admin school NULL → `[]`. Player Lovable `/portal/curriculum`: nút phát gọi `get_signed_media_url` (qua `invoke`, D76), `<audio>` từ `signed_url`, **watermark động** khi `watermark_required` (DMA·CTAN+tên trường+email+giờ), ẩn nút tải (D68). **KHÔNG migration cấu trúc** (chỉ +1 RPC).
- **🎯 Ngã B1 — Upload ảnh moment → zone `dma-private`.** Đọc Tài liệu G §6 (D64). **mig 032 `check_media_upload_access()`** (gate write-side secdef, nhận-tham-số → test SQL): nhân-sự-ĐÚNG-trường-moment (gương D58 same_school); PH/admin school NULL → `not_school_member`. **Edge mới `upload_media`** (Verify JWT OFF): auth → gate → PUT Bunny Storage (server storage-key) → insert `media_assets` service_role → audit `media_upload`. Lovable `/portal/moments`: list moment (RLS-scoped) + upload (FormData) + **preview ngay** qua `get_signed_media_url`.
- **🩹 D77 — bài học hạ tầng then chốt:** Bunny Storage **"Password" (read-write AccessKey, để PUT) ≠ CDN token-key (ký URL D74)** → secret RIÊNG per-zone (`BUNNY_*_STORAGE_KEY` vs `BUNNY_*_TOKEN_KEY`). Endpoint Storage region-specific `sg.storage.bunnycdn.com` (zone tạo ở Singapore) — KHÁC pull host. Transport client→Edge = multipart `FormData`.
- **Lock library:** RULES +D77, mở rộng D75 · SYSTEM_MAP v0.14 (+vá dòng mig 030 vốn thiếu trong bảng migration). **Xuất repo:** `031_list_curriculum_media.sql` + `032_check_media_upload_access.sql` + `upload_media/index.ts`.

---

## 2. TRẠNG THÁI THẬT CUỐI PHIÊN

- **DB:** **46 bảng** (KHÔNG đổi) · **36 hàm SECURITY DEFINER** (+`list_curriculum_media` mig 031, +`check_media_upload_access` mig 032) · **125 RLS policy** (KHÔNG đổi) · mig **001→032** · seed **001→008**.
- **Media — ĐỐI XỨNG HOÀN CHỈNH:**
  - **ĐỌC:** học liệu (entitlement D75, zone `dma-learning`, **player Portal GV + watermark**) + ảnh trẻ (consent D71, zone `dma-private`, journal có ảnh thật) — một Edge `get_signed_media_url` route-theo-cột-link.
  - **GHI:** ảnh trẻ upload (gate D77, zone `dma-private`) — Edge `upload_media` PUT Bunny Storage.
- **Bunny:** `dma-learning` + `dma-private` provision (token CDN bật). **MỚI:** storage AccessKey 2 zone (`BUNNY_PRIVATE_STORAGE_KEY`/`BUNNY_LEARNING_STORAGE_KEY`) — region Singapore. `dma` (public) lập khi tới marketing.
- **Secrets (Edge):** `BUNNY_LEARNING_*` + `BUNNY_PRIVATE_*` (host + token-key + **storage-key**) đã set.
- **App routes thật:** `/portal/{notifications, consent, support, journal, curriculum, moments}` + landing/auth/modules/rls-test.
- **Edge sống:** `get_signed_media_url` (2 nhánh) · `upload_media` (Verify JWT OFF). **⚠️ Còn sống cần xóa:** `bunny-sign-test` (ký bừa, không gate).

---

## 3. NGHIỆM THU v13 (bằng chứng thật)

| Lớp | Bằng chứng |
|---|---|
| **A — player GV** | mig 031 verify: grant `[]`, preview-demo 1 track. Login GV Cô Thúy Ngân `/portal/curriculum` → "Chú Vịt Con" + badge AUDIO/MPEG → **phát nhạc thật** (0:03/1:11, loa MacBook) + **watermark trôi** "DMA·CTAN·Trường Demo Dế Mèn·teacher.demo@…". |
| **A — PH chặn** | PH Bé Jenny `/portal/curriculum` → **rỗng** ("Chưa có học liệu nào được kích hoạt") — school NULL, học liệu = IP trường (D75). |
| **B1 — gate (SQL)** | mig 032: `test_staff_uploader`→`allowed:ok` (zone dma-private, school khớp) · `test_parent_blocked`→`not_school_member` · D15 `[]`. |
| **B1 — GV upload** | GV `/portal/moments` thấy 2 moment (Jenny vẽ tranh *Đã duyệt* + tập trống *Bản nháp*) → chọn file → **"✓ Đã tải" + ảnh hiện ngay** (upload→Bunny Storage→`media_assets`→ký URL→render = vòng GHI↔ĐỌC khép một màn). |
| **B1 — PH chặn (linh hồn)** | PH chọn file → **"Chỉ giáo viên của trường mới tải được ảnh khoảnh khắc"** (gate `not_school_member`). |
| **Gate 2 tầng D58 vẫn sống** | PH thấy **1 moment** (approved) · GV thấy **2** (cả draft) — LIVE. |

---

## 4. VIỆC TREO (dọn — gộp nợ cũ + mới)

1. **⭐ XÓA Edge `bunny-sign-test`** (ký bất kỳ path cho bất kỳ ai có anon key — bypass gate). Càng gần go-live càng nên xóa.
2. **⭐ MỚI: ảnh test móc nhầm.** GV upload thử = **screenshot DMWS** vào moment "Bé Jenny vẽ tranh mùa xuân" (approved) → 1 `media_assets` row rác + 1 object Bunny `dma-private/moments/ee2f63…/…`. Xóa row + object cho demo sạch. *(Lưu ý: nếu `get_child_journal.moments[]` trả nhiều media_id/moment thì PH có thể thấy ảnh rác này — kiểm khi dọn.)*
3. **Lưu migration vào repo:** mig **031/032** + Edge `upload_media/index.ts` đã xuất phiên này. Vẫn nợ **mig 026–030** (`.sql`) + Edge `get_signed_media_url/index.ts` cùng 001–025.
4. **Caption "[seed]"** còn ở moment thật trong DB (UI strip ở client). Cosmetic.
5. **Sửa file `seed_007_ops_config` repo:** `body_template` bỏ "Bé " thừa (đã UPDATE live).
6. **Xác nhận đã `drop function public._neg_test();`** (helper tạm test consent v9).
7. **Row test treo:** `child_observations.note`/`child_journey.entry_type`='WRITE-BLOCK TEST (panel)' + `learning_moments.caption='[panel] write-block test'` + License nếu admin từng bấm. Không gấp.

---

## 5. NGÃ KẾ (chọn đầu phiên sau)

- **A. B2 — upload học liệu zone `dma-learning`.** Cùng Edge `upload_media` mở rộng: nhánh `lesson_version_id` → zone `dma-learning` → gate = **admin/entitlement** (học liệu lõi = IP Dế Mèn, người upload = admin chứ không phải GV trường). Đóng nốt chiều GHI cho zone học liệu → media end-to-end cả 2 zone × 2 chiều.
- **B. Group-moment ≥2 trẻ (MIN-multi-child LIVE).** Seed 1 moment tag ≥2 trẻ + 1 ảnh → chứng `required_consent_type` đổi sang `group_moment_in_class`; negative: 1 trẻ thiếu consent → chặn cả ảnh + liệt kê `blocking_children`. Củng cố linh hồn consent (nhẹ).
- **C. Tách 4 portal / deploy** dma.vercel.app → demenart.com.
- **D. `request_sensitive_access`** (admin xem PII trẻ có audit — D48 carve) hoặc `create/resolve_private_share_link` (share ảnh cho PH ngoài — D55/D66).

> **Gợi ý nhịp:** **A (B2)** đóng trọn ma trận media (2 zone × 2 chiều) — gọn vì tái dùng Edge. **B** nếu muốn việc nhẹ + chứng MIN-multi-child. Dọn §4 lúc rảnh (ưu tiên xóa `bunny-sign-test` + ảnh test rác).

---

## 6. KỶ LUẬT GIỮ NGUYÊN (nhắc nhanh)

- **Audit DB/code thật trước khi viết** (D1) — phiên này bắt 2 delta nhờ audit: (a) media_assets Edge-only → cần RPC list; (b) storage-key ≠ token-key.
- **Engine-per-media-type, hai chiều (D71/D75/D77):** mỗi loại media có gate secdef nhận-tham-số (test SQL) cho CẢ đọc lẫn ghi; Edge chỉ điều phối+ký/PUT+audit, KHÔNG nhúng luật vào RLS. ảnh trẻ=consent/same_school · học liệu=entitlement/admin.
- **Storage-key ≠ token-key, secret-per-zone (D77/D74):** PUT Storage = "Password" read-write; ký CDN = token-key. Endpoint Storage region (`sg.storage.bunnycdn.com`) ≠ pull host. Secret CHỈ ở Edge (D63).
- **CORS `functions.invoke` (D76):** allow `x-client-info`; `reason` thật ở `error.context.json()`. FormData body cho upload.
- **No-download/no-claim (D65/D68):** học liệu watermark on (răn đe — yếu trên audio, cắn khi video); ảnh con-mình watermark off (ấm như album). KHÔNG tuyên bố chống quay 100%.
- **Lovable (D5/D11/D13/D14):** SCHEMA OWNERSHIP đầu prompt; fetch auth-gated client-side; KHÔNG "Try to fix all" (scanner 9–10 issue = nhiễu đúng thiết kế); REPLACE-entire-screen NOTE chống double route.
- **Library + Tra Cứu update cùng nhịp** — đã làm v13 (media tầng Edge, KHÔNG module Tra Cứu riêng → chỉ update RULES/SYSTEM_MAP; +vá dòng mig 030 thiếu).

---

*Handoff v13 — 2026-06-25 18:39 GMT+7. ✅ ĐÓNG KHỐI MEDIA ĐỐI XỨNG (đọc serving + ghi upload, cả 2 zone). Ngã A: player học liệu Portal GV (mig 031 `list_curriculum_media` + Lovable `/portal/curriculum`, nhạc+watermark). Ngã B1: upload ảnh trẻ (mig 032 `check_media_upload_access` + Edge `upload_media` PUT Bunny Storage + Lovable `/portal/moments`, upload→preview khép kín). D77 (storage-key≠token-key per-zone, region SG, FormData) + mở rộng D75. Nghiệm thu login thật: GV nghe nhạc+watermark/PH rỗng · GV upload+preview/PH chặn `not_school_member` · gate 2 tầng D58 sống. **46 bảng · 36 hàm definer · 125 policy · mig 001→032 · seed 001→008.** Xuất repo: mig 031/032 + Edge `upload_media`. Kế: B2 upload học liệu (admin) hoặc group-moment. Dọn: `bunny-sign-test` + ảnh test rác. Nguồn: A–G + RULES v13 + SYSTEM_MAP v0.14.*
