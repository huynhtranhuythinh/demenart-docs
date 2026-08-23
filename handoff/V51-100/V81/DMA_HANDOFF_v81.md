# DMA_HANDOFF_v81.md
**Sprint:** V81 — Gallery UX Polish + Multi-media Affordance Audit
**Ngày:** 2026-07-09 20:15 GMT+7 (Asia/Ho_Chi_Minh)
**Vai trò:** ChatGPT = CTO Advisor · Claude = PM + Prompt Operator + Builder · Lovable = build
**Trạng thái:** ✅ ĐÓNG SỔ — C3 Polish A (robustness + a11y) applied (AGENT mode "auto-áp") · smoke Jean PASS 7 ảnh · 17/17 acceptance PASS · CTO chốt PASS
**File code bị đụng:** 1 file — `src/routes/_authenticated/parent.journal.tsx` (lightbox-only polish, trong `ParentJournalLightbox`). DB/RPC/Edge/migration: **NONE.**

---

## 0. TL;DR

V81 là **polish/audit sprint** (KHÔNG kiến trúc): siết robustness + a11y cho gallery lightbox V80, và **audit** xem timeline có cần affordance đa-media nhỏ không. Kết luận audit: gallery V80 chạy đúng & sạch → **CHỈ polish lightbox**, **KHÔNG** thêm affordance timeline.

- **CTO chốt Lối 1 (Polish A):** 4 việc nhỏ, reversible, tất cả trong `ParentJournalLightbox`. **Lối B (chip "2 ảnh" trên trục) BỊ BÁC** — toàn hệ chỉ 1 moment gallery (`f51039be`) → chip hiện đúng 1 card, giá trị thấp + nhiễu; hoãn tới khi có nhiều moment ≥2 ảnh.
- **C3 (frontend, 1 file):** (1) guard `safeSelected` clamp index out-of-range; (2) `aria-live="polite"`+`aria-atomic`+`tabular-nums` cho counter (SR đọc "1/2","2/2"); (3) tap-target dots bọc `<button h-8 px-1>` quanh chấm (visual y hệt); (4) loading text "Đang tải ảnh…" nổi trên skeleton `absolute inset-0`, giữ khung `h-[45vh]` → 0 layout shift.
- **Build mode = AGENT** ("auto-áp"): 1 commit `f6b78c2a`, `get_diff` sạch (đúng 1 file, KHÔNG `routeTree.gen.ts`), typecheck pass, deploy 1 lần → `demenart.lovable.app`.
- **Nghiệm thu:** 17/17 acceptance PASS.

**⭐ Endpoint sau V81:** RULES **D213** · SYSTEM_MAP **v0.74** · Handoff **v81**.

---

## 1. Canonical đã đọc — ⚠️ DRIFT (D112) đã reconcile theo Lối A

**Topic mới:** đĩa ban đầu CHỈ có **v79 / D211 / v0.72** (thiếu `DMA_HANDOFF_v80.md`, RULES max D211, SYSTEM_MAP không có v0.73). V80 đóng sổ ở topic cũ nhưng 3 file canonical chưa được up lại.

**Xử lý (đúng D90/D112, KHÔNG dựng V80 từ memory):** audit **DB sống + code sống** làm nguồn sự thật → khớp y hệt mô tả V80 trong brief → brief đáng tin làm baseline. **CTO chốt Lối A:** up lại 3 file V80 thật (`DMA_HANDOFF_v80.md` + `DMA_RULES.md`@D212 + `DMA_SYSTEM_MAP.md`@v0.73) TRƯỚC khi đóng V81. Đã verify sau up: RULES **D212** · SYSTEM_MAP **v0.73** · Handoff **v80** ✔ → append V81 lên nền V80 thật.

**⚠️ Cảnh báo vận hành:** lần up lại project library từng **xoá mất** `DMA_RULES.md` (424 KB) + `DMA_SYSTEM_MAP.md` (233 KB) + toàn bộ handoff cũ v1–v79 + `DMA_G` (chỉ còn v80 handoff + base docs). Sau đó Jean re-up qua chat attachments → đủ 3 file. **Việc treo:** re-sync 2 file governance (RULES D213 + SYSTEM_MAP v0.74 sau phiên này) vào project library để đồng bộ.

Trước phiên (đĩa): v79/D211/v0.72. Sau reconcile: v80/D212/v0.73. Sau V81: **v81/D213/v0.74**.

---

## 2. C1 — Audit DB sống + code sống (read-only, kết quả)

