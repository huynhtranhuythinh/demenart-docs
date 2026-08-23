# 🧾 DMA_HANDOFF_V128_M0.md — MISSION CONTROL OS SKELETON · OBJECT WORKSPACE CONTRACT · V128-M0

> **Sprint closeout (canonicalization)** — Ghi B0/B0.1 (Mission Control OS Skeleton) vào governance. Admin chuyển từ module-centric dashboard sang **object-centric OS**: renderer trung tính 5-band + contract seam, fixture-only, **zero backend, zero migration**. Đây là thao tác canonicalize (READ history + APPEND records), KHÔNG code/DB.
> **Đọc boot:** `DMA_RULES.md` → `DMA_SYSTEM_MAP.md` → HANDOFF mới nhất, rồi re-pin live DB inventory + `list_edits` + tooling pin trước khi làm.

---

## Executive Verdict

**`CANONICALIZED — DMA V128-M0 (Mission Control OS Skeleton).`** B0 (`a117bfd5`) dựng renderer 5-band domain-agnostic + contract + fixtures + shell + generic route; B0.1 (`8d70281d`) **revision contract** (thêm navigation `href` + `actor` + semantic intent); `be04f4b` restore bun.lock canonical 2.8.5. **Provenance forensic từ `get_diff` 3 commit + `read_file`@SHA + `list_edits`, KHÔNG từ commit message.** DB baseline FROZEN, 0 delta. B1 (Object Intelligence Architecture) là **DESIGN-ONLY**, chưa shipped — ghi làm design-locked chỉ thị cho B2+. Canonicalized RULES **D348** · SYSTEM_MAP **v1.36**.

## Endpoint

- **RULES:** D348 · **SYSTEM_MAP:** v1.36 · **HANDOFF:** V128-M0
- **Frontend HEAD (accepted tip):** `be04f4b486e277a260c594740d93cfd008d523db` (`be04f4b`) — "V128-B0.1 tooling recovery: restore bun.lock canonical 2.8.5" (`developer_update`)
- **Migration tail:** `20260810074214 v127_m4_2_5b_acl_hardening` — **BẤT BIẾN từ D347** (B0/B0.1 = 0 DB)
- **Tooling:** `@lovable.dev/vite-tanstack-config` pin `2.8.5` (package.json == bun.lock, 0 residue 2.9.x); guard `assert-tooling-governance.mjs` active

## Context

Trước V128: Admin là module-centric (grid `admin.modules` + registry `admin_modules`/`admin_module_groups`/`admin_module_links` + ~18 route mục-đích-đơn). Sản phẩm cần chuyển sang **object-centric Mission Control OS** — Find object → Understand context → Evaluate health → Execute permitted action → Review history. V128-B0/B0.1 dựng **khung** (renderer + contract) fixture-only để chứng minh renderer render object không phụ thuộc domain, chưa nối data thật.

## Completed (B0/B0.1 — frontend-only, verified via get_diff)

**B0 `a117bfd5` "Added Mission Control OS skeleton" (`ai_update`):**
- Contract `src/features/mission-control/contract/objectWorkspaceModel.ts` (v0).
- Fixtures `fixtures/demoObjects.ts` — `demo-alpha` (đủ 5 dải) + `demo-beta` (thiếu context/health), trung tính, 0 PII, 0 domain type thật.
- Renderer `renderer/ObjectWorkspace.tsx` (5 dải cố định, KHÔNG rẽ nhánh type) + `WorkspaceEmptyState.tsx` + 5 band (`IdentityBand`/`ContextBand`/`HealthBand`/`ActionsBand`/`HistoryBand`).
- Shell `shell/MissionControlShell.tsx` + `shell/CommandBarPlaceholder.tsx` (disabled, "Command Center — sắp mở").
- Routes: `admin.mission-control.tsx` (layout) + `admin.mission-control.index.tsx` (landing) + `admin.object.$type.$id.tsx` (generic renderer, `findDemoObject`). `routeTree.gen.ts` regen (2 route import + nav). `admin.tsx` +1 nav "Mission Control".

