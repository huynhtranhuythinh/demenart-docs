# 💌 DMA_HANDOFF — V118-M1 · PARENT–TEACHER APPRECIATION LOOP — "LỜI CẢM ƠN" — ĐÓNG

**Ngày:** 27/07/2026 (GMT+7) · **Phiên:** Phase A audit (READY WITH EXPLICIT GAPS → CTO approved) + Phase B implementation + SQL/static QA + Owner QA 2 vòng · **Verdict: PASS — V118-M1 CLOSED**
**Endpoint canonical:** RULES **D335** · SYSTEM_MAP **v1.23** · HANDOFF **V118-M1** (file này — thay V117-M2 làm handoff hiện hành; V117-M2 giữ làm lịch sử)

---

## 0 · BOOT PHIÊN SAU (đọc theo thứ tự)
1. `DMA_HANDOFF_V118_M1.md` (file này) → 2. `DMA_00_START_HERE.md` → 3. `DMA_RULES.md` (tip = D335) → 4. Audit live DB (D1) → 5. `list_edits limit=1` re-pin single-writer (expected tip **`df958fc6`**).

---

## 1 · TRẠNG THÁI PRODUCTION

- **Frontend tip:** **`df958fc6`** — "Restored routeTree.gen.ts". Lineage V118-M1 nối `e20bffa4` (V117-M2): `ade28d85` "Applied byte-exact changes" (feature 8 file) → `fa824baf` "a11y SheetTitle/Description" → `5a1e3bfa` "Fix V118-SA visual 4 điểm" (Owner r1) → `48c62b32` "Redesigned Teacher love wall" → `3ec70199` "Convert list to grid layout" **⚠️ kèm routeTree.gen.ts bị build regenerate append khối declare-module — narrative agent claim "không đổi", diff nói ngược (D329 lần 3)** → `df958fc6` restore routeTree byte-exact (verified full-file read tại tip). **Net diff milestone vs baseline = đúng 9 file in-scope; routeTree/shell/teacher-session/school-today/journey/consent/Edge/dependency/lockfile zero-diff.** Mọi commit `get_diff` verified (D134). Cloudflare CI xanh; Owner QA trên production 2 vòng.
- **Backend:** +1 migration **`20260727062903 · v118_parent_teacher_appreciation`** (3-block D92 · VERIFY **10 assertion groups** PASS atomic gồm impersonation read-only D333 · `notify pgrst` đã gửi D289). **Delta đúng proposal 100%: 89 bảng (+1) · 214 hàm (+2) · 203 secdef (+2) · 166 policy (0 mới — deny-all by design) · 33 trigger · 1 cron · registry 118 · 52 routes · 16 Edge.**
- **Live data sau Owner QA:** 2 appreciation rows production hợp lệ (Hùng→An và Toản→Bình, cùng "Vương quốc âm thanh", đều có note, recipient GV Linh) + 2 audit rows metadata-only. Fixture `ph.toan.kidshouse` đã reset về password chuẩn `Test@123` + confirm email (Owner yêu cầu; pattern `extensions.crypt(...gen_salt('bf'))`).

## 2 · ĐÃ BUILD GÌ

**Bảng `session_appreciations`** — snapshot đủ 4 theo contract (recipient_teacher_profile_id · recipient_assignment_id · school_id qua `session_school_id` · sender_relation từ `child_parents.link_role` coalesce 'guardian') · UNIQUE(sender_parent_profile_id, child_id, session_id) không partial · preset CHECK 4 key · note CHECK 1–280 · immutable (không UPDATE/DELETE path) · **RLS ON deny-all: 0 policy, authenticated/anon zero table privilege** · index recipient+created_at DESC.

