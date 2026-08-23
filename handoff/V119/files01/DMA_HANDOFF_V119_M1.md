# 🎞️ DMA_HANDOFF_V119_M1.md — PARENT OUTCOME HISTORY "Những buổi gần đây"

> **CANONICAL ENDPOINT (đọc đầu mỗi phiên):** RULES **D337** · SYSTEM_MAP **v1.25** · HANDOFF **V119-M1** · frontend HEAD **`9a49e415`** · registry **119**.
> Boot protocol: đọc HANDOFF → RULES → SYSTEM_MAP từ đĩa/Jean-provided TRƯỚC mọi việc; re-pin repo + DB read-only; D1 audit live trước khi viết code.

---

## 0. Endpoint & lineage (authoritative)

- **Frontend HEAD (accepted tip):** `9a49e4159b88a95dd8a68ebd98f63a610834ecd8`
- **Lineage:** `78b75e59` (V118-M2) → `b93639af` ("Added parent outcome history") → **`9a49e415`** ("Deleted package-lock.json")
- **DB inventory (0 delta — V119 frontend-only):** 89 tables · 215 functions · 204 SECURITY DEFINER · 166 policies · 33 triggers · 1 cron · registry 119 · 52 routes · 16 Edge Functions.
- **Migration mới nhất:** `v118_m2_appreciation_acknowledgement` (`20260727115750`) — V119 KHÔNG thêm migration.
- **RPC authority:** `get_parent_session_outcomes(p_child_id uuid, p_limit integer)` — STABLE SECURITY DEFINER `search_path=''`, ACL `authenticated/postgres/service_role` (0 PUBLIC/anon), gate `is_child_parent`.
- **Production:** GitHub `main` → Cloudflare Pages CI → `demenart.com`. **Owner Gate PASS** (production observable).

## 1. Milestone tóm tắt

Mở rộng **Parent Outcome Loop** (V117-M1/D332) từ 1 featured card sang **featured + lịch sử "Những buổi gần đây"** — **frontend-only, 0 backend delta**. Đây là D337.

### Product Contract đã đạt (PC-01…PC-15)
- Initial ≤3 outcome; featured = mới nhất (Card lớn **giữ nguyên byte**), older = compact expandable.
- Compact **single-open accordion**; nút explicit **"Xem thêm những buổi trước"** (`has_more && limit<20`), KHÔNG scroll-fetch/auto-fetch.
- Load-more = **grow-and-replace** `p_limit += 3` clamp 20 (RPC có sẵn: fetch `limit+1`, `has_more`, order deterministic `occurred_at DESC, journey_id DESC`, KHÔNG offset/cursor → không duplicate/missing).
- **Media-on-expand:** collapsed KHÔNG render `MomentTile` → 0 signed URL; expand mới ký (reuse `useJourneySigning`, cache mediaId TTL 8′ → re-expand 0 request).
- Inline trong Section; mount `parent.index.tsx` KHÔNG đụng; **không route/nav/Edge/migration mới**; CTA "Xem trọn buổi học" → `?focus=journey:<id>` giữ.
- Appreciation available/sent/acknowledged giữ nguyên semantics; C2 continuity (dưới).
- a11y: `aria-expanded`/`aria-controls`, panel chỉ render khi mở (collapsed ngoài tab order), phân biệt trạng thái bằng shape+chữ+hành vi (không chỉ màu), tap-target ≥44px.
- DB delta = 0; protected surfaces zero-diff.

## 2. Files (frontend-only)

Commit `b93639af` — trong `src/features/parent/session-outcome/`:
1. **`useParentSessionOutcomes.ts`** (rewrite) — limit-state 3 / +3 / clamp 20 · `hasMore`/`loadMore`/`loadingMore`/`loadMoreError`/`retryLoadMore` · **stale-guard `latestKeyRef` + in-flight dedupe `inflightKeyRef` theo `childId|limit`** · đổi con reset `limit→3` đồng bộ · `loadingMore` giữ payload cũ (không skeleton toàn section).
2. **`ParentSessionOutcomeCompactCard.tsx`** (mới) — collapsed summary tĩnh (ngày · buổi · ≤2 kỹ năng +N · trạng thái cảm ơn nếu đã gửi, 0 media) · expand → render `ParentSessionOutcomeCard` (media ký khi mount).
3. **`ParentSessionOutcomeCard.tsx`** (edit tối thiểu) — thêm optional prop bridge `externalSent?`/`onSent?` (C2). Featured KHÔNG truyền → **behavior byte-nguyên**.
4. **`ParentSessionOutcomeSection.tsx`** (rewrite) — featured `[0]` + heading "Những buổi gần đây" + compact list `slice(1)` + nút load-more + `expandedId` single-open + `overrides` map keyed `journey_id`; reset cả hai theo `childId`.

Commit `9a49e415` — xóa `package-lock.json` (Bun authoritative; npm-lock stale = landmine).

