# DMA_HANDOFF — V114B-E3 · WP4-S3A · SESSION RESPONSIBILITY AUTHORITY CUTOVER (CLOSEOUT)

> **Canonical endpoint sau closeout:** RULES **D324** · SYSTEM_MAP **v1.16** · HANDOFF **V114B-E3-WP4-S3A**.
> **Trạng thái:** WP4-S3A **SEALED — AUTHORITY CUTOVER APPLIED**. Kế: **S4** (frontend/product-surface alignment) — CHƯA mở, chưa được authorize bởi closeout này.
> **Bản chất run này:** DOCUMENTATION-ONLY. Không DB/frontend/migration/deploy change; không rerun QA; không đổi `lead_teacher_id`.

---

## 1. Cutover đã làm gì (what changed)

Migration **114** — `v114b_e3_wp4_s3_authority_cutover` (`20260724092921`) — REPLACE 3 SECURITY DEFINER RPC, cutover quyền hành động session-scoped từ **class lead hiện tại** sang **session responsibility hiện hành**. Không thêm/bớt bảng, cột, policy, trigger, Edge, route; frontend không đổi.

- **`submit_session_journal(uuid,text,text)`** — `search_path=''` — gate 6 bước, KHÔNG fallback (planned/taught_by/lead/admin). md5 `29623e1c21a47f2edabb5cc9243ec429`.
- **`start_session(uuid)`** — `search_path=''` — responsibility birth-path (`runtime_start_session`, `assigned_by=current_profile()`), audit `session_started` coupled/blocking. md5 `48e62a76ffe1ecb2c70b5ffddaf59984`.
- **`get_session_detail(uuid)`** — `search_path=public` — thêm `can_submit_journal`·`submit_block_reason`·`responsible_teacher`, gương authority của submit. md5 `91a08743af57e9d071d5b8b2fab3b2d5`.
- **`is_session_lead(uuid)`** — KHÔNG đổi, byte-nguyên md5 `8b4f91dda7e45a3c2c801e70579f702d`.

## 2. Cái gì bây giờ authoritative (D324)

*"Session responsibility is the authority source for session-scoped teacher actions. Current class lead is not retrospective authority for historical sessions."* — xem RULES **D324** cho đặc tả gate đầy đủ (không fallback; birth-path; capability parity; owner_attested ≠ db_proven).

## 3. Cái gì còn dở có chủ đích (intentionally incomplete)

- Frontend vẫn suy affordance journal từ **legacy lead state** → S4 sẽ thay bằng server capability.
- `session_reports` **CHƯA** nằm trong responsibility containment.
- Responsibility-transfer RPC **vắng** (chưa authorize).

## 4. Skew-window restriction (ACTIVE)

**🔒 S3→S4 skew window MỞ: 2026-07-24 16:29:21 ICT.** Từ mốc này tới khi S4 deploy production: **CẤM đổi `class_distributions.lead_teacher_id`.** Lý do: frontend còn đọc lead cũ; đổi lead khi chưa cutover UI sẽ tạo lệch authority hiển thị ↔ server.

## 5. Rollback posture

Rollback S3 function (nếu Layer B/authority probe hỏng sau apply — KHÔNG kích hoạt, mọi gate xanh): restore 3 định nghĩa pre-S3 theo md5 `8fc9ace1eafb13d28bcf61dc83e8e27d` (submit) · `9307a5d92ed07707963bad2f62d512f8` (start) · `7f83cfce2c3e71755375efc6070924a2` (detail) + ACL; **KHÔNG** roll back S1/S2; verify pre-S3 md5 + STA/audit/business unchanged. Không auto second apply.

## 6. Current-state anchors (đo LIVE, không tin trí nhớ)

| Nhóm | Giá trị |
|---|---|
| Migration | version `20260724092921` · name `v114b_e3_wp4_s3_authority_cutover` · prev registry 113 → **114** |
| Inventory | **88 tables · 210 functions · 199 SECURITY DEFINER · 166 policies · 33 triggers** · 1 cron · routes 52 · 16 Edge |
| STA | total 13 · planned 9 · responsible 4 · current responsible 4 · runtime residue (post-QA) 0 |
| S2 evidence | db_proven 3 · owner_attested 1 |
| Audit anchors | `session_responsibility_backfilled` 4 · malformed historical `session_started` 3 · baseline observed 11056 |
| Frontend HEAD | `d8178a55` (KHÔNG đổi — backend-only) |
| Skew window | opened **2026-07-24 16:29:21 ICT** · open tới S4 deploy · `lead_teacher_id` freeze |

