# DMA_HANDOFF_v80.md
**Sprint:** V80 — Parent Lightbox Multi-media Gallery UI
**Ngày:** 2026-07-09 19:43 GMT+7 (Asia/Ho_Chi_Minh)
**Vai trò:** ChatGPT = CTO Advisor · Claude = PM + Prompt Operator + Builder · Lovable = build
**Trạng thái:** ✅ ĐÓNG SỔ — C3 UI gallery applied (PASTE mode) · smoke Jean PASS 8 ảnh · 18/18 acceptance PASS · CTO chốt PASS
**File code bị đụng:** 1 file — `src/routes/_authenticated/parent.journal.tsx` (UI gallery + vá a11y). DB/RPC/Edge/migration: **NONE.**

---

## 0. TL;DR

V80 là **Parent-lightbox UI sprint**: dùng `galleryItems[]` (data đã enrich ở V79/D211) để dựng **gallery THẬT chỉ trong `ParentJournalLightbox`**. Timeline vẫn 1 cover thumbnail như cũ; `/parent` home không đổi; **KHÔNG** badge số ảnh trên trục.

- **CTO chốt Lối A:** dots/pills + counter "1 / 2" (KHÔNG thumbnail rail ảnh — thumbnail ảnh buộc ký sẵn mọi item, phá "sign on demand").
- **C3 (frontend, 1 file):** `CompactMomentLeaf` truyền `galleryItems`; `ParentJournalLightbox` nhận `galleryItems?` optional. ≤1 item → **byte-identical V79**. >1 item → `selected`+cache, seed index0=cover `signedUrl` (0 re-sign), đổi dot ký **on-demand** Edge `get_signed_media_url`, cache theo mediaId, item lỗi soft-fallback không sập.
- **Vá phụ (CTO duyệt):** `DialogDescription` sr-only dọn warning a11y Radix (từ V71). 0 visual.
- **Build mode = PASTE** (Jean dán tay). Verify D3 bằng `read_file` live source khớp 100% + 8 ảnh smoke.
- **Nghiệm thu:** 18/18 acceptance PASS.

**⭐ Endpoint sau V80:** RULES **D212** · SYSTEM_MAP **v0.73** · Handoff **v80**.

---

## 1. Canonical đã đọc (Plan B — file thật)

Trước phiên: RULES **D211** · SYSTEM_MAP **v0.72** · Handoff **v79** (khớp brief, snapshot đĩa KHÔNG tụt phiên). Sau phiên: RULES **D212** · SYSTEM_MAP **v0.73** · Handoff **v80**.

---

## 2. C1 — Audit DB sống + code sống (read-only, kết quả)

**DB (live re-verify — RPC enrich V79 đã live đúng shape):**
1. `get_child_journal` nhánh moments: giữ `media_id`/`tagged_count` + `coverMediaId`/`mediaCount`/`hasGallery`/`galleryItems[]`. `galleryItems` ordered `created_at ASC`, mỗi item `{mediaId, fileType, createdAt, caption(←`metadata->>'caption'`), sortOrder:null}`. **0 signed_url.** SECURITY DEFINER, `search_path=''`. ✔
2. Shape 3 mẫu PASS: `f51039be` mediaCount=**2**/hasGallery=**true**/gallery len 2 ASC (`3ca6c3dd` 29/6 → `b2d5d20a` 30/6, cả 2 `image/jpeg`)/coverMediaId=`3ca6c3dd`=media_id ✔ · single (`ee2f63fd`)=1/false/len1 · no-media (`…00a2`)=0/false/`[]`/media_id=null/coverMediaId=null.
3. Summary An = **6 / 2 / 4** (drawings 6 · recordings 2 · moments-với-media 4). An **có** tag trong `f51039be`. ✔
4. Grants: `authenticated` + `service_role` (+ owner `postgres`) — **0 anon/PUBLIC**. ✔
5. Consent 3 bé tag `f51039be` (An/Bình/Chi = …41/42/43): `group_moment_in_class=true`, chưa rút. ✔ → cả 2 media của moment ký được cho PH Hùng.

