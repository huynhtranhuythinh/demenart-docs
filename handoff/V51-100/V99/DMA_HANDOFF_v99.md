# 📦 DMA_HANDOFF_v99.md — V99 FULL CONTROL PLANE OVERHAUL (12/07/2026)

## 1. Canonical endpoint (đọc cùng RULES + SYSTEM_MAP)
RULES **D244** · SYSTEM_MAP **v0.92** · Handoff **v99**
Live inventory: **73 tables · 133 SECURITY DEFINER · 159 RLS policies · 1 cron**
Baseline: An **6/2/6** · Evidence **22 rows / 16 groups** · Readiness **v2** emerging contemporaneous, gen current_3m failed = [too_short_duration, insufficient_longitudinal_spread] · Discovery **0 capsules** · V92–V98 nguyên vẹn.

## 2. V99 đã làm gì (15 gates)
- **G1 Registry Recovery (v99_1):** 6 ghost modules V92–V98 seeded vào group mới 🌱 journey-discovery; mission-control → live; audit-log route gán; 10 links; 10 playbooks WF-01..WF-10 (46 steps) = Workflow Diagnostics registry (G4).
- **G2/G5/G6/G11/G12 (v99_2):** 4 bảng mới `policy_registry` (5) · `admin_config_registry` (36 keys, D240 6-nhóm + hard-code governance G13 mức nhóm) · `edge_function_registry` (14) · `route_registry` (44). RLS is_admin.
- **G3+G10 (v99_3):** 5 RPC `admin_lookup_*` + `get_admin_system_health()` — reuse derive/compute canonical, không truth thứ hai. Bunny = UNKNOWN by design (D241).
- **G8 (v99_4 + v99_4b):** trigger `audit_config_change()` trên 5 bảng config. Bẫy: NEW.field trong CASE đa-bảng → fix to_jsonb (ghi D243).
- **G7 (v99_5):** `set_program_artistic_domain` — Admin map program→domain (6 code cố định) + audit; CTAN→music xác nhận no-op sạch.
- **G14+G15 (frontend):** /admin/lookup · /admin/policies · /admin/audit-log · /admin/system-map (5 tab, có Program→Domain editor) · admin home: search topbar → lookup, Bunny tile hết fake OK, nút Xử lý hết dead. NAV +4.
- **G-close (v99_6):** flip building→live, drift=0, full regression PASS.

## 3. Acceptance (server-verified qua JWT impersonation)
Case 1 PH không thấy ảnh → admin_lookup_media checklist (moment_exists/approved/tagged/active/consent + denial logs) ✅ · Case 2 chưa có Bản Khám Phá → readiness state + failed codes + policy version trong admin_lookup_child ✅ · Case 3 ảnh không mở → media source/consent/audit + health (bunny UNKNOWN thay vì fake OK) ✅ · Case 4 bao nhiêu feature live → Feature tab /admin/system-map ✅ · Case 5 policy nào điều khiển Readiness → /admin/policies readiness v2 ✅. Privacy: admin_lookup_child chỉ metadata Parent Memory (D244) ✅. Config audit: 1 edit hợp lệ → audit row action=config_change actor set ✅.

## 4. Deploy
Lovable commits 147f66c4 → 535aae13 → 99720c92 → 58bec3ff (typecheck pass toàn bộ, get_diff verify scope từng commit). Deploy production đã trigger (deployment a5e33af5) → **anh test trên demenart.com sau vài phút (D105 lag)**, hoặc Preview URL ngay.
Test nhanh: đăng nhập admin → /admin/lookup gõ "Hùng" → mở An → thấy 6/2/6 + readiness v2 + failed codes. /admin/policies · /admin/audit-log (bật "Config changes" thấy record demo_flag) · /admin/system-map tab Program→Domain.

## 4b. Prod smoke fix (v99_7 — 12/7 11:38)
Jean test production: click row Hùng → "Không kết nối được máy chủ". Root cause: `admin_lookup_user` dùng `session_teachers.teacher_profile_id` (cột thật: `profile_id`) — 42703 lúc runtime, lọt qua build vì hàm này chưa được smoke end-to-end (gate-return sớm không plan tới SQL sai). Fix v99_7: đổi 1 dòng + D15 re-hardening + VERIFY source-grep + gate smoke. Chain verify lại PASS: Hùng → [An, Khang] → An 6/2/6 · 22/16 · v2 · failed codes nguyên. `admin_lookup_capsule` (hàm chưa-chạy-hết còn lại) đã đối chiếu 9 cột dùng vs live schema: khớp 100%. Không cần redeploy frontend (fix DB-side, signature không đổi).

## 5. Session protocol notes
- Migrations v99_1..v99_7 đều D92 3-block + D15 re-hardening + VERIFY-as-rollback. Grant leak = 0 (aclexplode verified).
- D-rules mới: **D238–D244** (đã ghi đầy đủ trong RULES).
- Registry sync giờ là closure requirement (D238) — sprint sau PHẢI update admin_modules/route_registry/edge_function_registry trước khi đóng.

## 6. Nợ để lại V99.x
🟡 Bunny health probe (UNKNOWN → OK/ERROR thật) · 🟡 hard-code scan file-by-file FE (domain labels trùng 4 nơi = NEEDS_FURTHER_DECISION) · 🟡 pricing UI · 🟡 health-score weights card riêng trong /admin/policies · 🟡 policy_registry cần cập nhật cùng-migration khi policy đổi version (quy trình D242) · nợ V95–V98 giữ nguyên (repo re-sync · V96D readiness UI · Badge Provenance · Spine ref_id · child_skills · notification infra V93).


## 7. V99.8 — Smart Lookup UX Completion (cùng ngày)
Boot audit: contract đủ trừ 1 gap → v99_8 additive children_count (D92, leak 0, definer 133). Frontend: adminLookupPresentation.ts (mapping registry) + admin.lookup.tsx viết lại human-language-first. Đã loại khỏi UI mặc định: primary_parent, active, lead_distributions, session_teacher_rows, child_media_view, media_asset, UUID, UTC timestamps, v2/emerging/contemporaneous/gap codes — tất cả vào <details> Chi tiết kỹ thuật. Diagnostics facts-only (không fake OK); "Kiểm tra vấn đề" dùng consent + readiness thật; link audit-log không kèm filter (chưa có URL param contract — không fake). Nợ V99.8: URL filter contract cho audit-log deep-link · media diagnostic entry cần UUID (chưa có media browser per-child) · unknown audit actions hiện "Hoạt động khác". Regression: inventory 73/133/159/1 · baseline An nguyên · /parent/journal untouched · typecheck PASS. QA màn hình thật: chờ anh Jean xác nhận trên production (Flow A–D).


## 8. V99.8b — Child 360° readiness UX (cùng ngày)
QA prod của Jean: eligibility matrix dump chiếm 2-3 màn hình. Fix frontend-only: buildReadinessSummary (headline + ≤2 dòng, deterministic từ mapping — không suy luận) + buildReadinessMatrix (dedupe scopes cùng lý do, window labels VN, reasons ≤2/group) + collapsed "Xem độ sẵn sàng theo từng lát thời gian" mặc định đóng. Copy: "22 lần ghi nhận" · "Hệ thống tổng hợp/phân tích dữ liệu đang hoạt động". Hierarchy Child 360° giữ đúng thứ tự 12 mục spec. Regression: baseline nguyên, zero migration, typecheck PASS. Chờ Jean chụp 3 screenshot QA (default / expanded matrix / tech details collapsed) để đóng.
