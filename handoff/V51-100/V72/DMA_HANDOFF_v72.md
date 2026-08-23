# 📦 DMA_HANDOFF_v72.md — PARENT JOURNAL CONSENT-BLOCKED QA + UX GUARD

> **Phiên:** V72 · **Ngày chốt:** 2026-07-09 00:42 GMT+7
> **Loại:** **Audit/QA-only.** Khóa nợ nghiệm thu V71 — chứng minh Parent Journal Lightbox **tuyệt đối không mở** khi media không ở trạng thái `ok`. **0 code · 0 DB thay đổi vĩnh viễn · 0 migration/RPC/Edge/Auth/RLS/AI · KHÔNG C3.**
> **Kết quả:** ✅ **PASS.**

---

## 1. BỐI CẢNH — V72 SAU V71

V71 ship Parent Journal Lightbox (consent-safe detail): PH bấm tác phẩm/khoảnh khắc **đã được phép xem** → mở ảnh lớn + gợi ý trò chuyện, chỉ khi media `ok`, không re-sign, không bypass consent. Nghiệm thu V71 PASS cho nhánh `ok` (con An), nhưng nhánh **consent-blocked / denied / hidden / empty** CHƯA chứng minh bằng mắt vì data An khi đó không có moment ở trạng thái đó (nợ backlog, gộp R1).

V72 = **QA/hardening sprint nhỏ**, khóa đúng nợ đó: kiểm và chứng minh rằng lightbox **không thể mở** khi media không `ok`. Không phải sprint tính năng.

---

## 2. C1 — AUDIT CODE GUARD (đọc code sống, D1)

Đọc THẬT (không tin snapshot): `parent.journal.tsx` (Lovable `read_file`) + Edge `get_signed_media_url` (v20) + RPC `media_consent_check` + `get_child_journal` (Supabase read-only). Guard V71 đúng **bằng cấu trúc**.

**Ma trận state → behavior (MomentCard — bề mặt consent, ký lẻ):**

| Trạng thái `MomentImage` | `onReady` bắn? | `canOpen` | overlay render? | mở lightbox? | "Vì sao?" |
|---|---|---|---|---|---|
| loading | không | false | không | không | (skeleton) |
| **ok** | **có** | **true** | **có** | **CÓ** | – |
| denied (consent_missing) | không | false | không | không | **CÒN SỐNG** |
| denied (khác) | không | false | không | không | (chỉ message) |
| hidden (not_approved) | – | – | **card = null** | không | – |
| empty (media_id null) | không | false | không | không | – |

**CreationCard** (ba mẹ được cấp không cần consent): mở CHỈ `status==="ok" && kind==="drawing"`; recording → audio inline (không lightbox); denied → text-div (không clickable).

**Kết luận C1:**
- Overlay/nút mở chỉ render ở `ok` — Moment gate `canOpen=!!signedUrl` (set CHỈ qua `onReady`, bắn CHỈ ở nhánh `ok`); Creation gate `status==="ok" && kind==="drawing"`.
- Overlay `absolute inset-0` **vắng DOM** khi không ok (không phải "disabled") → **không click xuyên** + **không che** `ConsentWaitingHint` (nút "Vì sao?").
- **0 network trong lightbox** (`ParentJournalLightbox` thuần present, nhận `signedUrl`) · **0 media_id thô** (gate `!!signedUrl`) · **0 re-sign**.
- → Guard đúng bằng cấu trúc → **KHÔNG C3** (thêm guard thừa trái kỷ luật "không code nếu không cần").

---

## 3. GATE CONSENT XEM ẢNH — TRUY NGUỒN THẬT (mấu chốt V72)

Edge `get_signed_media_url` v20, nhánh `linked_moment_id` → RPC `media_consent_check(p_action='view')`:

- **`required_consent_type` chọn ĐỘNG theo `tagged_count`:** `≥2` → **`group_moment_in_class`** (ảnh nhóm) · `=1` → **`display_in_app`** (ảnh 1 bé) · `0` → allowed.
- **MIN-consent:** gom MỌI trẻ tag thiếu consent loại đó → chỉ 1 bé thiếu là cả ảnh `consent_missing` + trả `blocking_children`.
- **Creation** nhánh `source='kid'` + `linked_child_id` → ba mẹ liên kết xem KHÔNG cần consent (get_signed_media_url v20).

**⭐ `get_child_journal` trả `media_id` KHÔNG lọc consent** (chỉ `state='approved'` + active media asset). Consent chỉ chặn lúc **ký** ở Edge. → `summarizeChildJournal` đếm `hasDisplayableMedia=!!media_id` → **summary 6/2/3 BẤT BIẾN khi tắt consent**; chỉ `/parent/journal` chuyển card sang `consent_missing`. Đây là lý do QA consent-toggle **an toàn cho nghiệm thu chính**.

