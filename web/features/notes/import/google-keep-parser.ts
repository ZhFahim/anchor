import JSZip from "jszip";
import type { CreateNoteDto } from "../types";

/**
 * Extended CreateNoteDto with labels for import
 */
export interface ImportNoteDto extends CreateNoteDto {
  labels?: string[];
}

/**
 * Google Keep note structure from Takeout export
 */
interface GoogleKeepNote {
  title?: string;
  textContent?: string;
  color?: string;
  isPinned?: boolean;
  isArchived?: boolean;
  isTrashed?: boolean;
  labels?: Array<{ name: string }>;
  userEditedTimestampUsec?: number;
  createdTimestampUsec?: number;
  // List items for checklist notes
  listContent?: Array<{
    text: string;
    isChecked: boolean;
  }>;
  // Attachments (we'll just note them, not import media)
  attachments?: Array<{
    filePath: string;
    mimetype: string;
  }>;
}

/**
 * Map Google Keep colors to app background colors
 */
const COLOR_MAP: Record<string, string | null> = {
  DEFAULT: null,
  WHITE: null,
  RED: "red",
  ORANGE: "orange",
  YELLOW: "yellow",
  GREEN: "green",
  TEAL: "teal",
  BLUE: "blue",
  DARK_BLUE: "blue",
  PURPLE: "purple",
  PINK: "pink",
  BROWN: "brown",
  GRAY: "gray",
};

/**
 * Convert Google Keep checklist to plain text
 */
function convertListToText(
  listContent: Array<{ text: string; isChecked: boolean }>
): string {
  return listContent
    .map((item) => `${item.isChecked ? "☑" : "☐"} ${item.text}`)
    .join("\n");
}

/**
 * Parse a single Google Keep JSON note
 */
function parseKeepNote(json: GoogleKeepNote): ImportNoteDto | null {
  // Skip trashed notes
  if (json.isTrashed) {
    return null;
  }

  // Get content from either textContent or listContent
  let content = json.textContent || "";
  if (json.listContent && json.listContent.length > 0) {
    content = convertListToText(json.listContent);
  }

  // Skip empty notes (no title and no content)
  if (!json.title && !content) {
    return null;
  }

  // Extract labels
  const labels = json.labels?.map((l) => l.name) || [];

  return {
    title: json.title || "Untitled",
    content: content || undefined,
    isPinned: json.isPinned || false,
    isArchived: json.isArchived || false,
    background: json.color ? COLOR_MAP[json.color] || null : null,
    labels: labels.length > 0 ? labels : undefined,
  };
}

export interface ImportResult {
  notes: ImportNoteDto[];
  labels: string[];
  skipped: number;
  errors: string[];
}

/**
 * Parse Google Keep notes from a Takeout ZIP file
 */
export async function parseGoogleKeepZip(file: File): Promise<ImportResult> {
  const result: ImportResult = {
    notes: [],
    labels: new Set<string>() as unknown as string[],
    skipped: 0,
    errors: [],
  };
  const labelsSet = new Set<string>();

  try {
    const zip = await JSZip.loadAsync(file);
    const jsonFiles: JSZip.JSZipObject[] = [];

    // Find all JSON files in the Keep folder
    zip.forEach((relativePath, zipEntry) => {
      // Google Takeout structure: Takeout/Keep/*.json
      // Or sometimes just Keep/*.json
      if (
        relativePath.endsWith(".json") &&
        (relativePath.includes("Keep/") || relativePath.startsWith("Keep/"))
      ) {
        jsonFiles.push(zipEntry);
      }
    });

    if (jsonFiles.length === 0) {
      result.errors.push(
        "No Google Keep notes found in the ZIP file. Make sure you selected a Google Takeout export that includes Keep data."
      );
      return result;
    }

    // Parse each JSON file
    for (const zipEntry of jsonFiles) {
      try {
        const content = await zipEntry.async("string");
        const keepNote: GoogleKeepNote = JSON.parse(content);
        const parsedNote = parseKeepNote(keepNote);

        if (parsedNote) {
          result.notes.push(parsedNote);

          // Collect labels for potential tag creation
          if (keepNote.labels) {
            keepNote.labels.forEach((label) => labelsSet.add(label.name));
          }
        } else {
          result.skipped++;
        }
      } catch (e) {
        result.errors.push(`Failed to parse ${zipEntry.name}: ${e}`);
        result.skipped++;
      }
    }

    result.labels = Array.from(labelsSet);
  } catch (e) {
    result.errors.push(`Failed to read ZIP file: ${e}`);
  }

  return result;
}

/**
 * Parse Google Keep notes from individual JSON files
 */
export function parseGoogleKeepJson(jsonContent: string): CreateNoteDto | null {
  try {
    const keepNote: GoogleKeepNote = JSON.parse(jsonContent);
    return parseKeepNote(keepNote);
  } catch {
    return null;
  }
}
