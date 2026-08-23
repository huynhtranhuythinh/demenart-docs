# 🤝 DMA_HANDOFF — V116 · TEACHER SESSION EXPERIENCE · S4 (GHI NHẬN + HOÀN TẤT) — ĐÓNG TRỌN TRACK

**Ngày:** 26/07/2026 (GMT+7) · **Phiên:** S4 production build + full QA + QA-fix · **Verdict: PASS — V116 S0–S4 CLOSED**
**Endpoint canonical:** RULES **D331** · SYSTEM_MAP **v1.20** · HANDOFF **V116-SESSION-S4** (file này — absorb closeout S4, thay thế V116-SESSION-S0-S3 làm handoff hiện hành; S0-S3 giữ làm lịch sử)

---

## 0 · BOOT PHIÊN SAU (đọc theo thứ tự)
1. `DMA_HANDOFF_V116_SESSION_S4.md` (file này) → 2. `DMA_00_START_HERE.md` → 3. `DMA_RULES.md` (tip = D330) → 4. Audit live DB (D1 — không tin số trong tài liệu) → 5. `list_edits limit=1` re-pin single-writer (expected tip `b77697b0`).

---

## 1 · TRẠNG THÁI PRODUCTION

- **Frontend tip:** `b77697b0` — lineage V116: `18db884c` → `d6a9cfff` → `e3434bb4` → `41d6732e` → **`a1016721` (S4 feat)** → **`b77697b0` (S4 QA-fix D330)**. Cloudflare CI xanh, production demenart.com đã nhận.
- **Backend:** ZERO change toàn phiên. Re-pin cuối: **88 bảng · 210 hàm · 199 secdef · 166 policy · 33 trigger · 1 cron · registry 115 (latest `20260725011235 v114b_e3_rm1_session_reports_write_revoke`) · 52 routes · 16 Edge** — zero drift, khớp expected 100%.
- **File scope S4:** DUY NHẤT `src/routes/_authenticated/teacher.session.$id.tsx` (cả 2 commit). `routeTree.gen.ts` restore về HEAD cả 2 lần. Không route mới, không dependency change.

## 2 · S4 ĐÃ BUILD GÌ (commit `a1016721`)

**Giao thức thi công (→ D329):** file đích ~125k chars > giới hạn send_message 100k → build artifact cục bộ (`/home/claude/s4/teacher.session.new.tsx`, pre-verify esbuild parse + prettier printWidth-100 check sạch, xác nhận repo style vì prettier trên vùng frozen diff RỖNG) → 1 message với 9 REPLACEMENT block byte-exact anchor-based → agent áp → `get_diff` scope 1 file + freeze-grep → `read_file` byte-compare khớp artifact 100%.

**Bước 3 — Ghi nhận:**
- Tabs 44px + focusRing + aria-pressed; save-status `role="status" aria-live="polite"`; marks copy bỏ reference "Remote".
- **Điểm danh:** avatar initials (`initialsOf` từ teacherTokens), counts header "Có mặt N · Đi muộn N · Vắng N", dòng unmarked/đủ aria-live, nút 44px + Check khi chọn, label "Đi muộn", `#F6E4DF` literal → `T.peachSurface`, flex-wrap 320px, `role="group"` per bé.
- **Ghi nhận:** header ngữ cảnh bé đang chọn (avatar + trạng thái điểm danh + số kỹ năng), skill chip on = primary bg + Check / off = trắng viền, OBS_FLAGS + Check khi bật, heading "Ghi chú nhanh" + label + placeholder mới, chip bé Đi muộn có icon Clock.
- **Ảnh (P1-2/P1-3):** `toggleTag` bắt lỗi — fail → lỗi TẠI moment ("Chưa thể gắn bé vào ảnh" / "Vui lòng thử lại. Lựa chọn của cô vẫn được giữ."), chip "(chưa lưu)" viền đứt đỏ, nút "Thử lại — gắn/bỏ gắn {tên}", KHÔNG loadMoments khi fail (giữ ý định); `saveCaption` bắt lỗi — giữ text trong editor (uncontrolled, không bị server value đè), "Chưa thể lưu chú thích" + retry, status "Đang lưu chú thích…" aria-live; mutation lines (.from/.delete/.eq/.insert/.update payload) byte-nguyên, chỉ đổi `await` → `const { error: xxxErr } = await`.
- **RecordNav:** sticky ≤479 bottom-72px, CTA "Tiếp tục hoàn tất".

