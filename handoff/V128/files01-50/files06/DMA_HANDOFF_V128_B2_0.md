# 🗂️ DMA_HANDOFF_V128_B2_0.md — MISSION CONTROL OBJECT REGISTRY FOUNDATION — ĐÓNG

> **Ngày:** 2026-08-10 (GMT+7) · **Loại:** backend-only migration (catalog table) + canonicalization · **Verdict: V128-B2.0 CLOSED — migration verification PASS.**
> **Đọc boot phiên sau (theo thứ tự):** `DMA_HANDOFF_V128_B2_0.md` (file này) → `DMA_RULES.md` (tip **D349**) → `DMA_SYSTEM_MAP.md` (**v1.37**) → **audit live DB (D1 — không tin số trong tài liệu)** → re-pin `list_edits` (FE tip `be04f4b`, BẤT BIẾN — backend-only).

---

## A. VERDICT

**`V128-B2.0 CLOSED — MIGRATION VERIFICATION PASS`.** `mission_control_object_registry` (catalog-only) tạo + seed 17 dòng + ACL hardening, `apply_migration` transactional với BLOCK 3 VERIFY (RAISE = rollback guard) → `success`. Forensic re-audit độc lập sau apply: 100% khớp contract. Hai live-drift (RLS platform-auto ON · service_role full-CRUD qua D231) ghi nhận tường minh, cả hai an toàn (strictly more-restrictive / standard-DMA), Owner-acknowledged. **KHÔNG proceed B2.1** cho tới khi B2.0 canonicalized.

## B. ENDPOINT

- **RULES:** D349 · **SYSTEM_MAP:** v1.37 · **HANDOFF:** V128-B2.0
- **Migration:** `v128_b2_0_mission_control_object_registry` · version **`20260810150209`** (= migration tail)
- **Frontend HEAD (accepted tip):** `be04f4b` — **BẤT BIẾN** (backend-only, 0 FE delta)
- **DB inventory (re-verified live sau apply):** **90 tables · 233 functions · 222 SECURITY DEFINER · 166 policies · 33 triggers · 1 cron · 16 Edge**
- **Signer / Bunny / routes / tooling:** BẤT BIẾN (0 delta)

## C. CONTEXT

V128 mở tầng **Mission Control object-model**: một catalog khai báo để trang `/admin/object/<type>/<id>` biết object nào tồn tại, projectable tới đâu, và object nào **cấm tuyệt đối** (child/family-owned). B2.0 = **nền móng dữ liệu thuần** — CHƯA có adapter, CHƯA có UI. Ranh giới cứng: catalog-only, 0 logic, 0 executable string; dispatch `type → projector RPC` sẽ sống trong CASE tường minh của `get_object_workspace` (B2.1), KHÔNG `EXECUTE format(...)`.

## D. COMPLETED (session này)

1. **Precheck read-only (D1):** live baseline 89·233·222·166·33·1 · tail `20260810074214` · registry table absent — khớp package frozen baseline (HEAD `be04f4b`).
2. **Migration apply:** `v128_b2_0_mission_control_object_registry`, byte-exact từ `DMA_V128_B2_0_REGISTRY_IMPLEMENTATION_PACKAGE.md` §4 (D92 three-block). 0 rewrite, 0 addition.
   - **BLOCK 1:** CREATE TABLE (12 cột) + COMMENT + INSERT 17 seed.
   - **BLOCK 2:** REVOKE ALL FROM PUBLIC/anon/authenticated + GRANT SELECT service_role + `NOTIFY pgrst`.
   - **BLOCK 3:** DO $verify$ — 8 assertion, RAISE = atomic rollback guard.
3. **Post-apply forensic re-audit (độc lập, không tin report trước):** toàn bộ PASS.
4. **Canonicalization:** D349 (RULES) + v1.37 block (SYSTEM_MAP) + handoff này.

## E. VERIFIED (live, forensic)

**Bảng `mission_control_object_registry`** — 12 cột · PK(`object_type`) + **7 CHECK** (`mcor_kind_chk`, `mcor_scope_chk`, `mcor_privacy_chk`, `mcor_projstat_chk`, `mcor_scope_req_chk`, `mcor_forbidden_noproj_chk`, `mcor_forbidden_restrict_chk`).

