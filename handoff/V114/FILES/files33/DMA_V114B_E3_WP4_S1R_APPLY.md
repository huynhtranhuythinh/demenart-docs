# DMA V114B-E3 · WP4-S1R — RESPONSIBILITY FOUNDATION APPLY REPORT

> **KẾT QUẢ: APPLY BLOCKED.** Lần apply thứ hai gọi **đúng một lần**, body fail ở **BLOCK 3 · V10e**, transaction **rollback nguyên tử**. **Zero catalog delta, zero business delta, registry vẫn 111.** Không retry. Rollback contract **không dùng và không được phép dùng**.
> **Correction 1 (ACL erratum) đã được chứng minh ĐÚNG trên thực địa** — V09a PASS. Lỗi lần này ở **một chỗ khác**: một hằng số assertion do em viết phụ thuộc thứ tự sắp xếp. **Bản thân hàm mapping hoàn toàn đúng** — chính vector quan sát được là bằng chứng.

---

## 1. Acceptance of first atomic failure

Chấp nhận theo đúng phán quyết của Owner. Trạng thái sau lần thất bại thứ nhất đã được xác minh lại độc lập ngay trước lần apply thứ hai (§2) và khớp 100%: registry 111 · không có dòng S1 · inventory 88/207/198/166/33 · STA 9 (planned 9, responsible 0) · STA-CANON-1 `59e173e793d15c8cd848f1664f99df32` · HEAD `d8178a55…` · rollback contract không được thực thi.

Migration name giữ nguyên `v114b_e3_wp4_s1_responsibility_foundation`, không thêm hậu tố, vì lần thất bại không tạo dòng registry nào.

---

## 2. Second pre-apply continuity pin

| Hạng mục | Kỳ vọng | Quan sát | Kết quả |
|---|---|---|---|
| Repository HEAD | `d8178a55895b64bbffdf79bb05c06e6b4313d68b` | khớp (edit `edt-af7bf0bd`, 2026-07-22T06:07:04Z) | **PASS** |
| Migration count | 111 | 111 | **PASS** |
| Latest migration | `20260722112305` | `20260722112305` | **PASS** |
| Dòng registry tên S1 | 0 | **0** | **PASS** |
| Inventory | 88/207/198/166/33 | 88/207/198/166/33 | **PASS** |
| STA rows · planned · responsible | 9 · 9 · 0 | 9 · 9 · 0 | **PASS** |
| STA-CANON-1 | `59e173e793d15c8cd848f1664f99df32` | khớp | **PASS** |
| CHECK fingerprint | `9dcdb3544a44f99229a54c49c5723e8b` | khớp | **PASS** |
| Index fingerprint | `bb8d78ede51c1f8968babd7fbd3aac83` | khớp | **PASS** |
| Policy fingerprint (STA) | `5700d689c33a7a84e5ef28a7c03c2670` | khớp | **PASS** |
| FK `sta_supersede_fk` | tồn tại, **không** deferrable | `condeferrable=false` | **PASS** |
| Trigger | `trg_sta_immutable/27/dma_guard_sta_immutable()` | khớp | **PASS** |
| 3 function mới | vắng mặt | 0 | **PASS** |
| `is_session_lead` md5 | `8b4f91dda7e45a3c2c801e70579f702d` | khớp | **PASS** |
| lesson_sessions WP3 ACL posture | SELECT/REFERENCES/TRIGGER/MAINTAIN, không I/U/D/T | khớp | **PASS** |
| **STA ACL đầy đủ** | `authenticated` SELECT-only · `anon` vắng · `service_role` **vắng** · PUBLIC vắng | `authenticated:SELECT` + `postgres:{9 quyền}` — không có anon, không có service_role, không có PUBLIC | **PASS** |
| Function public cấp `anon:EXECUTE` | 0/207 | **0** | **PASS** |
| Probe residue `zz_acl_probe_*` | 0 | **0** | **PASS** |

**Zero drift.**

### 2.1 Dry-run BLOCK 1 (chạy lại đầy đủ)

**24/24 PASS.** Kết quả trả về qua RAISE mang dữ liệu:

