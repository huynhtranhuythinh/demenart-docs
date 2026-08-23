# DMA V114B-E3 · WP4-A3/A4 — AUTHORITY CONTRACT & BACKFILL DESIGN

> **NO APPLY.** Không migration, không DDL, không ghi dữ liệu, không `send_message`, 0 file frontend bị đụng.
> Baseline: **88** bảng · **207** hàm · **198** SECDEF · **166** policy · **33** trigger · migration **111** · HEAD `d8178a55895b64bbffdf79bb05c06e6b4313d68b`.
> Owner Gate D-1…D-5 = **A/A/A/A/A**. CTO conditions 1–15 đã nội hoá vào từng mục dưới.

---

## 0. Kết quả hai điều kiện chặn (13 & 14) — GIẢI XONG TRƯỚC KHI THIẾT KẾ

### 0.1 Condition 13 — H-1 frontend consumer coverage của `session_teacher_assignments`: **RESOLVED**

Phương pháp quyết định (không cần đọc 205 file): bảng `session_teacher_assignments` **ra đời** ở migration 109 `20260722012602` = **2026-07-22 01:26:02 UTC**. Mọi tham chiếu frontend tới bảng này **bắt buộc** phải nằm trong commit sau mốc đó. Commit cuối cùng **trước** mốc là `388b50ae` (2026-07-21 14:41 UTC).

⇒ Chạy **một** diff luỹ kế `388b50ae → d8178a55` (HEAD) = toàn bộ không gian có thể chứa consumer.

| Kết quả | |
|---|---|
| Số commit trong cửa sổ | **5** (`e7958c7d` · `a7d21c1c` · `70275984` · `fa52656b` · `d8178a55`) |
| File bị đụng | `package.json` · `school.manage.tsx` · **`school.schedule.tsx`** · `teacher.classes.tsx` · `teacher.index.tsx` |
| Số lần xuất hiện `.from("session_teacher_assignments")` | **0** |
| Consumer STA duy nhất | `school.schedule.tsx` → **chỉ qua RPC** `rpcUntyped("get_school_week_planned_teachers", { p_week_start })` |
| Ghi vào STA từ frontend | **0** (và không thể — `authenticated` chỉ có `SELECT`) |

**Phát hiện phụ quan trọng — parser client là fail-safe nhưng brittle.** `parsePlannedRow` trong `school.schedule.tsx` **từ chối toàn bộ response** nếu bất kỳ row nào có `evidence_grade` ngoài `null | "db_proven" | "owner_attested"`, hoặc `reason` ngoài `null | "no_planned_assignment"`. UI khi đó hiện *“Chưa hiển thị được giáo viên dự kiến”* — **thà im lặng còn hơn nói sai**, đúng tinh thần D290.

⇒ Ràng buộc cứng cho S1: **không được thêm `assignment_source` mới vào nhánh `planned`.** Mọi giá trị source mới của WP4 chỉ được dùng cho `assignment_type='responsible'`. Vì `get_school_week_planned_teachers` lọc `assignment_type='planned'` ở **cả hai** query (đếm unknown-source và query chính), row `responsible` **không bao giờ** lọt vào parser đó. **Đã verify trên prosrc sống.**

### 0.2 Condition 14 — 4 Edge Function ứng viên: **ĐỌC XONG 4/4, ZERO WRITER**

| Edge | verify_jwt | Ghi `session_reports`? | Ghi `session_teacher_assignments`? | Ghi `lesson_sessions`? | Kết luận |
|---|:--:|:--:|:--:|:--:|---|
| `capture_session_moment` v4 | false | ❌ | ❌ | ❌ | **Stub 410 `deprecated`** — không parse body, không side-effect |
| `capture_session_media` v4 | true | ❌ | ❌ | ❌ | **Stub 503 SEC0 fail-closed** — không đọc body, không attribution |
| `delete_session_media` v3 | false | ❌ | ❌ | ❌ | `svc` ghi `session_media` (delete) + RPC `drive_trash_media_service` + `write_audit_log`. Gate `check_session_media_upload_access` |
| `upload_media` v19 | false | ❌ | ❌ | ❌ | 7 nhánh (A/B/C/D/E/F/G); `svc` ghi `media_assets` · `session_media` · qua RPC finalize. Không chạm authority nhật ký |

**Không có service_role writer nào của `session_reports`.** Cutover containment ở S5 do đó **không** làm gãy Edge nào.

### 0.3 Coverage còn lại — khai báo trung thực

| Hạng mục | Trạng thái |
|---|---|
| STA consumer (frontend) | **ĐÓNG** — lập luận cửa sổ git + diff đầy đủ |
| STA consumer (DB) | **ĐÓNG** — 4/4: `get_school_week_planned_teachers` ✅lọc · `dma_snapshot_planned_teacher` ✅hardcode · `dma_guard_sta_immutable` ✅ · policy `sta_select_school` (SELECT-only, không lọc — chấp nhận) |
| STA consumer (Edge) | **ĐÓNG** — 16/16 slug đã liệt kê, 4 ứng viên đã đọc, 12 còn lại không có đường tới STA (`authenticated` chỉ SELECT; `service_role` không xuất hiện trong bất kỳ nhánh nào đã đọc) |
| **`session_reports` writer (frontend)** | **PARTIAL 2/6** — đã đọc **toàn văn** `teacher.session.$id.tsx` (chỉ gọi RPC `submit_session_journal`) và `teacher.journal.tsx` (chỉ gọi RPC `get_teacher_journals`, read-only). **Còn 4 ứng viên chưa đọc:** `school.index.tsx` · `school.moments.tsx` · `teacher.index.tsx` · `admin.lookup.tsx` |
| `session_reports` writer (DB) | **ĐÓNG** — quét `prosrc` toàn schema: **đúng 1** hàm ghi = `submit_session_journal` |

Bằng chứng dữ liệu bổ trợ: 3 dòng `session_reports`; dòng `state='final'` của `2fab0c56` có `created_at` = **24/06 23:14:18 ICT**, trùng phút với `created_at` của chính buổi ⇒ **seed**, không phải ghi runtime ngoài luồng. **Không có dấu vết writer ẩn nào trên production.**

> ⚠️ **Bảng `session_reports` KHÔNG có cột `updated_at`.** Một `PATCH` trực tiếp hôm nay **không để lại một dấu vết nào** — không timestamp, không audit, không trigger. Đây là lý do containment (D-3) không thể hoãn.

**PARTIAL 2/6 không chặn A3/A4** vì containment nằm ở **S5**, sau frontend. Nó trở thành **precondition cứng của S5** (§12).

---

## 1. Exact predicate contract

### 1.1 `public.is_session_responsible(uuid)` — MỚI

```sql
create or replace function public.is_session_responsible(p_session_id uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1
    from public.session_teacher_assignments a
    where a.session_id      = p_session_id
      and a.assignment_type = 'responsible'
      and a.is_current
      and a.valid_to is null
      and a.teacher_id      = public.current_profile()
  )
  and public.same_school(public.session_school_id(p_session_id));
$$;
```

| Hạng mục | Chốt |
|---|---|
| Signature | `public.is_session_responsible(uuid) → boolean` |
| Owner | `postgres` |
| Posture | **SECURITY DEFINER** · `stable` · **`search_path = ''`** |
| Grants | `revoke all on function … from public;` rồi `grant execute … to authenticated, service_role;` — **khối riêng, chạy SAU `CREATE OR REPLACE` (D15)**, verify bằng `aclexplode(coalesce(proacl, acldefault('f', proowner)))` |
| Trả `false` khi | chưa đăng nhập (`current_profile()` NULL) · session không tồn tại (`session_school_id` NULL ⇒ `same_school(null)` = false) · khác trường · không có dòng `responsible` · dòng `responsible` thuộc người khác |
| **Không bao giờ** | `raise` · ghi audit · ghi dữ liệu |
| Biên giới trường | **tường minh** bằng `same_school(...)` — không dựa gián tiếp như `is_session_lead` hôm nay |

**Hai điều kiện `is_current` và `valid_to is null` đều được giữ dù `sta_current_chk` đã ép chúng tương đương.** Redundancy có chủ ý: nếu ai đó nới CHECK trong tương lai, predicate vẫn fail-closed.

