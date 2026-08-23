# DMA_V128_B6_2 — M3 PREMISE CONFLICT · CTO DECISION REQUIRED

> **Trạng thái:** ⛔ **STOP** — Builder dừng trước khi viết M3 production migration draft.
> **Lý do:** conflict giữa design premise (mọi doc B6.2) và live runtime, phát hiện ở STEP 0 (M0 capture).
> **Rule tuân thủ:** "Nếu phát hiện conflict giữa design và live runtime: STOP và báo CTO."
> **Ngày:** 2026-08-14 (GMT+7) · 0 mutation đã thực hiện.

---

## 1. FINDING (concrete, definitive)

Live ACL của `mission_control_action_requests`:
```
relacl = postgres=arwdDxtm/postgres | authenticated=ar/postgres
has_table_privilege('authenticated', ledger, 'UPDATE') = FALSE
has_table_privilege('anon',          ledger, 'UPDATE') = FALSE
has_table_privilege('service_role',  ledger, 'UPDATE') = FALSE
```
`authenticated` chỉ có **INSERT + SELECT**. **Không role client nào UPDATE được ledger.**

Đồng thời ledger có **5 completed + 3 failed** rows (bắt buộc ghi bằng UPDATE) → chỉ `postgres` có UPDATE → các row đó ghi dưới **role postgres** (impersonation set JWT-claim, không `SET ROLE authenticated` — hazard D2/D3). Không row nào ghi dưới `authenticated` thật.

---

## 2. HAI HỆ QUẢ (chắc chắn theo INVOKER semantics)

### Hệ quả A — Forge §E.4 KHÔNG exploitable
Toàn bộ chuỗi B6.2 (spec → plan → migration-design → SQL-design) dựng trên tiền đề B6.1.5 §E.4: *"finish_own cho client forge completed/failed/result_payload qua PostgREST."* **Sai với live:** `authenticated` thiếu base UPDATE privilege → PostgREST PATCH bị permission-denied trước cả khi RLS chạy. `finish_own` là **dead policy**. Decision #7 (execution integrity hardening) đang giải quyết một lỗ hổng **không tồn tại trên runtime**.

### Hệ quả B — `execute` finalize BROKEN dưới authenticated thật (nghiêm trọng hơn)
`execute` = INVOKER → chạy dưới role caller = `authenticated`. Thân hàm finalize bằng:
```sql
update public.mission_control_action_requests set status='completed', ... where id = v_request_pk;
```
`authenticated` không có UPDATE → **permission denied** → exception. Trong success-branch, exception rơi vào `when others` → `MC_ACTION_EXECUTION_FAILED` → rơi tiếp xuống failure-branch UPDATE (ngoài block) → **permission denied lần nữa, uncaught** → function 500 → **PostgREST rollback toàn transaction** (class_distribution + audit đã tạo cũng bị revert).

→ **class.assign KHÔNG THỂ complete dưới một real authenticated login.** Nó chỉ "chạy" khi execute được gọi dưới role postgres (SQL editor / partial-impersonation). B6.1.5 "runtime-verified" thực chất verified dưới postgres-context, **không** phải real login — mâu thuẫn D2/D3.

---

## 3. IMPACT LÊN B6.2

| Artifact | Ảnh hưởng |
|---|---|
| **M3 "byte-identical"** | **Vô hiệu như phát biểu.** PATH B chuyển finalize vào `_mc_commit_action` (DEFINER/postgres) → UPDATE chạy → **fixes** finalize. Đây là **behavior change (broken→working) dưới authenticated**, không byte-identical. Byte-identical chỉ đúng dưới postgres-context. |
| **Decision #7 rationale** | Forge không exploitable → drop `finish_own` chỉ là **hygiene**, không phải "đóng forge". Giá trị thật của M3 = **sửa finalize**, không phải chống forge. |
| **Regression criterion** | "class.assign unchanged" mơ hồ: unchanged dưới role nào? Dưới authenticated hiện đang **broken**; M3 đổi nó. **Real-login regression (D2/D3) thành hard-gate bắt buộc**, và nó sẽ cho thấy broken→fixed, KHÔNG identical. |
| **B6.1.5 verification claim** | "runtime-verified" cần đính chính: verified dưới postgres-context, chưa dưới real authenticated. |
| **M1 / M2** | **Không ảnh hưởng** (additive, dormant). Có thể tiến bình thường. |

