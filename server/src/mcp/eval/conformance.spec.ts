import { evaluateAll, summarize } from './conformance';
import { tools } from '../tools/tools';
import { mcpResources } from '../resources/resources';
import { mcpPrompts } from '../prompts/prompts';

describe('MCP conformance evaluation (grounded in vendor guidance)', () => {
  it('covers every tool, resource, and prompt in the registries', () => {
    const results = evaluateAll();

    for (const t of Object.values(tools)) {
      const mine = results.filter((r) => r.target === `tool:${t.name}`);
      expect(Number(mine.length)).toBeGreaterThanOrEqual(3);
      expect(mine.some((r) => r.check === 'snake_case naming')).toBe(true);
      expect(mine.some((r) => r.check.startsWith('description meets'))).toBe(
        true,
      );
    }
    for (const res of Object.values(mcpResources)) {
      const mine = results.filter((r) => r.target === `resource:${res.name}`);
      expect(Number(mine.length)).toBeGreaterThanOrEqual(2);
      expect(mine.some((r) => r.check === 'uri scheme is anchor://')).toBe(
        true,
      );
      expect(mine.some((r) => r.check === 'description present')).toBe(true);
    }
    for (const prompt of Object.values(mcpPrompts)) {
      const mine = results.filter((r) => r.target === `prompt:${prompt.name}`);
      expect(Number(mine.length)).toBeGreaterThanOrEqual(1);
      expect(mine.some((r) => r.check === 'description present')).toBe(true);
    }
  });

  it('flags a description that fails the Anthropic 3-4 sentence floor', () => {
    // A single-sentence description must fail the floor (Anthropic: "at
    // least 3-4 sentences"). Proves the check is real, not vacuous.
    const original = tools.note_search.description;
    Object.assign(tools.note_search, { description: 'Too brief.' });
    const results = evaluateAll();
    const fail = results.find(
      (r) =>
        r.target === 'tool:note_search' &&
        r.check.startsWith('description meets'),
    );
    expect(fail?.pass).toBe(false);
    Object.assign(tools.note_search, { description: original });
  });

  it('enforces the Anthropic tool-name format on every tool', () => {
    const results = evaluateAll();
    for (const t of Object.values(tools)) {
      const mine = results.filter((r) => r.target === `tool:${t.name}`);
      expect(
        mine.some(
          (r) => r.check === 'name matches ^[a-zA-Z0-9_-]{1,128}$' && r.pass,
        ),
      ).toBe(true);
    }
  });

  it('keeps tool count under the OpenAI <20 start-of-turn suggestion', () => {
    const results = evaluateAll();
    const check = results.find(
      (r) =>
        r.check === 'tool count < 20 at start of turn (OpenAI soft suggestion)',
    );
    expect(check?.pass).toBe(true);
  });

  it('flags a write action mislabeled as read-only in readOnlyActions', () => {
    // Regression guard: if someone lists 'upload' as a readOnlyAction, the
    // gate-coherence check must fail (a read-only token would otherwise pass).
    const noteAttachments = tools.note_attachments;
    const original = noteAttachments.readOnlyActions;
    Object.assign(noteAttachments, {
      readOnlyActions: [...(original ?? []), 'upload'],
    });
    const results = evaluateAll();
    const fail = results.find(
      (r) =>
        r.target === 'tool:note_attachments' &&
        r.check === 'readOnlyActions contain no write actions',
    );
    expect(fail?.pass).toBe(false);
    Object.assign(noteAttachments, { readOnlyActions: original });
  });

  it('reports stable totals and lists failures', () => {
    const results = evaluateAll();
    const summary = summarize(results);
    expect(summary.total).toBe(results.length);
    expect(summary.passed + summary.failed).toBe(summary.total);
    expect(summary.failures).toEqual(results.filter((r) => !r.pass));
  });
});