**Zero-diff giữ:** `parentSessionOutcomeModel.ts` · `appreciationModel.ts` · `useJourneySigning.ts` · `parent.index.tsx` · mọi protected surface (teacher.session.$id, school-today, journey, consent, Edge).

## 3. Verification

- **RPC load-more proof (read-only, impersonation D333, rollback):** limit1 → 1 outcome + `has_more=true`; limit2 → 2 + `false`; top giống nhau mọi limit → grow-replace deterministic.
- **Route-tree semantic audit (authoritative):** routeTree @ baseline vs @ tip giống hệt tới `export const routeTree`; khác biệt DUY NHẤT = block `declare module '@tanstack/react-start' { interface Register{ssr;router;config} }` (type-only, compile-time, zero runtime). **Route inventory 52 bất biến**, không route thêm/bớt.
- **Owner Gate PASS** (production `demenart.com`, iPhone Safari, 9 ảnh): featured "Vương quốc âm thanh" giữ nguyên · "Những buổi gần đây" + compact "Tiếng mưa rơi" đóng-sẵn-0-ảnh → **mở ra 3 ảnh** · CTA đúng buổi trong Hành trình · "Đặng Mỹ Linh đã đọc lời cảm ơn 💚" + "Gửi lời cảm ơn" hồng · đổi con An↔Khang đúng · iPhone 0 overflow. Chuỗi text khớp byte code → production serve đúng V119-M1.

## 4. Tooling saga (ghi để phiên sau đỡ trả giá — chi tiết D337.5)

- **Platform auto-float:** `@lovable.dev/vite-tanstack-config` bị Lovable float lên `latest` mỗi build (`b93639af`→2.8.3, `9a49e415`→2.8.5; npm latest nay 2.8.6) vì `bunfig.toml` `minimumReleaseAge=86400` **exclude** package này. Correction commit nhiễm thêm bump 2.8.3→2.8.5 (STOP "unauthorized diff" đúng lúc) → **CTO chấp nhận 2.8.5 như platform-managed delta** (latest-track, `package.json`==`bun.lock`==2.8.5, route bất biến).
- **`get_diff` ẩn lockfile:** ở `b93639af` không hiện `bun.lock` (đã đổi cùng `package.json`) → suýt kết luận sai mismatch. **Verify tooling scope PHẢI đọc lockfile bằng `read_file` trực tiếp**, không tin get_diff/narrative agent.
- **Git sandbox ảo của agent ≠ lineage project:** agent báo HEAD `d2759bca`/parent `99f2e33a` + "không commit" trong khi Lovable ĐÃ ghi `9a49e415` (envelope `commit_sha` + `list_edits` mới authoritative). Exit-code frozen-gate của agent chỉ SUPPORTING.
- **Cổng vận hành:** agent-write bị chặn approval ("No approval received" ×3 tới khi Owner bật "always allow") + hết credits giữa chừng; paste tay vào editor KHÔNG tự thành commit `main`.

## 5. Debt

- **P2 (mới, ưu tiên) — Tooling governance:** quyết định chính thức cho floating `@lovable.dev/vite-tanstack-config` — pin/freeze (bỏ khỏi `minimumReleaseAgeExcludes` + pin exact) vs chấp nhận moving channel; cách verify lockfile khi get_diff ẩn nó; tránh mỗi milestone bị chặn bởi tooling churn.
- **P3 — Live data:** không child nào ≥4 outcome → nút "Xem thêm những buổi trước" + multi-accordion mutual-exclusion chưa demo được trên production Owner QA (đã chứng logic + RPC read-only; KHÔNG seed dữ liệu giả). Cần seed 1 demo child ≥4 outcome nếu muốn Owner test trực tiếp.
- **P3 — Placeholder ảnh xám** dưới "Câu chuyện quanh kỷ vật" trong `/parent/journal` của Khang (ảnh 9). Surface **Parent Journey** (protected, V119 KHÔNG đụng) — rà riêng, không chặn.
- Nợ cũ giữ nguyên (V117-M3 Parent outcome mở rộng · G.4+ restyle · V114-SEC1 · FMN E2E fixture · Day-state semantics v2 · Secondary-parent fixture).

## 6. Session-boot pointer (phiên sau)

1. Đọc HANDOFF (file này) → RULES (D337) → SYSTEM_MAP (v1.25) từ đĩa.
2. Re-pin: `list_edits` (tip `9a49e415`, parent `b93639af`) + `execute_sql` inventory (119/89/215/204/166/33/1, RPC ACL 0 anon).
3. **Verify tooling bằng `read_file`** package.json/bun.lock nếu chạm build (get_diff ẩn lockfile).
4. D1 audit live trước khi viết code; paste-mode default (agent chỉ khi "tự áp").

*Endpoint: RULES **D337** · SYSTEM_MAP **v1.25** · HANDOFF **V119-M1** · code HEAD **`9a49e415`**. Cập nhật "tới đâu ghi tới đó" (KỶ LUẬT VÀNG).*
