# 📦 DMA_HANDOFF_v112C.md — FMN PHASE 3 · V112C LIVING ARCHIVE NAVIGATION (16/07/2026 · ĐÓNG · EXPERIENCE PASS)

> **Phiên trước:** V111G Experience Regression Closeout (Phase 2 đóng · D307/v1.12/v111G).
> Boot chuẩn phiên sau: HANDOFF này → RULES tới **D308** → SYSTEM_MAP **v1.13** → **audit live DB**.
> Kỳ vọng live: **87 / 190 / 164 / 1** · migrations **101** · routes **52** · edge **16** · journey **37 = 36 non-family + 1 family** · preserve **5 = 1 active / 3 reversed / 1 orphaned** · threads/messages **2 / 3** · cards **16 = 15 active / 1 archived**.
> ⚠️ secdef 188→**190** (mig 101, +2 additive RPC). Mọi trục khác 0 drift so với v111G.

---

## 1. MỤC TIÊU V112C

Sprint BUILD đầu tiên của **Memory Navigation Layer** (Phase 3). Quyết định product: Phase 3 mở màn bằng **Navigation** (không phải Recall). Chỉ dựng **deterministic Timeline spine** trên Living Archive — KHÔNG Recall/Search/AI/Notification/People/Related/Calendar-event/Memory-Landscape. Hai nửa: **V112C-A backend contract** + **V112C-B frontend Archive Navigation UI**. Backend-first; Stream RPC giữ byte-stable; deploy sau build PASS; canonical append sau visual PASS.

---

## 2. BASELINE + INVENTORY (đo live, không tin handoff)

| Trục | Trước (v111G) | Sau (v112C) | Verdict |
|---|---|---|---|
| tables / secdef / policies / cron | 87 / 188 / 164 / 1 | **87 / 190 / 164 / 1** | ✅ (+2 secdef) |
| migrations | 100 | **101** | ✅ (+1) |
| routes | 52 | **52** | ✅ (0 route mới) |
| edge | 16 | 16 | ✅ |
| journey / preserve / cards / threads | 37 / 5=1/3/1 / 16=15/1 / 2·3 | idem | ✅ 0 drift, 0 data mutation |

Actor resolve LIVE (space "Gia đình Hùng" `4806ff8d-128e-4c25-9400-654bb2253038`): Hùng guardian profile `d1000000-…-051`/auth `eb94304a`; Bà ngoại non-guardian `2965d4a0`/auth `d3d062f8` (+4 removed history rows); Ngân co-guardian `d26e5914`/auth `6be1e47c`; outsider super_admin "Quản trị viên Test" `e86e45d1`/auth `446de75d` (non-member).

---

## 3. V112C-A — ARCHIVE CONTRACT (mig 101 · +2 secdef)

Migration `v112c_archive_navigation_contract` — **additive only, 0 schema/policy/data change**. 3-block pattern (DDL → REVOKE/GRANT hardening → VERIFY DO-block rollback guard, PASS).

**`get_family_archive_index(p_space_id)`** → `{ok, space_id, years:[{year, total, months:[{month, count}]}]}`. Active-only · accessible-only (reuse `family_card_effective_access` — D284 single truth) · ICT bucket · year/month DESC · sparse omitted · **no payload/media/names** (density metadata). Live: `{2026: total 15, [{month 7: 15}]}`.

**`get_family_memory_window(p_space_id, p_year, p_month, p_limit=20, p_before_occurred_at, p_before_created_at, p_before_id)`** → `{ok, space_id, year, month, cards:[<same shape as Stream>], has_more, next_cursor}`. Keyset pagination (row-tuple `<`, **no OFFSET**) · order occurred_at/created_at/id DESC · limit clamp 1..50 · same card builder as Stream (reused verbatim).

**Security (D291, verified live):** cả 2 `prosecdef=true` · `search_path=""` pinned · grants = authenticated + postgres + service_role only, **0 anon / 0 PUBLIC**. `NOTIFY pgrst 'reload schema'` signaled.

**Evidence (JWT impersonation, actor live):**
- Archive index Hùng = `{2026: total 15, month 7: 15}` (total=Σmonths, archived excluded).
- ICT bucket proven (fixtures, 0 data mutation): parent_memory 17:00Z→ICT 08/07 m7 · native 00:00Z→ICT 14/07 m7 · month-boundary 31/07 17:00Z→**ICT m8** (flips, ≠UTC) · year-boundary→ICT 2026 m1 · leap 29/02 valid.
- Window(2026,7,50) full = **15 cards, order_hash `92fbbfa1e320c7e9d215bacd569e47d4` IDENTICAL to Stream** (equivalence).
- Keyset: limit 5 × 3 trang `5/true→5/true→5/false`; union **15 total = 15 distinct** (0 dup, 0 miss).
- Edge: month=13/0 → `invalid_period` · limit=999 → clamp 15 · empty 2027-07 → 0/has_more=false (legit, no leak).
- **Governance:** outsider index+window → `not_authorized` (generic deny, 0 count/period/card leak); members authorized. D284/D293/D305 nguyên.
- **Stream byte-stable:** get_family_memory_stream AFTER = 15 / hash `92fbbfa1…47d4` = BEFORE. 0 regression.

---

## 4. V112C-B — ARCHIVE NAVIGATION UI (frontend · Lovable agent · commit `b28cd9b7`)

**3-tier model:** Archive Index → Period Window → Memory Room. Index-first / payload-lazy · Newest default (không Today) · search-param `?y=&m=` (UX state, không authority) · Stream/Room language reused.

