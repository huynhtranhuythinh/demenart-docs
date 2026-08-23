# 🧾 DMA_HANDOFF_v53.md — CHỤP/QUAY TỨC THÌ TRÊN REMOTE (định nghĩa lại → aux + chiếu ngay) · CONFIG SPRINT (school_settings + TV cue per-school + backfill registry) — 2026-07-05 18:26 GMT+7

> **Boot phiên sau:** đọc `DMA_00_START_HERE.md` → `DMA_RULES.md` → file này. Audit live trước khi viết code/SQL (D1).
> **Phiên này = 2 mạch, TẤT CẢ đã publish production + nghiệm thu thật (ảnh + video iPhone):** (1) Chụp/Quay trên Remote — làm 2 vòng vì Jean định nghĩa lại giữa phiên; (2) Config sprint: bảng `school_settings`, TV cue per-school, backfill 33 description registry.

---

## 0. TL;DR

- **Chụp/Quay (D164/D165/D166):** 2 nút cuối trên Remote hết "sắp có". Định nghĩa CHỐT: **tư liệu tức thì** — cô chụp tác phẩm / quay bé diễn → file đổ vào **Học liệu bổ sung** (`session_media` kind=`supplement`) và **chiếu NGAY lên Màn chiếu**; KHÔNG UI mới, KHÔNG tool mới (quota Org Drive, xoá qua 🗑 SessionResourcePanel, phát qua đường signed URL sẵn). Ảnh nhật ký/kỷ niệm = cô dùng camera máy như thói quen, KHÔNG qua nút này.
- **Config sprint (D167):** bảng MỚI `school_settings` (per-school key-value, thép chờ); cue TV đổi chữ/emoji/giai điệu tại `/school/settings`; Monitor đẩy `cueConfig` xuyên kênh; Remote/TV fallback mặc định. Backfill **33→0** module LIVE thiếu description.
- **Nghiệm thu thật (Jean, 7 ảnh):** ảnh + video .mov iPhone chiếu ngay lên TV · chip mọc trên Remote **và** laptop (fix D166) · quota cộng đúng (19.91/5000 MB, thấy trong /school/drive) · cue custom "Nhìn lên nè!" + giai điệu đổi chạy trên TV · trang Cài đặt lưu/khôi phục OK.

---

## 1. Trạng thái DB (audit live cuối phiên — D1/D90)

- **55 bảng (+`school_settings`) · 79 SECURITY DEFINER (+`check_remote_capture_access`) · migrations 001→085 · admin_modules 61 · Edge 11 (10 dùng + 1 stub deprecated) · 3 tenants.**
- Mig 081–085 apply qua **MCP `apply_migration`** → có vết `supabase_migrations.schema_migrations` (khỏi nợ D90).

| Mig | Nội dung |
|---|---|
| 081 | RPC `check_remote_capture_access(p_code)` — gate bằng code 4 số (SUPERSEDED ngay trong phiên) |
| 082 | DROP+CREATE gate bằng **`p_key` = remote_channel_key** (đường QR không có code — D164; đổi tên param bắt buộc DROP) |
| 083 | Bảng **`school_settings`** + RLS 4 policy (select same_school / write is_school_admin, D167) |
| 084 | Registry: +`school-settings` (61 module, cạnh 2 chiều teacher-remote) + **backfill 33 description** module LIVE → 0 thiếu |
| 085 | Gate v2: bỏ trần 60 khoảnh khắc (quota Org Drive thay thế — capture giờ đổ session_media) |

Grants verify sạch mọi vòng: `check_remote_capture_access` = `{postgres, service_role}`, leaky=[].

## 2. Edge Functions (11)

