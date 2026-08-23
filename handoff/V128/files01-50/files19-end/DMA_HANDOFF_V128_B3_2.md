# 🗂️ DMA_HANDOFF_V128_B3_2.md — MISSION CONTROL · SESSION SECOND CONTEXT CONSUMER — APPLIED · VERIFIED · CANONICALIZED

> **Ngày:** 2026-08-12 (GMT+7) · **Loại:** backend-only migration (SESSION second context consumer · assignment-scoped · class_distribution_id-bound projector) · **Verdict: V128-B3.2 APPLIED — migration + functional/security verification PASS · CLOSED — ALL PASS · CANONICALIZED D355 / v1.43.**
> **Boot phiên sau:** file này → `DMA_RULES.md` (tip **D355**) → `DMA_SYSTEM_MAP.md` (**v1.43**) → audit live DB (D1) → re-pin `list_edits` (FE `be04f4b`, BẤT BIẾN backend-only).

---

## A. CANONICAL ENDPOINT

- **RULES:** **D355** · **SYSTEM_MAP:** **v1.43** · **HANDOFF:** **V128-B3.2**
- **Migration tail:** `20260812051609` → **`20260812070542`** (`v128_b3_2_session_context_consumer`)
- **FE HEAD:** `be04f4b` — **BẤT BIẾN** (backend-only; 0 FE / 0 Edge / 0 Bunny)
- **Verdict:** `V128-B3.2 — CLOSED — ALL PASS` (Owner Apply Gate one-shot đã tiêu thụ).

## B. PRODUCTION INVENTORY (verified live)

**90 tables · 240 functions · 229 SECURITY DEFINER · 166 policies · 33 triggers · 1 cron.**

PRE→POST: `90/239/228/166/33/1` → **`90/240/229/166/33/1`**. Delta = **+1 fn** (`admin_lookup_session`) + **+1 SECURITY DEFINER** (same). Core = REPLACE in-place (0 net). tables/policies/triggers/cron BẤT BIẾN.

## C. REGISTRY EXACT SETS (17 rows · wired 7 / registered 4 / none 6)

- **wired (7):** `capsule`·`child`·`class`·`media`·`person`·`school`·**`session`**
- **registered (4):** `privacy_request`·`program`·`subscription`·`support_case`
- **none/forbidden (6):** `badges`·`child_journey`·`family_memory`·`journal`·`raw_media`·`skills`

Transition B3.2: wired **6→7** · registered **5→4** · none **6→6** (session-row UPDATE, không INSERT).

## D. SESSION EXACT CONTRACT

- `object_type=session` · kind=**supporting** · scope=**assignment** · projector_status=**wired** · privacy_policy=**open**
- discovery_fields = **`[title,state]`** · capability_vocab = `{"view":null}` · forbidden_groups = `[]`
- context_requirements = `{"version":1,"keys":{"class_distribution_id":{"type":"uuid","required":true}},"allow_unknown":false}`
- Bound lookup: `lesson_sessions.id = p_session_id AND lesson_sessions.class_distribution_id = p_class_distribution_id`
- Payload projector `{id,title,state}` → adapter strip về `{title,state}` (id mang trong DTO `object_id`). `title` nullable giữ NULL; `state` text từ enum `session_state`.

## E. FUNCTION SURFACES (Mission Control)

| Function | Signature | Posture |
|---|---|---|
| **`admin_lookup_session`** (MỚI) | `(uuid,uuid)` | secdef · owner postgres · `search_path=""` exact · EXECUTE `{authenticated,postgres,service_role}` · 0 PUBLIC/anon |
| `admin_lookup_class` | `(uuid,uuid)` | secdef · `search_path=""` · `{authenticated,postgres,service_role}` |
| `admin_lookup_school` | `(uuid)` | secdef · `search_path=""` · `{authenticated,postgres,service_role}` |
| `_mission_control_workspace_core` | `(text,uuid,jsonb,text)` | secdef · owner postgres · `search_path=""` exact · EXECUTE `{postgres,service_role}` · **0 PUBLIC/anon/authenticated** (internal) |
| `validate_mission_control_object_context` | `(text,jsonb)` | secdef · internal `{postgres,service_role}` |
| `get_object_workspace` (4-arg) | `(text,uuid,jsonb,text)` | secdef · `{authenticated,postgres,service_role}` (context-aware wrapper) |
| `get_object_workspace` (3-arg legacy) | `(text,uuid,text)` | secdef · `{authenticated,postgres,service_role}` (delegate empty context → fail-closed) |

