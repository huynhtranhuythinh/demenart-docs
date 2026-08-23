# 📦 DMA_HANDOFF_v106.md — V106 FAMILY NETWORK FOUNDATION (13/07/2026)

## 1. Canonical endpoint
RULES **D274** · SYSTEM_MAP **v0.99** · Handoff **v106**

**Inventory: 75→**80** bảng / 143→**153** definer / 160→**164** policy / **1** cron.** Migrations **66 → 73** (`v106a`–`v106g`; 1 lần apply fail tự rollback do VERIFY của chính Claude — D92 bắt lỗi ORDER BY literal, không ghi vết).
Edge mới: **`accept_family_invitation` v1** (registry 15→16). Routes **48 → 51** (+`/parent/family` · `/family-invite` · `/family`; kèm vá drift `/reset-password` từ V105).
Frontend: 2 commit (`49595da` UI chính · `b23fa70` fix D274) · 2 deploy · **tự áp qua Lovable agent lần đầu** (get_diff verify scope, 0 file ngoài phạm vi, routeTree.gen chỉ qua codegen).

**Baseline live (đo lúc đóng, ~18:05 HCM):**
- An: **22 kỷ vật (21 active + 1 archived) — 0 mutation trong toàn V106** · `child_parents` **17, không đổi một dòng**
- **Space FMN sống đầu tiên: "Gia đình Hùng"** — 2 bé (An·Khang demo KHM) · 2 guardian member (Hùng + đồng-guardian Ngân auto-add) · 1 member removed (Bà Ngoại Test, role `family_member`, 0 link guardian) · 4 invitations (3 revoked + 1 accepted) · 10 audit event `family_*`
- consents 37 (36 + 1 dòng `family_space_display` granted→**withdrawn** — đúng sổ cái) · dup user_id 0 · auth users 14

---

## 2. V106 là gì

**Phiên FMN build đầu tiên** (V-FMN-1 theo Master Build Plan v1): Family Space + membership theo ngữ cảnh + relationship theo từng bé + capability + invitation + consent boundary. **Tường, cửa và chìa khoá — CHƯA đặt kỷ niệm vào trong.**

Correction định hình phiên — **P-G của CTO** (trước khi viết SQL): *Membership trả lời "ai thuộc không gian"; Relationship trả lời "người này là gì của ai" — không bao giờ gộp hai câu hỏi vào một cột.* ⇒ tách `family_member_relationships` khỏi `family_members`, target child-scoped Horizon A. Chứng minh live: một bà = "Bà ngoại của An" + "Bà kế của Khang" trong một membership.

## 3. Quyết định đã chốt (P-A → P-G)

- **P-A:** enum `profile_role +'family_member'` — **routing persona ONLY**, cấm làm nguồn authorization; role hiện hữu join space không conversion (D273).
- **P-B:** pilot rule 1-bé ↔ 1-space-active ở **RPC gate**, không hard-index — không hoá ontology (invariant 5).
- **P-C:** đồng-guardian auto-add lúc bootstrap (membership không cấp thêm gì họ chưa có).
- **P-D:** 3 route như trên; `/family` shell tối giản (0 stream/card/composer).
- **P-E:** `consent_type +'family_space_display'` — opt-in tường minh, 0 default, per-child, không kế thừa `display_in_app`, MIN-rule-compatible cho V107.
- **P-F:** telemetry = 6 action `audit_logs`, 0 đụng `product_events`.
- **P-G:** tách relationship (D272). Bootstrap = **explicit guardian action** (khác gợi ý seed của Build Plan — 0 seed migration, 0 đường admin-assisted ⇒ X7 đúng bằng cấu trúc).

## 4. Kết quả kỹ thuật

### Schema (5 bảng — chi tiết SYSTEM_MAP v0.99)
`family_spaces` · `family_space_children` · `family_members` (capabilities CHECK `<@` whitelist 5; `display_label` non-authoritative) · `family_member_relationships` (**composite FK cùng-space** — schema tự vệ, 0 trigger) · `family_invitations` (bảng riêng, deny-all + 0 grant authenticated, `intended_relationships` jsonb validate-mint→materialize-accept).

### RPC (+10) & Edge
Kỷ luật D259–D263 + D269 nhân bản nguyên khối lên bảng mới (2 gate self-invite/self-accept re-verify X4). `_core` postgres-only; accept **HARDCODE `{view_space}`** — lời mời không bao giờ chở quyền; accept **0 child_parents · 0 consents**. Edge clone kiến trúc parent v2. Grants verify chính xác từng grantee bằng aclexplode trong VERIFY D92.

### UI (tự áp + scope guard)
`/parent/family` (tạo · mời per-child-relationship · link-một-lần · thu hồi · gỡ có guardian-protection) · `/family-invite` (10 phase, fragment token, 0 tên bé trước xác thực) · `/family` shell FOREST · consent group mới · nav +Gia đình · homePathForRole. Copy trung thực xuyên suốt: *"Thành viên gia đình chỉ thấy không gian chung. Nhật ký riêng của con vẫn chỉ ba mẹ nhìn thấy."*

