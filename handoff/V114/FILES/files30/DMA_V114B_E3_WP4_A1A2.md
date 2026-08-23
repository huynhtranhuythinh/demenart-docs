# DMA V114B-E3 · WP4-A1/A2 — AUTHORITY AUDIT & TRUTH MODEL

> Read-only. Không migration, không DDL, không ghi dữ liệu. 0 file frontend bị đụng.
> Baseline xác minh sống lúc **2026-07-22 18:55 ICT**: **88** bảng · **207** hàm · **198** SECDEF · **166** policy · **33** trigger · migration **111** (`20260722112305`) · HEAD `d8178a55895b64bbffdf79bb05c06e6b4313d68b`. Khớp 100% trạng thái đóng WP3.

---

## 1. Executive verdict

### **READY WITH OWNER DECISIONS**

Mô hình sự thật đủ dữ kiện để chốt. Nhưng **không được vào A3/A4 trước khi Owner quyết 5 việc ở §12**, và **một stop-gate đã chạm** (SG-8: có session lịch sử không backfill xác định được).

Ba phát hiện làm đổi hình dạng WP4 so với đề bài:

| # | Phát hiện | Hệ quả |
|---|---|---|
| **F1** | `session_reports` còn **INSERT/UPDATE/DELETE/TRUNCATE cấp bảng** cho `authenticated` **và** `anon`; RLS chỉ gác bằng `is_session_lead(...)` — tức **hồi tố**. | Sửa mỗi `submit_session_journal` **KHÔNG** đóng được điều kiện 4 của E3-SG-01. Còn một đường ghi nhật ký thứ hai, không đi qua RPC nào. **Đây là stop-gate #2, đã chạm.** |
| **F2** | `is_session_lead` gác **4 function + 14 policy**. Đổi ngữ nghĩa hàm này = đổi quyền ghi điểm danh, ghi nhận, ảnh, prep, marks của toàn hệ. | Bắt buộc chọn **Phương án A** (predicate mới `is_session_responsible`), không được sửa `is_session_lead`. |
| **F3** | `start_session` ghi audit sai hình dạng payload → **cả 3 dòng `session_started` đều có `actor_id` NULL, `entity_id` NULL, `metadata` NULL**. | Audit log **không dùng được** làm nguồn bằng chứng participation cho backfill. Nguồn runtime duy nhất còn lại là `lesson_sessions.taught_by`. |

---

## 2. One-day user view

**Hiệu trưởng / Phó hiệu trưởng — “Hôm nay trường mình có ổn không?”**

Cô Nguyệt Thi mở `/school`. Câu hỏi thật của cô không phải “ai là tổ trưởng lớp Hoa Hồng” mà là **“buổi sáng nay ai chịu trách nhiệm, và nhật ký đã tới ba mẹ chưa?”**. Hôm nay hệ thống trả lời được vế đầu **chỉ ở thì hiện tại**: màn Lịch triển khai hiện “Giáo viên dự kiến” (Surface A/B, đã có từ WP2) — dự kiến, chưa phải chịu trách nhiệm. Khi cô đổi tổ trưởng lớp — một thao tác hành chính bình thường, đã xảy ra thật 2 lần trên distribution Hoa Hồng ngày 21/07 — thì **toàn bộ lịch sử buổi học của lớp đó đổi chủ theo**. Buổi cô Mỹ Linh dạy ngày 30/06 đột nhiên thuộc quyền người khác. Cô hiệu trưởng không hề biết điều đó vừa xảy ra: không có màn hình nào nói.

Sau WP4, cùng thao tác đó chỉ đổi **người dự kiến của các buổi sắp tới**. Buổi 30/06 vẫn ghi tên cô Mỹ Linh, vĩnh viễn. Nếu cô hiệu trưởng thật sự cần chuyển trách nhiệm một buổi đã qua (GV nghỉ việc, GV dạy thay), phải là một hành động **có tên, có lý do, có người ký** — không phải hệ quả phụ của việc đổi tổ trưởng.

**Giáo viên — “Hôm nay tôi cần làm gì?”**

Cô Mỹ Linh mở `/teacher`. Cô thấy buổi của mình, vào dạy, điểm danh, chụp ảnh, gửi nhật ký. Nút “Hoàn tất & gửi nhật ký” hôm nay bật/tắt theo việc **cô có đang là tổ trưởng lớp hay không**, nhưng dòng chữ dưới nút lại viết *“Chỉ giáo viên phụ trách buổi mới gửi được nhật ký.”* — **giao diện đang hứa một điều backend chưa làm được**. Nếu sáng nay cô bị đổi khỏi vai tổ trưởng, buổi cô vừa dạy xong tối qua sẽ hiện nút xám và cô không gửi được nhật ký của chính buổi mình dạy; ghi nhận của cô nằm đó chờ người khác gửi hộ.

Sau WP4, câu trả lời là: **buổi nào cô chịu trách nhiệm thì cô gửi được nhật ký buổi đó, hôm nay và mãi sau** — kể cả khi lớp đã đổi tổ trưởng, kể cả khi cô đã chuyển lớp. Và ngược lại: một cô mới về, chưa từng bước vào buổi học đó, sẽ không bao giờ tự nhiên có quyền duyệt ảnh của các bé trong buổi ấy.

---

## 3. Current live authority chain

```
Client (teacher.session.$id.tsx · StepReview)
  └─ get_teacher_classes()  →  is_lead (theo LỚP, không theo buổi)
       └─ leadOfThis = rows.some(c => c.is_lead && c.sessions.includes(sessionId))
            └─ bật/tắt nút "Hoàn tất & gửi nhật ký"        ← suy luận ở CLIENT
  └─ supabase.rpc('submit_session_journal')
       └─ is_session_lead(p_session_id)                     ← CỔNG DUY NHẤT
            └─ lesson_sessions.class_distribution_id
                 └─ class_distributions.lead_teacher_id     ← MỘT TRƯỜNG DUY NHẤT, KHẢ BIẾN
                      └─ = current_profile()
```

Toàn bộ authority nhật ký treo trên **một trường `uuid` khả biến của bảng `class_distributions`**, và trường đó **không mang chiều thời gian**. Không có bất kỳ dữ kiện nào của chính buổi học tham gia vào quyết định.

Đường ghi song song (**không đi qua RPC nào**):

```
Client → PostgREST → public.session_reports  (INSERT / UPDATE / DELETE / TRUNCATE cấp bảng)
     └─ RLS: is_session_lead(session_id) OR (is_school_admin() AND same_school(...))
```

