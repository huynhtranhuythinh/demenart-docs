# V128-B3.0 FINAL APPLY PACKAGE v2.1 — SECURITY DELTA

> **Loại:** SECURITY DELTA REVISION ONLY — patch chồng lên **v2**, không viết lại package.
> **Status v2:** APPROVED WITH MINOR SECURITY REVISION → v2.1 giải quyết 2 delta security trước Owner Authorization Gate.
> **Boundary:** không `apply_migration`, không `execute_sql`, không đụng Supabase live, không sửa FE/RLS/role, không canonicalize. Mọi SQL = **DESIGN PLACEHOLDER**.
> **Baseline giữ nguyên:** RULES **D351** · SYSTEM_MAP **v1.39** · HANDOFF **V128-B2.2** · tail `20260811080037` · FE `be04f4b`.
> **Locked decisions (KHÔNG mở lại):** Variant A (3-arg → core → 4-arg) · `context_requirements jsonb` · validator separate seam · security ordering v2 · foundation boundary (0 class/session wiring, 0 command/permission/audit/rollback ledger, 0 RLS/role/FE change).

---

## 1. CHANGES FROM v2

| # | Vùng | v2 | v2.1 | Loại |
|---|---|---|---|---|
| **C-1** | Validator ACL | `{authenticated, service_role, postgres}` | **`{postgres, service_role}`** · 0 anon · **0 authenticated** · 0 PUBLIC | **Tightening** (least-privilege) |
| **C-2** | Core dependency ACL | (chưa có checklist riêng) | **+Verification block §3** cho mọi dependency `_mission_control_workspace_core` gọi | **Additive verify** (0 architecture change) |

Chỉ 2 delta. **Không** đổi kiến trúc, signature, DDL, ordering, DTO, hay foundation boundary của v2. Δ inventory dự kiến của B3.0 **không đổi** (vẫn +1 col · +1 CHECK · +3 fn · 1 REPLACE · projector +0).

---

## 2. VALIDATOR ACL DECISION

**Function:** `validate_mission_control_object_context(p_object_type text, p_context jsonb)`

### 2.1 Quyết định

**CHẤP NHẬN recommendation của CTO.** ACL cuối:

```
validate_mission_control_object_context
  → EXECUTE: { postgres (owner), service_role }
  → 0 anon · 0 authenticated · 0 PUBLIC
```

→ **Đối xứng với `_mission_control_workspace_core`** (cả hai = internal-only helper). Validator và core cùng posture: chỉ tới được qua 2 public overload; client không gọi trực tiếp được.

### 2.2 Chứng minh `authenticated` KHÔNG cần thiết (kiến trúc)

1. **Production path không đi qua authenticated grant.** Chuỗi gọi thực tế là `public overload (secdef, owner=postgres) → core (secdef, owner=postgres) → validator`. Core chạy với quyền owner `postgres`; `postgres` có EXECUTE trên validator theo mọi kịch bản → validator luôn reachable từ core **bất kể** client role. Grant `authenticated` không nằm trên đường đi nào của production.
2. **Không có caller trực tiếp nào khác.** Hai overload gọi core, không gọi validator; không edge function / RPC nào gọi validator trực tiếp. `authenticated` chỉ phục vụ "independent unit-test" và "future reuse" — cả hai là tiện lợi/suy đoán, không phải architectural necessity.
3. **Test không mất khả năng.** Unit-test validator chạy được qua `execute_sql` (as `postgres`) hoặc qua overload bằng impersonation (đi qua core → validator as owner). Không cần grant `authenticated` để test (xem §4 điều chỉnh test-runner).

### 2.3 Chứng minh việc GIỮ `authenticated` sẽ MỞ enumeration surface

Validator đọc `mission_control_object_registry.context_requirements` và trả structural verdict (`valid`/`invalid` + error class). Nếu `authenticated`:

- Client bất kỳ có thể gọi `validate_mission_control_object_context('<type>', '<probe>')` và dùng **verdict như oracle**:
  - `unknown` vs `not-unknown` → **enumerate object_type nào tồn tại** trong registry;
  - so khớp `context_missing_required_key` / `context_unknown_key` với các probe → **suy ra bộ required context keys** (`school_id`, `class_id`, …) của từng object — đúng reconnaissance map của Context Contract Layer.
