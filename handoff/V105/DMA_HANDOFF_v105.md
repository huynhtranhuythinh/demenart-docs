# 📦 DMA_HANDOFF_v105.md — V105 PRE-FMN HARDENING (13/07/2026)

## 1. Canonical endpoint
RULES **D271** · SYSTEM_MAP **v0.98** · Handoff **v105**

**Inventory: 75 / 143 / 160 / 1 — KHÔNG đổi.** Migrations **61 → 66** (`v105a`–`v105e`; 1 lần apply fail tự rollback, không ghi vết).
Edge đổi: `upload_media` **v17** (+caption per-file). Registry = live truth (D238): upload_media 17 · +accept_parent_invitation v2 · invite_parent **v8/retired**.
Frontend: 3 commit (`4fc9202` · `d11c860` · `bd2f02f`) · route mới `/reset-password` (47 → 48) · 2 deploy.

**Baseline live (đo lúc đóng, 15:35 HCM):**
- An: **22 kỷ vật (21 active + 1 archived) — 0 admin mutation trong toàn V105**
- 9 thẻ chưa hoàn thiện: **còn nguyên, chờ chủ sở hữu** (UI resolution đã live) · recurrence sau D266 = **0**
- `product_events`: 226 · consents 36 · dup `user_id` 0 · invitations 1 accepted · auth users 13

---

## 2. V105 là gì

Gỡ nợ vận hành + governance **trước khi** Family Memory Network nhân số người dùng. KHÔNG một dòng FMN schema/UI nào được viết.

---

## 3. Kết quả 6 workstream

