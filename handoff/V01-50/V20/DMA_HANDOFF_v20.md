# 🤝 DMA_HANDOFF_v20.md — BÀN GIAO PHIÊN (NGÃ A: MASTER TỰ QUẢN TRƯỜNG — 2026-06-27 09:43 GMT+7)

> **Cách dùng:** File này = ảnh chụp trạng thái cuối phiên v20. Boot phiên sau:
> `00_START_HERE` → `RULES` → file này. Rồi audit DB/code thật trước khi viết.
> **Naming:** DMA = nền tảng; CTAN = sản phẩm đầu. Không "DMMA".

---

## 1. LÀM GÌ PHIÊN NÀY

**Ngã A — master tự quản trường.** Master login được rồi → màn tự thêm **lớp / môn / GV / trẻ / phụ huynh** (mở rộng portal Trường). Mục tiêu: trường mới TỰ vận hành, KHÔNG cần Jean seed tay.

- **Audit D1 trước** (2 lượt): cụm Org/People (enum vai · guard trigger · RLS write · RPC sẵn) → lộ **`master_admin` ∈ `is_school_admin()`** ⇒ phần lớn self-manage RLS đã phục vụ sẵn, chỉ **2 lỗ ghi** cần RPC.
- **mig 040 — 2 RPC:** `assign_class_distribution` (rót môn, LICENSE-GATED) + `provision_parent_and_link` (tạo PH + link, vá D29).
- **UI Lovable `/portal/school`** 3 tab + nav 4-vai + quyết B (GV read-only).
- Nghiệm thu login thật 6 phép thử (gồm phép thử linh hồn license MNDM-không-Ballet).

---

## 2. TRẠNG THÁI THẬT CUỐI PHIÊN

- **DB cấu trúc:** **46 bảng · 45 hàm SECURITY DEFINER · 125 RLS policy · mig 001→040 · seed 001→012.** SYSTEM_MAP **v0.20.**
  - +2 hàm v20: `assign_class_distribution` · `provision_parent_and_link` (cả 2 grant authenticated, secdef, KHÔNG audit — mirror `create_child_and_enroll`).
  - mig 040 **KHÔNG thêm bảng/cột/enum/policy** — chỉ 2 RPC. 125 policy KHÔNG đổi.
- **Edge Functions (4 — không đổi):** `get_signed_media_url` · `upload_media` · `resolve_share_link` · `invite_master`.
- **Routes app:** thêm **`/portal/school`** (Quản lý Trường) + nav "Quản lý Trường" hiện cho 4 vai master_admin/sub_admin/lead_teacher/assistant_teacher.
- **3 tenant / 3 master:** `DEMO-001` · `KHM-DN` · `MNDM-DN`.
- **Data state (giữ từ v17):** KHM-DN `sharing_mode=private_share_link`; consent An `private_share_link` (`d1…e1`) **WITHDRAWN**.

> ⚠️ **Có data test còn trong DB KHM-DN** (Lớp Test Sáng · Cô Test · Bé Test + Mẹ/Bố Test + distributions của lớp test). SQL dọn ở §5 — chạy để về demo sạch.

---

## 3. mig 040 — 2 RPC (đã verify D15 `[]` + nghiệm thu login thật)

### `assign_class_distribution(p_class_id, p_program_id, p_lead_teacher_id default null) → uuid`
- Gate: `is_admin()` OR (`master_admin`/`sub_admin` AND class thuộc trường mình).
- **⭐ LICENSE-GATE:** `has_subject_entitlement(school, program)` (D51/D56 — reuse, chỉ rót MÔN ĐÃ MUA active/trial còn hạn). MNDM không mua Ballet → raise `subject_not_entitled`.
- Lead-teacher (nếu có) phải đúng trường + vai dạy được → `lead_teacher_invalid`.
- Chống trùng: `class_distributions` KHÔNG có unique(class,program) → tự kiểm → `distribution_exists`.
- Insert + `applied_by=current_profile()`, `applied_at=now()`. KHÔNG audit.

