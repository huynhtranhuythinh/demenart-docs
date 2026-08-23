# DMA V114B-E3 · WP4-S1 — RESPONSIBILITY FOUNDATION APPLY REPORT

> **KẾT QUẢ: APPLY BLOCKED.** `apply_migration` gọi **đúng một lần**, body **fail ở BLOCK 3 (V09a)**, transaction **rollback nguyên tử**. **Không có thay đổi catalog nào được commit. Không có dòng registry nào được ghi. Không dùng tới rollback contract.** Không retry.
> Lần apply được uỷ quyền **đã tiêu**. Cần Owner uỷ quyền lần apply thứ hai với khối ACL đã sửa (§11).

---

## 1. Pre-apply continuity pin

| Hạng mục | Kỳ vọng | Quan sát | Kết quả |
|---|---|---|---|
| Repository HEAD (`list_edits limit=1`) | `d8178a55895b64bbffdf79bb05c06e6b4313d68b` | `d8178a55895b64bbffdf79bb05c06e6b4313d68b` (edit `edt-af7bf0bd`, 2026-07-22T06:07:04Z) | **PASS** |
| Migration count | 111 | 111 | **PASS** |
| Latest migration | `20260722112305` `v114b_e3_wp3_a2_lesson_sessions_write_revoke` | khớp | **PASS** |
| Inventory | 88 / 207 / 198 / 166 / 33 | 88 / 207 / 198 / 166 / 33 | **PASS** |
| STA rows | 9 | 9 | **PASS** |
| assignment_type distribution | planned 9 · responsible 0 · other 0 | 9 / 0 / 0 | **PASS** |
| lesson_sessions rows | 9 | 9 | **PASS** |
| `is_session_lead(uuid)` md5(prosrc) | `8b4f91dda7e45a3c2c801e70579f702d` | khớp | **PASS** |
| lesson_sessions ACL (WP3 posture) | SELECT true · I/U/D/T false | `SELECT,REFERENCES,TRIGGER,MAINTAIN` cho cả `authenticated` và `anon` | **PASS** |
| STA ACL | `authenticated` SELECT-only · `anon` không entry · PUBLIC vắng | `authenticated:SELECT` · anon 0 entry · PUBLIC 0 entry · column ACL 0 | **PASS** |
| **STA-CANON-1** | `59e173e793d15c8cd848f1664f99df32` | `59e173e793d15c8cd848f1664f99df32` | **PASS** |

Fingerprint bổ sung đã ghim trước apply (dùng cho assertion và cho verify rollback):

| Fingerprint | Giá trị |
|---|---|
| STA CHECK-constraint fingerprint | `9dcdb3544a44f99229a54c49c5723e8b` |
| STA index fingerprint | `bb8d78ede51c1f8968babd7fbd3aac83` |
| STA policy fingerprint (`sta_select_school`) | `5700d689c33a7a84e5ef28a7c03c2670` |
| `dma_guard_sta_immutable()` md5(prosrc) | `ad939ee69823c54b9ccaca19a64d5919` · INVOKER |
| `trg_sta_immutable` tgtype | `27` (ROW + BEFORE + DELETE + UPDATE) |
| `get_school_week_planned_teachers(date)` md5 | `13d57d0e46308e879fd074710dc5290d` |
| `dma_snapshot_planned_teacher()` md5 | `d170b82aa761fcdf28a30a509ba28e6c` |
| `submit_session_journal(uuid,text,text)` md5 | `8fc9ace1eafb13d28bcf61dc83e8e27d` |
| `start_session(uuid)` md5 | `9307a5d92ed07707963bad2f62d512f8` |
| `get_session_detail(uuid)` md5 | `7f83cfce2c3e71755375efc6070924a2` |
| `is_session_lead` blast radius | **4 function · 15 policy** |

> **Đính chính so với A1/A2 §4:** báo cáo trước ghi *14 policy* tham chiếu `is_session_lead`. Đếm sống là **15** (`child_observations` 2 · `prep_items` 3 · `session_marks` 2 · `session_media` 3 · `session_reports` 2 · `session_teachers` 3 = 15). Lỗi cộng của em ở A1/A2. Giá trị **15** đã được ghim làm assertion P23 và đã PASS.

