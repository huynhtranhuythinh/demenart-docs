# 🧾 DMA_HANDOFF_v52.md — TÍN HIỆU TV + SFX · PREV/NEXT AUX · ĐÓNG NỢ REPO 071–078 · JOURNAL SPRINT J1+J2+J3 TRỌN VÒNG — 2026-07-05 16:24 GMT+7

> **Boot phiên sau:** đọc `DMA_00_START_HERE.md` → `DMA_RULES.md` → file này. Audit live trước khi viết code/SQL (D1).
> **Phiên này = 4 mạch liên tiếp, TẤT CẢ đã publish production + nghiệm thu login thật:** (A) Tín hiệu TV + SFX synth · (B) prev/next aux · (E) backup repo 071–078 · (D) Journal sprint J1+J2+J3 (mig 079–080).

---

## 0. TL;DR

- **Tín hiệu TV (D161):** Remote bắn 4 cue quản lớp lên Màn chiếu (👀 Nhìn lên cô · 👏 Vỗ tay nào · 🤫 Trật tự nhé · 🔔 Lắng nghe cô) — overlay 5s + **âm synth Web Audio** (không file, không đụng đường phát). Config nội dung/sound per-school = sprint sau.
- **prev/next aux:** ◀▶ trong AuxPalette Remote, bước tuần tự học liệu bổ sung, clamp biên, chip auto-scroll.
- **Nợ repo D90 ĐÓNG:** đối chiếu D112 bắt được 060–070 đã dump từ v43–v45 → chỉ còn 071–078; giao 4 file dump-từ-live. ⏳ 4 Edge Jean copy tay (§5).
- **Journal sprint TRỌN VÒNG cô dạy → ghi nhận → gia đình thấy con:** J1 sổ nhật ký `/teacher/journal` · J2 checkbox "Chia sẻ nhận xét với ba mẹ" → PH thấy khung "Cô nhận xét" · J3 nút "Ghi nhận" trên Remote → mốc lưu DB hiện lại ở form ghi nhận.

---

## 1. Trạng thái DB (audit live cuối phiên — D1/D90)

- **54 bảng (+`session_marks`) · 78 SECURITY DEFINER (+`get_teacher_journals`) · migrations 001→080 · admin_modules 60 · 9 Edge (KHÔNG đổi) · 3 tenants.**
- Mig 079 + 080 apply qua **MCP `apply_migration`** → có vết trong `supabase_migrations.schema_migrations` (khỏi nợ D90 tương lai).

### Migration 079 (3 khối D92, verify pass: grants sạch, leaky=[])
1. **`get_teacher_journals()`** MỚI — buổi của cô (`cd.lead_teacher_id = me` ∪ `session_teachers`), cửa sổ **−60/+7 ngày GIỜ HCM** (chống bẫy UTC); trả `items[]{session_id,title,scheduled_at,state,class_name,program_name,journal_status,obs_count,has_report}`; `journal_status`: in_progress→cần ghi · taught_report_pending/report_pending_approval→submitted · completed · cancelled/rescheduled→skipped · còn lại→not_started. Grant authenticated+service_role.
2. **`get_child_journal` REPLACE THÊM-ONLY** — journey entry +`teacher_note`, CHỈ KHI `child_observations.visibility='parent_visible'` (join live theo ref_id+child_id+entry_type='session'). **D163:** tick là PH thấy NGAY nếu journey entry đã tồn tại; buổi mới cần gửi nhật ký để entry sinh.
3. **Bảng `session_marks`** — id · session_id FK cascade · part_key · part_title · note · marked_at · created_by FK profiles; RLS: insert/delete GV-của-buổi (`is_session_lead OR is_session_teacher`), select same_school; index (session_id, marked_at).

### Migration 080 — Registry D106
+`teacher-journal` (route `/teacher/journal`, group lesson-session, cạnh 2 chiều `lesson-session↔teacher-journal`, keyword có dấu+không dấu). admin_modules 59→60.

---

## 2. Mạch A — Tín hiệu TV + SFX (D161)

