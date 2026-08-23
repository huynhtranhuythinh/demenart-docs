# 🤝 DMA_HANDOFF — V116 · TEACHER SESSION EXPERIENCE · S0–S3 (26/07/2026)

> **Endpoint canonical:** RULES **D328** · SYSTEM_MAP **v1.19** · HANDOFF **V116-SESSION-S0-S3** (file này).
> Absorb: các closeout S0/S1/S2/S3 trong hội thoại 26/07. Handoff trước: `DMA_HANDOFF_V114B_E3_MILESTONE_CLOSEOUT.md`.
> **Boot phiên sau:** đọc file này → START_HERE → RULES (D1→D328, chú ý D324–D328) → audit live DB → re-pin `list_edits limit=1`.

---

## 1 · TRACK LÀ GÌ

Rebuild trải nghiệm **buổi dạy của GV** theo 4 bước — **Chuẩn bị · Trong giờ học · Ghi nhận · Hoàn tất** — visual "Playful Preschool Companion" đồng bộ Teacher Home V1 (A115). ChatGPT = CTO/Release Authority ra spec S1/S2 (document); S3 chạy theo audit §12 + Owner "tiếp tục làm nào!". Toàn track: **frontend-only, zero backend/migration/RPC/RLS/Edge/data change**.

## 2 · CHUỖI COMMIT (main → Cloudflare CI → demenart.com, tất cả XANH + Owner QA PASS)

| Slice | Commit | Nội dung |
|---|---|---|
| baseline | `96e9d9e4` | Teacher Home V1 FINAL (A115; lineage `d6f3fb54`→`7afdbf2d`→`d36b57ce` pin resolvers **5.2.2**→`dd3a49b6`→`96e9d9e4`) |
| **S0** | `18db884c` | `package-lock.json` (lockfileVersion 3, 518 pkg) — CI npm deterministic. **D326: đổi dependency = cập nhật CẢ 2 lockfile** |
| **S1** | `d6a9cfff` | Shell/tokens: xoá D98 cục bộ → `T.*`/`cardStyle`/`focusRing`/`fmtTimeVN`; SessionTopBar (BackLink+Thông báo+Trợ giúp); h1 24/29px; stepper nhãn mới + subcopy + aria; skeleton loading; error card ấm + "Về Hôm nay"; `teacher.tsx` +1 dòng pageContext "Buổi học"; tokens +`honeyText`/`peachText`/`info` |
| **S2** | `e3434bb4` | **Chuẩn bị**: MỚI `features/teacher/sessionPrep.tsx` (SessionInfoCard · ResponsibleTeacherCard · ReadinessSummary · LessonPreview read-only seq+alive riêng); checklist checkbox native 44px + lỗi lưu; CTA "Bắt đầu buổi học"/"Tiếp tục buổi học" sticky ≤479 (bottom-72px); **START-FAIL P1 ĐÓNG** (forbidden→"Cô không phải giáo viên phụ trách buổi học này." không Thử lại; generic→copy + Thử lại); report-missing retry |
| **S3** | `41d6732e` | **Trong giờ học**: MỚI `features/teacher/sessionPlayer.tsx` (SessionMediaPlayer — Edge `get_signed_media_url`, seq+alive, KHÔNG autoplay, ảnh/audio/video native `nodownload`, empty/loading/error+Thử lại); **GỠ SẠCH** useSessionChannel/publishState/PocketMirror/StatusPill/blackout/eq/wm-drift/PROJECTION_AVAILABLE; `openPart/openMaterial/openAux/backToLesson` thuần local `auxMediaId`; notice mới "Chiếu lên TV lớp đang tạm ngưng… Cô mở học liệu ngay trên thiết bị này…"; chip "chạm để mở/ĐANG MỞ/Mở xen"; quick bar sticky ≤479; `SessionResourcePanel.tsx` token swap + "Mở xen" (mutations byte-nguyên). **P1 "GV không phát được học liệu" ĐÓNG** |

**KHÔNG đụng:** `classroom`/`remote` routes · `useSessionChannel.ts` (chờ V114-SEC1) · mọi backend.

## 3 · AUTHORITY (D324/D325) — GIỮ NGUYÊN TUYỆT ĐỐI

Mọi slice chứng minh semantic diff = 0 trên: `loadDetail`+3 ref (contract 3 nhánh) · `start()`+locks (S2 CHỈ thêm presentation trong nhánh lỗi — mẫu chuẩn D327) · `submit()`+locks+`recovering` · `stepForState`/`SENT_STATES`/`blockReasonCopy` (byte-identical, vẫn "Bạn không phải…" — ứng viên đổi "cô" thuộc S4 = re-QA bắt buộc) · BackLink · mọi mutation handler. Freeze-proof: grep RỖNG (S1/S2 verbatim; S3 bounded-range + dead-symbol grep — deviation ghi nhận trong closeout S3).

