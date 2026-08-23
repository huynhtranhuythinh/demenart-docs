# 🩰 DMA V127-M1.5-PHASE0A — BALLET PILOT PROVISIONING & READINESS (CTO REPORT · UPDATED)

> **Loại:** Provisioning executed (tenant shell) + readiness report cho CTO. **KHÔNG migration schema · KHÔNG deploy · KHÔNG canonicalize.**
> **Pilot:** Vườn Nghệ Thuật Dế Mèn · **Ballet Hạt Nắng** (3–4.5t) + **Ballet Cánh Hoa** (5–8t) · Teacher Champion **Cô Thuý Ngân** · ~30 trẻ / ~30 PH · **17/08/2026**.
> **Baseline pin (khớp):** RULES **D344** · SYSTEM_MAP **v1.32** · HEAD **`6b860338`** · signer deploy-25 (v24). Live inventory bất biến: **89 tables · 215 func · 204 SECDEF · 166 policies · tail `20260807130914`**.
> **Bản này SUPERSEDE** bản PHASE0A trước (khi tenant còn chưa chốt).

---

## 0. EXECUTIVE SUMMARY (cho CTO)

- **Owner decision đổi + re-lock:** từ "không tạo tenant mới" → **tạo tenant độc lập** (Vườn Nghệ Thuật Dế Mèn), tách hoàn toàn khỏi Trường Mầm Non Dế Mèn. Lý do: đây là **cơ sở nghệ thuật riêng**, không nằm trong trường mầm non; tenant riêng cho data sạch + định vị đúng + future-proof đa môn.
- **Đã provisioning (thực thi live):** tenant shell hoàn chỉnh — school + entitlement ballet + 2 lớp + 2 class_distributions bind ballet. **Toàn bộ là data INSERT vào bảng có sẵn — KHÔNG DDL/migration/Edge/deploy.** Inventory bất biến.
- **Trạng thái:** `SHELL READY · PILOT NOT READY`. Nền tảng + môi trường ballet đã sẵn; còn thiếu **account (master/teacher/parent)** + **cohort trẻ thật** + **verify video** + **Owner Gate real-login**.
- **Rủi ro #1 cần CTO chú ý:** **video iPhone HEVC/.MOV** — chỉ 1/17 video hiện đi qua Bunny Stream; raw MOV phát hỏng trên Chrome desktop/Android. Pilot múa = video-first → phải khoá cách quay trước 17/8.
- **Không có defect nền tảng chặn pilot.** Đường tới READY = account + cohort + verify, không cần engineering mới.

---

## 1. ĐÃ PROVISIONING — tenant shell (LIVE, verified)

Thực thi bằng **1 statement atomic** (data-modifying CTE; lỗi → rollback trọn, không để rác). Verify bằng câu đọc độc lập (D3).

| Object | ID | Chi tiết |
|---|---|---|
| **School** | `064dd53e-7aec-4085-9158-02bcd0945af3` | `Vườn Nghệ Thuật Dế Mèn` · code **`VNDM-DN`** · state active · curriculum_scope school · **master = NULL** |
| **Entitlement** | `a81d5e55-4bf0-45dc-a5ee-ea87640c1cb7` | program **ballet** · status **active** · start hôm nay · end +1 năm |
| **Class 1** | `9518e115-b9aa-44c4-9c5f-d573493578b7` | **Ballet Hạt Nắng** · active |
| **Class 2** | `5d8795fd-4089-4f31-bb89-7a64e90cf194` | **Ballet Cánh Hoa** · active |
| **Distribution 1** | `4bd46ca0-ec55-44af-ad4b-1dbe95f1b811` | "Ballet · Ballet Hạt Nắng" · program ballet · **lead_teacher NULL** |
| **Distribution 2** | `e41c5bc2-20c6-4c43-b9e2-14624533eb36` | "Ballet · Ballet Cánh Hoa" · program ballet · **lead_teacher NULL** |

**Verify state:** `VNDM-DN · active · master=NULL · entitlements=ballet(active) · classes=2 · distributions=2 · children=0` → **độc lập, 0 dính MNDM, 0 demo data.**

**Assumptions đã chọn (CTO override được):** code `VNDM-DN` · entitlement `active` (không `trial` để không hiện banner dùng thử cho gia đình thật) · lead_teacher `NULL` (gán khi có account cô thật) · chưa seed age_group riêng (bind đi qua class_distributions nên không cần — xem §3).

