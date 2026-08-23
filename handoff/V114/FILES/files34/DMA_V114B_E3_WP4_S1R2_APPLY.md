# DMA V114B-E3 · WP4-S1R2 — RESPONSIBILITY FOUNDATION APPLY REPORT

> **KẾT QUẢ: PASS — FOUNDATION APPLIED.**
> Migration **112** `20260722134535` `v114b_e3_wp4_s1_responsibility_foundation`. Full dress rehearsal **48/48 PASS** trước khi apply. Apply gọi **đúng một lần**, thành công, **không retry**. Layer B **PASS**, probe **17/17 PASS**, Layer B rerun **PASS**.
> **Inventory 88 / 210 / 199 / 166 / 33.** STA 9 dòng · planned 9 · **responsible 0**. STA-CANON-1 **không đổi**. Business row **±0**. Audit row **±0**. Frontend **0 file**.

---

## 1. Third pre-apply continuity pin

| Hạng mục | Kỳ vọng | Quan sát | Kết quả |
|---|---|---|---|
| Repository HEAD | `d8178a55895b64bbffdf79bb05c06e6b4313d68b` | khớp (`edt-af7bf0bd`) | **PASS** |
| Migration registry | 111 · latest `20260722112305` · 0 dòng S1 | khớp | **PASS** |
| Inventory | 88/207/198/166/33 | khớp | **PASS** |
| STA rows · planned · responsible | 9 · 9 · 0 | khớp | **PASS** |
| STA-CANON-1 | `59e173e793d15c8cd848f1664f99df32` | khớp | **PASS** |
| CHECK / index / policy fingerprint | `9dcdb354…` / `bb8d78ed…` / `5700d689…` | khớp | **PASS** |
| FK `sta_supersede_fk` | tồn tại, **không** deferrable | `false` | **PASS** |
| Trigger | `trg_sta_immutable/27/dma_guard_sta_immutable()` | khớp | **PASS** |
| 3 function mới | vắng | 0 | **PASS** |
| `is_session_lead` md5 | `8b4f91dda7e45a3c2c801e70579f702d` | khớp | **PASS** |
| Function cấp `anon:EXECUTE` | 0/207 | **0** | **PASS** |
| lesson_sessions WP3 ACL | SELECT/REFERENCES/TRIGGER/MAINTAIN | khớp | **PASS** |
| **STA relacl fingerprint** (mới ghim cho T11b) | — | **`9668f7a072cc0a9a933c62b217dccc3d`** | ghim |
| STA ACL | `authenticated:SELECT` + `postgres:{9}`; anon/service_role/PUBLIC **vắng** | khớp | **PASS** |
| Residue `zz_*` | 0 | 0 | **PASS** |

**Zero drift.**

---

## 2. Block 1 dry-run

Chạy lại toàn bộ body BLOCK 1 read-only trên pre-state sống.

```
STEP2-BLOCK1-DRYRUN :: 27 assertions PASS · inv 88/207/198/166/33
                     · sta 9 (p9 r0) · canon 59e173e793d15c8cd848f1664f99df32
```

**27/27 PASS**, phủ P01–P24 (27 câu `IF` cho 24 nhóm P). Mọi giá trị gom vào biến trước khi so sánh ⇒ không biểu thức parse-lười (D323-cand). Không alias trùng biến `DECLARE`.

### 2.1 Tiền đề bắt buộc của dress rehearsal — chứng minh `execute_sql` bọc transaction

Trước khi chạy bất kỳ DDL nào ngoài `apply_migration`, phải chứng minh nhiều câu lệnh trong một lần `execute_sql` nằm trong **một** transaction — nếu không, DDL sẽ commit nửa chừng và phá production.

Probe: `create or replace function public.zz_tx_wrap_probe() …;` rồi `do $$ begin raise exception 'TXWRAP_FORCED_ROLLBACK'; end $$;`

| Kiểm | Kết quả |
|---|---|
| Hàm probe sống sót? | **0** |
| `functions` sau probe | **207** (không đổi) |
| registry | 111 (không đổi) |

⇒ **`execute_sql` bọc transaction. Dress rehearsal bằng terminal RAISE là an toàn.**

---

## 3. Full dress rehearsal

