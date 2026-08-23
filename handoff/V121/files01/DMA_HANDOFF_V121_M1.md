# 🎞️ DMA_HANDOFF_V121_M1.md — PARENT DAILY VALUE · M1

> **Sprint closeout** — Home-Centric Continuity (Parent Home tái tổ chức quanh daily value). Frontend-only.
> **Đọc boot:** `DMA_RULES.md` → `DMA_SYSTEM_MAP.md` → **file này** (mới nhất), rồi re-pin live DB inventory + `list_edits` trước khi làm.

---

## A. VERDICT

**`FINAL PASS — DMA V121-M1 CLOSED`.** Owner Gate PASS trên production `demenart.com` (7 ảnh, 07/08/2026). Parent Home là "daily-value first"; recovery tooling/routeTree hoàn tất; canonicalized (RULES D339 · SYSTEM_MAP v1.27).

## B. ENDPOINT

- **RULES:** D339 · **SYSTEM_MAP:** v1.27 · **HANDOFF:** V121-M1
- **Frontend HEAD (accepted tip):** `ed9ca9e5fa301f2dbb67790fec76543d550df50b` ("Reverted vite-tanstack-config")
- **Registry:** 119 (bất biến) · **Route:** 204 RouteImport / 52 convention (bất biến)
- **DB inventory (re-verified, 0 delta):** 89 tables · 215 functions · 204 SECURITY DEFINER · 166 policies · 33 triggers · 1 cron · 16 Edge · migration mới nhất `v118_m2_appreciation_acknowledgement` (`20260727115750`)
- **Tooling:** `@lovable.dev/vite-tanstack-config` **exact 2.8.5** (package.json == bun.lock; verified read_file L65 + L241 sha512) · Bun authority · `bun.lock` lockfile duy nhất

## C. PRODUCT OUTCOME (cái gì đổi cho người dùng)

Parent Home chuyển từ "hero-ký-ức-first" sang **"daily-value-first"**. Thứ tự mới:

1. **Identity** ("Hôm nay của {con}")
2. **ChildSwitcher**
3. **Daily Focus** — session outcome "Sau buổi học" là **nội dung CHÍNH**, ngay sau child context (không hero 16:9 phía trên). Featured buổi gần nhất + "Những buổi trước" (tối đa 2, compact single-open, **không load-more** trên Home).
4. **Journey continuation** — link nhẹ "Xem hành trình của {con} · Đã lưu N điều · M do ba mẹ ghi lại" (tái dùng count sẵn, **không request mới**).
5. **Memory (demote + dedupe)** — MemoryHero xuống dưới, **ẩn khi trùng** featured outcome theo stable moment_id/media_id; nếu không có hero → affordance "Ghi thêm/Bắt đầu".
6. **Family signal** (nếu có) → **"Nhìn lại"** (discovery).

**GỠ khỏi Home:** "Gần đây" strip · "Cùng con hôm nay" card · thẻ "Hành trình" riêng · thẻ "Thế giới của con". Chronology cũ vẫn ở `/parent/journal`. Home giữ tông ấm — không dashboard/điểm số/social.

## D. TECHNICAL SCOPE (frontend-only)

**Đúng 2 file feature:**
- `src/routes/_authenticated/parent.index.tsx` — reorder; gỡ `buildRecent`/RecentLeaf + 2 import thừa (HeartHandshake, KeyRound); state `featuredIdentity: FeaturedOutcomeIdentity | null | "pending"` (reset "pending" khi đổi con); dedupe hero theo stable identity; signing gate; Journey continuation link.
- `src/features/parent/session-outcome/ParentSessionOutcomeSection.tsx` — export `FeaturedOutcomeIdentity` + prop `onFeaturedIdentity`; report featured identity qua effect; `HOME_HISTORY_MAX=2` (`older=slice(1,3)`); đổi tên "Những buổi gần đây"→"Những buổi trước"; **bỏ Home load-more** (hook `loadMore/hasMore/loadingMore/…` giữ nguyên).

**Corrections (C1):** C1.1 type alias `FeaturedIdentityState` giữ `useState<…>("pending")` 1 dòng (tránh `<` cuối dòng bị paste nuốt — D8). C1.2 signing gate `shouldSignHero = !!hero && heroSettled && !heroDuplicatesFeatured` → 0 signed-media request lúc pending/duplicate/no-hero, 1 request khi settled+distinct.

**Backend/DB/routes:** 0 delta. Không migration, không Edge, không route mới, không dependency mới.

## E. OWNER GATE — EVIDENCE (production `demenart.com`, 7 ảnh, 07/08/2026)

