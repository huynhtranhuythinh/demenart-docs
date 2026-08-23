# DMA HANDOFF — V128-B9.3 · AUTHORITY RESOLVER SKELETON RECONCILIATION

**Milestone:** V128-B9.3 — Phase-1 Authority Resolver **skeleton**, canonical reconciliation of an already-applied live implementation.
**Mode:** DOCUMENTATION-ONLY · CANONICAL APPEND-ONLY · **0 SQL · 0 migration · 0 DB mutation · 0 FE · 0 UI** in this canonicalization.
**Date:** 2026-08-16
**Endpoint (canonical):** RULES **D367** · SYSTEM_MAP **v1.55** · HANDOFF **V128-B9.3-SKELETON-RECONCILE** · backend tail **`20260815201925`** · FE main pin `2.8.5`

---

## 1 · Status

✅ **RECONCILED (governance).** Live implementation `v128_b93_authority_resolver_skeleton` (migration `20260815201925`) reconciled into canonical after a READ-ONLY live↔canonical audit. Canonical documentation now matches live state. **No mutation performed by this reconciliation.** B9.4 NOT opened. `child.transfer` NOT implemented. No enum/taxonomy minted. No legacy executor migrated.

## 2 · Objective

Bring canonical governance (RULES/SYSTEM_MAP/HANDOFF) into agreement with a live B9.3 skeleton migration that had already landed on the database, after verifying — by direct live audit, not memory — that the implementation conforms to the D366/B9.1 Authority Resolver contract, is isolated from the legacy executor, and introduces no unexplained drift.

## 3 · Canonical baseline (before reconciliation)

| Item | Value |
|---|---|
| RULES endpoint | D366 (D366.1–.8) |
| SYSTEM_MAP endpoint | v1.54 |
| HANDOFF endpoint | V128-B9.2-CANONICAL-RATIFICATION |
| Backend canonical tail | `20260815182235` (`v128_b8_i1_decision_lifecycle_foundation`) |
| D366.8 status of B9.3 | **deferred — await CTO authorization** |
| Inventory baseline (D366, public application) | tables 94 · fns 251 · secdef 239 · policies 169 · triggers 34 · cron 1 · `mc_internal` {7 fn / 6 secdef} |

Baseline re-pinned by direct read of canonical files at session start (endpoints matched → proceeded).

## 4 · Live reconciliation (delta accepted)

Backend tail advanced `20260815182235 → 20260815201925` (exactly one migration ahead, none interleaved).

| Metric | Canonical | Live | Δ | Attribution |
|---|---|---|---|---|
| tables (public) | 94 | 94 | 0 | log table is in `mc_internal` |
| fns (public) | 251 | 252 | +1 | `execute_authority_probe` |
| secdef (public) | 239 | 240 | +1 | probe (SECDEF) |
| policies | 169 | 169 | 0 | — |
| cron | 1 | 1 | 0 | — |
| mc_internal fn | 7 | 8 | +1 | `_resolve_authority` |
| mc_internal secdef | 6 | 7 | +1 | resolver (SECDEF) |
| triggers (public) | 34 | 34 | 0 | B9.3 added 0 triggers |
| triggers (all-schema) | — | 40 | +6 | system triggers — see §9 |

Every delta is fully explained by the B9.3 skeleton (2 fn + 1 table + 1 registry row). No residue.

## 5 · Migration provenance

| Field | Value |
|---|---|
| version | `20260815201925` |
| name | `v128_b93_authority_resolver_skeleton` |
| position | live tail; one ahead of D366 baseline `20260815182235`; no interleaving migration |
| structure | D92 three-block: DDL → ACL (D15/D231) → VERIFY (fail-closed `RAISE`) + `NOTIFY pgrst` |
| objects created | table `mc_internal.authority_probe_log` · fn `mc_internal._resolve_authority` · fn `public.execute_authority_probe` · registry INSERT `authority/authority.probe` |
| CREATE TRIGGER | **0** (confirmed from source body) |
| legacy touch | **0** (no ALTER/REPLACE of any executor) |

Charter match: "resolver authorizes one *new* governed action end-to-end, zero legacy touch."

## 6 · Technical verification

**Resolver** `mc_internal._resolve_authority(uuid,text,jsonb,jsonb)` — md5 `56b5e3f5a14360990b51c080ff1da1cb` · **STABLE** · SECURITY DEFINER · `search_path=''` · ACL **postgres:EXECUTE only** (no anon/authenticated leak).

**Probe** `public.execute_authority_probe(uuid,uuid)` — md5 `59e7c5d4a8d1dda25d9466500da82d13` · **VOLATILE** (has audit INSERT) · SECURITY DEFINER · `search_path=''` · ACL **authenticated + postgres**.

