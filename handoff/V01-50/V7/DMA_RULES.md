# 🛡️ DMA_RULES.md — TÚI KHÔN (D-series)

> **Cách dùng:** Đọc trước khi viết SQL/code. Mỗi luật = một bài học DMWS/DMA đã trả giá. Hệ số **D** (DMA tự nuôi tiếp); `(← G##)` là nguồn gốc DMWS để truy vết.
> **`[stack: X]`** = chỉ áp khi dùng công cụ X.
> **Stack DMA chính thức (tài liệu A §0):** Lovable (React+Vite+TS+Tailwind+shadcn, **routing = TanStack Start file-based + SSR**) → GitHub → Vercel · Supabase (DB/Auth/Edge Functions/RLS) · **Bunny** (storage/CDN/Stream) · GoDaddy (DNS) · Suno (tạo nhạc). Domain: dma.vercel.app → demenart.com.

---

## 🧭 PHẦN 0 — TÁM NGUYÊN TẮC META (nổ mỗi phiên)

1. **Audit thật trước khi làm.** DB sống + file code là nguồn sự thật; spec/handoff có thể sai. Không đoán.
2. **Verify bằng bằng chứng thật.** "Build OK"/"Lovable xong" ≠ xong. Chốt sau khi nhìn ảnh thật + SQL/Network. *(Trí nhớ cũng có thể sai — v3: "mig 010 đã đóng public execute" sai, verify mới bắt được hàm tạo sau dính anon.)*
3. **DB-first sequencing.** DB → RLS/Function → Edge → UI.
4. **Permission cộng thêm + CÓ SCOPE, không flip role.** Gate năng lực bằng permission gắn phạm vi (school/class), KHÔNG đổi `role` cơ bản. (← G473)
5. **Một sự thật lưu một nơi, đọc-xuyên-khoá.** KHÔNG sync engine/trigger 2 chiều. (← G305)
6. **Config-driven, không hardcode tham số.** Giá/giới hạn/chính sách sống trong bảng config. (← G393/G410)
7. **Registry-driven + self-documenting.** Menu/permission/tra-cứu đọc từ registry; thứ mới tạo phải tự khai báo metadata.
8. **Library & Tra Cứu update cùng nhịp.** Làm tới đâu ghi tới đó. *(Bài học V162.)*

> **⭐ Nguyên tắc LINH HỒN (đứng trên mọi luật):** Nhật ký nghệ thuật thuộc về TRẺ, không thuộc trường. License B2B chỉ là lớp gắn vào. Bảo toàn 2 thép chờ (D40, D41). KHÔNG chấm điểm/xếp hạng/so sánh trẻ. *(v3 chứng minh: parent thấy con-mình-không-thấy-trường; admin không thấy trẻ. v5 chứng minh thêm: parent ĐỌC trọn nhật ký con mình, admin thấy 0 journey/skills/badges.)*

---

## A. QUY TRÌNH

