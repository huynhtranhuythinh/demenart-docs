# 🗂️ DMA_HANDOFF_V128-B6.2-A2_CLOSEOUT.md — LEDGER FINALIZATION BOUNDARY · RUNTIME QA CLOSEOUT

> **Ngày:** 2026-08-14 (GMT+7) · **Loại:** QA-only runtime verification + canonical closeout (0 migration / 0 schema / 0 code).
> **Boot phiên sau:** file này → `DMA_RULES.md` (tip **D360**) → `DMA_SYSTEM_MAP.md` (**v1.48**) → audit live DB (D1) → re-pin.
> **Endpoint:** RULES **D360** · SYSTEM_MAP **v1.48** · HANDOFF **V128-B6.2-A2** · backend migration tail **`20260814114948`** (BẤT BIẾN từ D359) · FE main pin `2.8.5`.

---

## 1. STATUS

**CLOSED.** Toàn bộ runtime QA cho ledger finalization boundary (A1/D359) PASS. Hai mục "NOT VERIFIED" của D359 (replay idempotency · backend conflict injection) nay **runtime-VERIFIED**; forge-denied negative-verified. **G4 (ledger forge) runtime-proven**, không chỉ structural.

---

## 2. OBJECTIVE

Chứng minh runtime ba invariant đã hardened ở A1 (D359), **không** thay đổi schema/code:
- **Replay safety** — same request_id → idempotent, single side effect.
- **Conflict handling** — new request + existing business object → β2 rollback-only, no duplicate, no orphan.
- **Ledger integrity** — client (authenticated) không thể forge terminal state (INV-B62-A1-02).

---

## 3. RUNTIME QA EVIDENCE TABLE

| QA | Result | Evidence |
|---|---|---|
| **QA-1 Replay** | **PASS** | request `ec486402…` · exec1 `{ok:true,replayed:false}` + distribution `2a40a52f…` + ledger completed server-side · replay `{ok:true,replayed:true}` same distribution · replay Δ side-effect = 0 (ledger/dist/audit bất biến) — stored-result replay, no side effect |
| **QA-2 Conflict** | **PASS** | request MỚI `69286344…` · existing distribution → `distribution_exists` → `{ok:false, MC_ACTION_CONFLICT}` graceful · ledger rows for request = 0 · processing orphan = 0 · no `failed` persist · distribution 21→21 · audit 15→15 — MC_ACTION_CONFLICT, rollback-only |
| **QA-3 Forge** | **PASS** | target `ec486402…` · authenticated (master.demo) direct `UPDATE` → `ERROR 42501 permission denied for table` (grant layer) · row immutable (forged payload absent) · audit Δ 0 — permission denied |

**Method:** JWT-impersonation actor thật (master.demo, master_admin @ Trường Demo Dế Mèn, profile `2fee5a07…`, jwt sub `5396961a…`) + `SET LOCAL ROLE authenticated` / `RESET ROLE`. Captures đọc as postgres (true totals). Real auth path — không SQL-superuser bypass.

---

## 4. PERSISTED QA FIXTURE STATE

**⚠️ NO cleanup performed.** Các artifact sau **vẫn tồn tại** trong production:

- **Fixture seed** (school `b6a4ac35`, Trường Demo Dế Mèn — demo, không phải khách thật):
  - class `eeeeeeee-0000-4000-8000-000000000005` ("B6.2 QA Test Class", active)
  - program `eeeeeeee-0000-4000-8000-0000000000a5` ("B6.2 QA Test Program")
  - entitlement `eeeeeeee-0000-4000-8000-0000000000e5` (active)
- **QA runtime artifact:**
  - **distribution `2a40a52f-6991-4093-ae89-6273f0e733c5`** (active — fixture distribution remains)
  - ledger row `ec486402…` (status completed)
  - +1 audit `CLASS_ASSIGNMENT_CREATED`
- QA-2 request_ids (`10025b81`, `69286344`) — KHÔNG để lại dấu vết (đúng β2).

**Cleanup requires Owner Gate.** Không thực hiện implicit cleanup.

---

## 5. NEXT ALLOWED ACTION

- **Cleanup = OPTIONAL**, chỉ khi Owner Gate mở. Nếu chọn cleanup:
  ```sql
  DELETE FROM public.class_distributions WHERE id='2a40a52f-6991-4093-ae89-6273f0e733c5';
  DELETE FROM public.mission_control_action_requests WHERE request_id='ec486402-e06e-4bd3-bead-49e51cf7987c';
  DELETE FROM public.school_subject_entitlements WHERE id='eeeeeeee-0000-4000-8000-0000000000e5';
  DELETE FROM public.classes WHERE id='eeeeeeee-0000-4000-8000-000000000005';
  DELETE FROM public.programs WHERE id='eeeeeeee-0000-4000-8000-0000000000a5';
  ```
  *(Lưu ý: audit event lịch sử KHÔNG xóa — append-only audit.)*
- **NO implicit cleanup** — Builder không tự dọn.
- Các milestone kế (G4b School Portal unification · G1/G2/G3 · generic renderer) — mỗi cái Owner Gate riêng, không thuộc A2.

---

## STRUCTURAL STATE (BẤT BIẾN từ A1/D359)

Inventory **92 · 248 · 236 · 168 · 33 · 1** · migration tail `20260814114948`. A2 = QA-only: 0 schema, 0 migration, 0 code, 0 FE. Chỉ QA DATA persisted (§4).

**Canonical Endpoint:** RULES **D360** · SYSTEM_MAP **v1.48** · HANDOFF **V128-B6.2-A2** · backend tail `20260814114948` · FE main pin `2.8.5`. Khối A1 (D359/v1.47) = HISTORICAL SNAPSHOT (BẤT BIẾN).