Chạy **toàn bộ** biến đổi S1 ngoài `apply_migration`, đúng thứ tự thật (timezone → constraint → FK → 3 function → khối ACL → trigger → BLOCK 3 → probe → Layer-B-equivalent), rồi **ép rollback** bằng terminal RAISE.

| Check group | Passed | Total | Evidence |
|---|---:|---:|---|
| Constraint posture | 3 | 3 | `sta_type_chk` chứa `responsible` · `sta_dimension_source_chk` tồn tại · CHECK count = **7** |
| FK posture | 3 | 3 | `condeferrable=t` · `condeferred=t` · cột lineage không đổi |
| `is_session_responsible` posture + ACL | 2 | 2 | DEFINER · `search_path=""` · STABLE · ACL `authenticated,postgres,service_role` |
| `dma_assignment_evidence_grade` posture + ACL | 2 | 2 | IMMUTABLE · `search_path=""` · ACL `authenticated,postgres,service_role` |
| `dma_guard_sta_append_only` posture + ACL | 2 | 2 | INVOKER · `search_path=""` · ACL **`postgres`** only |
| PUBLIC / grant-option / anon | 3 | 3 | PUBLIC **0** · grant option **0** · function toàn schema cấp anon **0** |
| **Evidence-grade mapping (scalar)** | **9** | **9** | 9 kiểm độc lập, **không** aggregate, **không** phụ thuộc thứ tự |
| Trigger | 2 | 2 | `trg_sta_append_only/27/dma_guard_sta_append_only()` · `trg_sta_immutable` vắng |
| Probes T01–T15 | 13 | 13 | xem §11 |
| **Inventory (V24)** | 1 | 1 | **88/210/199/166/33 quan sát thực nghiệm** |
| Rows / canon / relacl / isl / policy / lsacl / audit / business | 8 | 8 | tất cả không đổi sau **toàn bộ** probe |
| **TỔNG** | **48** | **48** | |

Chuỗi kết quả nguyên văn:

```
DRESS-REHEARSAL PASS :: checks=48 | inv=88/210/199/166/33 | sta=9/p9/r0
 | canon=59e173e793d15c8cd848f1664f99df32 | relaclfp=9668f7a072cc0a9a933c62b217dccc3d
 | iacl=[authenticated,postgres,service_role] eacl=[authenticated,postgres,service_role]
   gacl=[postgres] pub=0 granopt=0 anonfn=0 | fk=t/t | trg=trg_sta_append_only
```

> **Điểm quyết định:** V24 = 88/210/199/166/33 lần đầu tiên được **quan sát**, không còn là suy diễn. Đây chính là hằng số đã tiêu một lần apply ở S1.

---

## 4. Forced rollback verification

Sau rollback ép buộc, đo lại ngoài transaction:

| Hạng mục | Kỳ vọng | Quan sát | Kết quả |
|---|---|---|---|
| Migration registry | 111 | **111** | **PASS** |
| Inventory | 88/207/198/166/33 | **88/207/198/166/33** | **PASS** |
| 3 function mới | vắng | **0** | **PASS** |
| STA CHECK count · fingerprint | 6 · `9dcdb354…` | 6 · `9dcdb354…` | **PASS** |
| FK deferrable | false | **false** | **PASS** |
| Trigger | `trg_sta_immutable/27/…immutable()` | khớp | **PASS** |
| STA rows · planned | 9 · 9 | 9 · 9 | **PASS** |
| STA-CANON-1 | `59e173e7…` | khớp | **PASS** |
| **STA relacl fingerprint** | `9668f7a0…` | **`9668f7a0…`** byte-identical | **PASS** |
| **`service_role` trên STA (grant tạm T11b)** | 0 | **0** | **PASS** |
| `is_session_lead` md5 | `8b4f91dd…` | khớp | **PASS** |
| Function cấp anon EXECUTE | 0 | **0** | **PASS** |
| Disposable residue `zz_*` | 0 | **0** | **PASS** |
| Business rows LS/SR/LM/CO · audit | 9/3/22/9 · 10 977 | khớp | **PASS** |

**Zero residue. Grant tạm của T11b biến mất hoàn toàn, relacl byte-identical.**

---

## 5. Corrected assertion design

