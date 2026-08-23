# 🤝 DMA_HANDOFF_v10.md — BÀN GIAO PHIÊN (Đóng 4/4 màn Chặng 2 Bunny-độc-lập + RPC đọc curated nhật ký)

> **Cách dùng:** File này = ảnh chụp trạng thái cuối phiên v10. Boot phiên sau:
> `00_START_HERE` → `RULES` → file này. Rồi audit DB/code thật trước khi viết.
> **Naming:** DMA = nền tảng; CTAN = sản phẩm đầu. Không "DMMA".

---

## 1. LÀM GÌ PHIÊN NÀY

Bunny vẫn tịt (nghi mạng VN) → đi **Ngã B (UI Bunny-độc-lập)**, đóng trọn các màn không cần media. Kết quả: **3 màn mới** + 1 RPC, hợp với `/portal/notifications` (v9) thành **4/4 màn Chặng 2**.

- **🎯 `/portal/consent` — Quyền riêng tư của con (Phương án A, đủ 8 loại consent).** PH quản 4 nhóm toggle ấm: Hiển-thị-nhật-ký · Chia-sẻ-ra-ngoài (kèm note tĩnh "phụ thuộc thiết lập trường" — D68, KHÔNG đọc `schools`) · Truyền-thông · Xác-nhận-chính-sách (`privacy_ack` dạng trạng thái, không toggle tắt). Cơ chế: bật = UPDATE-by-id/INSERT, rút = UPDATE `withdrawn_at`. Khớp engine D71 (`granted=true AND withdrawn_at IS NULL`). KHÔNG RPC (PH SELECT được row mình → RETURNING qua, D29 ổn).
- **🎯 `/portal/support` — Trợ giúp & Hỗ trợ.** Form `category` (Select 5 preset cố định: account/technical/content/billing/other — lưu giá trị Anh, hiện nhãn Việt) + `message` (textarea). List "Yêu cầu của tôi" self-scope (D57). Status enum `request_state` 7 giá trị map nhãn VN. Bỏ `attachment_media_id` khỏi V1 (upload = Edge media). **Bài học quy trình:** bản nháp chạy nhầm tên cột (`requester`/`subject`/`body` — KHÔNG tồn tại) → bản khóa thêm dòng NOTE "REPLACE entire screen" quét sạch tàn dư, KHÔNG double route.
- **🎯 `/portal/journal` — Nhật ký của con (TRÁI TIM DMA).** Timeline ấm (session→nhạc icon, badge→huy hiệu icon) + card Kỹ năng (chấm mềm, **không điểm/xếp hạng** D46) + card Huy hiệu. Mỗi entry placeholder "Hình ảnh sẽ sớm có" (hook chờ Edge). Gọi **RPC `get_child_journal`** client-side.
- **🎯 mig 028 — `get_child_journal(child_id)` (D73).** RPC secdef bắc cầu: PH đọc được bộ-xương journey nhưng KHÔNG resolve nhãn (`programs` D52 / `lesson_sessions` D53 school-scoped, PH `school_id` NULL). Gate `is_child_parent OR child_in_my_school` → JOIN nhãn an toàn (program_name + session_title + badge title/desc), KHÔNG lộ giáo trình. Grant `authenticated`.
- **Dọn rác:** xóa dòng consents `source LIKE 'WRITE-BLOCK TEST%'` → `consents_total=4`.
- Lock library: RULES +D73 · SYSTEM_MAP v0.11.

---

## 2. TRẠNG THÁI THẬT CUỐI PHIÊN

- **DB:** **46 bảng** · **33 hàm SECURITY DEFINER** (+1 v10: `get_child_journal`) · 1 non-definer · **125 RLS policy** (KHÔNG đổi — v10 chỉ thêm hàm) · mig **001→028** · seed **001→008**.
- **Hàm v10:** `get_child_journal(uuid)` — secdef, grant `authenticated` (read curated, PH gọi). Verify D15 grant `[]` ✓.
- **App — 4 màn Chặng 2 đóng:** `/portal/notifications` (v9) + `/portal/consent` + `/portal/support` + `/portal/journal`. Cùng khuôn: auth → fetch/RPC client-side sau hydrate (D13) → render Vietnamese ấm → ghi ngược. Nav header: chuông · ShieldCheck · LifeBuoy · BookHeart.
- **Media:** vẫn deny-by-default Edge-only (D69). Consent engine (mig 026) + audit writer (mig 027) đã sẵn — **chờ Bunny vào để ráp `get_signed_media_url`** (ký URL + watermark).

---

## 3. NGHIỆM THU v10 (bằng chứng thật — login PH `Ba/Mẹ Bé Jenny Demo`)

| Màn | Bằng chứng |
|---|---|
| **Consent** | Baseline đúng: `display_in_app`+`group_moment_in_class` ON, share/marketing OFF, `privacy_ack` ✓ (giờ VN). Rút `group_moment_in_class` → toggle OFF **sau re-fetch** (ghi DB thấm). |
| **Support** | Thấy **đúng 1 ticket seed của mình** ("không đổi được ảnh đại diện của con", Tài khoản, "Mới tiếp nhận"); **KHÔNG thấy** ticket profile khác (self-scope D57). Gửi yêu cầu mới (Thanh toán & hợp đồng + message) → list refresh, status default 'new'→"Mới tiếp nhận" (INSERT self). |
| **Journal** | Timeline 2 entry: "Buổi 1 — Làm quen âm thanh" gắn "Cảm Thụ Âm Nhạc Dế Mèn" + "Nhận huy hiệu mới 🎖️"; kỹ năng "Cảm thụ nhịp điệu" (chấm mềm 3/5, **không điểm số**); huy hiệu "Lần đầu giữ nhịp"; placeholder ảnh. RPC resolve nhãn đúng. |

