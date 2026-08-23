# 🤝 DMA_HANDOFF_v15.md — BÀN GIAO PHIÊN (DỌN §4 + DEPLOY LÊN demenart.com — WEB & EMAIL LIVE)

> **Cách dùng:** File này = ảnh chụp trạng thái cuối phiên v15. Boot phiên sau:
> `00_START_HERE` → `RULES` → file này. Rồi audit DB/code thật trước khi viết.
> **Naming:** DMA = nền tảng; CTAN = sản phẩm đầu. Không "DMMA".

---

## 1. LÀM GÌ PHIÊN NÀY

Phiên **hạ tầng** (không đụng DB/schema) — đi **ngã D→A** từ v14 §5:

- **🎯 Ngã D — Dọn §4 (demo sạch trước deploy).**
  - ✅ **XÓA Edge `bunny-sign-test`** (smoke-test ký bừa mọi path cho bất kỳ ai có anon key — lỗ bypass gate). Xong.
  - ✅ **XÓA ảnh DUPLICATE móc nhầm vào moment Jenny.** Row `media_assets` `568b6c5a-…` (path `/moments/ee2f63fd-…/4ab67b19-…jpg`) là **bản trùng** screenshot GV upload lặp vào moment "Bé Jenny vẽ tranh mùa xuân" → xóa row + object Bunny zone `dma-private`. DB verify: `rogue_gone:true`, `total_media_rows:4`, moment Jenny còn 1 ảnh.
  - **⚠️ ĐÍNH CHÍNH HANDOFF_v14 §4 mục 2 (SAI):** v14 ghi ảnh **"Gia đình Vịt Con" (Sakura/DMWS duck poster) là rác/rogue** — **SAI**. Thực tế poster đó **CHÍNH LÀ ảnh demo hợp lệ** của moment Jenny "Bé Jenny vẽ tranh mùa xuân". Jean đã đổi tên file thành `jenny_buoi1.jpg`, là seed image chính thức (row `614aa02e`, 3.11MB, ở root `dma-private`). **Cái bị xóa ở v15 là một row TRÙNG khác** (`568b6c5a`), không phải poster Vịt Con. → Vịt Con/`jenny_buoi1.jpg` = ảnh chính thức, GIỮ.
- **🎯 Ngã A — DEPLOY app lên domain thật `demenart.com`.** Web TanStack Start (Lovable) + Supabase + Bunny giờ chạy độc lập khỏi Lovable hosting trên hạ tầng Jean tự kiểm soát.
  - **Triết lý Jean (chốt giữa phiên):** muốn độc-lập-khỏi-Lovable-subscription. Tách: **Code→GitHub** (backup free) · **Hosting→nền tảng độc lập** · **DNS→Cloudflare**. (App khác của Jean — demenworkshop.vn, leparis.vn — deploy Vercel + Cloudflare-DNS-only; nhưng chúng KHÔNG phải Lovable TanStack Start.)
  - **Stack deploy chốt:** GitHub (`huynhtranhuythinh/demenart`, private, Lovable 2-way sync trên `main`) → **Cloudflare Pages** (hosting, build từ GitHub) → DNS Cloudflare → `demenart.com`.

---

## 2. TRẠNG THÁI THẬT CUỐI PHIÊN

- **DB:** **46 bảng** · **38 hàm SECURITY DEFINER** · **125 RLS policy** · mig **001→034** · seed **001→009**. **KHÔNG đổi gì** (phiên hạ tầng thuần). SYSTEM_MAP v0.16.
- **🌐 LIVE — app chạy trên domain thật:**
  - `https://demenart.com` → **Active + SSL enabled** (Cloudflare Pages custom domain)
  - `https://www.demenart.com` → **Active + SSL enabled**
  - `https://demenart.pages.dev` → vẫn chạy (default Pages domain, giữ để test)
  - Nghiệm thu LIVE: trang chủ "DMA – Dế Mèn Art" render; **đăng nhập super_admin → `/portal` load data đúng** (SSR + Supabase + RLS chạy trên domain thật).
- **📧 EMAIL công ty — SỐNG, không gián đoạn:** test gửi tới `info@demenart.com` (GoDaddy/Microsoft365) → **nhận được** sau khi đổi NS. 9 record email migrate đủ + đúng DNS-only.
- **Edge sống:** `get_signed_media_url` (2 nhánh đọc) · `upload_media` (2 nhánh ghi). **`bunny-sign-test` ĐÃ XÓA** (✅ nợ §4 v14 mục 1 trả xong).
- **Media data:** 4 row hợp lệ (2 audio CTAN + ảnh Jenny `jenny_buoi1.jpg` + ảnh nhóm). Row trùng đã xóa.

---