**Code sống `parent.journal.tsx`:** data path **passthrough thuần** (`get_child_journal` → `payload.moments ?? []` → `buildParentTimeline` inline, KHÔNG strip field → `galleryItems[]` tự chảy tới leaf ở runtime). `type MomentRow` đã có 4 field gallery optional (C3 V79). `CompactMomentLeaf` ký cover qua `MomentImage.onReady`→`signedUrl`, render `ParentJournalLightbox` với **1 `signedUrl`**. `ParentJournalLightbox` pure-presentational, chỉ nhận 1 URL, **chưa có khái niệm gallery**. `MomentImage` ký qua Edge `get_signed_media_url` (cơ chế ký tái dùng). → V80 chỉ cần bọc lớp gallery quanh engine ký sẵn, 0 DB/RPC/Edge.

---

## 3. C2 — Data path design (đã duyệt Lối A)

Cover đã ký sẵn ở leaf = `galleryItems[0]` (verified DB). Đường nhỏ nhất:
1. `CompactMomentLeaf` truyền `galleryItems={moment.galleryItems}` vào lightbox (metadata thuần, 0 ký).
2. `ParentJournalLightbox` nhận `galleryItems?`. `hasGallery=items.length>1` là switch DUY NHẤT. ≤1 → y hệt V79. >1 → `selected` state + cache `Record<mediaId,GallerySign>`, **seed index0 = cover `signedUrl`** (0 re-sign), counter "1/2" + dots.
3. Đổi dot → ký **on-demand** đúng Edge `get_signed_media_url` (consent D204 per-media tự chạy), cache theo mediaId. `knownRef:Set<mediaId>` chống ký trùng. Item lỗi → soft fallback riêng ô ảnh.

**CTO chốt A** (dots/pills + counter, KHÔNG thumbnail rail ảnh — thumbnail buộc pre-sign mọi item, phá "sign on demand").

---

## 4. C3 — Parent Lightbox Gallery UI (APPLY, paste mode)

`src/routes/_authenticated/parent.journal.tsx` — **1 file**, các thay đổi:
- Import: +`useRef` (react) · +`DialogDescription` (`@/components/ui/dialog`).
- `type GallerySign = {status:"ok";url} | {status:"loading"} | {status:"error"}`.
- `ParentJournalLightbox`: +prop `galleryItems?: MomentRow["galleryItems"]`; state `selected`+`cache`+`knownRef`; `useEffect([open])` reset selected=0; `useEffect([signedUrl,items.length])` seed cover; `selectItem(i)` ký on-demand + cache; UI 3 nhánh ảnh (gallery ok/loading/error vs single `<img>`) + rail counter+dots khi `hasGallery`; +`DialogDescription sr-only`.
- `CompactMomentLeaf`: +1 dòng `galleryItems={moment.galleryItems}` ở call site lightbox.

**Nguyên tắc an toàn:** cover = `galleryItems[0]` → seed cache 0 re-sign; ký on-demand item khi PH chọn (giữ D203/D204/D206/D211: 0 lift signed_url lên adapter/RPC, 0 Edge batch-sign, 0 raw Bunny); consent per-media tự sống; ≤1 item → byte-identical V79 (single/no-media an toàn tuyệt đối).

**Build mode = PASTE** (Jean dán tay, credit-saving). **Verify D3:** `read_file` live source sau paste khớp 100% (đúng 1 file, đủ marker, 0 đụng component khác — Lovable chỉ format lại vài dòng cosmetic). Paste mode **KHÔNG có agent commit SHA**.

**ROLLBACK C3:** revert block gallery + `DialogDescription` về V79 (frontend additive, gỡ vô hại, 0 DB/Edge/migration).

---

## 5. Nghiệm thu — smoke Jean PASS 8 ảnh, 18/18 acceptance

