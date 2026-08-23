# DMA — V114B-E3 · PHASE 1 SWEEP · PHẦN 1/2 — BỀ MẶT TEACHER

> **Đây CHƯA phải Phase 1 Final Audit Addendum.** Bề mặt Parent-facing và `school.manage.tsx` chưa quét.
> Owner cấm vào Phase 2 trước khi sweep hoàn tất — em tuân, và nói rõ còn thiếu gì.
> **Chưa chạm code. Chưa viết migration 105.**

---

## A. `taught_by` — DEPENDENCY SWEEP

| Tầng | Đọc | Ghi |
|---|---|---|
| DB (196 secdef fn) | **0** | 1 — `start_session` |
| `teacher.session.$id.tsx` (toàn văn) **[R]** | **0** | gọi `start_session` |
| Type `SessionInfo` trả từ `get_session_detail` | **không có trường `taught_by`** | — |

➡️ Tính tới đây, `taught_by` **chưa từng được đọc ở bất kỳ đâu**. Sweep còn lại: `parent.*`, `features/journey/*`, `school.manage.tsx`, `teacher.index/classes/journal/moments`. Nếu tất cả cũng bằng 0, hướng **rename an toàn `taught_by → started_by`** trở nên khả thi với rủi ro gần bằng 0 — nhưng **em chưa tuyên bố**.

`COMMENT ON COLUMN` theo §1 của Owner vẫn làm được ngay trong 105 bất kể kết quả sweep.

---

## B. 🔴 E3-06 — PHÁT HIỆN MỚI, P1: QUYỀN GỬI NHẬT KÝ CŨNG HỒI TỐ

`teacher.session.$id.tsx` · `StepReview.load()` **[R]**:

```js
const cls = await supabase.rpc("get_teacher_classes");
const leadOfThis = rows.some((c) => c.is_lead && (c.sessions ?? []).some((s) => s.id === session.id));
setCanSubmit(leadOfThis);
```

**[DB]** `get_teacher_classes` là hàm duy nhất trong nhóm này còn đọc `cd.lead_teacher_id`. Nghĩa là:

> **Ai được bấm "Hoàn tất & gửi nhật ký" cho một buổi đã dạy được quyết định bởi lead của distribution *tại thời điểm mở màn hình*.**

Đổi Giáo viên chính hôm nay ⇒ cô giáo đã thật sự dạy buổi tuần trước **mất quyền gửi nhật ký của chính buổi mình dạy**; người mới **được** quyền gửi nhật ký cho buổi mình chưa từng bước vào.

Đây **nặng hơn E3-02**. `submit_session_journal` là RPC sinh `child_journey` và duyệt `learning_moments` — tức là **cửa ra Parent-facing**. E2-01 không chỉ chạm hiển thị và upload media; nó chạm **quyền tạo bằng chứng phát triển của trẻ**.

**Copy đi kèm cũng sai:** *"Chỉ giáo viên phụ trách buổi mới gửi được nhật ký."* — "phụ trách **buổi**" gợi ý vai trò cấp session, nhưng thực thi là lead cấp **distribution**. Sau E3 câu này phải nói đúng **responsible teacher**.

⚠️ **Nghi vấn D293 chưa đóng:** UI gate đọc `get_teacher_classes.is_lead`; RPC `submit_session_journal` **không** chứa `lead_teacher_id` — nó tự kiểm bằng đường khác và trả `forbidden`. Hai gate **có thể không trùng nhau**. Chưa đọc thân RPC ⇒ **chưa kết luận**. Phải làm trong phần 2.

---

## C. 🔴 E3-07 — PHÁT HIỆN MỚI, P1: ĐIỂM DANH VÀ NHẬN XÉT KHÔNG CÓ ACTOR

**[DB]** `child_observations` — 12 cột:

```
id · session_id · child_id · attendance · skills_observed · note ·
linked_moment_ids · is_highlight · needs_support · follow_up_needed ·
visibility · created_at
```

