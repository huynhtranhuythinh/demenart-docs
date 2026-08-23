# DMA_HANDOFF_v94.md — V94: "Thêm Kỷ vật ngoài DMA" / Parent Adds Memories

> **ĐÓNG 2026-07-11 GMT+7.**
> Endpoint: RULES **D226** · SYSTEM_MAP **v0.87** · Handoff **v94**.
> **Baseline:** An **6/2/6** · Inventory **67 tables · 117 definer · 155 policies · 1 cron** · spine parity pm=spine · 0 orphan pending_attach.
> Sprint: **1 migration** (+2 bảng, +6 RPC, 5 RPC patch, 3 policy replace) + **2 Edge** (v15/v21) + **5 commit frontend** (2 file mới + 6 file edit, agent-mode).
> Deploy prod: deployment `247dedcd` → demenart.lovable.app / demenart.com.

---

## 1. Mục tiêu

Kích hoạt **THÉP CHỜ #1** (`child_journey.source`): PH tự đặt kỷ vật nghệ thuật xảy ra **ngoài DMA** (buổi hòa nhạc, tranh vẽ ở nhà, video múa, ghi chú ba mẹ…) vào hành trình của con. Kỷ vật PH = first-class citizen trong **Dải hành trình** + **Nhật ký**, thuộc về gia đình — trường/GV **0 đường vào**.

**Tiêu chí thành công (CTO):** PH thêm được kỷ vật với flow "đặt một kỷ vật mới vào hành trình của con" (không phải upload form/admin CRUD/social post) → **ĐẠT** (nghiệm thu ảnh thật 17:31–17:58 + DB cross-check).

**KHÔNG làm trong V94:** billing · Capsule scoring · AI evaluation · Kid authoring · Teacher access · public sharing · notification · đếm kỷ vật PH vào summary 6/2/6.

---

## 2. C1 — Canonical + Live audit

- Endpoint vào: RULES **D225** · SYSTEM_MAP **v0.86** · Handoff **v93** — 0 drift. Inventory vào **65/111/155/1** · An 6/2/6 (UUID exact `d1000000-…041`).
- **Phát hiện quyết định:** `child_journey` có sẵn `source` (default 'demen') + `entry_type` + `ref_id` + `occurred_at` — pattern session dùng ref_id→lesson_sessions ⇒ spine dùng lại được. `kid_creations`/`learning_moments` KHÔNG tái dùng được (hẹp/gắn chết class). `upload_media` v14 = 4 nhánh, 0 nhánh Parent; `get_signed_media_url` v20 nhánh kid = mẫu cho parent.
- ⚠️ 3 policy `child_journey` của trường SELECT/INSERT/UPDATE mọi row trẻ trường mình → **phải vá** trong cùng migration.

## 3. C2 — Quyết định CTO (qua 4 vòng correction)

1. **Kiến trúc A′ Spine+Detail**: `parent_memories` + spine row `child_journey` (source='parent', entry_type='parent_memory', ref_id, occurred_at MIRROR) — atomic 1 RPC. **EXACT PAIR bất biến**; mixed pair không bao giờ surface.
2. **6 memory_type** (artwork·audio·photo_moment·performance·experience·note — video KHÔNG là type, chỉ là attachment) · **6 domain** nullable (visual_art·music·dance_movement·theatre_performance·storytelling·mixed).
3. Edit/archive/restore **creator-only** + re-run linked-parent; cả 2 PH view; no hard-delete; archive giữ spine+media+conversation (khoá qua parity), restore hồi phục.
4. **Immediate publish** — memory active ngay khi lưu info, hợp lệ 0 media; UI states saving/uploading/partial_success/saved là **UI-only**, KHÔNG DB draft.
5. Quota **500MB/bé** config `app_settings.parent_memory_quota_mb_per_child`; accounting = retained (`bunny_purged <> 'true'`, mọi state).
6. **Mapping `parent_memory_media`** (KHÔNG cột mới trên media_assets): UNIQUE(memory,media) + **UNIQUE(media_id)** + UNIQUE(memory,sort_order); sort monotonic từ MAX mọi mapping kể cả soft-deleted.
7. **Finalize service_role-ONLY**: lock pm FOR UPDATE → authz → **lock children row (serialize quota per-child)** → validate EXACT pending (`pending_attach='true'` text-compare) → limits ≤5/≤1 audio/≤1 video → quota → sort → mapping → clear pending → audit.
8. Failure cleanup Edge: `deleted + attach_failed + pending_purge` → best-effort Bunny delete → `bunny_purged=true`.
9. **Video V94 = MP4-only** ≤100MB, 1/memory, no autoplay; MOV/WebM reject copy "Video này chưa tương thích. Vui lòng chọn file MP4." → backlog **Media Compatibility Pipeline**.
10. Summary guard: kỷ vật PH KHÔNG đổi 6/2/6.

