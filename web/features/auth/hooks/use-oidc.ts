"use client";

import { useEffect, useRef, useState } from "react";
import { useSearchParams, useRouter } from "next/navigation";
import { useQuery } from "@tanstack/react-query";
import { toast } from "sonner";
import { getOidcConfig, exchangeOidcCode } from "../api";
import { useAuthStore } from "../store";
import { getSafeRedirectUrl } from "../utils/redirect";
import type { OidcConfig } from "../types";

/**
 * Hook to get OIDC configuration
 */
export function useOidcConfig() {
  return useQuery<OidcConfig>({
    queryKey: ["oidc-config"],
    queryFn: getOidcConfig,
    retry: false,
    staleTime: 5 * 60 * 1000, // Consider fresh for 5 minutes
  });
}

/**
 * Hook to initiate OIDC login flow.
 */
export function useOidcLogin() {
  return {
    initiate: (redirectUrl?: string) => {
      const url = new URL("/api/auth/oidc/initiate", window.location.origin);
      if (redirectUrl) {
        url.searchParams.set("redirect", getSafeRedirectUrl(redirectUrl));
      }
      window.location.href = url.toString();
    },
  };
}

/**
 * Hook to handle OIDC callback from URL parameters.
 * Supports exchange code pattern: ?code=...&redirect=... (no JWT in URL).
 */
export function useOidcCallback() {
  const searchParams = useSearchParams();
  const router = useRouter();
  const { setAuth, setInitialized } = useAuthStore();
  const processedRef = useRef(false);
  const [isProcessing, setIsProcessing] = useState(false);

  useEffect(() => {
    const code = searchParams.get("code");
    const error = searchParams.get("error");

    if (error) {
      if (!processedRef.current) {
        processedRef.current = true;
        toast.error(decodeURIComponent(error));
        router.replace("/login");
      }
      return;
    }

    if (code && !processedRef.current) {
      processedRef.current = true;
      setIsProcessing(true);
      exchangeOidcCode(code)
        .then((result) => {
          setAuth(result.user, result.access_token, result.refresh_token);
          setInitialized(true);
          toast.success("Welcome back!");
          router.replace(getSafeRedirectUrl(result.redirectUrl));
        })
        .catch((err) => {
          toast.error(err.message || "Failed to authenticate");
          router.replace("/login");
        })
        .finally(() => {
          setIsProcessing(false);
        });
    }
  }, [searchParams, router, setAuth, setInitialized]);

  return { isProcessing };
}
