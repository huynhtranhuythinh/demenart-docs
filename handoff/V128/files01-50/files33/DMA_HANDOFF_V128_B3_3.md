# 🗂️ DMA_HANDOFF_V128_B3_3.md — MISSION CONTROL · PROGRAM THIRD CONTEXT CONSUMER — APPLIED · VERIFIED · CANONICALIZED

> **Ngày:** 2026-08-12 (GMT+7) · **Loại:** backend-only migration (PROGRAM third context consumer · platform-scoped · zero-context · identity-only `[name]` projector) · **Verdict: V128-B3.3 APPLIED — migration + POST verification PASS · CLOSED — ALL PASS · CANONICALIZED D356 / v1.44.**
> **Boot phiên sau:** file này → `DMA_RULES.md` (tip **D356**) → `DMA_SYSTEM_MAP.md` (**v1.44**) → audit live DB (D1) → re-pin `list_edits` (FE `be04f4b`, BẤT BIẾN backend-only).

---

## A. CANONICAL ENDPOINT

- **RULES:** **D356** · **SYSTEM_MAP:** **v1.44** · **HANDOFF:** **V128-B3.3**
- **Migration tail:** `20260812070542` → **`20260812190653`** (`v128_b3_3_program_context_consumer`, atomic apply SUCCESS)
- **FE HEAD:** `be04f4b` — **BẤT BIẾN** (backend-only; 0 FE / 0 Edge / 0 Bunny)
- **Inventory:** **90/241/230/166/33/1**
- **Package:** v8.4 (whole SHA `3665322e6056be9e95343484dbdf6957dd7a27112418b8b03989c723c9886d28`; §9 migration `77879867f43de276321443ca87593b4baab56bf3f1a1faa0335e23b63bf2c214`, 14,722 B)
- **Verdict:** `V128-B3.3 — CLOSED — ALL PASS` (Owner one-shot APPLY authorization **CONSUMED** — MUST NOT reuse; **DO NOT re-apply B3.3**).

## B. B3.3 CLOSED OUTCOME (verified live POST-APPLY)

- PROGRAM registered→**wired**. Projector **`admin_lookup_program(uuid)` PRESENT**; core CASE `WHEN 'program'` PRESENT; CLASS+SESSION branches PRESENT.
- Zero-context **platform** consumer; discovery `[name]`; **identity-only**; **IP-safe** (0 description/slug/curriculum/pricing).
- PRE: §4 drift gate PASS · §5 fail-closed resolver PASS · §7 `PRE_SELFCHECK_PASS` · §8 residue 0.
- POST: §11 ACL/inventory re-pin PASS · §12 `POST_SELFCOMPARE_PASS` diffcount=0 · §13 `P1_P13_PASS` · §14 assignment synthetic `dispatch_missing` · final audit/probe residue 0 · final fn 241.

## C. PRODUCTION INVENTORY (verified live)

**90 tables · 241 functions · 230 SECURITY DEFINER · 166 policies · 33 triggers · 1 cron.**

PRE→POST: `90/240/229/166/33/1` → **`90/241/230/166/33/1`**. Delta = **+1 fn** (`admin_lookup_program`) + **+1 SECURITY DEFINER** (same). Core = REPLACE in-place (0 net). tables/policies/triggers/cron BẤT BIẾN.

## D. REGISTRY EXACT SETS (17 rows · wired 8 / registered 3 / none 6)

- **wired (8):** `capsule`·`child`·`class`·`media`·`person`·**`program`**·`school`·`session`
- **registered (3):** `privacy_request`·`subscription`·`support_case`
- **none/forbidden (6):** `badges`·`child_journey`·`family_memory`·`journal`·`raw_media`·`skills`

Transition B3.3: wired **7→8** · registered **4→3** · none **6→6** (program-row UPDATE, không INSERT).

## E. MISSION CONTROL CONSUMER MAP (8 wired · scope/context)

| Object | Scope | Context | Projector |
|---|---|---|---|
| person·child·media·capsule | platform | zero (pre-seam objects) | admin_lookup_user/child/media/capsule |
| school | tenant | zero | `admin_lookup_school(uuid)` |
| class | tenant | required `school_id` | `admin_lookup_class(uuid,uuid)` |
| session | assignment | required `class_distribution_id` | `admin_lookup_session(uuid,uuid)` |
| **program** | **platform** | **zero-context** | **`admin_lookup_program(uuid)`** |

Seam demo cả ba scope (platform/tenant/assignment) + cả hai context mode (required + zero). Authorization = `is_admin()` DUY NHẤT; context = containment metadata, KHÔNG authorization (D352.5 NO-OP).

## F. PROGRAM EXACT CONTRACT

