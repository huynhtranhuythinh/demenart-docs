# DMA_HANDOFF_v91.md — V91: Teacher Upload Failure Recovery & Zero-Empty-Draft Guarantee

> **ĐÓNG 2026-07-10 GMT+7.** Endpoint: RULES **D223** · SYSTEM_MAP **v0.84** · Handoff **v91**.
> **Baseline cố định:** An **6/2/6** · Inventory **63 tables · 107 definer · 155 policies · 1 cron**.

---

## 1. Mục tiêu

Đảm bảo một lần Teacher multi-image upload KHÔNG BAO GIỜ để lại `learning_moment` draft rỗng (0 media) khi **tất cả** file upload thất bại. Đây là **đường sinh orphan THỨ 2** (D222 backlog) — khác đường V90 (deleted-media shell).

Chỉ xử đường all-upload-failed. KHÔNG redesign đường success/partial. KHÔNG retry queue / resumable / restore / media-manager.

---

## 2. C1 — Canonical + Live audit (zero-drift)

- Endpoint vào: RULES D222 · SYSTEM_MAP v0.83 · Handoff v90 — khớp, KHÔNG drift.
- Inventory vào: 63 tables · 106 definer · 155 policies · 1 cron.
- PhotoTab `onFile` order (live, D1): validate type/size (TRƯỚC) → INSERT `learning_moments` (draft, session_id+class_id+uploaded_by) → loop `upload_media` đếm `failCount` → nếu failCount>0 báo generic → `loadMoments()`. **Chỉ có failCount, không có successCount.**
- `upload_media` v14 nhánh A: `media_assets` INSERT chỉ chạy **sau** Bunny PUT thành công → mọi failure mode (type/size 400 · gate 403 · draft-guard 403 · bunny_put 502 · insert 500) tạo **0 media row** → total-failure = moment có đúng **0 total media**.
- `remove_moment_media_service` (V90): nhận `p_media_id`, bước 2 `NOT FOUND → media_not_found` → **không thể** xử moment 0-total-media (không media_id). Không hàm archive empty-draft nào tồn tại.
- FK trỏ learning_moments: `media_assets.linked_moment_id`=NO ACTION · `moment_children`+`kid_reactions`=CASCADE.
- Helper tái dùng: `current_profile`, `check_media_upload_access(moment,profile)`, `is_school_admin`, `is_session_lead(session)`, `is_session_teacher(session)`, `write_audit_log(action,fields)` — tất cả SECURITY DEFINER, verified.

---

## 3. C2/C3 — DB service (CTO-approved)

`public.archive_empty_draft_moment_service(p_moment_id uuid)` — migration `v91_archive_empty_draft_moment_service` (D92, DDL + REVOKE/GRANT).

**Đặc tả (CTO chỉnh so với đề xuất gốc):**
- SECURITY DEFINER · `SET search_path TO ''`.
- **CREATOR-ONLY:** `uploaded_by IS DISTINCT FROM v_profile` → `not_authorized`. Chỉ chính người tạo archive moment rỗng CỦA MÌNH (không phải admin cleanup tổng quát).
- **Collapse mọi authz-fail → generic `not_authorized`** (gồm `NOT FOUND` → không leak existence, chống enumeration).
- Authorize TRƯỚC lộ state: current_profile → lock FOR UPDATE → check_media_upload_access (same-school) → is_school_admin/lead/teacher → creator-check.
- Predicate empty-draft (SAU authz): `moment_not_draft` / `moment_has_media` (0 TOTAL media, không chỉ active) / `moment_has_tags` / `moment_has_caption`.
- Guarded UPDATE draft→archived recheck full predicate; ROW_COUNT<>1 → `archive_conflict`.
- Audit: `write_audit_log('archive_empty_draft_moment', {actor_id, entity_type:'learning_moment', entity_id, class_id, reason:'all_uploads_failed', metadata:{session_id, source:'photo_tab_total_upload_failure'}})`.
- Return `{ok:true, moment_id, state:'archived', archived:true}`.
- Grants: authenticated + service_role (0 anon/public, D15). **Definer 106→107.**

