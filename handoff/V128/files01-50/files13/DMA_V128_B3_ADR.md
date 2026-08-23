# 🧭 DMA_V128_B3_ADR.md — MISSION CONTROL COMMAND SYSTEM — ARCHITECTURE DECISION RECORD

> **Loại:** DESIGN-ONLY ADR (0 code · 0 migration · 0 FE). **Chưa apply.**
> **Ngày:** 2026-08-11 (GMT+7) · **Tác giả:** Claude (Technical Auditor/PM) · **Chờ:** Owner Gate (ChatGPT CPO/CTO/Release Authority) trước khi mở B3.0.
> **Endpoint neo (BẤT BIẾN khi viết ADR này):** RULES **D351** · SYSTEM_MAP **v1.39** · HANDOFF **V128-B2.2** · code HEAD **`be04f4b`** · migration tail **`20260811080037`**.

---

## 0. RE-PIN LIVE (D1 — audit thật, không từ trí nhớ)

Verify trong phiên này qua Supabase MCP (read-only):

| Trục | Canonical D351 | Live (re-pinned) | Verdict |
|---|---|---|---|
| tables | 90 | **90** | ✅ |
| functions | 235 | **235** | ✅ |
| secdef | 224 | **224** | ✅ |
| policies | 166 | **166** | ✅ |
| triggers | 33 | **33** | ✅ |
| cron | 1 | **1** | ✅ |
| migration tail | `20260811080037` | **`20260811080037`** | ✅ |

**Zero drift.** Registry live = **17 rows** · **5 wired** (person/child/media/capsule=platform + school=tenant) · **6 registered** (subscription/support_case/class/session/program/privacy_request) · **6 forbidden**.

**Adapter contract live (verbatim `pg_get_functiondef`):**
```
get_object_workspace(p_object_type text, p_object_id uuid, p_reason text DEFAULT NULL) RETURNS jsonb
  SECURITY DEFINER · search_path='' · ACL {authenticated,postgres,service_role} · 0 anon/public
```
Gate order live: `is_admin` → `unknown_object_type` → `forbidden_object` → `not_available` → `scope_not_wired`(scope∉{platform,tenant}) → `reason_required` → access-log(nếu needs_reason) → **static CASE dispatch** (person/child/media/capsule/school; ELSE `dispatch_missing`) → projector-ok → allowlist filter → `ADAPTER_ALLOWLIST_VIOLATION` guard → `ADAPTER_FORBIDDEN_LEAK` guard → **DTO/v1**.

**Hygiene note (không phải B3 blocker):** `admin_lookup_child/user/media/capsule` (P0B đời cũ) chạy `search_path=public`; chỉ B2.1/B2.2 fns (`get_object_workspace`, `admin_lookup_school`, `admin_workspace_access_log`) dùng `search_path=''`. Fold vào B3.1 re-harden khi có Owner Gate chạm projector — KHÔNG đụng ngoài gate.

---

## 1. VẤN ĐỀ — command layer là greenfield

Đọc adapter body verbatim cho thấy sự thật: **toàn bộ MC hiện tại là READ/projection.** Bản đồ **Object → Action → Permission → Audit → Rollback**:

| Tầng | Trạng thái hôm nay | Bằng chứng |
|---|---|---|
| **Object** | ✅ DONE (B2) | registry + adapter, 5 wired |
| **Action** | ❌ KHÔNG có | `capabilities` trong DTO chỉ là `capability_vocab` static echo (`{edit,view,assign,export,archive}`) — vocabulary thuần, **0 executor** |
| **Permission** | ❌ design-locked, chưa ship | D348.4 (`has_permission × scope-predicate`) là chỉ thị thiết kế, **0 code** |
| **Audit** | ⚠️ một nửa | `admin_workspace_access_log` = **READ-access log** (ai NHÌN); `write_audit_log` (D345.1) = domain security ledger. **KHÔNG có** command-envelope audit |
| **Rollback** | ❌ KHÔNG có | không nơi nào |

→ B3 = thiết kế **write-twin** của read chokepoint, giữ nguyên triết lý "single chokepoint + static CASE + privacy moat + fail-closed", mở rộng cho mutation.