**Delta phiên này:** +1 school · +1 entitlement · +2 classes · +2 class_distributions = **6 dòng data**. Zero schema/function/policy/Edge/route/deploy. **Rollback** = xoá 6 dòng theo `school_id`.

---

## 2. CƠ CHẾ BIND SUBJECT (đã verify — nền tảng của shell)

```
classes (nhóm trẻ)
  └─ class_distributions (class_id + program_id[ballet] + lead_teacher_id?)   ← chỗ gắn môn (KHÔNG qua class.age_group_id, cột legacy NULL)
        └─ lesson_sessions (chỉ class_distribution_id NOT NULL; title/scheduled_at/item nullable → buổi AD-HOC chạy được)
              └─ child_journey / moments / observations / media → parent view
enrollments (child_id + class_id)  ← trẻ thuộc lớp
```

- Model đã chứng minh ở KHM (2 distribution ballet active). 1 lớp mang nhiều môn được.
- **Curriculum ballet = stub 1 bài** ("Lộ trình Ballet học kỳ 1", 1 item) + **0 session ballet từng chạy** → **KHÔNG chặn** (session ad-hoc là container ghi múa), NHƯNG ballet path **chưa từng end-to-end** → Owner Gate phải test 1 buổi thật.

---

## 3. BLOCKER CLASSIFICATION (cập nhật sau provisioning)

### ✅ ĐÃ XONG (phiên này)
- Tenant độc lập · entitlement ballet · 2 lớp ballet · 2 distribution bind ballet.

### 🔴 MUST FIX BEFORE PILOT (còn lại)
1. **[ACCOUNT]** Master admin tenant → mời qua app → set `schools.master_profile_id`. *(Claude không tạo auth account.)*
2. **[ACCOUNT]** **Cô Thuý Ngân account thật** (role lead_teacher, school VNDM) → em set `lead_teacher_id` cho 2 distribution. Hiện chỉ có "Cô Thúy Ngân **Demo**" @ DEMO-001 — KHÔNG dùng.
3. **[DATA/ACCOUNT]** **~30 trẻ + ~30 phụ huynh thật**: em INSERT children/enrollments (cần tên + dob + lớp); anh mời phụ huynh qua `parent_invitations` + link `child_parents`.
4. **[DECISION/VERIFY] VIDEO-COMPAT** (xem §4) — rủi ro sống.
5. **[VERIFY]** Owner Gate real-login trên data pilot thật: parent chỉ thấy con mình · teacher chỉ thấy 2 lớp mình · **kiểm chéo 2 gia đình không leak** · **1 buổi ballet end-to-end thật**.

### 🟡 SHOULD FIX DURING PILOT
- **[DECISION]** Age group Hạt Nắng (36–54th) / Cánh Hoa (60–96th) — đúng hơn nhưng không chặn (bind qua distribution). Xác nhận **Cánh Hoa 5–8t vượt trần preschool** ổn về curriculum.
- **[DECISION]** Curriculum ballet stub — chạy ad-hoc đủ cho memory-capture, hay cần khung bài?
- **Kỳ vọng "Nhìn lại"/Discovery ngủ đông** toàn pilot: cohort mới = 0 lịch sử longitudinal → 100% State 3. Set copy/onboarding để không hiểu nhầm là lỗi. (Toàn hệ thống hiện mới **1 capsule**.)
- **Seeding teacher meaning-signal:** hướng dẫn cô ghi observation parent-visible đều.
- Observation SELECT school-scoped (không class-only) — chấp nhận cho pilot 1-teacher.

### ⚪ LATER
- Route video → Bunny Stream (transcode HLS) — giải pháp gốc video-compat (infra, ngoài "no feature").
- Media normalization pipeline đầy đủ · `/kid` Portal V2 · auto-generate capsule · per-domain change narrative · tooling excludes-hardening.

---

## 4. MEDIA AUDIT — iPhone ballet video (rủi ro #1)

**Live (112 asset):** image 84 · **video/mp4 9 · video/quicktime(.MOV) 8** · audio 11 · webp 2. **Chỉ 1 asset** đi qua Bunny Stream (`bunny_stream_video_id`); **16/17 video lưu raw**.

**Rủi ro:** iPhone quay mặc định **HEVC/.MOV** → raw lưu thẳng → **OK trên Safari/iOS, MÀN ĐEN trên Chrome desktop + nhiều Android**. Pilot múa video-first → xác suất cao gặp.

**Kiến trúc đã có đường đúng** (`bunny_stream_video_id` + `stream_only` → Bunny Stream HLS) nhưng pipeline upload gần như không route video vào Stream (1/17).