- Đây là **contract-shape enumeration**: không leak child/PII, nhưng leak cấu trúc nội bộ của MC OS cho mọi authenticated user → thừa attack surface, vi phạm least-privilege.

Hạ `authenticated` → đóng oracle này. Registry-shape chỉ lộ gián tiếp qua `get_object_workspace` (vốn đã is_admin-gated + fail-closed), **không** qua kênh validator độc lập.

### 2.4 Delta áp lên v2

- **v2 §5.4** ("ACL `{authenticated, postgres, service_role}` … an toàn để grant `authenticated`") → **SUPERSEDED**. Thay bằng §2.1 trên.
- **v2 §8.1 verify #4/#5** → mở rộng: validator VERIFY thêm assertion **0 authenticated** (giống core), dùng `aclexplode(coalesce(proacl, acldefault('f', proowner)))`, check grantee OID 0 (PUBLIC) + không có authenticated/anon grantee.

---

## 3. CORE DEPENDENCY ACL VERIFICATION (additive §8 requirement)

Bổ sung vào Verification Plan (v2 §8) — **chỉ thêm verify, không đổi architecture**. Trước apply, audit live (D1) mọi dependency mà `_mission_control_workspace_core` gọi; mỗi dependency phải PASS 4 gate: ACL phù hợp · không privilege escalation · không PUBLIC/anon exposure · không phá D15/D231.

### 3.1 Dependency inventory (core gọi)

| Dependency | Bước core | Security mode kỳ vọng | ACL baseline kỳ vọng (B2.x) | Verify |
|---|---|---|---|---|
| `public.is_admin()` | 1 authenticate | SECURITY DEFINER | callable authenticated (là gate chung) · 0 anon · 0 PUBLIC | exists · secdef · ACL không anon/PUBLIC · **KHÔNG bị B3.0 đụng** |
| `public.mission_control_object_registry` (SELECT) | 2 metadata | table (RLS deferred) | client roles **0 privilege** · `service_role` SELECT-only · owner `postgres` full | 0 anon/authenticated SELECT · RLS posture **unchanged** · read đi qua owner (definer) |
| `public.validate_mission_control_object_context(text,jsonb)` | 3 validate | SECURITY DEFINER · `search_path=''` | **`{postgres, service_role}`** (C-1) · 0 anon · 0 authenticated · 0 PUBLIC | ACL đối xứng core · no dynamic SQL |
| `public.admin_workspace_access_log(...)` | 5 privacy/reason | SECURITY DEFINER | `{postgres, authenticated, service_role}` · 0 anon · 0 PUBLIC (B2.1) | ACL unchanged · **KHÔNG bị B3.0 đụng** (additive-log capsule giữ) |
| projector RPC (static CASE): child/media/person/capsule + `admin_lookup_school` | 6 touch | SECURITY DEFINER | `{authenticated, postgres, service_role}` · **0 anon · 0 PUBLIC** (B2.1/B2.2) | mỗi projector 0 anon/0 PUBLIC · **KHÔNG bị B3.0 đụng** · count bất biến (projector +0) |

### 3.2 Privilege-escalation analysis

1. **Escalation bị gate bởi is_admin (bước 1).** Core là secdef owner=postgres; khi gọi dependency có side-effect (logger bước 5, projector bước 6) nó chạy quyền cao — nhưng **mọi** non-admin bị chặn `not_authorized` ở bước 1 trước khi chạm bất kỳ dependency effect nào. Elevation nằm sau auth gate, không trước.
2. **Không dependency nào có anon/PUBLIC → không bypass moat.** Nếu bất kỳ projector/logger vô tình có `anon`/`PUBLIC` EXECUTE, client có thể gọi trực tiếp **vòng qua** adapter (mất allowlist + forbidden-leak guard). Verify §3.1 khóa điều này: mọi dependency **0 anon · 0 PUBLIC**. Đây là invariant an ninh cốt lõi, phải re-audit live (không tin memory/doc — D1).
3. **B3.0 không mutate dependency ACL.** B3.0 chỉ CREATE/REPLACE 4 function target (validator, core, 2 overload). Dependencies **không** nằm trong migration statements → `proacl` của chúng không thể regress *do B3.0*. Verify vẫn chạy (baseline-drift guard), nhưng kỳ vọng: dependency ACL = baseline B2.x nguyên vẹn.

### 3.3 D15 / D231 posture verify