**DB (live re-verify, project `xcvhacymrbhdhohyylyq`):**
1. `get_child_journal`: SECURITY DEFINER · `search_path=''` · grants = `authenticated` + `postgres` + `service_role` (**0 anon/PUBLIC**, D15). Nhánh moments **byte-exact V79**: `media_id`/`coverMediaId`/`mediaCount`/`hasGallery`(count>1)/`galleryItems[]` ordered `created_at ASC`. **0 signed_url** — 2 match "sign" trong body chỉ là `signal_count` (skills) + comment "0 signed_url" (vô hại). **V80 = 0 thay đổi DB.** ✔
2. `f51039be…cd1f`: state=approved · caption=null · tagged 3 (An/Bình/Chi) · **2 media active** → cover `3ca6c3dd…e909` (29/6) → `b2d5d20a…b22c` (30/6), cả 2 `image/jpeg` ⇒ mediaCount=2, hasGallery=true, galleryItems.len=2. ✔
3. Summary An (`Nguyễn Hoàng An`, `d1000000-…-0041`): drawing **6** · recording **2** · moments-với-media **4** = **6/2/4**. ✔ Phân bố 4 moment tag An: 3×(1 ảnh) + 1×(2 ảnh = `f51039be`) → sẵn ca test single + gallery.

**Code sống `parent.journal.tsx`** (1 file, chứa trọn V80):
- `type MomentRow` = 5 field gốc + 4 field gallery optional (V79). `buildParentTimeline` inline passthrough (0 ký, badge skip → dedup V73). `CompactMomentLeaf` timeline 1 cover, truyền `galleryItems` xuống lightbox, KHÔNG badge "X ảnh".
- `ParentJournalLightbox` (V80): `hasGallery=items.length>1`; render theo `cache[mediaId]`; counter "i/n" + dots; `selectItem` ký **on-demand** qua Edge `get_signed_media_url` (consent per-media chạy), cover seed sẵn từ `signedUrl` (0 re-sign), `knownRef` chống ký trùng, cache theo mediaId, reset về cover khi mở lại; single-media → `<img src={signedUrl}>`. **0 batch-sign · 0 raw Bunny.** ✔

---

## 3. C2 — Quyết định UX (CTO chốt Lối 1: Polish A · KHÔNG affordance timeline)

Audit lộ: gallery V80 **đủ tốt** (dots+counter rõ, active dot tương phản, soft-fallback mềm). 3 lối đề xuất → **CTO chốt Lối 1 (Polish A "robustness + a11y")**, gồm 4 việc nhỏ đều thuộc C3-cho-phép, reversible:
1. Guard `selectedIndex` out-of-range (clamp).
2. `aria-live` cho counter (SR đọc khi đổi ảnh).
3. Nới tap-target dots trên mobile (chấm nhìn y hệt).
4. Loading text "Đang tải ảnh…" khi ký ảnh thứ 2 (subtle, 0 layout shift).

**Lối B (timeline affordance "2 ảnh") BỊ BÁC:** toàn hệ chỉ 1 moment gallery → chip hiện đúng 1 card, giá trị thấp + thêm nhiễu; để dành tới khi có nhiều moment ≥2 ảnh. **Lối 2 (audit-only, 0 code) không chọn** vì 4 việc trên đáng làm.

---

## 4. C3 — Lightbox Polish (APPLY, agent mode)

`src/routes/_authenticated/parent.journal.tsx` — **1 file, 3 hunk, TẤT CẢ trong `ParentJournalLightbox`:**
- **Hunk 1 — clamp guard:** `const safeSelected = items.length === 0 ? 0 : Math.min(Math.max(selected, 0), items.length - 1);` → `currentItem` dùng `safeSelected`. Derived (clamp mọi render, 0 effect mới, 0 state churn); reopen vẫn về cover-0 qua `useEffect([open])` sẵn có.
- **Hunk 2 — loading text:** Skeleton chuyển `absolute inset-0`, thêm pill "Đang tải ảnh…" (dot `animate-pulse`) nổi giữa cùng khung `h-[45vh]` → KHÔNG đẩy layout.
- **Hunk 3 — counter a11y + tap-target:** counter `aria-live="polite"` + `aria-atomic="true"` + `tabular-nums`, dùng `safeSelected`. Dots: bọc `<button className="group flex h-8 items-center justify-center px-1">` quanh `<span>` chấm (span vẫn `h-2.5`, `w-5` active `bg-amber-500` / `w-2.5` inactive `bg-amber-300/70 group-hover:bg-amber-400` — **visual y hệt**). `aria-label={`Xem ảnh ${i+1} trên ${items.length}`}`, `aria-current`, `title`. Strip `pb-3 pt-1`→`pb-2 pt-0.5`, `gap-1.5`→`gap-0.5` để bù chiều cao.

**Nguyên tắc an toàn:** 0 data-fetch mới · 0 signing mới · ≤1 item byte-identical V80 · consent per-media/D204 nguyên · 0 hardcode `f51039be` · 0 raw Bunny (vẫn ký on-demand qua `get_signed_media_url`).

