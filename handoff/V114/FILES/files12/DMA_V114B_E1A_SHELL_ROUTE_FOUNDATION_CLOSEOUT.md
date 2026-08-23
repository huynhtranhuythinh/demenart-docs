# DMA_V114B_E1A_SHELL_ROUTE_FOUNDATION_CLOSEOUT.md

> **Loại:** closeout xác minh (verification-only). ZERO code change · ZERO SQL · ZERO migration · ZERO route · ZERO Auth mutation · ZERO production data mutation.
> **Ngày chốt:** 21/07/2026 · GMT+7
> **Owner decision reference:** V114B-E1a FINAL CLOSEOUT — Option A + Option C approved.

---

## 0. FINAL VERDICT

```
V114B-E1a PASS WITH ROUTE QA EVIDENCE DEBT
```

Căn cứ (theo Owner reasoning, giữ nguyên):

- source extraction PASS
- Management route fidelity PASS
- typecheck PASS
- build PASS
- route inventory truthful
- authorization unchanged
- no fake Today
- no preference workaround
- no P0
- remaining gaps are **evidence availability**, not proven implementation defects

---

## 1. CLOUDFLARE PRODUCTION CONFIRMATION — ✅ PASS

Owner cung cấp bằng chứng dashboard trực tiếp (Cloudflare Pages → project `demenart` → Deployments).

| Trường | Giá trị |
|---|---|
| Environment | Production |
| Status | **Success** |
| Source branch | `main` |
| Source commit | **`e81c317`** — "Lovable update VERIFICATION…" |
| Deployment URL | `https://b553a7fd.demenart.pages.dev` |
| Thời điểm | ~7 giờ trước thời điểm verify |
| Automatic deployments | Enabled |
| Domains | `demenart.com` · `www.demenart.com` · `demenart.pages.dev` |

**Không có deployment nào mới hơn `e81c317`.** Production đang serve đúng HEAD đã audit.

**Đối chiếu chéo (Lovable `list_edits`, kênh read-only):** HEAD = `e81c3179`, không có commit nào sau đó, không có second writer. Commit chain khớp hai chiều:

```
bbf80936  (14h)  →  0bafc5a0  (9h)  →  e81c3179  (7h)
bbf8093          →  0bafc5a        →  e81c317        (Cloudflare, 7 ký tự)
```

→ **Loại bỏ `V114B-E1a DEPLOYMENT STALE`.** Toàn bộ QA dưới đây chạy trên đúng `e81c3179`.

---

## 2. ROUTE QA MATRIX — ✅ PASS (desktop)

Điều kiện đo: production `demenart.com` · real browser · real login · role `master_admin` (Huỳnh Trần Nguyệt Thi — Kids House Montessori Đà Nẵng) · viewport 1470×780.

| # | URL vào | URL cuối | Tab render | Content load | Refresh giữ | Blank | Redirect loop | Today giả |
|---|---|---|---|---|---|---|---|---|
| 1 | `/school` | `/school/manage` | Tổng quan | ✅ | ✅ | ✗ | ✗ | ✗ |
| 2 | `/school/manage` | `/school/manage` | Tổng quan | ✅ | ✅ | ✗ | ✗ | ✗ |
| 3 | `/school/manage?tab=classes` | idem | Lớp & Môn (2 lớp) | ✅ | ✅ | ✗ | ✗ | ✗ |
| 4 | `/school/manage?tab=teachers` | idem | Giáo viên (4 nhân sự) | ✅ | ✅ | ✗ | ✗ | ✗ |
| 5 | `/school/manage?tab=children` | idem | Trẻ & Phụ huynh | ✅ | ✅ | ✗ | ✗ | ✗ |
| 6 | `/school?tab=classes` | `/school/manage?tab=classes` | Lớp & Môn | ✅ | ✅ | ✗ | ✗ | ✗ |
| 7 | `/school?tab=teachers` | `/school/manage?tab=teachers` | Giáo viên | ✅ | ✅ | ✗ | ✗ | ✗ |
| 8 | `/school?tab=children` | `/school/manage?tab=children` | Trẻ & Phụ huynh | ✅ | ✅ | ✗ | ✗ | ✗ |
| 9 | `/school?tab=invalid` | `/school/manage` (query strip) | không tab nào chọn | ✅ | ✅ | ✗ | ✗ | ✗ |

