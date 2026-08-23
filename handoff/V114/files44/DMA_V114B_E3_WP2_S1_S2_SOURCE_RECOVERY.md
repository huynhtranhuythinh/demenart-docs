# DMA_V114B_E3_WP2_S1_S2_SOURCE_RECOVERY.md

> **BẢN CHẤT TÀI LIỆU:** Đây là **RECOVERY ARTIFACT** được tạo ngày **2026-07-25** trong nhiệm vụ
> *"WP2-S1/S2 Source Artifact Recovery"*. Đây **KHÔNG** phải là closeout WP2-S1/S2 gốc — file closeout
> WP2-S1/S2 **chưa từng tồn tại dưới dạng file**. Toàn bộ nội dung candidate D314-cand → D322-cand
> được **recover nguyên văn từ lịch sử hội thoại** của topic Claude:
>
> **`A114B-E3 - implementation readiness audit`**
> URL: `https://claude.ai/chat/189d86c6-df38-48a8-9e57-bc9d1446ab17`
> (updated_at cuối: 2026-07-22 07:04 UTC ≈ 14:04 ICT)
>
> Cấu trúc mỗi mục: **[ORIGINAL RECOVERED TEXT]** = nguyên văn trích từ nguồn ·
> **[PROVENANCE NOTE — 2026-07-25]** = ghi chú bổ sung hôm nay · **[GAP]** = phần chưa giải quyết.
>
> **Giới hạn kỹ thuật cần khai báo:** văn bản được recover qua công cụ `conversation_search`
> (trích đoạn hội thoại). Nội dung chữ là nguyên văn theo trích đoạn công cụ trả về; markdown
> rendering (bold/blockquote) được giữ theo trích đoạn, nhưng byte-exactness ở mức whitespace
> không thể chứng nhận tuyệt đối qua kênh này.

---

## 0. TÓM TẮT PHÂN BỔ

| ID | Milestone | Response nguồn (trong topic 189d86c6) | Trạng thái |
|---|---|---|---|
| D314-cand | WP2-S1 | "§5. D314-cand — ĐĂNG KÝ ĐÚNG SỐ" (blocker-analysis response, giai đoạn thiết kế S1) | EXACT SOURCE RECOVERED |
| D315-cand | WP2-S1 | cùng response với D314 ("Ứng viên bổ sung, phát sinh trực tiếp từ blocker này") | EXACT SOURCE RECOVERED |
| D316-cand | WP2-S1 | cùng response với D314/D315 | EXACT SOURCE RECOVERED |
| D317-cand | WP2-S1 | "CORRECTION 2" response (sửa công thức md5 `array_to_string` separator) | EXACT SOURCE RECOVERED |
| D318-cand | WP2-S2 | "§16. REMAINING STOP CONDITIONS / SC-1b" response (phát hiện `plan_mode=true` tạo commit) | EXACT SOURCE RECOVERED |
| D319-cand | WP2-S2 | "§26. P2 BACKLOG" (báo cáo DB slice S2) — đăng ký dạng bullet "D319-candidate" | EXACT SOURCE RECOVERED |
| D320-cand | WP2-S2 | "WP-A CORRECTIVE BLOCKED" response ("Rule candidate — D320-cand") | EXACT SOURCE RECOVERED |
| D321-cand | WP2-S2 | "WP-A FINAL PASS — WP-B BLOCKED" response ("Rule candidates:" — đăng ký D320 lần 2 + D321 + D322) | EXACT SOURCE RECOVERED |
| D322-cand | WP2-S2 | cùng response với D321 | EXACT SOURCE RECOVERED |

---

## 1. D314-cand — WP2-S1

**[ORIGINAL RECOVERED TEXT — response "§5. D314-cand — ĐĂNG KÝ ĐÚNG SỐ":]**

