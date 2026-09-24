import { capturePrompt, maintenancePrompt, mcpPrompts } from './prompts';
import type { McpServices } from '../tools/tools';

const services = {} as unknown as McpServices;

describe('mcp prompts', () => {
  it('exposes the orchestration prompts', () => {
    expect(Object.keys(mcpPrompts).sort()).toEqual(['capture', 'maintenance']);
  });

  it('capture prompt frames a tool workflow and includes the topic', async () => {
    const text = await capturePrompt.build(
      { topic: 'standup notes' },
      services,
    );
    expect(text).toContain('standup notes');
    expect(text.toLowerCase()).toContain('note_edit');
  });

  it('maintenance prompt is orchestration-only', async () => {
    const text = await maintenancePrompt.build({}, services);
    expect(text.toLowerCase()).toContain('note_search');
    expect(text.toLowerCase()).toContain('note_get');
  });
});
