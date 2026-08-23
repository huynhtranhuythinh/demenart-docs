// src/features/journey/useJourneySigning.ts
// V92B.1 · C4.1 — Parent media signing với TTL cache + retry.
// Bunny signed URL hết hạn ~10' (expires_policy_minutes=10) → re-sign khi URL cũ > 8'.
// resign() dùng cho ảnh onError. Per-media on-demand, KHÔNG batch, KHÔNG adapter-sign.
// V123-M1: MỘT lần ký / media giờ trả kèm bounded variant bundle (thumb/card/stage/fullscreen).
//   KHÔNG thêm invocation/variant. Cache vẫn keyed theo media_id. pickVariant() ưu tiên variant,
//   fallback sang original nếu Edge chưa mint (Optimizer chưa bật / media không đủ điều kiện).
import { useCallback, useRef, useState } from "react";
import { supabase } from "@/integrations/supabase/client";

// V123-M1 LOCKED roles — must mirror the signer's IMAGE_VARIANTS keys exactly.
export type VariantRole = "thumb" | "card" | "stage" | "fullscreen";
export type MediaVariants = Partial<Record<VariantRole, string>>;

export type SignState =
  | { status: "idle" }
  | { status: "loading" }
  | { status: "ok"; url: string; signedAt: number; variants?: MediaVariants }
  | { status: "denied"; reason: string }
  | { status: "error" };

export type JourneySigning = {
  ensureSigned: (mediaId: string | null | undefined) => void;
  getState: (mediaId: string | null | undefined) => SignState;
  resign: (mediaId: string | null | undefined) => void;
};

const IDLE: SignState = { status: "idle" };
const TTL_MS = 8 * 60 * 1000; // re-sign trước hạn 10' của Bunny

// V123-M1 — pick a transformed variant for a role, falling back ONCE to the original
// signed URL when the Edge did not mint variants (non-image, Optimizer disabled, or legacy
// signer). Returns null while not-ok so callers keep their reserved/loading state.
export function pickVariant(
  st: SignState,
  role: VariantRole,
): { url: string; isOriginalFallback: boolean } | null {
  if (st.status !== "ok") return null;
  const v = st.variants?.[role];
  if (v) return { url: v, isOriginalFallback: false };
  return { url: st.url, isOriginalFallback: true };
}

export function useJourneySigning(): JourneySigning {
  const [cache, setCache] = useState<Record<string, SignState>>({});
  const cacheRef = useRef<Record<string, SignState>>({});
  cacheRef.current = cache;
  const inflight = useRef<Set<string>>(new Set());

  const sign = useCallback((mediaId: string) => {
    if (inflight.current.has(mediaId)) return;
    inflight.current.add(mediaId);
    setCache((prev) => ({
      ...prev,
      // giữ URL cũ (nếu đang ok) trong lúc re-sign để tránh nháy; nếu chưa có → loading
      [mediaId]: prev[mediaId]?.status === "ok" ? prev[mediaId] : { status: "loading" },
    }));
    (async () => {
      const { data, error } = await (supabase as any).functions.invoke("get_signed_media_url", {
        body: { media_id: mediaId },
      });
      let reason: string = data?.reason ?? "unknown";
      if (error && (error as any).context && typeof (error as any).context.json === "function") {
        try {
          const body = await (error as any).context.json();
          reason = body?.reason ?? reason;
        } catch {
          /* keep reason */
        }
      }
      setCache((prev) => ({
        ...prev,
        [mediaId]:
          !error && data?.allowed && data?.signed_url
            ? {
                status: "ok",
                url: data.signed_url as string,
                signedAt: Date.now(),
                // V123-M1: additive — present only for eligible dma-private images.
                ...(data.variants ? { variants: data.variants as MediaVariants } : {}),
              }
            : { status: "denied", reason },
      }));
      inflight.current.delete(mediaId);
    })();
  }, []);

  const ensureSigned = useCallback(
    (mediaId: string | null | undefined) => {
      if (!mediaId) return;
      const cur = cacheRef.current[mediaId];
      if (cur?.status === "loading") return;
      if (cur?.status === "ok" && Date.now() - cur.signedAt < TTL_MS) return; // còn hạn → dùng cache
      if (cur?.status === "denied") return; // không auto-retry denied; resign() nếu cần
      sign(mediaId);
    },
    [sign],
  );

  const resign = useCallback(
    (mediaId: string | null | undefined) => {
      if (!mediaId) return;
      inflight.current.delete(mediaId);
      sign(mediaId);
    },
    [sign],
  );

  const getState = useCallback(
    (mediaId: string | null | undefined): SignState => (mediaId ? cacheRef.current[mediaId] ?? IDLE : IDLE),
    [],
  );

  return { ensureSigned, getState, resign };
}
