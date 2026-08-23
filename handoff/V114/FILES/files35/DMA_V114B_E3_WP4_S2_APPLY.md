# DMA V114B-E3 · WP4-S2 — RESPONSIBLE BACKFILL APPLY REPORT

> **KẾT QUẢ: PASS — RESPONSIBLE BACKFILL APPLIED.**
> Migration **113** · `20260722143704` · `v114b_e3_wp4_s2_responsible_backfill` · digest `1c2906862b9f8c82b48e1563d252ae72`. Dress rehearsal **33/33 PASS** trước apply. Apply gọi **đúng một lần**, thành công, không retry.
> **STA 13 · planned 9 · responsible 4** (db_proven **3** / owner_attested **1**) · audit **+4** · inventory **88/210/199/166/33 không đổi** · mọi hash nghiệp vụ **±0** · frontend **0 file**.
> **Authority CHƯA cutover.** `submit_session_journal` vẫn gác bằng `is_session_lead`, md5 không đổi.

---

## 1. Pre-apply continuity pin

| Hạng mục | Kỳ vọng | Quan sát | Kết quả |
|---|---|---|---|
| Repository HEAD | `d8178a55895b64bbffdf79bb05c06e6b4313d68b` | khớp (`edt-af7bf0bd`) | **PASS** |
| Migration registry · latest | 112 · `20260722134535` | khớp | **PASS** |
| **S1 digest** | `f9e1053f59ce020758368b66b653dc58` | khớp | **PASS** |
| Dòng registry S2 | 0 | 0 | **PASS** |
| Inventory | 88/210/199/166/33 | khớp | **PASS** |
| STA rows · planned · responsible | 9 · 9 · 0 | khớp | **PASS** |
| **STA-CANON-1** | `59e173e793d15c8cd848f1664f99df32` | khớp | **PASS** |
| S1 CHECK fingerprint (7 CHECK) | `4858af9edf690fdd81e1b57b4087cc44` | khớp | **PASS** |
| `sta_supersede_fk` | `DEFERRABLE INITIALLY DEFERRED` | `true/true` | **PASS** |
| Trigger | `trg_sta_append_only/27/dma_guard_sta_append_only()` · `trg_sta_immutable` vắng | khớp | **PASS** |
| `is_session_responsible` md5 · DEFINER · ACL | `488756875716bc43760b780e1c2edf6d` · true · `authenticated,postgres,service_role` | khớp | **PASS** |
| `dma_assignment_evidence_grade` md5 | `d0666e7d7d5c7a022f2641def4a79c9c` | khớp | **PASS** |
| `dma_guard_sta_append_only` md5 · INVOKER · ACL | `353c6ad4dca350460a549a464dfbac9d` · false · `postgres` | khớp | **PASS** |
| `is_session_lead` md5 | `8b4f91dda7e45a3c2c801e70579f702d` | khớp | **PASS** |
| `submit_session_journal` · `start_session` · `get_session_detail` · `get_school_week_planned_teachers` md5 | `8fc9ace1…` · `9307a5d9…` · `7f83cfce…` · `13d57d0e…` | khớp | **PASS** |
| STA relacl fingerprint · policy · index | `9668f7a0…` · `5700d689…` · `bb8d78ed…` | khớp | **PASS** |
| Function cấp `anon:EXECUTE` | 0/210 | **0** | **PASS** |
| **Planned canonical hash** (ghim mới) | — | **`b2045d6b37c538be3c879273cace3c0a`** | ghim |

Hash nghiệp vụ ghim trước apply: `lesson_sessions` **9** `ce73c2da…` · `session_reports` **3** `242e37f9…` · `learning_moments` **22** `c9e1ea5a…` · `child_observations` **9** `7dbb6a22…` · `child_journey` **40** `093f5758…` · `child_skills` **10** `e9e8bf9d…` · `audit_logs` **10 977**.

**Zero drift.**

---

## 2. Exact four-session evidence manifest

UUID buổi DEMO và profile giáo viên **được phân giải từ dữ liệu sống**, không gõ từ prompt.

