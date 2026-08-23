# 📦 DMA_HANDOFF_v111C_PRIME.md — FMN STREAM PRESENCE PAYLOAD (14/07/2026 · ĐÓNG)

> **Đọc cùng:** DMA_RULES.md (tới **D300**) · DMA_SYSTEM_MAP.md (**v1.07**) · DMA_00_START_HERE.md
> **Phiên trước:** HANDOFF v111C (QUIET & TRUTH STATES · ĐÓNG).
> **Phiên này:** **V111C′ — Stream Presence Payload.** Sprint hợp đồng dữ liệu, không phải sprint trải nghiệm.
> **Nguyên tắc phiên:** *Một ký ức gia đình không có người là một bản ghi cơ sở dữ liệu.*

---

## 1. TRẠNG THÁI ĐÓNG — CANONICAL

| Anchor | Trước | **Sau** |
|---|---|---|
| Tables | 87 | **87** |
| SECURITY DEFINER | 186 | **188** (+`family_display_name`, +`get_family_stream_presence`) |
| Policies / cron | 164 / 1 | **164 / 1** |
| Migrations | 98 | **99** (`v111ca_stream_presence`) |
| Routes / Edge | 51 / 16 | **51 / 16** |
| `journey_rows_total / _non_family / _effective` | 36 / 36 / 0 | **36 / 36 / 0** |
| `preserve_records` | 4 = 0/3/1 | **4 = 0 active / 3 reversed / 1 orphaned** |
| threads / messages | 2 / 3 | **2 / 3** |
| Memory Cards | 16 (15+1) | **16 (15+1)** |

> `family_contribution_visible` là hàm **thuần (IMMUTABLE, không SECURITY DEFINER)** ⇒ không tính vào secdef. Vì vậy secdef là **188**, không phải 187.

**0 bảng · 0 cột · 0 index · 0 data mutation · 0 backfill · 0 route · 0 edge · 0 Stream redesign.**

---

## 2. KIẾN TRÚC ĐÃ CHỌN

Giữ đúng đề xuất V111A: **REPLACE tối thiểu Stream RPC + một RPC presence additive.**

| Đối tượng | Việc |
|---|---|
| `family_contribution_visible(state, hidden_at, contributor, actor, is_guardian)` | **MỚI** — predicate hiển thị lời góp, **rút nguyên văn** từ `get_family_card_engagement`. IMMUTABLE, **không** secdef, **không** grant cho authenticated/anon/public. |
| `family_display_name(space, profile)` | **MỚI** (secdef, postgres-only) — nguồn TÊN **duy nhất**: `family_members.display_label` → `profiles.full_name` → **NULL**. |
| `get_family_card_engagement` | **REPLACE** — dùng chung predicate. Hành vi giữ **từng chữ**. |
| `get_family_memory_stream` | **REPLACE tối thiểu** — `+creator_name` (additive) và `ORDER BY …, mc.id DESC`. Gate **D284** và mọi field khác **không đổi một ký tự**. |
| `get_family_stream_presence(space)` | **MỚI** — **1 call/Space**, EXHAUSTIVE, gate bằng chính `family_card_effective_access`. |

**D284 giữ nguyên là single access truth:** presence **không** dựng lại predicate membership / child-link / guardian / consent — nó gọi thẳng `family_card_effective_access(mc.id, v_actor)`.

---

## 3. VISIBILITY MATRIX — TRƯỚC / SAU

| Actor | Trước | Sau | Kết luận |
|---|---|---|---|
| Hùng (guardian) | 15 thẻ · `set_md5 = ffd66ed5…` | 15 thẻ · `ffd66ed5…` | **byte-identical** ✓ |
| Ngân (guardian) | 15 · `ffd66ed5…` | 15 · `ffd66ed5…` | ✓ |
| Bà ngoại (member, non-guardian) | 15 · `ffd66ed5…` | 15 · `ffd66ed5…` | ✓ |
| PH Bé Jenny (ngoài space) | `not_authorized` | `not_authorized` (**stream và presence**) | 0 enumerate ✓ |

**Thứ tự** đổi từ `ord_md5 4c11c163…` → `92fbbfa1…` — **đúng như thiết kế**: 9 thẻ hoà nay đã có thứ tự tất định. **Tập card-id không đổi. Quyền không nới, không thu.**

---

## 4. STABLE ORDERING

```sql
-- trước:  ORDER BY occurred_at DESC, created_at DESC          ← KHÔNG toàn phần (9 thẻ trùng cả hai)
-- sau:    ORDER BY occurred_at DESC, created_at DESC, id DESC ← chronology tất định
```
Bằng chứng: gọi 2 lần liên tiếp cho **cùng một chuỗi**, và chuỗi đó **khớp đúng** `ORDER BY occurred_at DESC, created_at DESC, id DESC` tính thẳng trên bảng.
Tiebreak là `id` — **trung tính**. CẤM `updated_at` / contribution-ack timestamp / preserve-archive time / media count: những thứ đó **bump theo hoạt động** ⇒ niên đại lặng lẽ biến thành **ranking** (DD10).

