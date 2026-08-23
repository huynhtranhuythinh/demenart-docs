# 🛡️ DMA_RULES.md — TÚI KHÔN (D-series)

> **Cách dùng:** Đọc trước khi viết SQL/code. Mỗi luật = một bài học DMWS đã trả giá. Hệ số **D** (DMA tự nuôi tiếp); `(← G##)` là nguồn gốc DMWS để truy vết.
> **`[stack: X]`** = chỉ áp khi dùng công cụ X.
> **Stack DMA chính thức (tài liệu A §0):** Lovable (React+Vite+TS+Tailwind+shadcn, **routing = TanStack Start file-based + SSR**) → GitHub → Vercel · Supabase (DB/Auth/Edge Functions/RLS) · **Bunny** (storage/CDN/Stream — KHÔNG dùng Supabase Storage cho media chính) · GoDaddy (DNS) · Suno (tạo nhạc). Domain: dma.vercel.app → demenart.com.

---

## 🧭 PHẦN 0 — TÁM NGUYÊN TẮC META (nổ mỗi phiên)

1. **Audit thật trước khi làm.** DB sống + file code là nguồn sự thật; spec/handoff có thể sai. Không đoán.
2. **Verify bằng bằng chứng thật.** "Build OK"/"Lovable xong" ≠ xong. Chốt sau khi nhìn ảnh thật + SQL/Network.
3. **DB-first sequencing.** DB → RLS/Function → Edge → UI.
4. **Permission cộng thêm + CÓ SCOPE, không flip role.** Gate năng lực bằng permission gắn phạm vi (school/class), KHÔNG đổi `role` cơ bản. *(DMA: thành viên trường thấy hết, chỉ thao tác Lớp được phân công — như B2B DMWS.)* (← G473)
5. **Một sự thật lưu một nơi, đọc-xuyên-khoá.** KHÔNG sync engine/trigger 2 chiều. (← G305)
6. **Config-driven, không hardcode tham số.** Giá/giới hạn/chính sách sống trong bảng config. (← G393/G410)
7. **Registry-driven + self-documenting.** Menu/permission/tra-cứu đọc từ registry; thứ mới tạo phải tự khai báo metadata.
8. **Library & Tra Cứu update cùng nhịp.** Làm tới đâu ghi tới đó. *(Bài học V162.)*

> **⭐ Nguyên tắc LINH HỒN (đứng trên mọi luật):** Nhật ký nghệ thuật thuộc về TRẺ, không thuộc trường. License B2B chỉ là lớp gắn vào. Mọi thiết kế phải bảo toàn 2 thép chờ (D40, D41). KHÔNG chấm điểm/xếp hạng/so sánh trẻ.

---

## A. QUY TRÌNH

