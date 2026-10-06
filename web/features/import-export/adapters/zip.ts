import { strFromU8, unzipSync } from "fflate";

/** Read-only archive access. Also backs files picked without a zip around them. */
export type ZipArchive = {
  names: string[];
  has(path: string): boolean;
  text(path: string): string;
  blob(path: string): Blob;
};

const TEXT_ENTRY = /\.(json|md|markdown)$/i;

export function readZip(data: Uint8Array): ZipArchive {
  // fflate's filter runs before decompression: returning false lists names
  // without inflating anything.
  const names: string[] = [];
  unzipSync(data, {
    filter: (file) => {
      if (!file.name.endsWith("/")) names.push(file.name);
      return false;
    },
  });
  const nameSet = new Set(names);

  // unzipSync walks the whole archive on every call, so text entries inflate in one pass.
  const inflate = (path: string): Uint8Array => {
    const out = unzipSync(data, { filter: (file) => file.name === path });
    const bytes = out[path];
    if (!bytes) throw new Error(`Zip entry not found: ${path}`);
    return bytes;
  };

  let texts: Map<string, string> | undefined;
  const readTexts = () => {
    try {
      const out = unzipSync(data, {
        filter: (file) => TEXT_ENTRY.test(file.name),
      });
      return new Map(
        Object.entries(out).map(([name, bytes]) => [name, strFromU8(bytes)]),
      );
    } catch {
      // A damaged entry fails the whole pass; text() then inflates one by one.
      return new Map<string, string>();
    }
  };

  return {
    names,
    has: (path) => nameSet.has(path),
    text: (path) => {
      texts ??= readTexts();
      return texts.get(path) ?? strFromU8(inflate(path));
    },
    // fflate's Uint8Array is ArrayBufferLike-typed but never SharedArrayBuffer.
    blob: (path) => new Blob([inflate(path) as Uint8Array<ArrayBuffer>]),
  };
}

/** A picked file and the path it had inside the folder it came from. */
export type PickedFile = { path: string; file: File };

/**
 * Presents picked files as an archive. Text files are read up front;
 * attachments stay on disk until uploaded.
 */
export async function readFiles(picked: PickedFile[]): Promise<ZipArchive> {
  const files = new Map(picked.map(({ path, file }) => [path, file]));
  const texts = new Map(
    await Promise.all(
      [...files]
        .filter(([path]) => TEXT_ENTRY.test(path))
        .map(async ([path, file]) => [path, await file.text()] as const),
    ),
  );

  return {
    names: [...files.keys()],
    has: (path) => files.has(path),
    text: (path) => {
      const text = texts.get(path);
      if (text === undefined) throw new Error(`Text file not found: ${path}`);
      return text;
    },
    blob: (path) => {
      const file = files.get(path);
      if (!file) throw new Error(`File not found: ${path}`);
      return file;
    },
  };
}
