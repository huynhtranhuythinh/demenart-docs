# DMA_HANDOFF_v90.md
**Sprint:** V90 — Orphan Draft Moment Audit → **Archive Empty Draft Policy** (đổi scope theo CTO)
**Ngày:** 2026-07-10 GMT+7 (Asia/Ho_Chi_Minh)
**Vai trò:** ChatGPT = CTO Advisor · Claude = PM + Prompt Operator + Builder · Lovable = build
**Trạng thái:** ✅ ĐÓNG SỔ — **DB verify PASS + RPC smoke PASS (JWT-claims impersonation) + backfill 4/4 PASS + regression PASS.** +1 migration (CREATE OR REPLACE, **definer giữ 106**) · +4 UPDATE data (backfill) · 0 hard-delete · 0 Bunny · 0 cron · 0 frontend.
**File đụng:** DB-only — RPC `remove_moment_media_service` (V87 → **V90**, +archive-on-empty). **0 file frontend.** **0 Edge.**

---

## 0. TL;DR

CTO **đổi scope** V90 từ "Safe Cleanup" → **"Archive Empty Draft Policy"**: đóng root cause tại nguồn thay vì đi dọn hệ quả. Thay vì hard-delete/purge orphan, thêm **1 domain transition**: khi Teacher xoá **ảnh active cuối cùng** của một moment `draft` → moment chuyển `draft → archived` (thay vì để draft rỗng ẩn bằng UI-filter). Giữ TRỌN provenance (moment row + media `deleted` + metadata audit + tag/caption nếu có). `archived` = terminal state: vô hình mọi cổng, không publish, không editable.

- **⭐ Endpoint sau V90:** RULES **D222** · SYSTEM_MAP **v0.83** · Handoff **v90**.
- **Inventory 63/106/155/1 KHÔNG đổi** · **An 6/2/6 KHÔNG đổi.**
- **Không:** hard-delete · purge · cron · restore/recycle · archive `e1761056` · đụng Parent/Kid/Teacher UI · đụng upload flow · xử partial-fail path (backlog).

---

## 1. Canonical đã đọc — endpoint verify (đầu phiên)

Topic V90 mở mới. **KHÔNG dựa memory** — đọc canonical thật trên đĩa: `DMA_HANDOFF_v89.md` · `DMA_RULES.md` · `DMA_SYSTEM_MAP.md`.
**Endpoint đầu phiên (LIVE đĩa):** RULES **D221** · SYSTEM_MAP **v0.82** · Handoff **v89** — khớp brief cả 3 · **0 drift đĩa**.
**Inventory LIVE:** **63 bảng · 106 definer · 155 policy · 1 cron** — khớp. **An 6/2/6** (data-level LIVE) — khớp.

---

## 2. C1 — Audit LIVE (read-only) — chân dung orphan

**Schema `learning_moments`:** ownership qua `class_id→classes.school_id`; `session_id` **nullable**; creator=`uploaded_by`; `state` enum `moment_state`{draft·pending_approval·needs_revision·approved·rejected·hidden·archived}; trigger duy nhất `set_updated_at` (BEFORE UPDATE, 0 guard auth.uid, **0 DELETE trigger**).

**⭐ FK trỏ `learning_moments`:** `moment_children.moment_id`=**CASCADE** · `kid_reactions.moment_id`=**CASCADE** · `media_assets.linked_moment_id`=**NO ACTION** → hard-delete moment row **bị chặn nếu còn bất kỳ media row nào (kể cả `deleted`)**. ⇒ "delete only the learning_moment row" (Option 2 brief) **bất khả thi** với deleted-media shells.

**Toàn hệ 17 moments = 11 approved + 6 draft** (0 pending/needs_revision/rejected/hidden/archived).

