# 🤝 DMA_HANDOFF_v27.md — BÀN GIAO PHIÊN (NGÃ B — TRẢ NỢ REPO + TỔ CHỨC LẠI SEED THEO PHẠM VI — 2026-06-28 09:35 GMT+7)

> **Cách dùng:** File này = ảnh chụp trạng thái cuối phiên v27. Boot phiên sau:
> `00_START_HERE` → `RULES` → file này. Rồi audit DB/code thật trước khi viết.
> **Naming:** DMA = nền tảng; CTAN = sản phẩm đầu. Không "DMMA".

---

## 1. LÀM GÌ PHIÊN NÀY

**Ngã B — phiên REPO THUẦN: trả nợ đỏ lâu nhất + tổ chức lại seed theo PHẠM VI.** **KHÔNG mig, KHÔNG Edge, KHÔNG UI — schema/route/code KHÔNG đổi 1 dòng.** Mọi thứ = dump trung thực từ live (D90) để lưu repo.

- **Trả nợ đỏ (từ v22/v23):** `044_revoke_share_link.sql` + 2 Edge `invite_staff.ts` + `invite_parent.ts`. Dump trung thực: hàm = `pg_get_functiondef` + grants dump RIÊNG (sạch `authenticated`+`postgres`+`service_role`); Edge = source nguyên văn copy từ live deploy (KHÔNG dựng lại từ trí nhớ).
- **⭐ Tổ chức lại seed theo PHẠM VI (D96 — thay dải số 001–012 trộn-phạm-vi):** seed cũ trộn bảng TOÀN CỤC (pilot FK-phụ-thuộc) với bảng TENANT trong cùng dải số. Tách:
  - **`seed_000_global_foundation.sql`** = 13 bảng TOÀN CỤC (curriculum 8 D52 + `badges`/`home_activities` D54 + `pricing_config`/`app_settings`/`notification_types` D59). **Thay file `seed_007` lẻ** (gộp vào đây + đủ `app_settings` trước đó thiếu).
  - **`seed_demo001_fixtures.sql`** = 21 bảng tenant DEMO-001 (Bé Jenny/Jimmy), FK-order + `replica` (D85) + chicken-egg `master_profile_id` + `user_id`→NULL (D90).
  - **giữ `seed_010_012_pilots.sql`** (pilot KHM/MNDM).
- **Thứ tự phục hồi DB trắng:** `seed_000` → `seed_demo001` → `seed_010_012` (pilot/demo tham chiếu `programs`/`lessons` ở móng toàn cục — chạy ngược = FK-gãy).

---

## 2. TRẠNG THÁI THẬT CUỐI PHIÊN

- **DB cấu trúc — KHÔNG ĐỔI:** **46 bảng · 50 hàm SECURITY DEFINER · 125 RLS policy · mig 001→044 · seed 001→012 (data live không đổi).** SYSTEM_MAP **v0.26** (KHÔNG bump — phiên repo thuần). **Phiên KHÔNG đụng schema/route/code.**
- **Edge Functions (6 — KHÔNG đổi):** `get_signed_media_url` · `upload_media` · `resolve_share_link` · `invite_master` · `invite_staff` · `invite_parent`.
- **3 tenant / 3 master** (DEMO-001 · KHM-DN · MNDM-DN).

### ⭐ Cây seed repo SAU phiên này (chạy theo thứ tự khi phục hồi DB trắng)
1. `migrations/001…044` (+ `026_039_functions.sql` + `026_039_grants_and_column.sql` + `040`/`041`/`042`/`043` + **`044_revoke_share_link.sql` MỚI lưu**).
2. **`seeds/seed_000_global_foundation.sql`** ⭐ MỚI — móng toàn cục, chạy TRƯỚC.
3. **`seeds/seed_demo001_fixtures.sql`** ⭐ MỚI — tenant sandbox DEMO-001.
4. `seeds/seed_010_012_pilots.sql` — pilot KHM/MNDM (giữ).
5. `functions/invite_staff/index.ts` + `functions/invite_parent/index.ts` ⭐ MỚI lưu (+ 4 Edge cũ đã có).

> **Đã xóa khỏi repo:** file `seed_007_ops_config.sql` lẻ (gộp vào `seed_000`). **Giỏ nợ repo code+data giờ SẠCH.**

> **Routes app KHÔNG đổi** (giữ nguyên từ v26): 5 cổng `/parent`(amber)·`/teacher`(sky)·`/school`(emerald)·`/admin`(slate) đã tách + `/portal` shell hạ-tầng trung tính + `/kid` reserved V2. `/share/$token` public.

---

## 3. FILE PHIÊN NÀY (lưu repo tay — KHÔNG áp vào DB, dump trung thực D90)

**MỚI lưu repo:**
- `044_revoke_share_link.sql` (migration; thân hàm + block REVOKE/GRANT cuối).
- `invite_staff.ts` → `functions/invite_staff/index.ts`.
- `invite_parent.ts` → `functions/invite_parent/index.ts`.
- `seed_000_global_foundation.sql` (13 INSERT bảng toàn cục).
- `seed_demo001_fixtures.sql` (21 INSERT + replica + chicken-egg UPDATE).

