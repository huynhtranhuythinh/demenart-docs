---

## 🗺️ SYSTEM_MAP v1.55 — CURRENT CANONICAL ENDPOINT (2026-08-16)

> **Bump v1.54 → v1.55.** Khối v1.54 (B9.2 Authority Contract Ratification) phía trên = HISTORICAL SNAPSHOT (BẤT BIẾN). Khối này là authority DUY NHẤT về hiện trạng.
> **Reconciliation-only:** phản ánh live migration `20260815201925` (`v128_b93_authority_resolver_skeleton`) đã applied. **Không claim production migration mới; 0 DB mutation trong việc canonicalize này.**

### Endpoint
- RULES **D367** · SYSTEM_MAP **v1.55** · HANDOFF **V128-B9.3-SKELETON-RECONCILE**
- Backend tail: **`20260815201925`** (`v128_b93_authority_resolver_skeleton`)
- FE main pin: `2.8.5`
- Inventory (public application): tables **94** · fns **252** · secdef **240** · policies **169** · triggers **34** (public-only; all-schema=40 gồm 6 system trigger cron/realtime/storage — xem D367.7) · cron **1**
- `mc_internal`: **8 fn / 7 secdef**

### Authority Resolver — runtime relationship (NEW)
**Current state:**
- **Probe harness ACTIVE.** `authority.probe` (LOW) = governed action MỚI, dispatchable, single-domain RPC. Đường đi runtime: client (authenticated) → `public.execute_authority_probe(request_id, school_id)` → registry lookup (`mc_internal._mc_lookup_action`) → `mc_internal._resolve_authority(actor, 'authority.probe', {school_id}, null)` → verdict `{eligible, authority_source, reason_codes}` → nếu eligible: append `mc_internal.authority_probe_log` (definer-mediated, on-conflict-do-nothing theo `request_id`) → return.
- Resolver = internal-only (ACL postgres); probe = sole consumer.

**Future (deferred — KHÔNG active):**
- Governed action adoption (Strangler Phase 3–4): các action mới → decision paths → adapter policy → legacy admin RPC migration. HIGH/CRITICAL activation, delegation, object-scope expansion (`child.transfer`, session/school), multi-approver/quorum — tất cả deferred.

### Authority Resolver — boundary (canonical, D366.4/D367.4)
**Resolver OWNS:**
- authority policy verdict
- eligibility
- authority_source
- reason codes

**Resolver does NOT own:**
- domain mutation
- RLS enforcement
- lifecycle mutation (`_mc_transition_decision` — B8 boundary — nguyên vẹn)
- adapter effects / domain-safety invariants

### Legacy isolation (unchanged)
- `public.execute_mission_control_action` (md5 `09ef5f48…`) — UNCHANGED, không reference authority objects.
- `mc_internal._mc_transition_decision` (md5 `fe0eea59…`) — UNCHANGED, không reference authority objects.
- Governed legacy path dormant (class.assign MEDIUM → auto), như v1.54.

### Vocabulary status
- `authority_source` / `reason_code` = DRAFT candidates (D366.6 / D367.8). **NOT minted** thành enum/CHECK/taxonomy. Final mint deferred post-B9.3 evidence.

### Next gate
- **B9.4 / first production governed action** — chưa mở. Await explicit CTO authorization.