## 3. HẠ TẦNG DEPLOY — CHI TIẾT (nguồn sự thật cho phiên sau)

### 3.1 Cloudflare Pages
- **Account:** `Huynhtranhuythinh@gmail.com` (Free plan).
- **Project:** `demenart` (Workers & Pages) — connect GitHub `huynhtranhuythinh/demenart`, branch `main`, **automatic deployments ON** (push `main` → tự build+deploy).
- **Build config:** Framework preset **None** · Build command **`bun run build`** · Build output dir **`dist`** · Root dir trống.
- **Env vars (build-time, đúng D63 — chỉ public):** `VITE_SUPABASE_URL=https://xcvhacymrbhdhohyylyq.supabase.co` · `VITE_SUPABASE_PUBLISHABLE_KEY=eyJhbGci…` (publishable/anon — public-safe). **KHÔNG** service_role/Bunny ở đây.
- **Cloudflare IDs:** Zone ID `7e3e2049b553fdc23e6e2d7e4f7195d7` · Account ID `8fdfc6a77a6d28a0a9781f9c66008a49`.

### 3.2 ⭐ FIX then-chốt: nitro preset cho Lovable TanStack Start trên Cloudflare Pages (→ D84)
- **Triệu chứng:** Build "Success" nhưng `/` trả **404** (cả trên Vercel lẫn lần đầu Cloudflare Pages). Build log: `[@lovable.dev/vite-tanstack-config] No Lovable context detected — skipping nitro deploy plugin. Pass nitro: true to force-enable.` + `No functions dir at /functions found. Skipping.`
- **Gốc rễ:** Plugin Lovable `@lovable.dev/vite-tanstack-config` đã bundle nitro (target cloudflare mặc định) nhưng **tự tắt khi không phát hiện môi trường Lovable** → build chỉ ra `dist/client` + `dist/server` (vite SSR thô), **THIẾU `_worker.js`** → Pages không có entry SSR → 404.
- **FIX (đúng cách plugin tự chỉ, KHÔNG gây duplicate):** thêm key `nitro` vào `defineConfig` trong `vite.config.ts`:
  ```ts
  import { defineConfig } from "@lovable.dev/vite-tanstack-config";
  export default defineConfig({
    tanstackStart: { server: { entry: "server" } },
    nitro: { preset: "cloudflare-pages" },   // ← thêm dòng này
  });
  ```
  → preset `cloudflare-pages` build ra `dist/_worker.js` + `dist/_routes.json` (Pages tự nhận) trong **cùng `dist`** (không đổi output dir). **KHÔNG** thêm plugin `nitro()` vào mảng plugins (cái đó mới gây duplicate-plugin như comment trong file cảnh báo). nitro là **build-only** → KHÔNG ảnh hưởng Lovable preview (dev-server).
- **Cách áp dụng:** Jean tự sửa `vite.config.ts` trực tiếp trong Lovable code editor (hoặc GitHub) → commit → sync `main` → Cloudflare auto-rebuild. **KHÔNG nhờ AI Lovable viết** (sợ hiểu nhầm thành thêm plugin). Build sau fix: nitro chạy, có `_worker.js`, web lên.
- **Không cần `nodejs_compat`** (build chạy ngon không bật cờ này — để standby nếu sau có runtime Node-API error).
- **❌ Vercel bị bỏ:** Lovable config khóa nitro target = cloudflare; trên Vercel build ra `dist/server/` không phải `.vercel/output` → 404; `NITRO_PRESET=vercel` không override; fix bằng sửa vite.config thêm `nitro({preset:vercel})` có rủi ro vỡ Lovable preview (case dev.to ghi nhận). → **Cloudflare Pages là đường đúng cho Lovable TanStack Start** vì nó build sẵn cho cloudflare target.

### 3.3 DNS — chuyển `demenart.com` sang Cloudflare (giữ email GoDaddy)
- **Trước:** NS ở GoDaddy (ns41/ns42.domaincontrol.com), email GoDaddy/Microsoft365 (MX secureserver), web A@→160.153.0.115 (parking).
- **Cách làm (Cloudflare Pages BẮT BUỘC domain dùng NS Cloudflare — không cho giữ NS GoDaddy + CNAME):**
  1. Cloudflare → **Add a site** → **Connect a domain** (KHÔNG "Transfer" — không đổi ownership) → `demenart.com` → Free → **Import DNS automatically** → Cloudflare quét.
  2. **Đối chiếu 9 record email sống còn** + sửa: tắt proxy CNAME `email` (cam→xám DNS-only) + **thêm tay 2 CNAME DKIM** (`secureserver1/2._domainkey`) mà scan bỏ sót. Mọi email record = **DNS only (xám)** — proxy cam giết email.
  3. DNSSEC GoDaddy đã **TẮT** (điều kiện đổi NS an toàn — nếu bật phải tắt trước).
  4. GoDaddy → **Máy chủ tên** → "Dùng máy chủ tên của riêng tôi" → `aria.ns.cloudflare.com` + `armfazh.ns.cloudflare.com` (NS Cloudflare cấp riêng domain này) → Lưu.
  5. Propagate ~5 phút → Cloudflare báo **"Your domain is now protected by Cloudflare"**.
  6. Pages → project `demenart` → **Custom domains** → Set up: thêm `demenart.com` (Cloudflare thay A-parking bằng CNAME→`demenart.pages.dev`) + `www.demenart.com` → cả 2 **Active + SSL**.
