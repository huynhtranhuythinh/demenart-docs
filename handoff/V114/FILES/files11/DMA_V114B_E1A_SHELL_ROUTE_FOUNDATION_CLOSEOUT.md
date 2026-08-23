# DMA_V114B_E1A_SHELL_ROUTE_FOUNDATION_CLOSEOUT.md

> `V114B-E1a — Dual-View Shell & Route Migration Foundation` · 20/07/2026 · **frontend-only**

---

## 1. PHÁN QUYẾT

> ## **V114B-E1a PASS — DEPLOYMENT UNVERIFIED**

| Điều kiện §K | Kết quả |
|---|---|
| Management chạy trên cả lối vào `/school` và `/school/manage` | ✅ |
| URL `?tab=` cũ còn hiệu lực | ✅ |
| Build pass | ✅ `tsgo` EXIT 0 · `bun run build` EXIT 0 |
| Route inventory trung thực | ✅ 52 → **53** |
| **Không** có mô phỏng Today | ✅ |
| **Không** có workaround profile preference | ✅ |
| Ranh giới bảo mật không đổi | ✅ |
| Cloudflare deploy | ⏳ **chưa xác minh** |

Chỉ thiếu xác nhận deploy. Mọi điều kiện kỹ thuật khác đã đạt.

**Chuỗi commit:** `bbf80936` → **`0bafc5a0`** *(triển khai)* → **`e81c3179`** *(commit sinh ra bởi lượt verification; harness tự commit dù lệnh là read-only — nội dung không thay đổi source)*

> ⚠️ **HEAD hiện tại là `e81c3179`, không phải `0bafc5a0`.** Việc xác minh deploy phải nhắm HEAD này.

---

## 2. PHÁT BIỂU BẮT BUỘC

- ✅ Nền shell hai view **đã dựng**
- ✅ `/school/manage` **đã thành route chính tắc** của Quản lý trường
- ✅ URL cũ **được bảo toàn**
- ✅ `/school` **vẫn dẫn tới Management** trong E1a
- ❌ **Principal Today CHƯA được triển khai**
- ❌ **OD-2 CHƯA kích hoạt route gốc** — việc cắt route cuối cùng thuộc về mốc giao được Principal Today thật
- ⏸️ **Profile Preference hoãn sang `V114B-E1b`**
- ✅ **Không** dùng workaround persistence · **không** `localStorage`
- ✅ **0** migration · **0** RPC · **0** policy · **0** Edge · **0** mở rộng uỷ quyền

---

## 3. ROUTE MATRIX — hiện tại

| URL | Hành vi E1a |
|---|---|
| `/school` | `validateSearch` → `beforeLoad` → **redirect** `/school/manage`, `replace: true` |
| `/school/manage` | **Management chính tắc** — nội dung y hệt `/school` trước đây |
| `/school/manage?tab=classes\|teachers\|children` | Management, tab tương ứng |
| `/school/settings` · `/curriculum` · `/drive` · `/support` · `/notifications` · `/moments` | **không đổi** |

## 4. BACKWARD COMPATIBILITY MATRIX

| URL cũ | Kết quả | Cơ chế |
|---|---|---|
| `/school` | → `/school/manage` | redirect |
| `/school?tab=classes` | → `/school/manage?tab=classes` | redirect **giữ search** |
| `/school?tab=teachers` | → `/school/manage?tab=teachers` | redirect **giữ search** |
| `/school?tab=children` | → `/school/manage?tab=children` | redirect **giữ search** |
| `?tab=` giá trị rác | → `/school/manage` (tab `undefined`) | whitelist |

**Chống vòng lặp:** `/school/manage` là route riêng, không redirect ngược — **xác minh từ source**.

> ⚠️ **ĐÍNH CHÍNH.** Bản closeout trước phát biểu *"back/forward hoạt động bình thường"*. Phát biểu đó **rút lại**. Nó suy từ `replace: true` trong source chứ không từ thử nghiệm thật. Hành vi history của trình duyệt **chưa được kiểm chứng** và không được coi là đã đạt cho tới khi chạy Case A và Case B trên bản deploy.

**Hợp đồng search giữ nguyên byte:** `validateSearch` whitelist đúng ba giá trị `classes` · `teachers` · `children`, copy nguyên từ bản cũ. Không mở rộng schema.

## 5. OD-2 ACTIVATION MATRIX — tương lai