**B0.1 `8d70281d` "Applied V128-B0.1 contract" (`ai_update`) — CONTRACT REVISION (không phải "apply"):**
- `ObjectContext {key,label,value}` → `{kind,label,href?,meta[]}` (thêm **navigation**: href có = navigable, không = informational).
- `ObjectAction.intent "primary|neutral|caution"` → `"primary|default|danger"` (semantic).
- `HistoryEntry {key,at,label,detail}` → `{id,at,actor?,summary,kind?}` (thêm **actor** → Who).
- Cập nhật fixtures + `ContextBand`/`ActionsBand`/`HistoryBand` đồng bộ contract. 0 route mới, 0 backend.

**`be04f4b` "V128-B0.1 tooling recovery" (`developer_update`):**
- bun.lock restore canonical `2.8.5` (lockfile-only; `get_diff`="No changes" vì D339.5 ẩn lockfile). **HEAD.**

## Verified state (live re-pin, this session)

- **FE lineage (list_edits):** `8c0ca0a0` (V127-M4.2.5) → `a117bfd5` → `8d70281d` → **`be04f4b`** (HEAD).
- **DB (execute_sql):** **89 tables · 233 functions · 222 SECURITY DEFINER · 166 policies · 33 triggers · 1 cron · 16 Edge**. Migration tail `20260810074214`. **0 delta từ D347 — FROZEN confirmed.**
- **Tooling (read_file@`be04f4b`):** package.json `@lovable.dev/vite-tanstack-config: "2.8.5"` + bun.lock resolved `2.8.5`, **0 residue 2.9.x**. Build guard active.
- **Contract shape (get_diff):** v1 sau B0.1 revision — 5-band `{identity, contexts, health, actions, history}`; `ObjectAction` descriptor-only (no handler).

## Frozen decisions

- **D348.1** — Mission Control = object-centric OS; renderer domain-agnostic, 5 dải cố định KHÔNG rẽ nhánh type; module grid GIỮ (chưa retire).
- **D348.2** — `ObjectWorkspaceModel` = contract seam đóng băng; B0.1 là revision có chủ đích (đổi shape phải đi qua contract + fixtures + bands cùng lúc).
- **D348.3 (DESIGN-LOCKED, chưa shipped)** — Object Registry: ObjectType đóng ở registry, per-type projector, địa chỉ chung `/admin/object/<type>/<id>`.
- **D348.4 (DESIGN-LOCKED, chưa shipped)** — Capability = `has_permission(perm)` × object-scope-predicate; server authority; KHÔNG `role===admin`.
- **D348.5** — DB delta = 0 (frozen 89/233/222/166/33/1, tail `20260810074214`).
- **D348.6** — HEAD `be04f4b`; tooling 2.8.5; rollback = FE revert về `8c0ca0a0`.
- **Privacy/soul (giữ):** Forbidden objects (child journey/journal/skills/badges, family memory content, raw media bytes) KHÔNG BAO GIỜ là Mission Control object. Child-workspace open = reason-mandatory + logged (D345.2).

## Next milestone

- **B1 → design duyệt.** Object Intelligence Architecture report đã giao (DESIGN-ONLY). Chờ Owner chốt: (1) thứ tự object coverage cho B2 (★ School → Subscription → Support Case; Person/Child/Media/Capsule đã resolve); (2) child-in-search policy.
- **B2 (build kế, chờ authorize):** backend `resolve_object_candidates` + `get_object_workspace(type,id)` như **adapter** over `admin_lookup_*` + `get_person_workspace` + projector MỚI (School/Class/Subscription/Support). Additive, secdef, D15/D231 harden, D289 reload. **STOP-condition:** resolver school-scoping PHẢI có trước khi non-platform operator chạm Mission Control (cross-tenant risk).
- **B3/B4:** FE nối command bar → resolver thật; gấp module route thành object action/context; retire `admin.modules` chỉ khi mọi năng lực có object home.

## Governance / files exported (V128-M0)

3 file complete-replacement (append-only, prior bytes preserved):
1. `DMA_RULES.md` — +D348 block (prior 1752 dòng byte-identical).
2. `DMA_SYSTEM_MAP.md` — header pointer v1.35→v1.36 (line 9) + V128-M0 block (mọi dòng khác byte-identical).
3. `DMA_HANDOFF_V128_M0.md` — file này (mới).

**No source code / package / DB / migration / permission change.** Chỉ RULES + SYSTEM_MAP + HANDOFF.