- **D1 — Audit DB *và* code THẬT (read-only) TRƯỚC khi viết SQL/code.** `information_schema`, `pg_get_functiondef`, `pg_policies`. KHÔNG đoán cột/enum/grant/signature/FK. (← G78/G277)
- **D2 — `auth.uid()` LUÔN NULL trong Supabase SQL Editor.** Logic auth-gated (RLS/SECURITY DEFINER/trigger guard) test qua **UI thật** với tài khoản thật. (← G95)
- **D3 — "Build OK" ≠ XONG.** Verify bằng ảnh thật luồng người dùng + SQL/Network. (← G114)
- **D4 — SQL chia khối nhỏ đánh số.** SQL Editor chỉ trả kết quả **statement cuối** → đặt SELECT verify cuối. (← G106)
- **D5 [stack: Lovable] — KHÔNG bấm "Try to fix all"/"Fix with AI"** (revert ngầm). FULL paste-over. Soát keyword sau dán. (← G318/G509/G537)
- **D6 [stack: Lovable] — Anchor find-replace phải khớp file SAU Prettier.** (← G510)
- **D7 [stack: Lovable] — Preview có thể CACHE.** Hard reload trước khi nghi code. (← G321)
- **D8 [stack: Lovable] — Lovable NUỐT `<` cuối dòng khi paste khối.** (← G322)
- **D9 [stack: Lovable] — Reconnect đẻ repo mới.** ⛔ ĐỪNG đổi tên repo/project đang nối Lovable. (← G333)
- **D10 [stack: Lovable] — Cài npm = gõ `"Add the npm dependency [package]"` trong chat.** (← G541)
- **D11 — Schema thuộc Claude/migrations, KHÔNG để Lovable auto-generate.** Lovable chỉ generate dựa schema có sẵn (đọc + sinh TS types). Dán "SCHEMA OWNERSHIP" vào đầu mọi prompt Lovable.
- **D12 — Lỗi giống nhau 2 lần cùng chỗ = deterministic.** Đọc log/error thật, đừng retry mù. (← G449)
- **D13 [stack: Lovable/TanStack] — Stack routing = TanStack Start (file-based `src/routes/` + SSR), KHÔNG phải Vite SPA + React Router.** KHÔNG cần `vercel.json`. **SSR loader chạy KHÔNG có JWT** → mọi fetch auth-gated phải **client-side sau hydrate**; bọc code browser-only bằng `typeof window !== 'undefined'`. (mở rộng D82)
- **D14 [stack: Lovable] — KHÔNG để Lovable auto-fix bảo mật.** "Try to fix all"/"Fix with AI" có thể **ghi RLS/migration vào DB** → phá D11. **Phân loại nhiễu scanner:** *"RLS enabled no policy"* + *"Signed-in users can execute SECURITY DEFINER"* = **EXPECTED, đúng thiết kế** (deny-by-default; authenticated execute helper cố ý) — đừng fix; *"Public can execute SECURITY DEFINER"* = **thật** → sửa bằng migration `revoke ... from public, anon`; *"Leaked Password Protection Disabled"* = **thật nhưng là TOGGLE** Supabase (Auth→Attack Protection), KHÔNG sửa bằng code; *"Function Search Path Mutable"* thường là `rls_auto_enable` của Supabase (benign). Issue "profiles lack write protection" khi chưa có policy ghi = deny-by-default, không phải lỗ hổng sống. *(v5: scanner còn 7–13 issue — vẫn nhiễu đúng thiết kế, KHÔNG fix.)*
- **D15 — RE-VERIFY "public/anon EXECUTE" sau MỌI migration tạo SECURITY DEFINER function.** Hàm mới luôn đẻ grant EXECUTE mặc định cho `public`/`anon` → harden 1 lần (mig 010) KHÔNG phủ hàm tạo sau. *(v3: 3 guard function ở mig 014/015 dính `anon` → mig 016 dọn. v4: `current_school_id` sạch. v5: 3 helper Sessions sạch ngay trong mig 018.)* Query verify: `aclexplode(proacl)` join `pg_roles` lọc `rolname in ('public','anon') AND privilege_type='EXECUTE' AND prosecdef`. Kỳ vọng `[]`. *(Lưu ý cú pháp: `aclexplode` trả cột `grantee` đã là oid — join `pg_roles.oid=a.grantee`, KHÔNG có `grantee_oid`. Và: nếu `proacl` NULL thì aclexplode rỗng → mặc định PUBLIC vẫn execute được → BẮT BUỘC chạy REVOKE/GRANT để proacl khác NULL thì verify mới có nghĩa.)*

---

## B. SQL / SUPABASE

