// Checks every translation of the phone and web apps and writes TRANSLATIONS.md.
//   node i18n/status.mjs          writes TRANSLATIONS.md
//   node i18n/status.mjs --check  fails on a broken translation or an old table (CI)
import fs from "node:fs";
import path from "node:path";

const root = process.env.I18N_ROOT ?? path.join(import.meta.dirname, "..");
const TABLE = path.join(root, "TRANSLATIONS.md");
const APPS = [
  {
    name: "Phone",
    folder: path.join(root, "mobile/lib/l10n"),
    localeOf: (file) => file.match(/^app_(\w+)\.arb$/)?.[1]?.replaceAll("_", "-"),
  },
  {
    name: "Web",
    folder: path.join(root, "web/messages"),
    localeOf: (file) => file.match(/^([\w-]+)\.json$/)?.[1],
  },
];
const WEB_LOCALES = path.join(root, "web/i18n/locales.ts");

function catalogsOf(app) {
  const catalogs = new Map();
  for (const file of fs.readdirSync(app.folder).sort()) {
    const locale = app.localeOf(file);
    if (!locale) continue;
    catalogs.set(locale, {
      file: path.relative(root, path.join(app.folder, file)),
      data: JSON.parse(fs.readFileSync(path.join(app.folder, file), "utf8")),
    });
  }
  return catalogs;
}

const messagesOf = (data) =>
  Object.entries(data).filter(
    ([key, value]) => !key.startsWith("@") && typeof value === "string",
  );

/** The arguments, plural and select forms, and rich text tags of an ICU message. */
function shapeOf(message) {
  const args = new Set();
  const tags = new Set();
  const plurals = [];
  let at = 0;
  function readMessage(end) {
    while (at < message.length) {
      const char = message[at];
      if (char === "'" && "{}'".includes(message[at + 1] ?? "")) {
        const close = message.indexOf("'", at + 1);
        if (close < 0) throw new Error("an unclosed ' quote");
        at = close + 1;
      } else if (char === "{") {
        at++;
        readArgument();
      } else if (char === "}") {
        if (end === "}") return;
        throw new Error("a } with no {");
      } else if (char === "<") {
        const tag = message.slice(at).match(/^<\/?([a-zA-Z]\w*)>/);
        if (tag) {
          tags.add(tag[0].startsWith("</") ? `/${tag[1]}` : tag[1]);
          at += tag[0].length;
        } else at++;
      } else at++;
    }
    if (end === "}") throw new Error("a { with no }");
  }
  function readArgument() {
    const head = message.slice(at).match(/^\s*(\w+)\s*(?:,\s*(\w+)\s*)?/);
    if (!head) throw new Error(`a bad argument at ${at}`);
    const [, name, type] = head;
    args.add(name);
    at += head[0].length;
    if (!type) {
      if (message[at] !== "}") throw new Error(`a bad argument {${name}`);
      at++;
      return;
    }
    if (type !== "plural" && type !== "select" && type !== "selectordinal") {
      const close = message.indexOf("}", at);
      if (close < 0) throw new Error(`an unclosed {${name}`);
      at = close + 1;
      return;
    }
    if (message[at] !== ",") throw new Error(`no forms in {${name}, ${type}}`);
    at++;
    const forms = new Set();
    for (;;) {
      const form = message.slice(at).match(/^\s*(offset:\d+\s*)?(=?\w+)\s*\{/);
      if (!form) break;
      at += form[0].length;
      forms.add(form[2]);
      readMessage("}");
      at++;
    }
    const close = message.slice(at).match(/^\s*\}/);
    if (!close) throw new Error(`an unclosed {${name}, ${type}}`);
    at += close[0].length;
    if (!forms.has("other")) throw new Error(`{${name}, ${type}} has no other`);
    plurals.push({ name, type, forms });
  }
  readMessage(null);
  return { args, tags, plurals };
}

const isSameSet = (a, b) => a.size === b.size && [...a].every((item) => b.has(item));
const EXACT = { zero: "=0", one: "=1", two: "=2" };

