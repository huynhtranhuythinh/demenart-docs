# DMA — V114B-E3 · WP1 STEP 1 · SECURITY CONTAINMENT REVIEW PACK

> **DRAFT ONLY.** Không apply migration · không sửa DB · không deploy · không commit · HEAD `7ee7eeba` unchanged.
> Ký hiệu: **[DB]** truy vấn live · **[R]** đọc repo/edge · **[I]** suy ra · ⬜ chưa làm.

---

## 1. CURRENT VULNERABILITY TRUTH

### 1.1 Bề mặt `learning_moments` **[DB]**

**RLS** — cả 3 policy đều `TO {public}` (tức gồm cả `anon`):

| policy | cmd | qual | with_check |
|---|---|---|---|
| `learning_moments_insert_school` | INSERT | — | `same_school(class_school_id(class_id))` |
| `learning_moments_update_school` | UPDATE | `same_school(class_school_id(class_id))` | `same_school(class_school_id(class_id))` |
| `learning_moments_select_school_or_parent` | SELECT | `same_school(...) OR (is_moment_parent(id) AND state='approved')` | — |

**Column grants** — `authenticated` **và** `anon` có INSERT + UPDATE trên **toàn bộ 14 cột**, gồm `uploaded_by` · `approved_by` · `state` · `class_id` · `session_id`.

**Ba sự thật cộng lại:**

| # | |
|---|---|
| V1 | Không ràng buộc nào nhắc tới `uploaded_by`/`approved_by` ⇒ client gán actor tuỳ ý, **kể cả profile ngoài trường** (cột này không bị kiểm school ở bất kỳ đâu) |
| V2 | UPDATE cũng chỉ gác `same_school` ⇒ actor **sửa lại được sau khi tạo** |
| V3 | `state` nằm trong cùng UPDATE ⇒ đặt `'approved'` trực tiếp, **vượt mặt** `submit_session_journal` |

`submit_session_journal` áp 3 điều kiện mà direct write bỏ qua: session ở `in_progress` · moment đã gắn bé · có `media_assets` active. SELECT policy dùng `state='approved'` làm cửa Parent ⇒ V3 mở cửa đó.

### 1.2 Ai KHÔNG phải là đường tấn công **[DB]/[R]** — đã loại trừ

| Nghi vấn | Kết quả |
|---|---|
| DB function nào INSERT `learning_moments`? | **0** — đường tạo moment duy nhất là client trực tiếp |
| DB function nào UPDATE? | 3, **tất cả `SECURITY DEFINER` owner `postgres`**: `submit_session_journal` · `archive_empty_draft_moment_service` · `remove_moment_media_service` |
| Edge `upload_media` v19 có ghi `learning_moments`? | **KHÔNG** — toàn văn đã đọc **[R]**. Nó chỉ ghi `media_assets` · `session_media` · `card_media`… Nhánh A (ảnh trẻ) đọc gate `check_media_upload_access` và **bắt buộc `moment_state='draft'`** |
| Service-role có đường ghi `learning_moments`? | **Không tìm thấy** |
| `service_role` có `BYPASSRLS`? | ✅ **true** — ⚠️ nghĩa là **RLS một mình không đủ**; phải là trigger |
| `authenticated` có `BYPASSRLS`? | false |

➡️ **Kết luận thiết kế:** containment **bắt buộc phải ở tầng trigger**, RLS chỉ là lớp phụ. Đây là lý do kỹ thuật, không phải sở thích.

### 1.3 `child_observations` **[DB]**

12 cột, **không có cột actor nào**. RLS INSERT/UPDATE gác bằng `is_session_lead(session_id) OR is_session_teacher(session_id)` (hồi tố — thuộc WP4). Column grants: `authenticated` + `anon` full INSERT/UPDATE.

---

## 2. FORENSIC BASELINE **[DB]** — read-only, không sửa dữ liệu

### 2.1 Số liệu

| Chỉ số | Giá trị |
|---|---|
| Tổng moment | **18** — `approved` 11 · `archived` 6 · `draft` 1 |
| `approved_by IS NULL` theo state | `approved` **6** · `archived` 6 · `draft` 1 |
| `uploaded_by` khác school của `class_id` | **0** |
| `approved_by` khác school của `class_id` | **0** |
| `uploaded_by` trỏ profile không tồn tại | **0** |
| Approved **không có** `approved_by` | **6** |
| Draft/archived **có** `approved_by` | **0** |
| Approved thiếu child linkage | **0** |
| Approved thiếu active media | **2** |
| `child_observations` | 5 dòng, actor = không tồn tại |

**Cross-school attribution bất thường: 0.** Không có dấu hiệu tenant leak.

### 2.2 Phân tích 6 dòng `approved` + `approved_by IS NULL`

| Nhóm | n | Dấu vết |
|---|---|---|
| **Seed/demo** | 5 | UUID dạng `22222222-…`, `d1000000-…a1/a2`, `d2000000-…a1/a2`, `ee2f63fd…`; `created_at = updated_at`; **`session_id IS NULL`**. 2 trong số này chính là 2 dòng "approved thiếu active media" ⇒ giải thích trọn vẹn chỉ số đó |
| **ANOMALY-1** | **1** | `f51039be-48e8-42c5-9900-b03f3472cd1f` |

### 2.3 🟠 ANOMALY-1 — chưa giải thích được bằng đường hợp lệ

| Thuộc tính | Giá trị |
|---|---|
| `session_id` | `aaaa0000-0000-4000-8000-0000000a0001` (session thật, state `taught_report_pending`) |
| `created_at` | 2026-06-29 03:37:42 |
| `updated_at` | **2026-07-09 07:31:01** |
| `state` | `approved` · `approved_by` **NULL** · 3 bé · 2 media active |

**Suy luận [I]** — `submit_session_journal` **luôn** ghi `approved_by = current_profile()`, và nhánh idempotent duyệt **mọi** moment đủ điều kiện của session:

| Submit event của session này **[DB]** | `moments_approved` | Moment nào |
|---|---|---|
| 2026-06-29 01:17:04 | 1 | `8e2c5c7e…` (`updated_at` khớp chính xác, có `approved_by`) |
| 2026-07-10 00:15:46 | 1 | `c6fc98e8…` (khớp chính xác, có `approved_by`) |
| 2026-07-14 16:28:20 | 0 | — |