- **Kênh:** `ClassroomState` +`signal:{cue,nonce}|null` (additive-default — client cũ không vỡ).
- **Remote:** nút "Tín hiệu TV" (hết sắp-có) toggle strip 4 cue 2×2; bấm hiện "Đã gửi lên TV ✓" 1.5s.
- **Màn chiếu:** overlay emoji 130px + chữ, `pointer-events-none`, tự ẩn `CUE_MS=5s`, `key={nonce}` (bấm cue khác thay ngay). **Thứ tự lớp CHỐT: blackout z-10 < cue z-20 < lock z-30 < needTap z-40** — cue hiện được cả khi che màn.
- **SFX:** `playCueSfx(ctx,cue)` — Web Audio oscillator + gain envelope, master 0.22, mỗi cue một giai điệu (look C5→G5 · clap tách-tách square · quiet G4→E4 dịu · listen ding E6+hài âm). `sfxCtxRef` riêng, resume nếu suspended, gate `ready`. KHÔNG file, KHÔNG đụng element phát media, chạy song song nhạc nền.

## 3. Mạch B — prev/next aux (Remote)

`gotoAux(delta)` clamp (không wrap); ◀▶ trong header AuxPalette cạnh "Về bài dạy" (nút này bỏ icon ChevronLeft vì ◀ đứng cạnh); `auxChipRefs` map + effect `scrollIntoView({inline:"center"})` khi `state.auxMediaId` đổi; đổi aux vẫn `command:"stop"` (một-slot). Chưa chiếu chèn → ▶ vào aux đầu tiên.

## 4. Mạch D — Journal sprint J1+J2+J3

- **J1 — route MỚI `_authenticated/teacher.journal.tsx`** (`/teacher/journal`): header + 3 nhóm **Cần ghi nhận** (in_progress, viền honey, CTA "Ghi nhận ngay") / **Sắp tới** (not_started tương lai, muted) / **Đã gửi & lịch sử** (badge theo status, not_started quá khứ = "Chưa ghi" honey). Card = Link `/teacher/session/$id`. Nav `teacher.tsx`: "Nhật ký" vào nhóm Lớp học, **gỡ khỏi LOCKED** (Hồ sơ vẫn khoá).
- **J2 — chia sẻ nhận xét:** StepRecord load `visMap` (child_observations.visibility) + ObserveTab +checkbox "Chia sẻ nhận xét này với ba mẹ" → upsert `visibility` qua `saveObs` sẵn có (KHÔNG sửa RPC roster). `parent.journal.tsx`: journey entry render khung amber **"Cô nhận xét: '…'"** khi `teacher_note`.
- **J3 — mốc Ghi nhận (D162 — Remote công khai KHÔNG ghi DB):** Remote nút "Ghi nhận" (hết sắp-có) → broadcast `mark:{partKey,partTitle,nonce}` → **Monitor (GV đăng nhập) INSERT `session_marks` qua RLS** + toast pill đáy màn (pointer-events-none) "✓ Đã lưu mốc ghi nhận · HH:MM" → StepRecord dải honey "Mốc cô đánh dấu trong buổi" (chips "Phần · giờ"). Bề mặt anon giữ tối thiểu (chỉ `redeem`).

**Nghiệm thu login thật ĐẠT (5 ảnh):** GV Mỹ Linh — sổ nhật ký 3 nhóm đúng · cue 👀👏🤫🔔 + tiếng · 5 mốc "Nền mở đầu · 16:18" lên StepRecord · điểm danh + tick chia sẻ note bé An. PH Hùng — khung "Cô nhận xét" trong journey bé An + kỹ năng "Hát theo" cộng dồn.

## 5. Mạch E — Đóng nợ repo 071–078 (D90/D112)

**Đối chiếu D112:** nợ ghi "060–078" nhưng 060–066 (v43) · 067 (v44) · 068–070 (v45) ĐÃ dump → gói này chỉ 071–078.

**4 file đã giao (Jean lưu `supabase/migrations/`, KHÔNG chạy vào DB):**
| File | Bao |
|---|---|
| `071_072_session_remote_code.sql` | 3 cột remote_* + partial unique scoped-buổi-sống + mint (final 4-số) + redeem; redeem grant **anon CỐ Ý** (D131); 072 KHỚP verbatim `schema_migrations` version `20260702064148` |
| `073_078_org_cloud.sql` | session_media sort_order/kind/CHECK/DELETE-policy + 4 hàm Org Cloud (storage usage · check upload access · media library · get_lesson_guide final `_intro`+`aux`) |
| `registry_addendum_v46_v51.sql` | 4 row admin_modules verbatim (school-drive MỚI + 3 update), ON CONFLICT(id), chạy SAU seed_013 |
| `MANIFEST_071_078.md` | thứ tự phục hồi + phương pháp dump |

