# A1 — CANONICAL / RUNTIME TRUTH
**Workstream:** V113A · Parent Portal UX/UI Rebuild — Experience & Source Baseline Audit
**Date:** 2026-07-16 (GMT+7) · **Mode:** ZERO CODE · ZERO MIGRATION · ZERO DATA MUTATION · ZERO DEPLOY · ZERO CANONICAL APPEND
**Evidence legend:** `CANONICAL` (disk docs) · `OBSERVED_LIVE_DB` (Supabase read) · `OBSERVED_LIVE_UI` (browser) · `OBSERVED_SOURCE` (repo read) · `INFERRED` · `UNKNOWN`

---

## 1. Canonical endpoint (disk)

`CANONICAL` — Latest canonical artifacts on disk, reconciled:

| Artifact | Value | Note |
|---|---|---|
| RULES | **D308** | `DMA_RULES.md`, last rule D308 (Archive Navigation invariants) |
| SYSTEM_MAP | **v1.13** | header self-labels running skeleton; endpoint footer = v1.13 |
| HANDOFF | **v112C** | `DMA_HANDOFF_v112C.md` — FMN Phase 3 · Living Archive Navigation |
| Later handoff on disk | **none** | No v112D/E/F present. Prompt said "v112C or later"; latest found = v112C |

The prompt's stated anchor (`RULES D308 · SYSTEM_MAP v1.13 · HANDOFF v112C or later · 87/190/164/1 · mig 101 · routes 52 · edge 16 · journey 37 · preserve 5=1/3/1 · cards 16=15/1`) is treated as a claim to verify, not trusted.

## 2. Live inventory vs anchor — measured, 0 drift

`OBSERVED_LIVE_DB` (Supabase project `xcvhacymrbhdhohyylyq`, single consolidated read) + `OBSERVED_SOURCE` (routes/edge live in repo, not DB):

| Axis | Anchor | Live | Verdict |
|---|---|---|---|
| tables (public, base) | 87 | **87** | ✅ |
| SECURITY DEFINER funcs | 190 | **190** | ✅ |
| RLS policies (public) | 164 | **164** | ✅ |
| cron jobs | 1 | **1** | ✅ |
| migrations | 101 | **101** (latest `20260716111917`) | ✅ |
| edge functions | 16 | **16** (`OBSERVED_LIVE_DB` list) | ✅ |
| routes | 52 (convention) | **57 raw `fullPaths` = 52 convention + 5** (`OBSERVED_SOURCE` `routeTree.gen.ts`) | ✅ matches D307 §5 reconciliation |
| child_journey total | 37 | **37** | ✅ |
| child_journey `source='family'` | 1 | **1** | ✅ (37 = 36 non-family + 1 family) |
| preserve_records | 5 | **5** = 1 active / 3 reversed / 1 orphaned | ✅ |
| memory_cards | 16 | **16** = 15 active / 1 archived | ✅ |
| card provenance | — | active 15 = **12 parent_memory + 3 native**; archived 1 = native | `OBSERVED_LIVE_DB` |
| card_contributions | — | **5** = 3 active / 2 withdrawn (1 hidden) | `OBSERVED_LIVE_DB` |
| family_spaces | 1 | **1** | ✅ |

**Verdict: ZERO unexplained drift. Canonical endpoint confirmed against live. STOP-condition #1 (canonical/live drift) cleared.**

## 3. Live actor resolution (governance test identities)

`OBSERVED_LIVE_DB` — resolved from DB, not memory (V111D lesson: never trust remembered IDs). Space **"Gia đình Hùng"** `4806ff8d-128e-4c25-9400-654bb2253038` (cards link via `primary_context_type='family_space'` + `primary_context_id = space_id`; `memory_cards` has **no** `space_id` column).

| Actor | Profile ID | Role | Capabilities | Guardian (`is_family_space_guardian`) |
|---|---|---|---|---|
| Nguyễn Văn Hùng ("Ba") | `d1000000-…-051` | active member | view_space, invite_member, create_card, react, contribute | **true** |
| Tạ Thị Thuý Ngân ("Phụ huynh") | `d26e5914-…` | active member | view_space, invite_member, create_card, react, contribute | **true** |
| Bà Ngoại Test ("Bà ngoại") | `2965d4a0-…` | active member (+3 removed history rows) | view_space, create_card, react, contribute (no invite_member) | **false** |
| Outsider (super_admin, non-member) | `e86e45d1-…` | non-member | — | — (deny target) |

Children in space: **An** `d1000000-…-041`, **Khang** `d1000000-…-045`.
Relationships (`family_member_relationships`) confirm D303 privacy-collapse: Hùng = "Ba"(An)+"Ba"(Khang); grandmother = "Bà ngoại"(An)+"Bà kế"(Khang) — two labels collapse to identical strings only after child-name privacy projection.

## 4. Edge functions (live, 16)

`OBSERVED_LIVE_DB` — FMN/parent-relevant subset: `get_signed_media_url` (v23; family-contribution + parent-memory + child-photo signing branches), `upload_media` (v19; contribution branch G + child/curriculum/session), `accept_family_invitation` (v1), `accept_parent_invitation` (v2), `kid_gate` (v8; public Kid PIN/media signing), `resolve_share_link` (v8; public journal share). All 16 have `verify_jwt=false` (custom auth in body — consistent with project pattern).

## 5. Documentation-vs-live drift found (1, non-blocking)

`OBSERVED_SOURCE` ≠ `CANONICAL` — **Kid Portal is BUILT, not "reserved."** START_HERE / SYSTEM_MAP / memory describe `/kid` as "V2 reserved · namespace only · locked-door placeholder · not yet built." Live source shows a **fully functional** Kid subsystem: route `/parent/kid` (enable toggle, play-window, 4-digit PIN via `kid_set_pin`, device pairing via `kid_create_pairing_code` + realtime `paired` broadcast, device revoke), public `/kid` route, `kid_gate` edge v8, tables `kid_access`/`kid_devices`. This is a stale-documentation finding (the V1 "reserved" framing predates the actual Kid build in the v46-era, per RULES D220). Recorded for reconciliation; does **not** block V113A.

## 6. Confirmation of non-mutation

This audit performed **read-only** DB queries and **read-only** repo reads. No migration, no `apply_migration`, no INSERT/UPDATE/DELETE, no edge deploy, no Lovable write/deploy, no canonical file append. Inventory axes are unchanged post-audit (they were only read).
