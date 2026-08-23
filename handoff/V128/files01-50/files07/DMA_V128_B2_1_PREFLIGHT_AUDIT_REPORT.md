# 🛰️ DMA V128-B2.1 — MISSION CONTROL WORKSPACE ADAPTER · PRE-FLIGHT AUDIT REPORT

> **Loại:** READ-ONLY FORENSIC AUDIT. **0 code · 0 migration · 0 permission change · 0 deploy.**
> **Vai:** Claude = Technical Auditor / Security Reviewer · ChatGPT = CTO/CPO Governance Owner.
> **Ngày:** 2026-08-10 (GMT+7) · **Baseline:** post V128-B2.0 (registry live) · migration tail `20260810150209` · FE HEAD `be04f4b`.
> **Mục tiêu B2.1:** adapter `get_object_workspace(type, id)` — dispatch từ `mission_control_object_registry` tới projector RPC sẵn có bằng **CASE tường minh** (D349).
> **⚠️ Nợ mở:** B2.0 canonicalization (D349 vào RULES · v1.37 vào SYSTEM_MAP) CHƯA ghi file thật — chờ Owner upload `DMA_RULES.md`/`DMA_SYSTEM_MAP.md`. Audit này read-only nên không bị chặn, nhưng canonical write vẫn treo.

---

## 0. VERDICT

**`READY — WITH BINDING ADAPTER CONTRACT`.**

Nền móng projector đã đủ và an toàn để xây `get_object_workspace`. **Không có blocker cấu trúc.** Green-light B2.1 **với điều kiện ràng buộc**: adapter phải **whitelist theo `discovery_fields` + enforce `forbidden_groups`** (allowlist-first, KHÔNG passthrough thô), tự re-gate độc lập, route platform↔tenant theo `scope`, và gọi reason-log cho `child`. Các điều kiện này là *design contract*, không phải blocker — nhưng nếu vi phạm (passthrough thô) sẽ rò child-identity/capsule-items.

---

## 1. PROJECTOR CANDIDATE AUDIT (live introspection)

Mọi candidate: `RETURNS jsonb` · **SECURITY DEFINER** · owner **postgres** · VOLATILE · ACL = `{authenticated, postgres, service_role}` EXECUTE — **0 anon · 0 PUBLIC** (D15 sạch toàn bộ) · **0 dynamic SQL** (không hàm nào chứa `EXECUTE`).

| RPC | Args | Gate nội bộ | search_path | RLS-bypass posture | Tenant boundary |
|---|---|---|---|---|---|
| `admin_lookup_user` | `p_profile_id uuid` | `is_admin()` | `public` | DEFINER, gate trong body | platform (admin cross-tenant) |
| `admin_lookup_child` | `p_child_id uuid` | `is_admin()` + exists-check | `public` | DEFINER, gate trong body | platform |
| `admin_lookup_media` | `p_media_id uuid` | `is_admin()` + exists-check | `public` | DEFINER, gate trong body | platform |
| `admin_lookup_capsule` | `p_capsule_id uuid` | `is_admin()` | `public` | DEFINER, gate trong body | platform |
| `admin_lookup_search` | `p_q text` | `is_admin()` | `public` | DEFINER | platform |
| `get_person_workspace` | `p_school_id, p_person_id` | `is_admin() OR profile-in-school` + `not_authorized` | `public, pg_temp` | DEFINER, gate trong body | **tenant-isolated** ✅ |
| `get_school_people` | `p_school_id, p_query, p_limit` | `is_admin() OR profile-in-school` + `not_authorized` | `public, pg_temp` | DEFINER, gate trong body | **tenant-isolated** ✅ |
| `admin_workspace_access_log` | `p_entity_type, p_entity_id, p_reason` | `is_admin()` + reason (child=required) | `""` (strict) | DEFINER writer | platform (audit) |
| `get_school_overview` | `()` | ⚠️ **không thấy `is_admin`/actor string** | `""` | DEFINER | ⏸ **verify trước B2.2** |
| `get_teacher_session_workspace` | `p_session_id uuid` | (teacher-scope, chưa audit sâu) | `""` | DEFINER | ⏸ deferred P3 |