**6 draft phân loại (C2):**
| ID | tuổi | active | deleted | tag | caption | Loại |
|---|---|---|---|---|---|---|
| `ecb244b5…631c` | 6 phút | **2** | 0 | 0 | null | **A — draft đang làm việc SỐNG** ⛔ không đụng |
| `e1761056…c0b4` | ~15 ngày | 0 | 0 | 1 (Jenny) | "[seed] Bé Jenny tập trống" | **B — có nội dung** (caption+tag) — GIỮ nguyên |
| `aefae8a7…8926` | ~5 ngày | 0 | 1 | 0 | null | **D — deleted-media shell** → archive |
| `2efc8c20…159d` | 4.8h | 0 | 2 | 0 | null | **D** → archive |
| `921974af…263e` | 4.7h | 0 | 2 | 0 | null | **D** → archive |
| `6cd00926…06ef` | 4.6h | 0 | 2 | 0 | null | **D** → archive |

**⭐ 3 phát hiện quyết định:**
1. **KHÔNG có Category C thuần** (0 total media + 0 tag + caption blank). Mọi "orphan" đều là **deleted-media shell (D)** — còn media rows mang audit trail (`delete_reason='teacher_removed_from_draft'`, deleted_by=GV Mỹ Linh …011). Sinh trong smoke V87/V88 hôm nay.
2. **Draft mới nhất (`ecb244b5`) 2 active media, 6 phút** = bằng chứng "zero active media" MỘT MÌNH KHÔNG an toàn.
3. Chưa có function dọn orphan (chỉ `drive_purge_*` folder-scoped). 1 cron = `purge-drive-trash-nightly` (không moment).

**Ngoài scope (flag):** 2 moment **approved 0 media** (`…a2` Khang, `…a2` Phúc — seed captioned+tagged) = Category E brief. V90 KHÔNG đụng (chỉ audit draft); không ảnh hưởng summary (0 active).

---

## 3. Quyết định CTO — đổi scope

CTO **bác Option 1 (audit-only)** VÀ **bác hard-delete**. Chốt **Archive Empty Draft Policy** (biến thể Option 2B — soft-archive):
- Không hard-delete/purge/cron/restore/recycle.
- Transition: `draft` mất ảnh active cuối → `archived`. Provenance nguyên vẹn. "Lưu hồ sơ, không xoá".
- Nguyên tắc domain: UI-hide (`filter media>0`) che sai business state — draft-rỗng-ẩn phải trở thành `archived` để domain đúng.
- 3 quyết định phụ: (1) **backfill 4 shell** draft→archived (guarded) · (2) **giữ `e1761056`** draft (Category B, caption+tag, không proven orphan) · (3) **partial-fail 0-total-media draft = backlog** (đường sinh khác, sprint riêng).

---

## 4. C2-code-audit — ma trận vô hình `archived` (đọc body function thật)

| Đường đọc | Filter | archived hiện? |
|---|---|---|
| `get_session_moments` (Teacher) | mọi state, media active-only + UI `filter(media>0)` | ❌ ẩn (0 active) |
| `submit_session_journal` (publish) | promote CHỈ `state in (draft,pending_approval,needs_revision)` + exists(tag) + exists(active media) | ❌ không bao giờ publish |
| `get_child_journal` (Parent) | `lm.state='approved'` | ❌ |
| `get_kid_album_service` (Kid) | `lm.state='approved'` | ❌ |
| `get_school_moments` (School highlights) | `lm.state='approved'` | ❌ |
| `upload_media` PART B (V89) | reject `state!=='draft'` → `moment_not_editable` | ❌ archived không re-populate |

→ `archived` = terminal sạch, vô hình mọi cổng, không publish, không editable. Provenance giữ.

---

## 5. Migration — V90 (apply_migration `v90_archive_empty_draft_on_last_media_removed`, D92 3-block)

**KHỐI 1:** CREATE OR REPLACE `remove_moment_media_service(p_media_id uuid)` — giữ **nguyên văn body V87** (gate order D219: authenticated → lock media FOR UPDATE → moment-scoped → lock moment FOR UPDATE → **authorize-trước-lộ-state** [`check_media_upload_access` + `is_school_admin OR is_session_lead OR is_session_teacher`] → lộ state → guarded soft-delete ROW_COUNT=1). Chèn **bước 8** sau soft-delete thành công:
```
IF NOT EXISTS (SELECT 1 FROM media_assets WHERE linked_moment_id=v_moment.id AND state='active') THEN
  UPDATE learning_moments SET state='archived' WHERE id=v_moment.id AND state='draft';  -- recheck dưới lock
  v_archived := (ROW_COUNT=1);
END IF;
```
+ DECLARE `v_archived boolean:=false` + return thêm `'moment_archived', v_archived`.
**KHỐI 2:** `REVOKE ALL ... FROM PUBLIC, anon, authenticated` + `GRANT EXECUTE ... TO authenticated, service_role` (D15 — CREATE OR REPLACE reset proacl).
**KHỐI 3:** VERIFY DO block (RAISE=rollback guard) — 0 anon/public EXECUTE (grantee=0 hoặc rolname='anon' → 0).

