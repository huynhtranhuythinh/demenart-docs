# 📦 DMA_HANDOFF_v69.md — SHARED JOURNEY SUMMARY (Phương án A)

> **Phiên:** V68 (audit) → V69 (code) · **Ngày chốt:** 2026-07-08 19:43 GMT+7
> **Loại:** Frontend-only. Thống nhất tầng đếm journey giữa `/parent` và `/kid` bằng MỘT hàm summary canonical. 0 DB/RPC/Edge/Auth/RLS/migration · 0 AI thật · không Radar/Journey Detail.

---

## 1. BỐI CẢNH — V68 AUDIT DẪN TỚI V69

V68 = **Canonical Journey Spine Audit** (audit-only, 0 code). Đọc 3 canonical (HANDOFF v67 · RULES D200 · SYSTEM_MAP v0.61) + audit 6 nguồn code thật: 2 RPC (`get_kid_album_service`, `get_child_journal`), `kidJourneyModel.ts`, `kid.tsx`, `parent.index.tsx`, `parent.journal.tsx`.

**Phát hiện cốt lõi:** Hai đường đọc journey TÁCH RỜI, khác cả pipeline lẫn định nghĩa đếm:
- **KID:** `kid.tsx` → Edge `kid_gate(action=album)` → RPC `get_kid_album_service(token)` → Edge **ký batch `media_id`→`signed_url`** → `buildJourneyFeed()` → 1 feed hợp nhất → scrapbook. Summary cũ = `journeySummary(feed)`.
- **PARENT:** gọi `get_child_journal(child_id)` **trực tiếp**; `/parent` đếm **raw inline**, `/parent/journal` render 4 khối rời + ký media **lẻ từng thẻ** qua `get_signed_media_url` + consent gate.
- `child_journey` (thép chờ #1) **KHÔNG phải spine thật** — chỉ chứa session(13)+badge(1). Spine hiện tại = **jsonb merge tầng RPC** từ 5 bảng gốc.

**6 rủi ro lệch số đã liệt kê (R1–R6).** Quan trọng nhất:
- **R1** — Moment thiếu media active: `/parent` đếm raw (tính cả moment không ảnh), kid lọc `!!signed_url` (bỏ) → **Parent ≥ Kid**. An khớp 3/3 chỉ vì mọi moment đều có ảnh (may, không phải bất biến).
- **R2** — Định nghĩa `total` KHÁC HẲN: `/parent` total = works+voice+moments; `journeySummary` kid total = `feed.length` (gồm sessions+badges). Bẫy khi build Parent Dashboard.

**Jean chốt sau audit:** V68 PASS · V69 = Phương án A (shared frontend adapter) · KHÔNG B (chưa cần RPC canonical) · KHÔNG C (enrichment child_journey quá nặng, nguy cơ sync 2 chiều + nhân đôi).

---

## 2. ⭐ LUẬT R1 CANONICAL (Jean chốt — khoá trong code)

**Canonical visible moment/creation = approved + có ít nhất 1 media active/signed_url hiển thị được cho consumer hiện tại.**

Moment/creation thiếu media active:
- **KHÔNG** tính vào summary count.
- **KHÔNG** hiện trong Journey Feed hiển thị cho PH/bé.
- **KHÔNG** xoá dữ liệu gốc (để lại cho internal/debug/backlog).

**Lý do:** với PH và trẻ, "khoảnh khắc" = kỷ niệm CÓ ảnh/video xem lại. Count raw moment thiếu media → số cao hơn thứ PH thật sự thấy → cảm giác app sai/mất ảnh.

Khoá trong `hasDisplayableMedia(item) = !!(item.signed_url || item.media_id)` — một luật, hai consumer (kid mang `signed_url`, parent mang `media_id`).

---

## 3. ĐÃ SHIP (V69 · 3 commit · agent auto-app · deploy 1 lần cuối)

| Commit | SHA | File | Nội dung |
|---|---|---|---|
| **C1** | (paste tay) | `src/lib/kidJourneyModel.ts` | **Append thuần**: `hasDisplayableMedia()` + `summarizeChildJournal(input)` → `{works, voice, moments, badges, topSeed, visibleTotal}` + 2 type. Badge từ `badges[]`; visibleTotal=works+voice+moments (KHÔNG sessions/badges). |
| **C1-fix + C2** | `43d139c` | `kidJourneyModel.ts` · `parent.index.tsx` | Sửa **D8** (paste tay nuốt `<` → `Array` thành `Array<`) + `/parent` landing bỏ đếm raw inline, dùng `summarizeChildJournal(data)`; xoá 2 type chết `CreationRow`/`SkillRow`. |
| **C3** | `e134d58` | `kid.tsx` | 3 chip Parent Preview 💛 đổi nguồn số sang `summarizeChildJournal(album)`. Import thêm `summarizeChildJournal`. **Giữ nguyên** `enough`(=`sum.total>=3`), `sum.seeds`, feed, timeline. |

**Quy trình:** C1 Jean paste tay (workflow mặc định) → phát hiện D8 lúc verify `read_file` → chuyển agent auto-app (Jean gọi "tự áp"). Mỗi agent commit: `send_message` → `get_diff` sạch (đúng file, không đụng `routeTree.gen.ts`) → typecheck pass. Deploy 1 lần cuối (`e134d58`) lên production `demenart.com`.

**Bài học D8 tái khẳng định:** Lovable **nuốt `<` cuối dòng khi paste khối** → `read_file` verify SAU mọi paste tay TRƯỚC khi đi tiếp. Bắt được nhờ audit, không phải build fail runtime.

---

## 4. KIẾN TRÚC (không đổi cấu trúc)

- **3 file đụng:** `src/lib/kidJourneyModel.ts` (append + 1 char fix) · `src/routes/_authenticated/parent.index.tsx` · `src/routes/kid.tsx`.
- **KHÔNG đụng:** `parent.journal.tsx` · `routeTree.gen.ts` · `buildJourneyFeed`/`journeySummary`/`groupDrawingRows` (hàm cũ nguyên vẹn) · Supabase/Edge/RPC/RLS/Auth · npm.
- **Một hàm đếm chung** `summarizeChildJournal` cho cả 2 cổng — nhận album (kid, signed_url) lẫn payload `get_child_journal` (parent, media_id) qua structural typing.
- **0 DB · 0 RPC mới · 0 Edge · 0 AI · 0 npm.**

---

## 5. NGUYÊN TẮC TRUNG THỰC (giữ + mới)

- Rào Tô-màu (drawing gộp coloring → "Tranh"/"Tác phẩm") · Rào moment origin ("Khoảnh khắc ở lớp") — giữ nguyên.
- **⭐ D201 (mới):** Shared summary rule. Visible-media canonical (R1). Badge count từ `badges[]` KHÔNG từ `journey[]` entry_type='badge'. visibleTotal KHÔNG gồm sessions/badges.
- **Không rename** `kidJourneyModel.ts` ở V69 (rename = cập nhật mọi import + git mv → rủi ro build; để commit dọn dẹp riêng sau). Thêm helper vào chính file — commit an toàn nhất khi introduce data layer.

(DMA-KID-MEDIA-001 · linh hồn "nhật ký thuộc về trẻ + gia đình, không chấm điểm trẻ")

---

## 6. NGHIỆM THU (PASS — PH Nguyễn Văn Hùng, con An/Khang, 2 ảnh Jean)

1. `/parent` landing Summary Card An = **🎨 6 Tác phẩm · 🎵 2 Giọng hát · 📸 3 Khoảnh khắc** · hạt giống "Hát theo" ✅
2. `/kid` Parent Preview 💛 "Ba mẹ nhìn lại cùng An" = **🎨 6 tác phẩm · 🎵 2 hoạt động âm nhạc · 📸 3 khoảnh khắc ở lớp** ✅
3. **Hai cổng KHỚP 6/2/3** — cùng hàm `summarizeChildJournal` ✅
4. Timeline `/kid` (scrapbook, filter, gom tranh, AI Review placeholder insufficient-data) chạy y hệt — `enough`/seeds không đổi ✅
5. `/parent/journal` render bình thường (không đụng) ✅
6. 0 DB/RPC/Edge/Auth/RLS/migration · 0 AI · không Radar/Detail ✅

**Verify:** PH An/Khang = `ph.hung.kidshouse@demo.demenart.com` / `Test@123` → `/parent` (landing) + `/kid` (thiết bị An đã ghép, cuộn tới "Hành trình của An 🚌").

**Nhiễu môi trường (KHÔNG phải bug):** nút "📌 Save" đỏ trên tranh = extension Pinterest browser Jean (D199-note).

**Chưa nghiệm thu được (không có data thật):** nhánh R1 "moment thiếu media active" — An mọi moment đều có ảnh nên rule mới không lộ ra. Verify bằng logic + get_diff; ghi backlog nghiệm thu khi có child data phù hợp (giống D199-note). KHÔNG tạo data giả.

---

## 7. FILE ĐỤNG (chỉ 3)

- `src/lib/kidJourneyModel.ts` — append `hasDisplayableMedia`/`summarizeChildJournal` + fix `Array<`.
- `src/routes/_authenticated/parent.index.tsx` — dùng helper, xoá 2 type chết.
- `src/routes/kid.tsx` — 3 chip Parent Preview dùng helper; import thêm.
- **0** file khác.

---

## 8. KHÔNG LÀM TRONG V69 (guard đã tôn trọng)

Không rename file · không đụng `parent.journal.tsx` · không DB/RPC/Edge/Auth/RLS/migration · không AI/Radar/Journey Detail · không tạo data giả · không đổi `buildJourneyFeed`/`journeySummary`/timeline/gate. Badge count từ `badges[]`. visibleTotal = works+voice+moments.

---

## 9. BACKLOG / ON THE HORIZON

**Kế thừa từ audit V68 (chưa làm):**
- 🟠 **R4 badge trùng hiển thị ở `/parent/journal`** — `child_journey` badge entry render trong timeline "Hành trình" ĐỒNG THỜI sidebar "Huy hiệu" (từ `child_badges`). V69 chỉ chống trùng COUNT (lấy `badges[]`); phần HIỂN THỊ trùng thuộc journal refactor / Journey Detail sau.
- 🟠 **Nghiệm thu R1** — cần child ít data / có moment thiếu media active để nghiệm thu rule "không đếm/không hiện".
- 🟠 **Phương án B (RPC canonical `get_child_journey_service`)** — để dành khi build Journey Detail / Parent Dashboard / Radar cần field superset + envelope thống nhất (đụng RPC → Jean duyệt).
- 🔴 **Phương án C (enrichment `child_journey` thành spine thật)** — chỉ khi AI Review thật / Radar cần query spine phức tạp. Nguy cơ sync 2 chiều + nhân đôi (D5). Rủi ro cao.
- 🟠 **Rename `kidJourneyModel.ts` → `journeyModel.ts`** — commit dọn dẹp riêng (cập nhật mọi import, git mv).
- 🟠 **Consent-aware count ở landing** — hiện đếm mức "có media active", chưa trừ moment consent-blocked cho PH (chỉ biết sau khi ký lẻ; nặng, không hợp landing). Với An không có consent-blocked nên khớp. Nếu xuất hiện → landing có thể nhỉnh hơn journal thực xem → cân nhắc lúc làm B.

**Kế thừa cũ (giữ):**
- 🟠 Parent Portal đầy đủ (multi-child dashboard) · 🟠 Journey Detail · 🟠 Art Growth Radar · 🟠 AI Growth Review THẬT (policy/consent + copy Jean duyệt).
- 🔴 Coloring JSON schema (`{type:"coloring",templateId,coloredRegions}`) · 🔴 Moment media origin taxonomy.
- Backlog GitHub backup commits (migrations 093–104): Jean thủ công.

---

## 10. BOOT PROTOCOL PHIÊN SAU

1. Đọc `DMA_HANDOFF_v69.md` (file này).
2. Đọc `DMA_00_START_HERE.md` + `DMA_RULES.md` (endpoint **D201+**).
3. Đọc `DMA_SYSTEM_MAP.md` (**v0.62+**).
4. Audit live database / code thật — KHÔNG tin disk snapshot. (Sprint frontend-only: `read_file` Lovable + `pg_get_functiondef` Supabase là đủ.)
5. **Verify SAU mọi paste tay** bằng `read_file` (D8 — Lovable nuốt `<` cuối dòng).

**Workflow mặc định:** Claude đưa code byte-exact để Jean tự paste (tiết kiệm credit). Chuyển agent mode (`send_message`→`get_diff`→`deploy`) khi Jean nói "tự áp"/"auto-app". Sau sửa UI + BUILD PASS → tự publish; chỉ dừng hỏi khi (1) build fail, (2) đụng schema/data Supabase, (3) có thể phá buổi đang chạy thật. Gặp lỗi tool sau `send_message` → `list_messages`/`get_diff` kiểm tra TRƯỚC khi gửi lại.

---

## 11. TÀI KHOẢN DEMO (password `Test@123` · `@demo.demenart.com`)

- **PH An/Khang — KHM Nguyễn Văn Hùng:** `ph.hung.kidshouse` *(nghiệm thu Parent Portal — 2 con An/Khang, test child-selector + Parent Preview)*
- Master KHM Nguyệt Thi: `hieutruong.kidshouse`
- GV KHM Mỹ Linh: `gv.linh.kidshouse`
- Master MNDM Phương Dung: `hieutruong.demen`
- GV MNDM Ngọc Hân: `gv.han.demen`
- PH MNDM Văn Thành: `ph.thanh.demen`

*(Ghi email đầy đủ + mật khẩu khi nhờ Jean test — không để Jean tự tra.)*

---

*V69 = Shared Journey Summary (Phương án A) · frontend-only · 0 DB/RPC/Edge/Auth/RLS/migration · 0 AI · không Radar/Detail · 3 file (`kidJourneyModel.ts` + `parent.index.tsx` + `kid.tsx`). `summarizeChildJournal` dùng chung 2 cổng. R1 canonical: visible-media, moment thiếu media không đếm/không hiện, không xoá gốc. Nghiệm thu PASS khớp 6/2/3. Đóng sổ 2026-07-08 19:43 GMT+7.*