- **An (ph.hung.kidshouse, 2 outcome + Khang):** Daily Focus "SAU BUỔI HỌC / Lần gần nhất của con" primary ngay sau ChildSwitcher, không hero trên · "NHỮNG BUỔI TRƯỚC" 1 compact "Tiếng mưa rơi" đóng sẵn, **không nút load-more** · Journey "Xem hành trình của An · Đã lưu 44 điều · 21 do ba mẹ ghi lại" · MemoryHero "Tác phẩm mới của con" demote xuống dưới (creation distinct — giữ đúng, không trùng featured) · **Gần đây/Cùng con hôm nay/Hành trình-riêng/Thế giới-của-con GỠ HẾT** · đổi An→Khang sạch (Khang empty trung thực "Chưa có nhật ký buổi học nào…", "2 điều", không hero vì không media) · ack "Đặng Mỹ Linh đã đọc lời cảm ơn 💚".
- **479px:** không tràn ngang, bottom-nav 4 mục rõ, không che nội dung cuối.
- **Network (An, 479px):** `media.demenart` **2/8 request** — 2 asset khác nhau (moment featured + hero), **200 cả hai** (jpeg disk-cache + png 40.9kB), không N+1, không ký trùng media_id → **C1.2 signing gate verified production**.
- **Bình (ph.toan, appreciation):** featured + chip overflow "+1 ghi nhận khác" (>3 skill) + "đã đọc lời cảm ơn 💚" → NHỮNG BUỔI TRƯỚC. Vòng lặp cảm ơn/đã đọc còn nguyên.

**Chrome MCP không kết nối (phiên 4 liên tiếp) → Owner tự chạy Gate.** Owner Gate luôn Owner-executed (real login).

## F. BUILD / RECOVERY NOTE (concise)

- **Root cause "Build unsuccessful":** commit tay `67280d72` (Lovable Code Editor) **gỡ generated Register block** `declare module '@tanstack/react-start' { interface Register {ssr;router;config} }` khỏi `routeTree.gen.ts` → `bunx tsc --noEmit` fail. **2 file feature vô can.**
- **Fix routeTree:** build regen tự khôi phục block (`085d4439`); route membership 204 bất biến (type-only, D339.3).
- **Tooling incident:** cùng lúc, sandbox agent non-frozen init **float `@lovable.dev/vite-tanstack-config` 2.8.5→2.9.1** (STOP-gate #10) → CTO reject → **Phase C-R1 revert** → `ed9ca9e5` tooling về 2.8.5 (package.json + bun.lock verified; frozen-install exit 0 KHÔNG re-float). Cloudflare `SKIP_DEPENDENCY_INSTALL=1`+frozen-install → 2.8.5 deterministic; float không gate production (D339.4).
- **Lineage:** `9a49e415` → `677f13ce` → `67280d72` → `085d4439` → **`ed9ca9e5`**. Sandbox-only: `26a7bcb "Work in progress"` (không trên main; D339.5).
- **Gates `ed9ca9e5`:** frozen-install 0 · tsc 0 · build 0 · RouteImport 204 · Register block present.

## G. RESIDUAL DEBT (record-only — KHÔNG fix ở M1)

- **P2** — Journey continuation card nặng thị giác hơn "light entry" lý tưởng (UX iteration).
- **P3** — copy no-outcome ("Chưa có nhật ký buổi học nào…") có thể ấm hơn.
- **P2 tooling-governance** — sandbox Lovable re-float `@lovable.dev/vite-tanstack-config` mỗi agent-install (non-frozen init). Dứt điểm: bỏ khỏi `minimumReleaseAgeExcludes` + pin exact → **maintenance milestone RIÊNG, cần CTO mở**. Không chạm production (CF frozen).

## H. NEXT (câu hỏi sản phẩm, KHÔNG milestone)

Home đã "daily-value first". Câu hỏi mở cho phiên sau: sau khi Daily Focus lên đầu, **Journey continuation** nên nhẹ tới đâu (P2), và **"Những buổi trước"** có nên thêm ngưỡng "xem tất cả → /parent/journal" thay vì im lặng ở 2 buổi? Cùng track V119/journal loop. *(Ngoài ra: Kid Portal V2, Media Organization Sprint, /admin interior — chưa xếp.)*

---

**Trạng thái:** `FINAL PASS — DMA V121-M1 CLOSED & CANONICALIZED`. RULES D339 · SYSTEM_MAP v1.27 · HANDOFF V121-M1 · HEAD `ed9ca9e5`.
