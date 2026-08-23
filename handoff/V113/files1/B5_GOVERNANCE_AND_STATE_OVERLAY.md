# B5 — GOVERNANCE & STATE OVERLAY
**V113B** · Overlay the approved target IA/components against untouchable governance (**D284 / D293 / D298 / D305**). **No authorization simplification.** `CANONICAL` (rule) + `OBSERVED_SOURCE` (gate) + `OBSERVED_LIVE_DB` (actors). Every reorder below is presentation-only; authority branches are unchanged.

---

## 1. Invariants the target must preserve

`CANONICAL`:
- **D284** — `family_card_effective_access` is the single truth; UI never re-derives access.
- **D293** — UI gate mirrors backend **branch-for-branch**; keep `canEdit` / `canArchive` / `can_moderate` **separate** (never a merged `canManage`).
- **D298** — aux reads are **fail-closed-and-present**: on error show a quiet notice + retry; never silently drop a control or collapse to empty.
- **D305** — Memory Room direct-entry authorizes via `get_family_card`; not-found and not-authorized return **one** generic string (no enumeration); `origin`/`?y&m` are UX-only, never authorization.

## 2. Surface/action overlay (target IA)

| Target surface / action | Who sees it | Who can activate | Backend authority | Denied / error state | Visual placement constraint |
|---|---|---|---|---|---|
| **Hôm nay** modules | any parent w/ linked child | — (identity/preview) | `get_child_journal` (child-scoped) | child fetch error → quiet error (REFINE from silent-empty); no child → Support | identity + one memory + one action; **no KPI block** 🔒 |
| Home "family signal" | guardian/parent of child | open item | preserved `source='family'` in journal (D284 upstream) | omit if none | quiet, single signal (not a grid) |
| **Hành trình** viewer | parent of child | edit/archive only if `parent_memory && mine` `OBSERVED_SOURCE` | `archive_/restore_parent_memory` | media denial → per-reason warm copy + "Vì sao?"→consent | content-first (already) |
| **Nhìn lại một chặng** (Discovery in Journey) | parent of linked child | generate/open capsule | `*_discovery_capsule`, readiness (deterministic) | `not_eligible`/`failed` → "chưa đủ dữ liệu"; not-linked → generic | contextual entry, not a 5th primary 🔒 |
| **Gia đình → Ký ức** (archive) | space member (EA) | open card; create if `create_card` | `get_family_space`, archive index/window; `family_card_effective_access` | loading/denied/error/empty **distinct** (D298) | archive separated from `Thành viên` (?section) |
| **Gia đình → Thành viên** | space member | invite/remove/pending only if `invite_member`/guardian | `mint_/revoke_family_invitation`, `remove_family_member` (guardian protected) | `not_authorized`, `guardian_member_protected` → toast; read-only for members | member sees roster **read-only**; guardian sees management |
| One create CTA | member w/ `create_card` | same | `create_*`/composer | capability-gated (hidden if none) | single CTA within `Ký ức` (removes double-CTA) |
| **Memory Room** open | EA-authorized member | — | `get_family_card` direct-entry (D305) | not-found = not-authorized = **one** generic string; no enumeration | content-first reorder must keep generic denial visible |
| Room · Sửa | creator only | creator | `update_family_card` (`canEdit=isCreator`, native) | hidden if not creator | quiet lifecycle zone (bottom) |
| Room · Lưu trữ | creator or guardian | same | `archive_family_card` (`canArchive=native&&(isCreator\|\|isGuardian)`) | hidden otherwise | quiet lifecycle zone; **kept separate from Sửa** (D293) |
| Room · 💛 / contribute | `can_react`/`can_contribute` | same | engagement payload gates (D284×capability) | denied/error → quiet notice + retry (D298) | below content, above lifecycle |
| Room · own contribution Sửa/Rút lại | author (`mine`) | author | `edit_/withdraw_card_contribution` | author-only | inline on the contribution |
| Room · Ẩn/Hiện | guardian (`can_moderate`) | guardian | `hide_/unhide_card_contribution` | members: control absent | inline, guardian-only |
| Room · Preserve → Journey | guardian (preserve ctx children present) | guardian | `preserve_memory_card`/`preserve_card_contribution`, `reverse_preserve` | preserve read error → **fail-closed** quiet notice + retry (D298) | its own zone; MUST render even on error (present-not-hidden) |
| **Của con** (Kid gateway) | parent of child | enable/PIN/pair/window at depth | `kid_update_access`/`kid_set_pin`/`kid_create_pairing_code`/`kid_revoke_device` | `{ok,reason}` verdicts (`not_enabled`, `invalid_pin_format`) → toast | gateway preview first; controls at secondary depth 🔒 |
| **Quyền riêng tư** | parent of child | toggle consents | **direct `consents` write (RLS)** — unchanged 🔒 (F9 parked) | write error → toast; not-linked → empty | utility + contextual; write path unchanged |

## 3. Role / creator / author overlays (must stay branch-for-branch)

`OBSERVED_SOURCE` + `CANONICAL` — kept **separate**, no merge:
- **Guardian vs member:** guardian = invite/remove/moderate/preserve; member = view/contribute/react (+ own edit/withdraw). Set by capabilities from `get_family_space`/`get_family_space_role`.
- **Creator vs guardian (card):** `Sửa` = creator-only; `Lưu trữ` = creator **or** guardian. Two distinct predicates (D293) — the content-first Room reorder must not fuse them into one "manage" control.
- **Author vs moderator (contribution):** author → Sửa/Rút lại; moderator(guardian) → Ẩn/Hiện. Distinct.

## 4. State overlays (must remain visible after reorder)

`OBSERVED_SOURCE`:
- **Preserve states:** none / preserved(single) / preserved(n of m children) / reverse; live count 5 (1 active/3 reversed/1 orphaned per A1). Content-first Room keeps Preserve as its own zone that renders even on aux error (D298).
- **Archived Card:** `ArchivedCardsSection` (restore) reachable in both contexts; archived ≠ deleted. Keep discoverable after the `Ký ức` reorg.
- **Generic denial (D305):** Room not-found/not-authorized collapse to one string — the new "return context at top" must not leak existence before the auth check resolves.
- **Consent denial:** media gated by MIN-consent → "Đang chờ ba mẹ đồng ý…" + "Vì sao?"→`/parent/consent`. Preserve on reorder.
- **Kid access states:** disabled / enabled-no-PIN / enabled-PIN-set / paired / window — surface as **safety status** in the gateway (PO hierarchy item #3) using existing `kid_access`/`kid_devices` reads. No authority change.

## 5. Governance verdict

🔧 **The approved target IA and component plan overlay cleanly onto D284/D293/D298/D305 with no authorization simplification.** Every reorder (Home de-dashboard, Room content-first, Kid gateway, `Ký ức\|Thành viên` split, Discovery-in-Journey) is **presentation/entry** only:
- No merged permissions; `canEdit`/`canArchive`/`can_moderate` stay separate.
- Fail-closed aux (Preserve/engagement) stays present-not-hidden.
- Room keeps direct-entry auth + generic denial + UX-only `origin`.
- Two Family authorization contexts stay separate (component unification ≠ authz merge).
- Consent write path untouched (F9 parked 🔒).

**No STOP condition (§3/§6 of the brief) triggered:** no fixed decision needs a new audience or authority; no reorder hides a required fail-closed state.
