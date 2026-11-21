import type { ParsedImport } from "../types";
import type { ZipArchive } from "./zip";

export class ImportFileError extends Error {
  constructor(readonly reason: "backupTooNew") {
    super(reason);
  }
}

export interface ImportAdapter {
  id: ParsedImport["formatId"];
  /** Cheap check on the archive's entry listing / manifest */
  detect(zip: ZipArchive): Promise<boolean>;
  /** Eagerly parses metadata; attachment blobs stay lazy */
  parse(zip: ZipArchive): Promise<ParsedImport>;
}
