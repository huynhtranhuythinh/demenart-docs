# DMA_HANDOFF_v86.md
**Sprint:** V86 — Teacher Multi-media Moment Upload MVP (+ V86B compact card · V86C responsive 2-up grid)
**Ngày:** 2026-07-10 12:45 GMT+7 (Asia/Ho_Chi_Minh)
**Vai trò:** ChatGPT = CTO Advisor · Claude = PM + Prompt Operator + Builder · Lovable = build
**Trạng thái:** ✅ ĐÓNG SỔ — **IMPLEMENTATION PASS** · frontend-only · **1 file** · **0 DB/RPC/Edge/migration** · **0 Parent code** · Acceptance **22/22 PASS** · CTO chốt đóng.
**File code bị đụng:** **`src/routes/_authenticated/teacher.session.$id.tsx`** (duy nhất, chỉ trong `PhotoTab`). DB/RPC/Edge/migration: **NONE.**
**Commits:** `8a18994` (V86 core) → `0924b9e` (V86B compact card) → `e6534a66` (V86C grid). Deploy: `https://demenart.lovable.app`.

---

## 0. TL;DR

V86 biến ý tưởng của V85-audit thành hiện thực: **cho Giáo viên tạo 1 `learning_moment` với NHIỀU ảnh qua một workflow thật**, để Parent gallery (V80/V81) có nội dung sinh ra từ tay GV — không còn phụ thuộc moment đường-vòng `f51039be`.

- **C1 audit LIVE (read-only):** endpoint (D217/v0.78/v85) khớp đĩa **0 drift** · inventory **63/105/155/1** · An **6/2/4** (trước build) · `f51039be` 2 media · RPC 0 signed_url · grants sạch · schema no cover/sort · `media_assets.state='active'`. PhotoTab `onFile` = single-file. → **V86 frontend-only khả thi 100%.**
- **C3 build (Flow A + no-cleanup):** input `multiple` + state `progress` + `onFile` viết lại (validate hết → **1 INSERT moment** → loop `upload_media` cùng `moment_id` → giữ moment on partial-fail) + nút "Đang tải k/N ảnh…" + card chip "N ảnh".
- **C4 smoke PASS 22/22** — bằng chứng thật: GV Mỹ Linh upload 3 ảnh → 1 card → publish → PH thấy lightbox 1/3.
- **V86B — compact multi-media card:** cover compact + `MomentCover` + thumbnail strip + chip (chỉ PhotoTab).
- **V86C — responsive grid + audit delete:** 2 card/hàng (rộng), 1/hàng (hẹp); **per-image delete = BLOCKER → V87.**
- **⭐ BASELINE: An 6/2/4 → 6/2/5** (publish moment thật `c6fc98e8` gắn An) — **mong đợi, chấp nhận, KHÔNG regression.** CTO chốt **GIỮ, không rollback.** 6/2/4 lỗi thời sau V86.

**⭐ Endpoint sau V86:** RULES **D218** · SYSTEM_MAP **v0.79** · Handoff **v86**.

---

## 1. Canonical đã đọc — endpoint verify (đầu phiên)

Topic V86 mới mở. **KHÔNG dựa memory**, đọc canonical thật trên đĩa: `DMA_HANDOFF_v85.md` · `DMA_00_START_HERE.md` · `DMA_RULES.md` · `DMA_SYSTEM_MAP.md`.

**Endpoint đầu phiên (verify LIVE trên đĩa):** RULES **D217** (D-rule cao nhất) · SYSTEM_MAP **v0.78** (header dòng 1) · Handoff **v85** — **khớp brief cả 3** ✔ · **0 drift đĩa**.

---

## 2. C1 — Audit LIVE (read-only, kết quả)

