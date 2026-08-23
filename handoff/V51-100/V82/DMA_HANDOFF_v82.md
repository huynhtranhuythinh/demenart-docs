# DMA_HANDOFF_v82.md
**Sprint:** V82 — Gallery Stability Audit + Media Count Affordance Decision
**Ngày:** 2026-07-09 21:51 GMT+7 (Asia/Ho_Chi_Minh)
**Vai trò:** ChatGPT = CTO Advisor · Claude = PM + Prompt Operator + Builder · Lovable = build
**Trạng thái:** ✅ ĐÓNG SỔ — **AUDIT-ONLY** · CTO chốt Lối A · 0 code · 0 DB/RPC/Edge/migration · V82 PASS audit-only
**File code bị đụng:** **NONE.** DB/RPC/Edge/migration: **NONE.** (sprint ổn định/quyết định thuần)

---

## 0. TL;DR

V82 là **sprint ổn định + quyết định** (KHÔNG kiến trúc, KHÔNG code). Sau khi V78–V81 dựng gallery đa-media thật, chạy audit ổn định toàn Parent journal/gallery và quyết định liệu trục thời gian có cần affordance "media count" nhỏ ("2 ảnh") hay không.

- **C1 audit LIVE (read-only):** endpoint (D213/v0.74/v81) khớp · DB sống + code sống confirm gallery V80/V81 chạy đúng & sạch → **0 drift**.
- **C2 quyết định — CTO chốt Lối A (audit-only):** **KHÔNG** thêm chip "X ảnh" trên trục · **KHÔNG** đổi copy counter lightbox ("1/2" giữ nguyên) · giữ nguyên UX gallery V81 (RULES **D214**).
- **Lý do bác chip (nguyên từ V81, data KHÔNG đổi):** toàn hệ CHỈ 1 moment gallery (`f51039be`, n=1) → chip hiện đúng 1 card, giá trị thấp + đua chỗ badge privacy + chật mobile; gallery đã tự lộ (cover mời "Xem" → dots+counter a11y V81). **Revisit chip `mediaCount` CHỈ khi** có nhiều moment ≥2 ảnh **HOẶC** user testing cho thấy PH bỏ sót gallery.
- **Nghiệm thu:** V82 PASS audit-only — 0 DB/RPC/Edge/migration · 0 frontend code · 0 chip "2 ảnh" · 0 timeline visual change · UX gallery V81 đủ dùng.

**⭐ Endpoint sau V82:** RULES **D214** · SYSTEM_MAP **v0.75** · Handoff **v82**.

---

## 1. Canonical đã đọc — endpoint verify (đầu phiên)

Topic V82 mới mở. **KHÔNG dựa memory**, đọc canonical thật trên đĩa:
- `DMA_HANDOFF_v81.md` · `DMA_00_START_HERE.md` · `DMA_RULES.md` · `DMA_SYSTEM_MAP.md`.

**Endpoint đầu phiên (verify LIVE trên đĩa):** RULES **D213** (D-rule cao nhất; D214 chưa tồn tại — grep 0 match) · SYSTEM_MAP **v0.74** (header dòng 1) · Handoff **v81** — **khớp brief cả 3** ✔

---

## 2. C1 — Audit DB sống + code sống (read-only, kết quả)

**DB (`xcvhacymrbhdhohyylyq`, read-only qua Supabase MCP):**
1. `get_child_journal`: SECURITY DEFINER · `search_path=""` · grants = **`authenticated` + `service_role` + `postgres`** (0 anon/PUBLIC — D15) ✔. Gallery fields đủ (`coverMediaId`/`mediaCount`/`hasGallery`/`galleryItems`). **0 `signed_url` field trả về** — token `signed_url` xuất hiện **đúng 1 lần** trong body và là **comment** dòng 51 ("V79: … 0 signed_url"), KHÔNG phải field. AC 8 giữ ✔. Cover = `ORDER BY created_at LIMIT 1`; `mediaCount`=count(*); `hasGallery`=count>1; `galleryItems`=array. Đúng shape V79/D211.
2. `f51039be-48e8-42c5-9900-b03f3472cd1f`: state=**approved** · caption=**null** · tagged **3** (An `…0041` / Trần Thanh Bình `…0042` / Lê Bảo Chi `…0043`) · **2 media active** (`image/jpeg`): cover `3ca6c3dd…e909` (29/6) → `b2d5d20a…b22c` (30/6) ⇒ **mediaCount=2 · hasGallery=true · galleryItems.len=2** ✔
3. Summary An (`Nguyễn Hoàng An`, `d1000000-…-0041`): drawing **6** · recording **2** · moments-với-media **4** = **6/2/4** ✔ (kid_creations chỉ có drawing+recording, 0 kind lạ). Phân bố 4 moment-media: 3× (1 ảnh — gồm single "Bé chăm chú xem" `6bc3aef5`, "Hình ảnh thử nghiệm" `8e2c5c7e`, "An chăm chú lắng nghe…" `d1…00a1`) + 1× (2 ảnh = `f51039be`).
4. **Inventory:** **63 bảng · 105 definer · 155 policy · 1 cron** → khớp y hệt V81 → **0 DB drift** ✔

