# 🤝 DMA_HANDOFF_v31.md — BÀN GIAO PHIÊN (BUILD TEACHER V1 CỤM 1+2 — LUỒNG 4 BƯỚC: CHUẨN BỊ + PLAYER SỐNG — 2026-06-28 19:35 GMT+7)

> **Cách dùng:** File này = ảnh chụp trạng thái cuối phiên v31. Boot phiên sau:
> `00_START_HERE` → `RULES` → file này. Rồi audit DB/code thật trước khi viết (D1).
> **Naming:** DMA = nền tảng; CTAN = sản phẩm đầu. Không "DMMA".

---

## 1. LÀM GÌ PHIÊN NÀY

Tiếp BUILD Teacher Portal V1 từ v30: **wire engine "Việc cần làm" + dựng luồng 4 bước (Cụm 1 Chuẩn bị + Cụm 2 Player).** Đi đúng D1: audit DB sống TRƯỚC → engine 3-khối D92 → dịch Lovable → nghiệm thu login thật.

**(A) Mig 047 — `get_teacher_todo_counts()` (Dashboard-LITE, wire `TodoSection`):**
- Audit D1 chốt 4 số KHÔNG cần bảng mới: `attendance_pending` (buổi hôm nay in_progress/taught_report_pending mà roster `enrollments` active chưa đủ `child_observations.attendance`) · `journal_pending` (state `taught_report_pending`) · `photos_untagged` (moment của tôi draft/needs_revision có media active chưa `moment_children`) · `parent_replies` (=0 hook — chưa có bảng reaction).
- Scope GV gương `get_teacher_home` (lead distribution OR session_teachers). 3 khối D92, leaky=[].
- UI: số>0 badge **mật ong** (parent xanh-rừng); =0 mờ+`—`; total=0 → "Mọi việc đã xong 🎉".
- **Nghiệm thu login thật ĐẠT** (GV Mỹ Linh, REST anon-key D99): `attendance_pending:1` đúng (buổi a0003 in_progress chưa điểm danh) → UI badge mật ong số 1, 3 dòng còn lại mờ.

**(B) Mig 048 — `get_session_detail` + `start_session` (cụm RPC session, D101):**
- `get_session_detail(session_id)` = **1-call màn session**, gọi `get_session_readiness` BÊN TRONG + prep_items[] + class_name/program_name/child_count, gate same-school|admin.
- `start_session(session_id)` = state scheduled/prep_ready/makeup→`in_progress` + `taught_by`, gate **người-trong-phòng** (`is_session_lead OR is_session_teacher` — vì RLS base lesson_sessions UPDATE chỉ cho lead, muốn assistant "vào dạy" phải qua RPC); in_progress→idempotent; audit `session_started` bọc EXCEPTION-NULL. 4 khối D92, leaky=[].

**(C) Mig 049 — `get_session_curriculum` (Player Bước 2, D101/D75):**
- Lọc track của buổi (`media_assets.linked_lesson_version_id = lesson_sessions.lesson_version_id` + access_level private_curriculum + state active) + gate same-school|admin + EXISTS entitlement môn active (gương `list_curriculum_media` D73). Trả `{ok,tracks[]}`. 3 khối D92, leaky=[].

**(D) Mig 050 — `get_teacher_home` CREATE OR REPLACE (vá tie-break, D101):**
- Rough edge v30: nhiều buổi CÙNG GIỜ (seed 3 buổi 09:20) → `order by scheduled_at` pick nhầm → mất CTA "Tiếp tục buổi học". Vá: `order by case state when 'in_progress' then 0 ... end, scheduled_at, id` → ưu tiên buổi đang dạy.
- ⚠️ CREATE OR REPLACE reset grants → BẮT BUỘC re-HARDEN (D15). leaky=[].

