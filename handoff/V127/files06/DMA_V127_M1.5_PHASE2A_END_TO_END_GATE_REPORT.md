# 🩰 DMA V127-M1.5-PHASE2A — WAVE 0 END-TO-END GATE REPORT

> **Owner Gate:** PASS (approved). **Scope:** 1 bé thật (Wave 0), KHÔNG cohort, KHÔNG fake data.
> **Baseline (khớp, giữ nguyên):** RULES **D344** · SYSTEM_MAP **v1.32** · HEAD **`6b860338`** · inventory **89/215/166 · tail `20260807130914`** — bất biến.
> **Delta phiên này:** +1 child · +1 enrollment · +2 lead_teacher_id update (data-only). 0 schema/migration/deploy.

---

## STATUS: 🔴 **FAIL / BLOCKED** — end-to-end chưa chạy được (thiếu tiền đề, KHÔNG phải lỗi nền tảng)

Data wiring phía teacher-class + child-enrollment **đã dựng xong**. Nhưng gate **không thể tuyên PASS** vì **2 blocker cứng nằm ngoài quyền SQL của em** + cần real-login người thật. Em **không fake parent, không giả lập click UI** để ép PASS.

---

## 1. READ-ONLY VERIFY — 4 tiền đề (3/4 KHÔNG đạt)

| # | Owner giả định "exists" | Thực tế live | Verdict |
|---|---|---|---|
| 1 | Teacher profile | Account **có** — Tạ Thị Thuý Ngân (`d26e5914…`, `ngan.pepu@gmail.com`, user_id có) — nhưng **role=`secondary_parent`, school=NULL**, và đang link **"mother" tới 1 child seed** (`d1000000-…41`) | ⚠️ **CHƯA đủ tư cách teacher** |
| 2 | Child exists | **KHÔNG** — Trần Tuệ Linh không tồn tại | ❌ (đã tạo — mục 2) |
| 3 | Parent relationship | **KHÔNG** — "Trang Đoàn" không có profile/account | ❌ **BLOCKER** |
| 4 | VNDM mapping | Classes có (Hạt Nắng/Cánh Hoa) | ✅ |

---

## 2. APPROVED SETUP ĐÃ THỰC THI (SQL-able, reversible)

Trong phần Owner duyệt ("child/class mapping · teacher assignment if required"), phần làm được qua SQL đã áp + verify:

| Object | ID | Kết quả |
|---|---|---|
| **Child** Trần Tuệ Linh (Happy) | `8e70bd13-8639-450e-9724-8dfb3bcb1958` | tạo, state active |
| **Enrollment** | `68766385-c2df-41dc-9696-f2d38f1827bf` | → **Ballet Hạt Nắng** (VNDM), active |
| **Lead assign** (2 distribution) | `4bd46ca0…` + `e41c5bc2…` | `lead_teacher_id = d26e5914` (Tạ Thị Thuý Ngân) |

**Verify:** child → Ballet Hạt Nắng → VNDM-DN active · distribution Hạt Nắng: lead="Tạ Thị Thuý Ngân", child_count=1. → `get_teacher_classes` (xét `lead_teacher_id`, không xét role) sẽ **trả lớp cho cô**.

---

## 3. BLOCKER CỨNG (ngoài quyền SQL — cần Owner/admin/app)

### 🔴 B1 — Role cô = `secondary_parent` (không vào được Teacher Portal)
`guard_profiles_protected_cols`: non-admin → **ghim `role`/`school_id`/`user_id`/`permissions`**. `execute_sql` có `auth.uid()` NULL → **KHÔNG đổi role qua SQL được** (âm thầm no-op). App route theo role → cô sẽ vào **parent portal**, không phải teacher.
→ **Cần super_admin/admin đổi in-app:** `role=lead_teacher` · `school_id=VNDM (064dd53e…)`.
→ **Dọn kèm:** gỡ link "mother" tới child seed `d1000000-…41` (là delete — cần Owner duyệt riêng) để account cô sạch.

### 🔴 B2 — Parent "Mẹ Trang Đoàn" chưa có account
Em **không tạo được auth account** (rule: no account creation). → Mời qua app (`parent_invitations`) → khi accept mới tạo `child_parents` link tới `8e70bd13…`. Hiện `child_parent_links = 0`.

### 🔴 B3 — Live click-through cần người thật (D2/D3)
Teacher tạo session/upload/observation + Parent login/xem journey = **real-login người thật**. Em dựng data + verify logic, không thay người bấm UI.

---

## 4. SECURITY CHECK (cross-child) — verify ở tầng quan hệ
- Child Trần Tuệ Linh hiện **0 parent link** → chưa ai thấy (đúng).
- Khi link mẹ Trang Đoàn: `is_child_parent` = exists `child_parents` theo `parent_profile_id=current_profile()` → mẹ **chỉ thấy đúng 1 con** (single link). VNDM hiện **chỉ 1 bé** → không có bé khác để lộ.
- **Để test cross-child THỰC SỰ có ý nghĩa** cần ≥2 gia đình thật — Wave 0 một bé chưa đủ mẫu. Ghi nhận: ranh giới đúng ở tầng gate/RLS (đã audit PHASE0), nhưng **cross-child live test hoãn tới khi có bé thứ 2**.

---

## 5. OWNER GATE — REQUIRED ACTIONS để chạy được end-to-end
1. **[admin in-app]** Đổi role cô → `lead_teacher` + `school_id=VNDM`. *(SQL bị guard.)*
2. **[admin in-app, tùy chọn]** Gỡ link mother demo khỏi account cô.
3. **[app invite]** Tạo account **Mẹ Trang Đoàn** → link `child_parents` tới `8e70bd13…`.
4. **[video]** Khoá iPhone "Most Compatible" trước khi cô quay.
5. **[real-login]** Cô: login → thấy Ballet Hạt Nắng → tạo session → upload clip → observation + gắn skill ballet. Mẹ: login → chỉ thấy Trần Tuệ Linh → thấy observation + media.

---

## 6. SECURITY / CANONICAL
- **0 schema · 0 migration · 0 deploy · 0 permission change.** Inventory bất biến 89/215/166 · tail `20260807130914`.
- Guard `guard_profiles_protected_cols` + `guard_schools_protected_cols` hoạt động đúng (chặn SQL đổi role/master — đúng thiết kế).
- **Not canonicalized. Waiting for milestone close.** Giữ D344/v1.32/V126-M1.
- **Rollback phiên này:** `DELETE FROM enrollments WHERE id='68766385-c2df-41dc-9696-f2d38f1827bf'; DELETE FROM children WHERE id='8e70bd13-8639-450e-9724-8dfb3bcb1958';` + set `lead_teacher_id=NULL` cho 2 distribution (nếu Owner muốn revert).

---

**Kết:** `FAIL / BLOCKED`. Data wiring teacher-class + child-enrollment đã sẵn; gate không PASS được vì **role cô cần admin in-app (B1)** + **account mẹ cần app invite (B2)** + **real-login người thật (B3)**. Không fake để ép PASS. Sau khi Owner xử B1–B2, em verify lại logic + anh chạy real-login → mới tuyên PASS.