**Không có `created_by`. Không có `recorded_by`. Không có bất kỳ cột actor nào.**

Owner Contract §2.5 liệt kê **"Attendance recorder"** và **"Learning evidence creator"** là actor truth bất biến. Prompt §10 yêu cầu *"Attendance recorder: là actor thực hiện action"*.

**Hai thứ này hiện không tồn tại trong dữ liệu.** Không phải ghi sai — mà là **chưa từng được ghi**.

Hệ quả cho E3:
- Không thể "bảo toàn" attribution điểm danh/nhận xét — không có gì để bảo toàn.
- **Không thể backfill** — không có nguồn. Mọi observation lịch sử có recorder = **unknown vĩnh viễn**.
- E3 phải thêm cột actor cho observation mới, hoặc ghi debt rõ ràng rằng §2.5 chỉ được thoả **một phần** (journal author và media uploader có; attendance recorder và evidence creator **không**).

Em không tự quyết. Đây là dữ kiện, và nó thay đổi phạm vi §10 của prompt.

---

## D. WRITE PATH FRONTEND — GHI THẲNG BẢNG, KHÔNG QUA RPC

`teacher.session.$id.tsx` ghi trực tiếp 6 bảng **[R]**, RLS là rào duy nhất:

| Bảng | Thao tác | Actor được ghi |
|---|---|---|
| `prep_items` | UPDATE `is_ready` | ❌ không |
| `support_requests` | INSERT | ✅ `requester_profile_id` |
| **`child_observations`** | **UPSERT** (điểm danh + nhận xét + visibility) | ❌ **không có cột** |
| `learning_moments` | INSERT | ✅ `uploaded_by: profile?.id` — **do client gửi** |
| `learning_moments` | UPDATE caption | ❌ không |
| `moment_children` | INSERT / DELETE (gắn/bỏ gắn bé) | ❌ không |

Hai điểm cần ghi nhận:
1. **`uploaded_by` do client cung cấp.** RLS `learning_moments` policy `{public}` (V114A-P2-1 đã mở) — chưa xác minh có WITH CHECK ép `uploaded_by = profile của auth.uid()` hay không. **Phần 2 phải kiểm.** Nếu không có, đây là lỗ giả mạo attribution — và attribution là thứ E3 phải bảo vệ.
2. `moment_children` DELETE hard — gỡ gắn bé không để lại vết. Ngoài scope E3 nhưng liên quan trực tiếp tới "historical attribution không bị rewrite".

---

## E. `start_session` — AI BẤM ĐƯỢC

`StepPrep.start()` **[R]** không có gate vai trò nào ở UI. Bất kỳ ai mở được `/teacher/session/$id` và tới Bước 1 đều bấm được "Vào dạy". RPC tự kiểm state (`bad_state`) và authority.

➡️ **Xác nhận trực tiếp tiền đề của Owner:** start actor có thể là trợ giảng, hiệu trưởng, hoặc người đang cầm máy chung. Kết luận *"`taught_by` = actor, không phải actual teacher"* đúng với hành vi thật, không phải suy đoán.

Cho §2 của Owner Decision, điều kiện tạo **teaching participation candidate** tương lai (`profile active` + cùng school + là planned/co/assistant/substitute đã authorize) sẽ **loại đúng các trường hợp này** — thiết kế khớp với thực tế đo được.

---

## F. UI WORDING INVENTORY — BỔ SUNG TỪ FILE NÀY