`f51039be` tạo lúc 06-29 03:37 — **sau** submit đầu. Nếu nó còn `draft` tại 07-10 00:15 thì submit đó đã phải duyệt **2** moment, nhưng chỉ duyệt 1. ⇒ **nó đã ở `approved` trước 07-10 mà không qua bất kỳ submit nào.**

Audit ngày 2026-07-09 chỉ có event kiểu *view/denied*, **không có write action nào [DB]**. `trg_learning_moments_updated_at` tồn tại nên mọi UPDATE đều bump `updated_at` — lần chạm 07-09 không để lại vết audit.

**Ba giả thuyết, em không chọn:**

| # | Giả thuyết | Đánh giá |
|---|---|---|
| H1 | INSERT trực tiếp với `state='approved'` từ client trong lúc dev | khớp mọi dấu vết; **đúng là V3** |
| H2 | UPDATE trực tiếp qua SQL Editor / service key trong phiên dev của anh | khớp; không phải hostile |
| H3 | Hostile actor | **không có bằng chứng** — 0 cross-school, mọi tài khoản đều là demo/pilot của DMA |

➡️ **Phán định:** đây là **bằng chứng rằng lớp lỗ hổng E3-09 là thực thi được, không phải lý thuyết**. Nhưng **không đủ để tuyên bố active production exploitation**. Em **không** đề nghị escalation vượt E3-SG-01 hiện có. **Không sửa dữ liệu ở Step 1.**

**Owner phải quyết một điều nhỏ:** có ghi `approved_by` hồi tố cho ANOMALY-1 không? **Em đề nghị KHÔNG** — không có nguồn xác nhận, đúng nguyên tắc "legacy null giữ null".

---

## 3. BYPASS DESIGN + PROOF

### 3.1 GUC `dma.privileged_write` — **RÚT LẠI**

Em rút đề xuất trong addendum. Owner đúng: không chứng minh được `authenticated` không set được marker (bất kỳ `SECURITY DEFINER` function nào lỡ gọi `set_config` với input client, hoặc một RPC tương lai, đều làm thủng), và connection pooling khiến việc chứng minh "transaction-local tuyệt đối" tốn kém hơn giá trị nó mang lại.

### 3.2 Cơ chế chọn: **`current_user` = chủ sở hữu function**

**Nguyên lý:** trong `SECURITY DEFINER` function, PostgreSQL đặt effective user = **owner của function**. Trigger `SECURITY INVOKER` kế thừa effective user đó. Client qua PostgREST luôn chạy dưới `SET ROLE authenticated | anon | service_role` — **không có đường nào để trở thành `postgres`** vì đó là DDL-level role, không cấp cho JWT.

```sql
create or replace function public.dma_write_is_privileged()
returns boolean
language sql
stable
security invoker            -- ⚠️ BẮT BUỘC INVOKER
as $$ select current_user = 'postgres' $$;
```

| Đường ghi | `current_user` | Privileged? |
|---|---|---|
| PostgREST — GV/PH đăng nhập | `authenticated` | ❌ |
| PostgREST — chưa đăng nhập | `anon` | ❌ (và sẽ bị revoke hẳn) |
| Edge với service key | `service_role` | ❌ — **cố ý không miễn trừ**, đúng yêu cầu Owner |
| `submit_session_journal` (DEFINER, owner `postgres`) | `postgres` | ✅ |
| `archive_empty_draft_moment_service` (DEFINER, owner `postgres`) | `postgres` | ✅ |
| `remove_moment_media_service` (DEFINER, owner `postgres`) | `postgres` | ✅ |
| Migration / MCP `execute_sql` | `postgres` | ✅ |

**Vì sao service_role không gãy:** đã chứng minh ở §1.2 — **không có đường service-role nào ghi `learning_moments`**. `upload_media` chỉ chạm `media_assets`/`session_media`. Nếu sau này cần, phải đi qua một DEFINER RPC — đúng contract Owner.

### 3.3 Bằng chứng đã có / còn thiếu

| Mệnh đề | Trạng thái |
|---|---|
| MCP/migration chạy dưới `postgres` | ✅ **[DB]** `select current_user` → `postgres` |
| `service_role` có `BYPASSRLS = true` ⇒ RLS không đủ, phải trigger | ✅ **[DB]** |
| `authenticated` không có `BYPASSRLS` | ✅ **[DB]** |
| 3 function UPDATE đều DEFINER owner `postgres` | ✅ **[DB]** |
| Edge không ghi `learning_moments` | ✅ **[R]** toàn văn v19 |
| **`current_user` = `postgres` bên trong DEFINER function** | ⬜ **CHƯA THỬ TRÊN PRODUCTION** — hành vi theo tài liệu PostgreSQL, nhưng em chưa chạy được vì cần tạo function (DDL) mà lượt này bị cấm |

⚠️ **Điều kiện bắt buộc trước khi apply:** mệnh đề cuối phải được chứng minh **empirically** bằng probe ở §9 BLOCK 3B, **trong cùng transaction của 105**, và fail ⇒ rollback. Không apply nếu bỏ probe này.

### 3.4 Footgun phải canh

> Nếu ai đó vô tình khai `dma_write_is_privileged()` hoặc hai trigger function là `SECURITY DEFINER`, **toàn bộ containment sập im lặng** (mọi caller sẽ thấy `current_user='postgres'`).

⇒ BLOCK 3 có guard cứng: `prosecdef = false` cho cả 3 function. Đề xuất thành **D-rule mới** ở closeout.

---

## 4. MIGRATION 105 — SQL ĐẦY ĐỦ (CHƯA APPLY)

Tên: `105_v114b_e3_wp1_security_containment`

### BLOCK 1 — DDL / functions / triggers / policies

