import { createClient } from "jsr:@supabase/supabase-js@2";

const cors = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, content-type, apikey, x-client-info, x-supabase-api-version",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

const STORAGE_HOST = "sg.storage.bunnycdn.com"; // cả 2 zone region Singapore
const MAX_BYTES = 10 * 1024 * 1024;             // 10MB
const ALLOWED_TYPES = ["image/jpeg", "image/png", "image/webp"];

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: cors });
  try {
    const URL_ = Deno.env.get("SUPABASE_URL")!,
          ANON = Deno.env.get("SUPABASE_ANON_KEY")!,
          SVCKEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;

    // 1) auth — hàm tự gác (Verify JWT OFF)
    const auth = req.headers.get("Authorization") ?? "";
    const userClient = createClient(URL_, ANON, { global: { headers: { Authorization: auth } } });
    const { data: { user } } = await userClient.auth.getUser();
    if (!user) return json({ allowed: false, reason: "not_authenticated" }, 401);

    // 2) parse multipart
    const form = await req.formData().catch(() => null);
    if (!form) return json({ error: "expected_multipart_form" }, 400);
    const momentId = String(form.get("moment_id") ?? "");
    const file = form.get("file");
    if (!momentId) return json({ error: "missing_moment_id" }, 400);
    if (!(file instanceof File)) return json({ error: "missing_file" }, 400);

    // 3) validate file (loại + kích thước)
    const ftype = file.type || "application/octet-stream";
    if (!ALLOWED_TYPES.includes(ftype)) return json({ allowed: false, reason: "unsupported_file_type", file_type: ftype }, 400);
    if (file.size === 0)        return json({ allowed: false, reason: "empty_file" }, 400);
    if (file.size > MAX_BYTES)  return json({ allowed: false, reason: "file_too_large", size: file.size }, 400);

    const svc = createClient(URL_, SVCKEY);
    const { data: prof } = await svc.from("profiles").select("id, school_id").eq("user_id", user.id).maybeSingle();
    if (!prof) return json({ allowed: false, reason: "no_profile" }, 403);

    // 4) GATE (D64) — engine secdef nhận tham số
    const { data: v, error: gErr } = await svc.rpc("check_media_upload_access", { p_moment_id: momentId, p_viewer_profile: prof.id });
    if (gErr) return json({ error: "gate_error", detail: gErr.message }, 500);
    if (!v?.allowed) {
      await svc.rpc("write_audit_log", { p_action: "media_upload_denied", p_fields: { actor_id: prof.id, entity_type: "learning_moment", entity_id: momentId, metadata: { reason: v?.reason, kind: "child_upload" } } });
      return json(v ?? { allowed: false, reason: "denied" }, 403);
    }

    // 5) PUT lên Bunny Storage (dma-private) bằng server-side storage key (D63)
    const ext = ftype === "image/png" ? "png" : ftype === "image/webp" ? "webp" : "jpg";
    const objId = crypto.randomUUID();
    const path = `/moments/${momentId}/${objId}.${ext}`;   // path lưu vào media_assets.bunny_path
    const storageKey = Deno.env.get("BUNNY_PRIVATE_STORAGE_KEY");
    if (!storageKey) return json({ error: "storage_key_missing" }, 500);

    const bytes = new Uint8Array(await file.arrayBuffer());
    const putRes = await fetch(`https://${STORAGE_HOST}/dma-private${path}`, {
      method: "PUT",
      headers: { "AccessKey": storageKey, "Content-Type": "application/octet-stream" },
      body: bytes,
    });
    if (putRes.status !== 201 && putRes.status !== 200) {
      const txt = await putRes.text().catch(() => "");
      await svc.rpc("write_audit_log", { p_action: "media_upload_failed", p_fields: { actor_id: prof.id, entity_type: "learning_moment", entity_id: momentId, metadata: { http: putRes.status, detail: txt.slice(0, 200) } } });
      return json({ error: "bunny_put_failed", status: putRes.status }, 502);
    }

    // 6) ghi media_assets (service_role bypass RLS — bảng Edge-only D58)
    const { data: media, error: insErr } = await svc.from("media_assets").insert({
      storage_provider: "bunny",
      storage_zone: "dma-private",
      bunny_storage_zone: "dma-private",
      cdn_pull_zone: "dma-private",
      bunny_path: path,
      access_level: "private_child_media",
      protection_mode: "signed_url",
      file_type: ftype,
      size_bytes: file.size,
      watermark_required: false,   // ảnh con-mình ấm như album (linh hồn)
      download_allowed: false,     // V1
      stream_only: false,
      expires_policy_minutes: 10,
      linked_moment_id: momentId,
      linked_class_id: v.class_id ?? null,
      linked_school_id: v.moment_school_id ?? null,
      uploaded_by: prof.id,
      created_by: prof.id,
      state: "active",
      metadata: { source: "teacher_upload", original_name: file.name },
    }).select("id").single();
    if (insErr) return json({ error: "insert_failed", detail: insErr.message }, 500);

    // 7) audit media_upload (D67)
    await svc.rpc("write_audit_log", { p_action: "media_upload", p_fields: { actor_id: prof.id, entity_type: "media_asset", entity_id: media.id, media_id: media.id, school_id: v.moment_school_id ?? null, metadata: { moment_id: momentId, zone: "dma-private", file_type: ftype, size: file.size, kind: "child" } } });

    return json({ allowed: true, media_id: media.id, moment_id: momentId, file_type: ftype });
  } catch (e) {
    return json({ error: String(e) }, 500);
  }
});

function json(o: unknown, s = 200) {
  return new Response(JSON.stringify(o, null, 2), { status: s, headers: { ...cors, "Content-Type": "application/json" } });
}
