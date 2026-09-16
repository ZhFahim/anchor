import type { ReadResourceResult } from '@modelcontextprotocol/sdk/types.js';
import type { McpServices } from '../tools/tools';
import type { McpUserContext } from '../mcp-auth.context';

/**
 * Directory catalog + on-demand resources. Per plan P5 (context frugality):
 * list resources carry id + title + state metadata only — never note content.
 * `anchor://notes/<id>` returns a single note's content, mode-bounded.
 */

export interface McpResource {
  name: string;
  uri: string;
  description: string;
  mimeType?: string;
  load: (
    user: McpUserContext,
    uri: string,
    services: McpServices,
  ) => Promise<ReadResourceResult>;
}

export const listNotesResource: McpResource = {
  name: 'notes',
  uri: 'anchor://notes',
  description:
    'All notes (id, title, state, isArchived). Content is not included; call note_get for detail.',
  mimeType: 'application/json',
  async load(user, _uri, { notes }) {
    const rows = await notes.findAll(user.userId);
    return {
      contents: [
        {
          uri: 'anchor://notes',
          mimeType: 'application/json',
          text: JSON.stringify(
            rows.map((n) => ({
              id: n.id,
              title: n.title,
              state: n.state,
              isArchived: n.isArchived,
              updatedAt: n.updatedAt,
            })),
            null,
            2,
          ),
        },
      ],
    };
  },
};

export const noteResource: McpResource = {
  name: 'note',
  uri: 'anchor://notes/{id}',
  description: 'A single note, by id (summary metadata; no content).',
  mimeType: 'application/json',
  async load(user, _uri, { notes }) {
    const id = _uri.split('/').pop() ?? '';
    const note = await notes.findOne(user.userId, id);
    return {
      contents: [
        {
          uri: _uri,
          mimeType: 'application/json',
          text: JSON.stringify(
            {
              id: note.id,
              title: note.title,
              state: note.state,
              isArchived: note.isArchived,
              updatedAt: note.updatedAt,
            },
            null,
            2,
          ),
        },
      ],
    };
  },
};

export const tagsResource: McpResource = {
  name: 'tags',
  uri: 'anchor://tags',
  description: 'All tags (id, name, note count).',
  mimeType: 'application/json',
  async load(user, _uri, { tags }) {
    const rows = await tags.findAll(user.userId);
    return {
      contents: [
        {
          uri: 'anchor://tags',
          mimeType: 'application/json',
          text: JSON.stringify(
            rows.map((t) => ({
              id: t.id,
              name: t.name,
              noteCount: t._count?.notes ?? 0,
            })),
            null,
            2,
          ),
        },
      ],
    };
  },
};

export const mcpResources: Record<string, McpResource> = {
  [listNotesResource.name]: listNotesResource,
  [noteResource.name]: noteResource,
  [tagsResource.name]: tagsResource,
};
