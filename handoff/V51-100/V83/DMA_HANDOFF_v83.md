# DMA_HANDOFF_v83.md
**Sprint:** V83 — Parent Moment Detail Warmth
**Ngày:** 2026-07-09 22:23 GMT+7 (Asia/Ho_Chi_Minh)
**Vai trò:** ChatGPT = CTO Advisor · Claude = PM + Prompt Operator + Builder · Lovable = build
**Trạng thái:** ✅ ĐÓNG SỔ — copy-only · frontend-only · 1 file · 0 DB/RPC/Edge/migration · Nghiệm thu **21/21 PASS**
**File code bị đụng:** `src/routes/_authenticated/parent.journal.tsx` (copy-only). DB/RPC/Edge/migration: **NONE.**

---

## 0. TL;DR

V83 là **sprint copy/UX polish** (KHÔNG kiến trúc, KHÔNG data). Mục tiêu: lightbox/detail moment của `/parent/journal` "ấm" hơn — để PH cảm thấy *"mình đang nhìn con lớn lên qua nghệ thuật"*, không chỉ *"đang xem media"*.

- **C1 audit LIVE (read-only):** endpoint (D214/v0.75/v82) khớp đĩa · DB sống + code sống confirm gallery V80–V82 chạy đúng & sạch → **0 drift**.
- **C2 quyết định — CTO chốt Lối A:** warm **warmLine + conversation prompt** theo nhóm/riêng (`tagged_count`) + thêm **hint đa-ảnh** (`hasGallery`) trong lightbox. **GIỮ title** "Khoảnh khắc ở lớp" (timeline & lightbox) — KHÔNG type-aware title ở V83 (defer).
- **C3 build (agent "auto-app"):** 3 helper thuần + wire chỉ nhánh moment; 1 commit `f16a7f8c`, `get_diff` sạch, typecheck pass, deploy `a3c99f58`.
- **Nghiệm thu:** **21/21 PASS** qua ảnh thật (ma trận 4 tổ hợp nhóm/riêng × đa/1-ảnh). Console No Issues.

**⭐ Endpoint sau V83:** RULES **D215** · SYSTEM_MAP **v0.76** · Handoff **v83**.

---

## 1. Canonical đã đọc — endpoint verify (đầu phiên)

Topic V83 mới mở. **KHÔNG dựa memory**, đọc canonical thật trên đĩa:
- `DMA_00_START_HERE.md` · `DMA_RULES.md` · `DMA_SYSTEM_MAP.md` · `DMA_HANDOFF_v82.md`.

**Endpoint đầu phiên (verify LIVE trên đĩa):** RULES **D214** (D-rule cao nhất) · SYSTEM_MAP **v0.75** (header dòng 1) · Handoff **v82** — **khớp brief cả 3** ✔ · **0 drift đĩa** (khác V81 từng tụt phiên).

---

## 2. C1 — Audit DB sống + code sống (read-only, kết quả)

**DB (`xcvhacymrbhdhohyylyq`, Supabase MCP read-only):**
1. Summary An (`Nguyễn Hoàng An`, `d1000000-…-0041`): drawing **6** · recording **2** · moments-với-media-active **4** = **6/2/4** ✔ (kid_creations chỉ drawing+recording).
2. `f51039be-…-cd1f`: state=**approved** · caption=**null** · tagged **3** (An/Trần Thanh Bình/Lê Bảo Chi) · **2 media active** `image/jpeg` (cover `3ca6c3dd…e909` 29/6 → `b2d5d20a…b22c` 30/6) ⇒ mediaCount=2 · hasGallery=true · galleryItems.len=2 ✔
3. `get_child_journal`: SECURITY DEFINER · `search_path=""` · **0 field `signed_url`** (1 match duy nhất trong body = comment dòng 51) · grants = **authenticated + service_role + postgres** (0 anon/PUBLIC — D15) ✔
4. **Inventory:** **63 bảng · 105 definer · 155 policy · 1 cron** → khớp y hệt V82 → **0 DB drift** ✔