**Structural verify:** security_definer=true · search_path="" · grants {authenticated, service_role, postgres(owner)} · 0 PUBLIC/anon.

---

## 4. Safety matrix (10/10 PASS — JWT-claims impersonation)

Session a0002 (Mỹ Linh lead), debris `dead0091*` seed `session_replication_role=replica` (D85) → hard-delete sạch sau test, giữ 1 audit proof.

| # | Case | Kết quả |
|---|---|---|
| 1 | Creator + own empty draft | `ok:true, archived:true` |
| 2 | Có media | `moment_has_media` |
| 3 | Có tag | `moment_has_tags` |
| 4 | Caption non-blank | `moment_has_caption` |
| 5 | Approved (non-draft) | `moment_not_draft` |
| 6 | Khác creator (same school/session) | `not_authorized` |
| 7 | Wrong school | `not_authorized` |
| 8 | UUID không tồn tại | `not_authorized` (no leak) |
| 9 | Unauthenticated | `not_authenticated` |
| 10 | Repeat sau archive | `moment_not_draft` |

---

## 5. C4 — Frontend (`teacher.session.$id.tsx` / `onFile`)

Agent-mode, commit `f9e1590b`, get_diff 1-file (routeTree.gen.ts vắng), typecheck pass, deploy prod `demenart.lovable.app` (deployment 9866c712).

- Thêm `successCount` (`else successCount++`), giữ `failCount`.
- **Case A** `successCount>0`: giữ moment draft; `failCount>0` → warning partial cũ. (đường success/partial NGUYÊN VẸN)
- **Case B** `successCount===0`: `supabase.rpc("archive_empty_draft_moment_service",{p_moment_id:mom.id})`.
  - ok:true → "Không ảnh nào tải lên được. Khoảnh khắc chưa được tạo."
  - ok:false / error → "Không ảnh nào tải lên được. Hệ thống chưa thể hoàn tất thao tác, vui lòng thử lại." + `console.error` (KHÔNG giả vờ dọn thành công).
- `loadMoments()` cuối mọi case. Validation type/size GIỮ trước INSERT. KHÔNG hard-delete / auto-retry / resumable / queue.

---

## 6. Nghiệm thu LIVE (mạnh hơn smoke JWT)

GV Mỹ Linh thao tác thật qua browser, 21:54 GMT+7. DevTools Request-blocking URLPattern `https://xcvhacymrbhdhohyylyq.supabase.co/functions/v1/upload_media`, giữ **No throttling**.

- `learning_moments` INSERT 200 OK + `upload_media` blocked ("1 affected") → successCount=0.
- UI: "Không ảnh nào tải lên được. Khoảnh khắc chưa được tạo." · 0 card rỗng.
- DB: moment `e5f93993` = **archived · 0 media · 0 tags · blank caption** · uploaded_by Mỹ Linh.
- Audit: `archive_empty_draft_moment` · reason `all_uploads_failed` · session a0001 · **source `photo_tab_total_upload_failure`** · actor `d1…011`.

**Ghi chú smoke:** Offline-all SAI (fail INSERT trước nhánh V91 → guard `mErr` cũ). Phải chặn RIÊNG `upload_media` giữ online. URLPattern KHÔNG nhận `*wildcard*`. Chặn tầng network (supabase-js chốt fetch lúc init).

---

## 7. Cleanup + Regression

