/**
 * Markdown files shaped like the exports Anchor should accept. Tests
 * assemble these into in-memory zips.
 */

const lines = (...values: string[]) => `${values.join("\n")}\n`;

/** Nextcloud Notes: category folder, no title heading, a checklist. */
export const nextcloudPancakes = lines(
  "Mix and fry.",
  "",
  "- [ ] flour",
  "- [x] eggs",
  "    - [ ] free range",
);

export const nextcloudPacking = lines("- passport", "- charger");

/** Apple Notes exporters repeat the title as an H1 and sanitize the filename. */
export const appleMeeting = lines(
  "# Meeting: Q3 planning",
  "",
  "Agenda",
  "",
  "1. Budget",
  "2. Hiring",
);

export const appleIdeas = lines("# Rough thoughts", "", "Body text");

/** Obsidian: wiki embeds, a relative image, a wikilink and a stray pdf. */
export const obsidianAnchor = lines(
  "Design notes.",
  "",
  "![[diagram.png]]",
  "![screenshot](../assets/shot.png)",
  "See [[Ideas|my ideas]] and [spec](spec.pdf)",
);

export const obsidianDaily = lines("Woke up early.");

/** A README-style file: setext, fences, a table and a thematic break. */
export const readmeFile = lines(
  "Project",
  "=======",
  "",
  "```js",
  "const a = 1;",
  "```",
  "",
  "| a | b |",
  "| --- | --- |",
  "| 1 | 2 |",
  "",
  "***",
  "",
  "1) First",
  "",
  "Docs at <https://example.com> &amp; more",
);

/** What Anchor's own markdown export writes. */
export const anchorExportGroceries = lines(
  "milk",
  "",
  "![receipt.png](attachments/Groceries/receipt.png)",
);

export const anchorExportArchived = lines("Old plan body");

export const blankFile = "   \n\n";