### A. Password reset tự phục vụ — ✅ E2E PRODUCTION PASS
- Supabase **native recovery** (0 custom token system) + **Resend SMTP** — quyết định email provider ĐẦU TIÊN của DMA; family invitation thừa kế.
- `/auth`: dialog "Đặt lại mật khẩu" — **thông báo trung tính bất kể kết quả** (chống account enumeration) + hotline dự phòng.
- Route mới **`/reset-password`**: PKCE recovery session · min 6 ký tự (đúng Auth thật — bài học V104 #4) · invalid/expired-link state trung thực · signOut → đăng nhập lại.
- Hạ tầng: Resend key `dma-supabase-smtp` · domain `demenart.com` **Verified** (Cloudflare Auto-configure: MX+SPF `send.` · DKIM `resend._domainkey` — verify công cộng bằng DNS query độc lập; **MX gốc/hộp thư info@ nguyên vẹn**).
- **Chuỗi debug live (giá trị nhất phiên):** built-in mailer `noreply@mail.app.supabase.io` giao được cho founder nhưng KHÔNG BAO GIỜ giao được cho phụ huynh → `535 Authentication credentials invalid` (Chrome autofill đè API key bằng **Google OAuth client ID**) → `550 domain not verified` → **mail.send OK từ `no-reply@demenart.com`**. Mỗi bước trace bằng auth logs — client chỉ thấy generic 500, UI phụ huynh giữ nguyên thông báo trung tính, vết thật đầy đủ server-side (D264 thoả). ⇒ **D270**.
- E2E 15:34–15:35 HCM: email "DMA – Dế Mèn Art <no-reply@demenart.com>" → đổi mật khẩu thật (`auth.users.updated_at` khớp phút) → re-login PASS. Replay-safety: GoTrue recovery token one-time + màn hình invalid-link đã verify hoạt động ở flow 14:12.
- 🔴 **Phát hiện vĩnh viễn:** GoTrue chặn email đích không có MX (`email_address_invalid`) ⇒ **tài khoản demo không bao giờ dùng được recovery** — QA email bắt buộc mailbox thật.

### B. 9 thẻ chưa hoàn thiện của An — ✅ OWNER-CONTROLLED (D271)
- Re-verify = đúng 9 (6 rỗng hoàn toàn + 3 story ngắn); note chủ ý "điểm 10" + thẻ archived ngoài nhóm. Recurrence = 0.
- UI 3 trạng thái: `full` / `notes` (badge "ghi chú", KHÔNG nhãn lỗi, KHÔNG Lưu trữ nổi bật) / `empty` (3 hành động: Thêm tệp · Viết câu chuyện · Lưu trữ). Archive có confirm + toast **Hoàn tác** (`restore_parent_memory`). Hard delete KHÔNG mở. 0 bulk. **0 mutation dữ liệu — resolution thuộc về chị Ngân.**

### C. Registry hygiene — ✅ 3 dòng data-only
Trước: upload_media v15 · accept_parent_invitation vắng · invite_parent v7/"live". Sau: **v17 · v2 live · v8/retired-410**. Verify registry = live sau mỗi sửa.

### D. Governance P1 self-invite — ✅ D-1 + invariant canonical (D269)
- Audit xác nhận self-invite từng khả thi (mint không so email actor).
- Guardrail `v105b`: mint chặn self-email (so **auth.users**) + accept chặn accepter=created_by — cả hai ở vùng read-only (D263), grants re-harden (core postgres-only).
- Invariant chốt: *"Guardian mints family-context invitations. Operator only participates in explicitly governed bootstrap. Invitation must never become a privilege-escalation path."* Khai báo trung thực: guardrail KHÔNG chống operator dùng email phụ — cái chặn thật = audit + guardian-in-the-loop (V-FMN-1).

### E. Nhãn media per-file — ✅ 2 lớp
Auto-label "Tệp X/Y · Ảnh/Video/Âm thanh" (chỉ kỷ vật ≥2 tệp; 1 tệp giữ y hệt) + caption tự nhập lúc upload (≤80 ký tự) → Edge v17 → `metadata.label` → hiển thị qua `get_child_journal` +field `label` (`v105e`, additive, gate nguyên vẹn). Caption-edit sau upload = **defer có chủ đích**.

### F. `/auth` + repo hygiene — ✅ / UNVERIFIED
Modal mã mời chết = **no-op có bằng chứng** (V103 đã gỡ). Lệch duy nhất: mailto support@ → thống nhất `info@` (support@ mailbox UNVERIFIED — theo rule CTO: không verify được thì giữ info@). **Repo GitHub sync: UNVERIFIED** (MCP không đọc được) — nợ mang tiếp.

### Telemetry (`v105c`)
+2 event `parent_password_reset_success/_failure` (2 lớp whitelist D256, `_failure` giữ ép reason lạ → unknown). Guard D92 **bắt lỗi của chính Claude** lần apply đầu: câu VERIFY table-grant quá chặt (authenticated có SELECT là ĐÚNG V102) — đo lại live rồi viết verify theo invariant thật. Event nhánh parent chờ phụ huynh thật reset lần đầu (super_admin không log — đúng gate role, verify live = 0 event).

---

## 4. Security evidence
- Reset: 0 enumeration (response trung tính cả UI lẫn semantics) · token one-time · min-6 đúng Auth · fail-path có vết server-side (535/550/mail.send trace đầy đủ).
- Invitation: 2 gate mới trước mọi lệnh ghi; grants verify 0 leak (aclexplode); max-2-parents + audit giữ nguyên.
- Media: caption chỉ là metadata mô tả — 0 đụng authorization/signed URL/consent.
- Registry: data-only.
- RLS/policy/schema: **0 thay đổi scope** (160 policy không đổi).

## 5. Regression — PASS
`/parent` · `/parent/journal` · media playback/carousel · tạo kỷ vật · signed URL · consent: nguyên vẹn. An 22 (21+1) · dup_user_id 0 · consents 36 · V100–V104 nguyên vẹn. Login flow `/auth` không đổi.

## 6. Non-actions — xác nhận
❌ Family Space schema · ❌ family membership · ❌ memory_cards · ❌ card_person_links · ❌ preserve_records · ❌ FMN UI · ❌ hard delete kỷ vật · ❌ V106.

## 7. Nợ mang sang
- 🟡 Việt hoá email template reset (Dashboard → Auth → Email Templates — cosmetic, 5 phút, làm trước khi mời phụ huynh thật thứ hai).
- 🟡 Repo GitHub sync UNVERIFIED.
- 🟡 Caption-edit sau upload.
- 🟡 Telemetry parent-reset: chờ bằng chứng phụ huynh thật.
- 🟡 9 thẻ của An: công cụ đã trao, hành động thuộc về chủ sở hữu.
- (Giữ từ trước) 🔴 Share từ card — DEFER, re-evaluate sau V-FMN-4 · ⚪ TV cổ polish.

## 8. Trạng thái

# V105 — PRE-FMN HARDENING: **CLOSED** · **PILOT CONTINUES** · **RUNWAY SẠCH CHO V-FMN-1**

## 9. Bài học
1. **Người gửi trong email header là bằng chứng; "đã cấu hình xong" không phải bằng chứng.** Ba tầng cấu hình (toggle chưa bật → key bị autofill đè → domain chưa verify) đều báo "xong" ở tầng form, và chỉ auth logs + sender identity nói thật.
2. **Autofill của trình duyệt là một kẻ ghi đè câm.** Nó dán Google client ID vào ô Username SMTP và đè API key — hai lần trong một buổi chiều. Mọi ô credential dán tay xong phải nhìn lại trước khi Save.
3. **Guard VERIFY tự viết cũng phải đúng sự thật live** — v105c lần đầu rollback vì Claude assert một invariant chặt hơn thiết kế thật. D92 bảo vệ cả khỏi lỗi của người viết guard.
4. **Hệ demo và hệ thật tách nhau ở email:** domain không MX bị GoTrue từ chối ⇒ có những luồng chỉ test được bằng người thật, hộp thư thật — giống bài học T17-C, lần này ở tầng hạ tầng.
5. **Guardrail trung thực hơn guardrail hoành tráng:** D-1 tự khai không chống nổi kẻ chủ đích — và chính lời khai đó là thứ giữ cho V-FMN-1 phải xây guardian-in-the-loop thật thay vì ngủ quên trên một check email.

## 10. Recommended next action
> Chuẩn bị **V-FMN-1 / đề xuất V106 — Family Network Foundation** (theo Master Build Plan v1). KHÔNG tự mở.
