# ✅ V128-P1.0B — CANCELLED SESSION UX CORRECTION · IMPLEMENTATION REPORT

> **Owner decision:** Option A — APPROVED. Scope: read-contract correction (2 read RPC) + FE lifecycle UX.
> **Backend:** applied + verified (live impersonation). **FE:** paste-mode blocks ready (5 files). **0 authority/RLS/schema/lifecycle change.**

---

## 1 · MIGRATION IDENTIFIER

```
20260825015243_v128_p1_0b_teacher_read_contract_cancelled
```
- D92 3-block: DDL → REVOKE/GRANT → VERIFY (RAISE-guard, atomic).
- D15: `REVOKE ALL … FROM PUBLIC` + `GRANT EXECUTE … TO authenticated, service_role` cho cả 2 fn.
- D289: `notify pgrst, 'reload schema'`.
- In-migration VERIFY passed (fn có `cancel_reason`; classes fn không còn filter `<> 'cancelled'`).

**Changes (read-only):**
- `get_teacher_classes_in_school` — bỏ `and ls.state<>'cancelled'`; thêm `'cancel_reason', ls.cancel_reason`.
- `get_teacher_session_workspace` — thêm `'cancel_reason', v_cancel_reason` vào session object (var + SELECT + return).

---

## 2 · BACKEND VERIFICATION (live impersonation — read-only)

Đóng vai GV **Lê Thảo My** (`gv.my.kidshouse`), JWT-impersonation transaction-local:

| Điều kiện owner-gate | Kết quả |
|---|---|
| 1. Cancelled xuất hiện trong `get_teacher_classes_in_school` | ✅ 3 buổi cancelled hiện: "Hoàn tất QA S0A", "QA regression E2-02", "GV nghỉ ốm" |
| 2. `cancel_reason` được trả về (schedule) | ✅ Có, đúng giá trị mỗi buổi |
| 3. `get_teacher_session_workspace` trả `state='cancelled'` + `cancel_reason` | ✅ `state='cancelled'`, `cancel_reason='GV nghỉ ốm'`, key present=true |

→ **Backend PASS. Được phép sang FE.** (Ghi chú: đã có sẵn 1 buổi cancelled reason "QA kiểm tra vòng đời huỷ buổi" từ QA-4 vòng trước — dùng lại được để QA nhanh.)

---

## 3 · FRONTEND — PASTE-MODE BLOCKS (5 files)

> Paste byte-exact. Sau mỗi paste, verify bằng `read_file` (D8: ký tự `<` cuối dòng có thể rớt).

### 📄 File 1 — `src/features/teacher/teacherTokens.ts`
**FIND:**
```ts
    case "makeup":
      return { label: "Học bù", bg: T.peachSurface, color: "#8A4632" };
    default:
      return { label: "Sắp diễn ra", bg: T.mint, color: T.ink2 };
```
**REPLACE:**
```ts
    case "makeup":
      return { label: "Học bù", bg: T.peachSurface, color: "#8A4632" };
    case "cancelled":
      return { label: "Đã huỷ", bg: T.peachSurface, color: T.peachText };
    default:
      return { label: "Sắp diễn ra", bg: T.mint, color: T.ink2 };
```

### 📄 File 2 — `src/features/teacher/teacherWorkspace.ts`
**FIND:**
```ts
  lesson_version_id: string | null;
  child_count: number;
```
**REPLACE:**
```ts
  lesson_version_id: string | null;
  cancel_reason: string | null;
  child_count: number;
```

### 📄 File 3 — `src/features/teacher/useTeacherSchedule.ts`
**3a — FIND:**
```ts
export type ScheduleSession = {
  id: string;
  title: string | null;
  scheduled_at: string | null;
  state: string;
  class_name: string | null;
  program_name: string | null;
};

type SessionRow = { id: string; title: string | null; scheduled_at: string | null; state: string };
```
**REPLACE:**
```ts
export type ScheduleSession = {
  id: string;
  title: string | null;
  scheduled_at: string | null;
  state: string;
  cancel_reason: string | null;
  class_name: string | null;
  program_name: string | null;
};

type SessionRow = { id: string; title: string | null; scheduled_at: string | null; state: string; cancel_reason: string | null };
```
**3b — FIND:**
```ts
        flat.push({
          id: s.id,
          title: s.title,
          scheduled_at: s.scheduled_at,
          state: s.state,
          class_name: c.class_name,
          program_name: c.program_name,
        });
```
**REPLACE:**
```ts
        flat.push({
          id: s.id,
          title: s.title,
          scheduled_at: s.scheduled_at,
          state: s.state,
          cancel_reason: s.cancel_reason,
          class_name: c.class_name,
          program_name: c.program_name,
        });
```

