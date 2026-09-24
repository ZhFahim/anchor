import type { McpServices } from '../tools/tools';

export interface McpPrompt {
  name: string;
  title: string;
  description: string;
  build: (
    args: Record<string, string>,
    services: McpServices,
  ) => string | Promise<string>;
}

/**
 * `capture`: dictate/create/update a note. Or orchestration only (P9): the
 * driving agent already holds the intelligence; this prompt just frames how to
 * use the tools to capture or update a note from free-form intent.
 */
export const capturePrompt: McpPrompt = {
  name: 'capture',
  title: 'Capture a note',
  description:
    'Capture or update a note from free-form intent. Look up existing context, then use note_search / note_get to find the target, and note_edit to write it.',
  build(args) {
    return `Capture intent: ${args.topic ?? ''}

Workflow:
1. note_search to see if a matching note already exists (search the topic).
2. If one exists, note_get it (summary first) to decide whether to update.
3. Write via note_edit: set a clear title and Delta content. Reuse an existing note when it's a natural fit; otherwise create a summary of what was agreed, with an explicit next step.

Propose a title and up to 3 tags for the note from the content.`;
  },
};

/**
 * `maintenance`: stale notes, reminder sweep, trash review, tag hygiene.
 */
export const maintenancePrompt: McpPrompt = {
  name: 'maintenance',
  title: 'Notes maintenance sweep',
  description:
    "Run a maintenance pass over a user's notes: stale/overdue items, trash review, tag hygiene, and dedupe candidates.",
  build(args) {
    const focus = args.focus
      ? `Focus area requested: ${args.focus}.`
      : 'No focus specified — cover the default areas.';
    return `${focus}

Maintenance checklist (use the tools; do not invent data):
- note_search with broad queries to surface stale or duplicate notes.
- note_get summary for candidates before deciding anything.
- Suggest cleanup via note_edit (title/tag tidy) or note_history restore for accidental edits.
- Call out overdue reminders you can see, but do not delete reminders implicitly.

Report findings as a list; only make changes the user asked for.`;
  },
};

export const mcpPrompts: Record<string, McpPrompt> = {
  [capturePrompt.name]: capturePrompt,
  [maintenancePrompt.name]: maintenancePrompt,
};