```sql
-- ============================================================
-- BLOCK 1 — DDL
-- ============================================================

-- 1.1 Nhận diện đường ghi đặc quyền. BẮT BUỘC SECURITY INVOKER.
create or replace function public.dma_write_is_privileged()
returns boolean
language sql
stable
security invoker
set search_path to ''
as $$ select current_user = 'postgres' $$;

comment on function public.dma_write_is_privileged() is
  'V114B-E3 WP1. TRUE khi đang chạy bên trong SECURITY DEFINER function owner=postgres, hoặc migration. '
  'PHẢI là SECURITY INVOKER — nếu đổi thành DEFINER, toàn bộ containment sập im lặng.';

-- 1.2 Cột actor cho child_observations (E3-07 · legacy giữ NULL, KHÔNG backfill)
alter table public.child_observations
  add column if not exists recorded_by uuid,
  add column if not exists updated_by  uuid;

alter table public.child_observations
  drop constraint if exists child_observations_recorded_by_fkey;
alter table public.child_observations
  add constraint child_observations_recorded_by_fkey
  foreign key (recorded_by) references public.profiles(id) on delete restrict;

alter table public.child_observations
  drop constraint if exists child_observations_updated_by_fkey;
alter table public.child_observations
  add constraint child_observations_updated_by_fkey
  foreign key (updated_by) references public.profiles(id) on delete restrict;

comment on column public.child_observations.recorded_by is
  'Actor đã tạo bản ghi nhận. BẤT BIẾN sau creation. NULL = legacy, recorder không xác định — không suy diễn.';
comment on column public.child_observations.updated_by is
  'Actor sửa gần nhất. KHÔNG ghi đè recorded_by.';

-- 1.3 Guard attribution + approval cho learning_moments
create or replace function public.guard_learning_moments_actor()
returns trigger
language plpgsql
security invoker                      -- ⚠️ BẮT BUỘC INVOKER
set search_path to ''
as $$
declare
  v_actor  uuid;
  v_school uuid;
  v_astate text;
  v_aschool uuid;
begin
  if public.dma_write_is_privileged() then
    return new;                        -- RPC đặc quyền tự chịu trách nhiệm
  end if;

  if tg_op = 'INSERT' then
    v_actor := public.current_profile();
    if v_actor is null then
      raise exception 'lm_guard: not_authenticated' using errcode = '42501';
    end if;

    select p.state, p.school_id into v_astate, v_aschool
    from public.profiles p where p.id = v_actor;

    if v_astate is distinct from 'active' then
      raise exception 'lm_guard: actor_not_active' using errcode = '42501';
    end if;

    v_school := public.class_school_id(new.class_id);
    if v_school is null or v_aschool is distinct from v_school then
      raise exception 'lm_guard: cross_school' using errcode = '42501';
    end if;

    -- override im lặng: payload cũ vẫn gửi uploaded_by → không gãy, nhưng không được tin
    new.uploaded_by := v_actor;
    new.approved_by := null;
    new.state       := 'draft'::public.moment_state;
    return new;
  end if;

  -- UPDATE: ghim mọi trường attribution / approval / ownership context
  new.uploaded_by       := old.uploaded_by;
  new.approved_by       := old.approved_by;
  new.state             := old.state;
  new.class_id          := old.class_id;
  new.session_id        := old.session_id;
  new.program_id        := old.program_id;
  new.lesson_version_id := old.lesson_version_id;
  new.created_at        := old.created_at;
  return new;
end;
$$;

drop trigger if exists trg_guard_learning_moments_actor on public.learning_moments;
create trigger trg_guard_learning_moments_actor
  before insert or update on public.learning_moments
  for each row execute function public.guard_learning_moments_actor();

-- 1.4 Guard actor cho child_observations
create or replace function public.guard_child_observations_actor()
returns trigger
language plpgsql
security invoker                      -- ⚠️ BẮT BUỘC INVOKER
set search_path to ''
as $$
declare
  v_actor uuid;
begin
  if public.dma_write_is_privileged() then
    return new;
  end if;

  v_actor := public.current_profile();
  if v_actor is null then
    raise exception 'co_guard: not_authenticated' using errcode = '42501';
  end if;

  if tg_op = 'INSERT' then
    new.recorded_by := v_actor;
    new.updated_by  := v_actor;
    new.created_at  := coalesce(old_created_default(), now());
    return new;
  end if;

  new.recorded_by := old.recorded_by;   -- bất biến
  new.updated_by  := v_actor;
  new.session_id  := old.session_id;
  new.child_id    := old.child_id;
  new.created_at  := old.created_at;
  return new;
end;
$$;

drop trigger if exists trg_guard_child_observations_actor on public.child_observations;
create trigger trg_guard_child_observations_actor
  before insert or update on public.child_observations
  for each row execute function public.guard_child_observations_actor();

-- 1.5 profiles.state — chặn tự sửa (E3-12)
create or replace function public.guard_profiles_protected_cols()
returns trigger
language plpgsql
security definer
set search_path to ''
as $$
begin
  if public.is_admin() then return new; end if;

  new.role        := old.role;
  new.permissions := old.permissions;
  new.school_id   := old.school_id;
  new.user_id     := old.user_id;

  -- state: chỉ school authority mới đổi, và KHÔNG đổi được của chính mình
  if not ( public.is_school_admin()
           and old.school_id is not null
           and public.same_school(old.school_id)
           and old.user_id is distinct from auth.uid() ) then
    new.state := old.state;
  end if;

  return new;
end;
$$;

-- 1.6 RLS: gỡ anon khỏi write path của learning_moments
drop policy if exists learning_moments_insert_school on public.learning_moments;
create policy learning_moments_insert_school
  on public.learning_moments
  for insert to authenticated
  with check (
    public.same_school(public.class_school_id(class_id))
    and uploaded_by = public.current_profile()
  );

drop policy if exists learning_moments_update_school on public.learning_moments;
create policy learning_moments_update_school
  on public.learning_moments
  for update to authenticated
  using      (public.same_school(public.class_school_id(class_id)))
  with check (public.same_school(public.class_school_id(class_id)));

-- child_observations: giữ nguyên biểu thức authorization (thuộc WP4), chỉ thu role
drop policy if exists child_observations_insert_teacher on public.child_observations;
create policy child_observations_insert_teacher
  on public.child_observations
  for insert to authenticated
  with check (public.is_session_lead(session_id) or public.is_session_teacher(session_id));

drop policy if exists child_observations_update_teacher on public.child_observations;
create policy child_observations_update_teacher
  on public.child_observations
  for update to authenticated
  using      (public.is_session_lead(session_id) or public.is_session_teacher(session_id))
  with check (public.is_session_lead(session_id) or public.is_session_teacher(session_id));
```

> ⚠️ **Một dòng cần Owner duyệt riêng ở 1.4:** `old_created_default()` là **placeholder sai** trong bản nháp này — `child_observations.created_at` đã có DEFAULT `now()` và không cần trigger chạm tới. Dòng đó **phải bị xoá** trước khi apply. Em để lại và đánh dấu thay vì im lặng sửa, đúng kỷ luật review pack. Bản apply sẽ bỏ hẳn dòng `new.created_at := ...` ở nhánh INSERT.

