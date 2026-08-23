# 🤝 DMA_HANDOFF_v32.md — BÀN GIAO PHIÊN (TEACHER V1 CỤM 3+4 — GHI NHẬN + REVIEW & GỬI NHẬT KÝ — TRỌN VÒNG TỚI PH — 2026-06-29 09:00 GMT+7)

> **Cách dùng:** File này = ảnh chụp trạng thái cuối phiên v32. Boot phiên sau:
> `00_START_HERE` → `RULES` → file này. Rồi audit DB/code thật trước khi viết (D1).
> **Naming:** DMA = nền tảng; CTAN = sản phẩm đầu. Không "DMMA".

---

## 1. LÀM GÌ PHIÊN NÀY

Tiếp BUILD Teacher Portal V1 từ v31: **đóng Cụm 3 (Ghi nhận: Điểm danh + Ghi nhận tap-first + Ảnh-gắn-bé) + Cụm 4 (Review & gửi nhật ký).** Đi đúng D1: audit DB sống TRƯỚC → engine 3-khối D92 → dịch Lovable → **nghiệm thu login thật TRỌN VÒNG tới PH** (GV gửi → gia đình thấy hành trình + kỹ năng + ảnh gated consent).

**(A) Mig 051 — nền Cụm 3 (3 thứ):**
- `UNIQUE(session_id, child_id)` trên `child_observations` (= `child_observations_session_child_key`) → cho upsert điểm danh/ghi nhận `onConflict`.
- Bảng **`skill_catalog`** (id · program_id nullable · code unique · label_vi · sort_order · enabled) + 2 RLS (select all-auth · write admin) + seed **4 kỹ năng CTAN** (Jean chọn): `ctan_rhythm` "Cảm nhịp" · `ctan_sing_along` "Hát theo" · `ctan_move` "Vận động theo nhạc" · `ctan_listen` "Lắng nghe".
- RPC `get_session_roster(p_session_id)` secdef gate **same-school ONLY** (KHÔNG admin — D48), trả `{ok, session:{class_id,program_id,lesson_version_id,class_name}, roster:[{child_id,full_name,attendance,has_obs,is_highlight,needs_support,follow_up_needed,skills_observed,note}]}`. (`children` name col = `full_name`.)

**(B) Mig 052 — nền Tab Ảnh:**
- RPC `get_session_moments(p_session_id)` secdef gate same-school, trả `moments[]{moment_id,state,caption,media:[{media_id}],tagged_child_ids}`.
- DELETE policy `moment_children_delete_school` (để GV bỏ gắn bé).

**(C) Mig 053 — `submit_session_journal` (engine Cụm 4 — TIM của phiên):**
- `submit_session_journal(p_session_id, p_summary default null, p_follow_up default null)` secdef gate **`is_session_lead`**.
- **Mô hình duyệt = GV-gửi-THẲNG-tới-PH** (D45 người-trong-phòng; Master ký báo cáo sau như QC, KHÔNG gác ảnh).
- Làm 6 việc idempotent: (1) duyệt moment (đã gắn bé + có media active) draft/pending/needs_revision→`approved` + approved_by; (2) tạo `child_journey` 'session' cho bé **present|late ONLY** (chống trùng `NOT EXISTS ref_id`); (3) upsert `child_skills` signal_count+1 dùng **`skill_catalog.label_vi`** (nhãn tiếng Việt đẹp cho PH, khỏi sửa `get_child_journal`); (4) upsert `session_reports` (summary/highlighted/to_observe/follow_up, state='submitted'); (5) `lesson_sessions` in_progress→`taught_report_pending`; (6) audit `session_journal_submitted` bọc EXCEPTION-NULL.
- Trạng thái đã-gửi (taught_report_pending/…) → **idempotent**: chỉ duyệt thêm ảnh MỚI GV bổ sung sau (gửi-lại an toàn).
- 3 khối D92, leaky=`[]`.

**(D) UI — `teacher.session.$id.tsx` full paste-over (Jean áp Lovable, route giữ tên `$id`):**
- **Bước 3 StepRecord** 3 tab con:
  - *Điểm danh:* 3 nút Có mặt/Muộn/Vắng, auto-save mỗi tap, optimistic (không reload roster), header đếm.
  - *Ghi nhận (tap-first, KHÔNG nút Lưu):* tap kỹ năng/cờ = lưu ngay optimistic; note onBlur; "Đã tự động lưu". **Bé Vắng ẨN khỏi danh sách** (chọn bé bị đánh Vắng → tự nhảy bé khác; cả lớp vắng → empty state).
  - *Ảnh gắn bé:* Thêm ảnh→validate JPG/PNG/WEBP ≤10MB→INSERT learning_moments(draft)→Edge `upload_media` (FormData `file`+`moment_id`)→signed URL preview→tap bé gắn/bỏ + caption onBlur. **Bé Vắng ẨN khỏi tag** (lỡ gắn rồi mới Vắng → chip đỏ "(vắng)" + "chạm để bỏ gắn").