---

## 2. Mandatory Block 1 dry-run

Chạy nguyên văn body BLOCK 1 read-only trên pre-state sống trước khi gọi `apply_migration`. Mọi giá trị được gom vào biến **trước** khi so sánh, nên **không có biểu thức SQL nào nằm trong nhánh không chạy** — thoả yêu cầu ép parse lười của **D323-cand**. Không alias nào (`za, zb, zc, zg, zi, zk, zl, zm, zn, zp, zq, zs, zt, zx`) trùng bất kỳ biến `v_*` đã `DECLARE`.

| Assertion | Result | Evidence |
|---|---|---|
| P01 repository continuity pin | **PASS** | ngoài SQL — `list_edits` = `d8178a55…`, ghim ở §1 |
| P02a baseline migration tồn tại | **PASS** | `20260722112305` hiện diện |
| P02b không có migration lạ mới hơn | **PASS** | 0 dòng `version > baseline` khác tên S1 — công thức **bất biến với thứ tự** (D-A2-1) |
| P03 inventory 88/207/198/166/33 | **PASS** | khớp tuyệt đối |
| P04 STA rows = 9 · P04b lesson_sessions = 9 | **PASS** | 9 · 9 |
| P05 planned 9 / responsible 0 / other 0 | **PASS** | 9 / 0 / 0 |
| P06 `is_session_lead` md5 | **PASS** | `8b4f91dd…` |
| P07a/b/c STA ACL · PUBLIC · column ACL | **PASS** | `authenticated:SELECT` · 0 · 0 |
| P08 lesson_sessions WP3 posture | **PASS** | chuỗi ACL khớp byte |
| P09 CHECK fingerprint | **PASS** | `9dcdb354…` |
| P10a/b FK tồn tại & **không** deferrable | **PASS** | `condeferrable=false` |
| P11 `sta_current_uidx` def | **PASS** | khớp nguyên văn |
| P12 `sta_lineage_uk` def · P12b index fingerprint | **PASS** | khớp · `bb8d78ed…` |
| P13 `trg_sta_immutable` name/type/fn | **PASS** | `trg_sta_immutable` / 27 / `dma_guard_sta_immutable()` |
| P14 guard cũ md5 + INVOKER | **PASS** | `ad939ee6…` · `prosecdef=false` |
| P15/P16/P17 ba object mới vắng mặt | **PASS** | count = 0 |
| P18 STA-CANON-1 | **PASS** | `59e173e7…` |
| P19 9 dòng hiện tại thoả từ vựng tương lai | **PASS** | 0 dòng vi phạm; 3 cặp sống: `planned/migration_distribution_lead_snapshot`, `planned/migration_owner_attested`, `planned/migration_session_teachers_lead` |
| P21 policy `sta_select_school` fingerprint | **PASS** | `5700d689…` |
| P22 lineage anomaly | **PASS** | 0 (và 0 dòng có `superseded_by`) |
| P23 `is_session_lead` blast radius | **PASS** | fn 4 · policy 15 |
| P24a planned-reader fingerprints | **PASS** | `13d57d0e…` · `d170b82a…` |
| P24b locked non-change fingerprints | **PASS** | `8fc9ace1…` · `9307a5d9…` · `7f83cfce…` |

**Dry-run BLOCK 1: 24/24 PASS.**

### 2.1 Parse-validate BLOCK 3 và mẫu probe

Chạy riêng một DO block read-only trên pre-state để kiểm mẫu subtransaction:

| Kiểm | Kết quả |
|---|---|
| Probe âm (`INSERT` vi phạm → `get stacked diagnostics constraint_name` → rollback subtransaction) | **OK** — pre-state từ chối `assignment_type='responsible'` đúng như mong đợi (chứng minh `sta_type_chk` cũ đang chặn) |
| Probe dương (`INSERT` hợp lệ → `RAISE 'ROLLBACK_MARKER_OK'` → handler nuốt marker) | **OK** |
| Residue sau cả hai probe | **0** — STA rows vẫn 9 |