| # | Session (live UUID) | Trường | State | Teacher (live UUID) | Bằng chứng máy quan sát được |
|---|---|---|---|---|---|
| 1 | `2fab0c56-9f56-4610-9558-216d58573c20` | DEMO-001 | completed | `1810667b-75a0-4b83-a940-cc267b239851` Cô Thúy Ngân Demo | `taught_by` ✅ · `session_teachers.role='lead'` ✅ (1) · planned ✅ (1) · uploaded 0 · approved 0 · recorded 0 · audit 0 |
| 2 | `aaaa0000-0000-4000-8000-0000000a0001` | KHM-DN | taught_report_pending | `d1000000-…-011` Đặng Mỹ Linh | `taught_by` ✅ · uploaded **11** · approved **4** · audit `session_journal_submitted` **3** · planned ✅ |
| 3 | `aaaa0000-0000-4000-8000-0000000a0002` | KHM-DN | taught_report_pending | `d1000000-…-011` Đặng Mỹ Linh | `taught_by` ✅ · uploaded **4** · approved **1** · recorded **4** · audit **1** · planned ✅ |
| 4 | `aaaa0000-0000-4000-8000-0000000a0003` | KHM-DN | **in_progress** | `d1000000-…-011` Đặng Mỹ Linh | **KHÔNG CÓ BẰNG CHỨNG MÁY NÀO** — `taught_by` NULL · report 0 · moment 0 · observation 0 · session_teachers 0 · audit 0 |

**Đúng 3 buổi** thoả `taught_by is not null and state in (taught_report_pending, report_pending_approval, completed)` — không thừa, không thiếu. Cả 3 giáo viên `state='active'` và cùng trường với buổi. **5 buổi** scheduled/cancelled không đủ điều kiện. **0 dòng responsible** tồn tại trước S2.

Buổi #4: teacher `active`, cùng trường KHM (`d1000000-…-0001`). Posture zero-evidence xác nhận nguyên vẹn tại thời điểm apply.

---

## 3. Full dress rehearsal

Chạy toàn bộ body S2 (BLOCK 1 → 4 INSERT + 4 audit → BLOCK 3 → Layer-B-equivalent) trong một transaction rollback-only qua `execute_sql` (cơ chế bọc transaction đã chứng minh ở S1R2 §2.1).

| Check group | Passed | Total | Evidence |
|---|---:|---:|---|
| Row counts | 5 | 5 | sta **13** · planned **9** · responsible **4** · current **4** · closed **0** |
| Source distribution | 1 | 1 | `migration_responsible_backfill`=**3** · `migration_owner_attested`=**1** |
| Manifest & eligibility | 4 | 4 | manifest=**4** · scheduled/cancelled=**0** · school mismatch=**0** · `teacher_id = taught_by` cho **3/3** |
| Owner-attested integrity | 3 | 3 | đúng session+teacher · grade=`owner_attested` · audit db_proven **3** / owner_attested **1** |
| Column invariants | 5 | 5 | `valid_from` = `coalesce(scheduled_at, created_at)` **4/4** · `assigned_by` null **4/4** · `valid_to` null **4/4** · `superseded_by` null **4/4** · duplicate current **0** |
| Business hash | 7 | 7 | planned canon + 6 bảng nghiệp vụ **không đổi** |
| Audit | 2 | 2 | tổng **10 981** (+4) · action `session_responsibility_backfilled` = **4** · metadata owner-attested exact |
| S1 structural + locked md5 | 4 | 4 | inventory · CHECK/FK/trigger/policy/index/relacl · `is_session_lead` · 3 writer function |
| **TỔNG** | **33** | **33** | |

Chuỗi nguyên văn:

```
S2-DRESS-REHEARSAL PASS :: checks=33 | sta=13 p=9 r=4 cur=4 closed=0 | src bf=3/oa=1
 | manifest=4 | taught_match=3 | audit total=10981 new=4 dp=3 oa=1 | inv=88/210/199/166/33
 | oa_meta={"basis":"Owner Gate WP4 D-2","migration":"v114b_e3_wp4_s2_responsible_backfill",
   "teacher_id":"d1000000-0000-4000-8000-000000000011","attested_at":"2026-07-22",
   "attested_by":"owner","evidence_grade":"owner_attested","evidence_sources":[],
   "assignment_source":"migration_owner_attested"}
```