Core semantic delta = ĐÚNG một static CASE `WHEN 'session'` → `admin_lookup_session(p_object_id, (v_ctx->>'class_distribution_id')::uuid)`. CLASS branch unchanged. No dynamic SQL. Scope allowlist = `platform / tenant / assignment`.

## F. SECURITY & FAILURE SEMANTICS (verified S1–S14, impersonation rollback-safe)

- `correct context → ok` (fields keys exactly `{title,state}`, no leak) · `wrong cd → not_found` · `nonexistent → not_found` (**≡ indistinguishable**)
- `missing / malformed-uuid / unknown-key ctx → context_invalid` · `legacy 3-arg → context_invalid`
- `non-admin wrapper → not_authorized` · `non-admin DIRECT admin_lookup_session → not_admin`
- `forbidden object (journal) → forbidden_object` · CLASS correct/wrong-school **unchanged**
- 5 wired consumers (person/child/media/capsule/school) **PRE≡POST** · **six-object diffcount = 0** (capsule = REAL success fixture `discovery_capsules.id`, KHÔNG `not_found`)
- assignment-wired-no-dispatch synthetic (`__probe_b32__`) → `dispatch_missing` + rollback (17 rows, 0 residue)

## G. CURRENT-CONTAINMENT CAVEAT (BẮT BUỘC minh bạch)

`lesson_sessions.class_distribution_id` = NOT NULL + FK-bound NHƯNG **KHÔNG có immutability guard proven** (2 trigger: AFTER-INSERT snapshot + timestamp — không ghim cd_id). ⇒ SESSION context = **CURRENT containment**. Session dời A→B: context A → `not_found`, context B → `ok`. **KHÔNG được diễn giải lại B3.2 thành historical containment.** Projector biểu diễn containment hiện hành, KHÔNG lịch sử.

## H. NON-GOALS / UNTOUCHED SURFACES

KHÔNG: operational SESSION workspace · teacher/session authority redesign · reassignment lifecycle · immutable FK guard · FE · new role model · RLS/policy change · dynamic dispatch · reuse `is_session_lead`/`is_session_teacher`/`get_session_detail`/`get_teacher_session_workspace` cho MC projection · re-scope SESSION về tenant · thêm `school_id`/`class_id`/`teacher_id` vào SESSION context. `lesson_sessions` schema/lifecycle BẤT BIẾN.

## I. NEXT-TOPIC GATE

**KHÔNG pre-authorize B3.3.** Milestone kế phải bắt đầu bằng: **canonical boot → live re-pin → drift verdict → dependency audit → design gate**. KHÔNG giả định object kế tiếp (registered còn: `privacy_request`·`program`·`subscription`·`support_case`) cho tới khi audit xong. Canonicalization file này = CLOSED; mọi implementation kế cần Owner authorization riêng.

**Backup debt (mang theo):** migration files B3.0/B3.1/B3.1.5/B3.2 chưa commit vào repo (D90 dump-từ-live) — outstanding.

---

**FINAL: ✅ V128-B3.2 — SESSION SECOND CONTEXT CONSUMER — APPLIED · VERIFIED · CLOSED — ALL PASS · CANONICALIZED (D355 / v1.43 / HANDOFF V128-B3.2 · tail `20260812070542`). CLASS + SESSION both wired; registered=4; SESSION assignment-scoped, class_distribution_id-bound, current-containment.**