- **D1 — Audit DB *và* code THẬT (read-only) TRƯỚC khi viết SQL/code.** `information_schema`, `pg_get_functiondef`, `pg_policies`. KHÔNG đoán cột/enum/grant/signature/FK. (← G78/G277)
- **D2 — `auth.uid()` LUÔN NULL trong Supabase SQL Editor.** Logic auth-gated (RLS/SECURITY DEFINER) test qua **UI thật** với tài khoản thật. (← G95)
- **D3 — "Build OK" ≠ XONG.** Verify bằng ảnh thật luồng người dùng + SQL/Network. (← G114)
- **D4 — SQL chia khối nhỏ đánh số.** SQL Editor chỉ trả kết quả **statement cuối** → đặt SELECT verify cuối. (← G106)
- **D5 [stack: Lovable] — KHÔNG bấm "Try to fix all"/"Fix with AI"** (revert ngầm). FULL paste-over (Cmd+A→dán). Soát keyword sau dán. (← G318/G509/G537)
- **D6 [stack: Lovable] — Anchor find-replace phải khớp file SAU Prettier** (Prettier xoá dòng trống → anchor câm). (← G510)
- **D7 [stack: Lovable] — Preview có thể CACHE.** Hard reload trước khi nghi code. (← G321)
- **D8 [stack: Lovable] — Lovable NUỐT `<` cuối dòng khi paste khối.** Viết generic phức tạp trên 1 dòng / gõ tay `<`. (← G322)
- **D9 [stack: Lovable] — Reconnect đẻ repo mới.** ⛔ ĐỪNG đổi tên repo/project đang nối Lovable. (← G333)
- **D10 [stack: Lovable] — Cài npm = gõ `"Add the npm dependency [package]"` trong chat.** (← G541)
- **D11 — Schema thuộc Claude/migrations, KHÔNG để Lovable auto-generate.** Lovable chỉ generate dựa trên schema có sẵn (đọc + sinh TS types), không tự tạo bảng/cột/enum/RLS/migration. Dán "SCHEMA OWNERSHIP" vào đầu mọi prompt Lovable. *(Tài liệu C/E nhấn mạnh.)*
- **D12 — Lỗi giống nhau 2 lần cùng chỗ = deterministic.** Đọc log/error thật, đừng retry mù. (← G449)
- **D13 [stack: Lovable/TanStack] — Stack routing = TanStack Start (file-based `src/routes/` + SSR), KHÔNG phải Vite SPA + React Router.** KHÔNG cần `vercel.json` rewrite. **SSR loader chạy KHÔNG có JWT** → mọi fetch auth-gated (profile lookup, nội dung gated) phải **client-side sau hydrate**; bọc code browser-only bằng `typeof window !== 'undefined'`. (mở rộng D82) *(Lovable bắt đúng điều này khi build Chặng 1.)*
- **D14 [stack: Lovable] — KHÔNG để Lovable auto-fix bảo mật.** "Try to fix all (free)"/"Fix with AI" có thể **ghi RLS/migration vào DB** → phá D11. Mọi sửa bảo mật/schema đi qua **migration của mình**. **Phân loại nhiễu scanner Lovable:** *"RLS enabled no policy"* + *"Signed-in users can execute SECURITY DEFINER"* = **EXPECTED, đúng thiết kế** (đừng fix); *"Public can execute SECURITY DEFINER"* = **thật** → sửa bằng migration `revoke ... from public, anon`. Issue "profiles lack write protection" khi chưa có policy ghi = deny-by-default đã chặn, không phải lỗ hổng sống.

---

## B. SQL / SUPABASE

- **D20 — SECURITY DEFINER chuẩn:** `SET search_path=''` + schema-qualified (`public.bảng`) + dollar-quote đặt tên `$func$` + REVOKE→GRANT. (← G106/G164/G224)
- **D21 — Sau `CREATE OR REPLACE FUNCTION`: `REVOKE ALL … FROM public, anon` → `GRANT EXECUTE … TO authenticated`.** (← G164/G224)
- **D22 — Đổi signature RPC = DROP + recreate + REVOKE/GRANT** (KHÔNG `CREATE OR REPLACE`). (← G287)
- **D23 — RLS deny-by-default (CỐT LÕI DMA):** mọi bảng bật RLS; không policy = không ai đọc. INSERT `WITH CHECK`; UPDATE cần CẢ `USING`+`WITH CHECK`; SELECT/DELETE chỉ `USING`. Helper chuẩn (tài liệu C §14): `current_profile()`, `current_profile_role()`, `is_admin()`, `same_school(school_id)`, `is_child_parent(child_id)`, `is_distribution_lead()`, `is_session_teacher()`. *(Bật RLS ngay lúc tạo bảng; project bật "automatic RLS" → có event-trigger `rls_auto_enable` benign tự bật RLS cho bảng mới.)*
- **D24 — Supabase trả `numeric` dưới dạng STRING** → bọc `Number()`. (← G514)
- **D25 — `jsonb_build_object` cần số tham số CHẴN.** (← G529)
- **D26 — Trigger function (SECURITY DEFINER) KHÔNG cần GRANT EXECUTE** (chạy quyền owner; trigger vẫn fire dù đã revoke execute). Bọc logic phụ trong `BEGIN…EXCEPTION WHEN OTHERS THEN NULL` để lỗi phụ không chặn thao tác chính. (← G589)
- **D27 — Triggers nền DMA (tài liệu C §15):** `set_updated_at` · `enforce_max_two_parents` (child_parents) · `lesson_version_autoincrement` (immutable) · helper MIN-consent multi-child.

---

## C. KIẾN TRÚC / LINH HỒN (ranh giới cứng DMA)