**(E) UI — dịch Lovable (full paste-over D5):**
- `teacher.index.tsx`: wire counts vào `TodoSection` + CTA Hero `onClick`→navigate `/teacher/session/$id` + PrepPreview link session.
- **Route MỚI** `teacher.session.$id.tsx`: **1 route + step state nội-bộ** (KHÔNG đẻ 4 sub-route — D101/D100) · stepper 4 bước · **Bước 1 Chuẩn bị** (checklist `prep_items` tick được [client UPDATE thẳng] + "Báo thiếu học liệu"→`support_requests` [client INSERT thẳng, D57] + "Vào dạy"→`start_session`) · **Bước 2 Player** (get_session_curriculum + get_signed_media_url qua invoke + watermark trôi + nodownload, mượn pattern v13) · Bước 3/4 placeholder.
- **Nghiệm thu login thật ĐẠT** (GV Mỹ Linh, Lovable Preview + deploy): tick prep 1/3→2/3 ghi thật · báo thiếu→"Đã gửi báo cáo" (support_requests row) · "Vào dạy"→a0001 in_progress sang Bước 2 · player 2 track "Chú Vịt Con" phát thật + watermark "DMA·CTAN·Đà Nẵng·gv.linh…·19:31 28/6" · tie-break Home→a0001 "Đang diễn ra"+CTA "Tiếp tục buổi học".

> **D101 MỚI (RULES):** luồng đa-bước = 1 route step-nội-bộ + cụm RPC session + tie-break Home + client-ghi-thẳng-khi-RLS-cho-phép.

---

## 2. TRẠNG THÁI THẬT CUỐI PHIÊN

- **DB cấu trúc (hàm CÓ ĐỔI phiên này):** **47 bảng** (KHÔNG đổi) · **56 hàm SECURITY DEFINER** (+4: `get_teacher_todo_counts`·`get_session_detail`·`start_session`·`get_session_curriculum`; `get_teacher_home` = CREATE OR REPLACE, +0) · **129 RLS policy** (KHÔNG đổi — mig 047–050 thuần hàm) · **mig 001→050** · seed 001→012. SYSTEM_MAP **v0.28** (bump — +4 hàm).
- **Edge Functions (6 — KHÔNG đổi):** `get_signed_media_url` · `upload_media` · `resolve_share_link` · `invite_master` · `invite_staff` · `invite_parent`.
- **Routes app:** 5 cổng `/parent`(amber)·`/teacher`(ngà/xanh-rừng/mật-ong)·`/school`(emerald)·`/admin`(slate) + `/portal` shell hạ-tầng + `/kid` reserved V2. `/share/$token` public. **Route teacher mới có:** `teacher.session.$id.tsx` (luồng 4 bước). `teacher.tsx`/`teacher.index.tsx`/`teacher.curriculum.tsx`/`teacher.moments.tsx` đã có (teacher.index sửa phiên này).
- **3 tenant / 3 master** (DEMO-001 · KHM-DN · MNDM-DN).

> **Seed `[v29-test]` a0001 đổi state:** sau `start_session` test, buổi a0001 (lớp Hoa Hồng) giờ `in_progress` (trước là scheduled). Home pick a0001 "Đang diễn ra". Dọn seed khi xong luồng.

---

## 3. FILE PHIÊN NÀY

**Migration (Jean lưu repo từ live):**
- `047_get_teacher_todo_counts.sql` — RPC đếm 4 số (3 khối CREATE→REVOKE/GRANT→VERIFY).
- `048_session_detail_and_start.sql` — `get_session_detail` + `start_session` (4 khối: 2 CREATE → HARDEN chung → VERIFY chung).
- `049_get_session_curriculum.sql` — RPC track của buổi (3 khối).
- `050_get_teacher_home_tiebreak.sql` — `get_teacher_home` CREATE OR REPLACE + re-HARDEN (3 khối).

**UI (Jean áp Lovable tay, full paste-over):**
- `src/routes/_authenticated/teacher.index.tsx` (wire counts + CTA navigate).
- `src/routes/_authenticated/teacher.session.$id.tsx` (MỚI — luồng 4 bước: Bước 1 + Bước 2 thật, Bước 3/4 placeholder).

**3 file library xuất kèm (Jean lưu tay):**
- `DMA_HANDOFF_v31.md` (file này).
- `DMA_RULES.md` (thêm **D101** + footer v31).
- `DMA_SYSTEM_MAP.md` (**bump v0.28** — +4 hàm + 5 hàng migration 046–050 + footer v31).

**START_HERE: KHÔNG đổi. Tài liệu A–G, BUILD_PATH, DMWS_REFERENCE: KHÔNG đổi.**

---

## 4. NGHIỆM THU (login thật — D2/D3)

