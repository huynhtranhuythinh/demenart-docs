# 🤝 DMA_HANDOFF_v7.md — BÀN GIAO PHIÊN (sau cụm Business/License)

> **Cách dùng:** File này = ảnh chụp trạng thái cuối phiên v7. Boot phiên sau:
> `00_START_HERE` → `RULES` → file này. Rồi audit DB thật cụm kế (D1) trước khi viết SQL.
> **Naming:** DMA = nền tảng; CTAN = sản phẩm đầu. Không "DMMA".

---

## 1. LÀM GÌ PHIÊN NÀY

- **Hoàn tất cụm RLS Business/License** (cụm thứ 6/8): `pricing_config` · `school_subscriptions` · `school_subject_entitlements`.
- **mig 021** (`021_rls_business_license.sql`) — 9 policy, idempotent, **KHÔNG helper mới**.
- **seed_006** (`seed_006_business_license.sql`) — pricing 4 key + 1 subscription active (4 seat, 12tr) + 2 entitlement (CTAN+Ballet). Công thức D51 verify khớp 12.000.000đ.
- **Panel `/portal/rls-test`** thêm section "License (Giấy phép)" (3 count card + 1 nút write-block).
- **Nghiệm thu login thật 4 vai trò → 3 bằng chứng vàng** (xem §3).
- Lock thư viện: SYSTEM_MAP v0.8 · RULES +D56.

---

## 2. TRẠNG THÁI THẬT CUỐI PHIÊN

- **DB:** 44 bảng · **26 hàm SECURITY DEFINER** (không đổi) · 1 non-definer (`is_school_admin`) · **104 RLS policy** · mig **001→021** · seed **001→006**.
- **RLS xong 6/8 cụm** (đều login thật): Org/People · Curriculum · Sessions · Journey · Privacy/Consent · **Business/License**.
- **~20 bảng còn khóa kín** (deny-by-default, chưa policy): **Moments · Ops · Media**.
- **App:** `/portal/rls-test` panel 8 mục chạy thật với 4 user.

---

## 3. NGHIỆM THU v7 — MA TRẬN (login thật)

| Login (role) | pricing_config | school_subscriptions | school_subject_entitlements | Nút "Thử thêm subscription" |
|---|---|---|---|---|
| `info@` (super_admin) | 4 | **1** | 2 | (chưa bấm — không cần; admin write success sẽ đẻ row) |
| `master.demo` (master_admin) | 4 | **1** | 2 | 🟢 RLS chặn ghi (D51 trường-không-tự-cấp) |
| `teacher.demo` (lead_teacher) | 4 | **0** | 2 | (chưa bấm) |
| `parent.demo` (parent) | **0** | **0** | **0** | (chưa bấm; no school_id) |

**3 bằng chứng vàng:**
1. `teacher` subscriptions **0** vs `master` **1** → nhánh tài chính `is_school_admin()` **che số tiền hợp đồng khỏi GV** (tách-quyền-đọc-ở-tầng-bảng, kỹ thuật D52). GV vẫn thấy pricing (4) + môn được cấp (2).
2. `parent` **0 cả 3 bảng** (no `school_id`) → PH ngoài cuộc B2B; convention `current_school_id() IS NOT NULL` load-bearing.
3. `master` bấm thêm subscription → DB chặn "new row violates row-level security policy for table `school_subscriptions`" → **D51 trường-không-tự-cấp-license** sống ở tầng WRITE.

> Lưu ý: nút write-block CHỈ đẻ row khi **admin** bấm (`payment_status='WRITE-BLOCK TEST (panel)'`). Phiên này master/teacher/parent đều bị chặn nên **KHÔNG phát sinh row rác mới** ở cụm này.

---

## 4. VIỆC TREO (dọn trước khi seed cụm chạm trẻ kế tiếp)

Row test do các nút write-block để lại (3 cụm cũ — Sessions/Journey/Privacy). License KHÔNG thêm row (master bị chặn). Chạy 1 lần khi rảnh:

```sql
delete from public.child_observations  where note like 'WRITE-BLOCK TEST%';
delete from public.child_journey       where entry_type = 'WRITE-BLOCK TEST (panel)';
delete from public.consents            where source = 'WRITE-BLOCK TEST (panel)';
delete from public.school_subscriptions where payment_status = 'WRITE-BLOCK TEST (panel)'; -- chỉ có nếu từng bấm bằng admin
-- verify
select
  (select count(*) from public.child_observations  where note like 'WRITE-BLOCK TEST%')              as obs_left,
  (select count(*) from public.child_journey        where entry_type = 'WRITE-BLOCK TEST (panel)')    as journey_left,
  (select count(*) from public.consents             where source = 'WRITE-BLOCK TEST (panel)')        as consent_left,
  (select count(*) from public.school_subscriptions where payment_status = 'WRITE-BLOCK TEST (panel)') as sub_left;
-- kỳ vọng: 0 · 0 · 0 · 0  (consents về lại 4; school_subscriptions về lại 1 — chỉ giữ hợp đồng seed thật)
```

> ⚠️ Câu delete `school_subscriptions` an toàn vì lọc đúng nhãn test — KHÔNG đụng hợp đồng seed (`payment_status='paid'`). Nhưng nhớ kiểm `sub_left` về 0 và subscription thật còn nguyên (12tr/4 seat).

---

## 5. NGÃ KẾ (chọn đầu phiên sau)

Còn **2 cụm RLS** + Media (gộp Edge). Theo độ độc lập:

- **A. Ops** — `notifications` · `support_requests` · `audit_logs`. Phần lớn self-scoped + admin. Cơ học, KHÔNG chạm PII trẻ, ít bẫy. **Ứng viên mạnh kế tiếp** (giống Business về độ sạch).
- **B. Moments** — `learning_moments` · `moment_children` · `albums` + (Media: `media_assets`/`media_variants` — RLS mỏng; MIN-consent + signed-URL = Edge). **Chạm trẻ** → cẩn thận D48; phần thịt là Edge Function nên nên **gộp với Phase 4 Edge media**; nên dọn §4 trước.
- **C. UI Chặng 2** — rời panel-test sang màn vận hành thật (CRUD qua RPC). Bắt đầu chuyển từ "chứng minh RLS" sang "dùng được".

Mọi ngã bắt đầu bằng **audit DB thật cụm đó (D1)** trước khi viết SQL.

> **Gợi ý nhịp:** Ops (A) là cụm RLS thuần sạch cuối cùng → làm nốt để **đóng 7/8** rồi gom Moments+Media+Edge thành một khối Phase 4 lớn (vì RLS Moments mỏng, không đáng tách). Sau đó UI Chặng 2.

---

## 6. KỶ LUẬT GIỮ NGUYÊN (nhắc nhanh)

- Schema do migration sở hữu — Lovable KHÔNG sinh/sửa SQL. KHÔNG "Try to fix all" security scanner.
- `auth.uid()` NULL trong SQL Editor → nghiệm thu bằng **login thật** (D2).
- Mig idempotent (drop-if-exists). Seed idempotent (NOT EXISTS). Seed cụm-không-guard không cần `replica` (D30) — Business KHÔNG guard.
- SQL Editor trả statement cuối → đặt 1 `select jsonb_pretty(...)` verify ở cuối (D4).
- Hàm definer mới → re-verify + revoke EXECUTE public/anon (D15). *(Phiên v7 KHÔNG có hàm mới → không cần re-verify.)*
- Engine consent `min(trường,PH)` = **Edge Function**, không RLS (D47/D55).
- **License (D56):** che cột tài chính bằng tách-quyền-đọc-ở-tầng-bảng; WRITE admin-only; trường không tự cấp license; license-gate tách journey (D42).

---

*Handoff v7 — 2026-06-25 03:52 GMT+7. Cụm Business/License XONG (mig 021 + seed 006, 104 policy). 6/8 cụm RLS hoàn tất. Nguồn: A–G UPDATED + RULES v7 + SYSTEM_MAP v0.8.*