Bốn quan sát về chuỗi này:

1. `submit_session_journal` **không có nhánh school-admin**; RLS của `session_reports` **có**. Hiệu trưởng **không** gửi được nhật ký qua RPC nhưng **ghi đè được** bản ghi nhật ký trực tiếp. Bất đối xứng này chưa từng được thiết kế có chủ ý.
2. **Không tồn tại RPC approve/reject nhật ký nào.** Chỉ có duy nhất `submit_session_journal` ghi vào `session_reports`. Trạng thái `'final'` (đang có trên buổi DEMO `2fab0c56`) **không có writer có kiểm soát** — nó chỉ có thể đến từ seed hoặc ghi trực tiếp.
3. Duyệt ảnh (`learning_moments.state='approved'`, `approved_by`) nằm **bên trong** `submit_session_journal`, nên nó thừa hưởng nguyên vẹn tính hồi tố của `is_session_lead`.
4. Nhánh idempotent (`state in taught_report_pending / report_pending_approval / completed`) **vẫn duyệt ảnh mới** — nghĩa là quyền hồi tố không chỉ tồn tại về lý thuyết mà **có tác dụng ghi thật trên buổi đã đóng**.

---

## 4. Function and policy inventory

Mọi hàm dưới đây: owner `postgres`, EXECUTE ACL = `authenticated`, `postgres`, `service_role` (không có `PUBLIC`, không có `anon`).

| Object | Identity | Owner | Security | search_path | Reads | Writes | Authority role | Risk |
|---|---|---|---|---|---|---|---|---|
| `submit_session_journal` | `(uuid,text,text)` md5 `8fc9ace1…` | postgres | **DEFINER** | `public` | `lesson_sessions` `class_distributions` `child_observations` `moment_children` `media_assets` `skill_catalog` | `learning_moments` `child_journey` `child_skills` `session_reports` `lesson_sessions` `audit_logs` | **Cổng duy nhất** của gửi + duyệt nhật ký | **HỒI TỐ** · không có nhánh school-admin · `search_path=public` chưa harden |
| `is_session_lead` | `(uuid)` md5 `8b4f91dd…` | postgres | DEFINER | `""` | `lesson_sessions` `class_distributions` | — | Predicate authority | **HỒI TỐ** · gác 4 fn + 14 policy |
| `start_session` | `(uuid)` md5 `9307a5d9…` | postgres | DEFINER | `public` | `lesson_sessions` | `lesson_sessions.taught_by` `.state` `audit_logs` | Writer **duy nhất** của `taught_by` | Audit payload **sai hình dạng** (F3) · gate = `is_session_lead OR is_session_teacher` (hồi tố) |
| `is_session_teacher` | `(uuid)` md5 `44496f28…` | postgres | DEFINER | `""` | `session_teachers` **(legacy)** | — | Predicate participation | Đọc bảng legacy, **chưa** cutover sang canonical |
| `is_school_admin` | `()` md5 `71b0310c…` | postgres | **INVOKER** | **`<none>`** | `profiles` (qua `current_profile_role`) | — | Nhánh school-admin của 14 policy | **P2-HARDEN-01** — INVOKER + không ghim `search_path` |
| `is_distribution_lead` | `(uuid)` md5 `88a23304…` | postgres | DEFINER | `""` | `class_distributions` | — | Policy `lesson_sessions` ×2 | Hồi tố (đã không với tới được sau WP3) |
| `get_session_detail` | `(uuid)` md5 `7f83cfce…` | postgres | DEFINER | `public` | 5 bảng | — | Read model buổi học | **KHÔNG có `can_submit_journal`** — P1-12 của WP2 vẫn mở |
| `get_teacher_classes` | `()` | postgres | DEFINER | — | `class_distributions.lead_teacher_id` `session_teachers` | — | **Nguồn authority của UI** | UI suy luận quyền ở client từ `is_lead` cấp **lớp** |
| `check_session_media_upload_access` | `(uuid,uuid)` md5 `c3166bac…` | postgres | DEFINER | `public` | `lesson_sessions` `class_distributions` `session_teachers` | — | Gate upload/xoá media | Hồi tố · legacy table |
| `set_distribution_lead` | `(uuid,uuid)` md5 `223c68e7…` | postgres | DEFINER | `""` | `class_distributions` | `class_distributions.lead_teacher_id` `audit_logs` | **Nguồn của defect hồi tố** | Đổi 1 trường → đổi quyền toàn bộ lịch sử distribution |
| `dma_snapshot_planned_teacher` | `()` trigger | postgres | DEFINER | `""` | `class_distributions` | `session_teacher_assignments` | Writer **duy nhất** của `planned` | Hardcode `'planned'` ✅ · bỏ qua khi `lead_teacher_id IS NULL` (im lặng) |
| `dma_guard_sta_immutable` | `()` trigger | postgres | **INVOKER** | `""` | — | — | Chặn **mọi** UPDATE/DELETE trên STA | **Chặn vô điều kiện** → hiện chưa tồn tại đường supersession nào |
| `get_school_week_planned_teachers` | `(date)` | postgres | DEFINER | — | STA `+ 4` bảng | — | Surface A/B | Lọc đúng `assignment_type='planned'` ✅ **an toàn khi mở từ vựng** |
| `write_audit_log` | `(text,jsonb)` | postgres | DEFINER | — | — | `audit_logs` | Ghi audit | Đọc `p_fields->>'actor_id'`/`'entity_id'` — `start_session` gửi sai key (F3) |

**Policy tham chiếu `is_session_lead` (14):**

| Bảng | Policy | Grant cấp bảng `authenticated` | Với tới được? |
|---|---|---|---|
| `session_reports` | `_insert_lead_or_schooladmin` · `_update_lead_or_schooladmin` | **INSERT/UPDATE/DELETE/TRUNCATE** | **CÓ — F1** |
| `session_teachers` | `_insert` · `_update` · `_delete` | chỉ SELECT | không (đóng từ WP2-S0A) |
| `child_observations` | `_insert_teacher` · `_update_teacher` | column-grant (WP1) | **CÓ** — 10 cột |
| `prep_items` | `_insert` · `_update` · `_delete` | INSERT/UPDATE/DELETE/TRUNCATE | **CÓ** |
| `session_marks` | `_insert_teacher` · `_delete_teacher` | INSERT/UPDATE/DELETE/TRUNCATE | **CÓ** |
| `session_media` | `_insert_teacher` · `_update_teacher` · `_delete_teacher` | INSERT/UPDATE/DELETE/TRUNCATE | **CÓ** |