**Concurrency (nối D219):** moment `FOR UPDATE` lock (bước 4). Upload đồng thời cùng moment → INSERT `media_assets` giữ FK `FOR KEY SHARE` trên moment row → **block tới khi txn commit** → upload đọc `archived` → PART B reject. Race tự giải an toàn; KHÔNG cần lock thêm ở `upload_media`.

**Verify migration:** definer **106** (giữ, REPLACE) · grants `authenticated,postgres,service_role` (0 anon/public) · body có `ARCHIVE-ON-EMPTY`+`moment_archived` ✔.

---

## 6. Backfill 4 shell (bước F — data-only, guarded)

`UPDATE learning_moments SET state='archived' WHERE id IN (4 exact IDs) AND state='draft' AND NOT EXISTS(active media)` — bọc DO block `IF ROW_COUNT<>4 THEN RAISE` (auto-rollback). **Kết quả: đúng 4 rows.** Sau backfill: 4 shell = `archived`, media_total giữ (2/2/2/1 — deleted rows KHÔNG đụng), tags 0, caption null. **`ecb244b5` (2 active) + `e1761056` (Category B) KHÔNG đụng.**

---

## 7. Smoke PASS (DB-level, JWT-claims impersonation GV Mỹ Linh)

Seed test moment `dead0000…9090` (draft + 2 active media, session a0001, `SET session_replication_role=replica`, D85). Impersonate `set_config('request.jwt.claims','{"sub":"fd9322e1…af1b"}',false)` (⚠️ `sub`=`profiles.user_id`, KHÔNG profile id — `current_profile()` map `user_id=auth.uid()`).
- **Test I (delete 1/2):** moment vẫn **draft**, active_left=1 ✔ (không archive khi còn ảnh).
- **Test J (delete ảnh cuối):** RPC trả `{ok:true, state:deleted, moment_archived:true}` → moment=**archived**, 0 active, 2 deleted (provenance nguyên) ✔.
- **Cleanup:** hard-delete test moment+media sạch (0/0); reset jwt claims.

**Regression PASS (lúc đóng sổ):** An **6/2/6** · state **11 approved + 2 draft + 4 archived = 17** · `e1761056`+`ecb244b5` giữ draft · 4 archived inert (0 active/0 tag) → vô hình mọi đường approved/active-gated · **Inventory 63/106/155/1 giữ**.

**⭐ NGHIỆM THU LIVE PRODUCTION PASS (sau đóng sổ — GV Mỹ Linh thao tác thật, ảnh 20:02 GMT+7):** Jean login GV Mỹ Linh → PhotoTab buổi An → card draft `ecb244b5` (2 ảnh, có × editable, "Chưa gắn bé") → bấm × xoá lần lượt 2 ảnh (deleted_at 20:02:08→20:02:10 GMT+7). Ảnh cuối rơi → **policy archive-on-empty KÍCH HOẠT LIVE** → `ecb244b5` draft→**archived** → card biến mất. Bằng chứng chéo DB: 2 media của `ecb244b5` = `deleted`/`delete_reason='teacher_removed_from_draft'`/deleted_by …011, moment row + provenance nguyên. Ảnh cũng xác nhận: card approved "Bé làm workshop" (`c7fe22f4`, "✓ Đã gửi tới ba mẹ") thumbnail **KHÔNG có ×** (không xoá media approved — D219); draft-còn-ảnh CÓ × editable; **0 card rỗng/orphan lộ ra**. **An 6/2/6 bất biến.** → Policy chạy đúng qua UI thật, tay người thật (mạnh hơn smoke JWT).

