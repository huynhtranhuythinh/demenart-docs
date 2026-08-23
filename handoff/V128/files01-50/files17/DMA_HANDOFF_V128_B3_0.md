# 🗂️ DMA_HANDOFF_V128_B3_0.md — MISSION CONTROL CONTEXT SEAM FOUNDATION — APPLIED · VERIFIED · CANONICALIZED

> **Ngày:** 2026-08-11 (GMT+7) · **Loại:** backend-only foundation migration (registry column + validator seam + shared core + 4-arg overload) · **Verdict: V128-B3.0 APPLIED — migration + functional verification PASS (1 corrective fix) · CANONICALIZED D352 / v1.40.**
> **Boot phiên sau:** file này → `DMA_RULES.md` (tip **D352**) → `DMA_SYSTEM_MAP.md` (**v1.40**) → audit live DB (D1) → re-pin `list_edits` (FE `be04f4b`, BẤT BIẾN).

---

## A. VERDICT

**`V128-B3.0 APPLIED — VERIFICATION PASS`.** Context Contract Layer đóng: Variant A three-tier adapter (legacy 3-arg → shared internal core → context-aware 4-arg) + `context_requirements jsonb` declarative metadata + `validate_mission_control_object_context` structural seam. **Foundation-only:** 0 object wired mới, 0 projector mới, 0 command/permission/audit-ledger, 0 RLS/role/DTO/FE change; không object nào set requirements ≠ default → seam trong suốt với hành vi B2.2 đang chạy (regression 3-arg == 4-arg`{}` byte-identical, diffcount=0). Migration transactional (BLOCK 1 DDL → BLOCK 2 ACL D15/D231/D289 → BLOCK 3 in-tx RAISE-on-fail VERIFY). **1 defect bắt ở STEP 6 functional** (validator `text[] || untyped-literal` → `array_cat` → 22P02 trên error-path; happy-path che qua apply+structural-verify) → corrective REPLACE `array_append` (mig `20260811111257`). Post-fix functional PASS toàn bộ. **Canonicalization D352 + SYSTEM_MAP v1.40 ghi byte-preserving append lên file on-disk (grounded trên migration statements THẬT, không memory).**

## B. ENDPOINT

- **Migration:** `v128_b3_0_context_seam_foundation` (`20260811110749`) + `v128_b3_0_validator_errors_arrayfix` (`20260811111257`) · tail `20260811080037` → **`20260811111257`**
- **FE HEAD:** `be04f4b` — **BẤT BIẾN** (backend-only)
- **Canonical:** RULES **D352** · SYSTEM_MAP **v1.40** · HANDOFF **V128-B3.0**
- **DB inventory (live sau apply):** **90 tables · 238 functions · 227 SECURITY DEFINER · 166 policies · 33 triggers · 1 cron**

## C. COMPLETED

1. **Precheck (D1, read-only):** baseline khớp B2.2 tuyệt đối (90·235·224·166·33·1, tail `20260811080037`, FE `be04f4b`). Seam greenfield: adapter thật = `get_object_workspace(text,uuid,text)` (KHÔNG phải `get_workspace_adapter` — memory sai); validator/core/4-arg/`context_requirements` đều absent. Dependency ACL clean (is_admin, 5 projector, logger, registry table 0 anon/authenticated).
2. **Rehearsal (STEP 2):** phát hiện v2 = DESIGN PLACEHOLDER (validator/core body stub, BLOCK 2/3 prose). Materialize apply-ready three-block: core steps 1/2/5/6 **byte-faithful port từ live B2.2 body** (STEP 1 capture), step 3/4 + overloads + BLOCK 1 = code v2, validator từ spec §5, ACL từ D15/D231 + v2.1 C-1.
3. **Owner Gate (STEP 3):** Jean confirm `APPLY`.
4. **Migration apply (STEP 4):**
   - BLOCK 1: ALTER ADD COLUMN `context_requirements` + CHECK `mc_context_requirements_shape_chk`; CREATE validator; CREATE core; REPLACE `get_object_workspace/3` → wrapper; CREATE `get_object_workspace/4`.
   - BLOCK 2: ACL deterministic — validator+core `{postgres,service_role}` (REVOKE anon+authenticated), 2 overload `{authenticated,postgres,service_role}` (REVOKE anon); NOTIFY pgrst.
   - BLOCK 3: in-tx structural VERIFY (10 nhóm assertion, RAISE-on-fail) → PASS in-tx.
5. **Structural verification (STEP 5, post-commit):** 235→238 fn · 224→227 secdef · registry +1 col +1 CHECK · 17/17 default · 4 target đúng ACL/secdef/sp/no-default.
6. **Functional verification (STEP 6, impersonation, rollback-safe):** xem §E. **Bắt 1 defect → corrective fix → re-verify PASS.**
7. **Canonicalization (STEP 8):** D352 (+ .1..7) grounded trên migration statements THẬT (`20260811110749`/`20260811111257`); SYSTEM_MAP header→v1.40 + version-log block; file on-disk byte-preserved append.

## D. VERIFIED — structural (live)

- functions 235→**238** (+validator +core +4-arg) · secdef 224→**227** · tables/policies/triggers/cron bất biến (90/166/33/1).
- registry: **+1 col** `context_requirements jsonb NOT NULL` + **+1 CHECK** `mc_context_requirements_shape_chk`; **17 rows** = default; 5 wired / 6 registered / 6 forbidden bất biến; class+session vẫn registered.
- ACL: `validate_mission_control_object_context` = `{postgres,service_role}` · `_mission_control_workspace_core` = `{postgres,service_role}` · `get_object_workspace/3` + `/4` = `{authenticated,postgres,service_role}` — **cả 4 = 0 anon · 0 PUBLIC**.
- `get_object_workspace/4` `pronargdefaults=1` (p_context REQUIRED no-default). DTO marker `WorkspaceProjectionDTO/v1` present trong core.

