# 📦 DMA_HANDOFF_v109C.md — PRESERVE (14/07/2026 · ĐÓNG)

> **Đọc cùng:** DMA_RULES.md (tới **D290**) · DMA_SYSTEM_MAP.md (**v1.03**) · DMA_00_START_HERE.md
> **Phiên trước:** HANDOFF v109B (CONTRIBUTION CORE · ĐÓNG). **Phiên này:** V109C — "Giữ vào Hành trình".

---

## 1. TRẠNG THÁI ĐÓNG — CANONICAL

| Anchor | Giá trị |
|---|---|
| Inventory | **87 bảng / 183 secdef / 164 policy / 1 cron** (+1 bảng `preserve_records`, +6 definer, policy KHÔNG đổi — 3 policy `child_journey` được REPLACE) |
| Migrations | **94** (`v109c_a` → `v109c_e`) |
| Routes | **51** (không đổi) · Edge functions **16** (không đổi — 0 deploy) |
| `child_journey` | **non-family = 36, byte-identical** (X15). Spine tổng **37**: 36 cũ + 1 row mồ côi của contribution đã rút (giữ provenance, không hiển thị) |
| `preserve_records` | **3** — 1 active (voice, orphaned-derived) · 2 reversed (1 do Hùng, **1 do Ngân** = guardian conflict) |
| `memory_threads` / `memory_messages` | **2 / 3** — bất biến (D283 · X12) |
| Memory Cards | 16 (12 provenance + 2 native active + 2 native archived) · Card E2E `5125a540` vẫn **active** |
| Consents · `child_parents` | 37 (An `family_space_display` granted) · 17 |
| Audit sống | `family_preserve_created` 3 · `_reversed` 2 · `_orphaned` 1 |

## 2. SÁU QUYẾT ĐỊNH CTO ĐÃ THỰC THI

1. **Spine trỏ PreserveRecord:** `child_journey.ref_id = preserve_records.id` (không trỏ thẳng target) — state/actor/reversibility sống ở đúng một nơi.
2. **Reverse = DELETE spine row** + `state='reversed'` giữ provenance ⇒ `36 → 37 → 36 → 37`; consumer cũ không phải học khái niệm "reversed".
3. **Orphan derived, không lưu** — `preserve_source_live()` re-check source truth ở mọi read/sign; `family_preserve_orphaned` là audit evidence, ghi từ **4 path** mutation nguồn (withdraw · hide · archive card · archive parent_memory).
4. **Hidden = vô hình ở mọi consumption surface**, kể cả Child Journey; chỉ auditable ở stewardship surface. Unhide phục hồi nếu Preserve còn active và nguồn còn sống.
5. **Consent `family_space_display` chỉ điều tiết audience Family Space** — không gác Child Journey của guardian; rút consent ⇒ Card biến khỏi Family Space nhưng **không tự động reverse Preserve**.
6. **Reverse KHÔNG đòi membership/EA** — *"Space removal may revoke participation, but it must not prevent a guardian from removing an item from their child's Journey."*

## 3. VIỆC ĐÃ LÀM

**5 migration (D92 3-block, PASS lần đầu 5/5):**
- `v109c_a_journey_vocabulary_whitelist` — **prerequisite cứng (D288)**: 3 policy RLS `child_journey` → whitelist `source='demen'` · `get_child_journal` · `get_kid_album_service` (`in ('demen','parent')`) · `post_memory_message` + `get_memory_conversation` (chặn family — D283) · **+3 CHECK cấu trúc** (`source` · `entry_type` · cặp hợp lệ). VERIFY: journey 36, family=0, 0 policy blacklist còn sót.
- `v109c_b_preserve_records` — bảng deny-all 0-grant + 2 partial UNIQUE chống trùng + UNIQUE `journey_entry_id` + UNIQUE spine `ref_id WHERE source='family'` + 2 helper postgres-only (`is_child_guardian_profile`, **`preserve_source_live`**).
- `v109c_c_preserve_rpcs` — `preserve_memory_card` · `preserve_card_contribution` · `reverse_preserve` · `get_card_preserve_context` + `get_child_journal` nhánh family guardian-only (PHASE resolve→gate→mutate D263; deny = RETURN + audit D264).
- `v109c_d_signing_and_orphan_audit` — **tầng ký journey-rooted** (D281) cho cả `check_family_card_media_access` lẫn `check_family_contribution_media_access` (nhánh cũ giữ từng chữ) + vết orphan trên 4 path.
- `v109c_e_preserve_telemetry` — `product_events` +3 + `log_family_event` whitelist.

**0 Edge deploy** (2 hàm tầng ký REPLACE in-place, signature không đổi ⇒ `upload_media` v19 / `get_signed_media_url` v23 nguyên).

**UI — 2 commit:**
- Commit 1 (6 file): `PreserveControl` guardian-only ở Card Detail + từng Lời góp (picker đa-bé, "✓ Đã giữ vào Hành trình" / "Bỏ giữ", telemetry, refetch sau mọi mutation D282) · Journey render chip 🏡 "Từ Không gian gia đình" (Card → Polaroid/TV/gallery · voice → Radio "LỜI CỦA NGƯỜI THÂN" ký lazy · text → thẻ giấy), hành động duy nhất = Bỏ giữ.
- Commit 2 `1780436a` (1 file — **D290**): ẩn nút "Câu chuyện quanh kỷ vật" + tắt prefetch cho entry family; entry demen/parent giữ nguyên.

