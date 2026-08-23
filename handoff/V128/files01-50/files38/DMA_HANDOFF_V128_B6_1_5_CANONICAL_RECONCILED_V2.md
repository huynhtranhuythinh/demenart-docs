# 🗂️ DMA_HANDOFF_V128_B6_1_5.md — MISSION CONTROL ACTION FOUNDATION · CANONICAL RECONCILIATION — CLOSED

> **Ngày:** 2026-08-14 (GMT+7) · **Loại:** Canonical reconciliation (documentation-only) · **Verdict: DRIFT CLOSED ở tài liệu — 0 mutation.** KHÔNG build, KHÔNG migration, KHÔNG FE change.
> **Boot phiên sau:** file này → `DMA_RULES.md` (tip **D358**, sau merge) → `DMA_SYSTEM_MAP.md` (**v1.46**, sau merge) → audit live DB (D1) → re-pin FE HEAD accepted tip (Owner-confirmed).
> **Trạng thái:** CANONICAL RECONCILIATION CLOSED. **DO NOT authorize B6.2.** D358 / v1.46 endpoint accepted. FE accepted tip remains pending Owner confirmation.

---

## A. OBJECTIVE — vì sao reconciliation tồn tại

STEP 0 baseline audit của **V128-B6.2** phát hiện **canonical drift nghiêm trọng**: cả backend lẫn FE runtime đều **vượt** canonical on-disk. Toàn bộ **Mission Control Action Foundation** (execute RPC · ledger · registry · domain adapter · memory · FE action lifecycle) **đã sống trong production** nhưng **chưa có D-rule/handoff block nào** — canonical dừng ở D357/v1.45 (B6.1 Task 5.2, một FE fix `request_id`, tự khai backend "BẤT BIẾN tail Aug-12 90/241/230").

Milestone **V128-B6.1.5** đưa governance truth về đúng runtime **TRƯỚC** khi mở B6.2, thoả boot-protocol §5 + D1 (audit thật, đừng để library tụt phiên). Đây **KHÔNG** phải build phase.

---

## B. RUNTIME BASELINE (LIVE — audit read-only, nguồn sự thật)

- **Migration tail:** `20260813113400`.
- **Batch Aug-13 (8 migration, chưa canonical trước block này):** `20260813060038 · 060208 · 060625 · 063444 · 073711 · 073937 · 113248 · 113400`.
- **DB inventory (live):** **92 tables · 248 functions · 236 SECURITY DEFINER · 169 policies · 33 triggers · 1 cron.**
  - Δ vs D357 snapshot (90/241/230/166/33/1): **+2 tables · +7 fn · +6 secdef · +3 policies**; triggers/cron bất biến.
- **FE state (main):** hook `src/features/mission-control/class/hooks/useAssignClassAction.ts` chứa `lastIntentRef` + `submitLockRef` + `successNonce` + request_id forwarding (adapter `missionControlAdapter.executeAction` 1:1). FE main đã **vượt** canonical FE HEAD `e1c2ea8f` (các edit Aug-14: "Updated 4 MC files with code", "Replaced useClassAssign hook", "Added submit lock to class").
- **Package pin:** `@lovable.dev/vite-tanstack-config = 2.8.5` (exact, main) · build gate `scripts/assert-tooling-governance.mjs` present.
- **⚠️ FE HEAD accepted tip = CẦN OWNER XÁC NHẬN.** `list_edits` trả thứ tự lineage nhập nhằng (hazard D338: sandbox git ≠ lineage). Quan sát chắc chắn: main hiện tại có pin `2.8.5` + hook lifecycle Aug-14. Ứng viên tip: `e1c2ea8f` (canonical cũ) vs successor Aug-14 (`3435c609`/`b04e8fa7`/`f42a08f0`/`1f824b8e`). **Owner chốt tip deploy chính thức khi merge.**

---

## C. IMPLEMENTED FOUNDATION (chỉ cái ĐANG TỒN TẠI)