## E. VERIFIED — functional / privacy (impersonation, rollback-safe)

`ROLLBACK_OK: child{ok=true,rl=true} media{ok=true,rl=false} person{ok=true,rl=false} school{ok=true,rl=false} capsule{ok=true,rl=true} extrakey=context_invalid authval=denied_42501 nonadmin=not_authorized val_empty=true val_unk=false[context_unknown_key]  diffcount=0`
`ROLLBACK_OK: missing=false[context_missing_required_key] | badtype=false[context_type_mismatch] | good=true norm={school_id:...}`

| Case | Assertion | Result |
|---|---|---|
| Regression 3-arg · 5 wired (person/child/media/capsule/school) | ok=true | ✅ |
| 3-arg **==** 4-arg `{}` | DTO byte-identical (diffcount=0) | ✅ |
| reason/access-log (child reason_required, capsule restricted) | fire sau validate (rl=true) | ✅ |
| 4-arg extra-key `{"x":1}` | → `context_invalid`, không touch | ✅ |
| authenticated → validator trực tiếp | → `42501` (v2.1 C-1) | ✅ |
| non-admin | → `not_authorized` | ✅ |
| validator `{}` / unknown / missing-required / bad-uuid / good | valid / unknown / missing / type_mismatch / valid+normalized | ✅ |
| Residue | access-log child/capsule + seeding UPDATE **rolled back, zero residue** | ✅ |

## F. DEFECT & FIX (minh bạch)

**Defect:** validator `v_errors text[] := v_errors || '<untyped literal>'` → Postgres resolve `text[] || unknown` = `array_cat` → `22P02 malformed array literal`, chỉ nổ trên **error-path** (append error). Happy-path `{}` không append → apply + BLOCK 3 in-tx structural VERIFY pass sạch; **chỉ STEP 6 functional impersonation trên error-path bắt được.** Core `EXCEPTION WHEN OTHERS → context_invalid` giữ fail-closed đúng nhưng mất `errors[]`. **Fix:** `array_append` (mig `20260811111257`, REPLACE validator + D15 re-harden + D231 guard + D289; ACL posture giữ `{postgres,service_role}`). **→ D352.7:** error-accumulation path PHẢI functional-exercise; structural verify không đủ.

## G. FROZEN

DTO `WorkspaceProjectionDTO/v1` (không bump) · logger `admin_workspace_access_log` (không đụng) · registry 12 cột cũ + 7 CHECK cũ · 5 projector (`admin_lookup_user/child/media/capsule/school`, count bất biến) · `is_admin` · RLS · roles · `profiles.permissions[]` · Bunny · routes · tooling · FE (`be04f4b`). Δ ròng = **+3 fn + 1 REPLACE + 1 col + 1 CHECK**. Auth-slot (step 4) = no-op placeholder (KHÔNG `authorize_*`).

## H. ROLLBACK

```sql
DROP FUNCTION IF EXISTS public.get_object_workspace(text, uuid, jsonb, text);
DROP FUNCTION IF EXISTS public._mission_control_workspace_core(text, uuid, jsonb, text);
DROP FUNCTION IF EXISTS public.validate_mission_control_object_context(text, jsonb);
-- restore get_object_workspace(text,uuid,text) về monolith body B2.2 (nguồn: HANDOFF V128-B2.2 §C BLOCK 1b)
CREATE OR REPLACE FUNCTION public.get_object_workspace(text, uuid, text) ...;  -- B2.2 body
ALTER TABLE public.mission_control_object_registry DROP CONSTRAINT IF EXISTS mc_context_requirements_shape_chk;
ALTER TABLE public.mission_control_object_registry DROP COLUMN IF EXISTS context_requirements;
NOTIFY pgrst, 'reload schema';
```
Additive undo về đúng tip B2.2 (tail `20260811080037`). Registry 17-row business values + 5 projector + logger + DTO KHÔNG đụng.

## I. CANONICALIZATION — DONE

- **D352 (.1 Variant A · .2 context_requirements+CHECK · .3 validator seam · .4 core+order · .5 overload · .6 DB delta · .7 array_append learning) / SYSTEM_MAP v1.40 / HANDOFF V128-B3.0.**
- Grounded trên migration statements THẬT (`20260811110749`/`20260811111257`) + live re-pin. RULES tip D351→**D352** (1828→1852 lines); SYSTEM_MAP v1.39→**v1.40** (header bump + version-log block, 2504→2523 lines). Byte-preserving append lên file on-disk.

## J. NEXT MILESTONE

**V128-B3.1** — Context Authorization Slot: hook step-4 auth-slot (hiện no-op) → tenant authorization / class membership / assignment authorization, thao tác CHỈ trên `v_ctx` (validated+normalized) + registry metadata, **CẤM lookup-first**. Điều kiện wire class/session (two-id context: school-context + class/session-id) — set `context_requirements` ≠ default (vd `{"keys":{"school_id":{"type":"uuid","required":true}}}`) + projector mới + auth-slot logic. FE `ObjectWorkspaceModel` mapping cho 4-arg/context = track FE riêng (chưa làm). **Backup debt:** migration B2.0/B2.1/B2.2 + B3.0 (×2) chưa commit repo.

---

**FINAL: ✅ V128-B3.0 — MIGRATION + FUNCTIONAL VERIFICATION PASS (1 corrective fix) · APPLIED · CANONICALIZED (D352 / v1.40).**