---

## 4. OPTIONS (Builder recommendation ★)

### ★ Option 1 — Reframe M3 là governance + finalize-correctness fix (recommend)
- Giữ **PATH B nguyên** (nó chính là fix đúng: DEFINER commit-core finalize).
- **Đổi acceptance criterion** M3: từ "byte-identical" → *"byte-identical dưới postgres-context **AND** newly-correct dưới authenticated (real-login PASS bắt buộc)"*.
- Đính chính rationale #7: drop `finish_own` = hygiene (dead policy cleanup), không phải forge-closure.
- **Không** đổi architecture. Chỉ đổi cách mô tả + acceptance + thêm real-login hard-gate.
- Ưu: 1 migration, PATH B đã đúng, sửa luôn bug. Nhược: milestone giờ mang cả "fix", cần ghi nhận minh bạch.

### Option 2 — Tách "finalize fix" thành pre-req riêng, rồi mới governance
- M-pre: chuyển finalize sang privileged path (fix bug) độc lập, real-login verify.
- Sau đó M1–M5 governance layer lên trên nền đã đúng.
- Ưu: tách bạch "fix" vs "governance", audit sạch. Nhược: thêm migration + thêm 1 apply-session.

### Option 3 — GRANT UPDATE cho authenticated (KHÔNG recommend)
- Làm finalize dưới authenticated chạy được **mà không** đổi execute.
- Nhược nghiêm trọng: **kích hoạt** `finish_own` → **forge trở thành thật** (đúng cái §E.4 lo). Đi ngược PATH B. **Loại.**

---

## 5. CÂU HỎI CHO CTO

1. **Chọn Option 1 (★) / 2 / 3?** Tức B6.2 có chính thức bao gồm "finalize-correctness fix" không?
2. **Acceptance criterion M3:** chấp nhận thay "byte-identical" bằng "byte-identical postgres-context + newly-correct authenticated (real-login hard-gate)"?
3. **Đính chính premise:** cho phép Builder ghi note đính chính "forge §E.4 không exploitable / finalize broken under authenticated" vào các doc B6.2 trước đó (khi canonicalize sau này)?
4. **B6.1.5 verification:** có cần re-verify/đính chính claim "runtime-verified" của B6.1.5 (verified postgres-context, chưa real-login)?

---

## 6. NHỮNG GÌ KHÔNG BỊ CHẶN

- **M0 capture** đã hoàn tất (`DMA_V128_B6_2_M0_LIVE_CAPTURE.md`) — chính xác, dùng được.
- **M1 (schema foundation)** + **M2 (evaluator)** additive/dormant → không phụ thuộc conflict này, có thể authorize độc lập nếu CTO muốn.
- **M3 production SQL draft / regression plan / rollback plan** → **HELD** cho tới khi CTO chốt §5, vì premise của chúng (byte-identical, forge-closure) vừa đổi.

---

## 7. RISK NẾU BỎ QUA FINDING

Nếu viết M3 draft theo premise cũ và apply:
- Verify "byte-identical" bằng SQL-editor (postgres) sẽ **PASS giả** (cả trước lẫn sau đều chạy dưới postgres) → **che mất** sự thật rằng M3 đổi hành vi real-user.
- Không có real-login gate → có thể ship mà không biết mình vừa sửa (hoặc phá) một live path chưa từng verified đúng cách.
- Governance layer dựng trên narrative sai (chống forge) → audit/canonical ghi sai bản chất milestone.

→ Vì vậy Builder **STOP** và escalate thay vì tiếp tục. Chờ CTO decision cho §5.

---

**0 mutation. 0 apply. 0 canonical. Production M3 draft chưa viết — chờ Owner/CTO Gate sau khi resolve conflict.**