## 4. DB — migration `v94_parent_memories_domain` (đã apply, D92 3-block, header chứa 3 policy gốc để rollback)

- `parent_memories` + `parent_memory_media` — RLS bật **0 policy** + REVOKE; spine unique partial `(ref_id) WHERE exact-pair`; 3 policy trường replace (+`IS DISTINCT FROM` cả USING/WITH CHECK); CHECK `media_assets.source` +'parent'; seed quota.
- 6 RPC mới (grants: 5 public authenticated+service_role; finalize **CHỈ service_role**) + 5 patch (`get_child_journal` exact-pair + field `parent_memory{memory_id,memory_type,artistic_domain,title,story,mine,galleryItems[]}` · 4 RPC conversation V93 nhánh journey — **0 migration thêm cho conversation**).
- Authorize-trước-lộ-state giữ: generic `not_authorized` collapse not-found/wrong-child/wrong-family/state; business-reason (invalid_title/story_too_long/invalid_date/gallery_full/audio_limit/video_limit/quota_exceeded/attach_conflict/remove_conflict) chỉ sau authz.
- KHỐI 3 VERIFY-RAISE pass: counts 67/117/155/1 · policy strpos 2 chuỗi · uniques · CHECK · grants regprocedure · spine parity · An 6/2/6.

## 5. Edge — v15 / v21 (deployed ACTIVE, verify_jwt=false)

- `upload_media` **v15** — NHÁNH E `memory_id` (targets exclusivity +memory_id): gate creator+linked+active → type/size → pre-check limits/quota (fail sớm đỡ PUT phí; quyết định CUỐI ở finalize dưới lock) → PUT `/family/{child}/{uuid}.ext` dma-private → INSERT `metadata {source:'parent_memory', memory_id, pending_attach:'true', original_name}` → rpc finalize → ok `{allowed, kind:'parent_memory', media_id, sort_order}`. 4 nhánh cũ nguyên văn.
- `get_signed_media_url` **v21** — nhánh parent sau nhánh kid, select +`state`; parity 4 chân: `child_parents` link + mapping `deleted_at IS NULL` + `parent_memories.state='active'` + `media.state='active'`; audit `parent_memory_media_view`.

## 6. Smoke — 3 tầng

**DB matrix 7/7 PASS** (JWT impersonation): create backdate 20/6 · journal PH đủ detail mine:true · journal trường 0 row parent · conversation post journey_id (FK V93 chạy thẳng) · cross-family Thành 3× not_authorized · archive → ẩn + conversation khoá · restore → hiện + count=1. Debris hard-delete guarded về 0, **4 audit proof giữ**.

**Visual 9/9 PASS** (Jean, PH Hùng `ph.hung.kidshouse@demo.demenart.com`/Test@123, bé An, Preview URL): note text-only → lá thư "Ba mẹ lưu lại" · backdate đúng chương kệ · 3 ảnh (1.7–2.3MB) → polaroid gallery ký on-demand · MP4 phát no-autoplay + .MOV bị Finder chặn qua `accept` · partial 3/3 "Đã lưu kỷ vật" · Sửa đổi tên+ngày 10/7→6/7 kệ nhảy đúng · Gỡ tệp confirm "Gỡ tệp này khỏi kỷ vật?" · gỡ video cuối → còn lá thư (memory hợp lệ 0 media) · Lưu trữ confirm → kệ 22→21.

