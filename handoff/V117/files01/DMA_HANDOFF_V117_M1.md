# 🤝 DMA_HANDOFF — V117-M1 · PARENT OUTCOME LOOP "SAU BUỔI HỌC" — ĐÓNG

**Ngày:** 27/07/2026 (GMT+7) · **Phiên:** preflight + migration + FE build + QA đủ 3 tầng · **Verdict: PASS — V117-M1 CLOSED**
**Endpoint canonical:** RULES **D333** · SYSTEM_MAP **v1.21** · HANDOFF **V117-M1** (file này — thay V116-SESSION-S4 làm handoff hiện hành; V116 giữ làm lịch sử)

---

## 0 · BOOT PHIÊN SAU (đọc theo thứ tự)
1. `DMA_HANDOFF_V117_M1.md` (file này) → 2. `DMA_00_START_HERE.md` → 3. `DMA_RULES.md` (tip = D333) → 4. Audit live DB (D1) → 5. `list_edits limit=1` re-pin single-writer (expected tip `faa03708`).

---

## 1 · TRẠNG THÁI PRODUCTION

- **Frontend tip:** `faa03708` — "V117-M1: Parent session outcome module" (1 commit, agent send_message + get_diff verified D134), nối `b77697b0`. Cloudflare CI xanh, production demenart.com đã nhận (browser QA chạy trên production).
- **Backend:** +1 migration `v117_parent_session_outcomes` (3-block D92 · VERIFY 10 assertion PASS atomic · impersonation trong migration → D333). Re-pin: **88 bảng · 211 hàm (+1) · 200 secdef (+1) · 166 policy · 33 trigger · 1 cron · registry 116 · 52 routes · 16 Edge** — delta đúng expected 100%. ACL RPC mới: `postgres/authenticated/service_role EXECUTE` only. `notify pgrst` đã gửi (D289).
- **File scope FE:** 4 file MỚI `src/features/parent/session-outcome/` (`parentSessionOutcomeModel.ts` · `useParentSessionOutcomes.ts` · `ParentSessionOutcomeCard.tsx` · `ParentSessionOutcomeSection.tsx`) + 2 insertion `parent.index.tsx`. `routeTree.gen.ts` KHÔNG đổi. Zero diff: teacher.session.$id · sessionPrep/Player · parent.journal · Journey/FMN core · shell · Edge · dependency/lockfile.

## 2 · ĐÃ BUILD GÌ

**RPC `get_parent_session_outcomes(p_child_id uuid, p_limit int default 10) returns jsonb`** (STABLE secdef `search_path=''`):
- Gate DUY NHẤT `is_child_parent` — Parent-only; master/GV cùng trường KHÔNG nhận payload; denial generic `not_authorized` mọi nhánh (kể cả child không tồn tại — không lộ existence).
- Association (D332): journey `entry_type='session'` + `source='demen'` + **INNER JOIN lesson_sessions qua ref_id, ref_id IS NOT NULL** (⭐ phát hiện phiên: seed cũ của Khang/Hà/Phúc + 3 entry cũ của An có ref_id NULL → bị loại đúng, empty state trung thực là hành vi ĐÚNG) · skills per child+session từ `skills_observed` → `skill_catalog` enabled (KHÔNG suy từ aggregate `child_skills`) · moments approved + tag đúng child + media active.
- Clamp 1–20 · order `occurred_at DESC, journey_id DESC` · dedup per session (`distinct on ref_id`) · `has_more` · payload whitelist (không school/class/peer/note/flags/report/rank).