### 📄 File 4 — `src/routes/_authenticated/teacher.session.$id.tsx`
**4a — FIND:**
```ts
  class_name: string | null;
  program_name: string | null;
  child_count: number;
  readiness?: Readiness;
};
```
**REPLACE:**
```ts
  class_name: string | null;
  program_name: string | null;
  cancel_reason: string | null;
  child_count: number;
  readiness?: Readiness;
};
```
**4b — FIND:**
```ts
  const s = detail.session;

  return (
    <div className="space-y-5">
      <SessionTopBar />
```
**REPLACE:**
```ts
  const s = detail.session;

  if (s.state === "cancelled") {
    return <CancelledSessionView session={s} />;
  }

  return (
    <div className="space-y-5">
      <SessionTopBar />
```
**4c — thêm component** (paste ngay TRƯỚC `function BackLink() {`):
```tsx
function CancelledSessionView({ session }: { session: SessionInfo }) {
  return (
    <div className="space-y-5">
      <SessionTopBar />
      <div
        className="rounded-[20px] px-4 py-5"
        style={{ backgroundColor: T.peachSurface, border: `1px solid ${T.error}33` }}
      >
        <div className="flex items-start gap-2.5">
          <AlertCircle
            className="mt-0.5 h-[22px] w-[22px] shrink-0"
            style={{ color: T.error }}
            aria-hidden
          />
          <div className="min-w-0">
            <p className="text-[18px] font-semibold" style={{ color: T.ink }}>
              Buổi học đã huỷ
            </p>
            <p className="mt-1 text-[15px]" style={{ color: T.ink2 }}>
              {session.class_name ?? "Lớp"}
              {session.title ? ` · ${session.title}` : ""}
            </p>
            <p
              className="mt-0.5 inline-flex items-center gap-1.5 text-[14px]"
              style={{ color: T.muted }}
            >
              <Clock className="h-4 w-4" aria-hidden /> {fmtTimeVN(session.scheduled_at)}
            </p>
            {session.cancel_reason && (
              <div
                className="mt-3 rounded-xl px-3 py-2.5"
                style={{ backgroundColor: T.surface, border: `1px solid ${T.border}` }}
              >
                <p className="text-[13px] font-semibold" style={{ color: T.ink2 }}>
                  Lý do huỷ
                </p>
                <p className="mt-0.5 text-[15px]" style={{ color: T.ink }}>
                  {session.cancel_reason}
                </p>
              </div>
            )}
            <p className="mt-3 text-[14px]" style={{ color: T.muted }}>
              Buổi học này đã được nhà trường huỷ. Cô không cần chuẩn bị hay dạy buổi này.
            </p>
            <Link
              to="/teacher/schedule"
              className={`mt-4 inline-flex min-h-[44px] items-center gap-1.5 rounded-xl px-4 text-sm font-semibold ${focusRing}`}
              style={{ backgroundColor: T.primary, color: "#fff" }}
            >
              <ChevronLeft className="h-4 w-4" aria-hidden /> Về lịch dạy
            </Link>
          </div>
        </div>
      </div>
    </div>
  );
}
```
*(Tất cả symbol dùng — `T`, `AlertCircle`, `Clock`, `fmtTimeVN`, `Link`, `ChevronLeft`, `focusRing`, `SessionTopBar` — đều đã import sẵn trong file. Không thêm import → không drift.)*

