# DMA_HANDOFF_v84.md
**Sprint:** V84 — Parent Journal Filter & Month Navigation Audit
**Ngày:** 2026-07-10 00:17 GMT+7 (Asia/Ho_Chi_Minh)
**Vai trò:** ChatGPT = CTO Advisor · Claude = PM + Prompt Operator + Builder · Lovable = build
**Trạng thái:** ✅ ĐÓNG SỔ — **AUDIT-ONLY** · 0 code · 0 DB/RPC/Edge/migration · Nghiệm thu **audit-only PASS**
**File code bị đụng:** **NONE** (0 code). DB/RPC/Edge/migration: **NONE.**

---

## 0. TL;DR

V84 là **sprint audit / quyết-định-thiết-kế** (KHÔNG kiến trúc, KHÔNG code, KHÔNG data). Câu hỏi: khi data lớn dần, `/parent/journal` có cần **filter chip theo loại** và/hoặc **month navigation** không?

- **C1 audit LIVE (read-only):** endpoint (D215/v0.76/v83) khớp đĩa **0 drift** · DB sống + code sống xác nhận trạng thái V83 nguyên vẹn.
- **C2 quyết định — CTO chốt Lối A (audit-only):** **KHÔNG** filter chip · **KHÔNG** month-jump nav · giữ nguyên timeline V74–V83. Data còn nhỏ (16 item / 2 tháng), timeline đã group theo tháng sẵn → dễ đọc; thêm control kiểu dashboard là **quá sớm** và nghịch LINH HỒN (album ấm).
- **Nghiệm thu:** audit-only PASS — 0 frontend code · 0 DB/RPC/Edge/migration · 0 filter chip · 0 month nav · 0 timeline visual change. KHÔNG thêm code chỉ để có commit (D214/D216).

**⭐ Endpoint sau V84:** RULES **D216** · SYSTEM_MAP **v0.77** · Handoff **v84**.

---

## 1. Canonical đã đọc — endpoint verify (đầu phiên)

Topic V84 mới mở. **KHÔNG dựa memory**, đọc canonical thật trên đĩa:
- `DMA_HANDOFF_v83.md` · `DMA_00_START_HERE.md` · `DMA_RULES.md` · `DMA_SYSTEM_MAP.md`.

**Endpoint đầu phiên (verify LIVE trên đĩa):** RULES **D215** (D-rule cao nhất) · SYSTEM_MAP **v0.76** (header dòng 1) · Handoff **v83** — **khớp brief cả 3** ✔ · **0 drift đĩa** (khác V81/V82 từng tụt phiên).

---

## 2. C1 — Audit DB sống + code sống (read-only, kết quả)

**DB (`xcvhacymrbhdhohyylyq`, Supabase MCP read-only):**
1. Summary An (`Nguyễn Hoàng An`, `d1000000-0000-4000-8000-000000000041`): drawing **6** · recording **2** · moments-có-media-active **4** = **6/2/4** ✔ (kid_creations chỉ drawing+recording).
2. **Phân bố item-type + tháng cho An (điểm quyết định V84):**

| Loại trên trục | Nhãn UI | Số | Tháng |
|---|---|---|---|
| creation·drawing | 🎨 Tác phẩm của con | 6 | 2026-07 |
| creation·recording | 🎵 Âm thanh của con | 2 | 2026-07 |
| moment | 📸 Khoảnh khắc ở lớp | 4 | 2026-06 |
| journey·session | 🚌 Mốc hành trình / Buổi học | 4 | 2026-06 |
| **Tổng** | | **16 item** | **2 tháng** |

3. `f51039be-…-cd1f`: state=**approved** · caption=**null** · tagged **3** (An/Bình/Chi) · **2 media active** (cover `3ca6c3dd…e909` → `b2d5d20a…b22c`, ORDER BY created_at ASC) ⇒ mediaCount=2 · hasGallery=true · galleryItems.len=2 ✔ · multi-media moment toàn hệ vẫn **n=1**.
4. `get_child_journal`: SECURITY DEFINER · `search_path=""` · **0 field `signed_url`** (1 match duy nhất = comment) · grants = **authenticated + service_role + postgres** (0 anon/PUBLIC — D15) ✔
5. **Inventory:** **63 bảng · 105 definer · 155 policy · 1 cron** → khớp y hệt V82/V83 → **0 DB drift** ✔

**Code sống `parent.journal.tsx`** (đọc live qua `Lovable:read_file`, đúng `createFileRoute("/_authenticated/parent/journal")`):
- **0 code drift** — chứa đủ chuỗi V79→V83: `MomentRow` 4 field gallery (optional) · `safeSelected` clamp · counter `aria-live="polite"`/`aria-atomic`/`tabular-nums` · tap-target `<button h-8 px-1>` bọc chấm · loading pill "Đang tải ảnh…" trên skeleton · `getMomentWarmLine`/`getMomentConversationPrompt`/`MOMENT_GALLERY_HINT` · title "Khoảnh khắc ở lớp" giữ · `DialogDescription` sr-only.
- **🔑 Phát hiện then chốt:** `buildParentTimeline` ĐÃ gộp `journey(session) + creation + moment` (badge/skills → sidebar, KHÔNG lên trục). `groupTimelineByMonth` + section header "Tháng N, 2026" **ĐÃ render live từ V74** → phần lõi "điều hướng theo tháng" (nhóm + nhãn) đã tồn tại; cái duy nhất chưa có là **month-jump selector** (nhảy tới 1 tháng), chỉ đáng khi timeline trải nhiều tháng.
- **State hiện tại:** `JournalPage` chỉ có `children / selectedChildId / data / loading / error`. **0 filter state.** Empty-state: (a) 0 con liên kết; (b) timeline rỗng. Chưa có empty-state "lọc rỗng".