**Module "Sau buổi học" trên `/parent` Home** (chèn sau khối hero/create, trước supporting areas — không route/nav mới):
- Section: eyebrow "SAU BUỔI HỌC" · heading "Hôm nay con đã trải nghiệm gì?" / "Lần gần nhất của con" (theo ngày HCM) · subcopy "Những điều giáo viên vừa ghi nhận và gửi tới gia đình."
- Hook `useParentSessionOutcomes`: seq-guard Correction-A, đổi con clear NGAY, 1 RPC/child (`p_limit:1`), `rpcUntyped` (không any).
- Card: ngày giờ HCM · title · program · ≤3 skill chips + "+N ghi nhận khác" · ≤3 media tile (sign LAZY qua `useJourneySigning` sẵn có — KHÔNG engine ký thứ hai) · caption truncate · CTA "Xem trọn buổi học" → `/parent/journal?focus=journey:<journey_id>` (grammar sẵn có), full-width mobile.
- Truthful states đủ 5: skeleton aria-busy (không flash empty) · no-skills copy · no-moments copy · empty ("Chưa có nhật ký buổi học nào được gửi cho con." + dòng phụ) · lỗi section-level retry. `consent_missing` → tile "Ảnh đang chờ ba mẹ cho phép xem" + CTA "Quản lý quyền riêng tư" → `/parent/consent`; lỗi ký khác → retry TẠI tile.
- A11y: h1→h2→h3 đúng thứ tự · role=status/aria-live · 44px targets · alt không lộ peer · không autoplay · không điểm số/xếp hạng/so sánh/engagement giả.

## 3 · QA ĐỦ 3 TẦNG — TẤT CẢ PASS

1. **Migration VERIFY (atomic):** function present · aclexplode sạch (không PUBLIC/anon) · authenticated+service_role · positive Hùng ≥1 · clamp 999 · GV denied generic · cross-family denied generic · random-uuid denied generic · association cross-check từng row · payload key whitelist.
2. **SQL actor 6/6 (impersonation):** Hùng→An 2 outcome khớp DB từng field · Hùng→Khang empty (sibling scope sạch) · Thành→Hà authorized empty · Master KHM denied · GV Linh denied · random denied — đều generic.
3. **Browser production 14/14 (Claude-in-Chrome, tài khoản PH Hùng):** section render đúng · heading "Lần gần nhất của con" đúng (outcome 1/7 không phải hôm nay) · title/program/"lúc 09:00" HCM khớp DB · chips đúng observation · media ký media.demenart.com 200 đúng moment `093cc871…`, 1 request duy nhất (không N+1) · CTA href `journey:59e6dd40…` mở ĐÚNG Journey item, không banner focus-missing (rail 9/43) · đổi con An→Khang không flash + empty đúng copy → về An outcome nguyên vẹn · console 0 app error toàn phiên.
4. **Owner QA PASS** (Jean, iPhone Safari 09:37–09:38 27/07, 4 screenshot): mobile một cột, chips gọn, media tile chuẩn, CTA full-width, bottom nav không che — "đã ổn!".

## 4 · P2/P3 LEDGER

- P2 carry nguyên: 768px nav shell · nav lạc `/teacher/profile` (theo dõi) · sticky-CTA-với-bàn-phím.
- P3 mới: forbidden-language chỉ xuất hiện dạng phủ định trong code comment (minh bạch, không phải UI copy) · `resize_window` extension không áp dụng khi Chrome fullscreen (mobile QA giao Owner — tiền lệ hợp lệ) · F5-giữ-focus trên journal chưa re-verify độc lập phiên này (grammar V113G sẵn có, không phải code mới; batch timeout giữa chừng).
- Không mutation production nào ngoài migration; fixture nguyên vẹn (test read-only 100%).

## 5 · VIỆC JEAN CẦN LÀM TAY

1. Upload 3 file thay thế vào project knowledge: `DMA_RULES.md` (tip D333) · `DMA_SYSTEM_MAP.md` (v1.21) · `DMA_HANDOFF_V117_M1.md`.

## 6 · SPRINT KẾ — CANDIDATES (chưa mở)

A. **V117-M2** — outcome mở rộng (danh sách nhiều buổi / "Lần trước nữa", dùng `has_more` sẵn có). B. **G.4+ restyle** (consent/settings/kid surfaces). C. **FMN E2E fixture session** (cần Jean authorize mutation tường minh). D. **V114-SEC1** (classroom/remote + useSessionChannel). E. **Reaction contract** ("Lời cảm ơn" PH → GV — cửa đã chừa trong spec V117, chưa build).
