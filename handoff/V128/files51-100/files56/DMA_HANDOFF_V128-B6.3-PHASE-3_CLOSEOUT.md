# DMA_HANDOFF_V128-B6.3-PHASE-3_CLOSEOUT — INTENT INTEGRITY (MILESTONE CLOSED)

> **Endpoint:** RULES **D363** · SYSTEM_MAP **v1.51** · HANDOFF **V128-B6.3-PHASE-3** · backend tail **`20260815101138`** (`v128_b6_3_p3_intent_integrity`) · FE main pin `@lovable.dev/vite-tanstack-config = 2.8.5` (0 FE).
> **Disposition:** **V128-B6.3 milestone CLOSED — Owner-stamped 2026-08-15.**
> **Basis:** live DB read-only audit (project `xcvhacymrbhdhohyylyq`), real function bodies verified — không reconstruct từ memory.

---

## 0 · Milestone status

V128-B6.3 "Action Control Plane Foundation" — **CLOSED**. Three phases applied and closed:
- Phase 1 (D361 / v1.49 / tail `20260815080313`) — Registry Authority Foundation.
- Phase 2 (D362 / v1.50 / tail `20260815085223`) — Adapter Resolver Cutover (G1+G2 CLOSED).
- Phase 3 (D363 / v1.51 / tail `20260815101138`) — Intent Integrity (G3 CLOSED).

**Gap disposition (FINAL): G1 · G2 · G3 · G4 — all CLOSED.** 8/8 frozen invariants hold.

---

## 1 · What Phase 3 changed

**Intent fingerprint forge** — new `mc_internal._mc_begin_action` (SECURITY DEFINER, `search_path=''`):
- Actor via `public.current_profile()` (null → `raise actor_unresolved`).
- Canonical intent v1 = `{"v":1,"action_key","object_type","object_id","context":{"school_id"},"input":{"program_id","lead_teacher_id"}}`.
- `intent_fingerprint = encode(extensions.digest(convert_to(canonical::text,'UTF8'),'sha256'),'hex')`; `intent_hash_version = 1`.
- INSERT `status='processing'` … `ON CONFLICT (request_id) DO NOTHING RETURNING id`; returns `{inserted, intent_hash_version, intent_fingerprint}`.
- **Sole ledger INSERT owner.**

**Ledger schema** — `mission_control_action_requests` gains `intent_fingerprint text` (nullable) + `intent_hash_version smallint` (nullable), no default.

**Client write closure** — authenticated INSERT revoked; ledger INSERT policy dropped (policies 168→167); grants now SELECT-only (policy `mission_control_action_requests_select_own`). INSERT/UPDATE/DELETE all false.

**execute replay guard** — on `request_id` reuse (`inserted=false`): recompute fp; verify existing row structural-triple (action_key/object_type/object_id) + `intent_fingerprint IS NOT NULL` + `intent_hash_version=1` + `existing.intent_fingerprint = recomputed`; mismatch → `MC_ACTION_REQUEST_CONFLICT`; in-flight → `MC_ACTION_REQUEST_IN_PROGRESS` (`replayed:true`); terminal → stored `result_payload` + `replayed:true`.

---

## 2 · Live evidence (read-only, this session)