**XÓA khỏi repo:** `seed_007_ops_config.sql` lẻ (đã gộp vào `seed_000`).

> **KHÔNG file mig/Edge MỚI phát sinh** (phiên repo thuần — chỉ lưu thứ đã sống trong DB/deploy). **DB/Edge KHÔNG chạy gì** (các block SQL phiên này đều read-only dump).

---

## 4. NGHIỆM THU (đối chiếu số dòng dump vs audit live — D90)

- **`seed_000`:** programs 2 · age_groups 2 · levels 2 · themes 2 · lessons 2 · lesson_versions 2 · program_distributions 2 · program_distribution_items 2 · badges 1 · home_activities 1 · **pricing_config 4** · **app_settings 12** · **notification_types 10** → khớp audit toàn cục. ✅
- **`seed_demo001`:** schools 1 · profiles 3 · subscriptions 1 · entitlements 2 · classes 1 · class_distributions 1 · children 2 · enrollments 2 · child_parents 2 · session 1 · session_teachers 1 · reports 1 · observations 1 · journey 2 · skills 1 · badges 1 · consents 6 · moments 3 (gồm 1 draft) · moment_children 4 · **albums 1** (child-branch — cứu bởi OR-filter, audit class-only báo 0) · media 2 → khớp audit DEMO-001. ✅
- **Edge grants `044`:** `authenticated`+`postgres`+`service_role` only, KHÔNG PUBLIC/anon (D15 leaky=[]). ✅
- **Tổng kiểm:** pilot + DEMO-001 = global (children 14+2=16, classes 4+1=5, journey 9+2=11…). ✅

> Phiên KHÔNG có nghiệm thu login (không đụng app). Verify = đối chiếu số dump vs audit (D90).

---

## 5. ⭐ BẢNG TÀI KHOẢN TEST (mỗi lần nhờ test PHẢI ghi email kèm)

> Tất cả `@demo.demenart.com`, password **`Test@123`** (auto-confirm), trừ super_admin (password của Jean) + 2 login giữ-từ-v22 dùng password tạm.

| Vai | Email | Người / Trường | Land sau login (v26) |
|---|---|---|---|
| **Admin nền tảng** | `info@demenart.com` | Quản trị viên Test · super_admin | **`/admin`** |
| **Master KHM** | `hieutruong.kidshouse@demo.demenart.com` | Huỳnh Trần Nguyệt Thi · KHM | `/school` |
| **GV KHM** | `gv.linh.kidshouse@demo.demenart.com` | Đặng Mỹ Linh · KHM | `/teacher/curriculum` |
| **PH KHM** (2-con An+Khang) | `ph.hung.kidshouse@demo.demenart.com` | Nguyễn Văn Hùng · school NULL | `/parent/journal` |
| **Master MNDM** | `hieutruong.demen@demo.demenart.com` | Mai Phương Dung · MNDM | `/school` |
| **GV MNDM** | `gv.han.demen@demo.demenart.com` | Bùi Ngọc Hân · MNDM | `/teacher/curriculum` |
| **PH MNDM** (2-con Hà+Phúc) | `ph.thanh.demen@demo.demenart.com` | Đặng Văn Thành · school NULL | `/parent/journal` |
| GV KHM (giữ v22, password tạm) | `gv.my.kidshouse@demo.demenart.com` | Lê Thảo My · KHM | `/teacher/curriculum` |
| PH KHM (giữ v22, password tạm) | `ph.toan.kidshouse@demo.demenart.com` | Trần Quốc Toản · KHM | `/parent/journal` |

> **DEMO-001 (sandbox, login chưa gắn — `user_id` NULL trong seed, phục hồi xong re-invite):** master `master.demo@demenart.com` · GV `teacher.demo@demenart.com` (Cô Thúy Ngân Demo) · PH `parent.demo@demenart.com` (Bé Jenny/Jimmy).

---

## 6. VIỆC TREO (ưu tiên giảm dần)

1. 🟡 **Dead-link nhẹ `/admin`** (nợ §6 v26): nút "← Quay lại" `admin.modules.tsx` còn `to="/portal"` → đổi `to="/admin"` (bare `/portal` index đã xóa → outlet rỗng). + cosmetic text "/portal/curriculum"→"/teacher/curriculum" trong `admin.curriculum-admin.tsx` (chỉ text, không link).
2. 🟡 **Rough edge GV read-only** (nợ từ v25): GV ở `/school` tab Trẻ&PH bấm 1 bé → `ParentsPanel` gọi `get_child_parents` gate master/sub (D92) → GV thấy toast "không có quyền" + PH rỗng. **Sửa:** nới gate cho lead/assistant same-school (read-only) HOẶC ẩn panel khi `!canManage`.
3. **GV/PH pilot còn lại chưa login** (4 GV + 9 PH) → mời nốt qua app khi cần (engine D93 đủ).
4. **2 file nhạc curriculum gốc chưa nguồn lưu** (file `.mp3` thật, KHÔNG phải SQL — re-upload là tạo lại, không nằm trong seed) · **Vercel project dormant** xóa được.