**Bước 4 — Hoàn tất:**
- **P1-1:** `summary`/`followUp` state SỐNG ở SessionFlow, StepReview nhận props controlled; payload `p_summary: summary.trim() || null` byte-nguyên. Helper: "Nháp đang được giữ trong phiên này." Refresh mất = V1 by design.
- **Checklist actionable:** unmarked→tab att · untagged/absent-tagged→tab photo (prop `onGoTab` = goToRecord) · thiếu tóm tắt = gợi ý KHÔNG chặn; chặn gửi CHỈ từ server capability. Reactive: gõ nháp → finding tự biến mất.
- **Card GV phụ trách:** chỉ initials + display_name (không lộ assignment_source/evidence_grade/ID).
- **blockReasonCopy (D327 exception, keys/order/signature nguyên):** forbidden → "Cô không phải giáo viên phụ trách buổi học này. Nhật ký chỉ có thể được gửi bởi giáo viên phụ trách buổi. Ghi nhận của cô vẫn được lưu và sẽ đi kèm khi buổi được gửi." · no_responsible_assignment → "Buổi học chưa có giáo viên phụ trách…". Submit inline err "Bạn"→"Cô".
- **P1-5 (ĐÓNG P2 D325):** SessionFlow error branch 2 nhánh — `recoveryFail` → card "Chưa thể xác nhận kết quả gửi" + support "Cô vui lòng tải lại trạng thái buổi học để kiểm tra. Hệ thống sẽ không tự gửi lại nhật ký." + nút "Tải lại trạng thái" (`reloadSessionState` CHỈ gọi loadDetail); StepReview submit chèn `if (r === "failed") onRecoveryFailed();` sau comment block — ordering locked ops KHÔNG đổi.
- **Submit CTA:** "Gửi nhật ký" / "Đang gửi nhật ký…" / recovering "Đang kiểm tra kết quả gửi…" / err card "Không thể gửi nhật ký" + reason; sticky ≤479.
- **Success:** Heart mascot (1, không confetti/emoji), "Nhật ký đã được gửi" + "Những khoảnh khắc và ghi nhận của buổi học đã được gửi tới gia đình.", chỉ field thật (journey_created/moments_approved > 0 mới hiện), tên GV phụ trách, "Xem lại buổi học" (setResult null) + "Về Hôm nay" (/teacher).

**QA-fix (commit `b77697b0`, → D330):** route-error forbidden "Cô không có quyền xem buổi học này." → "**Tài khoản này** không có quyền xem buổi học này." — Owner QA bắt: PH nam nhận copy "Cô" sai đối tượng. Diff = đúng 1 dòng.

## 3 · AUTHORITY PRESERVATION PROOF (D324/D325/D327)

- get_diff `a1016721`: locked identifiers (`loadDetail`+3 refs · `startLockRef` · `spAliveRef` · `submitLockRef` · recovering ordering · `stepForState` · `SENT_STATES` · `BackLink`/`useCanGoBack` · `onReloadDetail` · `start_session` · `submit_session_journal` payload · mutation filter/conflict-key) KHÔNG xuất hiện trong dòng +/- ngoài 3 insertion spec cho phép: props StepReview mới · 2 dòng onRecoveryFailed · literal "Bạn"→"Cô". `read_file` post-commit byte-khớp artifact.
- get_diff `b77697b0`: 1 dòng string, không đụng gì khác.
- Gate submit duy nhất: `canSubmitJournal === true` server-sourced.

## 4 · QA RESULTS — 12/12 PASS

**Runtime actor (SQL impersonation, session `3bfb9730` taught_report_pending, re-resolve trước):** GV Linh ok+can_submit=true · Master KHM ok+can_submit=false+block=forbidden · Master MNDM ok=false forbidden · PH Hùng ok=false forbidden.

**Browser production (Claude-in-Chrome bước 1-8 dưới tài khoản cô Linh + Jean bước 9-12):**
1-8 ✅ route→B4 đúng state · Điểm danh chuẩn · Ghi nhận chuẩn · tag/caption live (hoàn tác sạch) · checklist Bổ sung nhảy đúng tab · P1-1 giữ nháp qua 2 vòng B3↔B4 · card GV initials · **submit thật thành công** ("Nhật ký đã được gửi", 6 bé, success screen chuẩn, "Xem lại buổi học" hoạt động). Console 0 app error toàn phiên.
9 ✅ Master KHM: card block đúng copy mới, không nút Gửi. 10 ✅ PH: "Không mở được buổi học" (→ phát sinh QA-fix copy D330). 11 ✅ 390/320px không vỡ. 12 ✅ F5 mất nháp = V1 by design.

**Safe failure-injection:** NOT EXECUTED (không có fixture an toàn không-mutation) — code-path evidence trong closeout, non-blocking theo spec §16.

## 5 · P2/P3 LEDGER CARRY

- P2: 768px nav (shell, ngoài scope) · tag/caption error giữ PhotoTab-local không lift lên checklist B4 (reasoned — hệ quả untagged đã cover) · nav lạc `/teacher/profile`→`/school/manage` quan sát 1 lần, chưa tái hiện (theo dõi) · sticky-CTA-với-bàn-phím (carry S0-S3).
- P3: `list_edits` commit label do platform sinh ("Applied byte-exact changes" / "Fixed teacher session copy") ≠ git subject yêu cầu — Owner xác nhận trên repo nếu cần · session_reports dead-door · residual E3-MC carry-forward (xem RULES).

## 6 · VIỆC JEAN CẦN LÀM TAY

1. Upload 3 file thay thế vào project knowledge: `DMA_RULES.md` (mới, tip D330) · `DMA_SYSTEM_MAP.md` (v1.20) · `DMA_HANDOFF_V116_SESSION_S4.md`.
2. (Tuỳ chọn) Xác nhận git subject 2 commit trên repo GitHub.

## 7 · SPRINT KẾ — CANDIDATES (chưa mở)

A. **G.4+ restyle** — consent/settings/kid surfaces. B. **FMN E2E fixture session** — cần Jean authorize mutation tường minh. C. **V114-SEC1** — hồi sinh classroom/remote + useSessionChannel theo contract mới.