- **⭐ Nguyên tắc giữ email khi đổi NS:** chỉ đụng record WEB (A `@`, CNAME `www`); **TUYỆT ĐỐI giữ đủ** MX×2 + CNAME email + 2 DKIM + SPF×2 + DMARC + SRV autodiscover, tất cả **DNS-only**. Undo = đổi NS GoDaddy về ns41/ns42.domaincontrol.com (DNS cũ ở GoDaddy không bị xóa). Backup zone file đã tải.

### 3.4 Supabase Auth URL Configuration (cho domain mới)
- **Site URL:** đổi `http://localhost:3000` → **`https://demenart.com`** (không wildcard).
- **Redirect URLs:** thêm `https://demenart.com/**` + `https://www.demenart.com/**` + `https://demenart.pages.dev/**` (giữ nguyên các URL Lovable/preview/localhost cũ → dev+preview vẫn login).
- Quên bước này = login trên domain mới lỗi redirect.

---

## 4. NGHIỆM THU v15 (bằng chứng thật)

| Hạng mục | Bằng chứng |
|---|---|
| **Dọn — Edge** | `bunny-sign-test` đã xóa (không còn trong Edge Functions list). |
| **Dọn — media** | Row trùng `568b6c5a` + object Bunny xóa; verify `rogue_gone:true`/`total_media_rows:4`/moment Jenny 1 ảnh. |
| **Build fix** | Build log sau sửa vite.config: nitro chạy (hết "skipping nitro deploy plugin"), có `_worker.js`, Deploy Success. |
| **Web LIVE** | `demenart.pages.dev` rồi `demenart.com` → trang chủ "DMA – Dế Mèn Art" + Đăng nhập; SSL hợp lệ. |
| **Login LIVE** | super_admin → `/portal` "Xin chào, Quản trị viên Test" / role `super_admin` (SSR+Supabase+RLS chạy trên domain thật). |
| **Custom domains** | demenart.com + www.demenart.com đều **Active + SSL enabled**. |
| **📧 Email LIVE** | Gửi test → **info@demenart.com nhận được** sau đổi NS (email không gián đoạn — 9 record migrate đúng). |
| **Supabase Auth** | Site URL=`https://demenart.com` + 3 Redirect URL production thêm xong. |

---

## 5. VIỆC TREO (cập nhật — trả nợ §4 v14, còn lại + mới)

1. ✅ **(TRẢ XONG)** ~~XÓA Edge `bunny-sign-test`~~ — đã xóa v15.
2. ✅ **(TRẢ XONG)** ~~ảnh móc nhầm moment Jenny~~ — đã xóa row trùng v15. **ĐÍNH CHÍNH:** ảnh "Vịt Con"/`jenny_buoi1.jpg` (row `614aa02e`) là **ảnh demo HỢP LỆ của Jenny, GIỮ** (v14 §4 mục 2 mô tả sai là rác).
3. **⚠️ SPF KÉP (mới phát hiện) — cấu hình SAI sẵn từ trước trên GoDaddy, đã migrate y nguyên sang Cloudflare.** `demenart.com` có **2 record TXT SPF** (`v=spf1 include:spf.flockmail.com include:spf.mx.hostinger.com include:relay.mailchannels.net ~all` **+** `v=spf1 include:secureserver.net -all`). Chuẩn DNS chỉ cho **1 SPF/domain** → 2 cái có thể làm mail gửi đi vào spam. **Cố ý GIỮ NGUYÊN khi deploy** (không sửa 2 thứ cùng lúc). **Dọn = việc riêng:** gộp thành 1 dòng SPF hợp lệ — cần xác định domain đang gửi mail thật qua provider nào (flockmail/hostinger/mailchannels/secureserver) rồi merge include. Làm khi rảnh, test kỹ.
4. **Lưu migration vào repo:** vẫn nợ **mig 026–034** (`.sql`) + Edge `get_signed_media_url/index.ts` + `upload_media/index.ts` cùng 001–025. (Phiên v15 không sinh mig mới.)
5. **Sửa file `seed_007_ops_config` repo:** `body_template` bỏ "Bé " thừa (đã UPDATE live từ phiên trước).
6. **Xác nhận đã `drop function public._neg_test();`** (helper tạm test consent v9).
7. **Caption "[seed]"** còn ở moment thật trong DB (UI strip client). Cosmetic.
8. **Row test treo:** `child_observations.note`/`child_journey.entry_type`='WRITE-BLOCK TEST (panel)' + `learning_moments.caption='[panel] write-block test'`. Không gấp.
9. **(MỚI) Vercel project `demenart` dormant** — đã tạo lúc thử Vercel (404), để yên vô hại; có thể xóa cho gọn account Vercel.

