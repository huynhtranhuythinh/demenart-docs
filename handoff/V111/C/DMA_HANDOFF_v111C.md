# 📦 DMA_HANDOFF_v111C.md — FMN QUIET & TRUTH STATES (14/07/2026 · ĐÓNG)

> **Đọc cùng:** DMA_RULES.md (tới **D298**) · DMA_SYSTEM_MAP.md (**v1.06**) · DMA_00_START_HERE.md
> **Phiên trước:** HANDOFF v111B (EXPERIENCE GRAMMAR · ĐÓNG).
> **Phiên này:** **V111C — Quiet & Truth States.** Phase 2 · Experience Layer.
> **Nguyên tắc phiên:** *Quiet must be true. Một màn hình trống là được — một thất bại được vẽ thành kho ký ức trống thì không.*

---

## 1. TRẠNG THÁI ĐÓNG — CANONICAL

| Anchor | Giá trị | Đổi? |
|---|---|---|
| Inventory | **87 / 186 / 164 / 1** | không |
| Migrations | **98** | không (**0 SQL**) |
| Routes | **51** | không (`routeTree.gen.ts` **không bị đụng**) |
| Edge functions | **16** | không (**0 deploy**) |
| `journey_rows_total` / `_non_family` / `_effective` | **36 / 36 / 0** | không |
| `preserve_records` | **4** — 0 active · 3 reversed · **1 orphaned** | không |
| `memory_threads` / `memory_messages` | **2 / 3** | không |
| Memory Cards | **16** (15 active + 1 archived) | không |
| `child_parents` | 17 | không |

**Backend: NONE · Route: NONE · Data mutation: NONE. Frontend: 3 commit · 5 file · 1 deploy.**

---

## 2. FAILURE-COLLAPSE MATRIX (D2 — trace code sống, không tin audit cũ)

| # | Bề mặt | Request | TRƯỚC — hệ nói dối gì | SAU — sự thật |
|---|---|---|---|---|
| 1 | Stream | `get_family_memory_stream` | `catch → setCards([])` ⇒ *"Kỷ niệm của gia đình sẽ xuất hiện ở đây"* | `loading / ready / empty / error + Thử lại / denied` |
| 2 | Engagement | `get_family_card_engagement` | `setData(null)` ⇒ **cả khu 💛 + lời góp biến mất** | error hiện rõ + Thử lại; **không** vẽ nút Viết/Thu (quyền chưa biết) |
| 3 | Preserve | `get_card_preserve_context` | `setPreserveCtx(null)` ⇒ nút "Giữ vào Hành trình" **biến mất y hệt như khi không có quyền** | fail-closed **+ visible** + Thử lại |
| 4 | Archive | `get_family_archived_cards` | `setCards([])` ⇒ chip biến mất ⇒ *"tôi chẳng còn gì đã lưu trữ"* | loading (không đếm) · empty ⇒ im lặng thật · error ⇒ nói + Thử lại |
| 5 | **Family Space** | `get_family_space` (**cả 2 route**) | `setSpaces([])` ⇒ `/parent/family` render **form "Tạo không gian gia đình"** | error ⇒ *"Chưa mở được không gian gia đình…"* + Thử lại |

**🔴 Đường số 5 KHÔNG có trong V111A.** Bắt được nhờ đọc lại code sống. Đây là lời nói dối nguy hiểm nhất FMN từng vẽ ra: **mạng chập ⇒ DMA mời gia đình tạo một không gian MỚI trong khi không gian cũ của họ vẫn còn nguyên.** Một cú bấm sai thời điểm là gia đình có hai không gian.

---

## 3. VIỆC ĐÃ LÀM

**File mới — `src/features/family/FamilyStateBlock.tsx`:** `FamilyLoadingBlock` (`role=status` + nhãn screen-reader) · `FamilyEmptyPlace` (**chất liệu giấy thư** — một chỗ trống đang chờ, KHÔNG phải trang lỗi) · `FamilyQuietNotice` (error/denied — khung trung tính, **khác hẳn empty**; error có `role=alert` + Thử lại; denied không có nút, không đổ lỗi).

