import { create } from "zustand";
import { persist } from "zustand/middleware";
import type { User } from "@/features/auth";

const TOKEN_KEY = "access_token";
const REFRESH_TOKEN_KEY = "refresh_token";

// Standalone token functions for use by API client (avoids circular deps)
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

// Refresh token functions
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

export function hasRefreshToken(): boolean {
  return !!getRefreshToken();
}

interface AuthState {
  user: User | null;
  isAuthenticated: boolean;
  isInitialized: boolean;
  setAuth: (user: User, accessToken: string, refreshToken: string) => void;
  setUser: (user: User | null) => void;
  setInitialized: (initialized: boolean) => void;
  logout: () => void;
  reset: () => void;
}

const initialState = {
  user: null,
  isAuthenticated: false,
  isInitialized: false,
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
      setInitialized: (isInitialized) => set({ isInitialized }),
      logout: () => {
        clearAccessToken();
        clearRefreshToken();
        set({ ...initialState, isInitialized: true });
      },
      reset: () => {
        clearAccessToken();
        clearRefreshToken();
        set(initialState);
      },
    }),
    {
      name: "auth-storage",
      partialize: (state) => ({
        user: state.user,
        isAuthenticated: state.isAuthenticated,
      }),
    }
  )
);
