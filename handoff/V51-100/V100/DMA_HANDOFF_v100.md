# 📦 DMA_HANDOFF_v100.md — V100 AUDIT INTELLIGENCE / ADMIN INVESTIGATION (12/07/2026)

## 1. Canonical endpoint (đọc cùng RULES + SYSTEM_MAP)
RULES **D247** · SYSTEM_MAP **v0.93** · Handoff **v100**
Live inventory: **73 tables · 135 SECURITY DEFINER · 159 RLS policies · 1 cron**
audit_logs: **7.843 rows · 4 index** (PK + 3 btree V100) · `admin_config_registry` **40 keys**
Baseline: An **6/2/6** · Evidence **22 / 16 groups** · Readiness **v2** emerging/contemporaneous, general current_3m failed = [too_short_duration, insufficient_longitudinal_spread] · Discovery **0 capsules** · V92–V99 nguyên vẹn · privacy D244 nguyên.

---

## 2. V100 làm gì
Biến `/admin/audit-log` từ **bảng log kỹ thuật** thành **công cụ điều tra vận hành**.
Nguyên tắc: **HUMAN-FIRST INVESTIGATION, RAW DATA ON DEMAND.**

**Nén thật: 7.838 raw events → 1.122 mục hoạt động (7,0×) · 157 trang → 23 trang.**

---

## 3. Phase 0 — 6 sự thật đúc từ live (KHÔNG ĐOÁN)

| # | Sự thật | Hệ quả thiết kế |
|---|---|---|
| 1 | audit_logs **chỉ có 1 index (PK)** → mọi filter là seq scan 7.838 rows | +3 btree bắt buộc |
| 2 | 4 media-view action = **7.505/7.838 = 95,8%** toàn bộ log | tiếng ồn render che 4,2% sự kiện có nghĩa |
| 3 | median gap giữa 2 event cùng actor = **0,25s** (71,2% ≤2s) | page-load fan-out ≠ hành vi người → **D245** |
| 4 | **79,8%** `child_media_view` thuộc group moment ≥2 trẻ | câu mẫu "xem 5 nội dung **của An**" là SAI SỰ THẬT → **D246** |
| 5 | `DENIED_ACTIONS` hard-code **3** action, live có **5** | FLOW C của V99 đang **báo thiếu sự kiện bảo mật** |
| 6 | `current_user` bị SECURITY DEFINER đổi thành owner | phải dùng `current_setting('role')` → **D247** |

**GIN KHÔNG tạo** — EXPLAIN ANALYZE: child filter trả 3.617/7.838 rows (**selectivity 46%**), nhánh `moment_id→moment_children` là cast+subselect ⇒ planner không dùng được GIN; seq scan 6ms là plan tối ưu. Index chết = nợ, không phải tài sản.

---

## 4. DB objects (4 migration · D92 3-block · D15/D231 hardening · grant leak = 0)

| Migration | Nội dung |
|---|---|
| `v100_1` | 3 btree index: `created_at DESC` · `(actor_id, created_at DESC)` · `(action, created_at DESC)` |
| `v100_2` | `audit_action_category()` (SQL IMMUTABLE, 7 category — **single source of truth trong DB**) · `audit_event_child_ids()` (SQL STABLE, 5 nguồn child-linkage) · `admin_audit_investigation()` **DEFINER** · `admin_audit_group_events()` **DEFINER** |
| `v100_2b` | Bỏ TEMP TABLE `ON COMMIT DROP` (RPC không re-entrant trong 1 transaction — đúng footnote V98 `generate_discovery_capsule`). Thay bằng CTE + `count(*) OVER ()`; đổi sang `count(DISTINCT id)` để LATERAL unnest child_ids không thổi phồng count. |
| `v100_3` | `audit_config_change()` +`metadata.actor_source` (D247) · `admin_audit_investigation()` +`actor_sources` +`all_signed` |

**Definer 133 → 135** (+2: `admin_audit_investigation`, `admin_audit_group_events`).
`audit_action_category` / `audit_event_child_ids` là SQL thường — **không** definer, nên không tính vào 135.

---

## 5. 3 canonical decision