**`is_session_lead(uuid)` GIỮ NGUYÊN BYTE** (condition 1). Migration phải có assertion `md5(prosrc) = '8b4f91dda7e45a3c2c801e70579f702d'` ở **cả BLOCK 1 lẫn BLOCK 3** của mọi migration WP4.

### 1.2 Ánh xạ evidence grade (dùng chung, không chép tay)

```sql
create or replace function public.dma_assignment_evidence_grade(p_source text)
returns text language sql immutable
set search_path = '' as $$
  select case p_source
    when 'migration_distribution_lead_snapshot' then 'db_proven'
    when 'migration_session_teachers_lead'      then 'db_proven'
    when 'runtime_distribution_lead_snapshot'   then 'db_proven'
    when 'system_distribution_lead_snapshot'    then 'db_proven'
    when 'runtime_start_session'                then 'db_proven'
    when 'migration_responsible_backfill'       then 'db_proven'
    when 'responsibility_transfer'              then 'db_proven'
    when 'migration_owner_attested'             then 'owner_attested'
    else null
  end;
$$;
```

`get_school_week_planned_teachers` **không được sửa ở WP4** (nó đang đúng và đang chạy). Hàm này chỉ phục vụ các reader `responsible` mới.

---

## 2. Exact responsibility lifecycle

| Sự kiện | planned | participating | responsible |
|---|---|---|---|
| `create_lesson_session` | trigger sinh 1 dòng `is_current` | — | — |
| buổi `scheduled` / `prep_ready` | 1 dòng | — | **không có** ⇒ `submit` = `no_responsible_assignment` |
| `cancel_lesson_session` | giữ nguyên | — | **không có, vĩnh viễn** |
| **`start_session`** | không đụng | ghi `taught_by` (bất biến) | **SINH đúng 1 dòng**, `teacher_id = current_profile()`, source `runtime_start_session`, `assigned_by = current_profile()` |
| `start_session` gọi lại khi đã `in_progress` | — | không đụng | **idempotent — không sinh dòng thứ hai** (guard `if v_state = 'in_progress' then return already` chạy TRƯỚC mọi ghi) |
| `submit_session_journal` | — | — | **đọc**, không ghi |
| `transfer_session_responsibility` | không đụng | không đụng | supersede: dòng cũ `is_current=false` + `valid_to` + `superseded_by`; dòng mới `is_current=true` |
| `set_distribution_lead` | **không đụng buổi đã tạo** | — | **KHÔNG ĐỤNG — đây là toàn bộ mục đích của WP4** |

**Bất biến bắt buộc (condition 5, 6):**
- `responsible` **không bao giờ** fallback sang `planned`, `taught_by`, hay `cd.lead_teacher_id`. Không có `coalesce` nào trong đường authority.
- Buổi không có `responsible` ⇒ **từ chối**, không đoán.
- Đúng **một** dòng `is_current` cho mỗi `(session_id, 'responsible')` — ép bởi `sta_current_uidx` sẵn có, **không cần index mới**.

---

## 3. Constraint conversion plan (D288 — migration bảo mật)

Trạng thái sống hiện tại đã verify:

```
sta_type_chk   CHECK (assignment_type = 'planned')
sta_source_chk CHECK (assignment_source = ANY (ARRAY[
                 'migration_distribution_lead_snapshot','migration_session_teachers_lead',
                 'migration_owner_attested','runtime_distribution_lead_snapshot',
                 'system_distribution_lead_snapshot']))
sta_actor_chk  CHECK (CASE assignment_source
                        WHEN 'runtime_distribution_lead_snapshot' THEN assigned_by IS NOT NULL
                        ELSE assigned_by IS NULL END)
sta_current_chk CHECK ((is_current AND valid_to IS NULL) OR (NOT is_current AND valid_to IS NOT NULL))
sta_validity_chk CHECK (valid_to IS NULL OR valid_to > valid_from)
sta_no_self_supersede_chk CHECK (superseded_by IS NULL OR superseded_by <> id)
sta_current_uidx UNIQUE (session_id, assignment_type) WHERE is_current
sta_lineage_uk   UNIQUE (id, session_id, assignment_type)
sta_supersede_fk FK (superseded_by, session_id, assignment_type) → (id, session_id, assignment_type)
```

### Chuyển đổi (S1)

```sql
alter table public.session_teacher_assignments
  drop constraint sta_type_chk,
  add  constraint sta_type_chk
       check (assignment_type in ('planned','responsible')),

  drop constraint sta_source_chk,
  add  constraint sta_source_chk
       check (assignment_source in (
         'migration_distribution_lead_snapshot',
         'migration_session_teachers_lead',
         'migration_owner_attested',
         'runtime_distribution_lead_snapshot',
         'system_distribution_lead_snapshot',
         'runtime_start_session',
         'migration_responsible_backfill',
         'responsibility_transfer')),

  drop constraint sta_actor_chk,
  add  constraint sta_actor_chk
       check (
         case
           when assignment_source in ('runtime_distribution_lead_snapshot',
                                      'runtime_start_session',
                                      'responsibility_transfer')
             then assigned_by is not null
           else assigned_by is null
         end),

  add  constraint sta_dimension_source_chk
       check (
         case assignment_type
           when 'planned' then assignment_source in (
                'migration_distribution_lead_snapshot','migration_session_teachers_lead',
                'migration_owner_attested','runtime_distribution_lead_snapshot',
                'system_distribution_lead_snapshot')
           when 'responsible' then assignment_source in (
                'migration_responsible_backfill','migration_owner_attested',
                'runtime_start_session','responsibility_transfer')
         end);
```

**`sta_dimension_source_chk` là ràng buộc quan trọng nhất của WP4 về mặt cấu trúc.** Nó khoá cứng kết luận §0.1: một `assignment_source` mới **không thể** lọt vào chiều `planned` kể cả do lỗi lập trình, nên parser `school.schedule.tsx` **không thể** bị vỡ. Đây là whitelist conversion đúng nghĩa D288 — chuyển từ "cho phép ngầm" sang "liệt kê tường minh cả hai chiều".

`migration_owner_attested` cố ý xuất hiện ở **cả hai** chiều: nó đã tồn tại trong `planned` (5 dòng sống) và Owner chỉ định dùng lại cho `responsible` của `aaaa…0a0003` (D-2).

### Không đổi

`sta_current_chk` · `sta_validity_chk` · `sta_no_self_supersede_chk` · `sta_current_uidx` · `sta_lineage_uk` · `sta_teacher_current_idx` · `sta_session_idx` · RLS `sta_select_school` · ACL (`authenticated` = SELECT, `anon` = không có entry).

### Đổi duy nhất về FK — bắt buộc, có lý do kỹ thuật

```sql
alter table public.session_teacher_assignments
  drop constraint sta_supersede_fk,
  add  constraint sta_supersede_fk
       foreign key (superseded_by, session_id, assignment_type)
       references public.session_teacher_assignments (id, session_id, assignment_type)
       deferrable initially deferred;
```

**Vì sao bắt buộc.** Supersession có một vòng phụ thuộc không gỡ được nếu FK là immediate:
- `sta_current_uidx` là UNIQUE partial `WHERE is_current` ⇒ **không thể** INSERT dòng mới `is_current=true` khi dòng cũ còn `is_current=true`.
- ⇒ phải UPDATE dòng cũ trước.
- Nhưng UPDATE dòng cũ phải set `superseded_by = <id dòng mới>`, mà dòng mới **chưa tồn tại** ⇒ FK immediate fail.

`DEFERRABLE INITIALLY DEFERRED` giải quyết: FK kiểm tra lúc COMMIT, unique index vẫn kiểm tra ngay từng statement. Thứ tự đúng:

```
1. v_new_id := gen_random_uuid();
2. UPDATE dòng cũ  SET is_current=false, valid_to=now(), superseded_by=v_new_id;   -- unique index nhả
3. INSERT dòng mới (id=v_new_id, is_current=true, valid_to=null, superseded_by=null);
4. COMMIT → FK validate
```

