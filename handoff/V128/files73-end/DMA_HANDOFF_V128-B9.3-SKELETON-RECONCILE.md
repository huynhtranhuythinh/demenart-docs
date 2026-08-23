# DMA_HANDOFF_V128-B9.3-SKELETON-RECONCILE

> Retroactive reconciliation of the live Authority Resolver Phase-1 Skeleton into canonical history. Documentation only — **0 DB mutation, 0 migration, 0 FE**. Canonical rule **D367**, SYSTEM_MAP **v1.55**. Read from live DB + B9.1 artifact, never memory.

---

## 1. Status

- **Milestone:** V128-B9.3 — Authority Resolver Phase-1 Skeleton.
- **Disposition:** RECONCILE + CANONICALIZE (retroactive). NOT greenfield implementation, NOT new runtime build, NOT `child.transfer` milestone.
- **Nature:** the skeleton was **already applied live** (migration `20260815201925`) but never recorded in RULES/SYSTEM_MAP/HANDOFF — a handoff↔live drift (D112), reconciled here via read-only DB audit (evidence-first).
- **Strangler position:** Phase 1 (new governed action authorizes via resolver from birth, through an isolated probe harness; zero legacy touch). Phases 2–4 deferred.
- **Mutation this session:** **0** (audit read-only; canonicalization is documentation append only).

---

## 2. Canonical baseline (re-pinned from disk, not memory)

| Axis | Value at baseline |
|---|---|
| RULES endpoint | D366 (V128-B9.2 Authority Resolver Foundation Contract — Ratification) |
| SYSTEM_MAP | v1.54 |
| HANDOFF | V128-B9.2-CANONICAL-RATIFICATION |
| backend canonical tail | `20260815182235` |
| FE main pin | `2.8.5` |
| RULES sha256 (pre-append) | `52a2a3938274f052c4a3c7604c1629f133d4ce59bd4c4b676c1543816572cd21` |
| SYSTEM_MAP sha256 (pre-append) | `5fb90f1ce900422fb3863f4ed3ce6cf25c3394046775dbc20d6a77ab9c63b870` |

Baseline established B9.2 as **design-frozen conceptual contract, 0 implementation**; B9.3 skeleton was the deferred next gate.

---

## 3. Live discovery

- **Live migration tail:** `20260815201925` > canonical tail `20260815182235` → drift.
- **Migration:** `20260815201925` = `v128_b93_authority_resolver_skeleton` (single-statement block; source `touches_legacy_executor=false`, `touches_transition_ctrl=false` → additive-only).
- **Live objects (all additive):**
  1. `mc_internal._resolve_authority(p_actor_id uuid, p_action_key text, p_object_context jsonb, p_decision_context jsonb DEFAULT NULL) → jsonb` — SECDEF · STABLE · `search_path=''` · ACL `postgres:EXECUTE` only · md5 `56b5e3f5a14360990b51c080ff1da1cb`.
  2. `public.execute_authority_probe(p_request_id uuid, p_school_id uuid) → jsonb` — SECDEF · `search_path=''` · ACL `authenticated`+`postgres` · **only caller** of resolver.
  3. `mc_internal.authority_probe_log` — 8 cols (`id` pk · `request_id` NOT NULL UNIQUE · `actor_id` · `school_id` · `authority_source` · `eligible` · `reason_codes` jsonb · `created_at`) · RLS ON + 0 policy (deny-all except definer) · 1 row.
  4. Action registry `authority.probe` — object_type `authority` · status `active` · adapter `authority.probe.v1` · risk LOW · execution_mode `single_domain_rpc`.
- **Inventory delta vs D366:** fns 251→252 · secdef 239→240 · `mc_internal` {7→8 fn / 6→7 secdef} · +1 `mc_internal` table (public tables unchanged 94) · policies/triggers/cron unchanged (169/34/1).

---

## 4. Provenance

- Migration `20260815201925` existed live **before** this canonical reconciliation. Origin actor not independently recorded in canonical.
- **Disposition:** retroactive reconciliation — blessed into canonical history on evidence (contract-conformant + 8/8 verify matrix + legacy-isolated + hardened ACL/`search_path`).
- **No "rogue"/"unauthorized" assertion** is made — there is no evidence to support that characterization; only the drift (handoff↔live) is recorded and now reconciled (D112).
- Rollback NOT performed (skeleton is valid, dormant, zero legacy touch). Rollback recipe recorded in D367 Delta should Owner later choose to reverse.

---

## 5. Contract verification (vs B9.1 / D366 frozen contract)

| Contract dimension | B9.1 / D366 | Live skeleton | Match |
|---|---|---|---|
| Signature | `resolve_authority(actor, action_key, object_context, decision_context)` | exact, `decision_context` DEFAULT NULL | ✅ |
| Output | `{ eligible, authority_source, reason_codes }` | identical (key `eligible`, not `allowed`) | ✅ |
| Read-only | never mutates | STABLE, SELECT only | ✅ |
| Actor identity | `profiles.id` (D88) | `profiles p where p.id=p_actor_id` | ✅ |
| Self-approval precedence | before authority grant (Risk 4) | self_decision_forbidden precedes platform branch | ✅ |
| Object context | consumed, not re-resolved (B3 seam) | reads `object_context.school_id` only | ✅ |
| Vocabulary | D366.6 draft (controlled-text) | draft subset, no pg-enum | ✅ |