**9/9 khớp expected.** Legacy `?tab=` được bảo toàn. `?tab=invalid` rơi về `/school/manage` không chọn tab, đúng đặc tả.

**Sidebar inventory (bằng chứng "no fake Today"):**
`/school/manage` (brand + nav) · `?tab=classes` · `?tab=teachers` · `?tab=children` · `/school/settings` · `/school/curriculum` · `/school/drive` · `/school/support` · `/school/notifications`.
→ **Không tồn tại mục "Hôm nay" / Today ở bất kỳ dạng nào** — không link, không button, không control disabled render như active.

---

## 3. BROWSER HISTORY — CASE A — ✅ PASS

Thực thi thật trong browser, không suy diễn từ `replace: true`.

| Bước | Quan sát |
|---|---|
| Trang trước khi điều hướng | `/` (landing ngoài School) |
| Điều hướng | `/school?tab=teachers` |
| URL cuối sau redirect | `/school/manage?tab=teachers` |
| Sau khi bấm Back | quay về `/` |
| Người dùng bị kẹt? | Không |
| Redirect loop? | Không |

**History behavior: acceptable.** Redirect entry bị thay thế đúng như thiết kế, Back không rơi ngược vào vòng redirect.

---

## 4. BROWSER HISTORY — CASE B — ⚠️ EVIDENCE DEBT

```
Browser History Case B = EVIDENCE DEBT
```

**Phân loại theo Owner decision: KHÔNG dán nhãn hành vi là intended hoặc correct.**

### 4.1 Những gì đã quan sát được trong browser thật

*(ghi lại nguyên trạng — đây là quan sát browser, không phải suy diễn từ source)*

| Bước | URL | Tab chọn | State khớp URL | Flicker / blank |
|---|---|---|---|---|
| Mở `/school/manage?tab=classes` | `?tab=classes` | Lớp & Môn | ✅ | Không |
| Click sang "Giáo viên" | `?tab=teachers` | Giáo viên | ✅ | Không |
| Back | **`?tab=children`** (một entry cũ hơn, không phải `?tab=classes`) | Trẻ & Phụ huynh | ✅ | Không |
| Forward | `?tab=teachers` | Giáo viên | ✅ | Không |
| Refresh (F5) | `?tab=teachers` giữ nguyên | Giáo viên | ✅ | Không |

**Hành vi quan sát được:** thao tác chuyển tab ghi vào history theo kiểu **replace**, không phải push. Entry `?tab=classes` bị ghi đè bởi `?tab=teachers`, nên Back nhảy ra khỏi chuỗi tab thay vì lùi về tab liền trước.

**Không có:** redirect loop · blank screen · state lệch URL · flicker · trap.

### 4.2 Vì sao vẫn là EVIDENCE DEBT, không phải PASS

Quan sát ở §4.1 đo trong một history stack đã tích luỹ từ các bước QA trước đó, **không phải một session sạch có kiểm soát**. Entry `?tab=children` xuất hiện ở bước Back là dấu vết từ ma trận §2, không phải một điều kiện khởi đầu được thiết lập chủ ý.

Do đó:

- hành vi replace-semantics là **quan sát được**, nhưng
- **chưa được tái lập trong một history stack sạch, tất định**, và
- **chưa được Owner phê chuẩn là intended behavior**.

**Giữ nguyên nguyên tắc đã chốt: suy diễn từ source KHÔNG phải bằng chứng browser.** Nguyên tắc này áp cả chiều ngược lại — một lần quan sát trong stack nhiễu chưa đủ để tuyên bố PASS.

→ Case B phải được thực thi lại trong session sạch, có kiểm soát, trước khi được kết luận.

---

## 5. POST-LOGIN VERIFICATION

### 5.1 `master_admin` — ✅ PASS

| Kiểm tra | Kết quả |
|---|---|
| Login thành công | ✅ (Huỳnh Trần Nguyệt Thi) |
| Landing route | `/school/manage` |
| Management render | ✅ đầy đủ |
| School scope đúng | ✅ Kids House Montessori Đà Nẵng — 2 lớp · 8 học sinh · 4 giáo viên |
| Today placeholder | ✗ không xuất hiện |

