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