## 4. BẰNG CHỨNG

**X-suite 20/20 PASS, 0 fail** (fixture 1 transaction, rollback, residue 0):
X0 vocabulary isolation 6/6 (trường **không đọc** row family + **INSERT bị RLS chặn** · kid album 0 tile family · V93 `post`/`get` = `not_authorized`, threads đứng yên 2 · demen/parent regression) · X1 non-guardian (bà ngoại có `contribute`) → `not_guardian_of_child` · X2/X14 `36 → 37` · X3 contribution `→ 38` · X4 cross-child (`not_guardian_of_child` / `child_not_linked_to_card`) · X5 duplicate → `already_preserved`, count đứng yên · X-READ read-through đúng · **X5c consent**: EA cả Hùng lẫn bà = false, Journey guardian **vẫn thấy 2 entry**, ký qua `family_contribution_journey`, **bà không leo quyền** · **X6/X6B** reverse sống sót removal, non-guardian nhận generic denial · X7 guardian conflict · **X8** withdraw → entry biến mất, **guardian lẫn chính chủ hết ký được**, vết orphan sống · X9 card archive → không lộ nội dung cũ · X10 hidden vô hình + unhide phục hồi · X11 contributor vẫn `not_authorized` khi đọc Journey · X12 threads 2/3 · X15 36 row byte-identical · X16 V109B regression.

**E2E người thật PASS:** bà ngoại thu voice mới → **bà KHÔNG thấy nút Preserve** → Hùng giữ voice vào Hành trình An → **giọng bà phát trong `/parent/journal`** ("Bà Ngoại Test · Được Nguyễn Văn Hùng giữ lại") → Bỏ giữ (37→36) → giữ lại → **bà Rút lại → thẻ biến mất, Hùng lẫn bà đều `not_authorized` khi ký, provenance còn auditable** → Hùng giữ **Card** (ảnh + video hiện đúng Polaroid/TV trong Hành trình) → **Ngân (guardian #2) Bỏ giữ** (`reversed_by = Tạ Thị Thuý Ngân`) → Card vẫn `active` trong Family Space.

## 5. HAI BUG PRODUCTION DO E2E BẮT (không X-test nào bắt được)

- 🔴 **D289 — PostgREST schema cache:** 5 migration PASS + X-suite 20/20 PASS, nhưng nút Preserve **không hiện** với guardian: `.rpc()` trả 404 `PGRST202` → UI `catch` → `setPreserveCtx(null)` → **biến mất câm**. Vá: `notify pgrst, 'reload schema'`. Luật: mọi sprint tạo RPC mới phải notify + smoke từ **trình duyệt thật**.
- 🟡 **D290 — cửa dẫn tới bức tường:** thẻ family vẫn hiện nút "Câu chuyện quanh kỷ vật" trong khi backend cố ý chặn (D283). Vá bằng commit 2.

## 6. PHÁT HIỆN & NỢ MỞ

- 🟡 **Spine row mồ côi**: contribution bị rút sau khi Preserve để lại 1 row `child_journey` (source=family) không hiển thị, giữ provenance. **Chưa quyết định** dọn (nightly sweep) hay giữ. Nếu giữ, mọi metric đếm `child_journey` phải đọc theo `source`, không đếm thô.
- 🟡 **Restore UI cho Card archived** — X9 chỉ PASS ở X-suite; **cố ý KHÔNG archive Card thật** trên production vì chưa có đường phục hồi (nợ V109B).
- 🟡 Chưa có surface quản lý Preserve tập trung (danh sách "những gì đang được giữ").
- (mang từ V109B) governance archive · badge `bg-black/8` · withdraw-sau-removal không có UI · Media Compatibility Pipeline · nightly sweep pending attachment · Việt hoá email · repo GitHub sync UNVERIFIED.

## 7. NON-ACTIONS XÁC NHẬN

❌ Adult/Life Journey · ❌ self-preserve người lớn · ❌ child self-agency · ❌ teacher preserve · ❌ auto-Preserve (tạo Card / góp / tag / publish **không** đổi Journey — X12) · ❌ snapshot/copy nội dung · ❌ ranking Preserve · ❌ thread V93 trên entry family · ❌ public sharing · ❌ Events/Circles · ❌ AI suggestions · ❌ **V110 KHÔNG mở**.

## 8. PHIÊN SAU ĐỌC GÌ

Boot chuẩn: HANDOFF này → RULES tới **D290** → SYSTEM_MAP **v1.03** → audit live (kỳ vọng: **87/183/164/1** · mig **94** · `child_journey` **37 tổng / 36 non-family** · `preserve_records` 3 · threads 2/3 · cards 16). Nếu mở version sau: quyết định trước về **spine row mồ côi** và **restore UI**, và nhớ D288 (whitelist trước khi mở vocabulary) + D289 (notify pgrst sau khi tạo RPC).