**Baseline moment sau nghiệm thu LIVE:** **11 approved + 1 draft + 5 archived = 17** (draft còn = seed `e1761056`; archived = 4 shell backfill + `ecb244b5` vừa archive live). ⚠️ Split draft/archived là **số ĐỘNG** — sẽ tiếp tục dịch mỗi lần GV xoá ảnh cuối một draft (policy chạy). KHÔNG phải regression. **An 6/2/6 + Inventory 63/106/155/1 = baseline cố định, giữ.**

---

## 8. Non-negotiable giữ nguyên

`submit_session_journal` · `get_child_journal` · `get_kid_album_service` · `get_school_moments` · `get_session_moments` · `kid_gate` · `check_media_upload_access` · `upload_media` (PART B V89) · consent V72 · badge V73 · Parent UI · Kid UI · Teacher PhotoTab UI · summary/gallery logic. `/kid` namespace reserved. **0 hard-delete · 0 Bunny · 0 cron · 0 restore/recycle · 0 frontend · 0 Edge.** Chỉ 1 RPC replace + 4 UPDATE data.

---

## 9. Endpoint & backlog sau V90

**Endpoint:** RULES **D222** · SYSTEM_MAP **v0.83** · Handoff **v90**.

**Backlog:**
- 🟠 re-sync project library (D222 + v0.83 + v90) · 🟠 lưu repo V90 (1 mig `v90_archive_empty_draft_on_last_media_removed`).
- ✅ **orphan draft (deleted-media shell) ĐÓNG** — root cause đóng tại nguồn (`remove_moment_media_service` archive-on-empty) + 4 shell hiện có backfilled.
- 🟡 **partial-fail 0-total-media draft** (PhotoTab INSERT moment + 0 upload thành công → draft 0 media, KHÔNG qua RPC này → policy archive-on-last-media KHÔNG bắt). Hiện inert (StepReview lọc media>0, submit đòi active). **Đường sinh riêng — cần audit/sprint riêng.** (`e1761056` seed thuộc họ này nhưng có caption+tag = Category B, giữ.)
- 🟢 (tùy, tương lai) lifecycle purge THẬT: `archived + N ngày + admin + backup + no-litigation` → hard-delete (media→moment theo FK order). **KHÔNG làm tới khi có retention policy + CTO duyệt riêng.**
- 🟠 (nợ taxonomy) `upload_media` nhánh A không set `source` (mig068) · 🟠 (theo dõi) consent-filter album Kid · 🟠 (hoãn) filter/month-nav · timeline "X ảnh" · `cover_media_id`/`sort_order` · KHÔNG Edge batch-sign · nợ cũ (Parent Dashboard/Radar/AI Review THẬT · Phương án B RPC `get_child_journey_service` · rename `kidJourneyModel.ts` · enrichment `child_journey` · Coloring schema · Moment media taxonomy).

---

## 10. Rollback plan (V90)

- **RPC:** CREATE OR REPLACE `remove_moment_media_service` về body V87 (bỏ bước 8 archive + field `moment_archived`) + REVOKE/GRANT lại. Source V87 dump trong D219.
- **Backfill:** `UPDATE learning_moments SET state='draft' WHERE id IN (4 shell IDs) AND state='archived'` → 4 shell về draft (ẩn lại qua UI-filter như cũ). Reversible hoàn toàn (0 media/tag/caption đụng).
- **Data:** 0 hard-delete → không mất gì.

---

## 11. Demo accounts

(`@demo.demenart.com` · `Test@123`): **GV KHM `gv.linh.kidshouse`** (Đặng Mỹ Linh, lead teacher, dùng smoke V90; profile `d1000000…011`, user_id `fd9322e1…af1b`) · PH KHM `ph.hung.kidshouse` (bé An) · Master KHM `hieutruong.kidshouse` · GV KHM `gv.my.kidshouse` (temp) · PH KHM `ph.toan.kidshouse` (temp) · Master MNDM `hieutruong.demen` · GV MNDM `gv.han.demen` · PH MNDM `ph.thanh.demen`.
