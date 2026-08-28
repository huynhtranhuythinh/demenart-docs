# 📊 V128-P2.0 — ATTENDANCE ROLLUP · VALUE GATE REPORT

> **Mode:** PRODUCT VALUE DELIVERY · AUDIT FIRST · Role = Architecture/Product Capability Reviewer (không phải workflow/scoring/authority designer).
> **Grounding:** live audit read-only (Supabase `xcvhacymrbhdhohyylyq` + Lovable HEAD). 0 mutation.
> **Câu hỏi vận hành:** *"Điểm danh các lớp của tôi đang thế nào?"* — cho Master/Principal (+ sub_admin theo authority sẵn có).

---

## ⭐ 0 · KẾT LUẬN GATE

**Gap P2 là THẬT** (khác P1 — P1 đã build sẵn). Không có read-contract nào trả breakdown **có mặt / vắng / đi muộn theo lớp trong một kỳ**. Dữ liệu thô **đủ** nhưng **chưa được expose** ở hình dạng rollup.

→ **Backend change = READ-CONTRACT ONLY** (1 read RPC mới). Theo boundary, em **STOP + báo** để owner authorize trước khi build — **không** dựng writer/permission/RLS/scoring.

---

## 1 · CURRENT ATTENDANCE DATA TRUTH

| Thuộc tính | Sự thật (verified) |
|---|---|
| Nguồn | `child_observations.attendance` |
| Kiểu | **text, nullable**, **KHÔNG có CHECK constraint** |
| Giá trị thực (live) | `present`, `late`, `absent` (+ `null` = chưa điểm danh) |
| Hạt | **1 dòng / bé / buổi** — unique `child_observations_session_child_key (session_id, child_id)` |
| Quan hệ | `child_observations.session_id → lesson_sessions.class_distribution_id → class_distributions (class_id, program_id) → classes.school_id`; `child_id → children` |
| Ghi bởi | `teacher_upsert_child_observation` (GV, assignment-aware) — mỗi tap điểm danh |

→ Dữ liệu thô **đủ** để rollup present/absent/late theo lớp × kỳ × trường. Semantics `late` (tính là "đi học" hay không) **chưa định nghĩa** ở DB → **không được tự phát minh** (xem §5).

---

## 2 · EXISTING BACKEND / READ CAPABILITY

RPC đụng attendance: `get_school_today_operations`, `get_teacher_session_workspace`, `get_session_roster`, `get_teacher_todo_counts(_in_school)`, `submit_session_journal`, `teacher_upsert_child_observation`.

Chỉ **1 fn aggregate ở cấp trường**: **`get_school_today_operations(p_date)`** — STABLE, SECURITY DEFINER, gate **master/sub_admin + school-scoped**. Nhưng:
- Trả `attendance: { recorded, total, complete }` = **chỉ mức HOÀN THÀNH điểm danh** (bao nhiêu bé đã được đánh), **KHÔNG** breakdown present/absent/late.
- **Chỉ MỘT ngày** (`p_date`, default hôm nay) — không phải rollup theo kỳ.
- Mục đích: bảng "hôm nay cần chú ý" (attention reasons như `attendance_incomplete`), không phải rollup điểm danh.

`get_school_overview` — **không** tham chiếu attendance. Không RPC nào trả present/absent theo lớp × kỳ.

→ **Không có read-contract đủ để FE tự aggregate** rollup present/absent. Dữ liệu present/absent thô **không** được expose tới bất kỳ contract cấp-trường nào.

---

## 3 · EXISTING UI CAPABILITY

| Surface | Có gì về attendance | Là rollup P2? |
|---|---|---|
| `/school/manage` · `SchoolTodayBlock` (`get_school_today_operations`) | Tín hiệu **hôm nay**: điểm danh đã đủ chưa, lý do cần chú ý | ❌ Completeness 1 ngày, không breakdown |
| `/teacher/session/$id` · Bước 3 Điểm danh | GV đánh present/late/absent từng bé | ❌ Per-session, teacher-scoped |
| `/school/schedule` | Lịch buổi (state) | ❌ Không attendance |
| Routes School khác (drive/curriculum/moments/support/settings/notifications) | — | ❌ |

→ **Không có surface nào hiện present/absent rollup theo lớp × kỳ.** Không trùng lặp — không có cái để "activate thay vì build".

---

## 4 · EXACT CONFIRMED PRODUCT GAP

> Master/Principal **không thể** thấy, cho một kỳ gần đây, mỗi lớp: **số buổi đã điểm danh · số lượt có mặt / vắng / đi muộn · (tỷ lệ đi học)** — mà không phải mở từng buổi hoặc đếm tay từng bé. Dữ liệu có; **read-contract chưa expose**; UI chưa có.

---

## 5 · RECOMMENDED SMALLEST V1

**1 read RPC mới** (read-only aggregate, reuse authority của `get_school_today_operations`) + **1 surface School mỏng**.

**Backend — `get_school_attendance_rollup(p_from date default null, p_to date default null)` → jsonb** (đề xuất, CHƯA áp):
- Authority: resolve `auth.uid()→profiles`; require `role in ('master_admin','sub_admin')`; school từ profile; generic `not_authorized`. **Y hệt pattern today_ops — 0 permission/authority mới.**
- Kỳ: default 7 ngày (`v_to = coalesce(p_to, today VN)`, `v_from = coalesce(p_from, v_to-6)`); caller đổi được.
- Per class (school-scoped, buổi có `scheduled_at::date` trong kỳ, loại `cancelled`):
  - `class_id, class_name, program_name`
  - `sessions_observed` = count distinct buổi có ≥1 attendance recorded
  - `present`, `late`, `absent` = count raw từ `child_observations.attendance`
  - `marked_total` = present+late+absent
