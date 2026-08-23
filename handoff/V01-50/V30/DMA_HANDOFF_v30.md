# 🤝 DMA_HANDOFF_v30.md — BÀN GIAO PHIÊN (BUILD TEACHER PORTAL V1 — HOME "CLASSROOM COMPANION" SỐNG — 2026-06-28 17:47 GMT+7)

> **Cách dùng:** File này = ảnh chụp trạng thái cuối phiên v30. Boot phiên sau:
> `00_START_HERE` → `RULES` → file này. Rồi audit DB/code thật trước khi viết.
> **Naming:** DMA = nền tảng; CTAN = sản phẩm đầu. Không "DMMA".

---

## 1. LÀM GÌ PHIÊN NÀY

Phiên **BUILD** đầu tiên của Teacher Portal V1 (dịch đặc tả v29 §8 thành app thật). Đi đúng D1: **audit DB/route sống TRƯỚC → engine → dịch Lovable → nghiệm thu login thật.**

**(A) Audit D1 trọn** (Jean chạy SQL, dán JSON):
- `child_observations` ĐỦ cột wire Điểm danh+Ghi nhận (`attendance` text · `skills_observed` jsonb · `note` · `linked_moment_ids` jsonb · `is_highlight`/`needs_support`/`follow_up_needed` bool · `visibility` default `private_internal`) — KHÔNG cần engine mới.
- Đường moment→consent→media ĐỦ: `learning_moments`→`moment_children`→`media_assets.linked_moment_id`; consent qua `consents`; engine MIN = `media_consent_check(p_moment_id, p_viewer, p_action)` definer.
  - ⚠️ **Đính chính RULES:** hàm gác upload thật = **`check_media_upload_access`** (KHÔNG phải `check_curriculum_upload_access`).
- `prep_items` CHƯA tồn tại (`existing_prep_tables=[]`) → grain chốt = **`lesson_sessions(id)`** (cùng cụm Sessions D53; `lesson_versions`=template loại, `class_distributions`=quá thô loại).
- Enum thật: `session_state` (scheduled/prep_ready/in_progress/taught_report_pending/report_pending_approval/completed/cancelled/rescheduled/makeup) · `enrollments.state` (active/paused/transferred_*/ended/graduated).
- Helper signatures xác nhận: `same_school(uuid)`/`session_school_id(uuid)`/`is_session_lead(uuid)`/`is_session_teacher(uuid)`/`is_admin()` đều **definer** (an toàn gọi trong RPC definer); **`is_school_admin()` = invoker** (tránh dùng).

**(B) Migration 046 — `prep_items` + `get_session_readiness` (3 khối D92):**
- Bảng `prep_items` (id · session_id FK→lesson_sessions ON DELETE CASCADE · label · is_ready · sort_order · created_by · created_at). RLS gương `session_media` (READ admin|same-school; INSERT/UPDATE/DELETE lead|assistant).
- RPC `get_session_readiness(p_session_id)` → trả `status` (1 field UI đọc map pill+CTA §8b) + `prep{ready,total}`. **Precedence: tiến trình (state) TRƯỚC → readiness 4-cạnh SAU.** Map: cancelled/rescheduled→`cancelled`; completed→`completed`; taught_report_pending/report_pending_approval→`report_pending`; in_progress→`in_progress`; (scheduled/prep_ready/makeup) → lead NULL→`unassigned` · lesson_version NULL hoặc 0 media active→`missing_materials` · có version published cao hơn cùng lesson→`needs_update` · else→`ready`.
- **Nghiệm thu login thật ĐẠT** (GV Mỹ Linh): 3 buổi test READY/MISSING/IN_PROGRESS → REST `200` đúng `status` + `prep{ready:1,total:3}` cho READY.

**(C) Migration 046b — `get_teacher_home()` (3 khối D92):**
- 1-call cho Home: tìm "tiết hôm nay" của GV (lead HOẶC `session_teachers`) + "tiết kế tiếp" + `today_count`, **gói sẵn `readiness`** mỗi buổi (gọi `get_session_readiness` bên trong), kèm `class_name`/`program_name`/`child_count` (đếm `enrollments` active).
- **Nghiệm thu login thật ĐẠT:** trả `today_count:3` · `today_session` lớp "Hoa Hồng" / "Cảm Thụ Âm Nhạc Dế Mèn" / 4 bé / readiness `ready` prep 1/3 · `next_session:null`.