```
DRYRUN-OK :: BLOCK1 24/24 PASS · inv 88/207/198/166/33 · sta 9 (p9 r0)
           · canon 59e173e793d15c8cd848f1664f99df32 · isl 8b4f91dda7e45a3c2c801e70579f702d
```

Mọi giá trị vẫn được gom vào biến **trước** khi so sánh ⇒ không có biểu thức parse-lười (D323-cand). Không alias (`za…zx`) trùng biến `v_*`.

---

## 3. Corrected ACL dry-run

Ba hàm dùng-một-lần (`zz_acl_probe_a` DEFINER sql · `zz_acl_probe_b` IMMUTABLE sql · `zz_acl_probe_c` INVOKER trigger) tạo trong subtransaction, áp **nguyên văn** khối ACL đã duyệt, đọc bằng `aclexplode(coalesce(proacl, acldefault('f', proowner)))`, rồi rollback.

```
A = [authenticated:EXECUTE:false, postgres:EXECUTE:false, service_role:EXECUTE:false]
B = [authenticated:EXECUTE:false, postgres:EXECUTE:false, service_role:EXECUTE:false]
C = [postgres:EXECUTE:false]
PUBLIC entries = 0/0/0 · anon entries = 0 · grant_option = 0 · residue = 0
```

| Kỳ vọng | Kết quả |
|---|---|
| Hai hàm public → `authenticated, postgres, service_role` | **PASS** |
| Trigger function → `postgres` only | **PASS** |
| `anon` vắng ở cả ba | **PASS** |
| PUBLIC vắng ở cả ba | **PASS** |
| Không grant option bất thường | **PASS** (`is_grantable = false` toàn bộ) |
| Zero probe residue | **PASS** |

### 3.1 Xác nhận trên thực địa trong lần apply thật

Trong migration thật, **V09a PASS** với `acl = authenticated,postgres,service_role` và **V09b PASS** (PUBLIC vắng); V10c/V10d cho `dma_assignment_evidence_grade` cũng **PASS**.

> **Correction 1 được xác nhận đúng bằng chứng cứ trực tiếp, không còn là suy đoán.** Lỗi ACL của lần apply thứ nhất đã được đóng.

---

## 4. Corrected inventory derivation

| Bước | Giá trị |
|---|---|
| Function trước S1 | **207** (bao gồm 12 trigger function — `prokind='f'`) |
| `is_session_responsible(uuid)` | +1 · **SECURITY DEFINER** |
| `dma_assignment_evidence_grade(text)` | +1 · INVOKER |
| `dma_guard_sta_append_only()` | +1 · INVOKER, trigger function |
| **Function sau S1** | **210** |
| SECDEF trước → sau | **198 → 199** |
| Tables · Policies · Triggers | **88 · 166 · 33** (±0; drop 1 trigger + create 1 trigger) |

V24 đã được ghim `88/210/199/166/33` trong BLOCK 3 của lần apply này. **Chưa được đánh giá** — BLOCK 3 dừng ở V10e, nằm trước V24. Vẫn là suy diễn số học chưa kiểm chứng thực nghiệm.

---

## 5. Migration apply

| | |
|---|---|
| Tool call | `apply_migration` — **gọi đúng một lần, không retry** |
| Migration name | `v114b_e3_wp4_s1_responsibility_foundation` |
| **Assigned version** | **KHÔNG CÓ** — registry không nhận dòng nào |
| Digest formula | `md5(array_to_string(statements, E'\n'))` |
| Digest value | **KHÔNG CÓ** |
| Result | **ERROR — atomic rollback** |
| SQLSTATE | **P0001** (`raise_exception`) — assertion tự phát của BLOCK 3 |
| Assertion thất bại | **V10e** |
| Error nguyên văn | `ERROR: P0001: V10e/V11/V12 FAIL: grade vector=<null>,db_proven,owner_attested,db_proven,db_proven,db_proven,db_proven,db_proven,db_proven` · `CONTEXT: PL/pgSQL function inline_code_block line 134 at RAISE` |
| Notices | không trả về — bị nuốt khi transaction abort |
| Retry count | **0** |

