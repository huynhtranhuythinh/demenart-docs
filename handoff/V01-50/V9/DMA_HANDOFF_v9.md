# 🤝 DMA_HANDOFF_v9.md — BÀN GIAO PHIÊN (Edge Ngã A khởi động: consent engine + RPC vận hành + màn thật đầu tiên)

> **Cách dùng:** File này = ảnh chụp trạng thái cuối phiên v9. Boot phiên sau:
> `00_START_HERE` → `RULES` → file này. Rồi audit DB/code thật trước khi viết.
> **Naming:** DMA = nền tảng; CTAN = sản phẩm đầu. Không "DMMA".

---

## 1. LÀM GÌ PHIÊN NÀY

- **Chọn Ngã A (Edge media)** nhưng **Bunny tịt giữa phiên** (nghi mạng VN — trang status.bunny.net báo operational, không sập diện rộng) → gạt phần ký Bunny sang phiên sau, làm các mảnh Bunny-độc-lập.
- **🎯 A2 — CONSENT ENGINE (mig 026, D71):** `media_consent_check(moment_id, viewer_profile, action)` — "người soát vé" quyết định media trẻ được xem/tải/chia sẻ. **MIN-multi-child** (1 trẻ thiếu consent → chặn cả moment + nêu tên bé) · nhân-sự-trường bỏ qua consent · gate `approved` · cổng khung-trường `min(trường,PH)`. **KHÔNG schema mới** (audit A1 chứng minh `media_assets` đã đủ field từ mig 005 — câu "Phase 4 ra delta" ở G §242 là ghi chú lỗi thời).
- **🎯 B — RPC VẬN HÀNH (mig 027, D72):** `create_notification` + `write_audit_log` = **"system-only writer"** cho bảng no-INSERT-policy (`notifications`/`audit_logs`). REVOKE cả `authenticated`, grant CHỈ `service_role` (chống spam noti + forge audit).
- **🎯 C — UI Chặng 2 màn thật ĐẦU TIÊN:** `/portal/notifications` (Lovable) — render config-driven qua `notification_types`, nghiệm thu login thật (parent Bé Jenny).
- **Vá nội dung:** `notification_types.body_template` bỏ "Bé " thừa (`'Bé {child}...'`→`'{child}...'`) — đã UPDATE live.
- Lock library: RULES +D71/D72 · SYSTEM_MAP v0.10.

---

## 2. TRẠNG THÁI THẬT CUỐI PHIÊN

- **DB:** **46 bảng** · **32 hàm SECURITY DEFINER** (+3 v9) · 1 non-definer · **125 RLS policy** (KHÔNG đổi — v9 thêm hàm, không thêm policy) · mig **001→027** · seed **001→008**.
- **3 hàm v9:**
  - `media_consent_check(uuid, uuid, text)` — secdef, **grant `authenticated`** (verdict read-only, UI pre-check).
  - `create_notification(text, uuid, jsonb)` · `write_audit_log(text, jsonb)` — secdef, **grant CHỈ `service_role`** (D72).
- **Media:** vẫn deny-by-default Edge-only (D69). **Consent engine đã dựng** — chờ Bunny vào để ráp `get_signed_media_url` (ký URL).
- **App:** thêm route thật `/portal/notifications` (ngoài `/portal`, `/portal/modules`, `/portal/rls-test`). Pattern khuôn: auth → fetch client-side (D13) → render qua catalog → ghi ngược.

---

## 3. NGHIỆM THU v9 (bằng chứng thật)

### A2 — consent engine (test thẳng SQL Editor, nhận tham số nên không cần login — lợi thế vs RLS D2)
| Test | Verdict | Ý nghĩa |
|---|---|---|
| staff xem approved | `school_staff`, allowed | người trong cuộc bỏ qua consent |
| PH xem approved | `ok`, allowed | trẻ có `display_in_app` → đọc nhật ký con |
| PH download | `school_blocks_download` | trường `no_external_sharing` chặn (min trường,PH) |
| PH share | `school_blocks_share` | như trên |
| PH xem draft | `moment_not_approved` | PH chỉ thấy đã-duyệt |
| **negative** (mở cổng trường→download) | **`consent_missing` + `blocking_children:[429d…]`** | **luật MIN-multi-child nổ: trẻ thiếu `download` → chặn + nêu đúng bé** |

D15 re-verify `media_consent_check`: **0 dòng public/anon** ✓.

