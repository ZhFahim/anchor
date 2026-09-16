import { tagCreate, tools } from './tools';
import type { McpUserContext } from '../mcp-auth.context';

const user: McpUserContext = {
  userId: 'u1',
  authMethod: 'apiToken',
  scope: 'readWrite',
};

const tagsService = () => ({
  create: jest.fn().mockResolvedValue({ id: 't1', name: 'work' }),
  update: jest.fn().mockResolvedValue({ id: 't1', name: 'home' }),
  remove: jest.fn().mockResolvedValue({ id: 't1' }),
});

describe('tag_manage (dense) tool', () => {
  it('is registered once, without a separate tag_remove', () => {
    expect(tools.tag_manage).toBeDefined();
    expect(tools.tag_remove).toBeUndefined();
  });

  it('create forwards name+color to the tags service', async () => {
    const tags = tagsService();
    const out = await tagCreate.run(
      user,
      { action: 'create', name: 'work', color: '#00ff00' },
      { tags } as never,
    );
    expect(tags.create).toHaveBeenCalledWith('u1', {
      name: 'work',
      color: '#00ff00',
    });
    expect(out.isError).toBeUndefined();
  });

  it('rename forwards name to the tags service', async () => {
    const tags = tagsService();
    const out = await tagCreate.run(
      user,
      { action: 'rename', tagId: 't1', name: 'home' },
      { tags } as never,
    );
    expect(tags.update).toHaveBeenCalledWith('u1', 't1', { name: 'home' });
    expect(out.isError).toBeUndefined();
  });

  it('recolor forwards color to the tags service', async () => {
    const tags = tagsService();
    const out = await tagCreate.run(
      user,
      { action: 'recolor', tagId: 't1', color: '#ff0000' },
      { tags } as never,
    );
    expect(tags.update).toHaveBeenCalledWith('u1', 't1', { color: '#ff0000' });
    expect(out.isError).toBeUndefined();
  });

  it('remove is confirm-gated and only then calls the tag service', async () => {
    const tags = tagsService();
    const refused = await tagCreate.run(
      user,
      { action: 'remove', tagId: 't1' },
      { tags } as never,
    );
    expect(refused.isError).toBe(true);
    expect(tags.remove).not.toHaveBeenCalled();

    const ok = await tagCreate.run(
      user,
      { action: 'remove', tagId: 't1', confirm: true },
      { tags } as never,
    );
    expect(tags.remove).toHaveBeenCalledWith('u1', 't1');
    expect(ok.isError).toBeUndefined();
  });

  it('rejects an unknown tag action', async () => {
    const tags = tagsService();
    const out = await tagCreate.run(user, { action: 'bogus', tagId: 't1' }, {
      tags,
    } as never);
    expect(out.isError).toBe(true);
    expect(tags.update).not.toHaveBeenCalled();
  });
});
