# 📦 DMA_HANDOFF_v109B.md — CONTRIBUTION CORE (14/07/2026 · ĐÓNG)

> **Đọc cùng:** DMA_RULES.md (tới **D287**) · DMA_SYSTEM_MAP.md (**v1.02**) · DMA_00_START_HERE.md
> **Phiên trước:** HANDOFF v108 (FAMILY CREATION · ĐÓNG). **Phiên này:** V109B — 💛 Gửi yêu thương + Góp một ký ức.
> **V109A Discovery:** đã hoàn tất trước phiên; 3 product decision chốt trong brief V109B (không lặp lại ở đây).

---

## 1. TRẠNG THÁI ĐÓNG — CANONICAL

| Anchor | Giá trị |
|---|---|
| Inventory | **86 bảng / 177 secdef / 164 policy / 1 cron** |
| Migrations | **89** (`v109b_a` → `v109b_e`) |
| Routes | **51** (không đổi) |
| Edge functions | **16** (`upload_media` **v19** · `get_signed_media_url` **v23** — registry đồng bộ) |
| `child_journey` | **36** — golden invariant giữ tại MỌI VERIFY block + mọi bước X-suite + E2E |
| Consents | 37 · An `family_space_display` **granted** |
| `child_parents` | 17 |
| Memory Cards | 16 (12 provenance + 2 native active + 2 native archived) |
| **Anchor "9 thẻ" — PIN LẠI TƯỜNG MINH** | **9 thẻ zero-junction** + 1 thẻ có junction nhưng media `state='deleted'` ("Múa nhảy mùa Hè") = **10 zero-active-media**. Dữ liệu KHÔNG đổi từ V108; chênh 9↔10 là hai định nghĩa metric. Regression sau này đo cả hai số. |
| `memory_threads` / `memory_messages` | **2 / 3** — bất biến (X12 · D283) |
| FMN data sống | 2 acknowledgements · 4 contributions active (2 text + 2 voice) · 2 contribution_media |
| UI | 1 commit `b20909f5` (1 file `FamilyMemoryStream.tsx`) · deploy `731dc397` |

## 2. BA QUYẾT ĐỊNH CTO ĐÃ THỰC THI

1. **Ack gate = Effective Access × capability `react`.** Defaults mới hardcode: bootstrap `{view_space, invite_member, create_card, react, contribute}` · invited `{view_space, create_card, react, contribute}`. Backfill 2 member active. Lời mời vẫn 0 tham số quyền (D269/D273b/D278 nguyên khối).
2. **Withdraw = ownership-only, sống sót removal, terminal** (D285). Generic denial chống enumeration. Withdrawn → không actor nào ký được voice bytes.
3. **`family_card_effective_access` = một nguồn sự thật** (D284). REPLACE stream/detail kèm guardrails: X13 capture-trước-so-sau **byte-identical** (14/14 cards 2 guardian · withdraw → 1 card 0-child · removed RAISE) + VERIFY old-vs-new in-migration.

## 3. VIỆC ĐÃ LÀM

**5 migrations (D92 3-block, PASS lần đầu 5/5):**
- `v109b_a_contribution_tables` — `card_acknowledgements` (UNIQUE card+profile; un-ack = DELETE) · `card_contributions` (kind CHECK text|voice · body CHECK per-kind [text 1–2000; voice caption ≤300] · state active|withdrawn + `withdrawn_at` đồng bộ · `hidden_at`/`hidden_by` trực giao) · `contribution_media` (UNIQUE(contribution_id) + UNIQUE(media_id)). Deny-all, 0 grant kể cả service_role.
- `v109b_b_effective_access_single_truth` — helper EA postgres-only + REPLACE `get_family_memory_stream`/`get_family_card` (payload từng chữ như cũ).
- `v109b_c_capability_react_contribute` — REPLACE `create_family_space` + `_accept_family_invitation_core` (chỉ đổi mảng) + backfill idempotent (removed KHÔNG đụng).
- `v109b_d_engagement_rpcs` — 7 public (`toggle_card_acknowledgement` · `get_family_card_engagement` · `create/edit/withdraw_card_contribution` · `hide/unhide_card_contribution`) + 2 service (`finalize_voice_contribution` atomic D286 · `check_family_contribution_media_access` D281) + helper `is_family_space_guardian`. PHASE resolve→gate→mutate (D263), deny RETURN + audit (D264), grants verify bằng aclexplode trong VERIFY.
- `v109b_e_telemetry_registry` — product_events CHECK +4 · `log_family_event` whitelist +4 · registry 19/23.

**2 Edge deploy:**
- `upload_media` v19: nhánh G `contribution_card_id` — audio-only, pre-check membership×`contribute` (authority ở DB), quota space chung, PUT → insert media (`metadata.source='family_contribution'`, pending_attach) → `finalize_voice_contribution` → compensating delete on fail. Nhánh A–F giữ nguyên byte.
- `get_signed_media_url` v23: nhánh family thử card-RPC, deny → fallback contribution-RPC (mirror pattern parent v22). Audit `family_contribution_media_view`.

