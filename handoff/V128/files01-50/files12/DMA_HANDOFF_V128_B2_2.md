# 🗂️ DMA_HANDOFF_V128_B2_2.md — MISSION CONTROL SCHOOL WIRING — APPLIED · VERIFIED · CANONICALIZED

> **Ngày:** 2026-08-11 (GMT+7) · **Loại:** backend-only migration (projector + adapter edit + registry transition) · **Verdict: V128-B2.2 APPLIED — migration + functional verification PASS · CANONICALIZED D349–D351.**
> **Boot phiên sau:** file này → `DMA_RULES.md` (tip **D351**) → `DMA_SYSTEM_MAP.md` (**v1.39**) → audit live DB (D1) → re-pin `list_edits` (FE `be04f4b`, BẤT BIẾN).

---

## A. VERDICT

**`V128-B2.2 APPLIED — VERIFICATION PASS`.** School (registered→wired) = **object tenant-scope ĐẦU TIÊN** trong Mission Control. Projector mới `admin_lookup_school(uuid)` + adapter 2-edit (scope gate widen tenant + CASE school) + registry transition. Migration transactional (BLOCK 1a→1b→1c→2→3), BLOCK 3 structural VERIFY pass in-tx. Post-commit functional verification (impersonate super_admin + non-admin, real pilot UUIDs, synthetic assignment row, rollback-safe): **A/A2 not_available · B school-ok · C person-ok · D scope_not_wired · E not_authorized**, zero residue. **Canonicalization batch D349/D350/D351 + SYSTEM_MAP v1.37/v1.38/v1.39 ghi byte-preserving lên file on-disk.**

## B. ENDPOINT

- **Migration:** `v128_b2_2_wire_school_object` · tail `20260811042807` → **`20260811080037`**
- **FE HEAD:** `be04f4b` — **BẤT BIẾN** (backend-only, 0 FE toàn arc B2.0→B2.2)
- **Canonical:** RULES **D351** · SYSTEM_MAP **v1.39** · HANDOFF **V128-B2.2**
- **DB inventory (live sau apply):** **90 tables · 235 functions · 224 SECURITY DEFINER · 166 policies · 33 triggers · 1 cron**

## C. COMPLETED

1. **Owner Gate (6★ ratified):** reject `get_school_overview`; create `admin_lookup_school`; discovery align [name,state]; scope gate widen tenant (explicit); projector identity-only; school open no-audit; school-root single-id (tenant two-id out of scope).
2. **Precheck (D1):** baseline khớp B2.1 tuyệt đối (90·234·223·166·33·1, tail `20260811042807`), zero drift. `admin_lookup_school` absent. `get_school_overview` REJECTED (4 lỗi cấu trúc — xem D351.1).
3. **Migration apply** (FINAL APPLY PACKAGE, CTO-reviewed):
   - BLOCK 1a: `CREATE admin_lookup_school(uuid)` — secdef, `search_path=''`, is_admin gate, not_found guard, `{ok,school:{id,name,state}}` identity-only.
   - BLOCK 1b: `CREATE OR REPLACE get_object_workspace` — **2 edit byte-preserve**: scope gate `+AND scope IS DISTINCT FROM 'tenant'`, CASE `+WHEN 'school'`→`admin_lookup_school`->'school'.
   - BLOCK 1c: `UPDATE` registry school — status registered→**wired**, discovery [name,status]→**[name,state]**, notes.
   - BLOCK 2: ACL deterministic (D15/D231) cả 2 hàm + `NOTIFY pgrst`.
   - BLOCK 3: transactional structural VERIFY (projector struct, adapter edits present, ACL no-anon×2, registry wired+[name,state], platform-wired-4 intact, class still registered, forbidden-6 intact) → PASS.
4. **Post-commit functional verification** (impersonation, rollback-safe): xem §E.
5. **Canonicalization:** D349 (B2.0 registry) + D350 (B2.1 adapter) + D351 (B2.2 school) grounded trên migration statements THẬT; SYSTEM_MAP header→v1.39 + version-log block; file on-disk byte-preserved.

## D. VERIFIED — structural (live)