Login `ph.hung.kidshouse@demo.demenart.com` / `Test@123` (con An):
- **`/parent`:** summary **6/2/4** + hero "Chào ba mẹ của An" + hint mỗi stat + selector An/Khang nguyên → home không đổi. (AC 1,2)
- **`/parent/journal`:** timeline y hệt V79 · `f51039be` (29/6) 1-cover "Khoảnh khắc ở lớp"/"Ảnh chung nhiều bé"/caption null, **0 badge số ảnh trên trục**. (AC 3,4)
- **Lightbox `f51039be`:** mở ảnh 1 trước + counter "1/2" + 2 dots (AC 5,6-cover). Bấm dot 2 → ảnh đổi (ký on-demand) + "2/2" (AC 6-switch). Bấm về dot 1 → **tức thì** (cache, không ký lại) (AC 6-back). Chip/privacy badge/warmLine/"💬 Gợi ý trò chuyện"/Đóng giữ (AC 7).
- **Single-media** (tranh) y hệt cũ, 0 counter/dots (AC 8). **No-media** không sập (AC 9).
- **Console:** chỉ `favicon.ico 404` (đỏ, pre-existing) — sau vá `DialogDescription`, warning vàng Radix **đã hết**. 0 lỗi do V80 (AC 16). Ảnh phục vụ qua signed URL `media.demenart.com` — 0 raw Bunny (AC 13).
- AC 10-12,14-15 bằng audit C1 (RPC 0 signed_url · adapter passthrough · 0 Edge batch-sign · consent V72 per-media · badge dedup V73 không đụng).

**18/18 acceptance PASS. CTO chốt PASS.**

Việc treo (không chặn PASS): favicon 404 (nợ vặt pre-existing) · smoke mobile viewport hẹp (AC 17 — desktop OK, responsive class có sẵn nhưng chưa soi viewport hẹp).

---

## 6. Guard đã giữ trọn (V80)

DB: **0 thay đổi** (0 migration/RPC/Edge/schema/RLS/policy/data). 63 bảng · 105 definer · 155 policy · mig 001→105 · Edge 14 · cron 1 · 3 tenant KHÔNG đổi. Frontend: **1 file** (UI gallery + vá a11y). 0 signed_url ở RPC · 0 ký ở adapter · 0 Edge batch-sign · 0 raw Bunny DOM · 0 hardcode `f51039be` · 0 fake gallery · 0 pre-sign toàn bộ item. KHÔNG đụng `parent.index.tsx`/`kidJourneyModel.ts`/`kid.tsx`/`routeTree.gen.ts`. Guard chuỗi: summary V69(→6/2/4) · /kid lightbox V70 · Parent Lightbox V71 · consent V72 · badge dedup V73 · adapter V74 · compact spine V75 · detail V76 · home V77 · data foundation V78 · RPC enrich V79.

---

## 7. Backlog (chưa làm ở V80)

- 🟠 Lưu repo/backup V80 (`parent.journal.tsx` gallery diff).
- 🟠 Smoke mobile lightbox ở viewport hẹp (AC 17 — desktop đã PASS).
- 🟠 favicon 404 (nợ vặt pre-existing, tách backlog riêng).
- 🟠 (tùy) migration `cover_media_id`/`sort_order` chỉ khi cần chọn cover thủ công / sắp thứ tự (hiện cover=ảnh đầu created_at ASC, sortOrder=null).
- 🟠 (tùy) Edge batch-sign chỉ khi gallery nhiều ảnh gây waterfall (hiện 2 ảnh/moment, on-demand ổn).
- Nợ cũ: Parent Dashboard đầy đủ / Radar / AI Review THẬT · Phương án B RPC canonical `get_child_journey_service` (hợp nhất 2 path đọc journey kid/parent) · rename `kidJourneyModel.ts` · enrichment `child_journey` · Coloring JSON schema · Moment media source taxonomy.

**Endpoint sau V80:** RULES **D212** · SYSTEM_MAP **v0.73** · Handoff **v80**.
Production: https://demenart.lovable.app (build từ paste — paste mode không có agent deploy ID). Handoff/RULES/SYSTEM_MAP trước V80: v79 / D211 / v0.72.
