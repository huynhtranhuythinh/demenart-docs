# DMA — V114B-E3 · WP3 CLOSEOUT

> **WP3 — FORMALLY PASS / CLOSED** · 2026-07-22
> **E3-SG-02 — CONTAINED FOR AUTHENTICATED/ANON USER-JWT PATH** (KHÔNG phải CLOSED)
> **E3-SG-01 — vẫn OPEN, không đụng**
> `DMA_RULES.md` và `DMA_SYSTEM_MAP.md` **KHÔNG canonicalize ở mốc này** — chờ E3 milestone closeout (theo đúng tiền lệ WP1). Khối append đã soạn sẵn ở §13.
> **R21 — ACTIVE OBSERVATION**, chưa hoàn tất.

---

## 1. PHẠM VI ĐÃ ĐÓNG

WP3 = **Session Write-Path Containment**. Mục tiêu duy nhất: gỡ quyền ghi trực tiếp bảng `public.lesson_sessions` khỏi `authenticated` và `anon`, để mọi mutation buổi học **chỉ** đi qua 5 RPC có kiểm soát.

| Gói | Nội dung | Trạng thái |
|---|---|---|
| **WP3-A1** | Exhaustive writer audit (DB layer) | **CONDITIONAL PASS** — DB complete; repo/Edge coverage tool-limited |
| **WP3-A1b** | Coverage completion | **INCOMPLETE** (H-1/H-2/H-3) — Owner chấp nhận là tool-coverage limitation |
| **WP3-A2 / A2.1 / A2.2** | Revoke design → correction → final execution contract | **APPROVED** |
| **WP3-A3** | Apply (lần 1) | **BLOCKED trước apply** — phát hiện defect P04, apply chưa tiêu |
| **WP3-A3R** | Inline erratum + apply + verify | **PASS** — Checkpoint A 17/17 · Checkpoint B 26/26 |
| **WP3-CLOSE** | Verdict + documentation | **file này** |

