import { describe, expect, it } from "vitest";
import {
  fromDataTransfer,
  fromFileList,
  MAX_PICKED_FILES,
} from "./picked-files";

const fileEntry = (name: string, content = "x") =>
  ({
    isFile: true,
    isDirectory: false,
    name,
    file: (resolve: (file: File) => void) => resolve(new File([content], name)),
  }) as unknown as FileSystemEntry;

const dirEntry = (name: string, children: FileSystemEntry[]) => {
  let served = false;
  return {
    isFile: false,
    isDirectory: true,
    name,
    createReader: () => ({
      // The real reader hands back its children once, then an empty batch
      readEntries: (resolve: (entries: FileSystemEntry[]) => void) => {
        resolve(served ? [] : children);
        served = true;
      },
    }),
  } as unknown as FileSystemEntry;
};

const transferOf = (entries: FileSystemEntry[], files: File[] = []) =>
  ({
    items: entries.map((entry) => ({ webkitGetAsEntry: () => entry })),
    files,
  }) as unknown as DataTransfer;

const droppedPaths = async (transfer: DataTransfer) =>
  (await fromDataTransfer(transfer)).files.map((item) => item.path);

describe("fromFileList", () => {
  it("keeps the relative path of a folder pick", () => {
    const file = new File(["x"], "Note.md");
    Object.defineProperty(file, "webkitRelativePath", {
      value: "Vault/Notes/Note.md",
    });

    expect(fromFileList([file] as unknown as FileList)).toEqual([
      { path: "Vault/Notes/Note.md", file },
    ]);
  });

  it("falls back to the plain name and tolerates no selection", () => {
    const file = new File(["x"], "Note.md");
    expect(fromFileList([file] as unknown as FileList)[0].path).toBe("Note.md");
    expect(fromFileList(null)).toEqual([]);
  });
});

describe("fromDataTransfer", () => {
  it("walks a dropped folder, keeping paths", async () => {
    const transfer = transferOf([
      dirEntry("Vault", [
        fileEntry("Note.md"),
        dirEntry("attachments", [fileEntry("shot.png")]),
      ]),
    ]);

    expect(await droppedPaths(transfer)).toEqual([
      "Vault/Note.md",
      "Vault/attachments/shot.png",
    ]);
  });

  it("skips hidden files and folders and macOS resource forks", async () => {
    const transfer = transferOf([
      dirEntry("Vault", [
        fileEntry("Note.md"),
        fileEntry(".DS_Store"),
        dirEntry(".obsidian", [fileEntry("app.json")]),
        dirEntry(".git", [fileEntry("HEAD")]),
      ]),
      dirEntry("__MACOSX", [fileEntry("._Note.md")]),
    ]);

    expect(await droppedPaths(transfer)).toEqual(["Vault/Note.md"]);
  });

  it("stops at the file limit and says so", async () => {
    const files = Array.from({ length: MAX_PICKED_FILES + 1 }, (_, index) =>
      fileEntry(`${index}.md`),
    );
    const dropped = await fromDataTransfer(
      transferOf([dirEntry("Vault", files)]),
    );

    expect(dropped.files).toHaveLength(MAX_PICKED_FILES);
    expect(dropped.isTruncated).toBe(true);
  });

  it("is not truncated when the drop fits the limit exactly", async () => {
    const files = Array.from({ length: MAX_PICKED_FILES }, (_, index) =>
      fileEntry(`${index}.md`),
    );
    const dropped = await fromDataTransfer(
      transferOf([dirEntry("Vault", files)]),
    );

    expect(dropped.files).toHaveLength(MAX_PICKED_FILES);
    expect(dropped.isTruncated).toBe(false);
  });

  it("handles a plain file drop", async () => {
    const transfer = transferOf([fileEntry("backup.zip")]);
    expect(await droppedPaths(transfer)).toEqual(["backup.zip"]);
  });

  it("falls back to the file list when entries are unavailable", async () => {
    const file = new File(["x"], "Note.md");
    const transfer = {
      items: [{ webkitGetAsEntry: () => null }],
      files: [file],
    } as unknown as DataTransfer;

    expect(await fromDataTransfer(transfer)).toEqual({
      files: [{ path: "Note.md", file }],
      isTruncated: false,
    });
  });
});