**Log** `mc_internal.authority_probe_log` — RLS **ON** · **0 policy** · grants revoked from PUBLIC/anon/authenticated/service_role → fail-closed, definer-mediated writes only. Columns (8): `id, request_id (unique), actor_id, school_id, authority_source, eligible, reason_codes (jsonb), created_at`.

**Registry** `authority/authority.probe` — capability `authority.probe` · adapter `authority.probe.v1` · status `active` · risk `LOW` · mode `single_domain_rpc` · audit `authority.probe.executed` · required_context `{keys:[school_id], types:{school_id:uuid}, exclusive:true}`.

**Caller graph** — `_resolve_authority` called only by `execute_authority_probe`; probe has no in-DB caller (client-facing RPC). VERIFY block in migration is fail-closed (determinism probe + hardening + leak checks + `RAISE`).

## 7 · Contract conformance (vs D366.1/.4) — PASS

Resolver **OWNS**: authority policy verdict · eligibility · authority_source · reason_codes.
Resolver does **NOT own**: domain mutation (STABLE, SELECT-only on `profiles`, zero write) · RLS enforcement · adapter effects · lifecycle mutation · executor replacement.

Non-blocking observation: skeleton does not yet branch on `p_action_key` (policy currently decides by role + `object_context.school_id`); acceptable for a single-action skeleton, logged as open item (§11c), not a contract violation. No enum/taxonomy minted.

## 8 · Legacy isolation — PASS

| Fn | md5 | refs resolver / probe / log |
|---|---|---|
| `public.execute_mission_control_action` | `09ef5f48f3318bfb53e126f3bc81d40a` | false / false / false |
| `mc_internal._mc_transition_decision` | `fe0eea599db711fb8472b37a72fa25e4` | false / false / false |

Both UNCHANGED and reference no authority object. Resolver does not replace the legacy executor; B8 lifecycle mutation boundary intact; governed legacy path remains dormant.

## 9 · Trigger anomaly resolution — Category B (existing-but-missing-from-inventory)

Discovery showed triggers 34 → 40 (+6). **Resolved as a counting-scope mismatch — not drift, not rogue.** Canonical "triggers 34" counts **public-schema application triggers**; the live figure (40) counted all schemas. Breakdown: **public 34** (matches baseline exactly) · cron 1 · realtime 1 · storage 4. The +6 are **Supabase-managed system triggers** (`cron.job`, `realtime.subscription`, `storage.buckets`×2, `storage.objects`×2), pre-existing since extension provisioning, never part of the DMA inventory. **B9.3 created 0 triggers.** Convention ratified (D367.7): DMA trigger inventory = **public-schema only**.

## 10 · Authorization provenance

Owner operational authorization sequence is recorded as execution provenance. Canonical reconciliation does not claim external signature or independent approval artifact.

(Specifically: after the read-only audit, Owner issued decision **A — Canonicalize B9.3**. This handoff records that operational decision as execution provenance only; it does not assert any external signature or independent approval artifact exists.)

## 11 · Open decisions (deferred — NOT authorized here)

a. `authority_source` enum + `reason_code` taxonomy mint — post-B9.3 evidence (D366.6/D367.8).
b. `UNIQUE(user_id)` enforcement — after reconciliation pass (re-verify duplicates=0 + D93 invite/link non-breakage).
c. `p_action_key` policy-branching when resolver serves more than one action.
d. Strangler Phase 3–4 legacy authority-site migration (≈51 `is_admin` / ≈29 hardcoded `master/sub_admin` / ≈18 `same_school`).
e. HIGH/CRITICAL activation · delegation · object-scope expansion (`child.transfer`, session/school) · multi-approver/quorum · notification · inbox UI.

## 12 · Next gate

**B9.4 / first production governed action.** NOT opened. Standing discipline: hard STOP at authorized scope boundary; await explicit CTO authorization before any B9.4 implementation, SQL, migration, or FE work. Do not start B9.4. Do not implement `child.transfer`. No new implementation.

---

## Boot pointer (next session)

Read canonical directly (never memory): `DMA_RULES.md` (→ **D367**) · `DMA_SYSTEM_MAP.md` (→ **v1.55**) · this handoff. Re-pin endpoint: RULES **D367** · SYSTEM_MAP **v1.55** · HANDOFF **V128-B9.3-SKELETON-RECONCILE** · backend tail `20260815201925` · FE main pin `2.8.5`. Then audit live DB (D1) before any work. Authority Resolver = skeleton live (probe harness active); **do not open B9.4 / any new implementation** — await CTO decision. Block D366/v1.54 (B9.2) = HISTORICAL SNAPSHOT (BẤT BIẾN).