- functions 234→**235** · secdef 223→**224** · tables/policies/triggers/cron bất biến (90/166/33/1).
- `admin_lookup_school` ACL = `{authenticated, postgres, service_role}` · **0 anon · 0 PUBLIC**.
- `get_object_workspace` ACL = `{authenticated, postgres, service_role}` · **0 anon · 0 PUBLIC** (re-harden sau REPLACE).
- registry: **17 rows** (1 UPDATE, 0 add); school = `wired` / discovery `[name,state]`.

## E. VERIFIED — functional / privacy (impersonation, rollback-safe)

`ROLLBACK_OK: A_not_available A2_not_available B_ok=true_scope=tenant_kind=core_pp=open_keys=name|state_rl=false_caps=archive|edit|export|view C_ok=true D_scope_not_wired E_not_authorized`

| Case | Assertion | Result |
|---|---|---|
| A · subscription (platform, registered) | → `not_available` | ✅ |
| A2 · class (tenant, registered) | → `not_available` (status gate trước scope gate) | ✅ |
| B · school (tenant, wired) | ok · scope=tenant · fields ⊆ {name,state} · reason_logged=false · caps {edit,view,export,archive} · **no child/media/person** | ✅ |
| C · person (platform, wired) | ok — unaffected | ✅ |
| D · synthetic assignment-scope wired | → `scope_not_wired` | ✅ |
| E · non-admin | → `not_authorized` | ✅ |

*Synthetic registry row + mọi state impersonation rolled back — zero residue. (authenticated INSERT vào registry bị `42501` — confirm D349.4 admin-managed ACL.)*

## F. FROZEN

Registry schema + 7 CHECK (unchanged) · 4 platform projector (unchanged) · `get_school_overview` (tenant-operator RPC, KHÔNG đụng) · `admin_workspace_access_log` (KHÔNG đụng — school open) · existing tables/policies/triggers/roles · `profiles.permissions[]` · Bunny · routes · tooling · FE (`be04f4b`). Δ ròng = **+1 function** (`admin_lookup_school`) + 1 registry-row UPDATE.

## G. ROLLBACK

```sql
DROP FUNCTION IF EXISTS public.admin_lookup_school(uuid);
-- restore get_object_workspace pre-B2.2 (scope platform-only gate, remove school CASE)
UPDATE public.mission_control_object_registry
   SET projector_status='registered', discovery_fields=ARRAY['name','status']::text[],
       notes='Tenant root (B2.2).', updated_at=now()
 WHERE object_type='school';
NOTIFY pgrst, 'reload schema';
```
Additive undo; baseline → tail `20260811042807`. Logger + 4 platform projector + registry table KHÔNG đụng.

## H. CANONICALIZATION — DONE

- **D349 / v1.37 / HANDOFF V128-B2.0** — registry catalog (+1 table, 0 fn).
- **D350 / v1.38 / HANDOFF V128-B2.1** — adapter (+1 fn, logger capsule ext).
- **D351 / v1.39 / HANDOFF V128-B2.2** — school wiring (+1 fn, registry transition).

Grounded trên migration statements THẬT (`20260810150209`/`20260811042807`/`20260811080037`) + live re-pin — KHÔNG reconstruct từ trí nhớ. RULES tip D348→**D351** (1772→1828 lines); SYSTEM_MAP v1.36→**v1.39** header + version-log block.

## I. NEXT MILESTONE

**V128-B3+** — wire object registered kế tiếp. Ứng viên gần: `subscription`/`support_case` (platform, giống person — projector `admin_lookup_*` mới hoặc reuse) · `class` (tenant — nhưng **cần contract two-id**: school-context + class-id → mở câu hỏi adapter signature `p_context`/compound-id mà B2.2 đã khoanh OUT OF SCOPE). **Tenant two-id context = design gate trước B3 nếu wire class/session.** FE `ObjectWorkspaceModel` mapping cho scope='tenant' = track FE riêng (chưa làm). Backup debt: 3 migration B2.0/B2.1/B2.2 chưa commit vào repo.

---

**FINAL: ✅ V128-B2.2 — MIGRATION + VERIFICATION PASS · APPLIED · CANONICALIZED (D349–D351 / v1.37–v1.39).**
