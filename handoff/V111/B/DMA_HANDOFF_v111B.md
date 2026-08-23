# 📦 DMA_HANDOFF_v111B.md — FMN EXPERIENCE GRAMMAR (14/07/2026 · ĐÓNG)

> **Đọc cùng:** DMA_RULES.md (tới **D296**) · DMA_SYSTEM_MAP.md (**v1.05**) · DMA_00_START_HERE.md
> **Phiên trước:** HANDOFF v110 (FMN LIFECYCLE HARDENING · ĐÓNG) → **V111A** (Experience Baseline Audit · audit-only).
> **Phiên này:** **V111B — Experience Grammar.** Phase 2 · Experience Layer · Living Archive.
> **Nguyên tắc phiên:** *Ngôn ngữ trước hình ảnh. `null` không bao giờ là một câu trả lời.*

---

## 1. TRẠNG THÁI ĐÓNG — CANONICAL

| Anchor | Giá trị | Đổi? |
|---|---|---|
| Inventory | **87 bảng / 186 secdef / 164 policy / 1 cron** | không |
| Migrations | **98** | không (**0 SQL**) |
| Routes | **51** | không |
| Edge functions | **16** | không (**0 deploy**) |
| `journey_rows_total` | **36** | không |
| `journey_rows_non_family` | **36** | không |
| `journey_entries_effective` | **0** | không |
| `preserve_records` | **4** — 0 active · 3 reversed · **1 orphaned** | không |
| `memory_threads` / `memory_messages` | **2 / 3** (D283) | không |
| Memory Cards | **16** (15 active + 1 archived) | không |
| `child_parents` · contributions · acks | 17 · 3 active/2 withdrawn · 2 | không |

**V111B là frontend-only. Backend: NONE. Route: NONE. Data mutation: NONE.**

---

## 2. V111A — EXPERIENCE BASELINE AUDIT (tóm tắt, đã ĐÓNG)

Audit-only: **Files changed NONE · Deploy NONE · Canonical NONE**. 22 finding (E-01…E-22).

**5 finding chi phối toàn bộ V111:**
1. **F01 (E4) — lỗi được vẽ thành trống rỗng.** `catch → setCards([])` (và `setData(null)`, `setPreserveCtx(null)`) ở **4 chỗ** ⇒ khi RPC fail, gia đình đọc được câu *"Kỷ niệm của gia đình sẽ xuất hiện ở đây"*. Hệ thống nói dối về sự tồn tại của ký ức.
2. **F02/F03 — tiếng nói & tác giả vô hình.** Payload Stream **không có** ack/contribution/creator_name ⇒ 5 lời góp + 2 💛 sống nhưng **0 dấu vết ở màn hình đầu tiên**; *"Bà ngoại đã thêm ký ức này"* chưa từng tồn tại trong sản phẩm.
3. **F04 — Detail không phải căn phòng.** `<Dialog max-w-lg>` + scrim `black/80` + nút X + cuộn trong cuộn. Không route ⇒ 0 deep link.
4. **F05 — thứ tự Stream không ổn định.** 9 card trùng **cả** `occurred_at` **và** `created_at`; không tiebreak thứ ba.
5. **F06 — hai quy ước thời gian.** Native = UTC-midnight; parent_memory = local-midnight. ⇒ **Chapter bắt buộc derive theo ICT.**

**Không có DD/EP nào bị REJECT.** DD2 & DD6 CONFIRMED **WITH CONSTRAINT**: *"0 schema change" đúng, nhưng "0 backend" sai* — EP5 (voices) không thể làm ở frontend vì dữ liệu không có trong payload.

**⚠️ Screenshot inventory (D3) KHÔNG thực thi được** — không có trình duyệt trong phiên, và Claude không nhập mật khẩu đăng nhập thay CTO. Đã trả **kế hoạch chụp** map sẵn route + actor + state. 3 state **NOT REACHABLE FROM LIVE BASELINE**: preserved-active (**0** bản ghi — không mutate để tạo, GATE F), reversed/orphaned (**không có surface**, đúng D292), error surface (**không tồn tại trong code** — chính là F01).

---

## 3. V111B — ĐÃ LÀM

### 3.1 File mới — `src/features/family/familyExperienceGrammar.ts` (pure · 0 React · 0 I/O)

