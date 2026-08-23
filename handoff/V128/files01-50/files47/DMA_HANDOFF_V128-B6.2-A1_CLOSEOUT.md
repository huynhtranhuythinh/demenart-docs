# 🗂️ DMA_HANDOFF_V128-B6.2-A1_CLOSEOUT.md — LEDGER FINALIZATION BOUNDARY · PRODUCTION CLOSEOUT

> **Ngày:** 2026-08-14 (GMT+7) · **Loại:** Production hardening APPLIED + canonical closeout · **Verdict: A1 LIVE — G4 (ledger forge) CLOSED.**
> **Boot phiên sau:** file này → `DMA_RULES.md` (tip **D359**) → `DMA_SYSTEM_MAP.md` (**v1.47**) → audit live DB (D1) → re-pin.
> **Endpoint:** RULES **D359** · SYSTEM_MAP **v1.47** · HANDOFF **V128-B6.2-A1** · backend migration tail **`20260814114948`** (`v128_b6_2_a1_ledger_finalization_boundary`) · FE main pin `2.8.5` (0 FE change).

---

## A. OBJECTIVE

Governance Execution Integrity Hardening (**scope A1 only**, Owner-gated). Chuyển terminal-finalization của Mission Control action ledger (`mission_control_action_requests`) từ **client-writable** (forge-completed khả dĩ qua PostgREST — RULES D358.9.4 / gap G4) sang **server-owned internal finalization boundary**, trong khi GIỮ:

- `execute_mission_control_action` = SECURITY INVOKER + public contract bất biến.
- `assign_class_distribution` = definition + grants bất biến (School Portal direct path unchanged).
- Không FE change · không migration khác · không G4b/G3/G1/generic-dispatch.

---

## B. PRODUCTION IMPLEMENTATION

Một migration atomic: `v128_b6_2_a1_ledger_finalization_boundary` · tail **`20260814114948`** · VERIFY guard trong body (RAISE → full rollback). One-shot authorization CONSUMED.

1. **New internal schema `mc_internal`** — `CREATE SCHEMA` (fail-closed, no IF NOT EXISTS) · REVOKE ALL PUBLIC · GRANT USAGE `authenticated` · **unexposed PostgREST** (Owner-verified manual gate).

2. **New finalization boundary `mc_internal._mc_commit_action(uuid, jsonb)`**
   - SECURITY DEFINER · owner `postgres` · `search_path=''`.
   - **completed-only** ledger finalization (`status='completed'` + server-generated `result_payload` + `error_code=null` + `completed_at=now()`).
   - Derive actor internally (`current_profile()`, không nhận `actor_id`); validate ownership (`processing` ∧ `actor_id=derived`, `FOR UPDATE`).
   - **KHÔNG** call adapter · **KHÔNG** dispatch · **KHÔNG** derive business result.
   - ACL: EXECUTE `{authenticated, postgres}`, 0 anon/PUBLIC.

3. **Updated `public.execute_mission_control_action(...)`** (CREATE OR REPLACE)
   - Remains **INVOKER** · `search_path=''` · public contract (signature + return envelope) BẤT BIẾN.
   - Keeps calling `assign_class_distribution` trực tiếp (authenticated EXECUTE giữ).
   - Delegates ledger finalization → `mc_internal._mc_commit_action`.
   - β2 subtransaction (`BEGIN…EXCEPTION`) bọc INSERT-processing + adapter + commit-core.
   - ACL re-hardened sau REPLACE (D231): EXECUTE `{authenticated, postgres}`, 0 anon/PUBLIC/service_role.

4. **Ledger ownership hardening**
   - DROP policy `mission_control_action_requests_finish_own`.
   - REVOKE `authenticated` column-UPDATE trên `{status, result_payload, error_code, completed_at}`.
   - Client CÒN: INSERT own-`processing` + SELECT own.

5. **Invariant preserved** — `assign_class_distribution` definition + grants UNCHANGED; School Portal direct path (`school.manage.tsx` `ClassSubjectsPanel.handleAssign`) UNCHANGED.

---

## C. SECURITY MODEL

**Hai boundary:**
- **Execution orchestration** = `execute` (INVOKER): validation · adapter invocation · evidence build · idempotency claim. KHÔNG own terminal privilege.
- **Finalization privilege** = `mc_internal._mc_commit_action` (DEFINER/postgres): sole writer của terminal ledger state; completed-only; reachable chỉ qua `execute`.

**Ledger ownership (post-A1):**

| Role | INSERT processing | SELECT own | UPDATE terminal |
|---|---|---|---|
| `authenticated` | ✅ | ✅ | ❌ REVOKED |
| commit-core (DEFINER postgres) | — | — | ✅ completed-only |

**G4 (forge-completed) = CLOSED.** Client không còn đường ghi terminal state; "completed + result_payload" server-authoritative. Nested DEFINER giữ `auth.uid()` → `assign_class_distribution` + `current_profile()` vẫn chấm end-user (không escalate). `is_admin()` + role/school scope = authority boundary vận hành (unchanged); context authz slot NO-OP (D352.5).

