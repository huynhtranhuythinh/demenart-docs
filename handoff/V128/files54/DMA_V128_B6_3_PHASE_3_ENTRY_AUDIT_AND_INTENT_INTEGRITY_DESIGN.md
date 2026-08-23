# V128-B6.3 PHASE 3 ENTRY AUDIT & INTENT INTEGRITY DESIGN

> **Mode:** READ-ONLY ENTRY AUDIT + DESIGN ONLY. **Không:** migration/DB mutation · code/FE · commit · canonical append · cleanup · Phase 4 · new action · generic engine.

---

## Canonical State
RULES **D362** · SYSTEM_MAP **v1.50** · HANDOFF **V128-B6.3-PHASE-2** · Phase 2 CLOSED · B6.3 NOT CLOSED · G1 CLOSED / G2 CLOSED / **G3 OPEN** / G4 CLOSED · tail `20260815085223`. Endpoint khớp — không STOP.

## Live Re-Pin (D1) — PASS
tail `20260815085223` · inv `92·248·236·168·33·1` · mc_internal 2/2 · execute `cf446902587cd6d0dea9d578d645bf71` (INVOKER) · get_mc_actions `3596633c6f7f1b7ecdc81822691475d4` · frozen lookup `5d940037…` / gaa `fd874243…` / commit `ce36c5fe…` / adapter `03a1510b…` · registry class.assign active/`class.assign.v1`/typed required_context/v1, class.edit disabled/NULL.

## Ledger Reader/Writer Inventory (byte/catalog-exact)
**Table `mission_control_action_requests` — 12 cols:** id(pk, uuid, gen_random_uuid) · request_id(uuid, **UNIQUE**, NOT NULL) · action_key(text) · object_type(text) · object_id(uuid) · status(text, default 'received') · result_payload(jsonb, null) · error_code(text, null) · actor_id(uuid→profiles ON DELETE SET NULL, null) · created_at(now) · started_at(null) · completed_at(null). No generated columns.
**Constraints:** `status_check` {received,processing,completed,failed} · `lifecycle_check` (received/processing→payload+error+completed NULL; completed→payload NOT NULL, error NULL, completed NOT NULL; failed→payload+error+completed NOT NULL) · pkey(id) · unique(request_id) · fk actor_id.
**Indexes:** pkey(id) · unique(request_id) · actor_id_idx. **RLS:** ON.
**Policies:** `insert_own_processing` (INSERT/authenticated, WITH CHECK `actor_id=current_profile() AND status='processing' AND result_payload IS NULL AND error_code IS NULL AND completed_at IS NULL`) · `select_own` (SELECT/authenticated, USING `actor_id=current_profile()`).
**Grants:** authenticated {INSERT, SELECT} (all columns). anon/service_role: none.
**Rows:** 12 (9 completed, 3 failed, 0 processing/received) — B6.2/B6.3 QA artifacts.
**Only 2 functions touch ledger:** `public.execute_mission_control_action` (INVOKER — **INSERT** processing) · `mc_internal._mc_commit_action` (DEFINER — **UPDATE** terminal). No hidden readers/writers.
**Crypto:** pgcrypto installed in `extensions` → `extensions.digest(bytea|text, text)` for SHA-256. `gen_random_uuid` available.

## Current Replay Contract
On `request_id` exists (INSERT ON CONFLICT(request_id) DO NOTHING → v_request_pk null):
1. `select * into v_existing where request_id` (RLS `select_own` → cross-actor invisible → NOT FOUND → `MC_ACTION_REQUEST_CONFLICT`).
2. structural-triple mismatch (`action_key ∨ object_type ∨ object_id`) → `MC_ACTION_REQUEST_CONFLICT`.
3. status ∈ {received,processing} → `MC_ACTION_REQUEST_IN_PROGRESS` (replayed:true).
4. completed → cached `result_payload` with `replayed=true`.
**Gap:** identity = structural triple only; **context/input (semantic intent) not compared** → same request_id + different program_id/lead_teacher_id/school_id could cache/replay incorrectly.