**DB (`xcvhacymrbhdhohyylyq`, Supabase MCP read-only):**
1. **Inventory = V85 y hệt → 0 DB drift:** **63 bảng · 105 definer · 155 policy · 1 cron.**
2. Summary An (`d1…041`, Nguyễn Hoàng An) trước build: drawing **6** · recording **2** · moments-có-media-active **4** = **6/2/4** ✔.
3. `f51039be`: approved · caption=null · tagged **3** · **2 media active** ✔. Multi-media moment **n=1 toàn hệ**. Phân bố media/moment: **0→3 · 1→7 · 2→1**.
4. `get_child_journal`: SECURITY DEFINER · `search_path=""` · **0 field signed_url** (1 match = comment) · gallery fields đủ · grants **authenticated + service_role + postgres** (0 anon — D15).
5. Schema: `learning_moments` **KHÔNG** `cover_media_id`/`sort_order` · `media_assets` dùng cột **`state`** (default `active`, KHÔNG `is_active`) · `kid_creations` KHÔNG `is_active`.

**Code sống (Lovable `read_file`):**
- `createFileRoute("/_authenticated/teacher/session/$id")` khớp file (D117). `PhotoTab` **inline trong file này** (không component tách rời).
- `onFile` = single-file: `files[0]`, input **KHÔNG `multiple`**; mỗi ảnh → INSERT 1 `learning_moments` (draft) + 1 `upload_media`; card render `media[0]`; tag/caption per-card SAU upload.
- `loadMoments` ký sẵn URL cho **mọi** media của moment (`urls[media_id]`) → thumbnail strip an toàn dùng được (dùng ở V86B).

**Kết luận C1:** mọi plumbing đã đủ (`upload_media` nhận moment_id có sẵn · `get_session_moments` jsonb_agg KHÔNG LIMIT 1 · `submit_session_journal` publish · gallery enrich V79 · lightbox V80/V81). **V86 frontend-only — KHÔNG cần DB/RPC/Edge/migration.**

---

## 3. C2 — Kế hoạch (A1 + no-cleanup, CTO duyệt)

1 file `teacher.session.$id.tsx`/PhotoTab. Quyết định chốt: **A1** (giữ tag/caption per-card sau upload — multi-select tạo 1 moment nên "tag once" tự nhiên) + **no-cleanup** (không thêm đường delete; moment rỗng vô hại vì StepReview lọc `media.length>0`).

---

## 4. C3 — Build (V86 core, commit `8a18994`)

Thay đổi trong `PhotoTab`:
1. Input ảnh thêm `multiple` (giữ `accept` 3 định dạng).
2. State `progress: {done,total}|null`.
3. `onFile` viết lại: `Array.from(e.target.files)` → validate MỌI file (IMG_OK/IMG_MAX), lỗi bất kỳ → dừng trước khi tạo gì; require `meta.class_id`; **INSERT đúng 1 `learning_moments` draft**; **loop tuần tự `upload_media` cùng `moment_id`**, đếm `failCount`, cập nhật `progress`; lỗi một phần → giữ moment + media đã lên + cảnh báo "Một số ảnh chưa tải lên được. Vui lòng thử lại." (**no-cleanup**); luôn `loadMoments()` cuối.
4. Nút upload: `Đang tải ${done}/${total} ảnh…`.
5. Card: chip **"N ảnh"** overlay khi `media.length>1` (chỉ PhotoTab).

`get_diff` = **1 file, `routeTree.gen.ts` vắng mặt**, typecheck sạch (`tsgo --noEmit`).

---

## 5. C4 — Smoke PASS 22/22 (bằng chứng thật + DB)

**Ảnh thật (GV Mỹ Linh `gv.linh.kidshouse@demo.demenart.com` / `Test@123`):** upload 3 ảnh → progress `1/3` → **1 card + chip "3 ảnh"** → tag 3 bé + caption → giữ draft (Bước 3) → `submit_session_journal` publish → PH (bé An) thấy timeline + **lightbox 1/3** dots/counter.