---

## 4. Forced rollback verification

| Hạng mục | Kỳ vọng | Quan sát | Kết quả |
|---|---|---|---|
| Migration registry | 112 | **112** | **PASS** |
| STA rows · planned · responsible | 9 · 9 · **0** | 9 · 9 · **0** | **PASS** |
| **STA-CANON-1** | `59e173e793d15c8cd848f1664f99df32` | khớp | **PASS** |
| `audit_logs` | 10 977 | **10 977** | **PASS** |
| Audit `session_responsibility_backfilled` | 0 | **0** | **PASS** |
| functions · trigger | 210 · `trg_sta_append_only` | khớp | **PASS** |
| Business rows LS/SR/LM/CO/CJ/CS | 9/3/22/9/40/10 | khớp | **PASS** |

**Zero residue.**

---

## 5. Migration apply

| | |
|---|---|
| Tool call | `apply_migration` — **gọi đúng một lần** |
| **Assigned version** | **`20260722143704`** |
| Migration name | `v114b_e3_wp4_s2_responsible_backfill` |
| Digest formula | `md5(array_to_string(statements, E'\n'))` |
| **Digest** | **`1c2906862b9f8c82b48e1563d252ae72`** |
| Result | **`{"success": true}`** |
| Notices | BLOCK 1 và BLOCK 3 đều `RAISE NOTICE`; nội dung không trả qua transport MCP — xác minh độc lập ở §6–§9 |
| Retry count | **0** |
| Migration inventory | **112 → 113** |
| Structure | D92 ba khối · BLOCK 2 đúng **4 INSERT + 4 audit** · **0** thay đổi function/policy/ACL/trigger/CHECK/FK/index |

---

## 6. Post-apply Layer B

Chạy ngay sau apply **và** chạy lại sau toàn bộ probe — hai lần giống hệt.

| Check | Expected | Observed | Result |
|---|---|---|---|
| migration count · latest | 113 · S2 | 113 · `20260722143704` | **PASS** |
| tables/functions/secdef/policies/triggers | 88/210/199/166/33 | khớp | **PASS** |
| STA rows | 13 | **13** | **PASS** |
| planned | 9 | **9** | **PASS** |
| responsible · current | 4 · 4 | **4 · 4** | **PASS** |
| Source split | 3 / 1 | **3 / 1** | **PASS** |
| **Planned canonical hash** | `b2045d6b37c538be3c879273cace3c0a` | khớp | **PASS** |
| S1 CHECK fingerprint | `4858af9edf690fdd81e1b57b4087cc44` | khớp | **PASS** |
| FK posture | `true/true` | khớp | **PASS** |
| Trigger | `trg_sta_append_only/27/dma_guard_sta_append_only()` | khớp | **PASS** |
| STA relacl · policy · index fingerprint | `9668f7a0…` · `5700d689…` · `bb8d78ed…` | khớp | **PASS** |
| `is_session_responsible` · `dma_assignment_evidence_grade` · `dma_guard_sta_append_only` md5 | `48875687…` · `d0666e7d…` · `353c6ad4…` | khớp | **PASS** |
| `is_session_lead` md5 | `8b4f91dd…` | khớp | **PASS** |
| `submit_session_journal` · `start_session` · `get_session_detail` · `get_school_week_planned_teachers` md5 | không đổi | khớp | **PASS** |
| Function cấp `anon:EXECUTE` | 0 | **0** | **PASS** |
| `audit_logs` · action mới | 10 981 · 4 | **10 981 · 4** | **PASS** |
| Business rows LS/SR/LM/CO/CJ/CS | 9/3/22/9/40/10 | khớp | **PASS** |
| `lesson_sessions` canonical hash | `ce73c2da…` | khớp | **PASS** |

**Toàn bộ PASS × 2 lần.**

---

## 7. Responsible assignment manifest