**`session_teacher_assignments` — posture hiện tại:** `authenticated` **chỉ `SELECT`**; `anon` **không có ACL entry nào**. RLS: 1 policy `sta_select_school` = `same_school(session_school_id(session_id))`. Không policy ghi. Trigger `trg_sta_immutable` (INVOKER) chặn UPDATE/DELETE vô điều kiện. **Stop-gate #4 KHÔNG chạm** — user-JWT không thể ghi đè bằng chứng append-only.

**Ràng buộc từ vựng (quan trọng nhất cho A3):**

```
sta_type_chk   CHECK (assignment_type = 'planned')          ← whitelist ĐÚNG MỘT giá trị
sta_source_chk CHECK (assignment_source IN (5 giá trị migration_*/runtime_*/system_*))
sta_current_uidx UNIQUE (session_id, assignment_type) WHERE is_current
sta_supersede_fk FOREIGN KEY (superseded_by, session_id, assignment_type)
                 REFERENCES (id, session_id, assignment_type)   ← lineage KHÔNG cross-dimension ✅
sta_actor_chk  assigned_by NOT NULL chỉ khi source='runtime_distribution_lead_snapshot'
```

Cột thật là `assignment_type` / `is_current` / `teacher_id` / `assignment_source` — **không phải** `dimension` / `state` / `profile_id` / `source` như đề bài WP4 giả định. **Không có cột `school_id`** — biên giới trường phải suy ra qua chuỗi FK `session → class_distribution → class → school`.

---

## 5. Current defect reproduction

Tất cả bằng chứng dưới đây **read-only**. Không có subtransaction nào bị bỏ dở, không có row nào đổi.

### 5.1 Bằng chứng lịch sử — quyền ĐÃ từng chuyển hồi tố trên production

`audit_logs`, `action='distribution_lead_changed'`, `entity_id = d1000000-…-031` (distribution Hoa Hồng, sở hữu **7/9** buổi kể cả **cả hai** buổi đã gửi nhật ký):

| Thời điểm ICT | lead_from | lead_to |
|---|---|---|
| 2026-07-21 13:53:13 | Đặng Mỹ Linh (…011) | **Trần Khánh Vy (…013)** |
| 2026-07-21 13:55:04 | Trần Khánh Vy (…013) | Đặng Mỹ Linh (…011) |

**Trong cửa sổ 111 giây đó, Trần Khánh Vy nắm quyền gửi/duyệt nhật ký của mọi buổi lịch sử thuộc distribution — kể cả buổi ngày 30/06 và 01/07 do cô Mỹ Linh dạy và đã gửi nhật ký. Đồng thời cô Mỹ Linh mất quyền trên chính hai buổi của mình.** Đây không phải giả định: nó đã xảy ra trên dữ liệu sống.

### 5.2 Bằng chứng cấu trúc — vì sao chuyện đó là tất yếu

`is_session_lead` chỉ có **một** đầu vào khả biến và **không** dữ kiện nào của buổi:

```sql
exists(select 1 from lesson_sessions s
       join class_distributions cd on cd.id = s.class_distribution_id
       where s.id = p_session_id and cd.lead_teacher_id = current_profile())
```

Suy ra hình thức: với **mọi** profile P, ghi P vào `cd.lead_teacher_id` ⇒ `is_session_lead(S) = true` cho **mọi** buổi S của distribution đó, quá khứ lẫn tương lai, không phụ thuộc bất kỳ bằng chứng nào. Bảng bằng chứng session-scoped của 3 ứng viên trên 2 buổi lịch sử:

| Buổi | Ứng viên | `taught_by` | `planned` | có upload ảnh | có gửi nhật ký | → `is_session_lead` nếu là lead hiện tại |
|---|---|:--:|:--:|:--:|:--:|:--:|
| `aaaa…0a0001` | Đặng Mỹ Linh | ✅ | ✅ | ✅ | ✅ | true |
| `aaaa…0a0001` | Trần Khánh Vy | ❌ | ❌ | ❌ | ❌ | **true** |
| `aaaa…0a0001` | Vũ Hoàng Nam | ❌ | ❌ | ❌ | ❌ | **true** |
| `aaaa…0a0002` | Đặng Mỹ Linh | ✅ | ✅ | ✅ | ✅ | true |
| `aaaa…0a0002` | Trần Khánh Vy | ❌ | ❌ | ❌ | ❌ | **true** |
| `aaaa…0a0002` | Vũ Hoàng Nam | ❌ | ❌ | ❌ | ❌ | **true** |

**Bốn ô `true` với bốn hàng bằng chứng rỗng — đó chính xác là defect.**

### 5.3 Quyền hồi tố có tác dụng GHI THẬT, không chỉ đọc

Đếm read-only số moment mà nhánh idempotent của `submit_session_journal` **sẽ duyệt** nếu lead hiện tại gọi lại trên buổi đã đóng:

| Buổi | state | Số moment sẽ bị duyệt với `approved_by` = người gọi |
|---|---|---|
| `2fab0c56` | completed | 0 |
| `aaaa…0a0001` | taught_report_pending | 0 |
| **`aaaa…0a0002`** | taught_report_pending | **1** |

Một ảnh của trẻ đang chờ, và **bất kỳ ai được ghi vào `cd.lead_teacher_id` ngày mai** đều có thể duyệt nó với tên mình trong `approved_by`, dù chưa từng có mặt trong buổi học đó.

### 5.4 Từ chối cross-school — hoạt động đúng

Impersonate `gv.han.demen@demo.demenart.com` (Bùi Ngọc Hân · MNDM · lead_teacher) gọi `submit_session_journal` trên buổi của KHM:

```json
{"ok": false, "reason": "forbidden"}
```

Không ghi. Cách ly trường **đang đúng** — nhưng đúng **một cách gián tiếp**: `is_session_lead` false vì cô không phải lead, chứ không phải vì có kiểm tra biên giới trường tường minh. Mã từ chối `forbidden` là generic ⇒ không lộ enumeration.

### 5.5 Từ chối theo state — hoạt động đúng

Impersonate `gv.linh.kidshouse@demo.demenart.com` (Đặng Mỹ Linh, **đang là lead**) gọi trên buổi `3bfb9730` state `scheduled`:

```json
{"ok": false, "state": "scheduled", "reason": "bad_state"}
```

State guard đúng và đứng **sau** authority guard — thứ tự này phải giữ nguyên ở A3.

### 5.6 Đường ghi thứ hai (F1) — chưa được chặn

Impersonate `hieutruong.kidshouse@demo.demenart.com` (master_admin):

| Kiểm tra | Kết quả |
|---|---|
| `has_table_privilege('authenticated','session_reports','UPDATE')` | **true** |
| `has_table_privilege('authenticated','session_reports','TRUNCATE')` | **true** |
| Vị từ RLS UPDATE trên buổi lịch sử `aaaa…0a0001` | **pass** |
| `is_school_admin()` | true |

Nghĩa là: `PATCH /rest/v1/session_reports?session_id=eq.<buổi lịch sử>` **thành công** cho lead hiện tại và cho school admin, ghi đè `summary` / `highlighted_children` / `state` — **không qua RPC, không audit, không state guard**. `TRUNCATE` **không chịu RLS** nên cả `anon` cũng xoá sạch bảng được.

> **Kết luận §5:** đóng authority chỉ ở `submit_session_journal` sẽ tạo ra một hệ thống *trông như* đã fix mà thực tế còn cửa sau rộng hơn cửa chính.

---

## 6. Planned / participating / responsible truth model

Ba chiều **không** được gộp. Định nghĩa chốt:

| | **planned** | **participating** | **responsible** |
|---|---|---|---|
| **Câu hỏi** | “Dự kiến ai đứng lớp?” | “Ai thực sự đã ở trong phòng?” | “Nhật ký buổi này là của ai?” |
| **Ngữ nghĩa** | sự thật **xếp lịch** | sự thật **vận hành** | sự thật **trách nhiệm** |
| **Ai tạo** | trigger `dma_snapshot_planned_teacher` khi tạo buổi; snapshot từ `cd.lead_teacher_id` **tại thời điểm đó** | `start_session` (`taught_by`) + `session_teachers` legacy (trợ giảng) | **CHƯA TỒN TẠI** — WP4 tạo ra |
| **Thời điểm** | `AFTER INSERT` trên `lesson_sessions` | khi cô bấm “Vào dạy” | đề xuất: cùng lúc `start_session` (§7) |
| **Số dòng active / buổi** | đúng **1** (`sta_current_uidx`) | 1 `taught_by` + N trợ giảng | đúng **1** |
| **Nơi lưu** | `session_teacher_assignments` `assignment_type='planned'` | `lesson_sessions.taught_by` (+ `session_teachers`) | `session_teacher_assignments` `assignment_type='responsible'` |
| **Bất biến?** | append-only, superseded được | `taught_by` bất biến sau WP3 | append-only, chuyển được có kiểm soát |
| **Có phải authority?** | **KHÔNG** | **KHÔNG** | **CÓ — nguồn duy nhất** |

**Trả lời từng câu hỏi bắt buộc của A2:**

