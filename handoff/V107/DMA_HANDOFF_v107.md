# 📦 DMA_HANDOFF_v107.md — V107 MEMORY CARD & STREAM (13/07/2026)

## 1. Canonical endpoint
RULES **D277** · SYSTEM_MAP **v1.00** · Handoff **v107**

**Inventory: 80 → 82 bảng / 153 → 158 definer / 164 policy (KHÔNG đổi) / 1 cron.** Migrations **73 → 77** (`v107a`–`v107d`, 0 lần fail).
Routes **51 — KHÔNG đổi** (Card Detail = overlay, chốt CTO #5). Edge **16 — KHÔNG đổi**.
Frontend: 2 commit (`a0c9ebe` Stream chính · `2d47519` fix iOS media — D277) · 2 deploy · tự áp qua Lovable agent, get_diff verify 0 file ngoài phạm vi, routeTree.gen không đụng.

**Baseline live (đo lúc đóng, ~20:20 HCM):**
- **12 Memory Card published** trong "Gia đình Hùng" (provenance `parent_memory`, related = An, newest-first) · 12 `card_person_links`
- Consent `family_space_display` của An: **granted** (anh Hùng bật qua UI thật 19:52 HCM) · Khang: 0 dòng consent + 0 nội dung trong batch — đúng thiết kế
- Telemetry sống: 5 `family_stream_opened` · 12 `family_card_detail_opened` · audit 13 `family_card_published` (12 batch + 1 XTEST) / 1 `_publication_denied` (consent_missing — bằng chứng X3+D264) / 1 `_unpublished`
- Regression: An **22 kỷ vật (21+1) — 0 mutation** · `child_journey` 36 · `child_parents` 17 · consents 37 · product_events 260

---

## 2. V107 là gì

**V-FMN-2 theo Master Build Plan v1:** kỷ niệm đầu tiên được đặt vào Family Space. Memory Card ra đời như first-class domain object theo mô hình **Hybrid Card-as-reference** — card sở hữu sự thật MỚI (publication scope · primary context · person links · occurred precision), content thuộc về nguồn, không dual-write.

**Invariant canonical mới (CTO):** *Primary context = nơi Card đang sống như social object. Provenance = nơi ký ức đến từ đâu. Native Card owns its own content; provenance-backed Card does not duplicate source content.* (D275 — enforce bằng CHECK cấu trúc, không chỉ bằng kỷ luật.)

## 3. 8 chốt CTO (đầu Stage 2)

1. Hybrid Card-as-reference — APPROVED (thay cho forward-migration destructive lẫn union-view thuần).
2. Batch 1 = parent_memories active của An **có intent rõ ràng**.
3. **9 thẻ chưa hoàn thiện LOẠI hoàn toàn** — không tạo card journal_only cho chúng (guard verify trong `v107d`).
4. Note chủ ý 0-media ("Hôm nay con được điểm 10") vẫn eligible ⇒ batch = 11 + 1 = **12 card**.
5. Detail = overlay, 0 route mới.
6. Publish per-card UI defer V108.
7. Batch 1: primary context = Family Space · provenance = parent_memory · related person = An (subject).
8. Provenance-backed card không copy title/story/media; chỉ native card tương lai sở hữu content local.

## 4. Kết quả thực thi

### Migrations (D92 từng bản, 0 fail)
- **`v107a_memory_card_core`** — `memory_cards` + `card_person_links` · deny-all RLS · CHECK content-ownership · UNIQUE partial provenance (X7 cấu trúc) · index stream.
- **`v107b_card_rpcs`** — 4 RPC: stream/detail (đọc-xuyên nguồn, 0 signed URL, MIN-consent re-check TẠI READ, nguồn archive ⇒ card ẩn) + publish/unpublish (**deny RETURN không RAISE** để vết audit sống — D276) · grants aclexplode verify 0 leak.
- **`v107c_family_telemetry`** — +2 view event + `log_family_event` (2 lớp whitelist D256; `log_parent_event` gate role parent nên family_member cần RPC riêng — phát hiện lúc audit).
- **`v107d_population_batch1`** — 12 card journal_only rule-based; VERIFY 4 tầng: đúng 12 · 0 thẻ-chưa-hoàn-thiện lọt · provenance 100% valid · nguồn nguyên vẹn 22.

### Publish (bước population 6-7, sau consent)
Anh Hùng bật consent An qua `/parent/consent` thật → 12 lệnh `publish_memory_card` qua đúng gate guardian (JWT identity Hùng) → 12 × ok + 12 vết audit. Stream Hùng trả đủ 12 card newest-first, payload 0 URL.

### X1–X8 — PASS 8/8 (JWT impersonation + card test XTEST, dọn sạch sau test)
- **X1** non-member (Đặng Văn Thành) → `not_authorized`. *(Lưu ý trung thực: chưa có Family B sống — X1 chứng minh ở dạng non-member-bị-chặn; gate là `is_family_space_member` nên cross-family isolation đúng bằng cấu trúc.)*
- **X2** `journal_only` không bao giờ ra stream (T3 + 12 card batch trước publish).
- **X3** consent withdrawn → stream rỗng + publish deny `consent_missing` **có vết audit** (tận dụng chính trạng thái withdrawn sẵn có làm bằng chứng).
- **X4** card An+Khang bị MIN chặn khi chỉ An granted.
- **X5** member removed (Bà Ngoại Test) → `not_authorized`.
- **X6** Bà Ngoại → `get_child_journal(An)` = `not_authorized` (family-side identity 0 đường vào Journey). *Biến thể "active non-guardian member" chưa test bằng người thật vì member duy nhất role family_member đã removed — cấu trúc grant V106 (42501 trước RLS) vẫn là bằng chứng nền; re-verify khi V108 có người thân sống.*
- **X7** UNIQUE provenance + 0 ref invalid (re-verify sau population).
- **X8** payload stream/detail 0 URL; ký vẫn lazy per-media qua Edge.
- Consent An restore đúng từng timestamp sau test; XTEST cleanup verify ở statement sau (bẫy D2 v17 tái diễn ở câu verify-cùng-statement — bắt ngay).

### UI (2 commit · 2 deploy)
- `a0c9ebe`: `src/features/family/` FamilyMemoryStream + model · immersive 1-card snap dọc / overview lưới 2 cột / toggle · Detail overlay (0 comment/reaction/share) · ký lazy qua `useJourneySigning` (import, không sửa journey) · telemetry fire-and-forget · cắm vào `/family` + `/parent/family` — **một Family Space, các view được authorize khác nhau, không fork sự thật**.
- `2d47519` (fix theo E2E ảnh thật của anh, công thức lấy từ `JourneyStage.tsx` production): cover không bao giờ dùng `<video>` (ảnh đầu tiên hoặc tile Video/Âm thanh) · note 0-media = thẻ lá-thư giấy kẻ dòng · AudioPlayer custom (`preload="none"` + user gesture + resign-once + link tải về) · video Detail resign-once · immersive media height `min(52vh,480px)` hết cắt title. ⇒ **D277**.
- E2E ảnh thật PASS: video piano phát trong Detail, audio 0:04/0:08 chạy, 3 ảnh workshop, lá thư "điểm 10", tile Video đúng, cả 2 chế độ.

## 5. Security evidence
- Effective Access đủ thừa số tại read; enum scope không bao giờ được đọc như authorization (D276).
- Deny-all RLS 2 bảng mới — batch publish của chính Claude cũng bị chặn SELECT trực tiếp (hệ đúng).
- Mọi nhánh deny publish để vết audit (RETURN không RAISE).
- 0 signed URL trong bất kỳ payload RPC nào; D224 nguyên vẹn.
- Grants: aclexplode verify 0 leak (PUBLIC/anon/service_role) trên 5 function mới.

## 6. Regression — PASS
Parent Journal (`get_child_journal` không đổi 1 chữ) · An 22 pm · `child_journey` 36 (0 dòng mới — V107 không đụng Journey semantics) · `child_parents` 17 · media playback · consent flows · `/auth` `/invite` `/reset-password` · family invitation/member flows V106.

## 7. Non-actions — xác nhận
❌ Family Creation (member tạo card) · ❌ Contribution · ❌ Preserve · ❌ Reactions · ❌ Relevance Engine/ranking · ❌ Adult/Life Journey · ❌ publish per-card UI · ❌ V108.

## 8. Nợ mang sang
- 🟡 **Thay 3 file v107 vào Project Knowledge** (RULES/SYSTEM_MAP bản này = bản v106 thật anh đã nạp + section V107 append nguyên văn — lần xuất 2, không còn reconstruct).
- 🟡 X6 biến thể active-non-guardian-member: re-verify bằng người thật khi V108 có người thân sống.
- 🟡 UX polish stream ("hơi tệ" → đã fix 4 điểm chính; polish sâu khi có người thân thật dùng).
- 🟡 Khang: 0 consent family_space_display (không chặn gì — 0 nội dung).
- 🟡 9 thẻ của An: công cụ đã trao (V105), hành động vẫn thuộc chị Ngân; card của chúng sẽ sinh qua đường thường khi được hoàn thiện (UNIQUE provenance sẵn sàng).
- (Giữ từ trước) 🟡 Việt hoá email template reset · 🟡 repo GitHub sync UNVERIFIED · 🟡 caption-edit sau upload · 🟡 telemetry parent-reset chờ phụ huynh thật · 🔴 Share từ card — DEFER, re-evaluate sau V-FMN-4.

## 9. Trạng thái

# V107 — MEMORY CARD & STREAM: **CLOSED** · **PILOT CONTINUES** · **KỶ NIỆM ĐẦU TIÊN ĐÃ SỐNG TRONG FAMILY SPACE**

## 10. Bài học
1. **Cover ≠ player.** iOS Safari không vẽ frame `<video>` trong list; journal đã trả giá bài này từ lâu — feature render media mới phải đối chiếu code sống (`JourneyStage`) TRƯỚC khi tự viết. V107 mất một vòng fix vì bỏ qua bước đó.
2. **Trạng thái an toàn mặc định chứng minh được cả hai chiều:** stream rỗng khi consent withdrawn là bằng chứng X3 miễn phí; publish deny khi thiếu consent để lại vết audit đầu tiên của hệ Card — không cần dựng kịch bản.
3. **Content-ownership enforce bằng CHECK rẻ hơn enforce bằng kỷ luật.** "Provenance-backed không copy content" là câu trong spec cho tới khi nó là constraint — sau đó nó là sự thật vật lý.
4. **Bẫy D2 v17 không cũ đi:** câu cleanup + count trong cùng statement lại đọc snapshot trước delete. Luật cũ bắt lỗi mới trong 30 giây.
5. **Project Knowledge lag là drift có thật (D112):** lần xuất 1 phải reconstruct section V106 từ vết hội thoại; sau khi anh nạp bản v106 thật, xuất lại lần 2 với nguyên văn — quy trình hai bước này (reconstruct-có-khai-báo → thay bằng bản thật khi có) rẻ hơn cả chờ lẫn đoán.

## 11. Recommended next action
> Chuẩn bị **V108 — FAMILY CREATION** (V-FMN-3 theo Master Build Plan v1): composer "Bạn muốn giữ lại điều gì?" cho member có capability `create_card` · native card (title NOT NULL — CHECK đã chờ sẵn) · tag/relate trong space · card của bà về An KHÔNG tự vào Journey (Journey candidate) · re-verify X6 với người thân sống. **KHÔNG tự mở.**