| Session | Teacher | Source | Evidence grade | valid_from (ICT) |
|---|---|---|---|---|
| `2fab0c56…` *(DEMO-001, completed)* | Cô Thúy Ngân Demo | `migration_responsible_backfill` | **db_proven** | 2026-06-23 23:14 |
| `aaaa…0a0003` *(KHM, in_progress)* | Đặng Mỹ Linh | **`migration_owner_attested`** | **owner_attested** | 2026-06-28 16:20 |
| `aaaa…0a0001` *(KHM, taught_report_pending)* | Đặng Mỹ Linh | `migration_responsible_backfill` | **db_proven** | 2026-06-30 09:30 |
| `aaaa…0a0002` *(KHM, taught_report_pending)* | Đặng Mỹ Linh | `migration_responsible_backfill` | **db_proven** | 2026-07-01 09:00 |

Cả 4 dòng: `is_current = true` · `valid_to = null` · `assigned_by = null` · `superseded_by = null` · **đúng một** current responsible mỗi buổi.
**0** dòng responsible trên bất kỳ buổi `scheduled` hay `cancelled` nào.
`teacher_id = lesson_sessions.taught_by` cho **cả 3** dòng db_proven — nguồn giáo viên là `taught_by`, **không** phải `lead_teacher_id`, **không** phải planned, **không** coalesce fallback.

---

## 8. Owner-attested treatment

Dòng `aaaa…0a0003` là dòng **duy nhất** không có bằng chứng máy. Xử lý ở **6 tầng**, không tầng nào gọi nó là `db_proven`:

| Tầng | Nội dung thực tế |
|---|---|
| **Dữ liệu** | `assignment_source = 'migration_owner_attested'` — giá trị **đã có sẵn** từ S1, không phát minh mới |
| **Ánh xạ** | `dma_assignment_evidence_grade('migration_owner_attested')` → **`owner_attested`**. Kiểm chống-nhãn-sai (`V13`) đếm số dòng owner-attested ánh xạ thành `db_proven` = **0** |
| **Audit** | `evidence_grade='owner_attested'` · `evidence_sources=[]` (rỗng, trung thực) · `attested_by='owner'` · `attested_at='2026-07-22'` · `basis='Owner Gate WP4 D-2'` |
| **Cách ly câu lệnh** | INSERT riêng, hardcode **đúng một** session UUID + **đúng một** teacher UUID; `WHERE` khẳng định `state='in_progress'` **và** `taught_by is null` **và** chưa có responsible. Không tổng quát hoá được sang buổi khác |
| **Reader** | Mọi reader gọi `dma_assignment_evidence_grade` sẽ nhận `owner_attested`; không có đường nào trả `db_proven` cho source này |
| **Tài liệu** | Ghi rõ ở đây và sẽ ghi vào closeout: **1/4 dòng responsible là owner-attested**, kèm session id |

**Đối lập trực tiếp:** 3 dòng db_proven có `evidence_sources` **liệt kê nguồn thật, tính từ dữ liệu sống từng dòng**, không phải danh sách chung chép cứng (§9).

---

## 9. Audit evidence

4 dòng, action `session_responsibility_backfilled`, `entity_type='lesson_session'`, `actor_id` **NULL** (migration, không có principal — hợp đồng audit cho phép), `school_id` đúng trường của từng buổi.

| Session | evidence_grade | evidence_sources (tính từ dữ liệu sống) |
|---|---|---|
| `2fab0c56…` | `db_proven` | `lesson_sessions.taught_by` · `session_teacher_assignments.planned` · `session_teachers.role_lead` |
| `aaaa…0a0001` | `db_proven` | `audit_logs.session_journal_submitted` · `learning_moments.approved_by` · `learning_moments.uploaded_by` · `lesson_sessions.taught_by` · `session_teacher_assignments.planned` |
| `aaaa…0a0002` | `db_proven` | `audit_logs.session_journal_submitted` · `child_observations.recorded_by` · `learning_moments.approved_by` · `learning_moments.uploaded_by` · `lesson_sessions.taught_by` · `session_teacher_assignments.planned` |
| `aaaa…0a0003` | **`owner_attested`** | **`[]`** |

Mỗi dòng mang `assignment_id` trỏ chính xác dòng STA tương ứng và `migration = 'v114b_e3_wp4_s2_responsible_backfill'`.

**Audit KHÔNG bọc `exception when others then null`** — nếu ghi audit hỏng thì S2 abort. Đây là khác biệt có chủ ý với `start_session`/`submit_session_journal` (D67/D72): với backfill trách nhiệm, audit **là** sản phẩm.