**BLOCK 1 PASS toàn bộ. BLOCK 2 thực thi thành công. BLOCK 3 PASS V01→V10d rồi dừng ở V10e.**

### 5.1 Phân tích gốc rễ — hàm ĐÚNG, assertion SAI

Assertion V10e so sánh một chuỗi ghép, tổng hợp bằng:

```sql
select string_agg(zx.g, ',' order by zx.s) ...
```

`order by zx.s` = sắp theo **chuỗi nguồn**, tức **thứ tự bảng chữ cái**. Nhưng chuỗi kỳ vọng em viết tay lại theo **thứ tự phần tử trong mảng `unnest`**. Hai thứ tự khác nhau.

Đối chiếu vector quan sát với thứ tự alphabet thực tế:

| # (alphabet) | Source | Grade quan sát | Đúng? |
|---|---|---|---|
| 1 | `__unknown__` | `<null>` | ✅ |
| 2 | `migration_distribution_lead_snapshot` | `db_proven` | ✅ |
| 3 | `migration_owner_attested` | **`owner_attested`** | ✅ |
| 4 | `migration_responsible_backfill` | `db_proven` | ✅ |
| 5 | `migration_session_teachers_lead` | `db_proven` | ✅ |
| 6 | `responsibility_transfer` | `db_proven` | ✅ |
| 7 | `runtime_distribution_lead_snapshot` | `db_proven` | ✅ |
| 8 | `runtime_start_session` | `db_proven` | ✅ |
| 9 | `system_distribution_lead_snapshot` | `db_proven` | ✅ |

**9/9 ánh xạ đúng tuyệt đối.** `migration_owner_attested` → `owner_attested` (không phải `db_proven`) — yêu cầu nghiêm ngặt nhất của mục D — **đã thoả**. Giá trị lạ → `null` — **đã thoả**.

`dma_assignment_evidence_grade` **không có defect nào**. Chỉ hằng số kỳ vọng của V10e sai thứ tự.

Đây đúng bài học **WP3 B05** (*"ACL target state — normalized, không dựa thứ tự aclitem"*) áp vào một chỗ khác: **em đã dựng assertion trên thứ tự của một aggregate**. Cùng loại lỗi, khác vị trí.

### 5.2 Bản sửa đề nghị — chỉ V10e, độc lập với thứ tự

Thay khối V10e/V11/V12 bằng kiểm từng ánh xạ, không aggregate:

```sql
  if public.dma_assignment_evidence_grade('migration_distribution_lead_snapshot') is distinct from 'db_proven'
     or public.dma_assignment_evidence_grade('migration_session_teachers_lead')   is distinct from 'db_proven'
     or public.dma_assignment_evidence_grade('runtime_distribution_lead_snapshot') is distinct from 'db_proven'
     or public.dma_assignment_evidence_grade('system_distribution_lead_snapshot')  is distinct from 'db_proven'
     or public.dma_assignment_evidence_grade('runtime_start_session')              is distinct from 'db_proven'
     or public.dma_assignment_evidence_grade('migration_responsible_backfill')     is distinct from 'db_proven'
     or public.dma_assignment_evidence_grade('responsibility_transfer')            is distinct from 'db_proven'
  then raise exception 'V10e FAIL: db_proven mapping drift'; end if;
  if public.dma_assignment_evidence_grade('migration_owner_attested') is distinct from 'owner_attested'
    then raise exception 'V11 FAIL: owner_attested mapping drift'; end if;
  if public.dma_assignment_evidence_grade('__unknown__') is not null
    then raise exception 'V12 FAIL: unknown source did not map null'; end if;
```

**Không đụng thân hàm.** Không đụng bất kỳ phần nào khác của migration.

---

## 6. External Layer B

Chạy ngay sau apply thất bại.

