# 🤝 DMA_HANDOFF_v4.md

> **Phiên:** v4 (RLS cụm **Curriculum** trọn gói: catalog member-read/admin-write + `lesson_versions` immutable + `ideas` scoped — **nghiệm thu bằng login thật 4 vai trò**)
> **Đóng phiên:** 2026-06-24 22:32 (GMT+7)
> **Naming:** DMA = nền tảng; CTAN = module đầu. Không "DMMA".

---

## 0. MỤC LỤC PHIÊN (đã làm gì)
1. Boot: đọc 00/RULES/HANDOFF_v3 + audit thật trên đĩa → SYSTEM_MAP v0.4 + RULES (D15/D28/D29/D30) khớp phiên trước, Project Knowledge không tụt.
2. Chọn hướng: **RLS cụm Curriculum**.
3. **Audit DB thật cụm Curriculum** (1 JSON, sửa 2 lần lỗi cú pháp `sql_identifier` → unnest+IN): 9 bảng, RLS bật/0 policy, enum (content_state/distribution_type/idea_state), helper sẵn (is_admin/current_profile/current_profile_role/same_school/is_school_admin), trigger `lesson_version_autoincrement` có. Phát hiện: `ideas` lệch cụm (có `school_id`+`proposer`).
4. **Chốt thiết kế (1 ngã rẽ):** ai đọc kho? → **Cách 2** (admin + thành viên trường, KHÔNG PH) để bảo vệ IP premium (D65).
5. **Thi công mig 017** (26 policy + helper `current_school_id`): catalog member-read/admin-write · lesson_versions no-UPDATE (immutable) · ideas scoped. Verify JSON: 26 policy đúng từng bảng, helper secdef=true, D15 leak=[].
6. **Seed `seed_002_curriculum_fixture`** (kho rỗng → phải seed): CTAN+Ballet + chuỗi catalog + 2 lesson_versions (version_no=[1,1] ⭐ trigger chạy) + 2 distributions + 2 items + 1 idea.
7. **Lovable**: thêm section "Kho giáo trình (Curriculum)" vào `/portal/rls-test` (4 count card + 1 write-block test). Fetch client-side D13/D82. KHÔNG "Try to fix all".
8. **NGHIỆM THU BẰNG LOGIN THẬT 4 VAI TRÒ** — ma trận READ + banner WRITE chặn (xem §2).
9. Chốt phiên: SYSTEM_MAP v0.5 + RULES (D52 + helper) + handoff này.

---

## 1. TRẠNG THÁI FILE — ⚠️ ĐẦU PHIÊN SAU: anh LƯU 2 file vào Project Knowledge (thay bản cũ)
- **`DMA_SYSTEM_MAP`** → **v0.5** (§3 Curriculum/Idea = ✅ XONG; §6 thêm mig 017 + seed_002, definer=23, policy=56, bước kế=Sessions; §7 panel thêm mục Curriculum + nghiệm thu v4).
- **`DMA_RULES`** → thêm **D52** (RLS cụm Curriculum) + helper `current_school_id()` vào D23.
- **Không đổi:** `DMA_00_START_HERE` · `DMA_BUILD_PATH` · `DMA_05_DMWS_REFERENCE` · `DMA_A_PRD`..`DMA_G`.
> **File SQL đã chạy (lưu repo):** `001`→`017` (17 file) + `seed_001` + `seed_002` — đều idempotent.

---

## 2. ⭐ NGHIỆM THU CỤM CURRICULUM (bằng chứng thật — login 4 vai trò)

**Ma trận READ (count theo RLS, ảnh thật `/portal/rls-test` mục Curriculum):**

| Login | programs | lessons | distributions | ideas |
|---|---|---|---|---|
| `info@` (super_admin) | 2 | 2 | 2 | 1 |
| `master.demo` (master_admin) | 2 | 2 | 2 | 1 |
| `teacher.demo` (lead_teacher) | 2 | 2 | 2 | 1 |
| `parent.demo` (primary_parent) | **0** ⭐ | **0** | **0** | **0** |

**Phép thử linh hồn ĐẠT:** ⭐ parent thấy **0 chương trình** — kho giáo trình premium ĐÓNG với phụ huynh (D52/D65). `ideas`=1 cho cả teacher VÀ master (cùng trường) nhưng 0 cho parent → policy `ideas_select_scoped` chạy đúng (scoped theo TRƯỜNG, khác 8 bảng catalog toàn cục).

**WRITE chặn ĐẠT — banner xanh:** `teacher.demo` bấm "Thử thêm 1 program" → banner xanh "✓ ĐÚNG: RLS chặn ghi" + lỗi DB thật `new row violates row-level security policy for table "programs"`. Non-admin bị `WITH CHECK is_admin()` từ chối ở tầng DB.

→ **READ + WRITE cụm Curriculum: nghiệm thu trọn.**

---

## 3. ⭐ TRẠNG THÁI THẬT (DB + App)
- **DB:** 44 bảng · **23 hàm SECURITY DEFINER** (22 cũ + `current_school_id`) · **1 non-definer** `is_school_admin` · **56 RLS policy** (30 cũ + 26 mig 017). Idempotent, tested trên `dma`.
- **RLS theo cụm:**
  - ✅ **Org/People XONG** (8 bảng — mig 011–016).
  - ✅ **Curriculum XONG** (9 bảng — mig 017): catalog member-read/admin-write · lesson_versions immutable (no UPDATE policy) · ideas scoped.
  - ⏳ **Hoãn cố ý:** `child_duplicates` (admin-ops) · DELETE phần lớn bảng (soft-delete qua `state`) · entitlement-gate đọc catalog (V1 chưa, business cluster sau).
  - 🔒 **~28 bảng còn lại CHƯA policy → khóa kín** (sessions, media, journey, privacy, business, ops). Việc lớn phía trước.