| Bước | Trạng thái |
|---|---|
| `/school/manage` là Management chính tắc | ✅ **xong ở E1a** |
| URL cũ được bảo toàn | ✅ **xong ở E1a** |
| Nền shell chứa được hai view | ✅ **xong ở E1a** |
| Principal Today tồn tại | ❌ chưa — **E2** |
| Today qua cổng trung thực + DC-1/2/3 | ❌ chưa |
| `/school` → Principal Today | ❌ **chưa kích hoạt** |
| Đổi view mặc định của Hiệu trưởng | ❌ chưa — cần **E1b** |

> ⚠️ **Bẫy cho E2:** `SCHOOL_VIEWS.today.to = "/school"`, mà `/school` hiện redirect sang `/school/manage`. Khi bật Today ở E2 **phải gỡ redirect trước**, nếu không nút "Hôm nay" sẽ quay về Manage. Ghi lại ở đây để không ai vấp.

## 6. PREFERENCE MATRIX — hoãn

| Hạng mục | Trạng thái E1a |
|---|---|
| Preferred School Landing | **DEFERRED** |
| Nơi lưu | **NOT AVAILABLE** — `profiles` không có cột preference/settings/jsonb; chỉ có `app_settings` (toàn hệ) và `school_settings` (theo trường) |
| `localStorage` fallback | **PROHIBITED** — không dùng |
| Migration cần | **YES — Owner Gate tương lai** |
| RPC cần | **TO BE DESIGNED** |
| Ảnh hưởng uỷ quyền | **NONE IN E1a** |
| API tạm | **không tạo** |

---

## 7. FILE THAY ĐỔI

| File | Thay đổi | Loại |
|---|---|---|
| `src/routes/_authenticated/school.manage.tsx` | **MỚI** — nhận toàn bộ Management (di chuyển, không copy) | source |
| `src/routes/_authenticated/school.index.tsx` | viết lại thành redirect tương thích | source |
| `src/routes/_authenticated/school.tsx` | NAV_GROUPS → `/school/manage` · `navActive` · 2 brand link · `SCHOOL_VIEWS` · pill switcher | source |
| `src/routes/_authenticated/school.moments.tsx` | `navigate` về `/school/manage` | source |
| `src/routes/index.tsx` | card portal "Nhà trường" → `/school/manage` | source |
| `src/lib/home-path.ts` | post-login `master_admin`/`sub_admin` → `/school/manage` | source |
| `src/routeTree.gen.ts` | **tự sinh** — đăng ký `/school/manage` | **non-source delta** |

**Không đổi** logic Management, quyền, data fetching, layout, mobile drawer.

### Ghi nhận generated churn
`routeTree.gen.ts` vừa **thêm** đăng ký `/school/manage` (10 chỗ), vừa **xoá** khối `declare module '@tanstack/react-start'` Register — chính khối đã được thêm ở `bbf80936` và ghi nhận trong closeout V114-R. Khối này **type-only cho SSR**, dao động giữa các lần chạy generator. Build EXIT 0 ở cả hai trạng thái. Ghi nhận minh bạch, không phải thay đổi source.

---

## 8. KIỂM KÊ TRƯỚC → SAU

| Hạng mục | Trước | Sau |
|---|---|---|
| Migrations | 103 | **103** |
| Tables | 87 | **87** |
| SECURITY DEFINER | 190 | **190** |
| RLS policies | 164 | **164** |
| Cron | 1 | **1** |
| **Routes** | 52 | **53** ← `/school/manage` là route thật |
| Edge Functions | 16 | **16** |
| Mở rộng uỷ quyền | — | **0** |

## 9. RANH GIỚI BẢO MẬT — đã kiểm chứng

Truy vấn live `pg_policies`:

```
total_policies = 164
policies đọc (view|mode|preference|today|manage|landing) = 0
```

- URL **không tạo ra quyền** — không có tham số `scope` / `mode` / `authority`
- Shell **không tạo ra quyền** — không có logic uỷ quyền trong `school.tsx`
- `/school/manage` có **đúng cùng** ranh giới uỷ quyền như `/school` cũ: cùng component, cùng RPC, cùng `_authenticated` guard
- **0** RPC · **0** Edge · **0** policy thay đổi
- **SEC0 intact** — không chạm `useSessionChannel.ts`, `remote.tsx`, `capture_session_media`

---

## 10. KIỂM ĐỊNH ĐÃ CHẠY

| Lệnh | Exit |
|---|---|
| `tsgo` | **0** |
| `bun run build` | **0** — 1.50s |
| route generation | `/school/manage` sinh đủ ở 9 vị trí trong `routeTree.gen.ts` |
| `git status --short` | sạch, chỉ generated file |