- **D20 — SECURITY DEFINER chuẩn:** `SET search_path=''` + schema-qualified (`public.bảng`) + dollar-quote `$func$` + REVOKE→GRANT. (← G106/G164/G224)
- **D21 — Sau `CREATE OR REPLACE FUNCTION`: `REVOKE ALL … FROM public, anon` → `GRANT EXECUTE … TO authenticated`.** (← G164/G224) *(Bổ sung D15: re-verify sau đó.)*
- **D22 — Đổi signature RPC = DROP + recreate + REVOKE/GRANT** (KHÔNG `CREATE OR REPLACE`). (← G287)
- **D23 — RLS deny-by-default (CỐT LÕI DMA):** mọi bảng bật RLS; không policy = không ai đọc. INSERT `WITH CHECK`; UPDATE cần CẢ `USING`+`WITH CHECK`; SELECT/DELETE chỉ `USING`. Helper chuẩn: `current_profile()`, `current_profile_role()`, `is_admin()`, `same_school(school_id)`, `is_child_parent(child_id)`, `is_distribution_lead(cd_id)`, `is_session_teacher(session_id)`. *(Project bật "automatic RLS" → event-trigger `rls_auto_enable` benign.)* **Helper DMA tự thêm (v3):** `class_school_id(class_id)` (map class→school, bypass RLS tránh đệ quy), `child_in_my_school(child_id)` (trẻ ghi danh ở trường mình), `is_school_admin()` (**non-definer** — chỉ so enum master/sub). **(v4):** `current_school_id()` (secdef — school_id của caller; NULL nếu admin nền tảng/PH; dùng phân biệt "thành viên trường"). **(v5 — cụm Sessions):** `cd_school_id(cd_id)` (class_distribution→class→school), `session_school_id(session_id)` (session→cd→class→school), `is_session_lead(session_id)` (caller là lead của distribution của tiết). Tất cả secdef, bypass RLS tránh đệ quy, đã re-verify D15.
- **D24 — Supabase trả `numeric` dưới dạng STRING** → bọc `Number()`. (← G514)
- **D25 — `jsonb_build_object` cần số tham số CHẴN.** (← G529)
- **D26 — Trigger function (SECURITY DEFINER) KHÔNG cần GRANT EXECUTE** (chạy quyền owner; fire dù đã revoke). Bọc logic phụ trong `BEGIN…EXCEPTION WHEN OTHERS THEN NULL`. (← G589) *(Vẫn nên revoke public/anon cho sạch scanner — D15.)*
- **D27 — Triggers nền DMA:** `set_updated_at` · `enforce_max_two_parents` · `lesson_version_autoincrement` (immutable) · helper MIN-consent multi-child.
- **D28 — ⭐ RLS KHÔNG khóa được CỘT → ghim cột nhạy cảm bằng TRIGGER GUARD.** Mặt leo thang (`role`/`permissions`/`school_id`/`user_id` của profiles; `master_profile_id`/`name`/`code`/`state` của schools; `global_child_id`/`identity_user_id`/`merged_into`/`state` của children) → `BEFORE UPDATE` trigger SECURITY DEFINER: `if public.is_admin() then return new; else new.col := old.col; ... end if`. RLS chỉ gác ROW (ai sửa được dòng nào); guard gác CỘT (sửa được cột nào). *(v3 nghiệm thu: parent/master/teacher bấm "tự nâng super_admin" → guard ghim → vai trò giữ nguyên.)*
- **D29 — ⭐ RETURNING bị lọc bằng SELECT policy → INSERT có thể "câm".** Nếu người tạo chưa thỏa SELECT policy của row vừa insert (vd `children` chưa có enrollment → `children_select_school` fail), client KHÔNG lấy được id/row trả về. Giải: tạo qua **RPC SECURITY DEFINER** làm nguyên tử (vd `create_child_and_enroll`: insert child + insert enrollment + `return id`), KHÔNG raw INSERT từ client. RPC tự kiểm quyền (`is_admin()` OR school-admin đúng trường) trước khi ghi.
- **D30 — ⭐ Seed/migration cần bypass guard trigger: `SET session_replication_role = replica;` … `SET session_replication_role = origin;`.** Vì SQL Editor không có `auth.uid()` → `is_admin()`=false → guard (D28) ghim cột → KHÔNG seed được `role`/`school_id`. `replica` tắt user trigger tạm thời. (Nếu thiếu quyền → `ALTER TABLE … DISABLE TRIGGER`.) Nhớ bật lại `origin` cuối khối. *(Lưu ý: chỉ cần khi cụm CÓ guard trigger. Cụm Sessions/Journey KHÔNG có guard → seed_003/004 không cần replica.)*

---

## C. KIẾN TRÚC / LINH HỒN (ranh giới cứng DMA)

