# DMA V113G.1 — OWNER GATE REPORT (FINAL)
2026-07-17 ~15:05 GMT+7 · Claude PM/Builder · Sau manual test 1–4 ✓ của PO + 19 evidence screenshots.

## A. VERDICT
**V113G.1 PASS — IMPLEMENTATION + VISUAL VERIFIED. CHỜ OWNER GATE DECISION** (2 quyết định ở mục H).

## B. ⚠️ PHÁT HIỆN QUAN TRỌNG NHẤT — PRODUCTION EXPOSURE (minh bạch tuyệt đối)
Ảnh test mobile của PO (IMG_8464/8465) chụp tại **demenart.com — PRODUCTION — và đang hiển thị shell G.1 mới.**
- Em **không** gọi deploy: `deploy_project` chưa từng được invoke; "deployment: NO" đúng với Lovable hosting.
- Nguyên nhân: kiến trúc pipeline **Lovable → GitHub auto-sync → Cloudflare Pages tự build & deploy `demenart.com` theo mỗi commit trên main**. Bốn commit G.1 (`8b5e6252` → `9385345c` → `31ef2932`) đã tự động lên production qua CI — hệ quả kiến trúc, không phải hành động deploy chủ động.
- Trạng thái thực tế: production đang chạy shell G.1, và chính ảnh test của PO chứng minh nó hoạt động đúng trên thiết bị thật (đăng nhập, điều hướng, hero, drawer đều ổn).
- Bài học ghi nhận (đề xuất D-rule mới): với repo này, **mọi commit = production deploy**; các sprint sau phải coi send_message/paste-apply là hành vi có hệ quả production, hoặc PO cân nhắc tách nhánh preview trên Cloudflare Pages.

## C. KẾT QUẢ MANUAL TEST CỦA PO (1–4 ✓) + PHÂN TÍCH EVIDENCE
1. **Drawer** ✓ (Img 1, 19): anatomy chuẩn — 4 primaries, nhóm "Dành cho ba mẹ", Đăng xuất, đóng/mở đúng.
2. **Regression 8 routes** ✓: journal (Img 2, 11 — local selector giữ nguyên, detail mở tốt), discovery (Img 3 — copy evidence-anchored nguyên), family (Img 4 — archive nav V112C nguyên), kid (Img 5), consent (Img 6 — 9-consent UI nguyên), settings (Img 7), /portal/notifications (Img 9) + /portal/support (Img 10) mount trong portal shell riêng đúng thiết kế. Lưu ý: Img 8 "/parent/notifications → Not Found" là **hành vi đúng** — route đó không tồn tại (route thật `/portal/notifications`); PO gõ nhầm rồi tự vào đúng URL ở Img 9.
3. **Hero deep-link** ✓ (Img 14): `?focus=creation%3A8701bf27…` mở đúng kỷ vật hero trong Hành trình — id-scheme contract hoạt động end-to-end.
4. **Composer** ✓ (Img 15): mở từ Hôm nay, type-picker nguyên bản; quiet metadata "Đã lưu 41 điều · 21 do ba mẹ ghi lại" hiển thị đúng ngữ pháp counts-as-metadata.

## D. TEST 5 — CONSOLE & NETWORK (từ Img 16, 17)
- **Fonts qua network: CHỐT TUYỆT ĐỐI** — DevTools Network filter `gstatic`: **12 requests / type font / tất cả HTTP 200 / ~145KB** (Img 17). Kết hợp bundle mới `styles-D-TPCMi_.css` chứa `--dma-emerald` + `401px`: cả 3 yêu cầu proof của Owner đạt, không phụ thuộc font máy.
- **Console: 1 error + 12 warnings, phân loại:**
  - 12× `postMessage origin` từ `lovable.js` — script preview-only của Lovable (không tồn tại trên production bundle).
  - 1× **React hydration mismatch** — evidence trong chính stack (Img 16): attribute `__processed_2da062f0…="true"` được inject vào DOM trước khi React load + thông điệp React chỉ rõ "client has a browser extension installed which messes with the HTML". Máy PO chạy nhiều extension can thiệp DOM (Simple Telex gõ tiếng Việt, Gemini…). Phân loại: **environment (extension), không phải defect G.1**. Open Item: re-verify console trong cửa sổ Incognito (0 extension) — kỳ vọng 0 error.

