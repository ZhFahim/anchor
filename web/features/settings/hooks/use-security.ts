"use client";

import { useQuery } from "@tanstack/react-query";
import { getTwoFactorStatus } from "@/features/auth/api";
import { useOidcConfig } from "@/features/auth/hooks/use-oidc";
import { useAuthStore } from "@/features/auth/store";

export const securityKeys = {
  status: ["two-factor"] as const,
};

/**
 * Whether this person manages their own second step, and what the server
 * offers. People without a password, and instances that sign in with a
 * provider only, have nothing to set up here.
 */
export function useSecurity() {
  const user = useAuthStore((s) => s.user);
  const oidc = useOidcConfig();
  const isProviderOnly =
    !!oidc.data?.enabled && !!oidc.data?.disableInternalAuth;
  const isManagedElsewhere = user?.hasPassword === false || isProviderOnly;
  const status = useQuery({
    queryKey: securityKeys.status,
    queryFn: getTwoFactorStatus,
    // Not before we know whether the provider alone signs people in.
    enabled: !!user && oidc.isFetched && !isManagedElsewhere,
  });
  const offersNothing =
    !!status.data &&
    !status.data.available.totp &&
    !status.data.available.passkeys;
  return {
    status,
    isManagedElsewhere,
    providerName: oidc.data?.providerName || "your sign-in provider",
    /** There is nothing to show: not even a note why. */
    isHidden: !isManagedElsewhere && offersNothing,
  };
}