## Threat / Gap Definition (G3)
Same `request_id` replayed as same request when triple matches **even if semantic intent differs** (context/input). FE request_id-reset discipline ≠ server integrity. **Target:** bind request_id to a **server-computed** intent fingerprint; same-id+same-intent → replay; same-id+different-intent → `MC_ACTION_REQUEST_CONFLICT`. No change to action/adapter/registry/FE/ledger-terminal-ownership.

## Canonical Intent Definition
Computed from **parsed typed semantic values** (post-validation), NOT raw client JSON:
```
{ "v":1,
  "action_key":"class.assign",
  "object_type":"class",
  "object_id":"<uuid canonical>",
  "context":{ "school_id":"<uuid canonical>" },
  "input":{ "program_id":"<uuid canonical>", "lead_teacher_id":"<uuid canonical>|null" } }
```
**actor_id EXCLUDED** — request ownership is already bound by the `actor_id` column + `select_own` RLS (cross-actor request_id collision → CONFLICT via invisibility). Fingerprint = **business-intent identity**, not ownership identity (STEP 3 recommendation ★).

## Canonicalization Rules
- **UUIDs** → `::uuid::text` (canonical lowercase hyphenated) — lexical/case differences collapse (R5).
- **lead_teacher_id absent ≡ `null` ≡ `""`** → all normalize to JSON `null` — **matches current adapter business behavior** (`nullif(...,'')::uuid` → NULL → assign without lead teacher). Fingerprint MUST treat equivalent (R3, STEP 6 decision ★).
- **key order irrelevant** — canonical jsonb built via `jsonb_build_object`; `jsonb::text` is deterministic for a value regardless of build order (R4).
- **computed AFTER validation** (typed parse), never hashing raw `p_context`/`p_input`; extra-key/bad-cast already rejected pre-fingerprint (precedence preserved).
- **Order:** validate → parse typed values → construct canonical intent jsonb → hash.

## Fingerprint Algorithm & Versioning
- `v_canonical text := (jsonb_build_object(...))::text` (deterministic).
- `v_fp text := encode(extensions.digest(convert_to(v_canonical,'UTF8'),'sha256'),'hex')` (64-char hex, deterministic, collision-resistant, **server-only** — client never supplies a hash).
- **Storage (STEP 5 ★):** explicit `intent_hash_version smallint` + `intent_fingerprint text` (hex). **No index** (lookup is by unique `request_id`; fingerprint compared only after fetching that row). Version column enables future canonicalization changes without ambiguity (bump v2, old rows stay v1).

## Ledger Schema Design (additive)
`ALTER TABLE mission_control_action_requests ADD COLUMN intent_hash_version smallint, ADD COLUMN intent_fingerprint text` — **nullable** (legacy rows can't be reconstructed). New rows: execute always writes both (non-null). No change to `lifecycle_check`/`status_check` (fingerprint outside those). Immutability: fingerprint written **once at INSERT**, never UPDATEd (commit-core doesn't touch it). authenticated must NOT gain UPDATE.

## Legacy Row Strategy (STEP 7 ★)
12 existing rows have **no stored context/input** → intent **not reconstructable**. **Do NOT fabricate** fingerprints from the structural triple (that would be a fake semantic fingerprint). Policy: **nullable columns, legacy `intent_fingerprint=NULL`, no backfill.** Replay branch: `if v_existing.intent_fingerprint IS NULL → structural-triple-only comparison (exact current behavior)`; `else → also compare fingerprint`. New rows always non-null → full integrity. Legacy request_ids are terminal UUIDs (collision-improbable); backward-compatible + safe. (Blends STEP-7 options A+B; version column marks the transition.)

