import { strToU8, zipSync } from "fflate";
import { describe, expect, it } from "vitest";
import { anchorAdapter } from "./anchor";
import { anchorManifestFixture } from "./fixtures/anchor-manifest";
import {
  keepChecklistNote,
  keepLabeledNote,
  keepNoteWithMedia,
  keepTextNote,
  keepTrashedNote,
} from "./fixtures/keep-notes";
import {
  anchorExportArchived,
  anchorExportGroceries,
  appleIdeas,
  appleMeeting,
  blankFile,
  nextcloudPacking,
  nextcloudPancakes,
  obsidianAnchor,
  obsidianDaily,
  readmeFile,
} from "./fixtures/markdown-notes";
import { googleKeepAdapter } from "./google-keep";
import { detectFormat } from "./index";
import { markdownAdapter } from "./markdown";
import { readZip, type ZipArchive } from "./zip";

function anchorZipBytes(): Uint8Array {
  return zipSync({
    "manifest.json": strToU8(JSON.stringify(anchorManifestFixture)),
    "attachments/11111111-1111-4111-8111-111111111111/att-1.png":
      new Uint8Array([1, 2, 3, 4]),
  });
}

function buildAnchorZip(): ZipArchive {
  return readZip(anchorZipBytes());
}

function buildKeepZip(prefix = "Takeout/Keep/"): ZipArchive {
  return readZip(
    zipSync({
      [`${prefix}shopping.json`]: strToU8(JSON.stringify(keepTextNote)),
      [`${prefix}packing.json`]: strToU8(JSON.stringify(keepChecklistNote)),
      [`${prefix}ideas.json`]: strToU8(JSON.stringify(keepLabeledNote)),
      [`${prefix}junk.json`]: strToU8(JSON.stringify(keepTrashedNote)),
      [`${prefix}receipt-note.json`]: strToU8(
        JSON.stringify(keepNoteWithMedia),
      ),
      [`${prefix}shopping.html`]: strToU8("<html></html>"),
      [`${prefix}receipt.jpg`]: new Uint8Array([255, 216, 255]),
      [`${prefix}voice-memo.3gp`]: new Uint8Array([0, 0, 0]),
    }),
  );
}

const picked = (files: File[]) =>
  files.map((file) => ({ path: file.name, file }));

function markdownZip(entries: Record<string, string | Uint8Array>): ZipArchive {
  return readZip(
    zipSync(
      Object.fromEntries(
        Object.entries(entries).map(([name, value]) => [
          name,
          typeof value === "string" ? strToU8(value) : value,
        ]),
      ),
    ),
  );
}

const nextcloudZip = () =>
  markdownZip({
    "Notes/Recipes/Pancakes.md": nextcloudPancakes,
    "Notes/Travel/Packing.md": nextcloudPacking,
  });

const appleZip = () =>
  markdownZip({
    "Meeting- Q3 planning.md": appleMeeting,
    "Ideas.md": appleIdeas,
  });

const obsidianZip = () =>
  markdownZip({
    "Vault/Projects/Anchor.md": obsidianAnchor,
    "Vault/Daily/2026-01-01.md": obsidianDaily,
    "Vault/attachments/diagram.png": new Uint8Array([1, 2, 3]),
    "Vault/assets/shot.png": new Uint8Array([4, 5]),
    "Vault/Projects/spec.pdf": new Uint8Array([6]),
    "Vault/.obsidian/app.json": "{}",
    "Vault/.obsidian/notes.md": "hidden",
  });

const anchorMarkdownZip = () =>
  markdownZip({
    "Groceries.md": anchorExportGroceries,
    "Archived/Old plan.md": anchorExportArchived,
    "attachments/Groceries/receipt.png": new Uint8Array([7, 8]),
  });

describe("format detection", () => {
  it("detects anchor backups by manifest", async () => {
    expect(await anchorAdapter.detect(buildAnchorZip())).toBe(true);
    expect(await googleKeepAdapter.detect(buildAnchorZip())).toBe(false);
  });

  it("detects keep takeouts by folder path", async () => {
    expect(await googleKeepAdapter.detect(buildKeepZip())).toBe(true);
    expect(await anchorAdapter.detect(buildKeepZip())).toBe(false);
  });

  it("detects keep takeouts with localized folder names via content sniffing", async () => {
    const zip = buildKeepZip("Takeout/Notizen/");
    expect(await googleKeepAdapter.detect(zip)).toBe(true);
  });

  it("detects markdown files, and only after the specific formats", async () => {
    expect(await markdownAdapter.detect(nextcloudZip())).toBe(true);
    expect(
      await markdownAdapter.detect(markdownZip({ "notes/A.MARKDOWN": "hi" })),
    ).toBe(true);
    expect(await markdownAdapter.detect(buildAnchorZip())).toBe(false);
    expect(await markdownAdapter.detect(buildKeepZip())).toBe(false);
  });

  it("ignores hidden folders and macOS resource forks", async () => {
    const zip = markdownZip({
      "__MACOSX/._note.md": "junk",
      ".trash/gone.md": "junk",
    });
    expect(await markdownAdapter.detect(zip)).toBe(false);
  });
});