**⏳ VIỆC TAY JEAN:** copy 4 Edge từ Supabase Dashboard vào repo (pattern v37): `upload_media` (v11) · `get_signed_media_url` (v18) · `delete_session_media` · `school_media_admin`.

---

## 6. File đã đụng phiên này

**DB:** mig 079 + 080 (qua `apply_migration`, có vết).
**UI (auto-áp agent, get_diff sạch từng lượt, đã publish):** `useSessionChannel.ts` (+signal +mark) · `remote.tsx` (strip cue · nút Ghi nhận · ◀▶ aux) · `teacher.classroom.tsx` (cue overlay+SFX · mark insert+toast) · `teacher.session.$id.tsx` (dải mốc + checkbox chia sẻ + visMap/marks) · `parent.journal.tsx` (khung Cô nhận xét) · `teacher.journal.tsx` (**MỚI**) · `teacher.tsx` (nav mở khoá Nhật ký).
**Repo:** 4 file backup §5. **Credits Lovable phiên này ~17.3.**

---

## 7. ⭐ Tài khoản test (luôn kèm khi nhờ Jean test — password `Test@123`, domain `@demo.demenart.com`)

GV Mỹ Linh `gv.linh.kidshouse` · Master KHM `hieutruong.kidshouse` (Nguyệt Thi) · PH Hùng `ph.hung.kidshouse` · Master MNDM `hieutruong.demen` (Phương Dung) · GV Hân `gv.han.demen` · PH Thành `ph.thanh.demen` · GV My `gv.my.kidshouse` (password tạm) · PH Toản `ph.toan.kidshouse` (password tạm) · Super admin `info@demenart.com` (password của Jean). Buổi demo: `aaaa0000-0000-4000-8000-0000000a0001` (lớp Hoa Hồng, "Tiếng mưa rơi").

---

## 8. VIỆC TREO

- 🟢 **Nút Chụp / Quay trên Remote** (2 sắp-có cuối) — chụp/quay khoảnh khắc từ điện thoại; cần thiết kế đường upload từ Remote công khai (theo D162: Remote không ghi DB → cần mint quyền hoặc chuyển qua Monitor).
- 🟡 **Config Tín hiệu TV per-school** — đổi nội dung chữ + sound 4 cue (Jean chốt hoãn, làm chung sprint config).
- 🟡 **Upload "Chú Vịt Con" chuẩn** — Phần 4 buổi demo đang placeholder; cần file nhạc từ Jean.
- 🟡 **4 Edge backup tay** (§5) — việc tay Jean.
- 🟡 **Dọn rác kho Bunny** — nút "Dọn rác kho" trong `/school/drive` (15 file mồ côi, Jean bấm).
- 🟡 **Backfill 51 module registry trống description** (chỉ backfill module LIVE).
- 🔴 **"Try to fix all" 11 issues Lovable — CHƯA ĐỘNG, ĐỪNG BẤM** (D5/D14).
- `/kid` V2 (cửa khoá placeholder) · nợ cũ v51 mang theo.

## 9. NGÃ KẾ (chọn đầu phiên sau)

1. **Chụp/Quay trên Remote** — đóng nốt 2 nút sắp-có, khép trọn Remote thành công cụ đứng lớp hoàn chỉnh.
2. **Config sprint** — TV cue text/sound per-school + backfill registry desc.
3. **`/kid` V2** — cổng trẻ PIN-based, parent approval flow (sprint lớn).

## 10. Kỷ luật giữ nguyên (nhắc nhanh)

D1 audit live trước mọi SQL · D92 3-khối · D15 re-grant sau CREATE OR REPLACE · D95 file trọn không patch · D90/D112 dump-từ-live + đối chiếu trước khi trả nợ · D106 route mới vào registry NGAY · D134 auto-áp + get_diff từng lượt · **D161 thứ tự z-layer Màn chiếu** · **D162 Remote công khai chỉ broadcast, Monitor ghi DB** · **D163 teacher_note gate parent_visible — cô quyết, không rò** · KHÔNG auto-publish đường phát, để Jean test Preview.

*Handoff v52 — 2026-07-05 16:24 GMT+7. Nguồn: Tài liệu A–G + tầm nhìn founder + DMWS. Cập nhật "tới đâu ghi tới đó" (KỶ LUẬT VÀNG).*
