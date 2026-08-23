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

> **⭐ Nguyên tắc LINH HỒN (đứng trên mọi luật):** Nhật ký nghệ thuật thuộc về TRẺ, không thuộc trường. License B2B chỉ là lớp gắn vào. Bảo toàn 2 thép chờ (D40, D41). KHÔNG chấm điểm/xếp hạng/so sánh trẻ. *(v3 đã chứng minh bằng login thật: parent thấy con-mình-không-thấy-trường; admin không thấy trẻ.)*

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
- **D14 [stack: Lovable] — KHÔNG để Lovable auto-fix bảo mật.** "Try to fix all"/"Fix with AI" có thể **ghi RLS/migration vào DB** → phá D11. **Phân loại nhiễu scanner:** *"RLS enabled no policy"* + *"Signed-in users can execute SECURITY DEFINER"* = **EXPECTED, đúng thiết kế** (deny-by-default; authenticated execute helper cố ý) — đừng fix; *"Public can execute SECURITY DEFINER"* = **thật** → sửa bằng migration `revoke ... from public, anon`; *"Leaked Password Protection Disabled"* = **thật nhưng là TOGGLE** Supabase (Auth→Attack Protection), KHÔNG sửa bằng code; *"Function Search Path Mutable"* thường là `rls_auto_enable` của Supabase (benign). Issue "profiles lack write protection" khi chưa có policy ghi = deny-by-default, không phải lỗ hổng sống.
- **D15 — RE-VERIFY "public/anon EXECUTE" sau MỌI migration tạo SECURITY DEFINER function.** Hàm mới luôn đẻ grant EXECUTE mặc định cho `public`/`anon` → harden 1 lần (mig 010) KHÔNG phủ hàm tạo sau. *(v3: 3 guard function ở mig 014/015 dính `anon` → mig 016 dọn.)* Query verify: `aclexplode(proacl)` join `pg_roles` lọc `rolname in ('public','anon') AND privilege_type='EXECUTE' AND prosecdef`. Kỳ vọng `[]`. *(Lưu ý cú pháp: `aclexplode` trả cột `grantee` đã là oid — join `pg_roles.oid=a.grantee`, KHÔNG có `grantee_oid`.)*

---

## B. SQL / SUPABASE