**Phương pháp parse-validate BLOCK 3:** mọi câu lệnh trong BLOCK 3 tham chiếu object **mới** được đặt ở nhánh **luôn chạy** (gom biến trước, assert sau; 5 probe đều chạy vô điều kiện). Do đó không tồn tại câu lệnh parse-lười nào — nếu có lỗi cú pháp/định danh, nó nổ ngay lần chạy đầu và rollback nguyên tử. Đây chính là điều đã xảy ra (§3).

### 2.2 ⚠️ Sai lệch phát hiện trong dry-run và cách xử lý — BÁO CÁO TRƯỚC KHI APPLY

Uỷ quyền ghi *"Expected: inventory 88/**209**/**200**/166/33"*. Con số này **mâu thuẫn số học với chính bộ object đã được duyệt**:

| Object mới (mục C, D, E của uỷ quyền) | prokind | prosecdef |
|---|---|---|
| `is_session_responsible(uuid)` | `f` | **true** |
| `dma_assignment_evidence_grade(text)` | `f` | false (hợp đồng không yêu cầu DEFINER; hàm thuần ánh xạ, không đọc bảng) |
| `dma_guard_sta_append_only()` | `f` | false (**bắt buộc INVOKER** — D311-cand) |

Trigger function **có** `prokind='f'` và **có** nằm trong con số 207 — đã verify trực tiếp: `dma_guard_sta_immutable()`, `guard_learning_moments_actor()`, `set_updated_at()` đều `prokind='f'`; toàn schema có 12 trigger function trong 207.

⇒ **functions 207 + 3 = 210** (không phải 209) · **secdef 198 + 1 = 199** (không phải 200).

Con số 209/200 bắt nguồn từ bảng §13 của **chính tài liệu A3/A4 do em soạn**, nơi em bỏ sót trigger function khi cộng — lỗi của em, đã lan vào văn bản uỷ quyền. Bộ object được duyệt thì rõ ràng và không đổi.

**Xử lý:** theo điều khoản dry-run (*"correct only a proven implementation defect; preserve the approved semantics"*), em ghim V24 = **88/210/199/166/33**. Nếu ghim 209/200 thì BLOCK 3 sẽ `RAISE` và tiêu lần apply vì một hằng số sai — đúng loại lỗi mà dry-run sinh ra để chặn.

**Ghi chú quan trọng:** V24 **chưa từng được đánh giá** trong lần apply này, vì BLOCK 3 dừng sớm hơn ở V09a. Con số 210/199 vẫn là suy diễn số học **chưa được kiểm chứng thực nghiệm**.

---

## 3. Migration apply

| | |
|---|---|
| Tool call | `apply_migration` — **gọi đúng một lần, không retry** |
| Migration name | `v114b_e3_wp4_s1_responsibility_foundation` |
| **Assigned version** | **KHÔNG CÓ** — registry không nhận dòng nào |
| Digest formula | `md5(array_to_string(statements, E'\n'))` |
| Digest value | **KHÔNG CÓ** — migration không được đăng ký nên không có digest được cấp |
| Result | **ERROR — atomic rollback** |
| Error (nguyên văn) | `ERROR: P0001: V09a FAIL: acl=anon,authenticated,postgres,service_role` · `CONTEXT: PL/pgSQL function inline_code_block line 120 at RAISE` |
| Notices thu được | không có notice nào trả về — BLOCK 1 `RAISE NOTICE` bị nuốt bởi transport khi transaction abort |
| Retries | **0** |

**BLOCK 1 và BLOCK 2 đã chạy thành công** (nếu không, lỗi đã xuất hiện sớm hơn V09a). BLOCK 3 gom biến xong rồi dừng ở assertion V09a. Toàn bộ bị rollback cùng transaction.

---

## 4. Post-apply Layer B

Chạy ngay sau khi apply thất bại, external, read-only.

