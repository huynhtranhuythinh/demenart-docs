# DMA V113G.2 — HÀNH TRÌNH + NHÌN LẠI + SHARE RE-HOME · CLOSEOUT A–Q
2026-07-18 ~10:35 GMT+7 · Claude PM/Builder · Operating mode: CONTINUE DIRECTLY ON MAIN.

## A. VERDICT
**V113G.2 PASS — LIVE ON MAIN, toàn bộ QA hoàn tất trên preview (bản cuối `567d2cc4`) + production (bản `e610434c` trở về trước); còn đúng 1 mảnh self-verify 20 giây cho PO ở mục Q.**

## B. BASELINE & COMMIT RANGE — CI EXPOSURE DECLARATION
Baseline vào: `8021c940`. Chuỗi commit main (MỖI COMMIT ĐÃ/ĐANG DEPLOY PRODUCTION QUA CLOUDFLARE CI — không gọi deploy_project):
`12917e93` JourneyShareAction → `4f577a3c` ParentJourneyViewer → `789564b7` parent.journal → `1cf65494` parent.discovery → `ccd955e0` JourneyDetail → `e610434c` normalize (prettier, chỉ Viewer đổi) → **`567d2cc4` P1 focus-hydrate fix = HEAD**.
5 commit đầu do phiên-trước-bị-treo hoàn tất muộn (Owner directive: coi là phần việc phiên trước, không revert theo nguồn); 2 commit cuối do phiên này. Contiguous, không unrelated work.

## C. FILES TRONG SCOPE (6 — đúng phê duyệt)
Changed: `parent.journal.tsx` (rebuild mounted composition) · `parent.discovery.tsx` (provider rebind) · `ParentJourneyViewer.tsx` (shareMomentId wiring) · `JourneyDetail.tsx` (Share slot + DMA tokens). New: `JourneyShareAction.tsx`. Touched-by-normalize-only: (không file nào ngoài 5 trên; normalize chỉ format Viewer). KHÔNG đụng: Stage/Rail/MemoryConversation/model/signing (mtime nguyên ZIP), mọi RPC/RLS/Edge/consent, routeTree/package/lockfile/types (fingerprint 4/4 byte-identical), migrations 101.

## D. SECURITY STOP-GATE ĐÃ KÍCH HOẠT & GIẢI QUYẾT (incident)
Giữa phase, list_edits phát hiện commit lạ đổ vào main + file workspace đổi giữa 2 lần đọc → **STOP đúng lúc, zero write từ phiên này trong thời gian mơ hồ, zero xung đột**. Owner xác nhận: phiên trước treo → hoàn tất muộn; single-session từ đó. Toàn bộ code phiên trước được **re-audit như third-party (D116)** trước khi nhận trách nhiệm: nội dung khớp spec từng mục, live≡local sau normalize.

## E. SHARE RE-HOME — OPTION B (Owner Gate) — VERIFIED
Contract cũ giữ NGUYÊN VẸN: `share_links` SELECT (creator-only RLS) · RPC `create_private_share_link` TTL 1440' · RPC `revoke_share_link` · route `/share/{token}` · không audience công khai · token không bao giờ vào log/console. Eligibility deterministic: **CHỈ moment** (`scope_type='moment'`), derive tại Viewer (`current.source==='moment'`), render tại Detail như **secondary utility cạnh ngày** — độc lập hoàn toàn với edit/archive/preserve, **không canManage** (D293-safe). Live QA production: creation → nút Chia sẻ **ẨN**; moment → **HIỆN**; popover mở đúng empty-state copy + chú thích 24h/thu hồi. **Không tạo/thu hồi link nào trên production** (mutation không được phê duyệt — create/revoke path được verify ở mức code + error-mapping đầy đủ 6 reason).

## F. HÀNH TRÌNH (journal) — VERIFIED
Mounted composition trong shell G.1: serif identity → shared ChildSwitcher (persisted) → Ghi lại emerald → Viewer (Detail→Stage→Rail giữ nguyên hành vi V92B.2) → TruthState loading/empty/error chuẩn F4. Dead branch V74/75 (compact timeline + ShareMomentButton cũ + leaves + lightbox) **đã gỡ, zero consumer còn lại** — chính là nguồn giảm 163 lỗi lint debt. Contracts nguyên: `get_child_journal` · `archive/restore_parent_memory` (toast + Hoàn tác) · sự kiện `parent-journal:refetch` (V109C reverse_preserve) · composer save→focus.

## G. DEEP-LINK `?focus` — VERIFIED (3 lớp)
Valid-newest: chip đúng, không banner. **Valid-non-newest** (moment `d1000000…a1` · 26/6): mở ĐÚNG kỷ vật cũ + Share hiện theo deep-link — contract thật, không trùng hợp. Invalid/foreign: banner truthful "Không tìm thấy kỷ vật được liên kết trong hành trình của {con}… đang xem kỷ vật mới nhất" + nút đóng, **không leak nội dung**, viewer fallback newest.