Không thay đổi auth hay role configuration trong quá trình verify.

### 5.2 `sub_admin` — ⛔ NOT EXECUTABLE

```
sub_admin post-login QA = NOT EXECUTABLE — NO LIVE FIXTURE
```

**KHÔNG mark PASS.**

**Ghi nhận sự thật vai trò (đo live, read-only):**

- `sub_admin` **tồn tại** trong enum `profile_role`
- được xếp cùng nhóm với `master_admin` trong domain quản trị Trường (School administration domain)
- dùng `permissions[]` **có scope**
- việc cấp permission **không flip role** (D45 / G473)
- đường RLS hiện tại **có bao gồm** `sub_admin` qua `is_school_admin()`
- UI gate hiện tại **có bao gồm** `sub_admin` qua `canManage`
- production hiện có **`0`** profile `sub_admin` được provision

**Phân bố role live (production, `select role, count(*) from profiles group by 1`):**

| role | count |
|---|---|
| super_admin | 1 |
| master_admin | 3 |
| lead_teacher | 6 |
| assistant_teacher | 2 |
| primary_parent | 13 |
| secondary_parent | 1 |
| family_member | 1 |
| **sub_admin** | **0** |

→ QA post-login theo vai này **không khả thi**.
→ Đây là **fixture không sẵn có (unavailable fixture)**, **KHÔNG phải regression quan sát được**.

**Không tạo tài khoản `sub_admin`.** Không mutate: Auth users · `profiles` · roles · permissions · school membership · production data.

### 5.3 Ghi chú vận hành trong lúc verify

Trong phiên verify, một lần đăng nhập đã rơi vào tài khoản `super_admin` ("Test") thay vì `sub_admin`; role này landing đúng `/admin` (Mission Control), **không** vào School shell. Ghi lại để minh bạch chuỗi thao tác; **không** ảnh hưởng phạm vi E1a và **không** được tính là một mốc QA.

---

## 6. RESPONSIVE QA

| Breakpoint | Trạng thái | Ghi nhận |
|---|---|---|
| Desktop (1470×780) | ✅ PASS | shared School shell đúng · sidebar active state đúng · brand/logo link → `/school/manage` · Management tabs đủ 3 · không overflow ngang · không blank shell · không duplicate navigation · không Today control |
| Narrow (500×657) | ✅ PASS | layout single-column · không overflow ngang · không duplicate nav · brand link đúng · content load đủ |
| Mobile thật (<480) | ⬜ **EVIDENCE DEBT** | Chrome trên thiết bị verify không thu window xuống dưới ~500px CSS → **không chạm được breakpoint drawer**. Mobile drawer active state **chưa quan sát được**. |
| Tablet | ⬜ **EVIDENCE DEBT** | thiết bị không sẵn có |

---

## 7. EXPLICIT EVIDENCE DEBT MATRIX

*(liệt kê tách bạch theo yêu cầu Owner — KHÔNG gộp thành một dòng chung)*

| # | Khoản debt | Trạng thái | Ghi chú |
|---|---|---|---|
| 1 | Cloudflare final HEAD confirmation | ✅ **RESOLVED** | Owner cung cấp bằng chứng dashboard: Status Success · `main e81c317`. Không còn là debt. |
| 2 | Desktop/mobile route matrix | ⚠️ **PARTIAL** | Desktop: 9/9 executed, PASS. Mobile <480: **chưa thực thi** — không chạm được breakpoint. |
| 3 | Browser History Case A | ✅ **RESOLVED** | Executed trong browser thật, PASS. Không còn là debt. |
| 4 | Browser History Case B | ⚠️ **EVIDENCE DEBT** | Đã quan sát replace-semantics trong browser thật (§4.1), nhưng **chưa tái lập trong history stack sạch** và **chưa được phê chuẩn là intended**. Phải chạy lại có kiểm soát. |
| 5 | `sub_admin` post-login | ⛔ **NOT EXECUTABLE** | `NO LIVE FIXTURE` — 0 profile được provision. Không mark PASS. Không tạo fixture. |
| 6 | Tablet QA | ⬜ **EVIDENCE DEBT** | Thiết bị không sẵn có. |