- ✅ **047 counts:** GV Mỹ Linh REST `get_teacher_todo_counts` → `200` `{counts:{attendance_pending:1,journal_pending:0,photos_untagged:0,parent_replies:0},total:1}`; UI Home badge mật ong "Lớp chưa điểm danh = 1", 3 dòng mờ+`—`.
- ✅ **048 detail+start:** màn session a0001 render (Hero CTAN/Hoa Hồng/4 bé) · tick prep 1/3→2/3 (prep_items UPDATE) · báo thiếu→support_requests row · "Vào dạy"→a0001 state `in_progress` + taught_by `…011` + sang Bước 2.
- ✅ **049 player:** Bước 2 liệt kê 2 track "Chú Vịt Con" (đúng lesson_version_id 47c5…013c) · "Phát"→signed URL zone dma-learning→audio phát + watermark trôi + nodownload · "Tiếp tục — Ghi nhận"→Bước 3.
- ✅ **050 tie-break:** reload `/teacher` → Home pick a0001 "Đang diễn ra" + CTA "Tiếp tục buổi học" (trước v50 pick nhầm a0002 MISSING).
- ✅ **Grants sạch D15:** cả 4 hàm leaky=`[]` (revoke public+anon — D99).

> **Phương pháp test (D99):** app TanStack KHÔNG expose `window.supabase` → gọi RPC qua REST `POST /rest/v1/rpc/<fn>` header `apikey`=ANON KEY (KHÔNG JWT→401) + `Authorization: Bearer <access_token từ localStorage sb-*-auth-token>`. Anon key ref `xcvhacymrbhdhohyylyq` (decode `role:anon`). UI player/start test qua Lovable Preview (login GV thật).

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

> **DEMO-001 (sandbox, login chưa gắn):** master `master.demo@demenart.com` · GV `teacher.demo@demenart.com` · PH `parent.demo@demenart.com` (Bé Jenny/Jimmy).

> **Seed test `[v29-test]` (CHƯA dọn — giữ demo luồng):** 3 buổi dưới cd `d1000000-…-31` (lớp Hoa Hồng, GV Mỹ Linh lead): `aaaa0000-…-a0001` **giờ `in_progress`** (prep 3 mục, 2 ready sau test — start_session đã chạy) · `…-a0002` MISSING (scheduled) · `…-a0003` IN_PROGRESS (scheduled→seed). Dọn bằng nhãn `[v29-test]` (xóa lesson_sessions like → cascade prep_items) khi không cần demo.

---

## 6. VIỆC TREO (ưu tiên giảm dần)

1. 🟢 **Cụm 3 — Bước 3 Ghi nhận (VIỆC NẶNG NHẤT):** 3 tab con — **Điểm danh** (`child_observations.attendance` so roster) · **Ghi nhận tap-first** (skills_observed jsonb chạm-chọn + is_highlight/needs_support/follow_up_needed, chữ là phụ) · **Ảnh-gắn-bé** (moment→moment_children→media_assets, MIN consent D71/D47, upload qua `upload_media` D77). CTA Bước 2 "Tiếp tục — Ghi nhận" hiện trỏ Bước 3 placeholder. Engine phần lớn ĐÃ CÓ (child_observations · moments · consent · upload) — audit D1 trước.
2. 🟢 **Cụm 4 — Bước 4 Review & gửi:** màn "Xem lại Bước 4/4 TRƯỚC khi gửi" (KHÔNG gửi thẳng — D98) → approval (nếu trường bật) → PH view. Transition `in_progress→taught_report_pending` đặt ở đây. Engine có.
3. 🟢 **Reaction "Lời cảm ơn"** (bảng reaction mới, flex — thay chat PH↔GV V1, Quyết C). `parent_replies` đang hook=0.
4. 🟡 **Dọn seed `[v29-test]`** (giữ tạm demo luồng — xóa khi xong Cụm 3/4).
5. 🟡 **Land GV về `/teacher`** (Home) thay `/teacher/curriculum`: sửa `homePathForRole` lead/assistant.
6. 🟡 **Tie-break get_teacher_home** đã vá nhưng pilot thật mỗi GV 1 buổi/khung giờ nên ít gặp — OK.
7. 🟡 **Chốt chính thức 1 linh vật** (chrome=mark hình học; illustration=dế tròn — cần Jean lock).
8. **GV/PH pilot còn lại chưa login** (4 GV + 9 PH) · **2 file nhạc curriculum gốc chưa nguồn lưu** · **Vercel project dormant** xóa được.