## H. P1 TỰ PHÁT HIỆN & TỰ SỬA TRONG SCOPE
Bug: effect reset theo `[selectedChildId]` chạy cả ở lần provider-hydrate đầu (null→id) → xoá `focusItemId` ngay sau mount → **mọi `?focus` bị vô hiệu** (case newest pass do trùng hợp — bị lật mặt bởi test invalid). Fix `567d2cc4`: `prevChildRef` guard (đồng pattern discovery). Verified PASS trên preview (banner hiện; non-newest mở đúng).

## I. NHÌN LẠI (discovery) — VERIFIED
Route-local child fetch **đã gỡ** — dùng provider + shared switcher (persistence chung: đổi con ở Journal giữ nguyên sang Discovery ✓ qua race test). Sequencing kép (`dataSeqRef`/`detailSeqRef`) + `capsuleParamRef` (không refetch thừa). Deep-link `?capsule` invalid/foreign → "Không tìm thấy bản khám phá này trong hồ sơ của {con}" + Quay lại, **không leak**. Đổi con → **drop `?capsule` trong 300ms** + clear data ngay. Contracts nguyên 4 RPC; boundary copy "không phải đánh giá năng lực…" giữ đúng. An hiện chưa có capsule (thực trạng data — readiness panel hiển thị đúng); generate không chạy trên production (mutation).

## J. RACE / SEQUENCING — VERIFIED LIVE
Journal An↔Khang: 150ms sau click — h1 đổi, stale content (41/41) biến mất tức thì; quay lại An phục hồi đủ. Discovery tương tự với drop param. Đúng chuẩn Correction-A toàn tuyến.

## K. RESPONSIVE MATRIX — 9/9 PASS + ZERO OVERFLOW
Iframe harness (border-0) trên /parent/journal: **1440·1024 = rail · 1023·768·500·480 = tablet bar · 479·430·390 = bottom nav** — amendment 479 chuẩn từng px trên composition mới; `scrollWidth ≤ clientWidth` ở mọi mốc (không tràn ngang stage/rail). Visual samples: ss_7818knun5 (desktop), ss_5970wz1br (Share popover), ss_5912w8hqz (390 mobile), ss_912771cep (discovery).

## L. REGRESSION — 6/6 ROUTES
/parent (hero An ✓) · /parent/family ("Gia đình Hùng" + archive nav V112C ✓) · /parent/kid ✓ · /parent/consent ✓ · /parent/settings ✓ · /parent/journal ✓ — tất cả mount trong shell, không trang trắng, không văng auth.

## M. CONSOLE & NETWORK
Network: **0 request ≥400** trong toàn bộ phiên QA preview. Console: đúng **1** hydration-mismatch với bằng chứng attribute `__processed_…__="true"` bị extension máy PO inject vào <body> trước React (lần thứ 2 có chuỗi chứng cứ này) — **environment, không phải defect**. Open Item giữ nguyên: verify Incognito khi tiện.

## N. STATIC QA (amendment-governed)
Prettier 5/5 PASS · ESLint targeted **0E/0W** · tsc 0 · build local exit 0 · Lovable build/typecheck pass mỗi commit · full lint **4.774E/26W = −163E/−6W** so baseline 4.937/32 (toàn bộ mức giảm đến từ gỡ dead branch trong file được phép — KNOWN DEBT REDUCED, ZERO NEW DEBT) · 0 finding từ file G.2 · fingerprints protected 4/4 nguyên · migrations 101 · secdef 190.

## O. DATA / MUTATION LEDGER
Production data mutation: **0** (không share link nào tạo/thu hồi; không capsule generate; chỉ read + audit-log tự nhiên của các view RPC). Backend/Edge/RLS/consent: không đụng.

## P. ROLLBACK ORDER (exact, ngược)
`567d2cc4` → `e610434c` → `ccd955e0` → `1cf654945` → `789564b7` → `4f577a3c` → `12917e93` ⇒ về `8021c940` (G.1+amendment nguyên vẹn). Mỗi revert tự deploy qua CF CI. Không migration/data nào cần đảo.

## Q. PENDING & NEXT
**1 mảnh self-verify (20s):** lúc kết thúc phiên browser, demenart.com đang CF-propagation-lag (HTML mới + assets 404 tạm thời — hiện tượng hạ tầng, preview đã chứng minh code đúng). PO mở:
`https://demenart.com/parent/journal?focus=journey%3A00000000-0000-0000-0000-000000000000`
→ thấy banner "Không tìm thấy kỷ vật được liên kết…" = **V113G.2 PRODUCTION-CONFIRMED, đóng hồ sơ**. (Nếu sau 15 phút vẫn trắng trang → CF build fail, báo em.)
Open Items chuyển tiếp: favicon generic (G.8) · Incognito console verify · retry-backoff media (G.8) · child-fetch error collapse trong provider (G.3+ candidate). **Không canonicalize** — ledger đã cập nhật, gộp tại closeout V113G-M1. Slice kế tiếp theo lộ trình: **G.3 (Gia đình/FMN restyle)** — chờ execution prompt hoặc chỉ đạo PO.