- **Action Registry** (`mission_control_action_registry`, RLS ON) — descriptor catalog registry-driven. 2 action active: `class.assign` (MEDIUM, audit `CLASS_ASSIGNMENT_CREATED`) · `class.edit` (LOW, audit `CLASS_UPDATED`). Discovery `get_available_actions` đọc registry sau context-match.
- **Action Request Ledger** (`mission_control_action_requests`, RLS ON, 3 policy own-scoped) — idempotency theo `request_id` (safe replay), lifecycle `processing → completed/failed`, `result_payload`/`error_code`/timestamps server-written trong execute RPC.
- **Execution Boundary** (`execute_mission_control_action`, SECURITY INVOKER, `search_path=''`) — server-owned validation gates (auth · profile · dispatch · input/context shape · school-match), dispatch literal `class.assign`, map domain-exception → `MC_ACTION_*`.
- **Domain Adapter — class.assign** (`assign_class_distribution`, SECURITY DEFINER) — authz (`is_admin ∨ master/sub_admin+school`) · entitlement · teacher-valid · dup-guard · INSERT `class_distributions` · `write_audit_log`.
- **Memory** (`get_mission_control_memory`, class-only) — projection trên `audit_logs` theo `class_id`, cursor pagination, map `CLASS_ASSIGNMENT_CREATED`→"Assigned <program>".
- **Admin roll-up** (`get_admin_action_center`).
- **FE lifecycle** — success auto-close (`successNonce`) · stale-reopen protection · duplicate-submit protection (`submitLockRef`) · conflict handling (business-failure giữ request identity) · request_id intent lifecycle (`lastIntentRef`, D357).

---

## D. B6.1 STATUS

**B6.1 runtime slice = CLOSED (runtime-verified, reconciled).** Action Foundation cho object `class` đã live + FE lifecycle wired. Block D358 (RULES) + v1.46 (SYSTEM_MAP) canonical hoá slice này. **Không reopen B6.1.**

*(Ghi chú: D357 = B6.1 Task 5.2 (FE request_id fix) đã canonical trước; D358 bổ sung phần foundation còn thiếu. Chronology inversion đã ghi rõ trong D358 header — foundation build straddle D357 nhưng documented sau, do append-only.)*

---

## E. DEFERRED TO V128-B6.2 (tường minh — KHÔNG làm ở đây)

1. **Registry authority enforcement** — execute phải tôn trọng registry (active/capability/object_type/adapter availability); đóng mismatch `class.edit` advertised nhưng execute reject.
2. **Adapter dispatch seam** — thay literal `if action_key == 'class.assign'` bằng `adapter_key → adapter registry → domain adapter`.
3. **Intent fingerprint** — `fingerprint = hash(actor, action_key, object_id, context, input)`; same request_id + fingerprint khác → `MC_ACTION_INTENT_MISMATCH`.
4. **Ledger ownership hardening** — chặn client tự set completed/failed/result_payload (execute INVOKER + policy `finish_own` hiện cho forge qua PostgREST).
5. **Generic action descriptor** — thêm `execution_mode/priority/group/availability/disabled_reason/required_context/input_schema/output_schema/adapter_key` vào registry.
6. **FE generic action renderer** — Workspace → Descriptor → Renderer → Execution Controller → Result Memory (thay drawer + `useAssignClassAction` class-specific); loading separation; error taxonomy.
7. **Advanced QA gates** — security matrix (cross-school execute, disabled direct-execute, forged ledger), execution-integrity matrix, B6.1 regression.

*(Ba debt B3.3 — `subscription`/`support_case`/`privacy_request`, D356.13 — vẫn registered-unwired, ngoài phạm vi.)*

---

## F. GOVERNANCE NOTE

Handoff này **chỉ reconcile trạng thái runtime đang tồn tại**. Nó **KHÔNG authorize B6.2 implementation**. 0 mutation đã thực hiện (DB/RPC/RLS/FE/Edge/Bunny đều intact). Merge = Owner append 3 artifact vào canonical + chốt numbering (D358 / v1.46 / V128-B6.1.5, recommended) + xác nhận FE HEAD accepted tip. B6.2 mở bằng một Owner Gate riêng **sau** khi merge xong.

**Canonical Endpoint:** RULES **D358** · SYSTEM_MAP **v1.46** · HANDOFF **V128-B6.1.5** · backend tail `20260813113400` · FE main pin `2.8.5`. FE accepted HEAD tip remains pending Owner confirmation.