## Replay State Machine (target)
On `request_id` exists (v_request_pk null), v_fp = server-computed for THIS call:
1. RLS-invisible/not-found → `MC_ACTION_REQUEST_CONFLICT` *(unchanged)*.
2. structural-triple mismatch → `MC_ACTION_REQUEST_CONFLICT` *(unchanged)*.
3. **NEW:** `v_existing.intent_fingerprint IS NOT NULL AND v_existing.intent_fingerprint <> v_fp` → `MC_ACTION_REQUEST_CONFLICT`.
4. status ∈ {received,processing} → `MC_ACTION_REQUEST_IN_PROGRESS` *(unchanged)*.
5. completed → cached replay *(unchanged)*.
**Precedence:** triple → fingerprint → in-progress/completed (fingerprint mismatch on processing/completed → CONFLICT, not IN_PROGRESS/replay). **No new public error code** — semantic mismatch reuses `MC_ACTION_REQUEST_CONFLICT` (it *is* a request conflict; FE already handles it; STEP 8 ★).

## Race / Concurrency Semantics
Fresh request: compute v_fp → INSERT processing **WITH fingerprint atomically** (ON CONFLICT(request_id) DO NOTHING). Loser: ON CONFLICT DO NOTHING → reads winner row → compares fingerprint → conflict/in-progress/replay. **No post-insert fingerprint UPDATE** (written in initial INSERT only). No TOCTOU (single atomic INSERT; comparison reads committed winner).

## Client-Forge Analysis (load-bearing)
**Current:** authenticated has direct table INSERT (via `insert_own_processing`), so a client can `POST` a processing row through PostgREST with arbitrary `request_id/object_id/action_key` (+ Phase-3 arbitrary `intent_fingerprint`), constrained only to `actor_id=self, status=processing, terminals null`.
**Impact assessment:**
- **Cross-user:** none — `select_own` RLS hides other actors' rows; a different user's execute with same request_id → NOT FOUND → CONFLICT.
- **Result forgery:** none — `completed`/`failed` require terminal write, DEFINER-only (`_mc_commit_action`, **G4**); WITH CHECK forbids `status≠processing` and non-null payload. Client cannot pre-seed a completed cached result.
- **Self:** client can forge fingerprint on their own processing row → their own later execute computes real fp → mismatch → CONFLICT (**self-DoS**, a pre-existing risk class: today a client can already grief own request_ids). No escalation.
**Conclusion:** with a plain nullable fingerprint column, forgery = self-DoS only. Two designs:

**Option A — minimal (keep direct INSERT):** rely on (self-RLS + DEFINER-terminal G4 + always-server-computed-compare). No grant/policy change. Residual: self-DoS (pre-existing).
**Option C — hardened (★):** move processing-INSERT into `mc_internal._mc_begin_action(request_id, action_key, object_id, actor_id, intent_hash_version, intent_fingerprint)` **SECURITY DEFINER** (owner postgres, `search_path=''`, ACL {authenticated,postgres}); **REVOKE INSERT on ledger from authenticated**; **DROP `insert_own_processing`**. execute (INVOKER) calls `_mc_begin_action` passing the **server-computed** fingerprint. Now **no client can insert any ledger row directly** → forge surface fully closed; both write boundaries (begin + commit) DEFINER-owned, matching the ownership model. Cost: +1 mc_internal fn (+1 secdef), grant+policy delta, execute md5 change larger.

**Recommendation ★ Option C** — Phase 3's mandate is integrity; full closure of the ledger write surface is the correct, defensible end-state and aligns SYSTEM_MAP's two-boundary ownership model (INVOKER orchestrates, DEFINER writes). Option A acceptable only if CTO wants minimal footprint and accepts self-DoS residual.

## Execute Delta Design
Change ONLY: (a) compute canonical intent + fingerprint from parsed typed values, placed **after gate-8 (context/object match), immediately before the ledger write block** (all typed values available; precedence of auth/lookup/null/context/input/object/mismatch **unchanged**); (b) processing write includes fingerprint+version (direct INSERT [A] or via `_mc_begin_action` [C]); (c) replay branch adds fingerprint comparison (step 3 above). **Unchanged:** signature · INVOKER · gate order · registry lookup · context/input validation semantics · object lookup · static adapter CASE · adapter exception map · commit-core call · success/replay/error envelopes.