## 4 · OWNER RUNTIME QA ĐÃ PASS (bằng chứng screenshot trong hội thoại 26/07)

Mobile + desktop · GV Mỹ Linh + Master Nguyệt Thi (KHM) + Master Phương Dung (MNDM): flow Chuẩn bị đầy đủ → start → bước 2; double-tap khoá; Master cùng trường bấm "Tiếp tục buổi học" → block copy đúng, đứng yên; Master khác trường → "Cô không có quyền xem buổi học này" (cách ly liên-trường); buổi đã gửi hiện banner + "GV phụ trách: Đặng Mỹ Linh"; **S3: upload ảnh → chip → ảnh mở trong player; video `Xuan_Thinh.mp4` mở xen "ĐANG MỞ" + "Về bài dạy" + PHÁT THẬT 0:08 hết bài trên emulation mobile; bước Ghi nhận network toàn 200, không regression.**

Buổi test: `demenart.com/teacher/session/91bc03d8-a1c3-4158-923c-bd9ac979b821` (in_progress, Hoa Hồng KHM) · `3bfb9730-193f-40c1-a285-d515bca01404` (taught_report_pending). Accounts (đều `Test@123`): GV `gv.linh.kidshouse@demo.demenart.com` · Master KHM `hieutruong.kidshouse@demo.demenart.com` · Master MNDM `hieutruong.demen@demo.demenart.com` · PH KHM `ph.hung.kidshouse@demo.demenart.com`.

## 5 · INVENTORY & DRIFT

Re-pin ×2 trong phiên: **88 bảng · 210 hàm · 199 secdef · 166 policy · 1 cron · registry 115 · 52 routes · 16 Edge — zero drift, 0 migration mới.** Single-writer giữ (mỗi slice = 1 edit push, `list_edits limit=1` trước mỗi WP).

## 6 · P2 LEDGER (carry, evidence-backed)

40 `no-explicit-any` trong `as any` RPC cast vùng freeze (cấm sửa khi freeze còn hiệu lực) · guide nạp 2 lần khi Chuẩn bị→Trong giờ học (LessonPreview vs StepTeach — paths tách chủ ý; hợp nhất = ứng viên tương lai) · 5 high npm audit pre-existing (S0 cấm upgrade) · commit messages platform-generated (diff đúng) · `SessionResourcePanel` giữ alias const trỏ `T.*` (cosmetic) · hls.js cho Bunny Stream video = **DEFER có chủ đích** (player chỉ file trực tiếp) · watermark không áp surface teacher-local (tiền lệ PocketMirror) · sticky CTA/quick-bar với bàn phím mở trên mobile cần theo dõi · token spec `focus #2066C2` không áp (giữ focusRing Home) · max-width shell 1152 vs spec 1180–1220 · skill-chip on/off cùng nền T.mint (S4 rework) · surface lỗi `#F6E4DF` literal (S4).

## 7 · SPRINT KẾ: S4 — GHI NHẬN + HOÀN TẤT (chưa mở)

Scope đã định: restyle StepRecord (3 tab điểm danh/quan sát/ảnh) + PhotoTab + StepReview theo tokens · **lift nháp `summary`/`followUp` lên SessionFlow** (hiện useState cục bộ StepReview → mất khi rời bước = P1 còn lại cuối cùng) · copy lỗi cho `toggleTag`/`saveCaption` (đang nuốt câm) · recovery-error copy (P2 D325) · cân nhắc "Bạn"→"cô" trong `blockReasonCopy` (= đụng authority string → **re-QA kiểu S4-4 bắt buộc**: double-tap Start/Submit, Master không-CTA, reload canonical, responsive). Freeze như cũ + D327 grep verbatim (không lặp deviation S3). Entry gate: re-pin HEAD `41d6732e` (hoặc commit mới Owner chỉ rõ) + Owner xác nhận S3 production ổn.

## 8 · TOOL PATTERNS PHIÊN NÀY (bổ sung kho)

`send_message` transport error ≠ fail: lấy `umsg_…` id từ pagination cursor của `list_messages` → `get_message` poll (`running`→`completed`, có `edit_id`/`commit_sha`/`cost_credits`) · poll rẻ bằng `list_edits limit=1` · S3 cost 7.8 credits, S1/S2 ~5–6.5 · agent tự restore routeTree regen về HEAD copy khi được dặn · RULES 796KB/MAP 440KB: append/patch bằng bash+python trên bản copy đĩa, KHÔNG regenerate (tail cắt UTF-8 đa byte → dùng `iconv -c` khi đọc).

## 9 · VIỆC TAY CỦA ANH JEAN

① Upload 3 file mới vào project knowledge (thay bản cũ RULES/MAP): `DMA_RULES.md` · `DMA_SYSTEM_MAP.md` · `DMA_HANDOFF_V116_SESSION_S0_S3.md`. ② Phiên sau mở bằng: *"Boot V116, chạy S4"*.
