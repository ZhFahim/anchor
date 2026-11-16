"use client";

import { useMutation, useQuery } from "@tanstack/react-query";
import { HTTPError } from "ky";
import { useCallback } from "react";
import { toast } from "@/components/ui/toast";
import { firstName } from "@/lib/utils";
import {
  getCapabilities,
  getMe,
  getRegistrationMode,
  login as loginApi,
  loginWithTwoFactor,
  register as registerApi,
  revokeRefreshToken,
} from "../api";
import { signInWithPasskey } from "../passkey";
import { getRefreshToken, hasAccessToken, useAuthStore } from "../store";
import type {
  LoginCredentials,
  RegisterCredentials,
  Session,
  TwoFactorLoginDto,
} from "../types";

async function initialize() {
  const { isInitialized, setUser, setInitialized, setUnreachable, logout } =
    useAuthStore.getState();
  if (isInitialized) return;

  if (!hasAccessToken()) {
    logout();
    return;
  }

  try {
    const user = await getMe();
    setUnreachable(false);
    setUser(user);
    setInitialized(true);
  } catch (error) {
    if (
      error instanceof HTTPError &&
      (error.response.status === 401 || error.response.status === 403)
    )
      logout();
    else setUnreachable(true);
  }
}

export function useAuth() {
  const {
    user,
    isAuthenticated,
    isInitialized,
    unreachable,
    logout: clearAuth,
  } = useAuthStore();

  const logout = useCallback(async () => {
    try {
      await revokeRefreshToken(getRefreshToken());
    } catch {
      // Sign out locally anyway.
    }
    clearAuth({ hasSignedOut: true });
  }, [clearAuth]);

  return {
    user,
    isAuthenticated,
    isInitialized,
    unreachable,
    initialize,
    logout,
  };
}

export function useRegistrationMode() {
  return useQuery({
    queryKey: ["registration-mode"],
    queryFn: getRegistrationMode,
    retryOnMount: false,
  });
}

/** Signs in with a session the server just issued. */
function useStartSession() {
  const setAuth = useAuthStore((state) => state.setAuth);
  return (session: Session, greeting = "Welcome back") => {
    setAuth(session.user, session.access_token, session.refresh_token);
    toast.success(`${greeting}, ${firstName(session.user.name)}`);
  };
}

export function useCapabilities() {
  return useQuery({
    queryKey: ["auth-capabilities"],
    queryFn: getCapabilities,
    retry: false,
    retryOnMount: false,
    staleTime: 5 * 60 * 1000,
  });
}

/** Resolves to a session, or to a challenge the page has to answer. */
export function useLogin() {
  const startSession = useStartSession();
  return useMutation({
    mutationFn: (credentials: LoginCredentials) => loginApi(credentials),
    onSuccess: (outcome) => {
      if (outcome.kind === "signedIn") startSession(outcome.session);
    },
  });
}

export function useTwoFactorLogin() {
  const startSession = useStartSession();
  return useMutation({
    mutationFn: (dto: TwoFactorLoginDto) => loginWithTwoFactor(dto),
    onSuccess: (session) => startSession(session),
  });
}

export function usePasskeyLogin() {
  const startSession = useStartSession();
  return useMutation({
    mutationFn: signInWithPasskey,
    onSuccess: (session) => startSession(session),
  });
}

export function useRegister() {
  const startSession = useStartSession();
  return useMutation({
    mutationFn: (credentials: RegisterCredentials) => registerApi(credentials),
    onSuccess: (outcome) => {
      // A pending account gets no tokens, and a person who has to set up
      // two-factor gets them once they have.
      if (outcome.kind === "signedIn")
        startSession(outcome.session, "Welcome to Anchor");
    },
  });
}