- **D40 — ⭐ THÉP CHỜ #1: Nhật ký treo vào ĐỨA TRẺ.** `child_journey` gắn `child_id` gốc + cột `source` (V1='demen'). `programs` = danh mục TOÀN CỤC. KHÔNG thiết kế nhật ký thuộc trường. *(v3: `children` KHÔNG có `school_id` — scope trẻ đi vòng enrollments→classes; parent thấy con mà không thấy trường. v5: parent ĐỌC trọn `child_journey/child_skills/child_badges` của con; admin thấy 0.)*
- **D41 — ⭐ THÉP CHỜ #2: `children` không khóa cứng khỏi danh tính tương lai.** Cột `identity_user_id` nullable để ngỏ Kid V2. Guard children ghim cột này khỏi non-admin (D28).
- **D42 — License-gate TÁCH khỏi journey-ownership.** Trường hết license → khóa thao tác, nhưng trẻ/PH vẫn xem hành trình. Đừng gắn cứng journey vào license/contract.
- **D43 — Versioning giáo trình BẤT BIẾN.** KHÔNG ghi đè lesson; tạo `lesson_versions` mới (version_no++ ở INSERT). Trường/lớp tự chọn version. *(v4: `lesson_versions` KHÔNG có UPDATE policy → bất biến cả ở tầng RLS.)*
- **D44 — Giáo án = GỐC bất biến (DM) + OVERRIDE per lớp/GV** (`content_override`+`session_media`), KHÔNG sửa bản gốc. *(v5: `lesson_sessions.content_override` jsonb — GV sửa instance, giữ lesson_version bất biến.)*
- **D45 — Scope quyền theo trường + môn-trong-lớp + tiết:** thành viên trường THẤY mọi buổi toàn trường, chỉ THAO TÁC môn-lớp mình lead (`class_distributions.lead_teacher_id`) / tiết mình assistant (`session_teachers`). Lead finalize report; Assistant điểm danh/đánh giá sau `prep_ready`. *(v5 nghiệm thu — xem D53.)*
- **D46 — Sao/badge KHỬ CẠNH TRANH.** Sao = ghi nhận RIÊNG; KHÔNG leaderboard/đua/shop. Badge rule gợi ý → GV/School xác nhận mới hiện. *(v5: `child_badges` PH chỉ ĐỌC, KHÔNG tự trao — WRITE = trường. `child_skills` chỉ signal_count, không xếp hạng.)*
- **D47 — Consent 2 tầng:** Trường set KHUNG → PH chọn TRONG khung. Hiệu lực = **min(trường, PH)**. Multi-child → MIN consent. Rút consent theo từng loại. *(Cụm Privacy CHƯA làm RLS.)*
- **D48 — ⭐ Admin Dế Mèn mặc định KHÔNG xem PII trẻ.** Moat = data ẩn danh/tổng hợp. Policy `children`/`enrollments`/`child_parents`/`child_transfers` (v3) + `child_observations`/`session_reports` (v5) + `child_journey`/`child_skills`/`child_badges` (v5) KHÔNG mở cho `is_admin()`. Xem định danh → `request_sensitive_access` (reason+purpose+scope) ghi audit TRƯỚC khi trả. *(v3: super_admin thấy 0 trẻ. v5: super_admin thấy 0 ở observations/reports/journey/skills/badges.)*
- **D49 — ⭐ Lớp = HOMEROOM đa môn (Cách Y).** `classes` KHÔNG gắn 1 môn. Môn rót qua `class_distributions` (mỗi môn 1 dòng, `lead_teacher_id` riêng). `enrollments` = trẻ × homeroom; mã HS + trạng thái học ở `enrollments`.
- **D50 — ⭐ Phân phối mẫu = cây roadmap→piece→tiết; GV chỉnh INSTANCE.** Rót mẫu vào homeroom → bung `lesson_sessions`. GV sửa instance, KHÔNG đụng mẫu gốc.
- **D51 — ⭐ License tách bạch (môn + seat).** `Tổng = (số môn × giá) + (số tk GV × giá) + storage`. Môn ⟂ seat (subject-agnostic). Master bundled (không seat). Gate dạy = seat active AND entitlement môn active; tách journey (D42). V1: `has_active_seat` = trường có subscription active + seat_count>0.
- **D52 — ⭐ RLS cụm CURRICULUM (mig 017, nghiệm thu login thật v4).** Kho giáo trình 8 bảng catalog (`programs`/`age_groups`/`levels`/`themes`/`lessons`/`lesson_versions`/`program_distributions`/`program_distribution_items`) = **TOÀN CỤC**: **READ** = `is_admin() OR public.current_school_id() IS NOT NULL` (admin + thành viên trường; **PH bị loại vì `school_id` NULL** — convention *load-bearing*, đừng để PH có school_id); **WRITE** = `is_admin()` only. **`lesson_versions` KHÔNG có UPDATE policy** → bất biến ở tầng RLS (gấp đôi trigger D43). **`ideas` KHÁC catalog** (có `school_id`+`proposer`) → scoped: READ = admin OR trường mình OR người đề xuất; INSERT = thành viên trường đúng school+đúng proposer; UPDATE = admin triage. **Nguyên tắc rộng:** RLS không gác CỘT → giấu nội dung premium khỏi 1 vai → tách quyền đọc ở tầng BẢNG. *(v4 ĐẠT: parent 0 program; teacher/master ghi `programs` → DB chặn.)*
- **D53 — ⭐ RLS cụm SESSIONS (mig 018, nghiệm thu login thật v5).** 5 bảng xoay quanh buổi học (`lesson_sessions`/`session_teachers`/`session_media`/`session_reports`/`child_observations`). Scope **KHÔNG phẳng** (khác Curriculum): **READ** = `same_school(session_school_id)` → thành viên trường thấy mọi buổi toàn trường; **admin + PH bị loại tự động** (school NULL → `same_school` false; D48 cho observations/reports chứa id trẻ). **WRITE theo vai trò người-trong-phòng:** `lesson_sessions`/`session_teachers` = lead (`is_distribution_lead`) HOẶC school-admin cùng trường; `session_media`/`child_observations` = lead HOẶC assistant (`is_session_teacher`); `session_reports` = lead HOẶC school-admin cùng trường (**school-admin step-in = moat chống GV nghỉ việc**). DELETE chưa làm (soft-delete qua `session_state`). 3 helper định tuyến mới: `cd_school_id`/`session_school_id`/`is_session_lead`. *(v5 ĐẠT: master ĐỌC observation nhưng GHI bị chặn "violates RLS policy for child_observations" → "thấy mà không thao tác" D45; super_admin 0 ở observations/reports D48; teacher-lead ghi observation THÀNH CÔNG.)*
- **D54 — ⭐ RLS cụm JOURNEY (mig 019, nghiệm thu login thật v5).** TRÁI TIM DMA. **Hai nhóm tách bạch:** (A) **gắn trẻ/PII** — `child_journey`/`child_skills`/`child_badges`: READ = `is_child_parent(child_id) OR child_in_my_school(child_id)` (PH của trẻ HOẶC thành viên trường; **admin bị loại — D48**); WRITE = `child_in_my_school(child_id)` (V1 nguồn 'demen' từ trường; **PH chưa ghi V1, PH-thêm = V2 với `source≠demen`**). (B) **catalog toàn cục** — `badges`/`home_activities` (không child_id/school_id): READ = mọi vai đăng nhập (gồm PH — nhãn/gợi ý công khai, không IP); WRITE = `is_admin()`. **D46 ghim vào RLS:** `child_badges` PH chỉ ĐỌC, KHÔNG tự trao. *(v5 ĐẠT — 3 phép thử linh hồn: parent ĐỌC trọn nhật ký con mình [2 entry+kỹ năng+huy hiệu]; super_admin thấy 0 journey/skills/badges nhưng đọc được catalog; parent bấm thêm entry → DB chặn "violates RLS policy for child_journey".)*
- **D55 — ⭐ RLS cụm PRIVACY/CONSENT (mig 020, nghiệm thu login thật v6).** 3 bảng quản trị: `consents` · `privacy_requests` · `share_links`. **Sự thật cốt lõi:** engine 2 tầng `min(trường, PH)` + MIN-multi-child = **Edge Function `get_signed_media_url` (D47), KHÔNG ở RLS**; RLS cụm này chỉ gác **quyền-truy-cập-DÒNG**. KHUNG trường = **các cột trên `schools`** (`sharing_mode`/`watermark_mode`/`moment_approval_mode`/`report_approval_mode`/`parent_comment_mode`), KHÔNG bảng riêng; `consents` thuần tầng PH (`parent_profile_id`, không `school_id`). **(1) `consents`:** READ = `is_child_parent OR child_in_my_school` (PH + thành viên trường; **admin loại — D48**); WRITE (**Fork 1A**) = **chỉ PH**, ghim `parent_profile_id = current_profile()` (trường ghi-hộ = RPC có audit, sau). **(2) `privacy_requests` (hồ sơ tuân thủ):** READ (**Fork 2A — carve-out CỐ Ý khỏi D48**) = `is_admin() OR requester=self OR (is_school_admin() AND same_school(school_id))` — Dế Mèn là controller BẮT BUỘC xử lý yêu cầu xóa/truy cập, không phải soi PII; INSERT = requester=self (+ ràng buộc child/school); UPDATE triage = admin OR school-admin cùng trường. **(3) `share_links` (Fork 3A):** creator-only mọi chiều; resolve-by-token = Edge public bypass RLS. KHÔNG helper mới, KHÔNG DELETE (soft qua `withdrawn_at`/`revoked_at`/`status`). *(v6 ĐẠT — 2 bằng chứng vàng: **teacher privacy_requests=0 vs master=1** → nhánh `is_school_admin()` đứng; **admin consents=0 nhưng privacy_requests=1** → carve-out 2A đúng. parent ghi consent THÀNH CÔNG; master/teacher ghi → DB chặn "violates RLS policy for consents".)*
- **D56 — ⭐ RLS cụm BUSINESS/LICENSE (mig 021, nghiệm thu login thật v7).** 3 bảng B2B: `pricing_config` · `school_subscriptions` · `school_subject_entitlements`. **KHÔNG chạm PII trẻ → D48 không áp. KHÔNG helper mới** (tái dùng `is_admin`/`same_school`/`is_school_admin`/`current_school_id`). **Sự thật cốt lõi — tách quyền đọc ở TẦNG BẢNG để che cột tài chính (kỹ thuật D52):** cột tiền (`total_amount`/`payment_status`/`contract_file_media_id`) sống trọn trong `school_subscriptions` → **READ = `is_admin() OR (is_school_admin() AND same_school(school_id))`** = chỉ chủ trường thấy hợp đồng + số tiền; còn "môn nào active" ở `school_subject_entitlements` (KHÔNG cột tiền) → **READ = `is_admin() OR same_school(school_id)`** = mọi GV trong trường thấy. `pricing_config` (price list TOÀN CỤC của Dế Mèn) → **READ = `is_admin() OR current_school_id() IS NOT NULL`** (member-read, **PH loại** — convention load-bearing như D52). **WRITE = `is_admin()` only cả 3 bảng** → trường KHÔNG tự cấp seat / kích hoạt môn / đổi giá; license là lớp Dế Mèn gắn vào (D51, D42 journey tách license). **KHÔNG DELETE** (lifecycle qua enum `subscription_state`: trial/active/past_due/expired/cancelled). *(v7 ĐẠT — 3 bằng chứng vàng: **teacher subscriptions=0 vs master=1** → nhánh tài chính `is_school_admin()` che số tiền khỏi GV; **parent 0 cả 3 bảng** (no school_id) → PH ngoài cuộc B2B; **master bấm thêm subscription → DB chặn** "violates RLS policy for school_subscriptions" → D51 trường-không-tự-cấp-license sống.)*

