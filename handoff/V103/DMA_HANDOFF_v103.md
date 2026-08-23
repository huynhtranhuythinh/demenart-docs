# 📦 DMA_HANDOFF_v103.md — V103 PARENT PILOT ACCESS & ONBOARDING (12/07/2026)

## 1. Canonical endpoint (đọc cùng RULES + SYSTEM_MAP)
RULES **D263** · SYSTEM_MAP **v0.96** · Handoff **v103**

**Inventory: 74/136/160/1 → 75/143/160/1** (tables / SECURITY DEFINER / policies / cron)
`+1` bảng `parent_invitations` · `+7` definer · **policy KHÔNG đổi** (bảng deny-all, 0 policy) · `+1` unique partial index `profiles_user_id_uq` · `+1` Edge `accept_parent_invitation` · Edge `invite_parent` **retired 410**.
Registry: `admin_modules` 74→**75** · `route_registry` 46→**47**.

**Baseline live (đo qua RPC phụ huynh, không giả định):**
- An: **6 Tác phẩm · 2 Âm thanh · 6 Khoảnh khắc · 5 Ba mẹ lưu lại**
- Evidence: **24 events · 18 groups** · **DC9 / OBS9 / PART6**
- Readiness: **v2 · emerging · contemporaneous** · general `current_3m failed = [too_short_duration, insufficient_longitudinal_spread]`
- `product_events` **9** · consents granted **34** · `parent_invitations` **0 row** · dup `user_id` **0**

> ⚠️ v102 ghi An `+4` và evidence `23/17 · OBS8`. Live là `+5` và `24/18 · OBS9`. **Explained drift, không regression:** cùng một nguyên nhân — record human-QA V102 (`Khoảnh khắc đáng yêu`, photo_moment, 12/07 15:26:34, PH Hùng). §1 của v102 chốt số **trước** QA, §8 ghi QA có tạo thật.

---

## 2. V103 làm gì

V102 dựng **giác quan**. V103 mở **cánh cửa**.

Trước V103, con đường duy nhất để một phụ huynh có tài khoản là: nhà trường bấm "Mời" → hệ thống sinh **mật khẩu tạm** → hiện nó **cho nhà trường** → trường đọc lại cho phụ huynh. Và **không có UI đổi mật khẩu ở bất kỳ cổng nào**.

Nghĩa là hiệu trưởng **vĩnh viễn** đăng nhập được với tư cách phụ huynh, đọc nhật ký riêng của gia đình, kỷ vật ba mẹ lưu, và "Câu chuyện quanh kỷ vật" (V93).

**DMA đang nói rằng nhật ký thuộc về gia đình, và không thực thi được điều đó.** V103 tồn tại để đóng khoảng cách giữa lời nói và cơ chế.

---

## 3. V103-A — Audit (không code) · 3 phát hiện P0

**KHÔNG TỒN TẠI hệ thống invitation nào.** Quét 74 bảng: 0 bảng invitations · 0 invite token · 0 access code · 0 signup token. (`kid_pairing_codes` thuộc domain Kid PIN — và đáng chú ý: nó lưu `code` **thô**, không hash. Không copy pattern đó.)

| # | P0 | |
|---|---|---|
| ① | **Trường biết mật khẩu PH, vĩnh viễn** | mật khẩu tạm hiện cho operator · 0 UI đổi mật khẩu · 0 self-service reset |
| ② | **S3 (PH nhiều con) VỠ CÂM** | `provision_parent_and_link` **luôn INSERT profile mới** + `profiles.user_id` **không unique** + `current_profile()` = `... where user_id=auth.uid() **limit 1**` **không ORDER BY** ⇒ 2 profile cùng 1 `user_id` ⇒ PH **thấy ngẫu nhiên một đứa con**, không lỗi, không cảnh báo |
| ③ | **`/auth` nói dối** | nút "Tôi có mã mời" → modal → bấm "Tiếp tục" → **không làm gì** |