**Agent mode ("auto-áp"):** 1 commit `f6b78c2a` (`f6b78c2a8fbfaecf2075229f6203751a742f86ce`), `get_diff` sạch (đúng 1 file `parent.journal.tsx`, KHÔNG `routeTree.gen.ts`, đúng 3 hunk), typecheck pass, deploy 1 lần → `demenart.lovable.app` (deployment `06c46138`). Cost 2.1 credits.

**ROLLBACK C3:** revert 3 hunk (hoặc restore `parent.journal.tsx` về commit V80). Additive/reversible, 0 DB/Edge/migration.

---

## 5. Nghiệm thu — smoke Jean PASS 7 ảnh, 17/17 acceptance

Login `ph.hung.kidshouse@demo.demenart.com` / `Test@123` (con An):
- **`/parent`:** summary **6/2/4** + hero "Chào ba mẹ của An" + hint mỗi stat + selector An/Khang nguyên → home không đổi. (AC 1,2)
- **`/parent/journal`:** timeline y hệt V80 · **0 chip "2 ảnh"** trên trục · badge đúng: "🔒 Riêng gia đình" (1 bé) vs "Ảnh chung nhiều bé" (nhóm) → consent V72 + badge dedup V73 nguyên. (AC 3,12,13)
- **Lightbox `f51039be`:** mở ảnh 1 + counter "1 / 2" + pill active (amber dài) → bấm sang → "2 / 2" ảnh đổi (ký on-demand). Counter có `aria-live`; dots dễ chạm hơn (chấm y hệt). (AC 4,5)
- **Single-media** (group "Bé chăm chú xem", 29/6): **0 counter/dots** → render y hệt cũ. (AC 6). No-media không sập (AC 7).
- **Console:** chỉ `favicon.ico 404` (static, pre-existing, KHÔNG phải regression V81). 0 lỗi app. (AC 14)
- AC 8-11,15-16 bằng audit C1 + diff (0 signed_url RPC · 0 ký adapter · 0 Edge batch-sign · 0 raw Bunny DOM · mobile/desktop lightbox dùng được).

**17/17 acceptance PASS. CTO chốt PASS.**

---

## 6. Guard đã giữ trọn (V81)

DB: **0 thay đổi** (0 migration/RPC/Edge/schema/RLS/policy/data). 63 bảng · 105 definer · 155 policy · mig 001→105 · Edge 14 · cron 1 · 3 tenant KHÔNG đổi. Frontend: **1 file** (lightbox polish, 3 hunk trong `ParentJournalLightbox`). 0 signed_url RPC · 0 ký adapter · 0 Edge batch-sign · 0 raw Bunny DOM · 0 hardcode `f51039be` · 0 fake gallery · 0 pre-sign · 0 timeline affordance/badge · 0 đổi summary logic · 0 đổi signing architecture. KHÔNG đụng `parent.index.tsx`/`kidJourneyModel.ts`/`kid.tsx`/`routeTree.gen.ts`. Guard chuỗi: summary V69(6/2/4) · /kid lightbox V70 · Parent Lightbox V71 · consent V72 · badge dedup V73 · adapter V74 · compact spine V75 · detail V76 · home V77 · data foundation V78 · RPC enrich V79 · gallery UI V80.

---

## 7. Backlog (chưa làm ở V81)

- 🟠 **Re-sync project library:** up `DMA_RULES.md` (D213) + `DMA_SYSTEM_MAP.md` (v0.74) mới vào project knowledge (2 file governance từng bị mất khi re-upload — hiện chỉ có ở chat attachments).
- 🟠 Lưu repo/backup V81 (`parent.journal.tsx` polish diff, commit `f6b78c2a`).
- 🟠 Smoke mobile lightbox ở viewport hẹp (desktop đã PASS; tap-target đã nới).
- 🟠 favicon 404 (nợ vặt pre-existing, tách backlog riêng).
- 🟠 (hoãn) Timeline affordance "X ảnh" — chỉ làm khi có nhiều moment ≥2 ảnh (hiện n=1).
- 🟠 (tùy) migration `cover_media_id`/`sort_order` chỉ khi cần chọn cover thủ công / sắp thứ tự.
- 🟠 (tùy) Edge batch-sign chỉ khi gallery nhiều ảnh gây waterfall.
- Nợ cũ: Parent Dashboard đầy đủ / Radar / AI Review THẬT · Phương án B RPC canonical `get_child_journey_service` (hợp nhất 2 path đọc journey kid/parent) · rename `kidJourneyModel.ts` · enrichment `child_journey` · Coloring JSON schema · Moment media source taxonomy.

**Endpoint sau V81:** RULES **D213** · SYSTEM_MAP **v0.74** · Handoff **v81**.
Production: https://demenart.lovable.app (deploy `06c46138`, commit `f6b78c2a`). Handoff/RULES/SYSTEM_MAP trước V81: v80 / D212 / v0.73.
