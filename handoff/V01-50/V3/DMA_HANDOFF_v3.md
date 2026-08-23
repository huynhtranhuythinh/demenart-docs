# 🤝 DMA_HANDOFF_v3.md

> **Phiên:** v3 (RLS cụm **Org/People** trọn gói: READ + WRITE + escalation guard — **nghiệm thu bằng login thật 4 vai trò**)
> **Đóng phiên:** 2026-06-24 21:55 (GMT+7)
> **Naming:** DMA = nền tảng; CTAN = module đầu. Không "DMMA".

---

## 0. MỤC LỤC PHIÊN (đã làm gì)
1. Boot: đọc 00/RULES/HANDOFF_v2; audit thật trên đĩa → **SYSTEM_MAP v0.3 + RULES (D13/D14) đã ở Project Knowledge** (khớp phiên trước).
2. **Audit DB thật cụm Org/People** (1 JSON): cột/FK/policy/rls/helpers — KHÔNG đoán (D1). Phát hiện chốt: `children` KHÔNG có `school_id` (thép chờ #1); enum `profile_role` 12 giá trị.
3. **Thi công RLS theo cụm — mig 011→016** (idempotent, verify từng cái bằng số/JSON thật):
   - **011** READ org backbone: schools/classes/profiles(+same_school)/class_distributions + helper `class_school_id`.
   - **012** READ children/people: children(KHÔNG admin — D48)/enrollments/child_parents/child_transfers + helper `child_in_my_school`.
   - **013** WRITE classes/enrollments (master/sub-admin scoped) + `is_school_admin()` (non-definer).
   - **014** ROSTER WRITE: RPC `create_child_and_enroll` (atomic, né RETURNING-câm) + children UPDATE + `guard_children_protected_cols` trigger + child_parents link/unlink.
   - **015** ESCALATION-SAFE: profiles/schools WRITE + 2 trigger guard ghim cột leo thang.
   - **016** Harden grants 3 guard function (tạo sau mig 010 nên dính `anon` → revoke).
4. **Seed fixture** (`seed_001`): 1 trường + 1 lớp + master/teacher/parent + 1 trẻ + enrollment + link PH. (Bắt lỗi `has_user=false` do auth user tạo sau seed → re-link.)
5. **Lovable Chặng 2-mini**: build `/portal/rls-test` (panel test scope + nút escalation), fetch client-side (D13/D82).
6. **NGHIỆM THU BẰNG LOGIN THẬT 4 VAI TRÒ** (D2/D3) — ma trận scope + 3 banner escalation xanh (xem §2).
7. Phân loại 6 security issue Lovable (D14) — 5 nhiễu đúng thiết kế + 1 thật (Leaked Password = toggle). **KHÔNG bấm "Try to fix all".**
8. Chốt phiên: cập nhật SYSTEM_MAP v0.4 + RULES (D15/D28/D29/D30) + handoff này.

---

## 1. TRẠNG THÁI FILE — ⚠️ ĐẦU PHIÊN SAU: anh LƯU 2 file vào Project Knowledge (thay bản cũ)
- **`DMA_SYSTEM_MAP`** → **v0.4** (§6 thêm mig 011–016 + sổ helper/policy mới; §7 thêm panel test + ma trận nghiệm thu; §2/§3 ghi RLS Org/People XONG).
- **`DMA_RULES`** → thêm **D15** (re-verify grants sau mỗi definer mới), **D28** (guard-cột pattern), **D29** (RPC vì RETURNING-câm), **D30** (seed dùng `session_replication_role=replica`).
- **Không đổi:** `DMA_00_START_HERE` · `DMA_BUILD_PATH` · `DMA_05_DMWS_REFERENCE` · `DMA_A_PRD`..`DMA_G`.
> **File SQL đã chạy (lưu repo):** `001`→`016` (16 file) + `seed_001_org_people_fixture.sql` — đều idempotent.

---

## 2. ⭐ NGHIỆM THU CỤM ORG/PEOPLE (bằng chứng thật — login 4 vai trò)

**Ma trận scope (count theo RLS, ảnh thật `/portal/rls-test`):**

| Login | schools | classes | children | enrollments | profiles | child_parents |
|---|---|---|---|---|---|---|
| `info@` (super_admin) | 1 | 1 | **0** ⭐ | 0 | 4 | 0 |
| `master.demo` (master_admin) | 1 | 1 | 1 | 1 | 2 | 1 |
| `teacher.demo` (lead_teacher) | 1 | 1 | 1 | 1 | 2 | 1 |
| `parent.demo` (primary_parent) | **0** ⭐ | **0** ⭐ | 1 | 1 | 1 | 1 |

**2 phép thử linh hồn ĐẠT:** ⭐ admin thấy **0 trẻ** (D48 — không xem PII trẻ); ⭐ parent thấy **0 trường/lớp nhưng 1 trẻ** (D40 — nhật ký treo vào trẻ, không qua trường).

**Escalation guard ĐẠT — 3 banner xanh:** parent/master/teacher bấm "tự nâng lên super_admin" → vai trò **giữ nguyên** (trigger guard mig 015 ghim cột). RLS không khóa cột, guard bịt đúng mặt nguy hiểm.

→ **READ + WRITE + escalation guard cụm Org/People: nghiệm thu trọn.**

---

## 3. ⭐ TRẠNG THÁI THẬT (DB + App)
- **DB:** 44 bảng · **22 hàm SECURITY DEFINER** (16 cũ gồm `rls_auto_enable` + 6 mới: `class_school_id`, `child_in_my_school`, `create_child_and_enroll`, 3 guard) · **1 hàm non-definer** `is_school_admin` · **30 RLS policy** (4 cũ mig 009 + 26 mới). Idempotent, tested trên `dma`.
- **RLS theo cụm:**
  - ✅ **Org/People XONG** (8 bảng: schools/classes/profiles/class_distributions/children/enrollments/child_parents/child_transfers).
  - ⏳ **Hoãn cố ý:** `child_duplicates` (admin-ops + sensitive access D48) · DELETE phần lớn bảng (soft-delete qua `state`).
  - 🔒 **~36 bảng còn lại CHƯA policy → khóa kín** (curriculum, sessions, media, journey, privacy, business, ops). Việc lớn phía trước.
- **App:** `/` landing · `/auth` · `_authenticated` gate · `/portal` (1 cổng gộp) · `/portal/modules` (Trung Tâm Tra Cứu) · **`/portal/rls-test`** (panel test — internal). 4 user thật chạy được.
- **Test users (xoá/đổi pass trước khi lên thật):** `info@` super_admin · `master.demo`/`teacher.demo`/`parent.demo` = `DemoDMA2026!`.

---

## 4. OPEN ITEMS
- **RLS ~36 bảng còn lại** theo cụm: Curriculum → Sessions → Media → Journey/Privacy → Business → Ops (việc chính).
- **`child_duplicates`** + sensitive-access pipeline (Edge `request_sensitive_access`) — khi làm admin-ops/D48.
- **Trường đọc profile PH:** hiện school-admin KHÔNG thấy profile PH (parent `school_id` NULL). Cần policy nhỏ "trường thấy PH của trẻ trong trường" khi build màn liên hệ PH.
- **Leaked Password Protection** — anh bật ở Auth → Attack Protection (1 toggle; KHÔNG sửa bằng code).
- **DELETE policies** + activation flow (set `user_id` cho profile) — RPC riêng sau.
- **Tách 4 portal** (`/admin /school /teacher /parent`) — khi mỗi portal có nội dung.
- **5 security issue nhiễu Lovable** — bỏ qua, ĐỪNG "Try to fix all" (D14).
- Giá thật `pricing_config`; `assistant_consumes_seat` default; permission catalog Sub-Admin; consent 2 tầng; deploy target — chốt Chặng 8.

---

## 5. ⭐ NEXT ACTION (đầu phiên sau)
1. Anh lưu **SYSTEM_MAP v0.4 + RULES** vào Project Knowledge.
2. **Audit cột `programs` + cụm Curriculum thật** (D1) → viết RLS cụm Curriculum theo cụm → test (programs là TOÀN CỤC D40: admin write, mọi authenticated read).
3. Hoặc: **Build UI Chặng 2 thật** (CRUD trường/lớp/trẻ qua RPC `create_child_and_enroll`) để rời panel-test sang màn vận hành.

---

## 6. BOOT phiên sau
1. Đọc `DMA_00_START_HERE` → `DMA_RULES` → file này.
2. Xác nhận SYSTEM_MAP v0.4 + RULES (D15/D28/D29/D30) đã ở Project Knowledge (audit thật — D1).
3. **Audit DB thật trước khi viết SQL** (`pg_policies`, `information_schema`, `pg_get_functiondef`): nhớ **22 hàm definer** + **30 policy** + 5 guard/trigger.
4. Vào §5. Sequencing: RLS theo cụm → test login thật (D2/D3) → Edge → UI.

---

## 7. TỰ ĐÁNH GIÁ
- **Được:** đóng trọn cụm RLS lớn nhất (Org/People) trong 1 phiên với **bằng chứng end-to-end thật** (ma trận 4 vai trò + 3 banner escalation), không chỉ "build OK"; chia migration đúng nhịp (push back tách roster/escalation ra 014/015 thay vì gộp) nên phần nguy hiểm có test riêng; verify-bằng-số bắt 2 lỗi thật (`has_user=false`; 3 guard dính `anon`) trước khi chúng thành nợ; phân loại đúng nhiễu scanner, không để Lovable đụng DB; panel test là đòn bẩy tốt để thấy RLS chạy thật.
- **Sai & sửa:** ban đầu nói "public execute đã đóng (mig 010)" — verify cho thấy hàm tạo SAU mig 010 vẫn dính `anon` → đẻ ra D15. Bài học: verify > trí nhớ.
- **Cần giữ:** SQL khối nhỏ + JSON verify cuối; chụp Plan Lovable trước Approve; không cho Lovable auto-fix DB; mỗi cụm test bằng đúng user vai trò (D2 — không test được trong SQL Editor); re-verify grants sau mỗi definer mới (D15).
- **Lưu ý phiên sau:** RLS Curriculum khác Org/People — `programs` TOÀN CỤC (đọc rộng, write hẹp); `lesson_versions` bất biến (D43); coi chừng RETURNING-câm khi bảng có policy SELECT hẹp (D29).
