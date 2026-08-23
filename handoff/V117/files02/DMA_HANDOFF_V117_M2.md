# 🤝 DMA_HANDOFF — V117-M2 · SCHOOL DAILY OPERATIONS — PRINCIPAL "HÔM NAY" — ĐÓNG

**Ngày:** 27/07/2026 (GMT+7) · **Phiên:** preflight A1–A7 + migration + FE build + QA-fix visual + QA đủ 3 tầng + Owner QA · **Verdict: PASS — V117-M2 CLOSED**
**Endpoint canonical:** RULES **D334** · SYSTEM_MAP **v1.22** · HANDOFF **V117-M2** (file này — thay V117-M1 làm handoff hiện hành; V117-M1 giữ làm lịch sử)

---

## 0 · BOOT PHIÊN SAU (đọc theo thứ tự)
1. `DMA_HANDOFF_V117_M2.md` (file này) → 2. `DMA_00_START_HERE.md` → 3. `DMA_RULES.md` (tip = D334) → 4. Audit live DB (D1) → 5. `list_edits limit=1` re-pin single-writer (expected tip **`e20bffa4`**).

⚠️ **Ghi chú phiên V117-M2:** project mount đầu phiên THIẾU `DMA_RULES.md`/`DMA_SYSTEM_MAP.md` trên đĩa → Jean upload nguồn thật vào chat, Claude áp máy móc trên byte thật (append D334 · patch 4 điểm v1.22, verify prefix-intact + grep tip) và xuất **đủ 3 full file thay thế** đúng nguyên tắc đóng phiên. Phiên sau verify tip D334/v1.22 trên đĩa trước khi làm việc.

---

## 1 · TRẠNG THÁI PRODUCTION

- **Frontend tip:** **`e20bffa4`** — "Styled Today block gradient" (QA-fix visual, 1 file `SchoolTodayOverview.tsx`) nối **`f8a94d14`** — "Added school today dashboard" (feature chính) nối `faa03708`. Cả 2 commit `get_diff` verified (D134/D329 — narrative agent trong QA-fix tự mâu thuẫn về sandbox SHA/routeTree, diff cuối là sự thật: đúng 1 file, routeTree không đổi). Cloudflare CI xanh, production demenart.com đã nhận (browser QA + Owner screenshot trên production).
- **Backend:** +1 migration **`v117_school_today_operations`** (3-block D92 · VERIFY **20 assertion** PASS atomic · impersonation D333 resolve actor qua email; sub_admin fixture vắng → skip hợp lệ). **Delta đúng expected 100%: 88 bảng · 212 hàm (+1) · 201 secdef (+1) · 166 policy · 33 trigger · 1 cron · registry 117 · 52 routes · 16 Edge.** ACL RPC mới: `postgres/authenticated/service_role EXECUTE` only (aclexplode sạch). `notify pgrst` đã gửi (D289).
- **File scope FE:** 6 file MỚI `src/features/school/today/` (`schoolTodayModel.ts` · `useSchoolTodayOperations.ts` · `SchoolTodayOverview.tsx` · `SchoolAttentionList.tsx` · `SchoolTodaySessionList.tsx` · `SchoolSessionDetailPanel.tsx`) + 2 route edit (`school.manage.tsx`: validateSearch +`session`, chèn Today block, ZoneHeading "Quản lý trường", GỠ `ParentEngagementPreview`, de-fake row ClassProgress; `school.index.tsx`: pass-through `session` qua redirect). `routeTree.gen.ts` KHÔNG đổi. Zero diff: shell `school.tsx` · teacher/parent/journey/family/Edge/dependency/lockfile.

## 2 · ĐÃ BUILD GÌ

**RPC `get_school_today_operations(p_date date default null) returns jsonb`** (STABLE secdef `search_path=''`):
- Authority server-side thuần: `auth.uid()` → profiles (role+school_id); CHỈ `master_admin|sub_admin` có school; denial `raise exception 'not_authorized'` generic mọi nhánh; không client-supplied school_id; không dùng `is_school_admin()` (non-definer) trong definer.
- `p_date` = presentation/QA date thuần (không tham gia authority); NULL = hôm nay `Asia/Ho_Chi_Minh`; UI luôn gọi NULL.
- **Nguồn canonical (⭐ phát hiện A4):** điểm danh = `child_observations.attendance` per child+session (KHÔNG phải `session_marks` — bảng đó là part-marks bài học) · roster = `enrollments.state='active'` · nhật ký = EXISTS `session_reports` (CẤM suy từ session_state — `taught_report_pending` có thể ĐÃ nộp) · phụ trách = `session_teacher_assignments` `responsible`+`is_current`+`valid_to IS NULL` current-row-only, không fallback.
- 4 reason codes + severity + dedup + day_state 3 giá trị + payload whitelist đầy đủ → xem D334.