**Chặn cứng trước khi build:** hai design gate phải chốt — (A) **tenant two-id contract** (B2.2 đã khoanh OUT OF SCOPE, giờ đến hạn), (B) **command chokepoint shape**. ADR này giải cả hai.

---

## 2. DESIGN GATE A — TENANT TWO-ID CONTRACT

### 2.1 Bản chất vấn đề (grounded trên cột thật)
- `school` (tenant root): `object_id = school_id = tenant_id` — **tự định danh, single-id đúng.** B2.2 quyết định giữ single-id cho school là **ĐÚNG, KHÔNG hồi tố.**
- `class` (scope=tenant): `classes.school_id` — 1 hop tới tenant. object_id=class_id resolve được, nhưng authority phải bind school_id.
- `session` (scope=assignment): `lesson_sessions.class_distribution_id → class_distributions.class_id → classes.school_id` — **2 hop** + responsibility (`taught_by`/`lead_teacher_id`, D324/D346).

### 2.2 Tension: derive-tenant vs explicit-tenant
- **Derive (single-id):** adapter resolve object → đọc `school_id` → check membership. **Lỗi thế trận:** phải *chạm row trước khi check* → coupling authz vào resolution, phá "check-before-touch" fail-closed ordering. Với definer + generic denial thì chưa lộ existence, nhưng ordering sai là nợ bảo mật.
- **Explicit (two-id):** caller cấp `tenant_id` cạnh `object_id`. Adapter check `membership(caller, tenant_id)` **TRƯỚC** resolve, rồi assert `object.school_id = tenant_id` (chống IDOR/id-swap cross-tenant). Đúng thế trận, khớp DMA moat discipline (generic denial, privacy-by-source, fail-closed).

### 2.3 ★ QUYẾT ĐỊNH (đề xuất — chờ Gate)

**★ G1 — Context seam = `p_context jsonb DEFAULT NULL` (additive trailing param), KHÔNG typed `p_tenant_id uuid`, KHÔNG compound-id.**
- Lý do: `session` (assignment) cần **>1 id phụ** (school + có thể class/distribution). Typed second-uuid sẽ ép **phá signature lần nữa** khi wire session. `jsonb` = một seam forward-compatible, **đổi signature MỘT lần duy nhất**. Khớp nguyên tắc #7 (registry-driven/self-describing) + D348.2 (contract seam đổi có chủ đích, một lần).
- Registry thêm cột `context_requirements text[]` (vd `{tenant_id}` cho class, `{tenant_id}` hoặc `{tenant_id,class_id}` cho session). Adapter validate context **generic theo registry**, KHÔNG per-CASE → giữ domain-agnostic (D348.1).

**★ G2 — Tenant/assignment scope YÊU CẦU context tường minh, KỂ CẢ platform admin.**
- platform scope: `p_context` bỏ qua (NULL hợp lệ).
- tenant root (school): context optional; nếu có, `context->>'tenant_id'` **phải =** `p_object_id` (consistency guard).
- tenant child (class): `context->>'tenant_id'` **BẮT BUỘC**; check predicate trước dispatch; projector assert belongs-to; lệch → `not_found` (generic, không lộ existence).
- assignment (session): context mang `{tenant_id[,class_id]}`; predicate `is_session_responsible`/`is_teacher_in_school`.
- Belt-and-suspenders: dù hôm nay adapter `is_admin`-platform-only (context "thừa" cho authz), vẫn require sớm để (a) chống IDOR, (b) sẵn khi MC mở cho school-operator (D348.4), (c) contract ổn định không phá về sau.

**Hệ quả:** school KHÔNG đổi (vẫn single-id, B2.2 đứng vững). Context seam ra đời **additive ở thời điểm wire tenant-child đầu tiên (class)** — đây là B3 gate, KHÔNG phải B2 regression.

---

## 3. DESIGN GATE B — COMMAND ARCHITECTURE (Object → Action → Permission → Audit → Rollback)

Nguyên tắc trụ: **write chokepoint = sinh đôi của read chokepoint.** Một hàm, static CASE, fail-closed, server-authority, client-blind.

### 3.1 Command chokepoint (đề xuất)
```
execute_object_command(
  p_object_type text, p_object_id uuid, p_command text,
  p_args jsonb DEFAULT '{}', p_context jsonb DEFAULT NULL, p_reason text DEFAULT NULL
) RETURNS jsonb   -- CommandResultDTO/v1
  SECURITY DEFINER · search_path='' · ACL {authenticated,postgres,service_role}
```