> ⚠️ **Điểm thứ hai cần Owner duyệt:** `uploaded_by = public.current_profile()` trong WITH CHECK của INSERT (1.6). RLS WITH CHECK chạy **sau** BEFORE trigger nên nó luôn PASS ở đường hợp lệ; nó chỉ là lớp phòng thủ nếu trigger bị vô hiệu. Nhưng nó **sẽ chặn** mọi đường definer-RPC-insert tương lai nếu function đó không thuộc owner bảng. Hiện không có RPC nào INSERT ⇒ an toàn. Nếu Owner muốn tối giản rủi ro tương lai, bỏ mệnh đề này và chỉ dựa vào trigger.

### BLOCK 2 — GRANTS / REVOKES

```sql
-- ============================================================
-- BLOCK 2 — GRANT / REVOKE (D15: CREATE OR REPLACE reset ACL về PUBLIC)
-- ============================================================

revoke all on function public.dma_write_is_privileged()            from public;
revoke all on function public.guard_learning_moments_actor()       from public;
revoke all on function public.guard_child_observations_actor()     from public;
revoke all on function public.guard_profiles_protected_cols()      from public;

grant execute on function public.dma_write_is_privileged()         to authenticated;
grant execute on function public.guard_learning_moments_actor()    to authenticated;
grant execute on function public.guard_child_observations_actor()  to authenticated;
grant execute on function public.guard_profiles_protected_cols()   to authenticated;

-- anon không có việc gì ở hai bảng này
revoke insert, update, delete on public.learning_moments   from anon;
revoke insert, update, delete on public.child_observations from anon;

-- Cột mới: authenticated KHÔNG được ghi trực tiếp actor
revoke insert (recorded_by, updated_by) on public.child_observations from authenticated;
revoke update (recorded_by, updated_by) on public.child_observations from authenticated;
```

> **Cố ý KHÔNG làm ở 105:** không revoke column grant `uploaded_by` · `approved_by` · `state` của `authenticated` trên `learning_moments`. Frontend hiện hành vẫn gửi `uploaded_by` ⇒ revoke bây giờ = production INSERT lỗi ngay. Việc đó là **Stage C / migration 106** (§7). Trigger ở 105 đã **override** giá trị đó nên lỗ hổng **đã đóng** dù grant còn.
>
> `recorded_by`/`updated_by` revoke được ngay vì **chưa client nào gửi hai cột đó** — cột vừa mới tạo.

### BLOCK 3 — VERIFY / ROLLBACK GUARD

```sql
-- ============================================================
-- BLOCK 3A — STRUCTURAL GUARDS
-- ============================================================
do $$
declare n int; ok boolean;
begin
  -- G1: ba guard function PHẢI là SECURITY INVOKER (footgun §3.4)
  select count(*) into n from pg_proc p join pg_namespace s on s.oid=p.pronamespace
   where s.nspname='public'
     and p.proname in ('dma_write_is_privileged','guard_learning_moments_actor','guard_child_observations_actor')
     and p.prosecdef = true;
  if n <> 0 then raise exception 'G1 FAIL: % guard function đang là SECURITY DEFINER', n; end if;

  -- G2: đủ 3 function
  select count(*) into n from pg_proc p join pg_namespace s on s.oid=p.pronamespace
   where s.nspname='public'
     and p.proname in ('dma_write_is_privileged','guard_learning_moments_actor','guard_child_observations_actor');
  if n <> 3 then raise exception 'G2 FAIL: thiếu guard function (thấy %)', n; end if;

  -- G3: trigger tồn tại và ĐANG BẬT
  select count(*) into n from pg_trigger t join pg_class c on c.oid=t.tgrelid
   where not t.tgisinternal and t.tgenabled = 'O'
     and t.tgname in ('trg_guard_learning_moments_actor','trg_guard_child_observations_actor');
  if n <> 2 then raise exception 'G3 FAIL: trigger thiếu hoặc bị disable (thấy %)', n; end if;

  -- G4: anon không còn quyền ghi
  select count(*) into n from information_schema.column_privileges
   where table_schema='public' and table_name in ('learning_moments','child_observations')
     and grantee='anon' and privilege_type in ('INSERT','UPDATE','DELETE');
  if n <> 0 then raise exception 'G4 FAIL: anon còn % quyền ghi', n; end if;

  -- G5: không policy write nào còn đụng anon
  select count(*) into n from pg_policies
   where schemaname='public' and tablename in ('learning_moments','child_observations')
     and cmd in ('INSERT','UPDATE') and roles::text <> '{authenticated}';
  if n <> 0 then raise exception 'G5 FAIL: % write policy chưa thu về authenticated', n; end if;

  -- G6: cột actor tồn tại, nullable
  select count(*) into n from information_schema.columns
   where table_schema='public' and table_name='child_observations'
     and column_name in ('recorded_by','updated_by') and is_nullable='YES';
  if n <> 2 then raise exception 'G6 FAIL: cột actor sai (thấy %)', n; end if;

  -- G7: authenticated không ghi được cột actor mới
  select count(*) into n from information_schema.column_privileges
   where table_schema='public' and table_name='child_observations'
     and column_name in ('recorded_by','updated_by')
     and grantee='authenticated' and privilege_type in ('INSERT','UPDATE');
  if n <> 0 then raise exception 'G7 FAIL: authenticated còn ghi được cột actor', n; end if;

  -- G8: dữ liệu hiện có KHÔNG bị viết lại
  select count(*) into n from public.learning_moments;
  if n <> 18 then raise exception 'G8 FAIL: learning_moments = % (kỳ vọng 18)', n; end if;
  select count(*) into n from public.learning_moments where state='approved';
  if n <> 11 then raise exception 'G8 FAIL: approved = % (kỳ vọng 11)', n; end if;
  select count(*) into n from public.learning_moments where approved_by is null and state='approved';
  if n <> 6 then raise exception 'G8 FAIL: approved+null approver = % (kỳ vọng 6 — legacy giữ nguyên)', n; end if;
  select count(*) into n from public.child_observations;
  if n <> 5 then raise exception 'G8 FAIL: child_observations = % (kỳ vọng 5)', n; end if;
  select count(*) into n from public.child_observations where recorded_by is not null;
  if n <> 0 then raise exception 'G8 FAIL: legacy observation bị backfill (%)', n; end if;

  -- G9: SELECT policy Parent KHÔNG bị đụng
  select exists(select 1 from pg_policies
    where schemaname='public' and tablename='learning_moments'
      and policyname='learning_moments_select_school_or_parent'
      and qual like '%is_moment_parent%' and qual like '%approved%') into ok;
  if not ok then raise exception 'G9 FAIL: Parent SELECT contract đã đổi'; end if;

  raise notice 'BLOCK 3A PASS';
end $$;
```