---

## 8. PRODUCT BACKLOG FINDING (NON-BLOCKING)

> **Tách bạch khỏi phạm vi E1a. KHÔNG sửa bây giờ. KHÔNG tự gán vào E2 scope.**

### `V114B-BL01 — Sub-Admin Provisioning & Scoped Delegation`

**Trạng thái hiện tại:**

- domain role **có tồn tại** (`profile_role.sub_admin`)
- RLS **có nhận diện** (`is_school_admin()`)
- UI **có nhận diện** (`canManage`)
- mô hình permission có scope (`permissions[]`) **có tồn tại**
- **không có tài khoản production nào**
- **không có workflow School UI nào đã được kiểm chứng là provision được một Sub-Admin**

**Việc sản phẩm tương lai phải xác định:**

1. ai được phép tạo Sub-Admin
2. lời mời và kích hoạt tài khoản
3. gán phạm vi permission
4. sửa và thu hồi permission
5. danh tính gắn với trường (school-bound identity)
6. audit trail
7. cách tính seat và billing
8. deactivation
9. khôi phục và chuyển giao quyền sở hữu

**Không thuộc phần implementation của E1a.**

---

## 9. MUTATION-FREE CONFIRMATION

Xác nhận trong toàn bộ phiên verification này:

- **KHÔNG** tạo, sửa, xoá bất kỳ Auth user nào
- **KHÔNG** tạo, sửa, xoá bất kỳ hàng nào trong `profiles`
- **KHÔNG** thay đổi role, `permissions[]`, hay school membership
- **KHÔNG** mutate production data dưới bất kỳ hình thức nào
- **KHÔNG** thay đổi auth hoặc role configuration trong lúc verify
- **KHÔNG** sửa source code
- **KHÔNG** chạy migration · **KHÔNG** `apply_migration` · **KHÔNG** DDL
- **KHÔNG** tạo commit mới
- **KHÔNG** canonicalize RULES hoặc SYSTEM_MAP

**Kênh đọc đã sử dụng (read-only, khai báo đầy đủ):**

- Lovable `list_edits` — đọc lịch sử commit
- Supabase `execute_sql` — **chỉ 4 câu `SELECT`**: liệt kê cột `information_schema.columns`; `profiles` lọc theo role; đếm role theo nhóm. Không `INSERT` / `UPDATE` / `DELETE` / DDL.
- Browser: điều hướng, đọc DOM/accessibility tree, một click chuyển tab (Management tab switch — thao tác đọc, không ghi dữ liệu), reload, back/forward.

**Không có write nào chạm production.**

---

## 10. COMMIT CHAIN (BẢO TOÀN)

```
bbf80936
0bafc5a0
e81c3179
```

Không commit mới được tạo trong phiên closeout này.

---

## 11. IMPLEMENTATION FACTS (GIỮ NGUYÊN TỪ BẢN AUDIT)

- `/school/manage` là Management route canonical
- `/school` là compatibility entry, redirect sang Management
- legacy `?tab=` URLs được bảo toàn
- `school.manage.tsx` là bản move trung thực của Management route cũ: **2424 dòng** so sánh, **đúng 4 khác biệt chủ ý**, không semantic drift
- Principal Today **chưa** implement
- profile preference **hoãn**
- migrations **103**
- routes **53**
- Edge Functions **16**
- RLS policies **164**
- authorization expansion **0**
- SEC0 nguyên vẹn
- `tsgo` và production build **PASS**

---

## 12. SCOPE CLOSURE

- **KHÔNG** mở E1b
- **KHÔNG** mở E2
- **KHÔNG** canonicalize RULES
- **KHÔNG** canonicalize SYSTEM_MAP
- `V114B-BL01` để ở backlog, **chưa gán scope**

---

```
FINAL: V114B-E1a PASS WITH ROUTE QA EVIDENCE DEBT
```

*Endpoint không đổi. Production HEAD `e81c3179` · Cloudflare Success · authorization unchanged · zero mutation.*