**Grammar mở rộng (cùng MỘT grammar, không đẻ grammar thứ hai):** `classifyRpcOutcome` · `outcomeToLoadState` · `isDeniedSignal` · `FAMILY_DENIED_REASONS` · 4 copy lỗi theo bề mặt (stream / engagement / preserve / archive / space).

**`FamilyMemoryStream.tsx`:** 4 state machine (Stream · Engagement · Preserve · Archive). `EmptyBlock`, `Sparkles`, `setCards([])` — **xoá sạch**. Archive chip **dời từ đáy Stream lên ngay dưới header**. Empty state **sở hữu CTA** (`onCreate` prop) và chỉ hiện CTA khi `can_create_card` thật.

**2 route file:** state machine cho `get_family_space` + `onCreate` + token cleanup (`#149A76`/`#FBF8F1` → 0).

---

## 4. BẰNG CHỨNG

**Acceptance thuần 18/18 PASS** (thực thi thật, trước khi UI đổi):

| Case | Kết quả |
|---|---|
| network fail | `error(retryable)` ✓ |
| `PGRST202` (schema cache — D289) | `error(retryable)` ✓ |
| RAISE `not_authorized` | **`denied`** ✓ (KHÔNG phải empty) |
| `ok:true` + 15 thẻ | `ready` ✓ |
| `ok:true` + 0 thẻ | **`empty`** ✓ — *chỉ ở đây mới được nói "chưa có ký ức"* |
| `data = null`, không error | **`error`** ✓ (KHÔNG phải empty) |
| `ok:false` + reason lạ | `error` ✓ |
| `ok:false` + `not_authorized` / `not_authenticated` / `not_found_or_not_authorized` | `denied` ✓ |
| archived `ok:true` + `[]` | `empty` ✓ (im lặng thật, không phải lỗi) |

**`denied` phân biệt được THẬT, không bịa:** stream/detail/engagement `RAISE` marker; archived/preserve/role trả `{ok:false, reason}`. Không phân biệt được ⇒ để `error`.

**TypeScript build PASS** (3/3 commit). `get_diff` verify scope: **`routeTree.gen.ts` không bị đụng**.

**⚠️ QA thất bại-đường bằng ảnh sống: `NOT VISUALLY REACHABLE SAFELY`.** Không có trình duyệt trong phiên; và theo GATE, em **không** mutate DB, **không** deploy RPC hỏng, **không** đổi tên function production để "tạo bằng chứng". Bằng chứng thay thế = 18/18 acceptance thuần + code-path. **Anh muốn thấy tận mắt:** mở DevTools → Network → **Offline** → vào `/parent/family` ⇒ phải thấy *"Chưa mở được không gian gia đình"* + **Thử lại**, **tuyệt đối không** thấy form "Tạo không gian gia đình".

---

## 5. GOVERNANCE REGRESSION (D293) — PASS

- **Hùng = guardian, KHÔNG phải creator.**
- `canEdit` = `isCreator` (creator-only, khớp `update_family_card`) ⇒ **Hùng KHÔNG thấy "Sửa"** trên Card do người khác tạo.
- `canArchive` = `native && (isCreator || isGuardian)` (khớp `archive_family_card`) ⇒ **Hùng thấy "Lưu trữ"**.
- `isGuardian` + `canCreate` đọc từ `get_family_space_role`, **fail-closed** (lỗi ⇒ false ⇒ không vẽ hành động).
- **0 ký tự** thay đổi trong governance predicate. Preserve/contribution/ack authority: không đụng.

---

## 6. HAI LUẬT MỚI (D297 · D298)