---

## 6. NGÃ KẾ (chọn đầu phiên sau)

- **A. Onboard data trường thật** — giờ đã có domain + hạ tầng live, bước tiếp là đưa dữ liệu trường thật vào (thay demo) để pilot.
- **B. `request_sensitive_access`** (admin xem PII trẻ CÓ AUDIT — D48 carve-out). Engine vừa phải; "cửa có kiểm soát".
- **C. `create/resolve_private_share_link`** (share ảnh khoảnh khắc cho PH/ông bà ngoài app — D55/D66). Token nội bộ + expiry + scope; resolve = Edge public bypass RLS.
- **D. UI Chặng 2 tiếp** — thêm màn portal còn thiếu (mới có consent/support/journal/curriculum/curriculum-admin/moments/notifications).
- **E. Dọn nhẹ:** SPF kép (§5 mục 3) + lưu mig vào repo (§5 mục 4).

> **Gợi ý nhịp:** Hạ tầng đã xong (web+email live trên `demenart.com`). **Nên onboard data trường thật (A)** để biến pilot thành thật, hoặc **share link (C)** để PH khoe ảnh con — cả hai tăng giá trị cảm nhận. **B** là admin tooling. Dọn (E) xen kẽ khi rảnh.

---

## 7. KỶ LUẬT GIỮ NGUYÊN (nhắc nhanh — phiên hạ tầng)

- **D63 (secret server-side):** env Cloudflare Pages CHỈ `VITE_SUPABASE_URL` + `VITE_SUPABASE_PUBLISHABLE_KEY` (public-safe). service_role/Bunny CHỈ ở Edge secrets. Đã giữ đúng khi deploy.
- **Đổi NS = giữ email:** chỉ đụng record web; giữ đủ MX/DKIM/SPF/SRV DNS-only; đổi NS reversible (undo về domaincontrol.com).
- **Lovable TanStack Start → Cloudflare Pages** (D84 mới): build cho cloudflare target sẵn; fix 404 = `nitro: { preset: "cloudflare-pages" }` (key config, KHÔNG plugin → tránh duplicate). KHÔNG dùng Vercel cho Lovable TanStack Start.
- **Schema do migration Claude sở hữu (D5):** phiên này KHÔNG đụng DB — chỉ hạ tầng + 1 file `vite.config.ts`. Lovable 2-way sync vẫn ON trên `main`.
- **Audit thật trước khi viết (D1):** trước khi đổi DNS đã catalog đủ 19 record GoDaddy + đối chiếu từng record email sau khi Cloudflare import.

---

*Handoff v15 — 2026-06-26 08:15 GMT+7. ✅ DỌN §4 + DEPLOY LÊN demenart.com — WEB & EMAIL LIVE. Ngã D: xóa `bunny-sign-test` + row media trùng (đính chính: ảnh "Vịt Con"/`jenny_buoi1.jpg` là ảnh Jenny HỢP LỆ, không phải rác như v14 ghi sai). Ngã A: deploy Lovable TanStack Start → GitHub → **Cloudflare Pages** → `demenart.com`+`www` (Active+SSL). Fix then-chốt 404: `nitro:{preset:"cloudflare-pages"}` trong vite.config (Lovable plugin tự tắt nitro ngoài sandbox → thiếu `_worker.js`); KHÔNG dùng Vercel. DNS chuyển NS GoDaddy→Cloudflare (aria/armfazh.ns.cloudflare.com) giữ đủ 9 record email DNS-only → **email info@demenart.com nhận test OK**. Supabase Auth Site URL+Redirect cho domain mới. **DB KHÔNG đổi: 46 bảng · 38 hàm definer · 125 policy · mig 001→034 · seed 001→009.** SYSTEM_MAP v0.16; RULES +D84 (deploy Cloudflare Pages). Nghiệm thu LIVE: web render + super_admin login `/portal` + email nhận + custom domain SSL. Việc treo mới: SPF kép cần gộp (sai sẵn từ GoDaddy), Vercel project dormant. Kế: onboard data trường thật · request_sensitive_access · share link. Nguồn: A–G + RULES + SYSTEM_MAP v0.16.*