Bỏ hoàn toàn so sánh dựa aggregate. Không còn `string_agg` / `array_agg` / `jsonb_agg` / vector viết tay trong đường verify mapping. Thay bằng **9 assertion vô hướng độc lập** `V10e-01…07`, `V11`, `V12` — đúng nguyên văn khối đã duyệt.

Ánh xạ được kiểm **hai lần**: một lần trong BLOCK 3 của migration (raise-on-fail), một lần trong bộ probe post-apply (đếm) → **T14 = 9/9**.

Thân hàm `dma_assignment_evidence_grade(text)` **không đụng một byte** — md5 `d0666e7d7d5c7a022f2641def4a79c9c`.

---

## 6. Migration apply

| | |
|---|---|
| Tool call | `apply_migration` — **gọi đúng một lần** |
| **Assigned version** | **`20260722134535`** |
| Migration name | `v114b_e3_wp4_s1_responsibility_foundation` |
| Digest formula | `md5(array_to_string(statements, E'\n'))` |
| **Digest** | **`f9e1053f59ce020758368b66b653dc58`** |
| `array_length(statements,1)` | **1** — toàn bộ script lưu thành một phần tử |
| Result | **`{"success": true}`** |
| Notices | không trả về qua transport MCP (BLOCK 1 và BLOCK 3 đều có `RAISE NOTICE`; nội dung của chúng được xác minh độc lập ở §3 và §7–§11) |
| Retry count | **0** |
| Migration inventory | **111 → 112** |

---

## 7. External Layer B

Chạy ngay sau apply, và **chạy lại lần hai sau toàn bộ probe** — cả hai lần giống hệt nhau.

| Check | Expected | Observed | Result |
|---|---|---|---|
| B01 migration count | 112 | **112** | **PASS** |
| B02 latest migration | S1 | `20260722134535` | **PASS** |
| B03 tables | 88 | 88 | **PASS** |
| B04 functions | **210** | **210** | **PASS** |
| B05 SECURITY DEFINER | **199** | **199** | **PASS** |
| B06 policies | 166 | 166 | **PASS** |
| B07 triggers | 33 | 33 | **PASS** |
| B08 STA rows | 9 | 9 | **PASS** |
| B09 planned | 9 | 9 | **PASS** |
| B10 **responsible** | **0** | **0** | **PASS** |
| B11 **STA-CANON-1** | `59e173e793d15c8cd848f1664f99df32` | khớp | **PASS** |
| B12 STA relacl fingerprint | `9668f7a072cc0a9a933c62b217dccc3d` | khớp | **PASS** |
| B13 STA policy fingerprint | `5700d689c33a7a84e5ef28a7c03c2670` | khớp | **PASS** |
| B14 STA index fingerprint | `bb8d78ede51c1f8968babd7fbd3aac83` | khớp | **PASS** |
| B15 `is_session_lead` md5 | `8b4f91dd…` | khớp | **PASS** |
| B16 `submit_session_journal` md5 | `8fc9ace1…` | khớp | **PASS** |
| B17 `start_session` md5 | `9307a5d9…` | khớp | **PASS** |
| B18 `get_session_detail` md5 | `7f83cfce…` | khớp | **PASS** |
| B19 `get_school_week_planned_teachers` md5 | `13d57d0e…` | khớp | **PASS** |
| B20 Function cấp `anon:EXECUTE` | 0 | **0** | **PASS** |
| B21 business rows LS/SR/LM/CO | 9/3/22/9 | 9/3/22/9 | **PASS** |
| B22 audit_logs | 10 977 | 10 977 | **PASS** |
| B23 disposable residue | 0 | 0 | **PASS** |

**23/23 PASS × 2 lần.**

---

## 8. Constraint and FK posture

**7 CHECK** (6 → 7). Định nghĩa chuẩn hoá đang sống:

```
sta_type_chk               CHECK (assignment_type = ANY (ARRAY['planned','responsible']))
sta_source_chk             CHECK (assignment_source = ANY (ARRAY[8 giá trị]))
sta_actor_chk              CHECK (CASE WHEN assignment_source = ANY (ARRAY[
                             'runtime_distribution_lead_snapshot','runtime_start_session',
                             'responsibility_transfer']) THEN assigned_by IS NOT NULL
                             ELSE assigned_by IS NULL END)
sta_dimension_source_chk   CHECK (CASE assignment_type
                             WHEN 'planned'     THEN assignment_source = ANY (ARRAY[5 giá trị planned])
                             WHEN 'responsible' THEN assignment_source = ANY (ARRAY[4 giá trị responsible])
                             ELSE false END)
sta_current_chk · sta_validity_chk · sta_no_self_supersede_chk   — KHÔNG ĐỔI
```

