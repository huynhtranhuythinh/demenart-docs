# DMA_HANDOFF_v78.md
**Sprint:** Parent Multi-media Moment — DATA FOUNDATION (V78A, data-only) + Gallery RPC Shape & V79 Plan (V78B/C, planning-only)
**Ngày:** 2026-07-09 GMT+7 (Asia/Ho_Chi_Minh)
**Vai trò:** ChatGPT = CTO Advisor · Claude = PM + Prompt Operator + Builder · Lovable = build
**Trạng thái:** ✅ ĐÓNG SỔ — V78A applied (1 UPDATE data) · V78B/C planning-only (ghi backlog, KHÔNG code)
**File code bị đụng:** KHÔNG (0 file). Thay đổi DUY NHẤT = 1 UPDATE `learning_moments.state` (data).

---

## 0. TL;DR

**V78A** không seed data giả. Audit DB sống lộ moment `f51039be…cd1f` (tag An/Bình/Chi) **đã có 2 media active THẬT** nhưng `state=draft` → vô hình `/parent/journal` vì `get_child_journal` nhánh moments lọc `state='approved'`. V77B đếm "0 moment ≥2 ảnh" **đúng nhưng chỉ trong nhóm approved**. `f51039be` là moment 2-ảnh **duy nhất** toàn hệ → nền multi-media rẻ & trung thực nhất. **1 UPDATE tối giản** `state` draft→approved (execute_sql, KHÔNG migration/RPC/Edge/UI). Consent cả 3 trẻ đã granted → PH Hùng mở được.

**⭐ Chốt quan trọng:** approve moment tag An làm summary `/parent` của An chuyển **6/2/3 → 6/2/4** (khoảnh khắc 3→4). Đã mô phỏng + surface TRƯỚC khi ghi; **CTO chấp nhận (Lối 1)** — đây là data đúng, KHÔNG regression. Rollback về draft → 6/2/3.

**V78B/C** chỉ planning: shape gallery RPC tương lai (backward-compatible, metadata-an-toàn, 0 signed_url/0 migration) + V79 sprint plan. KHÔNG code.

---

## 1. Canonical đã đọc (Plan B — file thật)

Endpoint xác nhận khớp brief, snapshot đĩa KHÔNG tụt phiên: **RULES D209 · SYSTEM_MAP v0.70 · Handoff v77** (trước phiên này). Sau phiên: **RULES D210 · SYSTEM_MAP v0.71 · Handoff v78**.

---

## 2. C1 — Audit DB sống + code sống (kết quả)

**DB (re-verify live, KHÔNG tin audit V77B):**
1. `get_child_journal` nhánh `moments` vẫn ký 1 media/moment: `SELECT ma.id … WHERE linked_moment_id=lm.id AND state='active' ORDER BY created_at LIMIT 1`. ✔
2. `media_assets.linked_moment_id` = FK **1-n** → schema sẵn nhiều media/moment. ✔
3. `learning_moments` **KHÔNG** có `cover_media_id`/`sort_order`. `media_assets` có `file_type`(vd `image/jpeg`) + `metadata` jsonb + `source`. ✔
4. Phân bố media/moment **approved**: 6 moment×1 ảnh · 2 moment×0 ảnh · **0 moment ≥2 ảnh** (khớp V77B). ✔
5. **⭐ Mọi state:** duy nhất moment `f51039be…cd1f` có **2 media active** — nhưng `state=draft` (vô hình journal). Đây là điểm V77B không lộ (chỉ đếm approved).
6. Enum `learning_moments.state` = draft/pending_approval/needs_revision/approved/rejected/hidden/archived → draft→approved hợp lệ.
7. Trigger trên `learning_moments` = chỉ `trg_learning_moments_updated_at` (BEFORE UPDATE → `set_updated_at`). **KHÔNG guard `auth.uid()` NULL**, **KHÔNG check-constraint đòi `approved_by`** → UPDATE từ MCP chạy sạch, KHÔNG cần `session_replication_role=replica`.
8. `media_consent_check`: moment ≥2 trẻ tag → required consent `group_moment_in_class`; MIN-consent gom **mọi** trẻ thiếu → 1 trẻ thiếu là block toàn bộ. Consent 3 trẻ (An/Bình/Chi) đều granted, chưa rút → gate PASS cho PH Hùng.

**Code sống `parent.journal.tsx`** (khớp handoff, KHÔNG surprise): `MomentRow` chỉ `media_id` đơn (không `galleryItems`/`mediaCount`); `CompactMomentLeaf` ký qua `MomentImage`; `ParentJournalLightbox` pure-presentational nhận **1** `signedUrl`, không biết media_id, không re-sign.

---

## 3. V78A — APPLY (data-only, đã ghi)

**UPDATE tối giản (execute_sql, KHÔNG migration):**
```sql
UPDATE public.learning_moments
SET state = 'approved'
WHERE id = 'f51039be-48e8-42c5-9900-b03f3472cd1f'
  AND state = 'draft';
-- caption GIỮ null · approved_by null · trigger set_updated_at tự bump updated_at
```

**BEFORE:** state=draft · caption=null · approved_by=null · 2 media active · tag An/Bình/Chi · consent cả 3 granted.

**AFTER (verify PASS):**
| Mục | Kết quả |
|---|---|
| state | draft → **approved** ✔ |
| caption | **null** (fallback "Khoảnh khắc ở lớp") ✔ |
| media active | **2** ✔ |
| tagged children | An / Bình / Chi — không đổi ✔ |
| consent (cả 3) | `group_moment_in_class` granted, chưa rút ✔ |
| summary An | **6 / 2 / 4** ✔ (accepted) |
| cover đơn RPC trả | `3ca6c3dd…e909` (ảnh đầu `created_at ASC`) → single-cover, chưa gallery ✔ |