**DB cross-check khớp:** parity 4pm(3 active+1 archived)=4spine · mapping 3 active+1 deleted ↔ media 3 active+1 deleted · **0 orphan pending_attach · 0 attach_failed** · quota An 8,187,842 bytes retained · threads/messages 0 · 6/2/6 (predicate copy verbatim KHỐI 3 — bẫy `kid_creations` không có cột state) · 67/117/155/1.

## 7. Frontend — 5 commit agent-mode (typecheck + diff-scope mỗi commit)

| Commit | Nội dung | Files |
|---|---|---|
| D.1 | Model (`ParentMemoryPayload`/`isParentMemory`/`DOMAIN_LABELS`/`parentMemoryRenderKind` — **theo media THẬT**) + 5 renderer Stage (khung tranh gallery arrows/swipe/fullscreen · polaroid · cassette "Kỷ vật gia đình" · khung video MP4 · lá thư "Ba mẹ lưu lại" line-clamp-5) + Rail kindOf/cover + Detail chip 🏡 + TimelineParentMemoryLeaf Nhật ký + node 🏡 | model · Stage · Rail · Detail · parent.journal |
| D.2 `b8352f38` | `useParentMemoryComposer.ts` (verdict-based, reason→VN map, uploadOne FormData qua functions.invoke + error.context.json, sequential uploadAll, retryFailed, planNewFiles client-validate) + `ParentMemoryComposer.tsx` (Sheet bottom/right matchMedia 1023, #FBF7EE, 4 bước, partial banner + Thử lại + Bỏ qua) | 2 file MỚI |
| D.3 `c68515b2` | Nút "+ Thêm một Kỷ vật" hàng riêng dưới header (giữ layout guard V92) + `focusItemId` viewer auto-select + reset đổi bé | parent.journal · Viewer |
| D.4 `edt-4c44e66b` | +updateMemory/removeMedia hook (+baseline counts edit-mode) · Composer editTarget prefill + "Tệp đang có"+Gỡ · Detail Sửa·Lưu trữ (chỉ mine) · Viewer plumbing · route handlers (archive confirm → rpc → loadJournalRef) | 5 file |
| D.5 `4232c02b` | Video `preload="metadata"` poster (CTO feedback: preload=none = ô đen) + Rail ObjVideo tile ▶ | Stage · Rail |

**Signing giữ nguyên bất biến D224:** viewport-lazy IO · TTL cache 8′ · resign · no batch · 0 re-sign khi mở composer/conversation.

## 8. Backlog sau V94

- 🟠 re-sync library (D226 + v0.87 + v94) · 🟠 lưu repo V94 (1 mig + 2 Edge + 8 file FE)
- 🔴 **Media Compatibility Pipeline** (gộp nợ audio webm iOS + MOV/HEVC/WebM video → chuẩn hoá/transcode, Bunny Stream/HLS)
- 🟡 sweep `pending_attach` >24h vào purge nightly · 🟡 Archived Memories management surface (restore UI — RPC sẵn) · 🟡 video poster server-side
- 🟡 V93C Kid reply · V93D notification (mở rộng +kỷ vật PH) · 🟡 Unified Journey Summary (đếm kỷ vật PH — quyết định product) · 🟡 rail badge video khi có cover ảnh
- fixture nợ V93 (#19 2-parents · PH Chi user_id NULL · creation-dead-media)
- nợ cũ: Portal header chung · Art Discovery Capsule · Kid adaptation · Context Navigator · pinch/pan fullscreen · Bunny orphan b2ce6685 · lifecycle purge · upload_media source mig068 · consent-filter Kid · filter/month-nav · cover_media_id/sort_order · Parent Dashboard/Radar/AI Review · Coloring schema · Moment media taxonomy.

## 9. Rollback

DROP 6 function + DROP 2 bảng + restore 3 policy gốc (verbatim trong header migration `v94_parent_memories_domain`) + restore CHECK `media_assets.source` cũ → **65/111/155/1**; Edge redeploy `upload_media` v14 + `get_signed_media_url` v20 (backup live trong transcript phiên); frontend revert về sha trước D.1 (Lovable History). Data PH đã tạo (nếu có sau go-live) cần dump trước khi rollback — spine+pm+mapping+media.
