# 🧩 V128-P1.0B — CANCELLED SESSION UX CORRECTION REPORT

> **Mode:** CONTROLLED UX CORRECTION · EXISTING LIFECYCLE ONLY · Role = Frontend Builder / Lifecycle UX Correction
> **Grounding:** live audit read-only — Lovable repo HEAD (5 files) + Supabase RPC bodies (`xcvhacymrbhdhohyylyq`). 0 mutation applied.
> **Final status:** 🔴 **BLOCKED** — read contract chưa expose `cancelled` + `cancel_reason` đủ. Cần owner authorize **1 chỉnh read-contract nhỏ** (2 read RPC) trước khi build. **Không chế FE workaround** (đúng ràng buộc mode).

---

## 1 · ROOT CAUSE

### BUG 1 — Teacher session detail vẫn "active" sau khi huỷ
`/teacher/session/$id` (`SessionFlow`) đọc qua `fetchTeacherWorkspace` → `get_teacher_session_workspace`. Contract **có trả `session.state`** (kể cả `'cancelled'`). Nhưng FE **không hề special-case `cancelled`**:

```ts
function stepForState(state: string): number {
  if (state === "in_progress") return 2;
  if (state === "taught_report_pending" || state === "report_pending_approval") return 4;
  if (state === "completed") return 4;
  return 1; // scheduled / prep_ready / makeup / cancelled  ← 'cancelled' rơi vào đây
}
```
→ `cancelled` → step **1** → render **`StepPrep`** kèm nút **"Bắt đầu buổi học"** (`start_session`). Vòng dạy vẫn mở.

Và nhãn **"Sắp diễn ra"** anh thấy đến từ `sessionStateLabel` — **không có case `cancelled`** nên rơi vào `default: "Sắp diễn ra"`:
```ts
default: return { label: "Sắp diễn ra", bg: T.mint, color: T.ink2 };
```

**Root cause BUG 1 = FE không phân biệt `cancelled`.** State CÓ trong contract → phần "disable workflow" sửa được FE-only. Riêng **`cancel_reason` KHÔNG có** trong contract detail.

### BUG 2 — Cancelled biến mất khỏi `/teacher/schedule`
`useTeacherSchedule` → `get_teacher_classes_in_school`. **Backend RPC loại thẳng cancelled**:
```sql
from public.lesson_sessions ls
where ls.class_distribution_id = d.cd_id and ls.state <> 'cancelled'   -- ← loại ở BACKEND
```
Và session object **không select `cancel_reason`** (chỉ `id,title,scheduled_at,state`).

**Root cause BUG 2 = backend read-contract loại trừ cancelled** (không phải filter FE). → **Không thể sửa FE-only.**

---

## 2 · READ-CONTRACT FINDINGS (điểm quyết định STOP/GO)

| Cần | Detail `get_teacher_session_workspace` | Schedule `get_teacher_classes_in_school` |
|---|---|---|
| `state = 'cancelled'` xuất hiện? | ✅ Có (trả `state` trung thực) | ❌ **Bị loại** (`state<>'cancelled'`) |
| `cancel_reason` có trong contract? | ❌ Không select | ❌ Không select |
| Session cancelled có được trả về? | ✅ Có (fetch theo id, mọi state) | ❌ Không |

**Kết luận:** contract **chưa đủ** → theo mode: **STOP + báo cáo smallest read-contract correction**, cấm FE workaround. Cả hai là **read RPC** (SECURITY DEFINER, gate không đổi) — chỉnh **chỉ ở tầng read/presentation**, KHÔNG đụng authority/RLS/permission/schema/`cancel_lesson_session`.

---

## 3 · SMALLEST REQUIRED CORRECTION (đề xuất — CHƯA áp)

### 🔧 Backend (2 read RPC — cần owner authorize; áp qua migration D92 3-block + D15 re-grant + D289 notify)

**A. `get_teacher_classes_in_school`** — bỏ filter loại cancelled + thêm reason (BUG 2):
```sql
-- TRƯỚC:
'sessions',(select coalesce(jsonb_agg(jsonb_build_object(
   'id',ls.id,'title',ls.title,'scheduled_at',ls.scheduled_at,'state',ls.state)
   order by ls.scheduled_at desc nulls last,ls.id desc),'[]'::jsonb)
 from public.lesson_sessions ls
 where ls.class_distribution_id=d.cd_id and ls.state<>'cancelled')
-- SAU:
'sessions',(select coalesce(jsonb_agg(jsonb_build_object(
   'id',ls.id,'title',ls.title,'scheduled_at',ls.scheduled_at,'state',ls.state,
   'cancel_reason',ls.cancel_reason)
   order by ls.scheduled_at desc nulls last,ls.id desc),'[]'::jsonb)
 from public.lesson_sessions ls
 where ls.class_distribution_id=d.cd_id)          -- ⬅ bỏ 'and ls.state<>cancelled'
```

**B. `get_teacher_session_workspace`** — thêm `cancel_reason` vào session object (BUG 1 reason; *optional* theo spec "if available", khuyến nghị có):
- Thêm var `v_cancel_reason text;` + select `ls.cancel_reason` ở SELECT đầu.
- Thêm `'cancel_reason', v_cancel_reason` vào object `session` trả về.

