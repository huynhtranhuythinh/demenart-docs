# 📦 DMA_HANDOFF_v71.md — PARENT JOURNAL LIGHTBOX (Consent-Safe Detail)

> **Phiên:** V71 · **Ngày chốt:** 2026-07-08 20:56 GMT+7
> **Loại:** Frontend-only. Đưa detail lightbox từ `/kid` (V70) sang `/parent/journal` cho Tác phẩm + Khoảnh khắc, TUYỆT ĐỐI không bypass consent. 0 DB/RPC/Edge/Auth/RLS/migration · 0 AI · 0 re-sign · không Radar/Dashboard/upload/notification.

---

## 1. BỐI CẢNH — V71 SAU V70

V70 đã cho `/kid` timeline bấm item → lightbox (ảnh lớn + gợi ý trò chuyện), nhưng cố ý HOÃN Parent Journal Lightbox vì `/parent/journal` ký lẻ từng thẻ + consent gate 5 trạng thái = bề mặt nhạy cảm consent (D202-note backlog). V71 làm bước riêng đó: phụ huynh bấm tác phẩm/khoảnh khắc **đã được phép xem** để mở ảnh lớn, đọc context nhẹ, gợi ý trò chuyện — nhưng chỉ mở khi media đang ở trạng thái `ok`, dùng lại URL đã ký trên card, **KHÔNG re-sign, KHÔNG bypass consent**.

Đây là **detail experience an toàn cho Parent Journal**, KHÔNG phải data sprint. Không AI, không Radar, không RPC/Edge mới, không đổi consent engine.

---

## 2. C1 — AUDIT PARENT JOURNAL MEDIA STATE (đọc code sống, D1)

Audit `parent.journal.tsx` + `dialog.tsx` thật qua `read_file` Lovable trước khi code:

