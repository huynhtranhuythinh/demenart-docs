# 🩰 DMA V127-M1.5-PHASE1.5 — BALLET CONTENT FOUNDATION REPORT

> **Loại:** Content foundation design + mutation package **ĐỀ XUẤT**. **KHÔNG execute · KHÔNG migration · KHÔNG canonicalize — chờ Owner Gate.**
> **Pilot:** Vườn Nghệ Thuật Dế Mèn (`VNDM-DN`) · program **Múa Ballet Dế Mèn** · Teacher **Cô Thuý Ngân** · lớp **Ballet Hạt Nắng** + **Ballet Cánh Hoa**.
> **Baseline (khớp):** RULES **D344** · SYSTEM_MAP **v1.32** · HEAD **`6b860338`** · inventory bất biến 89/215/204/166 · tail `20260807130914`.
> **Mục tiêu:** biến ballet từ *free-text observation* → *structured artistic memory* — **KHÔNG** biến DMA thành hệ chấm điểm. **Memory > Metric.**

---

## 1. VERDICT

**`CONTENT FOUNDATION DESIGN — READY (mutation package đã soạn, chờ Owner Gate) · APPLICATION + PILOT — NOT READY (chờ account + cohort)`.**

Toàn bộ hạ tầng data đã verify: skill taxonomy nối đúng cơ chế (`skills_observed` = mảng code), config đổi được không đụng schema, cohort intake sạch. **Không có defect · không cần migration/feature.** Mọi thay đổi đề xuất là **data INSERT/UPDATE vào bảng có sẵn**. Chỉ chờ Owner authorize + account cô Thuý Ngân + danh sách trẻ.

---

## 2. SKILL CATALOG PROPOSAL (Task 1)

**Cơ chế đã verify (an toàn để seed):**
- `skill_catalog(program_id, code, label_vi, sort_order, enabled)` · `code` **UNIQUE toàn cục** · FK program ON DELETE CASCADE · **0 trigger** · RLS on + 2 policy (đọc được, ctan đang chạy).
- Observation lưu **mảng CODE** vào `child_observations.skills_observed` (vd `["ctan_rhythm","ctan_move"]`); `child_skills(skill, signal_count)` roll-up. → Seed catalog `ballet_*` là frontend render tag → cô tap → code ghi vào observation → tín hiệu meaning-engine.
- Convention hiện có (ctan): code `ctan_*` snake_case · sort bội 10.

**5 skill (khớp 5 nhãn CPO duyệt):**

| # | code | label_vi | sort | ý nghĩa |
|---|---|---|---|---|
| 1 | `ballet_technique` | **Kỹ thuật & Tư thế** | 10 | posture · alignment · body control · ballet fundamentals |
| 2 | `ballet_discipline` | **Tập trung & Kỷ luật** | 20 | listening · nhớ động tác · kiên trì · làm theo hướng dẫn |
| 3 | `ballet_musicality` | **Cảm nhạc & Nhịp điệu** | 30 | musical awareness · rhythm · movement connection |
| 4 | `ballet_group` | **Tương tác & Tự tin nhóm** | 40 | collaboration · confidence · group participation |
| 5 | `ballet_expression` | **Biểu cảm Nghệ thuật** | 50 | emotion · expression · storytelling qua chuyển động |

