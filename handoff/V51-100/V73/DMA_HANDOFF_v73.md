# 📦 DMA_HANDOFF_v73.md — PARENT JOURNAL READING EXPERIENCE POLISH

> **Phiên:** V73 · **Ngày chốt:** 2026-07-09 09:58 GMT+7
> **Loại:** **Frontend-only reading-experience polish.** Làm `/parent/journal` dễ đọc/ấm hơn cho phụ huynh sau khi consent guard V71/V72 đã khóa. **1 file · 0 DB/RPC/Edge/Auth/RLS/migration · 0 AI · 0 re-sign · 0 media_id thô · 0 npm.** 3 commit agent auto-app.
> **Kết quả:** ✅ **PASS** (C1+C2 bằng ảnh; C3 bằng cấu trúc + data audit).

---

## 1. BỐI CẢNH — V73 SAU V72

V71 ship Parent Journal Lightbox (consent-safe). V72 = QA/audit-only chứng minh lightbox tuyệt đối không mở khi media không `ok`. Consent guard đã khóa → V73 chuyển sang **polish cách đọc**: header/copy ấm hơn, nhãn section rõ hơn, affordance "bấm để xem lớn", dedup badge trùng hiển thị. **KHÔNG data-architecture, KHÔNG RPC canonical, KHÔNG dashboard/Radar/AI thật.**

**File duy nhất đụng:** `src/routes/_authenticated/parent.journal.tsx`.

---

## 2. C1 — COPY / SECTION POLISH · commit `6be6edd`

Copy-only, 6 khối tìm–thay:
- **Header subcopy** ("Nhật ký của con") → "Tác phẩm, khoảnh khắc và hành trình nghệ thuật của con — lưu lại để ba mẹ cùng con nhìn lại, thuộc về con và gia đình."
- **Nhãn section** "Bé tự làm" → **"Tác phẩm của con"** · "Khoảnh khắc" → **"Khoảnh khắc ở lớp"** (đồng bộ title lightbox V71). Subcopy moment bỏ "ở lớp" trùng.
- **Recording** (CreationCard `kind==="recording"`): thêm label **"Âm thanh của con"** (trung tính — schema chưa phân biệt hát/nhạc) + câu khích lệ "Ba mẹ có thể nghe lại cùng con và hỏi con thích đoạn nào nhất." `<audio controls preload="none">` **GIỮ NGUYÊN**, chỉ `gap-3`→`gap-2`.
- **Moment empty** → "Những khoảnh khắc của con ở lớp sẽ dần được thêm vào đây."

---

## 3. C2 — LIGHTBOX AFFORDANCE · commit `f9018ef`

Badge zoom nhìn thấy được, CHỈ khi media mở được. 3 edit:
- Import `ZoomIn` (lucide-react).
- **MomentCard:** overlay button (đã `absolute inset-0`, chỉ render khi `canOpen=!!signedUrl`) thêm `group` + badge span con `<span className="pointer-events-none absolute bottom-2 right-2 …"><ZoomIn/> Xem lớn</span>`.
- **CreationCard drawing:** button `status==="ok" && kind==="drawing"` thêm `relative` + cùng badge span (sibling của `<img>`).

**Guard giữ đúng D203/D204:** badge `pointer-events-none` → không chặn click; nằm TRONG gate `canOpen`/`ok drawing` → **recording + denied/hidden/empty/loading KHÔNG có badge** → không rò ở consent-blocked, không che nút "Vì sao?".

---

## 4. C3 — BADGE DUPLICATE CLEANUP · commit `4885121`

Chỉ section "Hành trình": bọc conditional timeline trong IIFE:
```
const timelineEntries = data.journey.filter((e) => e.entry_type !== "badge");
return timelineEntries.length === 0 ? (<empty copy>) : (<ol>{timelineEntries.slice().sort(...).map(...)}</ol>);
```
- `timelineEntries` dùng cho **CẢ** empty-check **LẪN** map → **bẫy empty-list** đã chặn (bé chỉ có badge, không session → hiện empty copy đúng, không `<ol>` rỗng).
- Sidebar **"Huy hiệu kỷ niệm"** (đọc `data.badges` = `child_badges` `confirmed`) = **nguồn hiển thị chính** cho badge.
- 0 đổi data/count/RPC · inner `.map` body + curly-quotes teacher_note nguyên vẹn · sidebar KHÔNG đụng · `entryVisual` badge-branch để nguyên (giờ dead cho timeline, vô hại).

---

## 5. ⭐ C3 NGHIỆM THU BẰNG CẤU TRÚC + DATA AUDIT (mấu chốt V73)

**KHÔNG nghiệm thu C3 bằng ảnh An** — vì audit data sống cho thấy **An không có badge nào**. Truy nguồn thật (`get_child_journal` def + query):

