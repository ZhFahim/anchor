import { create } from "zustand";
import { persist } from "zustand/middleware";
import type { User } from "@/features/auth";

let accessToken: string | null = null;
let refreshToken: string | null = null;

// Standalone token functions for use by API client (avoids circular deps)
export function getAccessToken(): string | null {
  return accessToken;
}

export function setAccessToken(token: string): void {
  accessToken = token;
}

export function clearAccessToken(): void {
  accessToken = null;
}

export function hasAccessToken(): boolean {
  return !!getAccessToken();
}

// Refresh token functions
export function getRefreshToken(): string | null {
  return refreshToken;
}

export function setRefreshToken(token: string): void {
  refreshToken = token;
}

export function clearRefreshToken(): void {
  refreshToken = null;
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
