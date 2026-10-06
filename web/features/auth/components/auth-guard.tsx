"use client";

import { useQueryClient } from "@tanstack/react-query";
import { useRouter } from "next/navigation";
import { type ReactNode, useEffect } from "react";
import { useAuthStore } from "../store";
import { SessionCheck } from "./session-check";

interface AuthGuardProps {
  children: ReactNode;
}

function signInUrl() {
  const { pathname, search } = window.location;
  const path = pathname + search;
  return path === "/" || path === "/notes"
    ? "/login"
    : `/login?returnTo=${encodeURIComponent(path)}`;
}

export function AuthGuard({ children }: AuthGuardProps) {
  const router = useRouter();
  const queryClient = useQueryClient();
  const isAuthenticated = useAuthStore((state) => state.isAuthenticated);
  const isInitialized = useAuthStore((state) => state.isInitialized);
  const hasSignedOut = useAuthStore((state) => state.hasSignedOut);
  const logout = useAuthStore((state) => state.logout);

  useEffect(() => {
    const handleUnauthorized = () => logout();
    window.addEventListener("auth:unauthorized", handleUnauthorized);
    return () => {
      window.removeEventListener("auth:unauthorized", handleUnauthorized);
    };
  }, [logout]);

  useEffect(() => {
    if (isInitialized && !isAuthenticated) {
      queryClient.clear();
      router.replace(hasSignedOut ? "/login" : signInUrl());
    }
  }, [isInitialized, isAuthenticated, hasSignedOut, queryClient, router]);

  return <SessionCheck>{isAuthenticated ? children : null}</SessionCheck>;
}