- **`capture_session_media` v1 (MỚI — Edge thứ 10 đang dùng):** gate channel_key → **quota check verbatim nhánh C** (trước khi đụng Bunny) → Bunny `dma-private /school/{school}/` → `media_assets` (private_school_resource, uploaded_by/created_by = **cô chính** của buổi, D88) + `session_media` kind=supplement sort kế → audit `remote_capture` → trả `media_id`. Title tự đặt **"Chụp/Quay tại lớp HH:MM"** (giờ HCM). Trần: ảnh 10MB / video 100MB.
- **`capture_session_moment` v3 = STUB 410 deprecated** — bản đầu (v1–v2, đổ learning_moments draft) bị Jean định nghĩa lại; không xoá được Edge qua MCP → stub giết bề mặt anon cũ. 0 khoảnh khắc rác (chưa ai bấm trước khi đổi).
- 9 Edge cũ KHÔNG đổi.
- ⏳ **Việc tay Jean:** copy `capture_session_media` vào repo (pattern v37), cộng vào 4 Edge nợ từ v52 (`upload_media` v11 · `get_signed_media_url` v18 · `delete_session_media` · `school_media_admin`).

## 3. Mạch 1 — Chụp/Quay (2 vòng)

**Vòng 1 (SAI HƯỚNG, đã gỡ):** đổ vào `learning_moments` draft + trần 60/buổi — em tự suy "khoảnh khắc kỷ niệm". **Jean định nghĩa lại (D165):** use-case thật là tư liệu tức thì trong tiết; ảnh kỷ niệm cô chụp bằng camera máy rồi chọn lúc ghi nhận.

**Vòng 2 (CHỐT):**
- Remote `uploadCapture`: input `capture="environment"` (ảnh/video) → **check video ≤2 PHÚT bằng metadata client** (`onloadedmetadata`, không đọc được thì cho qua — server vẫn chặn size) → FormData {file, channel_key} → Edge → thành công: `publishState({guideRev: Date.now(), auxMediaId: media_id, command:"stop"})` → **Màn chiếu chiếu ngay**; thông điệp "✓ Đang chiếu lên TV — file nằm trong Học liệu bổ sung"; lỗi có chữ tử tế (quota_exceeded / file_too_large / invalid_or_ended…).
- **Fix D166:** StepTeach +effect lắng `state.guideRev` → `reloadGuide(false)` (KHÔNG publish lại — chống echo); `SessionResourcePanel` +prop `refreshKey={state.guideRev}` → điện thoại chụp xong, laptop mọc chip + panel thấy file để xoá, không cần F5.
- **Quota:** cộng/trừ tự nhiên (private_school_resource + state active). Verify thật: 3 file capture 3.26+0.83+0.44MB → kho KHM 15.83MB (sau đó Jean chụp thêm → 19.91MB khớp UI).
- **.mov iPhone:** nghiệm thu phát ngon trên Chrome của Jean; nếu môi trường khác chết HEVC → iPhone Formats→Most Compatible (họ D137/D157).

## 4. Mạch 2 — Config sprint

- **`/school/settings` (route MỚI, nav "Cài đặt" nhóm Quản lý trường):** 4 hàng cue — ô emoji · ô chữ (maxLength 30) · select 1/4 giai điệu synth · 🔊 Nghe thử (Web Audio tại chỗ, master 0.22, 4 giai điệu y hệt Màn chiếu) · preview chip nền tối "xem trên TV" · Lưu (upsert `tv_cues`) · Khôi phục mặc định (DELETE row → về null). Non-master lưu → RLS chặn → "Chỉ Chủ trường (Master) mới lưu được."
- **Engine:** `useSessionChannel` +`cueConfig` (additive-default null); Monitor nạp `school_settings` (RLS tự scope trường) → validate chặt (đủ 4 cue, sfx hợp lệ) → publish + đẩy lại trong nhịp republish guide (Remote vào trễ vẫn nhận); Remote strip + TV overlay + SFX đều `cueConfig ?? mặc định` — trường chưa chỉnh / client cũ chạy y nguyên.
- **Registry hygiene:** backfill 33 description (chỉ module LIVE, usage_note/keywords vốn đủ 100%) → **0 thiếu**; +module `school-settings` đủ 4 trường D106, cạnh đối xứng teacher-remote.

## 5. File đã đụng phiên này

