# 🤝 DMA_HANDOFF_v12.md — BÀN GIAO PHIÊN (ĐÓNG NHÁNH ẢNH TRẺ → journal có ẢNH THẬT)

> **Cách dùng:** File này = ảnh chụp trạng thái cuối phiên v12. Boot phiên sau:
> `00_START_HERE` → `RULES` → file này. Rồi audit DB/code thật trước khi viết.
> **Naming:** DMA = nền tảng; CTAN = sản phẩm đầu. Không "DMMA".

---

## 1. LÀM GÌ PHIÊN NÀY

Đi **Ngã B** — đóng **nhánh ảnh trẻ** của media serving → **trái tim DMA có ảnh thật** trong `/portal/journal`. Pattern y hệt slice học liệu v11, chỉ đổi engine sang consent (D71) + zone `dma-private`.

- **🎯 Provision zone `dma-private`** (token BẬT) + secret `BUNNY_PRIVATE_HOST`/`BUNNY_PRIVATE_TOKEN_KEY` + ảnh test `jenny_buoi1.jpg`. File trần = **403** (token chặn đúng).
- **🎯 mig 030 — móc media↔moment + journal trả ảnh.** D1 bắt delta: `media_assets` thiếu cột nối moment → thêm **`linked_moment_id`** (FK→learning_moments). `get_child_journal` trả thêm **`moments[]`** (chỉ `approved`, kèm `media_id`). Seed 1 ảnh trẻ móc moment approved của Jenny. Verify pre-login (D71 nhận-tham-số): approved→`allowed:ok`, draft→`moment_not_approved`, D15 `[]`, enum resolve đúng `private_child_media`.
- **🎯 Edge `get_signed_media_url` route theo cột link** (KHÔNG hardcode enum): `linked_lesson_version_id`→học liệu (D75) · `linked_moment_id`→**ảnh trẻ** gọi `media_consent_check` (D71, `view`) → ký zone `dma-private`. FULL paste-over.
- **🩹 D76 — CORS `x-client-info`.** `functions.invoke` tự gắn header `x-client-info` → preflight chặn vì Edge thiếu trong `Allow-Headers` (Console: *x-client-info is not allowed*, `net::ERR_FAILED`). Vá → cả 2 nhánh chạy. + đọc `error.context.json()` lấy `reason` (invoke throw trên 403) → UX mềm.
- **Lock library:** RULES +D76, mở rộng D75 · SYSTEM_MAP v0.13. **Xuất repo:** `030_child_media_branch.sql` + `get_signed_media_url/index.ts` (bản CORS-fixed).

---

## 2. TRẠNG THÁI THẬT CUỐI PHIÊN

- **DB:** **46 bảng** (KHÔNG đổi — mig 030 chỉ +1 cột) · **34 hàm SECURITY DEFINER** (KHÔNG đổi — `get_child_journal` là CREATE OR REPLACE) · **125 RLS policy** (KHÔNG đổi) · mig **001→030** · seed **001→008** + seed inline ảnh trẻ trong mig 030.
- **Media serving — CẢ 2 NHÁNH SỐNG:** học liệu (entitlement D75, zone `dma-learning`) + **ảnh trẻ (consent D71, zone `dma-private`)** qua một Edge `get_signed_media_url` route-theo-cột-link. Audit đủ (`curriculum_media_view`/`child_media_view`/`media_access_denied`).
- **Bunny:** `dma-learning` + `dma-private` đã provision (token bật). `dma` (public) lập khi tới marketing.
- **Secrets (Edge):** `BUNNY_LEARNING_*` + `BUNNY_PRIVATE_*` đã set.
- **App:** `/portal/journal` giờ có section **"Khoảnh khắc"** hiện **ảnh thật** (signed URL) + fallback consent mềm. 4 màn Chặng 2 đủ.
- **⚠️ Còn sống cần xóa:** Edge `bunny-sign-test` (ký bừa, không gate).

---

## 3. NGHIỆM THU v12 (bằng chứng thật — login PH `parent.demo`)

| Lớp | Bằng chứng |
|---|---|
| **Ảnh thật** | consent `display_in_app` ON → card "Bé Jenny vẽ tranh mùa xuân" hiện **ảnh thật** qua signed URL zone `dma-private`. Console No Issues. |
| **File trần** | `dma-private.b-cdn.net/jenny_buoi1.jpg` = **403 Forbidden** (token auth chặn). |
| **Negative consent (MIN sống LIVE)** | Tắt `display_in_app` → Edge **403 `consent_missing`** → card **vẫn hiện** nhưng ảnh đổi **"Đang chờ ba mẹ đồng ý cho xem ảnh này"**. Bật lại → ảnh về. *(Phép thử linh hồn: PH thấy có khoảnh khắc của con nhưng tự cầm quyền.)* |
| **Draft ẩn** | Moment `draft` (tập trống) không xuất hiện (RPC lọc `approved` + engine `moment_not_approved`). |
| **Gate pre-login (SQL)** | mig 030 verify: approved→`allowed:ok,display_in_app` · draft→`moment_not_approved` · D15 `[]` · seed ảnh móc moment đúng. |

---

## 4. VIỆC TREO (dọn — gộp nợ cũ + mới)