- **Bước 4 StepReview:** tóm tắt điểm danh (present/late/absent) + bé nổi bật + cần theo dõi (đều bỏ qua bé vắng) + đếm ảnh sẵn-sàng-gửi (loại ảnh chỉ-gắn-bé-vắng & chưa-gắn-bé) + cảnh báo (ảnh chưa gắn bé / ảnh gắn bé vắng) + 2 ô ghi chú nội bộ (summary/follow_up — KHÔNG gửi PH) + nút **"Hoàn tất & gửi nhật ký"**→`submit_session_journal`. Đã gửi → banner + "Gửi lại nhật ký". Gửi xong → màn **"Đã gửi nhật ký tới gia đình 🎉"** + số bé vào nhật ký + số ảnh tới PH + "Về Hôm nay".

> **D102/D103/D104 MỚI (RULES, chuỗi chính):** xem RULES. D102 = nền Cụm 3 (UNIQUE + skill_catalog + roster RPC + bé-Vắng-ẩn). D103 = `submit_session_journal` GV-gửi-thẳng + journey/skills present|late. D104 = consent ảnh nhóm `group_moment_in_class` vs solo `display_in_app` + **quyết product: ảnh nhóm mặc-định-BẬT (opt-out)**.

---

## 2. ⭐ NGHIỆM THU LOGIN THẬT — TRỌN VÒNG TỚI PH (ĐẠT — phép thử LINH HỒN)

**Phía GV** (Mỹ Linh `gv.linh.kidshouse@demo.demenart.com`/`Test@123`, buổi a0001 lớp Hoa Hồng):
- Tab Điểm danh: Bình=Có mặt, Chi+An=Muộn, Dung=Vắng → child_observations upsert 200/201.
- Tab Ghi nhận: tap "Hát theo"/"Cảm nhịp"/"Lắng nghe" + cờ → lưu ngay; bé Vắng (Dung) ẩn đúng.
- Tab Ảnh: 2 ảnh thật upload zone `dma-private`, gắn bé, preview qua signed URL.
- Bước 4: "1 ảnh sẵn sàng" → "Hoàn tất & gửi" → màn 🎉 "3 bé có buổi học này trong nhật ký · 1 ảnh đã tới ba mẹ". `submit_session_journal` 200. State a0001→`taught_report_pending` (Home thành "0 tiết hôm nay").

**Phía PH** (Hùng `ph.hung.kidshouse@demo.demenart.com`/`Test@123`, bé An):
- `/parent/journal` → An → **Hành trình** có "28 tháng 6 · [v29-test] Buổi READY · CTAN" ✓ · **Kỹ năng "Hát theo"** tăng ✓.
- Ban đầu 2 ảnh nhóm hiện "Đang chờ ba mẹ đồng ý" — **đúng MIN consent**: ảnh ≥2 bé cần `group_moment_in_class` từ MỌI bé; An/Chi mới có `display_in_app`. Sau cấp consent demo (`source='demo_seed'`) cho An+Chi → **2 ảnh nhóm hiện thật** ✓.

→ **Teacher V1 + consent engine KHÉP TRỌN VÒNG**: GV ghi nhận → gửi → gia đình thấy nhật ký con, ảnh chỉ lên khi mọi bé trong ảnh đồng ý.

---

## 3. TRẠNG THÁI THẬT CUỐI PHIÊN

- **DB cấu trúc (CÓ ĐỔI phiên này):** **48 bảng** (+`skill_catalog`) · **59 hàm SECURITY DEFINER** (+3: `get_session_roster`·`get_session_moments`·`submit_session_journal`) · **132 RLS policy** (+3: 2 skill_catalog select/write + 1 moment_children DELETE) · **+1 constraint** (`child_observations` UNIQUE session_id,child_id) · **mig 001→053** · seed 001→012. SYSTEM_MAP **v0.29** (bump).
- **Edge Functions (6 — KHÔNG đổi):** `get_signed_media_url` · `upload_media` · `resolve_share_link` · `invite_master` · `invite_staff` · `invite_parent`.
- **Routes app:** 5 cổng `/parent`(amber)·`/teacher`(ngà/xanh-rừng/mật-ong)·`/school`(emerald)·`/admin`(slate) + `/portal` shell hạ-tầng + `/kid` reserved V2. `/share/$token` public. **Teacher V1 luồng 4 bước HOÀN CHỈNH** trong `teacher.session.$id.tsx` (Bước 1→4 đều thật).
- **3 tenant / 3 master** (DEMO-001 · KHM-DN · MNDM-DN).

