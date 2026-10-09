"use client";

import { useRouter } from "next/navigation";
import { type ReactNode, useEffect } from "react";
import { useRegistrationMode } from "../hooks/use-auth";
import { useOidcConfig } from "../hooks/use-oidc";
import { useAuthStore } from "../store";
import { getSafeRedirectUrl } from "../utils/redirect";
import { SessionCheck } from "./session-check";

interface GuestGuardProps {
  children: ReactNode;
}

// A provider sign-in comes back with the server's own "redirect".
function afterSignInUrl() {
  const params = new URLSearchParams(window.location.search);
  const url = getSafeRedirectUrl(
    params.get("redirect") ?? params.get("returnTo"),
    "/notes",
  );
  return url === "/" ? "/notes" : url;
}

export function GuestGuard({ children }: GuestGuardProps) {
  const router = useRouter();
  const isAuthenticated = useAuthStore((state) => state.isAuthenticated);
  const isInitialized = useAuthStore((state) => state.isInitialized);
  const oidc = useOidcConfig();
  const registrationMode = useRegistrationMode();

  useEffect(() => {
    if (isInitialized && isAuthenticated) {
      router.replace(afterSignInUrl());
    }
  }, [isInitialized, isAuthenticated, router]);

  return (
    <SessionCheck isWaiting={!oidc.isFetched || !registrationMode.isFetched}>
      {isAuthenticated ? null : children}
    </SessionCheck>
  );
}