### V100-01 — Burst Compression ≠ Causal Interpretation (D245)
Group identity = **`(actor_id, category='media_access', chuỗi gap ≤ 15s)`**, chain trên **toàn bộ media_access stream của actor**, độc lập filter & độc lập `now()`. Filter **CHỌN** group, không **ĐỊNH NGHĨA** group ⇒ `admin_audit_group_events(actor, burst_start_at)` mở lại **đúng exact raw members** ở mọi phiên.
Chỉ `media_access` được group. Security/config/data_mutation/sharing/kid_session **không bao giờ**. `actor_id IS NULL` **không bao giờ** chain (nếu không, mọi thiết bị Cổng Bé dồn chung một partition).
**Rationale 15s:** burst lớn nhất **bão hoà ở 245 events từ W=15s**; nới 30s/60s không lộ episode lớn hơn, chỉ dán các đợt riêng biệt (group 831→630→440).
Copy bắt buộc: **"đợt truy cập nội dung"** — CẤM "một lần mở trang".

### V100-02 — Child Attribution Integrity (D246)
Nhãn sở hữu **"của [tên trẻ]"** chỉ khi tập trẻ resolve được là **singleton**. Multi → "liên quan tới N trẻ".
**Lọc theo trẻ = hợp lệ · Gán sở hữu = không.** Deep-link copy: "Hoạt động **liên quan đến** [tên]".
5 nguồn child-linkage chứng minh được: `child_id` native · `metadata.child_id` · `metadata.kid_child_id` · `metadata.blocking_children[]` · `metadata.moment_id → moment_children`. Ngoài 5 nguồn = cấm bịa.

### V100-03/04 — Raw Truth + Execution Source (D247)
Raw forensic truth luôn mở được, **không xoá, không rewrite**.
`actor_source ∈ {authenticated, service_role, system_sql, unknown}` — chứng minh **NGUỒN THỰC THI**, KHÔNG chứng minh **con người chịu trách nhiệm**. CẤM suy ra "Claude/Founder/Admin đã thay đổi".
Rows trước V100 **không backfill** → fallback trung tính.

---

## 6. Copy rule cho grouped access events (V100-05)
- `bool_and(metadata ? 'ttl_sec')` = true → **"N lần cấp quyền truy cập"**
- ngược lại → **"N sự kiện truy cập kỹ thuật"**
- CẤM generic "N sự kiện kỹ thuật" · CẤM đọc thành "N hành động người"
- Headline giữ tách bạch: **"đã xem 13 nội dung"** (nội dung riêng biệt) ≠ **"44 lần cấp quyền truy cập"** (số lần cấp signed URL — TTL 600s hết hạn / re-render)

---

## 7. Verification evidence

**Server suite 10/10:** total 1.122 group · raw re-open đúng 13 member · child An 476 · security 43 · config 5 · actor Hùng 278 · unknown action → 0 (không crash) · page overflow → total giữ, items [] · non-admin → `not_authorized` (cả 2 RPC) · invalid input → `invalid_input`.

**actor_source 4/4 live:**
| Ngữ cảnh | actor_id | actor_source |
|---|---|---|
| authenticated (JWT admin) | e86e45d1… | `authenticated` ✅ |
| service_role (`SET LOCAL ROLE`) | NULL | `service_role` ✅ |
| system_sql (MCP/migration) | NULL | `system_sql` ✅ |
| legacy (2 rows trước V100) | — | absent → fallback trung tính, **không backfill** ✅ |

**QA production (Jean, 15 ảnh):** Flow A actor deep-link 278 mục + URL + reload ✅ · Flow B burst "13 nội dung, liên quan tới 3 trẻ" → bung đúng **13 raw event** đủ metadata ✅ · Flow C security 43/21, 0 media-view lẫn ✅ · Flow D config có diff `old`/`new` thật ✅ · Flow E child 476 mục, wording "liên quan đến" ✅ · Regression ✅.

**V100-02 tự chứng minh trên màn hình thật:** singleton → *"đã xem 1 nội dung, **của An**"*; multi → *"liên quan tới 3 trẻ"*.

