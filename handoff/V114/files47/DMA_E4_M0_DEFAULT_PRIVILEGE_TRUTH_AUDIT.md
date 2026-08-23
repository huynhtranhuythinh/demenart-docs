# E4-M0 DEFAULT PRIVILEGE TRUTH AUDIT

> DMA V114B-E4 · Milestone M0 · READ-ONLY · 2026-07-25 (ICT) · Builder: Claude
> Target DB: Supabase `xcvhacymrbhdhohyylyq` (PostgreSQL 17.6, db `postgres`) · Repo: Lovable `d9d56000` · Session role khi audit: `postgres`

## 1. Executive verdict

**`READY WITH EXPLICIT GAPS`**

1. Zero drift trên mọi trục so với E3 accepted baseline (registry 115/RM1 · 88/210/199/166/33/1 · target relacl byte-identical · frontend tip `5d28ee67`).
2. `pg_default_acl` thực tế có **26 rows** (E3 residual chỉ pin 2 rows scope `public/tables`); trong đó **6 rows tác động schema `public`** — 2 grantor (`postgres`, `supabase_admin`) × 3 object class (tables `arwdDxtm`, sequences `rwU`, functions `X`) đều auto-grant cho `anon/authenticated/service_role`.
3. **Cơ chế function-class là mở rộng mới so với hồ sơ E3**: mọi function tương lai do `postgres` tạo tự nhận `EXECUTE` cho `anon` — hiện chưa materialize (0/210 function có anon/PUBLIC EXECUTE, 0 proacl NULL) nhờ kỷ luật D15/D92, tức containment hiện tại **giữ bằng convention, không bằng cơ chế**.
4. Active exposure mới: **không có**. User-JWT mutation closure E3 nguyên vẹn; 0 migration từng chạy `ALTER DEFAULT PRIVILEGES`; 0 `GRANT ... TO PUBLIC`.
5. E3-SG-02 giữ nguyên `CONTAINED — NOT CLOSED`. M1 đủ input để thiết kế contract; gaps liệt kê §10 đều non-blocking.

## 2. Baseline integrity

| Trục | Live evidence | Baseline E3 | Verdict |
|---|---|---|---|
| Repository | Lovable `d9d56000-3cf9-4c46-9890-651edc53d73f`; `supabase/config.toml` = `project_id "xcvhacymrbhdhohyylyq"` | same | MATCH |
| Branch/HEAD | Lovable direct-main (D309); tip `5d28ee67386dcaa3b5f627c6939fda4be23cb470` (2026-07-24T15:50:17Z) | frontend accepted tip `5d28ee67` | MATCH — 0 commit sau baseline |
| Lineage | `645fad7d` (ai) → `7df9621c` (manual) → `5d28ee67` (ai) — `list_edits` | — | ghi nhận |
| Dirty state | Lovable MCP không expose working-tree; auto-commit model ⇒ **N/A / not observable** (access gap G5, non-blocking vì HEAD = accepted tip) | — | UNKNOWN-BENIGN |
| Registry count | **115** (`list_migrations` + `count(*) supabase_migrations.schema_migrations`) | 115 | MATCH |
| Latest registry | `20260725011235 v114b_e3_rm1_session_reports_write_revoke` | RM1 | MATCH |
| Repo migration count | **0** — full file enumeration 3 trang `list_files` (205 files, kết thúc `has_more:false`): không tồn tại `supabase/migrations/`, không file `.sql` nào | registry là single source | MATCH — no mismatch channel |
| Live invariants | 88 tables · 210 functions · 199 SECDEF · 166 policies · 33 triggers · 1 cron · 0 views · 0 matviews · **0 sequences** trong `public` | 88/210/199/166/33/1 | MATCH |
| routeTree | `src/routeTree.gen.ts` tại tip accepted — không regenerate | — | MATCH |

