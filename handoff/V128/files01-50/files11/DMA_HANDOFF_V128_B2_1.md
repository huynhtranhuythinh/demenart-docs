# 🗂️ DMA_HANDOFF_V128_B2_1.md — MISSION CONTROL WORKSPACE ADAPTER — APPLIED & VERIFIED

> **Ngày:** 2026-08-11 (GMT+7) · **Loại:** backend-only migration (adapter + logger extension) · **Verdict: V128-B2.1 APPLIED — migration + functional verification PASS.**
> **Boot phiên sau:** file này → `DMA_RULES.md` (tip **pending D350**) → `DMA_SYSTEM_MAP.md` (**pending v1.38**) → audit live DB (D1) → re-pin `list_edits` (FE `be04f4b`, BẤT BIẾN).

---

## A. VERDICT

**`V128-B2.1 APPLIED — VERIFICATION PASS`.** Adapter `get_object_workspace(text,uuid,text)` tạo + logger `admin_workspace_access_log` mở rộng additive (`capsule`). Migration transactional (BLOCK 1a→1b→2→3), BLOCK 3 VERIFY pass in-tx. Post-commit functional verification (impersonate super_admin, real pilot UUIDs, rollback-safe): **child_ok · capsule_ok · media_ok · person_ok · guards_ok · nonadmin_ok**, zero residue.

## B. ENDPOINT

- **Migration:** `v128_b2_1_get_object_workspace_adapter` · tail `20260810150209` → **`20260811042807`**
- **FE HEAD:** `be04f4b` — **BẤT BIẾN** (backend-only, 0 FE)
- **Canonical (PENDING):** RULES **D350** · SYSTEM_MAP **v1.38** · HANDOFF **V128-B2.1** — *chờ 2 file thật để ghi byte-exact (xem §H)*
- **DB inventory (live sau apply):** **90 tables · 234 functions · 223 SECURITY DEFINER · 166 policies · 33 triggers · 1 cron**

## C. COMPLETED

1. **Precheck (D1):** tail `20260810150209`, 233 fn / 222 secdef, adapter absent, logger present (no capsule), wired-set `[capsule,child,media,person]`.
2. **Migration apply** (byte-exact FINAL APPLY PACKAGE v3):
   - BLOCK 1a: `CREATE OR REPLACE admin_workspace_access_log` — +`capsule` (action `ADMIN_OPEN_CAPSULE_WORKSPACE`, reason-required), child/parent byte-preserved.
   - BLOCK 1b: `CREATE get_object_workspace` — SECURITY DEFINER, `search_path=''`, is_admin gate, static CASE, allowlist filter, 2 leak-guard, fail-closed reason-log, `WorkspaceProjectionDTO/v1`.
   - BLOCK 2: ACL deterministic (REVOKE PUBLIC/anon/authenticated/service_role → GRANT authenticated/service_role) cho **cả 2** hàm + `NOTIFY pgrst`.
   - BLOCK 3: transactional VERIFY (struct, no-dynsql, ACL-no-anon, logger capsule + regression, wired-set) → PASS.
3. **Post-commit verification** (super_admin impersonation, UUID pilot thật): xem §E.

## D. VERIFIED — structural (live)

- functions 233→**234** · secdef 222→**223** · tables/policies/triggers bất biến (90/166/33).
- `get_object_workspace` ACL = `{postgres, authenticated, service_role}` EXECUTE · **0 anon · 0 PUBLIC**.
- `admin_workspace_access_log` ACL = `{postgres, authenticated, service_role}` EXECUTE · **0 anon · 0 PUBLIC** (deterministic v3 hardening confirmed).

## E. VERIFIED — functional / privacy (impersonation, rollback-safe)

`ROLLBACK_OK: child_ok capsule_ok media_ok person_ok guards_ok nonadmin_ok`

| Case | Assertion | Result |
|---|---|---|
| child + reason | fields ⊆ {full_name,nickname,state}; 0 forbidden group; reason_logged | ✅ |
| child no reason | → `reason_required` | ✅ |
| capsule + reason | ok (fail-closed ⇒ audit committed); **no `items`**; fields ⊆ {scope,domain,window_code}; reason_logged | ✅ |
| capsule no reason | → `reason_required` | ✅ |
| media | fields ⊆ {file_type,state}; **no linked_child** | ✅ |
| person | fields ⊆ {full_name,email,role,state}; **no permissions** | ✅ |
| forbidden (`journal`) | → `forbidden_object` | ✅ |
| registered (`school`) | → `not_available` | ✅ |
| unknown type | → `unknown_object_type` | ✅ |
| non-admin (unknown sub) | → `not_authorized` | ✅ |

*Mọi mutation (capsule audit row) rolled back — zero residue.*

## F. FROZEN

Registry (17 rows, unchanged) · 5 wired projector RPC (unchanged) · existing tables/policies/triggers/roles · `profiles.permissions[]` · Bunny · routes · tooling · FE (`be04f4b`). Delta ròng = **+1 function** (`get_object_workspace`) + **1 additive extension** (`admin_workspace_access_log`).

## G. ROLLBACK

```sql
DROP FUNCTION IF EXISTS public.get_object_workspace(text, uuid, text);
-- + restore admin_workspace_access_log to pre-B2.1 (child/parent-only) body — see FINAL APPLY PACKAGE v3 §1.8
NOTIFY pgrst, 'reload schema';
```
Additive undo; baseline → tail `20260810150209`.

## H. CANONICALIZATION — PENDING (blocker)

Không thể ghi `DMA_RULES.md` (D350) và `DMA_SYSTEM_MAP.md` (v1.38) byte-exact vì **chưa có file current-tip thật**. Đang treo **cả hai** milestone:
- **B2.0:** D349 / SYSTEM_MAP v1.37 (từ trước).
- **B2.1:** D350 / SYSTEM_MAP v1.38 / HANDOFF V128-B2.1.

**Cần Owner upload `DMA_RULES.md` (tip D348) + `DMA_SYSTEM_MAP.md` (v1.36).** Có 2 file → ghi lần lượt D349+D350 và v1.37+v1.38 byte-preserving, kèm proof prefix bất biến.

## I. NEXT MILESTONE

**V128-B2.2** — wire `school` (registered→wired): verify `get_school_overview` gate (audit B2.1 §6 flag), thêm CASE branch + tenant scope routing (scope='tenant' → `get_person_workspace`-style với school context). Pre-flight audit trước. Frontend `ObjectWorkspaceModel` mapping layer (tiêu thụ `WorkspaceProjectionDTO/v1`) = FE track riêng.

---

**FINAL: ✅ V128-B2.1 — MIGRATION + VERIFICATION PASS · APPLIED.** Canonical (D350/v1.38) chờ 2 file thật.