**Ghi rõ rủi ro của deferred FK:** nếu bước 3 fail, toàn bộ transaction rollback ở COMMIT thay vì fail sớm ở bước 2. Trong SECDEF RPC chỉ có một transaction nên hệ quả giống hệt — nhưng thông báo lỗi sẽ đến từ COMMIT. RPC phải bọc `exception when others` và trả `{"ok":false,"reason":"transfer_failed"}` generic.

---

## 4. Append-only supersession contract

Thay `dma_guard_sta_immutable()` (hiện `raise` vô điều kiện cho **cả** UPDATE và DELETE) bằng:

```sql
create or replace function public.dma_guard_sta_append_only()
returns trigger
language plpgsql
security invoker            -- D311-cand: BẮT BUỘC INVOKER
set search_path = ''
as $$
begin
  if tg_op = 'DELETE' then
    raise exception 'session_teacher_assignments la append-only: DELETE bi chan.'
      using errcode = 'restrict_violation';
  end if;

  -- Chỉ đường ĐẶC QUYỀN (bên trong SECDEF owner postgres) mới được supersede
  if not public.dma_write_is_privileged() then
    raise exception 'session_teacher_assignments: UPDATE chi cho phep qua RPC co kiem soat.'
      using errcode = 'restrict_violation';
  end if;

  -- ĐÚNG MỘT hình dạng UPDATE hợp lệ: đóng dòng hiện hành
  if not (
        old.is_current      is true
    and new.is_current      is false
    and old.valid_to        is null
    and new.valid_to        is not null
    and new.valid_to        >  old.valid_from
    and old.superseded_by   is null
    and new.superseded_by   is not null
    and new.superseded_by   <> old.id
    -- mọi cột còn lại BẤT BIẾN
    and new.id              is not distinct from old.id
    and new.session_id      is not distinct from old.session_id
    and new.teacher_id      is not distinct from old.teacher_id
    and new.assignment_type is not distinct from old.assignment_type
    and new.valid_from      is not distinct from old.valid_from
    and new.assigned_by     is not distinct from old.assigned_by
    and new.assignment_source is not distinct from old.assignment_source
    and new.created_at      is not distinct from old.created_at
  ) then
    raise exception 'session_teacher_assignments: chi cho phep dong dong hien hanh (is_current true->false + valid_to + superseded_by).'
      using errcode = 'restrict_violation';
  end if;

  return new;
end
$$;
```

| Điểm | Chốt |
|---|---|
| Trigger | `drop trigger trg_sta_immutable` → `create trigger trg_sta_append_only before delete or update on public.session_teacher_assignments for each row execute function public.dma_guard_sta_append_only()` |
| Security | **INVOKER** (D311-cand). Migration phải assert `prosecdef = false` |
| `service_role` | **cũng đi qua trigger** (D312-cand: BYPASSRLS không bypass trigger). Vì `dma_write_is_privileged()` = `current_user = 'postgres'`, `service_role` gọi trực tiếp sẽ **bị chặn** — đúng ý đồ |
| DELETE | chặn vô điều kiện, **kể cả** privileged |
| Reactivate (`false → true`) | **bị chặn** — không có nhánh nào cho phép |
| Đổi `teacher_id` tại chỗ | **bị chặn** |
| Xoá lịch sử | **không thể** |

**Stop-gate #5 giữ nguyên trạng thái KHÔNG CHẠM.**

### `transfer_session_responsibility` — RPC duy nhất được supersede

```sql
create or replace function public.transfer_session_responsibility(
  p_session_id uuid, p_to_teacher uuid, p_reason text)
returns jsonb language plpgsql security definer set search_path = ''
```

| Bước | Nội dung | Mã từ chối |
|---|---|---|
| 1 | `v_actor := public.current_profile()`; null? | `not_authenticated` |
| 2 | session tồn tại? `v_school := public.session_school_id(p_session_id)` null? | `session_not_found` |
| 3 | `public.current_profile_role() in ('master_admin','sub_admin')` **và** `v_school = any(public.user_school_ids())` (**condition 9** — chỉ school admin cùng trường; **KHÔNG** `is_admin()` platform, **KHÔNG** lead) | `not_authorized_for_school` |
| 4 | `p_to_teacher is not null` | `target_required` |
| 5 | `public.dma_assignable_teacher_reason(p_to_teacher, v_school) is null` (tái dùng validator S0B) | `target_teacher_invalid` |
| 6 | `length(btrim(coalesce(p_reason,''))) >= 10` | `reason_required` |
| 7 | tồn tại dòng `responsible` `is_current` cho session? | `no_responsible_assignment` |
| 8 | dòng hiện hành đã là `p_to_teacher`? | `{"ok":true,"already":true}` — idempotent, **không** sinh dòng |
| 9 | session state `in ('cancelled')`? | `bad_state` |
| 10 | supersede theo trình tự §3 (UPDATE → INSERT), source `responsibility_transfer`, `assigned_by = v_actor` | |
| 11 | `write_audit_log('session_responsibility_transferred', jsonb_build_object('actor_id', v_actor, 'entity_type','lesson_session', 'entity_id', p_session_id, 'school_id', v_school, 'metadata', jsonb_build_object('from_teacher', v_old_teacher, 'to_teacher', p_to_teacher, 'reason', left(btrim(p_reason),500), 'old_assignment_id', v_old_id, 'new_assignment_id', v_new_id)))` — **hình dạng payload đúng, KHÔNG bọc `exception when others` cho audit của hành động authority** | |

> **Khác biệt có chủ ý với D67/D72:** `start_session` và `submit_session_journal` bọc audit trong `exception when others then null` để lỗi audit không chặn nghiệp vụ. Với **chuyển trách nhiệm**, audit **là** sản phẩm — nếu không ghi được audit thì không được chuyển. Audit ở đây **không** bọc.

`p_reason` lưu vào audit metadata, **không** lưu vào STA (bảng giữ nguyên 11 cột — condition: không thêm cột ở WP4).

---

## 5. Historical backfill manifest — cả 9 buổi

`valid_from` dùng `coalesce(ls.scheduled_at, ls.created_at)` — thời điểm buổi học diễn ra là mốc tự nhiên nhất cho "trách nhiệm bắt đầu". Không dùng `now()` (sẽ nói dối rằng trách nhiệm mới phát sinh hôm nay).

| # | Session | Trường | State | Hành động S2 | teacher_id | assignment_source | evidence_grade | assigned_by | valid_from |
|---|---|---|---|---|---|---|---|---|---|
| 1 | `aaaa…0a0001` | KHM | taught_report_pending | **INSERT** | Đặng Mỹ Linh | `migration_responsible_backfill` | `db_proven` | NULL | 2026-06-30 09:30 ICT |
| 2 | `aaaa…0a0002` | KHM | taught_report_pending | **INSERT** | Đặng Mỹ Linh | `migration_responsible_backfill` | `db_proven` | NULL | 2026-07-01 09:00 ICT |
| 3 | `2fab0c56` | DEMO-001 | completed | **INSERT** | Cô Thúy Ngân Demo | `migration_responsible_backfill` | `db_proven` | NULL | 2026-06-23 23:14 ICT |
| 4 | **`aaaa…0a0003`** | KHM | in_progress | **INSERT** | Đặng Mỹ Linh | **`migration_owner_attested`** | **`owner_attested`** | NULL | 2026-06-28 16:20 ICT |
| 5 | `3bfb9730` | KHM | scheduled | **KHÔNG** | — | — | — | — | — |
| 6 | `91bc03d8` | KHM | scheduled | **KHÔNG** | — | — | — | — | — |
| 7 | `8dcf9f2e` | KHM | cancelled | **KHÔNG** | — | — | — | — | — |
| 8 | `ea85798a` | KHM | cancelled | **KHÔNG** | — | — | — | — | — |
| 9 | `6cbb4024` | KHM | cancelled | **KHÔNG** | — | — | — | — | — |

**Delta dòng dự kiến: `session_teacher_assignments` 9 → 13 (+4). `planned` 9 → 9 (±0). `responsible` 0 → 4.**
**Không UPDATE, không DELETE dòng nào. Business row của mọi bảng khác: ±0.**