**Seed 17** — projector_status: **4 wired** (`person`, `child`, `media`, `capsule`) · **7 registered** (`school`, `subscription`, `support_case`, `class`, `session`, `program`, `privacy_request`) · **6 forbidden→none** (`child_journey`, `journal`, `skills`, `badges`, `family_memory`, `raw_media`). kind: **6 core / 5 supporting / 6 forbidden**.

**Forbidden shape (defense-in-depth):** cả 6 dòng = `projector_status='none'` ∧ `privacy_policy='restricted'` ∧ `scope IS NULL` ∧ `forbidden_groups={'*'}` → 0 dòng lệch. Non-forbidden đều có scope → 0 dòng lệch.

**ACL / security boundary:** anon SELECT = **false** · authenticated SELECT = **false** · PUBLIC = 0 grant (`role_table_grants` client rows = 0) · service_role SELECT = **true**. Client KHÔNG SELECT trực tiếp → đọc chỉ qua SECURITY DEFINER adapter (B2.1).

**Executable-string audit:** cột duy nhất khớp `~*'(projector|function|rpc|exec)'` = `projector_status` (cờ, KHÔNG phải tên hàm). 0 dynamic-execution surface.

**Inventory sau apply:** 90 tables (89→90, chỉ +registry) · 233 functions · 222 SECURITY DEFINER · 166 policies · 33 triggers · 1 cron · 16 Edge.

## F. LIVE DRIFT (D112 — Owner-acknowledged, cả hai an toàn)

1. **RLS platform-auto ON.** SQL applied để dòng `ENABLE ROW LEVEL SECURITY` **comment** (đúng draft), nhưng live `relrowsecurity=true` (0 policy, `relforcerowsecurity=false`) — Supabase tự bật RLS trên bảng public mới. Hệ quả: deny-by-default cho role chịu RLS — **strictly more-restrictive**, khớp D14 belt-and-suspenders. Policy count nguyên (166). KHÔNG do migration SQL.
2. **service_role full CRUD (không SELECT-only).** BLOCK 2 `GRANT SELECT TO service_role` nhưng không revoke các quyền auto-grant D231 (INSERT/UPDATE/DELETE/TRUNCATE) → service_role giữ full CRUD. Byte-exact với package; khớp posture mọi bảng DMA (service_role trusted, BYPASSRLS). Predicate `service_role SELECT=true` thoả; client boundary (anon/auth/PUBLIC=0) nguyên — **0 client-facing leak**.

> **Nếu Owner muốn khớp literal draft:** (a) `ALTER TABLE ... DISABLE ROW LEVEL SECURITY;` để RLS off, và/hoặc (b) `REVOKE INSERT,UPDATE,DELETE,TRUNCATE ON ... FROM service_role;` để read-only. **CHƯA làm** — ngoài scope, chờ chỉ định.

## G. FROZEN (bất biến khi B2.0)

Existing tables · functions (233) · policies (166) · triggers (33) · roles · `profiles.permissions[]` · RLS policy của mọi bảng khác · 5 wrap-target RPC · Edge (16) · Bunny · routes · tooling (2.8.5) · Frontend (HEAD `be04f4b`). Delta ròng = **+1 table**.

## H. ROLLBACK

```sql
DROP TABLE IF EXISTS public.mission_control_object_registry;  -- 0 FK ref, không cascade
NOTIFY pgrst, 'reload schema';
```
Additive tuyệt đối · zero residue · baseline về `be04f4b` / tail `20260810074214`. `apply_migration` transactional: nếu BLOCK 3 RAISE → toàn migration rollback nguyên tử, KHÔNG ghi `schema_migrations`.

## I. NEXT MILESTONE

**V128-B2.1 — `get_object_workspace` adapter (projector dispatch).** SECURITY DEFINER, đọc catalog + dispatch `object_type → projector RPC` bằng **CASE tường minh** (KHÔNG `EXECUTE format`), reject forbidden bằng dữ liệu catalog. **CHƯA mở.** Pre-flight bắt buộc: audit RPC hiện hữu + ACL (aclexplode) + pinned search_path trước implementation (multi-agent session mode V127+). **KHÔNG bắt đầu B2.1 tới khi B2.0 CANONICALIZED** (D349 + v1.37 ghi vào file thật, byte-verified).

---

**FINAL: ✅ V128-B2.0 — MIGRATION VERIFICATION PASS · MILESTONE CLOSED.** Cập nhật "tới đâu ghi tới đó" (KỶ LUẬT VÀNG).
