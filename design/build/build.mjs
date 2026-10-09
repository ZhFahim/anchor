import fs from "node:fs";
import path from "node:path";
import { fileURLToPath, pathToFileURL } from "node:url";
import dtcg from "./dtcg.mjs";

const ROOT = path.resolve(
  path.dirname(fileURLToPath(import.meta.url)),
  "../..",
);
const TOKENS = path.join(ROOT, "design/tokens");
const CHECK = process.argv.includes("--check");

const read = (p) => JSON.parse(fs.readFileSync(p, "utf8"));
const set = await dtcg.load(
  path.join(TOKENS, "anchor.resolver.json"),
  async (p) => read(p),
);
const THEMES = Object.keys(set.contexts);

const problems = [];
for (const t of THEMES)
  problems.push(...dtcg.check(set.contexts[t]).map((p) => `${t}: ${p}`));
const names = (t) => [...dtcg.tokens(set.contexts[t]).keys()].sort().join("\n");
if (names("light") !== names("dark")) {
  const light = new Set(names("light").split("\n")),
    dark = new Set(names("dark").split("\n"));
  for (const name of light)
    if (!dark.has(name)) problems.push(`only in light: ${name}`);
  for (const name of dark)
    if (!light.has(name)) problems.push(`only in dark: ${name}`);
}
if (problems.length) {
  console.error("Token problems:\n  " + problems.join("\n  "));
  process.exit(1);
}

const resolved = Object.fromEntries(
  THEMES.map((t) => [t, dtcg.resolve(set.contexts[t])]),
);
const css = Object.fromEntries(THEMES.map((t) => [t, dtcg.flat(resolved[t])]));
const base = dtcg.resolve(set.base),
  baseCss = dtcg.flat(base);
const EXT = set.base.$extensions["app.anchor"],
  CATALOG = EXT.catalog,
  WEB = EXT.web;
const kebab = (s) => s.replace(/([a-z0-9])([A-Z])/g, "$1-$2").toLowerCase();
const under = (res, prefix) =>
  [...res.values()].filter(
    (x) => x.path.startsWith(prefix + ".") && !x.deprecated,
  );
const tail = (x, prefix) => x.path.slice(prefix.length + 1);
const decl = (vars) =>
  Object.entries(vars)
    .map(([k, v]) => `  --${k}: ${v};`)
    .join("\n");
const block = (selector, vars, extra = "") =>
  `${selector} {\n${decl(vars)}${extra}\n}\n`;
const HEAD =
  "Generated from design/tokens by design/build/build.mjs. Do not edit by hand.";
const out = {};