| Check | Expected (baseline) | Observed | Result |
|---|---|---|---|
| B01 migration count | 111 | **111** | **PASS** |
| B02 latest migration | `20260722112305` | `20260722112305` | **PASS** |
| B03 dòng registry S1 | 0 | **0** | **PASS** |
| B04 tables | 88 | 88 | **PASS** |
| B05 functions | 207 | **207** | **PASS** |
| B06 SECURITY DEFINER | 198 | **198** | **PASS** |
| B07 policies | 166 | 166 | **PASS** |
| B08 triggers | 33 | 33 | **PASS** |
| B09 ba function mới | 0 | **0** | **PASS** |
| B10 STA CHECK count | 6 | **6** | **PASS** |
| B11 STA CHECK fingerprint | `9dcdb354…` | `9dcdb354…` | **PASS** |
| B12 FK deferrable | false | **false** | **PASS** |
| B13 trigger | `trg_sta_immutable/27/dma_guard_sta_immutable()` | khớp | **PASS** |
| B14 STA rows · planned | 9 · 9 | 9 · 9 | **PASS** |
| B15 **STA-CANON-1** | `59e173e793d15c8cd848f1664f99df32` | khớp | **PASS** |
| B16 `is_session_lead` md5 | `8b4f91dd…` | khớp | **PASS** |
| B17 STA full ACL | `authenticated:SELECT` + `postgres:{9}` | khớp | **PASS** |
| B18 function cấp `anon:EXECUTE` | 0 | **0** | **PASS** |
| B19 business rows LS/SR/LM/CO | 9/3/22/9 | 9/3/22/9 | **PASS** |
| B20 audit_logs | 10 977 | 10 977 | **PASS** |

**20/20 PASS. Pre-state khôi phục byte-identical bởi chính transaction.**

---

## 7. Constraint and FK posture

**KHÔNG ĐỔI — vẫn là pre-state.**

- 6 CHECK nguyên bản, fingerprint `9dcdb3544a44f99229a54c49c5723e8b`
- `sta_type_chk` vẫn `CHECK (assignment_type = 'planned'::text)`
- `sta_source_chk` vẫn 5 giá trị
- `sta_dimension_source_chk` **chưa tồn tại**
- `sta_supersede_fk` vẫn `condeferrable = false`, `condeferred = false`

> **Ghi nhận:** trong lần apply, BLOCK 2 **đã thực thi thành công** và BLOCK 3 **đã verify PASS** các assertion V01a–V01e (4 CHECK mới đúng hình dạng, tổng 7 CHECK), V04/V05 (deferrable + initially deferred), V06 (cột lineage không đổi). Nghĩa là **toàn bộ phần constraint và FK của thiết kế đã được chứng minh chạy đúng trên dữ liệu sống** — chỉ chưa được commit.

---

## 8. Function identities, security posture and normalized ACL

Ba function **không tồn tại** sau rollback. Nhưng trong transaction đã bị huỷ, chúng đã được tạo và **verify PASS**:

| Assertion | Nội dung | Kết quả trong transaction |
|---|---|---|
| V08a | `is_session_responsible` SECURITY DEFINER | **PASS** |
| V08b | `proconfig = search_path=""` | **PASS** |
| V08c | owner `postgres` | **PASS** |
| V08d | `provolatile = 's'` (STABLE) | **PASS** |
| V08e | `lanname = 'sql'` | **PASS** |
| **V09a** | ACL chuẩn hoá `= authenticated,postgres,service_role` | **PASS** ← Correction 1 xác nhận |
| V09b | PUBLIC vắng | **PASS** |
| V10a | `dma_assignment_evidence_grade` `search_path=""` | **PASS** |
| V10b | `provolatile = 'i'` (IMMUTABLE) | **PASS** |
| V10c | ACL `= authenticated,postgres,service_role` | **PASS** |
| V10d | PUBLIC vắng | **PASS** |
| V10e | vector ánh xạ | **FAIL — lỗi hằng số assertion, không phải lỗi hàm** (§5.1) |
| V13a–V13g | guard INVOKER · `search_path=""` · plpgsql · ACL `postgres` only · PUBLIC vắng · 0 function cấp anon · 0 grant option | **chưa đánh giá** (nằm sau V10e) |