**DB:** mig 081–085 (qua `apply_migration`). **Edge:** `capture_session_media` v1 MỚI · `capture_session_moment` v3 stub.
**UI (auto-áp agent, get_diff sạch từng lượt, đã publish):** `remote.tsx` (Chụp/Quay + trần 2' + cueList) · `teacher.classroom.tsx` (cueConfig nạp/validate/publish + overlay/SFX theo config) · `teacher.session.$id.tsx` (+effect guideRev — D166) · `SessionResourcePanel.tsx` (+refreshKey) · `useSessionChannel.ts` (+cueConfig) · `school.settings.tsx` (**MỚI**) · `school.tsx` (nav Cài đặt).
**Credits Lovable phiên này ~14.7.**

**Ghi chú tooling:** thử claude-in-chrome tự e2e-test Remote — screenshot/navigate/type chạy, nhưng find/read_page treo (timeout 4' ×2) → nghiệm thu tay của Jean vẫn là đường tin cậy.

## 6. ⭐ Tài khoản test (luôn kèm khi nhờ Jean test — password `Test@123`, domain `@demo.demenart.com`)

GV Mỹ Linh `gv.linh.kidshouse` · Master KHM `hieutruong.kidshouse` (Nguyệt Thi) · PH Hùng `ph.hung.kidshouse` · Master MNDM `hieutruong.demen` (Phương Dung) · GV Hân `gv.han.demen` · PH Thành `ph.thanh.demen` · GV My `gv.my.kidshouse` (password tạm) · PH Toản `ph.toan.kidshouse` (password tạm) · Super admin `info@demenart.com` (password của Jean). Buổi demo: `aaaa0000-0000-4000-8000-0000000a0001` (lớp Hoa Hồng, "Tiếng mưa rơi") — PIN đổi theo buổi, xem trên trang Tiết học.

## 7. VIỆC TREO

- 🟢 **SPRINT TỔ CHỨC MEDIA (Jean chốt làm phiên sau):** (a) trang **"Học liệu của tôi"** ở `/teacher` — GV xem các học liệu bổ sung do MÌNH tải (mọi buổi); Trường thấy tất qua Kho của trường là đúng scoped-model, nhưng GV cần view riêng; (b) **fix tile VIDEO trong `/school/drive`** — đang render như ảnh → vỡ (cần poster/frame hoặc `<video preload="metadata">` như SessionResourcePanel).
- 🟡 **Copy Edge vào repo (tay Jean):** 4 file v52 + `capture_session_media`.
- 🟡 **Upload "Chú Vịt Con" chuẩn** — Phần 4 buổi demo vẫn placeholder; chờ file từ Jean.
- 🟡 **Dọn rác kho Bunny** — nút trong `/school/drive` (Jean bấm).
- 🔴 **"Try to fix all" 11 issues Lovable — CHƯA ĐỘNG, ĐỪNG BẤM** (D5/D14).
- `/kid` V2 (cửa khoá placeholder) · Config cue nâng cao (per-school đã xong; nếu muốn thêm giai điệu mới = lát riêng).

## 8. NGÃ KẾ (chọn đầu phiên sau)

1. **Sprint tổ chức Media** — "Học liệu của tôi" cho GV + fix tile video /school/drive (Jean đã đặt hàng). ← tự nhiên nhất
2. **`/kid` V2** — cổng trẻ PIN-based, parent approval flow (sprint lớn).
3. **Chú Vịt Con + polish nhỏ** — nếu Jean có file nhạc.

## 9. Kỷ luật giữ nguyên (nhắc nhanh)

D1 audit live · D92 3-khối · D15 re-grant · D95 file trọn · D90/D112 dump-từ-live · D106 registry ngay · D134 auto-áp + get_diff từng lượt · D161 z-layer Màn chiếu · D162 Remote chỉ broadcast (ngoại lệ upload = mint quyền D164) · D163 teacher_note gate · **D164 gate channel_key, RPC chỉ service_role, bề mặt cũ stub 410** · **D165 Chụp/Quay = tư liệu tức thì → aux, không UI mới** · **D166 guideRev lắng cả hai đầu, refetch không publish lại** · **D167 school_settings pattern per-school config** · KHÔNG auto-publish đường phát, để Jean test Preview.

*Handoff v53 — 2026-07-05 18:26 GMT+7. Nguồn: Tài liệu A–G + tầm nhìn founder + DMWS. Cập nhật "tới đâu ghi tới đó" (KỶ LUẬT VÀNG).*