> ✅ **Đã gạch phiên này:** mig 047 (todo counts + wire TodoSection) · mig 048 (session detail + start) · mig 049 (session curriculum player) · mig 050 (vá tie-break Home) · route luồng 4 bước (Bước 1 Chuẩn bị + Bước 2 Player thật) · wire CTA Home onClick · D101 · nghiệm thu login thật toàn bộ.
> ✅ **Đóng từ trước:** Ngã A 4/5 cổng tách (v24–26) · giỏ nợ repo SẠCH (v27) · mig 045 vá rough edge GV (v28) · thiết kế Teacher V1 trọn bộ D98 (v29) · Home "Classroom Companion" sống D99/D100 (v30).

---

## 7. NGÃ KẾ — ĐỀ XUẤT

**Tiếp BUILD Teacher V1:** ⭐ **Cụm 3 — Bước 3 Ghi nhận** (việc nặng nhất, làm theo cụm 3 tab). Boot sạch + audit D1 đầu phiên (soi `child_observations` write path · đường moment/moment_children/media_assets gắn bé · `media_consent_check` MIN · `upload_media` Edge cho ảnh moment).

- **⭐ Tab 1 Điểm danh:** roster = `enrollments` active của lớp; ghi `child_observations` (attendance). Engine có (RLS D53 lead|assistant write). Cần RPC roster-của-buổi (gương get_session_detail) HOẶC client query enrollments (audit RLS classes/enrollments trước).
- **Tab 2 Ghi nhận tap-first:** `child_observations` (skills_observed jsonb + flags). Cần danh mục kỹ năng chạm-chọn (audit có catalog skill chưa — có thể seed/config).
- **Tab 3 Ảnh-gắn-bé:** `learning_moments`→`moment_children` + `upload_media` (D77) + `media_consent_check` (D71 MIN — ảnh chưa-gắn-bé/bé-chưa-đồng-ý tạm giữ). Engine ĐÃ CÓ trọn (v12–v14).
- **Sau Cụm 3 → Cụm 4** (Review & gửi + transition taught_report_pending).

**Boot phiên sau:** đọc HANDOFF v31 → START_HERE → RULES → audit live DB/route thật (D1) trước khi viết. Đóng bằng HANDOFF v32.

---

## 8. ⭐ ENGINE ↔ UI (map hiện trạng — nguồn sự thật cho BUILD tiếp)

### 8a. Đã wire sống (login thật ĐẠT)
- ✅ **Home 1-call** = `get_teacher_home()` (mig 046b, vá tie-break mig 050) → `teacher.index.tsx`.
- ✅ **Readiness** = `get_session_readiness(session_id)` (mig 046) → status map pill+CTA + prep{ready,total}.
- ✅ **Việc cần làm** = `get_teacher_todo_counts()` (mig 047) → `TodoSection` (4 số; parent_replies hook=0).
- ✅ **Màn session 1-call** = `get_session_detail(session_id)` (mig 048) → `teacher.session.$id.tsx` (gói readiness + prep_items[]).
- ✅ **Bắt đầu buổi** = `start_session(session_id)` (mig 048) → CTA "Vào dạy" (scheduled/prep_ready/makeup→in_progress, gate người-trong-phòng).
- ✅ **Prep checklist** = `prep_items` (mig 046) tick client THẲNG (RLS lead|assistant UPDATE).
- ✅ **Báo thiếu học liệu** = `support_requests` INSERT client THẲNG (self, D57; category 'curriculum').
- ✅ **Player Bước 2** = `get_session_curriculum(session_id)` (mig 049) + Edge `get_signed_media_url` (D75) → audio + watermark trôi + nodownload.