**Drift verdict: ZERO DRIFT.** Evidence: `list_migrations`, 5 read-only `execute_sql` (catalog), `list_edits limit 3`, `list_files` ×3, `read_file supabase/config.toml`.

## 3. Default ACL truth matrix

Toàn bộ `pg_default_acl` = **26 rows**. Object class hiện diện: `r` (tables) · `S` (sequences) · `f` (functions). **Không có** class `T` (types) và `n` (schemas) ⇒ default ACL không ảnh hưởng types/schemas tương lai. Tất cả rows đều **per-schema scope** (không có global row). PG17 mapping xác nhận: r/S/f/T/n.

### 3.1 Rows tác động DMA (schema `public`) — 6 rows

| ID | Entry owner (grantor) | Schema | Class | Raw ACL | Decoded (grantee ← priv) | Grant opt | Future-object creator condition | Risk |
|---|---|---|---|---|---|---|---|---|
| DA-01 | `postgres` | public | r | `{postgres=arwdDxtm/postgres, anon=arwdDxtm/postgres, authenticated=arwdDxtm/postgres, service_role=arwdDxtm/postgres}` | anon/authenticated/service_role ← ALL 8 (a,r,w,d,D,x,t,m) | none | Table mới do **postgres** tạo (= mọi migration MCP) | **P1 — cơ chế chính của E3-SG-02** |
| DA-02 | `postgres` | public | S | `rwU` ×4 grantee | anon/auth/service ← SELECT,UPDATE,USAGE | none | Sequence mới do postgres tạo (hiện 0 sequence — dormant) | P2 |
| DA-03 | `postgres` | public | f | `X` ×4 grantee | **anon**/auth/service ← EXECUTE | none | Function mới do postgres tạo | **P1 — chưa từng có trong hồ sơ E3** |
| DA-04 | `supabase_admin` | public | r | `arwdDxtm` ×4 grantee | như DA-01 | none | Table do **supabase_admin** tạo trong public (platform ops; DMA objects không đi đường này — 88/88 owned postgres) | P2 (activation thấp) |
| DA-05 | `supabase_admin` | public | S | `rwU` ×4 | như DA-02 | none | như DA-04 | P2 |
| DA-06 | `supabase_admin` | public | f | `X` ×4 | như DA-03 | none | như DA-04 | P2 |

### 3.2 Rows ngoài `public` — 20 rows (tóm tắt, đầy đủ raw ACL đã pin trong evidence)

| Grantor | Schemas | Classes | Grantees chính | Ghi chú |
|---|---|---|---|---|
| `postgres` | storage | r/S/f | anon/auth/service (ALL/rwU/X) | Supabase Storage model chuẩn |
| `supabase_admin` | graphql, graphql_public | r/S/f | postgres, anon, auth, service | GraphQL surface chuẩn |
| `supabase_admin` | realtime | r/S/f | postgres, dashboard_user | |
| `supabase_admin` | extensions, cron | r/S/f | postgres (WITH GRANT OPTION `*`) | chỉ postgres |
| `supabase_auth_admin` | auth | r/S/f | postgres, dashboard_user | |

**Source/origin:** 0/115 migration chứa lệnh `ALTER DEFAULT PRIVILEGES` thực thi (hit duy nhất `20260715091549 v105f_v111e` là **comment** mô tả cơ chế D15, theo sau là REVOKE/GRANT tường minh — nguyên văn đã pin). Shape 26 rows khớp Supabase platform bootstrap chuẩn ⇒ **PLATFORM-DEFAULT CONSISTENT — creation event ngoài registry NOT PROVEN** (kênh Dashboard/psql lịch sử không thể loại trừ từ catalog; không ảnh hưởng remediation).

## 4. Existing object ACL matrix

### 4.1 Tables — 88 bảng, phân bố 10 pattern (owner 88/88 = `postgres`, RLS enabled 88/88, forced 0/88)