---

## 11. NỢ KIỂM ĐỊNH — ghi thẳng, không gộp

Phân biệt rõ bốn tầng bằng chứng, **không trộn thành một lời tuyên bố**:

| Tầng | Trạng thái |
|---|---|
| Static verification | ✅ đạt — redirect contract đọc trực tiếp trên `0bafc5a0` |
| Build verification | ✅ đạt — `tsgo` 0, build 0 |
| **Source inspection** | ✅ **đạt** — `diff -u` giữa `school.index.tsx@bbf80936` và `school.manage.tsx@HEAD`: **2424 dòng, đúng 4 dòng khác biệt**. Xem §11.1 |
| **Browser history QA (§7 Case A/B)** | ❌ **chưa chạy** — không được tuyên bố đạt |
| **Deployed render verification** | ❌ **chưa** — không có công cụ đọc Cloudflare |
| **QA matrix desktop/tablet/mobile (§H)** | ❌ **chưa** — không có browser automation; 8 URL × 3 viewport phải chạy thủ công |

**Không tuyên bố QA matrix đã chạy.** §H yêu cầu 8 URL trên ba viewport với back/forward/refresh/flicker — không thứ nào trong đó thực hiện được bằng công cụ hiện có.

### 11.1 Kết quả so sánh `school.manage.tsx`

Phân loại: **(1) bản di chuyển trung thành.** Không phải bản sửa đổi, không phải copy thiếu, không chứa thay đổi ngoài lề.

| Dòng | Thay đổi | Đánh giá |
|---|---|---|
| 53 | `createFileRoute("/_authenticated/school/")` → `"/_authenticated/school/manage"` | **bắt buộc** |
| 445 · 513 · 536 | 3 × `navigate({ to: "/school" … })` → `"/school/manage"` | **đúng** — link nội bộ của Management phải trỏ về chính nó, nếu để `/school` sẽ redirect vòng thêm một nhịp |

**Không đổi:** imports · `validateSearch` · component · data fetching · giả định uỷ quyền · layout · tab logic.

### 11.2 Link `/school` còn lại — phân loại

| Vị trí | Phân loại |
|---|---|
| `SCHOOL_VIEWS[today].to = "/school"` (`school.tsx`) | **intended future Today route** — `available: false`, không render |

Không còn **stale Management route** nào trỏ nhầm về `/school`.

### Việc Owner cần làm để đóng hoàn toàn
1. Xác nhận Cloudflare deploy **`e81c3179`** = Success (không phải `0bafc5a0`)
2. Chạy QA matrix 9 URL trên desktop + mobile (tablet nếu có, nếu không thì ghi là nợ bằng chứng, **không** khai đã chạy)
3. **Case A:** từ trang ngoài School → `/school?tab=teachers` → quan sát redirect → bấm Back. Ghi kết quả **thật**
4. **Case B:** mở `/school/manage?tab=classes` → chuyển sang Giáo viên → Back → Forward → Refresh. Ghi URL, tab đang chọn, và liệu `replace: true` có gây hành vi bất ngờ không
5. Post-login `master_admin` **và** `sub_admin` — cả hai phải vào `/school/manage`
6. `/school?tab=invalid` phải rơi về `/school/manage` với tab rỗng, không trắng trang

---

## 12. VIỆC KHÔNG LÀM

❌ Principal Today · projection · KPI · timeline · analytics · AI
❌ entity route (class/teacher/session) · profile preference persistence · `localStorage`
❌ migration · schema · RPC · Edge · policy · auth
❌ SEC1A-R · SEC1A-K · SEC1B
❌ canonicalize RULES / SYSTEM_MAP
❌ mở E1b · mở E2 · kích hoạt `/school` thành Principal Today

---

## 13. BLOCKER CÒN LẠI

| Blocker | Chủ |
|---|---|
| QA matrix §H + xác nhận deploy | thao tác Owner |
| `V114B-E1b` Profile Preference | cần Owner Gate cho migration |
| Principal Today | **E2** + DC-1 · DC-2 · DC-3 |
| Kích hoạt route gốc OD-2 | mốc giao Principal Today |
| V114-R R4 zero-data screenshots | **vẫn mở** |

**P0 đang mở: 0.**

---

*Sinh trong V114B-E1a. Không canonicalize. Không cập nhật RULES/SYSTEM_MAP.*