**DB chứng minh:** moment **`c6fc98e8-5d5f-4e65-9c2a-0234c4a6e9de`** = **1 learning_moment** · **3 media_assets active** · **`distinct_moment_link=1`** (cả 3 cùng `moment_id`) · tagged An/Bình/Chi **mỗi bé 1 lần** (`max_tag_per_child=1`) · **state approved** · uploaded_by …011. `f51039be` giữ **2 media**. Multi-media moment tổng **1→2**.

**Acceptance 22/22 PASS:** endpoint verified (#1) · 0 drift (#2) · frontend-only (#3) · 1-ảnh vẫn chạy (#4) · multi-select (#5) · 1 draft (#6) · N media cùng moment_id (#7) · tag 1 lần (#8) · draft tới submit (#9) · publish (#10) · Parent gallery tiêu thụ (#11) · 0 DB/RPC/Edge (#12) · 0 Parent UI (#13) · 0 signed_url RPC (#14) · 0 adapter-sign (#15) · 0 batch-sign (#16) · consent V72 (#17) · badge V73 (#18) · 0 raw Bunny (#19) · 0 console/network error (#20) · file reported (#21) · rollback rõ (#22).

---

## 6. V86B — Compact multi-media card (commit `0924b9e`, UI-only)

- Cover compact `h-48 sm:h-64 object-cover overflow-hidden` (bỏ `aspect-video` full-width feed).
- Subcomponent **`MomentCover`**: spinner khi chưa có URL · `onError` → "Ảnh chưa xem được" · ảnh thường (tránh hộp beige khổng lồ).
- Dải **thumbnail 14×14** khi `media.length>1`: 4 ảnh, hoặc 3 + "+N" khi >4, hoặc text "N ảnh đã tải lên" khi chưa ký.
- Chip "N ảnh" giữ (chỉ PhotoTab). **1 card = 1 moment** tuyệt đối. Caption/tag/status copy nguyên vẹn.
- Smoke PASS (card 3-ảnh của `c6fc98e8` hiện cover + chip + 3 thumb).

---

## 7. V86C — Responsive grid + audit delete (commit `e6534a66`, UI-only)

- Wrapper danh sách card `space-y-4` → **`grid grid-cols-1 gap-4 lg:grid-cols-2 items-start`** → màn rộng **2 card/hàng**, hẹp/mobile **1/hàng**, `items-start` giữ card cao tự nhiên (cover nửa-rộng hết bị kéo ngang).
- `get_diff` tổng V86 core→HEAD = **1 file sạch, 0 drift** (reconcile D112).
- Smoke PASS: Teacher 2-up; Parent home **6/2/5** + hero + child selector; Parent journal + `c6fc98e8` gallery không đổi.

**C1 audit đường xoá media (read-only):** `media_assets` **RLS bật + 0 policy** → frontend `authenticated` KHÔNG UPDATE/DELETE trực tiếp. State đang dùng: `active`/`deleted`/`trashed`. Teacher chỉ gọi được `drive_trash(p_school_id, p_media_ids[], p_folder_ids[])` — **folder-scoped của Drive** (`refs_folder=true, refs_moment=false`), KHÔNG hiểu `linked_moment_id`. `drive_trash_media_service` chỉ `service_role`. **KHÔNG có RPC moment-scoped.**

**→ Per-image delete = BLOCKER. KHÔNG build trong V86.**

---

## 8. Baseline change (CTO chốt GIỮ)

An summary **6/2/4 → 6/2/5** do publish moment thật `c6fc98e8` (gắn An). **Mong đợi · chấp nhận · KHÔNG regression.** 6/2/4 **lỗi thời** sau V86. Phiên sau audit **kỳ vọng 6/2/5**. `c6fc98e8` là moment multi-media **ĐẦU TIÊN từ workflow GV sạch** (khác `f51039be` đường-vòng 2 người/2 ngày).

**Rollback SQL (archival, KHÔNG chạy):** unpublish `UPDATE public.learning_moments SET state='draft' WHERE id='c6fc98e8-…'`; hoặc xoá theo thứ tự FK `media_assets(linked_moment_id)` → `moment_children(moment_id)` → `learning_moments(id)`. (Không "sạch" tuyệt đối vì `submit_session_journal` đã ghi journey rows.)

---

## 9. V87 backlog — Teacher Media Soft Delete (đề xuất, chờ CTO)

- RPC SECURITY DEFINER **`remove_moment_media_service(p_moment_id, p_media_id)`**:
  - guard caller = nhân sự trường của moment (`moment_school_id` + same_school);
  - **CHỈ khi `moment.state='draft'`** (KHÔNG gỡ media khỏi moment đã approved — bảo vệ thứ PH đã thấy + consent);
  - **soft-delete `media_assets.state='deleted'`** scoped đúng moment_id;
  - **KHÔNG hard-delete Bunny** ở V87; **KHÔNG xoá learning_moment**; ảnh cuối bị gỡ → giữ draft + hiện "Chưa có ảnh".
- Migration **D92** 3-block + REVOKE anon/public + GRANT authenticated (D15).
- UI: icon thùng rác nhỏ góc thumbnail + confirm "Xoá ảnh này khỏi khoảnh khắc?" → `loadMoments()` cập nhật chip/placeholder.
- **Parent UI KHÔNG đổi.**

---

## 10. Rollback plan (V86)

Frontend-only, 3 commit độc lập trên 1 file. Revert từng lớp: `e6534a66` (V86C grid) → `0924b9e` (V86B card) → `8a18994` (core). **0 DB/RPC/Edge nên không có gì phía DB để revert.**

---

## 11. Endpoint & backlog sau V86

**Endpoint:** RULES **D218** · SYSTEM_MAP **v0.79** · Handoff **v86**.

**Backlog:**
- 🟠 re-sync project library (RULES D218 + SYSTEM_MAP v0.79 + HANDOFF v86).
- 🟠 lưu repo V86.
- 🟢 **V87 — Teacher Media Soft Delete** (`remove_moment_media_service`, D92, draft-only, school-scoped, `state='deleted'`, no hard-delete Bunny, no xoá moment, ảnh cuối→"Chưa có ảnh", Parent bất biến).
- 🟠 (nợ taxonomy) `upload_media` nhánh A KHÔNG set cột `source` (mig068).
- 🟠 (hoãn) filter chip / month-jump nav khi đạt ngưỡng revisit.
- 🟠 (hoãn) timeline affordance "X ảnh" khi n≥2 moment gallery.
- 🟠 (tùy) migration `cover_media_id`/`sort_order`.
- 🟠 (tùy) Edge batch-sign nếu waterfall ký lightbox chậm.
- Nợ cũ: Parent Dashboard/Radar/AI Review THẬT · Phương án B RPC `get_child_journey_service` · rename `kidJourneyModel.ts` · enrichment `child_journey` · Coloring schema · Moment media taxonomy.

---

## 12. Non-negotiable giữ nguyên

Do not break V74–V83 Parent timeline/lightbox · /parent V77 home · **baseline 6/2/5** (KHÔNG revert 6/2/4) · consent guard V72 · badge dedup V73 · KHÔNG signed_url trong RPC/adapter · KHÔNG batch-sign · KHÔNG raw Bunny · KHÔNG hardcode `f51039be`/`c6fc98e8` · **/kid namespace reserved** (5 portal: /admin · /school · /teacher · /parent · /kid).

**Demo accounts** (`@demo.demenart.com` · `Test@123`): PH KHM `ph.hung.kidshouse` · Master KHM `hieutruong.kidshouse` · **GV KHM `gv.linh.kidshouse`** · Master MNDM `hieutruong.demen` · GV MNDM `gv.han.demen` · PH MNDM `ph.thanh.demen`.
