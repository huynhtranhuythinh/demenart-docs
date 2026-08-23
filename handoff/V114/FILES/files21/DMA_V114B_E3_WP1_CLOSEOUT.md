# DMA — V114B-E3 · WP1 CLOSEOUT

> **WP1 — FORMALLY PASS / CLOSED** · 2026-07-21
> `DMA_RULES.md` và `DMA_SYSTEM_MAP.md` **KHÔNG canonicalize** ở mốc này — chờ E3 milestone closeout.
> **E3-SG-01 KHÔNG đóng.**

---

## 1. PHẠM VI ĐÃ ĐÓNG

WP1 xử lý cụm defect attribution/approval integrity phát hiện ở Phase 1 sweep:

| Defect | Nội dung | Trạng thái |
|---|---|---|
| **E3-08** | `learning_moments.uploaded_by` client-supplied, forgeable, mutable | **CLOSED** |
| **E3-09** | Direct `UPDATE state='approved'` vượt mặt `submit_session_journal` | **CLOSED** |
| **E3-12** | `profiles.state` tự sửa được bởi non-authority | **CLOSED** |
| **E3-07** | `child_observations` không có cột actor | **CLOSED** (cột + guard; authorization semantics thuộc WP4) |

## 2. HAI MIGRATION

| | 105 | 106 |
|---|---|---|
| version | `20260721094857` | `20260721104516` |
| name | `v114b_e3_wp1_security_containment` | `v114b_e3_wp1_grant_hardening` |
| `md5(statements)` | `30f29f7f94c300a0ad234ec8ec5cadf1` | `b4446fd46ab3b3f96a25e41f110ad979` |
| vai trò | containment (đóng lỗ hổng ngay, backward compatible) | least privilege (thu compat grant sau frontend cutover) |

**Migration inventory cuối: 106.**

### Objects (105)

- `dma_write_is_privileged()` — **SECURITY INVOKER**, trả `current_user = 'postgres'`
- `guard_learning_moments_actor()` + `trg_guard_learning_moments_actor` — **SECURITY INVOKER**
- `guard_child_observations_actor()` + `trg_guard_child_observations_actor` — **SECURITY INVOKER**
- `guard_profiles_protected_cols()` — SECURITY DEFINER (replaced), nay ghim cả `state`
- `child_observations.recorded_by` · `.updated_by` — nullable, FK `ON DELETE RESTRICT`, legacy NULL
- 4 policy tái tạo `TO authenticated` (gỡ `anon` khỏi write path)

### Grant cuối cùng

| Bảng · cmd · role `authenticated` | Cột |
|---|---|
| `learning_moments` INSERT | `class_id, lesson_version_id, program_id, session_id` |
| `learning_moments` UPDATE | `album_id, caption, feedback_note, theme_tag, updated_at` |
| `child_observations` INSERT/UPDATE | `attendance, child_id, follow_up_needed, is_highlight, linked_moment_ids, needs_support, note, session_id, skills_observed, visibility` |
| `anon` | **không có quyền ghi nào** |

Table-level INSERT/UPDATE/DELETE đã revoke khỏi `authenticated` và `anon`. `uploaded_by` · `approved_by` · `state` · `id` · `created_at` **không client nào ghi được**.

## 3. FRONTEND CUTOVER

`src/routes/_authenticated/teacher.session.$id.tsx` · commit **`85e24768394be812f08a05c4f2694a8d1176427b`**

- Gỡ `uploaded_by: profile?.id ?? null,` khỏi INSERT payload `learning_moments`
- Gỡ `const { profile } = useCurrentProfile();` khỏi `PhotoTab` (biến vô dụng sau đổi 1)
- `import { useCurrentProfile }` giữ nguyên — `SessionFlow` vẫn dùng
- Commit có thêm ~12 chỗ Prettier reformat ngoài phạm vi; đã đọc từng chỗ, **không đổi hành vi**

## 4. BẰNG CHỨNG

### 4.1 In-transaction (migration 105)

| Probe | Kết quả |
|---|---|
| Definer-context: `dma_write_is_privileged()` trong SECURITY DEFINER owner `postgres` | **TRUE** |
| Cùng hàm, `authenticated` gọi trực tiếp | **FALSE** |
| INSERT có cột `id` (ngoài whitelist) | **permission denied** — whitelist hoạt động |
| INSERT với `uploaded_by` = profile khác | **override** thành actor thật |
| `approved_by` sau INSERT | **NULL** |
| `state` sau INSERT | **`draft`** |
| UPDATE `uploaded_by`/`approved_by`/`state` | **ghim về `old`** |
| UPDATE `caption` | **lưu được** — không chặn oan |

### 4.2 Production real-login

| Mốc | Moment | Bằng chứng |
|---|---|---|
| Sau 105, frontend **cũ** còn gửi `uploaded_by` | `5ce35382-…` · `093cc871-…` | actor đúng Mỹ Linh; `093cc871` được duyệt qua `submit_session_journal` với `approved_by` = Mỹ Linh |
| Sau 106 (Stage B), client **không gửi** actor | `79fe0562-99f9-4d95-ae52-94ccec422307` | `uploaded_by` = Mỹ Linh (database-derived) · `approved_by` NULL · `draft` · same-school |
| Sau 106 (Stage C), `uploaded_by` **không còn grant** | `e28ba054-9e05-4444-aa2e-affc82069bdd` | tạo thành công · actor đúng · `approved_by` NULL · `draft` · same-school · caption *"Chú thích 3"* lưu được |
| Observation | 4 dòng session `aaaa…0a0002` | `recorded_by = updated_by =` Mỹ Linh |

