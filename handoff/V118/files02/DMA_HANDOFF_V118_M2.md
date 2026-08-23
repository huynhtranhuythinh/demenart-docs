# 💚 DMA_HANDOFF — V118-M2 · TEACHER ACKNOWLEDGEMENT — "CÔ ĐÃ ĐỌC" — ĐÓNG

**Ngày:** 27/07/2026 (GMT+7) · **Phiên:** Phase A audit (READY FOR PRODUCT CONTRACT LOCK → CTO PASS WITH AMENDMENT) + Phase B implementation + migration VERIFY + rollback-only actor matrix + Owner QA + P1 UX correction + final read-only verification · **Verdict: PASS WITH ONE NON-BLOCKING P2 EVIDENCE GAP — V118-M2 CLOSED**
**Endpoint canonical:** RULES **D336** · SYSTEM_MAP **v1.24** · HANDOFF **V118-M2** (file này — thay V118-M1 làm handoff hiện hành; V118-M1 giữ làm lịch sử)

---

## 0 · BOOT PHIÊN SAU (đọc theo thứ tự)
1. `DMA_HANDOFF_V118_M2.md` (file này) → 2. `DMA_00_START_HERE.md` → 3. `DMA_RULES.md` (tip = **D336**) → 4. `DMA_SYSTEM_MAP.md` (**v1.24**, khối CURRENT CANONICAL ENDPOINT là authority duy nhất về hiện trạng) → 5. Audit live DB (D1 — không tin số trong tài liệu) → 6. `list_edits limit=1` re-pin single-writer (expected tip **`78b75e59`**).

---

## 1 · EXECUTIVE VERDICT

**PASS WITH ONE NON-BLOCKING P2 EVIDENCE GAP — V118-M2 CLOSED.**
Vòng lặp cảm xúc Parent → Teacher → Parent đã khép trọn: PH gửi lời cảm ơn (M1) → đúng GV nhận được lời cảm ơn bấm một chạm xác nhận (M2) → PH thấy "đã đọc". Không có milestone nào nhỏ hơn được nữa, và đó là chủ đích: M2 cố tình từ chối trở thành chat, inbox, reaction framework hay engagement loop.
Một P1 UX (Owner không nhận ra nút) đã sửa trong phiên. Một P2 evidence gap (P2-E1) được ghi nhận tường minh, không chặn.

## 2 · CANONICAL ENDPOINT

- RULES **D336** (append đúng 1 D-rule, không sửa lịch sử D335)
- SYSTEM_MAP **v1.24** (bump từ v1.23; khối endpoint đã thay HEAD/migration/inventory/trạng thái)
- HANDOFF **V118-M2** (file này)
- Accepted frontend tip: **`78b75e59`**
- Registry **119** · latest migration `v118_m2_appreciation_acknowledgement` (`20260727115750`)

## 3 · FINAL PRODUCTION STATE

- **Production:** GitHub `main` → Cloudflare Pages CI → `demenart.com`. `deploy_project` KHÔNG được gọi (production cập nhật gián tiếp qua CI — D309).
- **Frontend tip:** `78b75e59` "Fixed teacher appreciation UI" (17:01:29Z). Không commit/edit nào sau tip; single-writer PASS.
- **Backend:** migration 119 live, `notify pgrst` đã gửi, cả 3 RPC gọi được từ browser thật trong Owner QA (D291 thoả).

## 4 · COMMIT LINEAGE

```
df958fc6   (V118-M1 baseline, "Restored routeTree.gen.ts")
   └→ 56ee2005   V118-M2 implementation — "Updated Appreciation type"
                 · đúng 3 file authorized · 7 hunk byte-exact
   └→ 78b75e59   Owner-QA CTA-affordance correction — "Fixed teacher appreciation UI"
                 · đúng 1 file · 1 hunk · frontend-only · zero DB mutation
```
Cả hai commit `get_diff` verified (D134). **`routeTree.gen.ts` / generated / `package.json` / `bun.lock` / `package-lock.json` zero-diff ở cả hai commit.** ⚠️ Trong `56ee2005`, build agent lại regenerate `routeTree.gen.ts` (lần 3 liên tiếp) nhưng đã `git checkout` restore **trước** khi commit — diff cuối là bằng chứng, không phải narrative của agent.