**Code sống `parent.journal.tsx`** (đọc live qua `Lovable:read_file`, đúng `createFileRoute("/_authenticated/parent/journal")`):
- `MomentRow` đủ 4 field gallery V79 (optional). Chuỗi polish V81 nguyên (`safeSelected` clamp · counter aria-live/aria-atomic/tabular-nums · tap-target `button h-8 px-1` · loading "Đang tải ảnh…").
- **Copy moment TRƯỚC V83 (static, không phân biệt nhóm/riêng):** timeline title & lightbox title đều hardcode "Khoảnh khắc ở lớp"; warmLine 1 câu chung ("Ba mẹ có thể cùng con nhìn lại khoảnh khắc này ở lớp."); prompt 1 câu chung ("Lúc đó con đang làm gì?…"); **0 hint đa-ảnh** dù `f51039be` có 2 ảnh. Creation (Tác phẩm/Âm thanh) đã có warmLine/prompt riêng.
- Kết luận: khoảng trống cảm xúc = moment nhóm vs riêng giống hệt nhau + multi-media không có lời mời xem thêm. Copy nằm inline hết trong 1 file → scope 1 file hợp lệ.

---

## 3. C2 — Quyết định warmth (CTO chốt Lối A)

3 lựa chọn trình CTO: **A** (giữ title, warm warmLine+prompt+hint) ★ · **B** (type-aware title lightbox) · **C** (audit-only). **CTO chốt A** — privacy badge đã phân biệt nhóm/riêng nên title không cần gánh thêm nghĩa; giữ rủi ro tối thiểu.

**Copy đã duyệt (dùng field sẵn có `tagged_count`/`galleryItems.length`):**
- **Nhóm (`(tagged_count??1)>1`):** warmLine *"Một lát cắt nhỏ trong giờ học — nơi con cùng các bạn khám phá và tạo nên kỷ niệm chung."* · prompt *"Con nhớ lúc này đang làm gì cùng các bạn không? Con thích khoảnh khắc nào nhất hôm đó?"*
- **Riêng (else):** warmLine *"Một khoảnh khắc nhỏ ghi lại cách con quan sát, thử sức và lớn lên ở lớp nghệ thuật."* · prompt *"Con muốn kể cho ba mẹ nghe điều gì đang diễn ra trong bức ảnh này không?"*
- **Hint đa-ảnh (`hasGallery`, chỉ lightbox):** *"Khoảnh khắc này có nhiều ảnh — ba mẹ chạm vào các chấm để xem thêm."*

Ngưỡng nhóm/riêng **khớp `MomentPrivacyBadge`** (1 nguồn sự thật). Hint gate `hasGallery` **độc lập** nhóm/riêng.

---

## 4. C3 — Thay đổi code (copy-only, 1 file)

`src/routes/_authenticated/parent.journal.tsx` — 3 hunk:
1. **+3 helper** (module scope, trên `ParentJournalLightbox`): `getMomentWarmLine(taggedCount)` · `getMomentConversationPrompt(taggedCount)` · hằng `MOMENT_GALLERY_HINT`.
2. **+block hint** trong lightbox, dưới warmLine, gate `hasGallery`:
   `{hasGallery && (<p className="flex items-center gap-1.5 text-xs text-amber-600/80"><span aria-hidden="true">🖼️</span>{MOMENT_GALLERY_HINT}</p>)}`
3. **Wire call site moment** trong `CompactMomentLeaf`: `warmLine={getMomentWarmLine(moment.tagged_count)}` · `prompt={getMomentConversationPrompt(moment.tagged_count)}`. Title prop GIỮ "Khoảnh khắc ở lớp". Creation KHÔNG đụng.

**Build mode = AGENT ("auto-app"):** commit `f16a7f8c`, `get_diff` sạch (đúng 1 file, đúng 3 hunk, **KHÔNG `routeTree.gen.ts`**), typecheck pass, deploy 1 lần → `demenart.lovable.app` (deployment `a3c99f58`), credit 1.9.

