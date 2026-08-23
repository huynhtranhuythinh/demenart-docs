# DMA_HANDOFF_v89.md
**Sprint:** V89 — Retire Legacy Moments Routes & Close Governance Bypass (2 tầng)
**Ngày:** 2026-07-10 18:42 GMT+7 (Asia/Ho_Chi_Minh)
**Vai trò:** ChatGPT = CTO Advisor · Claude = PM + Prompt Operator + Builder · Lovable = build
**Trạng thái:** ✅ ĐÓNG SỔ — **Edge verify PASS + frontend/regression smoke PASS (ảnh thật)** · +0 bảng/definer/policy/cron · +0 migration · 0 xoá data · CTO chốt Lối A + PART B (siết backend draft-only).
**File code bị đụng:** Edge `upload_media` v13→**v14** (1 block nhánh A) · Frontend **7 file** (agent-mode, 3 commit): `teacher.moments.tsx`, `school.moments.tsx` (→redirect) · `MomentsView.tsx` (**XOÁ**) · `teacher.tsx`, `school.tsx` (gỡ nav) · `teacher.index.tsx`, `school.index.tsx` (đổi link).
**Commit UI:** `880308d` → `104d50d` → `a3a7bfc`. Deploy: `demenart.com` (production, auto Lovable→GitHub→Cloudflare) + Edge deploy trực tiếp Supabase.

---

## 0. TL;DR

V89 đóng **governance bypass 2 TẦNG** mà V88 backlog + V89 audit (D220→D221) phát hiện: legacy `/teacher/moments`+`/school/moments` (component `MomentsView`) cho nhân sự same-school gắn ảnh vào moment **approved** — bypass đường canonical Session `draft→submit_session_journal→approved`. CTO chặn "đóng sổ chỉ bằng gỡ route frontend" → bắt buộc đóng **cả** frontend surface **lẫn** backend write-path.

- **PART A — retire frontend:** gỡ 2 route legacy (→redirect an toàn), gỡ nav, đổi dashboard link, xoá `MomentsView`.
- **PART B — siết backend draft-only:** `upload_media` nhánh A (ảnh trẻ) reject upload nếu `moment_state !== 'draft'` (reuse state gate D220, 0 migration).
- **⭐ Endpoint sau V89:** RULES **D221** · SYSTEM_MAP **v0.82** · Handoff **v89**.
- **Inventory 63/106/155/1 + An 6/2/6 KHÔNG đổi.**

---

## 1. Canonical đã đọc — endpoint verify (đầu phiên)

Topic V89 mở mới. **KHÔNG dựa memory** — đọc canonical thật trên đĩa: `DMA_HANDOFF_v88.md` · `DMA_00_START_HERE.md` · `DMA_RULES.md` · `DMA_SYSTEM_MAP.md`.
**Endpoint đầu phiên (LIVE đĩa):** RULES **D220** · SYSTEM_MAP **v0.81** · Handoff **v88** — khớp brief cả 3 ✔ · **0 drift đĩa**.
**Inventory LIVE:** **63 bảng · 106 definer · 155 policy · 1 cron** — khớp. **Parent baseline An = 6/2/6** (data-level) — khớp.

---

## 2. C1 — Audit LIVE (read-only) — bằng chứng bypass

**Bề mặt legacy:** `teacher.moments.tsx` + `school.moments.tsx` = wrapper mỏng trỏ chung `MomentsView` (import bởi đúng 2 route).
**Hành vi `MomentsView`:** list **mọi** `learning_moments` (`select id,caption,state,class_id order by created_at desc` — **0 lọc draft**), mỗi card `upload_media(moment_id)`; nút Tải ảnh **không** disable theo state → gắn ảnh vào moment **approved** thành công.
**Gate backend `check_media_upload_access` (SECURITY DEFINER):** kiểm moment tồn tại + viewer **same-school**; trả `moment_state` **nhưng KHÔNG chặn theo state** → bypass THẬT ở cả backend.
**Canonical thay thế:** Session PhotoTab (multi-media vào draft → submit) thay thế đủ + chặt hơn (tag/caption/draft-discipline). Legacy 0 phụ thuộc DB/RPC/Edge (route = frontend thuần; `upload_media`/`check_media_upload_access` dùng chung Session → giữ).
**Reference sweep:** ngoài 2 nav (`teacher.tsx`/`school.tsx`), link legacy còn ở `teacher.index.tsx` (QuickActions + EmptyToday) và `school.index.tsx` (MomentsSection "Xem tất cả" + SuggestionsSection card). `teacher.session.$id.tsx` chỉ trỏ `/teacher` — **0 link legacy**.

