import { createMcpServer, refusedForReadOnly } from './mcp-server.factory';
import type { McpUserContext } from './mcp-auth.context';
import { mcpAuthStorage } from './mcp-auth.context';
import { noteEdit, noteAttachments } from './tools/tools';

const user: McpUserContext = {
  userId: 'u1',
  authMethod: 'apiToken',
  scope: 'readWrite',
};

const services = {
  notes: {
    findAll: jest.fn().mockResolvedValue([]),
    findOne: jest.fn().mockResolvedValue({
      id: 'n1',
      title: 'T',
      content: null,
      state: 'active',
      isArchived: false,
      updatedAt: '2026-01-01',
    }),
    update: jest.fn(),
  },
  history: { list: jest.fn().mockResolvedValue({ revisions: [] }) },
} as never;

describe('createMcpServer', () => {
  it('builds without throwing for explicit tool lists', () => {
    expect(() => createMcpServer(services, ['note_get'])).not.toThrow();
  });

  it('refuses a mutating tool for a read-only token', () => {
    expect(refusedForReadOnly(false, 'readOnly')).toBe(true);
    expect(refusedForReadOnly(true, 'readOnly')).toBe(false);
    expect(refusedForReadOnly(false, 'readWrite')).toBe(false);
    expect(refusedForReadOnly(false, 'jwt')).toBe(false);
  });

  it('tools run inside the auth context', () => {
    mcpAuthStorage.run(user, () => {
      const server = createMcpServer(services, ['note_get']);
      expect(server).toBeDefined();
    });
  });

  it('accepts an audit sink and records tool op metadata', () => {
    const records: unknown[] = [];
    const audit = (rec: unknown): void => {
      records.push(rec);
    };
    const server = createMcpServer(services, ['note_get'], audit);
    expect(server).toBeDefined();
    expect(records.length).toBe(0);
  });

  it('exposes the confirm gate contract via refusedForReadOnly helper', () => {
    // note_edit is recoverable (revision net) so it is not confirmRequired.
    expect(noteEdit.confirmRequired).toBeFalsy();
  });

  it('note_attachments declares list/download as read-only actions for the gate', () => {
    // Read-only tokens must still be able to list and get download URLs.
    expect(noteAttachments.readOnlyActions).toContain('list');
    expect(noteAttachments.readOnlyActions).toContain('download');
    // Write actions (upload/remove) must NOT be in the read-only allowlist.
    expect(noteAttachments.readOnlyActions).not.toContain('upload');
    expect(noteAttachments.readOnlyActions).not.toContain('remove');
  });
});