---

## 5. HỢP ĐỒNG PRESENCE

```jsonc
{ "ok": true, "space_id": "…", "presence": [
  { "card_id": "…",
    "contribution_people":    [ { "profile_id": "…", "display_name": "Bà ngoại" } ],
    "acknowledgement_people": [ { "profile_id": "…", "display_name": "Ba" } ] }
]}
```

**Omission semantics — EXHAUSTIVE (Option A), khai báo tường minh:**
- một entry cho **MỌI** thẻ người gọi nhìn thấy được
- entry có + mảng rỗng ⇒ **thật sự không có tiếng nói hiển thị được**
- request lỗi ⇒ **KHÔNG BIẾT** — **cấm** sụp thành "chưa ai nói gì" (D297 áp cho cả lớp phụ trợ)

**Không có count trong hợp đồng.** Nếu trả `{contribution_count: 3}` thì V111D **buộc** phải vẽ badge số — và badge số **là** engagement metric, dù ta gọi nó là gì.

**Contribution visibility:** `state='active' AND (hidden_at IS NULL OR is_guardian OR contributor = actor)` — **cùng một helper với Detail**. ⇒ *"Tiếng nói không hiện ở Detail thì tên người đó không rò ra Stream"* được bảo đảm **bằng cấu trúc**, không bằng lời hứa.
**Acknowledgement visibility:** `card_acknowledgements` **không có** cột state (toggle = insert/delete) ⇒ mọi row là effective; gộp theo `profile_id`, sắp theo lần đầu.

---

## 6. BẰNG CHỨNG (VERIFY in-migration 9/9 · RAISE ⇒ rollback toàn bộ)

| # | Kiểm | Kết quả |
|---|---|---|
| V1 | truth-table predicate: withdrawn(×2) · hidden-người-ngoài · hidden-chính-chủ · hidden-guardian · bình thường | **6/6** ✓ |
| V2 | visibility matrix + `creator_name`/`creator_profile_id` không NULL | 15 thẻ · md5 khớp · ✓ |
| V3 | order tất định | ✓ |
| V4 | outsider ⇒ `not_authorized` (stream **và** presence) | ✓ |
| V5 | presence exhaustive 15/15 cho cả 3 member | ✓ |
| V6 | **presence thật trên "Ảnh 2 có bé An (sửa lần 2)"** | góp = **`Ba` \| `Bà ngoại`** · 💛 = **`Ba` \| `Bà ngoại`** · bà ngoại có **2 lời đã rút (1 bị ẩn)** ⇒ **0 rò rỉ** · 14 thẻ còn lại: presence rỗng đúng sự thật ✓ |
| V7 | Detail engagement sau REPLACE | 3 lời góp + 2 ack — **không đổi** ✓ |
| V8 | grants | helper: **không** public/anon/authenticated · RPC: **không** public/anon · presence: `authenticated` ✓ |
| V9 | invariants | journey 36 · preserve 4 (orphaned 1) ✓ |

**`pg_proc` sống (D291 ②③④):**

| Function | secdef | proconfig | EXECUTE grantees |
|---|---|---|---|
| `family_contribution_visible` | **false** (IMMUTABLE) | — | postgres, service_role |
| `family_display_name` | true | `search_path=""` | postgres, service_role |
| `get_family_memory_stream` | true | `search_path=""` | **authenticated**, postgres |
| `get_family_card_engagement` | true | `search_path=""` | **authenticated**, postgres |
| `get_family_stream_presence` | true | `search_path=""` | **authenticated**, postgres, service_role |

**0 anon · 0 public** ở mọi function.

---

## 7. ✅ D291 — ĐỦ 10 BƯỚC, PASS

`notify pgrst, 'reload schema'` chạy trong migration ⇒ CTO xác minh trên **client production thật**.

**Bằng chứng (Chrome DevTools · `demenart.com/family` · actor **Bà Ngoại Test** — *non-guardian*, khắt khe hơn guardian path):**

| Quan sát | Kết luận |
|---|---|
| `get_family_stream_presence` → **200 · fetch · 1.3 kB** | RPC sống qua client production. **Không** `PGRST202`. Schema cache đã nạp. |
| **1 / 165 requests** (lọc theo tên) — **đúng một dòng** | **0 N+1 xác nhận trên hiện trường** (D300②). Một call cho cả Space, không phải 15 call theo thẻ. |
| Stream + `Đã lưu trữ (1)` **ngay dưới header** | V111C archive reachability sống thật; Stream không vỡ. |
| `/parent/family` · **Hùng** (guardian) → **200 · payload 15 entries** | Khớp đúng hợp đồng **EXHAUSTIVE** (15 thẻ active ⇒ 15 entry). Cả hai nhánh quyền đều xanh. |