describe("anchorAdapter.parse", () => {
  it("maps manifest notes to canonical notes", async () => {
    const parsed = await anchorAdapter.parse(buildAnchorZip());

    expect(parsed.formatId).toBe("anchor");
    expect(parsed.notes).toHaveLength(3);
    // Every manifest tag survives with its color, even ones no note references.
    expect(
      [...parsed.tags].sort((a, b) => a.name.localeCompare(b.name)),
    ).toEqual([
      { name: "Empty tag", color: "#00ff00" },
      { name: "Personal", color: null },
      { name: "Work", color: "#ff0000" },
    ]);
    expect(parsed.attachmentCount).toBe(1);
    expect(parsed.skipped).toEqual([]);

    const owned = parsed.notes[0];
    expect(owned.id).toBe("11111111-1111-4111-8111-111111111111");
    expect(owned.isPinned).toBe(true);
    expect(owned.background).toBe("color_teal");
    expect(owned.tagNames).toEqual(["Work", "Personal"]);
    expect(owned.contentDelta).toEqual({ ops: [{ insert: "hello\n" }] });
    expect(owned.attachments[0].supported).toBe(true);
    expect((await owned.attachments[0].getBlob()).size).toBe(4);

    const trashed = parsed.notes[1];
    expect(trashed.isTrashed).toBe(true);

    const shared = parsed.notes[2];
    expect(shared.id).toBeUndefined();
    expect(shared.title).toBe("Shared with me");
  });

  it("rejects manifests from newer format versions", async () => {
    const zip = readZip(
      zipSync({
        "manifest.json": strToU8(
          JSON.stringify({ ...anchorManifestFixture, version: 2 }),
        ),
      }),
    );
    await expect(anchorAdapter.parse(zip)).rejects.toThrow(/newer version/);
  });

  it("rejects manifests with a missing version field", async () => {
    const { version: _dropped, ...versionless } = anchorManifestFixture;
    const zip = readZip(
      zipSync({ "manifest.json": strToU8(JSON.stringify(versionless)) }),
    );
    await expect(anchorAdapter.parse(zip)).rejects.toThrow(/newer version/);
  });
});

describe("googleKeepAdapter.parse", () => {
  it("imports active and archived notes, skipping trashed ones", async () => {
    const parsed = await googleKeepAdapter.parse(buildKeepZip());

    expect(parsed.formatId).toBe("google-keep");
    expect(parsed.notes.map((note) => note.title).sort()).toEqual([
      "Packing list",
      "Project ideas",
      "Receipt",
      "Shopping thoughts",
    ]);
    expect(parsed.skipped).toContainEqual({
      item: "Old junk",
      reason: "Trashed in Google Keep",
    });
  });

  it("maps keep fields to canonical notes", async () => {
    const parsed = await googleKeepAdapter.parse(buildKeepZip());
    const byTitle = new Map(parsed.notes.map((note) => [note.title, note]));

    const shopping = byTitle.get("Shopping thoughts");
    expect(shopping?.isPinned).toBe(true);
    expect(shopping?.background).toBe("color_teal");
    expect(shopping?.createdAt).toBe(new Date(1700000000000).toISOString());
    expect(shopping?.updatedAt).toBe(new Date(1700000400123).toISOString());
    expect(shopping?.contentDelta.ops[0]).toEqual({
      insert: "Buy milk\nAnd maybe bread\n",
    });

    const packing = byTitle.get("Packing list");
    expect(packing?.isArchived).toBe(true);
    expect(packing?.contentDelta.ops).toContainEqual({
      insert: "\n",
      attributes: { list: "checked" },
    });

    const ideas = byTitle.get("Project ideas");
    expect(ideas?.tagNames).toEqual(["Projects", "Weekend"]);
    expect(parsed.tags).toContainEqual({ name: "Projects", color: null });
    expect(ideas?.background).toBe("color_dark_blue");
    expect(ideas?.contentDelta.ops).toContainEqual({
      insert: "https://example.com/plans",
      attributes: { link: "https://example.com/plans" },
    });
  });

  it("resolves media by stem and flags unsupported types", async () => {
    const parsed = await googleKeepAdapter.parse(buildKeepZip());
    const receipt = parsed.notes.find((note) => note.title === "Receipt");

    expect(receipt?.attachments).toHaveLength(2);
    const [image, audio] = receipt?.attachments ?? [];
    expect(image.filename).toBe("receipt.jpg");
    expect(image.supported).toBe(true);
    expect(audio.supported).toBe(false);
    expect(parsed.skipped).toContainEqual({
      item: "voice-memo.3gp",
      reason: "Unsupported file type (audio/3gpp)",
    });
    // Only supported attachments count toward the preview total
    expect(parsed.attachmentCount).toBe(1);
  });
});