Delta: **+4 chính xác** · phân bố `db_proven` **3** / `owner_attested` **1** · **0** dòng audit cũ bị sửa hay xoá (tổng 10 977 → 10 981, mọi hash nghiệp vụ khác không đổi).

---

## 10. Transactional probes

Toàn bộ rollback-only, zero residue.

| Probe | Expected | Observed | Cơ chế | Result |
|---|---|---|---|---|
| **Z01** Mỹ Linh · `0a0001` | true | **true** | — | **PASS** |
| **Z02** Mỹ Linh · `0a0002` | true | **true** | — | **PASS** |
| **Z03** Mỹ Linh · `0a0003` (owner-attested) | true | **true** | — | **PASS** |
| **Z04** Cô Thúy Ngân Demo · buổi DEMO | true | **true** | — | **PASS** |
| **Z05** Lê Thảo My (cùng trường, không phụ trách) | false | **false** | predicate | **PASS** |
| **Z06** *(xem §10.1)* | false cho lead mới · true cho người phụ trách | **đúng cả hai** | predicate | **PASS** |
| **Z07** Bùi Ngọc Hân (MNDM, cross-school) | false | **false** | `same_school` | **PASS** |
| **Z08** unauthenticated | false | **false** | `current_profile()` NULL → fail-closed | **PASS** |
| **Z09** session không tồn tại | false | **false** | `coalesce(..., false)` | **PASS** |
| **Z10** dòng responsible current thứ hai | reject | **`unique_violation`** | **`sta_current_uidx`** | **PASS** |
| **Z11** responsible + source chỉ-dành-cho-planned | reject | **`sta_dimension_source_chk`** | CHECK | **PASS** |
| **Z12** owner_attested + `assigned_by` non-null | reject theo `sta_actor_chk` | **`sta_actor_chk`** | CHECK | **PASS** |
| **Z13** DELETE dòng responsible | reject | **`restrict_violation`** | trigger append-only | **PASS** |
| **Z14** đổi `teacher_id` tại chỗ | reject | **`restrict_violation`** | trigger append-only | **PASS** |
| **Z15** planned reader không đổi | `ok:true`, chỉ dữ liệu planned | **`ok=true` · 2 buổi · grades chỉ `owner_attested`** | lọc `assignment_type='planned'` | **PASS** |

Sau probe: STA **13** · responsible **4** · `class_distributions.lead_teacher_id` khôi phục về Mỹ Linh · zero residue.

> **Z15 lưu ý:** `owner_attested` xuất hiện ở đây là của **chiều planned** (5 dòng planned có source `migration_owner_attested` từ S1), **không** phải rò rỉ dòng responsible. `get_school_week_planned_teachers` lọc `assignment_type='planned'` ở cả hai query, planned canonical hash không đổi, và md5 hàm không đổi ⇒ output xác định là y hệt trước S2.

### 10.1 Z06 — bằng chứng đối chứng trực tiếp với defect gốc

**Lần chạy đầu cho kết quả nghi vấn.** Em dùng Vũ Hoàng Nam làm lead tạm; probe trả `false` — đúng kỳ vọng, **nhưng có thể đúng vì lý do sai**. Kiểm lại: **Vũ Hoàng Nam không có auth user** (`nam_has_auth=false`), nên `auth.uid()` NULL và **mọi** predicate đều false bất kể logic. Probe đó **không kết luận được gì**.

Chạy lại với **Lê Thảo My** (có auth user thật), đổi tạm `class_distributions.lead_teacher_id` của distribution Hoa Hồng sang cô, rồi đo trên **cùng một buổi lịch sử** `aaaa…0a0001`:

| Persona | `is_session_lead` (vị từ CŨ, hồi tố) | `is_session_responsible` (vị từ MỚI, session-scoped) |
|---|:--:|:--:|
| **Lê Thảo My** — vừa trở thành lead hiện tại | **TRUE** | **FALSE** |
| **Đặng Mỹ Linh** — người thực sự dạy buổi đó, nay **không còn** là lead | **FALSE** | **TRUE** |

