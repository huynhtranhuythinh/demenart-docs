import { createClient } from "jsr:@supabase/supabase-js@2";
const cors = { "Access-Control-Allow-Origin":"*","Access-Control-Allow-Headers":"authorization, content-type, apikey, x-client-info, x-supabase-api-version","Access-Control-Allow-Methods":"POST, OPTIONS" };

// v24 (V123-M1): + ADDITIVE DELIVERY-TIME IMAGE VARIANTS (Bunny Optimizer, width+quality only).
//   For eligible dma-private STILL images (jpeg/png/webp) the response gains a `variants` object
//   { thumb, card, stage, fullscreen } alongside the UNCHANGED backward-compatible `signed_url`.
//   Transform params are SERVER CONSTANTS (locked table) — no client input ever enters the hash.
//   Params are co-signed into the Bunny token per Token-Auth query-parameter canonicalization
//   (key + path + expires + sortedParams; params ascending; token/expires excluded; not url-encoded),
//   so changing width/quality/path on a minted URL invalidates the signature (403). Original signing
//   is byte-identical to v23 (empty param set). Stream / curriculum / non-image paths are untouched.
// v23 (V109B): NHÁNH FAMILY thêm FALLBACK CONTRIBUTION (mirror pattern fallback nhánh parent v22):
//   media source='family' + linked_space_id → thử check_family_card_media_access (card);
//   nếu deny → thử check_family_contribution_media_access (voice contribution) — RPC service re-check:
//   contribution ACTIVE bắt buộc (withdrawn → deny MỌI actor) × Effective Access Card của viewer
//   × hidden → CHỈ contributor hoặc guardian. Consent withdraw / removal chặn NGAY tại tầng ký (D281).
//   Card path GIỮ NGUYÊN từng chữ. Logic sống ở DB — Edge không tự suy diễn quyền.
// v22 (V108): + NHÁNH FAMILY — gate DUY NHẤT = RPC service check_family_card_media_access
//   (a) media source='family' + linked_space_id (native family card): member active của đÚNG space,
//       card published + MIN-consent còn hiệu lực TẠI THờI ĐIỂM KÝ, hoặc creator xem draft của mình.
//   (b) VÁ NỢ V107: media kỷ vật PH (source='parent') — khi viewer KHÔNG phải guardian,
//       fallback đường family: media backs card đã publish trong space mà viewer là member active
//       + consent đủ → ký được. Consent withdraw / membership removed → chặn NGAY tại tầng ký.
//   Guardian path (child_parents) GIỮ NGUYÊN từng chữ.
// v21 (V94): + NHÁNH KỶ VẬT PHỤ HUYNH — media source='parent' + linked_child_id.
// v20: + NHÁNH SÁNG TÁC CỦA BÉ (Cổng Kid) — media source='kid' + linked_child_id.
// 3 nhánh cũ (học liệu / ảnh trẻ moment / kho trường) giữ nguyên.
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

    const { data: media, error: mErr } = await svc.from("media_assets")
      .select("id, access_level, cdn_pull_zone, bunny_path, bunny_stream_video_id, linked_moment_id, linked_lesson_version_id, linked_school_id, linked_session_id, linked_child_id, linked_space_id, source, state, download_allowed, watermark_required, stream_only, expires_policy_minutes, file_type")
      .eq("id", mediaId).maybeSingle();
    if (mErr)  return json({ error:"media_lookup_error", detail:mErr.message }, 500);
    if (!media) return json({ allowed:false, reason:"media_not_found" }, 404);

    let zone  = media.cdn_pull_zone as string;
    let path  = media.bunny_path as string;
    let streamVideoId = media.bunny_stream_video_id as string | null;
    let flags = { stream_only: media.stream_only, download_allowed: media.download_allowed, watermark_required: media.watermark_required };
    let ttlMin = media.expires_policy_minutes ?? 10;
    let auditAction = "media_view";
    let auditSchool: string | null = media.linked_school_id ?? null;
    let auditMeta: Record<string, unknown> = {};
    let fileType = (media.file_type ?? "") as string; // V123-M1: MIME gate for variant eligibility

    if (media.linked_lesson_version_id) {
      // ───── NHÁNH HỌC LIỆU (D75 — entitlement môn) ─────
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
      // ───── NHÁNH ẢNH TRẺ (D71 — consent min(trường,PH)) ─────
      const { data: c, error: cErr } = await svc.rpc("media_consent_check", { p_moment_id: media.linked_moment_id, p_viewer_profile: prof.id, p_action: "view" });
      if (cErr) return json({ error:"consent_error", detail:cErr.message }, 500);
      if (!c?.allowed) {
        await svc.rpc("write_audit_log", { p_action:"media_access_denied", p_fields:{ actor_id:prof.id, entity_type:"media_asset", entity_id:mediaId, media_id:mediaId, metadata:{ reason:c?.reason, kind:"child", blocking_children:c?.blocking_children } } });
        return json(c ?? { allowed:false, reason:"denied" }, 403);
      }
      auditAction = "child_media_view";
      auditMeta = { moment_id: media.linked_moment_id, kind:"child", consent_reason:c.reason };

    } else if (media.source === "kid" && media.linked_child_id) {
      // ───── NHÁNH SÁNG TÁC CỦA BÉ (Cổng Kid) — ba mẹ của bé xem, KHÔNG cần consent ─────
      const { data: link } = await svc.from("child_parents")
        .select("child_id").eq("child_id", media.linked_child_id).eq("parent_profile_id", prof.id).maybeSingle();
      if (!link) {
        await svc.rpc("write_audit_log", { p_action:"media_access_denied", p_fields:{ actor_id:prof.id, entity_type:"media_asset", entity_id:mediaId, media_id:mediaId, metadata:{ reason:"not_authorized", kind:"kid_creation" } } });
        return json({ allowed:false, reason:"not_authorized" }, 403);
      }
      auditAction = "kid_creation_view";
      auditMeta = { kind:"kid_creation", child_id: media.linked_child_id };

    } else if (media.source === "family" && media.linked_space_id) {
      // ───── NHÁNH FAMILY (V108 card · V109B contribution) — gate ở DB ─────
      const { data: fam, error: famErr } = await svc.rpc("check_family_card_media_access", { p_media_id: mediaId, p_viewer_profile: prof.id });
      if (famErr) return json({ error:"gate_error", detail:famErr.message }, 500);
      if (fam?.allowed) {
        auditAction = "family_card_media_view";
        auditMeta = { kind: fam.kind, space_id: fam.space_id, card_id: fam.card_id };
      } else {
        // ── V109B: fallback CONTRIBUTION — RPC service re-check toàn bộ
        //    (active × Effective Access × hidden→contributor/guardian; withdrawn→deny MỌI actor)
        const { data: fc, error: fcErr } = await svc.rpc("check_family_contribution_media_access", { p_media_id: mediaId, p_viewer_profile: prof.id });
        if (fcErr || !fc?.allowed) {
          await svc.rpc("write_audit_log", { p_action:"media_access_denied", p_fields:{ actor_id:prof.id, entity_type:"media_asset", entity_id:mediaId, media_id:mediaId, metadata:{ reason:"not_authorized", kind:"family_card" } } });
          return json({ allowed:false, reason:"not_authorized" }, 403);
        }
        auditAction = "family_contribution_media_view";
        auditMeta = { kind: fc.kind, space_id: fc.space_id, card_id: fc.card_id, contribution_id: fc.contribution_id };
      }

    } else if (media.source === "parent" && media.linked_child_id) {
      // ───── NHÁNH KỶ VẬT PHỤ HUYNH (V94) — guardian path GIỮ NGUYÊN ─────
      const { data: link } = await svc.from("child_parents")
        .select("child_id").eq("child_id", media.linked_child_id).eq("parent_profile_id", prof.id).maybeSingle();
      const { data: mm } = await svc.from("parent_memory_media")
        .select("memory_id, parent_memories!inner(state)")
        .eq("media_id", mediaId).is("deleted_at", null)
        .eq("parent_memories.state", "active").limit(1).maybeSingle();
      if (link && mm && media.state === "active") {
        auditAction = "parent_memory_media_view";
        auditMeta = { kind:"parent_memory", child_id: media.linked_child_id, memory_id: (mm as any).memory_id };
      } else {
        // ── V108 (vá nợ V107): đường FAMILY cho non-guardian member —
        //    media phải backs một card ĐÃ PUBLISH trong space mà viewer là member active,
        //    consent MIN còn hiệu lực tại thời điểm ký (RPC re-check toàn bộ).
        const { data: fam, error: famErr } = await svc.rpc("check_family_card_media_access", { p_media_id: mediaId, p_viewer_profile: prof.id });
        if (famErr || !fam?.allowed) {
          await svc.rpc("write_audit_log", { p_action:"media_access_denied", p_fields:{ actor_id:prof.id, entity_type:"media_asset", entity_id:mediaId, media_id:mediaId, metadata:{ reason:"not_authorized", kind:"parent_memory" } } });
          return json({ allowed:false, reason:"not_authorized" }, 403);
        }
        auditAction = "family_card_media_view";
        auditMeta = { kind: fam.kind, space_id: fam.space_id, card_id: fam.card_id, child_id: media.linked_child_id };
      }

    } else if (media.access_level === "private_school_resource") {
      // ───── NHÁNH MEDIA BUỔI / KHO TRƯờNG (Org Cloud — cùng trường) ─────
      if (!prof.school_id || prof.school_id !== media.linked_school_id) {
        await svc.rpc("write_audit_log", { p_action:"media_access_denied", p_fields:{ actor_id:prof.id, entity_type:"media_asset", entity_id:mediaId, media_id:mediaId, metadata:{ reason:"not_school_member", kind:"school_resource" } } });
        return json({ allowed:false, reason:"not_school_member" }, 403);
      }
      auditAction = "school_media_view";
      auditMeta = { kind:"school_resource", session_id: media.linked_session_id };

    } else {
      return json({ allowed:false, reason:"unsupported_media_type" }, 403);
    }

    const ttl = Math.max(60, ttlMin * 60);
    const expires = Math.floor(Date.now()/1000) + ttl;

    if (zone === "dma-stream") {
      const host = Deno.env.get("BUNNY_STREAM_HOST");
      const key  = Deno.env.get("BUNNY_STREAM_TOKEN_KEY");
      if (!host || !key) return json({ error:"zone_secret_missing", zone }, 500);

      const dir = path.endsWith("/") ? path : path + "/";
      const parameterData = `token_path=${dir}`;
      const hashableBase = `${key}${dir}${expires}${parameterData}`;
      const digest = await crypto.subtle.digest("SHA-256", new TextEncoder().encode(hashableBase));
      const token = b64url(new Uint8Array(digest));
      const authPrefix = `/bcdn_token=${token}&expires=${expires}&token_path=${encodeURIComponent(dir)}`;
      const playback_url = `https://${host}${authPrefix}${dir}playlist.m3u8`;
      const mp4_fallback = `https://${host}${authPrefix}${dir}play_720p.mp4`;

      await svc.rpc("write_audit_log", { p_action:auditAction, p_fields:{ actor_id:prof.id, entity_type:"media_asset", entity_id:mediaId, media_id:mediaId, school_id:auditSchool, metadata:{ ...auditMeta, ttl_sec:ttl, zone, kind_delivery:"hls_stream", stream_video_id:streamVideoId } } });

      return json({ allowed:true, is_stream:true, playback_url, mp4_fallback, signed_url:playback_url, expires, ...flags });
    }

    const host = bunnyHost(zone), key = bunnyKey(zone);
    if (!host || !key) return json({ error:"zone_secret_missing", zone }, 500);

    // V123-M1: original signed URL — byte-identical to v23 (empty transform param set).
    const signed_url = await signBunny(host, key, path, expires, null);

    // V123-M1: additive delivery-time image variants (Bunny Optimizer, width+quality only).
    // Eligible ONLY for dma-private STILL images (jpeg/png/webp). No gif/animated, no stream,
    // no curriculum/learning. Transform params are SERVER CONSTANTS — no client string enters the hash.
    let variants: Record<string, string> | undefined;
    if (zone === "dma-private" && IMAGE_VARIANT_TYPES.has(fileType.toLowerCase())) {
      variants = {};
      for (const [role, p] of Object.entries(IMAGE_VARIANTS)) {
        variants[role] = await signBunny(host, key, path, expires, p);
      }
    }

    await svc.rpc("write_audit_log", { p_action:auditAction, p_fields:{ actor_id:prof.id, entity_type:"media_asset", entity_id:mediaId, media_id:mediaId, school_id:auditSchool, metadata:{ ...auditMeta, ttl_sec:ttl, zone, variants: variants ? Object.keys(variants) : null } } });

    return json({ allowed:true, is_stream:false, signed_url, ...(variants ? { variants } : {}), expires, ...flags });
  } catch (e) { return json({ error:String(e) }, 500); }
});