---

## 6. Matrix evidence (8/8 PASS · resolver-direct · 0 write)

Called `mc_internal._resolve_authority` directly (STABLE → no write; probe RPC deliberately NOT called). Identities resolved live (no guessed UUIDs).

| # | Case | Input (actor → obj / dec) | Expected | Actual | PASS |
|---|---|---|---|---|---|
| 1 | platform authority | super_admin → school KHM | true / platform_role / authority_granted | idem | ✅ |
| 2 | master same school | KHM master → school KHM | true / organization_role / authority_granted | idem | ✅ |
| 3 | master cross school | KHM master → school MNDM | false / none / organization_scope_mismatch | idem | ✅ |
| 4 | teacher deny | lead_teacher → school KHM | false / none / role_not_eligible | idem | ✅ |
| 5 | parent deny | primary_parent → school KHM | false / none / role_not_eligible | idem | ✅ |
| 6 | missing school context | master → `{}` | false / none / object_context_mismatch | idem | ✅ |
| 7 | unknown actor | random uuid → school KHM | false / none / actor_unresolved | idem | ✅ |
| 8 | self approval forbidden | master → dec{requester=self, phase=approve} | false / none / self_decision_forbidden | idem | ✅ |

Demo identities (live): platform `info@demenart.com` · master `hieutruong.kidshouse` (school `d1000000-0000-4000-8000-000000000001`) · teacher `gv.linh.kidshouse` · parent `ph.hung.kidshouse` · unknown `00000000-0000-4000-8000-0000000000ff`. Schools: KHM-DN `d1…0001`, MNDM-DN `d2…0001`.

---

## 7. Legacy isolation

- `execute_mission_control_action` md5 `09ef5f48f3318bfb53e126f3bc81d40a` **UNCHANGED** (SECURITY INVOKER · VOLATILE) — does **not** reference `_resolve_authority`.
- `mc_internal._mc_transition_decision` md5 `fe0eea599db711fb8472b37a72fa25e4` **UNCHANGED**.
- Migration source does not touch either function; resolver caller-set = `{public.execute_authority_probe}` only.
- **Residue (audit was zero-mutation):** post-matrix all 3 md5 unchanged · migration tail `20260815201925` unchanged · `authority_probe_log` 1 row unchanged (probe RPC not called) · ledger 12 (+0) · decisions 0. DML = 0.
- **Not claimed:** child.transfer complete · legacy executor migrated · authorization replaced.

---

## 8. Open decisions (RECORDED, not resolved)

| ID | Topic | Current state | Recommendation | Status |
|---|---|---|---|---|
| OD-01 | Synthetic `authority.probe` registry | action registry has object_type `authority`; object registry has no `authority` row (probe uses action registry only) | synthetic-probe-exempt | OPEN |
| OD-02 | Vocabulary | controlled documented string-set; no pg-enum | defer mint until ≥2 actions exercise | OPEN |
| OD-03 | Probe ACL | `execute_authority_probe` exposed to `authenticated` (test surface; writes only probe_log; 0 production mutation; LOW) | no hardening mutation in reconciliation | OPEN |
| OD-04 | Migration provenance | migration existed live before canonical reconciliation | retroactive reconciliation; no rogue assertion | OPEN |

---

## 9. Next milestone boundary

- B9.3 skeleton = Strangler **Phase 1** reconciled. **Deferred (NOT authorized):** Phase 2 (decision paths consume resolver) · Phase 3 (adapter authority-policy migration) · Phase 4 (legacy RPC migration) · enum/taxonomy mint · `UNIQUE(user_id)` enforcement · delegation · object-scope expansion (`child.transfer`, session/school) · multi-approver/quorum · notification · inbox UI · HIGH/CRITICAL activation.
- **STOP condition:** do not open B9.4 · do not design `child.transfer` · do not apply migration. Await explicit Owner next-milestone authorization.

---

## Boot pointer (next session)

Read canonical directly (never memory): `DMA_RULES.md` (→ **D367**) · `DMA_SYSTEM_MAP.md` (→ **v1.55**) · this handoff · B9.1 freeze artifact. Endpoint to re-pin: **RULES D367 · SYSTEM_MAP v1.55 · HANDOFF V128-B9.3-SKELETON-RECONCILE · backend tail `20260815201925` · FE main pin `2.8.5`.** Authority Resolver = Phase-1 skeleton, exercised via probe harness only; production governed actions do NOT yet consume the verdict. Block D366/v1.54 (B9.2) = HISTORICAL SNAPSHOT (BẤT BIẾN).