**Failure model (β2, completed-only):** adapter fail → commit-core không gọi → subtransaction rollback → no orphan processing, no `failed` persistence → client `{ok:false, error_code}` graceful (không RPC exception). `failed` lifecycle schema-compatible nhưng UNUSED (không remove support).

---

## D. QA EVIDENCE (provenance-split — KHÔNG suy diễn)

**PASS — in-session structural (tool-logged):**
- Migration atomic apply.
- `execute` posture: `prosecdef=false` · `search_path=""`.
- commit-core posture: `prosecdef=true` · owner postgres · `search_path=""`.
- `authenticated` cannot UPDATE ledger terminal columns (col-grant `[]`).
- `finish_own` removed (ledger còn `insert_own_processing` + `select_own`).
- commit-core ACL: authenticated=yes · anon=no · PUBLIC=no.
- schema USAGE: authenticated=yes · anon=no.
- `assign_class_distribution` EXECUTE `authenticated` UNCHANGED.

**PASS — Owner-attested (real-login UI):**
- Mission Control `class.assign` works.
- `class_distribution` created.
- audit event `CLASS_ASSIGNMENT_CREATED` created.
- Memory projection updated.
- UI prevents duplicate program assignment.

---

## E. KNOWN NON-TESTED ITEMS (KHÔNG claim PASS)

- **Replay idempotency** — chưa verify runtime.
- **Backend conflict injection** — chưa verify runtime.

**Lý do:** chưa có authenticated QA harness cho direct-RPC replay/conflict injection. Ghi tường minh là **QA debt**; **KHÔNG** được đánh dấu PASS ở bất kỳ canonical nào.

---

## F. ROLLBACK STATUS

**Reversible — rollback verbatim đã capture:**

```
DROP FUNCTION mc_internal._mc_commit_action(uuid,jsonb);
DROP SCHEMA mc_internal;
-- CREATE OR REPLACE public.execute_mission_control_action(...) ← body pre-A1 (self-finalize:
--   INSERT processing OUTSIDE block; success→UPDATE completed; failure→UPDATE failed)
--   + re-harden ACL {authenticated,postgres}
CREATE POLICY mission_control_action_requests_finish_own
  ON public.mission_control_action_requests FOR UPDATE TO authenticated
  USING  ((actor_id = (select public.current_profile())) AND status = 'processing')
  WITH CHECK ((actor_id = (select public.current_profile()))
              AND status = ANY (ARRAY['completed','failed'])
              AND completed_at IS NOT NULL AND result_payload IS NOT NULL
              AND ((status='completed' AND error_code IS NULL)
                   OR (status='failed' AND error_code IS NOT NULL)));
GRANT UPDATE (status, result_payload, error_code, completed_at)
  ON public.mission_control_action_requests TO authenticated;
NOTIFY pgrst, 'reload schema';
```

Pre-apply state: policies 169 · tail `20260813113400` · no `mc_internal`.

**Rehearsal record:** rollback-safe `BEGIN…VERIFY…ROLLBACK` rehearsal PASS (0 persist); probe xác nhận `execute_sql` tôn trọng transaction control trước khi chạy destructive DDL.

---

## G. QA FIXTURE (additive, deterministic — cho H9, chưa cleanup)

- **school** `b6a4ac35-2e0a-4667-9eea-756f615c29eb` (Trường Demo Dế Mèn — demo, không phải khách thật).
- **class** `eeeeeeee-0000-4000-8000-000000000005` ("B6.2 QA Test Class", active).
- **program** `eeeeeeee-0000-4000-8000-0000000000a5` ("B6.2 QA Test Program", slug `b62-qa-test-program`).
- **entitlement** `eeeeeeee-0000-4000-8000-0000000000e5` (active, end_date null).
- **KHÔNG** distribution. Cleanup DELETE 4 row khi close QA.

---

## H. NEXT GATE RECOMMENDATION

1. **QA harness cho replay/conflict (đóng E)** — dựng authenticated direct-RPC test (real-login hoặc JWT-impersonation) để verify: same-request_id success replay (`replayed=true`), in-progress conflict (`MC_ACTION_REQUEST_IN_PROGRESS`), mismatch (`MC_ACTION_REQUEST_CONFLICT`), forge-denied (PostgREST UPDATE ledger→completed = permission denied). Owner Gate riêng.
2. **G4b + School Portal unification** (đề xuất milestone riêng, KHÔNG nhét vào hardening) — hợp nhất `school.manage.tsx handleAssign` onto MC action framework để một write path audited/idempotent duy nhất, rồi mới REVOKE direct-adapter EXECUTE. FE + contract change.
3. **G1/G2/G3/G5/G6** (registry-authority · adapter-seam · intent-fingerprint · generic-renderer · memory single-domain) — vẫn DEFERRED, mỗi cái Owner Gate riêng.
4. **QA fixture cleanup** — DELETE 4 seed row (§G) sau khi close H9.

---

**Canonical Endpoint:** RULES **D359** · SYSTEM_MAP **v1.47** · HANDOFF **V128-B6.2-A1** · backend tail `20260814114948` · FE main pin `2.8.5`. Khối B6.1.5 (D358/v1.46) = HISTORICAL SNAPSHOT.