- `object_type=program` · kind=**supporting** · scope=**platform** · projector_status=**wired** · privacy_policy=**open**
- discovery_fields = **`[name]`** · capability_vocab = `{"edit":"program.edit","view":null}` · forbidden_groups = `[]`
- context_requirements = `{"version":1,"keys":{},"allow_unknown":false}` (**zero-context**)
- Projector `admin_lookup_program(p_program_id uuid)` → `{ok,program:{id,name}}` → adapter strip → `{name}`. secdef · owner postgres · `search_path=""` exact · EXECUTE `{authenticated,postgres,service_role}` · 0 PUBLIC/anon · `CREATE FUNCTION` (không OR REPLACE).
- Core CASE `WHEN 'program'` → `admin_lookup_program(p_object_id)` (zero-context, không v_ctx). CLASS+SESSION unchanged. Static dispatch. Scope allowlist = `platform / tenant / assignment`.
- Legacy 3-arg → **ok** (zero-context ⇒ empty context hợp lệ — KHÁC class/session vốn `context_invalid`).
- **IP-safe:** 0 description/slug/curriculum/lesson/pricing leak.

## G. REMAINING REGISTERED CANDIDATES + DEBT (KHÔNG wired; debt còn nguyên)

- **subscription** — registry scope chưa phản ánh tenant/school containment · discovery phantom columns · financial/privacy boundary cần governance riêng.
- **support_case** — discovery phantom `subject` · free-form message = sensitive-text/PII boundary · cần registry/security prep.
- **privacy_request** — discovery hiện valid NHƯNG growth về child/requester identity = D48 hazard · cần guardrail tường minh trước khi wire.

**KHÔNG silently giải bất kỳ debt nào trong/ngoài B3.3 closeout.** Registry-debt correction là công việc riêng, phải design/authorize tách bạch — KHÔNG bundle im lặng với consumer wiring.

## H. NON-GOALS / UNTOUCHED SURFACES

KHÔNG: content/curriculum/pricing exposure · privacy/financial/sensitive-text/entitlement seam · renderer/FE/Edge/Bunny · dynamic dispatch · new role model · RLS/policy change · `programs` schema change. `is_admin()` = authorization boundary DUY NHẤT; context authz slot NO-OP (D352.5). Static dispatch + fail-closed context validation + privacy moat = BẤT BIẾN.

## I. NEXT-TOPIC GATE

**KHÔNG pre-authorize B3.4/B4.** Milestone kế PHẢI bắt đầu bằng: **canonical boot → fresh live re-pin → drift verdict → remaining registered-object debt review → Owner/CTO decision** (next = **B3.4 registry-correction/preparation** cho `subscription`/`support_case`/`privacy_request`, HAY **B4**). KHÔNG chọn next consumer silently. Ràng buộc mang theo: **KHÔNG re-apply B3.3** · KHÔNG mutation nếu chưa có Owner gate mới · preserve static dispatch · preserve fail-closed context validation · preserve privacy moat · registry-debt correction KHÔNG bundle im lặng với consumer wiring (design/authorize riêng).