## 5 · MIGRATION AND INVENTORY

**Migration:** `20260727115750 · v118_m2_appreciation_acknowledgement` — 3-block D92.
- BLOCK 1: `ALTER TABLE ... ADD COLUMN acknowledged_at timestamptz` · `CREATE FUNCTION acknowledge_session_appreciation` · additive replace `get_teacher_appreciations` + `get_parent_session_outcomes`
- BLOCK 2: REVOKE PUBLIC/anon + GRANT authenticated/service_role cho **cả 3** hàm (D15 — `CREATE OR REPLACE` reset grants)
- BLOCK 3: ~23 assertion + `RAISE` rollback guard, gồm impersonation read-only D333 ba persona
- Sau apply: `notify pgrst` (D289)

**Inventory sống (re-verified read-only tại closeout):**

| Chỉ số | Trước (V118-M1) | Sau (V118-M2) | Δ |
|---|---|---|---|
| tables | 89 | **89** | 0 |
| functions | 214 | **215** | +1 |
| SECURITY DEFINER | 203 | **204** | +1 |
| policies | 166 | **166** | 0 |
| triggers | 33 | **33** | 0 |
| cron | 1 | **1** | 0 |
| registry | 118 | **119** | +1 |
| routes | 52 | **52** | 0 |
| Edge Functions | 16 | **16** | 0 |

Delta đúng proposal 100%.

## 6 · EXACT IMPLEMENTATION

**Data:** đúng một cột additive nullable `session_appreciations.acknowledged_at timestamptz` (verified live: `timestamp with time zone`, `is_nullable=YES`). Không bảng mới, không policy mới (bảng vẫn RLS ON + 0 policy = deny-all), không trigger mới (0 trigger trên bảng), authenticated/anon/PUBLIC vẫn **zero table privilege**.

**Writer RPC:** `acknowledge_session_appreciation(p_appreciation_id uuid) returns jsonb` — VOLATILE · SECURITY DEFINER · `search_path=''` · schema-qualified · ACL `{authenticated, postgres, service_role}` (aclexplode verified, 0 PUBLIC/anon).
Flow: `current_profile()` → NULL thì `not_authorized` → role gate mirror `get_teacher_appreciations` (`lead_teacher|assistant_teacher`) → conditional atomic `UPDATE ... WHERE id=$1 AND recipient_teacher_profile_id=v_me AND acknowledged_at IS NULL RETURNING acknowledged_at` → nếu 1 row: audit metadata-only + `{ok, status:'acknowledged', acknowledged_at}` → nếu 0 row: re-select theo `id + recipient=v_me`, có timestamp thì `{ok, status:'already_acknowledged', acknowledged_at}` → mọi nhánh khác: `not_authorized` generic.
Client gửi đúng **1 tham số**; không nhận teacher/child/session/school/recipient/authority-role từ client.

**Teacher projection:** `get_teacher_appreciations` +`acknowledged: boolean`. Signature/role gate/recipient filter/clamp 1–20/sort/8 field cũ nguyên. Không timestamp, không count/unread.

**Parent projection:** `get_parent_session_outcomes` +`acknowledged: boolean` **chỉ trong node `sent`**. `available`/`unavailable`/ownership/eligibility/pagination/`has_more`/moments/denial nguyên; vẫn 1 RPC/child.

**Frontend (3 file):**
- `src/features/parent/appreciation/appreciationModel.ts` — `OutcomeAppreciation` +`acknowledged: boolean`, parse tolerant (`raw.acknowledged === true`, thiếu/sai kiểu → `false`).
- `src/features/parent/session-outcome/ParentSessionOutcomeCard.tsx` — trong nhánh `sent`: `acknowledged=true` → `{tên} đã đọc lời cảm ơn 💚.` (fallback `Giáo viên đã đọc lời cảm ơn 💚.`); `false` → giữ nguyên dòng M1. Không button/timestamp/toast/animation/fetch mới.
- `src/features/teacher/TeacherAppreciationSection.tsx` — parse `acknowledged`; local state keyed by appreciation ID (`ackedIds`/`ackingId`/`ackErrorId`); `rpcUntyped` hiện hữu, đúng 1 RPC/click, chỉ gửi `p_appreciation_id`; disable khi in-flight; cả `acknowledged` lẫn `already_acknowledged` đều flip sang tĩnh; lỗi giữ nguyên thiệp + dòng nhắc nhẹ `aria-live`; không refetch bắt buộc; focus/visibility load pattern cũ giữ nguyên và reconcile boolean từ server; không polling.
**0 file frontend mới.**

