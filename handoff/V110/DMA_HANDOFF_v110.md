# 📦 DMA_HANDOFF_v110.md — FMN LIFECYCLE HARDENING (14/07/2026 · ĐÓNG)

> **Đọc cùng:** DMA_RULES.md (tới **D293**) · DMA_SYSTEM_MAP.md (**v1.04**) · DMA_00_START_HERE.md
> **Phiên trước:** HANDOFF v109C (PRESERVE · ĐÓNG). **Phiên này:** V110 — orphan governance · Restore UI · runtime contract · metric semantics.
> **Nguyên tắc phiên:** *Audit truth may remain. Consumption truth must remain clean.*

---

## 1. TRẠNG THÁI ĐÓNG — CANONICAL

| Anchor | Giá trị |
|---|---|
| Inventory | **87 bảng / 186 secdef / 164 policy / 1 cron** (+3 definer: `restore_family_card` · `get_family_archived_cards` · `get_family_space_role`; 0 bảng mới, 0 policy mới) |
| Migrations | **98** (`v110a` → `v110d`) |
| Routes | **51** (không đổi) · Edge functions **16** (không đổi — **0 deploy**) |
| `journey_rows_total` | **36** |
| `journey_rows_non_family` | **36** — **byte-identical** (md5 khớp trước/sau toàn bộ X-suite) |
| `journey_entries_effective` | **0** (family row = 0) |
| `preserve_records` | **4** — 0 active · 3 reversed · **1 orphaned** (`contribution_withdrawn`) · **audit truth không mất dòng nào** |
| `memory_threads` / `memory_messages` | **2 / 3** — bất biến (D283) |
| Memory Cards | **16** (12 provenance + 3 native active + 1 native archived) |
| Consents · `child_parents` · An | 37 · 17 · 22 kỷ vật (0 admin mutation) |
| Audit sống | `family_card_restored` **2** · `family_preserve_swept` **1** · telemetry `family_restore_*` **4** |

**Transition V110 (đúng chốt CTO):** `journey 37 → 36` · non-family `36 → 36` · family spine `1 → 0` · preserve `active 1→0 · reversed 2 · orphaned 0→1 · total 3→3`.

---

## 2. HAI QUYẾT ĐỊNH CTO + MỘT CORRECTION CỦA CLAUDE

1. **Orphan policy = B′** — sweep **chỉ orphan terminal**, giữ PreserveRecord, chuyển `orphaned`.
   ⚠️ **Correction quan trọng (D292):** đề bài ban đầu ("sweep mọi orphan row") **sẽ phá X7**. Nguồn chết có **hai loại**: *terminal* (contribution withdrawn — D285 không có un-withdraw) và *reversible* (card archived · contribution hidden · parent_memory archived). Sweep loại reversible ⇒ phải viết code re-materialize spine ở **3 đường hồi sinh**, quên một đường là ký ức biến mất vĩnh viễn. Giữ mô hình **derived** cho nhóm reversible ⇒ **X7/X8 PASS bằng cấu trúc, 0 dòng code**.
2. **Metrics = 0 migration** — audit 13 function đụng `child_journey` chứng minh tầng DB **đã sạch** (evidence lọc `demen/session`; journal + kid album whitelist source; **0 consumer đếm thô**). Debt nằm ở **cách chúng ta viết tài liệu**, không nằm ở code ⇒ canonicalize định nghĩa (D292b), không dựng view/RPC ops mới.
3. **Restore = đường nhỏ nhất** — không Trash Center; chip thu gọn "Đã lưu trữ (n)" trong chính Family Stream.

---

## 3. VIỆC ĐÃ LÀM

**4 migration (D92 3-block, PASS lần đầu 4/4):**
- `v110a_terminal_orphan_lifecycle` — `preserve_records.state` +`orphaned` · +`orphaned_at`/`orphaned_reason` + CHECK sync · REPLACE `withdraw_card_contribution` (audit `_orphaned` → DELETE spine row → set `orphaned` → audit `_swept`) · **backfill đúng 1 row production**. VERIFY: journey 36/36 · family 0 · preserve 0/2/1 · **total 3** · 0 reversible bị sweep nhầm · grants sạch.
- `v110b_restore_family_card` — `restore_family_card` (**mirror ĐÚNG authorization của `archive_family_card`**: creator × capability `create_card` × member active **HOẶC** guardian của bé trong space × member active; PHASE resolve→gate→mutate D263; deny = RETURN + audit `family_card_restore_denied` D264) + `get_family_archived_cards` (chỉ trả Card mà **chính caller** được phép khôi phục).
- `v110c_restore_telemetry` — `product_events` +3 event `family_restore_opened/_completed/_failed` (whitelist 2 lớp: CHECK + `log_family_event`).
- `v110d_family_space_role` — `get_family_space_role` → `{is_guardian, can_create_card, can_invite}` (D293; **additive**, 0 đụng `get_family_memory_stream`/`get_family_card` ⇒ baseline D284 nguyên vẹn; fail-closed).

**0 Edge deploy.**