**Files (5 new + 6 narrow edits · diff-audited via list_messages→get_diff):**
- New: `useFamilyArchive.ts` · `useFamilyMemoryWindow.ts` (keyset + token stale-guard) · `FamilyArchiveIndex.tsx` (rail/sheet, aria-expanded/aria-current, quiet counts) · `FamilyMemoryPeriod.tsx` (period heading + flat MemoryItem + load-more) · `FamilyArchiveNavigation.tsx` (orchestrator: desktop two-pane / mobile Sheet, newest-default ref-guard, openCard origin+y+m).
- Edited: `familyExperienceGrammar.ts` (+`periodHeading`) · `FamilyMemoryStream.tsx` (export MemoryItem + ArchivedCardsSection; full component retained byte-stable, no longer mounted) · `family.tsx` + `parent.family.tsx` (validateSearch {y,m} + mount FamilyArchiveNavigation) · `family_.memory.$cardId.tsx` (+y/m) · `FamilyMemoryRoom.tsx` (+y/m fallback; history.back + auth UNCHANGED).

**Diff audit:** 0 forbidden change (0 migration/SQL/RPC/policy/edge/route-mới; `routeTree.gen.ts` KHÔNG đụng → routes 52). 1 toolchain devDep auto-bump `@lovable.dev/vite-tanstack-config 2.7.4→2.7.6` (benign, not reverted). **0 duplication** (2 transport-errored agent runs reconciled: run-2 chỉ align hook signatures). **Typecheck PASS** (`bunx tsgo --noEmit` clean, commit b28cd9b7). Deploy: `deployment_id 44a3c0a3-dbf2-40e3-a81b-48d581cd7173` → https://demenart.lovable.app.

**Presence:** reuse one-call-per-space `get_family_stream_presence` (space-wide, NOT window-scoped → payload debt at large scale, recorded/deferred). No third RPC, no per-card.

---

## 5. PRODUCT OWNER VISUAL ACCEPTANCE — ✅ PASS (16/07 · 10 ảnh production · demenart.com)

- **Newest default** `/parent/family` → URL tự chuẩn hoá `?y=2026&m=7`, land có nội dung (không Today, không rỗng).
- **Desktop two-pane:** rail DÒNG THỜI GIAN `2026 (15) · ● Tháng 7 (15)` + period `Tháng 7 · 2026 · 15 ký ức` + `Đã lưu trữ (1)` reachable. MemoryItem reused (creator line, evidence date).
- **Room return-to-period:** card URL `origin=/parent/family&y=2026&m=7`; Back về đúng `?y=2026&m=7`.
- **Mobile 400px:** nút "Dòng thời gian" mở Sheet index, không overflow.
- **Room discipline (Network):** card×1 · engagement×1 · preserve×1 · role×1 · signed-media on-demand · **0 `get_family_memory_stream`**. Mixed card video 0:08 không autoplay. Presence names OK.
- **Governance:** Hùng guardian thấy lời Bà ngoại chỉ "Ẩn" (không Sửa/Rút lại) — D293 button-level; Bà ngoại non-guardian authorized member view; outsider admin `/parent/family` → create-space empty state, **0 leak** năm/tháng/count/card.

**Findings:** 0 F, 0 E blocking. **DEFER:** rail mỏng (data 1 tháng — đúng V112A) · presence space-wide debt · creator/subject dual-line "Bà ngoại"/"Bà Ngoại Test" (S-level D306 §22, KHÔNG phải regression V112C).

---

## 6. INVARIANTS SAU V112C

87 / **190** / 164 / 1 · migrations **101** · routes **52** · edge **16** · journey **37** · preserve **5=1/3/1** (orphaned 1) · threads/messages **2/3** · cards **16** (15/1). **Backend: +1 mig, +2 secdef. Route: NONE (52). Data: 0 mutation. Dependency: 1 toolchain devDep bump (benign).**

---

## 7. CANONICAL CLOSEOUT

- **RULES:** D307 → **D308** (Archive Navigation invariants — xem RULES).
- **SYSTEM_MAP:** v1.12 → **v1.13**.
- **HANDOFF:** **v112C** (file này).

---

## 8. FINAL VERDICT

**✅ V112C LIVING ARCHIVE NAVIGATION — EXPERIENCE PASS.** Backend contract additive + verified; frontend Timeline spine deployed + Product-Owner visual accepted. Phase 3 Navigation foundation đóng.

---

## 9. ON THE HORIZON (Phase 3+)

- Memory Landscape / manual Chapters (lớp ấm phủ trên Timeline spine).
- Recall & Rediscovery (Today in Our Family / On This Day) — cần data year-over-year + hide/mute controls (V112A đã ghi).
- People Browse — cần identity payload (`profile_id`/`child_id` vào card payload) + >1 subject; giải nợ S-level creator/subject dedup (D306 §22).
- Window-scoped presence (khi archive lớn) · Search (Vietnamese FTS, schema mới).
- Media Compatibility Pipeline · Kid Portal V2 · pending repo backup to GitHub.

---

*Endpoint: RULES **D308** · SYSTEM_MAP **v1.13** · HANDOFF **v112C**. Kỷ luật vàng: audit live trước khi tin số; Navigation index-first/payload-lazy — không load-all; ICT bucket canonical; search-param là UX không authority; Stream RPC backward-compatible; deploy sau build PASS, canonical sau visual PASS.*
