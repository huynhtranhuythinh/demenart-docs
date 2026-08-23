# 📦 DMA_HANDOFF_v101.md — V101 PARENT FIRST-VALUE / PILOT READINESS (12/07/2026)

## 1. Canonical endpoint (đọc cùng RULES + SYSTEM_MAP)
RULES **D254** · SYSTEM_MAP **v0.94** · Handoff **v101**
Live inventory: **73 tables · 135 SECURITY DEFINER · 159 RLS policies · 1 cron** — **drift = 0** (V101 frontend-only).

**⭐ BASELINE MỚI (An — Nguyễn Hoàng An):**
- Parent summary: **6 Tác phẩm · 2 Âm thanh · 6 Khoảnh khắc · 4 Ba mẹ lưu lại**
- Evidence: **23 events · 17 independent groups** · **DC9 / OBS8 / PART6**
- Readiness: **policy v2 · emerging · contemporaneous** · general current_3m failed = `[too_short_duration, insufficient_longitudinal_spread]`
- Discovery capsules: **0** · `admin_config_registry` **40 keys**

> **Vì sao evidence 22/16 → 23/17.** Trong human QA production, Jean tạo thật một bản ghi qua flow người dùng: **"Bức tranh mùa hè 2"** (`artwork` · `visual_art` · có media · 12/07 13:56 HCM · PH Hùng). Nó là một `direct_creation` hợp lệ ⇒ DC8→DC9. **CTO chốt GIỮ** (không archive, không delete): đây là **bằng chứng end-to-end** rằng loop Parent First-Value chạy thật. Canonical chạy theo live truth, không ép live truth chạy theo baseline cũ.

**Bé Khang (truth-state chuẩn để test near-empty):** 0 creation · 0 parent memory · **1 moment approved nhưng 0 media row** (KHÔNG phải consent chặn — 2 consent đang bật) · 2 buổi học CTAN.

---

## 2. V101 làm gì
Ngừng phình chức năng. Đưa một phụ huynh mới từ *"tôi chưa hiểu app này để làm gì"* đến *"tôi vừa lưu được một điều đáng nhớ về con, xem lại được, và hiểu vì sao nên quay lại."*

Core loop đã sống: **Trang chủ → Ghi lại một điều về con → Lưu → Xem trong Hành trình → quay lại.**

---

## 3. V101-A — Audit (không code) · 5 P0 tìm được

| # | P0 | Bản chất |
|---|---|---|
| 1 | Kỷ vật ba mẹ **không được đếm** → Home vẫn báo empty | luật đếm chỉ nhìn item có media (V69) ⇒ PH lưu 5 kỷ vật mà app nói "chưa có gì" |
| 2 | Home **không có CTA tạo** nào | mục tiêu pilot là PH tự nhập, mà màn hình đầu không mời tạo |
| 3 | **Mobile = 0 navigation** | mọi nav link `hidden sm:inline-flex` |
| 4 | Home là **route mồ côi** | logo trỏ `/parent/journal`, không link nào về `/parent` |
| 5 | `buildPreview` gọi kỷ vật là **"Buổi học"** | fallback gắn nhãn sai nguồn (họ hàng với D246) |

**Phát hiện chặn brief:** D248 gốc muốn "Không gian của con" làm primary destination — audit live cho thấy `/parent/kid` là trang **PIN / khung giờ / ghép thiết bị**, đổi nhãn = hứa sai. CTO chấp nhận sửa target IA.

---

## 4. V101-B + V101-B.1 — 6 commit (frontend-only)

| Commit | SHA | Nội dung |
|---|---|---|
| 1 | `442c8f6` | **Truth fix:** `parentSaved` + `hasAnyJourneyData` (visibleTotal BẤT BIẾN) · sửa nhãn preview theo `entry_type` thật · ô thứ 4 "Ba mẹ lưu lại" |
| 2 | `621a0d6` | Nav 3 primary + **bottom nav mobile** + `/parent/settings` + `ParentChildProvider` (shared child selection, persist theo profile) |
| 3 | `a907e95` | Home first-value: 1 primary CTA + composer mở từ Home + post-save deep-link `?focus=journey:<id>` |
| 4 | `86ad85c` | Create flow: copy đời thường · 4 loại chính + "Lựa chọn khác" · taxonomy dưới "＋ Thêm chi tiết" · **auto-upload** · guard đóng khi còn tệp · "Ghi thêm một điều" |
| 5 | `5c1589f` | Empty states + thống nhất "Hành trình" + ẩn toggle 2 chế độ (code cả 2 mode còn nguyên) |
| 6 | `b45a773` | **V101-B.1:** Khang near-empty truth-state · gỡ CTA trùng (Home + Hành trình) · favicon 404 |

Typecheck PASS cả 6 · `get_diff` scope verify từng commit, 0 file rò rỉ · deploy production **demenart.lovable.app / demenart.com**.