function bunnyHost(z:string){ return z==="dma-learning"?Deno.env.get("BUNNY_LEARNING_HOST"):z==="dma-private"?Deno.env.get("BUNNY_PRIVATE_HOST"):undefined; }
function bunnyKey(z:string){ return z==="dma-learning"?Deno.env.get("BUNNY_LEARNING_TOKEN_KEY"):z==="dma-private"?Deno.env.get("BUNNY_PRIVATE_TOKEN_KEY"):undefined; }
function b64url(b:Uint8Array){ let s=""; for(const x of b) s+=String.fromCharCode(x); return btoa(s).replace(/\+/g,"-").replace(/\//g,"_").replace(/=+$/,""); }
function json(o:unknown,s=200){ return new Response(JSON.stringify(o,null,2),{status:s,headers:{...cors,"Content-Type":"application/json"}}); }

// ── V123-M1 LOCKED VARIANT CONTRACT (width + quality only; aspect preserved; no crop/height) ──
const IMAGE_VARIANT_TYPES = new Set(["image/jpeg", "image/png", "image/webp"]);
const IMAGE_VARIANTS: Record<string, { width: number; quality: number }> = {
  thumb:      { width: 256,  quality: 78 },
  card:       { width: 768,  quality: 80 },
  stage:      { width: 1280, quality: 82 },
  fullscreen: { width: 1920, quality: 85 },
};

// Bunny Token Authentication (query-parameter method), canonicalization:
//   hashableBase = security_key + path + expires + sortedParams
//   sortedParams: keys ASCENDING, join "k=v&k2=v2", exclude token/expires, NOT url-encoded.
//   token = b64url( SHA256_RAW(hashableBase) ).
// params === null → original URL (empty param set) → byte-identical to legacy v23 signing.
async function signBunny(host: string, key: string, path: string, expires: number, params: { width: number; quality: number } | null) {
  const qp = params
    ? Object.entries({ quality: params.quality, width: params.width })
        .sort(([a], [b]) => (a < b ? -1 : a > b ? 1 : 0))
        .map(([k, v]) => `${k}=${v}`)
        .join("&")
    : "";
  const hashableBase = `${key}${path}${expires}${qp}`;
  const digest = await crypto.subtle.digest("SHA-256", new TextEncoder().encode(hashableBase));
  const token = b64url(new Uint8Array(digest));
  return qp
    ? `https://${host}${path}?token=${token}&${qp}&expires=${expires}`
    : `https://${host}${path}?token=${token}&expires=${expires}`;
}
