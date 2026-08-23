# DMA — V114B-E3 · WP1 · STAGE B HANDOFF (INTERIM)

> **INTERIM ARTIFACT.** Không phải closeout. RULES / SYSTEM_MAP **không đổi**. WP1 **chưa đóng**.
> Ngày: 2026-07-21 · HEAD `85e24768` · migration count **105**

---

## 1. STAGE A — DATABASE CONTAINMENT · **PASS**

Migration 105 đóng ở tầng database, có bằng chứng in-transaction + verify độc lập sau apply:

| Lỗ hổng | Cơ chế đóng |
|---|---|
| Forged `uploaded_by` | trigger override bằng `current_profile()` |
| Mutable `uploaded_by` | ghim về `old` khi UPDATE |
| Forged `approved_by` | ép NULL khi tạo · ghim khi sửa · mất column grant |
| Direct client approval | `state` ép `draft` · ghim khi sửa · mất column grant |
| Anon write access | mất toàn bộ table grant · policy thu về `authenticated` |
| `profiles.state` self-edit | `guard_profiles_protected_cols` ghim `state` |
| Observation actor (E3-07) | `recorded_by` bất biến · `updated_by` theo actor · client không ghi được |

**Cơ chế privileged path:** `current_user = 'postgres'`. Đã chứng minh empirically trong transaction — `dma_write_is_privileged()` trả `TRUE` bên trong SECURITY DEFINER owner `postgres`, `FALSE` khi `authenticated` gọi trực tiếp. `service_role` **không** được miễn trừ.

Không legacy rewrite: `approved + approved_by NULL` giữ đúng 6 · legacy observation `recorded_by` NULL giữ đúng 5 · **ANOMALY-1 `f51039be-…` không đổi một byte** (`approved` · `approved_by` NULL · `updated_at` 2026-07-09 07:31:01.160368+00).

## 2. STAGE B — FRONTEND CUTOVER · **PASS**

`src/routes/_authenticated/teacher.session.$id.tsx` — 2 thay đổi trong `PhotoTab`:

1. Gỡ `uploaded_by: profile?.id ?? null,` khỏi INSERT payload của `learning_moments`
2. Gỡ `const { profile } = useCurrentProfile();` (thành biến vô dụng → `noUnusedLocals`)

`import { useCurrentProfile }` giữ nguyên (`SessionFlow` vẫn dùng). Build/typecheck xanh. Cloudflare CI deploy từ `main`. Hard reload production đã làm.

**Ghi chú phạm vi:** editor tự chạy Prettier nên commit chứa thêm ~12 chỗ reformat ngoài 2 dòng đã duyệt (xoá dòng trắng, wrap JSX, bỏ ngoặc dư). Đã đọc từng chỗ — **không chỗ nào đổi hành vi**; text tiếng Việt bị wrap vẫn render y hệt do JSX gộp khoảng trắng.

## 3. COMMIT

```
85e24768394be812f08a05c4f2694a8d1176427b
"Code edited in Lovable Code Editor" · manual_update · 2026-07-21T10:32:02Z
parent: 7ee7eeba721c4a3c3207530fac3a3901252b9fe5
```

## 4. MOMENT VERIFICATION — moment đầu tiên tạo mà client KHÔNG gửi actor

| Trường | Giá trị |
|---|---|
| `id` | **`79fe0562-99f9-4d95-ae52-94ccec422307`** |
| `created_at` | 2026-07-21 10:33:57.385626+00 |
| `uploaded_by` | `d1000000-0000-4000-8000-000000000011` — **Đặng Mỹ Linh**, **database-derived** |
| `approved_by` | **NULL** |
| `state` | **`draft`** |
| same-school | uploader `d1000000-…0001` = moment `d1000000-…0001` → **PASS** |
| `session_id` | `aaaa0000-0000-4000-8000-0000000a0002` |
| media active / bé gắn | 1 / 3 |
| **`uploaded_by` NULL mới** | **0** |
| cross-school mới | **0** |

Ảnh chụp màn hình Teacher Portal khớp DB: card draft, có nút gỡ ảnh, chưa có nhãn "Đã gửi tới ba mẹ".