| Câu | Vấn đề |
|---|---|
| *"Chỉ giáo viên phụ trách buổi mới gửi được nhật ký."* (×2: nhánh từ chối + thông báo lỗi RPC) | 🔴 "phụ trách **buổi**" ≠ thực thi bằng lead **distribution** |
| *"Ghi nhận của cô đã được lưu và sẽ đi kèm khi buổi được gửi."* | 🟡 đúng, nhưng không nói ai sẽ gửi |
| *"Buổi này đã gửi nhật ký. Cô có thể gửi lại để duyệt thêm ảnh mới."* | ✅ trung tính |
| *"Ảnh có bé chưa đồng ý sẽ tạm giữ với gia đình bé đó."* | ✅ đúng, khớp MIN-consent |
| *"Ghi chú này dành cho nhà trường xem lại, không gửi cho ba mẹ."* | ✅ cần regression-test sau E3 |
| *"Cô không có quyền ghi nhận buổi này."* / *"Cô không có quyền xem buổi học này."* | 🟡 sau E3 phải phân biệt planned vs responsible |

---

## G. ĐỀ XUẤT CẬP NHẬT E3-01 SAU AUDIT PROFILE DELETION

Owner yêu cầu audit đường xoá profile trước khi chốt FK. **[DB]** kết quả:

| Kiểm tra | Kết quả |
|---|---|
| Hàm nào `DELETE FROM profiles`? | **0** |
| Policy `DELETE` trên `profiles`? | **KHÔNG TỒN TẠI** — 5 policy: 3 SELECT, 1 INSERT, 1 UPDATE |
| Hàm nào set state inactive/disabled? | **0** |
| `profiles_update_row` cho phép school admin sửa cùng trường? | ✅ có |

➡️ **Không tồn tại đường xoá profile vật lý ở tầng ứng dụng.** Deactivation khả thi qua `profiles.state` với policy hiện có.

**Đề xuất chốt: `ON DELETE RESTRICT`** — đúng preference của Owner. Nó biến việc xoá profile vật lý thành bất khả thi khi còn lịch sử phân công, và đẩy vận hành về hướng deactivation. **Không** chọn `SET NULL`, vì đúng như Owner cảnh báo, nó sẽ để lại một assignment vô danh.

---

## H. DEFECT REGISTER — CẬP NHẬT

| ID | Mức | |
|---|---|---|
| E3-01 | 🔴 P1 | FK CASCADE → **đề xuất RESTRICT** (§G) |
| E3-02 | 🔴 P1 | Media/remote access hồi tố theo lead |
| **E3-06** | 🔴 **P1 MỚI** | **Quyền gửi nhật ký hồi tố theo lead** — chạm cửa ra Parent-facing |
| **E3-07** | 🔴 **P1 MỚI** | **`child_observations` không có cột actor** — attendance recorder & evidence creator chưa từng được ghi |
| E3-03 | 🔴 P1 | `session_teachers.role='lead'` mơ hồ (Owner nâng mức) |
| E3-04 | 🔴 invariant | enforce `profiles.state='active'` cho assignment mới |
| E3-05 | 🟡 P2 | enum `rescheduled` chết |
| **E3-08** | ⬜ **chưa kết luận** | `learning_moments.uploaded_by` do client gửi — cần kiểm WITH CHECK ở phần 2 |

**Security Stop-Gate: vẫn 🟢 không kích hoạt.** E3-08 là nghi vấn chưa xác minh, không phải phát hiện.

---

## I. CÒN LẠI CHO PHẦN 2

1. `school.manage.tsx` — UI đổi Giáo viên chính + câu chữ sai đã biết
2. `teacher.index.tsx` · `teacher.classes.tsx` · `teacher.journal.tsx` · `teacher.moments.tsx`
3. **Parent-facing:** `parent.journal.tsx` · `parent.index.tsx` · `features/journey/*` · `get_child_journal` — attribution hiển thị cho phụ huynh
4. Thân RPC `submit_session_journal` — đóng nghi vấn D293 ở §B
5. RLS `learning_moments` WITH CHECK — đóng E3-08
6. Mọi usage của `session_teachers.role='lead'` (2 dòng dữ liệu thật) + transition plan cho bảng
7. Final file inventory · schema cuối · migration 105 boundary · QA matrix

---

*Sinh trong V114B-E3 Phase 1 · HEAD `7ee7eeba` · migration 104 · chưa chạm code.*
