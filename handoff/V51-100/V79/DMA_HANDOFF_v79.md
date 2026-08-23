# DMA_HANDOFF_v79.md
**Sprint:** V79 — Gallery RPC Enrich + Backward-Compatible Adapter
**Ngày:** 2026-07-09 GMT+7 (Asia/Ho_Chi_Minh)
**Vai trò:** ChatGPT = CTO Advisor · Claude = PM + Prompt Operator + Builder · Lovable = build
**Trạng thái:** ✅ ĐÓNG SỔ — C2 (RPC enrich, apply_migration) + C3 (type-only) applied · smoke Jean PASS 3 ảnh · 15/15 acceptance PASS
**File code bị đụng:** 1 file — `src/routes/_authenticated/parent.journal.tsx` (type-only). DB: 1 function migration.

---

## 0. TL;DR

V79 là **data-shape sprint**: enrich `get_child_journal` để một moment lộ **metadata gallery an toàn**, UI backward-compatible **KHÔNG đổi hình ảnh**. Timeline vẫn 1 cover như cũ; **KHÔNG** dựng gallery UI/thumbnail rail (hoãn tới khi CTO duyệt V79-next).

- **C2 (DB):** `apply_migration` (Lối A/D92, `v79_get_child_journal_gallery_enrich`) enrich **CHỈ nhánh moments**. Giữ `media_id`/`tagged_count` byte-exact; thêm `coverMediaId` + `mediaCount` + `hasGallery` + `galleryItems[]` (metadata-only, **0 signed_url**, cover=ảnh đầu `created_at ASC`).
- **C3 (frontend):** type-only — +4 field optional vào `type MomentRow`. 0 runtime, 0 UI.
- **C4:** SKIP (nhãn "2 ảnh") đúng lệnh.
- **Nghiệm thu:** verify shape 3 mẫu SQL PASS + smoke Jean 3 ảnh PASS.

**⭐ Endpoint sau V79:** RULES **D211** · SYSTEM_MAP **v0.72** · Handoff **v79**.

---

## 1. Canonical đã đọc (Plan B — file thật)

Trước phiên: RULES **D210** · SYSTEM_MAP **v0.71** · Handoff **v78** (khớp brief, snapshot đĩa KHÔNG tụt phiên). Sau phiên: RULES **D211** · SYSTEM_MAP **v0.72** · Handoff **v79**.

---

## 2. C1 — Audit DB sống + code sống (read-only, kết quả)

**DB (live re-verify):**
1. `get_child_journal` nhánh moments: `media_id` = `SELECT ma.id … WHERE linked_moment_id=lm.id AND state='active' ORDER BY ma.created_at LIMIT 1`; gate `lm.state='approved'`. SECURITY DEFINER, `search_path=''`. ✔
2. `learning_moments` KHÔNG có `cover_media_id`/`sort_order`. `media_assets` có `file_type`(text,null) + `created_at` + `metadata`(jsonb) + `linked_moment_id`(1-n) + `state`(text), KHÔNG `sort_order`. ✔
3. `f51039be…cd1f`: state=approved · caption=null · **2 media active** · cover=`3ca6c3dd…e909` · gallery ASC = `3ca6c3dd`(29/6) → `b2d5d20a`(30/6), cả 2 `image/jpeg`. ✔
4. Phân bố moment approved: **0-media: 2** (`…00a2`) · **1-media: 6** (`…00a1`) · **2-media: 1** (`f51039be`) → đủ 3 mẫu test acceptance.
5. Summary An = drawings 6 · audio 2 · moments-với-media 4 → **6/2/4**. ✔ (child_id `d1000000-0000-4000-8000-000000000041`)
6. Grants RPC (baseline): EXECUTE cho authenticated + service_role (postgres owner). KHÔNG anon/PUBLIC.

