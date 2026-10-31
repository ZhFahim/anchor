import { create } from "zustand";
import { persist } from "zustand/middleware";

export type ViewMode = "masonry" | "grid" | "list";
export type SortBy = "updatedAt" | "createdAt" | "title";
export type SortOrder = "asc" | "desc";

interface UIPreferences {
  sidebarCollapsed: boolean;
}

interface NotesPreferences {
  viewMode: ViewMode;
  sortBy: SortBy;
  sortOrder: SortOrder;
  openArchivedTagIds: string[];
}

interface EditorPreferences {
  sortChecklistItems: boolean;
  foldedChecklistNoteIds: string[];
}

interface PreferencesState {
  ui: UIPreferences;
  notes: NotesPreferences;
  editor: EditorPreferences;
  setUIPreference: <K extends keyof UIPreferences>(
    key: K,
    value: UIPreferences[K],
  ) => void;
  setNotesPreference: <K extends keyof NotesPreferences>(
    key: K,
    value: NotesPreferences[K],
  ) => void;
  setEditorPreference: <K extends keyof EditorPreferences>(
    key: K,
    value: EditorPreferences[K],
  ) => void;
  setChecklistFolded: (noteId: string, isFolded: boolean) => void;
  setArchivedOpen: (tagId: string, isOpen: boolean) => void;
}

const defaultUIPreferences: UIPreferences = {
  sidebarCollapsed: false,
};

const defaultNotesPreferences: NotesPreferences = {
  viewMode: "masonry",
  sortBy: "updatedAt",
  sortOrder: "desc",
  openArchivedTagIds: [],
};

const defaultEditorPreferences: EditorPreferences = {
  sortChecklistItems: true,
  foldedChecklistNoteIds: [],
};

const MAX_FOLDED_NOTES = 500;
const MAX_OPEN_TAGS = 200;

const updateIdList = (
  ids: string[],
  id: string,
  isIncluded: boolean,
  max: number,
) => {
  const others = ids.filter((other) => other !== id);
  return isIncluded ? [...others, id].slice(-max) : others;
};

const initialState = {
  ui: defaultUIPreferences,
  notes: defaultNotesPreferences,
  editor: defaultEditorPreferences,
};

export const usePreferencesStore = create<PreferencesState>()(
  persist(
    (set) => ({
      ...initialState,
      setUIPreference: (key, value) =>
        set((state) => ({
          ui: { ...state.ui, [key]: value },
        })),
      setNotesPreference: (key, value) =>
        set((state) => ({
          notes: { ...state.notes, [key]: value },
        })),
      setEditorPreference: (key, value) =>
        set((state) => ({
          editor: { ...state.editor, [key]: value },
        })),
      setChecklistFolded: (noteId, isFolded) =>
        set((state) => ({
          editor: {
            ...state.editor,
            foldedChecklistNoteIds: updateIdList(
              state.editor.foldedChecklistNoteIds,
              noteId,
              isFolded,
              MAX_FOLDED_NOTES,
            ),
          },
        })),
      setArchivedOpen: (tagId, isOpen) =>
        set((state) => ({
          notes: {
            ...state.notes,
            openArchivedTagIds: updateIdList(
              state.notes.openArchivedTagIds,
              tagId,
              isOpen,
              MAX_OPEN_TAGS,
            ),
          },
        })),
    }),
    {
      name: "preferences",
      // Settings added later get their defaults.
      merge: (persisted, current) => {
        const saved = (persisted ?? {}) as Partial<PreferencesState>;
        return {
          ...current,
          ui: { ...current.ui, ...saved.ui },
          notes: { ...current.notes, ...saved.notes },
          editor: { ...current.editor, ...saved.editor },
        };
      },
    },
  ),
);