**Grant leak:** 0 (không candidate nào grant anon/PUBLIC).
**search_path:** tất cả **pinned** (không default/mutable) → 0 injection vector. Ghi chú P3: `admin_lookup_*` dùng `public` thay vì `''` canonical — chấp nhận được (pinned), adapter mới nên dùng `''` hoặc `public, pg_temp`.

---

## 2. EMISSION vs REGISTRY (leakage core)

Điều tối quan trọng: **projector emit NHIỀU HƠN `discovery_fields` cho phép**, nhưng **KHÔNG emit content thô**. Tất cả là metadata/count (D244).

| RPC | Emit gì (thực đọc từ body) | Content thô? | Registry cho phép (`discovery_fields`) | Kết luận |
|---|---|---|---|---|
| `admin_lookup_child` | identity + parents(email) + enrollments + `journal_summary`(count) + `media_counts` + `consents` + `parent_memory`(count, "metadata only D244") + `memory_conversation`(count) + `kid_devices`(count) + `evidence`(count) + `readiness` + `capsules`(list, **no items**) | ❌ không (chỉ count/flag) | `{full_name, nickname, state}` | **whitelist bắt buộc**: drop toàn bộ 6 forbidden group + parents/enrollments/counts. An toàn nếu adapter allowlist. |
| `admin_lookup_capsule` | capsule metadata + **`items[]`** (taxonomy_code/pattern_key/claim_strength/support) + child `full_name` | ⚠️ `items` = meaning-content | `{scope, domain, window_code}` | **PHẢI drop `items`** (`forbidden_groups={items}`) + drop child name. |
| `admin_lookup_media` | media metadata + `storage_zone`(name) + `linked_child`(name) + moment `caption` + tagged children names + consent checklist + audit | ❌ không URL/bytes | `{file_type, state}` | drop child names/caption/consent. **0 raw_bytes/signed_url** — projector không emit chúng. |
| `admin_lookup_user` / `get_person_workspace` | identity + contexts + responsibilities | ❌ | `{full_name, email, role, state}` | khớp gần đúng; whitelist vẫn nên áp. |

> **LINH HỒN / D347.3 verdict:** không projector nào rò journal content, drawing bytes, memory message text, signed URL, hay raw media. Rủi ro DUY NHẤT = adapter passthrough thô làm lộ **child-identity-adjacent metadata** (tên con, caption, capsule items). **Triệt tiêu bằng allowlist-first tại adapter.**

---

## 3. REGISTRY ALIGNMENT

| object_type | registry (kind / projector_status) | existing source | ready for adapter |
|---|---|---|---|
| `person` | core / **wired** | `admin_lookup_user` (platform) + `get_person_workspace` (tenant) | ✅ dual-source, cả hai gated; route theo scope |
| `child` | core / **wired** | `admin_lookup_child` (is_admin) + `admin_workspace_access_log` (reason) | ✅ metadata-only; **reason-log D345.2 bắt buộc**; whitelist `{full_name,nickname,state}` |
| `media` | supporting / **wired** | `admin_lookup_media` (is_admin) | ✅ 0 bytes/URL; whitelist `{file_type,state}` |
| `capsule` | supporting / **wired** | `admin_lookup_capsule` (is_admin) | ⚠️ emit `items` → **PHẢI drop**; whitelist `{scope,domain,window_code}` |
| `school` | core / registered | `get_school_overview` (⚠️ gate chưa xác nhận) + `get_school_people` | ⏸ B2.2 — verify `get_school_overview` gate trước |
| `subscription` | core / registered | — | ⏸ B2.2 (chưa có projector) |
| `support_case` | core / registered | — | ⏸ B2.2 |
| `class` | core / registered | — | ⏸ P2 |
| `session` | supporting / registered | `get_teacher_session_workspace` | ⏸ P3 (teacher-scope, audit sau) |
| `program` | supporting / registered | — | ⏸ P3 |
| `privacy_request` | supporting / registered | — | ⏸ P3 |
| `child_journey` `journal` `skills` `badges` `family_memory` `raw_media` | forbidden / none | — (reject bằng dữ liệu) | ✅ adapter reject: `forbidden_groups={*}`, không dispatch |

**Wired 4/4 có nguồn thật.** Registered 7 = adapter trả `not_available` (đúng thiết kế B2.0). Forbidden 6 = reject bằng catalog data.

---

## 4. SECURITY REVIEW (3 checkpoint bắt buộc)

