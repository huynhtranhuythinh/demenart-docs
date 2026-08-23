# DMA — V114B-E3 · WP1 STAGE A · EVIDENCE

> Báo cáo theo đúng 12 mục Owner yêu cầu. **Migration 105 ĐÃ APPLY.** Frontend **chưa** đụng. HEAD unchanged.

---

## 1. FINAL MIGRATION FILENAME

```
20260721094857_v114b_e3_wp1_security_containment
```

Migration đứng thứ **105** (`count(*) = 105`, trước đó 104).

## 2. HASH CỦA SQL ĐÃ APPLY

| | |
|---|---|
| `md5(statements)` **[DB]** từ `supabase_migrations.schema_migrations` | **`30f29f7f94c300a0ad234ec8ec5cadf1`** |
| Số statement | 1 (một khối atomic) |

## 3. MIGRATION APPLY RESULT

| Lần | Kết quả | Nguyên nhân |
|---|---|---|
| #1 | ❌ **ROLLBACK toàn bộ** | Em để sót một `DO` block placeholder chứa UUID không hợp lệ (`…00000000wp01`). Lỗi `22P02` ở giai đoạn khởi tạo biến. **Không có gì được ghi.** |
| #2 | ❌ **ROLLBACK toàn bộ** | Probe của em INSERT có cột `id` — **không nằm trong INSERT whitelist** ⇒ `42501 permission denied`. **Đây là bằng chứng dương tính rằng column whitelist hoạt động.** Em sửa probe, **không nới whitelist**. |
| #3 | ✅ **SUCCESS** | |

Cả hai lần fail đều rollback nguyên khối theo D92 — không để lại trạng thái nửa vời. Đã `notify pgrst, 'reload schema'` sau apply (D289).

## 4. BLOCK 3 STRUCTURAL RESULT

Toàn bộ guard PASS trong transaction. Xác minh lại **độc lập sau apply** **[DB]**:

| Guard | Kỳ vọng | Đo được |
|---|---|---|
| G1 · 3 guard fn là SECURITY INVOKER | `prosecdef=false` | `dma_write_is_privileged` **false** · `guard_learning_moments_actor` **false** · `guard_child_observations_actor` **false** ✅ |
| — · `guard_profiles_protected_cols` giữ DEFINER | `true` | **true** ✅ |
| G3 · 2 trigger enabled | `tgenabled='O'` | cả hai **O** ✅ |
| G4 · anon hết quyền ghi | 0 | `table_privileges` cho anon INSERT/UPDATE/DELETE: **rỗng** ✅ |
| G4b · authenticated hết DELETE | 0 | **rỗng** ✅ |
| G5 · authority column không ghi được | 0 | xem §4.1 ✅ |
| G7 · write policy chỉ `{authenticated}` | 0 vi phạm | ✅ |
| G8 · 2 cột actor nullable | 2 | ✅ |
| G10 · Parent SELECT policy nguyên vẹn | tồn tại | ✅ |
| G11 · probe function đã drop | 0 | **0** ✅ |

### 4.1 Column whitelist thực tế sau apply **[DB]**

| Bảng · role · cmd | Cột |
|---|---|
| `learning_moments` · authenticated · **INSERT** | `class_id, lesson_version_id, program_id, session_id, uploaded_by` |
| `learning_moments` · authenticated · **UPDATE** | `album_id, caption, feedback_note, theme_tag, updated_at` |
| `child_observations` · authenticated · **INSERT** | `attendance, child_id, follow_up_needed, is_highlight, linked_moment_ids, needs_support, note, session_id, skills_observed, visibility` |
| `child_observations` · authenticated · **UPDATE** | (giống INSERT) |

**Không có** `approved_by` · `state` · `id` ở INSERT. **Không có** `uploaded_by` · `approved_by` · `state` · `class_id` · `session_id` · `program_id` · `lesson_version_id` · `created_at` ở UPDATE. **Không có** `recorded_by` · `updated_by` ở cả hai.

`uploaded_by` ở INSERT là **temporary Stage-A compat grant**, sẽ thu ở 106.

### 4.2 Sửa bắt buộc theo Owner — đã áp dụng đủ

| Owner yêu cầu | |
|---|---|
| Xoá `old_created_default()` | ✅ nhánh INSERT của `guard_child_observations_actor` **không chạm `created_at`**; nhánh UPDATE vẫn ghim `created_at := old.created_at` |
| Giữ RLS `uploaded_by = current_profile()` | ✅ |
| **revoke-table-then-grant-column-whitelist** | ✅ — preflight xác nhận anh đúng: production đang cấp **table-level**, column revoke sẽ vô hiệu |
| Không grant trigger function cho authenticated | ✅ `guard_*` bị `revoke all from public, authenticated, anon`, **không grant lại** |
| Helper execute tối thiểu | ✅ chỉ `dma_write_is_privileged` grant cho `authenticated`; `anon` bị revoke |
| Definer-context probe | ✅ §5 |
| Direct-path probe giữ | ✅ §6 |
| Probe function drop cuối migration | ✅ G11 |