**Smoke UI — NGHIỆM THU ĐẠT (Jean, 5 ảnh, login `ph.hung.kidshouse@demo.demenart.com` / `Test@123`):**
- `/parent` summary = **6 Tác phẩm / 2 Âm thanh / 4 Khoảnh khắc** ✓ (đúng 6/2/4 accepted).
- `/parent/journal` render bình thường (timeline tháng 7 + tháng 6 đủ, không vỡ) ✓.
- Moment `f51039be` lên journal dạng **1 cover** "Khoảnh khắc ở lớp" (caption null → fallback đúng) · nhãn **"Ảnh chung nhiều bé"** (nhóm 3 trẻ) · 29/6 ✓ — chưa gallery UI ✓.
- Console **No Issues**, không lỗi network ✓.
- `/parent/consent` (An): "Cho con xuất hiện trong khoảnh khắc nhóm của lớp" **BẬT** ✓.
- Jean xác nhận: "chạy ổn".

**ROLLBACK SQL:**
```sql
UPDATE public.learning_moments
SET state = 'draft'
WHERE id = 'f51039be-48e8-42c5-9900-b03f3472cd1f'
  AND state = 'approved';
-- Sau rollback: moment ẩn khỏi journal An → summary về 6 / 2 / 3
```

---

## 4. V78B — Gallery RPC Shape (planning, CHƯA áp)

Shape tương lai nhánh `moments` của `get_child_journal`:
```ts
type MomentRow = {
  moment_id: string;
  caption: string | null;
  created_at: string;
  tagged_count?: number;

  media_id: string | null;          // GIỮ — backward-compatible (= cover)
  coverMediaId?: string | null;     // = media_id, ảnh đầu created_at ASC
  mediaCount?: number;              // đếm media active/moment
  hasGallery?: boolean;             // mediaCount > 1
  galleryItems?: Array<{
    mediaId: string;
    fileType: string | null;        // ← media_assets.file_type
    createdAt: string;              // ← media_assets.created_at
    caption?: string | null;        // null tới khi có cột/metadata
    sortOrder?: number | null;      // null; order tạm = created_at ASC
  }>;
};
```
Ràng buộc: `media_id` giữ nguyên (adapter/UI cũ không vỡ) · `coverMediaId`=`media_id`=ảnh đầu `created_at ASC` · `galleryItems[]` chỉ metadata an toàn, **0 signed_url** · `caption`/`sortOrder`=null tới khi có cột (né migration) · **0 ký ở adapter · 0 Edge batch-sign · 0 migration cover/sort**. Cover `f51039be` = `3ca6c3dd…e909`.

SQL sketch tương lai (minh hoạ, KHÔNG áp): giữ subquery cover `LIMIT 1` + thêm `count(*)` cho `mediaCount` + `jsonb_agg(… ORDER BY ma.created_at ASC)` cho `galleryItems` + `hasGallery`=count>1, cùng gate `state='active'`.

---

## 5. V78C — V79 Plan (đề xuất, chưa duyệt build)

- V79 enrich `get_child_journal` trả `galleryItems[]` + `mediaCount` + `coverMediaId` (+`hasGallery`). Adapter `buildParentTimeline` giữ backward-compatible.
- Timeline vẫn render **1 cover thumbnail**. Gallery **chỉ** dùng trong detail/`ParentJournalLightbox`.
- `galleryItems.length <= 1` → UI y nguyên. `> 1` → lightbox thêm thumbnail rail / điều hướng gallery.
- Ký **từng item khi mở lightbox** — KHÔNG ở adapter, KHÔNG ở RPC (giữ D203/D204/D206).
- Consent guard **V72** + badge dedup **V73** giữ nguyên. Summary baseline sau V78A = **6/2/4**.
- Vn: Edge batch-sign nếu gallery nhiều ảnh gây waterfall.
- **KHÔNG tiến V79 implementation tới khi CTO duyệt.**

---

## 6. Guard đã giữ trọn (V78)

0 file code · 0 migration/RPC/Edge/Auth/RLS · 0 AI · 0 signing/signed_url · 0 UI · 0 npm · 0 seed giả · 0 media row mới. Thay đổi duy nhất = 1 UPDATE `learning_moments.state`. Mô phỏng + surface mâu thuẫn summary TRƯỚC khi ghi (D210). KHÔNG đụng `parent.index.tsx`/`parent.journal.tsx`/`kidJourneyModel.ts`/`kid.tsx`/`routeTree.gen.ts`. Guard: summary V69 (6/2/3→6/2/4 accepted) · /kid lightbox V70 · Parent Lightbox V71 · consent V72 · badge dedup V73 · adapter V74 · compact spine V75 · detail polish V76 · parent home V77.

---

## 7. Backlog (chưa làm ở V78)

- **V79** multi-media gallery: RPC enrich `galleryItems[]`/`mediaCount`/`coverMediaId` → UI gallery trong `ParentJournalLightbox` ký từng item khi mở → (tùy) migration cover/sort → (tùy) Edge batch-sign. Nền data đã sẵn (`f51039be` 2 ảnh).
- Lưu repo/backup (phiên này KHÔNG đụng file code — không có diff repo).
- Nợ cũ: Parent Dashboard đầy đủ/Radar/AI Review THẬT · Phương án B RPC canonical `get_child_journey_service` · rename `kidJourneyModel.ts` · enrichment `child_journey` (creations/moments chảy vào spine) · Coloring JSON schema · Moment media taxonomy.

**Endpoint sau V78:** RULES **D210** · SYSTEM_MAP **v0.71** · Handoff **v78**.