### `provision_parent_and_link(p_child_id, p_full_name, p_email, p_phone, p_link_role) → uuid`
- **Vá D29 RETURNING-câm:** PH có `school_id=NULL` (D40) → raw INSERT thì 3 SELECT policy `profiles` đều false → RETURNING rỗng. → RPC atomic.
- Gate: master + `child_in_my_school` (đi vòng enrollment, D40 — children không school_id).
- max-2-parent: đếm trước, raise `max_parents_reached`; role `primary` (con #0) / `secondary` (con #1).
- Tạo PH (school_id NULL, user_id NULL — login gắn sau qua invite) + insert `child_parents` → trả `profile_id`. KHÔNG audit.

> **2 bảng đụng KHÔNG có guard trigger trên INSERT** (guard chỉ UPDATE) → secdef bypass RLS đủ, **KHÔNG cần `session_replication_role=replica`** (khác D30/D85).

---

## 4. UI `/portal/school` (Lovable) + nghiệm thu

**3 tab:** Lớp & Môn · Giáo viên · Trẻ & Phụ huynh.
- **Gate client-side** (D13 — sau hydrate): role 4-vai vào màn; `canManage = role ∈ {master_admin,sub_admin}`.
- **Quyết B — GV read-only (D45 "2 portal thông nhau"):** lead/assistant_teacher VÀO được, thấy danh sách, **ẩn mọi form ghi** ("chế độ chỉ đọc"). PH/admin-nền-tảng → "Không có quyền".
- Dropdown môn nguồn `school_subject_entitlements` lọc client active/trial+còn-hạn (license linh hồn ở UI).
- `.rpc()` KHÔNG throw → đọc `error.message` trực tiếp → map toast tiếng Việt.

**✅ Nghiệm thu login thật 6 phép thử (PASS):**
| # | Phép thử | KQ |
|---|---|---|
| 1 | master KHM thêm lớp "Lớp Test Sáng" | ✅ toast xanh |
| 2 | rót CTAN + GV Đặng Mỹ Linh | ✅ "GV chính: Đặng Mỹ Linh" |
| 3 | rót CTAN lần 2 (trùng) | ✅ `distribution_exists` → toast đỏ "Môn này đã có trong lớp." |
| 4 | thêm GV "Cô Test" (user_id NULL) + Bé Test + 2 PH | ✅ |
| 5 | thêm PH thứ 3 | ✅ `max_parents_reached` "Bé đã có đủ 2 phụ huynh." |
| 6 | **⭐ master MNDM dropdown môn** | ✅ **CHỈ CTAN, KHÔNG Ballet** (phép thử linh hồn license); KHM có cả 2 |
| + | GV Cô Linh `/portal/school` | ✅ read-only, thấy danh sách không thấy form |
| + | Isolation KHM vs MNDM | ✅ không lẫn lớp/trẻ |

**⭐ Bài học vàng:** master quản trường chạy trọn vòng KHÔNG sửa 1 dòng engine v3–v14 + 8 cụm RLS — chỉ thêm 2 RPC cho 2 lỗ ghi.

**⭐ Bẫy deploy-lag (D84):** toast câm 3 lần dù code vá đúng — Cloudflare Pages chưa rebuild (commit→build vài phút), test bản cũ; sau lag toast xanh/đỏ chạy chuẩn. *Phân biệt deploy-lag vs code-sai = test trong Preview Lovable (chạy ngay) vs demenart.com (chờ rebuild).*

---

## 5. ⭐ SQL DỌN DATA TEST (chạy để về demo sạch — idempotent)

Xóa Lớp Test Sáng + Cô Test + Bé Test + Mẹ/Bố Test + distributions của lớp test. `ON DELETE CASCADE` của FK (enrollments/class_distributions theo class_id; moment_children theo child) lo phần con. KHÔNG đụng data pilot thật.

```sql
-- ============================================================
-- DỌN DATA TEST v20 (Quản lý Trường) — idempotent, an toàn
-- Chạy bằng login admin/Jean trên SQL Editor.
-- Bọc replica vì children/profiles có guard trigger trên UPDATE/DELETE? → DELETE cũng nên replica cho chắc.
-- ============================================================
SET session_replication_role = replica;

-- 1) PH test (Mẹ/Bố Test) — gỡ link rồi xóa profile (school_id NULL, user_id NULL)
DELETE FROM public.child_parents cp
USING public.profiles p
WHERE cp.parent_profile_id = p.id
  AND p.school_id IS NULL AND p.user_id IS NULL
  AND p.full_name IN ('Mẹ Test','Bố Test');
DELETE FROM public.profiles
WHERE school_id IS NULL AND user_id IS NULL
  AND full_name IN ('Mẹ Test','Bố Test')
  AND role IN ('primary_parent','secondary_parent');

-- 2) Bé Test — xóa enrollment + child (CASCADE lo moment_children/journey nếu có)
DELETE FROM public.enrollments e USING public.children c
WHERE e.child_id = c.id AND c.full_name = 'Bé Test';
DELETE FROM public.children WHERE full_name = 'Bé Test';

-- 3) GV test (Cô Test) — chưa login (user_id NULL), thuộc KHM
DELETE FROM public.profiles
WHERE full_name = 'Cô Test' AND user_id IS NULL
  AND role IN ('lead_teacher','assistant_teacher');

-- 4) Lớp Test Sáng — distributions theo class CASCADE, rồi xóa class
DELETE FROM public.classes WHERE name = 'Lớp Test Sáng';

SET session_replication_role = DEFAULT;

-- 5) VERIFY (statement cuối)
SELECT jsonb_pretty(jsonb_build_object(
  'class_test_remain',   (SELECT count(*) FROM public.classes  WHERE name='Lớp Test Sáng'),
  'co_test_remain',      (SELECT count(*) FROM public.profiles WHERE full_name='Cô Test'),
  'be_test_remain',      (SELECT count(*) FROM public.children WHERE full_name='Bé Test'),
  'ph_test_remain',      (SELECT count(*) FROM public.profiles WHERE full_name IN ('Mẹ Test','Bố Test')),
  'classes_total',       (SELECT count(*) FROM public.classes),
  'children_total',      (SELECT count(*) FROM public.children)
));
```
**Kỳ vọng:** 4 `*_remain` = 0; `classes_total`/`children_total` về số demo gốc (KHM 2 lớp/8 trẻ, tổng 3 tenant như seed 001–012).

> Nếu Bé Test đã được gán PH (Mẹ/Bố Test) thì chạy đúng thứ tự trên (PH trước, trẻ sau) là sạch. Nếu báo FK còn vướng → đọc lỗi thật, đừng đoán (D1).

---

## 6. VIỆC TREO (ưu tiên giảm dần)

1. 🔴 **Lưu repo (nợ dồn):** mig 040 + file UI `src/routes/portal/school.tsx` → đóng gói đặt repo (D90). *(App chạy KHÔNG phụ thuộc — backup-dự-phòng.)*
2. 🟡 **UI cosmetic — xác nhận lại sau deploy:** tên PH hiển thị (embed `profiles!parent_profile_id`) + dropdown vai Mẹ/Bố/Người giám hộ — **đã trong bản vá**, anh chưa xác nhận lần cuối vì deploy-lag. Reload sau rebuild kiểm 1 lần.
3. **`revoke_share_link` + UI** (D87 — share link chỉ tự-chết qua expiry/rút-consent; chưa có nút thu hồi tay).
4. **Profile GV/PH còn lại chưa có login** (chỉ master + vài vai đã invite + GV-test thì xóa).
5. **2 file curriculum media chưa có nguồn lưu** (`media_curric`=2; re-upload là tạo lại).
6. **Vercel project dormant** xóa được.
7. **Vụn cũ:** sửa `seed_007` repo (body_template "Bé " thừa — đã UPDATE live) · caption "[seed]"/row test rác (UI đã strip client).

---

## 7. NGÃ KẾ — ĐỀ XUẤT

- **⭐ A — Dọn data test + lưu repo (mở phiên ngắn):** chạy SQL §5 + đóng gói mig 040+`school.tsx` repo (D90). Trả nợ gọn, về demo sạch.
- **B — Onboard staff/PH qua app hoàn chỉnh:** master tạo GV/PH rồi **mời login** (Edge `invite_master` mở rộng cho lead_teacher/parent — pattern v18 đã có, nhân ra). Đóng vòng "trường tự vận hành KHÔNG cần Jean".
- **C — `revoke_share_link` + UI** (đóng nốt vòng đời share link D87).
- **D — Tách 4 portal** (hiện gộp 1 `/portal`; RLS scope đã đúng tầng DB — chỉ là UI/IA).

**Boot phiên sau:** đọc HANDOFF v20 → audit live (D1) thật trước khi viết.

---

## 8. DATA STATE CẦN NHỚ (bẫy cho phiên sau)

- **KHM-DN `sharing_mode=private_share_link`** (KHÔNG phải `no_external_sharing`).
- **Consent An `private_share_link` (`d1…e1`) đang WITHDRAWN** (`withdrawn_at` 2026-06-26 04:22). Muốn test share lại phải `UPDATE … SET withdrawn_at=NULL`.
- **3 tenant / 3 master** sạch (sau khi chạy SQL §5).
- **PH 051 mỗi trường = 2-con-xuyên-lớp** (persona test multi-child cross-class).
- **`master_admin` ∈ `is_school_admin()`** → master tự được mọi RLS write same_school phục vụ; chỉ `class_distributions` write + provision-PH (RETURNING-câm) cần RPC.

---

> **KỶ LUẬT VÀNG:** đã cập nhật RULES (+D91, footer v20) + SYSTEM_MAP (bullet v20, bump v0.20, hàm 43→45, mig→040, route `/portal/school`) trong phiên này. 3 file xuất kèm: `DMA_HANDOFF_v20.md` · `DMA_RULES.md` · `DMA_SYSTEM_MAP.md`. **Tài liệu A–G, START_HERE, BUILD_PATH, DMWS_REFERENCE: KHÔNG đổi.**