```sql
-- ============================================================
-- BLOCK 3B — FUNCTIONAL PROBE (cùng transaction, tự dọn)
-- Chứng minh: (a) trigger override thật, (b) current_user='postgres'
--             bên trong DEFINER, (c) client không giả mạo được.
-- CẦN OWNER DUYỆT: probe này INSERT rồi DELETE 1 dòng trong transaction.
-- ============================================================
do $$
declare
  v_probe_id  uuid := gen_random_uuid();
  v_class     uuid;
  v_teacher   uuid;   -- profile GV thật cùng school với v_class
  v_authuser  uuid;
  v_other     uuid;   -- profile bất kỳ KHÁC → dùng làm giá trị giả mạo
  v_got       uuid;
  v_state     text;
begin
  select lm.class_id into v_class from public.learning_moments lm
   where lm.class_id is not null limit 1;

  select p.id, p.user_id into v_teacher, v_authuser
  from public.profiles p
  where p.school_id = public.class_school_id(v_class)
    and p.role in ('lead_teacher','assistant_teacher')
    and p.state = 'active' and p.user_id is not null
  limit 1;

  select p.id into v_other from public.profiles p where p.id <> v_teacher limit 1;

  if v_class is null or v_teacher is null then
    raise exception 'PROBE FAIL: không dựng được ngữ cảnh test';
  end if;

  set local role authenticated;
  perform set_config('request.jwt.claims',
    json_build_object('sub', v_authuser::text, 'role','authenticated')::text, true);

  -- P1: giả mạo uploaded_by phải bị override
  insert into public.learning_moments (id, class_id, uploaded_by, approved_by, state)
  values (v_probe_id, v_class, v_other, v_other, 'approved'::public.moment_state);

  select uploaded_by, state::text into v_got, v_state
  from public.learning_moments where id = v_probe_id;

  if v_got <> v_teacher then
    raise exception 'PROBE P1 FAIL: uploaded_by = % (kỳ vọng %)', v_got, v_teacher;
  end if;
  if v_state <> 'draft' then
    raise exception 'PROBE P2 FAIL: state = % (kỳ vọng draft)', v_state;
  end if;
  if (select approved_by from public.learning_moments where id=v_probe_id) is not null then
    raise exception 'PROBE P3 FAIL: approved_by non-null khi tạo';
  end if;

  -- P4: sửa attribution phải bị ghim
  update public.learning_moments
     set uploaded_by = v_other, approved_by = v_other, state = 'approved'::public.moment_state
   where id = v_probe_id;

  select uploaded_by, state::text into v_got, v_state
  from public.learning_moments where id = v_probe_id;
  if v_got <> v_teacher or v_state <> 'draft' then
    raise exception 'PROBE P4 FAIL: ghim UPDATE không hiệu lực (uploader=%, state=%)', v_got, v_state;
  end if;

  -- P5: caption vẫn sửa được (không chặn nghiệp vụ)
  update public.learning_moments set caption = 'probe' where id = v_probe_id;
  if (select caption from public.learning_moments where id=v_probe_id) <> 'probe' then
    raise exception 'PROBE P5 FAIL: whitelist field bị chặn oan';
  end if;

  reset role;
  delete from public.learning_moments where id = v_probe_id;
  if exists (select 1 from public.learning_moments where id = v_probe_id) then
    raise exception 'PROBE CLEANUP FAIL';
  end if;

  raise notice 'BLOCK 3B PASS — trigger override và ghim đều hiệu lực';
exception when others then
  reset role;
  raise;
end $$;
```

> `apply_migration` bọc toàn bộ trong một transaction (D92) ⇒ bất kỳ `RAISE EXCEPTION` nào ở 3A/3B đều rollback sạch, kể cả dòng probe.
>
> **Sau apply vẫn CHƯA được claim PASS.** BLOCK 3 chỉ chứng minh cấu trúc + hành vi ở tầng SQL. Real-login QA (§11) là bắt buộc — D2/D3/D291.

---

## 5. FRONTEND PASTE-OVER PATCH — REVIEW ONLY

**File:** `src/routes/_authenticated/teacher.session.$id.tsx` (xác nhận `createFileRoute("/_authenticated/teacher/session/$id")` — D117)

### 5.1 Đổi 1/2 — bỏ `uploaded_by` khỏi INSERT

**Exact current code** (trong `PhotoTab.onFile`):

```js
    const { data: mom, error: mErr } = await (supabase as any)
      .from("learning_moments")
      .insert({
        session_id: sessionId,
        class_id: meta.class_id,
        program_id: meta.program_id,
        lesson_version_id: meta.lesson_version_id,
        uploaded_by: profile?.id ?? null,
      })
      .select("id")
      .single();
```

**Exact replacement:**

```js
    // V114B-E3 WP1: uploaded_by do database tự gán từ phiên đăng nhập (trigger
    // guard_learning_moments_actor). Client KHÔNG gửi actor, KHÔNG gửi approved_by,
    // KHÔNG gửi state — mọi trường attribution/approval là sự thật phía server.
    const { data: mom, error: mErr } = await (supabase as any)
      .from("learning_moments")
      .insert({
        session_id: sessionId,
        class_id: meta.class_id,
        program_id: meta.program_id,
        lesson_version_id: meta.lesson_version_id,
      })
      .select("id")
      .single();
```

### 5.2 Đổi 2/2 — gỡ biến `profile` đã thành vô dụng

Sau đổi 1, `profile` trong `PhotoTab` **không còn chỗ dùng nào** ⇒ TypeScript `noUnusedLocals` sẽ báo lỗi build.

**Exact current code** (dòng đầu thân `PhotoTab`):

```js
  const { profile } = useCurrentProfile();
  const [moments, setMoments] = useState<MomentItem[] | null>(null);
```

**Exact replacement:**

```js
  const [moments, setMoments] = useState<MomentItem[] | null>(null);
```

### 5.3 Type implications

| | |
|---|---|
| `import { useCurrentProfile }` | **GIỮ** — còn dùng ở `SessionFlow` |
| `PhotoTab` props | không đổi |
| Kiểu insert payload | hẹp lại 5 → 4 trường; `learning_moments` cho phép `uploaded_by` NULL ⇒ **không lỗi type** |
| `noUnusedLocals` | được xử lý bởi 5.2 |
| Không đổi | `saveCaption` · `toggleTag` · `removeMedia` · `archive_empty_draft_moment_service` · UX · copy · Parent surface |