- **File cần đụng:** duy nhất `src/routes/_authenticated/parent.journal.tsx`. 0 file khác — KHÔNG `kidJourneyModel.ts`, KHÔNG `parent.index.tsx`, KHÔNG `kid.tsx`.
- **Dialog:** file CHƯA import (đúng handoff). Component có sẵn `@/components/ui/dialog` — `DialogContent` tự lo ✕ + Escape + click overlay đóng (AC #5 tự thoả). Cần Radix `DialogTitle` cho a11y → nhúng trong content.
- **Signed URL nằm ở đâu (mấu chốt consent):**
  - `CreationCard`: URL ở `state.url` **ngay tại card** (3 trạng thái loading/ok/denied). → lightbox local, 0 threading.
  - `MomentCard`: URL **KHÔNG ở card** — nằm một tầng sâu trong `MomentImage` (state riêng 5 trạng thái loading/ok/denied/hidden/empty). → phải đưa URL lên card qua callback nhỏ `onReady(url)` bắn khi `status==="ok"`.
- **Trạng thái consent:** MomentImage = loading/ok/denied(reason)/hidden(moment_not_approved→card null)/empty(media_id null). CreationCard = loading/ok/denied (media null → denied unknown; KHÔNG có nhánh empty/hidden).
- **Recording:** `creation` có 2 kind — `drawing` (ảnh) + `recording` (audio player inline). Lightbox CHỈ cho drawing.

**Jean chốt sau audit:** green-light plan, auto-app; kiến trúc = state local từng card + `ParentJournalLightbox` local cùng file, không lift lên `JournalPage`, không tách file mới.

---

## 3. ĐÃ SHIP (V71 · 3 commit · agent auto-app · deploy 1 lần cuối)

| Commit | SHA | Nội dung (chỉ `src/routes/_authenticated/parent.journal.tsx`) |
|---|---|---|
| **C1** | `f705173` | Import `Dialog, DialogContent, DialogTitle` + component **`ParentJournalLightbox`** (export, pure presentational): nhận `{open,onOpenChange,type,signedUrl,title,date,caption,prompt}` → render `<Dialog>` ảnh `object-contain max-h-[60vh]` nền cream `#FBF7EE` + nhãn (`DialogTitle`) + ngày + caption + khối 💬 Gợi ý trò chuyện. **KHÔNG network · KHÔNG biết media_id · KHÔNG consent logic.** Chưa wire → chưa đổi behavior. |
| **C2** | `66710b6` | `CreationCard`: +state `lightboxOpen`; ảnh drawing bọc `<button onClick>` (group-hover scale 1.03, title "Bấm để xem lớn") CHỈ khi `status==="ok" && kind==="drawing"`; render `<ParentJournalLightbox type="creation">` (nhãn "Tác phẩm của con", prompt "Con muốn kể… màu nào nhất?"). Recording GIỮ player inline, KHÔNG clickable. |
| **C3** | `4066dfb` | `MomentImage`: +prop `onReady?: (url)=>void`, bắn `onReady(signed_url)` ở nhánh ok, +dep effect. `MomentCard`: +state `signedUrl`/`lightboxOpen` + `handleReady` (useCallback), **overlay button `absolute inset-0`** chỉ hiện khi `canOpen=!!signedUrl` → mở `<ParentJournalLightbox type="moment">` (nhãn "Khoảnh khắc ở lớp", prompt "Lúc đó con đang làm gì?…"). |

**Quy trình:** Jean "auto-app" → agent mode. Mỗi commit `send_message`→`get_diff` (sạch, đúng 1 file, KHÔNG đụng `routeTree.gen.ts`)→typecheck pass. Deploy 1 lần cuối lên production (`demenart.lovable.app` / `demenart.com`).

---

## 4. QUYẾT ĐỊNH KỸ THUẬT MẤU CHỐT — OVERLAY, KHÔNG BỌC (chống re-sign + giữ consent hint)

Audit ban đầu đề xuất "bọc `MomentImage` trong `<button>`". Khi dựng phát hiện 2 lỗi → chuyển sang **overlay button trong suốt** (bản an toàn hơn của đúng audit, KHÔNG mở rộng scope):

1. **Chống re-sign:** bọc `MomentImage` trong button đổi TYPE của node ở vị trí đó (`MomentImage`→`button`) → React unmount/remount `MomentImage` → effect ký chạy lại → **gọi lại `get_signed_media_url`** (re-sign, vi phạm luật V71). Overlay giữ `MomentImage` cùng vị trí (con của `div.relative` ổn định) → **0 remount · 0 re-sign**.
2. **Giữ nút "Vì sao?":** ở trạng thái `denied` (consent_missing) `MomentImage` render `ConsentWaitingHint` = một `<button>` Popover. Nếu bọc trong outer button (disabled khi chưa ok) → nested-button + hint bị chặn click → hỏng consent UX. Overlay CHỈ render khi `canOpen` (ok) → denied KHÔNG có overlay → hint bấm bình thường.

→ `CreationCard` (drawing là `<img>` trực tiếp, denied là text-div, không nested-button) dùng button-wrap được. `MomentCard` bắt buộc overlay.

---

## 5. ITEM TYPE — MỞ ĐƯỢC / KHÔNG (trung thực)

**Mở lightbox (CHỈ khi `status==="ok"` + có signed URL sẵn):**
- 🎨 **Tác phẩm** (`kind="drawing"`, ảnh) — nhãn "Tác phẩm của con", `object-contain` không cắt.
- 📸 **Khoảnh khắc** (moment, ảnh) — nhãn "Khoảnh khắc ở lớp", không crop mạnh.

**KHÔNG mở (giữ nguyên UI hiện tại, KHÔNG lỗi):**
- `loading` (đang ký) · `denied` (consent_missing/school_blocks/not_authorized…) · `hidden` (moment_not_approved → card null) · `empty` (media_id null).
- 🎤 **Recording** (audio) — giữ player inline (né nested-button + audio không hợp lightbox).
- Nút "Vì sao?" ở ảnh denied **vẫn bấm được** (overlay không phủ trạng thái denied).

**Rào trung thực giữ nguyên:** drawing (vẽ+tô màu) → "Tác phẩm/Tranh"; moment → "Khoảnh khắc ở lớp" (DMA-KID-MEDIA-001). KHÔNG bịa taxonomy.

---

## 6. NGHIỆM THU (PASS — PH Nguyễn Văn Hùng, con An, 6 ảnh Jean)

1. `/parent` summary An **6/2/3 GIỮ NGUYÊN** ✅ (AC #12)
2. **Lightbox Tác phẩm** (tranh con sâu, 8/7): `object-contain` không cắt · nhãn "Tác phẩm của con" · ngày · 💬 "Con muốn kể… màu nào nhất?" ✅ (AC #2, #3, #10)
3. **Recording** giữ player audio inline, phát được 0:02/0:10, KHÔNG lightbox ✅
4. **Lightbox Khoảnh khắc** (ảnh nhóm workshop, 28/6): không crop mạnh · nhãn "Khoảnh khắc ở lớp" · ngày · caption "Hình ảnh thử nghiệm" · 💬 "Lúc đó con đang làm gì?…" ✅ (AC #4, #10)
5. ✕ đóng rõ cả 2 lightbox ✅ (AC #5)
6. 0 AI · 0 DB/RPC/Edge · timeline + Bé tự làm + Khoảnh khắc nguyên vẹn ✅ (AC #6, #11, #13–17)

**AC 1–4, 6–14, 17–18 PASS.** **AC #5/#8/#18 (denied/hidden/empty không mở) chưa chứng minh bằng mắt** — data An hiện KHÔNG có moment denied/empty trên màn; code chặn theo cấu trúc (overlay chỉ khi `signedUrl` có = chỉ khi `ok`). → backlog nghiệm thu (như R1).

**Verify:** `ph.hung.kidshouse@demo.demenart.com` / `Test@123` → An → `/parent/journal` → bấm tranh "Bé tự làm" + ảnh "Khoảnh khắc".

---

## 7. FILE ĐỤNG (chỉ 1)

- `src/routes/_authenticated/parent.journal.tsx` — import Dialog + `ParentJournalLightbox` + CreationCard clickable + MomentImage `onReady` + MomentCard overlay.
- **0** file khác. 0 DB/RPC/Edge/Auth/RLS/migration. 0 npm.

---

## 8. KHÔNG LÀM TRONG V71 (guard tôn trọng) + BACKLOG

**Không làm:** sửa consent engine/`get_signed_media_url` · re-sign trong lightbox · media_id thô · đụng `/kid`/`kidJourneyModel.ts`/summary V69 · AI thật · Radar · Parent Dashboard/multi-child · upload/notification/approval · rename `kidJourneyModel.ts` · refactor lớn `parent.journal.tsx` · data giả.

**BACKLOG (kế thừa + mới):**
- 🟠 **Nghiệm thu nhánh denied/hidden/empty Parent Lightbox** — chờ data An (hoặc bé khác) có moment consent-blocked để chứng minh "không mở" bằng mắt (gộp R1 V69: moment thiếu media active).
- 🟠 **Album "Tác phẩm" grid `/kid`** — drawings ngoài timeline chưa clickable.
- 🟠 **Recording detail** `/kid` (nested-button với `KidAudioCard`).
- 🟠 **Session/Badge detail** text-only nếu thấy giá trị.
- 🟠 Kế thừa V69/V70: R4 badge trùng HIỂN THỊ `/parent/journal` · Phương án B RPC canonical `get_child_journey_service` · consent-aware count landing · rename model.
- 🟠 Kế thừa cũ: Parent Portal đầy đủ (multi-child dashboard) · Art Growth Radar · AI Growth Review THẬT (policy/consent + copy Jean duyệt) · 🔴 Coloring JSON schema · 🔴 Moment media origin taxonomy · Backlog GitHub backup commits (migrations 093–104): Jean thủ công · lưu repo `parent.journal.tsx` V71.

---

## 9. BOOT PROTOCOL PHIÊN SAU

1. Đọc `DMA_HANDOFF_v71.md` (file này).
2. Đọc `DMA_00_START_HERE.md` + `DMA_RULES.md` (endpoint **D203+**).
3. Đọc `DMA_SYSTEM_MAP.md` (**v0.64+**).
4. Audit code/DB thật — KHÔNG tin disk snapshot (`read_file` Lovable + `pg_get_functiondef` Supabase).
5. **Verify `get_diff` mỗi lượt** (agent mode) / `read_file` sau mọi paste tay (D8).

**Workflow mặc định:** Claude đưa code byte-exact để Jean tự paste (tiết kiệm credit). Chuyển agent mode (`send_message`→`get_diff`→`deploy`) khi Jean nói "tự áp"/"auto-app". Sau sửa UI + BUILD PASS → tự publish; chỉ dừng hỏi khi (1) build fail, (2) đụng schema/data Supabase, (3) có thể phá buổi đang chạy thật.

---

## 10. TÀI KHOẢN DEMO (password `Test@123` · `@demo.demenart.com`)

- **PH An/Khang — KHM Nguyễn Văn Hùng:** `ph.hung.kidshouse` *(nghiệm thu Parent Journal Lightbox — con An)*
- Master KHM Nguyệt Thi: `hieutruong.kidshouse`
- GV KHM Mỹ Linh: `gv.linh.kidshouse`
- Master MNDM Phương Dung: `hieutruong.demen`
- GV MNDM Ngọc Hân: `gv.han.demen`
- PH MNDM Văn Thành: `ph.thanh.demen`

*(Ghi email đầy đủ + mật khẩu khi nhờ Jean test — không để Jean tự tra.)*

---

*V71 = Parent Journal Lightbox (Consent-Safe Detail) · frontend-only · 0 DB/RPC/Edge/Auth/RLS/migration · 0 AI · 0 re-sign · 1 file (`parent.journal.tsx`). Import Dialog + local `ParentJournalLightbox` + CreationCard drawing clickable + MomentImage `onReady` + MomentCard overlay clickable. Mở CHỈ khi `status==="ok"`; denied/hidden/empty/loading + recording KHÔNG mở; nút "Vì sao?" giữ nguyên. Commit `f705173`(C1)·`66710b6`(C2)·`4066dfb`(C3), agent auto-app, get_diff sạch, deploy 1 lần. Nghiệm thu PASS (PH Hùng, An; lightbox Tác phẩm 8/7 + Khoảnh khắc 28/6, 6 ảnh). Summary 6/2/3 + `/kid` lightbox V70 giữ nguyên. SYSTEM_MAP v0.63→v0.64. Đóng sổ 2026-07-08 20:56 GMT+7.*
