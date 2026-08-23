# DMA_V114_R_TRUTHFULNESS_REMEDIATION_CLOSEOUT.md

> Mốc khắc phục tính trung thực tiền-build · đóng ngày **20/07/2026**
> Mốc CODE đầu tiên của chuỗi V114. Chỉ **gỡ bỏ**, không mở rộng.

---

## 1. PHÁN QUYẾT

> ## **V114-R PASS WITH EVIDENCE DEBT**

| Hạng mục | Kết quả |
|---|---|
| R1 — trạng thái tắt trung thực của Remote/TV | ✅ **PASS** |
| R2 — gỡ phán quyết `Cần hỗ trợ` cấp lớp | ✅ **PASS** |
| R3 — CTA gửi nhật ký theo vai trò | ✅ **PASS** |
| R4 — bằng chứng zero-data | ❌ **OPEN — nợ bằng chứng** |
| SEC0 containment | ✅ **INTACT** |
| Type check · Build · Deploy | ✅ **PASS** |

**Nợ duy nhất còn lại của mốc là R4.** Không có blocker nào khác.

---

## 2. CHUỖI COMMIT THẬT

Chuỗi **không tuyến tính** — sáu commit gồm hai merge. Bản kê bốn commit ban đầu là chưa đủ; đây là chuỗi đọc từ Git.

```
b87b576b  baseline (V114-H · Applied health truthfulness)
    │
d919a73f  Applied V114-R remediation                    ← áp một phần
    │
10407770  R1 removed SmartPhone/QRCode                  ← đính chính lần 1
    │
5ae55aaa  Sửa V114-R R1 hoàn chỉnh                      ← gỡ transport chết
    │
62186bbd  Sửa gate màn chiếu & seek        [MERGE: 5ae55aaa + 7905ce9]
    │
bbf80936  Lovable update                   [MERGE: 62186bbd + 040f1d5]  ← HEAD
```

`7905ce9` và `040f1d5` là commit sandbox dev ("Work in progress"), không mang thay đổi sản phẩm. Diff ròng `b87b576b..bbf80936` là nguồn sự thật, và nó sạch.

**Deployed HEAD (Owner xác nhận):** `bbf80936` · **Cloudflare Pages status: Success**

---

## 3. FILE THAY ĐỔI

Diff ròng `b87b576b..bbf80936` — **4 file**:

| # | File | Vai trò |
|---|---|---|
| 1 | `src/routes/_authenticated/school.index.tsx` | R2 |
| 2 | `src/routes/_authenticated/teacher.index.tsx` | R1 — Home |
| 3 | `src/routes/_authenticated/teacher.session.$id.tsx` | R1 — Bước 2 · R3 — Bước 4 |
| 4 | `src/routeTree.gen.ts` | ⚠️ **non-source delta** |

### Ghi nhận non-source delta
`routeTree.gen.ts` là file **tự sinh** bởi TanStack Router Vite plugin, thay đổi trong `bbf80936`: 10 dòng append, chỉ khối `declare module '@tanstack/react-start'`. **Type declaration thuần — không thêm route nào.** Nằm ngoài ba file đã duyệt, nên ghi nhận minh bạch ở đây thay vì bỏ qua.

**Không chạm:** `src/hooks/useSessionChannel.ts` · `src/routes/remote.tsx` · `supabase/` · Parent Portal · Kid Portal · FMN.

---

## 4. R1 — TRẠNG THÁI TẮT TRUNG THỰC (Option A, Owner duyệt)

### Vì sao gỡ chứ không sửa câu chữ

Truy vết tĩnh xác lập: `mint_session_remote_code` là **stub vô hiệu** — thân hàm ba dòng, luôn trả `remote_temporarily_disabled`. Hệ quả dây chuyền:

1. `ensureRemoteCode()` luôn trả `null`
2. `openMonitor()` mở Classroom với `k=""`
3. `useSessionChannel(undefined)` → kênh không bao giờ mở
4. Mọi lệnh transport (`publishState`) rơi vào hư không

**Toàn bộ cụm Màn chiếu/TV đã hỏng sẵn trên production trước mốc này.** Giữ nút lại = giữ một thất bại được bảo đảm (**D290**). Khôi phục nó = phải bật lại credential đã bị SEC0 đóng.

Owner duyệt **Option A: gỡ trung thực toàn cụm**. Đây là **gỡ bỏ một năng lực đã chết**, không phải khôi phục hay thiết kế lại Remote.

### Trước → Sau