---

## D. ⭐ MEDIA / BUNNY SECURITY (nguồn sự thật = Tài liệu G — DMA chặt hơn DMWS)

> **Nguyên tắc nền:** Bunny chỉ LƯU + DELIVER. **Supabase Auth/RLS/Edge Function quyết định AI xem gì, bao lâu, có tải/chia sẻ không.**

- **D60 — Hai Bunny zone:** `dma-public` (brand/marketing) vs `dma-private` (media trẻ/học liệu — BẬT Token Authentication). Video dài → Bunny Stream (signed playback).
- **D61 — Private media KHÔNG BAO GIỜ có URL công khai/vĩnh viễn.** Mọi lượt xem qua Edge `get_signed_media_url` → kiểm quyền/consent → ký URL Bunny hết hạn ngắn (ảnh/video 5–15', download 3–10').
- **D62 — DB chỉ lưu `path/zone/provider/video_id/metadata`.** KHÔNG lưu permanent URL · token · signed URL · API key.
- **D63 — Secret CHỈ server-side (Edge Function secrets):** `SERVICE_ROLE_KEY`, `BUNNY_*`. Client `VITE_*` CHỈ `SUPABASE_URL` + `ANON_KEY`.
- **D64 — Upload private qua Edge `upload_media`** → ghi `media_assets` → audit. Parent KHÔNG upload moment V1.
- **D65 — Học liệu CTAN = stream-only/view-only V1.** KHÔNG download. Watermark ĐỘNG di chuyển khi `watermark_required`.
- **D66 — Private share link KHÔNG map thẳng Bunny URL.** Token nội bộ DMA (`share_links`) + expiry + scope.
- **D67 — Mọi thao tác media nhạy cảm GHI AUDIT.**
- **D68 — Trung thực về giới hạn:** V1 KHÔNG ngăn tuyệt đối quay màn hình. UI KHÔNG tuyên bố chống quay 100%. DRM = V2/V3.
- **D69 — Migration delta:** field `media_assets` Bunny-aware đã chuẩn bị (mig 005) nhưng CHƯA serving. Phase 4 bật Edge media. *(Cụm Media RLS thuần sẽ mỏng — phần thịt là Edge; làm chung với Edge.)*

