# 🧭 V128-P1.0 — SESSION SCHEDULING CAPABILITY DESIGN REPORT

> **Mode:** PRODUCT CAPABILITY DESIGN · AUDIT FIRST · DESIGN ONLY · **STOP (no code / no migration / no commit)**
> **Role:** Architecture Analyst / Product Capability Reviewer — **không phải builder, không quyết thay owner.**
> **Owner-approved inputs:** G1 roadmap ✅ · G2 creator = Master **+ Teacher Lead** ✅ · G3 V1 scope = create + weekly view + cancel (defer recurring/drag-drop/advanced) ✅.
> **Grounding:** ⭐ live audit read-only — Supabase (`xcvhacymrbhdhohyylyq`) **+ Lovable repo HEAD** (`d9d56000…`), 0 mutation.

---

## ⭐ 0 · KẾT LUẬN QUAN TRỌNG NHẤT (đọc trước tiên)

**Live audit lật ngược giả định của REVIEW.1 / ROADMAP.2.**

REVIEW.1 nói *"không có UI xếp lịch"*. ROADMAP.2 chỉnh thành *"backend có, UI là gap"*. **Cả hai đều dưới-đếm.** Sự thật từ repo HEAD:

> ### 🟢 P1 (Master) — **ĐÃ ĐƯỢC BUILD ĐẦY ĐỦ VÀ WIRED.**
> Route **`/school/schedule`** (`src/routes/_authenticated/school.schedule.tsx`) đã có **create + weekly view + edit + cancel**, nối vào **đúng các RPC đã tồn tại**, cho **Master/sub_admin**. Link "Mở lịch triển khai" từ `/school/manage` đã trỏ vào.

→ **Không cần build lại P1 cho Master.** Design gate này vừa **ngăn việc tái dựng một tính năng đã có** — đúng lý do mode bắt "AUDIT FIRST". Việc còn lại **không phải "build cái gì"** mà là **verify + quyết một điểm authority (G2)**.

*(Bài học meta: SYSTEM_MAP milestone log trễ hơn repo thật ở mảnh này. Live repo là authority — D1/D116. Em đính chính thẳng.)*

---

## 1 · CURRENT CAPABILITY STATE

| Thành phần P1 | Trạng thái thật | Bằng chứng |
|---|---|---|
| **Create session** | 🟢 BUILT (Master/sub) | `CreateSessionPanel` → `create_lesson_session(...)` |
| **Weekly schedule view** | 🟢 BUILT | `ScheduleView` → `get_school_week_schedule` + `get_school_week_planned_teachers` |
| **Cancel session** | 🟢 BUILT (Master/sub) | `SessionDetailPanel` → `cancel_lesson_session(reason)` + confirm 2 bước |
| **Edit/reschedule** (ngoài G3, bonus) | 🟢 BUILT (Master/sub) | `update_lesson_session` + `set_session_teachers`, gate state `{scheduled,prep_ready,makeup}` |
| **Teacher Lead tạo/sửa/huỷ (G2)** | 🔴 **CHƯA & backend KHÔNG cho** | 4 RPC đều Master-only; UI gate `canManage` = master/sub |
| **Discoverability** | 🟡 Yếu | Chỉ vào qua 1 link nhỏ trong card dashboard, chưa phải nav chính |
| **Adoption** | 🟡 Chưa dùng | Live 9 buổi (tạo gần nhất 21/07); **0 buổi `scheduled`** hiện tại (toàn past/cancelled) |

**Live data:** sessions `cancelled:3 · completed:1 · in_progress:1 · taught_report_pending:4`. Có buổi `cancelled` → luồng huỷ đã từng chạy thật. Không có buổi tương lai → pilot chưa dùng lịch để xếp buổi mới.

---

## 2 · LIVE AUDIT FINDINGS

### 2.1 · Backend (đã audit đầy đủ)
Ba RPC + 2 helper — tất cả **SECURITY DEFINER**, gác **giống hệt nhau**:

`is_admin() OR (current_profile_role() in ('master_admin','sub_admin') AND school ∈ user_school_ids())`

| RPC | Args (evidence) | Cho Lead? |
|---|---|---|
| `create_lesson_session` | `class_distribution_id, scheduled_at, duration_min?, title?, lesson_version_id?, teacher_ids[]?` | ❌ |
| `update_lesson_session` | `session_id, scheduled_at?, duration_min?, title?, lesson_version_id?, clear_lesson?` | ❌ |
| `cancel_lesson_session` | `session_id, reason?` (chỉ state `scheduled/prep_ready/makeup`) | ❌ |
| `set_session_teachers` | `session_id, teacher_ids[]?` | ❌ |
| `get_school_week_planned_teachers` | `week_start` | ❌ (read, school-scope) |