- **D15 (proacl reset khi REPLACE):** chỉ `get_object_workspace(text,uuid,text)` bị `CREATE OR REPLACE` → **bắt buộc** re-run REVOKE/GRANT deterministic ngay sau REPLACE; verify `aclexplode(...)` không còn default-grant sót.
- **D231 (Supabase auto-grant khi CREATE):** validator + core + 4-arg overload là CREATE mới → `ALTER DEFAULT PRIVILEGES` tự grant EXECUTE cho anon/authenticated/service_role → **bắt buộc** `REVOKE ALL FROM PUBLIC, anon, authenticated` trong Block 2; verify 0 anon/0 authenticated (validator+core), overload 0 anon/0 PUBLIC.
- **Dependencies KHÔNG replace → D15 không kích hoạt cho chúng.** Verify khẳng định proacl dependency không đổi.
- **search_path='' correctness:** core body phải **schema-qualify** mọi dependency call (`public.is_admin()`, `public.validate_mission_control_object_context(...)`, `public.admin_workspace_access_log(...)`, `public.<projector>(...)`, `public.mission_control_object_registry`) — vì `search_path=''` khiến tên unqualified không resolve. Verify: `pg_get_functiondef` của core không chứa tên dependency unqualified.

---

## 4. UPDATED SECURITY NOTES

- **Internal-only surface mở rộng (C-1):** validator gia nhập core thành **cặp internal helper đối xứng** (`{postgres, service_role}`). Public surface của MC workspace = **đúng 2 overload** `get_object_workspace/3` + `get_object_workspace/4`. Mọi thứ khác (core, validator) không reachable trực tiếp qua PostgREST → attack surface tối thiểu.
- **Enumeration posture:** registry-shape / context-contract chỉ lộ qua adapter is_admin-gated; kênh validator độc lập đóng (§2.3). Không object-type oracle cho authenticated.
- **Moat kép B2.x bất biến:** allowlist `discovery_fields` + forbidden-leak `forbidden_groups` ở bước 6 không đổi; §3.1 verify dependency projector 0-anon giữ moat không bị vòng.
- **Fail-closed giữ:** context_invalid → không touch; validator lỗi bất ngờ → core coi invalid; auth-slot no-op pass-through (không nới quyền so B2.2).
- **Test-runner điều chỉnh:** vì validator mất `authenticated`, "Validator trực tiếp" test (v2 §8.3) chạy **as `postgres` (execute_sql)** hoặc **as `service_role`**, hoặc gián tiếp qua overload+impersonation — **không** qua authenticated impersonation gọi thẳng validator (sẽ `42501`, và đó là kết quả ĐÚNG, có thể thêm làm assertion "authenticated không gọi trực tiếp validator được").

---

## 5. UPDATED OWNER GATE CHECKLIST IMPACT

Delta v2.1 **không thêm** hạng mục Owner Gate mới; nó **siết** OG-4 và **mở rộng** verify của OG-4/OG-6:

- **OG-4 · New functions** — cập nhật: validator ACL = **`{postgres, service_role}` · 0 authenticated** (đối xứng core), thay vì `{authenticated, service_role}` như v2. Owner ratify bản siết này.
- **OG-6 · Foundation-only guarantee** — cập nhật verify: bổ sung **Core Dependency ACL Verification §3** vào điều kiện PASS (mọi dependency 0 anon/0 PUBLIC, unchanged, D15/D231 intact) trước khi tuyên foundation-only.
- **OG-1, OG-2, OG-3, OG-5** — **không đổi**.

Không phát sinh gate mới; scope không mở rộng.

---

## CONCLUSION

Hai delta đều **additive/tightening**, không đụng locked decisions, không mở scope:

- **C-1** hạ validator ACL về `{postgres, service_role}` — least-privilege, đóng enumeration oracle, chứng minh `authenticated` không cần (§2).
- **C-2** thêm Core Dependency ACL Verification — chỉ verify, gate escalation bằng is_admin, khóa 0-anon/0-PUBLIC trên mọi dependency, giữ D15/D231 (§3).

**Status:**
**DESIGN READY FOR OWNER AUTHORIZATION**

Ratify OG-1…OG-6 (với OG-4 siết + OG-6 mở rộng verify) → mở phiên APPLY riêng. Không apply. Không build. Không canonicalize.
