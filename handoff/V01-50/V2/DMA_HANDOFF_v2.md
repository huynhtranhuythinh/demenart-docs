# 🤝 DMA_HANDOFF_v2.md

> **Phiên:** v2 (thi công DB 44 bảng + RLS helpers + policy batch 1 + Chặng 1 app TanStack chạy thật)
> **Đóng phiên:** 2026-06-24 21:15 (GMT+7)
> **Naming:** DMA = nền tảng; CTAN = module đầu. Không "DMMA".

---

## 0. MỤC LỤC PHIÊN (đã làm gì)
1. Boot: đọc 00/RULES/HANDOFF_v1, audit 11 file Project Knowledge OK.
2. Tạo Supabase project **`dma`** (region Singapore, bật "automatic RLS").
3. **Thi công trọn DB 44 bảng** qua **mig 001–007** (idempotent, verify từng cái bằng số thật).
4. **RLS helpers** (mig 008, 12 hàm) → **policy batch 1** (mig 009: profiles self/admin + registry) + nối profile test → **harden grants** (mig 010, đóng "public execute definer").
5. Audit hàm definer = 16 → cái thứ 16 là **`rls_auto_enable`** (Supabase automatic-RLS, benign).
6. **Lovable**: nối native Supabase vào `dma` → build **Chặng 1** (TanStack Start: landing/auth/_authenticated/portal/Trung Tâm Tra Cứu).
7. **TEST LOGIN THẬT THÀNH CÔNG:** `info@demenart.com` → `/portal` hiện super_admin. Sửa crash (thiếu `@supabase/supabase-js`).
8. Chốt phiên: cập nhật SYSTEM_MAP v0.3 + RULES (D13/D14) + handoff này.

---

## 1. TRẠNG THÁI FILE — ⚠️ ĐẦU PHIÊN SAU: anh LƯU 2 file vào Project Knowledge (thay bản cũ)
- **`DMA_SYSTEM_MAP`** → **v0.3** (thêm §6 mig 008–010 + §7 tầng app + chốt thi công mới).
- **`DMA_RULES`** → thêm **D13** (TanStack Start), **D14** (Lovable không auto-fix/auto-gen + phân loại nhiễu scanner); cập nhật D23 (current_profile_role rename, rls_auto_enable).
- **Không đổi:** `DMA_00_START_HERE` · `DMA_BUILD_PATH` · `DMA_05_DMWS_REFERENCE` · `DMA_A_PRD`..`DMA_G` (A–G giữ nguyên — chỉ là lớp thiết kế).
> **File SQL đã chạy (lưu vào repo/nơi an toàn):** `001_foundation` → `010_harden_function_grants` (10 file, đều idempotent).

---

## 2. ⭐ TRẠNG THÁI THẬT (DB + App)
- **DB:** 44 bảng + 16 hàm SECURITY DEFINER (3 trigger + 12 helper + `rls_auto_enable`) + triggers nền. **Idempotent, tested PostgreSQL/Supabase `dma`.**
- **RLS:** helpers XONG. **Policy MỚI batch 1** (chỉ profiles + registry). **~40 bảng còn lại CHƯA policy → khóa kín.** Đây là việc lớn phía trước.
- **App (Lovable, TanStack Start):** Chặng 1 chạy thật — login → đọc profile (RLS) → role → routing `/portal` + Trung Tâm Tra Cứu. Hiện gộp **1 `/portal`** (chưa tách 4 portal).
- **Test user:** `info@demenart.com` = super_admin (profile `Quản trị viên Test`).

---

## 3. OPEN ITEMS (chốt đúng chặng)
- **RLS policy ~40 bảng còn lại** — viết theo cụm + test bằng login thật (việc chính).
- **Tách 4 portal** (`/admin /school /teacher /parent`) — khi mỗi portal có nội dung (Chặng 2+).
- **3 user vai trò còn lại** (school/teacher/parent) để test routing đa vai trò.
- **#4 Leaked Password Protection** — bật ở Supabase → Authentication → Attack Protection (dễ, làm lúc nào cũng được).
- **Publish app** — để sau, khi app ổn + siết quyền xem (giờ đang để Public tạm để test).
- Giá thật `pricing_config`; default `assistant_consumes_seat`; permission catalog Sub-Admin; consent 2 tầng chi tiết; deploy target (Vercel preset vs Lovable hosting) — chốt Chặng 8.

---

## 4. ⭐ NEXT ACTION (đầu phiên sau)
1. Anh lưu **SYSTEM_MAP v0.3 + RULES** vào Project Knowledge.
2. **Tiếp RLS policy theo cụm** — bắt đầu cụm **Org/People** (schools/classes/profiles write + children/enrollments/child_parents) theo §14 C + D45 (scope trường/môn-lớp/tiết), rồi test bằng login thật. **Song song** có thể build UI Chặng 2 (CRUD org & people) để test policy ngay.
3. Tạo thêm user school/teacher/parent khi cần test scope đa vai trò.

---

## 5. BOOT phiên sau
1. Đọc `DMA_00_START_HERE` → `DMA_RULES` → file này.
2. Xác nhận SYSTEM_MAP v0.3 + RULES (D13/D14) đã ở Project Knowledge (audit thật — D1).
3. **Audit DB thật trước khi viết SQL** (`pg_policies`, `information_schema`): nhớ **16 hàm definer** (có `rls_auto_enable` benign), RLS policy mới có ở profiles + registry.
4. Vào Next Action §4. Sequencing: RLS policy theo cụm → test login thật (D2/D3) → Edge → UI.

---

## 6. TỰ ĐÁNH GIÁ
- **Được:** đi từ móng tới app-chạy-thật trong 1 phiên, 10 migration sạch verify-bằng-số; chọn đúng chiến lược "A" (app trước → test RLS thật) nên login end-to-end đã chứng minh; chặn kịp các bẫy Lovable (auto-fix, auto-gen schema, chọn nhầm org DMWS, vercel.json sai stack); audit ra `rls_auto_enable` thay vì hoảng; giữ KỶ LUẬT VÀNG (ghi sổ migration + chốt thi công).
- **Cần giữ:** chia SQL khối nhỏ + SELECT verify cuối; chụp Plan Lovable TRƯỚC khi Approve; không cho Lovable đụng DB; hỏi từng câu một; verify bằng ảnh/số thật.
- **Lưu ý phiên sau:** RLS policy là phần **dễ sai + nhiều nhất** còn lại — đi theo cụm, mỗi cụm test bằng user thật đúng vai trò (D2 — không test được trong SQL Editor). Đừng để Lovable tự sinh policy.