**Code sống `parent.journal.tsx`** (đọc live qua `Lovable:read_file`, 1 file chứa trọn timeline+lightbox):
- `type MomentRow` = 5 field gốc (`moment_id`/`caption`/`created_at`/`media_id`/`tagged_count?`) + 4 field gallery optional V79 (`coverMediaId?`/`mediaCount?`/`hasGallery?`/`galleryItems?`). `moment.mediaCount` CÓ sẵn trong scope leaf (nếu tương lai cần chip thì 0 fetch thêm).
- `CompactMomentLeaf`: timeline 1 cover (qua `MomentImage(media_id)`), truyền `galleryItems` xuống lightbox, badge **chỉ** `MomentPrivacyBadge` (🔒 Riêng gia đình / 👨‍👩‍👧 Ảnh chung nhiều bé) — **0 chip "X ảnh"** trên trục ✔.
- `ParentJournalLightbox`: `hasGallery=items.length>1`; cover seed từ `signedUrl` leaf (0 re-sign); `selectItem` ký on-demand qua Edge `get_signed_media_url`; `knownRef` chống ký trùng; cache theo mediaId.
- **V81 polish có mặt đủ 4** (verify từng dòng live): (1) `safeSelected = items.length===0?0:Math.min(Math.max(selected,0),items.length-1)` (clamp) ✔; (2) counter `aria-live="polite"` + `aria-atomic="true"` + `tabular-nums` ✔; (3) tap-target `<button className="group flex h-8 items-center justify-center px-1">` bọc `<span>` chấm (span `h-2.5`/`w-5` active/`w-2.5` inactive — visual y hệt), + `aria-label`/`aria-current`/`title` ✔; (4) loading pill "Đang tải ảnh…" (dot `animate-pulse`) trên Skeleton `absolute inset-0` giữ `h-[45vh]` ✔.

→ **Code live = đúng trạng thái đóng V81, 0 drift.**

*(Smoke real-login là việc tay của Jean — Claude KHÔNG tự đăng nhập. Static audit DB+code cho bằng chứng đủ mạnh để chốt quyết định audit-only. Account nếu Jean muốn re-smoke: `ph.hung.kidshouse@demo.demenart.com` / `Test@123`, con An → `/parent` (6/2/4) → `/parent/journal` (trục y hệt, 0 chip) → mở `f51039be` (counter 1/2 → switch 2/2) → mở 1 single-media.)*

---

## 3. C2 — Quyết định affordance (CTO chốt Lối A: audit-only)

**Câu hỏi:** trục thời gian có nên hiện chỉ báo "2 ảnh" nhỏ khi `mediaCount > 1`?

3 lối đề xuất — **CTO chốt Lối A (audit-only, 0 code):**

| Lối | Nội dung | Rủi ro | Giá trị hiện tại | Quyết |
|---|---|---|---|---|
| **A ⭐** | Audit-only, 0 code, đóng V82 stability | 0 | Nhất quán V81, trục sạch | ✅ **CHỐT** |
| B | Chip "2 ảnh" trên leaf khi mediaCount>1 | Thấp (cạnh badge privacy, chật mobile) | Thấp — hiện đúng 1 card | Hoãn |
| C | Đổi copy counter lightbox "1/2" → "1/2 ảnh" | Gần 0 | Rõ hơn chút | KHÔNG làm |

**Lý do (D214):** audit KHÔNG lộ bằng chứng mới để lật quyết định V81. Số moment multi-media KHÔNG tăng (vẫn **n=1**: `f51039be`) → lý do bác chip ở V81 còn nguyên. Gallery đã đủ khám phá (cover mời "Xem" → mở ra thấy ngay dots + counter a11y V81). Chip chỉ hiện 1 card mà đua chỗ với badge privacy + chật mobile → lời ít hơn hại. Không bịa commit chỉ để có commit (né bẫy "sprint phải có code").