### 5.1 Cơ sở bằng chứng từng dòng (condition 7)

| # | Bằng chứng máy độc lập |
|---|---|
| 1 | `taught_by` = Mỹ Linh · `learning_moments.uploaded_by` = Mỹ Linh (11 ảnh) · `approved_by` = Mỹ Linh (5) · `audit_logs.session_journal_submitted.actor_id` = Mỹ Linh · `planned` = Mỹ Linh — **5 nguồn đồng thuận** |
| 2 | `taught_by` · `uploaded_by` (4) · `approved_by` (1) · `child_observations.recorded_by` · `audit_logs` · `planned` — **6 nguồn đồng thuận** |
| 3 | `taught_by` = Thúy Ngân · `session_teachers` (role `lead`) · `planned` — **3 nguồn đồng thuận**. Không audit (buổi seed 24/06, trước khi audit `session_journal_submitted` được ghi cho DEMO) |
| 4 | **KHÔNG CÓ BẰNG CHỨNG MÁY NÀO.** `taught_by` NULL · 0 moment · 0 observation · 0 report · 0 `session_teachers` · 0 audit. Chỉ có Owner attestation ngày 22/07/2026 |

### 5.2 Owner-attested evidence treatment (condition 7, D-2)

**Nguyên tắc trình bày: hệ thống phải nói rõ đây là lời người, không phải bằng chứng máy.**

| Tầng | Xử lý |
|---|---|
| Dữ liệu | `assignment_source = 'migration_owner_attested'` — giá trị **đã tồn tại** trong whitelist, đã dùng ở S1 cho 5 dòng `planned`, không phát minh giá trị mới |
| Ánh xạ | `dma_assignment_evidence_grade('migration_owner_attested') = 'owner_attested'` — **không bao giờ** `db_proven` |
| Audit | S2 ghi một dòng `write_audit_log('session_responsibility_backfilled', {... metadata: {evidence_grade:'owner_attested', attested_by:'owner', attested_at:'2026-07-22', basis:'Owner Gate WP4 D-2'}})` cho **riêng** dòng #4; 3 dòng còn lại ghi `evidence_grade:'db_proven'` kèm danh sách nguồn |
| Reader | Mọi RPC trả `responsible` **bắt buộc** trả kèm `evidence_grade`. Reader **không được** bỏ field này đi |
| UI (S4+) | Nơi hiển thị giáo viên phụ trách của buổi `owner_attested` phải có chú thích phân biệt — ví dụ *“ghi nhận theo xác nhận của nhà trường”*. **Không** hiện như dữ liệu hệ thống tự chứng minh |
| Tài liệu | Ghi vào closeout + SYSTEM_MAP: **1/4 dòng responsible backfill là owner-attested**, kèm session id |

**Không** dùng `migration_responsible_backfill` cho dòng #4 — làm vậy sẽ ánh xạ thành `db_proven` và **nói dối**.

### 5.3 SQL backfill (S2, BLOCK 2) — hình dạng

```sql
-- 3 dòng db_proven: chỉ nhận buổi có taught_by KHÔNG NULL (bằng chứng runtime thật)
insert into public.session_teacher_assignments
  (session_id, teacher_id, assignment_type, is_current, valid_from, valid_to,
   assigned_by, assignment_source, superseded_by)
select ls.id, ls.taught_by, 'responsible', true,
       coalesce(ls.scheduled_at, ls.created_at), null,
       null, 'migration_responsible_backfill', null
from public.lesson_sessions ls
where ls.taught_by is not null
  and ls.state in ('taught_report_pending','report_pending_approval','completed')
  and not exists (select 1 from public.session_teacher_assignments a
                  where a.session_id = ls.id and a.assignment_type = 'responsible');

-- 1 dòng owner_attested: HARDCODE đúng một session id, không mệnh đề suy diễn
insert into public.session_teacher_assignments
  (session_id, teacher_id, assignment_type, is_current, valid_from, valid_to,
   assigned_by, assignment_source, superseded_by)
select ls.id, 'd1000000-0000-4000-8000-000000000011'::uuid, 'responsible', true,
       coalesce(ls.scheduled_at, ls.created_at), null,
       null, 'migration_owner_attested', null
from public.lesson_sessions ls
where ls.id = 'aaaa0000-0000-4000-8000-0000000a0003'::uuid
  and ls.taught_by is null
  and ls.state = 'in_progress'
  and not exists (select 1 from public.session_teacher_assignments a
                  where a.session_id = ls.id and a.assignment_type = 'responsible');
```

Mệnh đề `taught_by is not null` là **cổng an toàn tự nhiên**: nó tự loại 5 buổi scheduled/cancelled mà không cần liệt kê, và **không thể** rơi về `cd.lead_teacher_id`. Câu thứ hai hardcode một UUID vì đó là quyết định của người, không phải suy luận của máy — cố tình để nó **không** khái quát hoá được.

---

## 6. `session_reports` containment contract (D-3, condition 8)

### 6.1 Trạng thái hiện tại đã verify

| Role | SELECT | INSERT | UPDATE | DELETE | TRUNCATE |
|---|:--:|:--:|:--:|:--:|:--:|
| `authenticated` | ✅ | ✅ | ✅ | ✅ | ✅ |
| `anon` | ✅ | ✅ | ✅ | ✅ | ✅ |

Policy: `_select_school` (SELECT) · `_insert_lead_or_schooladmin` · `_update_lead_or_schooladmin`. **Không có policy DELETE** ⇒ DELETE bị RLS chặn. **TRUNCATE không chịu RLS** ⇒ `anon` xoá sạch bảng được. Bảng **không có `updated_at`** ⇒ ghi trực tiếp không để lại dấu vết.

### 6.2 Hợp đồng S5 — hai phần, cùng một migration

**Phần 1 — thu quyền (khuôn WP3, một câu lệnh):**

```sql
revoke insert, update, delete, truncate
  on table public.session_reports
  from authenticated, anon;
```

Không `REVOKE ALL`. Không đụng `SELECT`. Không đụng `service_role`, `postgres`, `pg_default_acl`, column grant.
`relacl` kỳ vọng: `authenticated`/`anon` từ `arwdDxtm` → **`rxtm`**.

**Phần 2 — sửa ý định đã ghi trong policy:**

```sql
alter policy session_reports_insert_lead_or_schooladmin on public.session_reports
  with check ( public.is_session_responsible(session_id)
               or (public.is_school_admin() and public.same_school(public.session_school_id(session_id))) );

alter policy session_reports_update_lead_or_schooladmin on public.session_reports
  using      ( public.is_session_responsible(session_id)
               or (public.is_school_admin() and public.same_school(public.session_school_id(session_id))) )
  with check ( public.is_session_responsible(session_id)
               or (public.is_school_admin() and public.same_school(public.session_school_id(session_id))) );
```

**Vì sao vẫn sửa policy dù đã revoke (WP3 giữ nguyên policy, ở đây thì không).** WP3 giữ policy cũ vì chúng **đúng về ý định**, chỉ mất tầm với. Ở đây policy cũ **sai về ý định** — nó ghi lại chính defect. Nếu ngày nào đó rollback bằng `GRANT`, ta phải khôi phục hành vi **đúng**, không phải defect. Policy là tài liệu thi hành được; để nó nói sai là để lại một quả mìn.

Nhánh `is_school_admin()` **giữ lại có chủ ý**: hiệu trưởng cần đường sửa bản ghi nội bộ của trường mình. Nhưng sau revoke, nhánh này **cũng** không với tới được từ user-JWT — nó chỉ còn là mô tả ý định cho tương lai.

### 6.3 Nợ đăng ký tường minh, KHÔNG làm ở WP4

