import { describe, expect, it } from "vitest";
import { fromDataTransfer, fromFileList } from "./picked-files";

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

    expect((await fromDataTransfer(transfer)).map((item) => item.path)).toEqual(
      ["Vault/Note.md", "Vault/attachments/shot.png"],
    );
  });

  it("handles a plain file drop", async () => {
    const transfer = transferOf([fileEntry("backup.zip")]);
    expect((await fromDataTransfer(transfer)).map((item) => item.path)).toEqual(
      ["backup.zip"],
    );
  });

  it("falls back to the file list when entries are unavailable", async () => {
    const file = new File(["x"], "Note.md");
    const transfer = {
      items: [{ webkitGetAsEntry: () => null }],
      files: [file],
    } as unknown as DataTransfer;

    expect(await fromDataTransfer(transfer)).toEqual([
      { path: "Note.md", file },
    ]);
  });
});