### 📄 File 5 — `src/routes/_authenticated/teacher.schedule.tsx`
**FIND** (trong `DaySection`, block `.map`):
```tsx
        {group.sessions.map((s) => {
          const meta = sessionStateLabel(s.state);
          return (
            <li key={s.id}>
              <Link
                to="/teacher/session/$id"
                params={{ id: s.id }}
                className={`flex items-center gap-3 rounded-xl px-3 py-2.5 transition-colors hover:bg-[#F0F7F3] ${focusRing}`}
              >
```
**REPLACE:**
```tsx
        {group.sessions.map((s) => {
          const meta = sessionStateLabel(s.state);
          if (s.state === "cancelled") {
            return (
              <li key={s.id}>
                <div
                  aria-disabled="true"
                  className="flex items-center gap-3 rounded-xl px-3 py-2.5 opacity-70"
                  style={{ backgroundColor: T.surface }}
                >
                  <span
                    className="w-[52px] shrink-0 text-[13px] font-medium line-through"
                    style={{ color: T.muted }}
                  >
                    {fmtTimeVN(s.scheduled_at)}
                  </span>
                  <span
                    className="shrink-0 rounded-full px-2 py-0.5 text-[13px]"
                    style={{ backgroundColor: meta.bg, color: meta.color }}
                  >
                    {meta.label}
                  </span>
                  <span className="min-w-0 flex-1">
                    <span
                      className="block truncate text-[15px] line-through"
                      style={{ color: T.ink2 }}
                    >
                      {s.class_name ?? "Lớp"}
                    </span>
                    <span className="block truncate text-[13px]" style={{ color: T.muted }}>
                      {s.cancel_reason ? `Lý do: ${s.cancel_reason}` : s.title ?? "Buổi học"}
                    </span>
                  </span>
                </div>
              </li>
            );
          }
          return (
            <li key={s.id}>
              <Link
                to="/teacher/session/$id"
                params={{ id: s.id }}
                className={`flex items-center gap-3 rounded-xl px-3 py-2.5 transition-colors hover:bg-[#F0F7F3] ${focusRing}`}
              >
```
*(Chỉ thêm nhánh cancelled ở đầu; phần Link active giữ NGUYÊN — đóng ngoặc `.map` và `</li>` phía dưới không đổi.)*

---

## 4 · BEFORE / AFTER UX

| Bề mặt | Before | After |
|---|---|---|
| `/teacher/session/$id` (cancelled) | Step "Chuẩn bị" + "Bắt đầu buổi học", nhãn "Sắp diễn ra" | Màn "Buổi học đã huỷ" + lý do + "Về lịch dạy". Stepper/CTA tắt hẳn. |
| `/teacher/schedule` (sau huỷ) | Buổi biến mất | Buổi vẫn hiện — badge "Đã huỷ", lý do, gạch ngang, non-actionable (div, không Link) |
| Nhãn state cancelled | "Sắp diễn ra" (sai) | "Đã huỷ" |

Invariants: **Cancel ≠ Delete · History ≠ Active · Visibility ≠ Authority · backend state = UI truth.**

---

## 5 · QA RESULTS

**Backend (Claude, done):** ✅ VERIFY PASS (mục 2).
**UI QA-1…QA-6 (owner-run, sau khi paste + deploy):**

| QA | Bước | Kỳ vọng |
|---|---|---|
| 1 | Master (`hieutruong.kidshouse` / `Test@123`) tạo buổi tương lai ở `/school/schedule` | Buổi hiện lịch |
| 2 | GV (`gv.my.kidshouse` / `Test@123`) mở `/teacher/schedule` | Buổi "Sắp diễn ra" |
| 3 | GV mở chi tiết buổi | Vòng dạy 4 bước bình thường |
| 4 | Master huỷ buổi, lý do **"QA kiểm tra vòng đời huỷ buổi"** | Huỷ thành công |
| 5 | GV **refresh** chi tiết buổi vừa huỷ | "Buổi học đã huỷ" + lý do + workflow disabled |
| 6 | GV mở `/teacher/schedule` | Buổi còn đó, "Đã huỷ" + lý do, không bấm được |

*(Có thể QA nhanh không cần tạo mới: buổi cancelled sẵn có "GV nghỉ ốm" của lớp GV Lê Thảo My đã đủ verify màn detail + lịch.)*

Tài khoản test (kèm mật khẩu, khỏi tra):
- Master KHM: `hieutruong.kidshouse` · `Test@123`
- GV Lê Thảo My: `gv.my.kidshouse` · `Test@123`

---

## 6 · BOUNDARY CONFIRMATION / DIFF PURITY

- ✅ **Không** đụng `cancel_lesson_session` / `create_lesson_session` / `update_lesson_session` / `set_session_teachers` / authority / role / RLS / permissions / schema / lifecycle semantics.
- ✅ Backend = read-contract only (bỏ 1 filter hiển thị + thêm 1 cột output); ACL re-hardened (D15).
- ✅ FE = 5 file đúng scope; **không** thêm import mới; **không** đụng `package.json` / `bun.lock` / route khác / migration khác / file Supabase khác.
- ⚠️ Sau khi paste FE: chạy `get_diff` + `read_file package.json` + `read_file bun.lock` xác nhận 0 pin-drift (D134) trước deploy.

---

## 🏁 FINAL STATUS: **READY FOR OWNER QA**

Backend applied + verified. FE 5 block paste-mode sẵn sàng. Owner: paste 5 file → deploy → chạy QA-1…QA-6.

**Endpoint: V128-P1.0B · migration `20260825015243` · backend VERIFY PASS · FE paste-ready · 0 forbidden drift.**