**FK lineage:**

```
sta_supersede_fk  FOREIGN KEY (superseded_by, session_id, assignment_type)
                  REFERENCES session_teacher_assignments(id, session_id, assignment_type)
                  DEFERRABLE INITIALLY DEFERRED
```

`condeferrable = true`, `condeferred = true`. Cột và target **không đổi**.
Index (5), policy `sta_select_school`, ACL bảng: **không đụng** — fingerprint bằng chứng ở §7.

---

## 9. Function posture and normalized ACL

Đọc bằng `aclexplode(coalesce(proacl, acldefault('f', proowner)))`, **không** dựa thứ tự văn bản aclitem.

| Identity | Owner | Security | search_path | Volatility | Lang | Normalized ACL (grantee:priv:grantable) | md5(prosrc) |
|---|---|---|---|---|---|---|---|
| `is_session_responsible(uuid)` | postgres | **DEFINER** | `""` | `s` STABLE | sql | `authenticated:EXECUTE:false, postgres:EXECUTE:false, service_role:EXECUTE:false` | `488756875716bc43760b780e1c2edf6d` |
| `dma_assignment_evidence_grade(text)` | postgres | INVOKER | `""` | `i` IMMUTABLE | sql | `authenticated:EXECUTE:false, postgres:EXECUTE:false, service_role:EXECUTE:false` | `d0666e7d7d5c7a022f2641def4a79c9c` |
| `dma_guard_sta_append_only()` | postgres | **INVOKER** | `""` | `v` | plpgsql | **`postgres:EXECUTE:false`** | `353c6ad4dca350460a549a464dfbac9d` |
| `dma_guard_sta_immutable()` *(giữ cho rollback)* | postgres | INVOKER | `""` | `v` | plpgsql | `postgres:EXECUTE:false` | `ad939ee69823c54b9ccaca19a64d5919` **không đổi** |

**Chứng minh bổ sung:**

- **0** grant tới `anon` trên **toàn bộ 210** function schema `public`
- **0** entry PUBLIC trên cả ba function mới
- **0** grant option (`is_grantable = false` toàn bộ)
- `dma_guard_sta_append_only` **không có caller EXECUTE ngoài `postgres`** — khớp đúng posture của guard cũ

---

## 10. Trigger and append-only posture

| | |
|---|---|
| Trigger đang sống | **`trg_sta_append_only`** · tgtype **27** (ROW + BEFORE + DELETE + UPDATE) · `dma_guard_sta_append_only()` |
| `trg_sta_immutable` | **vắng mặt** |
| Trigger count toàn schema | **33** (drop 1 + create 1) |
| DELETE | **chặn vô điều kiện**, kể cả `postgres` |
| UPDATE | chỉ cho **đúng một** hình dạng: `is_current` true→false + `valid_to` + `superseded_by`, mọi cột khác bất biến, **và** `dma_write_is_privileged()` = true |
| Reactivate false→true · đổi `teacher_id`/`source`/`type`/`session` tại chỗ · sửa dòng đã đóng | **chặn** |

---

## 11. Transactional probes

17 probe, chạy sau apply, **toàn bộ rollback**, zero residue.