**→ Bài học vàng V72:** muốn tạo trạng thái blocked cho ảnh **NHÓM** của một bé, tắt **`group_moment_in_class`** của bé đó — **KHÔNG** `display_in_app` (chỉ chặn ảnh 1-bé). Toggle share/download (`download`/`private_share_link`) tách riêng, KHÔNG đụng khi test view.

**Data thật moment của An** (child_id `d1000000-0000-4000-8000-000000000041`, chỉ `approved` lên journal): 29/6 nhóm(2)·28/6 nhóm(3)·26/6 một-bé(1). → tắt `group_moment_in_class` khóa 28/6+29/6; 26/6 (`display_in_app` còn ON) vẫn mở.

---

## 4. C2 — QA NGHIỆM THU BẰNG ẢNH (login thật PH Hùng, con An, 9 ảnh Jean)

| # | Bước | Kết quả |
|---|---|---|
| 1 | Baseline `/parent/journal` | 3 ảnh khoảnh khắc (29/6·28/6·26/6) hiện đủ |
| 2 | Baseline ok-branch | Lightbox 29/6 (ảnh nhóm) mở OK + 💬 gợi ý |
| 3 | Baseline summary `/parent` | **6/2/3** |
| 4 | `/parent/consent` trước tắt | `group_moment_in_class` + `display_in_app` đều ON |
| 5 | Sau tắt | **CHỈ** `group_moment_in_class` OFF · share/download giữ ON · toast "Đã cập nhật" |
| **6** | **Blocked** | 28/6+29/6 (nhóm) → "Đang chờ ba mẹ đồng ý cho xem ảnh này" + **"Vì sao?"** sống · 26/6 (1 bé) vẫn hiện ảnh |
| 7 | ok-branch sống song song | Lightbox 26/6 (1 bé, `display_in_app` còn ON) mở OK khi 2 ảnh nhóm blocked |
| 8 | Summary khi blocked | vẫn **6/2/3** (consent tắt không rớt số) |
| 9 | Sau rollback | 2 ảnh nhóm hiện lại |

---

## 5. ROLLBACK — DB CONFIRM (read-only)

`consents` của An sau nghiệm thu:
- `group_moment_in_class` → **ĐANG BẬT** (granted_at `2026-07-09 00:36` = dấu vết re-grant, đúng cơ chế `turnOn` đổi `granted_at`).
- `display_in_app` → ĐANG BẬT (granted_at 2026-06-26, **không đụng**).
- `download` → ĐANG BẬT (2026-06-27, **không đụng**).
- `private_share_link` → ĐANG BẬT (2026-06-27, **không đụng**).

→ Consent test **đã rollback**, demo về đúng trạng thái nghiệm thu chính. Chỉ `group_moment_in_class` có granted_at mới (dấu vết bật lại); quyền share/download nguyên vẹn.

---

## 6. ACCEPTANCE CRITERIA V72 (16/16)

**PASS bằng ảnh:** #1 (journal chạy không lỗi) · #2 (ok vẫn mở: ảnh #2+#7) · #3 (consent-blocked không mở: ảnh #6) · #7 ("Vì sao?" sống: ảnh #6) · #11 (không ảnh hưởng `/kid`: 0 đụng file kid) · #12 (không đổi 6/2/3: ảnh #3=#8) · #13 (0 migration) · #14 (0 sửa RLS/Auth/PIN/device) · #15 (0 AI) · #16 (rollback: ảnh #9 + DB confirm).

**PASS bằng cấu trúc (C1), chưa có data hiện bằng mắt:** #4 hidden (`get_child_journal` lọc `approved` → nhánh phòng thủ, `MomentCard` return null) · #5 empty (mọi moment approved của An có active media → `canOpen=false`) · #8 không re-sign · #10 không media_id thô (lightbox tiêu thụ lại signed URL, gate `!!signedUrl`).

**Câu hỏi lõi V72:** "Khi PH chưa có quyền / media không khả dụng, Parent Journal Lightbox có tuyệt đối không mở không?" → **CÓ, tuyệt đối không mở.**

---

## 7. FILE ĐỤNG

- **0 file code.** `parent.journal.tsx` KHÔNG sửa (guard V71 giữ nguyên).
- **0 DB thay đổi vĩnh viễn.** Chỉ consent toggle của Jean qua UI `/parent/consent` (tắt để test → bật lại rollback). 0 migration/RPC/Edge/Auth/RLS.
- Audit read-only: Lovable `read_file` (parent.journal.tsx, parent.consent.tsx) · Supabase `get_edge_function` (get_signed_media_url) + `execute_sql` (pg_get_functiondef media_consent_check/get_child_journal + query moment/consent An).