**(D) UI Home V1 — dịch Lovable (full paste-over, D5):**
- `teacher.tsx` (shell): re-token sky→**ngà `#FBF8F1` / xanh rừng `#149A76` / mật ong `#EFA63A`**; mark dế hình học gọn; header gọn (Hỗ trợ + chuông badge mật ong); **bottom nav 5 tab mobile** (Hôm nay·Lớp·Giáo án·Nhật ký·Hồ sơ) — Lớp/Nhật ký/Hồ sơ chưa có route → **toast "Sắp ra mắt"** (Quyết B Jean: render đủ 5 tab cửa-khoá, D98 cửa-khoá-để-sẵn).
- `teacher.index.tsx` (Home "Classroom Companion"): 7 khối (greeting "X tiết" · Hero card state-aware pill+CTA · prep preview 1/3 thanh mật ong · Việc-cần-làm 4 dòng [count=0 placeholder, 047 sau] · 4 quick action · lớp tiếp theo · Cần hỗ trợ 4 lỗi) + empty state ngày trống.
- **Nghiệm thu login thật ĐẠT** (GV Mỹ Linh, Lovable Preview): mọi khối render đúng; pill "Giáo án sẵn sàng" xanh + CTA "Bắt đầu buổi học"; bottom nav 5 tab hiện khi thu hẹp + toast "Lớp · Sắp ra mắt" chạy.

> **D99 MỚI (RULES):** pattern engine readiness + bài học test login thật qua REST (xem RULES D99). Mockup→production: đặc tả v29 dịch thành engine+UI thật, verify từng bước login thật.

---

## 2. TRẠNG THÁI THẬT CUỐI PHIÊN

- **DB cấu trúc (CÓ ĐỔI phiên này):** **47 bảng** (+`prep_items`) · **52 hàm SECURITY DEFINER** (+`get_session_readiness`, +`get_teacher_home`) · **129 RLS policy** (+4 cho `prep_items`) · **mig 001→046b** · seed 001→012. SYSTEM_MAP **v0.27** (bump — thêm bảng+hàm).
- **Edge Functions (6 — KHÔNG đổi):** `get_signed_media_url` · `upload_media` · `resolve_share_link` · `invite_master` · `invite_staff` · `invite_parent`.
- **Routes app:** 5 cổng `/parent`(amber)·`/teacher`(**re-token ngà/xanh-rừng/mật-ong** — bỏ accent sky)·`/school`(emerald)·`/admin`(slate) + `/portal` shell hạ-tầng + `/kid` reserved V2. `/share/$token` public. **Route teacher mới có:** `teacher.tsx` (shell sửa) + `teacher.index.tsx` (Home thật — trước là redirect-hop). `teacher.curriculum.tsx`/`teacher.moments.tsx` KHÔNG đổi.
- **3 tenant / 3 master** (DEMO-001 · KHM-DN · MNDM-DN).

> Lưu ý: accent `/teacher` LIVE đã đổi từ sky → hệ ngà/xanh-rừng/mật-ong (chỉ ở 2 file teacher; các cổng khác giữ accent cũ — sẽ re-token khi build từng cổng).

---

## 3. FILE PHIÊN NÀY

**Migration (Jean lưu repo từ live):**
- `046_prep_items_and_readiness.sql` — bảng `prep_items` + 4 RLS + RPC `get_session_readiness` + grants (3 khối CREATE→REVOKE/GRANT→VERIFY; có khối 2b gỡ `anon` execute — bài học D99).
- `046b_get_teacher_home.sql` — RPC `get_teacher_home` + grants (3 khối D92).

