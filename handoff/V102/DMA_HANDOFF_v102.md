# 📦 DMA_HANDOFF_v102.md — V102 PILOT OBSERVABILITY & FRICTION REMOVAL (12/07/2026)

## 1. Canonical endpoint (đọc cùng RULES + SYSTEM_MAP)
RULES **D258** · SYSTEM_MAP **v0.95** · Handoff **v102**

**Inventory: 73/135/159/1 → 74/136/160/1** (tables / SECURITY DEFINER / policies / cron) — delta đúng bằng dự kiến, drift = 0.
Registry: `admin_modules` 73→**74** · `route_registry` 45→**46**.

**Baseline giữ nguyên (regression PASS):**
- An (Nguyễn Hoàng An): **6 Tác phẩm · 2 Âm thanh · 6 Khoảnh khắc · 4 Ba mẹ lưu lại**
- Evidence: **23 events · 17 independent groups** · **DC9 / OBS8 / PART6**
- Readiness: **policy v2 · emerging · contemporaneous** · general current_3m failed = `[too_short_duration, insufficient_longitudinal_spread]`
- Khang: 0 creation · 0 parent memory · 1 moment (0 media) · 2 buổi học

---

## 2. V102 làm gì
V101 hỏi *"phụ huynh có tạo được giá trị đầu tiên không?"* V102 hỏi *"họ mắc ở đâu?"* — và câu trả lời trung thực đầu tiên là **chúng ta chưa có phụ huynh thật nào để quan sát.**

Nên V102 **không sửa UX**. Nó dựng giác quan **trước** khi người dùng thật đầu tiên bước vào — vì hành vi bỏ dở **không thể backfill**.

---

## 3. V102-A — Audit (không code) · 2 phát hiện chặn

**① Đường ghi event từ frontend ĐANG ĐÓNG HOÀN TOÀN.**
`audit_logs` là event stream **duy nhất** của toàn hệ thống (7.860 rows · 41 action · 7 category; quét cả 73 bảng, không có bảng telemetry nào khác). Nhưng:
- `write_audit_log()` grant **chỉ** `postgres` + `service_role` (D72)
- `audit_logs` có **đúng 1 policy**: `SELECT is_admin()` — **0 policy INSERT**

⇒ client `authenticated` **không có bất kỳ đường nào** ghi một event. Mọi cách đo `home_view` / `create_start` / `save_failure` đều **bắt buộc** đụng migration + definer ⇒ **STOP đúng §15**, chờ CTO.

**② Chưa có một phụ huynh thật nào.**
13 profile `primary_parent`: **9 chưa từng có login** · 4 có login đều `@demo.demenart.com`/`@demenart.com` · **0 phụ huynh thật** · actor duy nhất có hoạt động = **PH Hùng = tài khoản QA của chính chúng ta** (6 saves · 5 uploads · 3.094 media view · 13 ngày active).

**Funnel coverage trước V102:**

| Bước | Đo được? |
|---|---|
| Home viewed | ❌ mù |
| Create started | ❌ mù (đúng chỗ cần nhất) |
| Save succeeded | ✅ `audit_logs.create_parent_memory` |
| Save failed | ❌ mù |
| Journey item viewed | 🟡 proxy media — kỷ vật text-only **vô hình** |
| Second entry | ✅ derive được đầy đủ |
| Return session | 🟡 proxy — con không có media ⇒ PH mở app để lại **0 dấu vết** |

---

## 4. CTO decision → V102-B + V102-C cùng sprint
Kiến trúc A, nhưng GO luôn V102-C. `audit_logs` giữ nguyên vai trò forensic; product telemetry là **stream riêng, tối thiểu, privacy-first**.

---

## 5. V102-C — Migration `v102c_product_events_telemetry`

`+1 bảng` **`product_events`** · `+1 policy` (admin SELECT) · `+1 SECURITY DEFINER` **`log_parent_event()`** · **0 đụng `audit_logs`** · 0 Edge · 0 cron.

Schema: `id · actor_id · event_type · route · child_id · school_id · session_id · memory_type · media_count · outcome · reason_code · duration_bucket · created_at` + 8 CHECK constraint + 3 index (gương index V100).
**Cố ý KHÔNG có cột `metadata` jsonb** — không có túi tuỳ ý thì không có đường rò.

`log_parent_event()`: actor lấy server-side (**không có param `actor_id`**) · role gate parent · whitelist cứng 7 event · `is_child_parent()` deny **generic** · enum/regex validate · dedupe 3s cho `parent_home_view` · `school_id` suy từ enrollment · `search_path=''` · **không gọi `write_audit_log`**.

> ⚠️ **Guard D92 bắt được lỗi thật ngay lần apply đầu.** `REVOKE INSERT, UPDATE, DELETE ... FROM authenticated` là **chưa đủ** — Supabase còn để lại quyền **TRUNCATE** từ default grant. BLOCK 3 VERIFY phát hiện `authenticated:TRUNCATE`, migration **tự rollback**. Phải `REVOKE ALL` rồi `GRANT SELECT`. Không có khối VERIFY thì lỗ này đã lên production im lặng.