---

## E. FE / VẶT

- **D80 [stack: Supabase] — Cột chưa có trong generated TS types** → `(supabase as any)`. (← G280)
- **D81 [stack: TanStack Router] — union/indexed-access trong `useState` làm code-splitter chết** → tách `type` alias module-level. (← G557)
- **D82 [stack: TanStack Start] — SSR loader chạy KHÔNG có JWT** → nội dung gated fetch **client-side** (xem D13).
- **D83 [nếu clone Admin shell] — Icon registry:** icon chưa đăng ký âm thầm fallback → đăng ký khi thêm module. (← G513)

---

## F. TRUNG TÂM TRA CỨU (registry self-documenting — dựng từ Phase 1)

- **D100 — Module admin mới điền ĐỦ 4 trường NGAY:** `description` + `usage_note` + `search_keywords` (mảng) + `related_slugs`.
- **D101 — Hub/registry liên kết ĐỐI XỨNG hai chiều với con.**
- **D102 — Hub trỏ module ẨN → line VÔ HÌNH** → trỏ thêm ≥1 module *enabled*.
- **D103 — Liên kết một chiều giữa 2 module thường HỢP LỆ** (chỉ hub mới bắt buộc đối xứng).
- **D104 — Search content-based:** khớp label+description+usage_note+search_keywords, unaccent.

