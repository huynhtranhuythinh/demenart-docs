# 🗺️ DMA_SYSTEM_MAP.md — V128-P7 FINAL — CANON DELTA (append block)

> **How to apply:** Append to the live cumulative `DMA_SYSTEM_MAP.md`; **bump version to v‹live +1›** per repo convention (mounted reference snapshot was v1.67; live is ahead). Append only — do not rewrite unrelated subsystems.
> **Scope of assertions:** items below are stated only to the level independently verified on live production Supabase at closeout, plus the frozen P7 semantic contract. Column-level table detail beyond verified fields is intentionally not asserted here.

## SUBSYSTEM — Post-Session Child Follow-Up (V128-P7)

### Backend runtime pin
- Migration count **189** · tail `20260831055744 v128_p7_3_3_follow_up_rpc_anon_revoke` · prev `20260831023113 v128_p7_3_2_teacher_todo_follow_up_count` · no 190+.

### Tables
- `public.child_follow_up_actions` — follow-up action store. **RLS: enabled.** State values observed: `open`, `resolved` (lifecycle open→resolved only). Closeout fixture: total=2 · open=0 · resolved=2. Resolution records `resolved_by` / `resolved_at`; resolving emits a `child_follow_up_resolved` audit event (one per resolve; verified in preview full-loop = exactly 2, no duplicate). Does not rewrite `child_observations` truth.
- `public.session_reports` — **RLS: enabled.** Carries exactly **one** non-internal trigger: `create_follow_up_actions` (binds `tg_create_follow_up_actions`).

### Functions (verified: name / signature / SECDEF / ACL / body md5)
| Function | signature | SECDEF | search_path | ACL (EXECUTE) | body md5 |
|---|---|---|---|---|---|
| `follow_up_distribution_authority` | `(p_distribution_id uuid)` | ✓ | `''` | authenticated · service_role · postgres | `b96ba8742b469129e3e9e07e86a06fc4` |
| `resolve_child_follow_up` | `(p_action_id uuid)` | ✓ | `''` | authenticated · service_role · postgres | `50a202a256243b20077c46ff5155a8a1` |
| `get_teacher_open_follow_ups` | `()` | ✓ | `''` | authenticated · service_role · postgres | `abf65603abea9aecaeb3cfefd0961cd6` |
| `get_teacher_todo_counts` | `()` | ✓ | **`public`** ⚠️ | authenticated · service_role · postgres | `015279e217f4de96d958a3d1904b350b` |

- ACL invariant: **no `anon`, no `PUBLIC`** EXECUTE on any of the four (least-privilege, post-P7.3.3).
- Trigger functions (P7 substrate): `tg_create_follow_up_actions`, `tg_cfa_creation_guard`, `tg_cfa_immutable_guard` — SECURITY DEFINER, `search_path=''`.

### Authority model (semantic contract)
- **READ** = source observer OR current distribution authority. **RESOLVE** = current distribution authority only.
- Distribution authority = lead teacher OR temporal responsible-teacher precedence (in_progress → nearest upcoming → most-recent past/overdue; exclude cancelled/rescheduled).
- Both layers **fail-closed**: helper `COALESCE(…,false)`; resolve boundary `authority IS NOT TRUE ⇒ forbidden`.
- `counts.open_follow_up_count` = OPEN actions the caller can RESOLVE (RESOLVE-authority-derived), never readable-item count.

### Frontend surface (teacher portal)
- Accepted Product SHA `cfac171cdd1023bbf780688cab50ab3544f0fcce`; main pin `@lovable.dev/vite-tanstack-config = 2.8.5`.
- Files: `followUpModel.ts` · `TeacherFollowUpSection.tsx` · `followUpModel.test.ts` · `teacher.index.tsx` wiring.
- Behavior: exact server RPC contracts (no client-side authority reconstruction) · `can_resolve` controls the resolve CTA · read-only historical item shows "Chỉ xem" · actionable badge uses `open_follow_up_count` · quiet empty state "Hiện không có bé nào cần theo dõi tiếp."
- Portal scope: teacher only. **Parent: no P7 visibility.** School/admin projection deferred. `/kid` namespace unaffected.

### Deferred / debt
- `get_teacher_todo_counts` `search_path='public'` — non-blocking hardening debt (no migration 190 in P7).
- School/admin follow-up projection — fast-follow. Notifications — out of P7 core.

**Version:** bump to **v‹live +1›** (P7 FINAL). Endpoint: HANDOFF **V128-P7** · backend tail `20260831055744` · FE SHA `cfac171` · FE pin `2.8.5`.
