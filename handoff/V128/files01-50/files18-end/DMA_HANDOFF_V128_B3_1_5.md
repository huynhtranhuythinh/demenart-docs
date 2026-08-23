# 🗂️ DMA_HANDOFF_V128_B3_1_5.md — MISSION CONTROL CONTEXT SEAM — APPLIED · VERIFIED · CANONICALIZED

> **Ngày:** 2026-08-12 (GMT+7) · **Loại:** backend-only migration arc (context seam foundation + CLASS consumer + assignment scope gate) · **Verdict: V128-B3.0 / B3.1 / B3.1.5 APPLIED — migration + functional/security verification PASS · CANONICALIZED D352–D354.**
> **Boot phiên sau:** file này → `DMA_RULES.md` (tip **D354**) → `DMA_SYSTEM_MAP.md` (**v1.42**) → audit live DB (D1) → re-pin `list_edits` (FE `be04f4b`, BẤT BIẾN backend-only).

---

## A. VERDICT

**`V128-B3.0 / B3.1 / B3.1.5 APPLIED — VERIFICATION PASS`.** Ba milestone CLOSED, canonicalized append-only lên file on-disk:

- **B3.0 — Context Seam Foundation:** tách CORE internal-only (`_mission_control_workspace_core`) khỏi 2 public wrapper `get_object_workspace`; thêm validator registry-driven fail-closed (`validate_mission_control_object_context`) + cột `context_requirements`. Context = data-binding, authz slot NO-OP.
- **B3.1 — CLASS first consumer:** `class` registered→wired với context `{school_id uuid required}`; projector bound-lookup 2-id `admin_lookup_class` (wrong-school ≡ not_found). Package **v2** ALL PASS.
- **B3.1.5 — Assignment scope gate foundation:** scope vocabulary core `{platform,tenant}`→`{platform,tenant,assignment}`, ZERO SESSION wiring, DB 0 net. Synthetic proof: assignment-wired → `dispatch_missing` (không phải `scope_not_wired`).

## B. ENDPOINT

- **Migrations:** `v128_b3_0_context_seam_foundation` (`20260811110749`) → `v128_b3_0_validator_errors_arrayfix` (`20260811111257`) → `v128_b3_1_class_context_seam_v2` (`20260812023155`) → `v128_b3_1_5_assignment_scope_gate` (`20260812051609`).
- **Migration tail:** `20260811080037` → **`20260812051609`**
- **FE HEAD:** `be04f4b` — **BẤT BIẾN** (backend-only toàn arc B3.0→B3.1.5; 0 FE / 0 Edge / 0 Bunny)
- **Canonical:** RULES **D354** · SYSTEM_MAP **v1.42** · HANDOFF **V128-B3.1.5**
- **DB inventory (live sau apply):** **90 tables · 239 functions · 228 SECURITY DEFINER · 166 policies · 33 triggers · 1 cron**

## C. COMPLETED

1. **B3.0 (D352):** core/wrapper split (core EXECUTE `{postgres,service_role}` internal-only); 4-arg + 3-arg wrapper delegate (legacy empty context → fail-closed); registry `+context_requirements jsonb`; validator internal-only fail-closed (`context_requirements_malformed`/`context_not_object`/`context_type_mismatch`/`context_missing_required_key`/`context_unknown_key`); authz slot `PERFORM v_ctx` NO-OP; DTO/v1 giữ nguyên. 2 mig (foundation + validator array-fix).
2. **B3.1 (D353):** `admin_lookup_class(uuid,uuid)` bound-lookup identity-only, self-gated `is_admin()`; core CASE `WHEN 'class'` dùng `(v_ctx->>'school_id')::uuid`; registry class registered→wired + context `{school_id}`. Package v1→**v2** correction → ALL PASS.
3. **B3.1.5 (D354):** core scope allowlist `+assignment` (explicit 3-value); status gate giữ TRƯỚC scope gate; assignment domain = containment bởi `class_distribution` (chain lesson_sessions→…→schools). Core REPLACE in-place, 0 net object.
4. **Canonicalization:** D352/D353/D354 + SYSTEM_MAP v1.40→v1.42 grounded trên migration statements THẬT + live re-pin (`pg_get_functiondef` · `aclexplode` · registry · synthetic proof). Append-only; SYSTEM_MAP top-marker (line 9) = non-append duy nhất được phép theo convention.

## D. VERIFIED — structural (live)

- functions 235→**239** (+4: core + validator + 4-arg wrapper [B3.0] + `admin_lookup_class` [B3.1]) · secdef 224→**228** · tables/policies/triggers/cron BẤT BIẾN (90/166/33/1).
- **ACL:** `_mission_control_workspace_core` + `validate_mission_control_object_context` = `{postgres,service_role}` · **0 anon/authenticated/PUBLIC** (internal boundary). `get_object_workspace` (×2 overload) + `admin_lookup_class` + `admin_lookup_school` = `{authenticated,postgres,service_role}` · 0 anon/PUBLIC.
- core + validator + 2 wrapper + `admin_lookup_class` = SECURITY DEFINER, owner `postgres`, `search_path=''` pinned.
- registry: **17 rows** — **6 wired** (person/child/media/capsule=platform · school/class=tenant) · **5 registered** (subscription/support_case/program/privacy_request=platform · session=assignment) · **6 none/forbidden**. class discovery=`[name]` context=`{school_id uuid required}`.