| Hạng mục | Trước | Sau |
|---|---|---|
| Thông điệp lỗi | *"Chưa tạo được mã điều khiển. Cô kiểm tra mạng rồi thử lại nhé."* — **đổ lỗi mạng trường** | Thông báo trung thực, đủ 4 sự thật |
| Nút **Thử lại** | có, mời cô bấm lại việc chắc chắn hỏng | **gỡ** |
| Auto-mint khi vào Bước 2 | `useEffect` tự gọi RPC | **gỡ** |
| `Chiếu lên TV` · `Mở điều khiển` · `Kết nối điều khiển` | 3 nút | **gỡ** |
| Mở `/remote#k=` với key rỗng | có | **gỡ** |
| Mở `/teacher/classroom?…&k=` với key rỗng | có | **gỡ** |
| Khối QR + mã 6 số | có | **gỡ** |
| Transport: play · tua · seek · che màn · lặp · âm lượng | render, bấm được, vô tác dụng | **gỡ / gate** |
| `Trình chiếu` · `Dừng` | có | **gỡ** |
| `Tự chạy nền` / `Tạm dừng nền` | có | **gỡ** |
| `Tạm dừng lớp` | có | **gỡ** |
| Badge `○ Chờ màn chiếu` | có | **gate** |
| *"Chưa mở Màn chiếu — bấm 'Chiếu lên TV'."* | có | **gỡ** |
| Đoạn HD *"bấm Chiếu lên TV, kéo cửa sổ… Bắt đầu trình chiếu"* | có | **gỡ** |
| Home: `LockedAction` ×2 + *"Sắp ra mắt · V1.1"* | có | **gỡ** |
| Home ↔ Session | nói hai điều khác nhau | **nói cùng một điều** |

### Câu thông báo cuối (đủ 4 sự thật)

> Màn chiếu và điều khiển từ xa đang tạm ngưng để Dế Mèn nâng cấp bảo mật. Cô không cần thử lại hoặc kiểm tra mạng của trường. Cô vẫn có thể tiếp tục buổi học và ghi nhận hoạt động trên thiết bị này.

1. tạm ngưng ✅ 2. do Dế Mèn chủ động ✅ 3. lý do bảo mật ✅ 4. không phải mạng trường, không cần thử lại ✅

### Ranh giới còn giữ
`PROJECTION_AVAILABLE: boolean = false` vẫn có tham chiếu thật (gate thanh seek, dòng 757) — **không phải placeholder chết**. Đây là ranh giới tính năng tường minh.

> ⚠️ **Đổi cờ này một mình KHÔNG khôi phục được Remote.** Cần `V114-SEC1A-R` làm capability token phía server, uỷ quyền và transport mới.

### Vẫn hoạt động bình thường
Panel giáo án · `SessionResourcePanel` · chuỗi hoạt động · `PocketMirror` · chip học liệu trong phần · học liệu bổ sung · Báo lỗi phát/học liệu · điều hướng Hoạt động trước/sau · toàn bộ Bước 1, 3, 4.

---

## 5. R2 — GỠ PHÁN QUYẾT CẤP LỚP

**Frontend-only. Không migration.** Chuỗi `"Cần hỗ trợ"` **không nằm trong SQL** — `get_school_overview` chỉ trả `status: 'support'`; nhãn tiếng Việt nằm ở `STATUS_META` phía client.

| Trước | Sau |
|---|---|
| Badge đỏ **`Cần hỗ trợ`** cấp lớp | **gỡ hẳn** |
| `STATUS_META` (good/attention/support/not_started) | **xoá hẳn** |
| `Nhật ký {pct}%` — mẫu số ẩn | `Tiến độ nhật ký {pct}% — trên số buổi đã bắt đầu dạy` |
| `journal_pct == null` → `—` | `Chưa có buổi nào đã bắt đầu dạy` |

**Khiếm khuyết gốc:** ngưỡng `>=80 good / >=50 attention / else support`, với **mẫu số tính cả `in_progress`**. Hai buổi fixture kẹt `in_progress` từ 03/07 và 14/07 đủ kéo một lớp xuống "Cần hỗ trợ" — một phán quyết về chất lượng cô giáo, sinh ra từ dữ liệu thử nghiệm bỏ dở.

**Không tạo ngưỡng mới nào** — kể cả ngưỡng "ít dữ liệu", vì mọi ngưỡng đều là một phán quyết. Giữ nguyên tên lớp, tên môn, `{done}/{total} buổi`, thanh tiến độ, `onView`.

