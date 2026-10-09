"use client";

import { useQuery } from "@tanstack/react-query";
import { HTTPError } from "ky";
import { useRouter, useSearchParams } from "next/navigation";
import { useEffect, useRef, useState } from "react";
import { toast } from "@/components/ui/toast";
import { firstName } from "@/lib/utils";
import { exchangeOidcCode, getOidcConfig } from "../api";
import { useAuthStore } from "../store";
import type { OidcConfig } from "../types";
import { getSafeRedirectUrl } from "../utils/redirect";

export function useOidcConfig() {
  return useQuery<OidcConfig>({
    queryKey: ["oidc-config"],
    queryFn: getOidcConfig,
    retry: false,
    retryOnMount: false,
    staleTime: 5 * 60 * 1000, // Consider fresh for 5 minutes
  });
}

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

/** status is 0 when the server couldn't be reached. */
export type ProviderSignInFailure =
  | { by: "provider"; message: string }
  | { by: "server"; status: number; message: string };

/** Handles the OIDC callback: ?code=...&redirect=... (no JWT in the URL). */
export function useOidcCallback() {
  const searchParams = useSearchParams();
  const router = useRouter();
  const { setAuth, setInitialized } = useAuthStore();
  const processedRef = useRef(false);
  const [isProcessing, setIsProcessing] = useState(
    () => searchParams.has("code") && !searchParams.has("error"),
  );
  const [failure, setFailure] = useState<ProviderSignInFailure | null>(null);

  useEffect(() => {
    const code = searchParams.get("code");
    const error = searchParams.get("error");
    const status = searchParams.get("status");

    if (error) {
      if (!processedRef.current) {
        processedRef.current = true;
        setFailure(
          status
            ? { by: "server", status: Number(status), message: error }
            : { by: "provider", message: error },
        );
        router.replace("/login");
      }
      return;
    }

    if (code && !processedRef.current) {
      processedRef.current = true;
      exchangeOidcCode(code)
        .then((result) => {
          // GuestGuard navigates once signed in.
          setAuth(result.user, result.access_token, result.refresh_token);
          setInitialized(true);
          toast.success(`Welcome back, ${firstName(result.user.name)}`);
        })
        .catch((err: unknown) => {
          setFailure({
            by: "server",
            status: err instanceof HTTPError ? err.response.status : 0,
            message: err instanceof Error ? err.message : "",
          });
          router.replace("/login");
        })
        .finally(() => {
          setIsProcessing(false);
        });
    }
  }, [searchParams, router, setAuth, setInitialized]);

  return { isProcessing, failure, clearFailure: () => setFailure(null) };
}
