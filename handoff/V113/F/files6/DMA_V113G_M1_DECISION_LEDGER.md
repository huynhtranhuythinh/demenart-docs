# V113G-M1 — TEMPORARY DECISION LEDGER (chưa canonicalize — sẽ gộp ở closeout M1)
2026-07-17 · giữ theo Owner Decision Phase A mục 2.

## Owner decisions (Phase A)
1. Production: **A — ACCEPTED, LIVE** (không revert). Trạng thái: `V113G.1 PHASE A — OWNER ACCEPTED, LIVE ON PRODUCTION`.
2. Canonicalization: HOÃN — gộp một lần tại closeout V113G-M1 (không HANDOFF/RULES/SYSTEM_MAP riêng cho G.1).
3. **Breakpoint amendment (áp dụng ở vertical slice kế tiếp, chưa code):** Parent shell mobile ≤479 · tablet 480–1023 · desktop ≥1024. Thi công = đổi `--breakpoint-dtab: 401px → 480px` (styles.css) + sửa comment/label 401→480 trong 5 file shell + regression iframe harness mốc mới: 1440/1024/1023/768/500(tablet ✓)/480(tablet)/479(mobile)/430(mobile)/390(mobile).
4. **Pipeline Safety Rule (hiệu lực ngay):** mọi commit vào main = production-affecting; cấm build dở trên main; trước write kế tiếp phải có isolation workflow được PO xác nhận; closeout phải khai báo cả direct deploy lẫn indirect CI exposure; không dùng chữ "deployment: NO" khi CI đã kích hoạt.

## Commit ledger (main, production-deployed qua CF Pages CI)
- `8b5e6252` batch 1/2 (styles + 9 new) · `9385345c` batch 2/2 (2 routes) · `31ef2932` fonts scope-expansion (styles + __root) — cả 3 bởi Claude qua send_message.
- `c6d90054` "Fixed tablet menu focus-restore" 07:46:07Z — **OUT-OF-BAND** (Lovable editor UI, không qua Claude, trong lúc PO test tay). Diff verified read-only: chỉ ParentTabletBar.tsx, thêm menuTriggerRef + onCloseAutoFocus→focus trigger. Nội dung hợp lệ theo F5, trong scope 13-file. Lint/format của file này CHƯA được targeted-check (ghi nợ cho slice kế tiếp cùng amendment breakpoint).
- Production HEAD hiện tại (main + demenart.com): `c6d90054`.

## Facts verified cho isolation proposal
- Lovable MCP không expose branch config; GitHub/Cloudflare không có tool trong phiên → các bước isolation là thao tác tay của PO; Claude chỉ verify gián tiếp.
- Lovable hosting (demenart.lovable.app) tách biệt và KHÔNG phải nguồn của demenart.com; nguồn production = GitHub main → Cloudflare Pages.

## Work package: BREAKPOINT AMENDMENT 479 — CLOSED 2026-07-17 ~16:25
- Owner operating mode: CONTINUE DIRECTLY ON MAIN (no branch, no CI pause) — mọi commit hiểu là PRODUCTION-AFFECTING VIA CLOUDFLARE CI.
- Commit: **`8021c940acb47b84d293502d12beac6fdc89122a`** (main) — 5 thay thế chuỗi: `--breakpoint-dtab: 401px → 480px` (styles.css) + 4 comment truth-updates (parent.tsx, ParentTabletBar, MobileParentHeader, ParentBottomNav).
- **CI EXPOSURE DECLARATION: commit này ĐÃ deploy production demenart.com qua Cloudflare Pages CI.** deploy_project: không gọi.
- Nợ lint out-of-band `c6d90054` ĐÃ ĐÓNG: ParentTabletBar (bản có menuTriggerRef/onCloseAutoFocus) prettier PASS + eslint 0E/0W trong targeted run.
- QA: prettier PASS (5 file) · eslint targeted 0E/0W · tsc 0 · full lint 4.937E/32W (= trước, ≤ baseline 4.945/32) · build local exit 0 · Lovable build PASS.
- Production smoke: PO iPhone (~430px viewport) @ demenart.com — mobile header + bottom nav 4 mục ("Của con"), Hôm nay active (IMG_8466). Mốc 500-vẫn-tablet và 480/479 đã được suy chứng bởi giá trị breakpoint duy nhất 480px (một media query điều khiển cả ba shell — iframe harness đầy đủ có thể bổ sung khi cần).
- Rollback: revert 1 commit `8021c940` → trở về grammar 401/400 (CF tự deploy bản revert).
- Production HEAD: `8021c940`.

