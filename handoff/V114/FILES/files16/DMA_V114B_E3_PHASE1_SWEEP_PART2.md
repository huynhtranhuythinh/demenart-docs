# DMA — V114B-E3 · PHASE 1 SWEEP · PHẦN 2/2 — RPC · RLS · PARENT-FACING · SCHOOL

> Đóng 5/7 hạng mục §I của Phần 1. **Chưa chạm code. Chưa viết migration 105.**
> Ký hiệu: **[DB]** truy vấn live · **[R]** đọc repo · **[I]** suy ra · ⬜ chưa làm.

---

## A. ✅ ĐÓNG NGHI VẤN D293 (§B Phần 1) — **KHÔNG CÓ MISMATCH**

**[DB]** `submit_session_journal` gate duy nhất:

```sql
if not is_session_lead(p_session_id) then return ... 'forbidden'; end if;
```

**[DB]** `is_session_lead(p_session_id)`:

```sql
select exists (select 1 from lesson_sessions s
  join class_distributions cd on cd.id = s.class_distribution_id
  where s.id = p_session_id and cd.lead_teacher_id = current_profile());
```

| | Nguồn sự thật | Kết luận |
|---|---|---|
| UI gate (`StepReview`) | `get_teacher_classes.is_lead` ⟸ `cd.lead_teacher_id = v_profile` | |
| RPC gate | `is_session_lead` ⟸ `cd.lead_teacher_id = current_profile()` | |
| **Trùng nhau?** | **CÓ — cùng một cột, cùng một chủ thể** | 🟢 **D293 không vi phạm** |

Kiểm luôn nhánh rìa: `get_teacher_classes.sessions` loại `state = 'cancelled'`. Buổi `cancelled` ⇒ UI ẩn nút, RPC trả `bad_state` — **hai bên cùng từ chối**, không có cửa mở mà UI đóng hay ngược lại.

➡️ **E3-06 không phải lỗi lệch gate. Nó là lỗi *ngữ nghĩa nhất quán*** — cả hai tầng cùng đúng với nhau và **cùng sai** so với sự thật vận hành. Điều này thực ra **tốt cho E3**: chỉ cần đổi một khái niệm ở một chỗ (`is_session_lead` → `session_responsible()`), hai tầng tự khớp lại.

**Bổ sung [DB]:** `submit_session_journal` ghi `learning_moments.approved_by = current_profile()`. Đây là **artifact actor duy nhất được ghi đúng và không hồi tố** trong toàn hệ.

---

## B. 🔴 E3-08 → **XÁC MINH XONG, NÂNG LÊN P1**. Kéo theo **E3-09 MỚI**

**[DB]** RLS `learning_moments` — cả 3 policy đều dùng role `{public}`:

| cmd | qual | with_check |
|---|---|---|
| INSERT | — | `same_school(class_school_id(class_id))` |
| UPDATE | `same_school(class_school_id(class_id))` | `same_school(class_school_id(class_id))` |
| SELECT | `same_school(...) OR (is_moment_parent(id) AND state='approved')` | — |

### B.1 🔴 E3-08 — `uploaded_by` **không được ràng buộc ở bất kỳ đâu**

WITH CHECK **không nhắc tới `uploaded_by`**. Frontend gửi `uploaded_by: profile?.id` từ client (§D Phần 1). Vậy:

> Bất kỳ tài khoản nào trong cùng trường đều có thể INSERT một `learning_moment` và **gán tên người tạo cho một profile bất kỳ** — kể cả profile của trường khác (cột này không hề bị kiểm school).

Và vì UPDATE cũng chỉ gác `same_school`, `uploaded_by` của **moment đã tồn tại** cũng **sửa được**.

➡️ Đây đúng là thứ E3 sinh ra để bảo vệ: **attribution có thể bị giả mạo và bị viết lại sau**. Không phải suy đoán — là điều RLS đang cho phép.

### B.2 🔴 E3-09 — **MỚI, P1: UPDATE trực tiếp có thể tự duyệt moment, vượt mặt `submit_session_journal`**

Cùng policy `learning_moments_update_school`: `state` **không** nằm trong bất kỳ ràng buộc nào. Mà `state='approved'` chính là điều kiện Parent-facing:

```
SELECT: is_moment_parent(id) AND state = 'approved'
```