- **D297 — Error ≠ Empty, enforce bằng cơ chế.** Phân loại kết quả RPC bằng **tín hiệu backend**, không bằng hình dạng dữ liệu. `empty` chỉ tồn tại khi request **thành công** và kết quả **thật sự rỗng**. `denied` chỉ từ marker tường minh; không phân biệt được ⇒ `error`. Empty và Error **không dùng chung hình**. Retry chạy lại **đúng request**, không F5.
- **D298 — Lỗi đọc quyền: fail-closed VÀ hiện hữu.** Đối ngẫu thứ ba của D290/D293: *cổng chưa đọc được, UI im lặng bỏ cái cửa ⇒ người dùng tin rằng mình không có quyền.* Ba vế phải giữ đủ: (1) không vẽ hành động khi quyền chưa phân giải; (2) hiện **trạng thái không-hành-động đúng sự thật tại đúng chỗ của control** (không dùng toast — toast biến mất, sự thiếu vắng cái nút thì ở lại); (3) đọc lỗi = quyền **CHƯA BIẾT**, không phải `false`.

---

## 7. NỢ MỞ

**V111C′ (backend — bắt buộc đi qua D291 đủ 6 bước):**
- `creator_name` vào payload Stream (F03 — *"Bà ngoại đã thêm ký ức này"* vẫn chưa tồn tại)
- voices presence (F02 — 5 lời góp + 2 💛 vẫn vô hình ở tầng lướt)
- stable `mc.id DESC` tiebreak (F05 — 9 thẻ trùng cả `occurred_at` lẫn `created_at`)
- **một call/space, CẤM N+1** ★ đề xuất RPC **additive** (`get_family_stream_presence`) thay vì REPLACE sâu `get_family_memory_stream` — giữ baseline **D284** nguyên vẹn (tiền lệ `v110d`). Nếu REPLACE ⇒ bắt buộc X13 visibility-matrix byte-identical.

**Cũ:** 🟡 hex FMN trong `FamilyCardComposer.tsx` (chưa chạm) · 🟡 surface quản lý Preserve tập trung · 🟡 gỡ/sắp xếp media sau publish · 🟡 withdraw-sau-removal chưa có UI · 🟡 Media Compatibility Pipeline (3 card MOV) · 🟡 nightly sweep pending attachment · 🟡 Việt hoá email · repo GitHub sync **UNVERIFIED** · 🔴 Share từ card — **DEFER**.

**⚠️ Rủi ro nghiệm thu còn nguyên:** baseline **không có long-text** (story dài nhất 60 ký tự) và **không có preserved-active** ⇒ EP4 và preserve-skin vẫn **không QA được bằng dữ liệu hiện có**. V111D/E sẽ cần anh tạo nội dung thật bằng tay — **Claude không mutate hộ** (GATE F).

---

## 8. NON-ACTIONS XÁC NHẬN (V111C)

❌ chapter / Stream rhythm · ❌ presence payload · ❌ `mc.id DESC` · ❌ Memory Room · ❌ route 52 (routes vẫn **51**) · ❌ card composition mới · ❌ motion / reduced-motion · ❌ caching framework · ❌ generic state abstraction (`UniversalStateRenderer` & họ hàng) · ❌ bỏ mode toggle (**vẫn còn, vẫn chạy**) · ❌ social / AI / Events / Circles / Relevance Engine · ❌ **V111C′ chưa mở**.

---

## 9. PHIÊN SAU ĐỌC GÌ

Boot chuẩn: HANDOFF này → RULES tới **D298** → SYSTEM_MAP **v1.06** → **audit live DB** (kỳ vọng: **87/186/164/1** · migrations **98** · routes **51** · edge **16** · journey **36/36/0** · preserve **4** = 0/3/1 · threads **2/3** · cards **16** (1 archived) · `child_parents` **17**).

**Bước kế tiếp: V111C′ — STREAM PRESENCE PAYLOAD** (backend duy nhất của V111; D291 đủ 6 bước; D284 guardrails).

Sequence còn lại: `V111C′ → (V111D Stream Rhythm ∥ V111E Memory Room) → V111F Motion → V111G Closeout`. **CTO-B3:** Memory Room được cấp **+1 route** ở V111E (51 → 52).

**Ba câu phải nhớ khi mở V111C′:**
- `empty` là một lời khẳng định về sự thật — chỉ nói khi request **thành công** (D297).
- Quyền chưa đọc được **không phải** là không có quyền (D298).
- RPC mới ⇒ `notify pgrst` + gọi từ **client production** + **một hành động người-thật** rồi mới PASS (D291).