| Check | Expected (baseline) | Observed | Result |
|---|---|---|---|
| B01 migration count | 111 | **111** | **PASS** |
| B02 latest migration | `20260722112305` | `20260722112305` | **PASS** |
| B03 dòng registry tên `v114b_e3_wp4_s1_responsibility_foundation` | 0 | **0** | **PASS** |
| B04 tables | 88 | 88 | **PASS** |
| B05 functions | 207 | **207** | **PASS** |
| B06 SECURITY DEFINER | 198 | **198** | **PASS** |
| B07 policies | 166 | 166 | **PASS** |
| B08 triggers | 33 | 33 | **PASS** |
| B09 ba object mới hiện diện | 0 | **0** | **PASS** |
| B10 STA CHECK fingerprint | `9dcdb354…` | `9dcdb354…` | **PASS** |
| B11 `sta_supersede_fk` deferrable | false | **false** | **PASS** |
| B12 trigger trên STA | `trg_sta_immutable` | `trg_sta_immutable` | **PASS** |
| B13 STA rows | 9 | 9 | **PASS** |
| B14 **STA-CANON-1** | `59e173e793d15c8cd848f1664f99df32` | `59e173e793d15c8cd848f1664f99df32` | **PASS** |
| B15 `is_session_lead` md5 | `8b4f91dd…` | `8b4f91dd…` | **PASS** |

**15/15 PASS. Pre-state được khôi phục byte-identical bởi chính transaction, không cần can thiệp.**

---

## 5. Constraint posture

**KHÔNG ĐỔI.** Vẫn là 6 CHECK nguyên bản:

```
sta_type_chk    CHECK (assignment_type = 'planned'::text)
sta_source_chk  CHECK (assignment_source = ANY (ARRAY[5 giá trị]))
sta_actor_chk   CHECK (CASE assignment_source WHEN 'runtime_distribution_lead_snapshot' THEN assigned_by IS NOT NULL ELSE assigned_by IS NULL END)
sta_current_chk · sta_validity_chk · sta_no_self_supersede_chk
```

`sta_dimension_source_chk` **chưa tồn tại**. Fingerprint `9dcdb3544a44f99229a54c49c5723e8b` không đổi.

---

## 6. FK posture

**KHÔNG ĐỔI.** `sta_supersede_fk` = `FOREIGN KEY (superseded_by, session_id, assignment_type) REFERENCES session_teacher_assignments(id, session_id, assignment_type)`, `condeferrable = false`, `condeferred = false`.

---

## 7. Function posture and ACL

Ba object mới **không tồn tại**. `functions = 207`, `secdef = 198`.

### 7.1 GỐC RỄ CỦA THẤT BẠI — `pg_default_acl` cấp EXECUTE cho `anon`

Khối ACL trong BLOCK 2 chỉ có `REVOKE ALL … FROM PUBLIC` (theo đúng chữ của uỷ quyền mục C). ACL thực tế của `is_session_responsible` sau khi tạo là:

```
anon, authenticated, postgres, service_role      ← thừa "anon"
```

Nguyên nhân, đã truy đến catalog:

| `pg_default_acl` — schema `public`, objtype `f` (function) | |
|---|---|
| grantor `postgres` | `anon:EXECUTE, authenticated:EXECUTE, postgres:EXECUTE, service_role:EXECUTE` |
| grantor `supabase_admin` | `anon:EXECUTE, authenticated:EXECUTE, postgres:EXECUTE, service_role:EXECUTE` |

⇒ **Mọi function mới trong `public` tự động nhận EXECUTE cho `anon` dưới dạng grant TƯỜNG MINH.** `REVOKE ALL FROM PUBLIC` chỉ gỡ pseudo-role `PUBLIC` (`grantee = 0`), **không** đụng tới entry `anon`. Đây là biểu hiện **cấp function** của **D314-cand** — trước nay chỉ mới đăng ký ở cấp bảng.

### 7.2 Bất biến nền tảng bị vi phạm

Quét toàn bộ 207 function `public` đang sống:

| Chỉ số | Giá trị |
|---|---|
| Function có `anon` EXECUTE | **0 / 207** |
| Function có `proacl` NULL (dùng default ngầm) | **0 / 207** |

Nghĩa là **mọi migration trước đây đều đã quản lý grant tường minh và chưa từng để `anon` chạm function nào**. Khối ACL của S1 nếu đi qua sẽ là **function đầu tiên trong lịch sử hệ thống cấp EXECUTE cho `anon`** — một sai lệch least-privilege thật, không phải assertion khó tính. **V09a đã làm đúng việc của nó.**

### 7.3 Pre-validation của khối ACL đã sửa

