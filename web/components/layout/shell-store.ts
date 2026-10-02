import { create } from "zustand";

interface ShellState {
  drawerOpen: boolean;
  setDrawer: (open: boolean) => void;
  barShown: boolean;
  setBarShown: (shown: boolean) => void;
}

export const useShellStore = create<ShellState>((set) => ({
  drawerOpen: false,
  setDrawer: (drawerOpen) => set({ drawerOpen }),
  barShown: false,
  setBarShown: (barShown) => set({ barShown }),
}));