**Không viết lại phép tính domain.** DC-1 / DC-2 / DC-3 vẫn mở.

---

## 6. R3 — CTA GỬI NHẬT KÝ THEO VAI TRÒ

### Nguồn tín hiệu — do server suy ra, không đoán ở client

Truy vết: `get_session_detail` và `get_session_roster` **không** trả vai trò. Nhưng `get_teacher_classes` trả `is_lead` per-distribution kèm mảng `sessions[]`, và chỉ trả các distribution của **chính người gọi**.

Gate server:
```sql
is_session_lead(p_session_id) =
  EXISTS(lesson_sessions s JOIN class_distributions cd ON cd.id = s.class_distribution_id
         WHERE s.id = p_session_id AND cd.lead_teacher_id = current_profile())
```

UI phản chiếu **đúng** gate đó: tìm distribution có `sessions[]` chứa `session.id` → đọc `is_lead`. Không RPC mới, không projection mới, không quyền mới.

| Vai trò | Trước | Sau |
|---|---|---|
| GV phụ trách | nút bật | nút bật — **không đổi** |
| Trợ giảng | **nút bật**, bấm mới biết bị từ chối (**D290 · D293**) | thông báo trung thực, **không gọi RPC** |
| Hiệu trưởng | — | nhận `[]` → **không có CTA làm thay** |
| Đang tải | — | *"Đang kiểm tra quyền gửi…"* |

**Phòng thủ nhiều lớp:** `if (canSubmit !== true) return;` là dòng đầu tiên của `submit()` (dòng 2335). UI phản chiếu gate, **không thay thế** gate. `submit_session_journal` không đổi một byte.

---

## 7. R4 — NỢ BẰNG CHỨNG (VẪN MỞ)

**Trạng thái: `R4 OPEN — SAFE ZERO-DATA FIXTURE UNAVAILABLE`**

Không thu được ảnh chụp zero-data. Hai lý do, đều cứng:

1. **Không có browser automation** trong môi trường công cụ của phiên này.
2. **Cấm mutate production** để dựng trạng thái zero-data — và lệnh cấm này đúng.

**Không bịa bằng chứng.** Nợ V114-H giữ nguyên trạng thái mở.

### Việc cần làm để đóng R4
Đăng nhập một tài khoản trường **chưa có buổi học nào được ghi nhận**, mở `/school`, chụp ở **một viewport desktop** và **một viewport mobile**, xác nhận:

- ✅ không có điểm sức khoẻ
- ✅ không có phán quyết `Cần hỗ trợ` cấp trường
- ✅ không có phán quyết cấp lớp
- ✅ hiện trạng thái trung thực *"Chưa đủ dữ liệu để đánh giá"* / *"Trường chưa có buổi học nào được ghi nhận"*
- ✅ bố cục vẫn dùng được

---

## 8. XÁC MINH BẢO MẬT

| Kiểm | Kết quả |
|---|---|
| `src/hooks/useSessionChannel.ts` | **không chạm** — `SEC0_REMOTE_DISABLED` và `createTransport` còn nguyên |
| `src/routes/remote.tsx` | **không chạm** — vẫn là trang tĩnh "tạm ngưng" |
| `mint_session_remote_code` | **không đổi** — vẫn là stub vô hiệu |
| `capture_session_media` | **không đổi** — `verify_jwt:true`, fail-closed 503 |
| `capture_session_moment` | **không đổi** — stub 410 |
| RPC authorization | **không đổi** |
| RLS policies | **không đổi** — 164 |
| Edge deployment config | **không đổi** |

**Không có:** khôi phục năng lực Remote · `channel_key` làm bearer · mở lại receiver/capture · mở rộng phạm vi uỷ quyền · truy cập liên trường.

---

## 9. KIỂM KÊ TRƯỚC → SAU

| Hạng mục | Trước | Sau |
|---|---|---|
| Migrations | 103 | **103** |
| Tables | 87 | **87** |
| SECURITY DEFINER | 190 | **190** |
| RLS policies | 164 | **164** |
| Cron jobs | 1 | **1** |
| Routes | 52 | **52** |
| Edge Functions | 16 | **16** |
| Mở rộng uỷ quyền | — | **0** |

---

## 10. LỆNH VÀ KẾT QUẢ