**Backup debt (mang theo):** migration files B3.0/B3.1/B3.1.5/B3.2/**B3.3** chưa commit vào repo (D90 dump-từ-live) — outstanding.

---

**FINAL: ✅ V128-B3.3 — PROGRAM THIRD CONTEXT CONSUMER — APPLIED · VERIFIED · CLOSED — ALL PASS · CANONICALIZED (D356 / v1.44 / HANDOFF V128-B3.3 · tail `20260812190653` · inventory 90/241/230/166/33/1 · registry 17: wired 8 / registered 3 / none 6). PROGRAM platform-scoped, zero-context, identity-only `[name]`, IP-safe. B3.4/B4 NOT OPENED.**


---

## J. V128-B4 CLOSEOUT — CANONICALIZED

**Canonical endpoint:** RULES **D357** · SYSTEM_MAP **v1.45** · HANDOFF **V128-B4**.

**Completed:**

- V128-B4.0 — CLOSED
- V128-B4.0.1 ACL Hardening — CLOSED
- V128-B4.1 Action Resolver Foundation — CLOSED
- V128-B4.1.1 Context Enforcement — CLOSED
- V128-B4.1.2 Session Valid-Path Acceptance Alignment — CLOSED

**Delivered:**

- Action Resolver Foundation
- Context Enforcement Layer
- Cross-context isolation
- Mission Control Object Capability Separation

**Final architectural decision:** SESSION remains a wired context object. No SESSION action surface is introduced.

**Invariant carried forward:** Projection, Context, Action, and Execution capabilities are independent. Context capability does not imply action capability. Action capability requires successful context validation. Caller-supplied context is never authoritative; authoritative context must be resolved from the object itself.

**Future guard:** Do not assume `wired = action-capable`. V128-B5 is NOT OPENED by this closeout.

**STEP 12.8 mutation boundary:** canonical artifact append only. No migration. No database mutation.

**FINAL: ✅ V128-B4 — ACTION RESOLVER + CONTEXT ENFORCEMENT + CAPABILITY SEPARATION — CLOSED · CANONICALIZED (D357 / v1.45 / HANDOFF V128-B4). V128-B5 NOT OPENED.**


---

## K. V128-B5.0.1 CLOSEOUT — CANONICALIZED

**Status:** PASS

**Production:** Dế Mèn Art

**Migrations:**

- `20260813073711` — `v128_b5_0_1_execution_contract_remediation`
- `20260813073937` — `v128_b5_0_1_execution_memory_actor_index`

**Final outcome:**

- Execution primitive operational.
- Authenticated executor boundary established.
- Idempotency implemented.
- Audit contract aligned.
- Concurrency invariant protected.
- Runtime acceptance passed.

**Runtime acceptance:** context isolation · permission boundary · anonymous denial · replay protection · conflict handling · RLS isolation — ALL PASS.

**Canonical endpoint:** RULES **D358** · SYSTEM_MAP **v1.46** · HANDOFF **V128-B5.0.1**.

**Closeout guard:** V128-B5.0.1 is CLOSED. V128-B5.1 is NOT OPENED.

**FINAL: ✅ V128-B5.0.1 — EXECUTION CONTRACT REMEDIATION — PRODUCTION PASS · RUNTIME ACCEPTANCE PASS · CLOSED · CANONICALIZED (D358 / v1.46 / HANDOFF V128-B5.0.1).**


---

## L. V128-B6.0.1 CLOSEOUT — ARTIFACT SYNC + CANONICALIZED

**Status:** PASS — CLOSED + CANONICALIZED

**Production:** `xcvhacymrbhdhohyylyq` — Dế Mèn Art — PostgreSQL 17.6

**Repository re-pin:**

- Authority: `DMA/99-Repo/demenart`
- Branch / HEAD: `main` / `be04f4b486e277a260c594740d93cfd008d523db`
- Pre-sync working tree: clean
- Generated authority: `src/integrations/supabase/types.ts`
- Exact Supabase-generated sync, no manual edits
- Old: `100,970 B` · SHA-256 `da30c4695e5caba8bce83032d5ead496112643076a219be09d20d2584a3a6f17`
- New: `186,270 B` · SHA-256 `635eec14a708208c68b8d6cbff4803f9140e557d77e862116fb9ae7056a64dee`
- Repo diff: only generated `types.ts` (+3,484 / −605); declarations include `get_mission_control_workspace`, `get_mission_control_actions`, `get_mission_control_memory`, and `execute_mission_control_action`.

**Applied migrations:**

- `20260813113248` — `v128_b6_0_1_mission_control_presentation_read_contracts`
- `20260813113400` — `v128_b6_0_1_workspace_state_projection_fix`

**Delivered contracts:**

- `get_mission_control_workspace(text,uuid) returns jsonb`
- `get_mission_control_actions(text,uuid) returns jsonb`
- `get_mission_control_memory(text,uuid,integer,timestamptz) returns jsonb`

All three are `STABLE` · `SECURITY DEFINER` · owner `postgres` · `search_path=""`; EXECUTE only `authenticated,postgres`; 0 `PUBLIC/anon/service_role`; authenticated identity and domain authorization enforced inside the function.

**Runtime acceptance:** authenticated same-school admin success · workspace identity/context/state/capabilities PASS · actions expose `class.assign` only with `MissionActionInputSchema/v1` and authorized options · memory projection/pagination PASS · anonymous/non-admin/unsupported/nonexistent/invalid-limit boundaries fail closed · B5 compatibility PASS.

**Live inventory:** **92 tables · 248 functions · 236 SECURITY DEFINER · 169 policies · 33 user triggers · 1 cron.**

**Canonical endpoint:** RULES **D359** · SYSTEM_MAP **v1.47** · HANDOFF **V128-B6.0.1**.

**Mutation boundary:** generated Supabase types sync + append-only canonical artifacts only. No frontend code, no new database migration, no executor/handler/registry/table redesign, no new action.

**Next milestone prepared:** **V128-B6.1 — Class Workspace Vertical Slice FE Implementation**. This closeout does **not** start FE coding.

**FINAL: ✅ V128-B6.0.1 — DATABASE + SECURITY + RUNTIME + GENERATED TYPES + CANONICAL ARTIFACTS — ALL PASS · CLOSED · CANONICALIZED (D359 / v1.47 / HANDOFF V128-B6.0.1). V128-B6.1 NEXT; FE CODING NOT STARTED.**