| # | Raw ACL pattern | Số bảng | Diễn giải | Default-derived? |
|---|---|---|---|---|
| 1 | `postgres=arwdDxtm, anon=arwdDxtm, authenticated=arwdDxtm, service_role=arwdDxtm` | **51** | Full default materialized (vd `admin_config_registry`…`themes`) | **DEFAULT-DERIVED POSSIBLE — NOT PROVEN** (khớp DA-01 từng bit) |
| 2 | `postgres, service_role` full | 10 | FMN core (vd `card_person_links`…`parent_memory_media`) | NARROWED bằng migration |
| 3 | `postgres, service_role` full + `authenticated=r` | 8 | vd `family_member_relationships`…`product_events` | NARROWED |
| 4 | `postgres, authenticated, service_role` full (no anon) | 7 | vd `admin_module_links`…`prep_items` | NARROWED (anon revoked) |
| 5 | `postgres` only | 4 | vd `card_acknowledgements`…`preserve_records` | NARROWED |
| 6 | `anon=rxtm, authenticated=rxtm` + postgres/service full | 3 | `class_distributions`, `lesson_sessions`, `session_reports` | Residual x,t,m = fingerprint default-minus-revoke (WP3-A2/RM1) |
| 7 | `anon=rDxtm, authenticated=rDxtm` + postgres/service full | 2 | `learning_moments`, `child_observations` | như trên, còn giữ D (WP1) |
| 8 | `postgres` full + `authenticated=r` | 1 | `session_teacher_assignments` | NARROWED |
| 9 | `postgres` full + `anon/auth/service=r` | 1 | `session_teachers` | NARROWED |
| 10 | `postgres` full + `service_role=r` | 1 | `card_media` | NARROWED |

Ghi chú semantics: không bảng nào ACL `NULL`; PUBLIC (grantee 0) không xuất hiện trong bất kỳ relacl nào; owner rights luôn hiện diện tường minh.

### 4.2 Target objects (chi tiết, effective = stored vì anon/authenticated không kế thừa role nào)

| Object | Owner | anon | authenticated | service_role | postgres | RLS |
|---|---|---|---|---|---|---|
| `learning_moments` | postgres | r,**D**,x,t,m — no a/w/d | r,**D**,x,t,m — no a/w/d | ALL | ALL (owner) | enabled, not forced |
| `child_observations` | postgres | r,**D**,x,t,m | r,**D**,x,t,m | ALL | ALL | enabled, not forced |
| `session_reports` | postgres | r,x,t,m — **no D** | r,x,t,m | ALL | ALL | enabled, not forced |
| `lesson_sessions` | postgres | r,x,t,m | r,x,t,m | ALL | ALL | enabled, not forced |

`has_table_privilege` matrix xác nhận từng cell (đã pin). Khớp E3 RM1 byte-identical cho `lesson_sessions`/`session_reports`.

### 4.3 Aggregate effective exposure (live, đo bằng `has_table_privilege` trên 88 bảng)

| Metric | Live | Ghi chú |
|---|---|---|
| anon giữ INSERT∨UPDATE∨DELETE (stored) | **51/88** | toàn bộ = pattern 1; RLS-gated |
| authenticated giữ INSERT∨UPDATE∨DELETE | **58/88** | pattern 1+4; RLS-gated |
| anon giữ TRUNCATE | **53/88** | pattern 1+7; **RLS không chặn TRUNCATE** |
| authenticated giữ TRUNCATE | **60/88** | pattern 1+4+7 |

Kênh kích hoạt TRUNCATE cho user-JWT: PostgREST không phát TRUNCATE; **0/210 function chứa từ khóa TRUNCATE trong body** (prosrc scan = null); 0 function anon-executable ⇒ **NO PROVEN ACTIVATION PATH** — CONTAINED, đúng trạng thái E3.

### 4.4 Sequences / Views / Matviews / Types

`public` có **0** sequence, 0 view, 0 matview ⇒ DA-02/DA-05 dormant; không có sequence-ACL surface. Types: không có defacl class `T`; enum types theo mặc định PG cho PUBLIC USAGE — không phải write surface, ghi nhận P3.

