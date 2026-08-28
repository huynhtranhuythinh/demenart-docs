# V128-P3 — Announcement Capability

## FINAL CANONICAL CLOSEOUT EVIDENCE

**Project:** DẾ MÈN ART (DMA)  
**Capability:** School Announcement — in-app operational broadcast to eligible parents  
**Canonical phase:** V128-P3 FINAL  
**Final status:** **PRODUCT VALUE PROVEN · DEPLOYED**  
**Closeout date:** 2026-08-26 (Asia/Ho_Chi_Minh)  
**Owner:** Jean Huỳnh  
**Evidence source:** ChatGPT conversation `V128-P3.0 — ANNOUNCEMENT PRODUCT VALUE GATE` (`6a8d1c93-c3ec-83ec-90c9-889608b41095`)

---

## 1. Canonical decision

V128-P3 is closed as:

> **PRODUCT VALUE PROVEN · DEPLOYED**

The end-to-end product question has been answered **YES**:

> A school principal can compose one operational announcement in the School Portal, confirm and send it once, and DMA resolves the correct eligible parents for that school and delivers the announcement through the existing Parent in-app notification experience—without manually contacting parents one by one.

This is a bounded operational broadcast capability. It is not chat, a conversation system, a marketing system, or a new notification platform.

---

## 2. Final phase ledger

| Phase | Canonical result |
|---|---|
| V128-P3.0 — Product Value Gate | **CLOSED · PRODUCT VALUE PROVEN** |
| V128-P3.1 — Backend Writer | **LIVE · ACCEPTED WITH VERIFICATION NOTES** |
| V128-P3.1 — Security / fan-out / audit validation | **PASS** |
| V128-P3.2 — Frontend Controlled Build | **ACCEPTED** |
| V128-P3.2 — Owner QA | **PASS** |
| V128-P3.2.1 — Corrections | **ACCEPTED** |
| V128-P3.2.1 — Owner Re-QA | **PASS** |
| Production deployment | **DONE — owner confirmed** |
| Sent Announcement History | **DEFERRED · NON-BLOCKING** |
| Browser sound/autoplay limitation | **DOCUMENTED · NON-BLOCKING** |

Production deployment is recorded from the Owner's explicit confirmation in the source conversation: `tôi đã cho deploy rồi.` This closeout records that attestation; it does not claim an independent infrastructure/deployment inspection.

---

## 3. Product capability delivered

### School Portal

- School Operations users can access `/school/notifications`.
- The page provides a bounded announcement composer with plain-text title and body.
- Title is limited to 160 characters; body is limited to 4,000 characters.
- The user must confirm before the RPC executes.
- Sending is protected against accidental duplicate submission while in progress.
- The result distinguishes:
  - notification rows stored; and
  - parents currently login-reachable on DMA.
- A zero-eligible-recipient result is an explicit non-error state.

### Parent Portal

- `school_announcement` renders its payload title and body as escaped React text.
- Existing unread/read, mark-all-read, inbox, realtime refresh, and presenter/toast behavior remain in use.
- No HTML, Markdown execution, arbitrary links, or action parsing was introduced.

### Route boundary

- `/school/*` is guarded using the existing canonical experience resolver and home-path redirect pattern.
- A Parent entering `/school/notifications` directly is redirected to the Parent portal rather than receiving the School shell.
- School Operations access continues for the intended Master/sub-admin experience.
- This frontend boundary is defense-in-depth and does not replace backend authority.

---

## 4. Backend canonical evidence

### Live migration

- **Version:** `20260825055955`
- **Name:** `v128_p3_1_send_school_announcement`
- **State:** applied live; structural VERIFY completed successfully.

The first apply attempt failed inside the verification harness because `aclexplode()` was given a redundant column-definition list. The entire transaction rolled back cleanly. Architecture approved the bounded R3.1 harness-only correction, after which the same migration body re-applied successfully. No product/schema/authority side effect survived the failed attempt.

### Live RPC

```sql
public.send_school_announcement(
  p_school_id uuid,
  p_title text,
  p_body text
) returns jsonb
```

Receipt contract:

```json
{
  "announcement_id": "<uuid>",
  "stored_recipient_count": 0,
  "login_reachable_count": 0
}
```

### Notification contract

- **Type:** `school_announcement`
- **Audience:** `parent`
- **Display:** `toast`
- **Sound:** `soft`
- **Icon:** `megaphone`
- **Enabled:** `true`

Payload contract:

```json
{
  "announcement_id": "<uuid>",
  "title": "<plain text>",
  "body": "<plain text>"
}
```