## 5. Security evidence — X1–X7 PASS toàn bộ
Chạy trong transaction tự rollback (0 residue, verify 5 bảng = 0 dòng sau test):
- **X1** member A không thấy space/member B (RLS 0 dòng + RPC chỉ trả A)
- **X2** bà ngoại: `get_child_journal` denied · `children`/`child_journey` 0 dòng · `parent_memories` chặn từ tầng **GRANT (42501) trước cả RLS** · `family_space_children` 0 — nhưng vẫn thấy space (membership sống, guardianship bất khả xâm phạm)
- **X3** relationship trỏ bé ngoài space → `invalid_relationships` · người cầm nhầm token → `email_mismatch`
- **X4** `self_invite_not_allowed` + `self_accept_not_allowed`
- **X5** remove → mọi đường đọc chết, relationships removed đồng bộ; guardian `guardian_member_protected`
- **X6** 0 dòng consent tự sinh qua toàn bộ create+accept
- **X7** super_admin: create/mint `not_authorized` · 0 space nhìn thấy · insert tay denied

## 6. E2E production PASS (7 bước, ảnh + vết DB khớp)
Guardian demo Hùng + tài khoản bà ngoại tạo mới qua chính flow. 1 bug UI bắt được ở bước 2 (link-một-lần bị unmount bởi refresh — **D274**), fix 1 file, chạy lại PASS. Relationship per-child lưu đúng; consent granted→withdrawn; audit đủ 10 event. **QA note chấp nhận là UX debt:** member list hiện "Ba · Ba" (nhãn trùng khi non-guardian không resolve tên bé) — backend data đúng.

## 7. Regression — PASS
`/parent` · `/parent/journal` · media TV/Radio playback · `/parent/consent` (các consent cũ nguyên trạng) · `/auth` · `/invite` · `/reset-password`. An 22 (21+1) · `child_parents` 17 · dup 0 · V100–V105 nguyên vẹn.

## 8. Non-actions — xác nhận
❌ Memory Stream · ❌ `memory_cards` · ❌ Card UI · ❌ Create Memory composer · ❌ Contribution · ❌ Preserve · ❌ reactions · ❌ Relevance/Events/Circles · ❌ Adult/Life Journey · ❌ V107. `child_parents` không generalize, không một dòng bị đụng.

## 9. Nợ mang sang
- 🟡 **Parent shell mở được với `family_member`** (gõ tay `/parent/*`) — DATA an toàn tuyệt đối (X2), chỉ cần polish redirect theo role.
- 🟡 Nhãn thành viên trùng lặp cho non-guardian ("Ba · Ba") — cân nhắc hiển thị khi V107 mở consent-gated name display.
- 🟡 Edit relationship label sau khi tạo (mint đóng băng, bootstrap mặc định) — chưa có RPC.
- 🟡 Space archive flow (cột `state` có, RPC/UI chưa).
- (Giữ từ trước) 🟡 Việt hoá email template reset · 🟡 repo GitHub sync UNVERIFIED · 🟡 caption-edit sau upload · 🟡 telemetry parent-reset chờ bằng chứng thật · 🔴 share từ card — DEFER, re-evaluate sau V-FMN-4 · ⚪ TV cổ polish.

## 10. Trạng thái

# V106 — FAMILY NETWORK FOUNDATION: **CLOSED** · **PILOT CONTINUES** · **FMN CÓ NỀN MÓNG SỐNG ĐẦU TIÊN**

## 11. Bài học
1. **Một correction domain đúng lúc rẻ hơn mọi migration sửa sai.** P-G chặn thiết kế gộp membership+relationship TRƯỚC dòng SQL đầu tiên — và chính live data sau đó ("Bà ngoại của An · Bà kế của Khang") chứng minh vì sao phải tách.
2. **Composite FK là guardrail rẻ nhất:** toàn vẹn cùng-space nằm trong schema, không trigger, không code — kẻ viết RPC sau này không thể trỏ chéo space dù muốn.
3. **Guard D92 bảo vệ cả khỏi người viết guard** — lần thứ hai liên tiếp (v105c → v106c): VERIFY của Claude tự sai (ORDER BY literal) và transaction tự huỷ sạch.
4. **State chỉ-hiện-một-lần là dữ liệu, không phải UI** (D274): mint thành công + link không bao giờ render = token mất vĩnh viễn. Bug này chỉ hiện ra khi người thật bấm nút — X-test SQL không bao giờ thấy.
5. **"E2E đã chạy" phải đối chiếu được bằng vết:** checklist chưa đánh dấu + DB 0 dòng = chưa chạy; nói thẳng điều đó rẻ hơn canonicalize nhầm.

## 12. Recommended next action
> Chuẩn bị **V107 — MEMORY CARD & STREAM** (V-FMN-2 theo Master Build Plan v1): `memory_cards` + provenance/primary-context [C1] + `publication_scope` [C2] + `card_person_links` + quyết định forward-migration 22 `parent_memories` tại design + Memory Stream v1 + MIN-consent gate trên `family_space_display`. **KHÔNG tự mở.**
