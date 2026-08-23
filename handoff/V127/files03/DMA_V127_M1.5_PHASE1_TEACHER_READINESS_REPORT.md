# 🩰 DMA V127-M1.5-PHASE1 — TEACHER READINESS REPORT (Ballet)

> **Loại:** Teacher workflow validation (read-only). **Chưa mutation — chờ Owner Gate.**
> **Pilot:** Vườn Nghệ Thuật Dế Mèn (`VNDM-DN`) · program **Múa Ballet Dế Mèn** · Teacher **Cô Thuý Ngân** · lớp **Ballet Hạt Nắng** + **Ballet Cánh Hoa**.
> **Baseline (khớp):** RULES **D344** · SYSTEM_MAP **v1.32** · HEAD **`6b860338`** · inventory bất biến 89/215/204/166 · tail `20260807130914`.
> **Câu hỏi cốt lõi:** một cô giáo ballet thật có tạo được **journey content có ý nghĩa** không?

---

## 0. VERDICT

**`TEACHER PATH READY (program-agnostic) · CONTENT STRUCTURE THIN cho ballet · chờ account + Owner Gate`.**

Đường ghi của teacher (session → media → observation → parent) **không khoá theo môn** — chạy cho ballet y hệt nhạc. **Không có defect** chặn. Nhưng để content **"có ý nghĩa" + có cấu trúc** cho ballet, còn 2 khoảng trống data: **chưa gán teacher** (account chưa có) và **ballet chưa có skill taxonomy** (technique/concentration/group chỉ ghi được dạng free-text, không tag chuẩn).

---

## 1. TEACHER PORTAL FLOW — audit (cấu trúc/logic)

| Bước | Cơ chế (verified live) | Kết quả |
|---|---|---|
| **Login** | `current_profile()` từ auth.uid | ✅ (cần account cô thật) |
| **Class visibility** | `get_teacher_classes`: thấy distribution khi `lead_teacher_id=self` **HOẶC** là `session_teacher` ≥1 buổi | ✅ cơ chế OK · ⚠️ VNDM `lead_teacher_id=NULL` → **cô chưa thấy lớp nào tới khi gán** |
| **Child list** | `child_count` từ `enrollments` (active) trong get_teacher_classes; danh sách bé qua session detail | ✅ cơ chế OK · ⚠️ VNDM enrollments=0 → phụ thuộc cohort |
| **Create journey/session** | `create_lesson_session` (SECDEF, school-scope, **program-agnostic**) + session ad-hoc chạy được | ✅ |
| **Media upload** | `media_assets` + Bunny; video qua Bunny Stream | ✅ path OK · ⚠️ **video-compat** (§3.2) |
| **Observation** | `submit_session_journal` → `child_observations` (note free-text + skills_observed + is_highlight + visibility), **session-scoped**, program-agnostic | ✅ |
| **Parent visibility** | `get_child_journal` surface note **chỉ khi `visibility='parent_visible'`** (gắn đúng session); `private_internal` ở nội bộ | ✅ model sạch |

**Toàn bộ RPC ghi program-agnostic:** `create_lesson_session` · `start_session` · `submit_session_journal` · `set_session_teachers` · `create_session_appreciation` — **0 tham chiếu music/ctan lock**. Ballet dùng chung đường.

---

## 2. BALLET CONTENT WORKFLOW (task #3)

**Ba loại quan sát yêu cầu — đều TẠO ĐƯỢC, nhưng chỉ ở dạng free-text:**

| Loại quan sát | Ghi được? | Bằng cách nào |
|---|---|---|
| **Technique** (kỹ thuật/tư thế) | ✅ | `child_observations.note` free-text + `is_highlight` + `visibility=parent_visible` |
| **Concentration** (tập trung) | ✅ | note free-text (+ `needs_support`/`follow_up_needed` flag có sẵn) |
| **Group interaction** (tương tác nhóm) | ✅ | note free-text; hoặc `learning_moments` (caption + `theme_tag` tự do, nhiều bé qua `moment_children`) |

**NHƯNG — khoảng trống cấu trúc (finding chính):**
- **`skill_catalog` cho ballet = 0** (nhạc có 4: Cảm nhịp · Hát theo · Vận động theo nhạc · Lắng nghe). → Nếu form observation render skill-tag theo program, **ballet hiện rỗng** → cô **chỉ có free-text**, không có tag chuẩn technique/concentration/group.
- Hệ quả: (1) mỗi cô diễn đạt tự do → data kém nhất quán; (2) **tín hiệu cho meaning-engine yếu hơn** (skills_observed trống); (3) khó tổng hợp "con tiến bộ mảng nào".
- **`themes` ballet = 1** (mỏng, như nhạc).