> ## 5. D314-cand — ĐĂNG KÝ ĐÚNG SỐ
>
> Rút lại việc dùng nhầm **D313-cand** (số đó đã mang nghĩa *"Probe precondition must be verified, not assumed"* — và trớ trêu thay, đó chính xác là quy tắc em vừa vi phạm ở §0).
>
> > **D314-cand — New public objects are not private by default under live Supabase default ACL.**
> >
> > Live Supabase `pg_default_acl` grants broad privileges to API roles on newly created public tables and functions. Every migration creating a table or function must explicitly `REVOKE ALL` from `PUBLIC`, `anon`, `authenticated` and `service_role` before granting minimum required privileges, then verify table-level, function-level and column-level ACLs. Never assume a newly created public object is private.
>
> **Candidate-only. Không canonicalize `DMA_RULES.md` trong S1.**
>
> Bằng chứng live đỡ D314-cand (`pg_default_acl`, owner `postgres`, schema `public`):
> `objtype='r'` → `anon=arwdDxtm`, `authenticated=arwdDxtm`, `service_role=arwdDxtm`
> `objtype='f'` → `anon=X`, `authenticated=X`, `service_role=X`

**[PROVENANCE NOTE — 2026-07-25]:** Trong một response *trước đó cùng topic*, đúng nội dung
pg_default_acl này từng bị đăng ký nhầm số dưới tên "D313-cand" (bản tiếng Việt: *"`pg_default_acl`
của Supabase cấp `arwdDxtm` cho `anon`/`authenticated`/`service_role` trên mọi bảng mới trong
`public`…"*). Đăng ký nhầm số đó đã bị **rút lại tường minh** trong chính §5 trên. Bản đăng ký
đúng số D314-cand (tiếng Anh) là văn bản chính thức. S1 closeout §8 sau đó chỉ recap một dòng:
*"D314-cand (object public mới không private mặc định dưới `pg_default_acl` của Supabase)"* —
recap, không phải nguồn.

**[GAP]:** không.

---

## 2. D315-cand — WP2-S1

**[ORIGINAL RECOVERED TEXT — cùng response, ngay sau D314:]**

> **Ứng viên bổ sung, phát sinh trực tiếp từ blocker này:**
>
> > **D315-cand — Một tuyên bố ACL phải liệt kê MỌI principal, không chỉ principal đang được quan tâm.**
> > `information_schema.role_table_grants` lọc theo một grantee là bằng chứng về **một** role, không bao giờ là bằng chứng về "không role nào". Mọi khẳng định "không ai ghi được X" phải chạy trên toàn bộ tập `{PUBLIC, anon, authenticated, service_role, postgres, supabase_admin}` và phải kèm `relacl` nguyên văn.

**[PROVENANCE NOTE — 2026-07-25]:** D315-cand được **thi hành trực tiếp** trong Gate 1 của migration
S1 (comment trong SQL: `-- D315-cand: liet ke TAT CA principal, ghi lai, va CHI cuong che dieu kien can.`
kèm vòng lặp `has_table_privilege`/`has_column_privilege` trên 5 role) — bằng chứng phụ rằng đây là
đăng ký sống của WP2-S1, không phải paraphrase về sau.

**[GAP]:** không.

---

## 3. D316-cand — WP2-S1

**[ORIGINAL RECOVERED TEXT — cùng response, ngay sau D315:]**

> > **D316-cand — `updated_at` là nhân chứng BẤT ĐỐI XỨNG.**
> > `updated_at = created_at` chứng minh hàng chưa từng bị sửa. `updated_at = T` chỉ chứng minh **không có** lần ghi nào **sau** T; nó không nói gì về khoảng trước T, vì lần ghi cuối đã ghi đè dấu vết. Không được dùng `updated_at` để niêm phong một khoảng thời gian mở về phía quá khứ.

**[PROVENANCE NOTE — 2026-07-25]:** Sinh ra trong phân tích provenance backfill S1 (chứng minh
lead-tại-thời-điểm-tạo chỉ đạt 4/9 buổi; 5 buổi còn lại cần Owner attestation). S1 closeout §8 recap
một dòng: *"D316-cand (`updated_at` là nhân chứng bất đối xứng)"*.

**[GAP]:** không.

---

## 4. D317-cand — WP2-S1

**[ORIGINAL RECOVERED TEXT — response "CORRECTION 2" (công thức md5 separator `';'` → `E'\n'`):]**

> **Ứng viên rule mới:**
>
> > **D317-cand** — Một assertion pass không chứng minh assertion đó đúng. Khi biểu thức kiểm tra có tham số tuỳ chọn (dấu phân tách, thứ tự, collation, timezone), phải kiểm chứng biểu thức đó trên **dữ liệu phân biệt được**; một tập dữ liệu suy biến (mảng 1 phần tử, bảng 1 hàng) có thể làm hai công thức khác nhau cho cùng kết quả.

**[PROVENANCE NOTE — 2026-07-25]:** Ngữ cảnh sự cố nguồn (cùng response): công thức
`md5(array_to_string(statements, ';'))` và `E'\n'` cho cùng kết quả trên migration 1-statement, nên
sai sót không bị assertion phát hiện — "nó vẫn pass". Bốn vị trí bị sửa: Gate 0 (G-0.2) · Gate 1
(khối lineage đầu tiên) · Block 3 (V1) · P0. Danh sách thay đổi của pack đó ghi rõ mục
*"rule candidates | thêm D317-cand"*. S1 closeout §8 recap: *"D317-cand (assertion pass không
chứng minh assertion đúng khi tập dữ liệu suy biến)"*.