Nghĩa là một tài khoản cùng trường có thể `update learning_moments set state='approved'` thẳng từ client, **bỏ qua toàn bộ ba điều kiện** mà `submit_session_journal` áp:
- ❌ không cần buổi ở `in_progress`
- ❌ không cần moment đã gắn bé (`moment_children`)
- ❌ không cần có `media_assets` active
- ❌ không sinh `child_journey`, không audit log, `approved_by` để null

**Consent vẫn gác ở tầng ký URL** (MIN-consent khi phát signed URL) — nên **không rò ảnh**. Nhưng metadata moment (caption, gắn bé) hiện ra với phụ huynh qua một đường không phải cửa nhật ký.

**[DB] dấu vết production:** 18 moment · **13 moment có `approved_by IS NULL`**. Chưa thể kết luận đây là dấu hiệu bị lạm dụng — moment ở `draft` cũng null. Cần đối chiếu `state` từng dòng trước khi nói gì thêm. **Em chưa kết luận.**

### B.3 Stop-Gate — vẫn 🟢, và đây là lý do

| Tiêu chí Stop-Gate | E3-08 / E3-09 |
|---|---|
| Cross-school? | **Không** — `same_school` chặn. Kẻ khai thác phải đã là người của chính trường đó |
| Client-supplied identity? | **Có, một phần** — `uploaded_by` client gửi, không bị ràng buộc |
| Service-role bypass? | Không |
| Rò ảnh trẻ ra ngoài? | **Không** — consent gác ở tầng ký URL |

➡️ Em **đề nghị không kích hoạt Stop-Gate**, vì blast radius nằm trong biên một trường và không rò media. Nhưng E3-08/E3-09 **phải nằm trong migration 105**, không được đẩy sang milestone sau — vì đây chính là bề mặt E3 tuyên bố bảo vệ. **Owner có quyền lật quyết định này.**

---

## C. 🔴 E3-10 — MỚI, P1: `set_session_teachers` **HARD-DELETE lịch sử tham gia**

**[DB]** toàn văn:

```sql
delete from session_teachers st
where st.session_id = p_session_id and not (st.profile_id = any(v_ids));
...
insert into session_teachers (session_id, profile_id, role)
select p_session_id, u.x, 'assist' ...
```

Cho phép ở state `scheduled · prep_ready · makeup · **in_progress**`.

> Đổi danh sách giáo viên của một buổi **đang dạy** ⇒ dòng cũ **biến mất vĩnh viễn**, không audit ở tầng dòng (chỉ có `write_audit_log` ghi mảng id sau cùng).

Đây là **đường viết lại lịch sử phân công đã tồn tại và đang chạy**. Bảng `session_teacher_assignments` với I9 (không hard-delete, `superseded`) đúng là câu trả lời — §9.3 của audit đã thiết kế đúng, nay có bằng chứng nó giải quyết một defect thật chứ không phải phòng xa.

### C.1 Đính chính audit §7 — **`profiles.state` ĐÃ được enforce ở đây**

Audit Phase 1 §7 ghi *"Không guard nào trong 5 RPC của E2 đọc `profiles.state`"*. **Sai.** `set_session_teachers` có:

```sql
where p.id = u.x and p.school_id = v_school
  and p.state = 'active'
  and p.role in ('lead_teacher','assistant_teacher')
```

➡️ **E3-04 nhẹ hơn dự tính.** Ngữ nghĩa `state='active'` đã tồn tại và đã được thi hành ở ít nhất một guard. Việc cần làm là **mở rộng cho nhất quán**, không phải phát minh khái niệm. Em giữ đề xuất (a) — enforce trong assignment guard mới — với chi phí thấp hơn đã ước lượng.

**[DB]** 27 profile, **tất cả `state='active'`** — chưa trường nào cho nghỉ việc thật. Cửa vẫn khoá trước khi có ca đầu tiên.

---

## D. ✅ E3-03 — `session_teachers.role` : **0 người đọc, toàn hệ**