## 7 · AUTHORITY PROOF (3 tầng)

1. **Không tồn tại UPDATE path** đổi được `recipient_teacher_profile_id`: grep `pg_proc` — chỉ 4 hàm chạm bảng, không hàm nào update cột M1. Recipient của một row bất biến sau insert.
2. **Proof cấu trúc:** definition của writer có **0 reference tới `session_teacher_assignments`** → về mặt cấu trúc không thể resolve current responsibility. Đây là bằng chứng thay thế cho counterfactual "transfer" khi fixture không có (và đúng chỉ thị: không mutate STA để dựng counterfactual).
3. **Runtime denial:** GV cùng trường (không phải recipient), GV khác trường, Parent, master_admin, super_admin, not-found — tất cả trả **cùng một chuỗi** `not_authorized`.

**Không fallback** sang: current responsible · class lead · `taught_by` · planned Teacher · replacement Teacher · same-school Teacher · school admin · platform admin.
**Không thêm `profiles.state` gate ở M2** (chủ đích): gate phải mirror read RPC, tránh bất đối xứng read/action sinh cửa chết D290. Ghi P2 để CTO quyết riêng nếu muốn state semantics — phải sửa đối xứng cả read lẫn write.

## 8 · PRIVACY PROOF

- Parent nhận thêm **đúng 1 boolean**. Verified live: definition `get_parent_session_outcomes` **không chứa** key `'acknowledged_at'`; payload không có teacher profile ID / assignment ID / school ID / actor ID / audit ID.
- Teacher nhận thêm **đúng 1 boolean**; payload M1 whitelist nguyên, không thêm Parent PII.
- Admin (master/sub/platform) **không có routine surface mới** — cả 2 RPC đọc lẫn writer đều deny.
- Audit `appreciation_acknowledged`: metadata-only `{session_id}` + actor profile (D88) + entity + school. **Không** note body, preset copy, child name, Parent name/email, rendered copy.
- Cả 3 hàm: `search_path=''` verified (3/3), `proacl` non-null, 0 PUBLIC/anon EXECUTE.
- `create_session_appreciation` **zero-diff** (length 5748 bytes không đổi, không chứa chuỗi `acknowledg`).
- **Không** `create_notification` trong bất kỳ hàm nào của M2.

## 9 · SQL QA — ACTOR MATRIX

**14 PASS · 1 SKIP WITH DEFINITION-LEVEL COVERAGE** (rollback-only, raise-with-payload; residue verified sau rollback: 0 acknowledged row · 0 audit row).

| # | Case | Kết quả |
|---|---|---|
| T1 | snapshot recipient ack | `acknowledged`, timestamp set |
| T2 | gọi lại | `already_acknowledged`, **timestamp không đổi** |
| T3 | single transition | đúng **1** audit row |
| T4 | GV cùng trường không phải recipient (gồm class-lead-non-recipient) | `not_authorized` |
| T5 | GV khác trường | `not_authorized` |
| T6 | primary Parent | `not_authorized` |
| T7 | master_admin | `not_authorized` |
| T8 | platform super_admin | `not_authorized` |
| T9 | sub_admin | **SKIP** — fixture không tồn tại (0 profile trong DB sống) |
| T10 | not-found (random uuid) | `not_authorized` — **cùng chuỗi**, không existence oracle |
| T11a–d | authenticated direct SELECT/UPDATE/INSERT/DELETE | `42501 permission denied` cả 4 |
| T12 | Teacher projection sau ack | row1 `true` · row2 `false` · không lộ timestamp |
| T13 | Parent owner projection sau ack | node `{status:'sent', acknowledged:true}`, không `acknowledged_at` |
| T14 | unrelated Parent đọc child khác | `not_authorized` |
| T15 | audit | 1 row, metadata chỉ `{session_id}`, không body/preset/PII |