**UI (Jean áp Lovable tay, full paste-over):**
- `src/routes/_authenticated/teacher.tsx` (shell re-token + bottom nav 5 tab + toast Sắp-ra-mắt).
- `src/routes/_authenticated/teacher.index.tsx` (Home V1 "Classroom Companion" — wire `get_teacher_home`).

**3 file library xuất kèm (Jean lưu tay):**
- `DMA_HANDOFF_v30.md` (file này).
- `DMA_RULES.md` (thêm **D99** + footer v30).
- `DMA_SYSTEM_MAP.md` (**bump v0.27** — +`prep_items`, +2 hàm, +4 policy + footer v30).

**START_HERE: KHÔNG đổi. Tài liệu A–G, BUILD_PATH, DMWS_REFERENCE: KHÔNG đổi.**

---

## 4. NGHIỆM THU (login thật — D2/D3)

- ✅ **046 readiness:** GV Mỹ Linh gọi REST `get_session_readiness` 3 buổi → `200` + status đúng (ready/missing_materials/in_progress); READY prep `{ready:1,total:3}`; gate same-school qua; `lead_teacher_id` resolve đúng (`…011`).
- ✅ **046b home:** GV Mỹ Linh gọi REST `get_teacher_home` → `200` shape đúng (today_count:3 · today_session lớp Hoa Hồng/CTAN/4 bé/readiness ready · next:null).
- ✅ **Grants sạch D15:** cả 2 hàm chỉ `postgres·service_role·authenticated` (gỡ `anon` — D99).
- ✅ **UI Home V1** (Lovable Preview, GV Mỹ Linh): greeting "Chào cô Linh · CN 28/6 · 3 tiết" · Hero card đầy đủ (pill môn + pill "Giáo án sẵn sàng" + Hoa Hồng + 16:20 · 4 bé + luồng 4 bước + CTA "Bắt đầu buổi học" xanh) · prep 1/3 thanh mật ong · 4 quick action · support 4 dòng · tokens ngà/xanh/mật-ong đúng D98.
- ✅ **Bottom nav 5 tab + cửa khoá** (thu hẹp <640px): 5 tab hiện, tab Hôm nay active xanh; gõ Lớp/Nhật ký/Hồ sơ → toast "Sắp ra mắt" (Quyết B).

> **Phương pháp test (D99):** app TanStack KHÔNG expose `window.supabase` → gọi RPC qua REST `POST /rest/v1/rpc/<fn>` với header `apikey`=ANON KEY (KHÔNG phải JWT) + `Authorization: Bearer <access_token từ localStorage sb-*-auth-token>`. Anon key decode có `role:anon` (khác JWT có email/sub). Lấy anon key từ Network tab → Request Headers → `apikey`.

---

## 5. ⭐ BẢNG TÀI KHOẢN TEST (mỗi lần nhờ test PHẢI ghi email + password kèm)

> Tất cả `@demo.demenart.com`, password **`Test@123`** (auto-confirm), trừ super_admin (password của Jean) + 2 login giữ-từ-v22 dùng password tạm.

| Vai | Email | Người / Trường | Land sau login |
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

> **DEMO-001 (sandbox, login chưa gắn — `user_id` NULL trong seed):** master `master.demo@demenart.com` · GV `teacher.demo@demenart.com` · PH `parent.demo@demenart.com` (Bé Jenny/Jimmy).

> **Seed test phiên này (CHƯA dọn — giữ để demo Home):** 3 buổi `[v29-test]` dưới cd `d1000000-…-31` (lớp Hoa Hồng, GV Mỹ Linh lead): `aaaa0000-…-a0001` READY (prep 3 mục, 1 ready) · `…-a0002` MISSING · `…-a0003` IN_PROGRESS. Dọn bằng nhãn `[v29-test]` (xóa lesson_sessions like '[v29-test]%' → cascade prep_items) khi không cần demo.

---

## 6. VIỆC TREO (ưu tiên giảm dần)