**[DB]** quét toàn bộ 196 secdef function bằng regex `st\.role | role='lead' | role='assist'` ⇒ **0 kết quả**.
**[DB]** 10 function có nhắc `session_teachers`, không function nào chạm cột `role`.
**[R]** `school.manage.tsx` · `teacher.session.$id.tsx` · `parent.journal.tsx` — 0 tham chiếu.
**[DB]** `set_session_teachers` **luôn ghi `'assist'`**, không đường nào ghi `'lead'`.
**[DB]** dữ liệu: `assist` ×1 · `lead` ×1 — dòng `lead` là **di tích**, không đường nào sinh ra được nữa.

➡️ **E3-03 hạ từ 🔴 xuống 🟡 an toàn.** Cột `role` là write-only legacy với 0 consumer. Transition plan tối giản:

1. Migration 105: `COMMENT ON COLUMN` đánh dấu deprecated + **không** đọc trong bất kỳ resolver mới nào.
2. Backfill: 1 dòng `lead` → `session_teacher_assignments` với `dimension='planned'`, `participation_role='co_teacher'` (**không** phải `primary` — không có bằng chứng nó nghĩa là primary), `source='legacy_backfill'`.
3. Drop cột ở milestone sau, sau khi assignment table đã là nguồn sự thật ≥1 sprint.

Mâu thuẫn "hai nguồn sự thật cho lead" **về mặt vận hành đã không tồn tại** — vì không ai đọc.

---

## E. 🔴 E3-11 — MỚI: **PARENT-FACING KHÔNG HỀ CÓ ATTRIBUTION** (§2.5 chưa đạt, toàn phần)

**[DB]** quét toàn schema `public`, function nào chạm `uploaded_by` / `approved_by`:

| Function | `uploaded_by` | `approved_by` | Bề mặt |
|---|---|---|---|
| `admin_lookup_media` · `get_school_media_library` · `drive_*` (6) · `archive_empty_draft_moment_service` · `finalize_voice_contribution` · `get_teacher_todo_counts` | ✅ | — | Admin / School / Teacher |
| `submit_session_journal` | — | ✅ **ghi** | Teacher |
| **`get_child_journal`** | ❌ | ❌ | **Parent** |
| **`get_kid_album_service`** | ❌ | ❌ | **Kid** |
| `get_session_detail` | ❌ | ❌ | Teacher |

**`approved_by` có 0 function đọc.** Ghi rồi để đó.

**[R]** `parent.journal.tsx` toàn văn: chỉ tiêu thụ payload `get_child_journal` (`journey · skills · badges · moments · creations`) qua `buildParentTimeline`. **Không** đọc bảng trực tiếp. **Không** có trường tên giáo viên ở bất kỳ đâu.

➡️ **Hai hệ quả trái chiều, cả hai đều quan trọng:**

1. ✅ **Rủi ro regression Parent-facing = 0.** E3 đổi mô hình attribution không thể làm hỏng màn hình ba mẹ, vì màn hình ba mẹ chưa từng hiển thị attribution. Đây là điều kiện thuận lợi lớn cho migration 105.
2. 🔴 **§2.5 "gia đình biết ai đã ghi lại điều này" chưa đạt — không phải một phần, mà là toàn bộ.** Không có gì để "bảo toàn"; phải **xây mới**.

Em đề nghị **tách việc hiển thị attribution cho ba mẹ ra khỏi E3** thành một mục riêng (E4?). E3 lo *sự thật được ghi đúng và không bị viết lại*; việc *gia đình nhìn thấy sự thật đó* là quyết định sản phẩm có ràng buộc riêng (quyền riêng tư giáo viên, cô đã nghỉ việc, tên hiển thị). Trộn hai việc vào 105 sẽ làm migration phình và khó rollback. **Owner quyết.**

---

## F. E3-07 MỞ RỘNG — RLS `child_observations` **cũng hồi tố**

**[DB]**:

| cmd | gate |
|---|---|
| INSERT | `is_session_lead(session_id) OR is_session_teacher(session_id)` |
| UPDATE | `is_session_lead(session_id) OR is_session_teacher(session_id)` |
| SELECT | `same_school(session_school_id(session_id))` |

`is_session_lead` = lead **hiện tại**. Vậy ngoài việc **không có cột actor** (E3-07), quyền **sửa điểm danh và nhận xét của buổi lịch sử** cũng chuyển sang lead mới ngay khi đổi Giáo viên chính.

**[DB]** 5 dòng `child_observations` trên production — recorder = **unknown vĩnh viễn**, đúng như kết luận Phần 1.