> **Data state phiên này:** (1) buổi a0001 = `taught_report_pending` (đã gửi nhật ký). (2) `consents` demo_seed MỚI: An (…41) + Lê Bảo Chi (…43) có `group_moment_in_class` granted `source='demo_seed'` (seed nội bộ để demo ảnh nhóm — KHÔNG phải PH tự cấp). (3) `child_journey` + `child_skills` của An/Bình/Chi đã có entry từ submit thật (giữ).

---

## 4. FILE PHIÊN NÀY

**Migration (Jean lưu repo từ live — dump trung thực D90):**
- `051_record_foundation.sql` — UNIQUE child_observations + table skill_catalog (+2 RLS +seed 4) + RPC `get_session_roster` (3 khối).
- `052_session_moments.sql` — RPC `get_session_moments` + DELETE policy moment_children (3 khối).
- `053_submit_session_journal.sql` — RPC `submit_session_journal` (3 khối).

**UI (Jean áp Lovable tay, full paste-over):**
- `src/routes/_authenticated/teacher.session.$id.tsx` (Bước 3 StepRecord 3 tab + Bước 4 StepReview thật; bé-Vắng-ẩn ở ghi nhận & tag).

---

## 5. VIỆC TREO (ghi rõ để pilot không bất ngờ)

**🟢 Product lớn (đã chốt hướng — làm phiên sau):**
- **D104 thực thi A+C — ảnh nhóm consent mặc-định-BẬT (opt-out):** (A) PH onboard tự có `group_moment_in_class` granted `source='onboarding_default'` → sửa Edge `invite_parent` + seed consent mặc định; (C) ở journal PH, ảnh "đang chờ" có nút "Vì sao?" → giải thích + (nếu con mình chặn) link `/parent/consent` cấp quyền. Blur mặt bé-chưa-đồng-ý = **V2**. *(Lý do: ảnh lớp hầu hết ≥2 bé; 1 PH chưa cấp chặn cả ảnh → nhiều PH khác không thấy con. Mặc-định-BẬT giải ~80% nghẽn, PH vẫn cầm quyền tắt — đúng linh hồn.)*

**🟡 UX/đường-vào (phiên polish):**
- Nút **"Sửa ảnh & ghi nhận" ở Bước 4** → về Bước 3 Tab Ảnh (hiện phải bấm stepper "3" — khó thấy; cô Linh hỏi 2 lần).
- **`/teacher/moments`** (trang cũ) chưa ký signed URL → không preview (ảnh vẫn nguyên; Tab Ảnh trong buổi hiện đúng). Thêm preview giống Tab 3 HOẶC gộp vào luồng buổi.
- Tab Ảnh **reload toàn bộ moments sau mỗi tag** (re-sign nhiều request) — tối ưu sau.
- 2 PH **email-null** (Lê Thị Hạnh / Phạm Văn Đức) — hồ sơ có, chưa gắn auth → tạo login nếu muốn test đủ lớp.

**🟡 Nợ cũ (mang theo):**
- Dọn seed `[v29-test]` (3 buổi lớp Hoa Hồng) + consent `demo_seed` (An/Chi) khi xong demo.
- Land GV `/teacher/curriculum`→`/teacher`.
- Lưu repo: `045` (nợ v28) + `051/052/053` + 2 Edge `invite_staff.ts`/`invite_parent.ts` (nợ v22).
- Dead-link nhẹ "← Quay lại" `admin.modules.tsx` `to="/portal"`→`/admin`.
- Reaction "Lời cảm ơn" (parent_replies hook = 0).
- GV/PH pilot còn lại chưa login (4 GV + nhiều PH) · 2 file nhạc curriculum chưa nguồn lưu · Vercel dormant · lock 1 linh vật.

---

## 6. KẾ HOẠCH PHIÊN SAU

Boot sạch → audit D1 → **chọn 1 trong 2 hướng:**
- **(I) Thực thi D104 (A+C)** — consent ảnh nhóm mặc-định-BẬT: sửa Edge `invite_parent` cấp `group_moment_in_class` mặc định + UI journal PH nút "Vì sao?"→`/parent/consent`. (Việc product giá-trị-cao, đỡ nghẽn ảnh nhóm cho pilot.)
- **(II) Pass NỘI THẤT V1 (D98 design)** — áp design direction 5 cổng: accent nội-thân + mobile nav + cửa `/kid` khoá "Sắp ra mắt" + nút "Sửa ảnh & ghi nhận" Bước 4 + lock 1 linh vật.

Em đề xuất **(I) trước** (đóng nghẽn vận hành ảnh nhóm trước pilot), rồi **(II)**. Đóng = HANDOFF v33.

---

*Teacher Portal V1 FUNCTIONALLY COMPLETE — luồng 4 bước trọn (Chuẩn bị→Player→Ghi nhận→Review&gửi) + engine submit + consent gated, nghiệm thu trọn vòng GV→PH. Nguồn: Tài liệu A–G UPDATED + tầm nhìn founder + DMWS v170.*
