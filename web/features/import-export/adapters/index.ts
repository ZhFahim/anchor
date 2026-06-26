import { anchorAdapter } from "./anchor";
import type { ImportAdapter } from "./types";
import { readZip, type ZipArchive } from "./zip";

// Detection runs in order; anchor's manifest check is the cheapest and
// most specific. New formats (markdown, ...) register here.
const ADAPTERS: ImportAdapter[] = [anchorAdapter];

export async function detectFormat(
  file: File,
): Promise<{ adapter: ImportAdapter; zip: ZipArchive } | null> {
  let zip: ZipArchive;
  try {
    zip = readZip(new Uint8Array(await file.arrayBuffer()));
  } catch {
    return null;
  }

  for (const adapter of ADAPTERS) {
    if (await adapter.detect(zip)) {
      return { adapter, zip };
    }
  }
  return null;
}
