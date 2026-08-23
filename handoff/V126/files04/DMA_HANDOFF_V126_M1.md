# 🎨 DMA_HANDOFF_V126_M1.md — PARENT MEMORY JOURNEY · MEANING BRIDGE + IA ALIGNMENT · M1

> **Sprint closeout** — DMA chuyển từ *school record system* → *child artistic memory journey* bằng cách **KÍCH HOẠT tầng meaning ĐÃ TỒN TẠI** (evidence → readiness → discovery capsule → parent experience), KHÔNG xây engine mới. C0 validate capsule (zero-mutation) · C1 Home meaning bridge (frontend-only, 0 DB) · C2 real-login QA · C3 IA alignment (nav + naming). Trong C3 phát sinh **routeTree Register regression** (Lovable regen quét mất augmentation trong `*.gen.ts`) → fix vĩnh viễn dời sang `src/router.tsx` (D344.5). **Zero backend/DB/Edge/signer/Bunny/dependency delta.**
> **Đọc boot:** `DMA_RULES.md` → `DMA_SYSTEM_MAP.md` → **file này** (mới nhất), rồi re-pin live DB inventory + `list_edits` + deployed signer version trước khi làm.

---

## Executive Verdict

**`PASS — DMA V126-M1 CLOSED & CANONICALIZED`.** Owner Gate PASS (ChatGPT Release Authority, real-login PH Nguyễn Văn Hùng, production `demenart.com` + preview build). Meaning engine kích hoạt end-to-end trên data eligible thật; C1 bridge 3-state PASS; C3 IA alignment PASS với mobile frozen-4 bảo toàn; build PASS. Canonicalized (RULES **D344** · SYSTEM_MAP **v1.32**).

## Product Thesis

DMA moved: **Digital School Record → Child Artistic Memory Journey.** Câu hỏi đổi: KHÔNG "Con học bao nhiêu?" mà **"Con đã thay đổi như thế nào?"**. KHÔNG tạo: feed · dashboard · scoring · AI summary · social · ranking · child evaluation. Nguyên tắc: **Memory > Metric · Meaning > Quantity · Child understood, not measured.**

## Endpoint

- **RULES:** D344 · **SYSTEM_MAP:** v1.32 · **HANDOFF:** V126-M1
- **Frontend HEAD (accepted tip):** `6b860338125a63e8b74815d549db5be723ad732a` (`6b860338`) — `manual_update`
- **Lineage:** `b3372e1c` (V125-M0 tip) → `742db062` (C1 bridge) → `af4b37cc` (C1.6 copy-fix) → `d498bf75` (C3 paste + **routeTree regression**) → `f8723cc4` (journal rename + copy-revert) → `28325e5b` (**empty commit — regen-strip proof**) → **`6b860338`** (Register → router.tsx, accepted tip). Verify authoritative `read_file`@SHA + `list_edits` (get_diff ẩn lockfile — D339.5).
- **Signer:** `get_signed_media_url` **deploy-25 = v24** — BẤT BIẾN, 0 delta
- **Bunny:** `dma-private`/`dma-learning`/`dma-public` — 0 change
- **Registry:** 119 · **Route:** 52 — bất biến
- **DB inventory (re-verified live):** 89 tables · 215 functions · 204 SECURITY DEFINER · 166 policies · 1 cron · 16 Edge · migration tail **`20260807130914`** — BẤT BIẾN (KHÔNG migration V126)
- **Tooling:** Bun sole PM · `bun.lock` byte-unchanged · `@lovable.dev/vite-tanstack-config` exact **2.8.5** · `2.9.1` count = 0 · tất cả edit `manual_update` (zero re-float)

## Phase A — Reality audit (read-only)

Discovery meaning layer **ĐÃ TỒN TẠI và hoàn chỉnh**, chỉ LẠNH. Spine `get_child_journal` đã hợp nhất 4 nguồn (demen session/badge · parent `parent_memories` · family FMN · moments/creations) — và parent-authored meaning là bucket lớn nhất. Evidence layer (`derive_child_evidence_internal`) + readiness (`compute_child_evidence_readiness` v2, gate longitudinal + chống retrospective) + capsule engine (`generate_discovery_capsule` + `discovery_capsules`) + parent surface `/parent/discovery` ("Nhìn lại") đều đã build. **Gap = activation + continuity**, KHÔNG phải thiếu hạ tầng: `discovery_capsules = 0` (chưa từng sinh), teacher meaning-signal (`is_highlight`/parent_visible note) gần như trống, `parent_memories` dồn 1 bé. An `…0041` **eligible current_3m ngay** (failed=[]) nhưng chưa có capsule.

