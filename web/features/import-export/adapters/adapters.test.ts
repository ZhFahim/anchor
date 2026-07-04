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
import { googleKeepAdapter } from "./google-keep";
import { detectFormat } from "./index";
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

describe("detectFormat", () => {
  it("returns the matching adapter for a zip file", async () => {
    const file = new File([anchorZipBytes() as BlobPart], "backup.zip", {
      type: "application/zip",
    });
    const result = await detectFormat(file);
    expect(result?.adapter.id).toBe("anchor");
  });

  it("returns null for a non-zip file", async () => {
    const file = new File([new Uint8Array([1, 2, 3])], "junk.bin");
    expect(await detectFormat(file)).toBeNull();
  });
});