**UI (tự áp qua agent + get_diff verify scope — đúng 1 file):** CardDetail +💛 section (names-over-counts) + "Góp một ký ức" (2 nút ngang hàng Viết/Thu · list chronological · Sửa/Rút lại cho owner · Ẩn/Hiện lại cho guardian · badge "Đã ẩn") + composer text (≤2000) + recorder MediaRecorder ưu-tiên-`audio/mp4` (D224) cap 3' + preview + caption ≤300 · AudioPlayer + lazy signing tái dùng · refetch sau mọi mutation (D282) · telemetry 4 events · copy DNA: "Gửi yêu thương" / "Góp một ký ức" / "Rút lại".

## 4. BẰNG CHỨNG

**X-suite: 50/50 PASS, 0 fail** — một transaction fixture (3 auth.users + 3 profiles + 2 member space A + space B + card B + 2 media voice), rollback → **residue 0** (verify riêng sau rollback). Phủ: X1 cross-space 2 chiều · X2 removed chết 4 đường + engagement RAISE · **X2B** withdraw sống sót removal (text + voice + idempotent + không rút hộ + sau rút signing chết cho guardian/contributor/member) · X3 consent withdraw (helper false, engagement RAISE, ack deny, V2 signing chết cả guardian lẫn contributor) · X4 card 0-child không vạ lây (engagement/sign OK giữa lúc withdraw) · X5 ownership · X6 hide/unhide + hidden-visibility 3 vai (owner thấy cờ, guardian thấy cờ, member thường không thấy) · X7 signing 3 deny + hidden-semantics (member deny, contributor OK, guardian OK) · X8 payload 0 signed_url · X9 UNIQUE toggle · X10 journey 36 · X11 residue 0 + baselines · X12 threads 2/3 · X13 byte-identical.

**E2E người thật 15/15 PASS** (bà ngoại re-invite qua flow thật — nhận capability mới tự động từ hàm accept đã REPLACE; đó là bằng chứng production đầu tiên của `v109b_c`):
💛+reload · text+reload · voice thật 2 chiều (bà thu → Ba nghe; Ba thu → bà nghe) · edit "(đã sửa)" · guardian hide/unhide · bà không có nút moderation · consent An OFF → stream bà tụt về card 0-child, contribution card-An + signing biến · card 0-child nguyên vẹn · consent ON → về đủ · remove bà → mất sạch (kể cả ký voice của chính bà — SQL verify: EA false, sign_own_voice false, **Hùng vẫn nghe được voice bà** = nội dung ở lại với gia đình đúng D285) · re-invite → **quyền + voice tự phục hồi nguyên vẹn** · journey 36 xuyên suốt. Audit sống: 4 `family_contribution_created` + 5 `family_contribution_media_view`.

## 5. PHÁT HIỆN & NỢ MỞ

- 🟡 **GOVERNANCE ARCHIVE (phát hiện nhờ câu hỏi CTO tại E2E):** cả 2 native card production do **bà ngoại** (non-guardian) tạo → bà archive được (gate = creator OR guardian) → card biến khỏi stream **mọi người**, kéo theo toàn bộ 💛 + lời góp + voice của người khác; **chưa có restore UI**. Đề xuất V-sau: build restore UI trước, hoặc archive-bởi-non-guardian cần guardian xác nhận.
- 🟡 Badge "Đã ẩn" dùng class `bg-black/8` (ngoài scale Tailwind — cosmetic, chữ vẫn hiện).
- 🟡 Withdraw-sau-removal chưa có bề mặt UI cho người đã removed (quyền sống ở tầng RPC — pilot xử lý qua support; đúng thiết kế).
- (Mang từ V108) empty-state family_member không-guardian · restore Card archived · gỡ/sắp xếp media post-publish · Media Compatibility Pipeline (MOV/HEVC/WebM) · nightly sweep pending attachment mồ côi · Việt hoá email template · repo GitHub sync UNVERIFIED.

## 6. NON-ACTIONS XÁC NHẬN

❌ Preserve / `preserve_records` / nút "Giữ vào Hành trình" · ❌ mọi mutation `child_journey` (0 bảng/RPC/trigger nào của V109B tham chiếu nó) · ❌ photo/video contribution (nudge tạo Card mới) · ❌ threaded replies · ❌ ranking / reaction palette / số like · ❌ @mention · ❌ public sharing · ❌ AI summarization/transcription · ❌ **V109C KHÔNG mở**.

## 7. PHIÊN SAU ĐỌC GÌ

Boot chuẩn: HANDOFF này → RULES tới D287 → SYSTEM_MAP v1.02 → audit live (kỳ vọng: 86/177/164/1 · mig 89 · journey 36 · threads 2/3 · 4 contributions). Nếu mở V109C (Preserve): đọc lại FINAL DIRECTIVE V109B + D283–D286; Preserve là hành động guardian có chủ đích, tuyệt đối không auto-ingest Contribution vào Journey.
