# 🤝 DMA_HANDOFF_v11.md — BÀN GIAO PHIÊN (Bunny vào lại → ĐÓNG MẢNH MEDIA ĐẦU TIÊN: học liệu)

> **Cách dùng:** File này = ảnh chụp trạng thái cuối phiên v11. Boot phiên sau:
> `00_START_HERE` → `RULES` → file này. Rồi audit DB/code thật trước khi viết.
> **Naming:** DMA = nền tảng; CTAN = sản phẩm đầu. Không "DMMA".

---

## 1. LÀM GÌ PHIÊN NÀY

Bunny vào lại (mạng VN ổn) → đi **Ngã A (Edge media)**, đóng **mảnh kiến trúc lớn cuối V1** ở slice đầu tiên: **HỌC LIỆU** (ưu tiên #1 của Jean — đó là IP/moat franchise, và là đường ít ma sát hơn ảnh trẻ vì curriculum↔media đã nối sẵn qua `linked_lesson_version_id`).

- **⭐ Chốt topology 3-zone (D74).** Phân trục theo **token TẮT/BẬT** (Token Auth là công tắc cả-zone), KHÔNG theo "assets vs learning": `dma` (public) · `dma-learning` (học liệu, token bật) · `dma-private` (ảnh trẻ + hợp đồng + báo cáo + support, token bật). **Secret theo-từng-zone** → Edge tra host+key theo `media_assets.cdn_pull_zone`. Phiên này CHỈ provision `dma-learning`.
- **🎯 Smoke-test ký token (de-risk).** Deploy hàm `bunny-sign-test` (chỉ ký, không gate) → ký `/Chu_Vit_Con.mp3` → **phát được nhạc**; file trần = **403**. → Thuật toán **Bunny Standard URL Token Auth (SHA256)** khớp (D74). Đóng ẩn số rủi ro nhất của cả media V1.
- **🎯 mig 029 — gate học liệu (D75).** Engine `check_curriculum_media_access(media_id, viewer_profile)` secdef, **nhận tham số → test thẳng SQL Editor** (như D71): resolve media→lesson_version→program → check `school_subject_entitlements` + `school_subscriptions.state ∈ {active,trial}` còn hạn. Trả verdict + path/zone/cờ. PH + admin nền tảng từ chối ở V1. + seed inline 1 `media_assets` (Chu_Vit_Con.mp3).
- **🎯 Edge `get_signed_media_url` (D75).** Điều phối: auth `getUser()` → tra profile → gọi engine (service_role) → denied: audit `media_access_denied`+403 / allowed: ký token theo zone + audit `curriculum_media_view` → trả `signed_url`. **Deploy Verify JWT OFF** (hàm tự auth).
- **Lock library:** RULES +D74 +D75 (sửa D60) · SYSTEM_MAP v0.12. **Xuất repo:** `029_curriculum_media_gate.sql` + `get_signed_media_url/index.ts`.

---

## 2. TRẠNG THÁI THẬT CUỐI PHIÊN

- **DB:** **46 bảng** · **34 hàm SECURITY DEFINER** (+1 v11: `check_curriculum_media_access`, grant authenticated+service_role) · 1 non-definer · **125 RLS policy** (KHÔNG đổi) · mig **001→029** · seed **001→008**.
- **Media serving — slice học liệu SỐNG:** `get_signed_media_url` deploy chạy (Verify JWT OFF). Gate entitlement + ký token 3-zone + audit đủ. Nhánh **ảnh trẻ (consent) CHƯA** ráp.
- **Bunny:** 3-zone topology chốt; **chỉ `dma-learning` đã provision** (token bật, host `dma-learning.b-cdn.net`, 1 file test). `dma` + `dma-private` lập khi tới phần đó.
- **Secrets (Edge):** `BUNNY_LEARNING_HOST` + `BUNNY_LEARNING_TOKEN_KEY` đã set. (`BUNNY_PRIVATE_*` khi ráp ảnh trẻ.)
- **App:** 4 màn Chặng 2 (notifications · consent · support · journal) như v10 — **journal vẫn placeholder "Hình ảnh sẽ sớm có"** (chờ nhánh ảnh trẻ). Chưa có UI player học liệu.
- **⚠️ Còn sống cần xóa:** Edge `bunny-sign-test` (ký bừa, không gate).

---

## 3. NGHIỆM THU v11 (bằng chứng thật — 3 lớp)

| Lớp | Bằng chứng |
|---|---|
| **Ký token** | Smoke-test: `signed_url` phát được `Chu_Vit_Con.mp3` (1:11); file trần `dma-learning.b-cdn.net/Chu_Vit_Con.mp3` = **403** (token auth chặn đúng). Standard SHA256 khớp. |
| **Gate logic** (verify029 SQL) | `seeded_media` 1 row (gắn lesson_version, private_curriculum, dma-learning, watermark_required, download_allowed=false). `grant_leak_check_D15 = []`. **MEMBER → `allowed:true,"entitled"`** · **PARENT → `allowed:false,"not_school_member"`**. |
| **Edge + auth** | `get_signed_media_url` deploy chạy; tester anon → **401 `not_authenticated`** (auth gác đúng — check trước khi đọc media_id; placeholder media_id vô hại). |

*Lớp 4 (GV login thật nghe nhạc / PH không) + watermark = slice player Portal GV — để dành (D2 cần login thật).*

---

## 4. VIỆC TREO (dọn — gộp nợ cũ + mới)

1. **⭐ XÓA Edge `bunny-sign-test`** sau khi yên tâm `get_signed_media_url` (nó ký bất kỳ path cho bất kỳ ai có anon key — bypass gate). Chưa go-live nên chưa nguy, nhưng đừng để sống.
2. **Lưu migration vào repo:** mig 029 + Edge `.ts` đã xuất phiên này. Vẫn nợ **mig 026/027/028** (file `.sql`) cùng 001–025.
3. **Sửa file `seed_007_ops_config` repo:** `body_template` bỏ "Bé " thừa (đã UPDATE live).
4. **Xác nhận đã `drop function public._neg_test();`** (helper tạm test consent v9).
5. **Row test treo** (consents đã dọn v10): `child_observations.note`/`child_journey.entry_type`='WRITE-BLOCK TEST (panel)' + `learning_moments.caption='[panel] write-block test'` + License nếu admin từng bấm (block dọn handoff v8). Không gấp.

---

## 5. NGÃ KẾ (chọn đầu phiên sau)

- **A. Player học liệu Portal GV — hoàn tất trải nghiệm học liệu.** Gắn nút phát (gọi `get_signed_media_url`) + **watermark động di chuyển** (G §9: DMA·CTAN + tên trường + user + giờ) + **ẩn nút tải** (no-download = UI, D65/D68). Login GV thật nghe nhạc / PH không (lớp 4). Cần thêm UI; engine đã sẵn.
- **B. Nhánh ẢNH TRẺ → journal/moment có ảnh thật (cảm xúc nhất — trái tim DMA).** Mở `get_signed_media_url` thêm nhánh `private_child_media` gọi **`media_consent_check`** (D71, đã có). Thay placeholder "Hình ảnh sẽ sớm có" ở `/portal/journal`. **Cần:** provision zone `dma-private` (token bật) + secret `BUNNY_PRIVATE_*` + 1 ảnh test + seed `media_assets` gắn moment.
- **C. `upload_media`** (GV upload moment/học liệu qua Edge → ghi media_assets → audit). Mở đường nhập liệu thật.
- **D. Tách 4 portal / deploy** dma.vercel.app → demenart.com.

> **Gợi ý nhịp:** **B** nếu muốn journal có ảnh thật (đắt giá cảm xúc, khoe được) — pattern y hệt slice học liệu, chỉ đổi engine consent + zone private. **A** nếu muốn đóng trọn khối học liệu trước (watermark + player). Dọn §4 lúc rảnh (ưu tiên xóa `bunny-sign-test`).

---

## 6. KỶ LUẬT GIỮ NGUYÊN (nhắc nhanh)

- **Audit DB/code thật trước khi viết** (D1). Engine nhận-tham-số test thẳng SQL Editor; hàm dùng `auth.uid()`/JWT test bằng login thật (D2).
- **Engine-per-media-type (D75):** mỗi loại media nhạy cảm = 1 engine gác secdef nhận-tham-số (consent ảnh trẻ D71 · entitlement học liệu D75 · role hợp đồng/báo cáo sau). Edge chỉ điều phối + ký + audit, KHÔNG nhúng luật vào RLS.
- **Secret-per-zone (D74):** Edge tra host+key theo `cdn_pull_zone`. Secret CHỈ ở Edge (D63), KHÔNG `VITE_*`.
- **Ký = Standard SHA256** cho file đơn (D74); Advanced HS256 directory-token để dành HLS curriculum Stream.
- **No-download V1 = UI** (ẩn nút) + watermark + audit, KHÔNG chặn tuyệt đối ở token — trung thực, UI không hứa chống quay 100% (D68).
- **Verify JWT OFF** cho Edge tự-auth; hàm definer mới → re-verify revoke public/anon (D15).
- **Lovable (D5/D11/D13/D14):** SCHEMA OWNERSHIP đầu prompt; fetch auth-gated client-side; KHÔNG "Try to fix all".
- **Library + Tra Cứu update cùng nhịp** (KỶ LUẬT VÀNG) — đã làm v11 (media serving là tầng Edge, KHÔNG có module Tra Cứu riêng → đúng khi chỉ update RULES/SYSTEM_MAP).

---

*Handoff v11 — 2026-06-25 14:59 GMT+7. ✅ Bunny vào lại → ĐÓNG MẢNH MEDIA ĐẦU TIÊN (học liệu): topology 3-zone (D74) + gate entitlement `check_curriculum_media_access` (mig 029, D75) + Edge `get_signed_media_url` (ký token theo zone + audit). Nghiệm thu 3 lớp: phát nhạc qua signed URL / file trần 403 / member-allowed-parent-denied / Edge auth 401. **46 bảng · 34 hàm definer · 125 policy · mig 001→029 · seed 001→008.** Xuất repo: mig 029 + Edge .ts. Kế: nhánh ảnh trẻ (journal có ảnh thật) hoặc player học liệu Portal GV. Xóa `bunny-sign-test`. Nguồn: A–G + RULES v11 + SYSTEM_MAP v0.12.*
