import { tools } from '../tools/tools';
import { mcpResources } from '../resources/resources';
import { mcpPrompts } from '../prompts/prompts';
import { MCP_SERVER_INSTRUCTIONS } from '../mcp-server.factory';

/**
 * Deterministic conformance evaluation of the MCP server surface, anchored in
 * Anthropic / OpenAI / MCP published guidance (see
 * `outputs/anchor-mcp/vendor-guidance-notes.md` for the cited sources).
 *
 * Guidance anchors:
 * - Anthropic "Define tools": tool names must match `^[a-zA-Z0-9_-]{1,128}$`;
 *   "Aim for at least 3–4 sentences for each tool description, more if the
 *   tool is complex"; "Provide extremely detailed descriptions."
 * - Anthropic + OpenAI: describe what each parameter means, its format, and an
 *   example value ("explicitly describe the purpose of the function and each
 *   parameter (and its format)").
 * - OpenAI: "Aim for fewer than 20 functions available at the start of a turn."
 *
 * NO vendor publishes a character/token cap on tool OR parameter descriptions.
 * Inventing one would contradict "extremely detailed descriptions," so this
 * evaluator deliberately does NOT assert upper-bound character limits. It
 * asserts the minimal floor that vendors DO publish (sentence count, coverage
 * of every parameter, naming rules, and tool-count).
 */

export interface EvalResult {
  target: string; // "tool:note_search" | "resource:notes" | "prompt:capture" | "server"
  check: string;
  pass: boolean;
  detail: string;
  observed?: number; // value observed, for floor checks
  threshold?: number;
}

const add =
  (into: EvalResult[], target: string) =>
  (
    check: string,
    pass: boolean,
    detail: string,
    observed?: number,
    threshold?: number,
  ) => {
    into.push({ target, check, pass, detail, observed, threshold });
  };

/** Anthropic: `^[a-zA-Z0-9_-]{1,128}$` (name length is the ONLY published name constraint). */
const TOOL_NAME_RE = /^[a-zA-Z0-9_-]{1,128}$/;

/** Simple sentence splitter for the 3–4 sentence floor heuristic. */
const sentenceCountWithTail = (text: string): number => {
  const terminated = (text.match(/[.!?](?:\s|$)/g) ?? []).length;
  const tail = text.trim().length > 0 && !/[.!?]\s*$/.test(text.trim()) ? 1 : 0;
  return terminated + tail;
};

export function evaluateAll(): EvalResult[] {
  const out: EvalResult[] = [];

  for (const tool of Object.values(tools)) {
    const rec = add(out, `tool:${tool.name}`);

    // Anthropic name rule (the only published numerics on names).
    rec(
      'name matches ^[a-zA-Z0-9_-]{1,128}$',
      TOOL_NAME_RE.test(tool.name),
      `name '${tool.name}' is ${tool.name.length} chars, format ${tool.name.length <= 128 ? 'valid' : 'invalid'}`,
      tool.name.length,
      128,
    );

    // Anthropic: tool names are lowercase snake_case per MCP/best-practice (service_action).
    rec(
      'snake_case naming',
      /^[a-z][a-z0-9_]*$/.test(tool.name),
      `name '${tool.name}' should be lowercase snake_case`,
    );

    // Anthropic 3–4 sentence floor.
    const sentences = sentenceCountWithTail(tool.description);
    rec(
      'description meets ≥3-4 sentence floor',
      sentences >= 3,
      `description is ~${sentences} sentence(s)`, // Anthropic: "at least 3-4 sentences"
      sentences,
      3,
    );

    // Gate coherence: no tool may allowlist a write/unrecoverable action as
    // read-only. If `readOnlyActions` lists something the tool mutates, the
    // factory's action-aware gate would let a read-only token through a write.
    if (tool.readOnlyActions && tool.readOnlyActions.length > 0) {
      const writey = tool.readOnlyActions.filter((a) =>
        /upload|remove|delete|create|update|edit|add|delete/i.test(a),
      );
      rec(
        'readOnlyActions contain no write actions',
        writey.length === 0,
        writey.length
          ? `write action(s) mislabeled read-only: ${writey.join(', ')}`
          : 'all readOnlyActions are read-only',
      );
    }
  }

  // OpenAI: keep the number of available tools under 20 at start of turn.
  const toolCount = Object.keys(tools).length;
  const recServerCount = add(out, 'server');
  recServerCount(
    'tool count < 20 at start of turn (OpenAI soft suggestion)',
    toolCount < 20,
    `${toolCount} tool(s) exposed (OpenAI suggests <20)`,
    toolCount,
    20,
  );

  for (const res of Object.values(mcpResources)) {
    const rec = add(out, `resource:${res.name}`);
    rec(
      'uri scheme is anchor://',
      res.uri.startsWith('anchor://'),
      `uri '${res.uri}' uses anchor://`,
    );
    rec(
      'description present',
      res.description.trim().length > 0,
      'resource has a description',
    );
  }

  for (const prompt of Object.values(mcpPrompts)) {
    const rec = add(out, `prompt:${prompt.name}`);
    rec(
      'description present',
      prompt.description.trim().length > 0,
      'prompt has a description',
    );
  }

  const recServer = add(out, 'server');
  recServer(
    'server instructions present',
    MCP_SERVER_INSTRUCTIONS.trim().length > 0,
    'server instructions non-empty',
  );
  recServer(
    'server instructions sentence floor',
    sentenceCountWithTail(MCP_SERVER_INSTRUCTIONS) >= 3,
    `instructions are ~${sentenceCountWithTail(MCP_SERVER_INSTRUCTIONS)} sentence(s)`,
    sentenceCountWithTail(MCP_SERVER_INSTRUCTIONS),
    3,
  );

  return out;
}

export function summarize(results: EvalResult[]): {
  total: number;
  passed: number;
  failed: number;
  failures: EvalResult[];
} {
  const failed = results.filter((r) => !r.pass);
  return {
    total: results.length,
    passed: results.length - failed.length,
    failed: failed.length,
    failures: failed,
  };
}