**[GAP]:** không.

---

## 5. D318-cand — WP2-S2

**[ORIGINAL RECOVERED TEXT — response "§16. REMAINING STOP CONDITIONS" (SC-1b, `plan_mode` finding):]**

> **Ứng viên rule mới:**
> > **D318-cand** — `Lovable:send_message(plan_mode=true)` **không** phải thao tác chỉ-đọc: nó tạo commit `"Update plan"` và một edit record mới. Không được dùng M1 ở nơi bất biến "zero repository mutation" là bắt buộc, trừ khi CTO chấp nhận trước loại commit này. Mọi stop condition dựa trên "commit SHA unchanged" phải nêu rõ có tha thứ commit plan-artifact hay không.

**[PROVENANCE NOTE — 2026-07-25]:** Sinh ra từ SC-1 FAIL (commit SHA đổi `388b50ae…` → `e7958c7d…`,
edit `edt-55e401b8-…` `"Update plan"`) trong giai đoạn chuẩn bị S2. Các pack S2 sau đó liệt kê
"D314·D315·D316·D317·D318-cand giữ candidate-only" — recap, không phải nguồn.

**[GAP]:** không.

---

## 6. D319-cand — WP2-S2

**[ORIGINAL RECOVERED TEXT — response báo cáo DB slice S2, "§26. P2 BACKLOG":]**

> - **D319-candidate** — fingerprint pinning trong tương lai nên dùng `regprocedure` thay vì `proname` khi có khả năng overload. *(Ghi chú: V17 hiện dùng `proname`; hôm nay không có overload nào trong tập 18 hàm, nhưng đó là may mắn chứ không phải bảo đảm.)*

**[PROVENANCE NOTE — 2026-07-25]:** Đăng ký gốc ở dạng bullet P2-backlog với nhãn "D319-candidate"
(không phải blockquote như D314–D318). S2 WP-C closeout §18 recap tiếng Anh một dòng:
*"D319-cand pin fingerprints by `regprocedure` where overloads may exist."* — recap, không phải nguồn.

**[GAP]:** không (dạng đăng ký gọn hơn các candidate khác là đặc điểm của nguồn gốc, không phải thiếu dữ liệu).

---

## 7. D320-cand — WP2-S2

**[ORIGINAL RECOVERED TEXT — lần đăng ký ĐẦU, response "WP-A CORRECTIVE BLOCKED":]**

> **Rule candidate — D320-cand:** the Lovable agent harness forbids stateful `git` commands (`checkout`, `reset`, `revert`). File restoration must go through the Lovable Revert UI, a `code--write` with byte-exact content, or generator re-emission. Never plan a corrective step around `git checkout`.

**[ORIGINAL RECOVERED TEXT — lần tái đăng ký gọn, response "WP-A FINAL PASS — WP-B BLOCKED":]**

> **D320-cand** — the Lovable agent harness forbids stateful `git`; restoration must use the Revert UI, `code--write`, or generator re-emission.

**[PROVENANCE NOTE — 2026-07-25]:** Bản đăng ký đầu (WP-A corrective) là nguồn đầy đủ nhất.
S2 WP-C closeout §18 recap: *"D320-cand Lovable harness forbids stateful `git` restoration."*