### 4.5 Functions — 210 (owner 210/210 = postgres; 199 SECDEF / 11 INVOKER)

| proacl pattern | secdef | n |
|---|---|---|
| `postgres,authenticated,service_role = X` | ✔ | 123 |
| `postgres,service_role = X` | ✔ | 36 |
| `postgres,authenticated = X` | ✔ | 25 |
| `postgres,service_role,authenticated = X` | ✔ | 7 |
| `postgres = X` | ✔ | 8 |
| `postgres,authenticated,service_role = X` | ✖ | 5 |
| `postgres,service_role = X` | ✖ | 4 |
| `postgres = X` | ✖ | 2 |

**PUBLIC EXECUTE: 0 · anon EXECUTE: 0 · proacl NULL: 0.** Đây là bằng chứng trực tiếp rằng default-ACL function grant (DA-03) chưa từng materialize sót — mọi function đều đã qua REVOKE/GRANT tường minh (D15/D92).

### 4.6 Schemas / Database

`public`: owner `pg_database_owner`; PUBLIC + anon/auth/service = USAGE; CREATE chỉ `pg_database_owner` (postgres qua db ownership). `net`: PUBLIC + anon/auth/service = USAGE (function surface trong `net` chưa enumerate — gap G4). Database `postgres`: owner postgres; PUBLIC = CONNECT+TEMP (chuẩn platform).

## 5. Role and ownership map

| Role | Login | Inherit | Super | BypassRLS | Membership liên quan | Ownership / relevance |
|---|---|---|---|---|---|---|
| `postgres` | ✔ | ✔ | ✖ | **✔** | member WITH ADMIN của anon, authenticated, service_role, authenticator; + `supabase_privileged_role`, pg_read_all_data, pg_monitor… | Owner db + 88 tables + 210 functions + defacl entries DA-01/02/03 + storage rows. **= Migration execution role.** |
| `supabase_admin` | ✔ | ✔ | **✔** | ✔ | — | Owner phần lớn platform schemas + defacl DA-04/05/06 + các rows ngoài public. **postgres KHÔNG phải member ⇒ không thể `ALTER DEFAULT PRIVILEGES FOR ROLE supabase_admin`.** |
| `service_role` | ✖ | ✔ | ✖ | **✔** | — | Trusted operational tier (Edge Functions). E3-SG-02 blocker giữ nguyên. |
| `anon` / `authenticated` | ✖ | ✔ | ✖ | ✖ | — | User-JWT tiers qua `authenticator` (NOINHERIT, SET-only switching — chuẩn PostgREST). |
| `authenticator` | ✔ | ✖ | ✖ | ✖ | anon/auth/service (inherit=false, set=true) | Connection role PostgREST. |
| `supabase_auth_admin` / `supabase_storage_admin` | ✔ | ✖ | ✖ | ✖ | — | Platform services; auth-schema defacl owner. |

Không xuất secret/credential nào. Evidence gap: transitively-derived privileges của `supabase_privileged_role` chưa expand (không ảnh hưởng contract M1 — postgres đã đủ quyền qua ownership + WITH ADMIN).

## 6. Migration provenance