- `journey[]` đọc **`child_journey`** (MỌI `entry_type`, gồm `'badge'`); `badges[]` đọc **`child_badges` JOIN `badges` WHERE `status='confirmed'`** — **2 nguồn KHÁC NHAU**. Cùng badge có thể hiện ở CẢ timeline lẫn sidebar (R4 trùng hiển thị).
- **Audit toàn hệ (2026-07-09):**
  - Chỉ **1 bé có badge = Bé Jenny Demo** (`429d4fb7-67f0-4166-8ec3-fee7ad1a3666`) — có **CẢ** journey-badge entry **LẪN** `child_badges` `confirmed`. → đúng ca trùng, dedup chuyển badge về sidebar (vẫn hiện).
  - **KHÔNG bé nào** có journey-badge mà thiếu confirmed-badge → dedup **không giấu badge nào** → **an toàn tuyệt đối**.
  - **An** (`d1000000-0000-4000-8000-000000000041`): **4 session, 0 badge** (`child_journey` không có `entry_type='badge'`; `child_badges` rỗng). → C3 **no-op** với An; sidebar "Huy hiệu kỷ niệm" **VẮNG là ĐÚNG** (badges[] rỗng), KHÔNG phải regression.

**An KHÔNG phải dataset nghiệm thu badge dedup.** Visual QA badge dedup (nếu cần sau này): login **Jenny Demo → PH `parent.demo@demenart.com`**, hoặc seed 1 `child_badges` confirmed cho An ở **sprint data riêng** (đổi data, cần Jean duyệt, ngoài V73).

**Bài học D1/D3:** nghiệm thu C3 lần đầu Claude nói "sidebar badge vẫn hiện đủ" — suy từ premise R4, chưa kiểm data An → **SAI**. Sửa bằng audit DB sống. Không khẳng định "chuyển về/vẫn hiện ở nơi X" nếu chưa query dataset THẬT.

---

## 6. NGHIỆM THU C1 + C2 BẰNG ẢNH (login PH Hùng, con An, 7 ảnh Jean)

| # | Bước | Kết quả |
|---|---|---|
| 1 | `/parent` landing | Summary **6/2/3** + "Hạt giống nổi bật: Hát theo" giữ nguyên |
| 2 | `/parent/journal` C1 | Section "Tác phẩm của con" + "Khoảnh khắc ở lớp"; recording "Âm thanh của con" + câu khích lệ; audio phát bình thường |
| 3 | Lightbox C1 | Bấm tranh → mở object-contain không cắt + "Tác phẩm của con" + 💬 gợi ý (V71 nguyên vẹn) |
| 4 | Badge zoom C2 | 4 tranh + 3 khoảnh khắc có badge "🔍 Xem lớn"; card recording KHÔNG có |
| **5** | **Consent-blocked C2** | Tắt `group_moment_in_class` → 2 ảnh nhóm 29/6·28/6 "Đang chờ ba mẹ đồng ý" + **"Vì sao?" sống** + **KHÔNG rò badge zoom**; ảnh 1-bé 26/6 vẫn hiện + có badge |

---

## 7. FILE ĐỤNG

- **1 file code:** `src/routes/_authenticated/parent.journal.tsx` (3 commit: `6be6edd` · `f9018ef` · `4885121`). Mỗi commit get_diff sạch (đúng 1 file, 0 đụng `routeTree.gen.ts`), typecheck pass, deploy production.
- **0 DB thay đổi.** Audit read-only: `get_child_journal` def (`pg_get_functiondef`) + query `child_journey`/`child_badges`/`children`/`profiles` (An + toàn hệ).

---

## 8. KHÔNG LÀM TRONG V73 (guard tôn trọng) + BACKLOG

**Không làm:** data-architecture · RPC canonical mới · Edge mới · sửa RLS/Auth/PIN/device · AI thật · Radar · Parent Dashboard lớn · multi-child dashboard · upload/notification/approval · consent engine rewrite · `get_signed_media_url` rewrite · re-sign trong lightbox · media_id thô · rename `kidJourneyModel.ts` · refactor lớn/reorder layout `parent.journal.tsx` · hardcode data giả · đổi summary V69 · phá `/kid` lightbox V70 / Parent Lightbox V71 / consent guard V72 · seed badge cho An (đổi data).