---

*Seed khởi tạo cho DMA, chắt lọc Hiến pháp DMWS (v170) + Trung Tâm Tra Cứu + đặc tả media Tài liệu G. Nuôi tiếp hệ D. **Cập nhật 2026-06-24 (v3): thêm D15/D28/D29/D30; bổ sung helper DMA vào D23; nghiệm thu login thật vào D40/D48.** **Cập nhật (v4): thêm D52 (RLS Curriculum); thêm `current_school_id()` vào D23.** **Cập nhật 2026-06-24 23:41 GMT+7 (v5): thêm D53 (RLS cụm Sessions — scope lead/assistant, admin-no-PII, school-admin step-in), D54 (RLS cụm Journey — PH sở hữu nhật ký, admin-no-PII, badge khử cạnh tranh); thêm 3 helper `cd_school_id`/`session_school_id`/`is_session_lead` vào D23; ghi nghiệm thu v5 vào D40/D44/D45/D46/D48.** **Cập nhật 2026-06-25 (v6): thêm D55 (RLS cụm Privacy/Consent — engine min(trường,PH) ở Edge không RLS; Fork 1A PH-only ghi consent; Fork 2A admin carve-out đọc privacy_requests; Fork 3A share_links creator-only). KHÔNG helper mới. Nghiệm thu login thật 4 vai trò.** **Cập nhật 2026-06-25 03:52 GMT+7 (v7): thêm D56 (RLS cụm Business/License — che cột tài chính bằng tách-quyền-đọc-ở-tầng-bảng; WRITE admin-only = trường không tự cấp license; KHÔNG helper mới). Nghiệm thu login thật 4 vai + 3 bằng chứng vàng. 6/8 cụm RLS xong, 104 policy.***