- **D40 — ⭐ THÉP CHỜ #1: Nhật ký treo vào ĐỨA TRẺ.** `child_journey` gắn `child_id` gốc + cột `source` (V1='demen'). `programs` = danh mục TOÀN CỤC (Piano ở đâu cũng cùng program). KHÔNG thiết kế nhật ký thuộc trường. → thêm nguồn ngoài/PH tự thêm sau = thêm giá trị `source`, không đổi cấu trúc.
- **D41 — ⭐ THÉP CHỜ #2: `children` không khóa cứng khỏi danh tính tương lai.** V1 trẻ không auth (đúng tài liệu), nhưng để ngỏ chỗ gắn PIN/quyền-vào-app (cổng Kid V2). KHÔNG mô hình hóa trẻ kiểu "vĩnh viễn không thể là user".
- **D42 — License-gate TÁCH khỏi journey-ownership.** Trường hết license → GV+trường bị khóa thao tác, nhưng **trẻ/PH vẫn xem được hành trình đã tích lũy**. Quyền vận hành (license) ≠ quyền ký ức (của trẻ). Đừng gắn cứng journey vào license/contract.
- **D43 — Versioning giáo trình BẤT BIẾN.** KHÔNG ghi đè lesson; tạo `lesson_versions` mới (version_no++). Trường/lớp **tự chọn** version (không ép); version trẻ thực học ghi ở `lesson_sessions.lesson_version_id`. Report/journey ghi đúng `lesson_version_id`. *(version_no tự tăng ở INSERT; bất biến NỘI DUNG sau publish = tầng RLS/app lo, cần biết state.)*
- **D44 — Giáo án = GỐC bất biến (DM) + OVERRIDE per lớp/GV.** GV điều chỉnh giáo án + thêm học liệu/audio per tiết = lớp phủ riêng (`content_override`+`session_media`), KHÔNG sửa bản gốc DM.
- **D45 — Scope quyền theo trường + môn-trong-lớp + tiết (như /b2b DMWS):** thành viên trường THẤY mọi buổi học toàn trường, chỉ THAO TÁC môn-lớp mình là lead (`class_distributions.lead_teacher_id`) / tiết mình là assistant (`session_teachers`). Lead finalize report; Assistant chỉ điểm danh/đánh giá/mở bài, sau `prep_ready`.
- **D46 — Sao/badge KHỬ CẠNH TRANH.** Sao = ghi nhận RIÊNG từng trẻ; KHÔNG leaderboard/đua/shop/so sánh. Badge do rule gợi ý → GV/School xác nhận mới hiển thị.
- **D47 — Consent 2 tầng:** Trường set KHUNG → PH chọn TRONG khung. Quyền hiệu lực = **min(trường, PH)**. Multi-child moment → áp **MIN consent**. Rút consent xử lý **theo từng loại**.
- **D48 — Admin Dế Mèn mặc định KHÔNG xem PII trẻ.** Moat = data **ẩn danh/tổng hợp**. Xem định danh → `request_sensitive_access` (reason+purpose+scope) ghi audit TRƯỚC khi trả.
- **D49 — ⭐ Lớp = HOMEROOM đa môn (Cách Y).** `classes` KHÔNG gắn 1 môn. Môn rót vào lớp qua `class_distributions` (mỗi môn 1 dòng, `lead_teacher_id` riêng). `enrollments` = trẻ × homeroom. Mã HS + trạng thái học ở `enrollments`, KHÔNG ở `children`.
- **D50 — ⭐ Phân phối mẫu = cây roadmap→piece→tiết; GV chỉnh INSTANCE.** `program_distributions` kiểu `roadmap`/`piece`; `program_distribution_items` CHECK mỗi item là tiết XOR piece. Rót mẫu vào homeroom (`class_distributions`) → bung `lesson_sessions`. GV sửa instance (`content_override`, `session_media`), KHÔNG đụng mẫu gốc.
- **D51 — ⭐ License tách bạch (môn + seat).** `Tổng = (số môn × giá) + (số tk GV × giá) + storage`. `school_subject_entitlements` ⟂ `school_subscriptions.seat_count` (seat subject-agnostic). Master bundled (không seat). Trợ giảng seat tùy `settings.assistant_consumes_seat`. Gate dạy = seat active AND entitlement môn active; license-gate **tách** journey (D42). *(V1: `has_active_seat` = trường có subscription active + seat_count>0; chưa gán ghế-từng-GV.)*

---

## D. ⭐ MEDIA / BUNNY SECURITY (nguồn sự thật = Tài liệu G — DMA chặt hơn DMWS)

