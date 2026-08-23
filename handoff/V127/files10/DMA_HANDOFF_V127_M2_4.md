# 🧾 DMA_HANDOFF_V127_M2_4.md — ADMIN PROVISIONING AUDIT SPINE + ACTIVATE TEACHER · M2.4

> **Sprint closeout (FORENSIC RECONSTRUCTION)** — Mốc backend-only đặt xương sống audit cho provisioning + hành động admin kích hoạt giáo viên. Canonical hoá **sau sự việc** từ bằng chứng sống (migration body + aclexplode + list_edits), KHÔNG từ trí nhớ. Đây là mốc nền cho V127-M3.7 (teacher identity bridge) và V127-M4.2.5 (People workspace).
> **Đọc boot:** `DMA_RULES.md` → `DMA_SYSTEM_MAP.md` → HANDOFF mới nhất, rồi re-pin live DB inventory + `list_edits` + deployed signer trước khi làm.

---

## Executive Verdict

**`RECONSTRUCTED & CANONICALIZED — DMA V127-M2.4`.** Backend-only (2 migration, 0 frontend commit). DB delta xác minh trực tiếp trên hệ sống: +2 SECURITY DEFINER function, cả hai hardened (`search_path=""`, anon/PUBLIC denied). **KHÔNG có Owner-Gate runtime QA record** cho mốc này — canonical entry phản ánh đúng: bằng chứng cấu trúc (migration + ACL + lineage), không phải QA runtime. Canonicalized RULES **D345** · SYSTEM_MAP **v1.33**.

## Provenance (vì sao tin được mà không QA lại)

- **Migration body**: đọc verbatim từ `supabase_migrations.schema_migrations` (2 version `20260809180755`, `20260809180815`).
- **ACL**: `aclexplode` live trên 2 hàm mới → `authenticated/postgres/service_role` EXECUTE, anon/PUBLIC không có; `secdef=true`, `search_path=""`.
- **Lineage**: `list_edits` — 0 commit frontend giữa `6b860338` (V126-M1 tip) và `c8705e14` (M3.7-era) ⇒ backend-only, code HEAD bất biến.

## Endpoint

- **RULES:** D345 · **SYSTEM_MAP:** v1.33 · **HANDOFF:** V127-M2.4
- **Frontend HEAD:** `6b860338125a63e8b74815d549db5be723ad732a` (`6b860338`) — **BẤT BIẾN** (backend-only, 0 FE commit)
- **Migration:** `20260809180755 v127_m2_4_phase1a_audit_spine` + `20260809180815 v127_m2_4_phase1b_admin_activate_teacher` → tail **`20260809180815`**
- **Signer / Bunny / tooling:** deploy-25 (v24) · 3 zone · pin 2.8.5 — tất cả BẤT BIẾN

## Phase 1A — Audit spine (additive, behavior unchanged)

CREATE OR REPLACE 3 RPC provisioning chỉ để thêm `write_audit_log` (không đổi hành vi/authz/signature), mỗi cái REVOKE public/anon + GRANT authenticated/service_role (D15):
- `create_child_and_enroll` → `CHILD_CREATED` + `CLASS_ASSIGNMENT_CHANGED`(kind=initial)
- `provision_parent_and_link` → `PARENT_CHILD_LINK_CREATED`(path=provision)
- `assign_class_distribution` → `distribution_lead_changed`(kind=assign)

**+1 hàm mới** `admin_workspace_access_log(entity_type, entity_id, reason)`: admin mở workspace `child` **bắt buộc reason** (`reason_required` nếu trống) → `ADMIN_OPEN_CHILD_WORKSPACE`; `parent` → `ADMIN_OPEN_PARENT_WORKSPACE`; is_admin gate.

## Phase 1B — admin_activate_teacher (domain action, single-role P0)

**+1 hàm mới** `admin_activate_teacher(profile_id, school_id, teacher_type, reason)`: flip `role`→lead/assistant_teacher + `school_id` + `state='active'`, log `TEACHER_ACTIVATED`. **KHÔNG đụng `permissions[]`, KHÔNG gán lớp.** Gate is_admin platform-only (dựa `guard_profiles_protected_cols`). Guards: `cannot_downgrade_admin`, `has_active_parent_link`, `invalid_teacher_type`, `profile_not_found`, `school_not_found`; idempotent `noop`.

## DB / Delta

**+2 SECURITY DEFINER function; 0 table/policy/trigger/Edge.** Inventory verified live: **89 tables · 217 functions · 206 SECURITY DEFINER · 166 policies · 33 triggers · 1 cron · 16 Edge**. Migration tail `20260807130914` → `20260809180815`. `notify pgrst` cả 2 phase (D289). **Rollback = revert 2 migration** (3 REPLACE về bản trước + DROP 2 hàm mới). Frontend/tooling: 0.

## Residual / carry-forward

- Audit event mới ĐƯỢC PHÁT ở tầng provisioning + admin-open; **firehose vs security-ledger separation** (`media_access_log` vs `audit_logs`) vẫn là horizon.
- `admin_activate_teacher` là nền cho M3.7 (teacher identity/context) — consume ở mốc sau.
- Không QA runtime cho mốc này; nếu cần bằng chứng hành vi, chạy actor-matrix rollback-only trên 2 hàm mới ở phiên sau.

---

**Trạng thái:** `RECONSTRUCTED & CANONICALIZED — DMA V127-M2.4`. RULES D345 · SYSTEM_MAP v1.33 · HANDOFF V127-M2.4 · HEAD `6b860338` (bất biến) · migration tail `20260809180815` · signer deploy-25 (v24) · tooling 2.8.5 — zero frontend/Edge/Bunny/tooling delta. Provenance: forensic (migration body + aclexplode + list_edits), no runtime QA record.