| Probe | Expected | Observed | Cơ chế từ chối thật | Result |
|---|---|---|---|---|
| **T01** valid `responsible` INSERT | allowed | **ALLOWED** | — | **PASS** |
| **T02** `planned` + `runtime_start_session` | reject | `sta_dimension_source_chk` | **CHECK constraint** | **PASS** |
| **T03** `responsible` + `runtime_distribution_lead_snapshot` | reject | `sta_dimension_source_chk` | **CHECK constraint** | **PASS** |
| **T04** supersession có đặc quyền + `SET CONSTRAINTS … IMMEDIATE` | allowed, FK validate | **SUPERSEDE_OK + FK_VALIDATED** | — | **PASS** |
| **T05** UPDATE `teacher_id` tại chỗ | reject | `restrict_violation` | **trigger guard** | **PASS** |
| **T06** UPDATE `assignment_source` | reject | `restrict_violation` | **trigger guard** | **PASS** |
| **T07** reactivate false→true | reject | `restrict_violation` | **trigger guard** | **PASS** |
| **T08** DELETE dòng hiện hành | reject | `restrict_violation` | **trigger guard** | **PASS** |
| **T09** DELETE dòng đã đóng | reject | `restrict_violation` | **trigger guard** | **PASS** |
| **T10** `authenticated` UPDATE trực tiếp | reject | `42501` | **ACL layer** (không có UPDATE grant) — trigger **không** được chạm tới | **PASS** |
| **T11a** `service_role` UPDATE trực tiếp, **không** grant | reject | `42501` | **ACL layer** — đúng như Correction 4 dự đoán, **không phải** trigger | **PASS** |
| **T11b** `service_role` + GRANT UPDATE tạm, `SET` không tham chiếu cột | reject **bởi guard** | **`restrict_violation` FROM GUARD** | **trigger guard** — `dma_write_is_privileged()` = false vì `current_user` ≠ postgres | **PASS** |
| **T11b-note** cùng probe nhưng có `WHERE id = …` | — | `42501_missing_SELECT` | **ACL layer** — mệnh đề `WHERE` cần SELECT, mà `service_role` không có | **ghi nhận** |
| **T12** lineage cross-dimension | reject | `foreign_key_violation` | **FK lineage** | **PASS** |
| **T13** lineage cross-session | reject | `foreign_key_violation` | **FK lineage** | **PASS** |
| **T14** evidence mapping | 9/9 | **9/9** | — | **PASS** |
| **T15** predicate false (session có thật · UUID không tồn tại) | false, false | **false, false** | — | **PASS** |

### 11.1 T11b — giải được nghi vấn còn treo từ S1R

Ở S1R em báo T11b **NOT EXECUTABLE** vì grant UPDATE đơn thuần cho `42501` chứ không tới được trigger. Nguyên nhân đã xác định chính xác ở đây: mệnh đề `WHERE id = …` đòi **SELECT** privilege trên cột, mà `service_role` không có SELECT trên STA.

Cách khắc phục **nằm trong đúng phạm vi uỷ quyền** (chỉ GRANT UPDATE, không mở rộng): dùng `update … set valid_to = now()` **không** `WHERE` và **không** tham chiếu cột trong biểu thức `SET`. Khi đó chỉ cần quyền UPDATE, câu lệnh chạm tới trigger, và guard từ chối bằng `restrict_violation`.

⇒ **Nhánh phòng thủ chiều sâu `dma_write_is_privileged()` nay đã được chứng minh thực nghiệm, không còn là suy luận.** D312-cand (BYPASSRLS không bypass trigger) được xác nhận trực tiếp: `service_role` có `rolbypassrls=true` vẫn bị guard chặn.

Sau rollback: `service_role` trên STA = **0 entry**, relacl fingerprint **`9668f7a072cc0a9a933c62b217dccc3d`** byte-identical.

### 11.2 Zero residue sau probe

```
post sta=9/p9/r0 · canon=59e173e793d15c8cd848f1664f99df32
   · relaclfp=9668f7a072cc0a9a933c62b217dccc3d · svc_on_sta=0
```

---

## 12. Zero-delta evidence