### Authority and hardening

- RPC owner: `postgres`.
- `SECURITY DEFINER` with hardened empty `search_path`.
- `EXECUTE` granted to `authenticated`.
- No `PUBLIC` or `anon` execute access.
- Caller must pass existing `is_school_admin()` and same-school authority checks.
- Teacher, Parent, and cross-school calls were denied with `42501` in controlled QA.
- Target school must be active.
- `create_notification()` remains internal-only (`postgres` / `service_role`); it was not exposed to authenticated clients.
- Direct authenticated `INSERT` authority on `notifications` was not added.
- Existing notification RLS policies remained `select_own` and `update_own`; no new INSERT policy was introduced.
- No new role or permission model was created.

### Server-side recipient resolution

The RPC resolves recipients server-side through the active relationship chain:

`school → active class → active enrollment → active child → child_parents → active parent profile`

Eligible parent roles are the existing `primary_parent` and `secondary_parent` roles. Recipients are deduplicated by `parent_profile_id`, so a parent connected through multiple children or classes receives one notification. A qualifying parent profile without `user_id` still receives a stored notification row; `login_reachable_count` separately counts profiles with a usable linked account.

The client does not send recipient, class, child, or audience arrays.

### Audit behavior

- One canonical `school_announcement_send_completed` audit event is written per completed send, including zero-recipient completion.
- `entity_id` reconciles to the generated `announcement_id`.
- Metadata records the school, actor, stored/reachable counts, content lengths, and content hashes.
- Full announcement content is not duplicated into the audit record.

---

## 5. Frontend implementation and commits

### V128-P3.2 controlled frontend build

- **Accepted P3.2 tip:** `d9a3df21` (short SHA preserved in the source evidence).
- The build added the School Announcement composer, RPC integration, explicit `school_announcement` rendering in the notification inbox and realtime presenter, and mounted the composer on the School notifications surface.
- Reported implementation files were bounded to the School announcement feature, the School notifications route, `NotificationsView`, and `NotificationPresenter`.
- No backend, migration, RLS, authority, generated Supabase type, or dependency expansion was authorized in P3.2.

### V128-P3.2.1 correction commit

- **Commit:** `ca69ea5b2577d649bd96b3ea4a502c5de6b219a5`
- **Commit title:** `Fixed school route & config`
- **Pre-correction HEAD:** `d9a3df21`
- **Cumulative correction diff:** exactly two frontend files:
  - `src/routes/_authenticated/school.tsx`
  - `src/features/school/announcement/SchoolAnnouncementComposer.tsx`

Corrections:

1. Added the canonical `beforeLoad` School route guard using `fetchMyExperiences()` / `get_my_experiences`, `experiences.school_operations`, and `homePathForRole(...)`, with fail-closed behavior and self-loop protection.
2. Captured the submitted trimmed title before clearing the form and added announcement-specific receipt wording:

   `“{TITLE}” đã được gửi.`

   followed by the unchanged stored and login-reachable count lines.

Tooling governance was restored/verified at the established `2.8.5` pin. The temporary platform float to `2.13.1` produced no net dependency change against the P3.2 baseline, and no dependency was added.

Reported correction validation:

- `assert-tooling-governance.mjs` — **OK**
- `bunx tsc --noEmit` — **OK**
- `bun run build` — **PASS**

---

## 6. QA evidence

### Backend controlled QA

All data-writing backend rehearsals were rollback-safe; no test notification or audit rows persisted.

| Case | Evidence | Result |
|---|---|---|
| Master admin → own active school | Receipt `8 stored / 3 reachable`; 8 notification rows inside rehearsal transaction | **PASS** |
| Multi-child / multi-class dedup | Parent linked through 2 children and 2 active classes received exactly 1 notification | **PASS** |
| Parent profile without `user_id` | Stored notification created inside rehearsal | **PASS** |
| Reachable count | `3`, matching eligible profiles with non-null `user_id` | **PASS** |
| Audit reconciliation | Exactly 1 event with matching announcement ID and `8/3` counts | **PASS** |
| Teacher send | Denied `42501` | **PASS** |
| Parent send | Denied `42501` | **PASS** |
| Cross-school send | Denied `42501` | **PASS** |
| Active school with zero eligible parents | Valid `0/0`, 0 notifications, exactly 1 completion audit | **PASS** |
| Cleanup / persistence | Rehearsal rolled back; 0 test notification rows and 0 test audit rows remained | **PASS** |

Verification notes retained from P3.1:

- `sub_admin` success was not runtime-exercised because no suitable demo identity existed; the existing `is_school_admin()` path covers it by construction.
- Inactive class/enrollment/child/profile exclusions were not runtime-exercised against inactive pilot records; the active-state predicates were structurally verified.
- Inactive-school rejection was not runtime-exercised because the existing protected-school guard prevented synthetic state mutation; the live RPC branch was structurally verified.

These are residual verification notes, not blockers to the accepted P3 closeout.

### Owner product QA

Owner QA and re-QA were accepted after the P3.2.1 corrections:

| Case | Observed result | Status |
|---|---|---|
| Parent direct URL boundary | Parent entering `/school/notifications` redirected to the Parent portal; School shell not exposed | **PASS** |
| Intended School Operations access | Master could enter `/school/notifications` and see the composer | **PASS** |
| Receipt specificity | Receipt identified the just-sent title and retained both counts | **PASS** |
| End-to-end announcement | School send produced an in-app Parent announcement using the existing notification experience | **PASS / PRODUCT VALUE PROVEN** |

Captured receipt evidence:

> “Thông báo Test 5” đã được gửi.  
> Đã lưu thông báo cho 8 phụ huynh.  
> 3 phụ huynh hiện có thể xem thông báo trên DMA.

The wording correctly distinguishes stored recipient rows from parents currently able to view the notification; it does not claim that every recipient has read or already seen it.

---

## 7. Production state

Production deployment is canonically recorded as **DONE** based on the Owner's explicit post-QA confirmation.

Final deployed capability:

1. School Admin composes a plain-text operational announcement.
2. School Admin confirms once before sending.
3. The backend validates existing authority and school scope.
4. The backend resolves and deduplicates eligible parents.
5. DMA stores one in-app notification per eligible parent profile.
6. Parent inbox, unread/read behavior, and realtime presentation use the existing notification system.
7. The sender receives an announcement-specific receipt with stored and login-reachable counts.

No production capability was added for email, SMS, browser/mobile push, Zalo, chat, replies, attachments, scheduling, templates, segmentation, per-class targeting, per-child targeting, or teacher broadcasting.

---

## 8. Deferred and non-blocking items

### Sent Announcement History — deferred

Outbound/sent announcement history was explicitly deferred as a new product requirement for a future phase.

P3 did **not** add:

- local/session storage history;
- a new history table;
- a history/list RPC;
- an audit-log reader exposed as product history; or
- another outbound notification system.

This does not block P3 because the core compose → send → receive value flow is proven and deployed.

### Browser sound/autoplay — documented

Audit confirmed:

- `notification_sounds.slug = 'soft'` exists and is enabled;
- the Bunny asset path resolves;
- `school_announcement.sound = 'soft'` matches;
- the presenter resolves the URL and attempts `Audio.play()`.

No code defect was proven. Browser autoplay policy may reject playback until a qualifying user gesture, and the existing rejected promise is handled silently. This was classified **REPORT ONLY / NON-BLOCKING**; no workaround or data change was added in P3.

---

## 9. Frozen boundaries carried forward

- Visibility does not grant authority.
- Broadcast is not chat.
- Notification is not conversation.
- Recipient resolution remains server-side and school-scoped.
- `create_notification()` remains an internal primitive.
- Existing RLS and authority helpers remain the security source of truth.
- Parent profiles without a login may have stored notifications; login reachability remains a separate receipt concept.
- P3 remains in-app only.

Any future sent-history, sound-unlock UX, outbound channel, audience segmentation, or teacher-broadcast work requires a new product and architecture gate. It must not be treated as unfinished P3 scope.

---

## 10. Handoff to V128-P4 — Home Practice

P3 is closed. The roadmap may proceed to:

> **V128-P4 — HOME PRACTICE**

P4 should begin with its own product-value gate and live audit. It inherits no authorization to change the P3 announcement writer, notification authority, RLS, delivery channels, or deferred history capability.

Recommended P4 opening condition:

- treat P3 as deployed production baseline;
- preserve the announcement contracts documented here;
- audit current Home Practice data and user flows before proposing implementation;
- define one owner-verifiable end-to-end value test before build authorization.

---

## 11. Final canonical statement

**V128-P3 — ANNOUNCEMENT CAPABILITY is FINAL CLOSED.**

**Status:** `PRODUCT VALUE PROVEN · DEPLOYED`  
**Backend:** `LIVE`  
**Frontend:** `ACCEPTED`  
**Owner QA:** `PASS`  
**Production:** `DEPLOYED (OWNER CONFIRMED)`  
**Deferred items:** `NON-BLOCKING`  
**Next phase:** `V128-P4 — HOME PRACTICE`