1. **planned và responsible khác nhau được không?** — **Có, và phải được phép.** Cô A được xếp lịch, cô B dạy thay. Nếu bắt bằng nhau thì WP4 chỉ đổi tên defect.
2. **responsible và participating khác nhau được không?** — **Có.** Trợ giảng tham gia nhưng không chịu trách nhiệm nhật ký. Một buổi có nhiều participating, luôn đúng một responsible.
3. **Giáo viên dạy thay?** — `start_session` ghi `taught_by` = cô B ⇒ responsible = cô B, **không** phải người planned. Đây là ca dùng chính, phải chạy được mà không cần hiệu trưởng can thiệp.
4. **Cô A mở buổi, cô B gửi nhật ký?** — **Không cho phép mặc định.** Ai mở buổi thì người đó chịu trách nhiệm. Muốn đổi ⇒ phải qua đường chuyển trách nhiệm tường minh (§7.3). Đây là câu quan trọng nhất của cả WP4: nó là điểm khác biệt giữa “ai đó trong trường” và “người chịu trách nhiệm”.
5. **Chuyển được không?** — **Có**, nhưng phải append-only + superseding, có actor, có lý do bắt buộc.
6. **Ai được chuyển?** — school admin cùng trường (`master_admin`/`sub_admin`) **hoặc** chính người đang responsible bàn giao. **Không** phải lead hiện tại của distribution — nếu cho lead chuyển thì defect quay lại bằng cửa khác.
7. **Bằng chứng phải giữ gì?** — dòng cũ giữ nguyên với `is_current=false`, `valid_to`, `superseded_by` trỏ dòng mới; `assigned_by` = actor; audit log riêng. **Không bao giờ UPDATE `teacher_id`, không bao giờ DELETE.**
8. **Buổi đã huỷ?** — **không có responsible**, và **không cần**. `cancelled` không sinh nhật ký. Fail-closed ở đây là đúng, không phải lỗi.
9. **Buổi chưa dạy (`scheduled`/`prep_ready`)?** — **chưa có responsible**. Chỉ có planned. UI **không được** hiện chữ “phụ trách” ở giai đoạn này (target #5).
10. **Buổi không có responsible thì sao?** — **fail-closed: từ chối gửi nhật ký**, mã `no_responsible_assignment`. Với ngoại lệ bắt buộc ở §8/§12 cho dữ liệu lịch sử.
11. **Fail-closed tổng quát** — thiếu bằng chứng ⇒ từ chối, **không** rơi về lead hiện tại. Không có fallback ngầm nào. Đây là ranh giới không được thương lượng.

---

## 7. Responsibility lifecycle

```
 tạo buổi          →  planned      (trigger, snapshot cd.lead_teacher_id)
 [scheduled]          responsible: KHÔNG CÓ            → không gửi được nhật ký (đúng)
      │
      ├─ huỷ  →  [cancelled]       responsible: KHÔNG CÓ, vĩnh viễn
      │
      └─ start_session
           ├─ ghi taught_by  (participating — bất biến sau WP3)
           └─ ghi STA assignment_type='responsible', teacher_id = người bấm
                                     ↑ ĐIỂM SINH DUY NHẤT của responsible
      [in_progress]
      │
      ├─ submit_session_journal  →  is_session_responsible(session) = TRUE?
      │        └─ [taught_report_pending] → nhánh idempotent CŨNG phải qua cùng cổng
      │
      └─ transfer_session_responsibility(session, người mới, lý do)
               dòng cũ: is_current=false · valid_to=now() · superseded_by=<mới>
               dòng mới: is_current=true · assigned_by=actor · source='responsibility_transfer'
               → lịch sử KHÔNG mất một byte
```

**Tại sao điểm sinh là `start_session` chứ không phải lúc tạo buổi:** trách nhiệm là sự thật vận hành, không phải sự thật hành chính. Người bước vào phòng là người biết chuyện gì đã xảy ra. Đây cũng là điểm duy nhất trong hệ thống đã có bằng chứng runtime (`taught_by`) và đã được WP3 làm cho bất biến — gắn `responsible` vào cùng thời điểm cho hai chiều một nguồn gốc, kiểm chứng chéo được.

**Hệ quả:** `responsible` sẽ **luôn** khớp `taught_by` tại thời điểm sinh. Chúng vẫn là hai khái niệm riêng vì `taught_by` **không bao giờ** đổi (bằng chứng runtime), còn `responsible` **có thể** chuyển (bàn giao). Sau một lần chuyển, hai giá trị lệch nhau — và sự lệch đó chính là thông tin, không phải mâu thuẫn.

---

## 8. Historical backfill classification

9 buổi sống. Phân loại theo bằng chứng thật, **không suy đoán**:

| Buổi | Trường | State | `taught_by` | `planned` | Nhật ký | Bằng chứng khác | Phân loại |
|---|---|---|---|---|---|---|---|
| `aaaa…0a0001` | KHM | taught_report_pending | Mỹ Linh | Mỹ Linh | submitted · 11 ảnh (5 duyệt) | uploader + approver + audit `session_journal_submitted` = Mỹ Linh | **XÁC ĐỊNH** → Mỹ Linh |
| `aaaa…0a0002` | KHM | taught_report_pending | Mỹ Linh | Mỹ Linh | submitted · 4 ảnh (1 duyệt) | uploader + approver + recorder + audit = Mỹ Linh | **XÁC ĐỊNH** → Mỹ Linh |
| `2fab0c56` | DEMO-001 | completed | Cô Thúy Ngân Demo | Cô Thúy Ngân Demo | **final** · 1 observation | `session_teachers` = Thúy Ngân/`lead` · recorder NULL (legacy) · **không có audit** | **XÁC ĐỊNH (yếu)** → Thúy Ngân — 3 nguồn độc lập đồng thuận, nhưng state `final` không có writer giải trình được |
| **`aaaa…0a0003`** | KHM | **in_progress** | **NULL** | Mỹ Linh | không | **không moment, không observation, không report, không session_teachers, không audit** | **⛔ MƠ HỒ — SG-8** |
| `3bfb9730` | KHM | scheduled | NULL | Mỹ Linh | — | — | **KHÔNG ÁP DỤNG** (chưa dạy) |
| `91bc03d8` | KHM | scheduled | NULL | Mỹ Linh | — | — | **KHÔNG ÁP DỤNG** |
| `8dcf9f2e` | KHM | cancelled | NULL | Mỹ Linh | — | `session_teachers` = Lê Thảo My/`assist` | **KHÔNG ÁP DỤNG** (đã huỷ) |
| `ea85798a` | KHM | cancelled | NULL | Mỹ Linh | — | — | **KHÔNG ÁP DỤNG** |
| `6cbb4024` | KHM | cancelled | NULL | Mỹ Linh | — | — | **KHÔNG ÁP DỤNG** |

**Tổng: 3 xác định · 1 mơ hồ · 5 không áp dụng · 0 không bằng chứng.**
**Delta dòng dự kiến STA: +3 hoặc +4** (tuỳ quyết định D-2 ở §12). Không dòng nào bị sửa hay xoá.

### Vì sao `aaaa…0a0003` là stop-gate thật

Buổi này ở `in_progress` — trạng thái **duy nhất** mà `submit_session_journal` chấp nhận — nhưng **`taught_by` là NULL**, nghĩa là `start_session` chưa từng chạy trên nó (đây là fixture seed từ trước khi có `start_session`). Nó có **zero** dấu vết vận hành.

- Nếu backfill = planned (Mỹ Linh) ⇒ **vi phạm nguyên tắc “không dùng lead hiện tại làm sự thật lịch sử”**, vì planned của buổi này chính là snapshot của lead.
- Nếu **không** backfill ⇒ buổi rơi vào fail-closed và **không ai gửi được nhật ký** ⇒ **vi phạm target #4** (“luồng hợp lệ đang chạy phải tiếp tục chạy”).

**Không có lối thoát kỹ thuật. Đây là quyết định của Owner (D-2 §12).**

### Cảnh báo về nguồn bằng chứng (F3)

Đề bài WP4-A4 liệt kê “audit log” là nguồn bằng chứng hợp lệ. **Trên hệ thống sống nó KHÔNG dùng được cho participation:** cả 3 dòng `session_started` đều có `actor_id`, `entity_id`, `metadata` = NULL, do `start_session` truyền `{'session_id','actor'}` trong khi `write_audit_log` đọc `{'entity_id','actor_id'}`. Audit **chỉ** dùng được cho `session_journal_submitted` (hình dạng đúng). Sửa payload này là một P1 độc lập, nên nằm trong WP4 slice 1.

---

## 9. Proposed authority predicate

### Khuyến nghị: ★ **PHƯƠNG ÁN A — predicate mới `is_session_responsible(uuid)`**

**Lý do bác Phương án B (inline trong `submit_session_journal`):** không phải vì inline sai về kỹ thuật, mà vì `session_reports` (F1) và các policy khác cũng cần đúng vị từ đó. Inline ⇒ logic authority tồn tại một bản trong RPC và một bản chép tay trong policy ⇒ vi phạm **D293** (UI/policy phải soi gương *mọi* nhánh của RPC) ngay từ ngày đầu. Predicate dùng chung là cách duy nhất giữ một nguồn sự thật.

**Lý do KHÔNG sửa `is_session_lead`:** nó gác **4 function + 14 policy** trên 6 bảng. Đổi ngữ nghĩa = trợ giảng mất quyền điểm danh, mất quyền upload ảnh, mất quyền tick prep — một sự cố vận hành lớn hơn nhiều lần defect đang sửa. `is_session_lead` phải **giữ nguyên byte** trong WP4.

```sql
create or replace function public.is_session_responsible(p_session_id uuid)
returns boolean
language sql stable
security definer
set search_path = ''
as $$
  select exists (
    select 1
    from public.session_teacher_assignments a
    join public.lesson_sessions ls on ls.id = a.session_id
    where a.session_id      = p_session_id
      and a.assignment_type = 'responsible'
      and a.is_current
      and a.valid_to is null
      and a.teacher_id      = public.current_profile()
      and public.same_school(public.session_school_id(p_session_id))
  );
$$;
```

| Hạng mục | Chốt |
|---|---|
| Signature | `public.is_session_responsible(uuid) → boolean` |
| Owner | `postgres` |
| Posture | **SECURITY DEFINER**, `stable` |
| `search_path` | **`''`** (rỗng — chặt hơn `submit_session_journal` hiện tại) |
| Grants | `REVOKE ALL FROM PUBLIC` → `GRANT EXECUTE TO authenticated, service_role` — **theo D15, khối REVOKE/GRANT phải chạy riêng sau `CREATE OR REPLACE`, verify bằng `aclexplode`** |
| RLS | Không phụ thuộc RLS (DEFINER); biên giới trường ép **tường minh** bằng `same_school`, không dựa gián tiếp như hôm nay |
| Failure contract | Predicate trả `false` — **không** raise. RPC trả `{"ok":false,"reason":"forbidden"}` cho mọi trường hợp không đủ quyền, và `{"ok":false,"reason":"no_responsible_assignment"}` **chỉ** khi caller ở đúng trường (không tạo enumeration cross-school) |
| Audit | Predicate **không** ghi audit (là hàm `stable`). Ghi audit ở RPC gọi nó |

**Thứ tự guard bắt buộc trong `submit_session_journal` sau WP4** — không được đảo:

```
1. session tồn tại?            → session_not_found
2. is_session_responsible()?   → forbidden          ← THAY is_session_lead
3. có dòng responsible không?  → no_responsible_assignment
4. state hợp lệ?               → bad_state
5. nhánh idempotent            ← PHẢI đi qua bước 2, không được đường tắt
```

**Từ vựng cần mở (đây là migration bảo mật theo D288):**

```sql
sta_type_chk   : CHECK (assignment_type = 'planned')
              → CHECK (assignment_type IN ('planned','responsible'))
sta_source_chk : + 'runtime_start_session' · 'migration_responsible_backfill'
                 · 'responsibility_transfer'
sta_actor_chk  : phải yêu cầu assigned_by NOT NULL cho 'responsibility_transfer'
```

**Tiền đề bắt buộc trước khi mở từ vựng (whitelist conversion — D288):** đã kiểm toán xong **toàn bộ** consumer của STA.

| Consumer | Lọc `assignment_type`? | Kết luận |
|---|---|---|
| `get_school_week_planned_teachers` | ✅ `='planned'` ở **cả hai** query | An toàn |
| `dma_snapshot_planned_teacher` | ✅ hardcode `'planned'` khi INSERT | An toàn |
| `dma_guard_sta_immutable` | không cần (chặn mọi UPDATE/DELETE) | An toàn — **nhưng phải nới cho supersession** |
| RLS `sta_select_school` | ❌ không lọc | SELECT-only, cùng trường — **chấp nhận được**, nhưng frontend đọc trực tiếp STA sẽ **nhân đôi dòng** |
| Frontend đọc STA trực tiếp | **CHƯA XÁC MINH** — xem §11 H-1 | Phải verify trước slice 3 |

`dma_guard_sta_immutable` chặn UPDATE vô điều kiện ⇒ **chưa tồn tại đường supersession nào**. Slice chuyển trách nhiệm bắt buộc phải thay guard này bằng bản cho phép **đúng một** hình dạng UPDATE (`is_current: true→false` + set `valid_to` + set `superseded_by`, mọi cột khác bất biến) và **chỉ** khi `dma_write_is_privileged()` — giữ INVOKER theo **D311-cand**.

---

## 10. Caller impact map

Cột: **R** = read model · **C** = command authority · **U** = UI affordance · **RT** = runtime evidence · **H** = historical evidence.

| Surface | R | C | U | RT | H | Tác động WP4 |
|---|:--:|:--:|:--:|:--:|:--:|---|
| **Teacher Home** (`get_teacher_home`) | ✅ | — | — | — | ✅ | Danh sách buổi vẫn resolve qua `cd.lead_teacher_id` — buổi lịch sử của cô **biến mất** khỏi Home khi cô đổi lớp. Cần bổ sung nhánh `responsible`. **Không chặn WP4.** |
| **Teacher Classes** (`get_teacher_classes`) | ✅ | **✅** | ✅ | — | — | **Đường quan trọng nhất.** Frontend suy `leadOfThis` từ `is_lead` cấp **lớp**. Sau WP4 nó sẽ **sai lệch với backend** → nút bật mà RPC từ chối, hoặc nút tắt mà cô có quyền — **vi phạm D290/D293 theo cả hai chiều**. Bắt buộc thay bằng capability server-derived. |
| **`get_session_detail`** | ✅ | — | — | — | — | Bổ sung `can_submit_journal` + `submit_block_reason`, **mirror đúng 5 nhánh** ở §9. Đây là món nợ P1-12 từ WP2 chưa trả. |
| **Session route** `teacher.session.$id.tsx` | ✅ | ✅ | ✅ | ✅ | — | `StepReview` bỏ `get_teacher_classes` khỏi hàm `load()`; `canSubmit` lấy từ `get_session_detail`. Copy hiện tại *“Chỉ giáo viên phụ trách buổi…”* **hôm nay đang nói dối**, sau WP4 mới thành thật — **không cần sửa chữ, cần sửa backend cho khớp chữ**. |
| **Journal submission UI** | — | ✅ | ✅ | — | — | Thêm hiển thị `no_responsible_assignment` bằng tiếng người, không hiện mã lỗi. |
| **School session detail** | ✅ | — | ✅ | — | ✅ | Phải phân biệt rõ **“Giáo viên dự kiến”** (planned) vs **“Giáo viên phụ trách”** (responsible) — hai dòng khác nhau, không gộp. |
| **Surface A** (nhãn tuần) | ✅ | — | ✅ | — | — | `get_school_week_planned_teachers` lọc `'planned'` đúng ⇒ **không đổi hành vi**. Chỉ cần xác nhận copy vẫn nói “dự kiến”. |
| **Surface B** (panel chi tiết, đọc-chỉ) | ✅ | — | ✅ | — | ✅ | Nơi tự nhiên để hiện responsible **sau khi** buổi đã dạy. Vẫn đọc-chỉ. |
| **Surface C** (deferred) | — | ✅ | ✅ | — | — | **GIỮ ĐÓNG cho tới khi authority model được chứng minh** (target #7). WP4 là tiền đề của nó, không phải ngược lại. |
| **Reassignment writer** (tương lai) | — | ✅ | ✅ | — | ✅ | Sẽ đổi **planned**. Phải viết sao cho **không** chạm `responsible` — hai writer riêng, hai RPC riêng, hai quyền riêng. |
| **`prep_items` · `session_marks` · `session_media` · `child_observations`** | — | ✅ | ✅ | ✅ | ✅ | Vẫn gác bằng `is_session_lead OR is_session_teacher` ⇒ **vẫn hồi tố**. Chủ ý: WP4 **không** đụng, vì đây là quyền *ghi trong buổi*, không phải *authority nhật ký*. Đăng ký nợ tường minh, không im lặng. |
| **`session_reports` direct DML (F1)** | ✅ | **✅** | — | — | ✅ | **Phải xử lý trong WP4**, nếu không điều kiện 4 của E3-SG-01 **không đóng được**. Xem D-3 §12. |

**Không có thay đổi frontend nào trong A1/A2.** Toàn bộ bảng trên là bản đồ, chưa phải lệnh thi công.

---

## 11. Security stop-gates

| # | Stop-gate | Trạng thái | Bằng chứng |
|---|---|---|---|
| 1 | Trách nhiệm chỉ suy được từ class state khả biến | **CHẠM — chính là defect đang sửa** | §5.2 — `is_session_lead` có đúng 1 đầu vào, 0 dữ kiện buổi |
| 2 | Lead hiện tại approve/submit buổi lịch sử không có bằng chứng session-scoped | **CHẠM ×2** | §5.3 (qua RPC, 1 ảnh thật) và **§5.6 (qua `session_reports` trực tiếp — đường thứ hai, chưa ai đăng ký)** |
| 3 | Actor khác trường resolve/mutate được trách nhiệm | **KHÔNG chạm** | §5.4 — `forbidden`, generic |
| 4 | User-JWT ghi đè được bằng chứng append-only | **KHÔNG chạm** | STA: `authenticated` chỉ SELECT · `anon` không ACL · trigger INVOKER chặn UPDATE/DELETE |
| 5 | Chuyển trách nhiệm xoá/ghi đè lịch sử được | **KHÔNG chạm (vì chưa có đường chuyển nào)** | `dma_guard_sta_immutable` raise vô điều kiện — A3 phải nới rất hẹp |
| 6 | Cần `service_role`/`postgres` cho luồng user bình thường | **KHÔNG chạm** | 5 writer đều SECDEF owner `postgres`, caller không cần table grant |
| 7 | Cutover làm hỏng nhật ký hiện có mà không có kế hoạch đối soát | **CÓ RỦI RO — đã có kế hoạch §8** | 2 buổi `taught_report_pending` sẽ tiếp tục gửi lại được nhờ backfill; buổi thứ 4 chờ D-2 |
| 8 | Có buổi lịch sử mơ hồ không backfill xác định được | **CHẠM** | `aaaa…0a0003` — §8 |

**Giới hạn coverage, ghi rõ (kế thừa WP3, không được coi là đã giải):**

- **H-1** — MCP Lovable không có repo-wide search. Đã đọc trực tiếp **1** file frontend (`teacher.session.$id.tsx`) trong ~205 file. **Chưa chứng minh được** rằng không có nơi nào đọc `session_teacher_assignments` trực tiếp mà thiếu lọc `assignment_type` — đây là điều kiện tiên quyết của D288 và **phải giải trước slice 3**.
- **H-3** — 16 Edge Function; WP3 đã đọc 7. **Chưa xác minh** Edge nào ghi `session_reports` bằng `service_role` (Edge dùng `service_role` ⇒ bypass RLS ⇒ vượt mọi predicate ở §9). 4 ứng viên cần đọc: `capture_session_moment` · `capture_session_media` · `delete_session_media` · `upload_media`.
- **QA debt** — không có profile `sub_admin` nào trong dữ liệu sống; nhánh school-admin chưa probe thực nghiệm được (kế thừa WP3 §5.4).

---

## 12. Owner decisions required

> Em đề xuất kèm ★. Anh trả lời gọn theo mã: `D-1: A` …

**D-1 · Điểm sinh của `responsible`**
- **A ★** — sinh trong `start_session`, teacher_id = người bấm “Vào dạy”. Trùng nguồn với `taught_by`, kiểm chứng chéo được.
- **B** — sinh trong `submit_session_journal` lần đầu. Đơn giản hơn nhưng buổi `in_progress` sẽ không có trách nhiệm suốt thời gian dạy.
- **C** — sinh lúc tạo buổi, copy từ planned. **Em không khuyến nghị** — đây chính là defect cũ đội tên mới.

**D-2 · Buổi `aaaa…0a0003` (in_progress · taught_by NULL · zero bằng chứng) — SG-8**
- **A ★** — **`migration_owner_attested`**: anh xác nhận bằng văn bản rằng cô Mỹ Linh chịu trách nhiệm buổi này, hệ thống ghi source `migration_owner_attested` (giá trị này **đã có sẵn** trong `sta_source_chk`, đã dùng ở S1, `evidence_grade='owner_attested'` chứ không phải `db_proven`). Trung thực: hệ thống nói rõ “đây là lời người, không phải bằng chứng máy”.
- **B** — không backfill; buổi này vĩnh viễn không gửi được nhật ký; cần đường vận hành riêng để đóng nó.
- **C** — huỷ buổi (`cancelled`) rồi tạo lại. Mất fixture, nhưng dứt điểm.

**D-3 · Đường ghi thứ hai `session_reports` (F1)**
- **A ★** — **đưa vào phạm vi WP4**: `REVOKE INSERT, UPDATE, DELETE, TRUNCATE ON session_reports FROM authenticated, anon` (đúng khuôn WP3, một câu lệnh, rollback một câu `GRANT`), giữ 3 policy làm defence-in-depth. **Nếu không làm, không được tuyên bố E3-SG-01 điều kiện 4 đã đóng.**
- **B** — tách WP5 riêng. E3-SG-01 vẫn OPEN sau WP4.
- **C** — chỉ đổi policy `is_session_lead` → `is_session_responsible` mà giữ nguyên grant. **Em không khuyến nghị**: `TRUNCATE` không chịu RLS nên `anon` vẫn xoá sạch bảng được.

**D-4 · Ai được chuyển trách nhiệm**
- **A ★** — school admin cùng trường (`master_admin`/`sub_admin`), bắt buộc lý do ≥10 ký tự, có audit.
- **B** — A **+** chính người đang responsible được bàn giao cho người cùng trường.
- **C** — hoãn hoàn toàn sang WP5; WP4 chỉ có đường **sinh**, chưa có đường **chuyển**. (Nhỏ nhất, an toàn nhất, nhưng GV nghỉ việc sẽ khoá buổi.)

**D-5 · `search_path` của `submit_session_journal`**
- **A ★** — nhân dịp sửa authority, đổi `search_path=public` → `''` và qualify toàn bộ tên bảng. Hàm 4776 ký tự, khoảng 20 chỗ phải sửa — rủi ro trung bình, nhưng làm sau sẽ đắt hơn.
- **B** — giữ `public`, ghim nguyên trạng, hoãn cùng P2-HARDEN-01.

---

## 13. Recommended WP4 implementation slices

Thứ tự **bắt buộc**. Mỗi slice đóng độc lập, rollback độc lập.

| Slice | Nội dung | Gate trước khi vào |
|---|---|---|
| **A3** | Chốt hợp đồng predicate + hình dạng migration. Chưa apply. | **Owner Gate D-1…D-5** |
| **A4** | Thiết kế backfill: precondition / postcondition / rollback / hash chuẩn tắc / delta dòng dự kiến. Chưa apply. | A3 duyệt |
| **S1** | **Migration 112 — nền tảng.** Mở `sta_type_chk` + `sta_source_chk`; tạo `is_session_responsible`; thay `dma_guard_sta_immutable` bằng bản cho phép đúng một hình dạng supersession; **sửa audit payload `start_session` (F3)**. Chưa đổi authority. | **D288 whitelist conversion phải xong — tức H-1 phải giải** |
| **S2** | **Migration 113 — backfill.** Sinh dòng `responsible` cho 3 buổi xác định (+1 nếu D-2=A). Append-only, delta dự kiến +3/+4, zero-unexplained-delta check. | S1 PASS |
| **S3** | **Migration 114 — cutover authority.** `submit_session_journal`: `is_session_lead` → `is_session_responsible` + nhánh `no_responsible_assignment`; `start_session` sinh `responsible`; `get_session_detail` trả `can_submit_journal`. | S2 PASS · **frontend chưa deploy ⇒ chấp nhận cửa sổ lệch ngắn, hoặc đảo S3/S4 theo bài học WP2** |
| **S4** | **Frontend.** `StepReview` bỏ `leadOfThis`, dùng `can_submit_journal`. Copy phân biệt “dự kiến” vs “phụ trách”. | S3 PASS |
| **S5** | **Migration 115 — containment `session_reports`** (nếu D-3=A) + policy chuyển sang `is_session_responsible`. | S4 deploy xong |
| **S6** | **Migration 116 — `transfer_session_responsibility`** (nếu D-4≠C). | S5 PASS |
| **S7** | QA login thật 2 trường (D2/D3) + Layer B re-run + zero-delta. | tất cả |

**Ràng buộc tuyệt đối:** S1 trước S2 trước S3 · **frontend (S4) trước containment (S5)** — đảo lại là lặp đúng lỗi Stage C của WP1. Và theo **D323-cand**, mọi `DO` block phải dry-run read-only trên pre-state sống trước khi apply.

---

## 14. Documentation impact

**Không sửa file canonical nào ở mốc này.** Theo tiền lệ WP1/WP3, `DMA_RULES.md` (endpoint **D309**) và `DMA_SYSTEM_MAP.md` (**v1.14**) chỉ canonicalize ở **E3 milestone closeout** sau khi WP4 đóng.

Khi đó, khối append phải gộp:

- khối WP3 đã soạn sẵn (WP3 closeout §13) — chưa áp;
- **D323-cand** (PL/pgSQL lazy SQL + alias shadowing) — chưa promote;
- D310-cand … D322-cand — chưa promote;
- các candidate mới do WP4 sinh ra, hiện đề xuất 3 mã, **chưa gán số**:

> **D324-cand — [authority · SESSION-SCOPED KHÔNG PHẢI ENTITY-SCOPED]**
> Quyền trên một **sự kiện đã xảy ra** không bao giờ được resolve từ trạng thái **hiện tại** của thực thể chứa nó. Predicate authority cho artefact lịch sử phải đọc bằng chứng gắn với chính sự kiện đó (`session_id` + `is_current` + dimension), không đọc con trỏ khả biến của thực thể cha. Kiểm thử: *“nếu tôi đổi một trường quản trị, có ai đó bỗng có quyền trên quá khứ không?”* — nếu có, đó là defect, không phải feature.

> **D325-cand — [security · ĐÓNG RPC MÀ QUÊN BẢNG]**
> Thay predicate trong một RPC **không** đóng được đường ghi nếu bảng đích còn grant DML cấp bảng cho `authenticated`. Trước khi tuyên bố bất kỳ authority nào đã đóng, phải chạy `aclexplode` trên **mọi bảng mà RPC đó ghi** và chứng minh không role API nào còn INSERT/UPDATE/DELETE/**TRUNCATE**. `session_reports` sống sót qua WP1 và WP3 đúng vì lý do này.

> **D326-cand — [audit · PAYLOAD KHÔNG KHỚP SCHEMA = MẤT BẰNG CHỨNG IM LẶNG]**
> `write_audit_log` đọc key cố định (`actor_id`, `entity_type`, `entity_id`, `school_id`, `metadata`). Truyền sai key **không** báo lỗi — nó ghi một dòng NULL. Mọi caller phải được verify bằng một `select` thật trên `audit_logs` sau lần gọi đầu tiên. `start_session` đã ghi 3 dòng vô dụng suốt từ đầu và chỉ lộ ra khi WP4 cần dùng chúng làm bằng chứng.

**Tài liệu WP4 sẽ sinh:** `DMA_V114B_E3_WP4_A1A2.md` (file này) → `…_WP4_A3A4.md` (hợp đồng + backfill design) → `…_WP4_CLOSEOUT.md` → **E3 milestone closeout** (nơi RULES/SYSTEM_MAP mới được canonicalize một lần).

---

WP4-A1/A2 COMPLETE — OWNER DECISIONS REQUIRED
