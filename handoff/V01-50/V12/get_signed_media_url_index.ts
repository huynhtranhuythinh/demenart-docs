import { createClient } from "jsr:@supabase/supabase-js@2";
const cors = { "Access-Control-Allow-Origin":"*","Access-Control-Allow-Headers":"authorization, content-type, apikey","Access-Control-Allow-Methods":"POST, OPTIONS" };

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: cors });
  try {
    const URL_ = Deno.env.get("SUPABASE_URL")!, ANON = Deno.env.get("SUPABASE_ANON_KEY")!, SVCKEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
    const auth = req.headers.get("Authorization") ?? "";
    const userClient = createClient(URL_, ANON, { global: { headers: { Authorization: auth } } });
    const { data: { user } } = await userClient.auth.getUser();
    if (!user) return json({ allowed:false, reason:"not_authenticated" }, 401);

    const body = await req.json().catch(()=>({}));
    const mediaId = body.media_id;
    if (!mediaId) return json({ error:"missing_media_id" }, 400);

    const svc = createClient(URL_, SVCKEY);
    const { data: prof } = await svc.from("profiles").select("id, school_id").eq("user_id", user.id).maybeSingle();
    if (!prof) return json({ allowed:false, reason:"no_profile" }, 403);

    // Fetch media row → định tuyến theo cột link nào có mặt (KHÔNG hardcode enum)
    const { data: media, error: mErr } = await svc.from("media_assets")
      .select("id, cdn_pull_zone, bunny_path, linked_moment_id, linked_lesson_version_id, linked_school_id, download_allowed, watermark_required, stream_only, expires_policy_minutes")
      .eq("id", mediaId).maybeSingle();
    if (mErr)  return json({ error:"media_lookup_error", detail:mErr.message }, 500);
    if (!media) return json({ allowed:false, reason:"media_not_found" }, 404);

    // mặc định ký bằng chính media row; nhánh curriculum sẽ ghi đè bằng verdict engine
    let zone  = media.cdn_pull_zone as string;
    let path  = media.bunny_path as string;
    let flags = { stream_only: media.stream_only, download_allowed: media.download_allowed, watermark_required: media.watermark_required };
    let ttlMin = media.expires_policy_minutes ?? 10;
    let auditAction = "media_view";
    let auditSchool: string | null = media.linked_school_id ?? null;
    let auditMeta: Record<string, unknown> = {};

    if (media.linked_lesson_version_id) {
      // ───────── NHÁNH HỌC LIỆU (D75 — entitlement môn) ─────────
      const { data: v, error: gErr } = await svc.rpc("check_curriculum_media_access", { p_media_id: mediaId, p_viewer_profile: prof.id });
      if (gErr) return json({ error:"gate_error", detail:gErr.message }, 500);
      if (!v?.allowed) {
        await svc.rpc("write_audit_log", { p_action:"media_access_denied", p_fields:{ actor_id:prof.id, entity_type:"media_asset", entity_id:mediaId, media_id:mediaId, metadata:{ reason:v?.reason, kind:"curriculum" } } });
        return json(v ?? { allowed:false, reason:"denied" }, 403);
      }
      zone = v.cdn_pull_zone; path = v.bunny_path;
      flags = { stream_only:v.stream_only, download_allowed:v.download_allowed, watermark_required:v.watermark_required };
      ttlMin = v.expires_policy_minutes ?? ttlMin;
      auditSchool = v.school_id ?? auditSchool;
      auditAction = "curriculum_media_view";
      auditMeta = { program_id: v.program_id, kind:"curriculum" };

    } else if (media.linked_moment_id) {
      // ───────── NHÁNH ẢNH TRẺ (D71 — consent min(trường,PH)) ─────────
      const { data: c, error: cErr } = await svc.rpc("media_consent_check", { p_moment_id: media.linked_moment_id, p_viewer_profile: prof.id, p_action: "view" });
      if (cErr) return json({ error:"consent_error", detail:cErr.message }, 500);
      if (!c?.allowed) {
        await svc.rpc("write_audit_log", { p_action:"media_access_denied", p_fields:{ actor_id:prof.id, entity_type:"media_asset", entity_id:mediaId, media_id:mediaId, metadata:{ reason:c?.reason, kind:"child", blocking_children:c?.blocking_children } } });
        return json(c ?? { allowed:false, reason:"denied" }, 403);
      }
      auditAction = "child_media_view";
      auditMeta = { moment_id: media.linked_moment_id, kind:"child", consent_reason:c.reason };

    } else {
      return json({ allowed:false, reason:"unsupported_media_type" }, 403);
    }

    const host = bunnyHost(zone), key = bunnyKey(zone);
    if (!host || !key) return json({ error:"zone_secret_missing", zone }, 500);

    const ttl = Math.max(60, ttlMin * 60);
    const expires = Math.floor(Date.now()/1000) + ttl;
    const digest = await crypto.subtle.digest("SHA-256", new TextEncoder().encode(`${key}${path}${expires}`));
    const token = b64url(new Uint8Array(digest));
    const signed_url = `https://${host}${path}?token=${token}&expires=${expires}`;

    await svc.rpc("write_audit_log", { p_action:auditAction, p_fields:{ actor_id:prof.id, entity_type:"media_asset", entity_id:mediaId, media_id:mediaId, school_id:auditSchool, metadata:{ ...auditMeta, ttl_sec:ttl, zone } } });

    return json({ allowed:true, signed_url, expires, ...flags });
  } catch (e) { return json({ error:String(e) }, 500); }
});

function bunnyHost(z:string){ return z==="dma-learning"?Deno.env.get("BUNNY_LEARNING_HOST"):z==="dma-private"?Deno.env.get("BUNNY_PRIVATE_HOST"):undefined; }
function bunnyKey(z:string){ return z==="dma-learning"?Deno.env.get("BUNNY_LEARNING_TOKEN_KEY"):z==="dma-private"?Deno.env.get("BUNNY_PRIVATE_TOKEN_KEY"):undefined; }
function b64url(b:Uint8Array){ let s=""; for(const x of b) s+=String.fromCharCode(x); return btoa(s).replace(/\+/g,"-").replace(/\//g,"_").replace(/=+$/,""); }
function json(o:unknown,s=200){ return new Response(JSON.stringify(o,null,2),{status:s,headers:{...cors,"Content-Type":"application/json"}}); }