1. 🟢 **Migration 047 — count "Việc cần làm" (Dashboard-LITE, Quyết B v28):** RPC đếm 4 số (lớp chưa điểm danh · nhật ký chờ gửi · ảnh chưa gắn bé · phản hồi PH mới) → wire vào `TodoSection` (hiện placeholder `—`). + reaction **"Lời cảm ơn"** (flex, thay chat PH↔GV V1, Quyết C).
2. 🟢 **Build luồng 4 bước** (CTA Home chưa wire onClick — màn đích chưa dựng): Bước 1 Chuẩn bị (checklist `prep_items` tick-được + "Báo thiếu học liệu"→`support_requests` D75) → Bước 2 Lesson Player → Bước 3 Ghi nhận (3 tab: Điểm danh·Ghi nhận tap-first·Ảnh-gắn-bé MIN consent) → Bước 4 Review-trước-gửi.
3. 🟡 **Dọn seed `[v29-test]`** (giữ tạm để demo Home — xóa khi xong luồng).
4. 🟡 **Chốt chính thức 1 linh vật** (chrome=mark hình học gọn đã dùng ở `teacher.tsx`; illustration/empty/sent=dế tròn-cute — cần Jean lock dứt khoát).
5. 🟡 **Land GV về `/teacher`** (Home) thay vì `/teacher/curriculum`: sửa `homePathForRole` lead/assistant → `/teacher`.
6. **GV/PH pilot còn lại chưa login** (4 GV + 9 PH) · **2 file nhạc curriculum gốc chưa nguồn lưu** (`.mp3`) · **Vercel project dormant** xóa được.

> ✅ **Đã gạch phiên này:** audit D1 trọn · mig 046 (`prep_items`+readiness) · mig 046b (`get_teacher_home`) · UI Home V1 "Classroom Companion" (re-token + bottom nav 5 tab + 7 khối) · nghiệm thu login thật toàn bộ · D99.
> ✅ **Đóng từ trước:** Ngã A 4/5 cổng tách (v24–26) · giỏ nợ repo SẠCH (v27) · mig 045 vá rough edge GV (v28) · chốt north-star + lộ trình + khoá V1 scope (v28) · thiết kế Teacher V1 trọn bộ D98 (v29).

---

## 7. NGÃ KẾ — ĐỀ XUẤT

**Tiếp BUILD Teacher V1:** ⭐ **Migration 047 (count "Việc cần làm")** — engine cuối còn thiếu cho Home, gọn (1 RPC đếm), wire ngay vào `TodoSection` đã render sẵn. Rồi **luồng 4 bước** (việc lớn — nhiều màn, làm theo cụm).

- **⭐ Bước 1 — Mig 047:** RPC `get_teacher_todo_counts()` đếm 4 số trong scope GV (lớp hôm nay chưa có `child_observations` đủ roster · session state `taught_report_pending` chờ gửi · `media_assets`/`learning_moments` chưa `moment_children` · reaction "Lời cảm ơn" mới — nếu chưa có bảng reaction thì đếm 0 + để hook). Audit D1 trước: soi cách xác định "chưa điểm danh" (so roster `enrollments` active vs `child_observations` có `attendance`).
- **Bước 2 — Luồng 4 bước:** dựng route `teacher.session.$id.*` (hoặc tương tự) cho Chuẩn bị/Player/Ghi nhận/Review; wire CTA Home onClick. Engine phần lớn ĐÃ CÓ (child_observations · moments · consent · upload).

**Boot phiên sau:** đọc HANDOFF v30 → audit live DB/route thật (D1) trước khi viết. Đóng bằng HANDOFF v31.

---

## 8. ⭐ ENGINE ↔ UI (map hiện trạng — nguồn sự thật cho BUILD tiếp)

### 8a. Đã wire sống (login thật ĐẠT)
- ✅ **Home 1-call** = `get_teacher_home()` (mig 046b) → `teacher.index.tsx`. Trả today_count · today_session(+readiness) · next_session.
- ✅ **Readiness** = `get_session_readiness(session_id)` (mig 046) → status map pill+CTA §8b + prep{ready,total}.
- ✅ **Prep checklist** = bảng `prep_items` (mig 046, grain `lesson_sessions`). RLS lead/assistant write, same-school read.