- **Migration tail:** `20260815101138` (`v128_b6_3_p3_intent_integrity`).
- **`mc_internal`:** 3 fn / 3 secdef — `_mc_begin_action` (`f47260ef…`, NEW), `_mc_commit_action` (`ce36c5fe…`, frozen), `_mc_lookup_action` (`5d940037…`, frozen). All `search_path=''`.
- **execute:** SECURITY INVOKER (`execute_secdef=false`); md5 `7a526354…`; registry-driven lookup; static CASE resolver; no `EXECUTE format` / `::regprocedure`; calls both begin + commit.
- **adapter:** `assign_class_distribution` md5 `03a1510b…` frozen (SECURITY DEFINER).
- **gaa:** `get_mission_control_actions` md5 `3596633c…` frozen (FE read-contract byte-stable).
- **ledger columns:** `…, intent_hash_version, intent_fingerprint`.
- **ledger grants:** authenticated SELECT=true; INSERT=false; UPDATE=false; DELETE=false.
- **ledger policies:** only `mission_control_action_requests_select_own` (SELECT).
- **ledger indexes:** pkey `id`; UNIQUE `request_id`; `actor_id_idx`. No unique index on `intent_fingerprint`.
- **backfill:** total 12 rows; `intent_fingerprint` NULL = 12; NOT NULL = 0; `intent_hash_version` distinct = {null}. → **no legacy backfill.**
- **registry:** 2 rows — `class.assign` active / adapter `class.assign.v1`; `class.edit` disabled / adapter null.
- **forge grants:** `_mc_begin_action`, `_mc_commit_action` EXECUTE = `{authenticated, postgres}` only.
- **Public inventory:** tables 92 · fns 248 · secdef 236 · policies 167 · triggers 33.

---

## 3 · Frozen invariants (8/8 PASS)

1. execute SECURITY INVOKER ✅ (`execute_secdef=false`).
2. `_mc_commit_action` SECURITY DEFINER, sole terminal writer ✅ (md5 `ce36c5fe…` frozen).
3. adapter unchanged ✅ (`assign_class_distribution` md5 `03a1510b…`).
4. registry unchanged ✅ (2 rows, disposition intact).
5. FE unchanged ✅ (gaa md5 frozen; pin `2.8.5`; no FE repo change this milestone).
6. no legacy fingerprint backfill ✅ (12/12 NULL).
7. no terminal client write ✅ (UPDATE/DELETE=false; + INSERT=false — full seal).
8. no dynamic SQL dispatch ✅ (execute + begin bodies verified).

---

## 4 · Scope

**Completed:** registry authority · adapter resolver · intent integrity · replay semantic protection · ledger write boundary · conflict handling · forge protection.

**Deferred (out-of-scope, documented):** Decision layer · approval workflow · human-in-loop · multi-object action expansion · generic action marketplace · FE expansion.

**Known debt:** FE `ClassWorkspaceScreen` submit path still class.assign-specific (latent coupling; future decouple).

**Unpersisted proof:** positive-path fingerprint row not present (12/12 legacy NULL). Mechanism structurally verified via body audit + grant/policy closure; a committed positive-path (fp NOT NULL row) has not been exercised in persisted data. Recommend one JWT-impersonation positive-path run (`BEGIN…ROLLBACK`) if a persisted-evidence bar is desired — not required for milestone closure.

---

## 5 · Rollback (Phase 3 → Phase 2)

1. `DROP FUNCTION mc_internal._mc_begin_action(uuid,text,text,uuid,uuid,uuid,uuid)`.
2. `CREATE OR REPLACE execute_mission_control_action` → P2 body (md5 `cf446902587cd6d0dea9d578d645bf71`) + re-harden ACL `{authenticated,postgres}`.
3. Re-CREATE ledger INSERT policy `..._insert_own` (verbatim P2) + `GRANT INSERT` authenticated.
4. `ALTER TABLE mission_control_action_requests DROP COLUMN intent_fingerprint, DROP COLUMN intent_hash_version`.
5. `NOTIFY pgrst, 'reload schema'`.
- 0 data-repair (no fingerprinted rows exist). Restores tail `20260815085223` / v1.50 / D362.

---

## 6 · Canonical append performed at close

- `DMA_RULES.md` → append **D363** block (this milestone).
- `DMA_SYSTEM_MAP.md` → append **v1.51** block.
- `DMA_HANDOFF_V128-B6.3-PHASE-3_CLOSEOUT.md` → this file.

Base for RULES/SYSTEM_MAP replacements = verified project-library head D362/v1.50 (RULES sha256 `d06ed3d3…`, SYSTEM_MAP sha256 `82622ea2…`). If live working-copy head differs, re-append onto that head before committing.

---

**MILESTONE V128-B6.3 CLOSED.** No successor phase within B6.3. Next Mission Control work = new milestone.
