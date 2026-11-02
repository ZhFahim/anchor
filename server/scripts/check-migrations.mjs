// Checks that this fork's migrations leave a database upstream Anchor's
// server can still run on, so a server can switch back to it:
//
//   node scripts/check-migrations.mjs <upstream git ref>
//
// A migration upstream doesn't have may make tables and types of its own and
// do what it likes with them. To upstream's tables it may only add columns
// that are optional or have a default, and indexes that aren't unique; it may
// change their rows. Anything else (a value added to one of upstream's enums,
// a column renamed, dropped or made required, a unique index) can stop
// upstream's server reading or writing them. A migration that does so on
// purpose says why in a line starting `-- switch-back:`, and
// docker/test-switch-back.sh has to show it's safe.
import { execFileSync } from 'node:child_process';
import { readdirSync, readFileSync } from 'node:fs';
import path from 'node:path';

// Applied before this check existed; undone by 20261102130000_note_file_table.
const GRANDFATHERED = new Set(['20261028120000_attachment_file_type']);

const ref = process.argv[2];
if (!ref) {
  console.error('usage: node scripts/check-migrations.mjs <upstream git ref>');
  process.exit(2);
}

const dir = path.join(import.meta.dirname, '..', 'prisma', 'migrations');
const upstream = new Set(
  execFileSync(
    'git',
    ['ls-tree', '--full-tree', '--name-only', `${ref}:server/prisma/migrations`],
    { encoding: 'utf8' },
  )
    .split('\n')
    .filter(Boolean),
);
if (upstream.size === 0) {
  console.error(`No migrations at ${ref}`);
  process.exit(2);
}

const migrations = readdirSync(dir, { withFileTypes: true })
  .filter((entry) => entry.isDirectory())
  .map((entry) => entry.name)
  .sort();

const name = String.raw`"?(\w+)"?`;
const statements = (sql) =>
  sql
    .replace(/--.*$/gm, '')
    .split(';')
    .map((s) => s.replace(/\s+/g, ' ').trim())
    .filter(Boolean);

// Tables and types this fork made, so free to change.
const ours = new Set();
const problems = [];

for (const migration of migrations) {
  if (upstream.has(migration)) continue;
  const sql = readFileSync(path.join(dir, migration, 'migration.sql'), 'utf8');
  for (const s of statements(sql)) {
    const made = s.match(new RegExp(`^CREATE (?:TABLE|TYPE) ${name}`, 'i'));
    if (made) ours.add(made[1]);
  }
  if (GRANDFATHERED.has(migration) || /^-- switch-back:/m.test(sql)) continue;

  const problem = (s, why) =>
    problems.push(`${migration}: ${why}\n    ${s.slice(0, 160)}`);

  for (const s of statements(sql)) {
    if (/^(BEGIN|COMMIT)$/i.test(s)) continue;
    if (/^(INSERT INTO|UPDATE|DELETE FROM) /i.test(s)) continue;

    const table = s.match(new RegExp(`^ALTER TABLE (?:ONLY )?${name} (.*)$`, 'i'));
    if (table) {
      if (ours.has(table[1])) continue;
      const changes = table[2].split(/,(?![^(]*\))/).map((c) => c.trim());
      for (const change of changes) {
        if (!/^ADD (COLUMN )?/i.test(change)) {
          problem(s, `changes upstream's table "${table[1]}" beyond adding to it`);
        } else if (/^ADD CONSTRAINT .* (UNIQUE|PRIMARY KEY|CHECK)/i.test(change)) {
          problem(s, `constrains upstream's table "${table[1]}"`);
        } else if (
          /^ADD (COLUMN )?/i.test(change) &&
          !/^ADD CONSTRAINT/i.test(change) &&
          /NOT NULL/i.test(change) &&
          !/DEFAULT/i.test(change)
        ) {
          problem(s, `adds a required column without a default to "${table[1]}"`);
        }
      }
      continue;
    }

    const type = s.match(new RegExp(`^(?:ALTER|DROP) TYPE (?:"public"\\.)?${name}`, 'i'));
    if (type) {
      if (!ours.has(type[1])) problem(s, `changes upstream's type "${type[1]}"`);
      continue;
    }

    const index = s.match(
      new RegExp(`^CREATE (UNIQUE )?INDEX ${name} ON ${name}`, 'i'),
    );
    if (index) {
      if (index[1] && !ours.has(index[3])) {
        problem(s, `adds a unique index to upstream's table "${index[3]}"`);
      }
      continue;
    }

    const drop = s.match(new RegExp(`^DROP (TABLE|INDEX) (?:IF EXISTS )?${name}`, 'i'));
    if (drop) {
      if (drop[1].toUpperCase() === 'TABLE' && !ours.has(drop[2])) {
        problem(s, `drops upstream's table "${drop[2]}"`);
      }
      continue;
    }

    if (/^CREATE (TABLE|TYPE) /i.test(s)) continue;
    problem(s, 'not a change this check knows is safe for upstream');
  }
}

if (problems.length > 0) {
  console.error(
    "These migrations could stop upstream Anchor's server running on this " +
      'database (see scripts/check-migrations.mjs):\n\n' +
      problems.join('\n\n'),
  );
  process.exit(1);
}
console.log(
  `${migrations.filter((m) => !upstream.has(m)).length} migrations of this fork leave upstream's tables readable`,
);