**Surface "Hôm nay" trên `/school/manage` DashboardView** (deviation hợp thức so prompt: audit A3 chứng minh home thật là `/school/manage` theo Route Contract A E1a — `/school` vẫn redirect giữ search nên "mở /school thấy Today" vẫn đúng):
- Composition: Welcome → **khối HÔM NAY nền forest đậm** (visual anchor — Owner chỉ đạo) → ZoneHeading "Quản lý trường · Điều hành & dữ liệu tích lũy" → KPI/Health/Progress/Week/Moments/Support nguyên vẹn.
- Khối Hôm nay: eyebrow honey `HÔM NAY` · h2 trắng "Hôm nay trường mình có ổn không?" · ngày VN không lệch UTC (dựng Date từ parts) · banner **Green `#22B586` (ổn) / Red `#E2574C` (Có N việc cần chú ý, N phóng to) / trung tính (chưa có buổi)** · 4 tile số text-3xl/4xl bold trắng · skeleton/error cùng tone tối, section-level retry, phần dưới luôn dùng được.
- Attention list exception-first (thứ tự severity từ server) + timeline nhóm Cần chú ý → Đang diễn ra → Sắp diễn ra → Đã hoàn tất → Đã huỷ (mỗi buổi đúng 1 nhóm) + detail Sheet read-only reuse payload (Đóng · Mở quản lý giáo viên · Xem khoảnh khắc của trường khi count>0; copy thiếu phân công: "Cần phân công giáo viên phụ trách cho buổi này."; CẤM mọi CTA làm thay GV).
- `?session=` = UX state thuần: validate ≤64, drop khi có `tab`, invalid/không-trong-payload tự dọn im lặng (replace), F5 giữ, redirect `/school` pass-through.
- Today CHỈ render khi canManage — GV read-only không thấy section, **zero** call RPC (D290 sạch, browser-proven).
- Hook `useSchoolTodayOperations`: `rpcUntyped` pattern V117-M1, seq-guard, đúng 1 RPC/load, không polling.

## 3 · QA ĐỦ 3 TẦNG + OWNER — TẤT CẢ PASS

1. **Migration VERIFY 20 assertion (atomic):** function/ACL/aclexplode · KHM positive 07-22 (needs_attention, total 3, attn 1) · MNDM no_sessions cùng ngày (isolation) · NULL=ICT today · deterministic · whitelist top/session/nested · forbidden-field grep · summary cross-check (sched+inprog+done+cancelled=total; attn=len) · dedup · **predicate proof `3bfb9730`: taught_report_pending + report ĐÃ nộp → chỉ `attendance_incomplete`, KHÔNG mislabel journal** · cancelled 0 reason · order.
2. **SQL actor QA 8/8 (runtime impersonation, zero mutation):** KHM today 27/07 = no_sessions trung thực · 07-23 = needs_attention `[attendance_incomplete]` resp Đặng Mỹ Linh · 06-30 = on_track · 07-22 mixed đúng · MNDM sạch · GV Linh / PH Hùng / super_admin denied generic.
3. **Browser production QA (Claude-in-Chrome, KHM master):** `/school`→`/school/manage` · "Thứ Hai, 27/07" đúng · no_sessions + 0·0·0·0 khớp RPC · composition đúng · `?session` bogus tự dọn · `?tab=classes&session=abc` giữ tab drop session, ManagementView OK · console 0 app error · network đúng **1** Today RPC không per-session/loop · GV direct route: read-only không Today không RPC · PH direct route: "Không có quyền". (Detail mở buổi thật cần ngày có buổi — proven qua SQL historical, đúng quy trình không mutate; platform-admin browser smoke skip vì không có mật khẩu — SQL denial đã chứng minh.)
4. **Owner QA PASS** (Jean, desktop + iPhone Safari 11:47–12:07 27/07, 10 screenshot): bố cục PASS, mobile một cột + summary 2×2 sạch; 2 chỉ đạo design → fix ngay commit `e20bffa4` (Green/Red semantics + Today visual anchor đậm) → Owner re-check **"ok ổn rồi!"**.

## 4 · P2/P3 LEDGER

- **P2 mới:** nâng cấp day-state semantics sâu hơn khi có dữ liệu vận hành thật (Owner #1 — "số 0 chưa nói được cảm giác ổn"; hiện tại trung thực là đủ pre-pilot).
- P2 carry nguyên: 768px nav shell · nav lạc `/teacher/profile` · sticky-CTA-với-bàn-phím.
- **P3 mới:** desc Zone2 còn chữ "tương tác gia đình" dù card preview đã gỡ (copy remnant) · HEAD poll `notifications` 503 transient một lần (shell sẵn có, không thuộc scope) · Chrome extension MCP rớt kết nối 2 lần giữa phiên (QA vẫn đủ) · sidebar còn mục LOCKED "Tương tác phụ huynh" (shell zero-diff chủ đích — trung thực, giữ).
- Zero mutation production ngoài migration; fixture nguyên vẹn.

## 5 · VIỆC JEAN CẦN LÀM TAY

1. Upload 3 file thay thế vào project knowledge: `DMA_RULES.md` (tip D334, 818.738 bytes) · `DMA_SYSTEM_MAP.md` (v1.22, 447.066 bytes) · `DMA_HANDOFF_V117_M2.md`.

## 6 · SPRINT KẾ — CANDIDATES (chưa mở)

A. **Reaction contract** ("Lời cảm ơn" PH → GV — School giờ đã trả lời được câu vận hành cơ bản, prerequisite lý do defer đã gỡ). B. **V117-M3** — Parent outcome mở rộng (danh sách nhiều buổi, `has_more` sẵn có). C. **G.4+ restyle** (consent/settings/kid). D. **V114-SEC1** (classroom/remote + useSessionChannel). E. **FMN E2E fixture session** (cần Jean authorize mutation tường minh). F. **Day-state semantics v2** (P2 Owner #1, sau khi có dữ liệu vận hành thật).