---

## 3. C2 — Quyết định (CTO chốt Lối A + bắt buộc PART B)

CTO duyệt **A (retire hoàn toàn)** + **thêm PART B**: "Do not close V89 as Governance Closure using frontend route removal alone." Bypass thật cũng ở backend (`check_media_upload_access` không enforce draft-only). Đóng **2 tầng**.

**PART B audit gate (trước sửa, 4/4 ✅):** (1) caller nhánh moment của `upload_media` = chỉ `MomentsView` (retire) + PhotoTab; (2) PhotoTab luôn `insert learning_moments` (default `state='draft'` NOT NULL) → moment mới rồi upload, không reuse (kể cả "Gửi lại nhật ký"); (3) 0 workflow hợp lệ gắn media vào approved; (4) guard trong `if(momentId){}` → nhánh session/drive/curriculum không đụng. **Edge-only authoritative** vì `media_assets` RLS bật + 0 write-policy frontend → mọi write qua Edge → **0 migration**.

---

## 4. PART B — Edge `upload_media` v13→v14 (deployed)

Chèn 1 block trong **nhánh A (ảnh trẻ) DUY NHẤT**, sau gate allowed:
```
if (v.moment_state !== "draft") {
  await svc.rpc("write_audit_log", { ...reason:"moment_not_editable", moment_state:v.moment_state... });
  return json({ allowed:false, reason:"moment_not_editable" }, 403);
}
```
Reuse `moment_state` `check_media_upload_access` **đã trả** (D220) → RPC + nhánh C/D/B **byte-identical**. `verify_jwt=false` giữ. Reason generic (không lộ approved cụ thể; audit log nội bộ ghi state).
**Verify gate-matrix (gọi thẳng RPC, không cần auth.uid()):** draft same-school→`allowed:true,state:draft`→**PASS** · approved same-school→`allowed:true,state:approved`→**REJECT moment_not_editable** · other-school→`allowed:false,wrong_school`→**REJECT (chưa tới guard)**.
**Rollback:** redeploy `upload_media` v13 (source cũ đã dump).

---

## 5. PART A — Frontend (agent-mode, 7 file, get_diff scope sạch 3 lượt)

- **Lượt 1 (`880308d`):** `teacher.moments.tsx`+`school.moments.tsx` → redirect stub (`useNavigate` + `toast("Khoảnh khắc hiện được tạo và gửi trong từng buổi học.")` → về `/teacher`|`/school`, `replace:true`); `MomentsView.tsx` **XOÁ** (`rg` xác nhận 0 consumer).
- **Lượt 2 (`104d50d`):** gỡ nav item "Khoảnh khắc" ở `teacher.tsx`+`school.tsx` (dùng chung desktop+mobile FLAT_ITEMS) + gỡ import `Camera` thừa.
- **Lượt 3 (`a3a7bfc`):** `teacher.index.tsx` (QuickActions gỡ shortcut "Khoảnh khắc" · EmptyToday link "Nhật ký bé" → `/teacher/journal`); `school.index.tsx` (MomentsSection gỡ "Xem tất cả" — **giữ** read-only highlights + `get_school_moments` · SuggestionsSection gỡ card "Gửi khoảnh khắc").
- typecheck pass mỗi lượt; `rg` xác nhận 0 link app còn trỏ route legacy (chỉ route tree + redirect stub). `teacher.session.$id.tsx` **KHÔNG đụng**. Deploy prod.
- **Redirect an toàn:** không loop (route con → layout index, index không trỏ ngược) · giữ auth (`_authenticated`) · 0 hardcode session id · không đẩy Teacher sang Parent/Kid.

---

## 6. Smoke PASS (ảnh thật production)

