import { QueryClient } from "@tanstack/react-query";
import { createRouter } from "@tanstack/react-router";
import { routeTree } from "./routeTree.gen";
import type { startInstance } from "./start.ts";

export const getRouter = () => {
  const queryClient = new QueryClient();

  const router = createRouter({
    routeTree,
    context: { queryClient },
    scrollRestoration: true,
    defaultPreloadStaleTime: 0,
  });

  return router;
};

// V126-M1 (C3.2) — TanStack Start Register augmentation relocated here from the
// generated routeTree.gen.ts. That file is regenerated on save and strips manual
// additions (V121-M1 failure mode: the Register block kept vanishing). router.tsx
// is hand-authored, so the augmentation survives route regeneration. getRouter is
// defined above (in scope); startInstance is type-only imported from ./start.ts.
declare module "@tanstack/react-start" {
  interface Register {
    ssr: true;
    router: Awaited<ReturnType<typeof getRouter>>;
    config: Awaited<ReturnType<typeof startInstance.getOptions>>;
  }
}
