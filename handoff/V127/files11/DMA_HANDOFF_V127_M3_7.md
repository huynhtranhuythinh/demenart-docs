# 🧾 DMA_HANDOFF_V127_M3_7.md — TEACHER IDENTITY / CONTEXT BRIDGE · M3.7

> **Sprint closeout (FORENSIC RECONSTRUCTION)** — Giáo viên vận hành theo **school-assignment** thay vì `profile.school_id`: nhận diện qua predicate context, ghi qua adapter assignment-aware, RLS/drive/media gate mở nhất quán `same_school OR is_teacher_in_school`. Xuyên admin (P0B teacher operational surface) + teacher portal (Wave A/B/C) + drive + media + Edge. Consume nền M2.4 (activate teacher). Canonical hoá từ bằng chứng sống, KHÔNG từ trí nhớ.
> **Đọc boot:** `DMA_RULES.md` → `DMA_SYSTEM_MAP.md` → HANDOFF mới nhất, rồi re-pin live DB inventory + `list_edits` + deployed signer trước khi làm.

---

## Executive Verdict

**`RECONSTRUCTED & CANONICALIZED — DMA V127-M3.7`.** 9 migration backend + FE 2 cụm (admin P0B manual + teacher Wave A/B/C agent). DB delta verified live: **+14 SECURITY DEFINER function** (231/220), 11 RLS policy recompat (net 0), 7 drive-fn + 3 media-check REPLACE, Edge body updates. **KHÔNG có Owner-Gate runtime QA record** trên đĩa — canonical phản ánh đúng: bằng chứng cấu trúc (migration + get_diff + lineage), FE Wave A/B/C là `ai_update` shipped lên main. Canonicalized RULES **D346** · SYSTEM_MAP **v1.34**.

## Provenance

- **Migration**: 9 body verbatim từ `schema_migrations` (`20260810044250`…`20260810052804`).
- **FE attribution**: `get_diff c8705e14` phơi in-code tag `// V127-M3-P0B — Teacher operational surface` ⇒ cụm admin-lookup 02:17–03:08 thuộc M3.7 (không phải M2.4-FE).
- **Lineage**: `list_edits` — code HEAD tip `58e02f82` (kế tiếp là `8c0ca0a0`=M4.2.5C).

## Endpoint

- **RULES:** D346 · **SYSTEM_MAP:** v1.34 · **HANDOFF:** V127-M3.7
- **Frontend HEAD (accepted tip):** `58e02f8262b4c1155cf185638835d9939267f261` (`58e02f82`) — "Hardened teacher.media flow"
- **Migration tail:** `20260810052804 v127_m3_7_wave_c_teacher_school_context_reads`
- **Signer / Bunny:** deploy-25 (v24) / 3 zone — số bất biến (Edge auth-check + drive-signing bodies updated); **tooling pin 2.8.5**

## Wave A — Teacher identity bridge
REPLACE `get_my_experiences`, `get_teacher_session_workspace`. Giáo viên nhận diện + workspace phiên theo context, không đơn-trường.

## Wave B — Context compatibility (lớn)
- **Predicates (assignment-scoped authority):** `is_teacher_in_school` · `is_session_teacher` · `is_session_responsible` · `is_moment_teacher`.
- **REPLACE teacher-aware:** `get_lesson_guide` · `submit_session_journal` · `drive_my_zone` · `get_school_storage_usage` · `check_media_upload_access` · `guard_learning_moments_actor`.
- **11 RLS policy DROP+CREATE** (child_observations · prep_items · session_marks · session_media · learning_moments ×3 · moment_children ×4): gate `same_school OR is_teacher_in_school`.
- **Fixes:** `guard_session_class_fix` (session_class_id + guard) · `moment_insert_policy_fix` · `moment_rls_row_scope_fix`.
- **Write adapters (+4 secdef, assignment-aware, NO direct table write):** `teacher_upsert_child_observation` · `teacher_create_learning_moment` · `teacher_update_learning_moment_caption` · `teacher_set_moment_child`.
- **Media compat REPLACE:** `media_consent_check` · `check_curriculum_media_access` · `check_school_resource_media_access`.
- **b1 drive scope:** `DO $$` REPLACE 7 hàm drive (list/create_folder/move/trash/restore/list_trash/rename) mở gate `same_school OR is_teacher_in_school`, có assertion phòng hộ (raise nếu không thấy gate cũ).

## Wave C — Teacher school-context reads
+4 secdef: `get_teacher_home_in_school` · `get_teacher_classes_in_school` · `get_teacher_journals_in_school` · `get_teacher_todo_counts_in_school`.

## Frontend (2 cụm)
- **P0B admin-lookup (manual paste, teacher operational surface):** `c8705e14`…`e2473c2c` — AssignClassDialog + chẩn đoán giáo viên (not_activated/unassigned/account_state_attention) + `set_distribution_lead` error copy.
- **Teacher Wave A/B/C (`ai_update`/agent):** `77290658`(A) → `1eb602ac`(B) → `2485721a`(Edge auth) → `00757982`(Drive signing) → `070bc1ab`(teacher school context) → **`58e02f82`**(teacher.media hardened, tip).
- **Tooling:** float events `0f9cc72e` (empty-file ai_update) + `82430296` (lock-hash fix) — recurring pattern (D342.5/D343.x), handled; pin 2.8.5.

## DB / Delta

**+14 SECURITY DEFINER function; 11 RLS policy drop+recreate (net 0); 7 drive-fn + 3 media-check + Wave-A/B REPLACE; Edge 16 bodies updated.** Inventory verified live: **89 tables · 231 functions · 220 SECURITY DEFINER · 166 policies · 33 triggers · 1 cron · 16 Edge**. Migration tail `20260809180815` → `20260810052804`. `notify pgrst` mỗi migration (D289). **Rollback = revert 9 migration** (policy/drive gate về same-school + DROP hàm mới) **+ FE revert**.

## Residual / carry-forward

- **KHÔNG runtime QA record** cho M3.7 — nếu cần bằng chứng hành vi, chạy actor-matrix rollback-only trên predicate + 8 hàm mới (đa-trường isolation) ở phiên sau.
- FE Wave A/B/C là `ai_update` (agent) — nếu cần byte-audit từng file, get_diff theo từng SHA.
- M3.7 là nền cho M4.2.5 (People workspace projection consume teacher-identity).

---

**Trạng thái:** `RECONSTRUCTED & CANONICALIZED — DMA V127-M3.7`. RULES D346 · SYSTEM_MAP v1.34 · HANDOFF V127-M3.7 · HEAD `58e02f82` · migration tail `20260810052804` · signer deploy-25 (v24) · tooling 2.8.5. Provenance: forensic (9 migration body + get_diff + list_edits), no runtime QA record.