1. **No dynamic SQL requirement** — ✅ **CONFIRMED.** 0 `EXECUTE` trong mọi candidate. Adapter gọi projector tĩnh qua CASE; KHÔNG `EXECUTE format(...)`. 0 injection surface (D349.2).
2. **CASE dispatch possible** — ✅ **YES.** Mọi projector là jsonb RPC id-based, callable tĩnh. `get_object_workspace` map `object_type → RPC` bằng CASE tường minh, code-review được.
3. **No privilege escalation** — ✅ **CONDITIONAL PASS.** ACL sạch (0 anon/PUBLIC); projector gate `is_admin` nội bộ. **Điều kiện:** adapter (DEFINER) phải **tự re-gate**, KHÔNG giả định caller là admin, KHÔNG nới quyền của projector. Adapter là DEFINER-owner-postgres như projector → không leo thang nếu gate đúng.
4. **No child memory leakage** — ⚠️ **CONDITIONAL.** Projector 0 content thô; rủi ro chỉ ở passthrough. **Điều kiện cứng:** whitelist `discovery_fields` + drop `forbidden_groups` (đặc biệt `capsule.items` + child names). Allowlist-first, KHÔNG blacklist-only.
5. **Tenant isolation** — ✅ **PASS (with routing rule).** Tenant projector (`get_person_workspace`/`get_school_people`) gate `is_admin() OR profile-in-school` + `not_authorized`. Platform lookup (`admin_lookup_*`) = admin cross-tenant **có chủ đích**. **Điều kiện:** adapter route theo `registry.scope` — caller school-scoped KHÔNG được chạm `admin_lookup_*`; person scope=platform note ghi rõ dual-path.

---

## 5. BINDING ADAPTER CONTRACT (điều kiện cho B2.1 build)

1. **Allowlist-first projection:** adapter đọc `discovery_fields` từ registry, chỉ emit đúng các field đó; mọi field khác trong projector output bị **drop tại adapter**. Không bao giờ passthrough thô.
2. **Forbidden enforcement kép:** `kind='forbidden'` → reject ngay (không dispatch). `forbidden_groups` → drop nhóm tương ứng kể cả khi projector trả (defense-in-depth, D349.3).
3. **Reason-gate cho `child`:** `privacy_policy='reason_required'` → adapter yêu cầu reason + gọi `admin_workspace_access_log('child', id, reason)` trước khi trả (D345.2).
4. **Scope routing:** dispatch platform (`admin_lookup_*`) vs tenant (`get_person_workspace`) theo `registry.scope` + caller context; không cho tenant caller chạm platform lookup.
5. **Self re-gate:** adapter DEFINER phải có gate riêng (`is_admin()`/tenant membership), không tin projector gate hộ.
6. **Static CASE only:** `object_type → RPC` bằng CASE literal; cấm `EXECUTE format`.
7. **capsule.items + child names:** kiểm thử riêng — verify adapter output cho `capsule` KHÔNG chứa `items`, cho `child`/`media` KHÔNG chứa tên con ngoài whitelist.

---

## 6. DEFERRED / FOLLOW-UP (không chặn B2.1)

- **`get_school_overview` gate:** không thấy `is_admin`/actor string trong signal scan — verify body (có thể gate qua helper `current_school_id()`/membership khác) **trước khi wire `school` ở B2.2**.
- **`get_teacher_session_workspace`:** teacher-scope, audit sâu khi tới `session` (P3).
- **search_path P3:** `admin_lookup_*` = `public` (pinned, an toàn) — cân nhắc chuẩn hoá `''` ở milestone hardening; adapter mới nên dùng `''`/`public, pg_temp`.
- **B2.0 canonicalization:** D349/v1.37 chờ ghi file thật (Owner upload RULES/SYSTEM_MAP).

---

## 7. FINAL

**VERDICT: `READY — WITH BINDING ADAPTER CONTRACT`.**
Không blocker. B2.1 được phép xây `get_object_workspace` **khi và chỉ khi** tuân §5 (allowlist-first, forbidden enforcement, reason-gate child, scope routing, self re-gate, static CASE). **No implementation until Owner authorize** — audit này là pre-flight, chưa phải lệnh build.

*Endpoint dự kiến sau B2.1 (khi build + canonicalize): RULES D350 · SYSTEM_MAP v1.38 · HANDOFF V128-B2.1.*