## 5. MIGRATION 105 — IDENTITY

| | |
|---|---|
| version | `20260721094857` |
| name | `v114b_e3_wp1_security_containment` |
| `md5(statements)` | **`30f29f7f94c300a0ad234ec8ec5cadf1`** |
| số statement | 1 (một khối atomic) |
| migration inventory sau apply | **105** |

Objects: `dma_write_is_privileged()` · `guard_learning_moments_actor()` · `guard_child_observations_actor()` (cả 3 **SECURITY INVOKER**, `prosecdef=false` đã verify) · `guard_profiles_protected_cols()` (DEFINER, replaced) · 2 trigger · `child_observations.recorded_by` + `.updated_by` (nullable, FK `ON DELETE RESTRICT`) · 4 policy tái tạo `TO authenticated`.

Probe function `__e3_probe_definer_context()` đã drop trong cùng migration; residue = 0.

### Grant hiện tại (sau 105, trước 106)

| Bảng · cmd | Cột `authenticated` |
|---|---|
| `learning_moments` INSERT | `class_id, lesson_version_id, program_id, session_id,` **`uploaded_by`** ← temporary compat |
| `learning_moments` UPDATE | `album_id, caption, feedback_note, theme_tag, updated_at` |
| `child_observations` INSERT/UPDATE | `attendance, child_id, follow_up_needed, is_highlight, linked_moment_ids, needs_support, note, session_id, skills_observed, visibility` |
| `anon` | **không có quyền ghi nào** |

Table-level INSERT/UPDATE/DELETE đã revoke khỏi `authenticated` và `anon` — column grant là đường ghi duy nhất.

## 6. MIGRATION 106 — SQL ĐANG CHỜ (CHƯA APPLY)

```sql
-- 106_v114b_e3_wp1_grant_hardening
-- BLOCK 1: khong DDL

-- BLOCK 2 — thu temporary compat grant `uploaded_by`
revoke insert on public.learning_moments from authenticated;

grant insert (
  session_id,
  class_id,
  program_id,
  lesson_version_id
) on public.learning_moments to authenticated;

-- BLOCK 3 — verify
do $blk$
declare n int;
begin
  if has_column_privilege('authenticated','public.learning_moments','uploaded_by','INSERT')
     or has_column_privilege('authenticated','public.learning_moments','approved_by','INSERT')
     or has_column_privilege('authenticated','public.learning_moments','state','INSERT')
     or has_column_privilege('authenticated','public.learning_moments','id','INSERT')
  then raise exception '106 FAIL: con grant INSERT tren protected column'; end if;

  if not has_column_privilege('authenticated','public.learning_moments','session_id','INSERT')
     or not has_column_privilege('authenticated','public.learning_moments','class_id','INSERT')
     or not has_column_privilege('authenticated','public.learning_moments','program_id','INSERT')
     or not has_column_privilege('authenticated','public.learning_moments','lesson_version_id','INSERT')
  then raise exception '106 FAIL: final INSERT whitelist bi thu nham'; end if;

  select count(*) into n from information_schema.column_privileges
   where table_schema='public' and table_name='learning_moments' and grantee='authenticated'
     and privilege_type='UPDATE'
     and column_name in ('caption','theme_tag','album_id','feedback_note','updated_at');
  if n <> 5 then raise exception '106 FAIL: UPDATE whitelist bi thu nham (thay %)', n; end if;

  if has_table_privilege('authenticated','public.learning_moments','INSERT')
     and not has_column_privilege('authenticated','public.learning_moments','session_id','INSERT')
  then raise exception '106 FAIL: table-level grant con sot'; end if;

  raise notice '106 PASS';
end $blk$;
```

**Final INSERT whitelist:** `session_id` · `class_id` · `program_id` · `lesson_version_id`.

## 7. LÝ DO HOÃN

Owner quyết **A — DEFER**:

- 105 đã containment đầy đủ việc giả mạo và rewrite attribution.
- Stage B production đã PASS.
- 106 **chỉ** thu temporary compatibility grant `uploaded_by`; **không đóng thêm vulnerability nào**.
- Không chấp nhận gây gián đoạn buổi dạy chỉ để đạt least privilege sớm vài giờ.

## 8. RỦI RO — STALE FRONTEND BUNDLE

Sau 106, bất kỳ tab nào còn giữ bundle **trước** `85e24768` vẫn gửi `uploaded_by` trong INSERT payload ⇒ PostgREST trả **`403 permission denied for column uploaded_by`**, UI hiện *"Không tạo được khoảnh khắc."*

Đặc điểm rủi ro: giáo viên **không tự biết** cần reload; lỗi rơi đúng vào lúc đang dạy; không có cơ chế ép client refresh. ⇒ chỉ apply trong khung giờ thấp điểm.

## 9. PREFLIGHT + QA BẮT BUỘC TRƯỚC KHI APPLY 106

Chỉ chạy sau khi Owner nói **`GO STAGE C`**. Verify read-only, đủ 10 mục:

1. `main` vẫn chứa `85e24768` hoặc descendant đã verify
2. Production bundle mới đang chạy
3. Không có `uploaded_by IS NULL` mới
4. Không có cross-school attribution mới
5. Không có lỗi `lm_guard` / `co_guard` bất thường trong logs
6. **Không có write activity đáng kể lên `learning_moments` / `child_observations` trong 30 phút gần nhất**
7. Không có dấu hiệu trường đang thao tác dạy học thực tế
8. Migration inventory vẫn **105**
9. SQL 106 chỉ thu temporary INSERT grant `uploaded_by`
10. Final INSERT whitelist đúng 4 cột ở §6

⚠️ **Không** dựa riêng vào `session_state='in_progress'` để kết luận trường đang hoạt động — state có thể cũ. Phải kết hợp recent write activity (mục 6).

### Sau khi apply 106 — verify bắt buộc

- Grant protected column cũ đã mất
- Final INSERT whitelist đúng
- Frontend production tạo moment mới **thành công**
- `uploaded_by` do trigger gán đúng actor · `approved_by` NULL · `state` `draft`
- `uploaded_by` NULL mới = 0
- Caption / update workflow vẫn PASS
- Parent regression không đổi
- Không có guard error bất thường

Chỉ khi **toàn bộ** PASS mới được tuyên bố **WP1 — FORMALLY PASS / CLOSED**.

## 10. TRẠNG THÁI DỨT KHOÁT

| | |
|---|---|
| WP1 Stage A | **PASS** |
| WP1 Stage B | **PASS** |
| WP1 Stage C | **PENDING** — chờ `GO STAGE C` |
| **WP1** | **NOT FORMALLY CLOSED** |
| **E3-SG-01** | **PARTIALLY CONTAINED; AUTHORITY SEMANTICS PENDING WP4** — **không** đóng |
| `DMA_RULES.md` | **KHÔNG ĐỔI** |
| `DMA_SYSTEM_MAP.md` | **KHÔNG ĐỔI** |
| D310–D312 | **candidate rules for E3 milestone closeout** — chưa gán D-number canonical |
| HEAD | `85e24768` |
| Migration count | **105** |
| WP2 | **chưa mở** |

### QA debt đang mở

**CONSENT-NEGATIVE-FIXTURE** — duy trì một fixture QA chuyên biệt có approved single-child moment, trong đó child thiếu `display_in_app`, để kiểm thử UI `consent_missing` mà không sửa dữ liệu vận hành hoặc enrollment thật.

Bối cảnh: quét toàn bộ 31 cặp parent × moment cho action `view` → `consent_missing` = **0** · allowed 28 · `moment_not_approved` 3. Parent Portal chỉ gọi `media_consent_check(..., 'view')` (`get_signed_media_url` v23 hardcode), nên các verdict `consent_missing` ở `download`/`share` không tới được từ UI. S9 phân loại: **NOT EXECUTABLE WITH CURRENT DATASET; COMPENSATING EVIDENCE PASS**.

---

*Interim handoff · V114B-E3 · WP1 Stage B · không canonicalize · không closeout.*