describe("markdownAdapter.parse", () => {
  it("takes the title from the filename and folders from the path", async () => {
    const parsed = await markdownAdapter.parse(nextcloudZip());

    expect(parsed.formatId).toBe("markdown");
    expect(parsed.hasFolders).toBe(true);
    expect(parsed.notes.map((note) => note.title)).toEqual([
      "Pancakes",
      "Packing",
    ]);
    expect(parsed.notes[0].folderTags).toEqual(["Recipes"]);
    expect(parsed.notes[1].folderTags).toEqual(["Travel"]);
    expect(parsed.tags).toEqual([
      { name: "Recipes", color: null },
      { name: "Travel", color: null },
    ]);
    expect(parsed.notes[0].tagNames).toEqual([]);
    expect(parsed.notes[0].contentDelta.ops).toContainEqual({
      insert: "\n",
      attributes: { list: "unchecked", indent: 1 },
    });
  });

  it("drops a title heading that repeats the filename", async () => {
    const parsed = await markdownAdapter.parse(appleZip());
    const byTitle = new Map(parsed.notes.map((note) => [note.title, note]));

    expect(byTitle.get("Meeting- Q3 planning")?.contentDelta.ops[0]).toEqual({
      insert: "Agenda",
    });
    // A heading that says something else is content
    expect(byTitle.get("Ideas")?.contentDelta.ops).toEqual([
      { insert: "Rough thoughts" },
      { insert: "\n", attributes: { header: 1 } },
      { insert: "\n" },
      { insert: "Body text" },
      { insert: "\n" },
    ]);
    expect(parsed.hasFolders).toBe(false);
  });

  it("resolves obsidian embeds and relative images, skipping other files", async () => {
    const parsed = await markdownAdapter.parse(obsidianZip());
    const anchor = parsed.notes.find((note) => note.title === "Anchor");

    expect(parsed.notes.map((note) => note.title).sort()).toEqual([
      "2026-01-01",
      "Anchor",
    ]);
    expect(anchor?.attachments.map((a) => a.filename)).toEqual([
      "diagram.png",
      "shot.png",
    ]);
    expect(await anchor?.attachments[0].getBlob().then((b) => b.size)).toBe(3);
    expect(parsed.attachmentCount).toBe(2);

    const text = anchor?.contentDelta.ops
      .map((op) => (typeof op.insert === "string" ? op.insert : ""))
      .join("");
    expect(text).toContain("See my ideas and spec");
    expect(text).not.toContain("diagram.png");
    expect(anchor?.folderTags).toEqual(["Projects"]);
  });

  it("keeps readme-style structure without inventing formats", async () => {
    const parsed = await markdownAdapter.parse(
      markdownZip({ "README.md": readmeFile }),
    );
    const ops = parsed.notes[0].contentDelta.ops;

    expect(ops[1]).toEqual({ insert: "\n", attributes: { header: 1 } });
    expect(ops).toContainEqual({
      insert: "\n",
      attributes: { "code-block": true },
    });
    expect(ops).toContainEqual({ insert: "| a | b |" });
    expect(ops).toContainEqual({
      insert: "https://example.com",
      attributes: { link: "https://example.com" },
    });
    expect(
      ops.some(
        (op) => typeof op.insert === "string" && op.insert.includes("&"),
      ),
    ).toBe(true);
    expect(parsed.notes[0].folderTags).toEqual([]);
  });

  it("round-trips its own markdown export", async () => {
    const parsed = await markdownAdapter.parse(anchorMarkdownZip());
    const groceries = parsed.notes.find((note) => note.title === "Groceries");
    const archived = parsed.notes.find((note) => note.title === "Old plan");

    expect(groceries?.contentDelta.ops).toEqual([
      { insert: "milk" },
      { insert: "\n" },
    ]);
    expect(groceries?.attachments.map((a) => a.filename)).toEqual([
      "receipt.png",
    ]);
    expect(archived?.isArchived).toBe(true);
    expect(archived?.folderTags).toEqual([]);
    expect(parsed.hasFolders).toBe(false);
  });

  it("finds a shared attachments folder kept above the notes", async () => {
    // How Apple Notes exporters lay out a multi-folder export
    const parsed = await markdownAdapter.parse(
      markdownZip({
        "Export/Personal/Trip.md": "![](Attachments/A1B2.jpeg)\n\nbody\n",
        "Export/Work/Plan.md": "See ![](Attachments/C3D4.jpeg)\n",
        "Export/Attachments/A1B2.jpeg": new Uint8Array([1]),
        "Export/Attachments/C3D4.jpeg": new Uint8Array([2, 3]),
      }),
    );

    expect(parsed.skipped).toEqual([]);
    expect(
      parsed.notes.map((note) => note.attachments.map((a) => a.filename)),
    ).toEqual([["A1B2.jpeg"], ["C3D4.jpeg"]]);
    expect(parsed.attachmentCount).toBe(2);
  });

  it("skips blank files and reports unresolved references", async () => {
    const parsed = await markdownAdapter.parse(
      markdownZip({
        "Blank.md": blankFile,
        "Real.md": "![missing](gone.png)\n\ntext\n",
        "Notes.txt": "ignored",
      }),
    );

    expect(parsed.notes.map((note) => note.title)).toEqual(["Real"]);
    expect(parsed.skipped).toContainEqual({
      item: "Blank",
      reason: "Empty file",
    });
    expect(parsed.skipped).toContainEqual({
      item: "gone.png",
      reason: "Attachment file not found",
    });
  });

  it("treats an Untitled filename as no title", async () => {
    const parsed = await markdownAdapter.parse(
      markdownZip({ "Untitled.md": "body\n" }),
    );
    expect(parsed.notes[0].title).toBe("");
  });
});