Validation sẵn: duration 5–480 · lesson_version phải `published` + cùng program · teacher_ids phải active lead/assistant same-school · chống trùng slot (`session_slot_taken`) · audit `session_created/updated/cancelled`. **RLS policy có nhắc `is_distribution_lead` NHƯNG RPC secdef bypass RLS → authority thật = check-trong-RPC = Master-only.**

### 2.2 · Frontend (repo HEAD)
- **`/school/schedule`** — `ssr:false`; roles view = master/sub/lead/assistant, **manage = master/sub** (`canManage`). Grid tuần + nút "+" mỗi ô (chỉ canManage) + click buổi → chi tiết. Reuse design tokens `#149A76`, `Sheet`/`Card`/`Select`.
- **`CreateSessionPanel`** — form: Ngày · Giờ (→ ghép ISO `scheduled_at`) · Thời lượng (default **45**) · Tiêu đề (optional) · Bài học (từ `useProgramLessons`, published) · Giáo viên thêm (checkbox → `teacher_ids`). **GV chính KHÔNG chọn — lấy từ `distribution.lead_teacher_id`** (người gửi nhật ký).
- **`SessionDetailPanel`** — edit khi state ∈ editable; **cancel** với lý do + xác nhận đỏ 2 bước; error map đầy đủ (`mapOpsErr`).
- **Pattern write** toàn portal School = `supabase.rpc(...)` inline + toast + reload (không adapter nặng). `/school/schedule` theo đúng pattern này.
- **Điều hướng:** `/school/manage` → card "Lịch triển khai tuần" (read-only preview) → link "Mở lịch triển khai" → `/school/schedule`.

### 2.3 · Role model (confirmed)
`is_school_admin()` = role ∈ {master_admin, sub_admin} · `is_distribution_lead(cd)` = `cd.lead_teacher_id = current_profile()` · scope qua `current_school_id()` / `user_school_ids()`.

---

## 3 · RECOMMENDED V1 SCOPE (đã hiệu chỉnh theo sự thật)

Vì Master-scheduling **đã tồn tại**, "V1 scope" không còn là *build*, mà là **3 việc**:

**V1-a · VERIFY (bắt buộc, 0 code):** owner login-thật xác nhận `/school/schedule` **đã deploy production** + chạy đúng: master tạo buổi → hiện lịch → GV thấy buổi ở `/teacher` → cancel → biến khỏi GV. *(Handoff em đọc chưa ghi QA cho route này → cần nghiệm thu.)*

**V1-b · DISCOVERABILITY (nhỏ, UI-only nếu owner muốn):** nâng `/school/schedule` thành **mục nav chính** của cổng School (hiện chỉ vào qua link trong card). Frontend-only, 0 backend.

**V1-c · QUYẾT G2 (Teacher Lead tạo buổi):** **CHƯA build & backend chưa cho.** Đây là điểm cần owner quyết (xem §8 Gate). Không thuộc "no permission change" của gate này.

> **Fields V1:** đã đúng chuẩn tối thiểu evidence-based, **không phát minh field mới** (đúng boundary). GV chính = ngầm từ distribution; teacher_ids = GV phụ optional.
> **Create/Edit/Cancel:** cả ba đã có. Edit là bonus ngoài G3 — **giữ, không cần gỡ**.

---

## 4 · USER JOURNEYS

### 4.1 · Master flow (ĐÃ TỒN TẠI — mô tả để verify)
```
/school (→ /school/manage)
  → card "Lịch triển khai tuần" → "Mở lịch triển khai"
  → /school/schedule (grid tuần: Lớp·Môn × 7 ngày)
  → bấm "+" ở ô (ngày × distribution)
  → Sheet "Tạo buổi học": ngày/giờ/thời lượng/tiêu đề/bài học/GV thêm
  → "Tạo buổi" → create_lesson_session → toast → lịch refresh
  → (sửa) bấm buổi → Sheet chi tiết → Lưu / Huỷ (lý do + xác nhận)
```

### 4.2 · Teacher Lead flow (CHƯA TỒN TẠI — phụ thuộc Gate G2)
Hiện GV lead **chỉ VIEW** `/school/schedule` (read-only) + thao tác buổi của mình qua `/teacher` · `/teacher/classes` · `/teacher/journal`. **Không tạo/sửa/huỷ buổi được** (RPC chặn). Nếu owner muốn G2 đúng nghĩa → cần:
```
[BACKEND — cần CTO authorize] thêm nhánh is_distribution_lead vào
  create/update/cancel_lesson_session + set_session_teachers
[FE] surface tạo buổi cho GV trên /teacher (giới hạn distribution mình lead)
```

---

## 5 · SURFACE RECOMMENDATION

| Surface | Khuyến nghị | Lý do |
|---|---|---|
| **School `/school/schedule`** | ⭐ **Giữ làm nhà chính của scheduling** + nâng lên nav chính | Đã build; đúng chủ thể (hiệu trưởng xếp lịch cả trường); read contract school-scope sẵn |
| **Teacher `/teacher`** | Chỉ mở surface tạo **nếu** Gate G2 = "có" | Cần backend authority mới; GV hiện đã có đường thao tác buổi của mình |
| **Mission Control `/admin/mission-control`** | ❌ **KHÔNG** | MC là tầng điều phối/governance của **admin nền tảng**, không phải vận hành trường. Scheduling là school-ops. Đưa vào MC = phá "Context ≠ Permission" |