- **Temporal:** `FAMILY_TZ = "Asia/Ho_Chi_Minh"` (hard gate) · `chapterOf` → `today | this_week | this_month | earlier | null` (**tuần bắt đầu Thứ Hai**, khoá cứng) · `humanTime` (narrative) · `evidenceDate` (provenance, tôn trọng `occurred_precision`). `long_ago` **chưa mở** — baseline chỉ trải 7 ngày.
- **Actor:** `memoryActorLine` · `contributionActorLine` · `acknowledgementLine` (names-over-counts). **Không suy diễn quan hệ từ tên** — payload chưa có `creator_name` thì trả `null`, **không bịa "Ba Hùng"**.
- **Composition:** `deriveComposition` → `text | image | gallery | video | audio | mixed`. **Text là composition. Audio là composition.** Không còn `fallback` / `no-media` / `placeholder` trong từ vựng.
- **Truth state:** `FamilyLoadState<T>` = `loading | ready | empty | error(retryable) | denied` + 5 copy object (Empty: Recognition→Meaning→Gentle Action · Error: Truth→Reassurance→Retry · Denied: Boundary→Privacy · Loading: một câu, không văn chương giả).
- **Provenance:** `provenanceLabel` — metadata hệ thống, **không all-caps**, không bao giờ là tiêu đề.

### 3.2 Token layer — `src/styles.css` (append · oklch · FMN-only · light-only)

Surfaces · Ink · Living accent (forest) · Memory material (letter · audio · film · preserve) · **đúng 1 depth token** · `--font-memory` + `--fmn-measure: 68ch` (reading measure **chỉ desktop**, mobile không bị ép 65–75ch). **Radius KHÔNG token hoá** — chưa có nhu cầu semantic. 10 semantic class `.fmn-*`.

### 3.3 `familyStreamModel.ts` — delegate

`formatOccurredAt` → `evidenceDate` · `sourceLabel` → `provenanceLabel`. Giữ nguyên type payload + media helper. **Zero visual regression về ngày tháng** (byte-identical).

### 3.4 `FamilyMemoryStream.tsx` — 22 swap (token/font/helper)

Hex → token · Georgia → `font-memory` · `bg-black/8` → `.fmn-badge-quiet` · `ackLine` cục bộ → `acknowledgementLine` từ grammar · nhãn provenance bỏ `uppercase tracking-wide` · `formatArchivedDate` bỏ giờ-trình-duyệt → `evidenceDate(iso,"day")`. **Không đổi:** layout · card composition · flow · lifecycle control · data fetching · RPC · route · mode toggle.

**2 commit** (commit 2 = `a465ed66`) · `get_diff` verify scope đúng file · **1 deploy** → `demenart.lovable.app`.

---

## 4. BẰNG CHỨNG

**Temporal + composition + actor: 39/39 PASS** bằng **thực thi thật** (trước khi một dòng UI nào đổi):

| Case | Kết quả |
|---|---|
| `2026-07-13T17:00:00Z` → ngày ICT | **14/07** ✓ (đúng kỷ vật ba mẹ) |
| `2026-07-14T00:00:00Z` → ngày ICT | **14/07** ✓ (đúng Card native) |
| Thứ Hai 13/07 | `this_week` ✓ (đầu tuần đúng) |
| **Chủ Nhật 12/07** | `this_month` ✓ — **không** lọt vào tuần này |
| 30/06 | `earlier` ✓ |
| TZ trình duyệt = LA / Kiritimati | **không đổi kết quả** ✓ |
| input rác / null | `null` ✓ — **không** âm thầm trả `today` |
| `evidenceDate` vs `formatOccurredAt` cũ | **byte-identical** ✓ |
| `[]→text` · `[img]→image` · `[img,img]→gallery` · `[video]→video` · `[audio]→audio` · `[img,video,audio]→mixed` | ✓ 7/7 |

**TypeScript build PASS** (agent chạy `tsgo --noEmit`, 0 lỗi).

**Hardcode audit (§18D):** trong FMN component → **0** occurrence của `#149A76` · `#FBF8F1` · `LETTER_BG` · `Georgia` · `bg-black/8` · `bg-amber-*` · `text-amber-*` · `ring-amber-*` · `bg-emerald-*` · `text-emerald-*`.
**RETAINED có lý do:** ① record-red `bg-rose-600/700` — affordance "đang ghi âm", không thuộc memory palette ② `FamilyCardComposer.tsx` + `routes/family.tsx` + `routes/parent.family.tsx` còn hex — **ngoài allowlist V111B**, chuyển V111C ③ `relativeVi` (lời góp) giữ nguyên — là **duration**, TZ-independent nên **không sai**; hợp nhất ngôn ngữ thời gian thuộc V111D khi Stream render `humanTime`.

**Governance regression PASS (D293):** `isCreator` → `canEdit` (creator-only, khớp `update_family_card`) · `canArchive` = `native && (isCreator || isGuardian)` (khớp `archive_family_card`) · `get_family_space_role` fail-closed. **Hùng = guardian, không phải creator ⇒ thấy "Lưu trữ", KHÔNG thấy "Sửa".** Không một ký tự nào của governance predicate bị chạm.