**Gate order (write-twin, fail-closed):**
1. `is_admin()` (tương lai: `is_authorized_operator`) → `not_authorized`
2. registry lookup → `unknown_object_type`
3. forbidden/none → `forbidden_object`
4. registered → `not_available` (chưa projector ⇒ chưa command)
5. scope gate (platform/tenant/assignment khi wired) → `scope_not_wired`
6. **command validity:** `p_command` ∈ capability_vocab[object] → `unknown_command`
7. **context binding (Gate A):** validate `p_context` theo `context_requirements` + tenant predicate → `context_required` / `tenant_mismatch`
8. **permission (Gate: D348.4):** `has_permission(caller, cap.permission)` **×** `scope_predicate(scope, context)` → `permission_denied`. **Server là authority tính enabled/disabledReason** (mirror D290/D293); client mù.
9. **reason gate:** mọi command **mutating** ⇒ reason bắt buộc (xem G6) → `reason_required`
10. **precondition guard:** invariant per-command (vd không archive school còn subscription active) — khai báo trong cap descriptor hoặc executor-side → `precondition_failed`
11. **AUDIT pre-write:** ghi ledger `status='attempted'` (actor, object, command, args, context, reason, before-snapshot)
12. **static CASE dispatch** → command executor (write projector). **KHÔNG dynamic SQL.** Thêm command = thêm CASE branch tường minh (mirror D350.2).
13. **AUDIT post-write:** update ledger `status='committed'` + after-snapshot + `rollback_token`
14. return **CommandResultDTO/v1** `{ok, command, object_type, object_id, audit_id, rollback_token?, effect_summary, reason_logged}`

### 3.2 ★ G3 — ROLLBACK = inverse-command (compensating action), KHÔNG snapshot-restore
- Mỗi command khai báo **inverse** trong descriptor (`archive↔restore`, `assign↔unassign`). Rollback = chạy inverse với `audit_id` làm authorization.
- **Command KHÔNG đảo được ⇒ CẤM ở tầng registry** (không bao giờ có capability entry). Trùng khít LINH HỒN + ràng buộc vận hành: **MC không hard-delete; chỉ archive (soft-state).** Rollback do đó **luôn an toàn** vì destructive op bị loại từ thiết kế.
- Snapshot-restore bị loại làm default: nặng + last-write-wins clobber concurrent edit.