**3 RPC secdef (`search_path=''`, ACL postgres/authenticated/service_role only, D15 verified aclexplode):**
- `create_session_appreciation(p_child_id, p_session_id, p_preset_key, p_note_text)` — 16 bước đúng contract: role primary/secondary_parent → `is_child_parent` → snapshot relation → outcome eligibility CÙNG semantic `get_parent_session_outcomes` (child_journey session/demen/ref_id) → duplicate → resolve responsible current-row-only KHÔNG fallback → verify recipient role+school=session_school → whitelist preset → normalize note (collapse whitespace, empty→NULL, cap 280, >280 = `note_too_long`) → insert (race unique_violation → already_sent) → audit KHÔNG note body → curated result `{ok, status: sent|already_sent|recipient_unavailable, recipient_teacher_name, sent_at}`. Ownership denial generic `not_authorized` đồng nhất mọi nhánh.
- `get_teacher_appreciations(p_limit=5)` — clamp 1–20, lead/assistant only, `recipient=current_profile()` tuyệt đối, payload whitelist (id · sender_relation · child_name nickname-first · session_title · session_date · preset_key · note_text · created_at), KHÔNG PII Parent, KHÔNG session_id/school_id/profile_id, KHÔNG unread/count.
- `get_parent_session_outcomes` — additive replace: +node `appreciation{status: available|sent|unavailable, recipient_teacher_name, sent_at}` per outcome (sent từ snapshot row của caller; available từ current responsible; unavailable khi thiếu). Signature/ownership/eligibility/sort/pagination/has_more/moments/denial NGUYÊN. Vẫn 1 RPC/child, không N+1.

**Parent FE:** `src/features/parent/appreciation/` — `appreciationPresets.ts` (4 preset copy CTO + `presetIcon` map HeartHandshake/Smile/Sparkles/Heart + `relationLabel` mother→Mẹ/father→Ba/else→Người giám hộ — SHARED cho cả Teacher) · `appreciationModel.ts` · `useSendSessionAppreciation.ts` (rpcUntyped, không any) · `SessionAppreciationSheet.tsx` (bottom sheet, SheetTitle/Description, radiogroup roving-tabindex + Check không-chỉ-màu, counter x/280, copy "không cần phải trả lời", chống double-submit, giữ note khi lỗi, **success-hold 1400ms tim lớn + toast sonner 6s**, timer clear on unmount). Card protected scoped-edit: CTA secondary **tim hồng rose-50/200/600** dưới "Xem trọn buổi học" · sent → dòng tĩnh tim nhỏ "Đã gửi lời cảm ơn đến {tên}." · unavailable → ẩn CTA (D290) · childId qua `useParentChild()` không đổi props · sentOverride local, KHÔNG re-fetch outcome · Sheet unmount theo child-switch (seq discipline sẵn có). Model protected scoped-edit: +field `appreciation` parse tolerant.

**Teacher FE:** `TeacherAppreciationSection.tsx` — "Lời cảm ơn từ gia đình" = **Bức Tường Yêu Thương**: thiệp pastel 5 màu xoay vòng (vàng/hồng/lá/dương/tím) + ghim tròn màu đỉnh thiệp + rotate ±1.2° + bóng mềm · quote nghiêng trong ngoặc kép + note "— …" + chữ ký "{relation} của {child} · {session} · {date}" + icon preset nhỏ màu ghim · **grid `auto-fill minmax(300px,1fr)`** (full-width 2 thiệp/hàng, cột phải hẹp tự 1 cột) · load mount + focus/visibility seq-guard, KHÔNG polling/realtime mới · empty "Chưa có lời cảm ơn nào." · error section-level retry · KHÔNG reply/reaction/badge/count/unread. Mount 2 nhánh loại trừ trong `teacher.index.tsx` (cột phải dưới PrepCard · sau EmptyToday).

**M1 KHÔNG có (đúng Locked Contract):** Teacher reply · chat · edit/withdraw/delete · mark-read · read receipt · unread counter · notification projection (`create_notification` không gọi, `parent_replies=0` nguyên, `get_teacher_todo_counts` không đụng) · realtime · polling mới · route mới · analytics/rating.

## 3 · QA — TẤT CẢ PASS