**Về T9 SKIP:** không chặn vì role gate của RPC chỉ mở cho `lead_teacher|assistant_teacher`; mọi role khác rơi đúng cùng nhánh denial đã prove runtime bằng master_admin/super_admin/parent/teacher-khác. Đây là definition-level coverage, ghi tường minh — **không ghi "15/15 PASS"**.

## 10 · OWNER QA

Owner QA trên production, dữ liệu thật có chủ đích. Xác nhận:
- Teacher Home có 2 appreciation cards (Bức Tường Yêu Thương)
- acknowledgement mutation hoạt động thật
- card chuyển sang trạng thái tĩnh `Đã đọc 💚`
- reload (F5) giữ trạng thái
- Parent PH Hùng thấy: **`Đặng Mỹ Linh đã đọc lời cảm ơn 💚.`**
- không timestamp · không Parent reply CTA · không badge/unread/count/todo/notification
- responsive 479px không overflow, không bị bottom navigation che

## 11 · CTA CORRECTION (P1 — CORRECTED)

**Classification:** `P1 OWNER-QA UX AFFORDANCE — CORRECTED`.
**Triệu chứng:** Owner **không nhận ra** `Cô đã đọc 💚` là nút gửi — tưởng là text trạng thái. Nguyên nhân kép: (a) copy trùng nghĩa với trạng thái sau khi bấm; (b) nền translucent trắng trên thiệp pastel không đủ tương phản để đọc ra affordance.
**Correction commit `78b75e59`** — đúng 1 file, 1 hunk, frontend-only, **zero DB mutation**, zero protected-surface drift:
- label action: **`Gửi xác nhận đã đọc 💚`**
- CTA nền đặc forest `#3D6B4F` + chữ ivory `#FFFDF7` + `shadow-sm`
- hover `#345D45` · pressed/active `#2C503B` · `transition-colors`
- `cursor-pointer` · visible focus (`focusRing` teacher tokens) · disabled `opacity-60 + cursor-not-allowed` · `min-h-11` (44px)
- aria-label: `Gửi xác nhận đã đọc lời cảm ơn của {relation} {child}`
- trạng thái tĩnh giữ nguyên **`Đã đọc 💚`** (plain text, không nền) → phân biệt bằng **hình khối + nội dung chữ + hành vi**, không chỉ bằng màu
- không icon/import/package mới; không redesign thiệp/pastel/ghim/rotate/grid

## 12 · P2-E1 — EVIDENCE GAP (NON-BLOCKING)

> **P2-E1 — Corrected unacknowledged CTA state was not captured in a live production screenshot because both existing appreciation rows had already been acknowledged. Exact one-file diff, build and deployment evidence exist. Non-blocking.**

Bằng chứng thời gian giải thích gap: cả 2 lần acknowledge (16:50:49Z và 16:58:19Z) xảy ra **trước** commit correction `78b75e59` (17:01:29Z). Vì acknowledgement là immutable by design, **không reset** để manufacture evidence — chấp nhận mất ảnh chụp, ghi gap tường minh.
**Không tuyên bố** Owner đã nhìn thấy CTA đã sửa trên production.
Cách đóng gap tự nhiên (không cần hành động đặc biệt): appreciation mới bất kỳ do PH gửi ở phiên sau sẽ hiện CTA bản mới ở trạng thái chưa-ack.

## 13 · PROTECTED ZERO-DIFF LIST (canonical)

`create_session_appreciation` · mọi field M1 của `session_appreciations` ngoài `acknowledged_at` · Session Appreciation Sheet · Parent send hook · appreciation presets · Parent Outcome hook · Parent Outcome section · `parentSessionOutcomeModel` · Teacher mount topology (`teacher.index.tsx`) · Teacher Session V116 · School Today V117-M2 · Parent Journey · Parent Consent · session responsibility D324/D325 · STA · `get_session_detail` · `start_session` · `submit_session_journal` · `is_session_lead` · `get_teacher_todo_counts` · `parent_replies` · notifications · notification types · notification bell · Edge Functions · consent/media signing · shells · routes · route tree · dependencies · lockfiles · analytics/rating/ranking.
Tất cả verified zero-diff qua `get_diff` hai commit + live DB checks.