**Vì sao ② chưa nổ:** live sạch **chỉ vì** 3 PH-2-con được seed thẳng bằng SQL, chưa từng đi qua đường app. *Cái bẫy chưa sập vì chưa có ai thật bước vào.*

---

## 4. ⚠️ Sự cố giữa phiên — CONCURRENT BUILDER

Giữa lúc audit, inventory nhảy **74/136 → 75/143** *ngay trong phiên*. Một phiên khác **đã build xong V103** (migration `v103` + `v103b`, 7 RPC, Edge, `/invite`, và đã chạy QA live 15:59–16:03).

⇒ **STOP đúng stop-condition #12.** Không apply đè, không deploy đè, không push commit đè. Surface cho CTO.

**CTO quyết:** chuyển phiên này thành **AUDITOR ĐỘC LẬP** — con mắt thứ hai chưa từng nhìn thấy code đó. (Đúng bài học V102 #7: thứ bắt được lỗi P0 không phải typecheck, không phải test suite, mà là một con mắt độc lập.)

---

## 5. Audit độc lập — cái KHÔNG thủng

Em đi tìm lỗ ở đúng những chỗ hay thủng, và **không thấy**:

| Chỗ nghi | Sự thật |
|---|---|
| Token lưu raw? | **Không.** Cột `token_hash` CHECK `^[0-9a-f]{64}$`, không có cột raw. 256-bit entropy. |
| Token rò qua URL? | **Không.** Fragment `#t=` (không tới web server) + `history.replaceState` xoá khỏi thanh địa chỉ. |
| Edge lấy email từ client? | **Không.** `p_email` lấy từ **`peek` (DB)**. Binding email không bypass được. |
| Wrapper lấy email từ `profiles`? | **Không.** Lấy từ **`auth.users`**. (Nếu lấy từ `profiles`, trường chỉ cần sửa email là chiếm tài khoản.) |
| `authenticated` còn sót TRUNCATE? | **Không.** Grant bảng chỉ `postgres`+`service_role`. (Bẫy V102 đã được học.) |
| Cửa hậu mật-khẩu-tạm còn sống? | **Không.** `invite_parent` **retire → 410**, chết cả khi `fetch` thẳng bằng JWT master né UI. |
| Enumeration? | **Không.** not-found và wrong-school **cùng** `not_authorized`; token sai-format và không-tồn-tại **cùng** `invalid_invitation`. |

---

## 6. 🔴 P0 tìm ra — CROSS-TENANT PLACEHOLDER ABSORPTION (D262)

`_accept_parent_invitation_core` reuse placeholder profile **chỉ theo email**, không scope theo `child_id`/`school_id`.

**Chuỗi khai thác:** master trường B tạo bé trong trường mình → mint lời mời tới email của một placeholder **trường A** (họ **giữ raw token** — họ là operator) → tự mở `/invite`, tự đặt mật khẩu → Edge `createUser` → core bind auth user đó vào **profile của trường A** (đang mang link tới trẻ trường A) → **đọc được nhật ký, ảnh, kỷ vật, câu chuyện của một gia đình ở trường khác.**

Bản không-ác-ý cũng đủ chết: **một cú gõ nhầm email.**

**Live lúc phát hiện: 9 placeholder "đạn sống"** (PH chưa login, có email, đã gắn bé), trải trên cả hai trường. Chứng minh read-only bằng **chính câu SELECT của hàm** trên live data: lời mời MNDM + email placeholder KHM → trả về profile `d1…053` (Lê Thị Hạnh, KHM) mang bé **Lê Bảo Chi**.

**Hotfix `v103c`** (CREATE OR REPLACE ×2, D92 3-block, VERIFY chặn drift):
- `_accept_parent_invitation_core`: placeholder chỉ được kích hoạt nếu **đã gắn ĐÚNG bé của lời mời** (`join child_parents on cp.child_id = v_inv.child_id`).
- `provision_parent_and_link`: chỉ reuse profile mà **mọi** con hiện có đều thuộc **trường của caller** (derive qua `child_parents → enrollments → classes.school_id`, vì PH có `school_id = NULL` — D40).

---

## 7. 🔴 P0 thứ hai — chỉ Edge live mới lộ (D263)

DB-side T17-C của em **PASS giả**: em chọn nhánh fail là `invitation_revoked` — nhánh đó `return` **trước** khi ghi.

Jean bấm thật trên production `/invite` (bé đã đủ 2 PH, lời mời mint từ khi bé còn 0 PH ⇒ `peek` pass ⇒ Edge **createUser** ⇒ core fail `max_parents_reached`):

| Kiểm chứng | 18:39:57 (trước `v103d`) |
|---|---|
| `parent_invitation_failed{stage:db_accept}` ⇒ **createUser đã chạy** | ✅ |
| `auth.users` = 0 ⇒ **deleteUser đã dọn** | ✅ |
| **`profiles`** | **1** 🔴 orphan |
| **FK treo** (`user_id` trỏ auth user đã chết) | **1** 🔴 |

**Root cause:** cổng `max_parents_reached` đặt **SAU** `INSERT profiles`. **`return` trong plpgsql KHÔNG rollback.** Rồi Edge compensating-delete auth user → FK `ON DELETE SET NULL` bị **trigger guard `trg_guard_profiles_protected` (BEFORE UPDATE) NUỐT** (D89 tái xuất) ⇒ `user_id` không được dọn theo.

⇒ Hệ thống **tự đẻ thêm đúng loại "placeholder-đạn" mà `v103c` vừa đi tháo**, mỗi lần một PH bấm nhầm lời mời của bé đã đủ 2 người thân.

**Hotfix `v103d`:** cấu trúc lại thành **PHASE 1 resolve (read-only) → PHASE 2 mọi cổng từ chối → PHASE 3 mutate**; `accept_conflict` đổi từ `return` sang `raise` (rollback khi thua race). VERIFY block kiểm **vị trí trong source**: `max_parents_reached` phải đứng **trước** `insert into public.profiles`.

**Jean bắn lại cùng link (18:45:31):**

| | Kết quả |
|---|---|
| `parent_invitation_failed` +1 ⇒ createUser vẫn chạy | ✅ |
| `auth.users` cho QA email | **0** ✅ (tổng về đúng 12) |
| **`profiles`** | **0** ✅ |
| `child_parents` / `consents` / invite | 2 / 0 / **vẫn pending** ✅ |
| **FK treo** | **0** ✅ |

# ⇒ T17-C PASS — live, qua Edge thật.

---

## 8. QA matrix — kết quả cuối

| Test | Kết quả |
|---|---|
| **X1** cross-school collision | 🟢 PASS **ở tầng authorization**: `is_child_parent(bé trường A) = false` · `get_child_journal(bé trường A)` **raise `not_authorized`** · placeholder KHM vẫn `user_id IS NULL` |
| **X2** same-child placeholder reuse | 🟢 PASS — reuse đúng placeholder, 1 profile, 0 trùng |
| T4 token rác | 🟢 PASS — 4 biến thể → cùng `invalid_invitation` |
| T9/S2 · T10/S3 | 🟢 PASS — 1 auth user · **1 profile** · 2 con |
| T11/S4 · T12 | 🟢 PASS — 2 PH/1 bé; PH thứ 3 chặn **cả ở mint lẫn ở accept** |
| T13/S6 | 🟢 PASS — `email_mismatch`, không attach, không override |
| T14 · T15 · T16 | 🟢 PASS — `authenticated` SELECT thẳng → **`42501`** (bắt được live) · 0 anon/PUBLIC |
| T17-A/B/D | 🟢 PASS — retry cùng user → `already_accepted`; khác user → `already_used`; `already_linked` chặn tại mint |
| **T17-C** | 🟢 **PASS** (sau `v103d`) |
| T18 modal giả | 🟢 PASS — đã gỡ sạch |

**QA cleanup:** residue **0 tuyệt đối** (invites/auth/profiles/links/children/enrollments/consents). Audit rows **giữ** (append-only D247), metadata chỉ có `expires_at`/`new_account`/`stage`/`reason` — **0 token · 0 email · 0 password**.

---

## 9. Nợ có chủ đích

- 🟠 **P1 — operator self-invite.** Ai mint được lời mời thì mint được cho email của chính mình. **KHÔNG chặn ở V103**: đây là governance debt, bị giới hạn bởi max-2-parents, và **được audit đầy đủ**. *"Operator self-invite is not prohibited in V103; it remains visible in audit logs and subject to school/operator governance."*
- 🟡 **P2** — `provision_parent_and_link` vẫn sinh placeholder mang email. Sau D262, email **không còn là authority** ⇒ inert. Cleanup debt.
- 🟡 **P3** — copy `/auth` lệch số hotline · **chưa có UI đổi mật khẩu ở `/parent/settings`** · dialog mời GV còn nhắc "Quên mật khẩu" chưa tồn tại.
- 🟡 **Password reset — defer có chủ đích.** Pilot đi đường hotline. Không mở SMTP/magic-link/OAuth/self-service reset.
- 🔴 **Jean tự xác nhận Supabase Dashboard:** *Allow new users to sign up* nên **OFF** (Model B không cần public signup).
- 🟠 **Repo:** `v103` · `v103b` · `v103c` · `v103d` · `v103e` + Edge `accept_parent_invitation` + `invite_parent` (410) + `/invite` + `ParentsPanel` — **chưa lưu repo** (D90).
- Nợ V95–V102 giữ nguyên.

---

## 10. Trạng thái

# V103 — PARENT PILOT ACCESS: **CLOSED** · **READY TO INVITE FIRST REAL PARENT**

---

## 11. Bài học phiên này

1. **Một cánh cửa mở có chủ đích trông y hệt một cánh cửa bị quên.** Mật khẩu tạm hiện cho nhà trường trông như tiện ích vận hành. Thực ra nó là cái lỗ duy nhất đủ lớn để nuốt trọn linh hồn sản phẩm.

2. **`return` không phải `rollback`.** Ba chữ này tốn của chúng ta hai vòng hotfix. Trong plpgsql, một hàm "từ chối" vẫn để lại nguyên những gì nó đã ghi. Mọi cổng từ chối phải đứng **trước** lệnh ghi đầu tiên — không phải vì đẹp, mà vì nếu không thì **lời từ chối vẫn sinh ra dữ liệu**.

3. **Test DB không thay được test Edge.** T17-C của em PASS ở tầng DB — vì em vô tình chọn đúng cái nhánh fail **trước** khi ghi. Đường thật fail **sau** khi ghi. Không một câu SQL nào của em lộ ra điều đó. **Một cú bấm thật của Jean lộ ra trong 3 giây.**

4. **Bằng chứng phải ở tầng authorization, không phải tầng đếm row.** "Không thấy row lạ" là chưa đủ. Chỉ khi `is_child_parent()` trả `false` và `get_child_journal()` **raise `not_authorized`** thì mới biết engine **thật sự** từ chối.

5. **Hai builder trên một production DB là thảm hoạ.** Inventory nhảy giữa phiên là tín hiệu duy nhất. Nếu em không đo lại live mà tin vào con số đã đọc lúc boot, em đã apply đè lên công trình của phiên kia.

6. **Con mắt độc lập là thứ đắt nhất và rẻ nhất.** Phiên kia build V103 rất tốt — token hash, fragment, retire cửa hậu, gate email từ `auth.users`. Nhưng nó không thấy được hai lỗ của chính nó. Không phải vì kém. Vì **không ai kiểm được điểm mù của chính mình**.

7. **Hệ thống có thể tự đẻ ra chính thứ nó vừa đi vá.** `v103c` tháo 9 quả đạn placeholder. `v103d` phát hiện hệ thống đang **sản xuất thêm đạn mới** ở mỗi lời mời thất bại. Vá một lỗ mà không hỏi *"cái gì đang tạo ra lỗ này?"* là vá tạm.