Đây chính xác là **hình ảnh đảo ngược** của defect ghi ở A1/A2 §5.1 — nơi việc đổi lead ngày 21/07 đã chuyển quyền trên buổi lịch sử trong 111 giây. Hai vị từ nay đứng cạnh nhau trên cùng một buổi, cùng một transaction, và cho kết quả **ngược nhau**.

`class_distributions.lead_teacher_id` khôi phục về Mỹ Linh sau rollback — đã verify ngoài transaction.

**Không gọi `submit_session_journal` làm bằng chứng cutover.** Authority chưa cutover ở S2.

---

## 11. Zero-unexplained-delta evidence

| Chiều | Trước S2 | Sau S2 | Delta | Giải thích |
|---|---|---|---|---|
| `supabase_migrations` | 112 | **113** | **+1** | có chủ ý |
| `session_teacher_assignments` | 9 | **13** | **+4** | 4 dòng responsible — có chủ ý |
| — planned | 9 | **9** | **±0** | **planned canonical hash `b2045d6b37c538be3c879273cace3c0a` byte-identical** |
| — responsible | 0 | **4** | **+4** | manifest §7 |
| `audit_logs` | 10 977 | **10 981** | **+4** | 4 dòng `session_responsibility_backfilled` |
| `lesson_sessions` | 9 · `ce73c2da…` | 9 · `ce73c2da…` | **±0** | |
| `session_reports` | 3 · `242e37f9…` | 3 · `242e37f9…` | **±0** | |
| `learning_moments` | 22 · `c9e1ea5a…` | 22 · `c9e1ea5a…` | **±0** | |
| `child_observations` | 9 · `7dbb6a22…` | 9 · `7dbb6a22…` | **±0** | |
| `child_journey` | 40 · `093f5758…` | 40 · `093f5758…` | **±0** | |
| `child_skills` | 10 · `e9e8bf9d…` | 10 · `e9e8bf9d…` | **±0** | |
| tables/functions/secdef/policies/triggers | 88/210/199/166/33 | **88/210/199/166/33** | **±0** | |
| CHECK · FK · trigger · policy · index · relacl fingerprint | S1 values | khớp toàn bộ | **±0** | |
| `is_session_lead` · `submit_session_journal` · `start_session` · `get_session_detail` · `get_school_week_planned_teachers` md5 | pinned | khớp | **±0** | |
| Function cấp `anon:EXECUTE` | 0 | **0** | **±0** | |
| Repository HEAD | `d8178a55…` | `d8178a55…` | **0 file** | |

**Chỉ hai bảng thay đổi: `session_teacher_assignments` (+4) và `audit_logs` (+4). Mọi thứ khác byte-identical.**

---

## 12. Rollback readiness

Không cần dùng — apply thành công, mọi verify PASS. Hợp đồng vẫn nguyên vẹn, đúng thứ tự bắt buộc:

```sql
-- 1. tạm gỡ guard (vai postgres)
alter table public.session_teacher_assignments disable trigger trg_sta_append_only;

-- 2. xoá đúng 4 dòng responsible do S2 tạo
delete from public.session_teacher_assignments
where assignment_type = 'responsible'
  and assignment_source in ('migration_responsible_backfill','migration_owner_attested')
  and session_id in ('aaaa0000-0000-4000-8000-0000000a0001',
                     'aaaa0000-0000-4000-8000-0000000a0002',
                     'aaaa0000-0000-4000-8000-0000000a0003',
                     '2fab0c56-9f56-4610-9558-216d58573c20');

-- 3. xoá đúng 4 dòng audit của S2
delete from public.audit_logs
where action = 'session_responsibility_backfilled'
  and metadata->>'migration' = 'v114b_e3_wp4_s2_responsible_backfill';

-- 4. bật lại guard
alter table public.session_teacher_assignments enable trigger trg_sta_append_only;
```

**Verify sau rollback:** STA **9** · responsible **0** · planned **9** · STA-CANON-1 = `59e173e793d15c8cd848f1664f99df32` · `audit_logs` = **10 977** · trigger enabled và đúng hình dạng · cấu trúc S1 nguyên vẹn (CHECK fp `4858af9e…`, FK `true/true`).

**Không rollback S1** trừ khi chính S1 bị phát hiện lỗi.