**Khuyến nghị (data-only, KHÔNG feature/migration):** seed `skill_catalog` cho ballet ~5 mục program-scoped, ví dụ: **Kỹ thuật & tư thế · Tập trung · Tương tác nhóm · Cảm nhạc/nhịp · Biểu cảm sân khấu**. Đúng 3 loại task #3 = 3 tag đầu. Đây là INSERT vào bảng có sẵn (label do CPO chốt) → biến observation ballet từ "prose rời" thành "có cấu trúc + có ý nghĩa". **Chờ Owner Gate.**

---

## 3. BLOCKERS

### 🔴 MUST FIX BEFORE PILOT
1. **[ACCOUNT→DATA]** Account **Cô Thuý Ngân thật** (lead_teacher, school VNDM) → set `lead_teacher_id` cho 2 distribution → cô mới thấy lớp. Hiện chỉ "Cô Thúy Ngân **Demo**" @ DEMO-001.
2. **[VERIFY] Video-compat** (carried PHASE0A): iPhone HEVC/.MOV, 1/17 qua Bunny Stream → clip múa cô quay có thể **màn đen trên Chrome/Android**. Khoá **P1** (iPhone "Most Compatible"/H.264) + verify cross-device.
3. **[VERIFY] Owner Gate — 1 buổi ballet end-to-end thật:** cô login → tạo buổi → upload clip múa → ghi observation `parent_visible` → **phụ huynh đúng bé thấy note + video**. Ballet **chưa từng chạy end-to-end** → phải chứng minh, không suy từ flow nhạc.

### 🟡 SHOULD FIX (trước/trong pilot)
- **[DATA]** Seed `skill_catalog` ballet (§2) — để technique/concentration/group thành tag chuẩn + tăng tín hiệu meaning. Data-only, label CPO chốt.
- **[CONFIG]** **Approval mode:** VNDM tạo với mặc định `moment_approval_mode=true` + `report_approval_mode=true`, và **master=NULL**. Pilot 1 cô → moment/report cần duyệt nhưng **chưa có người duyệt** → nội dung có thể **kẹt không tới phụ huynh**. Quyết định: tắt approval cho pilot (`false`) HAY có master duyệt. *(Data update, chờ Owner.)*
- **[ONBOARDING]** Hướng dẫn cô phân biệt `parent_visible` vs `private_internal` rõ ràng, để note thật sự tới phụ huynh.

### ⚪ LATER
- Curriculum ballet đầy đủ (hiện stub 1 bài — ad-hoc đủ chạy) · route video → Bunny Stream (gốc video-compat) · themes ballet phong phú.

---

## 4. SECURITY / SCOPE (teacher side)
- Observation SELECT (staff) = `same_school(...)` → **school-scope, không strict class-only**. Pilot 1 academy · 1 cô dạy cả 2 lớp → rủi ro ~0. Ghi nhận cho tương lai multi-teacher.
- Write gated theo **session authority** (D324): `submit_session_journal`/`start_session` = `is_session_lead OR is_session_teacher` — không fallback admin. Vững.
- Parent chỉ thấy observation `parent_visible` của con mình (qua `get_child_journal` + `is_child_parent`). Không leak chéo.

---

## 5. OWNER GATE CHECKLIST (real-login, khi có account + cohort)
- [ ] Set `lead_teacher_id` (2 distribution) = Cô Thuý Ngân thật → cô thấy đúng 2 lớp + child_count đúng.
- [ ] Cô tạo 1 buổi (mỗi lớp) → thấy danh sách bé.
- [ ] Upload 1 clip múa iPhone → phát được trên Android + Chrome desktop (hoặc P1 đã khoá).
- [ ] Ghi 3 observation: **technique · concentration · group** (parent_visible) → phụ huynh đúng bé thấy cả 3.
- [ ] 1 observation `private_internal` → phụ huynh KHÔNG thấy (xác nhận ranh giới).
- [ ] Moment có/không cần duyệt đúng như quyết định approval-mode.
- [ ] Kiểm chéo: cô/PH không thấy dữ liệu bé ngoài phạm vi.

---

## 6. CPO DECISIONS PENDING
1. Seed `skill_catalog` ballet? Nếu có → chốt ~5 nhãn tiếng Việt.
2. Approval mode VNDM: tắt cho pilot hay giữ + có master duyệt?
3. Account Cô Thuý Ngân + master → ai mời qua app.
4. Video: khoá P1 ngay?

---

**Trạng thái:** `TEACHER PATH READY (program-agnostic) · chờ account + skill seed + Owner Gate`. Đường ghi teacher không khoá môn, ballet chạy chung; 3 loại observation task#3 tạo được (free-text ngay, tag chuẩn cần seed skill_catalog — data-only). Blocker còn lại = account + video verify + Owner Gate 1-buổi-end-to-end + config approval. **KHÔNG mutation phiên này · KHÔNG canonicalize** (giữ D344/v1.32/V126-M1). Inventory bất biến. Delta = 0 (read-only).