## 5. DEFINER-CONTEXT PROBE RESULT

Tạo `__e3_probe_definer_context()` (SECURITY DEFINER, owner `postgres`, `search_path=''`, revoke public, grant authenticated), gọi dưới `SET LOCAL ROLE authenticated`:

| Đo | Kỳ vọng | Kết quả |
|---|---|---|
| `dma_write_is_privileged()` gọi **trực tiếp** bởi `authenticated` | `FALSE` | ✅ **FALSE** |
| `dma_write_is_privileged()` gọi **bên trong DEFINER** owner `postgres` | `TRUE` | ✅ **TRUE** |

➡️ **Mắt xích còn thiếu trong review pack đã được chứng minh empirically.** `current_user = 'postgres'` bên trong SECURITY DEFINER là hành vi thật trên production này, không phải suy đoán từ tài liệu. Probe function đã drop, G11 xác nhận.

## 6. DIRECT-PATH PROBE RESULT

Chạy dưới `SET LOCAL ROLE authenticated` + JWT claims của một GV thật (school `d1000000…0001`), fixture tự dọn:

| # | Ca | Kết quả |
|---|---|---|
| P0 | INSERT có cột `id` (ngoài whitelist) | ❌ **permission denied** — đúng như mong muốn (đây là lần fail #2 ở §3) |
| P1 | INSERT với `uploaded_by` = profile **khác** | ✅ bị override thành **actor thật** |
| P2 | `approved_by` sau INSERT | ✅ **NULL** |
| P3 | `state` sau INSERT | ✅ **`draft`** |
| P4 | UPDATE → `uploaded_by`/`approved_by`/`state` | ✅ **không đổi** (ghim về `old`) |
| P5 | UPDATE `caption` | ✅ **lưu được** — whitelist nghiệp vụ không bị chặn oan |
| — | Cleanup fixture | ✅ 0 dòng còn lại |

## 7. REAL-LOGIN QA — ⬜ **CHƯA CHẠY**

Em không đăng nhập trình duyệt được. Đây là phần **anh phải chạy** trước khi Stage A được tuyên bố PASS (D2/D3/D291 — migration success ≠ production PASS).

**Chạy với frontend CŨ đang chạy trên production** (chưa deploy Stage B) — chính điều này chứng minh containment không phụ thuộc client:

| # | Ca | Tài khoản | Kỳ vọng |
|---|---|---|---|
| S1 | `/teacher/session/<id>` → Bước 3 → tab **Ảnh** → thêm 1 ảnh | GV KHM Mỹ Linh · `gv.linh.kidshouse@demo.demenart.com` / `Test@123` | **Upload thành công như cũ.** Đây là ca quan trọng nhất — chứng minh Stage-A compat grant `uploaded_by` còn nguyên |
| S2 | Sửa chú thích ảnh vừa thêm | Mỹ Linh | ✅ lưu bình thường |
| S3 | Gắn / bỏ gắn bé vào ảnh | Mỹ Linh | ✅ như cũ |
| S4 | Xoá 1 ảnh draft (nút ×) | Mỹ Linh | ✅ như cũ (`remove_moment_media_service` là privileged path) |
| S5 | Điểm danh + nhận xét 1 bé + tick "chia sẻ với ba mẹ" | GV MNDM Ngọc Hân · `gv.han.demen@demo.demenart.com` / `Test@123` | ✅ tự lưu như cũ |
| S6 | Buổi `in_progress` → Bước 4 → **Hoàn tất & gửi nhật ký** | Mỹ Linh (hoặc GV đang là lead) | ✅ `ok`, ảnh tới ba mẹ |
| S7 | Gửi lại nhật ký lần 2 | như trên | ✅ nhánh idempotent chạy |
| S8 | Mở Hành trình của con, so với trước | PH KHM Nguyễn Văn Hùng · `ph.hung.kidshouse@demo.demenart.com` / `Test@123` | **Giống hệt** — không được đổi gì |
| S9 | Xem ảnh có bé chưa consent | PH MNDM Văn Thành · `ph.thanh.demen@demo.demenart.com` / `Test@123` | Consent gate **y như cũ** |
| S10 | Trang `/school/manage?tab=teachers` | Master MNDM Phương Dung · `hieutruong.demen@demo.demenart.com` / `Test@123` | ✅ như cũ |

Sau khi anh chạy, gửi em kết quả (chỉ cần "S1–S10 ok" hoặc chụp màn hình chỗ lỗi). Em sẽ đo lại **[DB]** attribution của dữ liệu mới sinh:

```sql
select id, created_at, uploaded_by, approved_by, state::text
from learning_moments where created_at > '2026-07-21' order by created_at;

select session_id, child_id, recorded_by, updated_by
from child_observations where recorded_by is not null;
```

⚠️ Nếu S1 fail, dừng ngay và báo em — đó là cửa gãy duy nhất còn có thể xảy ra, và R1 (`disable trigger`) là biện pháp khẩn.

## 8. FORENSIC COUNTS — BEFORE → AFTER

| Chỉ số | Trước 105 | Sau 105 | |
|---|---|---|---|
| `learning_moments` | 18 | **18** | ✅ |
| `state='approved'` | 11 | **11** | ✅ |
| `approved` + `approved_by IS NULL` | 6 | **6** | ✅ |
| `uploaded_by` cross-school | 0 | **0** | ✅ |
| `child_observations` | 5 | **5** | ✅ |
| `recorded_by IS NOT NULL` | — | **0** | ✅ không backfill |
| `updated_by IS NOT NULL` | — | **0** | ✅ |
| Tables · secdef · policies | 87 · 196 · 165 | **87 · 196 · 165** | ✅ không phình |
| Migrations | 104 | **105** | ✅ |

## 9. EVIDENCE — KHÔNG CÓ LEGACY REWRITE

- G9 (trong transaction) và G12 (sau probe) đều kiểm đúng 5 con số trên; sai một cái là `RAISE EXCEPTION` ⇒ rollback.
- Kiểm lại độc lập **sau apply**, ngoài transaction: tất cả khớp.
- **ANOMALY-1 nguyên vẹn** **[DB]**:
  `f51039be-48e8-42c5-9900-b03f3472cd1f` → `state='approved'` · `approved_by = NULL` · `updated_at = 2026-07-09 07:31:01.160368+00` — **không đổi một byte**. Không backfill, đúng chỉ đạo §6.
- Fixture của probe đã xoá; `learning_moments` vẫn đúng 18 dòng sau probe.

## 10. WP1 STAGE A VERDICT

> **STAGE A — DATABASE CONTAINMENT APPLIED · PENDING REAL-LOGIN QA**

Đã đóng ở tầng database, có bằng chứng in-transaction:

| | |
|---|---|
| ✅ Forged `uploaded_by` | trigger override |
| ✅ Mutable `uploaded_by` | ghim về `old` |
| ✅ Forged `approved_by` | ép NULL khi tạo, ghim khi sửa, mất cả column grant |
| ✅ Direct client approval | `state` ép `draft`, ghim khi sửa, mất column grant |
| ✅ Anon write access | mất toàn bộ table grant + policy thu về `authenticated` |
| ✅ Profile-state self-edit | `guard_profiles_protected_cols` ghim `state` |
| ✅ Observation actor capture | `recorded_by` bất biến · `updated_by` theo actor · client không ghi được |

**Chưa PASS** cho tới khi §7 real-login xanh. Em **không** tuyên bố Stage A PASS lúc này.

## 11. E3-SG-01 STATUS

> **E3-SG-01 — PARTIALLY CONTAINED; AUTHORITY SEMANTICS PENDING WP4**

**KHÔNG đóng.** Điều kiện *"không approve khi không có đúng session responsibility"* vẫn phụ thuộc `is_session_lead` (hồi tố) — chỉ đóng sau khi WP4 thay bằng session-level responsible authority.

## 12. NEXT ACTION

**Chờ anh chạy §7 real-login QA Stage A.** Xanh ⇒ em vào **Stage B**: paste-over `teacher.session.$id.tsx` (2 chỗ: bỏ `uploaded_by` khỏi INSERT payload; gỡ `const { profile } = useCurrentProfile()` trong `PhotoTab`), build/typecheck, commit, Cloudflare deploy, hard reload, tạo 1 moment thật, verify actor không NULL.

**Chưa được và sẽ không làm:** deploy frontend trước khi QA xanh · apply 106 trước khi verify frontend production · mở WP2 · claim `E3-SG-01 CLOSED` · sửa ANOMALY-1 · sửa Parent UI · đổi journal authority.

---

## PHỤ LỤC — D-RULE ĐỀ XUẤT CHO CLOSEOUT

| # | Nội dung |
|---|---|
| **D310** | Column-level `REVOKE` **không** phủ định table-level grant còn tồn tại. Muốn thu quyền ghi phải `REVOKE ... ON TABLE` trước, rồi `GRANT (cols)`. Verify bằng `has_table_privilege` **và** `has_column_privilege`, không chỉ `information_schema.column_privileges` — view đó biểu diễn table grant thành quyền trên mọi cột. |
| **D311** | Privileged-write detection dùng `current_user = 'postgres'`. Ba function `dma_write_is_privileged` · `guard_learning_moments_actor` · `guard_child_observations_actor` **phải** là `SECURITY INVOKER`; đổi sang DEFINER làm containment sập im lặng. Migration phải có guard `prosecdef = false`. Mọi DEFINER function owner `postgres` ghi `learning_moments`/`child_observations` đi qua privileged path và **tự chịu trách nhiệm invariant**. |
| **D312** | `service_role` có `BYPASSRLS = true` ⇒ RLS một mình không bao giờ đủ để bảo vệ attribution. Containment phải ở tầng trigger; RLS là lớp phụ. |

---

*V114B-E3 · Phase 2 · WP1 Stage A · migration 105 applied · HEAD `7ee7eeba` unchanged · no code changed · no deploy.*