- **KHÔNG** ranking, **KHÔNG** color-judgment, **KHÔNG** risk/score.

**Tỷ lệ đi học (rate):** chỉ thêm **NẾU owner định nghĩa semantics** — `late` tính là "đi học" hay không? Vì mode cấm phát minh semantics, **V1 mặc định chỉ trả raw present/late/absent**; rate = presentation-derived sau khi owner chốt công thức (Gate P2-G1). Đề xuất: hiện raw counts + để owner chọn `rate = (present+late)/marked_total` hay `present/marked_total`.

**FE — surface (paste-mode khi backend PASS):**
- ⭐ Đề xuất: route mỏng **`/school/attendance`** (mirror pattern `/school/schedule`, reuse emerald tokens), link từ overview `/school`. Bảng: mỗi lớp 1 hàng — buổi đã điểm danh · có mặt · đi muộn · vắng · (rate) — + toggle kỳ **7 / 30 ngày** + hàng tổng. Mỗi lớp drill sang `/school/schedule` (buổi của lớp) khi cần.
- Nhẹ hơn (alternative): 1 section trong overview thay vì route riêng. *(Owner chọn — Gate P2-G2.)*

**UX principle giữ đúng:** Rollup = **Tín hiệu vận hành**, KHÔNG phải điểm GV / xếp hạng lớp / phán xét. **Signal ≠ Decision · Visibility ≠ Authority.**

---

## 6 · EXACT USER WHO BENEFITS

**Master / Principal** (chủ thể chính) + **sub_admin** nơi authority sẵn có cho phép (đúng gate `master_admin/sub_admin` của today_ops). GV **không** — GV đã có điểm danh per-buổi; rollup là góc nhìn điều hành của hiệu trưởng.

---

## 7 · FILES / CONTRACTS LIKELY AFFECTED

| Layer | Đối tượng | Loại |
|---|---|---|
| Backend | **NEW** `get_school_attendance_rollup(date,date)` | read RPC (migration D92/D15/D289 khi authorize) |
| FE hook | **NEW** `useSchoolAttendanceRollup.ts` | read |
| FE surface | **NEW** `/school/attendance` route (hoặc section overview) | presentation |
| FE nav | link từ `/school` overview → attendance | 1 link |
| Reuse | school emerald tokens, Card/Select, `vnDateKey` | — |

**Không đụng:** `child_observations` schema, `teacher_upsert_child_observation`, RLS, authority resolver, lifecycle, Mission Control.

---

## 8 · BACKEND CHANGE CLASSIFICATION

**🟡 READ-CONTRACT ONLY** — 1 read RPC mới, aggregate raw counts, reuse authority master/sub + school-scope. Không writer, không permission mới, không RLS, không lifecycle, không scoring.
→ Theo boundary + invariant "no new backend without CTO auth": **STOP + báo để owner authorize** trước khi áp (như P1.0B).

---

## 9 · BUILDER-READY SCOPE

Khi owner authorize:
1. **Migration** (D92 3-block · D15 grant `authenticated,service_role` · D289 notify): tạo `get_school_attendance_rollup`.
2. **Backend VERIFY** (impersonation master read-only): rollup trả present/late/absent đúng cho ≥1 lớp có data; gate chặn non-master.
3. **FE paste-mode**: hook + `/school/attendance` (bảng + toggle 7/30 + tổng + drill) + link overview.
4. **Owner QA** (§10) với `hieutruong.kidshouse` / `Test@123`.

Scope cấm: ranking/scoring, color-as-judgment, đụng writer/RLS/authority, đặt vào Mission Control.

---

## 10 · OWNER QA SCENARIO

```
Cổng Trường (/school)
  → mở "Điểm danh" (/school/attendance)
  → chọn kỳ (7 / 30 ngày)
  → thấy mỗi lớp: buổi đã điểm danh · có mặt · đi muộn · vắng · (rate)
  → (tùy) mở lớp/buổi để xem sâu
```
**Không SQL. Không đếm tay từng bé.** PASS khi hiệu trưởng đọc được thực trạng present/absent toàn trường trong ≤2 chạm.

---

## 🏁 FINAL QUESTION — "Sau khi P2 deploy, hiệu trưởng làm được điều MỚI gì?"

> **Cụ thể:** Hiệu trưởng mở Cổng Trường → một bảng cho biết trong 7 (hoặc 30) ngày qua, **mỗi lớp** đã điểm danh bao nhiêu buổi và tổng **có mặt / vắng / đi muộn** — **không cần mở từng buổi hay đếm tay từng bé**. Trước P2: phải mở từng session / từng observation. Sau P2: thấy toàn cảnh trong 2 chạm.

→ Câu trả lời **cụ thể** → **P2 ĐỦ ĐIỀU KIỆN BUILD** (pending 1 authorization).

---

## ✅ DECISION

- Capability **chưa tồn tại** ✅ (không phải activate).
- Read-contract **không đủ** để FE-only → cần **1 read RPC mới**.
- **STATUS: STOP + REPORT** — chờ owner authorize `get_school_attendance_rollup` (read-only). Đồng thời chờ **Gate P2-G1** (định nghĩa rate / late) + **P2-G2** (route riêng hay section).

**Owner cần quyết:**
1. **Authorize** read RPC `get_school_attendance_rollup`? (Y/N)
2. **P2-G1:** rate = raw-only V1 (khuyến nghị) / (present+late)/total / present/total?
3. **P2-G2:** `/school/attendance` route riêng (khuyến nghị) / section trong overview?

**Endpoint: V128-P2.0 · AUDIT DONE · gap CONFIRMED · backend=READ-CONTRACT ONLY · STOP pending owner authorization + G1/G2 · 0 mutation.**