mig 028 verify (SQL): `grant_leak_check=[]` (D15) · `journey_preview` nhãn resolve đẹp · `badges_preview` confirmed. *(Gate `not_authorized` chưa test login-vai-khác — verdict nằm trong logic, để dành kiểm khi tiện.)*

---

## 4. VIỆC TREO (dọn trước khi đi tiếp — gộp nợ cũ + mới)

1. **Lưu mig 026 + 027 + 028** (file `.sql`) vào repo/nơi an toàn cùng 001–025.
2. **Sửa file `seed_007_ops_config` trong repo:** `body_template` bỏ "Bé " thừa (`'Bé {child}...'`→`'{child}...'`) — đã UPDATE live, nhưng re-seed sẽ tái lặp "Bé Bé Jenny" nếu file repo chưa sửa.
3. **Xác nhận đã `drop function public._neg_test();`** (helper tạm test consent v9).
4. **Row test còn treo** (consents ĐÃ dọn v10): chạy block dọn handoff v8 §4 cho `child_observations.note`/`child_journey.entry_type` = `'WRITE-BLOCK TEST (panel)'` + `learning_moments.caption='[panel] write-block test'` + License nếu admin từng bấm. (Không gấp — không ảnh hưởng demo.)

---

## 5. NGÃ KẾ (chọn đầu phiên sau)

- **A. Edge media `get_signed_media_url` (nếu Bunny vào lại) — MẢNH KIẾN TRÚC LỚN CUỐI V1.** Ráp `media_consent_check` (A2 v9) + `write_audit_log` (B v9) + ký Bunny Token-Auth URL ngắn hạn + watermark động. Xong cái này thì journal/moment có ảnh thật (thay placeholder "Hình ảnh sẽ sớm có"). **Cần Bunny zone `dma-private` bật Token-Auth + `BUNNY_TOKEN_AUTH_KEY` + host.** Nguồn = Tài liệu G §12.
- **B. Tách 4 portal (Bunny-độc-lập nếu Bunny còn tịt).** Giờ mỗi portal đã có nội dung → bắt đầu tách `/portal` gộp thành Admin/School/Teacher/Parent shell riêng. Hoặc thêm màn nội-bộ-trường (vd Teacher: danh sách buổi học/điểm danh — đọc được không cần Bunny).
- **C. Deploy.** dma.vercel.app → demenart.com (A record apex + CNAME www + cập nhật Supabase auth redirect). *(Domain preview hiện đang `demenart.lovable.app`.)*

> **Gợi ý nhịp:** Bunny lên → **A** (đóng khối media, journal/moment có ảnh thật — đáng giá nhất). Bunny còn tịt → **B** (tách portal / màn nội bộ trường). Dọn §4 lúc rảnh.

---

## 6. KỶ LUẬT GIỮ NGUYÊN (nhắc nhanh)

- **Audit DB/code thật trước khi viết** (D1). Hàm nhận-tham-số test thẳng SQL Editor; hàm dùng `auth.uid()` qua helper (gate `get_child_journal`) phải login thật (D2).
- **Curated-read (D73):** vai cần đọc dữ liệu mà NHÃN ở bảng nó không có quyền → RPC secdef trả nhãn an toàn, KHÔNG nới RLS bảng gốc.
- **System-writer (D72):** bảng no-INSERT-policy ghi qua secdef grant CHỈ service_role.
- **Lovable (D5/D11/D13/D14):** KHÔNG "Try to fix all"; SCHEMA OWNERSHIP đầu mọi prompt; fetch auth-gated client-side; scanner 6–13 issue = nhiễu đúng thiết kế. **Prompt còn `⚠️CONFIRM` = đọc trước, CHƯA build; chỉ build prompt đã khóa schema.**
- **Media (D58/D69/D71):** giữ Edge-only; consent engine là secdef, KHÔNG nhét vào RLS.
- Hàm definer mới → re-verify revoke public/anon (D15).
- **Library + Tra Cứu update cùng nhịp** (KỶ LUẬT VÀNG) — đã làm v10.

---

## 7. ⭐ CÁCH LÀM VIỆC MỚI (Jean chốt v10 — thử nghiệm hiệu quả)

**Làm song song việc ĐỘC LẬP, tuần tự chỉ khi PHỤ THUỘC.**
- Việc không cần output của nhau → gói **một lượt**, Jean chạy/đọc song song (vd: SQL dọn rác + prompt Lovable cùng nhau; audit read-only luôn chạy song song).
- Điểm nghẽn tuần tự DUY NHẤT: **audit schema → rồi mới khóa code** (D1). Claude viết sẵn khung prompt song song với audit, chỉ chừa dòng `⚠️CONFIRM`; audit về vá trong vài giây.
- **Nhãn rõ ràng:** prompt `⚠️CONFIRM` = chưa build; prompt "đã khóa" = build được. SQL audit = read-only, chạy bất cứ lúc nào.
- Phiên v10 chứng minh: cách này cắt được nhiều vòng chờ (Consent→Support→Journal đi gần như liên tục).

---

*Handoff v10 — 2026-06-25 13:23 GMT+7. ✅ Đóng 4/4 màn Chặng 2 Bunny-độc-lập (notifications · consent · support · journal — trái tim DMA) + ✅ RPC đọc curated `get_child_journal` (mig 028, D73). 46 bảng · 33 hàm definer · 125 policy · mig 001→028 · seed 001→008. Bunny vẫn tịt → Edge media (Ngã A) = mảnh kiến trúc lớn cuối V1, chờ phiên sau. Nguồn: A–G UPDATED + RULES v10 + SYSTEM_MAP v0.11.*