## Frozen Objects
`get_mission_control_actions` · `_mc_lookup_action` · `get_available_actions` · `assign_class_distribution` · **`_mc_commit_action`** (audited: UPDATE sets status/payload/error/completed only, does NOT reference new columns → **stays byte-identical, md5 frozen**) · registry rows/schema · FE. No new action/engine.

## P3-E QA Matrix (JWT-impersonation, BEGIN…ROLLBACK; PRE/POST)
- **P3-E1** same id + identical intent → cached replay (replayed:true, same result).
- **P3-E2** same id + different program_id → `REQUEST_CONFLICT`.
- **P3-E3** same id + different lead_teacher_id → `REQUEST_CONFLICT`.
- **P3-E4** same id + different context.school_id (fixture: object valid for both only via mismatch) → whichever precedence applies; if both reach ledger with different school context → CONFLICT.
- **P3-E5** same intent, JSON key order changed → replay (NOT conflict).
- **P3-E6** lead_teacher_id absent vs null vs '' → same fingerprint → replay.
- **P3-E7** UUID lexical/case variation → same intent → replay.
- **P3-E8** race/processing row: same intent → IN_PROGRESS; different intent → CONFLICT.
- **P3-E9** legacy pre-fingerprint row (fingerprint NULL) → structural-triple-only (current behavior).
- **P3-E10** direct authenticated forge attempt on fingerprint columns → [C] INSERT denied (no grant); [A] self-only, execute compare still authoritative.
- **P3-E11** completed cached replay returns exact stored response, no side effects.
- **P3-E12** conflict path rollback-only, no orphan (ledger_R=0).
- **Regression subset:** no-auth PERMISSION_DENIED · class.edit/unknown precedence NOT_FOUND · E3/E4 CONTEXT/INPUT · E6 OBJECT_NOT_FOUND · **E2b OBJECT_NOT_FOUND** · E1 success · E7 replay same-dist · get_mission_control_actions (E12) unchanged.

## Allowed Behavioral Delta
**Intentional (only one):** same request_id + same structural triple + **different semantic intent** → now `MC_ACTION_REQUEST_CONFLICT` (was potential incorrect replay/cache). **Forbidden deltas:** success shape · replay shape for identical intent · error precedence unrelated to fingerprint · adapter/audit behavior · FE discovery · ledger terminal ownership.

## Migration Design (DESIGN ONLY)
`v128_b6_3_p3_intent_integrity`, D92 3-block:
- **BLOCK 1:** ALTER ADD 2 columns (nullable); [C] CREATE `mc_internal._mc_begin_action` DEFINER; CREATE OR REPLACE execute (fingerprint compute + write + replay compare).
- **BLOCK 2:** [C] REVOKE INSERT on ledger FROM authenticated; DROP `insert_own_processing`; GRANT/harden `_mc_begin_action` ACL {authenticated,postgres}; re-harden execute ACL {authenticated,postgres}. [A] execute ACL re-harden only.
- **BLOCK 3:** VERIFY fail-closed (columns exist nullable; execute INVOKER+sig unchanged+references digest+replay fingerprint compare; commit/adapter/lookup/gaa/get_mc_actions md5 unchanged; authenticated UPDATE=0; [C] authenticated INSERT=0 + `_mc_begin_action` DEFINER; inventory delta as expected).
- `NOTIFY pgrst`. No index on fingerprint.

## Expected Structural Delta
tables same · **+2 columns** · [C] +1 mc_internal fn/secdef → mc_internal {3/3}; policies 168→**167** (drop insert_own_processing); authenticated INSERT revoked · [A] no fn/policy/grant delta · execute REPLACE (md5 change) · triggers 0 · index 0 · public inventory `92·248·236·168·33·1` unchanged (execute REPLACE net 0).