| Operation | Kết quả search registry (115 migrations, full-text `statements`) | Debt effect |
|---|---|---|
| `ALTER DEFAULT PRIVILEGES` (thực thi) | **0** migration. 1 hit text tại `20260715091549 v105f_v111e` = comment D15, theo sau: `REVOKE ALL ON FUNCTION public.get_family_card(uuid) FROM PUBLIC, anon, authenticated, service_role; GRANT EXECUTE ... TO authenticated;` | KHÔNG TẠO — debt là platform bootstrap |
| `GRANT ALL` | 2: `086_drive_folders` → `GRANT ALL ON public.drive_folders TO service_role`; `093_kid_portal_foundation` → `grant all on public.kid_access, kid_devices, kid_pairing_codes, kid_sessions, kid_reactions to service_role` | PRESERVED (đúng trusted-tier contract) |
| `GRANT ... TO PUBLIC` (regex grantee thật, loại `search_path TO public`) | **0** | — |
| `REVOKE` | 98/115 migrations | NARROWED (cơ chế chính chống materialization) |
| `GRANT` (mọi dạng) | 90/115 | per-object explicit |
| `SECURITY DEFINER` | 89/115 | RPC model |
| Executing role | **postgres — PROVEN**: session role MCP = `postgres` (đo trực tiếp) + ownership đồng nhất 88/88 tables và 210/210 functions về `postgres` (không object nào owner khác ⇒ không migration nào chạy bằng role tạo-object khác) | — |
| SQL template/generator trong repo có thể tái tạo debt | **0** — repo không chứa file SQL nào (enumeration đầy đủ §2). Cơ chế tái tạo debt duy nhất = quên block REVOKE trong migration mới (convention risk, không phải code artifact) | — |

## 7. Trusted-path dependency analysis

### 7.1 `learning_moments`
Writers duy nhất tìm được (prosrc scan INSERT/UPDATE/DELETE): `archive_empty_draft_moment_service`, `remove_moment_media_service` — cả hai SECDEF owner postgres, EXECUTE: authenticated+service_role. Triggers: `trg_guard_learning_moments_actor` → `guard_learning_moments_actor` **INVOKER**, EXECUTE chỉ postgres+service_role (đúng WP1); `set_updated_at` SECDEF. **Required để sống:** postgres owner rights (bất khả revoke) + service_role ALL + authenticated EXECUTE trên 2 RPC. **Removable-apparent:** anon r,D,x,t,m; authenticated D,x,t,m (giữ authenticated r nếu có read-path trực tiếp PostgREST — cần xác nhận consumer trước khi rút `r`: NOT YET PROVEN). Preservation M1: không đụng proacl RPC; không đụng owner; SELECT policy `learning_moments_select_school_or_parent` roles=`public` đang phục vụ read qua RLS — rút `r` của anon cần kiểm tra share-token/kid read path trước.
### 7.2 `child_observations`
Cùng writers/guard model như 7.1 (`trg_guard_child_observations_actor` INVOKER). Cùng preservation requirements. Policies SELECT chỉ authenticated ⇒ anon `r` là candidate rút mạnh hơn LM, vẫn cần consumer-proof.
### 7.3 `session_reports`
**0 trigger — xác nhận lại: KHÔNG trigger-contained** (đúng E3 contract). Writer duy nhất: `submit_session_journal` (SECDEF, authenticated+service_role EXECUTE). Trusted capability = service_role/postgres table-level (arwdDxtm) — ngoài user-JWT closure, phải **PRESERVE nguyên vẹn**. Dead-door INSERT/UPDATE policies cho authenticated tồn tại (P3 carry-forward). Removable-apparent: anon/authenticated x,t,m; anon r cần consumer-proof.
### 7.4 `lesson_sessions`
Writers: `create_lesson_session`, `update_lesson_session`, `cancel_lesson_session`, `start_session`, `submit_session_journal` — đều SECDEF, authenticated+service_role EXECUTE. Triggers: `dma_snapshot_planned_teacher` (SECDEF, EXECUTE chỉ postgres) + `set_updated_at` (SECDEF). R21 giữ nguyên `OPEN RESIDUAL MONITORING — NON-BLOCKING` (không mutation nào chạy session này để verify — đúng điều kiện chờ organic/owner mutation). Preservation: như 7.3.
### 7.5 Migration execution role (`postgres`)
Phụ thuộc: db/schema CREATE qua ownership; WITH ADMIN trên anon/authenticated/service_role/authenticator ⇒ đủ thẩm quyền GRANT/REVOKE thay các role đó và `ALTER DEFAULT PRIVILEGES FOR ROLE postgres` (+ FOR ROLE anon/auth/service nếu cần). **Không** đủ thẩm quyền với entries `FOR ROLE supabase_admin` (không membership) — constraint cứng cho M1. Rollback capability: `apply_migration` transaction-wrap + D92 Block-3 RAISE — không phụ thuộc privilege nào nằm trong diện thu hẹp.
### 7.6 `service_role` operational path
Edge Functions (16) ghi qua service_role: bảng target ALL + 51 bảng pattern-1 ALL + FMN tables ALL + EXECUTE 170/210 functions. Cron job #1 (`purge_trash`, 19:15 UTC daily) chạy `username=postgres`, gọi `net.http_post` → Edge (service_role nội bộ). **Preservation:** mọi remediation default-ACL không được kèm blanket revoke service_role trên existing objects; `net` USAGE cho postgres + pg_net execute phải giữ.