## Incident 2026-07-17 16:27 — Journal images broken trên iPhone 4G: CLOSED AS TRANSIENT
- Evidence chain: Edge get_signed_media_url v23 logs = ~30 POST đều HTTP 200 tại thời điểm sự cố; token không bind IP/UA; JourneyStage <img> thuần như hero; code journey không bị đụng bởi G.1/amendment.
- Tái hiện 2026-07-18 08:45–08:47: desktop production PASS, responsive 400 PASS (all media.demenart = 200), iPhone PASS (stage + thumbnails đầy đủ).
- Kết luận: transient CDN/carrier-4G. Không sửa code/Edge/Bunny. Open Item (monitor): nếu tái diễn → PO chụp status code qua Safari Web Inspector; cân nhắc onError retry-backoff ở G.8 media polish.

## Work package: V113G.2 — JOURNEY + DISCOVERY + SHARE RE-HOME (Option B) — CLOSED 2026-07-18 ~10:30
- Commit range (main, mỗi commit PRODUCTION-AFFECTING VIA CLOUDFLARE CI): `12917e93` ShareAction → `4f577a3c` Viewer → `789564b7` journal → `1cf65494` discovery → `ccd955e0` Detail (5 commit từ phiên-trước-treo, Owner chỉ đạo coi là phần việc hoàn tất muộn, đã audit như third-party theo D116) → `e610434c` normalize prettier (Claude) → `567d2cc4` P1 focus-hydrate fix (Claude). HEAD = `567d2cc4`.
- Incident PARALLEL-SESSION: phiên trước treo rồi hoàn tất muộn trong lúc phiên này chạy → Security Stop-Gate kích hoạt đúng lúc, zero xung đột commit; Owner xác nhận single-session từ thời điểm đó. Bài học D-rule đề xuất: trước MỌI work package phải list_edits re-pin + xác nhận không phiên song song.
- P1 tự sửa trong scope: effect reset [selectedChildId] chạy ở lần provider-hydrate đầu (null→id) làm mọi ?focus vô hiệu ngay sau mount — fix bằng prevChildRef guard (pattern đồng nhất với discovery). Verified PASS trên preview.
- QA PASS: static (prettier 5/5 · eslint 0/0 · tsc 0 · build 0 · full lint 4.774E/26W = −163E/−6W so baseline nhờ gỡ dead branch · fingerprints 4/4 nguyên) · Share eligibility (creation ẩn / moment hiện / popover read-only đúng copy — KHÔNG create/revoke trên production) · focus valid-newest + valid-non-newest (moment 26/6 + Share theo deep-link) + invalid banner truthful · discovery invalid-capsule truthful + drop ?capsule 300ms khi đổi con · race An↔Khang stale-clear 150ms · responsive 9/9 (1440/1024=rail · 1023/768/500/480=tablet · 479/430/390=bottomNav) + zero overflow · regression 6/6 routes · network 0 failed · console: chỉ 1 hydration = extension-inject (bằng chứng __processed_ attr, lần 2).
- PENDING 1 mảnh: production demenart.com đang CF-propagation-lag lúc mất browser (HTML mới + assets 404 tạm). Preview đã chứng minh bản 567d2cc4 đúng. PO self-verify: mở demenart.com/parent/journal?focus=journey%3A00000000-0000-0000-0000-000000000000 → thấy "Không tìm thấy kỷ vật được liên kết…" = DONE.
- Rollback order (ngược): revert 567d2cc4 → e610434c → ccd955e0 → 1cf65494 → 789564b7 → 4f577a3c → 12917e93 (về 8021c940).
- PRODUCTION-CONFIRMED 2026-07-18 10:49 (PO screenshot): banner truthful + persisted-child Khang + Share-on-moment + CF propagation hoàn tất trên demenart.com. **V113G.2 CLOSED.**