**Code sống `parent.journal.tsx`:** KHÔNG có file adapter riêng — `buildParentTimeline` inline; moments passthrough RPC→state (`payload.moments ?? []`)→leaf (KHÔNG strip field). `type MomentRow` = `{moment_id, caption, created_at, media_id, tagged_count?}`. `CompactMomentLeaf` chỉ dùng `media_id`(cover qua `MomentImage`)/`caption`/`tagged_count`. `ParentJournalLightbox` pure-presentational, nhận 1 `signedUrl`. → Field RPC mới = 0 visual change.

---

## 3. C2 — RPC enrich (APPLY qua apply_migration, Lối A/D92)

Migration `v79_get_child_journal_gallery_enrich`, **3-KHỐI**:
- **KHỐI 1** — `CREATE OR REPLACE FUNCTION public.get_child_journal(uuid)`: 4 nhánh journey/skills/badges/creations **reproduce nguyên văn**; CHỈ nhánh moments enrich. Giữ `media_id`/`tagged_count`; thêm:
  - `coverMediaId` = cùng subquery `ORDER BY ma.created_at LIMIT 1` (⇒ luôn = `media_id`)
  - `mediaCount` = `count(*)` media active
  - `hasGallery` = `mediaCount > 1`
  - `galleryItems[]` = `jsonb_agg(... ORDER BY ma.created_at ASC)` mỗi item `{mediaId, fileType←`file_type`, createdAt, caption←`metadata->>'caption'`, sortOrder:NULL}`
  - **0 signed_url · mọi object `public.*` (giữ `search_path=''`).**
- **KHỐI 2** — `REVOKE ALL … FROM PUBLIC` + `GRANT EXECUTE … TO authenticated` + `TO service_role` (khớp baseline; CREATE OR REPLACE reset grants về PUBLIC → phải re-grant, D15).
- **KHỐI 3** — VERIFY (`RAISE`=rollback guard, chạy trong txn của apply_migration): **query underlying tables** (KHÔNG gọi RPC — `auth.uid()` NULL trong editor sẽ trúng gate `not_authorized`). Assert: function exists · grantee chỉ postgres/authenticated/service_role · `f51039be`=2 · `…00a1`=1 · `…00a2`=0 · cover=`3ca6c3dd` · An 6/2/4. → apply_migration trả `success:true` = mọi assert PASS.

**Verify shape thật (post-apply, replicate nhánh moments standalone, bypass auth gate):**

| Moment | media_id | coverMediaId | mediaCount | hasGallery | galleryItems |
|---|---|---|---|---|---|
| `f51039be` | `3ca6c3dd` | `3ca6c3dd` (=media_id) | **2** | **true** | len **2**, ASC 29/6→30/6, `image/jpeg`, caption/sortOrder null |
| `…00a1` | `4002c7c2` | `4002c7c2` | **1** | false | len **1** |
| `…00a2` | null | null | **0** | false | `[]` |

**Grants sau migration (re-verify):** authenticated + service_role (+ owner postgres); anon/PUBLIC revoked. ✔

**ROLLBACK C2:** `CREATE OR REPLACE` về body cũ (nhánh moments chỉ `media_id` + `tagged_count`) + cùng REVOKE/GRANT. Rủi ro thấp: field mới additive, RPC cũ backward-compat.

---

## 4. C3 — Adapter/type update (APPLY, agent mode)

`src/routes/_authenticated/parent.journal.tsx` — **type-only**: thêm 4 field optional vào `type MomentRow`:
```ts
  coverMediaId?: string | null;
  mediaCount?: number;
  hasGallery?: boolean;
  galleryItems?: Array<{ mediaId: string; fileType: string | null; createdAt: string; caption?: string | null; sortOrder?: number | null }>;
```
0 runtime change · 0 UI · `CompactMomentLeaf`/`ParentJournalLightbox`/`MomentImage`/`buildParentTimeline` KHÔNG đụng. **C4 nhãn "2 ảnh" SKIP** (V79 = data-shape, UI y nguyên).