1. **⭐ XÓA Edge `bunny-sign-test`** (ký bất kỳ path cho bất kỳ ai có anon key — bypass gate). Chưa go-live nên chưa nguy.
2. **Lưu migration vào repo:** mig **030** + Edge `.ts` (CORS-fixed) đã xuất phiên này. Vẫn nợ **mig 026/027/028/029** (`.sql`) cùng 001–025.
3. **Caption "[seed]"** còn ở moment thật trong DB (UI đã strip ở client). Cosmetic — UPDATE bỏ prefix nếu muốn demo sạch tuyệt đối.
4. **Sửa file `seed_007_ops_config` repo:** `body_template` bỏ "Bé " thừa (đã UPDATE live).
5. **Xác nhận đã `drop function public._neg_test();`** (helper tạm test consent v9).
6. **Row test treo:** `child_observations.note`/`child_journey.entry_type`='WRITE-BLOCK TEST (panel)' + `learning_moments.caption='[panel] write-block test'` + License nếu admin từng bấm. Không gấp.

---

## 5. NGÃ KẾ (chọn đầu phiên sau)

- **A. Player học liệu Portal GV — hoàn tất khối học liệu (lớp 4 còn nợ từ v11).** Nút phát (gọi `get_signed_media_url`) + **watermark động di chuyển** (G §9: DMA·CTAN + tên trường + user + giờ) + **ẩn nút tải** (D65/D68). Login GV thật nghe nhạc / PH không. Engine sẵn; **lưu ý áp D76** (CORS `x-client-info`) cho player gọi từ browser.
- **B. `upload_media`** (GV upload moment/học liệu qua Edge → ghi `media_assets` → audit). Mở đường nhập liệu thật → thay seed thủ công. Cho cả 2 zone.
- **C. Nghiệm thu nhánh `group_moment_in_class` (ảnh nhiều trẻ).** Seed 1 moment tag ≥2 trẻ + 1 ảnh → chứng MIN-multi-child + `required_consent_type` đổi sang group. Negative: 1 trẻ thiếu consent → chặn cả ảnh + liệt kê `blocking_children`.
- **D. Tách 4 portal / deploy** dma.vercel.app → demenart.com.

> **Gợi ý nhịp:** **A** đóng trọn khối học liệu (watermark + player) — sau đó cả media (học liệu + ảnh trẻ) đều có UI hoàn chỉnh. **B** nếu muốn ngưng seed tay, vào nhập liệu thật. Dọn §4 lúc rảnh (ưu tiên xóa `bunny-sign-test`).

---

## 6. KỶ LUẬT GIỮ NGUYÊN (nhắc nhanh)

- **Audit DB/code thật trước khi viết** (D1) — phiên này bắt đúng delta `linked_moment_id` nhờ audit FK.
- **Engine-per-media-type (D75):** ảnh trẻ=consent D71 · học liệu=entitlement D75 · hợp đồng/báo cáo=role (sau). Edge **route theo cột link**, chỉ điều phối+ký+audit, KHÔNG nhúng luật vào RLS.
- **CORS `functions.invoke` (D76):** mọi Edge gọi từ browser PHẢI allow `x-client-info` (+`x-supabase-api-version`). Lỗi preflight ≠ lỗi gate (SQL-pass có thể ↔ live-fail). `reason` thật ở `error.context.json()`.
- **Secret-per-zone (D74):** Edge tra host+key theo `cdn_pull_zone`. Secret CHỈ ở Edge (D63).
- **Ký = Standard SHA256** cho file đơn (D74). **Verify JWT OFF** cho Edge tự-auth.
- **No-download V1 = UI** + audit. Ảnh con-mình watermark off (ấm như album); học liệu watermark on.
- **Lovable (D5/D11/D13/D14):** SCHEMA OWNERSHIP đầu prompt; fetch auth-gated client-side; KHÔNG "Try to fix all" (scanner 9–10 issue = nhiễu đúng thiết kế).
- **Library + Tra Cứu update cùng nhịp** — đã làm v12 (media serving tầng Edge, KHÔNG module Tra Cứu riêng → chỉ update RULES/SYSTEM_MAP).

---

*Handoff v12 — 2026-06-25 17:39 GMT+7. ✅ ĐÓNG NHÁNH ẢNH TRẺ → journal có ẢNH THẬT (trái tim DMA). mig 030 (`media_assets.linked_moment_id` + `get_child_journal.moments[]`) + Edge route-theo-cột-link (ảnh trẻ → `media_consent_check` D71 → ký zone `dma-private`) + D76 (CORS `x-client-info`). Nghiệm thu login thật PH: ảnh thật phát qua signed URL / file trần 403 / tắt consent → "Đang chờ ba mẹ đồng ý" (negative MIN-consent LIVE) / draft ẩn. **46 bảng · 34 hàm definer · 125 policy · mig 001→030 · seed 001→008.** Xuất repo: mig 030 + Edge .ts (CORS-fixed). Kế: player học liệu Portal GV (watermark) hoặc `upload_media`. Xóa `bunny-sign-test`. Nguồn: A–G + RULES v12 + SYSTEM_MAP v0.13.*