**Vòng lặp khép kín D247:** chính lệnh INSERT registry của Claude (service-role SQL) đã tự sinh audit row mang `actor_source = system_sql` → RPC surface → UI render **"Thay đổi từ hệ thống"**. Contract tự chứng minh trên production data.

---

## 8. Inventory BEFORE → AFTER

| | BEFORE (V99) | AFTER (V100) | Object gây thay đổi |
|---|---|---|---|
| tables | 73 | **73** | — |
| SECURITY DEFINER | 133 | **135** | +`admin_audit_investigation`, +`admin_audit_group_events` |
| policies | 159 | **159** | — |
| cron | 1 | **1** | — |
| audit_logs rows | 7.838 | **7.843** | +5 config_change **thật**: 1 registry insert + 3 verify actor_source + 1 registry insert D238. **Không xoá** (xoá = rewrite forensic history, cấm) |
| audit_logs index | 1 | **4** | +3 btree V100_1 |
| admin_config_registry | 38 | **40** | +`audit.burst_window_sec`, +`audit.actor_source` |

---

## 9. Regression (toàn bộ PASS)
- Lookup: Hùng → **2 trẻ** · An → **6/2/6** · evidence **22/16** · readiness **v2** emerging + failed codes nguyên
- `privacy_note` D244 nguyên: `parent_memory` chỉ metadata (total/archived/quota), **không đọc body** — privacy regression = **0**
- `/parent/journal` · `/parent/discovery` · Kid Portal: **untouched**
- Grant leak trên cả 5 object V100: **0** (aclexplode verified)
- typecheck PASS cả 2 commit · `get_diff` scope verify: commit 1 = 3 file, commit 2 = 1 file, 0 rò rỉ

---

## 10. Deploy
Lovable `23fecb09` (build) → `219f7eae` (patch V100.1). Deploy production `4f718192` → demenart.com + demenart.lovable.app. **D105:** nếu thấy "This page didn't load", đợi vài phút hoặc dùng Preview URL.

---

## 11. Registry sync (D238)
- `route_registry` `/admin/audit-log` = **live** (đã có từ V99, drift = 0)
- `admin_modules` `audit-log` → title "Nhật ký hoạt động", description + usage_note cập nhật theo V100 (kèm cảnh báo burst ≠ hành động người, actor_source ≠ human responsibility)
- `admin_config_registry` +2 key (xem §8)

---

## 12. Nợ để lại V100
- 🟡 **GIN metadata** — xét lại khi `audit_logs` > 100k rows (hiện selectivity 46% → vô dụng)
- 🟡 **Grouping ở scale lớn** — hiện chain toàn bộ media_access stream mỗi query. Chấp nhận được ở 7,8k rows; cần rethink (materialized burst_id) ở ~1M rows
- 🟡 **`actor_source` cho action ngoài `config_change`** — hiện chỉ trigger config ghi field này
- 🟡 Alert / anomaly detection (chưa duyệt — V100 non-goal)
- Nợ V95–V99 giữ nguyên: Bunny health probe · hard-code scan FE · pricing UI · V96D readiness UI · Badge Provenance · Spine ref_id backfill · child_skills refactor · notification infra V93 · repo re-sync

---

## 13. Bài học phiên này
1. **Brief có thể sai một cách thuyết phục.** Câu mẫu trong brief V100 — *"Hùng đã xem 5 nội dung của An"* — nghe rất hợp lý, nhưng audit quan hệ thật cho thấy **79,8% trường hợp là khẳng định sai**. Nếu code theo brief mà không audit `moment_children`, sản phẩm sẽ nói dối một cách trơn tru. **D1 áp cho cả yêu cầu của CTO, không chỉ cho schema.**
2. **QA của người dùng phơi ra lỗ hổng governance, không chỉ lỗi UI.** Dòng "Không xác định được người thực hiện" trong ảnh QA của Jean không phải bug — nó là hệ thống nói thật, và cái sự thật đó dẫn thẳng tới D247.
3. **Bẫy cũ quay lại.** TEMP TABLE `ON COMMIT DROP` đã được ghi footnote ở V98 mà vẫn tái phạm ở V100. Footnote không đủ — phải thành D-rule mới không lặp.
