# V128-B20 — FE PASTE PATCH (class.edit full-field)

Base: FE HEAD `6a0f3504` · pin `2.8.5` · paste-mode (Lovable editor).
Untouched: `renderer/ActionDrawer.tsx`, generic renderer, generic parsers
(`parseClassActions`/`parseFields`/`parseOptions`/`parseClassEditExecuteResult`).

Apply all 5 files, verify build passes (governance guard: pin stays `2.8.5`), then publish.

---

## 1 — `src/features/mission-control/contract/workspacePresentation.ts`

FIND:
```ts
export type WorkspaceView = {
  identity: WorkspaceIdentity;
  contexts: WorkspaceRow[];
  state: WorkspaceRow[];
  capabilities: WorkspaceCapabilities;
};
```
REPLACE:
```ts
export type WorkspaceView = {
  identity: WorkspaceIdentity;
  contexts: WorkspaceRow[];
  state: WorkspaceRow[];
  capabilities: WorkspaceCapabilities;
  attributes?: Record<string, string | null>;
};
```

---

## 2 — `src/features/mission-control/class/class-adapter.ts`

FIND:
```ts
  const identity: WorkspaceIdentity = {
    id,
    label: asString(object["label"]) ?? "Không tên",
    status: asString(object["status"]),
  };

  const caps = data["capabilities"];
```
REPLACE:
```ts
  const identity: WorkspaceIdentity = {
    id,
    label: asString(object["label"]) ?? "Không tên",
    status: asString(object["status"]),
  };

  const attributes: Record<string, string | null> = {
    age_group_id: asUuid(object["age_group_id"]) ?? null,
    level_id: asUuid(object["level_id"]) ?? null,
  };

  const caps = data["capabilities"];
```

FIND:
```ts
    view: {
      identity,
      contexts: parseRows(data["context"]),
      state: parseRows(data["state"]),
      capabilities,
    },
```
REPLACE:
```ts
    view: {
      identity,
      contexts: parseRows(data["context"]),
      state: parseRows(data["state"]),
      capabilities,
      attributes,
    },
```

---

## 3 — `src/features/mission-control/class/classActions.ts`

FIND:
```ts
export type ClassEditPayload = {
  context: { school_id: string };
  input: { name: string };
};

export type BuildClassEditPayloadResult =
  | { ok: true; payload: ClassEditPayload }
  | { ok: false; reason: "missing_school" | "empty_name" };
```
REPLACE:
```ts
export type ClassEditPayload = {
  context: { school_id: string };
  input: { name?: string; age_group_id?: string; level_id?: string };
};

export type BuildClassEditPayloadResult =
  | { ok: true; payload: ClassEditPayload }
  | { ok: false; reason: "missing_school" | "empty_name" | "no_changes" };
```

FIND (entire current function):
```ts
export function buildClassEditPayload(args: {
  schoolId: string | null;
  values: Record<string, string | null>;
}): BuildClassEditPayloadResult {
  const schoolId = (args.schoolId ?? "").trim();
  if (!schoolId) return { ok: false, reason: "missing_school" };

  const rawName = args.values["name"];
  const nameStr = typeof rawName === "string" ? rawName : "";
  if (nameStr.trim().length === 0) return { ok: false, reason: "empty_name" };

  return { ok: true, payload: { context: { school_id: schoolId }, input: { name: nameStr } } };
}
```
REPLACE:
```ts
// Dirty-only inclusion: a field enters input ONLY when it differs from the seed
// (accurate changed_fields + minimal write). name is blank-tested (trim decides validity
// only) then sent VERBATIM. age_group_id/level_id send the selected uuid; clear-to-null is
// out of scope this slice (drawer cannot emit empty once seeded).
export function buildClassEditPayload(args: {
  schoolId: string | null;
  values: Record<string, string | null>;
  initialValues?: Record<string, string | null>;
}): BuildClassEditPayloadResult {
  const schoolId = (args.schoolId ?? "").trim();
  if (!schoolId) return { ok: false, reason: "missing_school" };

  const seed = args.initialValues ?? {};
  const dirty = (key: string): boolean => (args.values[key] ?? "") !== String(seed[key] ?? "");
  const input: ClassEditPayload["input"] = {};

  if (dirty("name")) {
    const rawName = args.values["name"];
    const nameStr = typeof rawName === "string" ? rawName : "";
    if (nameStr.trim().length === 0) return { ok: false, reason: "empty_name" };
    input.name = nameStr;
  }
  if (dirty("age_group_id")) {
    const v = (args.values["age_group_id"] ?? "").trim();
    if (v.length > 0) input.age_group_id = v;
  }
  if (dirty("level_id")) {
    const v = (args.values["level_id"] ?? "").trim();
    if (v.length > 0) input.level_id = v;
  }

  if (Object.keys(input).length === 0) return { ok: false, reason: "no_changes" };
  return { ok: true, payload: { context: { school_id: schoolId }, input } };
}
```

---

## 4 — `src/features/mission-control/class/hooks/useClassEditAction.ts`

FIND:
```ts
  submit: (args: { schoolId: string | null; values: Record<string, string | null> }) => void;
```
REPLACE:
```ts
  submit: (args: {
    schoolId: string | null;
    values: Record<string, string | null>;
    initialValues?: Record<string, string | null>;
  }) => void;
```

FIND:
```ts
  const submit = (args: { schoolId: string | null; values: Record<string, string | null> }) => {
    if (submitLockRef.current || mutation.isPending) return;
    const built = buildClassEditPayload({ schoolId: args.schoolId, values: args.values });
```
REPLACE:
```ts
  const submit = (args: {
    schoolId: string | null;
    values: Record<string, string | null>;
    initialValues?: Record<string, string | null>;
  }) => {
    if (submitLockRef.current || mutation.isPending) return;
    const built = buildClassEditPayload({
      schoolId: args.schoolId,
      values: args.values,
      initialValues: args.initialValues,
    });
```

---

## 5 — `src/features/mission-control/class/ClassWorkspaceScreen.tsx`

FIND:
```tsx
    const view = ws.data.view;
    const schoolId = view.contexts.find((c) => c.key === "school_id")?.value ?? null;
```
REPLACE:
```tsx
    const view = ws.data.view;
    const schoolId = view.contexts.find((c) => c.key === "school_id")?.value ?? null;
    const editInitialValues: Record<string, string | null> = {
      name: view.identity.label,
      age_group_id: view.attributes?.["age_group_id"] ?? "",
      level_id: view.attributes?.["level_id"] ?? "",
    };
```

FIND:
```tsx
          initialValues={
            openActionKey === CLASS_EDIT_ACTION_KEY ? { name: view.identity.label } : undefined
          }
```
REPLACE:
```tsx
          initialValues={
            openActionKey === CLASS_EDIT_ACTION_KEY ? editInitialValues : undefined
          }
```

FIND:
```tsx
          onSubmit={(values) => active.submit({ schoolId, values })}
```
REPLACE:
```tsx
          onSubmit={(values) => {
            if (openActionKey === CLASS_EDIT_ACTION_KEY) {
              edit.submit({ schoolId, values, initialValues: editInitialValues });
            } else {
              assign.submit({ schoolId, values });
            }
          }}
```

---

## Post-paste verification
1. Build passes (typecheck + governance guard pin `2.8.5`).
2. Publish to production.
3. Real-login: master KHM `hieutruong.kidshouse@demo.demenart.com` / `Test@123`
   → Mission Control → class "Hoa Hồng" → Edit Class drawer shows name + Nhóm tuổi + Cấp độ (seeded);
   change age group → save → success; reopen → value persisted.
