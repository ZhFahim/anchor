import { strFromU8, unzipSync } from "fflate";

/** Minimal read-only zip access, so adapters don't depend on a zip library. */
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
