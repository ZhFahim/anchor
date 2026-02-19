"use client";

import { useCallback, useEffect } from "react";
import { useMutation } from "@tanstack/react-query";
import { useRouter } from "next/navigation";
import { useAuthStore, hasAccessToken, getRefreshToken } from "../store";
import { login as loginApi, register as registerApi, getMe, revokeRefreshToken } from "../api";
import type { LoginCredentials, RegisterCredentials } from "../types";
import { toast } from "sonner";

export function useAuth() {
  const router = useRouter();
  const {
    user,
    isAuthenticated,
    isInitialized,
    setAuth,
    setUser,
    setInitialized,
    logout: clearAuth,
  } = useAuthStore();

  // Initialize auth state by validating token with server
  const initialize = useCallback(async () => {
    if (!hasAccessToken()) {
      setInitialized(true);
      return;
    }

    try {
      const user = await getMe();
      setUser(user);
      setInitialized(true);
    } catch {
      // Token is invalid, clear auth state
      clearAuth();
    }
  }, [setUser, setInitialized, clearAuth]);

  // Listen for unauthorized events from API client
  useEffect(() => {
    const handleUnauthorized = () => {
      clearAuth();
      router.push("/login");
    };

    window.addEventListener("auth:unauthorized", handleUnauthorized);
    return () => {
      window.removeEventListener("auth:unauthorized", handleUnauthorized);
    };
  }, [clearAuth, router]);

  const loginMutation = useMutation({
    mutationFn: (credentials: LoginCredentials) => loginApi(credentials),
    onSuccess: (data) => {
      if (data.access_token && data.refresh_token) {
        setAuth(data.user, data.access_token, data.refresh_token);
        toast.success("Welcome back!");
        router.push("/");
      }
    },
    onError: (error: Error) => {
      toast.error(error.message || "Failed to login");
    },
  });

  const registerMutation = useMutation({
    mutationFn: (credentials: RegisterCredentials) => registerApi(credentials),
    onSuccess: (data) => {
      if (data.access_token && data.refresh_token) {
        // User is active, log them in
        setAuth(data.user, data.access_token, data.refresh_token);
        toast.success("Account created successfully!");
        router.push("/");
      } else {
        // User is pending approval
        toast.success(data.message || "Registration successful. Your account is pending approval.");
        router.push("/login");
      }
    },
    onError: (error: Error) => {
      toast.error(error.message || "Failed to create account");
    },
  });

  const logout = useCallback(async () => {
    try {
      await revokeRefreshToken(getRefreshToken());
    } catch {
      // Ignore - ensure local logout always completes
    }
    clearAuth();
    router.push("/login");
  }, [clearAuth, router]);

  return {
    user,
    isAuthenticated,
    isInitialized,
    initialize,
    login: loginMutation.mutate,
    register: registerMutation.mutate,
    logout,
    isLoginPending: loginMutation.isPending,
    isRegisterPending: registerMutation.isPending,
  };
}