Chạy trong subtransaction tự huỷ (tạo hàm giả `zz_acl_probe_*`, revoke/grant, đọc ACL, rollback):

| Object mẫu | ACL sau khối sửa | PUBLIC | Kết quả |
|---|---|---|---|
| DEFINER function (mẫu của `is_session_responsible` / `dma_assignment_evidence_grade`) | `authenticated, postgres, service_role` | 0 entry | **ĐÚNG MỤC TIÊU** — khớp `is_session_lead` sống |
| Trigger function (mẫu của `dma_guard_sta_append_only`) | `postgres` | 0 entry | **ĐÚNG MỤC TIÊU** — khớp `dma_guard_sta_immutable` sống |
| Residue sau probe | **0** | | **PASS** |

---

## 8. Trigger and append-only posture

**KHÔNG ĐỔI.** `trg_sta_immutable` (BEFORE UPDATE OR DELETE, FOR EACH ROW, tgtype 27) vẫn trỏ `dma_guard_sta_immutable()` — hàm này vẫn `raise` **vô điều kiện** cho cả UPDATE lẫn DELETE, md5 `ad939ee69823c54b9ccaca19a64d5919`, INVOKER.

`dma_guard_sta_append_only()` **chưa tồn tại**. `trg_sta_append_only` **chưa tồn tại**.

Hệ quả: **chưa có đường supersession nào** — đúng như trạng thái trước S1.

---

## 9. Transactional probes

| Probe | Expected | Observed | Result |
|---|---|---|---|
| T01–T15 | — | **KHÔNG CHẠY** | **N/A** |

Toàn bộ T01–T15 phụ thuộc object mới (`sta_dimension_source_chk`, FK deferrable, `dma_guard_sta_append_only`, `is_session_responsible`, `dma_assignment_evidence_grade`) — không object nào tồn tại nên probe không có ý nghĩa. Chưa chạy dòng nào.

**Probe đã chạy được (trong BLOCK 3 trước khi abort):** không có. V09a nằm **trước** toàn bộ 5 probe nội khối (V03, V30, V16, V17, V17b) trong thứ tự assertion, nên chúng cũng chưa được đánh giá.

### 9.1 Ghi chú phải sửa cho lần apply sau — T11

Uỷ quyền viết: *"T11 service_role direct UPDATE: must still be rejected by the trigger because current_user is not postgres."*

Kiểm ACL sống: `session_teacher_assignments` ACL đầy đủ = `authenticated:SELECT` + `postgres:{ALL}`. **`service_role` KHÔNG có bất kỳ grant nào trên bảng này.** Do đó T11 sẽ bị từ chối bởi **thiếu quyền (`42501`)**, **không phải** bởi trigger. Em sẽ báo cáo đúng cơ chế thật thay vì gán công cho trigger.

Hệ quả kèm theo: nhánh `dma_write_is_privileged()` trong guard mới hiện là **defence-in-depth không thể chạm tới**, vì không role non-postgres nào giữ UPDATE trên STA. Đó là posture **đúng**, nhưng phải ghi nhận là **chưa chứng minh được bằng thực nghiệm** với dataset hiện tại — cùng họ QA debt với `sub_admin`.

---

## 10. Zero-delta evidence

| Chiều | Trước apply | Sau apply thất bại | Delta |
|---|---|---|---|
| `supabase_migrations.schema_migrations` | 111 dòng | **111 dòng** | **±0** |
| tables / functions / secdef / policies / triggers | 88/207/198/166/33 | **88/207/198/166/33** | **±0** |
| `session_teacher_assignments` rows | 9 | 9 | **±0** |
| **STA-CANON-1** | `59e173e793d15c8cd848f1664f99df32` | `59e173e793d15c8cd848f1664f99df32` | **byte-identical** |
| STA CHECK fingerprint | `9dcdb354…` | `9dcdb354…` | **±0** |
| STA index fingerprint | `bb8d78ed…` | (không đụng) | **±0** |
| STA policy fingerprint | `5700d689…` | (không đụng) | **±0** |
| `is_session_lead` md5 | `8b4f91dd…` | `8b4f91dd…` | **±0** |
| `lesson_sessions` / `session_reports` / `learning_moments` / `child_observations` rows | 9 / 3 / 22 / 9 | không đụng | **±0** |
| `audit_logs` | 10 977 | không đụng | **±0** |
| Repository HEAD | `d8178a55…` | `d8178a55…` | **0 file** |
| Probe residue (`zz_acl_probe_*`) | — | **0** | **±0** |