### 4.3 Không rewrite dữ liệu cũ

| | Trước 105 | Sau 106 |
|---|---|---|
| `learning_moments` | 18 | 22 (chênh lệch = QA thật) |
| `approved` + `approved_by` NULL | 6 | **6** |
| `child_observations` | 5 | 9 |
| `recorded_by` NULL (legacy) | — | **5** |
| `uploaded_by` NULL (toàn bảng) | — | **0** |
| cross-school attribution | 0 | **0** |
| probe residue | — | **0** |

**ANOMALY-1 `f51039be-48e8-42c5-9900-b03f3472cd1f`** — `approved` · `approved_by` NULL · `updated_at` `2026-07-09 07:31:01.160368+00` — **không đổi một byte** qua cả hai migration. Không backfill.

### 4.4 Parent surface

`learning_moments_select_school_or_parent` byte-identical:
`(same_school(class_school_id(class_id)) OR (is_moment_parent(id) AND (state = 'approved'::moment_state)))`

Không đụng `media_consent_check` · `get_signed_media_url` v23 · consent data · Parent RPC · media signing.

## 5. E3-SG-01 — TRẠNG THÁI

> **PARTIALLY CONTAINED; AUTHORITY SEMANTICS PENDING WP4**

| Điều kiện đóng | WP1 |
|---|---|
| 1 · không giả mạo `uploaded_by` | ✅ |
| 2 · không sửa `uploaded_by` sau creation | ✅ |
| 3 · không tự approve từ client | ✅ |
| 4 · **không approve khi không có đúng session responsibility** | ⛔ **PENDING WP4** |
| 5 · không cross-school | ✅ |
| 6 · Parent không thấy unapproved metadata | ✅ |
| 7 · service-role path không bypass | ✅ |
| 8 · media/consent behavior vẫn PASS | ✅ (compensating — xem §7) |

Điều kiện 4 vẫn phụ thuộc `is_session_lead` (hồi tố). **Không được ghi `E3-SG-01 CLOSED` trước WP4.**

## 6. QA MATRIX

S1–S8 **PASS** · **S9 — NOT EXECUTABLE WITH CURRENT DATASET; COMPENSATING EVIDENCE PASS** · S10 **PASS** · Stage B production **PASS** · Stage C production **PASS**.

## 7. QA DEBT ĐANG MỞ

**CONSENT-NEGATIVE-FIXTURE** — duy trì một fixture QA chuyên biệt có approved single-child moment, trong đó child thiếu `display_in_app`, để kiểm thử UI `consent_missing` mà không sửa dữ liệu vận hành hoặc enrollment thật.

Cơ sở: quét 31 cặp parent × moment cho action `view` → `consent_missing` = **0** (allowed 28 · `moment_not_approved` 3). Parent Portal chỉ gọi `media_consent_check(..., 'view')` — `get_signed_media_url` v23 hardcode action này — nên các verdict `consent_missing` ở `download`/`share` không tới được từ UI. Ba bé thiếu `display_in_app` (Bé Jimmy Demo · Bùi Yến Nhi · Trịnh Khánh Vi) đều không có moment single-child nào. WP1 không đụng consent path nên debt này không chặn closeout.

## 8. CANDIDATE RULES FOR E3 MILESTONE CLOSEOUT

Chưa gán D-number canonical.

| Mã tạm | Nội dung |
|---|---|
| **D310-cand** | Column-level `REVOKE` **không** phủ định table-level grant còn tồn tại. Muốn thu quyền ghi phải `REVOKE ... ON TABLE` trước rồi `GRANT (cols)`. Verify bằng `has_table_privilege` **và** `has_column_privilege` — không chỉ `information_schema.column_privileges`, vì view đó biểu diễn table grant thành quyền trên mọi cột. |
| **D311-cand** | Privileged-write detection dùng `current_user = 'postgres'`. `dma_write_is_privileged` và hai guard trigger function **phải** `SECURITY INVOKER`; đổi sang DEFINER làm containment sập im lặng. Migration phải có guard `prosecdef = false`. Mọi DEFINER function owner `postgres` ghi `learning_moments`/`child_observations` đi qua privileged path và **tự chịu trách nhiệm invariant**. |
| **D312-cand** | `service_role` có `BYPASSRLS = true` ⇒ RLS một mình không đủ bảo vệ attribution. Containment phải ở tầng trigger; RLS là lớp phụ. |

## 9. TRẠNG THÁI CUỐI

| | |
|---|---|
| **WP1** | **FORMALLY PASS / CLOSED** |
| Stage A · B · C | PASS · PASS · PASS |
| **E3-SG-01** | **PARTIALLY CONTAINED; AUTHORITY SEMANTICS PENDING WP4** |
| HEAD | `85e24768` |
| Migration inventory | **106** |
| `DMA_RULES.md` | **KHÔNG ĐỔI** |
| `DMA_SYSTEM_MAP.md` | **KHÔNG ĐỔI** |
| WP2 | **chưa mở** |
| ANOMALY-1 | giữ nguyên, không sửa |
| Parent attribution (E3-11) | vẫn deferred — backlog "Parent Artifact Attribution Experience" |

**WP tiếp theo:** WP2 — assignment foundation. Chưa mở, chờ Owner.

---

*V114B-E3 · WP1 closeout · không canonicalize RULES/SYSTEM_MAP · E3-SG-01 không đóng.*