---

## 8. KHÔNG LÀM TRONG V72 (guard tôn trọng) + BACKLOG

**Không làm:** C3 code (guard V71 đúng bằng cấu trúc) · migration/RPC/Edge mới · sửa consent engine/`get_signed_media_url` · re-sign trong lightbox · media_id thô · đụng `/kid` lightbox V70 / summary V69 / `kidJourneyModel.ts` · AI thật · Radar · Parent Dashboard · upload/notification/approval · rename model · refactor `parent.journal.tsx` · hardcode data giả · seed data giả (dùng UI consent thật + rollback).

**BACKLOG (kế thừa + mới):**
- 🟠 **Nghiệm thu nhánh hidden/empty Parent Lightbox** — nhánh phòng thủ, chưa có data thật (moment not_approved / media_id null của An) để chứng minh bằng mắt (gộp R1). Đã chặn bằng cấu trúc.
- 🟠 **Lưu repo/backup thay đổi V71** (`parent.journal.tsx`) nếu chưa làm · Backlog GitHub backup commits (migrations 093–104): Jean thủ công.
- 🟠 Parent Journal polish tiếp (nếu cần) — consent guard đã khóa.
- 🟠 Kế thừa: R4 badge trùng HIỂN THỊ `/parent/journal` · Phương án B RPC canonical `get_child_journey_service` (khi cần superset: Journey Detail/Dashboard/Radar) · rename `kidJourneyModel.ts`→`journeyModel.ts` · consent-aware count landing · album "Tác phẩm" grid `/kid` clickable · recording/session/badge detail.
- 🟠 Parent Portal đầy đủ (multi-child dashboard) · Art Growth Radar · AI Growth Review THẬT (policy/consent + copy Jean duyệt).
- 🔴 Coloring JSON schema (`{type:"coloring",templateId,coloredRegions}` thay `kind:"drawing"` chung) · 🔴 Moment media origin taxonomy.

---

## 9. BOOT PROTOCOL PHIÊN SAU

1. Đọc `DMA_HANDOFF_v72.md` (file này).
2. Đọc `DMA_00_START_HERE.md` + `DMA_RULES.md` (endpoint **D204+**).
3. Đọc `DMA_SYSTEM_MAP.md` (**v0.65+**).
4. Audit code/DB thật — KHÔNG tin disk snapshot (`read_file` Lovable + `pg_get_functiondef`/`get_edge_function` Supabase).
5. **Verify `get_diff` mỗi lượt** (agent mode) / `read_file` sau mọi paste tay (D8).

**Workflow mặc định:** Claude đưa code byte-exact để Jean tự paste (tiết kiệm credit). Chuyển agent mode (`send_message`→`get_diff`→`deploy`) khi Jean nói "tự áp"/"auto-app". Sau sửa UI + BUILD PASS → tự publish; chỉ dừng hỏi khi (1) build fail, (2) đụng schema/data Supabase, (3) có thể phá buổi đang chạy thật.

---

## 10. TÀI KHOẢN DEMO (password `Test@123` · `@demo.demenart.com`)

- **PH An/Khang — KHM Nguyễn Văn Hùng:** `ph.hung.kidshouse` *(nghiệm thu V72 consent-blocked — con An, child_id `d1000000-0000-4000-8000-000000000041`)*
- Master KHM Nguyệt Thi: `hieutruong.kidshouse`
- GV KHM Mỹ Linh: `gv.linh.kidshouse`
- Master MNDM Phương Dung: `hieutruong.demen`
- GV MNDM Ngọc Hân: `gv.han.demen`
- PH MNDM Văn Thành: `ph.thanh.demen`

*(Ghi email đầy đủ + mật khẩu khi nhờ Jean test — không để Jean tự tra.)*

---

*V72 = Parent Journal Consent-Blocked QA + UX Guard · audit/QA-only · 0 code · 0 DB thay đổi vĩnh viễn · 0 migration/RPC/Edge/Auth/RLS/AI · KHÔNG C3. Khóa nợ nghiệm thu V71: chứng minh Parent Journal Lightbox tuyệt đối không mở khi media không `ok`, bằng ảnh thật (PH Hùng con An, 9 ảnh). Tắt `group_moment_in_class` → 2 ảnh nhóm blocked + "Vì sao?" sống; ảnh 1-bé vẫn mở; summary 6/2/3 bất biến; rollback DB confirm. Guard V71 đúng bằng cấu trúc. RULES → D204. SYSTEM_MAP v0.64→v0.65. Đóng sổ 2026-07-09 00:42 GMT+7.*
