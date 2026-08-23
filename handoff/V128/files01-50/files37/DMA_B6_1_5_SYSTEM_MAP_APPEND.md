<!-- ============================================================= -->
<!-- ARTIFACT 2 — APPEND-ONLY BLOCK for DMA_SYSTEM_MAP.md          -->
<!-- Paste VERBATIM at the END of DMA_SYSTEM_MAP.md.               -->
<!-- Current-state topology only. No B6.2 future state.           -->
<!-- Version v1.46 = RECOMMENDED, pending Owner confirmation.      -->
<!-- NOTE for Owner: top-of-file CURRENT CANONICAL ENDPOINT block  -->
<!-- (line ~9) still reads D356/v1.44/B3.3 and is stale; bumping   -->
<!-- it to D358/v1.46/B6.1.5 is a separate top-block edit for      -->
<!-- Owner to authorize (not part of this append).                -->
<!-- ============================================================= -->

---

## 🧭 V128-B6.1.5 · MISSION CONTROL ACTION LAYER — FOUNDATION TOPOLOGY (canonical reconciliation) — v1.46 (2026-08-14)

> **Endpoint:** RULES **D358** · SYSTEM_MAP **v1.46** · HANDOFF **V128-B6.1.5** · backend tail **`20260813113400`** · FE main pin `@lovable.dev/vite-tanstack-config = 2.8.5`. Khối B6.1-Task-5.2 (v1.45) phía trên = HISTORICAL SNAPSHOT.
> **Bản chất:** Reconciliation-only. Bản đồ hoá Action Foundation **đã sống trong live** (backend Aug-13 + FE Aug-14), chưa canonical hoá. **Chỉ current state** — KHÔNG intent fingerprint, KHÔNG generic adapter framework, KHÔNG action engine mới (những thứ đó thuộc B6.2).

### Topology (LIVE, object type `class`)

```
Object Workspace            get_object_workspace / get_mission_control_workspace   (context seam D349–D356)
        ↓
Context Resolution          resolve_mission_control_object_context
                            validate_mission_control_object_context(_match)
        ↓
Action Registry             mission_control_action_registry  ──► get_available_actions / get_mission_control_actions
        ↓                   (registry-driven discovery, status='active' per object_type)
Action Execution Boundary   execute_mission_control_action   (SECURITY INVOKER · search_path='' · server-owned validation)
        ↓                   dispatch = literal `if action_key == 'class.assign'`  (proto, chưa generic)
Domain Adapter              assign_class_distribution        (SECURITY DEFINER · authz+entitlement+insert)
        ↓
Audit Event                 write_audit_log ──► audit_logs   (action='CLASS_ASSIGNMENT_CREATED', class_id, actor, metadata)
        ↓
Memory Projection           get_mission_control_memory       (đọc audit_logs theo class_id, map→summary, cursor paginate)

Ledger (cross-cut)          mission_control_action_requests  (request_id idempotency · lifecycle received/processing→completed/failed)
Admin roll-up               get_admin_action_center
```

### Objects mới (vs B3.3 skeleton)

| Table | Vai trò | RLS |
|---|---|---|
| `mission_control_action_registry` | Descriptor catalog (action_key, label, capability, risk_level, audit_event, status, metadata). 2 active: `class.assign`, `class.edit`. | ON |
| `mission_control_action_requests` | Action request ledger (request_id, status, result_payload, error_code, actor_id, created/started/completed_at). 3 policy own-scoped. | ON |

### Function surface (action layer, live)

- `execute_mission_control_action(text,uuid,jsonb,jsonb,uuid)` — execution boundary (INVOKER).
- `assign_class_distribution(uuid,uuid,uuid)` — class.assign domain executor (DEFINER) → `class_distributions` + `write_audit_log`.
- `get_available_actions(text,uuid,jsonb)` — registry-driven discovery (context-match gated).
- `get_mission_control_actions(text,uuid)` — action listing.
- `get_mission_control_memory(text,uuid,int,timestamptz)` — memory projection over `audit_logs` (class-only).
- `get_mission_control_workspace(text,uuid)` — action-aware workspace read.
- `get_admin_action_center()` — admin action roll-up.
- Helpers: `audit_action_category(text)`, `dma_assignable_teacher_reason(uuid,uuid)`, `dma_assignment_evidence_grade(text)`, `validate_mission_control_object_context_match(text,uuid,jsonb)`, `resolve_mission_control_object_context(text,uuid)`, `request_sensitive_access(uuid,text,text,text)`.

### Inventory (reconciled-to-live)

**`92 tables · 248 functions · 236 SECURITY DEFINER · 169 policies · 33 triggers · 1 cron`** · migration tail **`20260813113400`**.
(Δ vs D357 historical snapshot 90/241/230/166/33/1: +2 tables · +7 fn · +6 secdef · +3 policies via 8 migration Aug-13.)

### Authority boundary (unchanged)

`is_admin()` + role/school scope (`current_profile_role ∈ {master_admin,sub_admin} ∧ school ∈ user_school_ids()`) là boundary vận hành cho action execute/memory. Context authz slot (D352.5) vẫn NO-OP. MC admin-axis ⟂ teaching/session-axis (D355.6).

### Known foundation gaps (DEFERRED → B6.2; xem RULES D358.9)

Registry authority chưa enforce (class.edit advertised, execute reject) · dispatch literal (no `adapter_key`) · no intent fingerprint · ledger INVOKER (`finish_own` cho client set result_payload) · FE class-specific · memory single-domain. **KHÔNG thiết kế ở đây.**
