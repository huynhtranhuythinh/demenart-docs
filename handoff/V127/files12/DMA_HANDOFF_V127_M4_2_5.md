# 🧾 DMA_HANDOFF_V127_M4_2_5.md — SCHOOL PEOPLE WORKSPACE · IDENTITY PROJECTION · M4.2.5

> **Sprint closeout** — School operator thấy "ai tham gia trường + context + trách nhiệm" qua **projection layer** (không tạo Person model mới). A = Projection Contract · B = 2 projection RPC + ACL hardening · C = frontend People Workspace. **Mốc CUỐI của khối V127** — đóng trọn lỗ canonical V126→M2.4→M3.7→M4.2.5.
> **Đọc boot:** `DMA_RULES.md` → `DMA_SYSTEM_MAP.md` → HANDOFF mới nhất, rồi re-pin live DB inventory + `list_edits` + deployed signer trước khi làm.

---

## Executive Verdict

**`RECONSTRUCTED & CANONICALIZED — DMA V127-M4.2.5`.** A contract (0 migration) + B 2 projection RPC (secdef, anon-denied, aclexplode ✓) + C frontend commit `8c0ca0a0` (build tsgo=0/build=0, get_diff scope verified). **Provenance mạnh nhất trong 3 mốc reconstruct** (RPC body + aclexplode + get_diff + build — tất cả verified TRONG phiên). **Owner-Gate runtime QA CHƯA ghi nhận** — test accounts đã giao, chờ QA để nâng lên PASS. Canonicalized RULES **D347** · SYSTEM_MAP **v1.35**.

## Endpoint

- **RULES:** D347 · **SYSTEM_MAP:** v1.35 · **HANDOFF:** V127-M4.2.5
- **Frontend HEAD (accepted tip):** `8c0ca0a0f6bffe838f335c10f97417f2eb6ee0c0` (`8c0ca0a0`) — "Added People page to school"
- **Migration tail:** `20260810074214 v127_m4_2_5b_acl_hardening`
- **Signer / Bunny:** deploy-25 (v24) / 3 zone — bất biến; **tooling pin 2.8.5**

## A — Identity Projection Contract (design, 0 migration)

People Workspace là **projection read-only** từ `profiles` + `class_distributions`; KHÔNG tạo entity Person canonical mới, KHÔNG canonicalize identity. Projection layer là source duy nhất cho People Workspace.

## B — 2 projection RPC + ACL hardening (verified live)

- `get_school_people(p_school_id, p_query, p_limit)` → `{ok, school_id, people[{person_id, identity{name,email,phone}, contexts[{type:school}], responsibilities[{type:teaching,class_id,class_name,title}]}]}`.
- `get_person_workspace(p_school_id, p_person_id)` → `{ok, identity{id,name,email,phone}, contexts, responsibilities}` | `{ok:false, error:not_authorized|not_found}`.
- Cả hai: secdef, `search_path=public,pg_temp`, gate `is_admin() OR profile-in-school`, denial generic. `mig 20260810074045` CREATE + REVOKE PUBLIC + GRANT authenticated/service_role; `mig 20260810074214 acl_hardening` explicit `REVOKE EXECUTE … FROM anon` (D231). aclexplode live: authenticated/postgres/service_role only.

## C — Frontend People Workspace (commit 8c0ca0a0)

`src/features/people/**`: `people-adapter.ts` (pure, parse defensive) · `hooks/usePeopleSearch.ts` + `usePersonWorkspace.ts` (rpcUntyped cast, seq-guard, debounce) · 5 component (PersonCard/IdentityCard/ContextCard/ResponsibilityCard/EmptyState + contextLabels) · `PeopleDirectory.tsx` + `PersonWorkspace.tsx`. Routes `_authenticated/school.people.tsx` (`/school/people`) + `school.people_.$personId.tsx` (`/school/people/$personId`, opt-out nesting giữ school shell — mẫu `family_.memory.$cardId`). 1 nav item "Con người" trong `school.tsx`. `routeTree.gen.ts` plugin-generated. **Data flow Component→Hook→Adapter→RPC; KHÔNG query bảng trực tiếp; KHÔNG `profiles.role` render; contexts render động (KHÔNG bịa Family).** tsgo=0/build=0; tooling float caught + restore 2.8.5.

## DB / Delta

**+2 SECURITY DEFINER function; 0 table/policy/trigger/Edge.** Inventory verified live: **89 tables · 233 functions · 222 SECURITY DEFINER · 166 policies · 33 triggers · 1 cron · 16 Edge**. Migration tail `20260810052804` → `20260810074214`. **Rollback = DROP 2 RPC + FE revert** (route/nav/feature).

## V127 gap — CLOSED

Function 215→233 truy vết đủ, không dư không thiếu: **M2.4 +2 · M3.7 +14 · M4.2.5 +2**. secdef 204→222 tương tự. Canonical chain V126-M1 → V127-M2.4 → V127-M3.7 → V127-M4.2.5 liền mạch.

## Residual / next

- **Owner-Gate runtime QA People** (accounts đã giao: `hieutruong.kidshouse@demo.demenart.com` / `hieutruong.demen@demo.demenart.com`, `Test@123`) — chạy để nâng M4.2.5 lên Owner-Gate PASS.
- **Family context**: cần milestone **backend** riêng nếu muốn badge Family thật (FE đã sẵn render động, 0 sửa).
- Actor-matrix rollback-only QA cho các hàm mới M2.4/M3.7 (nếu cần bằng chứng hành vi runtime).
- Inherited: media compat MOV/HEVC/WebM · `/kid` Portal V2 · scale hardening (indexes/observability) trước commercial pilot.

---

**Trạng thái:** `RECONSTRUCTED & CANONICALIZED — DMA V127-M4.2.5`. RULES D347 · SYSTEM_MAP v1.35 · HANDOFF V127-M4.2.5 · HEAD `8c0ca0a0` · migration tail `20260810074214` · signer deploy-25 (v24) · tooling 2.8.5. V127 canonical gap CLOSED (V126→M2.4→M3.7→M4.2.5). Provenance M4.2.5: structural+build+ACL verified (phiên này); runtime QA pending.