1. **Migration VERIFY 10 groups atomic:** table/RLS/unique grain exact/policy tổng 166/table ACL sạch/func ACL aclexplode + search_path + proacl not-null cho cả 3/inventory delta/impersonation PH Hùng payload có node appreciation hợp lệ + forbidden-field grep/PH gọi teacher-list denied/GV Linh list ok rỗng trung thực/bảng rỗng zero-seed.
2. **SQL actor matrix T1–T18 rollback-only PASS** (raise-with-payload, zero residue verified 0·0·0): create+normalize · duplicate→already_sent 1 row · invalid_preset · note 281 reject · whitespace→NULL · outcome sent+tên đúng · cross-child denial · parent thứ hai row riêng · **counterfactual recipient_unavailable fail-closed không insert** (dựng bằng cancelled session + journey row trong txn — guard `dma_guard_sta_append_only` chặn mutate STA, chính guard = proof authority bất biến) · cross-school parent denial · GV Linh 3 items whitelist sạch không PII · GV cùng trường 0 · GV khác trường 0 · master + super_admin denied cả 2 RPC · anon zero privilege · authenticated direct SELECT/INSERT `insufficient_privilege` · integrity assignment↔session↔school 0 mismatch · audit không body.
3. **Static:** typecheck + build PASS mọi commit; routeTree net zero-diff (byte-verified tại tip).
4. **Owner QA PASS 2 vòng** (desktop + incognito; PH Hùng, PH Toản, GV Linh, GV Hân isolation-check; network đúng 1 RPC/surface, console sạch, F5 giữ sent). Chỉ đạo đã fix: nút tim hồng · icon preset · success-hold + toast 6s · thiệp love-wall + grid 2/hàng. Chỉ đạo **#6 Teacher thả tim/reply → DEFER đúng quy trình** (contract M1 cấm tường minh) → candidate M2.

## 4 · P2/P3 LEDGER

- **P2 mới:** (a) **M2 "Teacher acknowledgement"** — Owner muốn GV phản hồi một chạm/preset; cần CTO mở contract (mark-read + reaction hiện bị cấm M1); (b) "2 parent cùng 1 child" mới prove constraint-level — fixture thiếu secondary_parent chung child; (c) D291 khép khi browser thật đã gọi 3 RPC ✅ (Owner QA đã gọi cả 3 trên production — coi như ĐÓNG).
- **P2 carry nguyên:** 768px nav shell · nav lạc `/teacher/profile` · sticky-CTA-bàn-phím · day-state semantics v2.
- **P3 mới:** Chrome MCP không kết nối trọn phiên Claude (Owner tự browser-QA — lần 2 liên tiếp, cân nhắc kiểm tra extension) · `notifications` table grant rộng hơn cần (RLS che — hygiene note từ Phase A) · agent build regenerate generated-file rồi commit lẫn (2 lần trong phiên; lần 2 lọt vào commit `3ec70199`, đã restore `df958fc6`) — **quy trình cứng: mọi get_diff phải soi mục routeTree.gen.ts/generated trước khi chấp nhận.**
- Zero mutation production ngoài migration + 2 appreciation rows Owner QA + password reset fixture Toản (đều là ý định Owner).

## 5 · VIỆC JEAN CẦN LÀM TAY

1. Upload 3 file thay thế vào project knowledge: `DMA_RULES.md` (tip D335, 823.228 bytes) · `DMA_SYSTEM_MAP.md` (v1.23, 449.159 bytes) · `DMA_HANDOFF_V118_M1.md`.

## 6 · SPRINT KẾ — CANDIDATES (chưa mở, chờ CTO)

A. **M2 "Teacher acknowledgement"** (Owner-requested: GV một chạm "đã đọc 💚" ± 2–3 preset phản hồi — vẫn không chat; CẦN CTO mở lại các mục cấm mark-read/reaction của M1). B. **V117-M3** — Parent outcome mở rộng (list nhiều buổi, `has_more` sẵn). C. **G.4+ restyle** (consent/settings/kid). D. **V114-SEC1** (classroom/remote + useSessionChannel). E. **FMN E2E fixture session** (cần Jean authorize mutation tường minh). F. **Day-state semantics v2**. G. **Secondary-parent fixture bổ sung** (đóng gap P2-b khi tiện).