### 3.3 ★ G4 — Audit = HAI ledger, tách concern (READ vs WRITE)
- `admin_workspace_access_log` (đã có) = **READ-access** (ai NHÌN) — giữ nguyên.
- `mission_control_command_log` (MỚI, append-only, ACL admin-managed như registry D349.4) = **command envelope + rollback linkage** (ai THAY ĐỔI). Cột: actor_id, object_type, object_id, tenant_context jsonb, command, args jsonb, reason, before_state jsonb, after_state jsonb, status(attempted/committed/failed/rolled_back), `inverse_of uuid` (self-ref rollback), created_at.
- **KHÔNG hai nguồn sự thật (nguyên tắc #5):** domain event vẫn đi qua `write_audit_log` (D345.1) trong executor; command-log chỉ thêm **envelope meta + rollback token** lên trên. Executor archive gọi routine domain (routine tự `write_audit_log`) → MC bọc envelope. Không nhân đôi domain audit.

### 3.4 ★ G5 — Permission source = mở rộng `capability_vocab` thành per-command descriptor
- Từ vocab phẳng `{edit,view,...}` → descriptor: `{"archive":{"permission":"school.archive","scope_predicate":"is_school_admin","reason":"required","inverse":"restore","mutating":true}, ...}`.
- Registry vẫn là **single source** (nguyên tắc #7). Thêm command = 1 registry entry + 1 CASE executor + 1 CASE inverse. **Renderer domain-agnostic (D348.1) không đổi:** đọc descriptor, hiện enabled/disabledReason (server-computed), không tính enablement client-side.

### 3.5 ★ G6 — Reason policy write ≠ read (asymmetric)
- Read: chỉ object nhạy cảm (`reason_required`/`restricted`) cần reason.
- Write: **MỌI command mutating cần reason** bất kể privacy object (write cao rủi ro hơn read). Non-mutating command (export?) — Gate quyết riêng.

---

## 4. BUILD PATH B3.x (mỗi bước = design → Owner Gate → apply → verify → canonicalize; D92 three-block; D15/D231 re-harden; D289 NOTIFY)

| Phase | Nội dung | Delta | Reversible |
|---|---|---|---|
| **B3.0** | Context seam: `p_context jsonb` additive vào `get_object_workspace` + registry cột `context_requirements` + validator generic. **Wire 0 object mới** — chỉ chứng minh seam trên object đã wired (school context=self/NULL; person/media ignore). Read-only. | +1 col, adapter REPLACE | DROP col + restore adapter |
| **B3.1** | Wire **class** (tenant-child đầu tiên): projector `admin_lookup_class(uuid, jsonb)` identity-only + belongs-to assert; registry class→wired, `context_requirements={tenant_id}`. Fold search_path='' hygiene khi chạm projector cũ (Gate). Read-only. | +1 fn, registry 1-row | DROP fn + registry revert |
| **B3.2** | **Command ledger + chokepoint skeleton:** table `mission_control_command_log` + `execute_object_command` gate 1–10 + audit, nhưng capability_vocab khai báo **0 mutating command** (dry-run/no-op dispatch). Chứng minh chokepoint + audit **không mutation thật**. | +1 table +1 fn | DROP cả hai |
| **B3.3** | **First reversible command** (archive↔restore) trên object an toàn (school/subscription), Owner-gated. Thiết lập pattern rollback end-to-end. | executor + inverse CASE | inverse-command |
| **B3.4+** | Mở rộng command vocab per object — luôn reversible, luôn registry-declared. | incremental | inverse-command |

FE `ObjectWorkspaceModel` (B0.1 `ObjectAction` descriptor đã có seam `enabled`/`disabledReason`, KHÔNG handler) = **track FE riêng**, tiêu thụ capabilities khi B3.2+ sẵn.

---

## 5. OWNER-GATE DECISIONS (cần chốt trước B3.0)

| # | Quyết định | ★ Đề xuất |
|---|---|---|
| **G1** | Context contract shape | **`p_context jsonb`** additive (vs typed uuid / compound-id) |
| **G2** | Tenant binding cho platform admin | **Require explicit context** cho tenant/assignment (belt-and-suspenders IDOR) |
| **G3** | Rollback model | **Inverse-command** + cấm irreversible ở registry |
| **G4** | Ledger topology | **2 ledger** (access-log READ + command-log WRITE mới) |
| **G5** | Permission source | **Mở rộng capability_vocab** per-command descriptor |
| **G6** | Reason policy write | **Mọi mutating command reason-logged** (asymmetric với read) |

---

## 6. FROZEN / OUT-OF-SCOPE (B3)
- **school single-id** — KHÔNG hồi tố (B2.2 đúng).
- **6 forbidden object** — KHÔNG BAO GIỜ thành MC command target (LINH HỒN + D347.3).
- **DTO/v1** read contract — KHÔNG bump ở B3.0/B3.1 (context là input param, không đổi output shape).
- **Destructive/irreversible ops** — KHÔNG bao giờ là MC command (G3).
- **FE** — track riêng, 0 FE trong B3.0–B3.2 (backend-only arc tiếp tục).
- **Existing:** registry schema + 7 CHECK, 4 platform projector, logger, `get_school_overview` (tenant-operator RPC — KHÔNG tái dùng), profiles.permissions[], Bunny, routes, tooling 2.8.5.

---

## 7. NEXT ACTION (một việc)

**Chốt Owner Gate G1–G6.** Sau khi có 6 quyết định, em mở **B3.0** (context seam, read-only, reversible) làm FINAL APPLY PACKAGE với D92 three-block + BLOCK 3 structural VERIFY + post-commit impersonation — theo đúng khuôn B2.x.

> **ADR này là DESIGN-ONLY. Chưa có migration, chưa có code, chưa canonicalize.** Endpoint vẫn D351/v1.39/V128-B2.2/`be04f4b`/`20260811080037` cho tới khi B3.0 apply + verify.