> **Nguyên tắc nền:** Bunny chỉ LƯU + DELIVER. **Supabase Auth/RLS/Edge Function quyết định AI xem gì, bao lâu, có tải/chia sẻ không.** Bunny không quyết định quyền nghiệp vụ.

- **D60 — Hai Bunny zone:** `dma-public` (brand/marketing) vs `dma-private` (media trẻ/học liệu/nhạy cảm — BẬT Token Authentication). Video dài → Bunny Stream (signed playback).
- **D61 — Private media KHÔNG BAO GIỜ có URL công khai/vĩnh viễn.** Mọi lượt xem private đi qua Edge Function `get_signed_media_url` → kiểm tra quyền/consent → ký URL Bunny **hết hạn ngắn** (ảnh/video 5–15', download 3–10').
- **D62 — DB chỉ lưu `path/zone/provider/video_id/metadata`.** TUYỆT ĐỐI KHÔNG lưu: permanent private URL · Bunny token · signed URL · API key. *(media_assets mặc định an toàn: private · signed_url · stream_only · no-download · expires 10'.)*
- **D63 — Secret CHỈ server-side (Edge Function secrets):** `SERVICE_ROLE_KEY`/secret key, `BUNNY_*`. Client (`VITE_*`) CHỈ chứa `SUPABASE_URL` + `ANON/PUBLISHABLE_KEY`. KHÔNG đặt secret vào `VITE_*`/frontend/bundle/repo.
- **D64 — Upload private qua Edge Function `upload_media`** → ghi `media_assets` → audit. Teacher chỉ upload trong lớp/buổi được gán; Parent KHÔNG upload moment V1.
- **D65 — Học liệu CTAN = stream-only/view-only V1.** KHÔNG download/permanent URL. Watermark ĐỘNG (DMA·CTAN + trường + user + thời gian) **di chuyển** khi `watermark_required`.
- **D66 — Private share link KHÔNG map thẳng Bunny URL.** Token nội bộ DMA (`share_links`) + expiry + scope. Mở → `resolve_private_share_link`. Thu hồi → 403.
- **D67 — Mọi thao tác media nhạy cảm GHI AUDIT.**
- **D68 — Trung thực về giới hạn:** V1 KHÔNG ngăn tuyệt đối quay màn hình. UI KHÔNG tuyên bố chống quay 100%. DRM = V2/V3.
- **D69 — Migration delta:** field `media_assets` Bunny-aware đã chuẩn bị (mig 005) nhưng CHƯA serving. Phase 4 bật Edge Functions media.

---

## E. FE / VẶT

- **D80 [stack: Supabase] — Cột chưa có trong generated TS types** → `(supabase as any)`. (← G280)
- **D81 [stack: TanStack Router] — union/indexed-access trong `useState` làm code-splitter chết** → tách `type` alias module-level. (← G557)
- **D82 [stack: TanStack Start] — SSR loader chạy KHÔNG có JWT** → nội dung gated theo quyền fetch **client-side** (xem D13). (← DMWS FAQ gating)
- **D83 [nếu clone Admin shell] — Icon registry:** icon chưa đăng ký âm thầm fallback → đăng ký khi thêm module. (← G513)

---

## F. TRUNG TÂM TRA CỨU (registry self-documenting — dựng từ Phase 1)

- **D100 — Module admin mới điền ĐỦ 4 trường NGAY khi tạo:** `description` + `usage_note` + `search_keywords` (mảng) + `related_slugs`. *(DMWS 42/46 thiếu → search câm.)*
- **D101 — Hub/registry liên kết ĐỐI XỨNG hai chiều với con.**
- **D102 — Hub trỏ module ẨN → line VÔ HÌNH** → trỏ thêm ≥1 module *enabled*.
- **D103 — Liên kết một chiều giữa 2 module thường HỢP LỆ** (chỉ hub mới bắt buộc đối xứng).
- **D104 — Search content-based:** khớp label+description+usage_note+search_keywords, unaccent (gõ không dấu vẫn ra).

---

*Seed khởi tạo cho DMA, chắt lọc Hiến pháp DMWS (v170) + bài học Trung Tâm Tra Cứu + đặc tả media Tài liệu G. Nuôi tiếp hệ D. **Cập nhật phiên 2026-06-24: thêm D13 (TanStack Start), D14 (Lovable không auto-fix/auto-gen + phân loại nhiễu scanner); ghi current_profile_role rename + rls_auto_enable vào D23.***