---

## 6 · DEPENDENCIES

Tất cả **đã sống** cho Master path:
- RPC: `create_lesson_session` · `update_lesson_session` · `cancel_lesson_session` · `set_session_teachers` · `get_school_week_schedule` · `get_school_week_planned_teachers` ✅
- Schema: `lesson_sessions` (scheduled_at/duration_min/state/cancel_reason/title/lesson_version_id) · `session_teachers` · `class_distributions` (lead) ✅
- FE: `/school/schedule` route + panels + `useProgramLessons` + design tokens ✅
- Read refs: `class_distributions` (active) + `profiles` (teachers) ✅

**Chỉ Teacher-Lead path** mới có dependency chưa có: nhánh authority `is_distribution_lead` trong 4 RPC + FE surface GV.

---

## 7 · RISK ASSESSMENT

| Path | Risk | Ghi chú |
|---|---|---|
| **Master V1 (verify + discoverability)** | 🟢 **Rất thấp** | 0 backend, 0 authority mới. Chỉ QA + (tùy) 1 nav link. |
| **Teacher-Lead V1 (G2 đúng nghĩa)** | 🟡 **Trung bình** | Chạm **authority model** (4 RPC secdef) → cần CTO gate riêng + migration + re-harden D15/D92 + verify impersonation D333. **Vi phạm boundary "no permission change" của gate P1.0** → phải tách gate. |
| **Adoption** | 🟡 | Tính năng có nhưng pilot chưa xếp buổi mới (0 `scheduled`). Rủi ro "build mà không dùng" — verify + onboarding quan trọng hơn thêm code. |
| **Preserve invariants** | 🟢 | Master path giữ nguyên: Visibility≠Authority (GV thấy lịch, không sửa) · Context≠Permission · Signal≠Decision (RPC secdef là decision point). |

---

## 8 · ⭐ OWNER DECISION GATE (điểm duy nhất cần anh Jean quyết)

**GATE P1-G7 — Teacher Lead có được TẠO buổi học không?**

| Lựa chọn | Nội dung | Hệ quả |
|---|---|---|
| **⭐ A (khuyến nghị)** | **V1 = Master-only (đã có).** Verify + nâng discoverability. **Teacher-Lead-create tách thành P1.1** — 1 gate backend riêng (thêm nhánh `is_distribution_lead` vào 4 RPC + surface GV) khi owner cần. | Giao giá trị **ngay** (Master là người xếp lịch chính); giữ boundary gate P1.0; không mở authority vội. |
| **B** | Làm authority amendment **ngay** để đúng G2 4-RPC. | Ra ngoài scope "no permission change"; cần CTO gate + migration + re-harden; chậm hơn. |

**Phụ — GATE P1-G8 (nhỏ):** có nâng `/school/schedule` thành **nav chính** cổng School không? (FE-only, khuyến nghị: có.)
**Phụ — GATE P1-G9:** ai verify production QA `/school/schedule` (owner login-thật) trước khi coi P1 là "đóng"?

---

## 9 · BUILDER HANDOFF BOUNDARY

**Nếu owner chọn A (khuyến nghị) — builder KHÔNG viết logic scheduling mới:**
- IN: (1) owner-QA `/school/schedule` production login-thật; (2) *nếu G8=có* → thêm 1 nav entry School → `/school/schedule` (FE-only, `school.tsx` nav); (3) *nếu 0 buổi tương lai gây khó QA* → owner tạo 1 buổi thật qua UI (không seed SQL).
- OUT / CẤM: tái dựng CreateSessionPanel/SessionDetailPanel; đụng 6 RPC scheduling; đụng authority resolver; migration; đổi `create_lesson_session` sang cho lead (đó là P1.1, cần gate riêng).

**Nếu owner chọn B — builder DỪNG, mở gate backend P1.1 riêng trước** (design authority amendment → CTO authorize → migration D92 3-block + D15 re-harden → mới FE surface GV).

---

## ✅ SUCCESS CONDITION

Owner giờ trả lời được **"chính xác đang build gì?"**:
> *"P1 Master-scheduling **đã build sẵn** — không build lại. Việc còn lại là **verify production** + (tùy) 1 nav link, và **quyết P1-G7**: Teacher-Lead-create tách thành gate backend riêng (A) hay làm authority amendment ngay (B). Khuyến nghị A."*

**Endpoint: V128-P1.0 · DESIGN ONLY · STOP · 0 mutation · live audit (Supabase + Lovable HEAD) · P1-Master = ALREADY BUILT · quyết duy nhất = Gate P1-G7 (Teacher-Lead authority).**