// Must match the next/font variables in web/app/layout.tsx.
const FONT_VARS = {
  "DM Sans": "--font-dm-sans",
  "JetBrains Mono": "--font-jetbrains-mono",
  "Playfair Display": "--font-playfair",
};
const family = (p) => {
  const [first, ...rest] = baseCss[p].split(", ");
  const v = FONT_VARS[first.replace(/"/g, "")];
  return [v ? `var(${v})` : first, ...rest].join(", ");
};
const ms = (v) => (v.unit === "s" ? v.value * 1000 : v.value);

const staticTheme = {
  "font-sans": family("font.family.sans"),
  "font-mono": family("font.family.mono"),
  "font-serif": family("font.family.serif"),
  ...Object.fromEntries(
    under(base, "font.weight").map((x) => [
      "font-weight-" + tail(x, "font.weight"),
      baseCss[x.path],
    ]),
  ),
  "radius-*": "initial",
  ...Object.fromEntries(
    under(base, "radius").map((x) => [
      "radius-" + kebab(tail(x, "radius")),
      baseCss[x.path],
    ]),
  ),
  ...Object.fromEntries(
    under(base, "type").flatMap((x) => {
      const name = kebab(tail(x, "type")),
        style = x.value;
      return [
        [`text-${name}`, dtcg.css("dimension", style.fontSize)],
        [`text-${name}--line-height`, style.lineHeight],
        [
          `text-${name}--letter-spacing`,
          dtcg.css("dimension", style.letterSpacing),
        ],
        [`text-${name}--font-weight`, dtcg.css("fontWeight", style.fontWeight)],
      ];
    }),
  ),
  ...Object.fromEntries(
    under(base, "motion.ease").map((x) => [
      "ease-" + kebab(tail(x, "motion.ease")),
      baseCss[x.path],
    ]),
  ),
  "spacing-gutter": baseCss["space.gutter"],
  "spacing-gutter-phone": baseCss["space.gutterPhone"],
  ...Object.fromEntries(
    under(base, "breakpoint").map((x) => [
      "breakpoint-" + tail(x, "breakpoint"),
      baseCss[x.path],
    ]),
  ),
  ...Object.fromEntries(
    under(base, "color.avatar").map((x) => [
      "color-avatar-" + kebab(tail(x, "color.avatar")),
      baseCss[x.path],
    ]),
  ),
  ...Object.fromEntries(
    under(base, "color.media").map((x) => [
      "color-media-" + kebab(tail(x, "color.media")),
      baseCss[x.path],
    ]),
  ),
  "color-knob": baseCss["color.control.knob"],
};
const webColors = Object.keys(WEB.light).filter((k) => !k.startsWith("$"));
const HIGHLIGHTS = CATALOG.highlights;
const SIZES = under(base, "size")
  .filter((x) => x.type === "dimension")
  .map((x) => [kebab(tail(x, "size").replace(/\./g, "-")), baseCss[x.path]]);
// Sizes are spacing to Tailwind, so h-field and size-checkbox work.
const inlineTheme = {
  ...Object.fromEntries(webColors.map((k) => [`color-${k}`, `var(--${k})`])),
  ...Object.fromEntries(
    SIZES.map(([name]) => [`spacing-${name}`, `var(--size-${name})`]),
  ),
  ...Object.fromEntries(
    ["note", "note-surface", "note-border", "note-pattern", "note-muted"].map(
      (k) => [`color-${k}`, `var(--${k})`],
    ),
  ),
  ...Object.fromEntries(
    HIGHLIGHTS.flatMap((c) => [
      [`color-hl-${c}`, `var(--hl-${c})`],
      [`color-hl-${c}-ink`, `var(--hl-${c}-ink)`],
    ]),
  ),
  "shadow-*": "initial",
  ...Object.fromEntries(
    under(resolved.light, "shadow").map((x) => [
      `shadow-${kebab(tail(x, "shadow"))}`,
      `var(--sh-${kebab(tail(x, "shadow"))})`,
    ]),
  ),
};
const perNote = (t) =>
  resolved[t].get("color.check.mark").extensions?.["app.anchor"]?.perNote;
const colors = (t) => {
  const themeCss = css[t],
    ref = (v) => {
      const alias = typeof v === "string" && v.match(/^\{(.+)\}$/);
      return alias ? themeCss[alias[1]] : v;
    };
  return Object.fromEntries(
    webColors.map((k) => [
      k,
      k === "check-mark" && perNote(t) ? "initial" : ref(WEB[t][k]),
    ]),
  );
};
const themed = (t) => ({
  ...colors(t),
  ...Object.fromEntries(
    HIGHLIGHTS.map((c) => [`hl-${c}-ink`, css[t][`color.highlight.${c}.ink`]]),
  ),
  ...Object.fromEntries(
    under(resolved[t], "shadow").map((x) => [
      `sh-${kebab(tail(x, "shadow"))}`,
      css[t][x.path],
    ]),
  ),
  ...Object.fromEntries(
    under(resolved[t], "blend").map((x) => [
      `mix-${kebab(tail(x, "blend"))}`,
      css[t][x.path] + "%",
    ]),
  ),
});
const always = {
  ...Object.fromEntries(
    under(base, "motion.duration").map((x) => [
      `duration-${kebab(tail(x, "motion.duration"))}`,
      baseCss[x.path],
    ]),
  ),
  ...Object.fromEntries(
    under(base, "layer").map((x) => [
      `z-${kebab(tail(x, "layer"))}`,
      baseCss[x.path],
    ]),
  ),
  ...Object.fromEntries(SIZES.map(([name, value]) => [`size-${name}`, value])),
  ...Object.fromEntries(
    ["h1", "h2", "h3"].flatMap((h) => [
      [`heading-${h}`, baseCss[`heading.${h}.scale`] + "em"],
      [`heading-${h}--line-height`, baseCss[`heading.${h}.lineHeight`]],
      [`heading-${h}--letter-spacing`, baseCss[`heading.${h}.tracking`] + "em"],
      [`heading-${h}--font-weight`, baseCss[`heading.${h}.weight`]],
    ]),
  ),
  "mix-late": baseCss["blend.lateChip"] + "%",
};
out["web/app/styles/tokens.css"] = `/* ${HEAD} */
@theme static {
${decl(staticTheme)}
}

@theme inline {
${decl(inlineTheme)}
}

${block(":root", { ...always, ...themed("light") }, "\n  color-scheme: light;")}
${block(".dark", themed("dark"), "\n  color-scheme: dark;")}
${block(".light", themed("light"), "\n  color-scheme: light;")}`;

const svgUri = (w, h, body) =>
  `url("data:image/svg+xml,${encodeURIComponent(`<svg xmlns='http://www.w3.org/2000/svg' width='${w}' height='${h}'>${body}</svg>`)}")`;
const lucide = async (name) => {
  const file = path.join(
    ROOT,
    `web/node_modules/lucide-react/dist/esm/icons/${name}.mjs`,
  );
  const icon = await import(pathToFileURL(file).href);
  return icon.__iconData.node
    .map(
      ([tag, attrs]) =>
        `<${tag} ${Object.entries(attrs)
          .filter(([k]) => k !== "key")
          .map(([k, v]) => `${k}='${v}'`)
          .join(" ")}/>`,
    )
    .join("");
};
const pattern = async (kind, color) => {
  if (!kind) return "none";
  if (kind === "dots")
    return svgUri(20, 20, `<circle cx='10' cy='10' r='2' fill='${color}'/>`);
  if (kind === "grid")
    return svgUri(
      24,
      24,
      `<path d='M0.5 0V24M0 0.5H24' stroke='${color}' stroke-width='1' fill='none'/>`,
    );
  if (kind === "lines")
    return svgUri(
      24,
      24,
      `<path d='M0 23.5H24' stroke='${color}' stroke-width='1'/>`,
    );
  if (kind === "waves")
    return svgUri(
      40,
      40,
      `<path d='M0 20Q10 10 20 20T40 20' stroke='${color}' stroke-width='2' fill='none'/>`,
    );
  const [, name, rotation] = kind.split(":"),
    inner = await lucide(name);
  const icon = (x, y) =>
    `<g transform='translate(${x} ${y}) rotate(${rotation} 12 12)'>${inner}</g>`;
  return svgUri(
    60,
    120,
    `<g fill='none' stroke='${color}' stroke-width='2' stroke-linecap='round' stroke-linejoin='round'>${icon(8, 8)}${icon(38, 68)}${icon(-22, 68)}</g>`,
  );
};
const patternSize = (kind) =>
  !kind
    ? "auto"
    : kind === "dots"
      ? "20px 20px"
      : kind === "waves"
        ? "40px 40px"
        : kind.startsWith("icon")
          ? "60px 120px"
          : "24px 24px";
const BGS = [...CATALOG.backgrounds.colors, ...CATALOG.backgrounds.patterns];
const noteVars = async (t, bg) => {
  const noteColor = (p) => css[t][`color.note.${bg.note}.${p}`];
  const highlight = (c) =>
    css[t][
      resolved[t].has(`color.note.${bg.note}.highlight.${c}.fill`)
        ? `color.note.${bg.note}.highlight.${c}.fill`
        : `color.highlight.${c}.fill`
    ];
  return {
    note: noteColor("bg"),
    "note-surface": noteColor("surface"),
    "note-border": noteColor("border"),
    "note-pattern": noteColor("pattern"),
    "note-muted": noteColor("muted"),
    "note-image": await pattern(bg.kind, noteColor("pattern")),
    "note-image-size": patternSize(bg.kind),
    ...Object.fromEntries(HIGHLIGHTS.map((c) => [`hl-${c}`, highlight(c)])),
  };
};
const noteSelector = (t, bg) =>
  `${t === "dark" ? ".dark " : ""}[data-note${bg.id ? `="${bg.id}"` : ""}]`;
let notes = `/* ${HEAD} */\n`;
for (const t of THEMES)
  for (const bg of BGS)
    notes += block(noteSelector(t, bg), await noteVars(t, bg));
out["web/app/styles/notes.css"] = notes;

const json = (v) => JSON.stringify(v, null, 2);
const tags = CATALOG.tags.map((name) => ({
  name,
  stored: baseCss[`color.tag.${name}.stored`].toUpperCase(),
  hash: Object.fromEntries(
    THEMES.map((t) => [t, css[t][`color.tag.${name}.hash`]]),
  ),
  tintFill: Object.fromEntries(
    THEMES.map((t) => [t, css[t][`color.tag.${name}.tintFill`]]),
  ),
}));
out["web/lib/design/tokens.ts"] = `// ${HEAD}

/** A note stores the id; null is the default. */
export const BACKGROUNDS = ${json({
  colors: CATALOG.backgrounds.colors.map((b) => ({
    id: b.id,
    name: b.name,
    palette: b.note,
  })),
  patterns: CATALOG.backgrounds.patterns.map((b) => ({
    id: b.id,
    name: b.name,
    palette: b.note,
    kind: b.kind,
  })),
})} as const;

/** hash is the # on a chip; tintFill is the swatch fill. */
export const TAG_COLORS = ${json(tags)} as const;

/** Notes store the name, never a color. */
export const HIGHLIGHTS = ${json(HIGHLIGHTS)} as const;

/** Milliseconds. */
export const DURATION = ${json(Object.fromEntries(under(base, "motion.duration").map((x) => [tail(x, "motion.duration"), ms(x.value)])))} as const;

export const EASE = ${json(Object.fromEntries(under(base, "motion.ease").map((x) => [tail(x, "motion.ease"), baseCss[x.path]])))} as const;

export const TAILWIND_THEME = ${json({
  text: under(base, "type").map((x) => kebab(tail(x, "type"))),
  spacing: ["gutter", "gutter-phone", ...SIZES.map(([name]) => name)],
  radius: under(base, "radius").map((x) => kebab(tail(x, "radius"))),
  shadow: under(resolved.light, "shadow").map((x) => kebab(tail(x, "shadow"))),
  ease: under(base, "motion.ease").map((x) => kebab(tail(x, "motion.ease"))),
  "font-weight": under(base, "font.weight").map((x) => tail(x, "font.weight")),
})};
`;

const stale = [];
for (const [rel, text] of Object.entries(out)) {
  const file = path.join(ROOT, rel);
  const existing = fs.existsSync(file) ? fs.readFileSync(file, "utf8") : null;
  if (CHECK) {
    if (existing !== text) stale.push(rel);
    continue;
  }
  fs.mkdirSync(path.dirname(file), { recursive: true });
  if (existing !== text) fs.writeFileSync(file, text);
}
if (CHECK) {
  if (stale.length) {
    console.error(
      "Out of date, run node design/build/build.mjs:\n  " + stale.join("\n  "),
    );
    process.exit(1);
  }
  console.log("Generated files are up to date.");
} else {
  console.log(
    `${[...resolved.light.values()].length} tokens, ${THEMES.join(" and ")}, no problems`,
  );
  for (const rel of Object.keys(out))
    console.log(" ", rel, fs.statSync(path.join(ROOT, rel)).size, "bytes");
}