- **D20 — SECURITY DEFINER chuẩn:** `SET search_path=''` + schema-qualified (`public.bảng`) + dollar-quote `$func$` + REVOKE→GRANT. (← G106/G164/G224)
- **D21 — Sau `CREATE OR REPLACE FUNCTION`: `REVOKE ALL … FROM public, anon` → `GRANT EXECUTE … TO authenticated`.** (← G164/G224) *(Bổ sung D15: re-verify sau đó.)*
- **D22 — Đổi signature RPC = DROP + recreate + REVOKE/GRANT** (KHÔNG `CREATE OR REPLACE`). (← G287)
- **D23 — RLS deny-by-default (CỐT LÕI DMA):** mọi bảng bật RLS; không policy = không ai đọc. INSERT `WITH CHECK`; UPDATE cần CẢ `USING`+`WITH CHECK`; SELECT/DELETE chỉ `USING`. Helper chuẩn: `current_profile()`, `current_profile_role()`, `is_admin()`, `same_school(school_id)`, `is_child_parent(child_id)`, `is_distribution_lead()`, `is_session_teacher()`. *(Project bật "automatic RLS" → event-trigger `rls_auto_enable` benign.)* **Helper DMA tự thêm (phiên v3):** `class_school_id(class_id)` (map class→school, bypass RLS tránh đệ quy), `child_in_my_school(child_id)` (trẻ ghi danh ở trường mình), `is_school_admin()` (**non-definer** — chỉ so enum master/sub). **(phiên v4):** `current_school_id()` (secdef — school_id của caller; NULL nếu admin nền tảng/PH; dùng phân biệt "thành viên trường").
- **D24 — Supabase trả `numeric` dưới dạng STRING** → bọc `Number()`. (← G514)
- **D25 — `jsonb_build_object` cần số tham số CHẴN.** (← G529)
- **D26 — Trigger function (SECURITY DEFINER) KHÔNG cần GRANT EXECUTE** (chạy quyền owner; fire dù đã revoke). Bọc logic phụ trong `BEGIN…EXCEPTION WHEN OTHERS THEN NULL`. (← G589) *(Vẫn nên revoke public/anon cho sạch scanner — D15.)*
- **D27 — Triggers nền DMA:** `set_updated_at` · `enforce_max_two_parents` · `lesson_version_autoincrement` (immutable) · helper MIN-consent multi-child.
- **D28 — ⭐ RLS KHÔNG khóa được CỘT → ghim cột nhạy cảm bằng TRIGGER GUARD.** Mặt leo thang (`role`/`permissions`/`school_id`/`user_id` của profiles; `master_profile_id`/`name`/`code`/`state` của schools; `global_child_id`/`identity_user_id`/`merged_into`/`state` của children) → `BEFORE UPDATE` trigger SECURITY DEFINER: `if public.is_admin() then return new; else new.col := old.col; ... end if`. RLS chỉ gác ROW (ai sửa được dòng nào); guard gác CỘT (sửa được cột nào). *(v3 nghiệm thu: parent/master/teacher bấm "tự nâng super_admin" → guard ghim → vai trò giữ nguyên.)*
- **D29 — ⭐ RETURNING bị lọc bằng SELECT policy → INSERT có thể "câm".** Nếu người tạo chưa thỏa SELECT policy của row vừa insert (vd `children` chưa có enrollment → `children_select_school` fail), client KHÔNG lấy được id/row trả về. Giải: tạo qua **RPC SECURITY DEFINER** làm nguyên tử (vd `create_child_and_enroll`: insert child + insert enrollment + `return id`), KHÔNG raw INSERT từ client. RPC tự kiểm quyền (`is_admin()` OR school-admin đúng trường) trước khi ghi.
- **D30 — ⭐ Seed/migration cần bypass guard trigger: `SET session_replication_role = replica;` … `SET session_replication_role = origin;`.** Vì SQL Editor không có `auth.uid()` → `is_admin()`=false → guard (D28) ghim cột → KHÔNG seed được `role`/`school_id`. `replica` tắt user trigger tạm thời. (Nếu thiếu quyền → `ALTER TABLE … DISABLE TRIGGER`.) Nhớ bật lại `origin` cuối khối.

---

## C. KIẾN TRÚC / LINH HỒN (ranh giới cứng DMA)

