import { create } from "zustand";
import { persist } from "zustand/middleware";

export type ViewMode = "masonry" | "grid" | "list";
export type SortBy = "updatedAt" | "createdAt" | "title";
export type SortOrder = "asc" | "desc";

export interface UIPreferences {
  sidebarCollapsed: boolean;
}

export interface NotesPreferences {
  viewMode: ViewMode;
  sortBy: SortBy;
  sortOrder: SortOrder;
}

export interface EditorPreferences {
  sortChecklistItems: boolean;
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
  resetPreferences: () => void;
}

const defaultUIPreferences: UIPreferences = {
  sidebarCollapsed: false,
};

const defaultNotesPreferences: NotesPreferences = {
  viewMode: "masonry",
  sortBy: "updatedAt",
  sortOrder: "desc",
};

const defaultEditorPreferences: EditorPreferences = {
  sortChecklistItems: true,
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
      resetPreferences: () => set(initialState),
    }),
    {
      name: "preferences",
    },
  ),
);