### 5.4 Hành vi theo thứ tự deploy

| | Frontend cũ (còn gửi `uploaded_by`) | Frontend mới (không gửi) |
|---|---|---|
| **Trước 105** | `uploaded_by` = giá trị client gửi ✅ chạy · ❌ giả mạo được | `uploaded_by` = **NULL** ⚠️ **mất attribution** |
| **Sau 105** | trigger override → actor thật ✅ | trigger gán actor thật ✅ |

➡️ Ô góc trên-phải là lý do **không được deploy frontend trước migration**. Đúng cảnh báo §6 của Owner.

---

## 6. DEPLOY SEQUENCE

### Option 1 ★ — Migration-first, backward compatible **(em chọn)**

| # | Bước | Bất biến giữ được |
|---|---|---|
| 1 | Apply migration 105 | Frontend cũ vẫn INSERT được; `uploaded_by` bị override thành actor thật; **lỗ hổng đóng ngay** |
| 2 | Security QA §11 với frontend **cũ** còn chạy | Chứng minh containment không phụ thuộc frontend |
| 3 | Deploy frontend patch §5 (Cloudflare CI) | Payload sạch; hành vi không đổi |
| 4 | Verify production (hard reload — D105) | Không có `uploaded_by` NULL mới sinh |
| 5 | Apply migration 106 hardening §7 | Quyền tối thiểu |
| 6 | Security QA lại | E3-SG-01 đủ điều kiện đóng |

**Không có cửa gãy ở bất kỳ thời điểm nào.** Không cần release atomic giữa Supabase và Cloudflare.

### Option 2 — RPC-first frontend

| # | Bước |
|---|---|
| 1 | 105 tạo thêm `create_session_moment()` (DEFINER, derive actor) |
| 2 | Frontend chuyển từ `.from().insert()` sang `.rpc()` |
| 3 | 106 revoke INSERT trên bảng |

**Không chọn**, ba lý do: (a) thêm một RPC mới vào đúng lượt đang đóng lỗ hổng ⇒ tăng bề mặt review; (b) `create_session_moment` sẽ phải viết lại lần nữa ở WP4 khi authority đổi sang responsible teacher — hai lần thay cùng một thứ; (c) Option 1 đã đóng lỗ hổng ngay ở bước 1, không chậm hơn.

**Không đề xuất "deploy cùng lúc"** — Supabase migration và Cloudflare CI không có cơ chế atomic chung.

---

## 7. MIGRATION 106 — HARDENING DRAFT (Stage C)

Chỉ apply **sau khi** §6 bước 4 xác nhận frontend mới đang chạy trên production.

### 7.1 Điều kiện tiên quyết — verify trước, không suy đoán

| # | Cách xác minh |
|---|---|
| 1 | `list_edits` limit=1 → commit của patch §5 đã lên `main` |
| 2 | Bundle production đã đổi (hard reload, D105) |
| 3 | **[DB]** `select count(*) from learning_moments where created_at > '<t_deploy>' and uploaded_by is null` = **0** |
| 4 | Có ít nhất 1 moment mới tạo sau deploy với `uploaded_by` đúng actor |
| 5 | `get_logs('postgres')` không có lỗi `lm_guard:` bất thường |

### 7.2 SQL

```sql
-- 106_v114b_e3_wp1_grant_hardening
-- BLOCK 1: (không DDL)

-- BLOCK 2 — thu quyền tối thiểu
revoke insert (uploaded_by, approved_by, state)                     on public.learning_moments from authenticated;
revoke update (uploaded_by, approved_by, state, class_id,
               session_id, program_id, lesson_version_id, created_at) on public.learning_moments from authenticated;

-- BLOCK 3 — verify
do $$
declare n int;
begin
  select count(*) into n from information_schema.column_privileges
   where table_schema='public' and table_name='learning_moments' and grantee='authenticated'
     and ( (privilege_type='INSERT' and column_name in ('uploaded_by','approved_by','state'))
        or (privilege_type='UPDATE' and column_name in ('uploaded_by','approved_by','state','class_id','session_id')) );
  if n <> 0 then raise exception '106 FAIL: còn % grant cần thu', n; end if;

  -- whitelist nghiệp vụ PHẢI còn
  select count(*) into n from information_schema.column_privileges
   where table_schema='public' and table_name='learning_moments' and grantee='authenticated'
     and privilege_type='UPDATE' and column_name in ('caption','theme_tag','album_id','feedback_note','updated_at');
  if n <> 5 then raise exception '106 FAIL: whitelist bị thu nhầm (thấy %)', n; end if;

  raise notice '106 PASS';
end $$;
```

> Sau 106, nếu một client cũ (tab chưa reload) còn gửi `uploaded_by`, PostgREST trả **403 permission denied for column**. Đó là hành vi **mong muốn** — nhưng vì vậy 106 chỉ được apply sau khi §7.1 xanh, và nên chọn giờ thấp điểm.
>
> **Whitelist ở đây là tên cột production thật, đã verify [DB]:** `learning_moments` có đúng 14 cột — `id · session_id · class_id · lesson_version_id · program_id · caption · album_id · theme_tag · state · uploaded_by · approved_by · feedback_note · created_at · updated_at`. **Không có `updated_by`.** `child_observations` có 12 cột và **không có `updated_at`**.

---

## 8. GRANTS / RLS MATRIX — BEFORE → AFTER

### 8.1 `learning_moments`

| | Trước 105 | Sau 105 | Sau 106 |
|---|---|---|---|
| RLS INSERT role | `{public}` (gồm anon) | `authenticated` | = |
| RLS INSERT check | `same_school(class)` | `same_school(class)` **+ `uploaded_by = current_profile()`** | = |
| RLS UPDATE role | `{public}` | `authenticated` | = |
| RLS SELECT | `same_school OR (parent AND approved)` | **KHÔNG ĐỔI** | **KHÔNG ĐỔI** |
| anon INSERT/UPDATE/DELETE table grant | ✅ có | ❌ revoked | = |
| authenticated INSERT `uploaded_by` | ✅ | ✅ (bị trigger override) | ❌ revoked |
| authenticated INSERT `approved_by`/`state` | ✅ | ✅ (bị override) | ❌ revoked |
| authenticated UPDATE `uploaded_by`/`approved_by`/`state` | ✅ | ✅ (bị ghim) | ❌ revoked |
| authenticated UPDATE `caption`/`theme_tag`/`album_id`/`feedback_note` | ✅ | ✅ | ✅ **giữ** |
| Trigger guard | ❌ không có | ✅ BEFORE INSERT OR UPDATE | ✅ |

