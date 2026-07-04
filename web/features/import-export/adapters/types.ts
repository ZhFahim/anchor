import type { ParsedImport } from "../types";
import type { ZipArchive } from "./zip";

export interface ImportAdapter {
  id: ParsedImport["formatId"];
  label: string;
  /** Cheap check on the archive's entry listing / manifest */
  detect(zip: ZipArchive): Promise<boolean>;
  /** Eagerly parses metadata; attachment blobs stay lazy */
  parse(zip: ZipArchive): Promise<ParsedImport>;
}