## E. VERIFIED — functional / security (impersonation + synthetic, rollback-safe)

| Case | Assertion | Result |
|---|---|---|
| Validator malformed/unknown/missing | `context_requirements_malformed` / `context_unknown_key` / `context_missing_required_key` fail-closed | ✅ |
| class via 4-arg + valid `{school_id}` | ok · fields ⊆ {name} · **no school_id leak** | ✅ |
| class via 3-arg legacy (empty ctx) | → `context_invalid` (required school_id missing) | ✅ |
| class wrong-school ≡ nonexistent | → `not_found` (indistinguishable) | ✅ |
| session (registered/assignment) normal path | → `not_available` (status gate trước scope gate) | ✅ |
| synthetic assignment-wired (no dispatch) | PRE `scope_not_wired` → POST **`dispatch_missing`** | ✅ |
| authenticated **direct core** call | → `42501 permission denied` | ✅ |
| authenticated **admin** via wrapper | works | ✅ |
| authenticated **non-admin** via wrapper | → `not_authorized` | ✅ |

*Synthetic registry rows + impersonation state rolled back — zero residue.*

## F. FROZEN

`is_admin()` = authorization boundary DUY NHẤT · context authz slot = NO-OP (chưa gate quyền) · DTO/v1 (không bump) · scope allowlist đóng `{platform,tenant,assignment}` (không mở toang) · status gate TRƯỚC scope gate (D351.3) · privacy double-moat (allowlist + forbidden-leak, D350.3) · 6 forbidden object (LINH HỒN + D347.3) · RLS/policies/role/permission model · Bunny/routes/tooling/FE (`be04f4b`). **SESSION KHÔNG đụng** (projector/discovery/context/dispatch).

## G. ROLLBACK (arc, additive undo)

```sql
-- B3.1.5: restore core scope gate 2-value {platform,tenant} (remove assignment predicate)
-- B3.1:   DROP FUNCTION admin_lookup_class(uuid,uuid); restore core CASE pre-class;
--         UPDATE registry class → registered, context_requirements default-empty
-- B3.0:   DROP core + validator + get_object_workspace(text,uuid,jsonb,text);
--         restore get_object_workspace(text,uuid,text) = B2.2 chokepoint body (inline, authenticated);
--         ALTER TABLE mission_control_object_registry DROP COLUMN context_requirements
NOTIFY pgrst, 'reload schema';
```
Baseline pre-arc → tail `20260811080037` (D351/v1.39). Forbidden set + platform projector + registry table KHÔNG đụng.

## H. CANONICALIZATION — DONE

- **D352 / v1.40 / HANDOFF V128-B3.0** — context seam foundation (+3 fn + registry column).
- **D353 / v1.41 / HANDOFF V128-B3.1** — CLASS first consumer (+1 fn, class wired).
- **D354 / v1.42 / HANDOFF V128-B3.1.5** — assignment scope gate (0 net, core REPLACE).

Grounded trên migration statements THẬT (`20260811110749`/`20260811111257`/`20260812023155`/`20260812051609`) + live re-pin — KHÔNG reconstruct từ trí nhớ. RULES tip D351→**D354** (1828→1886 lines); SYSTEM_MAP v1.39→**v1.42** (line-9 marker + consolidated B3 section, 2504→2577 lines). Historical prefix byte-identical (append-only).

## I. NEXT MILESTONE

**V128-B3.2 — SESSION = SECOND CONTEXT CONSUMER** (⚠️ **NOT STARTED · NO IMPLEMENTATION AUTHORIZATION**).

- **Current SESSION (live):** kind=supporting · scope=assignment · projector_status=**registered** · context_requirements default-empty · `admin_lookup_session` **ABSENT** · normal path `not_available`.
- **PROPOSED (NOT APPLIED)** — design input duy nhất, cần Owner Gate trước khi wire:
  - SESSION context contract: `{"version":1,"keys":{"class_distribution_id":{"type":"uuid","required":true}},"allow_unknown":false}`.
  - Cần: projector `admin_lookup_session(...)` (bound-lookup theo assignment containment `class_distribution`) + core CASE `WHEN 'session'` + registry session registered→wired + context UPDATE.
  - Bound-lookup phải theo chain `class_distribution_id → class_distributions → class_id → classes → school_id` (assignment-scoped, KHÔNG re-scope tenant).
- **Backup debt:** migration files B3.0/B3.1/B3.1.5 (4 mig) chưa commit vào repo — outstanding.

---

**FINAL: ✅ V128-B3.0 / B3.1 / B3.1.5 — MIGRATION + VERIFICATION PASS · APPLIED · CANONICALIZED (D352–D354 / v1.40–v1.42). SESSION registered/assignment/unwired — B3.2 chờ gate.**