**V82 decision (ghi rõ):**
- KHÔNG timeline `mediaCount` affordance trong V82.
- KHÔNG đổi copy counter lightbox trong V82.
- UX gallery V81 hiện tại **đủ dùng**.
- **Revisit chip `mediaCount` CHỈ khi** có nhiều moment ≥2 ảnh thật HOẶC user testing cho thấy PH bỏ sót gallery.

---

## 4. Nghiệm thu — V82 PASS audit-only

- **V82 PASS như sprint audit-only.**
- **0 DB/RPC/Edge/migration.**
- **0 frontend code change.**
- **KHÔNG chip "2 ảnh".**
- **0 timeline visual change.**
- KHÔNG có commit / diff / rollback — vì **0 thay đổi**. Production giữ nguyên trạng thái V81 đã nghiệm thu 17/17 (deploy `06c46138`, commit `f6b78c2a`).

**Trạng thái LIVE đã verify (closure requirement #5):**
- Đầu phiên: RULES **D213** / SYSTEM_MAP **v0.74** / Handoff **v81**.
- An summary **6 / 2 / 4**.
- `f51039be` **mediaCount=2 · hasGallery=true · galleryItems.length=2**.
- `get_child_journal` **0 signed_url output** (1 match = comment).
- Grants = **authenticated + service_role + postgres** only (0 anon/PUBLIC).
- Inventory KHÔNG đổi: **63 bảng / 105 definer / 155 policy / 1 cron**.
- `parent.journal.tsx` live chứa V81 polish: **selectedIndex clamp (`safeSelected`) · counter `aria-live` · tap-target dots lớn hơn · state "Đang tải ảnh…"**.

---

## 5. Guard đã giữ trọn (V82)

DB: **0 thay đổi** (0 migration/RPC/Edge/schema/RLS/policy/data). 63 bảng · 105 definer · 155 policy · mig 001→105 · Edge 14 · cron 1 · 3 tenant KHÔNG đổi. Frontend: **0 file**. 0 signed_url RPC · 0 ký adapter · 0 Edge batch-sign · 0 raw Bunny DOM · 0 hardcode `f51039be` · 0 fake gallery · 0 pre-sign · 0 timeline affordance/badge · 0 chip · 0 đổi copy counter · 0 đổi summary logic · 0 đổi signing architecture. Consent guard V72 + badge dedup V73 nguyên. Guard chuỗi: summary V69(6/2/4) · /kid lightbox V70 · Parent Lightbox V71 · consent V72 · badge dedup V73 · adapter V74 · compact spine V75 · detail V76 · home V77 · data foundation V78 · RPC enrich V79 · gallery UI V80 · gallery polish V81.

---

## 6. Backlog (kế thừa — chưa làm ở V82)

- 🟠 **Re-sync project library:** up `DMA_RULES.md` (D214) + `DMA_SYSTEM_MAP.md` (v0.75) mới vào project knowledge (2 file governance từng bị mất khi re-upload — nợ mang từ V81).
- 🟠 Lưu repo/backup V81 (`parent.journal.tsx` polish diff, commit `f6b78c2a`).
- 🟠 Smoke mobile lightbox ở viewport hẹp (desktop PASS; tap-target đã nới V81).
- 🟠 favicon 404 (nợ vặt pre-existing, backlog riêng).
- 🟠 **(hoãn) Timeline affordance "X ảnh"** — chỉ làm khi có nhiều moment ≥2 ảnh (hiện n=1) HOẶC user testing PH miss gallery.
- 🟠 (tùy) migration `cover_media_id`/`sort_order` — chỉ khi cần chọn cover thủ công / sắp thứ tự.
- 🟠 (tùy) Edge batch-sign — chỉ khi gallery nhiều ảnh gây waterfall.
- Nợ cũ: Parent Dashboard đầy đủ / Radar / AI Review THẬT · Phương án B RPC canonical `get_child_journey_service` (hợp nhất 2 path đọc journey kid/parent) · rename `kidJourneyModel.ts` · enrichment `child_journey` · Coloring JSON schema · Moment media source taxonomy.

**Endpoint sau V82:** RULES **D214** · SYSTEM_MAP **v0.75** · Handoff **v82**.
Production: https://demenart.lovable.app (giữ deploy `06c46138`, commit `f6b78c2a` — V82 KHÔNG deploy). Handoff/RULES/SYSTEM_MAP trước V82: v81 / D213 / v0.74.