### 8b. Đã có engine, CHƯA wire UI (cho luồng 4 bước)
- ✅ **Điểm danh + Ghi nhận** = `child_observations` (attendance · skills_observed · is_highlight · needs_support · follow_up_needed · note · linked_moment_ids · visibility). RLS D53.
- ✅ **Ảnh + gắn bé + consent** = `learning_moments`→`moment_children`→`media_assets.linked_moment_id` + `media_consent_check` D71 (MIN) + Edge `upload_media`/`get_signed_media_url`. Gate upload = `check_media_upload_access` (D77).
- ✅ **Gửi nhật ký → PH** = approval (nếu trường bật) + parent view (approved+consent+MIN) — engine có, cần wire.

### 8c. Engine CHƯA có (phát sinh tiếp)
- ❌ **Count "Việc cần làm" (4 số)** = RPC `get_teacher_todo_counts` (mig 047 — Dashboard-LITE Quyết B). `TodoSection` đang placeholder `—`.
- ❌ **"Báo thiếu học liệu"** (CTA missing_materials) = ghi `support_requests` (category curriculum, self-insert sẵn) — KHÔNG bảng mới. GV KHÔNG thay học liệu (IP Dế Mèn D75).
- ❌ **Reaction "Lời cảm ơn"** = bảng reaction mới (flex, Quyết C — thay chat PH↔GV V1; chat thật = V2).

### 8d. Design tokens `/teacher` V1 (đã áp 2 file teacher)
- Nền **ngà `#FBF8F1`** · thẻ trắng `#FFFFFF` bo 16–18px · viền `#EFE7D6`.
- Primary = **xanh rừng `#149A76`** (nút chính chữ trắng) · text đậm `#0F6E56`.
- Accent = **mật ong `#EFA63A`** = "chỗ cần để mắt" (badge/tiến độ/chấm noti/CTA cần-xử) · bg mật-nhạt `#FCEFD6` · text `#8A5410`.
- Xám trung tính `#9A9183`/`#6B6357` cho phụ/khoá. Dế = mark hình học gọn (SVG inline trong header).

### 8e. Data state (bẫy — GIỮ từ v23/v28/v29)
- **KHM-DN `sharing_mode=private_share_link`** · **DEMO-001 `no_external_sharing`**.
- **Consent An `private_share_link` (`d1…e1`) = GRANTED** + download consent An bật.
- **DEMO-001 trung thực D90:** 1 moment `draft` · consent `demen_marketing granted=false` · 2 media `bunny_path`; UUID NGẪU NHIÊN → lọc tenant FK-ngược (D96).
- **PH 051 mỗi trường = 2-con-xuyên-lớp.** Role PH thật = `primary_parent`.
- `master_admin` ∈ `is_school_admin()`; PH `school_id=NULL` → RPC curated. GV same-school read-only `get_child_parents` (mig 045).
- `school.index` giữ `ssr:false`; shell KHÔNG đặt ssr:false. Auth-gated fetch = client-side `useEffect` (JWT NULL khi SSR — D-trap).
- Engine media-nhạy-cảm = 5 gate secdef: consent (D71) · entitlement (D75) · upload (D77) · share (D87) · revoke (D94).
- **GV Mỹ Linh** (`…011`) lead 2 distribution: cd `d1000000-…-31` (lớp Hoa Hồng `…21`) + cd `8c6bb771…` (lớp `f253ea00…`); KHÔNG có lesson_sessions thật trước phiên này (3 buổi `[v29-test]` là seed).

---

> **KỶ LUẬT VÀNG:** đã cập nhật **RULES** (thêm **D99** — engine readiness pattern + test login thật qua REST anon-key; footer v30) + **SYSTEM_MAP** (**bump v0.27** — +`prep_items` +2 hàm +4 policy; footer v30) trong phiên này. **5 file xuất kèm:** 2 migration repo (`046`, `046b`) + 2 UI (Jean áp Lovable) + 3 library (`HANDOFF_v30` · `RULES` · `SYSTEM_MAP`). **START_HERE: KHÔNG đổi.** **Tài liệu A–G, BUILD_PATH, DMWS_REFERENCE: KHÔNG đổi.**