> ✅ **Đã gạch phiên này (Ngã B):** trả nợ repo `044` + 2 Edge `invite_staff`/`invite_parent` (dump trung thực D90) · tổ chức lại seed theo phạm vi (`seed_000_global_foundation` thay `seed_007` lẻ + `seed_demo001_fixtures`) · **giỏ nợ repo code+data SẠCH.**

---

## 7. NGÃ KẾ — ĐỀ XUẤT

- **⭐ A — Vá rough edge GV read-only** (§6.2) — nới `get_child_parents` cho lead/assistant same-school read-only HOẶC ẩn `ParentsPanel` khi `!canManage`. *(Phiên nhỏ, đóng rough edge tồn từ v25.)*
- **B — UI/UX polish pass** (đã hoãn tới khi xong engine V1 — Ngã A đã khép): thống nhất accent nội-thân từng cổng (vd `school.index` đang amber → emerald); mượt **mobile nav** (4 cổng đều `hidden sm:inline-flex` → mobile mất nav); vá 2 dead-link/cosmetic §6.1.
- **C — Khởi động `/kid` V2** (trẻ vào bằng PIN, ba mẹ duyệt) — thép chờ #2 đã để ngỏ `children.identity_user_id`; namespace `/kid` đã reserved. *(Bước lớn, sang "tầng 2".)*

**Boot phiên sau:** đọc HANDOFF v27 → audit live DB/route thật (D1) trước khi viết.

---

## 8. DATA STATE CẦN NHỚ (bẫy cho phiên sau — GIỮ từ v23/v24)

- **KHM-DN `sharing_mode=private_share_link`** (KHÔNG phải `no_external_sharing`). **DEMO-001 `sharing_mode=no_external_sharing`** (giữ trong seed_demo001).
- **Consent An `private_share_link` (`d1…e1`) = GRANTED** (đổi WITHDRAWN→GRANTED ở v23 để test, để vậy) **+ download consent An bật.**
- **DEMO-001 (trong seed_demo001, trung thực D90):** 1 moment `draft` (Jenny tập trống) · consent `demen_marketing granted=false` · 2 media trỏ `bunny_path` (file Bunny có thể cần re-upload sau phục hồi). KHÔNG "dọn đẹp".
- **3 tenant / 3 master** (DEMO-001 1lớp/2trẻ · KHM 2/8 · MNDM 2/6 = 5 lớp/16 trẻ).
- **DEMO-001 dùng UUID NGẪU NHIÊN** (`b6a4ac35…`), KHÔNG prefix sạch như pilot (`d1…`/`d2…`) → lọc tenant bằng FK-ngược, KHÔNG prefix (D96).
- **PH 051 mỗi trường = 2-con-xuyên-lớp** (persona multi-child, CÙNG-trường).
- **Role PH thật trong DB = `primary_parent`** (`homePathForRole` để ngỏ cả `secondary_parent`).
- **2 login giữ từ v22:** GV Lê Thảo My + PH Trần Quốc Toản.
- **`link_role` lưu CODE** `mother`/`father`/`guardian`; legacy seed = `primary`/`secondary` (UI render cả hai).
- **`master_admin` ∈ `is_school_admin()`**; PH `school_id=NULL` cần RPC curated cho ghi (D29) lẫn đọc (D92).
- **`school.index` giữ `ssr:false`**; shell `{admin,school,teacher,parent}.tsx` KHÔNG đặt ssr:false (kế thừa guard pathless `_authenticated/route.tsx`).
- **`/portal` = shell hạ-tầng** (notifications+support); KHÔNG vai nào land thẳng (else→`/admin`). Brand không-link.
- **Engine media-nhạy-cảm = 5 gate secdef nhận-tham-số:** consent ảnh trẻ (D71) · entitlement học liệu (D75) · upload (D77) · share (D87) · revoke (D94).
- **⭐ Repo dump trung thực (D90/D96):** mọi backup từ live, KHÔNG chép tay; seed tổ chức theo phạm vi (global → tenant), thứ tự phục hồi global-TRƯỚC.

---

> **KỶ LUẬT VÀNG:** đã cập nhật **RULES** (thêm D96 — dump seed theo phạm vi + bẫy albums-child-branch + bẫy query_to_xml-câm + thứ tự phục hồi global-trước; footer v27) + **SYSTEM_MAP** (note v27 ở footer, **KHÔNG bump v0.26** — phiên repo thuần) trong phiên này. **3 file xuất kèm:** `DMA_HANDOFF_v27.md` · `DMA_RULES.md` · `DMA_SYSTEM_MAP.md`. **5 file repo Jean đã lưu tay:** `044_revoke_share_link.sql` · `invite_staff.ts` · `invite_parent.ts` · `seed_000_global_foundation.sql` · `seed_demo001_fixtures.sql` (+ xóa `seed_007` lẻ). **KHÔNG file SQL/Edge MỚI phát sinh** (phiên repo thuần). **START_HERE: KHÔNG đổi.** **Tài liệu A–G, BUILD_PATH, DMWS_REFERENCE: KHÔNG đổi.**