> Chi phí có chủ ý của append-only: DELETE bị guard chặn vô điều kiện nên rollback S2 **bắt buộc** phải đi qua bước disable/enable trigger dưới vai `postgres`. Đã ghi trong runbook từ A3/A4.

---

## 13. Residual risks

**Giữ nguyên tường minh:**

- **S3 chưa bắt đầu.** S4, S5, S6, S7 chưa bắt đầu.
- **Authority CHƯA cutover.** `submit_session_journal` vẫn gác bằng `is_session_lead(uuid)` — md5 `8fc9ace1eafb13d28bcf61dc83e8e27d` không đổi. **Defect hồi tố vẫn còn nguyên hiệu lực trên production.** Bốn dòng responsible hiện là *sự thật đã ghi nhận nhưng chưa được dùng làm quyền*.
- **`session_reports` chưa containment.** `authenticated` và `anon` vẫn giữ INSERT/UPDATE/DELETE/TRUNCATE; bảng vẫn không có `updated_at`.
- **Frontend không đổi.** HEAD `d8178a55…`, 0 file. UI vẫn tính `canSubmit` từ `get_teacher_classes.is_lead`.
- **E3-SG-01 OPEN** · **E3-SG-02 CONTAINED (không CLOSED)** · **R21 ACTIVE** (tới 2026-07-25 18:23 ICT; mutation buổi học hữu cơ đầu tiên vẫn AWAITING).
- **`pg_default_acl` function exposure** — nợ nền tảng chưa xử lý; S2 không đụng.

**Nợ QA mới ghi nhận từ S2:**

- **Vũ Hoàng Nam (`d1000000-…-012`) không có auth user** — không impersonate được. Đã phát hiện khi probe Z06 cho kết quả đúng vì lý do sai. Cùng họ với nợ `sub_admin` và Trần Khánh Vy. **Bài học vận hành: một probe trả về giá trị kỳ vọng chưa chứng minh cơ chế đúng — phải xác nhận persona thực sự phân giải được (`current_profile()` không NULL) trước khi tin kết quả.**
- **`sub_admin`** — vẫn không có profile nào trên dữ liệu sống.

**D333-cand** tiếp tục ghi nhận, chưa promote. S2 áp dụng đúng: mọi hằng số kỳ vọng (planned canon, 6 hash nghiệp vụ, audit 10 981) đều **quan sát trước, ghim sau**; không assertion nào phụ thuộc thứ tự aggregate. Apply PASS ngay lần đầu.

---

## 14. Final verdict

| | |
|---|---|
| **WP4-S2** | **PASS — RESPONSIBLE BACKFILL APPLIED** |
| Migration | **113** · `20260722143704` · `v114b_e3_wp4_s2_responsible_backfill` |
| Digest | `1c2906862b9f8c82b48e1563d252ae72` (`md5(array_to_string(statements,E'\n'))`) |
| Apply | **1 lần, không retry** |
| Dress rehearsal | **33/33 PASS** trước apply · rollback zero residue |
| Layer B | **PASS × 2 lần** |
| Probes | **Z01–Z15 PASS** (Z06 chạy lại bằng persona có auth thật) |
| DB | **88 · 210 · 199 · 166 · 33** không đổi |
| STA | **13** · planned **9** · responsible **4** (db_proven 3 / owner_attested 1) |
| Business/audit delta | chỉ `session_teacher_assignments` +4 và `audit_logs` +4 |
| Repository HEAD | `d8178a55895b64bbffdf79bb05c06e6b4313d68b` — **0 file** |
| `DMA_RULES.md` / `DMA_SYSTEM_MAP.md` | **KHÔNG ĐỔI** |
| Rollback contract | **không dùng**, sẵn sàng |

Sự thật trách nhiệm session-scoped nay **đã tồn tại** cho toàn bộ 4 buổi lịch sử cần nó, và Z06 đã chứng minh nó **miễn nhiễm với việc đổi tổ trưởng lớp**. Việc còn lại của S3 là làm cho `submit_session_journal` **dùng** sự thật đó.

---

WP4-S2 PASS — RESPONSIBLE BACKFILL APPLIED — READY FOR S3 REVIEW