- **D40 — ⭐ THÉP CHỜ #1: Nhật ký treo vào ĐỨA TRẺ.** `child_journey` gắn `child_id` gốc + cột `source` (V1='demen'). `programs` = danh mục TOÀN CỤC. KHÔNG thiết kế nhật ký thuộc trường. *(v3: `children` KHÔNG có `school_id` — scope trẻ đi vòng enrollments→classes; parent thấy con mà không thấy trường.)*
- **D41 — ⭐ THÉP CHỜ #2: `children` không khóa cứng khỏi danh tính tương lai.** Cột `identity_user_id` nullable để ngỏ Kid V2. Guard children ghim cột này khỏi non-admin (D28).
- **D42 — License-gate TÁCH khỏi journey-ownership.** Trường hết license → khóa thao tác, nhưng trẻ/PH vẫn xem hành trình. Đừng gắn cứng journey vào license/contract.
- **D43 — Versioning giáo trình BẤT BIẾN.** KHÔNG ghi đè lesson; tạo `lesson_versions` mới (version_no++ ở INSERT). Trường/lớp tự chọn version.
- **D44 — Giáo án = GỐC bất biến (DM) + OVERRIDE per lớp/GV** (`content_override`+`session_media`), KHÔNG sửa bản gốc.
- **D45 — Scope quyền theo trường + môn-trong-lớp + tiết:** thành viên trường THẤY mọi buổi toàn trường, chỉ THAO TÁC môn-lớp mình lead (`class_distributions.lead_teacher_id`) / tiết mình assistant (`session_teachers`). Lead finalize report; Assistant điểm danh/đánh giá sau `prep_ready`.
- **D46 — Sao/badge KHỬ CẠNH TRANH.** Sao = ghi nhận RIÊNG; KHÔNG leaderboard/đua/shop. Badge rule gợi ý → GV/School xác nhận mới hiện.
- **D47 — Consent 2 tầng:** Trường set KHUNG → PH chọn TRONG khung. Hiệu lực = **min(trường, PH)**. Multi-child → MIN consent. Rút consent theo từng loại.
- **D48 — ⭐ Admin Dế Mèn mặc định KHÔNG xem PII trẻ.** Moat = data ẩn danh/tổng hợp. Policy `children`/`enrollments`/`child_parents`/`child_transfers` KHÔNG mở cho `is_admin()`. Xem định danh → `request_sensitive_access` (reason+purpose+scope) ghi audit TRƯỚC khi trả. *(v3 nghiệm thu: super_admin thấy 0 trẻ.)*
- **D49 — ⭐ Lớp = HOMEROOM đa môn (Cách Y).** `classes` KHÔNG gắn 1 môn. Môn rót qua `class_distributions` (mỗi môn 1 dòng, `lead_teacher_id` riêng). `enrollments` = trẻ × homeroom; mã HS + trạng thái học ở `enrollments`.
- **D50 — ⭐ Phân phối mẫu = cây roadmap→piece→tiết; GV chỉnh INSTANCE.** Rót mẫu vào homeroom → bung `lesson_sessions`. GV sửa instance, KHÔNG đụng mẫu gốc.
- **D51 — ⭐ License tách bạch (môn + seat).** `Tổng = (số môn × giá) + (số tk GV × giá) + storage`. Môn ⟂ seat (subject-agnostic). Master bundled (không seat). Gate dạy = seat active AND entitlement môn active; tách journey (D42). V1: `has_active_seat` = trường có subscription active + seat_count>0.
- **D52 — ⭐ RLS cụm CURRICULUM (mig 017, nghiệm thu login thật v4).** Kho giáo trình 8 bảng catalog (`programs`/`age_groups`/`levels`/`themes`/`lessons`/`lesson_versions`/`program_distributions`/`program_distribution_items`) = **TOÀN CỤC**: **READ** = `is_admin() OR public.current_school_id() IS NOT NULL` (admin + thành viên trường; **PH bị loại vì `school_id` NULL** — đây là convention *load-bearing*, đừng để PH có school_id); **WRITE** = `is_admin()` only. **`lesson_versions` KHÔNG có UPDATE policy** → bất biến ở tầng RLS (gấp đôi trigger D43). **`ideas` KHÁC catalog** (có `school_id`+`proposer`) → scoped: READ = admin OR trường mình (`school_id=current_school_id()`) OR người đề xuất; INSERT = thành viên trường đúng school+đúng proposer (chống giả mạo); UPDATE = admin triage. **Nguyên tắc rộng:** RLS không gác được CỘT → khi cần giấu nội dung premium (giáo án) khỏi 1 vai trò, **tách quyền đọc ở tầng BẢNG** (PH không đọc catalog; thấy nội dung con qua cụm Journey/Sessions sau). *(v4 ĐẠT: parent thấy 0 program; teacher/master ghi `programs` → DB chặn "violates RLS policy".)*

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
- **D69 — Migration delta:** field `media_assets` Bunny-aware đã chuẩn bị (mig 005) nhưng CHƯA serving. Phase 4 bật Edge media.

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

*Seed khởi tạo cho DMA, chắt lọc Hiến pháp DMWS (v170) + Trung Tâm Tra Cứu + đặc tả media Tài liệu G. Nuôi tiếp hệ D. **Cập nhật 2026-06-24 (phiên v3): thêm D15 (re-verify grants sau mỗi definer mới), D28 (guard-cột chống leo thang), D29 (RPC vì RETURNING-câm), D30 (seed dùng session_replication_role=replica); bổ sung helper DMA vào D23, ghi nghiệm thu login thật vào D40/D48.** **Cập nhật 2026-06-24 (phiên v4): thêm D52 (RLS cụm Curriculum — catalog member-read/admin-write, lesson_versions immutable, ideas scoped); thêm helper `current_school_id()` vào D23.***