## 8. Risk register

| ID | Sev | Finding | Activation precondition | Objects/roles | Stored → Effective | Containment hiện tại | Future-migration effect | Evidence conf. | Remediation dep. | Blocks M1 |
|---|---|---|---|---|---|---|---|---|---|---|
| R-E4-01 | **P1** | Defacl `public/r` ×2 grantor auto-grant ALL cho anon/auth/service trên table tương lai | 1 lệnh `CREATE TABLE` bởi postgres thiếu block REVOKE | DA-01/DA-04 | arwdDxtm tương lai | Convention D92 (không cơ chế) | MATERIALIZE ngoài contract | HIGH (catalog) | ADP FOR ROLE postgres | NO — là input chính |
| R-E4-02 | **P1** | Defacl `public/f` auto-grant EXECUTE cho **anon** trên function tương lai — **chưa có trong hồ sơ E3** | 1 lệnh `CREATE FUNCTION` thiếu REVOKE (D15 window: `CREATE OR REPLACE` cũng reset về default này) | DA-03/DA-06 | X tương lai | 0/210 materialized (proven) | anon gọi được RPC mới qua PostgREST ngay khi schema reload | HIGH | như trên | NO |
| R-E4-03 | P2 | Defacl `public/S` + `storage/*` rwU/ALL tương lai | tạo sequence/storage object mới | DA-02/05 + storage rows | rwU | 0 sequence tồn tại — dormant | thấp | HIGH | gộp cùng ADP | NO |
| R-E4-04 | P2 | 51 bảng materialized full-grant anon/authenticated (a,w,d + D,x,t,m); phòng tuyến duy nhất = RLS (enabled 88/88, forced 0) | RLS policy bug/bypass tương lai | pattern-1 tables | stored write = effective write, RLS-gated | RLS + 166 policies; trạng thái E3-documented | tăng theo R-E4-01 | HIGH | existing-object sweep (M-sau, tách khỏi ADP) | NO |
| R-E4-05 | P2 | TRUNCATE: anon 53/88, authenticated 60/88 — RLS không chặn TRUNCATE | cần kênh SQL trực tiếp as-role (không tồn tại: PostgREST no-TRUNCATE, 0 func body TRUNCATE, 0 anon func) | pattern 1+4+7 | stored, NO PROVEN ACTIVATION | E3 CONTAINED xác nhận lại | theo R-E4-01 | HIGH | existing-object sweep | NO |
| R-E4-06 | P2 | `service_role` + `postgres` BYPASSRLS (E3-SG-02 blocker carry-forward) | credential compromise (ngoài scope DB-priv) | roles | — | Trusted-tier contract E3 | — | HIGH | governance, không remediate bằng REVOKE | NO |
| R-E4-07 | P3 | Dead-door INSERT/UPDATE policies (authenticated) trên cả 4 target trong khi table-priv đã rút — D290-class doc debt | — | 4 targets | — | vô hại chức năng | — | HIGH | policy cleanup milestone riêng | NO |
| R-E4-08 | P3 | Historical figure "TRUNCATE 62/88" không tái lập (live 60/88 authenticated · 53/88 anon; union 60) — khác biệt đo lường, KHÔNG drift (target relacl + registry identical) | — | doc | — | — | — | MED | ghi chú SYSTEM_MAP kỳ canonicalize sau | NO |
| R-E4-09 | P2 | 4 rows defacl `FOR ROLE supabase_admin` trong public/storage **không tự remediate được** bằng postgres | supabase_admin tạo object trong public (platform ops hiếm) | DA-04/05/06 | như DA-01 | activation thấp (0 object DMA owner supabase_admin) | tồn tại vĩnh viễn trừ khi platform xử lý | HIGH | **Owner/CTO decision D-M1** | NO (cần decision trước M2) |
| R-E4-10 | P2 | `net` schema USAGE cho PUBLIC/anon/authenticated; EXECUTE surface của `net.*` chưa enumerate | tùy ACL net functions | net | UNKNOWN | chưa đo | — | LOW — gap | bổ sung 1 query đầu M1 | NO |