## E. TEST 6 — MOBILE THIẾT BỊ THẬT (Img 18, 19 · production demenart.com)
- Trang render đẹp: serif Playfair đúng, diacritics chuẩn, hero + CTA "Xem ký ức này", drawer đầy đủ.
- **Hiện tượng cần PO nhìn nhận (không phải bug):** iPhone của PO hiển thị **tablet composition** (top bar + ☰ + drawer, Img 18/19) thay vì bottom nav. Nguyên nhân: viewport CSS của iPhone màn lớn (Pro Max ≈ 430px) **> 400** → rơi vào tablet range **401–1023 đúng theo grammar đã ĐÓNG BĂNG ở V113F** (mobile ≤400). Iframe harness đã chứng minh 390/400 → bottom nav chuẩn xác; máy 430px thấy drawer là **hệ quả trực tiếp của spec đông cứng**, không phải lỗi code. Nếu PO muốn điện thoại lớn (401–~500) dùng bottom nav, đó là **thay đổi frozen boundary** — thuộc quyết định design riêng (đề xuất xem xét ở G.8/F-amendment, không tự ý đổi trong G.1).

## F. TOÀN CẢNH EVIDENCE MATRIX (tổng hợp cả phiên)
| Hạng mục | Kết quả | Evidence |
|---|---|---|
| Lovable build | PASS (commit 31ef2932, agent-run) | send_message log |
| Bundle DMA layer + 401px | ✓ styles-D-TPCMi_.css | JS fetch proof |
| Fonts network | ✓ 12×200 woff2 ~145KB | Img 17 + fetch 4.720/23.204B |
| Breakpoints 8/8 (1440/1024/1023/768/500/401/400/390) | ✓ chính xác từng px | iframe harness (border-0 verified) |
| Hôm nay An (hero/switcher/sections/no-KPI) | ✓ | ss_0933pofsh, Img 13 |
| Correction A (race) | ✓ live: clear ngay + loading + không stale | JS probe 120ms |
| Khang near-empty + sole primary + quiet metadata | ✓ | ss_8129j95sg, Img 12 |
| Drawer a11y anatomy | ✓ | Img 1, 19 |
| Regression 8 routes | ✓ 8/8 mounts | Img 2–11 |
| Hero deep-link focus | ✓ | Img 14 |
| Composer flow | ✓ | Img 15 |
| Static QA amendment | PASS (12/12 prettier · 0E/0W eslint · 4.937/32 ≤ baseline · rule-sets identical · tsc 0) | lint_before/after.txt, build_pristine_verified.txt |
| Protected fingerprints/migrations/routes | ✓ không đổi (4/4 hash · 101 · 57/52) | sha256 + SQL |
| Consent/backend/Journey Share/Discovery contracts | ✓ untouched | scope + diff traces |
**KNOWN PRE-EXISTING LINT DEBT PRESERVED OR REDUCED; G.1 INTRODUCED ZERO NEW LINT DEBT.**

## G. CHANGE PROOF & ROLLBACK
13 files trong scope duyệt (3 sửa + 9 mới + `__root.tsx` theo scope expansion đã approve) · commit range **`8b5e6252` → `31ef2932`** (contiguous, chỉ G.1) · package/lockfile/routeTree/types/SQL/RPC/RLS/Edge/consent: **0 thay đổi** · production data mutation: **0** · Lovable deploy_project: **KHÔNG gọi**.
**Rollback:** revert 4 commit theo thứ tự ngược (31ef2932 → 58cb… batch1) khôi phục amber shell + `__root.tsx` cũ; Cloudflare Pages sẽ tự deploy bản revert (~vài phút). Không đụng backend/route/data.

## H. HAI QUYẾT ĐỊNH CHỜ OWNER (chỉ anh quyết — em dừng tại đây)
1. **Production exposure:** (A ★) **Chấp nhận trạng thái hiện tại** — shell G.1 đã live, toàn bộ test PASS kể cả trên thiết bị thật của anh; ghi nhận pipeline-rule mới. (B) **Revert ngay** 4 commit để production về amber trong khi chờ review thêm.
2. **Canonicalize:** sau khi anh chọn (1), em mới viết HANDOFF v113G.1 + append D-rules (pipeline rule, iframe-harness method, Lightning-CSS font rule, breakpoint-430 note) + SYSTEM_MAP bump. **Chưa làm** cho đến khi anh ra lệnh.

Không mở V113G.2.
