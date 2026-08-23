# 🤝 DMA_HANDOFF_v5.md

> **Phiên:** v5 (đóng **2 cụm RLS** trong 1 phiên: **Sessions** mig 018 + **Journey** mig 019 — đều nghiệm thu bằng login thật 4 vai trò)
> **Đóng phiên:** 2026-06-24 23:41 (GMT+7)
> **Naming:** DMA = nền tảng; CTAN = module đầu. Không "DMMA".

---

## 0. MỤC LỤC PHIÊN (đã làm gì)
1. Boot: đọc 00/RULES/HANDOFF_v4 + audit thật trên đĩa → RULES=v4 (D52+`current_school_id`), SYSTEM_MAP=v0.5. Library KHÔNG tụt.
2. Chọn hướng: **RLS cụm Sessions** (giữ nhịp DB-first).
3. **Audit DB thật cụm Sessions** (1 JSON): 5 bảng RLS bật/0 policy · enum `session_state`(9) · signature thật `is_distribution_lead(p_cd_id)` + `is_session_teacher(p_session_id)` · `lesson_sessions.content_override` (D44). Micro-audit `class_distributions` → `class_id`(NOT NULL)/`lead_teacher_id`(nullable).
4. **Chốt thiết kế:** READ = thành viên trường (option A — `same_school`, admin+PH loại tự động); WRITE theo người-trong-phòng; **school-admin step-in cho `session_reports`** (moat chống GV nghỉ).
5. **Thi công mig 018** (15 policy + 3 helper `cd_school_id`/`session_school_id`/`is_session_lead`). Verify JSON: 3/bảng, helper secdef, exec_leak=[].
6. **Seed `seed_003`** (kho rỗng → seed trước): 1 chuỗi distribution→session→teacher→observation→report cho bé Jenny, lead=Cô Thúy Ngân.
7. **Lovable**: thêm section "Buổi học (Sessions)" vào `/portal/rls-test` (5 count + write-block observation). Client-side D13/D82. KHÔNG "Try to fix all".
8. **NGHIỆM THU SESSIONS** login thật: READ ma trận + master ĐỌC-mà-GHI-bị-chặn (banner xanh) + teacher-lead ghi THÀNH CÔNG.
9. Chuyển **cụm Journey** (recommend trước Media vì Media chủ yếu Edge-gated; Journey = trái tim DMA).
10. **Audit Journey** (1 JSON): 5 bảng, chia 2 nhóm (A gắn-trẻ PII / B catalog toàn cục). `child_journey.source` default 'demen'.
11. **Chốt 2 ngã rẽ:** badges/home_activities cho PH đọc (khác curriculum); child_journey WRITE V1 = trường.
12. **Thi công mig 019** (15 policy, không helper mới). Verify: 3/bảng, 3 helper present.
13. **Seed `seed_004`** (kho rỗng): bé Jenny 2 journey + 1 skill + 1 badge def + 1 child_badge(confirmed) + 1 home_activity.
14. **Lovable**: section "Nhật ký (Journey)" (5 count + write-block entry; đổi target sang `child_journey` để tránh unique-collision của child_badges).
15. **NGHIỆM THU JOURNEY** login thật: 3 phép thử linh hồn ĐẠT (parent đọc trọn nhật ký con; admin 0 PII journey; parent ghi entry → chặn).
16. Chốt phiên: SYSTEM_MAP v0.6 + RULES (D53+D54+3 helper) + handoff này.

---

## 1. TRẠNG THÁI FILE — ⚠️ ĐẦU PHIÊN SAU: anh LƯU 2 file vào Project Knowledge (thay bản cũ)
- **`DMA_SYSTEM_MAP`** → **v0.6** (§3 Sessions + Journey = ✅ XONG; §6 thêm mig 018/019 + seed_003/004, definer=26, policy=86, bước kế=Privacy/Business/Moments/Ops/Media; §7 panel 7 mục + nghiệm thu v5).
- **`DMA_RULES`** → thêm **D53** (RLS Sessions) + **D54** (RLS Journey) + 3 helper `cd_school_id`/`session_school_id`/`is_session_lead` vào D23.
- **Không đổi:** `DMA_00_START_HERE` · `DMA_BUILD_PATH` · `DMA_05_DMWS_REFERENCE` · `DMA_A_PRD`..`DMA_G`.
> **File SQL đã chạy (lưu repo):** `001`→`019` (19 file) + `seed_001`→`seed_004` — đều idempotent.