- **App:** `/` landing · `/auth` · `_authenticated` · `/portal` · `/portal/modules` · **`/portal/rls-test`** (panel test — giờ có Org/People + escalation + Curriculum + write-block). 4 user thật chạy được.
- **Seed kho:** 2 program (CTAN slug=`ctan`, Ballet slug=`ballet`), lessons slug `ctan-bai-1`/`ballet-bai-1`, 1 idea "Thêm bài hát dân ca vào CTAN".
- **Test users (xoá/đổi pass trước khi lên thật):** `info@` super_admin · `master.demo`/`teacher.demo`/`parent.demo` = `DemoDMA2026!`.

---

## 4. OPEN ITEMS
- **RLS ~28 bảng còn lại** theo cụm: **Sessions** (kế) → Media → Journey/Privacy → Business → Ops.
  - Sessions phức tạp hơn Curriculum: scope theo lead (`class_distributions.lead_teacher_id`) / assistant (`session_teachers`) — D45. Helper sẵn `is_distribution_lead()`, `is_session_teacher()` (chưa audit signature thật — D1 trước khi dùng).
- **Trường đọc profile PH:** school-admin chưa thấy profile PH (parent `school_id` NULL). Policy nhỏ "trường thấy PH của trẻ trong trường" khi build màn liên hệ PH.
- **`child_duplicates`** + sensitive-access pipeline (Edge `request_sensitive_access`) — khi làm admin-ops/D48.
- **Leaked Password Protection** — anh bật ở Auth → Attack Protection (toggle; KHÔNG code).
- **DELETE policies** + activation flow (set `user_id`) — RPC riêng sau.
- **Tách 4 portal** (`/admin /school /teacher /parent`) — khi mỗi portal có nội dung.
- **6 security issue Lovable** — bỏ qua, ĐỪNG "Try to fix all" (D14).
- Giá thật `pricing_config`; permission catalog Sub-Admin; consent 2 tầng; deploy target — chốt Chặng 8.

---

## 5. ⭐ NEXT ACTION (đầu phiên sau)
1. Anh lưu **SYSTEM_MAP v0.5 + RULES** vào Project Knowledge.
2. **Audit cụm Sessions thật** (D1): `lesson_sessions` · `session_teachers` · `session_media` · `session_reports` · `child_observations` (+ xác nhận signature `is_distribution_lead`/`is_session_teacher`) → viết RLS cụm Sessions theo cụm → test login thật.
3. Hoặc: **Build UI Chặng 2 thật** (CRUD trường/lớp/trẻ qua RPC `create_child_and_enroll`) rời panel-test sang màn vận hành.

---

## 6. BOOT phiên sau
1. Đọc `DMA_00_START_HERE` → `DMA_RULES` → file này.
2. Xác nhận SYSTEM_MAP v0.5 + RULES (D52 + `current_school_id`) đã ở Project Knowledge (audit thật — D1).
3. **Audit DB thật trước khi viết SQL** (`pg_policies`, `information_schema`, `pg_get_functiondef`): nhớ **23 hàm definer** + **56 policy** + guard/trigger.
4. Vào §5. Sequencing: RLS theo cụm → test login thật (D2/D3) → Edge → UI.

---

## 7. TỰ ĐÁNH GIÁ
- **Được:** đóng trọn cụm RLS thứ 2 (Curriculum) trong 1 phiên với bằng chứng end-to-end (ma trận READ 4 vai trò + banner WRITE chặn DB thật); bắt sớm 2 cái bẫy trước khi viết — (a) `ideas` lệch cụm nên tách policy riêng thay vì gộp mù; (b) kho rỗng → count 0 vô nghĩa nên seed TRƯỚC khi nghiệm thu, không để "0 vì chặn hay 0 vì rỗng" làm mờ kết quả; chốt 1 ngã rẽ thật (PH đọc kho?) bằng multiple-choice thay vì tự quyết; verify-bằng-JSON từng bảng nên không bị tổng-nhẩm-sai che lỗi.
- **Sai & sửa:** (1) audit query lỗi `sql_identifier = text[]` 2 lần — fix bằng unnest+IN; bài học: domain type của `information_schema` không so trực tiếp text[]. (2) Lúc nêu kỳ vọng ghi "29 policy" — **sai số học**, đúng là 26; JSON trả 26 khớp từng-bảng nên verify vẫn đậu. Bài học lặp lại của v3: **verify > trí nhớ (và > số học của Claude)** — luôn để JSON breakdown từng-bảng làm trọng tài, đừng tin con số tổng tự nhẩm.
- **Cần giữ:** seed trước khi test count; tách policy khi bảng lệch mô hình (ideas); D15 re-verify grant sau helper definer mới (`current_school_id` đã sạch); panel write-block test (1 nút) là đòn bẩy rẻ chứng minh WITH CHECK; chụp Plan Lovable, không auto-fix DB.
- **Lưu ý phiên sau:** Sessions KHÁC Curriculum — scope theo lead/assistant (D45), không phải member-flat; audit `is_distribution_lead`/`is_session_teacher` signature thật trước khi dùng; coi chừng RETURNING-câm khi tạo session có SELECT policy hẹp (D29); `lesson_sessions` có `content_override` (GV sửa instance, giữ lesson_version bất biến — D44).
