# 📦 DMA_HANDOFF_v70.md — JOURNEY DETAIL LIGHTBOX (Kid)

> **Phiên:** V70 · **Ngày chốt:** 2026-07-08 20:28 GMT+7
> **Loại:** Frontend-only. Thêm detail lightbox cho từng item trong Kid Timeline "Hành trình". 0 DB/RPC/Edge/Auth/RLS/migration · 0 AI thật · không Radar/Dashboard · không Parent Journal (backlog).

---

## 1. BỐI CẢNH — V70 SAU V69

V69 đã thống nhất tầng ĐẾM journey (`summarizeChildJournal` dùng chung `/parent` + `/kid`, khớp 6/2/3). V70 làm bước tiếp: sau khi timeline đã đẹp và số đã thống nhất, cho phụ huynh/bé **bấm vào một item để xem chi tiết** — ảnh lớn, thông tin nhẹ, và một câu gợi ý trò chuyện phù hợp. Mục tiêu cảm xúc: "không chỉ nhìn timeline mà mở từng tác phẩm/khoảnh khắc ra để cùng kể chuyện".

Đây là **detail experience nhẹ**, KHÔNG phải data-architecture sprint. Không mở AI thật, không mở Radar, không tạo RPC canonical, không enrich `child_journey`.

---

## 2. C1 — AUDIT CLICKABILITY (đọc code sống, D1)

Audit 3 file thật qua `read_file` Lovable trước khi code:

- **`/kid` timeline "Hành trình" (target chính):** card feed (`single` + `drawingGroup`) là `<div>` **chưa click được**. → chỗ V70 cần thêm.
- **`/kid` album "Khoảnh khắc" (trên timeline):** moment ĐÃ có lightbox sẵn (`onOpenMoment` → `<Dialog>` với reaction). Pattern lightbox + shadcn `Dialog` **đã import sẵn trong `kid.tsx`** → reuse, không dựng mới.
- **`/kid` album "Tác phẩm" (drawings grid):** chưa click được — KHÔNG nằm trong AC (AC nói timeline). → backlog nhỏ.
- **Media timeline đã ký sẵn:** `e.media.url` trong `JourneyEventViewModel` là signed_url **đã ký batch** từ `get_kid_album_service` → detail render thẳng, **0 RPC/Edge/ký lại**.
- **Helper conversation prompt V66?** KHÔNG có — 3 câu "Gợi ý ba mẹ hỏi con" là array static inline trong `kid.tsx`, không reuse được. → tạo helper mới (C4).
- **`/parent/journal`:** `CreationCard`/`MomentCard` ký lẻ từng thẻ qua `get_signed_media_url` + consent gate 5 trạng thái (loading/ok/denied/hidden/empty); file **KHÔNG import `Dialog`**. → rủi ro trung bình, tách sprint riêng (Commit 3 backlog).

**Jean chốt sau audit:** Phương án **A** — làm `/kid` (Commit 1+2) trước, verify PASS, backlog Commit 3 parent.

---

## 3. ĐÃ SHIP (V70 · 2 commit · agent auto-app · deploy 1 lần cuối)

| Commit | SHA | File | Nội dung |
|---|---|---|---|
| **C1** | `501c68e` | `src/lib/kidJourneyModel.ts` | **Append thuần**: `conversationPrompt(event): string` — pure/static theo eventType/artifact (artifact drawing→màu sắc/ý tưởng · artifact recording→bài hát · moment→hoạt động ở lớp · session→buổi học · badge→khích lệ nhẹ · fallback). KHÔNG AI, KHÔNG chấm điểm. 4 hàm cũ (`summarizeChildJournal`/`buildJourneyFeed`/`journeySummary`/`groupDrawingRows`) nguyên vẹn. |
| **C2** | `dcf794c` | `src/routes/kid.tsx` | 5 edit: (1) import `conversationPrompt`; (2) state `openItem: JourneyEventViewModel \| null`; (3) thumbnail trong `drawingGroup` bọc `<button onClick={setOpenItem(ev)}>`; (4) ảnh card `single` bọc `<button onClick={setOpenItem(e)}>` (giữ nguyên max-h/object-fit/bg); (5) `<Dialog>` detail cuối `AlbumView` — nhãn màu (`journeyLabelClass`) + ngày (`formatDateVi`) + ảnh lớn (`object-contain` cream cho tranh / `object-cover` cho moment, `max-h-[60vh]`) + `KidAudioCard` nếu media audio + storyText + khối 💬 Gợi ý trò chuyện (`conversationPrompt`). Reuse `Dialog`/`DialogContent` đã import sẵn. |

