# 🩰 DMA V127-M1.5-PHASE0 — BALLET PILOT READINESS REPORT

> **Loại:** Phase 0 audit (read-only) · **KHÔNG canonicalize** cho tới Owner Gate.
> **Pilot:** Dế Mèn Ballet Academy · lớp **Ballet Hạt Nắng** (3–4.5t) + **Ballet Cánh Hoa** (5–8t) · Teacher Champion **Cô Thuý Ngân** · ~30 trẻ / ~30 phụ huynh · **khởi động 17/08/2026**.
> **Baseline pin (khớp):** RULES **D344** · SYSTEM_MAP **v1.32** · HANDOFF **V126-M1** · HEAD **`6b860338`** · signer deploy-25 (v24).
> **Ràng buộc phiên:** KHÔNG tạo feature · KHÔNG migration · KHÔNG deploy · KHÔNG mở rộng scope. Chỉ audit + phân loại.

---

## 🚦 VERDICT — `NOT READY (as of 09/08/2026)`

**Nền tảng (platform) LÀNH MẠNH — pilot environment thì CHƯA được cấp phát (provisioned).**

Đây là điểm phân biệt quan trọng: **không có defect nền tảng nào chặn pilot.** Mọi blocker MUST-FIX đều thuộc nhóm **provisioning + config + verification** (thao tác dữ liệu onboarding + real-login sign-off), **KHÔNG** phải engineering mới, migration schema, hay deploy. Nghĩa là con đường tới READY là *cấp phát + kiểm chứng*, không phải *xây thêm*.

Nếu 7 hạng mục MUST-FIX bên dưới được đóng trước 17/8 và Owner Gate real-login PASS trên chính data pilot → chuyển READY.

---

## 🔬 PHẠM VI & PHƯƠNG PHÁP

**Đã audit (live DB read-only, project `xcvhacymrbhdhohyylyq`):** inventory baseline · tenant/school · program/subject model · entitlements · classes + age_group/level · tài khoản teacher · quy mô enrollment · RLS trên bảng nhạy cảm · gate RPC parent/teacher · trạng thái cold-start meaning-layer.