**Agent mode ("tự áp"):** 1 commit `94ca942d` · `get_diff` sạch (đúng 1 file, KHÔNG `routeTree.gen.ts`, chỉ +11 dòng type) · typecheck pass · deploy 1 lần → `demenart.lovable.app` (deployment `6f3b2d5b`).

**ROLLBACK C3:** revert type block (additive, vô hại).

---

## 5. Nghiệm thu — smoke Jean PASS 3 ảnh

Login `ph.hung.kidshouse@demo.demenart.com` / `Test@123` (con An):
- **`/parent`:** summary **6 Tác phẩm / 2 Âm thanh / 4 Khoảnh khắc** ✔ · hero + hint mỗi stat + selector An/Khang nguyên (V77).
- **`/parent/journal`:** timeline y hệt V78 · `f51039be` (29/6, caption null → fallback "Khoảnh khắc ở lớp", "Ảnh chung nhiều bé") hiện **1-cover bình thường**, 0 gallery UI ✔ · "MỐC HÀNH TRÌNH" ("Tiếng mưa rơi" + Cô nhận xét) + "Riêng gia đình" badge nguyên (V73/V76).
- **Lightbox:** mở như cũ — 1 cover + chip + privacy badge + warmLine + "Gợi ý trò chuyện"; **0** thumbnail rail/gallery nav ✔ · ảnh ký OK, không lỗi network.

**15/15 acceptance PASS** (1-6,10-12,14-15 bằng SQL/diff; 7,8,9,13 bằng smoke ảnh).

---

## 6. Guard đã giữ trọn (V79)

DB: **+1 function migration** (get_child_journal replace, D92) → mig 001→105; **0 cột/bảng/Edge/schema/RLS/policy** mới. 63 bảng · 105 definer (replace, không +) · 155 policy · Edge 14 · cron 1 · 3 tenant KHÔNG đổi. Frontend: **1 file type-only**. 0 signed_url ở RPC · 0 ký ở adapter · 0 Edge batch-sign · 0 seed giả · 0 hardcode gallery. KHÔNG đụng `parent.index.tsx`/`kidJourneyModel.ts`/`kid.tsx`/`routeTree.gen.ts`. Guard chuỗi: summary V69 (→6/2/4) · /kid lightbox V70 · Parent Lightbox V71 · consent V72 · badge dedup V73 · adapter V74 · compact spine V75 · detail V76 · home V77 · data foundation V78.

---

## 7. Backlog (chưa làm ở V79)

- **V79-next (chờ CTO duyệt):** UI gallery THẬT trong `ParentJournalLightbox` — thumbnail rail + điều hướng khi `hasGallery` (mediaCount>1); ký **TỪNG item khi mở lightbox** (consent per-media qua Edge `get_signed_media_url`, **0 lift signed_url lên RPC/adapter**, 0 re-sign — giữ D203/D204/D206). Data đã sẵn (`galleryItems[]` từ V79).
- **(tùy) migration `cover_media_id`/`sort_order`** chỉ khi cần chọn cover thủ công / sắp thứ tự (hiện cover=ảnh đầu created_at ASC, sortOrder=null).
- **(tùy) Edge batch-sign** chỉ khi gallery nhiều ảnh gây waterfall.
- Lưu repo/backup V79 (`parent.journal.tsx` type diff + migration SQL).
- Nợ cũ: Parent Dashboard đầy đủ/Radar/AI Review THẬT · Phương án B RPC canonical `get_child_journey_service` (hợp nhất 2 path đọc journey kid/parent) · rename `kidJourneyModel.ts` · enrichment `child_journey` · Coloring JSON schema · Moment media source taxonomy.

**Endpoint sau V79:** RULES **D211** · SYSTEM_MAP **v0.72** · Handoff **v79**.
Production: https://demenart.lovable.app (deploy `6f3b2d5b`). Deploy trước V79: `1a3288fa` · commit trước C3: `05ec1209`.