➡️ E3-07 nâng phạm vi: cần **cả** `recorded_by` (dòng mới) **và** đổi gate sang responsible/participation. Backfill bất khả — ghi debt.

---

## G. `school.manage.tsx` — TOÀN VĂN ĐÃ ĐỌC **[R]**

### G.1 Câu chữ sai, nguyên văn

`ClassSubjectsPanel`, ngay dưới danh sách môn:

> *"Giáo viên chính là người gửi nhật ký của môn. **Đổi giáo viên chính chỉ áp dụng cho buổi tạo mới, không thay đổi buổi đã xếp.**"*

| Vế | Phán định |
|---|---|
| "GV chính là người gửi nhật ký của môn" | 🟡 **đúng-hiện-tại** (`is_session_lead`) — **sẽ sai sau E3**, phải đổi thành *responsible teacher của buổi* |
| "chỉ áp dụng cho buổi tạo mới, không thay đổi buổi đã xếp" | 🔴 **SAI** — E3-02 (media/remote) + E3-06 (gửi nhật ký) + §F (điểm danh) đều hồi tố ngay lập tức |

### G.2 UI đổi lead — **không một lớp bảo vệ nào**

`DistributionRowItem`: một `<Select>` + nút "Lưu GV chính" → `set_distribution_lead`. Không đếm buổi lịch sử bị ảnh hưởng, không confirm dialog, không cảnh báo. **[I]** Với thiết kế E3 (planned materialize tại `create_lesson_session`), nút này sau 105 **phải** hỏi: *áp cho buổi tương lai thôi, hay cả buổi đã xếp chưa dạy?* → đây chính là chỗ `bulk_reassign_future_sessions` của §11 gắn vào.

### G.3 Ghi thẳng bảng (ngoài scope E3, ghi nhận)

| Bảng | Thao tác | Gác bởi |
|---|---|---|
| `classes` | INSERT | RLS `is_admin() OR (is_school_admin() AND same_school)` ✅ |
| `profiles` | INSERT (thêm GV, client gửi `role` + `school_id`) | RLS whitelist role, `user_id IS NULL`, `same_school` ✅ |
| `support_requests` · `notifications` | SELECT | RLS ✅ |

### G.4 ✅ Kiểm tra escalation — **AN TOÀN**

Vì `school.manage.tsx` để client gửi `role`/`school_id` vào `profiles`, em kiểm đường tự nâng quyền:

- **[DB]** `authenticated` **có** `UPDATE` grant trên cột `role`, `school_id`, `user_id`, `permissions`.
- **[DB]** RLS `profiles_update_row` có nhánh `user_id = auth.uid()` ⇒ tự sửa dòng mình, WITH CHECK không chặn cột.
- **[DB]** **NHƯNG** trigger `trg_guard_profiles_protected` → `guard_profiles_protected_cols()` ghim lại cho mọi non-admin:
  ```sql
  new.role := old.role; new.permissions := old.permissions;
  new.school_id := old.school_id; new.user_id := old.user_id;
  ```

➡️ 🟢 **Không có đường tự nâng quyền, không có đường nhảy trường.** Stop-Gate không kích hoạt.

⚠️ Ghi nhận nhỏ (không phải E3): cột **`state` KHÔNG được ghim**. Một tài khoản có thể tự đổi `profiles.state` của chính mình. Vô hại hôm nay (chưa guard nào đọc `state` ngoài `set_session_teachers`), nhưng sau khi E3 dùng `state='active'` làm điều kiện assignment thì cột này trở thành **bề mặt bảo mật** — **phải ghim vào trigger trong 105**. Ghi là **E3-12 🟡**.

### G.5 `rescheduled` — E3-05 lặp lại ở file này

`ScheduleLegend` liệt kê `rescheduled` = "Đổi lịch"; `SESSION_CELL` map đủ màu. Enum chết vẫn hiện chú giải ở **hai** file (`school.schedule.tsx` + `school.manage.tsx`).

---

## H. DEFECT REGISTER — HỢP NHẤT SAU SWEEP