## 14 · LIVE DATA STATE (read-only verified tại closeout — KHÔNG SỬA)

| Row | Sender | Bé | Recipient | acknowledged | acknowledged_at |
|---|---|---|---|---|---|
| `f0192945…` | PH Hùng | An | Đặng Mỹ Linh | ✅ | 2026-07-27 **16:58:19Z** |
| `48a8b21d…` | PH Toản | Bình | Đặng Mỹ Linh | ✅ | 2026-07-27 **16:50:49Z** |

- Tổng: **2 appreciation rows · 2/2 acknowledged**
- Audit: **2 rows** action `appreciation_acknowledged`, actor cả 2 = profile GV Đặng Mỹ Linh (`d1000000-…-011`), entity_type `session_appreciation`, metadata **chỉ** `{session_id}` — không note/preset/PII
- ⚠️ **Khác với mô tả "An giữ làm control"** trong prompt correction: tại thời điểm verification, **An đã được acknowledge lúc 16:58:19Z** (trước commit correction). Báo đúng sự thật, **không tự sửa, không reset** — đây chính là nguyên nhân của P2-E1.
- Zero mutation production ngoài 2 acknowledgement do chính Owner thực hiện.

## 15 · P2/P3 CARRY

**P2 mới:**
- **P2-E1** — evidence gap CTA corrected (mục 12), non-blocking, tự đóng khi có appreciation mới.
- **P2-STATE** — `profiles.state` không được enforce ở bất kỳ RPC appreciation nào (kế thừa M1; live chỉ có `'active'`). Nếu CTO muốn state semantics phải sửa **đối xứng** read + write, mở việc riêng.

**P2 carry nguyên:** secondary-parent fixture chung child (constraint-level đã prove, runtime chưa) · 768px nav shell · nav lạc `/teacher/profile` · sticky-CTA-bàn-phím · day-state semantics v2.

**P3:**
- Agent build regenerate generated-file **lần 3 liên tiếp** (`56ee2005` — đã chặn trước commit). **Quy trình cứng giữ nguyên: mọi `get_diff` phải soi mục `routeTree.gen.ts`/generated trước khi chấp nhận. Không tin narrative của agent (D329).**
- Chrome MCP không kết nối **phiên thứ 3 liên tiếp** → mọi runtime browser QA phải do Owner tự làm. Cân nhắc kiểm tra lại extension.
- Supabase MCP connector chập chờn (nhiều lần "server isn't responding" giữa phiên closeout, tự hồi phục sau retry) — transport error, không phải state change; luôn retry rồi mới kết luận.
- `notifications` table grant rộng hơn cần (RLS che — hygiene note từ V118-M1 Phase A).

## 16 · VIỆC JEAN CẦN LÀM TAY

1. Upload 3 file thay thế vào project knowledge:
   - `DMA_RULES.md` (tip **D336**, 832.284 bytes — bản gốc 823.228 + append D336)
   - `DMA_SYSTEM_MAP.md` (**v1.24**, 450.027 bytes — bản gốc 449.159 + patch endpoint block)
   - `DMA_HANDOFF_V118_M2.md` (file này)

## 17 · SPRINT KẾ — CANDIDATES (chưa mở, chờ CTO)

A. **V117-M3** — Parent outcome mở rộng (list nhiều buổi; `has_more` đã sẵn trong payload).
B. **G.4+ restyle** (consent/settings/kid surfaces).
C. **V114-SEC1** (classroom/remote + `useSessionChannel`).
D. **FMN E2E fixture session** (cần Jean authorize mutation tường minh).
E. **Day-state semantics v2**.
F. **Secondary-parent fixture bổ sung** (đóng gap P2 runtime khi tiện).

---

*Không mở milestone tiếp theo trong cùng phiên. Chờ CTO/Owner quyết sprint kế.*