| Chiều | Trước S1 | Sau S1 (đã commit) | Delta |
|---|---|---|---|
| `supabase_migrations.schema_migrations` | 111 | **112** | **+1 (có chủ ý)** |
| tables | 88 | 88 | **±0** |
| functions | 207 | **210** | **+3 (có chủ ý)** |
| SECURITY DEFINER | 198 | **199** | **+1 (có chủ ý)** |
| policies | 166 | 166 | **±0** |
| triggers | 33 | 33 | **±0** |
| STA rows · planned · **responsible** | 9 · 9 · 0 | 9 · 9 · **0** | **±0** |
| **STA-CANON-1** | `59e173e793d15c8cd848f1664f99df32` | `59e173e793d15c8cd848f1664f99df32` | **byte-identical** |
| STA relacl fingerprint | `9668f7a072cc0a9a933c62b217dccc3d` | khớp | **±0** |
| STA policy · index fingerprint | `5700d689…` · `bb8d78ed…` | khớp | **±0** |
| `is_session_lead` md5 | `8b4f91dd…` | `8b4f91dd…` | **±0** |
| `submit_session_journal` · `start_session` · `get_session_detail` md5 | `8fc9ace1…` · `9307a5d9…` · `7f83cfce…` | khớp | **±0** |
| `get_school_week_planned_teachers` md5 | `13d57d0e…` | khớp | **±0** |
| lesson_sessions ACL (WP3 posture) | `rxtm` cho 2 role API | khớp | **±0** |
| `lesson_sessions` / `session_reports` / `learning_moments` / `child_observations` | 9 / 3 / 22 / 9 | 9 / 3 / 22 / 9 | **±0** |
| `audit_logs` | 10 977 | **10 977** | **±0** |
| Function cấp `anon:EXECUTE` | 0/207 | **0/210** | **±0** |
| Repository HEAD | `d8178a55…` | `d8178a55…` | **0 file** |
| Disposable residue | 0 | 0 | **±0** |

**Business row ±0. Audit row ±0. Không một hàng nghiệp vụ nào bị đụng.**

---

## 13. Rollback readiness

Rollback contract **không cần dùng** — apply thành công và mọi verify PASS. Vẫn sẵn sàng nguyên vẹn:

```sql
alter table public.session_teacher_assignments
  drop constraint sta_type_chk,
  add  constraint sta_type_chk check (assignment_type = 'planned'),
  drop constraint sta_source_chk,
  add  constraint sta_source_chk check (assignment_source in (5 giá trị cũ)),
  drop constraint sta_actor_chk,
  add  constraint sta_actor_chk check (case assignment_source
         when 'runtime_distribution_lead_snapshot' then assigned_by is not null
         else assigned_by is null end),
  drop constraint sta_dimension_source_chk,
  drop constraint sta_supersede_fk,
  add  constraint sta_supersede_fk foreign key (superseded_by, session_id, assignment_type)
       references public.session_teacher_assignments (id, session_id, assignment_type);

drop trigger trg_sta_append_only on public.session_teacher_assignments;
create trigger trg_sta_immutable before update or delete on public.session_teacher_assignments
  for each row execute function public.dma_guard_sta_immutable();

drop function public.dma_guard_sta_append_only();
drop function public.is_session_responsible(uuid);
drop function public.dma_assignment_evidence_grade(text);
```

`dma_guard_sta_immutable()` **được giữ nguyên, md5 `ad939ee69823c54b9ccaca19a64d5919` không đổi** ⇒ khôi phục trigger cũ chỉ là một lệnh, không cần tái tạo hàm.

Verify sau rollback: inventory về 88/207/198/166/33 · CHECK fingerprint `9dcdb354…` · FK `condeferrable=false` · STA-CANON-1 · relacl fingerprint.

---

## 14. Process lesson

**D333-cand — ghi nhận, KHÔNG promote.**

> **D333-cand — [assertion · HẰNG SỐ KỲ VỌNG PHẢI ĐƯỢC QUAN SÁT, KHÔNG ĐƯỢC VIẾT TAY]**
> Trong khối verify của migration, mọi literal dùng để so sánh (số đếm inventory, chuỗi ghép, fingerprint, vector ánh xạ) phải được **sinh từ một lần chạy quan sát thật** — trên pre-state, hoặc trên post-state tạm dựng bằng dress rehearsal rollback-only — rồi mới ghim vào code. Viết tay literal từ tài liệu thiết kế là nguồn lỗi trực tiếp và **mỗi lỗi tiêu một lần apply được uỷ quyền**, dù thay đổi cấu trúc hoàn toàn đúng. Hệ quả bắt buộc: **cấm assertion phụ thuộc thứ tự sắp xếp của aggregate** (`string_agg`, `array_agg`, `jsonb_agg`) — phải kiểm từng phần tử độc lập. Mở rộng của bài học WP3 B05 về ACL sang mọi loại fingerprint tổng hợp.

**Bằng chứng D333-cand hoạt động:** hai lần apply đầu tiêu vì hằng số viết tay (đếm nhầm function; giả định sai thứ tự `string_agg`). Lần thứ ba, dress rehearsal **quan sát** 88/210/199/166/33 và **quan sát** 9/9 scalar mapping trước khi ghim ⇒ apply PASS ngay lần đầu, không một assertion nào trượt.

