import type { PickedFile } from "./adapters/zip";

/** Ceiling on how many files one drop can bring in. */
export const MAX_PICKED_FILES = 5000;

/** Files chosen through an input; a folder pick carries its relative path. */
export function fromFileList(files: FileList | null): PickedFile[] {
  return Array.from(files ?? []).map((file) => ({
    path: file.webkitRelativePath || file.name,
    file,
  }));
}

function readFile(entry: FileSystemFileEntry): Promise<File> {
  return new Promise((resolve, reject) => entry.file(resolve, reject));
}

function readBatch(
  reader: FileSystemDirectoryReader,
): Promise<FileSystemEntry[]> {
  return new Promise((resolve, reject) => reader.readEntries(resolve, reject));
}

async function walkEntry(
  entry: FileSystemEntry,
  prefix: string,
  out: PickedFile[],
): Promise<void> {
  if (out.length >= MAX_PICKED_FILES) return;

  if (entry.isFile) {
    out.push({
      path: `${prefix}${entry.name}`,
      file: await readFile(entry as FileSystemFileEntry),
    });
    return;
  }
  if (!entry.isDirectory) return;

  // readEntries hands back at most 100 children per call
  const reader = (entry as FileSystemDirectoryEntry).createReader();
  for (;;) {
    const batch = await readBatch(reader);
    if (!batch.length) return;
    for (const child of batch) {
      await walkEntry(child, `${prefix}${entry.name}/`, out);
    }
  }
}

/**
 * Files from a drop, walking any folders that came with it. Entries must be
 * read from the event before the first await.
 */
export async function fromDataTransfer(
  transfer: DataTransfer,
): Promise<PickedFile[]> {
  const entries = Array.from(transfer.items ?? [])
    .map((item) => item.webkitGetAsEntry?.() ?? null)
    .filter((entry): entry is FileSystemEntry => entry !== null);
  const fallback = fromFileList(transfer.files);

  if (entries.length) {
    const out: PickedFile[] = [];
    for (const entry of entries) {
      await walkEntry(entry, "", out);
    }
    if (out.length) return out;
  }

  return fallback;
}