---

## 6. Security tests T1–T9 — PASS toàn bộ (live)

| # | Test | Kết quả |
|---|---|---|
| T1 | Parent log event cho con mình | ✅ ok |
| T2 | Parent log cho **con người khác** | `not_authorized` |
| T2b | Parent log cho **child_id không tồn tại** | `not_authorized` — **cùng một chuỗi** ⇒ 0 enumeration |
| T3 | `event_type` lạ (`admin_delete_everything`) | `invalid_event_type` |
| T4 | Giả mạo `actor_id` | **bất khả thi** — hàm không có tham số đó |
| T5a | `memory_type` = `<script>alert(1)</script>` | `invalid_memory_type` |
| T5b | `route` = `/parent/journal; DROP TABLE x` | `invalid_route` |
| T5c | `reason_code` = chuỗi lỗi thô **chứa mật khẩu** | ✅ ghi, nhưng **ép về `unknown`** — chuỗi thô **KHÔNG được lưu** |
| T6 | `authenticated` INSERT thẳng `product_events` | **42501 denied** |
| T7 | Parent / Teacher SELECT raw | **0 row** (RLS) |
| T8 | Admin SELECT | ✅ |
| T9 | Teacher gọi `log_parent_event` | `not_authorized` |

T5c là bài học đắt nhất: **chuỗi lỗi thô là nơi dữ liệu nhạy cảm rò rỉ nhiều nhất.** Enum-coerce, không log raw.

---

## 7. V102-B — Frontend (2 commit, 7 file)

| Commit | SHA | Nội dung |
|---|---|---|
| 1 | `626ced0` | `src/lib/parentTelemetry.ts` (session id per-tab, **không fingerprint**, fire-and-forget) + instrument: Home view · CTA create-start · save-failure (4 reason) · upload-start/failure · journey-item-view (debounce 800ms) · `setTelemetryChild` trong ParentChildProvider |
| 2 | `1b6cde7` | `parent_create_type_selected` trong Composer + **`/admin/pilot-funnel`** |

Typecheck PASS cả 2 · `get_diff` scope verify: **0 file rò rỉ** · deploy production.

**Admin `/admin/pilot-funnel`:** A Population · B Funnel F1 (+ time-to-first-save) · C Thất bại (+ phân bố `reason_code`) · D Funnel F2 (return session · second entry · median gap) · E 50 event gần nhất + link sang V100 Audit Intelligence.
**Mỗi chỉ số có chip provenance bắt buộc** — `product_events` / `audit_logs` / `suy ra`. Chỗ chưa đo được ghi **"Chưa có dữ liệu"**, không phải `0`.
**Banner sự thật** khi real pilot parents = 0: *"Mọi số liệu bên dưới chỉ đến từ tài khoản nội bộ/demo và KHÔNG được dùng để kết luận về hành vi người dùng thật."*

**Data-only:** `app_settings.pilot_exclude_email_domains = ["demo.demenart.com","demenart.com"]` — loại mặc định, có toggle bật lại cho QA, **không xoá lịch sử**.

---

## 8. Human QA production (Jean, 12/07 15:25–15:30) — PASS sau 2 fix

Jean chạy thật end-to-end trên demenart.com bằng PH Hùng. **9 event, đúng thứ tự, 0 storm, 0 nội dung bị log:**

| Giờ HCM | Event | Chi tiết |
|---|---|---|
| 15:25:48 | `parent_home_view` | ×1 — **không storm** |
| 15:25:52 | `parent_create_start` | ×1 — **không lặp** |
| 15:25:57–15:26:06 | `parent_create_type_selected` | ×4 — `artwork → note → audio → photo_moment`. **KHÔNG phải duplicate**: 4 lần bấm thật vào 4 tile khác nhau. Đây là hành vi lưỡng lự có thật của người dùng — chính xác là thứ funnel sinh ra để thấy. |
| 15:26:39 | `parent_media_upload_start` | `media_count=1` |
| — | *save success* | `audit_logs.create_parent_memory` (nguồn chuẩn, **không nhân đôi**) |
| — | *upload success* | `audit_logs.media_upload` (**không nhân đôi**) |
| 15:26:56 · 15:27:46 | `parent_journey_item_view` | ×2, cách nhau 50s = 2 lần xem thật, không phải double-fire |

Privacy: 0 caption · 0 tên tệp · 0 URL · 0 free-text. `memory_type` chỉ là enum.

### ⚠️ QA bắt được 2 lỗi mà code review không thấy

**① P0 — Funnel đếm giáo viên thành phụ huynh (D258).**
Trang báo **"5 phụ huynh pilot quan sát được"**. Không thể đúng — pilot có 0 phụ huynh thật. Nguyên nhân: bảng tra `profiles` chỉ nạp role phụ huynh, nhưng `audit_logs.media_upload` có actor là **GV Mỹ Linh (55 uploads), GV Ngọc Hân, Cô Thúy Ngân, Hiệu trưởng Nguyệt Thi, Quản trị viên Test**. Không tra được ⇒ `isInternal()` trả `false` ⇒ **được giữ lại và đếm là phụ huynh pilot**. Hậu quả đúng bằng thứ D257 sinh ra để chặn: **banner sự thật bị tắt oan**, và "Tải tệp thành công" hiện **69** trong khi phụ huynh chỉ upload **6**.

