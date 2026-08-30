import { strFromU8, unzipSync } from "fflate";

/**
 * Minimal read-only archive access, so adapters don't depend on a zip
 * library. Also backs files picked without a zip around them.
 */
export type ZipArchive = {
  names: string[];
  has(path: string): boolean;
  text(path: string): string;
  blob(path: string): Blob;
};

export function readZip(data: Uint8Array): ZipArchive {
  // fflate has no list-without-inflate API, but its filter runs per entry
  // before decompression - returning false enumerates names, inflating nothing.
  const names: string[] = [];
  unzipSync(data, {
    filter: (file) => {
      if (!file.name.endsWith("/")) names.push(file.name);
      return false;
    },
  });
  const nameSet = new Set(names);

  // Inflate a single entry on demand to keep attachment reads lazy.
  const inflate = (path: string): Uint8Array => {
    const out = unzipSync(data, { filter: (file) => file.name === path });
    const bytes = out[path];
    if (!bytes) throw new Error(`Zip entry not found: ${path}`);
    return bytes;
  };

  return {
    names,
    has: (path) => nameSet.has(path),
    text: (path) => strFromU8(inflate(path)),
    // fflate's Uint8Array is ArrayBufferLike-typed but never SharedArrayBuffer.
    blob: (path) => new Blob([inflate(path) as Uint8Array<ArrayBuffer>]),
  };
}

/** A picked file and the path it had inside the folder it came from. */
export type PickedFile = { path: string; file: File };

/**
 * Presents picked files as an archive. Bytes are read up front; only the zip
 * path stays lazy.
 */
export async function readFiles(picked: PickedFile[]): Promise<ZipArchive> {
  const buffers = await Promise.all(
    picked.map(({ file }) => file.arrayBuffer()),
  );
  const entries = new Map<string, { bytes: Uint8Array; type: string }>();

  picked.forEach(({ path, file }, index) => {
    entries.set(path, {
      bytes: new Uint8Array(buffers[index]),
      type: file.type,
    });
  });

  const read = (path: string) => {
    const entry = entries.get(path);
    if (!entry) throw new Error(`File not found: ${path}`);
    return entry;
  };

  return {
    names: [...entries.keys()],
    has: (path) => entries.has(path),
    text: (path) => strFromU8(read(path).bytes),
    blob: (path) => {
      const entry = read(path);
      return new Blob([entry.bytes as Uint8Array<ArrayBuffer>], {
        type: entry.type,
      });
    },
  };
}
