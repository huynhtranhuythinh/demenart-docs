> ⬇️ APPEND-ONLY BLOCK — dán vào CUỐI file thật `DMA_SYSTEM_MAP.md` (sau mục V111G/v1.12) và bump tiêu đề dòng 1 `v1.12` → `v1.13`. KHÔNG regenerate toàn file (bản đọc trong phiên bị truncate — D90).

---

## V112C — FMN PHASE 3 · LIVING ARCHIVE NAVIGATION (16/07/2026 · v1.12 → v1.13)

**Memory Navigation Layer — sprint BUILD đầu tiên của Phase 3.** Additive backend (+2 secdef, mig 101) + frontend Timeline spine. Kiến trúc lõi KHÔNG đổi; đây là tầng wayfinding phủ TRÊN Stream/Room.

**Backend contract (mig 101 · secdef 188→190 · 0 schema/policy/data change):**
- `get_family_archive_index(p_space_id)` → `{ok, space_id, years:[{year, total, months:[{month,count}]}]}` — density metadata, active+accessible only, ICT bucket, year/month DESC, sparse omitted, no payload. secdef · search_path='' · grant authenticated only.
- `get_family_memory_window(p_space_id, p_year, p_month, p_limit=20, p_before_occurred_at, p_before_created_at, p_before_id)` → `{ok, space_id, year, month, cards[], has_more, next_cursor}` — same card shape as Stream, keyset (no OFFSET), limit clamp 1..50, reuse `family_card_effective_access` (D284).
- `get_family_memory_stream` **UNCHANGED, byte-stable** (legacy/Recent surface; hash `92fbbfa1…47d4` before=after).
- ICT bucket contract: `(occurred_at AT TIME ZONE 'Asia/Ho_Chi_Minh')` — query/presentation only, 0 data mutation.

**Frontend (commit `b28cd9b7` · Lovable project `d9d56000-…-651edc53d73f`):**
- Data: `useFamilyArchive.ts` (index ×1/space) · `useFamilyMemoryWindow.ts` (window + keyset + token stale-guard + reset-on-period-change).
- UI: `FamilyArchiveIndex.tsx` (rail desktop / Sheet mobile, aria-expanded year, aria-current month, quiet counts) · `FamilyMemoryPeriod.tsx` (period heading `Tháng M · YYYY` + `N ký ức` secondary + flat MemoryItem + keyset load-more) · `FamilyArchiveNavigation.tsx` (orchestrator: two-pane desktop / bottom Sheet mobile, newest-default ref-guard, openCard origin+y+m).
- Grammar: `periodHeading(year,month)` (pure) added to `familyExperienceGrammar.ts`. `MemoryItem` + `ArchivedCardsSection` now exported from `FamilyMemoryStream.tsx` (full Stream component retained, no longer mounted).
- Routes: `/family` + `/parent/family` gain `validateSearch {y,m}` and mount `FamilyArchiveNavigation` (base prop). `/family/memory/$cardId` gains optional y/m → Room fallback back-to-period. **Routes remain 52** (search-param only, `routeTree.gen.ts` untouched). Room `/family/memory/$cardId` authorization UNCHANGED.

**Request discipline (design + live Network):** archive load = index ×1 + window ×1 + presence ×1/space (reused, space-wide) + role/space as existing; **0 `get_family_memory_stream` in archive nav**; month change = window ×1 (no index/presence refetch); Room = card×1/engagement×1/preserve×1/role×1/signed-media on-demand; no per-card engagement/profile; signed media on-demand.

**Search-param behavior:** `?y=&m=` = UX navigation state, never authority. Invalid → Newest fallback (not Today). Back/Forward/F5 preserve period. Room origin period = UX hint only.

**Deferred payload debt:** presence is space-wide one-call (not window-scoped) — acceptable now, revisit at large archive scale.

**Visual acceptance (16/07, 10 ảnh production demenart.com): PASS** — Newest default · desktop two-pane rail · Room return-to-period (`origin+y+m`) · mobile 400px Sheet · Room request discipline (0 Stream RPC, mixed card video no-autoplay) · governance button-level (guardian Hùng thấy lời Bà ngoại chỉ "Ẩn") · outsider admin 0 leak (create-space empty state).

**Invariants:** 87/**190**/164/1 · mig **101** · routes **52** · edge **16** · journey **37** · preserve **5=1/3/1** · threads **2/3** · cards **16** (15/1). Endpoint: RULES **D308** · SYSTEM_MAP **v1.13** · HANDOFF **v112C**.

**Deferred → Phase 3+:** Memory Landscape / manual Chapters · Recall (Today in Our Family / On This Day — cần year-over-year data + hide/mute) · People Browse (cần identity payload + >1 subject; nợ S-level creator/subject dedup D306 §22) · window-scoped presence · Search (Vietnamese FTS) · Notification · AI.

**FINAL: ✅ V112C EXPERIENCE PASS.**