## Phase B / C0 — Controlled validation (ZERO mutation)

KHÔNG insert capsule qua SQL (D2: `auth.uid()` NULL → `is_child_parent` fail; bypass service_role = test không trung thực + để rác). Thay vào: chạy chính `build_discovery_candidates_internal` mà generate() tiêu thụ + áp đúng chọn/sort/limit của generate() + render qua shipped `discoveryModel`. Payload faithful (generate() chép builder verbatim; `get_discovery_capsule` re-validate cùng builder+window → suppress khi mất bằng chứng).
- **Evidence trace PASS:** mọi group_key → row của An (8 kid_creations + 6 parent_memories + 1 learning_moment + 4 session journey-row). Bài học: session ref_id-NULL group_key theo `child_journey.id` KHÔNG `lesson_sessions.id`.
- **LINH HỒN PASS:** không đánh giá trẻ · không scoring · không ranking · không over-claim (claim là frequency-pattern, "đang dần hiện rõ") · evidence traceable · parent cảm nhận trưởng thành không bị chấm (conversationPrompts + ANTI_PRESSURE + boundary chối bỏ đánh-giá-năng-lực).
- **Verdict:** PASS → proceed C1. **Về sau xác thực bằng capsule THẬT: dự đoán read-only = 4 item byte-identical.**

## Phase C1 — Parent Meaning Bridge (frontend-only, 1 file, 0 DB)

`MeaningBridge` trong `parent.index.tsx`: **list-first** `list_discovery_capsules` (rẻ) → có capsule = **State 1 has_capsule**; else **lazy** `get_child_evidence_readiness` → eligible = **State 2 eligible_without_capsule** / else = **State 3 accumulating_insufficient**; hold=null, error=quiet fallback. **No auto generation** (giữ parent-initiated), no scoring, no comparison, no inline capsule item (bridge-only link-out). Child-scoped Correction-A. Copy state-3 (Owner-approved C1.5): *"Mỗi trải nghiệm của con đang góp thêm một phần vào câu chuyện riêng. Khi hành trình đủ đầy hơn, ba mẹ có thể cùng nhìn lại những điều đang dần hình thành."* 0 RPC/migration/Edge/dependency.

## Phase C2 — Real-login QA

- **An eligible flow PASS:** Home State 2 (eligible) → `/parent/discovery` "Tạo Bản Khám Phá" → capsule sinh (`384042c1`, 4 items khớp **byte-identical** C0) → Home chuyển State 1 (has_capsule).
- **Insufficient child PASS:** Khang (maturity insufficient, 0 capsule, 3-window fail) → State 3 accumulation, degrade nhẹ, ANTI_PRESSURE, không "chấm".
- **Child switching PASS:** An↔Khang không bleed chéo con (Daily Focus / Nhật ký count / bridge state đều cập nhật đúng bé).

## Phase C3 — Parent IA Alignment

- Nav `parentNav.ts`: **"Hành trình" → "Nhật ký"** (records, `/parent/journal`, BookHeart) + thêm **"Nhìn lại"** (`/parent/discovery`, **Telescope**, `railOnly`).
- `ParentBottomNav` filter `!railOnly` → **mobile frozen-4 preserved** (grid-cols-4 bất biến: Hôm nay · Nhật ký · Gia đình · Của con); "Nhìn lại" chỉ ở rail + tablet drawer; mobile vào qua Home bridge.
- Bridge title → "Nhìn lại"; journal h1 → "Nhật ký của {con}".
- Vocabulary: "Hành trình" = product concept (brand/umbrella) GIỮ; "Nhật ký" = records; "Nhìn lại" = meaning.
- Rail (`ParentIdentityRail`) + tablet (`ParentTabletBar`) map cả `PARENT_PRIMARY_NAV` → "Nhìn lại" tự hiện (KHÔNG sửa 2 shell này).

## Incident Report — routeTree Register regression