**Không một byte nào thay đổi trên production.**

### 10.1 Phát hiện phụ có giá trị vận hành

`apply_migration` **không ghi dòng registry nào** khi body thất bại. Điều này **giải quyết một nửa** ẩn số D-A2-1: trên **đường thất bại**, việc chèn registry là **transactional**. Thứ tự chèn trên **đường thành công** vẫn chưa kiểm chứng — quy tắc cấm assert `count(*)=N` trong body **vẫn giữ nguyên**.

---

## 11. Rollback readiness

**Rollback contract KHÔNG được sử dụng, và KHÔNG được phép sử dụng.** Uỷ quyền ghi rõ: *"Do not use rollback if apply transaction failed atomically and no catalog change committed."* Cả hai điều kiện đều thoả và đã chứng minh ở §4 và §10.

Rollback contract vẫn nguyên vẹn, sẵn sàng cho lần apply sau nếu cần.

### 11.1 Bản sửa đề nghị — chỉ khối ACL, không đụng ngữ nghĩa

Chỉ **5 dòng** trong BLOCK 2 thay đổi. BLOCK 1, BLOCK 2 (constraint / FK / 3 function body / trigger), BLOCK 3 **giữ nguyên byte**.

```sql
-- ---- ACL block (D15: tách riêng sau CREATE OR REPLACE) ----
revoke all on function public.is_session_responsible(uuid)        from public, anon;
revoke all on function public.dma_assignment_evidence_grade(text) from public, anon;
revoke all on function public.dma_guard_sta_append_only()         from public, anon, authenticated, service_role;
grant execute on function public.is_session_responsible(uuid)        to authenticated, service_role;
grant execute on function public.dma_assignment_evidence_grade(text) to authenticated, service_role;
```

Đã pre-validate thực nghiệm (§7.3): cho ra đúng `authenticated, postgres, service_role` cho hai hàm public và `postgres` cho trigger function, PUBLIC vắng ở cả ba, residue 0.

**Việc này cần Owner uỷ quyền lần apply thứ hai.** Em không tự retry.

---

## 12. Residual risks and deferred work

**Giữ nguyên tường minh:**

- **S2 chưa bắt đầu.** S3, S4, S5, S6, S7 chưa bắt đầu.
- **Không có dòng `responsible` nào được tạo.** `assignment_type` vẫn chỉ nhận `planned`.
- **Authority chưa cutover.** `submit_session_journal` vẫn gác bằng `is_session_lead(uuid)` — **vẫn hồi tố**. Defect §5 của A1/A2 còn nguyên hiệu lực trên production.
- **`session_reports` chưa containment.** `authenticated` và `anon` vẫn giữ INSERT/UPDATE/DELETE/TRUNCATE; bảng vẫn không có `updated_at`.
- **Frontend không đổi.** HEAD `d8178a55…`, 0 file bị đụng.
- **R21 (WP3) vẫn ACTIVE OBSERVATION** — cửa sổ tới 2026-07-25 18:23 ICT, mutation buổi học hữu cơ đầu tiên vẫn AWAITING.
- **E3-SG-01 vẫn OPEN.** Điều kiện 4 chưa đóng.
- **E3-SG-02 vẫn CONTAINED (không CLOSED).**

**Nợ mới phát sinh từ S1:**

- **`pg_default_acl` cấp function** — mọi function mới trong `public` nhận `anon:EXECUTE` tường minh. Hiện 0/207 function bị ảnh hưởng vì các migration trước đều revoke tường minh, nhưng **rủi ro là hệ thống, không phải cá biệt**: bất kỳ migration tương lai nào chỉ `REVOKE FROM PUBLIC` sẽ mở `anon` một cách im lặng. Đề xuất đăng ký cùng cụm D314-cand và cân nhắc `ALTER DEFAULT PRIVILEGES … REVOKE EXECUTE ON FUNCTIONS FROM anon` ở một work package bảo mật nền tảng riêng.
- **T11 không kiểm chứng được như mô tả** (§9.1) — `service_role` không có grant trên STA nên nhánh privileged-guard là defence-in-depth chưa chạm tới được.
- **V24 = 210/199 vẫn là suy diễn chưa kiểm chứng** — sẽ được xác nhận thực nghiệm ở lần apply sau.