**Quy trình:** Jean gọi "auto-app" → agent mode. Mỗi commit: `send_message` → `get_diff` (sạch, đúng 1 file, không đụng `routeTree.gen.ts`) → typecheck pass. Deploy 1 lần cuối lên production `demenart.com`. **Không nuốt `<` (D8)** vì agent dùng heredoc/line-replace, không phải Jean paste khối — nhưng vẫn verify `get_diff` mỗi lượt.

---

## 4. KIẾN TRÚC (không đổi cấu trúc)

- **2 file đụng:** `src/lib/kidJourneyModel.ts` (append 1 hàm) · `src/routes/kid.tsx` (import + 1 state + 2 ảnh clickable + 1 Dialog).
- **KHÔNG đụng:** `parent.journal.tsx` · `parent.index.tsx` · `routeTree.gen.ts` · 4 hàm model cũ · Parent Preview 💛 + 3 chip · Supabase/Edge/RPC/RLS/Auth · npm.
- Detail dùng `openItem.media.url` **đã ký sẵn** — **0 RPC · 0 Edge · 0 ký lại · 0 DB · 0 AI · 0 npm.**
- shadcn `Dialog` tự lo ✕ + Escape + click overlay đóng (AC #5).

---

## 5. ITEM TYPE — CLICK ĐƯỢC / CHƯA (trung thực)

**Click được → mở lightbox:**
- 🎨 **Tranh** (artifact drawing, media image) — card `single` + thumbnail trong `drawingGroup`.
- 📸 **Khoảnh khắc** (moment, media image) — card `single`.

**CHƯA click (cố ý, backlog):**
- 🎤 **Recording** (media audio) — card feed audio giữ `KidAudioCard` inline KHÔNG bọc button (tránh nested-button trong player). Dialog CÓ nhánh render audio phòng hờ, nhưng hiện KHÔNG có đường set audio vào `openItem` từ timeline → recording chưa mở detail. Backlog.
- **Buổi học** (session) / **Huy hiệu** (badge) — không media → non-clickable. Backlog.
- **Album "Tác phẩm" grid** (`/kid`, ngoài timeline) — drawings chưa clickable. Backlog nhỏ.

**Rào trung thực giữ nguyên:** drawing (vẽ+tô màu) → nhãn "Tranh"; moment → "Khoảnh khắc ở lớp". KHÔNG bịa taxonomy (DMA-KID-MEDIA-001).

---

## 6. NGHIỆM THU (PASS — PH Nguyễn Văn Hùng, con An, 10 ảnh Jean)

1. Timeline `/kid` render đủ (8/7 → 19/6), nhãn màu + seeds + storyText đúng — không vỡ (8 ảnh cuộn).
2. **Summary 6/2/3 GIỮ NGUYÊN** — Parent Preview 💛 vẫn 🎨 6 · 🎵 2 · 📸 3 (AC #12) ✅
3. **Bấm card Tranh 8/7** → lightbox mở: nhãn "Tranh" (rose) · ngày 8/7/2026 · tranh `object-contain` **không cắt** · storyText · 💬 "Con muốn kể cho ba mẹ nghe về bức tranh này không? Con thích màu nào nhất?" ✅ (AC #2, #3, #6)
4. **Bấm khoảnh khắc 29/6** → lightbox mở: nhãn "Khoảnh khắc ở lớp" · ngày · ảnh lớn không crop mạnh · storyText 'Bé chăm chú xem' · 💬 "Lúc đó con đang làm gì? Con thích điều gì nhất?" ✅ (AC #4, #6)
5. ✕ đóng ✅ (AC #5)
6. 0 AI · 0 nhận xét giả · 0 DB/RPC/RLS/Auth · timeline nguyên vẹn ✅ (AC #7–13)

**AC 1–13 PASS.** AC #14 (parent không bypass consent) / #15 (backlog rõ) — không áp dụng vì Commit 3 backlog (ghi §8).

**Nhiễu môi trường (KHÔNG phải bug):** nút đỏ "Save" đè lên tranh = extension Pinterest browser Jean (D199-note).

**Verify:** `ph.hung.kidshouse@demo.demenart.com` / `Test@123` → thiết bị An → PIN → cuộn "Hành trình của An 🚌" → bấm card.

---

## 7. FILE ĐỤNG (chỉ 2)

- `src/lib/kidJourneyModel.ts` — append `conversationPrompt`.
- `src/routes/kid.tsx` — import + `openItem` state + 2 ảnh clickable + Dialog detail.
- **0** file khác.

---

## 8. KHÔNG LÀM TRONG V70 (guard đã tôn trọng) + BACKLOG

**Không làm:** Commit 3 parent · rename `kidJourneyModel.ts` · đụng `parent.journal.tsx`/`parent.index.tsx` · DB/RPC/Edge/Auth/RLS/migration · AI thật · Radar · Parent Dashboard · enrich `child_journey` · data giả · đổi summary/timeline/feed/sort.

**BACKLOG (ưu tiên khi mở sprint sau):**
- 🟠 **Parent Journal Lightbox (Commit 3 hoãn)** — sprint riêng. Yêu cầu: `CreationCard`/`MomentCard` clickable **CHỈ khi media `status==="ok"`** → shared lightbox dùng URL **đã ký**, **KHÔNG re-sign, KHÔNG bypass consent**. Trạng thái denied/hidden/loading/empty GIỮ non-clickable. `parent.journal.tsx` chưa import `Dialog` (phải thêm). Audit consent kỹ trước khi code.
- 🟠 **Album "Tác phẩm" grid `/kid`** — drawings chưa clickable (ngoài timeline).
- 🟠 **Recording detail** — mở lightbox cho card audio timeline (cần giải nested-button với `KidAudioCard`).
- 🟠 **Session/Badge detail** — mở detail text-only (không media) nếu thấy có giá trị.
- **Kế thừa V69 (giữ):** 🟠 R4 badge trùng HIỂN THỊ `/parent/journal` · 🟠 nghiệm thu R1 (moment thiếu media) · 🟠 Phương án B RPC canonical `get_child_journey_service` · 🟠 consent-aware count landing · 🟠 rename model.
- **Kế thừa cũ:** 🟠 Parent Portal đầy đủ (multi-child dashboard) · 🟠 Art Growth Radar · 🟠 AI Growth Review THẬT (policy/consent + copy Jean duyệt) · 🔴 Coloring JSON schema · 🔴 Moment media origin taxonomy · Backlog GitHub backup commits (migrations 093–104): Jean thủ công.

---

## 9. BOOT PROTOCOL PHIÊN SAU

1. Đọc `DMA_HANDOFF_v70.md` (file này).
2. Đọc `DMA_00_START_HERE.md` + `DMA_RULES.md` (endpoint **D202+**).
3. Đọc `DMA_SYSTEM_MAP.md` (**v0.63+**).
4. Audit code/DB thật — KHÔNG tin disk snapshot. (Sprint frontend-only: `read_file` Lovable + `pg_get_functiondef` Supabase là đủ.)
5. **Verify SAU mọi paste tay** bằng `read_file` (D8). Agent mode: verify `get_diff` mỗi lượt.

**Workflow mặc định:** Claude đưa code byte-exact để Jean tự paste (tiết kiệm credit). Chuyển agent mode (`send_message`→`get_diff`→`deploy`) khi Jean nói "tự áp"/"auto-app". Sau sửa UI + BUILD PASS → tự publish; chỉ dừng hỏi khi (1) build fail, (2) đụng schema/data Supabase, (3) có thể phá buổi đang chạy thật.

---

## 10. TÀI KHOẢN DEMO (password `Test@123` · `@demo.demenart.com`)

- **PH An/Khang — KHM Nguyễn Văn Hùng:** `ph.hung.kidshouse` *(nghiệm thu Kid Journey Detail — con An)*
- Master KHM Nguyệt Thi: `hieutruong.kidshouse`
- GV KHM Mỹ Linh: `gv.linh.kidshouse`
- Master MNDM Phương Dung: `hieutruong.demen`
- GV MNDM Ngọc Hân: `gv.han.demen`
- PH MNDM Văn Thành: `ph.thanh.demen`

*(Ghi email đầy đủ + mật khẩu khi nhờ Jean test — không để Jean tự tra.)*

---

*V70 = Journey Detail Lightbox (Kid) · frontend-only · 0 DB/RPC/Edge/Auth/RLS/migration · 0 AI · không Radar/Dashboard · 2 file (`kidJourneyModel.ts` append `conversationPrompt` + `kid.tsx` lightbox). Click được: Tranh (single+group thumbnail) + Khoảnh khắc. Backlog: Parent Journal Lightbox (chỉ mở khi status==="ok", không re-sign, không bypass consent) · album Tác phẩm grid · recording/session/badge detail. Nghiệm thu PASS (PH Hùng, An; tranh 8/7 + khoảnh khắc 29/6). Summary 6/2/3 giữ nguyên. Commit `501c68e`(C1)·`dcf794c`(C2), deploy 1 lần. Đóng sổ 2026-07-08 20:28 GMT+7.*