> Cả A & B: `CREATE OR REPLACE` → **bắt buộc D15** (REVOKE/GRANT lại: `authenticated, service_role`), **D289** `notify pgrst, 'reload schema'`, gói **D92** (DDL→GRANT→VERIFY). Gate authz (`is_teacher_in_school` / assignment check) **giữ nguyên** — 0 thay đổi quyền.

### 🎨 Frontend (paste-mode; áp SAU khi backend deploy để có field)

1. **`teacherTokens.ts` · `sessionStateLabel`** — thêm case:
```ts
case "cancelled":
  return { label: "Đã huỷ", bg: T.peachSurface, color: T.peachText };
```
2. **`teacherWorkspace.ts` · `WorkspaceSession`** — thêm `cancel_reason: string | null;`
3. **`teacher.session.$id.tsx`**:
   - `SessionInfo` thêm `cancel_reason: string | null;`
   - Trong `SessionFlow`, sau `const s = detail.session;`: **early-return** khi `s.state === "cancelled"` → render `CancelledView` (thông điệp "Buổi học đã huỷ" + `cancel_reason` nếu có + link **"Về lịch dạy" → `/teacher/schedule`**). **KHÔNG** render stepper/StepPrep, **KHÔNG** "Bắt đầu buổi học". No mutation.
4. **`useTeacherSchedule.ts`** — `ScheduleSession` + `SessionRow` thêm `cancel_reason: string | null;` map xuyên qua.
5. **`teacher.schedule.tsx` · `DaySection`** — với `s.state === "cancelled"`: render **item KHÔNG phải `<Link>`** (non-actionable), badge **"Đã huỷ"**, hiện reason, style mờ/gạch — không mở vòng dạy. Session active vẫn là `<Link>`.

**Thứ tự bắt buộc:** Backend trước → FE sau (FE trước thì BUG 2 vẫn trống vì RPC còn loại cancelled).

---

## 4 · UX BEHAVIOR — BEFORE / AFTER

| Bề mặt | Before (bug) | After (target) |
|---|---|---|
| `/teacher/session/$id` khi cancelled | Step 1 "Chuẩn bị" + "Bắt đầu buổi học" (nhãn "Sắp diễn ra") | Màn "Buổi học đã huỷ" + lý do (nếu có) + "Về lịch dạy". Vòng dạy tắt. |
| `/teacher/schedule` sau huỷ | Buổi **biến mất** hoàn toàn | Buổi **vẫn hiện** — badge "Đã huỷ" + lý do, non-actionable |
| Nhãn state cancelled | "Sắp diễn ra" (sai) | "Đã huỷ" |

Invariants giữ đúng: **Cancel ≠ Delete · History ≠ Active · Visibility ≠ Authority · State phản ánh backend truth**.

---

## 5 · VALIDATION RESULTS

⏸ **Chưa chạy được** — QA-1…QA-6 sẽ thực thi **sau khi** correction được authorize + áp. Kế hoạch bám đúng script boot:
- QA-1..3: Master tạo buổi tương lai → GV thấy "Sắp diễn ra" → mở detail (đang OK, đã PASS ở P1.0).
- QA-4: Master huỷ, lý do "QA kiểm tra vòng đời huỷ buổi".
- QA-5: refresh detail GV → **kỳ vọng**: hiện "Đã huỷ" + lý do, workflow disabled.
- QA-6: `/teacher/schedule` → **kỳ vọng**: buổi còn đó, "Đã huỷ" + lý do, không bấm vào vòng dạy được.

---

## 6 · BOUNDARY CONFIRMATION

- ✅ Không đụng `cancel_lesson_session`, scheduling authority, RLS, permission model, database schema.
- ✅ 2 chỉnh backend **chỉ ở read-contract** (bỏ 1 filter hiển thị + thêm 1 cột output); gate authz nguyên vẹn; re-harden ACL theo D15.
- ✅ FE thuần presentation; **no mutation from Teacher side**.
- ⚠️ Vì có chạm 2 SECURITY DEFINER read RPC → **cần owner authorization** (invariant "no backend change without CTO auth" + publish-workflow "hỏi trước khi đụng Supabase"). Đây đúng là STOP-condition mà mode đã nêu.

---

## ✅ FINAL STATUS: 🔴 BLOCKED — chờ 1 quyết định của owner

Read contract teacher **chưa expose** `cancelled` (schedule) + `cancel_reason` (cả hai). Theo mode, em dừng và báo smallest correction thay vì chế workaround.

**Owner authorize gì:**
> Cho phép áp **2 chỉnh read-contract** (`get_teacher_classes_in_school`: bỏ filter cancelled + thêm `cancel_reason`; `get_teacher_session_workspace`: thêm `cancel_reason`) qua migration (D92 3-block · D15 re-grant · D289 notify) — **read-only, 0 authority/RLS/schema change** — rồi em áp FE paste-mode (5 file trên) và chạy QA-1…QA-6.

Anh **"go"** thì em: (1) áp migration read-contract + VERIFY, (2) đưa block paste FE byte-exact, (3) chạy QA. Nếu anh muốn **bỏ hiển thị lý do** để khỏi đụng backend detail (B), em có thể chỉ chỉnh `get_teacher_classes_in_school` (BUG 2 buộc phải có) + FE — nhưng BUG 2 **không thể** FE-only.

**Endpoint: V128-P1.0B · AUDIT DONE · 0 mutation · BLOCKED pending owner authorization of read-contract correction.**