---

## 5. BA LUẬT MỚI (D294 · D295 · D296)

- **D294** — Grammar (time/actor/composition/state) **sống ngoài component**, pure & test được. Và: **`null`/`[]` KHÔNG BAO GIỜ là một trạng thái UI** — lỗi không được vẽ thành trống rỗng. Họ hàng của D264/D289/D290: hệ thống im lặng đúng lúc cần nói sự thật.
- **D295** — Thời gian của FMN **khoá `Asia/Ho_Chi_Minh` + tuần bắt đầu Thứ Hai**; invalid → `null` tường minh. Human time (narrative) và evidence time (provenance) là **hai hàm khác nhau**, không gộp bằng boolean flag.
- **D296** [stack: Lovable] — **`read_file` ở HEAD có thể trả bản CŨ** ngay sau commit; `get_diff(sha)` mới là sự thật. Và `send_message` **lỗi tool ≠ message chưa tới** — kiểm `list_messages`/`list_edits` trước khi retry (V111B: tool trả error nhưng agent đã áp đủ 17 edit; retry mù là hỏng).

---

## 6. NỢ MỞ

**Chuyển thẳng V111C:** 🔴 **lắp error/denied state thật vào UI** (F01 — E4) · 🟡 archive reachability (chip "Đã lưu trữ" nằm sau 15 snap toàn màn hình) · 🟡 hex trong `FamilyCardComposer.tsx` + 2 route file · 🟡 empty-state sai actor (*"ba mẹ của bé sẽ là người bắt đầu"* — trong khi bà ngoại **có** `create_card`) + CTA nằm ngoài empty block.

**Chuyển V111C′ (backend, đi qua D291 đủ 6 bước):** `creator_name` + voices presence trong payload Stream · stable `mc.id DESC` tiebreak. ★ Đề xuất **RPC additive** (`get_family_stream_presence`) thay vì REPLACE sâu `get_family_memory_stream` — giữ baseline D284 nguyên vẹn (tiền lệ `v110d`). Nếu REPLACE ⇒ **bắt buộc X13 visibility-matrix byte-identical**.

**Cũ:** 🟡 surface quản lý Preserve tập trung · 🟡 gỡ/sắp xếp media sau publish · 🟡 withdraw-sau-removal chưa có UI · 🟡 Media Compatibility Pipeline (3 card MOV) · 🟡 nightly sweep pending attachment · 🟡 Việt hoá email · repo GitHub sync **UNVERIFIED** · 🔴 Share từ card — **DEFER**.

**⚠️ Rủi ro nghiệm thu đã biết:** baseline **không có long-text** (story dài nhất = 60 ký tự) và **không có preserved-active** ⇒ EP4 và preserve-skin **không QA được bằng dữ liệu hiện có**. V111D/E sẽ cần CTO tạo nội dung thật bằng tay — **Claude không mutate hộ** (GATE F).

---

## 7. NON-ACTIONS XÁC NHẬN (V111B)

❌ chapter header render · ❌ Stream grouping/rhythm · ❌ Memory Room · ❌ route mới (routes vẫn **51**) · ❌ RPC/schema/migration/edge · ❌ skeleton Stream · ❌ motion & reduced-motion · ❌ bỏ mode toggle (**vẫn còn, vẫn chạy**) · ❌ social primitive · ❌ AI · ❌ Events/Circles · ❌ Relevance Engine · ❌ ranking/curation trá hình · ❌ **V111C chưa mở**.

---

## 8. PHIÊN SAU ĐỌC GÌ

Boot chuẩn: HANDOFF này → RULES tới **D296** → SYSTEM_MAP **v1.05** → **audit live DB** (kỳ vọng: **87/186/164/1** · migrations **98** · routes **51** · edge **16** · `journey_rows_non_family` **36** · `journey_rows_total` **36** · `preserve_records` **4** = 0/3/1 · threads **2/3** · cards **16** (1 archived) · `child_parents` **17**).

**Bước kế tiếp: V111C — QUIET & TRUTH STATES.**

Sequence còn lại: `V111C → V111C′ (backend, D291) → (V111D Stream Rhythm ∥ V111E Memory Room) → V111F Motion → V111G Closeout`.
**CTO-B3 đã khoá:** Memory Room **được cấp +1 route** ở V111E (51 → 52).

**Ba câu phải nhớ khi mở V111C:**
- Đừng làm cho sự trống rỗng **đẹp hơn** trước khi biết chắc nó **đúng sự thật** (D294b).
- Mọi ngày tháng đi qua `familyExperienceGrammar` — **không** `new Date().getDate()` (D295).
- `get_diff(sha)` là sự thật của một commit, **không** phải `read_file` (D296).