Không có P0. Không risk nào nâng severity chỉ vì privilege string rộng khi thiếu activation path; không risk nào hạ vì thiếu production users.

## 9. Contract inputs for M1

1. **Removable (evidence-backed):** 6 rows defacl `FOR ROLE postgres` (public r/S/f + storage r/S/f) — thay bằng contract hẹp. Đề xuất khung để CTO duyệt: tables → không auto-grant gì cho anon/authenticated (service_role: CTO quyết A: giữ auto-ALL / B: explicit-only ★B để mọi grant đều registry-traceable); sequences → drop auto; functions → drop auto EXECUTE cho cả 3 (giữ D92 explicit-grant làm đường duy nhất).
2. **Must preserve:** postgres owner rights (implicit, không đụng) · toàn bộ proacl hiện hữu (đặc biệt authenticated EXECUTE trên 160 RPC) · service_role grants hiện hữu trên existing objects · cron/net path (7.6) · authenticated `r` trên các bảng có PostgREST read trực tiếp.
3. **Chưa đủ evidence để rút:** anon `r` trên pattern-1/6/7 (consumer-proof cần: share/$token, kid flows) · authenticated `r` per-table · bất kỳ thay đổi existing-object nào — **tách existing-object sweep khỏi milestone ADP** (ADP chỉ chạm future objects → zero-risk với runtime hiện tại).
4. **Ordering constraints:** M2 = 1 migration D92 ba block: BLOCK 1 `ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public|storage REVOKE ... FROM anon, authenticated[, service_role]` (idempotent, chỉ future) → BLOCK 2 không cần GRANT bù (không object mới tạo) → BLOCK 3 VERIFY đọc lại `pg_default_acl` + **simulation in-transaction**: `CREATE TABLE`/`CREATE FUNCTION` tạm → assert ACL kết quả → `DROP` → RAISE nếu sai (simulation nằm trong cùng transaction, rollback-safe). Sau đó `NOTIFY pgrst` không bắt buộc (không đổi object hiện hữu) nhưng vô hại (D289).
5. **SECDEF/INVOKER constraints:** không đổi security mode nào; D15 vẫn hiệu lực sau ADP-fix ở dạng nhẹ hơn (CREATE OR REPLACE sẽ reset về default *mới* = không grant — vẫn phải GRANT lại authenticated/service_role tường minh, tức D15 đổi chiều rủi ro từ "mở quá" sang "quên grant → 42501"; cần D-rule cập nhật khi canonicalize).
6. **Owner/CTO decisions cần khóa trước M2:** D-M1-a: xử lý 4 rows `supabase_admin` (★ACCEPT-AS-PLATFORM + rule-guard, vì bất khả tự remediate) · D-M1-b: service_role auto-grant giữ/bỏ (mục 1) · D-M1-c: phạm vi storage schema có gộp cùng đợt không (★có, cùng cơ chế).
7. **Verification assertions M2:** `pg_default_acl` sau migration chỉ còn contract rows; simulation table/function ACL = kỳ vọng; 0 thay đổi trên existing relacl/proacl (checksum count so sánh trước/sau); registry +1.

