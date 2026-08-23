// =====================================================================
// DMA Edge Function — get_signed_media_url
// Nguồn: RULES D74 (topology 3-zone, secret-per-zone, ký Standard SHA256)
//        + D75 (gate học liệu qua check_curriculum_media_access) + Tài liệu G §12.
//
// Vai trò: ĐIỀU PHỐI (không nhúng luật). auth → gate engine (service_role)
//          → ký Bunny token theo zone → ghi audit → trả signed_url.
//
// ⚠️ Deploy: "Verify JWT" = OFF (hàm tự auth — khuyến nghị Supabase; cổng JWT yếu).
// Secrets cần (Edge Function Secrets):
//   SUPABASE_URL, SUPABASE_ANON_KEY, SUPABASE_SERVICE_ROLE_KEY (auto-injected)
//   BUNNY_LEARNING_HOST, BUNNY_LEARNING_TOKEN_KEY        (zone dma-learning — đang dùng)
//   BUNNY_PRIVATE_HOST,  BUNNY_PRIVATE_TOKEN_KEY         (zone dma-private — khi ráp ảnh trẻ)
//
// V1 slice: chỉ học liệu (private_curriculum). Ảnh trẻ (consent) ráp sau qua media_consent_check.
// =====================================================================

import { createClient } from "jsr:@supabase/supabase-js@2";

const cors = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, content-type, apikey",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: cors });
  try {
    const URL_ = Deno.env.get("SUPABASE_URL")!;
    const ANON = Deno.env.get("SUPABASE_ANON_KEY")!;
    const SVCKEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;

    // 1) Auth user thật từ JWT (KHÔNG dựa cổng Verify JWT)
    const auth = req.headers.get("Authorization") ?? "";
    const userClient = createClient(URL_, ANON, { global: { headers: { Authorization: auth } } });
    const { data: { user } } = await userClient.auth.getUser();
    if (!user) return json({ allowed: false, reason: "not_authenticated" }, 401);

    const body = await req.json().catch(() => ({}));
    const mediaId = body.media_id;
    if (!mediaId) return json({ error: "missing_media_id" }, 400);

    // 2) Tra profile (service_role — media_assets/profiles deny-by-default ở client)
    const svc = createClient(URL_, SVCKEY);
    const { data: prof } = await svc
      .from("profiles").select("id, school_id").eq("user_id", user.id).maybeSingle();
    if (!prof) return json({ allowed: false, reason: "no_profile" }, 403);

    // 3) Gate engine (D75) — verdict + path/zone/cờ
    const { data: v, error: gErr } = await svc.rpc("check_curriculum_media_access", {
      p_media_id: mediaId, p_viewer_profile: prof.id,
    });
    if (gErr) return json({ error: "gate_error", detail: gErr.message }, 500);

    if (!v?.allowed) {
      await svc.rpc("write_audit_log", {
        p_action: "media_access_denied",
        p_fields: {
          actor_id: prof.id, entity_type: "media_asset", entity_id: mediaId,
          media_id: mediaId, metadata: { reason: v?.reason, kind: "curriculum" },
        },
      });
      return json(v ?? { allowed: false, reason: "denied" }, 403);
    }

    // 4) Ký Bunny Standard URL Token Auth (SHA256) theo zone (D74)
    const host = bunnyHost(v.cdn_pull_zone);
    const key = bunnyKey(v.cdn_pull_zone);
    if (!host || !key) return json({ error: "zone_secret_missing", zone: v.cdn_pull_zone }, 500);

    const ttl = Math.max(60, (v.expires_policy_minutes ?? 10) * 60);
    const expires = Math.floor(Date.now() / 1000) + ttl;
    const path = v.bunny_path;
    const digest = await crypto.subtle.digest(
      "SHA-256", new TextEncoder().encode(`${key}${path}${expires}`),
    );
    const token = b64url(new Uint8Array(digest));
    const signed_url = `https://${host}${path}?token=${token}&expires=${expires}`;

    // 5) Audit thành công
    await svc.rpc("write_audit_log", {
      p_action: "curriculum_media_view",
      p_fields: {
        actor_id: prof.id, entity_type: "media_asset", entity_id: mediaId,
        media_id: mediaId, school_id: v.school_id,
        metadata: { program_id: v.program_id, ttl_sec: ttl, zone: v.cdn_pull_zone },
      },
    });

    return json({
      allowed: true, signed_url, expires,
      stream_only: v.stream_only,
      download_allowed: v.download_allowed,   // V1: false — UI ẩn nút tải (D65/D68)
      watermark_required: v.watermark_required, // UI render watermark động (G §9)
    });
  } catch (e) {
    return json({ error: String(e) }, 500);
  }
});

// --- helpers: tra host+key THEO ZONE (secret-per-zone, D74) ---
function bunnyHost(z: string) {
  return z === "dma-learning" ? Deno.env.get("BUNNY_LEARNING_HOST")
    : z === "dma-private" ? Deno.env.get("BUNNY_PRIVATE_HOST")
    : undefined;
}
function bunnyKey(z: string) {
  return z === "dma-learning" ? Deno.env.get("BUNNY_LEARNING_TOKEN_KEY")
    : z === "dma-private" ? Deno.env.get("BUNNY_PRIVATE_TOKEN_KEY")
    : undefined;
}
function b64url(b: Uint8Array) {
  let s = "";
  for (const x of b) s += String.fromCharCode(x);
  return btoa(s).replace(/\+/g, "-").replace(/\//g, "_").replace(/=+$/, "");
}
function json(o: unknown, s = 200) {
  return new Response(JSON.stringify(o, null, 2), {
    status: s, headers: { ...cors, "Content-Type": "application/json" },
  });
}