→ 3 tag đầu phủ đúng technique / concentration / group (task PHASE1 #3); +2 mở rộng musicality & expression cho ballet.

> **KHÔNG có tầng điểm số / thang đo.** Skill = *nhãn ghi nhận có xuất hiện* (signal), không phải mức đạt. Không rating, không %, không xếp hạng.

---

## 3. OBSERVATION TEMPLATE (Task 2)

**Cấu trúc 3 lớp — dùng đúng cột đã có, giữ Memory > Metric:**

### Lớp A — Moment · "Chuyện gì đã diễn ra?"
`learning_moments`: ảnh/clip múa + `caption` (kể lại khoảnh khắc) + `theme_tag` (tự do). Nhiều bé qua `moment_children`. → *bằng chứng thị giác*.

### Lớp B — Teacher Observation · "Cô nhận thấy điều gì?"
`child_observations.note` (free-text, **kể — không chấm**) + `is_highlight` (khoảnh khắc đáng nhớ) + `needs_support`/`follow_up_needed` (hỗ trợ, không phải điểm trừ) + `visibility` (`parent_visible` để gửi phụ huynh / `private_internal` giữ nội bộ).

### Lớp C — Development Signal · "Chạm vào mảng phát triển nào?"
`skills_observed` = chọn 0–n trong 5 skill ballet. **Chỉ đánh dấu "có chạm tới", KHÔNG đo mức.** Trống cũng hợp lệ.

**Mẫu tốt vs xấu (đưa vào onboarding cô):**

| ✅ NÊN (memory) | ❌ TRÁNH (metric) |
|---|---|
| "Hôm nay con tự tin hơn khi xoay cùng nhóm." | "Con đạt 8/10 kỹ thuật xoay." |
| "Con nhớ được chuỗi động tác dù mới học tuần trước." | "Kỹ thuật: khá. Nhịp: trung bình." |
| "Lần đầu con dám đứng hàng đầu và cười khi biểu diễn." | "Xếp hạng 3/12 trong lớp." |

Signal ở Lớp C gắn với câu chuyện ở Lớp B — cùng nhau thành *ký ức phát triển*, không thành phiếu điểm.

---

## 4. THEME STRUCTURE REVIEW (Task 3)

**Hiện trạng:** `themes` program+age_group+level-scoped. ctan: 1 ("Nhịp điệu mùa xuân"). **ballet: 1 ("Vũ điệu Giáng Sinh 2026")** — gắn age_group+level cụ thể.

**Đánh giá:** theme mỏng ở CẢ hai môn (1 mỗi môn) — không phải điểm yếu riêng ballet. Moment có `theme_tag` **free-text** nên cô tự đặt chủ đề buổi mà không cần theme catalog.

**Khuyến nghị:** **KHÔNG cần thêm theme để khởi động pilot.** Theme catalog là nice-to-have (gợi ý chủ đề học kỳ), có thể bổ sung sau khi thấy nhịp dạy thật. Không chặn. *(Nếu CPO muốn, thêm sau = data-only, cần age_group+level ballet — mà age_group ballet đang là quyết định treo từ PHASE0A.)*

---

## 5. CONFIGURATION DECISIONS (Task 4)

### 4.1 — Approval mode (⚠️ cần quyết trước pilot)
**VNDM hiện:** `moment_approval_mode=true` · `report_approval_mode=true` · `parent_comment_mode=false` · `master_profile_id=NULL` · sharing `no_external_sharing` · watermark `null`.

**Vấn đề:** approval BẬT + **chưa có master** → cô tạo moment/report cần duyệt mà **không ai duyệt** → **nội dung kẹt, phụ huynh không thấy**.

**Khuyến nghị ★:** pilot 1 cô champion tin cậy → **TẮT cả hai approval** (`false`) để nội dung tới phụ huynh trực tiếp. *(Guard cho phép đổi *_mode — xem MP-2.)* Phương án B: giữ approval + gán master duyệt (thêm 1 account + thao tác duyệt mỗi lần — nặng cho pilot nhỏ).

### 4.2 — Teacher assignment readiness
Cần **account Cô Thuý Ngân thật** (hiện chỉ "Cô Thúy Ngân **Demo**" @ DEMO-001). Thao tác chính xác:
1. **Tạo account** (auth) qua invite/app → **Claude KHÔNG tạo được auth account/password.**
2. **Profile:** `role='lead_teacher'` · `school_id=VNDM (064dd53e-…)` · `full_name='Cô Thuý Ngân'` · `state='active'` · `user_id` = auth user vừa tạo.
3. **Gán lead:** UPDATE `lead_teacher_id` 2 distribution = profile-id cô (**MP-3**).

### 4.3 — Cohort intake template
Children **không có school_id** → thuộc VNDM qua **enrollment**. `global_child_id`/`state` tự sinh → children INSERT chỉ cần `full_name` (+dob/gender optional).

**Template thu thập (anh/cô điền):**

| Họ tên bé* | DOB (YYYY-MM-DD) | Giới tính | Lớp (Hạt Nắng / Cánh Hoa) | Tên phụ huynh | Email/SĐT phụ huynh |
|---|---|---|---|---|---|

- **Trẻ + enrollment** = em INSERT qua SQL (MP-5).
- **Phụ huynh** = mời qua **`parent_invitations`** (app flow: token_hash + email — KHÔNG tạo tay bằng SQL) → khi accept, tạo `child_parents` link. Claude soạn danh sách mời + mapping child↔parent, **không tạo auth account**.

---

## 6. OWNER GATE REQUIRED ACTIONS
- [ ] CPO duyệt **5 skill ballet** (nhãn + code) → cho áp **MP-1**.
- [ ] CPO chốt **approval mode**: TẮT (MP-2) hay giữ + gán master.
- [ ] Tạo **account Cô Thuý Ngân** (+ master nếu chọn giữ approval) qua app.
- [ ] Cung cấp **danh sách cohort** (template §4.3) → áp MP-5 + mời phụ huynh.
- [ ] **Gán master** cho VNDM: **qua admin in-app** (KHÔNG qua SQL — guard ghim `master_profile_id` khi không `is_admin()`).
- [ ] Owner Gate real-login: cô ghi 1 observation mỗi loại (technique/discipline/group) + moment có clip → phụ huynh đúng bé thấy.

---

## 7. MUTATION PACKAGE (ĐỀ XUẤT — KHÔNG execute)

> Tất cả là **data INSERT/UPDATE** vào bảng có sẵn. **0 DDL · 0 migration · 0 Edge · 0 deploy.** Chạy qua `execute_sql` sau khi Owner authorize. Rollback ghi kèm.

### MP-1 · Seed 5 skill ballet *(chạy được ngay, không cần id ngoài; idempotent)*
```sql
INSERT INTO skill_catalog (program_id, code, label_vi, sort_order, enabled)
SELECT p.id, v.code, v.label_vi, v.sort_order, true
FROM programs p
CROSS JOIN (VALUES
  ('ballet_technique',  'Kỹ thuật & Tư thế',       10),
  ('ballet_discipline', 'Tập trung & Kỷ luật',     20),
  ('ballet_musicality', 'Cảm nhạc & Nhịp điệu',    30),
  ('ballet_group',      'Tương tác & Tự tin nhóm', 40),
  ('ballet_expression', 'Biểu cảm Nghệ thuật',     50)
) AS v(code, label_vi, sort_order)
WHERE p.slug = 'ballet'
ON CONFLICT (code) DO NOTHING;
```
*Rollback:* `DELETE FROM skill_catalog WHERE code LIKE 'ballet_%';`

### MP-2 · Tắt approval cho pilot *(nếu CPO chọn phương án ★)*
```sql
UPDATE schools SET moment_approval_mode = false, report_approval_mode = false
WHERE code = 'VNDM-DN';
```
*Guard cho phép (*_mode không bị ghim). Rollback:* đặt lại `true`.

### MP-3 · Gán Cô Thuý Ngân làm lead 2 lớp *(cần profile-id cô sau khi có account)*
```sql
UPDATE class_distributions SET lead_teacher_id = '<THUY_NGAN_PROFILE_ID>'
WHERE id IN ('4bd46ca0-ec55-44af-ad4b-1dbe95f1b811',   -- Ballet Hạt Nắng
             'e41c5bc2-20c6-4c43-b9e2-14624533eb36');  -- Ballet Cánh Hoa
```
*Rollback:* set lại `NULL`.

### MP-4 · Gán master VNDM — **KHÔNG qua SQL**
Guard `guard_schools_protected_cols` ghim `master_profile_id` trừ khi `is_admin()`; `execute_sql` có `auth.uid()` NULL → sẽ **no-op âm thầm**. → Thực hiện qua **admin in-app** (super_admin gán master). Ghi nhận, không cấp SQL.

### MP-5 · Cohort children + enrollment *(template — chờ danh sách thật)*
```sql
-- mỗi bé: global_child_id/state auto → chỉ cần full_name (+dob/gender)
WITH ins AS (
  INSERT INTO children (full_name, dob, gender)
  VALUES ('<Họ tên bé>', '<YYYY-MM-DD>'::date, '<male|female|null>')
  RETURNING id
)
INSERT INTO enrollments (child_id, class_id, state)
SELECT id,
  '9518e115-b9aa-44c4-9c5f-d573493578b7',  -- Hạt Nắng  (hoặc 5d8795fd-…-Cánh Hoa)
  'active'
FROM ins;
```
*Phụ huynh:* mời qua app (`parent_invitations`), KHÔNG SQL. *Rollback:* xoá enrollment + children theo id trả về.

---

**Trạng thái:** `FOUNDATION DESIGN READY · chờ Owner Gate + account + cohort`. Package MP-1..MP-5 đã soạn byte-chính-xác, toàn data (0 schema/migration/deploy). Giữ **Memory > Metric** (skill = signal, không điểm). Cần CPO: duyệt skill · chốt approval · tạo account · gửi cohort · gán master in-app. **KHÔNG execute phiên này · KHÔNG canonicalize** (giữ D344/v1.32/V126-M1). Inventory bất biến. Delta = 0 (read-only audit).