### 8b. Đã có engine, CHƯA wire UI (cho Cụm 3/4)
- ✅ **Điểm danh + Ghi nhận** = `child_observations` (attendance · skills_observed · is_highlight · needs_support · follow_up_needed · note · linked_moment_ids · visibility). RLS D53 lead|assistant write. → **Bước 3 tab 1+2.**
- ✅ **Ảnh + gắn bé + consent** = `learning_moments`→`moment_children`→`media_assets.linked_moment_id` + `media_consent_check` D71 (MIN) + Edge `upload_media` (gate `check_media_upload_access` D77) / `get_signed_media_url`. → **Bước 3 tab 3.**
- ✅ **Gửi nhật ký → PH** = approval (nếu trường bật) + parent view (approved+consent+MIN). → **Bước 4.** Transition `in_progress→taught_report_pending` đặt ở Bước 4.

### 8c. Engine CHƯA có (phát sinh tiếp)
- ❌ **Danh mục kỹ năng tap-first** (skills catalog cho tab 2) — audit có config chưa; có thể seed/app_settings.
- ❌ **Reaction "Lời cảm ơn"** = bảng reaction mới (flex, Quyết C — thay chat PH↔GV V1). `parent_replies` hook=0.

### 8d. Design tokens `/teacher` V1 (đã áp các file teacher)
- Nền **ngà `#FBF8F1`** · thẻ trắng `#FFFFFF` bo 16–18px · viền `#EFE7D6`.
- Primary = **xanh rừng `#149A76`** (nút chính chữ trắng) · text đậm `#0F6E56`.
- Accent = **mật ong `#EFA63A`** = "chỗ cần để mắt" (badge/tiến độ/việc tồn/CTA cần-xử) · bg mật-nhạt `#FCEFD6` · text `#8A5410`.
- Xám trung tính `#9A9183`/`#6B6357` cho phụ/khoá. Dế = mark hình học (header). Watermark player = `#0F6E56` opacity 0.18 trôi 12s.

### 8e. Data state (bẫy — GIỮ từ v23/v28/v29/v30)
- **KHM-DN `sharing_mode=private_share_link`** · **DEMO-001 `no_external_sharing`**.
- **Consent An `private_share_link` (`d1…e1`) = GRANTED** + download consent An bật.
- **DEMO-001 trung thực D90:** 1 moment `draft` · consent `demen_marketing granted=false` · 2 media `bunny_path`; UUID NGẪU NHIÊN → lọc tenant FK-ngược (D96).
- **PH 051 mỗi trường = 2-con-xuyên-lớp.** Role PH thật = `primary_parent`.
- `master_admin` ∈ `is_school_admin()`; **`is_school_admin()` = INVOKER → TRÁNH gọi trong thân RPC definer** (dùng `same_school`/`session_school_id`/`is_session_lead`/`is_session_teacher`/`is_admin` definer — D99/D101).
- Auth-gated fetch = client-side `useEffect` (JWT NULL khi SSR — D13/D82). `school.index` giữ `ssr:false`; shell KHÔNG.
- **`child_observations.attendance` hiện chỉ có giá trị `present`** (audit v31) — Cụm 3 sẽ thêm absent/late nếu cần.
- **Gate upload ảnh moment = `check_media_upload_access`** (KHÔNG phải `check_curriculum_upload_access` — đính chính từ v30).
- Engine media-nhạy-cảm = 5 gate secdef: consent (D71) · entitlement (D75) · upload (D77) · share (D87) · revoke (D94).
- **GV Mỹ Linh** (`…011`) lead 2 distribution: cd `d1000000-…-31` (lớp Hoa Hồng `…21`, 4 bé) + cd `8c6bb771…`; buổi a0001 lesson_version `47c52596-…013c` có 2 track CTAN active.

---

> **KỶ LUẬT VÀNG:** đã cập nhật **RULES** (thêm **D101** — luồng đa-bước 1-route step-nội-bộ + cụm RPC session + tie-break Home + client-ghi-thẳng; footer v31) + **SYSTEM_MAP** (**bump v0.28** — +4 hàm + 5 hàng migration 046–050; footer v31) trong phiên này. **6 file xuất kèm:** 4 migration repo (`047`·`048`·`049`·`050`) + 2 UI (`teacher.index.tsx` sửa · `teacher.session.$id.tsx` mới — Jean áp Lovable) + 3 library (`HANDOFF_v31` · `RULES` · `SYSTEM_MAP`). **START_HERE: KHÔNG đổi.** **Tài liệu A–G, BUILD_PATH, DMWS_REFERENCE: KHÔNG đổi.**