**Hai candidate phụ, cũng chỉ ghi nhận:**

> **D330-cand — `REVOKE FROM PUBLIC` không đủ cho function mới.** `pg_default_acl` schema `public` objtype `f` (2 grantor: `postgres`, `supabase_admin`) cấp `EXECUTE` cho `anon`/`authenticated`/`service_role` dưới dạng grant tường minh. Khối ACL sau `CREATE OR REPLACE` (D15) phải gỡ **đích danh** từng role: `revoke all on function … from public, anon;` — trigger function gỡ cả `authenticated, service_role`. Bất biến nền tảng phải giữ: **0 function `public` cấp EXECUTE cho `anon`**.

> **D331-cand — đường thất bại của `apply_migration` là transactional.** Khi body `RAISE`, không dòng registry nào được ghi (đã quan sát 2 lần). Thứ tự chèn registry trên đường **thành công** vẫn chưa kiểm chứng ⇒ giữ nguyên lệnh cấm assert `count(*)=N` registry trong body.

> **Bổ sung có ích cho quy trình:** `execute_sql` bọc nhiều câu lệnh trong **một** transaction — đã chứng minh bằng probe (§2.1). Đây là cơ sở kỹ thuật cho dress rehearsal, và cần verify lại nếu runtime MCP thay đổi.

---

## 15. Final verdict

| | |
|---|---|
| **WP4-S1R2** | **PASS — FOUNDATION APPLIED** |
| Migration | **112** · `20260722134535` · `v114b_e3_wp4_s1_responsibility_foundation` |
| Digest | `f9e1053f59ce020758368b66b653dc58` (`md5(array_to_string(statements,E'\n'))`) |
| Apply | **1 lần, không retry** |
| Dress rehearsal | **48/48 PASS** trước apply |
| BLOCK 1 · BLOCK 3 | **27/27** · **toàn bộ PASS** (gồm 9 scalar mapping) |
| Layer B | **23/23 × 2 lần** |
| Probes | **17/17** |
| DB | **88 · 210 · 199 · 166 · 33** |
| STA | 9 dòng · planned **9** · **responsible 0** · STA-CANON-1 không đổi |
| Repository HEAD | `d8178a55895b64bbffdf79bb05c06e6b4313d68b` — **0 file** |
| `DMA_RULES.md` / `DMA_SYSTEM_MAP.md` | **KHÔNG ĐỔI** — canonicalize ở E3 milestone closeout |
| Rollback contract | **không dùng**, sẵn sàng |

### Trạng thái giữ nguyên tường minh

- **S2 chưa bắt đầu.** S3–S7 chưa bắt đầu.
- **`responsible` rows = 0.** Không dòng trách nhiệm nào được commit trong S1 — đúng hợp đồng.
- **Authority chưa cutover.** `submit_session_journal` vẫn gác bằng `is_session_lead` (md5 không đổi) — **vẫn hồi tố**. Defect nguyên vẹn trên production.
- **`session_reports` chưa containment.** `authenticated`/`anon` vẫn giữ INSERT/UPDATE/DELETE/TRUNCATE.
- **Frontend không đổi.**
- **`pg_default_acl` function exposure** — nợ nền tảng chưa xử lý, S1 không đụng theo đúng chỉ đạo.
- **E3-SG-01 OPEN · E3-SG-02 CONTAINED (không CLOSED) · R21 ACTIVE** (tới 2026-07-25 18:23 ICT; mutation buổi học hữu cơ đầu tiên vẫn AWAITING).
- **QA debt kế thừa:** không có profile `sub_admin` trên dữ liệu sống.

### Nền tảng nay đã sẵn sàng cho S2

`assignment_type` nhận `planned` **và** `responsible` · source an toàn theo chiều · FK lineage hỗ trợ supersession nguyên tử · `is_session_responsible(uuid)` tồn tại và fail-closed · `dma_assignment_evidence_grade(text)` tồn tại với `owner_attested` tách bạch · STA UPDATE chỉ mở đúng một hình dạng có đặc quyền · DELETE chặn vô điều kiện.

---

WP4-S1R2 PASS — FOUNDATION APPLIED — READY FOR S2 REVIEW