describe("detectFormat", () => {
  it("returns the matching adapter for a zip file", async () => {
    const file = new File([anchorZipBytes() as BlobPart], "backup.zip", {
      type: "application/zip",
    });
    const result = await detectFormat([{ path: file.name, file }]);
    expect(result?.adapter.id).toBe("anchor");
  });

  it("reads loose markdown files without a zip around them", async () => {
    const files = picked([
      new File(["# a\n"], "First.md", { type: "text/markdown" }),
      new File(["b\n"], "Second.md", { type: "text/markdown" }),
    ]);
    const result = await detectFormat(files);
    expect(result?.adapter.id).toBe("markdown");

    const parsed = await result?.adapter.parse(result.zip);
    expect(parsed?.notes.map((note) => note.title)).toEqual([
      "First",
      "Second",
    ]);
  });

  it("pairs a loose markdown file with the image it references", async () => {
    const files = picked([
      new File(["![shot](shot.png)\n\nbody\n"], "Note.md"),
      new File([new Uint8Array([1, 2])], "shot.png", { type: "image/png" }),
    ]);
    const result = await detectFormat(files);
    const parsed = await result?.adapter.parse(result.zip);

    expect(parsed?.notes[0].attachments.map((a) => a.filename)).toEqual([
      "shot.png",
    ]);
  });

  it("keeps the folder structure of a picked directory", async () => {
    const result = await detectFormat([
      {
        path: "Vault/Recipes/Pancakes.md",
        file: new File(["flour\n"], "Pancakes.md"),
      },
      {
        path: "Vault/Travel/Packing.md",
        file: new File(["passport\n"], "Packing.md"),
      },
    ]);
    const parsed = await result?.adapter.parse(result.zip);

    expect(result?.adapter.id).toBe("markdown");
    expect(parsed?.notes.map((note) => note.folderTags)).toEqual([
      ["Recipes"],
      ["Travel"],
    ]);
  });

  it("returns null for a non-zip file and for an empty pick", async () => {
    const file = new File([new Uint8Array([1, 2, 3])], "junk.bin");
    expect(await detectFormat(picked([file]))).toBeNull();
    expect(await detectFormat([])).toBeNull();
  });
});