---

## 2. ⭐ NGHIỆM THU (bằng chứng thật — login 4 vai trò)

### Cụm SESSIONS (mig 018)
**READ (count theo RLS):**

| Login | lesson_sessions | session_teachers | session_media | session_reports | child_observations |
|---|---|---|---|---|---|
| `info@` super_admin | **0** | 0 | 0 | **0** ⭐ | **0** ⭐ (D48) |
| thành viên trường (master/teacher) | 1 | 1 | 0 | 1 | 1 |
| `parent.demo` | **0** ⭐ | 0 | 0 | 0 | 0 |

**WRITE:** `master.demo` bấm "thêm observation" → **banner xanh** "RLS chặn ghi" + DB thật `new row violates RLS policy for table "child_observations"` (ĐỌC được nhưng không THAO TÁC — D45). `teacher.demo` (lead) → ghi THÀNH CÔNG (người trong phòng).

### Cụm JOURNEY (mig 019) — 3 PHÉP THỬ LINH HỒN
**READ (count theo RLS):**

| Login | child_journey | child_skills | child_badges | badges | home_activities |
|---|---|---|---|---|---|
| `info@` super_admin | **0** ⭐ | **0** ⭐ | **0** ⭐ | 1 | 1 |
| master/teacher | 2 | 1 | 1 | 1 | 1 |
| `parent.demo` | **2** ⭐ | **1** ⭐ | **1** ⭐ | 1 | 1 |

**WRITE:** `parent.demo` bấm "thêm entry nhật ký" → **banner xanh** + DB thật `new row violates RLS policy for table "child_journey"` (PH đọc-mà-chưa-ghi V1 — D40 thép chờ V2).

→ **Sessions + Journey: nghiệm thu trọn READ+WRITE. 4/~8 cụm RLS xong.**

---

## 3. ⭐ TRẠNG THÁI THẬT (DB + App)
- **DB:** 44 bảng · **26 hàm SECURITY DEFINER** (23 cũ + 3 Sessions) · **1 non-definer** `is_school_admin` · **86 RLS policy** (56 cũ + 15 mig 018 + 15 mig 019). Idempotent, tested trên `dma`.
- **RLS theo cụm:**
  - ✅ **Org/People** (mig 011–016) · ✅ **Curriculum** (017) · ✅ **Sessions** (018) · ✅ **Journey** (019) — đều nghiệm thu login thật.
  - 🔒 **~26 bảng còn lại CHƯA policy → khóa kín:** Moments · Privacy/Consent · Media · Business · Ops.
  - ⏳ **Hoãn cố ý:** `child_duplicates` (admin-ops) · DELETE phần lớn bảng (soft-delete qua `state`) · entitlement-gate đọc catalog.
- **App:** `/portal/rls-test` panel 7 mục (Org/People + escalation + Curriculum + Sessions + Journey, mỗi cụm có write-block). 4 user thật chạy được.
- **Seed:** trường DEMO-001 · lớp Mầm A · master/teacher/parent · bé Jenny · CTAN+Ballet · 1 buổi CTAN(completed) · nhật ký Jenny (2 entry + kỹ năng + huy hiệu).
- **Test users:** `info@` super_admin · `master.demo`/`teacher.demo`/`parent.demo` = `DemoDMA2026!` (xoá/đổi pass trước khi lên thật).

---

## 4. OPEN ITEMS
- **🧹 Dọn row test:** cú bấm write-block của teacher/master để lại row thật. Chạy khi tiện:
  - `delete from public.child_observations where note like 'WRITE-BLOCK TEST%';`
  - `delete from public.child_journey where entry_type = 'WRITE-BLOCK TEST (panel)';`