### 8.2 `child_observations`

| | Trước 105 | Sau 105 |
|---|---|---|
| Cột actor | ❌ không có | ✅ `recorded_by` · `updated_by` (nullable, FK RESTRICT) |
| RLS INSERT/UPDATE role | `{authenticated}` | `authenticated` (biểu thức **giữ nguyên** — authority thuộc WP4) |
| anon write grant | ✅ có | ❌ revoked |
| authenticated ghi `recorded_by`/`updated_by` | — | ❌ revoked ngay (chưa client nào gửi) |
| Trigger guard | ❌ | ✅ |

### 8.3 `profiles`

| | Trước | Sau 105 |
|---|---|---|
| `role`/`permissions`/`school_id`/`user_id` | ghim cho non-admin | **không đổi** |
| `state` | **tự sửa được** 🔴 | ghim, trừ `is_school_admin()` cùng trường sửa cho **người khác** |

---

## 9. TRIGGER BEHAVIOR MATRIX

### `guard_learning_moments_actor`

| Đường ghi | INSERT | UPDATE |
|---|---|---|
| `authenticated`, actor active, cùng school | `uploaded_by := actor` · `approved_by := null` · `state := draft` | ghim `uploaded_by`/`approved_by`/`state`/`class_id`/`session_id`/`program_id`/`lesson_version_id`/`created_at`; các field khác đi qua |
| `authenticated`, không có profile | ❌ `lm_guard: not_authenticated` | ❌ (RLS chặn trước) |
| `authenticated`, profile `state<>'active'` | ❌ `lm_guard: actor_not_active` | ghim (không chặn sửa caption) |
| `authenticated`, class khác trường | ❌ `lm_guard: cross_school` (RLS cũng chặn) | ❌ RLS |
| `anon` | ❌ không còn grant | ❌ |
| `service_role` | ⚠️ đi vào nhánh non-privileged → `current_profile()` NULL → **exception**. **Đúng ý đồ**: hiện không có đường nào; nếu cần phải qua DEFINER RPC | như trên |
| `submit_session_journal` / `archive_empty_draft_moment_service` / `remove_moment_media_service` | `return new` không sửa | `return new` không sửa |
| migration / MCP `postgres` | `return new` | `return new` |

### `guard_child_observations_actor`

| Đường ghi | INSERT | UPDATE (gồm nhánh UPSERT ON CONFLICT) |
|---|---|---|
| `authenticated` có profile | `recorded_by := actor` · `updated_by := actor` | `recorded_by := old` (bất biến) · `updated_by := actor` · ghim `session_id`/`child_id`/`created_at` |
| `authenticated` không profile | ❌ `co_guard: not_authenticated` | ❌ |
| privileged | pass-through | pass-through |

> Frontend `saveObs()` dùng `.upsert(..., {onConflict:"session_id,child_id"})` ⇒ lần đầu chạy nhánh INSERT, lần sau chạy nhánh UPDATE của trigger. Cả hai đều được phủ.

### `guard_profiles_protected_cols`

| Chủ thể | `role`/`permissions`/`school_id`/`user_id` | `state` |
|---|---|---|
| `is_admin()` | tự do | tự do |
| school admin sửa **người khác** cùng trường | ghim | ✅ sửa được |
| school admin sửa **chính mình** | ghim | ❌ ghim |
| GV/PH sửa chính mình | ghim | ❌ ghim |

---

## 10. ROLLBACK PLAN

### 10.1 Trong lúc apply
`apply_migration` = một transaction. Bất kỳ guard nào ở BLOCK 3 `RAISE` ⇒ **rollback nguyên khối**, kể cả dòng probe của 3B. Không có trạng thái nửa vời.

### 10.2 Sau khi apply, nếu production gãy

Ưu tiên theo thứ tự **ít phá nhất**:

| # | Biện pháp | Hệ quả |
|---|---|---|
| R1 | `alter table public.learning_moments disable trigger trg_guard_learning_moments_actor;` | Mở lại lỗ hổng ⇒ **chỉ dùng khi đang chảy máu nghiệp vụ**, và phải báo Owner ngay. E3-SG-01 quay lại TRIGGERED |
| R2 | Khôi phục policy `{public}` + re-grant anon | Chỉ cần nếu R1 không đủ (rất khó xảy ra — anon không được dùng ở đâu) |
| R3 | Migration `105R` drop 2 trigger + 3 function | Không đụng cột dữ liệu |
| R4 | Drop `recorded_by`/`updated_by` | ⚠️ **mất attribution đã ghi sau 105** — chỉ làm nếu Owner chấp nhận mất |

**Không rollback được bằng cách nào khác:** dữ liệu legacy không bị chạm ở 105 (G8 chứng minh), nên không có gì phải phục hồi.

### 10.3 Rollback 106
`grant insert (uploaded_by, approved_by, state), update (...) on public.learning_moments to authenticated;` — thuần quyền, không mất dữ liệu.

---

## 11. QA — LỆNH & CA KIỂM THỬ

### 11.1 Sau migration 105, TRƯỚC khi deploy frontend

Chạy với **frontend cũ** — mục đích: chứng minh containment không phụ thuộc client.