**BACKLOG (kế thừa + mới):**
- 🟠 **Lưu repo/backup `parent.journal.tsx` V73** (Jean thủ công) · Backlog GitHub backup commits (migrations 093–104): Jean thủ công.
- 🟠 **Visual QA badge dedup** — dùng Jenny Demo (`parent.demo@demenart.com`) hoặc seed badge confirmed cho An ở sprint data riêng. An KHÔNG phù hợp (0 badge).
- 🟠 R4 badge trùng đã xử lý HIỂN THỊ (dedup timeline; count đã chống trùng từ V69).
- 🟠 Kế thừa: nghiệm thu nhánh hidden/empty Parent Lightbox (chờ data consent-blocked, gộp R1) · Phương án B RPC canonical `get_child_journey_service` (khi cần superset: Journey Detail/Dashboard/Radar) · rename `kidJourneyModel.ts`→`journeyModel.ts` · consent-aware count landing · album "Tác phẩm" grid `/kid` clickable · recording/session/badge detail `/kid`.
- 🟠 Parent Portal đầy đủ (multi-child dashboard) · Art Growth Radar · AI Growth Review THẬT (policy/consent + copy Jean duyệt).
- 🔴 Coloring JSON schema (`{type:"coloring",templateId,coloredRegions}` thay `kind:"drawing"` chung) · 🔴 Moment media origin taxonomy.

---

## 9. BOOT PROTOCOL PHIÊN SAU

1. Đọc `DMA_HANDOFF_v73.md` (file này).
2. Đọc `DMA_00_START_HERE.md` + `DMA_RULES.md` (endpoint **D205+**).
3. Đọc `DMA_SYSTEM_MAP.md` (**v0.66+**).
4. Audit code/DB thật — KHÔNG tin disk snapshot (`read_file` Lovable + `pg_get_functiondef`/`get_edge_function`/query bảng gốc Supabase).
5. **Verify `get_diff` mỗi lượt** (agent mode) / `read_file` sau mọi paste tay (D8).

**Workflow mặc định:** Claude đưa code byte-exact để Jean tự paste (tiết kiệm credit). Chuyển agent mode (`send_message`→`get_diff`→`deploy`) khi Jean nói "tự áp"/"auto-app". Sau sửa UI + BUILD PASS → tự publish; chỉ dừng hỏi khi (1) build fail, (2) đụng schema/data Supabase, (3) có thể phá buổi đang chạy thật.

---

## 10. TÀI KHOẢN DEMO (password `Test@123` · `@demo.demenart.com`, trừ khi ghi khác)

- **PH An/Khang — KHM Nguyễn Văn Hùng:** `ph.hung.kidshouse` *(con An `d1000000-…-0041` — nghiệm thu V73 C1+C2; An 0 badge → không hợp nghiệm thu C3)*
- **PH Bé Jenny Demo:** `parent.demo@demenart.com` *(role primary_parent — bé DUY NHẤT có badge trùng; dùng nghiệm thu badge dedup C3. Mật khẩu KHÔNG có trong sổ tay — Jean tra/thử `Test@123`)*
- Master KHM Nguyệt Thi: `hieutruong.kidshouse`
- GV KHM Mỹ Linh: `gv.linh.kidshouse`
- Master MNDM Phương Dung: `hieutruong.demen`
- GV MNDM Ngọc Hân: `gv.han.demen`
- PH MNDM Văn Thành: `ph.thanh.demen`

*(Ghi email đầy đủ + mật khẩu khi nhờ Jean test — không để Jean tự tra.)*

---

## 11. VIỆC MỞ NGAY SAU KHI ĐÓNG SỔ (Jean thao tác)

- ⚠️ **Bật lại `group_moment_in_class` cho An** tại `/parent/consent` — ảnh test C2 để consent này đang TẮT (2 ảnh nhóm 28/6·29/6 đang "chờ đồng ý"). Bật lại để demo về đủ 6/2/3 (như rollback V72).

---

*V73 = Parent Journal Reading Experience Polish · frontend-only · 1 file `parent.journal.tsx` · 0 DB/RPC/Edge/Auth/RLS/migration/AI/re-sign. 3 commit agent auto-app (get_diff sạch, không đụng `routeTree.gen.ts`, typecheck pass, 3 deploy): C1 `6be6edd` copy/section polish · C2 `f9018ef` badge "🔍 Xem lớn" (chỉ khi media mở được) · C3 `4885121` badge dedup timeline (IIFE `timelineEntries`). C1+C2 nghiệm thu ảnh (PH Hùng, An, gồm consent-blocked). C3 nghiệm thu CẤU TRÚC + DATA AUDIT: chỉ Jenny Demo có badge (journey-badge + confirmed child_badge); An 0 badge → C3 no-op, sidebar vắng là đúng. Guard giữ nguyên: summary V69 6/2/3 · `/kid` lightbox V70 · Parent Lightbox V71 · consent guard V72. RULES → D205. SYSTEM_MAP v0.65→v0.66. Đóng sổ 2026-07-09 09:58 GMT+7.*