| ID | Mức | Nội dung | Trạng thái |
|---|---|---|---|
| E3-01 | 🔴 P1 | FK `session_teachers.profile_id` CASCADE | ✅ chốt `ON DELETE RESTRICT` (§G Phần 1) |
| E3-02 | 🔴 P1 | Media/remote access hồi tố theo lead | xác minh |
| E3-06 | 🔴 P1 | Quyền gửi nhật ký hồi tố theo lead | ✅ D293 **không** vi phạm — sai ngữ nghĩa nhất quán (§A) |
| E3-07 | 🔴 P1 | `child_observations` không có actor **+ gate hồi tố** | mở rộng (§F) · backfill bất khả |
| **E3-08** | 🔴 **P1** | `learning_moments.uploaded_by` không ràng buộc — giả mạo & viết lại được | ✅ **đóng nghi vấn, là defect thật** (§B.1) |
| **E3-09** | 🔴 **P1 MỚI** | UPDATE trực tiếp đặt `state='approved'` — vượt mặt `submit_session_journal` | §B.2 |
| **E3-10** | 🔴 **P1 MỚI** | `set_session_teachers` hard-delete lịch sử tham gia, cho cả `in_progress` | §C |
| **E3-11** | 🔴 **MỚI** | Parent-facing **không có** attribution; `approved_by` 0 người đọc | §E — đề nghị tách khỏi E3 |
| E3-03 | 🟡 P2 | `session_teachers.role` | ✅ **hạ mức** — 0 consumer toàn hệ (§D) |
| E3-04 | 🟡 | enforce `profiles.state='active'` | ✅ **nhẹ hơn** — đã có tiền lệ trong `set_session_teachers` (§C.1) |
| E3-05 | 🟡 P2 | enum `rescheduled` chết, còn trong legend ×2 file | §G.5 |
| **E3-12** | 🟡 **MỚI** | `profiles.state` không được trigger ghim — sẽ thành bề mặt bảo mật sau E3 | §G.4 |

**Security Stop-Gate: 🟢 KHÔNG KÍCH HOẠT** — không cross-school, không escalation, không rò media. E3-08/09 nằm trong biên một trường. Em nêu rõ để Owner có thể lật.

---

## I. CÒN THIẾU — TRUNG THỰC

| # | Hạng mục | Vì sao em cho là **đủ để vào Phase 2** |
|---|---|---|
| 1 | `teacher.index/classes/journal/moments.tsx` chưa đọc từng dòng | Cả 4 chỉ tiêu thụ `get_teacher_home` · `get_teacher_classes` · `get_teacher_todo_counts` · `get_teacher_journals` — **đã inventory đầy đủ ở §4.1 của audit**. Rủi ro còn lại là **câu chữ UI**, không phải dependency |
| 2 | `parent.index.tsx` · `features/journey/*` chưa đọc từng dòng | **[DB] chứng minh** không RPC parent nào trả attribution ⇒ component không thể hiển thị thứ không tồn tại (§E) |
| 3 | `taught_by` frontend sweep | 0 đọc ở `teacher.session.$id` · `school.manage` · `parent.journal`; `SessionInfo` không có trường này ⇒ **đề xuất giữ hướng 1** (canonicalize + `COMMENT`), **vẫn chưa đề xuất rename** |

⬜ **Thực sự chưa làm:** QA matrix cuối · nội dung SQL migration 105.

---

## J. ĐỀ XUẤT — MỘT VIỆC TIẾP THEO

Phase 1 sweep **coi như hoàn tất** ở mức đủ để thiết kế. Còn **đúng một cửa Owner phải mở** trước khi em viết migration 105:

> **§10 của audit: 10-A hay 10-B** cho 3 dòng `taught_by` lịch sử.
>
> **10-A ★** — tạo dòng `dimension='actual'`, `confirmation_status='candidate'`, `source='legacy_session_start_actor'`.
> **10-B** — không tạo dòng nào, `taught_by` ở nguyên chỗ cũ như legacy evidence.

Và **một quyết định mới sinh ra từ Phần 2**:

> **§E: E3-11 (hiển thị attribution cho ba mẹ) nằm trong 105, hay tách sang milestone sau?**
> Em nghiêng **tách** — 105 đã gánh bảng mới + 4 resolver + 5 RPC + 6 REPLACE + backfill + 4 defect P1 mới (08/09/10/12).

Owner chốt hai điều này, em vào Phase 2 và viết 105.

---

*Sinh trong V114B-E3 Phase 1 · HEAD `7ee7eeba` · migration 104 · chưa chạm code.*
