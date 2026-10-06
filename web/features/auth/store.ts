import { create } from "zustand";
import { persist } from "zustand/middleware";
import type { User } from "./types";

const TOKEN_KEY = "access_token";
const REFRESH_TOKEN_KEY = "refresh_token";

// Plain functions the API client can import without a circular dependency.
export function getAccessToken(): string | null {
  if (typeof window === "undefined") return null;
  return localStorage.getItem(TOKEN_KEY);
}

export function setAccessToken(token: string): void {
  if (typeof window !== "undefined") {
    localStorage.setItem(TOKEN_KEY, token);
  }
}

export function clearAccessToken(): void {
  if (typeof window !== "undefined") {
    localStorage.removeItem(TOKEN_KEY);
  }
}

export function hasAccessToken(): boolean {
  return !!getAccessToken();
}

export function getRefreshToken(): string | null {
  if (typeof window === "undefined") return null;
  return localStorage.getItem(REFRESH_TOKEN_KEY);
}

export function setRefreshToken(token: string): void {
  if (typeof window !== "undefined") {
    localStorage.setItem(REFRESH_TOKEN_KEY, token);
  }
}

export function clearRefreshToken(): void {
  if (typeof window !== "undefined") {
    localStorage.removeItem(REFRESH_TOKEN_KEY);
  }
}

interface AuthState {
  user: User | null;
  isAuthenticated: boolean;
  isInitialized: boolean;
  unreachable: boolean;
  /** Signed out from the menu, not by a session that ended. */
  hasSignedOut: boolean;
  setUnreachable: (unreachable: boolean) => void;
  setAuth: (user: User, accessToken: string, refreshToken: string) => void;
  setUser: (user: User | null) => void;
  mergeUser: (changes: Partial<User>) => void;
  setInitialized: (initialized: boolean) => void;
  logout: (options?: { hasSignedOut?: boolean }) => void;
}

const initialState = {
  user: null,
  isAuthenticated: false,
  isInitialized: false,
  unreachable: false,
  hasSignedOut: false,
};

export const useAuthStore = create<AuthState>()(
  persist(
    (set) => ({
      ...initialState,
      setAuth: (user, accessToken, refreshToken) => {
        setAccessToken(accessToken);
        setRefreshToken(refreshToken);
        set({
          user,
          isAuthenticated: true,
          isInitialized: true,
        });
      },
      setUser: (user) =>
        set({
          user,
          isAuthenticated: !!user,
        }),
      mergeUser: (changes) =>
        set((state) =>
          state.user ? { user: { ...state.user, ...changes } } : {},
        ),
      setInitialized: (isInitialized) => set({ isInitialized }),
      setUnreachable: (unreachable) => set({ unreachable }),
      logout: ({ hasSignedOut = false } = {}) => {
        clearAccessToken();
        clearRefreshToken();
        set({ ...initialState, isInitialized: true, hasSignedOut });
      },
    }),
    {
      name: "auth-storage",
      partialize: (state) => ({
        user: state.user,
        isAuthenticated: state.isAuthenticated,
      }),
    },
  ),
);