**Candidate rules mới:**

> **D330-cand — [ACL · `REVOKE FROM PUBLIC` KHÔNG ĐỦ CHO FUNCTION MỚI]**
> `pg_default_acl` của schema `public` (objtype `f`, hai grantor `postgres` và `supabase_admin`) cấp `EXECUTE` cho `anon`, `authenticated`, `service_role` dưới dạng grant **tường minh** trên mọi function mới. `REVOKE ALL … FROM PUBLIC` chỉ gỡ `grantee = 0` và **không** chạm các entry đó. Khối ACL sau `CREATE OR REPLACE` (D15) phải liệt kê **đích danh** mọi role cần gỡ: `revoke all on function … from public, anon;` — và với trigger function thì gỡ cả `authenticated, service_role`. Verify bắt buộc bằng `aclexplode`, so với bất biến nền tảng **0/207 function public cấp EXECUTE cho `anon`**.

> **D331-cand — [migration · ĐƯỜNG THẤT BẠI CỦA `apply_migration` LÀ TRANSACTIONAL]**
> Khi body migration `RAISE`, `apply_migration` **không** để lại dòng nào trong `supabase_migrations.schema_migrations`: count giữ nguyên, không có version được cấp, không có digest. Giải được **một nửa** ẩn số D-A2-1. Thứ tự chèn registry trên **đường thành công** vẫn chưa kiểm chứng ⇒ **giữ nguyên** lệnh cấm assert `count(*) = N` của registry bên trong body; mọi kiểm đếm registry vẫn phải là Layer B external.

> **D332-cand — [assertion · POSTCONDITION SAI HẰNG SỐ TIÊU MỘT LẦN APPLY]**
> Con số inventory kỳ vọng phải được **suy ra từ danh sách object đã duyệt tại thời điểm viết BLOCK 3**, không chép lại từ bảng tóm tắt của tài liệu thiết kế. Trigger function có `prokind='f'` và **được đếm** trong tổng số function — chỗ dễ sót nhất. Sai một hằng số verify sẽ làm migration tự abort và tiêu mất một lần apply đã được uỷ quyền, dù mọi thay đổi cấu trúc đều đúng.

---

## 13. Final verdict

| | |
|---|---|
| **WP4-S1** | **APPLY BLOCKED** |
| Lần apply được uỷ quyền | **đã tiêu** (1/1), không retry |
| Trạng thái transaction | **rollback nguyên tử, 0 catalog change commit** |
| Rollback contract | **không dùng, không được phép dùng** |
| Migration inventory | **111** (không đổi) |
| DB | **88 · 207 · 198 · 166 · 33** (không đổi) |
| STA | 9 dòng · planned 9 · responsible 0 · STA-CANON-1 không đổi |
| Repository HEAD | `d8178a55895b64bbffdf79bb05c06e6b4313d68b` — 0 file đụng |
| `DMA_RULES.md` / `DMA_SYSTEM_MAP.md` | **KHÔNG ĐỔI** |
| E3-SG-01 | **OPEN** · E3-SG-02 **CONTAINED** · R21 **ACTIVE** |
| Cần từ Owner | uỷ quyền **lần apply thứ hai** với khối ACL §11.1 (5 dòng), mọi phần khác giữ nguyên byte |

---

WP4-S1 APPLY BLOCKED — BLOCK 3 assertion V09a: `is_session_responsible(uuid)` EXECUTE ACL = `anon,authenticated,postgres,service_role` (kỳ vọng `authenticated,postgres,service_role`). Nguyên nhân gốc: `pg_default_acl` schema `public` objtype `f` cấp `anon:EXECUTE` tường minh cho mọi function mới, và `REVOKE ALL … FROM PUBLIC` không gỡ được entry đó. Transaction rollback nguyên tử, registry 111 không đổi, zero delta, rollback contract không dùng.