**V111C′ ĐÓNG HOÀN TOÀN. Không còn nợ backend.**

## 8. FRONTEND (4 file · **0 JSX** — presentation thuộc V111D)

- `useFamilyStreamPresence.ts` (**mới**) — **1 request/Space**; `FamilyLoadState<FamilyPresenceMap>`; lỗi ⇒ `error`, **Stream vẫn sống**.
- `familyExperienceGrammar.ts` §7 — `FamilyPresencePerson` · `FamilyCardPresence` · `presenceByCardId` · `presenceNames` · `hasVisibleVoices` (**chỉ hỏi được khi `ready`**).
- `familyStreamModel.ts` — `FamilyCard.creator_name: string | null`. **Dữ liệu trình bày, KHÔNG phải quyền.**
- `FamilyMemoryStream.tsx` — import + gọi hook. **Không một thay đổi JSX nào.**

**N+1 audit:** tối đa **2 request/Stream** (cards + presence). `get_family_card_engagement` vẫn **chỉ** gọi khi mở Detail. Không có `.rpc(` nào bên trong `map()` hay per-card `useEffect`.

---

## 9. GOVERNANCE (D293) — PASS

Hùng = **guardian, không phải creator** · thấy **"Lưu trữ"** · **không** thấy **"Sửa"** · `canEdit`/`canArchive`/`isGuardian` **không đổi một ký tự**.
**`creator_name` KHÔNG BAO GIỜ là quyền.** Cấm tuyệt đối `canEdit = creatorName === currentUserName`.

---

## 10. HAI LUẬT MỚI

- **D299** — Chronology phải **tất định** bằng tiebreak, và tiebreak phải **trung tính** (`id`). Tiebreak theo *hoạt động* = ranking trá hình.
- **D300** — Presence là **NGƯỜI**, không phải **SỐ**. + ① không rò tiếng nói đã tắt (một predicate, một helper, hai consumer) ② một call/Space ③ omission semantics phải khai báo (EXHAUSTIVE) — và presence lỗi ≠ "không có tiếng nói".

---

## 11. NỢ MỞ

🟡 hex FMN trong `FamilyCardComposer.tsx` · 🟡 surface quản lý Preserve tập trung · 🟡 gỡ/sắp xếp media sau publish · 🟡 withdraw-sau-removal chưa có UI · 🟡 Media Compatibility Pipeline (3 card MOV) · 🟡 nightly sweep pending attachment · 🟡 Việt hoá email · repo GitHub sync **UNVERIFIED** · 🔴 Share từ card — **DEFER**.

**⚠️ Rủi ro nghiệm thu còn nguyên:** baseline **không có long-text** và **không có preserved-active** ⇒ EP4 + preserve-skin **không QA được bằng dữ liệu hiện có**. V111D/E cần anh tạo nội dung thật bằng tay — Claude **không mutate hộ** (GATE F).

---

## 12. NON-ACTIONS XÁC NHẬN (V111C′)

❌ count-as-contract · ❌ ranking / bump / relevance · ❌ N+1 · ❌ chapter header · ❌ hiển thị creator line · ❌ hiển thị voices · ❌ đổi card ratio · ❌ bỏ mode toggle · ❌ Detail redesign · ❌ Memory Room · ❌ route 52 · ❌ index đầu cơ · ❌ bảng/cột mới · ❌ **V111D chưa mở**.

---

## 13. PHIÊN SAU ĐỌC GÌ

Boot chuẩn: HANDOFF này → RULES tới **D300** → SYSTEM_MAP **v1.07** → **audit live DB** (kỳ vọng: **87 / 188 / 164 / 1** · migrations **99** · routes **51** · edge **16** · journey **36/36/0** · preserve **4** = 0/3/1 · threads **2/3** · cards **16**).

**Bước kế tiếp: V111D — STREAM RHYTHM.**

V111D sẽ có sẵn: `creator_name` · presence (người, không phải số) · chronology tất định · truth-state grammar · token layer · temporal grammar.
Việc của V111D: **chaptered stream · human time · creator presentation · voices presentation · composition rendering · bỏ mode toggle · một bề mặt cuộn duy nhất.**

**Ba câu phải nhớ:**
- Presence là **người**, không phải số — nếu V111D vẽ ra một con số, V111D đã sai (D300).
- Presence **lỗi** ≠ "chưa ai nói gì" (D297 · D300③).
- `creator_name` là **trình bày**, quyền vẫn là ID + backend (D293).