Mọi ACL đều đọc bằng `aclexplode(coalesce(proacl, acldefault('f', proowner)))`, **không** dựa thứ tự văn bản aclitem.

---

## 9. Trigger and append-only posture

**KHÔNG ĐỔI.** `trg_sta_immutable` (tgtype 27 = ROW+BEFORE+DELETE+UPDATE) vẫn trỏ `dma_guard_sta_immutable()` — vẫn `raise` vô điều kiện cho cả UPDATE lẫn DELETE, md5 `ad939ee69823c54b9ccaca19a64d5919`, INVOKER.

`dma_guard_sta_append_only()` và `trg_sta_append_only` **chưa tồn tại**. **Chưa có đường supersession nào.**

V14/V15 (trigger mới đúng hình dạng, trigger cũ vắng) **chưa được đánh giá** — nằm sau V10e.

---

## 10. Transactional probes

| Probe | Expected | Observed | Result |
|---|---|---|---|
| V03 (dimension guard: planned + responsible-only source) | reject bởi `sta_dimension_source_chk` | **chưa chạy** | **N/A** |
| V30 (dimension guard: responsible + planned-only source) | reject bởi `sta_dimension_source_chk` | **chưa chạy** | **N/A** |
| V16 (DELETE) | reject | **chưa chạy** | **N/A** |
| V17 (UPDATE `teacher_id` tại chỗ) | reject | **chưa chạy** | **N/A** |
| V17b (UPDATE bộ phận) | reject | **chưa chạy** | **N/A** |
| T01–T10, T12–T15 | — | **chưa chạy** | **N/A** |
| **T11a** | — | **chưa chạy** | **N/A** |
| **T11b** | — | **chưa chạy** | **N/A** |

Toàn bộ probe nội khối nằm **sau** V10e trong BLOCK 3, nên chưa dòng nào được đánh giá. T01–T15 external phụ thuộc object đã bị rollback.

### 10.1 T11a — posture đã xác minh độc lập (read-only, không cần migration)

ACL đầy đủ của `public.session_teacher_assignments`:

```
authenticated:SELECT
postgres:{SELECT,INSERT,UPDATE,DELETE,TRUNCATE,REFERENCES,TRIGGER,MAINTAIN}
```

**`service_role` không có bất kỳ entry ACL nào.** Do đó `SET ROLE service_role` + direct UPDATE sẽ bị từ chối `42501` **do thiếu quyền cấp bảng**, tức **ACL-layer containment**, **không phải** trigger containment. Sẽ báo cáo đúng cơ chế này khi chạy được.

### 10.2 T11b — đánh giá khả thi

T11b (tạm GRANT UPDATE cho `service_role`, `SET LOCAL ROLE`, thử UPDATE hình dạng supersession hợp lệ, kỳ vọng bị `dma_guard_sta_append_only` từ chối vì `dma_write_is_privileged()` = false, rồi rollback cả grant) là **KHẢ THI VỀ MẶT KỸ THUẬT** trong runtime này: `execute_sql` chạy dưới vai `postgres`, và mẫu subtransaction tự huỷ đã được chứng minh hai lần trong phiên này (§3 và parse-validate S1) với **zero residue** và **relacl khôi phục nguyên vẹn**.

**Nhưng T11b chỉ chạy được sau khi `dma_guard_sta_append_only` tồn tại** — tức sau khi S1 commit thành công. Hiện chưa đủ điều kiện.

---

## 11. Zero-delta evidence

