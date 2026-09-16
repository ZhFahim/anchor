import {
  listNotesResource,
  noteResource,
  tagsResource,
  mcpResources,
} from './resources';
import type { McpServices } from '../tools/tools';
import type { McpUserContext } from '../mcp-auth.context';

const user: McpUserContext = {
  userId: 'u1',
  authMethod: 'apiToken',
  scope: 'readOnly',
};

const notes = {
  findAll: jest.fn().mockResolvedValue([
    {
      id: 'n1',
      title: 'A',
      state: 'active',
      isArchived: false,
      updatedAt: '2026-01-01',
    },
  ]),
  findOne: jest.fn().mockResolvedValue({
    id: 'n1',
    title: 'A',
    content: 'body',
    state: 'active',
    isArchived: false,
    updatedAt: '2026-01-01',
  }),
  update: jest.fn(),
};
const history = { list: jest.fn() };
const tags = {
  findAll: jest
    .fn()
    .mockResolvedValue([{ id: 't1', name: 'work', _count: { notes: 3 } }]),
};
const services = { notes, history, tags } as unknown as McpServices;

describe('mcp resources', () => {
  beforeEach(() => jest.clearAllMocks());

  it('exposes the catalog resources', () => {
    expect(Object.keys(mcpResources).sort()).toEqual(['note', 'notes', 'tags']);
  });

  it('listNotesResource returns id+title+state metadata, no content', async () => {
    expect(listNotesResource.uri).toBe('anchor://notes');
    const out = await listNotesResource.load(user, 'anchor://notes', services);
    const txt = (out as { contents: { text: string }[] }).contents[0].text;
    expect(txt).toContain('"title": "A"');
    expect(txt).not.toContain('body');
  });

  it('noteResource by id returns a single note summary', async () => {
    const out = await noteResource.load(user, 'anchor://notes/n1', services);
    expect(notes.findOne).toHaveBeenCalledWith('u1', 'n1');
    const txt = (out as { contents: { text: string }[] }).contents[0].text;
    expect(txt).toContain('"title": "A"');
  });

  it('tagsResource returns tag names and counts', async () => {
    const out = await tagsResource.load(user, 'anchor://tags', services);
    expect(tags.findAll).toHaveBeenCalledWith('u1');
    const txt = (out as { contents: { text: string }[] }).contents[0].text;
    expect(txt).toContain('"name": "work"');
  });
});