**Phương án (CTO chọn):**
- **P1 — vận hành, rẻ, ngay, 0 code (khuyến nghị làm ngay):** iPhone Cô Thuý Ngân → Settings → Camera → Formats → **"Most Compatible" (H.264)**.
- **P2 — route video → Bunny Stream** (gốc, transcode HLS): infra, có thể chạm "feature" → contract riêng, khả năng LATER.
- **P3 — transcode server-side:** infra, LATER.

**[VERIFY] bắt buộc:** 1 clip iPhone thật (MOV) → upload qua flow teacher → phụ huynh mở trên **Android + Chrome desktop** → phát được. Fail → khoá P1 làm ràng buộc documented.

---

## 5. SECURITY BOUNDARY (đã verify cấu trúc — VỮNG)

- Parent chỉ thấy con mình: `children_select_parent = is_child_parent(id)` (SECDEF, `search_path=''`, gate `child_parents.parent_profile_id = current_profile()`).
- Journey isolation: parent đọc trọn con mình; school chỉ thấy `source='demen'` (đúng LINH HỒN, không thấy parent-authored memory).
- `parent_memories`/`parent_memory_media`/`discovery_capsules`: **RLS ON + 0 policy = deny-all direct** → chỉ vào qua SECDEF RPC gated. Mọi bảng nhạy cảm RLS ON.
- Entry RPC gated: `get_child_journal`/`get_child_evidence_readiness`/`list_discovery_capsules` = SECDEF + child_parent_gate.
- **Cần Owner Gate real-login (D2/D3) xác nhận hành vi** với 2 gia đình pilot thật (kiểm chéo không leak) trước khi mời phụ huynh.

---

## 6. RUNBOOK CÒN LẠI (khi có account + data thật)

1. Set `master_profile_id` = master account (sau invite).
2. Set `lead_teacher_id` (2 distribution) = Cô Thuý Ngân account thật.
3. INSERT `children` (full_name + dob) + `enrollments` phân về 2 lớp theo tuổi.
4. `parent_invitations` (app) + `child_parents` link parent↔child.
5. Khoá video P1 + verify cross-device.
6. Owner Gate real-login (§7).

> Tất cả bước còn lại vẫn là **data + account**, **không migration**. Chờ tài liệu account/cohort từ CTO/Owner rồi thực thi.

---

## 7. OWNER GATE CHECKLIST (real-login, data pilot thật)
- [ ] CTO chốt: age-group approach · curriculum ad-hoc vs khung · video P1/P2.
- [ ] Cô Thuý Ngân (account thật) login → thấy đúng 2 lớp ballet, tạo buổi, upload media, ghi observation.
- [ ] **1 buổi ballet end-to-end thật:** session → clip múa → observation parent-visible → phụ huynh đúng bé thấy.
- [ ] Parent #1 chỉ thấy con mình; **không** thấy dấu vết con Parent #2 (kiểm chéo).
- [ ] Clip iPhone MOV phát được trên Android + Chrome desktop (hoặc P1 constraint đã khoá).
- [ ] Mobile smoke thiết bị thật cả 2 dải tuổi (nav frozen-4, media, journey).
- [ ] Discovery State 3 hiển thị "đang tích luỹ" nhẹ nhàng (ANTI_PRESSURE).

---

## 8. CTO DECISIONS PENDING
1. **Master admin** tenant VNDM là ai → mời qua app.
2. **Age band:** thêm age_group Hạt Nắng/Cánh Hoa hay bỏ qua? Chấp nhận **Cánh Hoa 5–8t**?
3. **Curriculum:** ad-hoc hay cần khung bài trước pilot?
4. **Video:** khoá P1 ngay, hay ưu tiên P2 Bunny Stream?
5. **Cohort intake:** gửi danh sách trẻ (họ tên · dob · lớp) + phụ huynh (tên · email/sđt) → em chuẩn bị template điền sẵn nếu cần.

---

**Trạng thái:** `SHELL READY · PILOT NOT READY — chờ account + cohort + verify + Owner Gate`. Tenant độc lập Vườn Nghệ Thuật Dế Mèn đã provisioning live (6 dòng data, zero schema/deploy). **KHÔNG canonicalize** (giữ D344/v1.32/V126-M1) cho tới Owner Gate PASS. Inventory bất biến 89/215/204/166 · tail `20260807130914`. Delta = data-only, rollback = xoá 6 dòng theo `school_id=064dd53e-7aec-4085-9158-02bcd0945af3`.