| Nợ | Lý do hoãn |
|---|---|
| `session_reports` thiếu `updated_at` | thêm cột = đổi schema ngoài phạm vi authority |
| Không có RPC approve/reject nhật ký; `state='final'` không có writer | thiết kế sản phẩm, không phải bảo mật — thuộc "Master ký sau" |
| `child_journey` / `child_skills` cho phép **mọi** user cùng trường INSERT/UPDATE trực tiếp (`child_in_my_school`, không cần lead) | **defect class riêng**, nghiêm trọng, **phải đăng ký ngay** — nhưng không phải session authority. Đề xuất WP5 |
| `prep_items` · `session_marks` · `session_media` · `child_observations` vẫn gác bằng `is_session_lead OR is_session_teacher` (hồi tố) | quyền *ghi trong buổi*, không phải authority nhật ký. Đổi ở đây sẽ làm trợ giảng mất việc |
| TRUNCATE toàn nền tảng 62/88 · `pg_default_acl` · `service_role` BYPASSRLS · P2-HARDEN-01 | kế thừa WP3 |

---

## 7. `start_session` audit repair (condition 11)

### 7.1 Defect

```
start_session gọi:  write_audit_log('session_started', jsonb_build_object('session_id', …, 'actor', …))
write_audit_log đọc: p_fields->>'actor_id' · 'entity_type' · 'entity_id' · 'school_id' · 'metadata'
```

⇒ 3 dòng `session_started` sống đều có `actor_id` NULL, `entity_id` NULL, `entity_type` NULL, `metadata` NULL. **Không báo lỗi, không ai biết.**

### 7.2 Sửa (trong S3)

```sql
perform public.write_audit_log('session_started', jsonb_build_object(
  'actor_id',    v_me,
  'entity_type', 'lesson_session',
  'entity_id',   p_session_id,
  'school_id',   public.session_school_id(p_session_id),
  'metadata',    jsonb_build_object('assignment_id', v_assignment_id)
));
```

### 7.3 Ràng buộc

- **KHÔNG backfill, KHÔNG sửa, KHÔNG xoá 3 dòng NULL cũ** (condition 11). Chúng ở lại nguyên trạng như bằng chứng lịch sử về defect.
- **KHÔNG dùng chúng làm bằng chứng backfill** — §5 không tham chiếu chúng ở bất kỳ dòng nào.
- Postcondition S3 phải assert: `select count(*) from audit_logs where action='session_started' and actor_id is null` = **3**, không hơn không kém.
- QA S7 phải có một `start_session` thật rồi verify dòng audit **mới** có đủ 4 trường.

---

## 8. `submit_session_journal` cutover contract

### 8.1 Thứ tự guard — bắt buộc, không đảo

| # | Kiểm tra | Trả về khi fail |
|---|---|---|
| 1 | session tồn tại | `{"ok":false,"reason":"session_not_found"}` |
| 2 | **`public.is_session_responsible(p_session_id)`** | `{"ok":false,"reason":"forbidden"}` |
| 3 | tồn tại dòng `responsible` `is_current` **và** caller cùng trường | `{"ok":false,"reason":"no_responsible_assignment"}` |
| 4 | state hợp lệ | `{"ok":false,"reason":"bad_state","state":…}` |
| 5 | nhánh idempotent | đi qua **đúng** guard 1–4 ở trên |

**Tách bước 2 và 3 để không tạo enumeration cross-school.** Bước 2 trả `forbidden` generic cho mọi lý do (khác trường, không phải người phụ trách, chưa đăng nhập). Bước 3 chỉ chạy **sau khi** đã biết caller cùng trường (kiểm bằng `public.same_school(public.session_school_id(...))` trong RPC), nên `no_responsible_assignment` chỉ lộ cho người trong trường — họ vốn đã thấy buổi đó qua RLS SELECT.

### 8.2 Điều tuyệt đối không được làm

- Không `is_session_lead` ở bất kỳ nhánh nào của hàm này sau S3.
- Không `coalesce` / `or` với `planned`, `taught_by`, `cd.lead_teacher_id` (condition 5).
- Không thêm nhánh `is_school_admin()` vào RPC — hôm nay không có, WP4 **không** thêm. Bất đối xứng với policy `session_reports` được ghi nhận và giữ nguyên; mở nhánh admin là quyết định sản phẩm riêng.
- Không đụng logic duyệt moment, `child_journey`, `child_skills`, `session_reports` upsert, chuyển state — **chỉ đổi cổng**.

### 8.3 Harden `search_path` (D-5 = A, condition 10)

`search_path=public` → **`''`**, qualify đầy đủ **mọi** object. Danh sách phải qualify (đã đếm từ prosrc sống, 4776 ký tự):

`lesson_sessions` · `class_distributions` · `learning_moments` · `moment_children` · `media_assets` · `child_observations` · `child_journey` · `child_skills` · `skill_catalog` · `session_reports` — 10 bảng; `is_session_lead`→`is_session_responsible` · `session_school_id` · `current_profile` · `write_audit_log` — 4 hàm; kiểu `session_state` trong `declare`.

**Rủi ro và cách chặn:** bỏ sót một tên ⇒ `42P01 relation does not exist` **ngay lần chạy đầu**, không phải lỗi im lặng. Nhưng theo **D323-cand**, PL/pgSQL parse lười ⇒ nhánh hiếm (ví dụ nhánh idempotent) có thể không nổ lúc apply. **Bắt buộc:** QA S7 phải chạy **cả hai** nhánh (`in_progress` → submit lần đầu, và `taught_report_pending` → submit lại) trên transaction rollback trước khi đóng.

### 8.4 Bổ sung tuỳ chọn — cần Owner xác nhận ở bước uỷ quyền

`start_session` cũng đang `search_path=public`. Vì S3 đã sửa hàm này (audit + sinh `responsible`), harden luôn sang `''` là gần như miễn phí. **Không** nằm trong chữ của condition 10. Em đề xuất **CÓ**, anh có thể phủ quyết.

---

## 9. `get_session_detail` capability contract (D293)

Thêm **hai** field vào payload `session` sẵn có. **Không** thêm RPC mới, **không** thêm round-trip.

```
'can_submit_journal'  boolean
'submit_block_reason' text | null
```

Bảng ánh xạ — phải **soi gương đúng** 5 nhánh của §8.1:

| Điều kiện | `can_submit_journal` | `submit_block_reason` |
|---|:--:|---|
| `is_session_responsible` false | `false` | `'forbidden'` |
| responsible true nhưng không có dòng (không xảy ra được, giữ để fail-closed) | `false` | `'no_responsible_assignment'` |
| responsible true, state ∉ hợp lệ | `false` | `'bad_state'` |
| responsible true, state `in_progress` | **`true`** | `null` |
| responsible true, state ∈ (`taught_report_pending`,`report_pending_approval`,`completed`) | **`true`** | `null` (gửi lại — nhánh idempotent) |

**Ràng buộc D293:** hai giá trị này **phải** tính bằng cách gọi **chính** `public.is_session_responsible(...)`, không chép logic. Migration S3 phải có assertion so khớp: với mọi buổi × mọi persona QA, `can_submit_journal` = `(submit_session_journal trả ok)`.

`get_session_detail` cũng đang `search_path=public`; **không đụng** ở WP4 (ngoài việc thêm 2 field) để giữ diff nhỏ.

Frontend S4: `StepReview.load()` **bỏ** `supabase.rpc("get_teacher_classes")` khỏi `Promise.all`, `canSubmit` lấy từ `detail.session.can_submit_journal`, biến `leadOfThis` bị xoá. Copy hiện tại *“Chỉ giáo viên phụ trách buổi mới gửi được nhật ký.”* **giữ nguyên** — sau S3 nó mới đúng.

---

## 10. Migration slices — precondition · postcondition · rollback

Mọi migration theo **D92 ba khối**; **D323-cand: dry-run read-only toàn bộ BLOCK 1 trên pre-state sống trước mỗi apply**; **D15: khối REVOKE/GRANT tách riêng sau `CREATE OR REPLACE`, verify bằng `aclexplode`**; **D-A2-1: cấm assert `count(*)=N` của registry trong body**.

### Precondition dùng chung cho **mọi** slice (P00-series)

```
P00a  md5(prosrc of is_session_lead(uuid))          = '8b4f91dda7e45a3c2c801e70579f702d'   ← condition 1
P00b  inventory tables/functions/secdef/policies/triggers = giá trị kỳ vọng của slice
P00c  supabase_migrations có version của slice trước, không có version lạ mới hơn
P00d  session_teacher_assignments: relacl authenticated = {SELECT}, anon = không entry
P00e  lesson_sessions relacl authenticated/anon = 'rxtm' (WP3 chưa bị rollback)
```