### B — RPC vận hành
- Verify grantee 2 hàm = **`postgres` + `service_role` only** (KHÔNG public/anon/authenticated) → anti-spam + append-only đứng.
- `create_notification('moment_new', parent, payload)` → trả uuid, ghi noti thật; slug sai → raise `unknown slug`. `write_audit_log` → ghi audit thật. Dọn theo nhãn `_test` → noti về 4, audit test 0.

### C — màn /portal/notifications (ảnh thật)
- Login parent Bé Jenny → thấy 2 noti của mình (RLS). Icon/title/body/thời-gian-VN render đúng; card chưa-đọc kem+chấm-cam, đã-đọc muted; nav chuông badge "1" + "Đánh dấu tất cả đã đọc". KHÔNG bấm "Try to fix all".

---

## 4. VIỆC TREO (dọn trước khi đi tiếp)

1. **Xác nhận đã `drop function public._neg_test();`** (helper tạm test consent v9).
2. **Row test còn treo từ v8** (chưa chắc đã dọn) — chạy block dọn ở handoff v8 §4: `WRITE-BLOCK TEST%` ở observations/journey/consents/subscriptions + `learning_moments.caption='[panel] write-block test'`. Kỳ vọng moment_total về 2.
3. **Sửa file `seed_007_ops_config` trong repo:** body_template bỏ "Bé " thừa (đã sửa live, nhưng re-seed sẽ tái lặp nếu file repo chưa sửa).
4. **Lưu mig 026 + 027** (file `.sql`) vào repo/nơi an toàn cùng 001–025.

---

## 5. NGÃ KẾ (chọn đầu phiên sau)

- **A. Edge media `get_signed_media_url` (nếu Bunny vào lại).** Ráp `media_consent_check` (A2 xong) + `write_audit_log` (B xong) + ký Bunny Token-Auth URL ngắn hạn. **Cần Bunny zone `dma-private` bật Token-Auth + `BUNNY_TOKEN_AUTH_KEY` + host.** Nguồn = Tài liệu G §12. Mảnh kiến trúc lớn cuối V1.
- **B. UI Chặng 2 tiếp (Bunny-độc-lập nếu Bunny còn tịt).** Nhân khuôn từ `/portal/notifications`: **Support** (D6 — list + tạo ticket, RLS self-insert sẵn) hoặc **Consent** (D4 — ăn khớp consent engine, giá trị cao). Bắt đầu tách 4 portal khi mỗi portal có nội dung.
- **C. Deploy.** dma.vercel.app → demenart.com (A record apex + CNAME www + cập nhật Supabase auth redirect).

> **Gợi ý nhịp:** Bunny lên → **A** (đóng khối DB+Edge media). Bunny còn tịt → **B** (Support hoặc Consent) để không kẹt. Dọn §4 lúc rảnh.

---

## 6. KỶ LUẬT GIỮ NGUYÊN (nhắc nhanh)

- **Audit DB/code thật trước khi viết** (D1). `auth.uid()` NULL trong SQL Editor → cụm RLS test login thật (D2); **nhưng hàm nhận-tham-số (như `media_consent_check`) test thẳng SQL Editor được** — tận dụng.
- **System-writer (D72):** bảng no-INSERT-policy ghi qua secdef grant CHỈ service_role — đừng lỡ grant `authenticated`.
- **Lovable (D5/D11/D13/D14):** KHÔNG "Try to fix all"; SCHEMA OWNERSHIP đầu mọi prompt; fetch auth-gated client-side; scanner 6–13 issue = nhiễu đúng thiết kế.
- **Media (D58/D69/D71):** giữ Edge-only; consent engine là secdef, KHÔNG nhét vào RLS.
- Hàm definer mới → re-verify revoke public/anon (D15).
- **Library + Tra Cứu update cùng nhịp** (KỶ LUẬT VÀNG) — đã làm v9.

---

*Handoff v9 — 2026-06-25 12:37 GMT+7. Edge Ngã A khởi động: ✅ consent engine (mig 026, D71) + ✅ RPC vận hành (mig 027, D72) + ✅ màn thật đầu tiên `/portal/notifications`. 46 bảng · 32 hàm definer · 125 policy · mig 001→027. Bunny tịt (nghi mạng VN) → ký Bunny URL hoãn phiên sau. Nguồn: A–G UPDATED + RULES v9 + SYSTEM_MAP v0.10.*