**CHƯA (nằm ngoài quyền/khả năng Phase 0 — thuộc Owner Gate):**
- **Real-login (D2/D3):** `auth.uid()` NULL trong SQL Editor → mọi khẳng định UX phải được xác nhận bằng đăng nhập thật. Em audit *cấu trúc*; Owner Gate xác nhận *hành vi*.
- **Edge signer source** (`get_signed_media_url`): chưa đọc mã nguồn phiên này → gating per-child của media suy ra từ kiến trúc + handoff, **cần verify** (mục MUST-FIX #6).

**Baseline re-verify PASS:** `89 tables · 215 functions · 204 SECURITY DEFINER · 166 policies · migration tail 20260807130914` — khớp endpoint D344/v1.32. (triggers đếm 39 theo `NOT tgisinternal` vs doc 33 — khác cách đếm, non-blocking.)

---

## 1️⃣ PARENT JOURNEY — audit

| Điểm kiểm | Kết quả cấu trúc | Ghi chú |
|---|---|---|
| First login | RPC entry gated đúng | children list qua RLS `children_select_parent = is_child_parent(id)` |
| Child context | Child-scoped, không bleed | V126 QA real-login đã PASS An↔Khang không lẫn con (music data) |
| Journey discovery | `get_child_journal` SECDEF + `is_child_parent` gate + `current_profile()` | parent đọc TRỌN journey con mình; school chỉ thấy `source='demen'` |
| Meaning ("Nhìn lại") | Engine lành, **nhưng sẽ NGỦ suốt pilot** | ⚠️ xem cold-start bên dưới |
| Media viewing | Signed URL qua Edge (dma-private) | ⚠️ video-compat chưa verify (MUST-FIX #6) |
| Mobile | frozen-4 bottom nav preserved (V126 PASS 390px) | audit cấu trúc OK; real-device pilot cần smoke |

**⚠️ COLD-START MEANING LAYER (finding trọng yếu, không phải bug):**
Toàn hệ thống hiện có **đúng 1 discovery capsule** (của bé An, từ QA V126). Lịch sử journey cũ nhất mới ~1.5 tháng (24/6). Readiness gate v2 (`compute_child_evidence_readiness`) yêu cầu **cửa sổ longitudinal 3m/6m/12m + chống retrospective-concentration**. Cohort ballet mới bắt đầu 17/8 = **0 lịch sử** → **100% trẻ pilot sẽ ở State 3 "accumulating_insufficient"** trong suốt pilot ngắn. Flagship "Nhìn lại" của V126 **sẽ không sinh capsule nào** cho gia đình pilot trong nhiều tháng.
→ **Không phải lỗi** — gate chạy đúng thiết kế (Memory > Metric). Nhưng là **kỳ vọng phải set trước**: trải nghiệm phụ huynh pilot = **Nhật ký (records) + Hôm nay + Gia đình**, KHÔNG phải capsule khám phá.

---

## 2️⃣ TEACHER WORKFLOW — audit

| Điểm kiểm | Kết quả | Ghi chú |
|---|---|---|
| Class access | `get_teacher_classes` SECDEF + `current_profile()` | teacher thấy lớp của mình |
| Create journey | write-path qua session/journey (school-gated) | flow đã chạy trên demo; cần real-login trên data ballet |
| Upload media | Edge signer path | ⚠️ video-compat (MUST-FIX #6) |
| Write observation | `child_observations` INSERT (teacher) + UPDATE (`is_session_lead OR is_session_teacher`) | write gated theo session responsibility |
| Parent visibility | qua `parent_visible` note / journey projection | **teacher meaning-signal gần như trống** (residual V126) → accumulation yếu |

**⚠️ Observation SELECT scope = `same_school(...)`, KHÔNG strict class-only.** Teacher (authenticated) đọc observation phạm vi **toàn trường**, không giới hạn lớp được phân. Với pilot **một academy, một teacher champion dạy cả 2 lớp** → rủi ro thực tế = thấp/không. Nhưng nghiêm ngặt mà nói đây **không phải class-isolation** — cần biết rõ khi về sau có nhiều teacher.

---

## 3️⃣ SECURITY BOUNDARY — audit (cao nhất về niềm tin)

**Kết luận cấu trúc: VỮNG.** Không thấy lỗ hổng cross-child rõ ràng ở tầng cấu trúc.

- **Parent chỉ thấy con mình:** `children_select_parent = is_child_parent(id)`; `is_child_parent` = SECDEF, `search_path=''`, gate theo `child_parents.parent_profile_id = current_profile()`. ✅
- **Journey isolation:** `child_journey` SELECT = `is_child_parent(child_id) OR (child_in_my_school(child_id) AND source='demen')` → parent đọc trọn con mình; **school KHÔNG đọc được parent-authored memory** (đúng LINH HỒN). ✅
- **Memory & capsule = deny-all direct:** `parent_memories`, `parent_memory_media`, `discovery_capsules` có **RLS ON + 0 policy** → PostgREST trực tiếp bị chặn hoàn toàn; chỉ vào được qua SECURITY DEFINER RPC đã gate `is_child_parent`. Đây là pattern hardened ĐÚNG (RPC-only), **KHÔNG phải leak**. ✅
- **Mọi bảng nhạy cảm RLS ON:** children, child_journey, child_observations, learning_moments, session_reports, moment_children, child_badges, child_skills, enrollments, family_members. ✅
- **Entry RPC gating:** `get_child_journal` / `get_child_evidence_readiness` / `list_discovery_capsules` = SECDEF + child_parent_gate; `get_session_detail` = school_gate. ✅

**Cần Owner Gate xác nhận bằng real-login (D2/D3):** 2 gia đình pilot thật, đăng nhập chéo — parent A **không** thấy bất kỳ dấu vết nào của con nhà B (journey, ảnh, capsule, daily focus). Đây là bài kiểm phải PASS trước khi mời phụ huynh thật.

---

## 4️⃣ BALLET-PILOT REALITY GAP (provisioning)

| Hạng mục | Cần cho pilot | Thực trạng live | Trạng thái |
|---|---|---|---|
| Tenant | "Dế Mèn Ballet Academy" | Chỉ 3 trường mầm non (DEMO-001, MNDM-DN, KHM-DN). **Không có academy.** | ❌ THIẾU |
| Program/curriculum | Ballet | **"Múa Ballet Dế Mèn"** (slug `ballet`, domain `dance_movement`, **published**) — align meaning-engine | ✅ CÓ |
| Entitlement | Academy → ballet | ballet entitled ở KHM + DEMO (không có academy riêng) | ⚠️ lệch tenant |
| Class | Hạt Nắng + Cánh Hoa | 5 lớp toàn tên mầm non; **không có 2 lớp ballet**; tất cả `age_group_id`/`level_id` = NULL | ❌ THIẾU |
| Age band | 3–4.5t (36–54th) + 5–8t (60–96th) | ballet chỉ có **1 age_group "4–5 tuổi" (48–60th)** — **không phủ** cả 2 cohort | ❌ LỆCH |
| Teacher champion | Cô Thuý Ngân (academy) | Chỉ "Cô Thúy Ngân **Demo**" (lead_teacher @ DEMO-001) — demo, chưa onboard thật | ❌ THIẾU |
| Quy mô | ~30 trẻ / ~30 PH | **16 trẻ / 13 primary_parent** toàn demo | ❌ THIẾU |

**Lưu ý age 5–8t (Cánh Hoa):** vượt trần preschool (mầm non) mà toàn hệ thống được thiết kế quanh đó. Kỹ thuật: children lưu DOB, tuổi suy diễn, age_group enforcement lỏng (class NULL) → rủi ro kỹ thuật thấp. Nhưng là **câu hỏi curriculum-fit cho CPO**: giáo trình ballet có thiết kế cho 5–8t không?

---

## 5️⃣ PILOT BLOCKER CLASSIFICATION

### 🔴 MUST FIX BEFORE 17/8
1. **Quyết định + cấp phát tenant pilot.** Tạo school "Dế Mèn Ballet Academy" (hoặc quyết định chạy dưới trường có sẵn). *Data provisioning, không migration.*
2. **Reconcile age band ballet.** Thêm/sửa age_group phủ Hạt Nắng (36–54th) + Cánh Hoa (60–96th); "4–5 tuổi" hiện tại không phủ cohort nào. Xác nhận với CPO việc chấp nhận 5–8t vượt preschool. *Config/data.*
3. **Tạo 2 lớp ballet** (Hạt Nắng, Cánh Hoa) gắn program ballet; xác minh subject/program **thực sự chảy vào journey** khi class có program (hiện mọi class NULL → chưa từng chứng minh binding này hoạt động). *Data + verify.*
4. **Onboard teacher champion thật** cho Cô Thuý Ngân (không dùng account Demo) + phân công cả 2 lớp.
5. **Cấp phát cohort:** ~30 children + ~30 parent + parent_invitations + child_parents links + enrollments.
6. **Verify VIDEO capture/upload/playback trên mobile** cho clip múa (iPhone quay mặc định HEVC/MOV). Residual "media compat MOV/HEVC/WebM normalization" hiện là **backlog** — nhưng với pilot **múa (video-first)** đây là tuyến đầu. Phải: (a) 1 clip iPhone thật upload + phát được cho phụ huynh, HOẶC (b) đặt ràng buộc format có tài liệu cho teacher. *Verify (đọc signer source + real-device).*
7. **Owner Gate real-login trên chính data pilot (D2/D3):** parent first-login chỉ thấy con mình · teacher chỉ thấy lớp được phân · **kiểm chéo 2 gia đình thật không leak**.

### 🟡 SHOULD FIX DURING PILOT
- **Set kỳ vọng "Nhìn lại" ngủ đông** suốt pilot (cold-start). Cân nhắc copy/onboarding để phụ huynh không hiểu nhầm là hỏng — hoặc quyết định sản phẩm làm mềm copy State-3 cho trẻ hoàn toàn mới.
- **Seeding teacher meaning-signal:** hướng dẫn Cô Thuý Ngân ghi highlight/observation parent-visible đều đặn để accumulation không rỗng.
- **Observation scope school-wide (không class-only):** chấp nhận cho pilot 1-teacher; ghi nhận để revisit khi multi-teacher.
- Cosmetic: comment lệch tên bridge trong `parent.index.tsx` (residual V126, non-blocking).

### ⚪ LATER (ngoài pilot)
- `/kid` Portal V2 (PIN) — không cần cho pilot.
- Media normalization pipeline đầy đủ (MOV/HEVC/WebM).
- Tooling excludes-hardening milestone (`minimumReleaseAgeExcludes`).
- Auto-generation capsule khi eligible · per-domain "change" narrative (cần product contract riêng).

---

## 6️⃣ OWNER GATE CHECKLIST (real-login, trên data pilot thật)

- [ ] Parent pilot #1 login → chỉ thấy con mình (journey/ảnh/daily focus/capsule).
- [ ] Parent pilot #1 **không** thấy bất kỳ dấu vết con của Parent pilot #2 (kiểm chéo).
- [ ] Cô Thuý Ngân login → thấy đúng Hạt Nắng + Cánh Hoa, tạo journey được, upload media được, ghi observation được.
- [ ] Teacher observation parent-visible → phụ huynh đúng bé nhìn thấy; bé khác không.
- [ ] 1 clip múa iPhone thật: upload → phụ huynh phát được trên mobile (hoặc ràng buộc format documented).
- [ ] Mobile smoke trên thiết bị thật (frozen-4 nav, media, journey) — cả 2 dải tuổi.
- [ ] Discovery State 3 hiển thị "đang tích luỹ" nhẹ nhàng, không giống lỗi (ANTI_PRESSURE).

---

## ĐỊNH HƯỚNG (câu hỏi cho CPO/Pilot Director — KHÔNG tự mở)

1. Pilot chạy dưới **tenant academy mới** hay **trường có sẵn**? (quyết định #1 kéo theo entitlement + class + teacher assignment).
2. Chấp nhận **Cánh Hoa 5–8t** vượt khung preschool ở mức curriculum không?
3. Kỳ vọng cho **"Nhìn lại"** trong pilot ngắn: chấp nhận ngủ đông, hay cần điều chỉnh copy State-3 (product decision, cần contract)?
4. Ràng buộc **video format** cho teacher, hay ưu tiên đẩy media-compat lên trước pilot?

---

**Trạng thái:** `NOT READY (09/08/2026) — provisioning + verification gated, platform sound`. Không có defect nền tảng chặn pilot; đường tới READY = đóng 7 MUST-FIX + Owner Gate real-login PASS. **KHÔNG canonicalize** (RULES/SYSTEM_MAP/HANDOFF giữ nguyên D344/v1.32/V126-M1) cho tới khi Owner Gate PASS. Zero DB/schema/deploy delta phiên này (audit read-only thuần).