| Chiều | Trước apply #2 | Sau apply #2 thất bại | Delta |
|---|---|---|---|
| `supabase_migrations.schema_migrations` | 111 | **111** | **±0** |
| Dòng registry tên S1 | 0 | **0** | **±0** |
| tables/functions/secdef/policies/triggers | 88/207/198/166/33 | **88/207/198/166/33** | **±0** |
| STA rows · planned · responsible | 9 · 9 · 0 | 9 · 9 · 0 | **±0** |
| **STA-CANON-1** | `59e173e793d15c8cd848f1664f99df32` | `59e173e793d15c8cd848f1664f99df32` | **byte-identical** |
| STA CHECK count · fingerprint | 6 · `9dcdb354…` | 6 · `9dcdb354…` | **±0** |
| STA full ACL | `authenticated:SELECT` + `postgres:{9}` | khớp | **±0** |
| FK deferrable | false | false | **±0** |
| Trigger | `trg_sta_immutable/27/…immutable()` | khớp | **±0** |
| `is_session_lead` md5 | `8b4f91dd…` | `8b4f91dd…` | **±0** |
| Function cấp `anon:EXECUTE` | 0 | **0** | **±0** |
| `lesson_sessions`/`session_reports`/`learning_moments`/`child_observations` | 9/3/22/9 | 9/3/22/9 | **±0** |
| `audit_logs` | 10 977 | 10 977 | **±0** |
| Repository HEAD | `d8178a55…` | `d8178a55…` | **0 file** |
| Probe residue | 0 | 0 | **±0** |

**Không một byte nào thay đổi trên production qua cả hai lần apply.**

**D331-cand được củng cố lần thứ hai:** `apply_migration` không ghi dòng registry nào khi body thất bại. Đường thất bại là transactional. Thứ tự chèn trên đường **thành công** vẫn chưa kiểm chứng ⇒ giữ nguyên lệnh cấm assert `count(*)=N` registry trong body.

---

## 12. Rollback readiness

**Rollback contract KHÔNG được sử dụng, và KHÔNG được phép sử dụng.** Điều kiện *"do not run rollback when no catalog change committed"* thoả tuyệt đối, đã chứng minh ở §6 và §11.

Rollback contract vẫn nguyên vẹn cho lần commit thành công tương lai.

---

## 13. Residual risks

**Giữ nguyên tường minh:**

- **`pg_default_acl` function exposure — nợ nền tảng chưa xử lý.** Hai entry (`postgres`, `supabase_admin`) trên schema `public`, objtype `f`, cấp `anon:EXECUTE` cho mọi function mới. S1 **không** đụng `pg_default_acl` theo đúng chỉ đạo. Rủi ro hệ thống: bất kỳ migration tương lai nào chỉ `REVOKE FROM PUBLIC` sẽ mở `anon` im lặng.
- **S2 chưa bắt đầu.** S3–S7 chưa bắt đầu.
- **`responsible` rows vẫn = 0.** `assignment_type` vẫn chỉ nhận `planned`.
- **Authority chưa cutover.** `submit_session_journal` vẫn gác bằng `is_session_lead` — **vẫn hồi tố**. Defect nguyên vẹn trên production.
- **`session_reports` chưa containment.** `authenticated`/`anon` vẫn giữ INSERT/UPDATE/DELETE/TRUNCATE; bảng vẫn không có `updated_at`.
- **Frontend không đổi.** HEAD `d8178a55…`, 0 file.
- **E3-SG-01 OPEN · E3-SG-02 CONTAINED (không CLOSED) · R21 ACTIVE** (cửa sổ tới 2026-07-25 18:23 ICT; mutation buổi học hữu cơ đầu tiên vẫn AWAITING).
- **V24 = 88/210/199/166/33 vẫn là suy diễn chưa kiểm chứng thực nghiệm.**
- **T11b chưa khả thi** cho tới khi guard mới tồn tại.

**Rủi ro quy trình — em phải nói thẳng:** hai lần apply được uỷ quyền đã tiêu, **cả hai đều vì defect trong code verify của em**, không phải trong thiết kế và không phải trong thay đổi cấu trúc. Cả hai lần production không suy suyển. Nhưng tần suất này là tín hiệu rõ: **quy trình dry-run của em chưa phủ được các hằng số kỳ vọng trong BLOCK 3.**

Nguyên nhân chung của cả hai lần: em **viết tay** giá trị kỳ vọng thay vì **suy ra từ quan sát**. Lần 1: đếm nhầm số function. Lần 2: giả định sai thứ tự của `string_agg`.

**Đề xuất siết quy trình cho lần apply kế tiếp** (không đổi ngữ nghĩa migration, chỉ đổi cách em làm việc):