---

## 5. Parent IA sau V101
**Primary:** Trang chủ `/parent` · Hành trình `/parent/journal` · Cài đặt `/parent/settings`
**Secondary/contextual:** Nhìn lại `/parent/discovery` · Quyền riêng tư & chia sẻ `/parent/consent` · Cổng của bé — PIN & thiết bị `/parent/kid` · Hỗ trợ `/portal/support`
**6 route đều sống** (deep-link giữ nguyên, không redirect cưỡng ép). Logo → `/parent`.

---

## 6. Human QA production (Jean) — đã chứng minh
- Home An: **6/2/6 + Ba mẹ lưu lại** hiển thị đúng
- Parent memory **không còn bị gọi là "Buổi học"**
- Shared child selection: chọn Khang → sang Hành trình → quay Home → **reload vẫn Khang** ✅
- Bottom nav mobile PASS · Consent route còn hoạt động · `/parent/kid` giữ đúng semantics PIN/thiết bị
- **Tạo thật 1 record qua production flow** → vào Hành trình → vào Evidence Engine đúng (DC9)
- V101-B.1 sửa 2 điểm QA bắt được: Khang bị gọi sai là "chưa có gì" · CTA tạo bị lặp

---

## 7. Registry sync (D238)
- `admin_modules`: **+`parent-settings`** (live, `/parent/settings`, icon Settings) · `journey-viewer` title → **"Hành trình (Parent)"** · usage_note V101 cho `parent-memory` (D253) và `discovery-capsule` (D251)
- `route_registry`: **+`/parent/settings`** (live, nav_visible=true) · `nav_visible=false` cho `/parent/consent`, `/parent/discovery`, `/parent/kid` (vẫn live + deep-link, chỉ rời primary nav)
- Drift registry ↔ live: **0**

---

## 8. ⚠️ Nợ canonical phát hiện trong phiên (QUAN TRỌNG)
`DMA_RULES.md` và `DMA_SYSTEM_MAP.md` trong **Project Knowledge đang stale ở V99.8 / v0.92** — thiếu hoàn toàn D245–D247 và §V100, dù HANDOFF v100 khai báo D247/v0.93. Bản thay thế phiên này đã **khôi phục D245–D247 + §V100 từ HANDOFF v100** (nguồn canonical còn lại) rồi mới ghi tiếp V101.
**Jean phải re-upload cả 3 file** (RULES · SYSTEM_MAP · HANDOFF v101) vào Knowledge, nếu không phiên sau lại boot từ bản stale (D112 tái phạm lần thứ ba).

---

## 9. Nợ pilot còn lại
- 🟡 Nội dung trang `/parent/discovery` vẫn là UI V98 — mới đổi tên ở lối vào ("Nhìn lại"), chưa viết lại copy bên trong
- 🟡 Chế độ xem "nhật ký" cũ còn trong code nhưng không có lối vào (chủ ý pilot)
- 🟡 Hồ sơ con read-only (cần capability backend nếu muốn PH sửa)
- 🟡 Notification cho parent memory (nợ từ V93) · lọc theo loại ở Hành trình khi timeline ≥25–30 item
- Nợ V95–V100 giữ nguyên: GIN metadata · burst grouping ở scale lớn · `actor_source` ngoài config_change · Bunny health probe · V96D readiness UI · Badge Provenance · Spine ref_id backfill · `child_skills` refactor · repo re-sync

---

## 10. Trạng thái
# V101 — PARENT FIRST-VALUE: **CLOSED** · **READY FOR PILOT**
Chưa mở V102.

---

## 11. Bài học phiên này
1. **Luật đếm là một quyết định sản phẩm, không phải chi tiết kỹ thuật.** `visibleTotal` chỉ đếm item có media — hoàn toàn hợp lý cho Kid Portal, nhưng khi Parent tự nhập dữ liệu thì chính luật đó khiến app nói với phụ huynh rằng công sức của họ **không tồn tại**. Một hằng số đúng ở tầng này có thể là lời nói dối ở tầng kia.
2. **"Không có gì xem lại được" ≠ "không có gì xảy ra".** Bé Khang có 2 buổi học và 1 khoảnh khắc — chỉ là khoảnh khắc đó chưa có ảnh. Nếu không audit tới tận `media_assets`, ta đã "sửa" một câu copy sai bằng một câu copy sai khác.
3. **Human QA thấy thứ code review không thấy.** Hai nút cùng chức năng cách nhau 200px trông rất bình thường trong diff, và rất chướng trên màn hình điện thoại thật.
4. **Dữ liệu QA thật là tài sản, không phải rác.** Giữ "Bức tranh mùa hè 2" đắt hơn một dòng baseline đẹp: nó là bằng chứng sống rằng vòng lặp giá trị đầu tiên đã chạy.