- **Cause:** `declare module '@tanstack/react-start'` Register augmentation nằm trong `src/routeTree.gen.ts` (generated). Lovable **regenerate `routeTree.gen.ts` khi save** → manual insertion **bị xoá**. Chứng minh: empty-commit `28325e5b` (thêm block → regen quét → net 0 diff) + block vắng qua 3 lần thử vá tay. Đây là gốc build-fail V121-M1 tái diễn ở dạng nặng (regen-strip, không chỉ manual-remove).
- **Resolution (permanent):** dời `declare module '@tanstack/react-start'` Register sang **`src/router.tsx`** (hand-authored, regen không đụng). `getRouter` local (in-scope) + `import type { startInstance } from "./start.ts"`. Đúng 1 khai báo Register (no duplicate); `routeTree.gen.ts` = generated thuần. Build PASS (preview load OK → tsc xanh).
- **Rule mới (D344.5):** `*.gen.ts` KHÔNG phải extension point. CẤM chèn code tay vào generated files; mọi module augmentation / extension phải nằm trong hand-authored source. Thay workaround cũ "build regen-restore".

## Final QA

| Surface | Kết quả |
|---|---|
| Desktop rail | Hôm nay · Nhật ký · **Nhìn lại**(Telescope) · Gia đình · Thế giới — PASS |
| Tablet drawer (480px) | có **Nhìn lại** — PASS |
| Mobile bottom nav (390px) | **frozen-4** (Hôm nay · Nhật ký · Gia đình · Của con), KHÔNG Nhìn lại — PASS |
| Home meaning bridge | title "Nhìn lại"; State 1/2/3 đúng — PASS |
| Journal | h1 "Nhật ký của An" — PASS |
| Discovery | eligible → generate → capsule persist; insufficient degrade nhẹ — PASS |
| Capsule content vs C0 | byte-identical 4-item + tone LINH HỒN — PASS |
| Build | preview `preview--demenart.lovable.app` load OK → tsc xanh (Register ở router.tsx bền) — PASS |

## DB / Delta

**ZERO backend/DB delta.** Inventory bất biến 89/215/204/166 · 16 Edge · registry 119 · routes 52 · migration tail `20260807130914`. Frontend delta: `parent.index.tsx` · `parent.journal.tsx` · `parentNav.ts` · `ParentBottomNav.tsx` + `router.tsx` (Register relocation) + `routeTree.gen.ts` (Register removed — moved). Capsule DATA (hợp lệ, immutable): An `384042c1` general/current_3m 4-items qua UI real-login. Tất cả edit `manual_update`, pin 2.8.5 giữ, bun.lock byte-unchanged, zero re-float. **Rollback = frontend revert** (backend/data 0).

## Demo pilot accounts (password `Test@123`, `@demo.demenart.com`)

- PH KHM Nguyễn Văn Hùng: `ph.hung.kidshouse` (bé An `…0041` = capsule-eligible; Khang `…0045` = insufficient)
- Master KHM Nguyệt Thi: `hieutruong.kidshouse` · GV KHM Mỹ Linh: `gv.linh.kidshouse`
- Master MNDM Phương Dung: `hieutruong.demen` · GV MNDM Ngọc Hân: `gv.han.demen` · PH MNDM Văn Thành: `ph.thanh.demen`

## Residual debt (record-only)

- Teacher meaning-signal (`is_highlight` / parent_visible note) gần như trống → phần lớn bé sẽ `insufficient`; Home bridge đã degrade trung thực. Populate teacher observation = product decision phiên sau.
- `parent_memories` concentrated 1 bé (demo data).
- Comment `parent.index.tsx` "7 · Nhật ký của con" hơi lệch tên bridge ("Nhìn lại") — cosmetic, non-blocking.
- Inherited: School Drive eager-sign/lazy (Candidate 2); media compat MOV/HEVC/WebM; `/kid` Portal V2 (PIN-based, namespace reserved); optional excludes-hardening tooling milestone.

## Next (câu hỏi sản phẩm, KHÔNG milestone)

Meaning layer đã kích hoạt + IA đã sạch. Mở cho phiên sau: (1) auto-generation capsule khi eligible (đổi lifecycle manual/consent — cần contract riêng); (2) teacher meaning-signal populate (highlight/note per-child) để nhiều bé đủ điều kiện; (3) per-domain "change" narrative; (4) `/kid` Portal V2. *(Không tự mở nếu CTO chưa lock.)*

---

**Trạng thái:** `PASS — DMA V126-M1 CLOSED & CANONICALIZED`. RULES D344 · SYSTEM_MAP v1.32 · HANDOFF V126-M1 · HEAD `6b860338` · signer deploy-25 (v24, BẤT BIẾN) · tooling 2.8.5 (bun.lock byte-unchanged) · zero backend/DB delta. Meaning engine kích hoạt (không xây mới) · routeTree Register dời sang router.tsx (D344.5, chấm dứt V121-M1 recurring) · mobile bottom nav frozen-4 preserved.