**UI — 2 commit (đúng 1 file `src/features/family/FamilyMemoryStream.tsx`, get_diff verify scope):**
- `2f99b3e8` — `ArchivedCardsSection`: chip **"Đã lưu trữ (n)"** + list (tiêu đề · người tạo · ngày lưu trữ) + nút **"Khôi phục"** + confirm + telemetry. **Render cả khi Stream rỗng** (nếu mọi Card đều archived thì đây là đường DUY NHẤT để khôi phục).
- `9273231f` — **D293**: tách `canEdit` (creator-only, khớp `update_family_card`) khỏi `canArchive` (creator **hoặc** guardian, khớp `archive_family_card`); confirm đổi lời khi guardian lưu trữ Card của người khác.

---

## 4. BẰNG CHỨNG

**X-suite 12/12 PASS, 0 fail** (1 transaction · RAISE cuối ⇒ rollback · residue 0 verify sau đó):
X1 orphan sweep **không** xoá PreserveRecord (total 3) · X2 36 non-family **byte-identical** · X3 creator restore OK / outsider `not_authorized` · X4 removed member `not_authorized` · X5 cross-space `not_authorized` · **X7** preserve → archive ⇒ `source_live=false`, Journey ẩn; restore ⇒ `source_live=true`, Journey **hiện lại** · X6 consent rút ⇒ EA=false (restore không lộ Card tag trẻ) · **X8** reversed Preserve **không** sống lại sau archive+restore · X9 archived ⇒ ký **denied**; restored ⇒ ký **allowed** (`family_card_native`) · X12 withdraw-sweep (swept=1, orphaned=1) + contributor ownership + hide/unhide + ack + contribution.

**E2E production thật (CTO, 17:41–17:59):**
1. **X10/D291** — bà ngoại `/family` → chip **"Đã lưu trữ (2)"** hiện trong trình duyệt thật ⇒ RPC gọi được sau schema reload.
2. Restore "Kỷ niệm 03" ⇒ thẻ về Stream, **ảnh ký và hiển thị được**.
3. Hùng giữ Card "Ảnh 2 có bé An" vào Hành trình An ⇒ thẻ 🏡 hiện ở `/parent/journal`.
4. Bà ngoại **archive** Card ⇒ thẻ 🏡 **biến khỏi Hành trình**.
5. **Hùng (guardian, không phải creator) khôi phục Card do người khác tạo** ⇒ thẻ 🏡 **quay lại**, ảnh + video phát được.
6. Bỏ giữ ⇒ state trả về sạch (family spine 0).

---

## 5. BUG PRODUCTION DO E2E BẮT — D293

🟡 **Guardian không thấy nút "Lưu trữ".** `archive_family_card` cho phép creator **hoặc** space-guardian (D279), nhưng `CardDetail` tính `canManage = creator === currentProfileId` ⇒ guardian **không bao giờ** lưu trữ được Card do người thân khác tạo. Nợ ngủ từ **V108**, chỉ lộ ra khi V110 có Restore và CTO đi chạy X9 thật.
**Đây là đối ngẫu chính xác của D290:** cổng mở ở DB nhưng **cửa không được vẽ ở UI** — và khó thấy hơn D290, vì người dùng không gặp lỗi, họ chỉ **không làm được việc mà hệ thống đã cho phép**.
Vá: `v110d` + commit `9273231f`. Nghiệm thu bằng ảnh thật (Hùng thấy "Lưu trữ", **không** thấy "Sửa").

---

## 6. NỢ MỞ

🟡 chưa có surface quản lý Preserve tập trung ("những gì đang được giữ") · 🟡 gỡ/sắp xếp media **sau** publish · 🟡 withdraw-sau-removal chưa có bề mặt UI (quyền sống ở RPC — support path) · 🟡 badge `bg-black/8` cosmetic · 🟡 Media Compatibility Pipeline (MOV/HEVC/WebM) · 🟡 nightly sweep pending attachment mồ côi · 🟡 Việt hoá email template · repo GitHub sync **UNVERIFIED** · 🔴 Share từ card — **DEFER** (blocker đạo đức, không phải hạ tầng).

---

## 7. NON-ACTIONS XÁC NHẬN

❌ social primitive mới · ❌ Preserve target type mới · ❌ Adult/Life Journey · ❌ AI · ❌ Events/Circles · ❌ Relevance Engine · ❌ public sharing · ❌ đổi consent semantics · ❌ đổi guardian ontology · ❌ mở rộng terminal taxonomy ngoài `contribution_withdrawn` · ❌ **V111 KHÔNG mở**.

---

## 8. PHIÊN SAU ĐỌC GÌ

Boot chuẩn: HANDOFF này → RULES tới **D293** → SYSTEM_MAP **v1.04** → **audit live DB** (kỳ vọng: **87/186/164/1** · migrations **98** · `journey_rows_non_family` **36** · `journey_rows_total` **36** · `preserve_records` **4** = 0 active/3 reversed/1 orphaned · threads **2/3** · cards **16** (1 archived) · consents 37 · `child_parents` 17).

**Ba luật mới phải nhớ khi mở version sau:**
- **D291** — RPC mới: `notify pgrst` + gọi từ **client production** + 1 hành động người-thật, rồi mới PASS.
- **D292** — chỉ sweep orphan **terminal**; nguồn có thể hồi sinh thì **giữ derived**, đừng đụng spine.
- **D293** — gate UI phải soi gương **đúng từng vế** gate RPC; hai nguồn quyền ⇒ hỏi cả hai.

Và luôn ghi **`journey_rows_non_family = 36`**, không ghi mơ hồ `child_journey = 36` (D292b).