function problemsOf(locale, english, translated) {
  let source;
  let target;
  try {
    source = shapeOf(english);
  } catch {
    return [];
  }
  try {
    target = shapeOf(translated);
  } catch (error) {
    return [`isn't valid: ${error.message}`];
  }
  const problems = [];
  if (!isSameSet(source.args, target.args))
    problems.push(
      `has {${[...target.args].join("}, {")}} where English has {${[...source.args].join("}, {")}}`,
    );
  if (!isSameSet(source.tags, target.tags))
    problems.push("has different <tags> from English");
  const needed = new Intl.PluralRules(locale).resolvedOptions().pluralCategories;
  for (const plural of target.plurals) {
    if (plural.type !== "plural") continue;
    const missing = needed.filter(
      (form) =>
        form !== "other" &&
        !plural.forms.has(form) &&
        !(EXACT[form] && plural.forms.has(EXACT[form])),
    );
    if (missing.length)
      problems.push(`{${plural.name}, plural} needs ${missing.join(", ")}`);
  }
  return problems;
}

const errors = [];
const rows = new Map();

for (const app of APPS) {
  const catalogs = catalogsOf(app);
  const english = catalogs.get("en");
  if (!english) throw new Error(`No English file in ${app.folder}`);
  const source = new Map(messagesOf(english.data));
  for (const [locale, { file, data }] of catalogs) {
    const row = rows.get(locale) ?? { translators: new Set() };
    rows.set(locale, row);
    let translated = 0;
    for (const [key, value] of messagesOf(data)) {
      if (!source.has(key)) {
        errors.push(`${file}: ${key} isn't in English any more`);
        continue;
      }
      if (!value.trim()) continue;
      translated++;
      if (locale === "en") continue;
      for (const problem of problemsOf(locale, source.get(key), value))
        errors.push(`${file}: ${key} ${problem}`);
    }
    for (const login of data["@@x-translators"] ?? []) row.translators.add(login);
    row[app.name] = { translated, total: source.size };
  }
}

const webLocales = [
  ...fs.readFileSync(WEB_LOCALES, "utf8").matchAll(/LOCALES = \[([^\]]*)\]/g),
]
  .flatMap((match) => [...match[1].matchAll(/"([\w-]+)"/g)])
  .map((match) => match[1]);
const webFiles = [...catalogsOf(APPS[1]).keys()];
if (!isSameSet(new Set(webLocales), new Set(webFiles)))
  errors.push(
    `web/i18n/locales.ts lists ${webLocales.join(", ")}, but web/messages has ${webFiles.join(", ")}`,
  );

const languageName = (locale) =>
  new Intl.DisplayNames([locale], { type: "language" }).of(locale) ?? locale;
const cell = (stats) =>
  stats ? `${Math.floor((100 * stats.translated) / stats.total)}%` : "";
const missing = (row) =>
  APPS.reduce(
    (sum, app) =>
      sum + (row[app.name] ? row[app.name].total - row[app.name].translated : 0),
    0,
  );

const locales = [...rows.keys()].sort((a, b) =>
  a === "en" ? -1 : b === "en" ? 1 : languageName(a).localeCompare(languageName(b)),
);
const table = [
  "# Translations",
  "",
  "Anchor's phone and web apps can be shown in these languages. To add a language or improve one, see [Translations](.github/CONTRIBUTING.md#translations) in the contributing guide.",
  "",
  "This file is written by `node i18n/status.mjs`. Don't edit it by hand.",
  "",
  "| Language | Phone | Web | Missing | Translators |",
  "| --- | --- | --- | --- | --- |",
  ...locales.map((locale) => {
    const row = rows.get(locale);
    const name =
      locale === "en"
        ? "English (source)"
        : `${languageName(locale)} (${locale})`;
    const people = [...row.translators]
      .sort()
      .map((login) => `[@${login}](https://github.com/${login})`)
      .join(", ");
    return `| ${name} | ${cell(row.Phone)} | ${cell(row.Web)} | ${locale === "en" ? "" : missing(row)} | ${people} |`;
  }),
  "",
].join("\n");

if (process.argv.includes("--check")) {
  const current = fs.existsSync(TABLE) ? fs.readFileSync(TABLE, "utf8") : "";
  if (current !== table)
    errors.push("TRANSLATIONS.md is out of date: run node i18n/status.mjs");
  for (const error of errors) console.error(`✗ ${error}`);
  if (errors.length) process.exit(1);
  console.log("Translations are fine.");
} else {
  for (const error of errors) console.error(`✗ ${error}`);
  fs.writeFileSync(TABLE, table);
  console.log(`Wrote TRANSLATIONS.md${errors.length ? ` (${errors.length} problems)` : ""}`);
}