| # | Ca | Tài khoản | Kỳ vọng |
|---|---|---|---|
| S1 | Vào `/teacher/session/<id>` Bước 3 tab Ảnh → thêm 1 ảnh | GV KHM Mỹ Linh · `gv.linh.kidshouse@demo.demenart.com` / `Test@123` | Upload thành công; **[DB]** `uploaded_by` = profile của Mỹ Linh (không phải giá trị client gửi) |
| S2 | DevTools console: `supabase.from('learning_moments').insert({class_id:'<class KHM>', uploaded_by:'<profile GV khác>'})` | Mỹ Linh | Row tạo được nhưng `uploaded_by` = Mỹ Linh · `state='draft'` |
| S3 | Console: `.update({uploaded_by:'<khác>'}).eq('id','<moment vừa tạo>')` | Mỹ Linh | Không đổi |
| S4 | Console: `.update({state:'approved'})` | Mỹ Linh | Không đổi — vẫn `draft` |
| S5 | Console: `.insert({class_id:'<class MNDM>'})` | Mỹ Linh (KHM) | Lỗi — `lm_guard: cross_school` hoặc RLS |
| S6 | Sửa caption ảnh | Mỹ Linh | ✅ lưu bình thường (whitelist không bị chặn oan) |
| S7 | Gửi nhật ký buổi `in_progress` | Mỹ Linh | ✅ `ok:true`; **[DB]** `approved_by` = Mỹ Linh; `state='approved'` |
| S8 | Gửi lại nhật ký (idempotent branch) | Mỹ Linh | ✅ duyệt ảnh bổ sung, không lỗi trigger |
| S9 | Gỡ 1 ảnh draft (`remove_moment_media_service`) | Mỹ Linh | ✅ hoạt động — chứng minh privileged path không bị ghim nhầm |
| S10 | Điểm danh + nhận xét 1 bé | GV MNDM Ngọc Hân · `gv.han.demen@demo.demenart.com` / `Test@123` | **[DB]** `recorded_by` = Ngọc Hân; sửa lại lần 2 → `recorded_by` **không đổi**, `updated_by` = Ngọc Hân |
| S11 | Console: tự đổi `profiles.state` của mình | Ngọc Hân | Không đổi |
| S12 | Master đổi `state` của một GV cùng trường | Master MNDM Phương Dung · `hieutruong.demen@demo.demenart.com` / `Test@123` | ✅ đổi được |
| S13 | Master tự đổi `state` của chính mình | Phương Dung | Không đổi |
| S14 | Mở Parent Journal, đối chiếu ảnh chụp màn hình trước 105 | PH KHM Nguyễn Văn Hùng · `ph.hung.kidshouse@demo.demenart.com` / `Test@123` | **Giống hệt** |
| S15 | PH không thấy moment `draft` | PH Hùng | Không thấy |
| S16 | Ký URL ảnh có bé chưa consent | PH MNDM Văn Thành · `ph.thanh.demen@demo.demenart.com` / `Test@123` | Consent gate **không đổi** — vẫn chặn như trước |
| S17 | Kid album | (kênh PIN) | Không đổi |

### 11.2 Lệnh [DB] kèm theo

```sql
-- attribution của moment mới sinh sau apply
select id, created_at, uploaded_by, approved_by, state::text
from learning_moments where created_at > '<t_apply>' order by created_at;

-- actor của observation mới
select session_id, child_id, recorded_by, updated_by
from child_observations where recorded_by is not null;

-- không dòng legacy nào bị chạm
select count(*) from learning_moments where state='approved' and approved_by is null;  -- kỳ vọng 6
select count(*) from child_observations where recorded_by is not null;                  -- kỳ vọng = số ca test

-- lỗi guard bất thường
-- get_logs(service='postgres') → tìm 'lm_guard:' / 'co_guard:'
```

### 11.3 Ánh xạ sang 8 điều kiện đóng E3-SG-01

| Điều kiện Owner | Ca |
|---|---|
| 1 · không giả mạo `uploaded_by` | S2 |
| 2 · không sửa `uploaded_by` sau creation | S3 |
| 3 · không tự approve từ client | S4 |
| 4 · không approve khi không có journal authority | S7 + (WP4 mới đóng trọn vẹn) |
| 5 · không cross-school | S5 |
| 6 · Parent không thấy unapproved metadata | S15 |
| 7 · service-role path không bypass | S1 (Edge `upload_media` vẫn chạy) + §1.2 |
| 8 · media/consent behavior vẫn PASS | S14 · S16 · S17 |

⚠️ Điều kiện **4** chỉ đóng được **một phần** ở WP1: authority hiện vẫn là `is_session_lead` (hồi tố). Owner đã chỉ đạo giữ nguyên để không trộn WP. ⇒ **E3-SG-01 chỉ đóng hoàn toàn sau WP4.** Em ghi rõ debt này thay vì claim sớm.

---

## 12. STOP CONDITIONS

Dừng và báo Owner, **không tự quyết**, nếu:

| # | |
|---|---|
| 1 | BLOCK 3B probe cho thấy `current_user` **không** = `postgres` bên trong DEFINER ⇒ toàn bộ §3 sai nền, phải thiết kế lại |
| 2 | Tìm thêm đường ghi `learning_moments` chưa biết (service-role, trigger khác, function mới) |
| 3 | Phát hiện cross-school attribution ≠ 0 ở lần đo lại ngay trước apply |
| 4 | Trigger làm gãy `upload_media` nhánh A hoặc `submit_session_journal` |
| 5 | Parent surface đổi dù chỉ một chi tiết |
| 6 | Consent signing đổi hành vi |
| 7 | Xuất hiện `uploaded_by` NULL mới sau khi deploy frontend |
| 8 | Có bằng chứng mới cho thấy ANOMALY-1 là hostile ⇒ escalation thật, dừng mọi thứ |

---

## 13. FILES DỰ KIẾN THAY ĐỔI

| Loại | Đường dẫn / tên | WP |
|---|---|---|
| Migration | `105_v114b_e3_wp1_security_containment` | WP1 Stage A |
| Migration | `106_v114b_e3_wp1_grant_hardening` | WP1 Stage C |
| Frontend | `src/routes/_authenticated/teacher.session.$id.tsx` | WP1 Stage B — **2 chỗ**, §5.1 + §5.2 |
| DB objects mới | `dma_write_is_privileged()` · `guard_learning_moments_actor()` · `guard_child_observations_actor()` · 2 trigger · 2 cột `child_observations` | |
| DB objects REPLACE | `guard_profiles_protected_cols()` | |
| Policy thay | `learning_moments_insert_school` · `learning_moments_update_school` · `child_observations_insert_teacher` · `child_observations_update_teacher` | |
| **KHÔNG ĐỤNG** | mọi file `parent.*` · `features/journey/*` · Edge `upload_media` · `get_child_journal` · `get_kid_album_service` · SELECT policy của `learning_moments` | |

---

## 14. TRẠNG THÁI

| | |
|---|---|
| Migration applied | **KHÔNG** — 105 và 106 mới ở dạng draft, migration cao nhất vẫn **104** |
| Database changed | **KHÔNG** — lượt này chỉ `select` / `pg_get_functiondef` / `pg_policies` / `information_schema` / `get_edge_function` |
| Code changed | **KHÔNG** — không `send_message`, không paste vào repo |
| Deployed | **KHÔNG** |
| HEAD | `7ee7eeba` — **unchanged** |
| Owner review | **BẮT BUỘC trước khi apply** |

---

*Sinh trong V114B-E3 Phase 2 · WP1 Step 1 · HEAD `7ee7eeba` · migration 104 · chưa chạm code.*
