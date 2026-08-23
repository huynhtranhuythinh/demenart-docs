# 🤝 DMA_HANDOFF_v8.md — BÀN GIAO PHIÊN (đóng 8/8 cụm RLS + móng config)

> **Cách dùng:** File này = ảnh chụp trạng thái cuối phiên v8. Boot phiên sau:
> `00_START_HERE` → `RULES` → file này. Rồi audit DB thật trước khi viết SQL.
> **Naming:** DMA = nền tảng; CTAN = sản phẩm đầu. Không "DMMA".

---

## 1. LÀM GÌ PHIÊN NÀY

- **🎉 ĐÓNG 8/8 CỤM RLS** — hoàn tất 2 cụm cuối: **Ops/Config** (#7) + **Moments** (#8).
- **Móng config-driven (gợi ý Jean từ FE DMWS — D59):** dựng `notification_types` (registry template) + `app_settings` (key-value). Feature mới cần báo → gọi `slug`+payload là xong.
- **5 migration mới:**
  - `022_config_foundation` — CẤU TRÚC: 2 bảng móng + FK `notifications.type`.
  - `023_rls_ops_config` — RLS 5 bảng Ops/Config (12 policy).
  - `024_rls_moments` — RLS 3 bảng Moments (9 policy + 2 helper).
  - `025_fix_moment_children_approved_gate` — VÁ gate approved cho tag-table (+1 helper).
- **2 seed mới:** `seed_007_ops_config` · `seed_008_moments`.
- **Panel `/portal/rls-test`** thêm 2 section: "8. Vận hành (Ops/Config)" + "9. Moments".
- **Nghiệm thu login thật 4 vai trò** cả 2 cụm → 7 bằng chứng vàng (xem §3).
- Lock library: RULES +D57/D58/D59/D70 · SYSTEM_MAP v0.9.

---

## 2. TRẠNG THÁI THẬT CUỐI PHIÊN

- **DB:** **46 bảng** · **29 hàm SECURITY DEFINER** · 1 non-definer (`is_school_admin`) · **125 RLS policy** · mig **001→025** · seed **001→008**.
- **✅ 8/8 CỤM RLS XONG** (đều login thật): Org/People · Curriculum · Sessions · Journey · Privacy/Consent · Business/License · **Ops/Config** · **Moments**.
- **Media** (`media_assets`/`media_variants`): **deny-by-default CỐ Ý = Edge-only** (D69/Tài liệu G). KHÔNG phải cụm thứ 9, KHÔNG phải lỗ hổng — là tư thế bảo mật đúng tới Phase 4 Edge.
- **3 helper Moments mới** (secdef, re-verify D15 sạch): `moment_school_id` · `is_moment_parent` · `moment_is_approved`.
- **App:** `/portal/rls-test` panel **10 mục** chạy thật với 4 user.

---

## 3. NGHIỆM THU v8 — MA TRẬN (login thật)

### Cụm Ops/Config (mig 023)
| Login (role) | notifications | support_requests | audit_logs | app_settings | internal_flag | forge audit |
|---|---|---|---|---|---|---|
| `info@` (super_admin) | 0 | **2** | **2** | **12** | **CÓ** | 🟢 chặn |
| `master` (master_admin) | 1 | 0 | 0 | 11 | KHÔNG | — |
| `teacher` (lead_teacher) | 1 | 1 | 0 | 11 | KHÔNG | 🟢 chặn |
| `parent` (primary_parent) | 2 | 1 | 0 | 11 | KHÔNG | — |

### Cụm Moments (mig 024–025)
| Login (role) | learning_moments | moment_children | albums | tạo khoảnh khắc |
|---|---|---|---|---|
| `info@` (super_admin) | **0** | **0** | **0** | 🟢 chặn |
| `master` / `teacher` | 2 | 2 | 1 | 🔵 ghi được |
| `parent` | **1** | **1** | 1 | 🟢 chặn |

**7 bằng chứng vàng:**
1. **audit_logs** non-admin 0 vs admin 2 → carve-out D48 (sổ kiểm toán chỉ controller đọc).
2. **support_requests** master 0 / self 1 / admin 2 → tách theo người gửi.
3. **app_settings** internal-flag chỉ admin (12 vs 11) → cổng `is_public` đứng.
4. **forge audit chặn KỂ CẢ admin** (`violates RLS policy for audit_logs`) → append-only, chỉ service_role ghi.
5. **Moments admin 0/0/0** → D48 (admin Dế Mèn không xem nội dung trẻ).
6. **parent 1 vs trường 2** ở moment+tag → gate `approved` HAI TẦNG (learning_moments + moment_children) → PH chỉ thấy đã-duyệt, không suy ra được bản nháp con.
7. **parent/admin tạo moment → DB chặn** (D64 PH-không-tạo-content); teacher/master ghi được.

> **Bài học login thật:** ban đầu parent "Tag trẻ"=2 (đếm được tag của moment draft) → gate chỉ ở learning_moments chưa đủ → **mig 025** siết thêm `moment_children` bằng `moment_is_approved` → về 1. *(Verify SQL không bắt được, chỉ login thật mới lộ — D2/D3.)*

---

## 4. VIỆC TREO (dọn 1 lần khi rảnh — trước khi vào UI Chặng 2)

Row test do các nút write-block/create để lại. Chạy 1 lần:

```sql
delete from public.child_observations   where note like 'WRITE-BLOCK TEST%';
delete from public.child_journey        where entry_type = 'WRITE-BLOCK TEST (panel)';
delete from public.consents             where source = 'WRITE-BLOCK TEST (panel)';
delete from public.school_subscriptions where payment_status = 'WRITE-BLOCK TEST (panel)';
-- MỚI v8: nút "Thử tạo khoảnh khắc" của teacher/master đẻ draft thật
delete from public.learning_moments     where caption = '[panel] write-block test';

-- verify (kỳ vọng tất cả 0; subscription thật còn 1 với payment_status='paid', moment seed còn 2)
select
  (select count(*) from public.child_observations   where note like 'WRITE-BLOCK TEST%')                 as obs_left,
  (select count(*) from public.child_journey         where entry_type = 'WRITE-BLOCK TEST (panel)')       as journey_left,
  (select count(*) from public.consents              where source = 'WRITE-BLOCK TEST (panel)')           as consent_left,
  (select count(*) from public.school_subscriptions  where payment_status = 'WRITE-BLOCK TEST (panel)')   as sub_left,
  (select count(*) from public.learning_moments      where caption = '[panel] write-block test')          as moment_panel_left,
  (select count(*) from public.learning_moments)                                                          as moment_total;
```

> ⚠️ Mỗi lần teacher/master bấm "Thử tạo khoảnh khắc" lại đẻ 1 draft `[panel]` → nếu test nhiều lần sẽ có nhiều row; câu delete trên lọc đúng nhãn, an toàn. `moment_total` sau dọn nên = **2** (chỉ giữ 2 seed approved+draft).

---

## 5. NGÃ KẾ (chọn đầu phiên sau)

8/8 RLS xong → DB-layer về cơ bản hoàn tất. Theo độ phụ thuộc:

- **A. Edge Functions — Media serving (Phase 4).** Phần thịt còn lại: `get_signed_media_url(media_id|moment_id|album_id)` + `upload_media` + engine **consent min(trường,PH) + MIN-multi-child** (D47/D55 — sống ở Edge KHÔNG RLS) + ký Bunny Token-Auth URL hết hạn ngắn + watermark động + audit per-view. Bật `media_assets` serving (D69). **Nguồn sự thật = Tài liệu G.** Đây là việc lớn & đặc thù DMA nhất.
- **B. RPC vận hành thật.** `create_notification(slug, profile_id, payload)` (secdef — vì client KHÔNG insert noti) + ghi `audit_logs` qua secdef/Edge. Mở khóa cho Vận hành "dùng được", không chỉ "khóa đúng".
- **C. UI Chặng 2.** Rời panel-test → màn vận hành thật (CRUD qua RPC). Bắt đầu tách 4 portal khi mỗi portal có nội dung.
- **D. Deploy.** dma.vercel.app → demenart.com (A record apex + CNAME www + cập nhật Supabase auth redirect URL).

> **Gợi ý nhịp:** **A (Edge media)** là mảnh ghép kiến trúc lớn cuối cùng của V1 — nên làm tiếp để DB+Edge thành một khối hoàn chỉnh, rồi mới B (RPC vận hành) + C (UI Chặng 2). Dọn §4 trước khi vào UI cho sạch.

Mọi ngã bắt đầu bằng **audit DB/code thật (D1)** trước khi viết.

---

## 6. KỶ LUẬT GIỮ NGUYÊN (nhắc nhanh)

- Schema do migration sở hữu — Lovable KHÔNG sinh/sửa SQL. KHÔNG "Try to fix all" (scanner 6–13 issue = nhiễu đúng thiết kế).
- `auth.uid()` NULL trong SQL Editor → nghiệm thu bằng **login thật** (D2). *(v8 chứng minh lại: SQL verify pass nhưng login thật bắt lỗi tag=2 → phải vá.)*
- Mig idempotent (drop-if-exists). Seed idempotent (ON CONFLICT/NOT EXISTS). Cụm-không-guard không cần `replica` (D30) — Ops/Config/Moments KHÔNG guard.
- Hàm definer mới → re-verify + revoke EXECUTE public/anon (D15). *(v8: 3 helper Moments sạch ngay.)*
- **Media (D58/D69):** giữ Edge-only, KHÔNG viết RLS client-read cho child media — serving qua Edge.
- **Config móng (D59):** notification_types = template (sound/icon/position); app_settings is_public cho phần công khai. Feature mới: gọi slug, đừng hardcode chuỗi noti.
- **Anti-fraud (D70):** hoãn tới Edge/Auth phase; substrate `audit_logs.{device,ip,user_agent,metadata}` đã sẵn — đừng quên.

---

*Handoff v8 — 2026-06-25 11:44 GMT+7. ✅ 8/8 CỤM RLS XONG (mig 022–025 + seed 007–008). 46 bảng · 29 hàm definer · 125 policy. Móng config-driven dựng (D59). Media Edge-only cố ý. Nghiệm thu login thật 4 vai × 9 cụm panel. Nguồn: A–G UPDATED + RULES v8 + SYSTEM_MAP v0.9.*