**② Deep-link `?focus=journey:<id>` render nhầm ở lần vẽ đầu.**
Jean phát hiện: lưu kỷ vật mới xong, Hành trình hiện **kỷ vật cũ** trước rồi mới nhảy về đúng id. `useState` initializer chọn `items.length - 1` rồi mới để `useEffect` sửa. Nợ V101, không phải lỗi telemetry.

### Fix `1895dbc` (2 file, typecheck PASS, deploy)
- `admin.pilot-funnel.tsx`: lọc **theo vai trò TRƯỚC**, theo demo SAU. Actor không tra được ⇒ **LOẠI** (fail-closed).
- `ParentJourneyViewer.tsx`: initializer ưu tiên `focusItemId`.

### Verify sau fix (tính thẳng từ DB)
| | Trước | Sau |
|---|---|---|
| Phụ huynh pilot (mặc định) | 5 ❌ | **0** ✅ → banner hiện đúng |
| Nội bộ/demo đã loại | 2 | 2 |
| Bật toggle → quan sát được | 7 ❌ | **2** ✅ (PH Hùng + PH demo Jenny) |
| Tải tệp thành công | 69 ❌ | **6** ✅ |

## 9. Nợ pilot còn lại
- 🔴 **Chưa có phụ huynh thật** — đây là việc *sản phẩm*, không phải việc *kỹ thuật*. Instrumentation đã sẵn sàng và đang chờ họ.
- 🟡 Friction Removal Loop — **hoãn có chủ đích (D257)**, mở lại khi có bằng chứng người dùng thật
- 🟡 Notification cho parent memory (nợ từ V93) · copy bên trong `/parent/discovery` · Hồ sơ con read-only · lọc theo loại ở Hành trình khi timeline ≥25–30 item
- Nợ V95–V101 giữ nguyên: GIN metadata · burst grouping ở scale lớn · `actor_source` ngoài config_change · Bunny health probe · V96D readiness UI · Badge Provenance · Spine ref_id backfill · `child_skills` refactor · repo re-sync

---

## 10. Trạng thái
# V102 — PILOT OBSERVABILITY: **CLOSED** · **READY TO START REAL PILOT**
Human QA PASS · 2 fix đã deploy · Chưa mở V103.

---

## 11. Bài học phiên này
1. **Một cánh cửa đóng có chủ đích trông y hệt một cánh cửa bị quên.** `write_audit_log` không có grant `authenticated` — nhìn qua tưởng thiếu sót, thực ra là D72 đang bảo vệ tính bất khả xâm phạm của audit trail. Cách đúng không phải mở nó ra, mà là **xây cửa mới cho mục đích mới**.
2. **Đo trước khi có người để đo — đúng lúc. Kết luận trước khi có người để kết luận — sai.** Hai câu này nghe mâu thuẫn nhưng cùng đúng, và ranh giới giữa chúng chính là D257.
3. **Khối VERIFY không phải thủ tục.** `REVOKE INSERT, UPDATE, DELETE` trông đầy đủ; Supabase vẫn để lại `TRUNCATE`. Guard D92 bắt được và tự rollback. Ba dòng SQL đã chặn một lỗ quyền lên production.
4. **Chuỗi lỗi thô là chỗ rò rỉ dữ liệu nhiều nhất.** Không ai cố tình log mật khẩu — người ta chỉ log `error.message`. Vì thế `reason_code` phải là enum, và giá trị lạ phải bị **ép về `unknown`**, không phải lưu lại "để debug sau".
5. **Số 0 trung thực đắt hơn một dashboard đẹp.** Một biểu đồ funnel dựng từ dữ liệu của chính mình trông rất giống sản phẩm đang có người dùng — và đó là cách nhanh nhất để tự lừa mình.
6. **Một bộ lọc thiếu vế không im lặng — nó bịa ra dữ liệu.** Trang funnel tra `profiles` chỉ có phụ huynh, gặp actor lạ thì cho qua. "Cho qua" nghe vô hại, nhưng ở tầng analytics nó **tạo ra 5 phụ huynh không tồn tại** và tắt luôn cái banner được dựng riêng để chống chuyện đó. Ở tầng đo lường, mặc định phải là **LOẠI**, không phải **GIỮ**.
7. **Sprint chống tự-lừa-mình suýt tự lừa mình.** V102 tồn tại để ngăn chúng ta nhìn số của chính mình rồi tin là sự thật. Và chính nó, ở lần chạy đầu tiên, đã hiển thị "5 phụ huynh pilot". Con mắt người thật — không phải typecheck, không phải test T1–T9, không phải scope guard — là thứ bắt được.