**Bất biến:** 0 DB/RPC/Edge/Auth/RLS/migration · 0 npm · 0 signed_url ở RPC/adapter · 0 Edge batch-sign · 0 raw Bunny DOM · 0 backend field mới · 0 chip "2 ảnh" trên trục · 0 /parent home change · 0 timeline layout change · 0 Kid Portal · 0 hardcode `f51039be`. ≤1-item/creation **byte-identical V82**. Signing engine (cover seed từ `signedUrl` leaf · ký on-demand từng item · `knownRef` chống ký trùng · cache mediaId · consent D204 per-media) KHÔNG đụng.

---

## 5. Nghiệm thu — ma trận 21/21 PASS (ảnh thật)

Login PH `ph.hung.kidshouse@demo.demenart.com` / `Test@123`, con **An**:

| Case | Moment | warmLine | prompt | hint 🖼️ | title | Kết quả |
|---|---|---|---|---|---|---|
| Nhóm + đa-ảnh | `f51039be` (29/6, Ảnh chung nhiều bé, 2 ảnh) | nhóm | nhóm | **CÓ** | "Khoảnh khắc ở lớp" | ✔ counter 1/2→2/2 ký on-demand |
| Nhóm + 1-ảnh | "Bé chăm chú xem" (29/6) | nhóm | nhóm | không | "Khoảnh khắc ở lớp" | ✔ 0 dots/counter |
| Nhóm + 1-ảnh | "Hình ảnh thử nghiệm" (28/6) | nhóm | nhóm | không | "Khoảnh khắc ở lớp" | ✔ |
| Riêng + 1-ảnh | "An chăm chú lắng nghe…" (26/6, 🔒 Riêng gia đình) | riêng | riêng | không | "Khoảnh khắc ở lớp" | ✔ |

Ngoài ma trận: `/parent` summary **6/2/4** + home không đổi · `/parent/journal` timeline y hệt, **0 chip "2 ảnh"** trên trục · switch 1→2→1 chạy · single-media/creation không đổi · **Console No Issues** · 0 raw Bunny (signed URL `media.demenart.com`) · badge "Riêng gia đình"/"Ảnh chung nhiều bé" đúng → consent V72 + dedup V73 nguyên.

**Bài học D3:** dù nhánh riêng chỉ là hằng đối của cùng ternary đã proven ở nhánh nhóm, VẪN yêu cầu ảnh thật mở lightbox moment "Riêng gia đình" trước khi tick pass — nghiệm thu theo **ma trận tổ hợp quan sát được**, không suy luận đối xứng.

---

## 6. Rollback

Revert commit `f16a7f8c` (hoặc gỡ 3 hunk). Frontend additive/copy-only → 0 DB/Edge/migration, gỡ vô hại, trở về V82.

---

## 7. Endpoint & Backlog sau V83

**Endpoint:** RULES **D215** · SYSTEM_MAP **v0.76** · Handoff **v83**.

**Backlog:**
- 🟠 re-sync project library (RULES D215 + SYSTEM_MAP v0.76) · lưu repo V83
- 🟠 (tùy) type-aware title lightbox nhóm/riêng nếu sau muốn ấm hơn (đã defer V83 theo Lối A)
- 🟠 (hoãn) timeline affordance "X ảnh" khi n≥2 moment gallery HOẶC user-testing PH miss gallery (nguyên từ D213/D214)
- 🟠 (tùy) migration `cover_media_id`/`sort_order` nếu cần chọn cover thủ công/sắp thứ tự
- 🟠 (tùy) Edge batch-sign nếu gallery nhiều ảnh gây waterfall
- 🟠 smoke mobile viewport hẹp · favicon 404 (nợ vặt pre-existing)
- (kế thừa) 🟠 Parent Dashboard/Radar/AI Review THẬT · 🟠 Phương án B RPC `get_child_journey_service` · 🟠 rename `kidJourneyModel.ts` · 🟠 enrichment `child_journey` · 🔴 Coloring schema · 🔴 Moment media taxonomy

---

*V83 đóng sổ. Copy-only, reversible, 21/21 PASS. Guard chuỗi V69→V82 giữ nguyên.*