- **b2ce6685** (An smoke debris, approved, ảnh screenshot "Test hình ảnh 3/3", đẩy An 6→7): CTO **Chọn A** → hard-delete scoped FK-safe (media 3 → tag 2 → moment 1, guarded DO block RAISE-rollback nếu lệch, WHERE id+caption+uploaded_by+session). Verify: b2ce6685 gone · 3 media gone · **An về 6/2/6** · siblings `c6fc98e8`/`c7fe22f4`/`f51039be` NGUYÊN.
- **Bunny test-storage orphan backlog** (KHÔNG xoá — V91 không tạo storage-delete path): zone `dma-private`
  - `/moments/b2ce6685-e66b-433b-a3ae-6de259ad067e/3a821761-c70a-4bfa-a73d-4d3ee84ef640.jpg`
  - `/moments/b2ce6685-e66b-433b-a3ae-6de259ad067e/83573d99-77a4-4907-b834-80c78acf33c8.jpg`
  - `/moments/b2ce6685-e66b-433b-a3ae-6de259ad067e/fa1efdf0-cad6-4514-9ec3-0347d24b400a.jpg`
- **Regression PASS:** An **6/2/6** · `empty_draft_orphans=0` · Inventory **63/107/155/1** · state 11 approved + 6 archived + 1 draft = 18 (archived ĐỘNG +1 = e5f93993 inert, KHÔNG regression). Parent/Kid UI 0 đụng.

---

## 8. Non-negotiable giữ

`submit_session_journal` · `remove_moment_media_service` (V90, KHÔNG đụng) · `get_child_journal` · `get_kid_album_service` · `get_school_moments` · `get_session_moments` · `kid_gate` · `upload_media` (KHÔNG đụng) · consent V72 · badge V73 · Parent/Kid/Teacher UI · summary/gallery logic · `/kid` namespace. **0 cron · 0 recycle bin · 0 media-manager · 0 fake success · 0 hard-delete approved (trừ b2ce6685 CTO-duyệt một-lần).**

---

## 9. Rollback

- **DB:** `DROP FUNCTION IF EXISTS public.archive_empty_draft_moment_service(uuid);` (hàm mới hoàn toàn → 0 data đụng, definer 107→106).
- **Frontend:** revert `onFile` về sha trước `f9e1590b` (Lovable History).
- Reversible hoàn toàn, không mất data.

---

## 10. Backlog sau V91

- 🟠 re-sync project library (RULES D223 + SYSTEM_MAP v0.84 + HANDOFF v91).
- 🟠 lưu repo V91 (1 mig `v91_archive_empty_draft_moment_service` + `onFile`).
- ✅ **orphan đường-sinh-2 (partial-fail 0-total-media) ĐÓNG.**
- 🟠 (mới) **Bunny test-storage orphan** `/moments/b2ce6685/*` (3 object) — cần retention/storage-delete path riêng tương lai (KHÔNG làm trong V91).
- 🟢 lifecycle purge THẬT (archived + retention + admin + backup → hard-delete media→moment theo FK; tương lai, cần retention policy + CTO duyệt).
- nợ cũ: upload_media source mig068 · consent-filter Kid · filter/month-nav · timeline "X ảnh" · cover_media_id/sort_order · KHÔNG Edge batch-sign · Parent Dashboard/Radar/AI Review THẬT · Phương án B RPC `get_child_journey_service` · rename `kidJourneyModel.ts` · enrichment `child_journey` · Coloring schema · Moment media taxonomy.

---

## 11. Demo accounts

(`@demo.demenart.com` · `Test@123`): GV KHM **`gv.linh.kidshouse`** (Đặng Mỹ Linh, lead, profile `d1…011`, user_id `fd9322e1…af1b` — dùng smoke V91) · GV KHM `gv.my.kidshouse` (assistant `d1…014`) · GV MNDM `gv.han.demen` (lead khác trường `d2…011`) · PH KHM `ph.hung.kidshouse` (bé An `d1…041`) · Master KHM `hieutruong.kidshouse` · Master MNDM `hieutruong.demen` · GV MNDM `gv.han.demen` · PH MNDM `ph.thanh.demen` · PH KHM `ph.toan.kidshouse` (temp).