---

### **S1 — migration 112 · `v114b_e3_wp4_s1_responsibility_foundation`**

**Nội dung:** constraint conversion (§3) · `sta_supersede_fk` DEFERRABLE · `is_session_responsible` · `dma_assignment_evidence_grade` · `dma_guard_sta_append_only` + trigger swap. **Chưa đổi authority, chưa backfill.**

| | |
|---|---|
| **Precondition** | P00a–P00e · `sta_type_chk` def khớp byte hiện tại · `sta_source_chk` 5 giá trị · `sta_actor_chk` dạng CASE hiện tại · `sta_supersede_fk` **không** deferrable · trigger `trg_sta_immutable` tồn tại, function `prosecdef=false` · **0 dòng có `assignment_type <> 'planned'`** · rows STA = 9 · `is_session_responsible` **chưa tồn tại** |
| **Postcondition** | 4 CHECK mới đúng định nghĩa · FK deferrable=true · `is_session_responsible` tồn tại, `prosecdef=true`, `proconfig={search_path=""}`, ACL = `{authenticated,service_role,postgres}` EXECUTE, **PUBLIC vắng** · `dma_guard_sta_append_only` `prosecdef=false` · `trg_sta_immutable` **không còn**, `trg_sta_append_only` tồn tại · **rows STA = 9, `STA-CANON-1` KHÔNG ĐỔI** · functions 207→**209**, secdef 198→**200**, triggers 33→33 · `is_session_lead` md5 không đổi |
| **In-tx probe** | (a) INSERT `assignment_type='responsible'` hợp lệ → **thành công**, rollback. (b) INSERT `assignment_type='planned'` + `assignment_source='runtime_start_session'` → **fail** `sta_dimension_source_chk`. (c) UPDATE đúng hình dạng supersede dưới `postgres` → **thành công**, rollback. (d) UPDATE `teacher_id` → **fail**. (e) UPDATE `is_current` false→true → **fail**. (f) DELETE → **fail**. (g) `set local role authenticated` + UPDATE → **fail** (privileged guard). |
| **Rollback** | Khôi phục 3 CHECK cũ + drop `sta_dimension_source_chk` · FK về non-deferrable · `drop function is_session_responsible, dma_assignment_evidence_grade` · `drop trigger trg_sta_append_only` + `create trigger trg_sta_immutable … dma_guard_sta_immutable()` (giữ function cũ, **không drop**, để rollback là một lệnh) · dữ liệu ±0 |
| **Gate vào** | §0.1 RESOLVED ✅ (condition 13) |

### **S2 — migration 113 · `v114b_e3_wp4_s2_responsible_backfill`**

| | |
|---|---|
| **Precondition** | P00a–P00e · S1 đã apply (4 CHECK mới hiện diện) · rows STA = **9** · `count(assignment_type='responsible')` = **0** · đúng **3** buổi thoả `taught_by is not null and state in (…)` · buổi `aaaa…0a0003` tồn tại, `taught_by is null`, `state='in_progress'` · profile `d1000000-…-011` tồn tại, `state='active'`, cùng trường với buổi #4 · `LS-CANON-1` = `fa919ddfc6f8dfa4e2efddb8e30729f3` |
| **Postcondition** | rows STA = **13** · `responsible` = **4** · `planned` = **9**, `STA-PLANNED-CANON` **không đổi** · phân bố source: `migration_responsible_backfill`=3, `migration_owner_attested`(responsible)=1 · mỗi buổi có **≤1** dòng `responsible` `is_current` (vòng lặp kiểm từng session_id) · **0** dòng `responsible` cho 5 buổi scheduled/cancelled · `lesson_sessions` rows=9 và `LS-CANON-1` **không đổi** · `learning_moments` · `child_observations` · `session_reports` · `child_journey` · `child_skills` count **±0** · audit thêm đúng **4** dòng `session_responsibility_backfilled` |
| **Zero-unexplained-delta** | Chỉ được thay đổi: +4 dòng STA, +4 dòng `audit_logs`, +1 dòng registry. Mọi hash khác byte-identical |
| **Rollback** | `delete from session_teacher_assignments where assignment_type='responsible' and assignment_source in ('migration_responsible_backfill','migration_owner_attested')` — **nhưng trigger chặn DELETE**. ⇒ Rollback S2 **bắt buộc** phải chạy sau khi tạm gỡ trigger, hoặc rollback S1 trước. **Ghi rõ trong runbook:** thứ tự rollback là **S2 → S1**, và rollback S2 phải là `alter table … disable trigger trg_sta_append_only; delete …; enable trigger` dưới vai `postgres`. Đây là chi phí có chủ ý của append-only |
| **Gate vào** | S1 PASS · Owner đã ký D-2 ✅ |

### **S3 — migration 114 · `v114b_e3_wp4_s3_authority_cutover`**

| | |
|---|---|
| **Nội dung** | `submit_session_journal`: cổng → `is_session_responsible` + nhánh `no_responsible_assignment` + `search_path=''` + qualify đầy đủ · `start_session`: sinh dòng `responsible` + sửa audit payload (+ harden `search_path` nếu Owner duyệt §8.4) · `get_session_detail`: +2 field capability |
| **Precondition** | P00a–P00e · S2 PASS · `responsible` = 4 · md5 3 hàm khớp giá trị đã ghim (`8fc9ace1…` · `9307a5d9…` · `7f83cfce…`) · 3 dòng `session_started` NULL đang tồn tại |
| **Postcondition** | 3 hàm md5 **đã đổi** · `prosecdef=true` cả 3 · `submit_session_journal.proconfig = {search_path=""}` · **`prosrc` của `submit_session_journal` KHÔNG chứa chuỗi `is_session_lead`** · `is_session_lead` md5 **không đổi** (P00a) · 4 function + 14 policy khác vẫn tham chiếu `is_session_lead` **nguyên vẹn** (fingerprint policy `a1ea3593…` không đổi) · ACL 3 hàm không đổi · inventory functions 209, secdef 200 · rows mọi bảng ±0 · `count(session_started where actor_id is null)` = **3** |
| **In-tx probe** | xem §11 |
| **Rollback** | `CREATE OR REPLACE` 3 hàm về nguyên bản (giữ sẵn 3 khối `pg_get_functiondef` trước apply) **+ khối REVOKE/GRANT riêng ngay sau (D15)** + verify `aclexplode`. Dữ liệu ±0 |
| **Cửa sổ lệch** | Từ S3 apply → S4 deploy, frontend vẫn tính `canSubmit` bằng `get_teacher_classes.is_lead`. Với dataset hiện tại, lead = responsible ở cả 4 buổi ⇒ **không lệch trên thực tế**. Đã verify. Nếu Owner đổi lead trong cửa sổ này thì nút sẽ bật mà RPC từ chối. **Runbook: không đổi lead từ khi apply S3 tới khi deploy S4** |

### **S4 — frontend (không migration)**

| | |
|---|---|
| **Nội dung** | `teacher.session.$id.tsx`: `StepReview.load()` bỏ `get_teacher_classes`, `canSubmit` ← `can_submit_journal`; thêm text cho `no_responsible_assignment`. `school.schedule.tsx`: Surface B thêm dòng “Giáo viên phụ trách” (chỉ khi có, kèm chú thích nếu `owner_attested`) |
| **Precondition** | S3 PASS · `list_edits limit=1` = `d8178a55…` (single-writer, D134) · đọc `createFileRoute(...)` xác nhận đúng file (D117) |
| **Postcondition** | build PASS · `get_diff` xác nhận đúng phạm vi (D134) · **không** file nào ngoài 2 file trên bị đụng |
| **Rollback** | revert commit |
| **Chế độ** | **paste mode** mặc định — em đưa block byte-exact, anh dán. Trừ khi anh nói “tự áp” |

### **S5 — migration 115 · `v114b_e3_wp4_s5_session_reports_containment`**