| Lệnh | Exit | Ghi chú |
|---|---|---|
| `tsgo` | **0** | không lỗi |
| `bun run build` | **0** | built in 1.26s |
| `bun run lint` | — | lỗi prettier / `explicit-any` **rải khắp repo, có sẵn từ trước**; **không** có `no-unused-vars` do V114-R sinh ra |
| `git diff --stat b87b576b..bbf80936 -- useSessionChannel.ts remote.tsx supabase/` | — | **rỗng** |

### Grep chuỗi cũ trên `teacher.session.$id.tsx` — **rỗng hoàn toàn**
`Chiếu lên TV` · `Mở điều khiển` · `Kết nối điều khiển` · `Bắt đầu trình chiếu` · `Chưa mở Màn chiếu` · `Tự chạy nền` · `Tạm dừng nền` · `Trình chiếu` · `Thử lại` · `remote#k=` · `mint_session_remote_code` · `openMonitor` · `openRemote` · `QRCodeSVG`

### Ngoại lệ được ghi nhận
`kiểm tra mạng` còn **2 dòng**:
- dòng 88 — trong `PROJECTION_NOTICE`, là **câu phủ định đã duyệt** ✅
- dòng 1498 — *"Chưa lưu được — kiểm tra mạng rồi thử lại"* trong tab Ghi nhận. Đây là **lỗi lưu thật**: auto-save quan sát trẻ hỏng thì đúng là nên kiểm tra mạng và đúng là nên thử lại. Không liên quan projection. **Giữ nguyên là đúng.**

`Cần hỗ trợ` còn trong `OBS_FLAGS` của `teacher.session.$id.tsx` — cờ quan sát **cho TỪNG BÉ**, hợp lệ, **không phải** phán quyết cấp lớp. **Giữ nguyên có chủ đích.**

---

## 11. TRIỂN KHAI

| | |
|---|---|
| Cơ chế | Cloudflare Pages CI, direct-main (`deploy_project` không được gọi) |
| Commit nguồn production | **`bbf80936`** |
| Trạng thái deploy | **Success** *(Owner xác minh độc lập)* |
| Dữ liệu production | **không thay đổi một dòng nào** |

---

## 12. BÀI HỌC TỪ QUÁ TRÌNH ÁP

Ba lượt agent liên tiếp trả **lỗi transport ở đường phản hồi** trong khi **commit vẫn vào main thành công**. Lỗi transport **không phải** phán quyết build — nhưng cũng **không được** suy ngược thành build pass. Cách duy nhất đúng là kiểm `list_edits` → `get_diff` trực tiếp.

Lượt áp đầu (`d919a73f`) **thiếu 5 thao tác** dù chỉ thị đã liệt kê rõ, và để lại tình trạng nguy hiểm hơn cả trước khi sửa: nút bị gỡ nhưng **đoạn hướng dẫn bấm nút vẫn còn**. Chỉ thị dạng *"bọc khối X"* bị diễn giải lệch; chỉ thị dạng *"xoá hẳn đoạn này, thay bằng đoạn này"* thì không. **Luôn `get_diff` sau mỗi `send_message`** — chưa soi diff thì chưa có gì được coi là đã áp.

---

## 13. VIỆC KHÔNG LÀM TRONG MỐC NÀY

- ❌ Không canonicalize `DMA_RULES.md` hay `DMA_SYSTEM_MAP.md`
- ❌ Không đánh dấu V114-H là SEALED
- ❌ Không mở V114B (shell dual-view · Route Contract A · profile preference)
- ❌ Không mở SEC1A-R · SEC1A-K · SEC1B
- ❌ Không triển khai di trú route OD-2 (chỉ **ghi nhận** ở `DMA_V114B_OD2_ROUTE_CONTRACT_APPROVED.md`)

---

## 14. BLOCKER CÒN LẠI

| Blocker | Chủ |
|---|---|
| **R4** — ảnh chụp zero-data | thao tác thủ công của Owner |
| Phát hành Principal Today | DC-1 · DC-2 · DC-3 |
| Phát hành dữ liệu lõi Teacher Today | **SEC1B** + controlled validation |
| Teacher Remote | **SEC1A-R** |
| Ghép thiết bị Cổng Kid | **SEC1A-K** |
| Build V114B | **OD-2 đã chốt** → sẵn sàng khi Owner mở |

**P0 đang mở: 0. Production: ổn định.**

### Mốc kế tiếp được khuyến nghị
`V114B-E1` — Dual-View Shell, Route Contract A, Profile Preference. **Không tự khởi động.**

---

*Sinh trong V114-R. Không canonicalize. Không cập nhật RULES/SYSTEM_MAP.*