- **Teacher nav:** "CHƯƠNG TRÌNH & MEDIA" chỉ còn Giáo án + Học liệu — mất "Khoảnh khắc" ✔
- **School nav:** chỉ còn Học liệu + Kho của trường — mất "Khoảnh khắc" ✔
- **`/teacher/moments`** → về `/teacher` + toast ✔ · **`/school/moments`** → về `/school` Tổng quan + toast ✔ · không loop ✔
- **Teacher empty-state** "Nhật ký bé" → `/teacher/journal` (Nhật ký lớp học) ✔
- **School** "Khoảnh khắc nổi bật" read-only **vẫn hiện** (4 ảnh), mất "Xem tất cả" · SuggestionsSection còn 2 card ✔
- **PART B PASS:** GV Mỹ Linh PhotoTab → thêm ảnh → **tạo draft mới "2 ảnh"** (có × xoá draft, tag chưa gắn) upload OK ✔ · card approved "Bé làm workshop" = "Đã gửi tới ba mẹ", tag tick, **không có ×** (không sửa) ✔
- **Regression:** Kid `/kid` **An 6/2/6** + gallery 6 khoảnh khắc + audio + creations y cũ ✔ · Parent 6/2/6 (summary lib chung `summarizeChildJournal`) ✔ · V86 multi-select + V87 xoá-draft y cũ ✔

---

## 7. Non-negotiable giữ nguyên

`submit_session_journal` · `remove_moment_media_service` · `get_child_journal` · `get_kid_album_service` · `kid_gate` · `check_media_upload_access` RPC (chỉ reuse, KHÔNG sửa) · nhánh session-resource/drive/curriculum của `upload_media` · consent V72 · badge V73 · Parent UI · Kid UI · Session/PhotoTab workflow · summary/gallery logic. `/kid` namespace reserved. **0 signed_url RPC · 0 xoá data · 0 migration.**

---

## 8. Endpoint & backlog sau V89

**Endpoint:** RULES **D221** · SYSTEM_MAP **v0.82** · Handoff **v89**.

**Backlog:**
- 🟠 re-sync project library (D221 + v0.82 + v89).
- 🟠 lưu repo V89 (Edge `upload_media` v14 + 7 file frontend).
- ✅ **retire legacy moments ĐÓNG** · ✅ **governance bypass ĐÓNG (2 tầng: UI surface + backend write-path)**.
- 🟠 (tùy, NGOÀI V89) siết tuyệt đối: thêm draft-guard vào RPC `check_media_upload_access` (migration D92 3-block) — hiện **Edge-guard đã đủ** vì `media_assets` RLS chặn write trực tiếp; chỉ làm nếu tương lai mở đường write khác.
- 🟡 purge orphan draft moment (0 active media + 0 tag sau xoá ảnh cuối; inert).
- 🟠 (nợ taxonomy) `upload_media` nhánh A không set `source` (mig068).
- 🟠 (theo dõi) consent-filter album Kid (V88) ẩn moment fail consent — document khi pilot mở rộng.
- 🟠 (hoãn) filter chip / month-jump nav (D216) · timeline affordance "X ảnh" · migration `cover_media_id`/`sort_order` · **KHÔNG** Edge batch-sign.
- Nợ cũ: Parent Dashboard/Radar/AI Review THẬT · Phương án B RPC `get_child_journey_service` · rename `kidJourneyModel.ts` · enrichment `child_journey` · Coloring schema · Moment media taxonomy.

---

## 9. Rollback plan (V89)

- **PART B (Edge):** redeploy `upload_media` **v13** (source cũ dump verbatim) — bỏ guard draft-only; các nhánh khác đã byte-identical nên không lệch.
- **PART A (frontend):** revert về sha trước `880308d` (Lovable History) — khôi phục `MomentsView` + 2 route + nav + dashboard link. **Lưu ý:** revert PART A mà KHÔNG revert PART B thì `MomentsView` sống lại nhưng upload vào approved vẫn bị guard chặn (`moment_not_editable`) — an toàn.
- **Data:** 0 đụng (0 xoá/sửa moment/media).

---

## 10. Demo accounts

(`@demo.demenart.com` · `Test@123`): **PH KHM `ph.hung.kidshouse`** (bé An — ghép `/parent/kid` + PIN → `/kid`) · Master KHM `hieutruong.kidshouse` · **GV KHM `gv.linh.kidshouse`** (lead teacher, dùng smoke PART B) · GV KHM `gv.my.kidshouse` (temp) · PH KHM `ph.toan.kidshouse` (temp) · Master MNDM `hieutruong.demen` · GV MNDM `gv.han.demen` · PH MNDM `ph.thanh.demen`.
