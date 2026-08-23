# 🤝 DMA_HANDOFF_v6.md — BÀN GIAO PHIÊN (sau cụm Privacy/Consent)

> **Cách dùng:** File này = ảnh chụp trạng thái cuối phiên v6. Boot phiên sau:
> `00_START_HERE` → `RULES` → file này. Rồi audit DB thật cụm kế (D1) trước khi viết SQL.
> **Naming:** DMA = nền tảng; CTAN = sản phẩm đầu. Không "DMMA".

---

## 1. LÀM GÌ PHIÊN NÀY

- **Hoàn tất cụm RLS Privacy/Consent** (cụm thứ 5/8): `consents` · `privacy_requests` · `share_links`.
- **mig 020** (`020_privacy_consent_rls.sql`) — 9 policy, idempotent, KHÔNG helper mới.
- **seed_005** (`seed_005_privacy_consent.sql`) — 4 consent bé Jenny + 1 privacy_request.
- **Panel `/portal/rls-test`** thêm section "Quyền riêng tư (Consents)".
- **Nghiệm thu login thật 4 vai trò → xanh tuyệt đối** (xem §3).
- Lock thư viện: SYSTEM_MAP v0.7 · RULES +D55.

---

## 2. TRẠNG THÁI THẬT CUỐI PHIÊN

- **DB:** 44 bảng · **26 hàm SECURITY DEFINER** (không đổi) · 1 non-definer (`is_school_admin`) · **95 RLS policy** · mig **001→020** · seed **001→005**.
- **RLS xong 5/8 cụm** (đều login thật): Org/People · Curriculum · Sessions · Journey · **Privacy/Consent**.
- **~23 bảng còn khóa kín** (deny-by-default, chưa policy): **Business/License · Moments · Ops · Media**.
- **App:** `/portal/rls-test` panel 8 mục chạy thật với 4 user.

---

## 3. NGHIỆM THU v6 — MA TRẬN (login thật)

| Login (role) | consents | privacy_requests | share_links | Nút "Thử thêm consent" |
|---|---|---|---|---|
| `info@` (super_admin) | **0** (D48) | **1** (carve-out 2A) | 0 | "Không có child_id — đúng vai admin" |
| `master.demo` (master_admin) | 5 | **1** | 0 | 🟢 RLS chặn ghi (Fork 1A) |
| `teacher.demo` (lead_teacher) | 5 | **0** | 0 | 🟢 RLS chặn ghi |
| `parent.demo` (parent) | 4→5 | 1 | 0 | 🔵 Ghi THÀNH CÔNG (PH làm chủ) |

**2 bằng chứng vàng:**
1. `teacher.demo` privacy_requests **0** vs `master.demo` **1** → nhánh `is_school_admin()` đứng vững.
2. admin consents **0** nhưng privacy_requests **1** → carve-out 2A đúng thiết kế (controller cầm hồ sơ tuân thủ, không soi PII consent).

> Lưu ý: parent ghi consent THÀNH CÔNG **chèn 1 row thật** (`source='WRITE-BLOCK TEST (panel)'`) → consents 4→5. Row test cần dọn (§4).

---

## 4. VIỆC TREO (dọn trước khi seed cụm chạm trẻ kế tiếp)

Row test do các nút write-block để lại (3 cụm). Chạy 1 lần khi rảnh:

```sql
delete from public.child_observations where note like 'WRITE-BLOCK TEST%';
delete from public.child_journey      where entry_type = 'WRITE-BLOCK TEST (panel)';
delete from public.consents           where source = 'WRITE-BLOCK TEST (panel)';
-- verify
select
  (select count(*) from public.child_observations where note like 'WRITE-BLOCK TEST%') as obs_left,
  (select count(*) from public.child_journey where entry_type = 'WRITE-BLOCK TEST (panel)') as journey_left,
  (select count(*) from public.consents where source = 'WRITE-BLOCK TEST (panel)') as consent_left;
-- kỳ vọng: 0 · 0 · 0  (consents về lại 4)
```

---

## 5. NGÃ KẾ (chọn đầu phiên sau)

Còn **3 cụm RLS** + Media (gộp Edge). Theo độ độc lập:

- **A. Business/License** (D51) — `school_subscriptions` · `school_subject_entitlements` · `pricing_config`. Gate `has_active_seat` / `has_subject_entitlement` (helper đã có từ mig 008). Cơ học, ít bẫy. **Ứng viên mạnh kế tiếp.**
- **B. Moments** — `learning_moments` · `moment_children` · `albums` · `media_assets`/`media_variants`/`session_media` (phần RLS mỏng; MIN-consent + signed-URL = Edge). Chạm trẻ → cẩn thận D48; nên dọn §4 trước.
- **C. Ops** — `notifications` · `support_requests` · `audit_logs` · `admin_modules`/`groups`. Phần lớn self-scoped + admin.
- **D. UI Chặng 2** — rời panel-test sang màn vận hành thật (CRUD qua RPC).

Mọi ngã bắt đầu bằng **audit DB thật cụm đó (D1)** trước khi viết SQL.

---

## 6. KỶ LUẬT GIỮ NGUYÊN (nhắc nhanh)

- Schema do migration sở hữu — Lovable KHÔNG sinh/sửa SQL. KHÔNG "Try to fix all" security scanner.
- `auth.uid()` NULL trong SQL Editor → nghiệm thu bằng **login thật** (D2).
- Mig idempotent (drop-if-exists). Seed idempotent (NOT EXISTS). Seed cụm-không-guard không cần `replica` (D30).
- SQL Editor trả statement cuối → đặt 1 `select jsonb_pretty(...)` verify ở cuối (D4).
- Hàm definer mới → re-verify + revoke EXECUTE public/anon (D15). *(Phiên v6 không có hàm mới.)*
- Engine consent `min(trường,PH)` = **Edge Function**, không RLS (D47/D55).

---

*Handoff v6 — 2026-06-25. Cụm Privacy/Consent XONG (mig 020 + seed 005, 95 policy). 5/8 cụm RLS hoàn tất. Nguồn: A–G UPDATED + RULES v6 + SYSTEM_MAP v0.7.*