| | |
|---|---|
| **Precondition** | S4 **đã deploy production** · P00a–P00e · `session_reports` relacl `authenticated`/`anon` = `arwdDxtm` · 3 policy đúng định nghĩa hiện tại · rows `session_reports` = 3 · **§0.3 PARTIAL 2/6 đã nâng lên 6/6** (xem §12) |
| **Postcondition** | relacl → **`rxtm`** cho cả 2 role · SELECT còn nguyên (`has_table_privilege` true) · `service_role`/`postgres` không đổi · PUBLIC vắng · column ACL vắng (`attacl` null ×10) · 2 policy ghi đã trỏ `is_session_responsible` · policy `_select_school` **byte-identical** · rows ±0 · policy count 166 |
| **In-tx probe** | GV phụ trách UPDATE trực tiếp → `42501` · master_admin INSERT trực tiếp → `42501` · `anon` TRUNCATE → `42501` · `submit_session_journal` của người phụ trách → vẫn `ok:true` (rollback) · `service_role` UPDATE → **thành công** (control, rollback) |
| **Rollback** | `grant insert, update, delete, truncate on table public.session_reports to authenticated, anon;` dưới vai `postgres` (**không** `GRANT ALL`) + `alter policy` về 2 predicate cũ. Vài giây |

### **S6 — migration 116 · `v114b_e3_wp4_s6_responsibility_transfer`** (D-4 = A)

| | |
|---|---|
| **Precondition** | S5 PASS · `transfer_session_responsibility` chưa tồn tại · FK deferrable=true · trigger append-only tồn tại · `dma_assignable_teacher_reason(uuid,uuid)` tồn tại, `prosecdef=false` |
| **Postcondition** | hàm tồn tại, DEFINER, `search_path=''`, ACL `{authenticated,service_role,postgres}`, PUBLIC vắng · functions 210, secdef 201 · rows ±0 |
| **In-tx probe** | master_admin cùng trường + lý do 15 ký tự → `ok:true`, STA 13→14, dòng cũ `is_current=false`+`valid_to`+`superseded_by`, dòng mới `is_current=true`, audit 1 dòng đủ 4 trường — **rollback** · lý do 5 ký tự → `reason_required` · GV phụ trách gọi → `not_authorized_for_school` · master_admin trường khác → `not_authorized_for_school` · target khác trường → `target_teacher_invalid` · target NULL → `target_required` · buổi cancelled → `bad_state` · gọi lại cùng target → `already:true`, rows không đổi |
| **Rollback** | `drop function public.transfer_session_responsibility(uuid,uuid,text);` |

### **S7 — QA login thật (không migration)**

D2/D3: login thật 2 trường, không chỉ SQL Editor. Chi tiết §11.3.

---

## 11. Transactional persona QA

Mọi probe chạy trong subtransaction và **rollback**. Mẫu WP3 Checkpoint B. Mật khẩu tất cả: `Test@123`.

### 11.1 Nhân sự

| Persona | Email | profile_id | Vai |
|---|---|---|---|
| Đặng Mỹ Linh | `gv.linh.kidshouse@demo.demenart.com` | `d1000000-…-011` | lead_teacher · **responsible** 4 buổi · lead hiện tại |
| Lê Thảo My | `gv.my.kidshouse@demo.demenart.com` | `d1000000-…-014` | assistant_teacher · không responsible |
| Huỳnh Trần Nguyệt Thi | `hieutruong.kidshouse@demo.demenart.com` | `d1000000-…-010` | master_admin KHM |
| Bùi Ngọc Hân | `gv.han.demen@demo.demenart.com` | `d2000000-…-011` | lead_teacher MNDM (cross-school) |
| Mai Phương Dung | `hieutruong.demen@demo.demenart.com` | `d2000000-…-010` | master_admin MNDM (cross-school) |
| Nguyễn Văn Hùng | `ph.hung.kidshouse@demo.demenart.com` | — | phụ huynh |
| **Trần Khánh Vy** | **không có auth user** | `d1000000-…-013` | **QA DEBT — xem §11.4** |

### 11.2 Ma trận probe sau S3

| # | Persona | Buổi | Kỳ vọng |
|---|---|---|---|
| Y01 | Mỹ Linh | `0a0002` taught_report_pending | `ok:true, already:true` — nhánh idempotent qua cổng mới |
| Y02 | Mỹ Linh | `0a0003` in_progress (owner-attested) | `ok:true` — **chứng minh backfill owner-attested làm luồng hợp lệ chạy được** |
| Y03 | Mỹ Linh | `3bfb9730` scheduled | `bad_state` |
| Y04 | Lê Thảo My | `0a0002` | `forbidden` |
| Y05 | Nguyệt Thi (master_admin cùng trường) | `0a0002` | `forbidden` — **không có nhánh admin trong RPC, có chủ ý** |
| Y06 | Bùi Ngọc Hân | `0a0002` | `forbidden` (generic, không lộ tồn tại) |
| Y07 | Phương Dung | `0a0002` | `forbidden` |
| Y08 | PH Hùng | `0a0002` | `forbidden` |
| Y09 | Mỹ Linh | uuid không tồn tại | `session_not_found` |
| **Y10** | **Mỹ Linh — sau khi `set_distribution_lead` đổi lead sang Vũ Hoàng Nam trong cùng tx** | `0a0002` | **`ok:true`** ← **ĐÂY LÀ PROBE QUAN TRỌNG NHẤT CỦA CẢ WP4** |
| **Y11** | **Vũ Hoàng Nam — sau cùng thao tác đổi lead đó** | `0a0002` | **`forbidden`** ← chứng minh hết hồi tố |
| Y12 | Mỹ Linh | `get_session_detail(0a0002)` | `can_submit_journal=true`, `submit_block_reason=null` |
| Y13 | Lê Thảo My | `get_session_detail(0a0002)` | `can_submit_journal=false`, `reason='forbidden'` |
| Y14 | Mỹ Linh | `get_session_detail(3bfb9730)` | `can_submit_journal=false`, `reason='bad_state'` |
| Y15 | Lê Thảo My | `start_session(3bfb9730)` rồi `submit` | `start_session` `ok:true` (cô là session teacher?) → nếu ok, `submit` phải `ok:true` vì cô vừa thành responsible — **kiểm tra lifecycle §2 end-to-end** |
| Y16 | control `service_role` | UPDATE trực tiếp `session_reports` | **thành công** (rollback) — chứng minh revoke không lan quá phạm vi |

**Y10/Y11 là bằng chứng đối chứng trực tiếp với §5.1 của A1/A2**: cùng một thao tác `set_distribution_lead` đã từng chuyển quyền hồi tố ngày 21/07, sau WP4 phải **không** còn tác dụng lên buổi lịch sử.

### 11.3 QA login thật (S7 — D2/D3, không thay thế bằng SQL)

| # | Login | Bước | Kỳ vọng |
|---|---|---|---|
| 1 | `gv.linh.kidshouse@demo.demenart.com` / `Test@123` | `/teacher/session/aaaa0000-0000-4000-8000-0000000a0002` → Bước 4 | Nút **“Gửi lại nhật ký”** bật |
| 2 | ″ | Bấm gửi | Màn “Đã gửi nhật ký tới gia đình” |
| 3 | `gv.my.kidshouse@demo.demenart.com` / `Test@123` | cùng route → Bước 4 | Ô vàng “Chỉ giáo viên phụ trách buổi mới gửi được nhật ký” — **không** nút |
| 4 | `hieutruong.kidshouse@demo.demenart.com` / `Test@123` | `/school/schedule` | Lưới tuần + nhãn “Giáo viên dự kiến” render **không đổi** |
| 5 | ″ | mở panel chi tiết buổi `0a0002` | Có **cả hai** dòng: “Giáo viên dự kiến” và “Giáo viên phụ trách” |
| 6 | ″ | mở panel buổi `0a0003` | Dòng phụ trách kèm chú thích owner-attested |
| 7 | ″ | `/school/manage` đổi giáo viên chính lớp Hoa Hồng sang người khác | thành công |
| 8 | quay lại (1) | `/teacher/session/…0a0002` | **Nút vẫn bật cho Mỹ Linh** — bằng chứng vận hành cuối cùng |
| 9 | ″ | trả lead về Mỹ Linh | dọn dẹp |
| 10 | `ph.hung.kidshouse@demo.demenart.com` / `Test@123` | `/parent/journal` | Hành trình con render, **không đổi** |