> **Mọi hằng số so sánh trong BLOCK 3 phải được sinh ra từ một lần chạy quan sát thật, không được viết tay.** Với giá trị chỉ tồn tại ở post-state, phải dựng bằng probe dùng-một-lần trong subtransaction tự huỷ (như đã làm đúng cho ACL ở §3) và **đọc ra giá trị thực** trước khi ghim. **Cấm assertion dựa trên thứ tự của bất kỳ aggregate nào** (`string_agg`, `array_agg`, `jsonb_agg`) — phải kiểm từng phần tử độc lập, cùng nguyên tắc đã áp cho ACL từ WP3 B05.

**Candidate rule mới:**

> **D333-cand — [assertion · HẰNG SỐ KỲ VỌNG PHẢI ĐƯỢC QUAN SÁT, KHÔNG ĐƯỢC VIẾT TAY]**
> Trong khối verify của migration, mọi literal dùng để so sánh (số đếm inventory, chuỗi ghép, fingerprint, vector ánh xạ) phải được **sinh từ một lần chạy quan sát thật** trên pre-state hoặc trên probe post-state dùng-một-lần, rồi mới ghim vào code. Viết tay literal từ tài liệu thiết kế là nguồn lỗi trực tiếp và **mỗi lỗi tiêu một lần apply được uỷ quyền**, dù thay đổi cấu trúc hoàn toàn đúng. Hệ quả bắt buộc: **cấm assertion phụ thuộc thứ tự sắp xếp của aggregate** — kiểm từng phần tử độc lập (mở rộng của bài học WP3 B05 về ACL sang mọi loại fingerprint tổng hợp).

---

## 14. Final verdict

| | |
|---|---|
| **WP4-S1R** | **APPLY BLOCKED** |
| Lần apply thứ hai | **đã tiêu** (1/1), không retry |
| Trạng thái transaction | **rollback nguyên tử, 0 catalog change commit** |
| Rollback contract | **không dùng, không được phép dùng** |
| Correction 1 (ACL) | **XÁC NHẬN ĐÚNG** — V09a/V09b/V10c/V10d PASS trên thực địa |
| Correction 2 (inventory) | ghim 88/210/199/166/33, **chưa đánh giá** |
| Correction 3 (dependency 4 fn / 15 policy) | **PASS** ở P23 |
| Correction 4 (T11a/T11b) | T11a posture đã xác minh read-only; T11b khả thi nhưng chưa đủ điều kiện |
| Migration inventory | **111** (không đổi) |
| DB | **88 · 207 · 198 · 166 · 33** (không đổi) |
| STA | 9 · planned 9 · responsible 0 · STA-CANON-1 không đổi |
| Repository HEAD | `d8178a55895b64bbffdf79bb05c06e6b4313d68b` — 0 file |
| `DMA_RULES.md` / `DMA_SYSTEM_MAP.md` | **KHÔNG ĐỔI** |
| E3-SG-01 **OPEN** · E3-SG-02 **CONTAINED** · R21 **ACTIVE** | |
| Cần từ Owner | uỷ quyền **lần apply thứ ba** với sửa V10e §5.2 (một khối assertion, không đụng thân hàm và không đụng bất kỳ phần nào khác) |

---

WP4-S1R APPLY BLOCKED — BLOCK 3 assertion V10e, SQLSTATE P0001: `grade vector=<null>,db_proven,owner_attested,db_proven,db_proven,db_proven,db_proven,db_proven,db_proven`. Nguyên nhân: hằng số kỳ vọng của V10e viết theo thứ tự mảng `unnest` trong khi `string_agg` sắp theo `order by zx.s` (alphabet) — **lỗi assertion, không phải lỗi hàm**; đối chiếu từng phần tử cho thấy `dma_assignment_evidence_grade` ánh xạ **đúng 9/9**, gồm `migration_owner_attested → owner_attested` và giá trị lạ → `null`. Correction 1 (ACL) đã được xác nhận đúng qua V09a PASS. Transaction rollback nguyên tử, registry 111 không đổi, zero delta, rollback contract không dùng.