## P3-A1–A20 Acceptance
A1 sig unchanged · A2 INVOKER · A3 registry-driven selection unchanged · A4 static CASE unchanged · A5 commit md5 unchanged · A6 adapter md5 unchanged · A7 lookup md5 unchanged · A8 gaa md5 unchanged · A9 get_mc_actions md5 unchanged · A10 server-computed fingerprint for new requests · A11 version stored · A12 same intent replays · A13 different intent conflicts · A14 null/absent normalization approved · A15 key-order irrelevant · A16 client cannot forge fingerprint ([C] no direct INSERT / [A] compare authoritative) · A17 legacy per policy · A18 authenticated no terminal UPDATE · A19 0 FE/code change · A20 no unrelated drift.

## Rollback Plan
Restore execute → `cf446902587cd6d0dea9d578d645bf71`; [C] restore authenticated INSERT grant + recreate `insert_own_processing` policy + DROP `_mc_begin_action`; DROP 2 columns (safe — new, only execute reads them, no external dependency); re-harden ACL; NOTIFY pgrst. **No** ledger-data cleanup beyond dropping Phase-3 columns; historical rows preserved. Frozen (lookup/gaa/commit/adapter/get_mc_actions) untouched.

## Risk Review
- **R1 modified input reuse** → different fingerprint → CONFLICT ✓.
- **R2 context.school_id change** → different fingerprint (or earlier gate) → CONFLICT ✓.
- **R3 teacher null↔absent** → normalized equal → replay ✓ (business-equivalent).
- **R4 key order** → jsonb canonical → same ✓.
- **R5 UUID lexical** → uuid-cast canonical → same ✓.
- **R6 future canonicalization change** → version column disambiguates ✓.
- **R7 legacy no-fingerprint** → NULL → structural-triple fallback ✓.
- **R8 direct ledger INSERT forge** → [C] fully closed / [A] self-DoS only, no escalation (G4 terminal + RLS self + server-compare) — **load-bearing, recommend C**.
- **R9 replay semantics before/after** → only intended delta (semantic mismatch → CONFLICT); identical-intent replay unchanged.
- **R10 fingerprint computed pre-validation** → avoided (computed post-validation from typed values).

## CTO Micro-Decisions Required
1. **Canonical intent fields:** `{v,action_key,object_type,object_id,context.school_id,input.program_id,input.lead_teacher_id}`, **actor_id excluded** ★.
2. **Absent vs null lead_teacher:** normalize both (+ empty) → null (matches adapter) ★.
3. **Hash storage:** `intent_hash_version smallint` + `intent_fingerprint text`(hex sha256), no index ★.
4. **Legacy rows:** nullable, NULL, no backfill, replay structural-triple-fallback when NULL ★.
5. **Forge defense:** ★ **Option C** (DEFINER `_mc_begin_action` + REVOKE authenticated INSERT + drop insert_own_processing) vs Option A (minimal, self-DoS residual).
6. **Storage model:** hash-only (no canonical-payload storage) ★.
7. **Privilege/policy delta:** tied to #5 (Option C = INSERT revoke + policy drop + new DEFINER fn).

## Recommendation
Proceed Phase 3 as **additive fingerprint (2 nullable columns) + server-computed SHA-256 intent hash + replay fingerprint comparison**, closing **G3** only, with **Option C** write-path closure (DEFINER begin) for full forge defense. Freeze adapter/commit/lookup/gaa/get_mc_actions/registry/FE. Gate apply behind PRE/POST P3-E1–E12 + regression equivalence (only intended delta: semantic-intent mismatch → `MC_ACTION_REQUEST_CONFLICT`). Rollback = restore execute md5 + drop columns/helper + restore grant/policy.

---

## PHASE 3 DESIGN READY FOR CTO APPROVAL

*(Read-only entry audit + design. No SQL/migration/mutation/code/FE/commit/canonical. Phase 3 APPLY only after CTO review.)*