Không migration nào được viết trong M0.

## 10. Evidence gaps

| ID | Gap | Loại (đúng một) | Nguyên nhân | Ảnh hưởng M1 | Blocker |
|---|---|---|---|---|---|
| G1 | Origin event của defacl `FOR ROLE postgres` không truy được ngoài registry | source gap | catalog không lưu provenance; kênh Dashboard/bootstrap không log vào registry | Không — remediation độc lập origin | NO |
| G2 | Anon-read consumer-proof (bảng nào thật sự cần anon SELECT) | production evidence gap | chưa trace frontend/PostgREST read paths per-table | Chặn **existing-object sweep**, không chặn ADP milestone | NO cho M1-ADP |
| G3 | "TRUNCATE 62/88" historical không tái lập (live 60/53) | P3 debt | phương pháp đếm E3 không ghi lại | Không | NO |
| G4 | `net.*` function EXECUTE surface chưa enumerate | access/effort gap | ngoài minimal scope session | 1 query bổ sung đầu M1 | NO |
| G5 | Lovable dirty-state không observable qua MCP | access gap | MCP không expose working tree | Không (tip = accepted) | NO |
| G6 | 4 rows `supabase_admin` bất khả tự remediate | governance decision | postgres thiếu membership | Cần D-M1-a trước M2 | NO cho M1 design |
| G7 | Dynamic-SQL writers (nếu có) không phát hiện được bằng prosrc scan | source gap | phương pháp tĩnh | Thấp (0 EXECUTE-string hit các target) | NO |

Zero traffic / thời gian trôi **không** được dùng làm proof ở bất kỳ finding nào phía trên.

## 11. Stop-gate assessment

- Stop-gate mới: **KHÔNG**.
- User-JWT containment drift: **KHÔNG** (target relacl byte-identical RM1; 0 anon function; 0 PUBLIC grant).
- PUBLIC/anon/authenticated effective write ngoài contract: **KHÔNG phát hiện mới** — write privileges tồn tại trên 51/58 bảng là trạng thái E3-documented (SG-02 blockers), RLS-gated, không vượt evidence E3; phần mở rộng duy nhất so với hồ sơ E3 là **cơ chế tương lai** (function-class DA-03) — future-mechanism, không current exposure ⇒ P1, không stop-gate.
- Trusted operational path nguy cơ bị phá bởi remediation: đã lập preservation plan đầy đủ (§7, §9.2) ⇒ điều kiện stop không kích hoạt.
- Repo truth ↔ database truth: **NHẤT QUÁN** (config.toml đúng project; registry duy nhất; 0 SQL trong repo).
- E4 sang M1: **ĐƯỢC**, theo verdict §1.
- **E3-SG-02 giữ nguyên: `CONTAINED — NOT CLOSED`.** M0 không đóng, không hứa thời điểm đóng.

## 12. Mutation attestation

code changes: 0 · documentation changes: 0 · migration changes: 0 · database mutations: 0 · schema mutations: 0 · data mutations: 0 · auth mutations: 0 · storage mutations: 0 · `GRANT`: 0 · `REVOKE`: 0 · `ALTER DEFAULT PRIVILEGES`: 0 · mutation RPC calls: 0 · actor impersonation: 0 · commit: 0 · push: 0 · deploy: 0 · canonicalization: 0.

Tool trace: `list_migrations` ×1 · `execute_sql` ×6 (5 thành công, 1 lỗi cú pháp SELECT — `regexp_matches` trong aggregate, chạy lại dạng subquery; không side effect) · Lovable `list_edits` ×1 · `list_files` ×3 · `read_file` ×1 · project docs read ×1. Toàn bộ SELECT-only.

---

**M0 VERDICT: `READY WITH EXPLICIT GAPS` — chờ CTO review.**