- **RLS cụm còn lại** theo độ độc lập: **Privacy/Consent** (D47 engine 2 tầng — min(trường,PH), multi-child MIN) → **Business/License** (D51 seat×môn) → **Moments** → **Ops** → **Media** (mỏng ở RLS; phần thịt = Edge Functions, gộp Phase 4).
- **Trường đọc profile PH:** school-admin chưa thấy profile PH (parent `school_id` NULL). Policy nhỏ khi build màn liên hệ PH.
- **`child_duplicates`** + sensitive-access pipeline (Edge `request_sensitive_access`) — khi làm admin-ops/D48.
- **Leaked Password Protection** — anh bật ở Auth → Attack Protection (toggle; KHÔNG code).
- **DELETE policies** + activation flow (set `user_id`) — RPC riêng sau.
- **Tách 4 portal** (`/admin /school /teacher /parent`) — khi mỗi portal có nội dung.
- **Security issue Lovable** (7–13) — bỏ qua, ĐỪNG "Try to fix all" (D14).
- Giá thật `pricing_config`; permission catalog Sub-Admin; consent 2 tầng; deploy target — chốt Chặng 8.

---

## 5. ⭐ NEXT ACTION (đầu phiên sau)
1. Anh lưu **SYSTEM_MAP v0.6 + RULES** vào Project Knowledge.
2. Chọn cụm kế (recommend **Privacy/Consent** — độc lập, chạm D47 engine 2 tầng đáng đóng sớm; HOẶC **Business/License** D51). **Audit DB thật cụm đó (D1)** → viết RLS theo cụm → seed nếu rỗng → test login thật.
3. Hoặc: **Build UI Chặng 2 thật** (CRUD trường/lớp/trẻ qua RPC `create_child_and_enroll`) rời panel-test sang màn vận hành.

---

## 6. BOOT phiên sau
1. Đọc `DMA_00_START_HERE` → `DMA_RULES` → file này.
2. Xác nhận SYSTEM_MAP v0.6 + RULES (D53/D54 + 3 helper) đã ở Project Knowledge (audit thật — D1).
3. **Audit DB thật trước khi viết SQL** (`pg_policies`, `information_schema`, `pg_get_functiondef`): nhớ **26 hàm definer** + **86 policy** + guard/trigger.
4. Vào §5. Sequencing: RLS theo cụm → seed nếu rỗng (TRƯỚC khi test count) → test login thật (D2/D3) → Edge → UI.

---

## 7. TỰ ĐÁNH GIÁ
- **Được:** đóng **2 cụm RLS** trong 1 phiên với bằng chứng end-to-end mỗi cụm (ma trận READ 4 vai trò + banner WRITE chặn DB thật). Giữ kỷ luật **seed TRƯỚC khi test count** cả 2 cụm (tránh "0 vì chặn hay rỗng"). Bắt sớm 2 cái bẫy trước khi viết: (a) cụm Sessions có guard không? → audit thấy chỉ `updated_at`, nên seed không cần `replica`; (b) Journey write-block dùng `child_badges` có nguy cơ unique-collision che kết quả RLS → đổi target sang `child_journey` cho sạch. Chốt ngã rẽ bằng multiple-choice (READ-scope Sessions; badges-cho-PH) thay vì tự quyết. Verify-bằng-JSON từng bảng nên không bị tổng-nhẩm che lỗi. Recommend đổi thứ tự (Journey trước Media) có lý do kiến trúc rõ (Media = Edge-gated).
- **Sai & sửa:** không có lỗi SQL nào phải sửa lại phiên này (khác v3/v4 mỗi phiên 1–2 lỗi cú pháp). Một quyết định thiết kế chủ động đáng ghi: thêm **school-admin step-in cho `session_reports`** — không có trong spec gốc nhưng đúng moat "chống GV nghỉ việc"; đã flag rõ để anh duyệt, không lén.
- **Cần giữ:** audit signature THẬT helper trước khi dùng làm xương sống (đã verify `is_distribution_lead`/`is_session_teacher`); seed trước test; tách 2 nhóm khi bảng lệch mô hình (Journey A/B); panel write-block 1 nút là đòn bẩy rẻ chứng minh WITH CHECK; chụp Plan Lovable, không auto-fix DB; đọc giờ thật qua `TZ date`.
- **Lưu ý phiên sau:** **Privacy/Consent KHÁC mọi cụm trước** — consent hiệu lực = **min(trường, PH)**, multi-child → MIN; rút consent theo loại (D47) → có thể cần helper tính min + bảng `consents` 8 loại; audit kỹ enum loại consent. **Media** đừng làm RLS thuần một mình — phần thịt là Edge `get_signed_media_url` (D61), gộp Phase 4. Nhớ dọn 2 row test (§4) trước khi seed/test cụm có liên quan đến trẻ.