**[GAP]:** không.

---

## 8. D321-cand — WP2-S2

**[ORIGINAL RECOVERED TEXT — response "WP-A FINAL PASS — WP-B BLOCKED", khối "Rule candidates:":]**

> **D321-cand** — the TanStack route-tree generator non-deterministically drops the `@tanstack/react-start` `Register` augmentation on file-editing runs; any "exactly N files changed" gate must exclude `*.gen.ts` or it will fail on unrelated grounds.

**[PROVENANCE NOTE — 2026-07-25]:** Sự cố nguồn: dao động lần 3 của `routeTree.gen.ts`
(deleted → restored → deleted; md5 `f88f0bb3…` vs `c849de82…`), WP-B commit `fa52656b…` chứa file
thứ 5 ngoài 4 file được duyệt. S2 WP-C closeout §18 recap bổ sung mệnh đề quan sát cuối:
*"…oscillates on file-editing runs but converges; never affects the route table"* — mệnh đề
"but converges; never affects the route table" là **bổ sung tại closeout** (sau khi file tự về
zero diff ở WP-C), không có trong đăng ký gốc.

**[GAP]:** không.

---

## 9. D322-cand — WP2-S2

**[ORIGINAL RECOVERED TEXT — cùng response với D321:]**

> **D322-cand** — never accept an agent's own stability claim without comparing its measurements to an independently recorded prior baseline; a hash pair that matches each other can still both differ from the true reference.

**[PROVENANCE NOTE — 2026-07-25]:** Sự cố nguồn: agent tuyên bố `routeTree.gen.ts` "already modified
before WP-B" — tuyên bố sai, bị bác bằng baseline độc lập Stage 1 (`git status` rỗng, md5 `f88f0bb3…`).
S2 WP-C closeout §18 recap: *"D322-cand compare hash measurements against an independently pinned
baseline, not only against each other."*

**[GAP]:** không.

---

## 10. MENTION-ONLY EXCLUSIONS (KHÔNG PHẢI SOURCE)

Các tài liệu sau chỉ nhắc ID / dải candidate và bị **loại khỏi vai trò original source**:

1. `DMA_V114B_E3_WP3_CLOSEOUT.md` — dòng 262 nhắc "`pg_default_acl` (D314-cand)"; dòng 274 nhắc dải "D310-cand…D322-cand".
2. `DMA_RULES.md` (D324/D325 lineage notes) · `DMA_SYSTEM_MAP.md` (endpoint block) · `DMA_BUILD_PATH.md` (E3 execution state) — chỉ nhắc dải "D310–D323-cand".
3. WP4-S3A / WP4-S4 closeout — chỉ nhắc dải.
4. Topic "A114B-E3 · D1 — Candidate & Residual Formal Disposition" (25/07) và "V114B-E3 - Final Milestone Closeout & Residual Security Disposition" (25/07) — cả hai đều tuyên bố D313–D322 NOT FOUND / KEEP HELD tại thời điểm đó; là bằng chứng gap, không phải source.
5. Recap một dòng trong S1 closeout §8 và S2 WP-C closeout §18 (cùng topic 189d86c6) — recap của chính các đăng ký gốc, đã được dùng làm chứng cứ đối chiếu, không thay thế nguồn.
6. Đăng ký nhầm số "D313-cand (pg_default_acl)" trong topic 189d86c6 — **retracted**, superseded bởi D314-cand §5.

*Ghi chú ngoài phạm vi 9 ID:* **D313-cand** (probe-precondition) có source riêng trong topic
"A114B-E3 - Project knowledge baseline verification and artifact gaps"
(`https://claude.ai/chat/6c688d80-03d5-4c55-a8d6-15252ad90553`, S0B closeout §11 "NEW D-RULE") —
đã nằm trong `DMA V114B E3 WP2 S0B CLOSEOUT FINAL.md` theo xác nhận của Owner, không thuộc nhiệm vụ này.

---

*Recovery artifact · tạo 2026-07-25 · read-only source recovery · không canonicalize · không sửa repo/DB.*
