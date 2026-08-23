# A7 — STATE & PERMISSION MATRIX
**V113A** · Governance is **untouchable** (D284/D293/D305). This records the *as-built* authority so the rebuild mirrors every branch. Tags: `OBSERVED_SOURCE` (UI gate) + `CANONICAL` (backend rule) + `OBSERVED_LIVE_DB` (actors).

---

## 1. Authority sources

`CANONICAL` + `OBSERVED_SOURCE`:
- **Effective Access (single truth):** `family_card_effective_access(card, profile)` — published × card active × provenance active × active membership in the card's space × MIN-consent across linked children. All FMN reads/gates call it (D284). UI never re-derives it.
- **Guardian:** `is_family_space_guardian(space, profile)` (`OBSERVED_LIVE_DB`: Hùng/Ngân true; Bà ngoại false).
- **Space role (UI):** `get_family_space_role` → `{is_guardian, can_create_card, can_invite}` (additive, fail-closed — D293/D298).
- **Card creator:** `provenance_source='native' && creator_profile_id === self`.
- **Contribution author / moderation:** payload `mine` (author) and `can_moderate` (guardian) computed **server-side** (`get_family_card_engagement`); UI must not derive them.
- **Generic denial:** not-found and not-authorized collapse to one string (`not_found_or_not_authorized` for the card; `FAMILY_DENIED_COPY` in UI) — no enumeration (D305 §2).

## 2. Family action → gate mirror (UI reflects backend branch-for-branch)

`OBSERVED_SOURCE` `memoryRoomShared.tsx` / `parent.family.tsx`:

| Action | UI gate | Backend rule | Rule |
|---|---|---|---|
| See card (stream/room) | membership + EA | `family_card_effective_access` | D284 |
| Edit card ("Sửa") | `canEdit = isCreator` (native + creator===self) | `update_family_card` creator-only | D293/D305 §5 |
| Archive card ("Lưu trữ") | `canArchive = native && (isCreator || isGuardian)` | `archive_family_card` creator **or** guardian | D293 |
| Restore card | shown in `ArchivedCardsSection` only for restorable cards | `restore_family_card` mirrors archive authz | D293/V110 |
| Contribute (💛 / write / voice) | `can_react` / `can_contribute` (from engagement payload) | ack + contribute gates = EA × capability | D284/V109B |
| Edit / withdraw own contribution | `item.mine` → Sửa / Rút lại | `edit_/withdraw_card_contribution` author-only, re-runs authz | D225/V109B |
| Hide / unhide contribution | `can_moderate` → Ẩn / Hiện | `hide_/unhide_card_contribution` guardian-only | D293 |
| Preserve → Journey | `PreserveControl` renders only if `preserve_ctx.children` non-empty (guardian path) | `preserve_memory_card`/`preserve_card_contribution`, `reverse_preserve` | V109C/V110 |
| Invite member | `canInvite = my_capabilities.includes('invite_member')` | `mint_family_invitation` guardian/cap-gated | V109B |
| Remove member | `canRemove = canInvite && !is_guardian && !is_self` | `remove_family_member`; guardians protected (`guardian_member_protected`) | V110 |
| Revoke invite | shown to `canInvite` | `revoke_family_invitation` | — |
| Create space | empty-state form (guardian) | `create_family_space` | — |

**Mirror integrity:** `canEdit` and `canArchive` are kept **separate** (never merged to a `canManage`) — exactly the D293 requirement. Preserve/aux reads are **fail-closed and present** (D298: error → quiet notice + retry, never a silently-missing control).

## 3. Live governance expectations (for the required visual matrix, once browser is available)

`OBSERVED_LIVE_DB` actors → expected UI (to confirm by capture; not asserted as `OBSERVED_LIVE_UI`):

| Actor | On a card by Bà ngoại | On own card | Contribution controls |
|---|---|---|---|
| Hùng (guardian) | **Lưu trữ** yes; **Sửa** no (not creator) | Sửa + Lưu trữ | own → Sửa/Rút lại; others' → **Ẩn** only (`can_moderate=true`) |
| Ngân (guardian) | Lưu trữ yes; Sửa no | Sửa + Lưu trữ | as Hùng |
| Bà ngoại (member, creator≠guardian) | own card → Sửa + Lưu trữ | — | own → Sửa/Rút lại; others' → **no** Ẩn (`can_moderate=false`) |
| Outsider (non-member admin) | `get_family_card` → generic `not_found_or_not_authorized`; 0 leak | — | — |

`CANONICAL` (D307/V112C live replay) already validated this matrix by JWT impersonation; the V113A visual confirmation is **NOT TESTABLE this pass (browser unavailable)** and is listed as an open evidence gap (A8).

## 4. Consent / privacy semantics

`OBSERVED_SOURCE` + `CANONICAL`:
- Consent types (9): `display_in_app`, `group_moment_in_class`, `download`, `private_share_link`, `school_internal_comm`, `school_external_marketing`, `demen_marketing`, `privacy_ack`, **`family_space_display`** (default OFF; gates a child's content appearing in the family space — share-into-space "opens later").
- **MIN-consent:** most-restrictive across tagged children applies to the whole moment; group moments require `group_moment_in_class` (D71/D104). Enforced at sign time in `get_signed_media_url`; UI shows "Đang chờ ba mẹ đồng ý…" + "Vì sao?".
- **Consent write path (finding):** `/parent/consent` writes **directly to `consents`** (RLS-gated) rather than via a SECURITY DEFINER RPC — the only sensitive parent write not routed through an RPC/Edge chokepoint. Recorded as a governance-hygiene refine item (A6), not a proven vulnerability.
- **Platform admins never see child PII** (D48); outsiders get generic denial.

## 5. Kid-access authority

`OBSERVED_SOURCE`: `/parent/kid` mutations (`kid_update_access`, `kid_set_pin`, `kid_create_pairing_code`, `kid_revoke_device`) all return `{ok, reason}` verdicts; child entry is gated at `kid_gate` edge (v8) — PIN + device + play-window + per-moment consent (`CANONICAL` D220). PIN is 4 digits (`invalid_pin_format` guard). Pairing requires access enabled (`not_enabled`).

## 6. State grammar (per surface)

`OBSERVED_SOURCE`:
- **FMN surfaces** (family, archive, room, engagement, preserve, archived): `loading / denied / error / empty` are **distinct** via `classifyRpcOutcome`+`outcomeToLoadState`; error **never** masquerades as empty (F01/V111C); aux layers fail independently (D298).
- **Home:** four hand-rolled states (no-child / other-only / near-empty / empty) — correct actor copy but not using the shared grammar.
- **Journey:** loading / error (message) / empty ("Bắt đầu hành trình…") / data; media denial per-reason.
- **Room:** primary (`get_family_card`) vs independent aux (engagement/preserve/role); generic denial on primary.

**Governance verdict:** as-built authority is coherent and correctly mirrored UI↔backend across FMN. The rebuild must preserve every branch verbatim (D284/D293/D305 untouchable). No governance simplification is proposed. Open item: the direct-table consent write is a hygiene inconsistency, not a breach.
