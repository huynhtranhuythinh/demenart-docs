# V128-B2.0 — OBJECT REGISTRY FOUNDATION — IMPLEMENTATION PACKAGE

> **Loại:** MIGRATION DESIGN ONLY. **KHÔNG execute · KHÔNG apply · KHÔNG build.** SQL dưới đây là DRAFT để review, chưa chạy.
> **Vai:** Claude = Database Architect + Security Reviewer · ChatGPT = CTO/CPO approval.
> **Canonical:** D348 · SYSTEM_MAP v1.36 · HANDOFF V128-M0 · HEAD `be04f4b` · baseline FROZEN 89·233·222·166·33·1 · tail `20260810074214`.
> **Scope:** tạo `mission_control_object_registry` + seed. KHÔNG đụng bảng cũ · KHÔNG RLS policy · KHÔNG grant application-permission · KHÔNG role mới.

---

## 0. SECURITY POSTURE (Security Reviewer — chốt trước SQL)

1. **Catalog-only.** Bảng chỉ chứa *dữ liệu khai báo*. KHÔNG logic, KHÔNG chạy được gì.
2. **KHÔNG cột function-name.** Không có cột nào lưu tên RPC dạng string. Chỉ `projector_status` (`wired|registered|none`). Mapping `type → projector RPC` sống trong **CASE tường minh của `get_object_workspace`** (B2.1) — code review được, KHÔNG `EXECUTE format(...)`. → **0 dynamic-execution / injection surface.**
3. **Forbidden khai báo tường minh.** 6 forbidden type có mặt trong seed với `kind='forbidden'` + `projector_status='none'` + `privacy_policy='restricted'` + `forbidden_groups={*}`. Defense-in-depth: adapter reject bằng dữ liệu, không dựa vào "vắng mặt".
4. **Least privilege.** ACL: REVOKE client roles (anon/authenticated/PUBLIC); đọc chỉ qua SECURITY DEFINER adapter (owner postgres) → client KHÔNG SELECT trực tiếp.
5. **Config-driven, migration-owned (D11 + #6).** Mọi thay đổi catalog đi qua migration; KHÔNG INSERT/UPDATE runtime từ app.

> **⚠️ RLS decision (flag cho Owner):** package này theo đúng constraint *"No RLS changes"* → **KHÔNG bật RLS**, khóa bằng **table ACL** (client roles không có SELECT grant → PostgREST không expose). Điều này an toàn (không có grant thì không truy cập được). **DMA convention (D14)** thường bật `ENABLE ROW LEVEL SECURITY` deny-by-default cho bảng mới như belt-and-suspenders; đó là *thêm* RLS cho bảng mới (không phải "đổi" RLS hệ thống). Em **khuyến nghị bật** nhưng **để mặc định TẮT** trong draft này để tuân chặt yêu cầu — Owner quyết 1 dòng `ENABLE RLS` có thêm hay không.

---

## 1. COLUMN JUSTIFICATION

| Cột | Kiểu | Vì sao | Ghi chú an ninh |
|---|---|---|---|
| `object_type` | `text` PK | Khóa định danh ổn định; là địa chỉ `/admin/object/<type>/<id>`; adapter dispatch theo nó | `text` (không enum) để catalog data-extensible không cần `ALTER TYPE` |
| `kind` | `text` NOT NULL | Phân loại `core\|supporting\|future\|forbidden` — quyết định có projectable | CHECK IN; drives forbidden reject |
| `scope` | `text` NULL | Predicate phạm vi `platform\|tenant\|assignment`; NULL cho forbidden (n/a) | CHECK (NULL hoặc IN); non-forbidden bắt buộc NOT NULL |
| `privacy_policy` | `text` NOT NULL | `open\|reason_required\|restricted` — kỷ luật truy cập | reason_required→D345.2; restricted→forbidden/capsule |
| `projector_status` | `text` NOT NULL | `wired\|registered\|none` — cờ triển khai. **KHÔNG phải tên hàm** | Không executable; dispatch ở adapter CASE |
| `discovery_fields` | `text[]` NOT NULL DEFAULT `{}` | Field identity an toàn phát trong candidate (resolver đọc) | Rỗng cho forbidden → không phát gì |
| `forbidden_groups` | `text[]` NOT NULL DEFAULT `{}` | Nhóm field projector PHẢI drop (privacy-by-source, D347.3) | `{*}` cho forbidden = drop tất |
| `capability_vocab` | `jsonb` NOT NULL DEFAULT `{}` | Từ vựng `{view,edit,assign,archive,export : perm-string\|null}` — adapter đọc để biết gọi `has_permission(perm)` nào | **Vocabulary, KHÔNG grant.** `null`=view scope-gated, không cần perm riêng |
| `sort_order` | `int` NOT NULL DEFAULT 100 | Thứ tự hiển thị ổn định | — |
| `notes` | `text` NULL | Tài liệu người đọc (mô tả object). **KHÔNG chứa tên hàm executable** | Documentation only |
| `created_at` | `timestamptz` NOT NULL DEFAULT now() | Audit | — |
| `updated_at` | `timestamptz` NOT NULL DEFAULT now() | Audit | — |

---

## 2. INDEXES

**Chỉ PK index (unique trên `object_type`).** Catalog **<50 dòng** (seed 17) → seq scan rẻ hơn maintain index phụ. **KHÔNG over-index** (không tạo index trên `kind`/`projector_status` — không justify ở scale này). Nếu sau này catalog phình >vài trăm dòng mới cân nhắc.

---

## 3. CONSTRAINTS

- PK `(object_type)`.
- `kind` CHECK IN `(core,supporting,future,forbidden)`.
- `scope` CHECK `(scope IS NULL OR scope IN (platform,tenant,assignment))`.
- `privacy_policy` CHECK IN `(open,reason_required,restricted)`.
- `projector_status` CHECK IN `(wired,registered,none)`.
- **Semantic CHECKs (defense-in-depth):**
  - `kind='forbidden' OR scope IS NOT NULL` — non-forbidden phải có scope.
  - `kind<>'forbidden' OR projector_status='none'` — forbidden KHÔNG được có projector.
  - `kind<>'forbidden' OR privacy_policy='restricted'` — forbidden phải restricted.

---

## 4. MIGRATION DRAFT (D92 three-block · DO NOT APPLY)

**Tên migration:** `v128_b2_0_mission_control_object_registry`

```sql
-- ═══════════════════════════════════════════════════════════════════
-- V128-B2.0 · mission_control_object_registry (catalog-only, 0 behavior)
-- BLOCK 1 — DDL + SEED
-- ═══════════════════════════════════════════════════════════════════
CREATE TABLE public.mission_control_object_registry (
  object_type       text PRIMARY KEY,
  kind              text        NOT NULL,
  scope             text,
  privacy_policy    text        NOT NULL,
  projector_status  text        NOT NULL,
  discovery_fields  text[]      NOT NULL DEFAULT '{}',
  forbidden_groups  text[]      NOT NULL DEFAULT '{}',
  capability_vocab  jsonb       NOT NULL DEFAULT '{}'::jsonb,
  sort_order        integer     NOT NULL DEFAULT 100,
  notes             text,
  created_at        timestamptz NOT NULL DEFAULT now(),
  updated_at        timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT mcor_kind_chk      CHECK (kind IN ('core','supporting','future','forbidden')),
  CONSTRAINT mcor_scope_chk     CHECK (scope IS NULL OR scope IN ('platform','tenant','assignment')),
  CONSTRAINT mcor_privacy_chk   CHECK (privacy_policy IN ('open','reason_required','restricted')),
  CONSTRAINT mcor_projstat_chk  CHECK (projector_status IN ('wired','registered','none')),
  CONSTRAINT mcor_scope_req_chk CHECK (kind = 'forbidden' OR scope IS NOT NULL),
  CONSTRAINT mcor_forbidden_noproj_chk  CHECK (kind <> 'forbidden' OR projector_status = 'none'),
  CONSTRAINT mcor_forbidden_restrict_chk CHECK (kind <> 'forbidden' OR privacy_policy = 'restricted')
);

COMMENT ON TABLE public.mission_control_object_registry IS
  'V128-B2.0 catalog-only. Type→projector dispatch lives in get_object_workspace CASE, NOT here. No executable strings.';

-- SEED (17 rows) — data only
INSERT INTO public.mission_control_object_registry
  (object_type, kind, scope, privacy_policy, projector_status, discovery_fields, forbidden_groups, capability_vocab, sort_order, notes)
VALUES
-- ── WIRED (B2.1 dispatch) ──────────────────────────────────────────
('person','core','platform','open','wired',
   ARRAY['full_name','email','role','state'], '{}',
   '{"view":null,"edit":"person.edit","assign":"teacher.activate","archive":"person.archive","export":"person.export"}'::jsonb,
   10,'Identity/account — teacher/parent/admin. Platform: admin_lookup_user; tenant: get_person_workspace.'),
('child','core','platform','reason_required','wired',
   ARRAY['full_name','nickname','state'],
   ARRAY['journal_summary','evidence','readiness','capsules','parent_memory','memory_conversation'],
   '{"view":null,"edit":"child.edit","archive":"child.archive"}'::jsonb,
   20,'Operational only; reason-logged (D345.2). Meaning/family layers dropped (LINH HON / D347.3).'),
('media','supporting','platform','open','wired',
   ARRAY['file_type','state'], ARRAY['raw_bytes','signed_url'],
   '{"view":null,"archive":"media.archive"}'::jsonb,
   30,'Media asset metadata only; never bytes/URL.'),
('capsule','supporting','platform','restricted','wired',
   ARRAY['scope','domain','window_code'], ARRAY['items'],
   '{"view":null}'::jsonb,
   40,'Discovery capsule — integrity metadata only; items (meaning-content) forbidden.'),
-- ── REGISTERED (projector B2.2/P2/P3, adapter returns not_available) ─
('school','core','tenant','open','registered',
   ARRAY['name','status'], '{}',
   '{"view":null,"edit":"school.edit","archive":"school.archive","export":"school.export"}'::jsonb,
   50,'Tenant root (B2.2).'),
('subscription','core','platform','open','registered',
   ARRAY['plan','status'], '{}',
   '{"view":null,"edit":"subscription.edit","export":"subscription.export"}'::jsonb,
   60,'Commercial control surface (B2.2).'),
('support_case','core','platform','open','registered',
   ARRAY['subject','status'], '{}',
   '{"view":null,"edit":"support.edit","assign":"support.assign"}'::jsonb,
   70,'Ops triage (B2.2).'),
('class','core','tenant','open','registered',
   ARRAY['name'], '{}',
   '{"view":null,"edit":"class.edit","assign":"class.assign"}'::jsonb,
   80,'Operational unit (P2).'),
('session','supporting','assignment','open','registered',
   '{}', '{}', '{"view":null}'::jsonb,
   90,'Lesson session (P3).'),
('program','supporting','platform','open','registered',
   ARRAY['name'], '{}', '{"view":null,"edit":"program.edit"}'::jsonb,
   100,'Curriculum/program (P3).'),
('privacy_request','supporting','platform','open','registered',
   ARRAY['status'], '{}', '{"view":null,"edit":"privacy.edit"}'::jsonb,
   110,'Compliance queue (P3).'),
-- ── FORBIDDEN (never a Mission Control object) ──────────────────────
('child_journey','forbidden',NULL,'restricted','none','{}',ARRAY['*'],'{}'::jsonb,900,'FORBIDDEN — child-owned (LINH HON / D347.3).'),
('journal','forbidden',NULL,'restricted','none','{}',ARRAY['*'],'{}'::jsonb,910,'FORBIDDEN — child journal content.'),
('skills','forbidden',NULL,'restricted','none','{}',ARRAY['*'],'{}'::jsonb,920,'FORBIDDEN — child skills/assessment.'),
('badges','forbidden',NULL,'restricted','none','{}',ARRAY['*'],'{}'::jsonb,930,'FORBIDDEN — child badges.'),
('family_memory','forbidden',NULL,'restricted','none','{}',ARRAY['*'],'{}'::jsonb,940,'FORBIDDEN — family-owned memory content.'),
('raw_media','forbidden',NULL,'restricted','none','{}',ARRAY['*'],'{}'::jsonb,950,'FORBIDDEN — raw bytes/signed URL never browsable.');

-- ═══════════════════════════════════════════════════════════════════
-- BLOCK 2 — ACL HARDENING (D15 / D231)
-- ═══════════════════════════════════════════════════════════════════
-- D231 trap: ALTER DEFAULT PRIVILEGES auto-grants to anon/authenticated/service_role
-- on new tables → REVOKE FROM PUBLIC KHÔNG đủ; phải REVOKE tường minh client roles.
REVOKE ALL ON public.mission_control_object_registry FROM PUBLIC;
REVOKE ALL ON public.mission_control_object_registry FROM anon;
REVOKE ALL ON public.mission_control_object_registry FROM authenticated;
-- Owner (postgres) giữ full → SECURITY DEFINER adapter (B2.1) đọc được.
-- service_role: đọc-only cho backend tooling (ACL, KHÔNG phải application-permission).
GRANT SELECT ON public.mission_control_object_registry TO service_role;

-- (RLS: KHÔNG bật trong draft — xem §0 flag. Nếu Owner duyệt belt-and-suspenders:
--  ALTER TABLE public.mission_control_object_registry ENABLE ROW LEVEL SECURITY;  -- deny-by-default, no policy)

-- PostgREST cache reload (D289)
NOTIFY pgrst, 'reload schema';

-- ═══════════════════════════════════════════════════════════════════
-- BLOCK 3 — VERIFY (RAISE = atomic rollback guard nếu sai)
-- ═══════════════════════════════════════════════════════════════════
DO $verify$
DECLARE
  v_total int; v_wired int; v_registered int; v_forbidden int;
  v_bad_forbidden int; v_bad_scope int; v_anon_priv boolean; v_auth_priv boolean;
BEGIN
  SELECT count(*) INTO v_total FROM public.mission_control_object_registry;
  SELECT count(*) INTO v_wired      FROM public.mission_control_object_registry WHERE projector_status='wired';
  SELECT count(*) INTO v_registered FROM public.mission_control_object_registry WHERE projector_status='registered';
  SELECT count(*) INTO v_forbidden  FROM public.mission_control_object_registry WHERE kind='forbidden';
  -- forbidden phải: projector_status='none' AND privacy='restricted' AND scope NULL AND forbidden_groups={'*'}
  SELECT count(*) INTO v_bad_forbidden FROM public.mission_control_object_registry
    WHERE kind='forbidden' AND NOT (projector_status='none' AND privacy_policy='restricted'
          AND scope IS NULL AND forbidden_groups = ARRAY['*']);
  -- non-forbidden phải có scope
  SELECT count(*) INTO v_bad_scope FROM public.mission_control_object_registry
    WHERE kind<>'forbidden' AND scope IS NULL;
  -- ACL: client roles KHÔNG có SELECT
  v_anon_priv := has_table_privilege('anon','public.mission_control_object_registry','SELECT');
  v_auth_priv := has_table_privilege('authenticated','public.mission_control_object_registry','SELECT');

  IF v_total <> 17 THEN RAISE EXCEPTION 'SEED_COUNT_FAIL: % (expect 17)', v_total; END IF;
  IF v_wired <> 4 THEN RAISE EXCEPTION 'WIRED_FAIL: % (expect 4)', v_wired; END IF;
  IF v_registered <> 7 THEN RAISE EXCEPTION 'REGISTERED_FAIL: % (expect 7)', v_registered; END IF;
  IF v_forbidden <> 6 THEN RAISE EXCEPTION 'FORBIDDEN_FAIL: % (expect 6)', v_forbidden; END IF;
  IF v_bad_forbidden <> 0 THEN RAISE EXCEPTION 'FORBIDDEN_SHAPE_FAIL: % rows', v_bad_forbidden; END IF;
  IF v_bad_scope <> 0 THEN RAISE EXCEPTION 'SCOPE_REQUIRED_FAIL: % rows', v_bad_scope; END IF;
  IF v_anon_priv THEN RAISE EXCEPTION 'ACL_FAIL: anon has SELECT'; END IF;
  IF v_auth_priv THEN RAISE EXCEPTION 'ACL_FAIL: authenticated has SELECT'; END IF;

  RAISE NOTICE 'V128-B2.0 VERIFY OK: 17 rows (4 wired / 7 registered / 6 forbidden), ACL locked.';
END $verify$;
```

---

## 5. SEED STRATEGY

- **Idempotency:** seed nằm TRONG migration tạo bảng → chạy đúng 1 lần cùng DDL (bảng mới, không tồn tại trước). KHÔNG cần `ON CONFLICT`. Nếu muốn re-seedable độc lập sau này → tách seed thành migration riêng với `INSERT ... ON CONFLICT (object_type) DO UPDATE`.
- **Data, không logic:** thuần INSERT VALUES.
- **Thay đổi tương lai** (thêm object / đổi projector_status wired) = **migration mới** (config-driven #6, schema-ownership D11) — KHÔNG UPDATE runtime từ app.

---

## 6. ACL PLAN (tóm tắt)

| Role | Trước (default privilege trap D231) | Sau BLOCK 2 |
|---|---|---|
| PUBLIC | (implicit) | REVOKE ALL |
| anon | auto-SELECT (D231) | **REVOKE ALL** → 0 |
| authenticated | auto-SELECT (D231) | **REVOKE ALL** → 0 |
| service_role | auto | GRANT SELECT (backend read; ACL, không phải app-permission) |
| postgres (owner) | full | full → SECURITY DEFINER adapter đọc |

- **KHÔNG grant application-permission** (không đụng `profiles.permissions[]`). `capability_vocab` chỉ là *từ vựng*.
- **KHÔNG role mới.** Chỉ dùng role sẵn có.
- Verify anon/authenticated `has_table_privilege = false` (BLOCK 3).

---

## 7. ROLLBACK SQL

```sql
-- V128-B2.0 rollback — additive DB, sạch tuyệt đối
DROP TABLE IF EXISTS public.mission_control_object_registry;  -- 0 FK ref, không cascade gì
NOTIFY pgrst, 'reload schema';
```

- Bảng **không được reference bởi bất kỳ FK/hàm nào** ở B2.0 (adapter B2.1 chưa tồn tại) → DROP sạch, zero residue.
- Baseline về `be04f4b` / tail `20260810074214`. FE/renderer/RLS/5-RPC-target **không đụng** → không cần rollback.
- `apply_migration` transactional: nếu BLOCK 3 RAISE → toàn migration rollback nguyên tử, **không ghi** `schema_migrations`.

---

## 8. VERIFICATION QUERIES (post-apply, read-only)

```sql
-- (V1) Cấu trúc bảng + constraints
SELECT column_name, data_type, is_nullable
FROM information_schema.columns
WHERE table_schema='public' AND table_name='mission_control_object_registry'
ORDER BY ordinal_position;

SELECT conname, pg_get_constraintdef(oid)
FROM pg_constraint
WHERE conrelid='public.mission_control_object_registry'::regclass ORDER BY conname;

-- (V2) Seed integrity
SELECT projector_status, count(*) FROM public.mission_control_object_registry GROUP BY 1;  -- wired 4 / registered 7 / none 6
SELECT kind, count(*) FROM public.mission_control_object_registry GROUP BY 1;              -- core 6 / supporting 5 / forbidden 6

-- (V3) Forbidden shape (defense-in-depth)
SELECT object_type FROM public.mission_control_object_registry
WHERE kind='forbidden' AND NOT (projector_status='none' AND privacy_policy='restricted'
      AND scope IS NULL AND forbidden_groups=ARRAY['*']);   -- kỳ vọng 0 dòng

-- (V4) Non-forbidden phải có scope
SELECT object_type FROM public.mission_control_object_registry
WHERE kind<>'forbidden' AND scope IS NULL;                  -- kỳ vọng 0 dòng

-- (V5) ACL — client roles KHÔNG SELECT
SELECT
  has_table_privilege('anon','public.mission_control_object_registry','SELECT')          AS anon_select,
  has_table_privilege('authenticated','public.mission_control_object_registry','SELECT') AS auth_select;
  -- kỳ vọng: false, false

-- (V6) Baseline vẫn frozen (bảng mới +1)
SELECT count(*) FROM pg_tables WHERE schemaname='public';   -- 89 → 90 (chỉ +registry)

-- (V7) Không có cột executable-string (an ninh) — xác nhận schema không lưu tên hàm
SELECT column_name FROM information_schema.columns
WHERE table_schema='public' AND table_name='mission_control_object_registry'
  AND column_name ~* '(projector|function|rpc|exec)';        -- kỳ vọng: chỉ 'projector_status' (flag, không phải tên hàm)
```

---

## 9. IMPACT / DELTA (khi apply — CHƯA apply)

- DB: **+1 table** (`mission_control_object_registry`, 17 seed rows) · **0 function/policy/trigger/RLS/Edge** · **0 application-permission** · **0 role**.
- Inventory sau apply: **90 tables** · 233 functions · 222 secdef · 166 policies · 33 triggers · 1 cron · 16 Edge.
- FE / renderer / 5 wrap-target RPC: **BẤT BIẾN.**
- Migration tail sẽ `20260810074214` → `<new>` (chỉ khi apply).

---

## 10. CONSTRAINT COMPLIANCE

| Yêu cầu | Tuân thủ |
|---|---|
| 1. Migration design only | ✓ draft, chưa apply |
| 2. No execution | ✓ không gọi `apply_migration` |
| 3. No existing table changes | ✓ chỉ CREATE table mới |
| 4. No RLS changes | ✓ không thêm/sửa policy (RLS-enable để flag Owner, mặc định không có trong draft) |
| 5. No permission grants | ✓ không đụng `profiles.permissions[]`; `capability_vocab` = vocabulary; service_role SELECT = table-ACL (đã tách nghĩa) |
| 6. No role changes | ✓ dùng role sẵn có |
| Catalog only | ✓ data, 0 logic |
| No dynamic function execution | ✓ không cột function-name; dispatch = adapter CASE (B2.1) |
| No projector names as executable strings | ✓ chỉ `projector_status` flag |
| Forbidden explicitly declared | ✓ 6 forbidden rows, kind='forbidden' + none + restricted + {*} |

**END V128-B2.0 IMPLEMENTATION PACKAGE — DRAFT ONLY · DO NOT APPLY · DO NOT BUILD.**