**Vấn đề gốc (E3-SG-02):** `authenticated` giữ INSERT/UPDATE/DELETE/**TRUNCATE** cấp bảng trên `lesson_sessions`, và RLS policy còn *cho phép* `is_distribution_lead(...)`. Hệ quả: một giáo viên là distribution lead có thể `PATCH /rest/v1/lesson_sessions` sửa thẳng `state`, `scheduled_at` và **`taught_by`** — vượt mặt toàn bộ state guard và audit. Điều này **mâu thuẫn trực tiếp** với bất biến đã khoá: *"`lesson_sessions.taught_by` là bằng chứng runtime bất biến"*.

`TRUNCATE` **không chịu RLS**. Trước WP3, thứ duy nhất chặn `TRUNCATE ... CASCADE` là 2/9 bảng tham chiếu (`session_teacher_assignments`, `session_teachers`) tình cờ đã bị thu quyền TRUNCATE từ S1/WP1 — **một rào chắn ngẫu nhiên, không phải thiết kế**.

---

## 2. MIGRATION

| | |
|---|---|
| **Version** | `20260722112305` |
| **Name** | `v114b_e3_wp3_a2_lesson_sessions_write_revoke` |
| **Digest** | `15747cd0b1e48247c3fc411a4c9a78de` |
| **Công thức digest** | `md5(array_to_string(statements, E'\n'))` — **KHÔNG** dùng `';'` |
| **Migration inventory** | **110 → 111** |
| **Kết quả** | `{"success": true}` · gọi đúng **một lần** · không retry |
| **Notices** | `BLOCK 1 — all preconditions PASS (P01..P18)` · `BLOCK 3 — all postconditions PASS (V01..V26, V13 column loop, V18 writer loop)` |
| **Rollback cần thiết?** | **KHÔNG** |

### Thay đổi quyền duy nhất

```sql
revoke insert, update, delete, truncate
  on table public.lesson_sessions
  from authenticated, anon;
```

**Không** `REVOKE ALL`. **Không** đụng `SELECT`. **Không** sửa/xoá policy. **Không** đụng `service_role`, `postgres`, default privileges, column grants, function, trigger, row. **Không** `COMMENT ON TABLE`.

### Hình dạng migration (D92 ba khối, Layer A)

- `set local timezone = 'UTC';` (transaction-scoped, hợp lệ vì `apply_migration` bọc transaction)
- **BLOCK 1** — 18 precondition P01…P18
- **BLOCK 2** — đúng một lệnh REVOKE
- **BLOCK 3** — postcondition V01…V19, V21…V26 + vòng lặp 16 cột (V13) + vòng lặp 5 writer (V18)
- **KHÔNG** assert migration count trong body (xem §12 · D-A2-1)

---

## 3. PRIVILEGE POSTURE — TRƯỚC / SAU

| Role | SELECT | INSERT | UPDATE | DELETE | TRUNCATE |
|---|:--:|:--:|:--:|:--:|:--:|
| `authenticated` — trước | ✅ | ✅ | ✅ | ✅ | ✅ |
| `authenticated` — **sau** | ✅ | ❌ | ❌ | ❌ | ❌ |
| `anon` — trước | ✅ | ✅ | ✅ | ✅ | ✅ |
| `anon` — **sau** | ✅ | ❌ | ❌ | ❌ | ❌ |
| `service_role` — trước/sau | ✅ | ✅ | ✅ | ✅ | ✅ (BYPASSRLS giữ nguyên) |
| `postgres` (owner) — trước/sau | ✅ | ✅ | ✅ | ✅ | ✅ |
| `PUBLIC` (`grantee = 0`) | — không có ACL entry, trước và sau — | | | | |

**`relacl` trước:** `{postgres=arwdDxtm/postgres, anon=arwdDxtm/postgres, authenticated=arwdDxtm/postgres, service_role=arwdDxtm/postgres}`
**`relacl` sau:** `{postgres=arwdDxtm/postgres, anon=rxtm/postgres, authenticated=rxtm/postgres, service_role=arwdDxtm/postgres}`

**Residual có chủ ý:** `r` (SELECT) · `x` (REFERENCES) · `t` (TRIGGER) · `m` (MAINTAIN) còn lại trên 2 role API. Trong đó **`t` (TRIGGER)** là quyền duy nhất mang tính write-adjacent — nằm ngoài scope WP3, cần quyết định riêng (§11).

**3 policy giữ nguyên** (`lesson_sessions_select_school` · `_insert_lead_or_schooladmin` · `_update_lead_or_schooladmin`). Sau revoke, 2 policy ghi trở thành **defence-in-depth không còn với tới được** — giữ lại vì chúng ghi lại ý định thiết kế và khôi phục hành vi đúng ngay nếu rollback.

---

## 4. CHECKPOINT A — POST-APPLY STRUCTURAL VERIFY

Layer B `B01–B17`, chạy nguyên văn ngay sau apply. **17/17 PASS.**

| B row | Kết quả |
|---|---|
| B01 migration_count = 111 · B02 migration tồn tại · B03 là mới nhất · B04 không migration lạ | PASS ×4 |
| B05 ACL target state (`aclexplode` normalized, không dựa thứ tự aclitem) | PASS |
| B06 authenticated write = false · B07 anon write = false · B08 authenticated SELECT = true | PASS ×3 |
| B09 service_role nguyên · B10 postgres nguyên · B11 PUBLIC vắng (`grantee = 0`) | PASS ×3 |
| B12 column grant vắng (`attacl` null ×16 + `has_column_privilege` false ×16×2 — D310-cand) | PASS |
| B13 5 writer nguyên · B14 inventory 88/207/198/166/33 · B15 policy+trigger fingerprint nguyên | PASS ×3 |
| B16 rows + 5 canonical hash nguyên · B17 owner + RLS flag nguyên | PASS ×2 |

---

## 5. CHECKPOINT B — TRANSACTIONAL PERSONA PROBES

**26/26 PASS.** Mọi probe chạy trong subtransaction và **đã rollback**; mọi mutation bị huỷ.

### 5.1 Từ chối ghi trực tiếp (14 probe)

| Probe | Persona | Thao tác | Quan sát |
|---|---|---|---|
| X1–X5 | GV lead (Đặng Mỹ Linh) | INSERT · UPDATE `state` · UPDATE `scheduled_at` · **UPDATE `taught_by`** · DELETE | `42501 permission denied for table lesson_sessions` ×5 |
| X6 | GV thường (Lê Thảo My, assistant, không lead) | UPDATE `taught_by` | `42501` |
| X7–X8 | `master_admin` (Nguyệt Thi) | INSERT · UPDATE `state` | `42501` ×2 |
| X9 | PH (Nguyễn Văn Hùng) | UPDATE `taught_by` | `42501` |
| X10 | GV lead khác trường (Bùi Ngọc Hân, MNDM) | UPDATE `state` | `42501` |
| X11 / X11b / X11c | `anon` | INSERT · UPDATE `taught_by` · DELETE | `42501` ×3 |
| **X14** | GV lead | **TRUNCATE CASCADE** (chạy **cuối cùng**, có guard bắt success) | `42501` |

### 5.2 RPC vẫn sống + từ chối chuẩn (10 probe)

| Probe | Persona | RPC | Kỳ vọng | Quan sát |
|---|---|---|---|---|
| X1r | master_admin | `create_lesson_session` | `ok:true` | `{"ok":true,"session_id":"486b34b9…"}` |
| X2r | master_admin | `update_lesson_session` (scheduled) | `ok:true` | `{"ok":true,…}` |
| X3r | master_admin | `cancel_lesson_session` | `ok:true` | `{"ok":true,"state":"cancelled"}` |
| X4r | master_admin | `update_lesson_session` (taught_report_pending) | `bad_state` | `{"ok":false,"reason":"bad_state"}` |
| X5r | GV lead | **`start_session`** (ghi `taught_by`) | `ok:true` | `{"ok":true,"state":"in_progress"}` |
| X6r | GV lead | `submit_session_journal` | `ok:true` | `{"ok":true,"already":true}` |
| X7r | GV thường | `start_session` | `forbidden` | `{"ok":false,"reason":"forbidden"}` |
| X8r | PH | `create_lesson_session` | `not_authorized_for_school` | khớp |
| X9r | GV lead khác trường | `cancel_lesson_session` | `not_authorized_for_school` | khớp |
| X10r | master_admin MNDM | `update_lesson_session` (cross-school) | `not_authorized_for_school` | khớp |

### 5.3 Control đặc quyền (2 probe — phải THÀNH CÔNG)

| Probe | Role | Thao tác | Quan sát |
|---|---|---|---|
| X12 | `service_role` | direct UPDATE `state` | **thành công** (đã rollback) |
| X13 | `postgres` | direct UPDATE `taught_by` | **thành công** (đã rollback) |

> 24 lần từ chối chứng minh revoke có hiệu lực trên **mọi** persona và **mọi** động từ ghi; 2 control thành công chứng minh revoke **không** lan quá phạm vi.

**Layer B chạy lại sau toàn bộ probe: 17/17 PASS** — zero residue.

### 5.4 QA DEBT MỞ

**`sub_admin` — NOT EXECUTABLE WITH CURRENT DATASET.** Dữ liệu sống không có profile `sub_admin` nào. Đã thay bằng `assistant_teacher` (GV thường) + `master_admin` (nhánh school-admin). Vì revoke ở **mức role `authenticated`**, `sub_admin` bị từ chối bởi đúng cơ chế đó — nhưng **chưa được probe thực nghiệm**. Giữ làm QA debt cho lần có fixture.

---

## 6. ZERO-DELTA EVIDENCE

**Business-row delta = ±0.** Thay đổi catalog duy nhất: `pg_class.relacl` của `public.lesson_sessions` + 1 dòng `supabase_migrations.schema_migrations`.

| Fingerprint | Giá trị (trước = sau) |
|---|---|
| `LS-CANON-1` | `fa919ddfc6f8dfa4e2efddb8e30729f3` |
| `LS-TAUGHT_BY-1` | `753db6cb679845200351349de0f3e91c` |
| `LS-STATE-1` | `d6d19f96663b0c5bffcf6c238288251c` |
| `LS-SCHEDULED_AT-1` | `5205f8e6d6c8f3e6b8f2e45cbdeaf0f7` |
| `STA-CANON-1` | `59e173e793d15c8cd848f1664f99df32` |
| Policy fingerprint | `a1ea35931e4fd686ba118a0ac8c5a4a4` |
| Trigger fingerprint | `ba1efd080022f9a817fa62bd084a8262` |
| Rows | `lesson_sessions` 9 · `session_teacher_assignments` 9 |
| Inventory | tables **88** · functions **207** · SECDEF **198** · policies **166** · triggers **33** |
| Repository HEAD | `d8178a55895b64bbffdf79bb05c06e6b4313d68b` — **0 file frontend bị đụng** |

### 6.1 CÔNG THỨC HASH CHÍNH TẮC (bắt buộc dùng nguyên văn từ WP3 trở đi)

> **LS-CANON-1** = `md5(string_agg(concat_ws('|', <16 cột theo thứ tự attnum>), E'\n' order by id))`, trong đó timestamptz serialize bằng `to_char(<col> at time zone 'UTC','YYYY-MM-DD HH24:MI:SS.US')`, null marker `'<N>'`.
> **STA-CANON-1** = như trên với 11 cột của `session_teacher_assignments`.
> **LS-TAUGHT_BY-1 / LS-STATE-1 / LS-SCHEDULED_AT-1** = `md5(string_agg(<biểu thức cột>, E'\n' order by id))`.

**Bất khả so sánh chéo:** các giá trị này **KHÔNG** so được với `ls_hash 392e8975…` (S2, công thức không ghi lại) hay `d41e3d08…` (bản nháp WP3-A2, công thức row-cast `t::text`). Mọi fingerprint phải khai báo công thức kèm giá trị — cùng họ bài học với `md5(prosrc)` vs `md5(pg_get_functiondef())` và `E'\n'` vs `';'`.

---

## 7. ROLLBACK CONTRACT (vẫn sẵn sàng)

```sql
grant insert, update, delete, truncate
  on table public.lesson_sessions
  to authenticated, anon;
```

- Chạy với vai `postgres` để grantor khớp `/postgres` → `relacl` trở lại **byte-identical**.
- **KHÔNG** dùng `GRANT ALL` (sẽ cấp thêm SELECT/REFERENCES/TRIGGER/MAINTAIN như grant mới, sai hình dạng).
- Verify (read-only, có guard `grantee = 0`): 16 ACL entry cho `authenticated`+`anon`, cả 4 quyền = true, PUBLIC vắng, `LS-STATE-1` = `d6d19f96663b0c5bffcf6c238288251c`.
- Thời gian: vài giây · không deploy · không coupling code · không migrate dữ liệu.
- **Rollback = mở lại E3-SG-02.** Phải đặt lại trạng thái OPEN trong cùng hành động.
- **Bắt buộc rollback khi:** một RPC hợp lệ fail vì privilege · phát hiện đường production phụ thuộc direct DML của `authenticated`/`anon` · bất kỳ Layer B row FAIL · hash/row-count đổi bất ngờ · `service_role`/`postgres` drift · **bất kỳ `42501` không giải thích được ở R21**.

---

## 8. TRẠNG THÁI E3-SG

### E3-SG-02 — **CONTAINED FOR AUTHENTICATED/ANON USER-JWT PATH**

Cơ sở bằng chứng: (1) grant ghi cấp bảng đã gỡ; (2) normalized ACL target state đã verify; (3) INSERT/UPDATE/DELETE/TRUNCATE trực tiếp bị từ chối; (4) mutation `taught_by` trực tiếp bị từ chối; (5) `start_session` còn là writer duy nhất của `taught_by`; (6) RPC hợp lệ vẫn chạy; (7) persona không hợp lệ giữ nguyên mã từ chối chuẩn; (8) posture `service_role`/`postgres` bảo toàn; (9) zero data delta; (10) rollback sẵn sàng.

**KHÔNG gọi là CLOSED vì:**
- `service_role` giữ `BYPASSRLS = true`;
- đường vận hành đặc quyền còn nguyên và **chưa kiểm kê xong** (call graph `supabaseAdmin` chưa giải, 9/16 Edge Function chưa đọc);
- `pg_default_acl` vẫn cấp `arwdDxtm` cho mọi bảng public mới → chưa xử lý;
- phơi nhiễm TRUNCATE toàn nền tảng (62/88 bảng cho `authenticated`, 55/88 cho `anon`) là mục riêng;
- static repository coverage bị giới hạn công cụ (H-1/H-2/H-3);
- **R21 vẫn là cổng quan sát đang mở.**

### E3-SG-01 — **OPEN**

Không đụng. `is_session_lead` vẫn giải quyết qua `class_distributions.lead_teacher_id` **hiện tại** (hồi tố). Điều kiện 4 ("không approve khi không có đúng session responsibility") vẫn chờ **WP4**, nơi ngữ nghĩa `dimension='responsible'` sẽ hội tụ authority với planned truth.

---

## 9. R21 — ACTIVE OBSERVATION (CHƯA HOÀN TẤT)

| Mốc | Thời điểm |
|---|---|
| **Apply** | **2026-07-22 11:23:05 UTC** / **18:23:05 ICT** |
| +24h | 2026-07-23 18:23 ICT |
| +48h | 2026-07-24 18:23 ICT |
| +72h | 2026-07-25 18:23 ICT |
| Mutation buổi học hữu cơ đầu tiên | **AWAITING** |

**Quy tắc quan sát.** Nếu xuất hiện `42501` không giải thích được trên đường ghi `lesson_sessions` thật: ghi lại actor · trường · route · HTTP method · hình dạng payload · timestamp · dòng API log → **rollback 4 quyền** → verify rollback → đặt **E3-SG-02 = OPEN** → định danh chính xác consumer ghi trực tiếp đang ẩn.

> **Giới hạn phát hiện, ghi rõ.** Browser smoke không-mutation **không thể** phát hiện một writer trực tiếp ẩn trong frontend, vì đường đó chỉ chạy khi có người thật sửa buổi học. **Cổng thật là mutation buổi học hữu cơ đầu tiên sau apply** — phải theo dõi có ý thức, không mặc định. Trên pilot 2 trường, lưu lượng mutation trong 72h có thể bằng 0; khi đó residual là **được giám sát**, chưa phải **đã loại trừ**.

---

## 10. OPTIONAL POST-RELEASE UX SMOKE — NON-BLOCKING

**Không chặn WP3 closeout. Không chờ screenshot.** Mật khẩu tất cả tài khoản: `Test@123`. Chỉ xem, **không** tạo/sửa/huỷ/bắt đầu/gửi nhật ký, **không** mở tab tự-lưu điểm danh/ghi nhận.

| # | Login | Route | Kỳ vọng |
|---|---|---|---|
| 1 | `hieutruong.kidshouse@demo.demenart.com` | `/school` | Dashboard + KPI render |
| 2 | ″ | `/school/schedule` | Lưới tuần render |
| 3 | ″ | `/school/schedule` | Nhãn **"Giáo viên dự kiến"** hiện (Surface A) |
| 4 | ″ | `/school/schedule` → mở panel chi tiết buổi (chỉ xem) | Dòng giáo viên dự kiến **đọc-chỉ** (Surface B) |
| 5 | `gv.linh.kidshouse@demo.demenart.com` | `/teacher` | Home render |
| 6 | ″ | `/teacher/classes` | Lớp + buổi render |
| 7 | `ph.hung.kidshouse@demo.demenart.com` | `/parent/journal` | Hành trình con render |
| 8 | ″ | `/parent/family` (hoặc `/family`) | Bề mặt FMN render |

---

## 11. RESIDUAL RISK & VIỆC HOÃN

### Rủi ro phát hành đã chấp nhận

| Chiều | Đánh giá |
|---|---|
| Khả năng tồn tại writer trực tiếp user-JWT chưa phát hiện | **THẤP** — mọi file đã đọc đều định tuyến qua RPC; 7/16 Edge Function xác nhận 0 truy cập `lesson_sessions`, mọi ghi dưới `service_role` |
| Tác động nếu tồn tại | **TRUNG BÌNH** — một luồng gãy với `42501` lộ rõ; không mất dữ liệu, không ghi sai |
| Khả năng phát hiện **tại thời điểm apply** | **THẤP–TRUNG BÌNH** — smoke không-mutation không chạm đường ghi |
| Khả năng phát hiện **trong cửa sổ quan sát** | **TRUNG BÌNH** — phụ thuộc có mutation hữu cơ thật trong R21 |
| Sẵn sàng rollback | **CAO** — một câu `GRANT`, vài giây |
| **Tổng thể** | **THẤP–TRUNG BÌNH, chấp nhận được — với điều kiện R21 được thực thi.** Không phải zero. |

### Hoãn / tách riêng (không gộp vào WP3)

- **P2-HARDEN-01** — `is_school_admin()` là INVOKER, chưa ghim `search_path` (đã xác nhận sống). Là gate duy nhất của RPC S2 và nằm trong predicate 2 policy ghi của `lesson_sessions`.
- **Phơi nhiễm TRUNCATE toàn nền tảng** — `authenticated` giữ TRUNCATE trên **62/88** bảng public, `anon` **55/88**. TRUNCATE **không chịu RLS**. Đây là phát hiện mới của WP3-A1, **chưa đăng ký** làm stop-gate.
- **`pg_default_acl`** (D314-cand) — mọi bảng public mới tự động nhận `arwdDxtm` cho cả 4 role API.
- **`service_role` BYPASSRLS** (D312-cand).
- **Residual `REFERENCES` / `TRIGGER` / `MAINTAIN`** trên `authenticated`/`anon`. `TRIGGER` là quyền write-adjacent duy nhất còn lại.
- **`search_path=public`** (thay vì `""`) trên `start_session` và `submit_session_journal` — đã ghim để không drift âm thầm, chưa harden.
- **WP3-A1b coverage** — H-1 (≈191/205 file repo chưa đọc; MCP không có repo-wide search), H-2 (importer/call-site của `supabaseAdmin` chưa giải), H-3 (9/16 Edge Function chưa đọc).
- **Surface C · Surface D · FUTURE-ADMIN-FORENSIC-01 · planned-teacher reassignment writer** — vẫn deferred.
- **`sub_admin` probe** — QA debt (§5.4).

---

## 12. BÀI HỌC MỐC — CANDIDATE RULE

RULES sống hiện có endpoint canonical **D309** và **không chứa mục `-cand` nào**; theo tiền lệ WP1, candidate rule sống trong closeout document cho tới E3 milestone closeout. Số kế tiếp còn trống sau D310-cand…D322-cand là **D323-cand**.

> ### 🆕 **D323-cand** — [migration · PL/pgSQL LAZY SQL + ALIAS SHADOWING]
> **Biểu thức SQL trong `DO` block của PL/pgSQL được parse LƯỜI — chỉ khi câu lệnh đó thực sự chạy lần đầu. Một `DO` block "review sạch" vẫn có thể nổ ở runtime.** Trước khi apply bất kỳ migration nào chứa `DO` block, phải **chạy thử toàn bộ khối assertion read-only trên pre-state sống** (hoặc ép mọi biểu thức lười thực thi bằng cách khác). **CẤM đặt alias SQL trùng tên biến đã `DECLARE`** — PL/pgSQL thay thế định danh trước khi parser SQL nhìn thấy, nên `r.g` với `r` là biến `record` chưa gán sẽ báo `55000 record "r" is not assigned yet`, dù `r(g)` là alias của một bảng `VALUES` hoàn toàn hợp lệ.
>
> **Sự cố nguồn (WP3-A3):** Block 1 assertion P04 dùng `(values …) r(g)` trong khi block khai báo `r record` cho vòng lặp P12. Block 3 **không** dính vì đã dùng `c2`/`pr`. Defect chỉ lộ khi dry-run standalone; nếu apply thẳng, `apply_migration` sẽ fail (rollback nguyên tử, không hại production) nhưng **tiêu mất lần apply đã được uỷ quyền**.
>
> **Hệ quả vận hành:** dry-run Block 1 trở thành bước bắt buộc trước mọi apply — nó read-only, không tốn gì, và đồng thời chứng minh luôn toàn bộ precondition đang PASS trên dữ liệu sống.

**Bài học phụ (D-A2-1, ghi kèm):** thứ tự chèn dòng registry của `apply_migration` vào `supabase_migrations.schema_migrations` **chưa được kiểm chứng** là trước hay sau khi chạy body. Vì vậy **cấm assert `count(*) = N` bên trong migration body**; assertion lineage phải viết theo kiểu **bất biến với thứ tự** (baseline tồn tại + không có version lạ mới hơn), và mọi kiểm tra đếm registry chuyển sang **Layer B external post-apply**.

---

## 13. KHỐI APPEND ĐÃ SOẠN SẴN (dùng ở E3 MILESTONE CLOSEOUT — CHƯA ÁP)

Khi E3 milestone đóng (sau WP4), dán nguyên văn:

**→ `DMA_RULES.md`** (cuối file, sau dòng update V113G-M1):

```
 **Cập nhật 2026-07-22 18:23 GMT+7 (V114B-E3 · WP3 · ĐÓNG): ⭐ SESSION WRITE-PATH CONTAINMENT — thu quyền ghi trực tiếp `lesson_sessions` khỏi `authenticated`/`anon`.** Mig **111** `20260722112305 v114b_e3_wp3_a2_lesson_sessions_write_revoke` (digest `15747cd0b1e48247c3fc411a4c9a78de`, công thức `md5(array_to_string(statements,E'\n'))`). Một lệnh duy nhất: `revoke insert, update, delete, truncate on table public.lesson_sessions from authenticated, anon`. `relacl` `arwdDxtm` → **`rxtm`** cho cả 2 role API; SELECT/policy/trigger/function/service_role/postgres/default-ACL **0 đổi**; business row **±0**. Checkpoint A **17/17**, Checkpoint B **26/26** (14 từ chối trực tiếp gồm TRUNCATE + 10 RPC/refusal + 2 control đặc quyền), Layer B re-run **17/17**. **`taught_by` nay chỉ ghi được qua `start_session`** — bất biến "runtime evidence bất biến" trở thành đúng về mặt cấu trúc với mọi principal user-JWT. **E3-SG-02 = CONTAINED FOR AUTHENTICATED/ANON USER-JWT PATH (KHÔNG CLOSED)** · **E3-SG-01 vẫn OPEN**. **DB: 88 bảng · 207 hàm · 198 definer · 166 policy · 33 trigger · mig 001→111.** Rollback 1 câu GRANT, sẵn sàng. R21 observation active. Nợ tách riêng: P2-HARDEN-01 · TRUNCATE toàn nền tảng 62/88 · `pg_default_acl` · `service_role` BYPASSRLS · residual REFERENCES/TRIGGER/MAINTAIN. Cập nhật "tới đâu ghi tới đó".*
```

**→ `DMA_SYSTEM_MAP.md`** (cuối file, bump **v1.14 → v1.15**):

```
## 🔒 V114B-E3 · WP3 — SESSION WRITE-PATH CONTAINMENT (22/07/2026 · v1.14 → v1.15)

Mig **111** `v114b_e3_wp3_a2_lesson_sessions_write_revoke`. `public.lesson_sessions` ACL: `authenticated`/`anon` `arwdDxtm` → **`rxtm`** (mất INSERT/UPDATE/DELETE/TRUNCATE, giữ SELECT). 5 writer có kiểm soát là đường ghi DUY NHẤT: `create_lesson_session` · `update_lesson_session` · `cancel_lesson_session` · `start_session` (writer duy nhất của `taught_by`) · `submit_session_journal` — tất cả SECDEF owner `postgres`, không cần caller table grant. 3 policy giữ nguyên làm defence-in-depth (2 policy ghi nay không với tới được). `service_role` giữ `arwdDxtm` + BYPASSRLS = bypass đặc quyền còn nguyên, ngoài scope.

**Invariants:** **88**/**207**/**198**/**166**/**33** · mig **111** · routes 52 · edge 16 — frontend HEAD `d8178a55` KHÔNG đổi. Endpoint: RULES **D309** (WP3 không canonicalize D mới; **D323-cand** treo) · SYSTEM_MAP **v1.15**.

**E3-SG-02 = CONTAINED (authenticated/anon user-JWT path), KHÔNG CLOSED. E3-SG-01 = OPEN.** R21 observation active tới 25/07 18:23 ICT.
```

---

## 14. TRẠNG THÁI CUỐI

| | |
|---|---|
| **WP3** | **FORMALLY PASS / CLOSED** |
| WP3-A3R Checkpoint A · B | **17/17** · **26/26 + 17/17** |
| Checkpoint C (browser smoke) | **NON-BLOCKING POST-RELEASE UX SMOKE** — không chặn verdict |
| **E3-SG-01** | **OPEN** — chờ WP4 |
| **E3-SG-02** | **CONTAINED FOR AUTHENTICATED/ANON USER-JWT PATH** — KHÔNG CLOSED |
| **R21** | **ACTIVE OBSERVATION** — chưa hoàn tất |
| Migration inventory | **111** |
| DB | 88 bảng · 207 hàm · 198 definer · 166 policy · 33 trigger |
| Repository HEAD | `d8178a55895b64bbffdf79bb05c06e6b4313d68b` — 0 file đụng |
| `DMA_RULES.md` | **KHÔNG ĐỔI** (khối append đã soạn — §13) |
| `DMA_SYSTEM_MAP.md` | **KHÔNG ĐỔI** (khối append đã soạn — §13) |
| Candidate promoted | **KHÔNG** |
| WP4 | **chưa mở**, chờ Owner |

**WP tiếp theo đề xuất:** **WP4 — journal-authority cutover** (đóng điều kiện 4 của E3-SG-01 bằng `dimension='responsible'`), vì đó là điều kiện tiên quyết cho cả Surface C lẫn planned-teacher reassignment writer. Ứng viên thay thế nếu Owner ưu tiên bảo mật nền tảng: đăng ký + xử lý phơi nhiễm TRUNCATE/`pg_default_acl` toàn nền tảng.

---

*V114B-E3 · WP3 closeout · RULES/SYSTEM_MAP không canonicalize · E3-SG-02 CONTAINED không CLOSED · E3-SG-01 không đóng · R21 active.*