**Authority proof (lead-change counterfactual, rollback-only):**
- Lê Thảo My: `is_session_lead=true` · `is_session_responsible=false` · submit = **forbidden**
- Đặng Mỹ Linh: `is_session_lead=false` · `is_session_responsible=true` · submit = **allowed/idempotent**

Đây là bằng chứng quyết định: authority theo responsibility, KHÔNG theo current class lead.

**QA (rollback-only, Q01–Q15):** Q01 responsible allowed · Q02 same-school non-resp forbidden · Q03 same-school admin forbidden · Q04 cross-school teacher+admin forbidden · Q05 parent forbidden · Q06 session_not_found · Q07 no_responsible_assignment · Q08 responsible+scheduled bad_state · Q09 owner_attested detail · Q10 counterfactual (4 predicate) · Q11 first-start 1 responsibility + 1 valid audit · Q12 second-start no duplicate · Q13 submit-after-start (responsible allowed / other forbidden) · Q14 capability/command parity 100% · Q15 zero residue. Layer B PASS ×2.

## 7. S4 entry contract (next milestone)

S4 = **frontend & product-surface alignment**. S4 phải:
- Thay affordance submit-journal legacy-lead bằng **server capability**.
- Consume `can_submit_journal` · `submit_block_reason` · `responsible_teacher`.
- KHÔNG cho UI tự suy authority từ class lead; server là nguồn sự thật.
- Test **explicit** S3→S4 skew window.
- Deploy **trước** khi cho phép bất kỳ mutation `lead_teacher_id`.
- KHÔNG mở rộng responsibility-transfer trừ khi authorize riêng.
- KHÔNG containment `session_reports` trừ khi authorize riêng.

**S4 chưa được authorize bởi closeout này.**

## 8. Residual risks (retain — KHÔNG đóng)

1. Frontend còn suy một số journal affordance từ legacy lead state tới S4.
2. `session_reports` ngoài responsibility containment mới.
3. Responsibility-transfer RPC vắng.
4. **E3-SG-01 OPEN.**
5. **E3-SG-02 CONTAINED** (authenticated/anon user-JWT path).
6. **R21 ACTIVE.**
7. `pg_default_acl` debt chưa giải quyết.
8. sub_admin persona QA debt.
9. Vũ Hoàng Nam auth-persona debt.
10. Trần Khánh Vy auth-persona debt.

## 9. Ghi chú thực thi md5/serialization (implementation evidence — KHÔNG phải D-rule)

Artifact canonical được regen từ byte-exact `pg_get_functiondef` của các body compact đã rehearse (round-trippable). md5 pinned: submit `29623e1c…` (khớp accepted), start `48e62a76…` (khớp accepted), **detail `91a08743…`** (re-pinned). Giá trị abbreviated/historical `37a3b4a1…` ghi trong rehearsal report đầu tiên là body compact có bytes **không khôi phục được sau rollback**; body detail canonical hiện tại là whitespace-variant **semantic-identical**, đã re-rehearse đầy đủ (mọi nhánh capability/parity). Chi tiết whitespace/serialization/md5 này CHỈ là implementation evidence (ghi ở HANDOFF + BUILD_PATH), **KHÔNG được nâng thành D-rule** (theo CTO S3A).

## 10. Lineage E3 & canonical note

Track V114B-E3 (WP1→WP4) dùng D-rule *candidate* (D310–D323-cand + D-A2-1) sống trong file closeout WP tương ứng; chỉ **E3 milestone closeout** (sau S4) mới canonicalize. S3A nâng **một** quyết định governance bền vững → **D324** (RULES). SYSTEM_MAP endpoint block cập nhật lên **v1.16** (registry 114, authority surface, skew window). BUILD_PATH ghi S3A sealed + S4 entry contract.

---

**FINAL: ✅ V114B-E3-WP4-S3A — DOCUMENTATION CLOSEOUT · READY TO OPEN S4.**