**Smoke (C1.5):** V83 vừa PASS 21/21 + audit trên xác nhận 0 drift DB+code ⇒ production đang đúng trạng thái V83. Vì chốt audit-only (0 code) nên KHÔNG cần smoke lại (không có gì thay đổi để verify).

---

## 3. C2 — Quyết định (CTO chốt Lối A · audit-only)

4 phương án trình CTO: **A** (audit-only, 0 code) ★ · **B** (chip lọc type) · **C** (month nav) · **D** (filter + month nav, brief tự loại). **CTO chốt A.**

**Lý do chốt A (cụ thể):**
- 16 item / 2 tháng đã group sẵn → dễ đọc, cuộn nhanh.
- Chip lọc *chạy được về kỹ thuật* (có đủ 4 type thật, gồm "Buổi học" = 4 session) nhưng thêm control kiểu dashboard **quá sớm**: vụn narrative (Âm thanh = 2 item), chật mobile 5 chip → nghịch **LINH HỒN** (album ấm, KHÔNG SaaS dashboard lạnh).
- **Month-grouping đã có sẵn** (từ V74) tự lo điều hướng thời gian; **month-jump selector vô nghĩa với 2 tháng**.
- Khớp **D214/D216-nguyên-tắc**: "không làm cũng là quyết định có giá trị khi data chưa đủ"; **grouping đã có ≠ navigation**; né bẫy "sprint phải có code".

---

## 4. Tiêu chí revisit (ghi để phiên sau không làm theo phản xạ)

Mở lại **filter chip / month navigation** CHỈ khi ≥1 điều kiện THẬT quan sát được đúng:
1. Một trẻ có timeline **~25–30+ item**.
2. Timeline trải **4–5+ tháng**.
3. User testing PH cho thấy **khó tìm** 1 loại hoạt động / 1 giai đoạn cụ thể.

Trước ngưỡng đó: thêm control = giảm cảm xúc, tăng bề mặt điều khiển vô ích.

*(Spec Option B đã sẵn nếu sau này duyệt: chỉ đụng 1 file `parent.journal.tsx`, thêm local `filter` state + lọc `timeline` client-side TRƯỚC `groupTimelineByMonth`, 0 RPC/DB/fetch/signing, empty-state mềm "Chưa có nội dung phù hợp trong mục này." — KHÔNG bung ở V84.)*

---

## 5. Nghiệm thu — audit-only PASS

- ✅ 0 frontend code · 0 DB/RPC/Edge/migration
- ✅ 0 filter chip · 0 month nav · 0 timeline visual change
- ✅ `/parent` summary vẫn **6/2/4**; home không đổi
- ✅ `/parent/journal` timeline card không đổi; V83 lightbox warm copy nguyên; `f51039be` gallery nguyên (2 media, switch 1→2→1)
- ✅ 0 signed_url ở RPC · 0 ký adapter · 0 Edge batch-sign · 0 raw Bunny
- ✅ consent guard V72 + badge dedup V73 giữ · 0 hardcode `f51039be`

**Guard chuỗi giữ nguyên:** summary V69(6/2/4) · /kid V70 · Lightbox V71 · consent V72 · badge V73 · adapter V74 · compact V75 · detail V76 · home V77 · data V78 · RPC enrich V79 · gallery UI V80 · polish V81 · stability V82 · warmth V83.

---

## 6. Rollback

**Không cần** — 0 thay đổi code/DB/Edge/migration. Chỉ cập nhật library (handoff + RULES D216 + SYSTEM_MAP v0.77). Không có diff/commit để revert.

---

## 7. Endpoint & Backlog sau V84

**Endpoint:** RULES **D216** · SYSTEM_MAP **v0.77** · Handoff **v84**.

**Backlog:**
- 🟠 re-sync project library (RULES D216 + SYSTEM_MAP v0.77) · lưu repo V84
- 🟠 (hoãn) filter chip / month-jump nav — bung khi đạt **ngưỡng revisit §4**
- 🟠 (hoãn) timeline affordance "X ảnh" khi n≥2 moment gallery HOẶC user-testing PH miss gallery (nguyên từ D213/D214)
- 🟠 (tùy) migration `cover_media_id`/`sort_order` nếu cần chọn cover thủ công/sắp thứ tự
- 🟠 (tùy) Edge batch-sign nếu gallery nhiều ảnh gây waterfall
- 🟠 smoke mobile viewport hẹp · favicon 404 (nợ vặt pre-existing)
- (kế thừa) 🟠 Parent Dashboard/Radar/AI Review THẬT · 🟠 Phương án B RPC `get_child_journey_service` · 🟠 rename `kidJourneyModel.ts` · 🟠 enrichment `child_journey` · 🔴 Coloring schema · 🔴 Moment media taxonomy

---

*V84 đóng sổ. Audit-only, 0 code, 0 DB. Quyết định: giữ timeline V74–V83 nguyên vẹn, defer filter/month-nav tới ngưỡng revisit. Guard chuỗi V69→V83 giữ nguyên.*