Bước 7–8 là **mutation thật trên production** ⇒ cần Owner uỷ quyền riêng ở bước QA, không nằm trong uỷ quyền implementation.

### 11.4 QA debt (kế thừa + mới)

- **`sub_admin`** — không có profile `sub_admin` nào trên dữ liệu sống; nhánh school-admin của `transfer_session_responsibility` **chưa probe thực nghiệm được**. Kế thừa WP3 §5.4.
- **Trần Khánh Vy (`…013`)** — có profile nhưng **không có auth user** ⇒ không impersonate được. Y11 dùng **Vũ Hoàng Nam (`…012`)** thay thế; Nam cũng không có auth user? **Phải verify trước S7**; nếu không có, Y11 chuyển sang đánh giá predicate read-only (như §5.2 của A1/A2) và ghi là compensating evidence.
- **Consent negative fixture** — kế thừa WP1 §7, không đụng.

---

## 12. Stop conditions

Dừng ngay, không thiết kế vòng qua, nếu bất kỳ điều nào xảy ra:

| # | Điều kiện dừng | Slice liên quan |
|---|---|---|
| 1 | `md5(prosrc)` của `is_session_lead` khác `8b4f91dd…` ở bất kỳ thời điểm nào | mọi slice |
| 2 | Bất kỳ đường nào cho phép `responsible` rơi về `planned` / `taught_by` / `cd.lead_teacher_id` | S3 |
| 3 | Phát hiện dòng STA `assignment_type` ngoài `{planned, responsible}` | S1+ |
| 4 | Một `assignment_source` mới lọt vào chiều `planned` (⇒ parser `school.schedule.tsx` vỡ) | S1 |
| 5 | Supersession xoá/ghi đè được bất kỳ cột lịch sử nào | S1, S6 |
| 6 | `authenticated`/`anon` ghi trực tiếp được STA | mọi slice |
| 7 | Sau S5, một luồng hợp lệ fail vì privilege trên `session_reports` | S5 |
| 8 | **§0.3 không nâng được lên 6/6** — tức tìm thấy một frontend writer thật của `session_reports` | **chặn S5** |
| 9 | Backfill sinh ≠ 4 dòng, hoặc chạm bất kỳ buổi scheduled/cancelled nào | S2 |
| 10 | Dòng owner-attested bị ánh xạ thành `db_proven` ở bất kỳ reader nào | S2+ |
| 11 | 3 dòng `session_started` NULL bị sửa/xoá/backfill | S3 |
| 12 | Bất kỳ hash zero-delta nào đổi ngoài dự kiến | mọi slice |
| 13 | `apply_migration` fail giữa chừng và registry ghi version nhưng body rollback | mọi slice — kiểm bằng Layer B external |
| 14 | Owner đổi lead trong cửa sổ S3→S4 | runbook |

### Precondition cứng còn phải trả trước S5

Đọc toàn văn 4 file còn lại và xác nhận **0** lần xuất hiện `.from("session_reports")` kèm `.insert/.update/.upsert/.delete`:
`src/routes/_authenticated/school.index.tsx` · `school.moments.tsx` · `teacher.index.tsx` · `admin.lookup.tsx`.
Ước lượng: 1 lượt đọc/file, không tốn credit Lovable (read_file miễn phí). **Không chặn S1–S4.**

---

## 13. Tóm tắt thay đổi inventory dự kiến

| Mốc | tables | functions | secdef | policies | triggers | migrations | STA rows |
|---|:--:|:--:|:--:|:--:|:--:|:--:|:--:|
| Hiện tại | 88 | 207 | 198 | 166 | 33 | 111 | 9 |
| Sau S1 | 88 | **209** | **200** | 166 | 33 | **112** | 9 |
| Sau S2 | 88 | 209 | 200 | 166 | 33 | **113** | **13** |
| Sau S3 | 88 | 209 | 200 | 166 | 33 | **114** | 13 |
| Sau S5 | 88 | 209 | 200 | 166 | 33 | **115** | 13 |
| Sau S6 | 88 | **210** | **201** | 166 | 33 | **116** | 13 |

Bảng · policy · trigger count: **±0 toàn bộ WP4**. Không tạo bảng, không tạo cột, không tạo policy.

---

## 14. Điều em làm ngoài chữ của conditions — Owner có thể phủ quyết

| # | Việc | Lý do | Mặc định |
|---|---|---|---|
| 1 | Thêm CHECK `sta_dimension_source_chk` (không ai yêu cầu) | Khoá cứng việc source mới không lọt vào `planned` ⇒ parser frontend không thể vỡ. Rẻ, một dòng | **LÀM** |
| 2 | Đổi `sta_supersede_fk` sang DEFERRABLE | **Bắt buộc kỹ thuật** — không có nó thì supersession không thực hiện được (§3) | **LÀM** |
| 3 | Sửa cả 2 policy ghi của `session_reports` sang `is_session_responsible` | Để rollback khôi phục hành vi đúng chứ không phải defect | **LÀM** |
| 4 | Harden `start_session` sang `search_path=''` | Đang sửa hàm đó rồi; gần như miễn phí | **LÀM — anh phủ quyết được** |
| 5 | Tạo `dma_assignment_evidence_grade` | Tránh chép tay ánh xạ owner_attested ở nhiều nơi | **LÀM** |
| 6 | Audit của `transfer_session_responsibility` **không** bọc `exception when others` | Với hành động authority, audit là sản phẩm | **LÀM** |

---

## 15. Documentation impact

Không sửa file canonical. `DMA_RULES.md` endpoint **D309**, `DMA_SYSTEM_MAP.md` **v1.14** giữ nguyên tới **E3 milestone closeout**.

Candidate mới sinh ở A3/A4, chưa gán số canonical:

> **D327-cand — [migration · SUPERSESSION CẦN FK DEFERRABLE]**
> Mẫu append-only "một dòng hiện hành + con trỏ `superseded_by`" có vòng phụ thuộc không gỡ được nếu FK lineage là immediate: unique-partial-index buộc đóng dòng cũ trước, FK buộc dòng mới tồn tại trước. Thiết kế bảng append-only phải khai báo FK lineage là `DEFERRABLE INITIALLY DEFERRED` **ngay từ đầu**, nếu không sẽ phải ALTER giữa đường và mọi lỗi sẽ dời về COMMIT.

> **D328-cand — [coverage · CỬA SỔ GIT LÀ BẰNG CHỨNG ĐỦ]**
> Khi MCP không có repo-wide search, coverage của một **bảng mới** giải được trọn vẹn bằng lập luận cửa sổ thời gian: bảng ra đời ở migration `T`; mọi tham chiếu frontend phải nằm trong commit sau `T`; một `get_diff(base=<commit cuối trước T>, head=HEAD)` phủ toàn bộ không gian. Chỉ áp dụng cho **object mới** — không áp dụng cho object đã tồn tại lâu (ví dụ `session_reports`), nơi vẫn phải đọc file.

> **D329-cand — [UI · PARSER NGHIÊM NGẶT LÀ TÍNH NĂNG BẢO MẬT]**
> `school.schedule.tsx` từ chối cả response khi gặp `evidence_grade` lạ và hiện "chưa hiển thị được" thay vì render một phần. Đây là hành vi **đúng** (thà im lặng còn hơn nói sai — họ hàng D290) và nó biến mọi lần mở từ vựng backend thành một breaking change **có thể phát hiện được**. Khi mở enum/whitelist, phải kiểm tra parser client trước, và ưu tiên ràng buộc DB khoá giá trị mới ra khỏi chiều dữ liệu mà parser đang đọc.

Tài liệu tiếp theo: `DMA_V114B_E3_WP4_S1_APPLY.md` … → `DMA_V114B_E3_WP4_CLOSEOUT.md` → **E3 milestone closeout** (nơi RULES/SYSTEM_MAP canonicalize một lần, gộp khối WP3 §13 + D310…D329-cand).

---

WP4-A3/A4 COMPLETE — READY FOR IMPLEMENTATION AUTHORIZATION
