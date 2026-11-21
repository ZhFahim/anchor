import { HTTPError } from "ky";
import type { Translate } from "@/i18n/translate";
import { errorCodeOf } from "@/lib/api/error-code";

export const providerValues = (provider: string | undefined) => ({
  provider: provider ?? "",
  hasName: provider ? "yes" : "no",
});

/** "pending" when the account waits for approval, otherwise a message to show. */
export function signInError(
  t: Translate,
  error: Error | null,
  provider: string | undefined,
) {
  if (!error) return null;
  if (!(error instanceof HTTPError)) return t("errorUnreachable");
  const status = error.response.status;
  const code = errorCodeOf(error);
  if (code === "ACCOUNT_PENDING") return "pending" as const;
  if (code === "PASSWORD_SIGN_IN_DISABLED")
    return t("authSignInWithProviderInstead", providerValues(provider));
  if (code === "OIDC_ACCOUNT")
    return t("authAccountUsesProvider", providerValues(provider));
  if (status === 401) return t("authIncorrectCredentials");
  if (status === 429) return t("authTooManyTries");
  if (status >= 500) return t("errorServer");
  return t("authSignInFailed");
}

/** status is 0 when the server couldn't be reached. */
export function serverSignInError(
  t: Translate,
  status: number,
  isProviderOnly = false,
) {
  if (!status) return t("errorUnreachable");
  if (status === 429) return t("authTooManyTries");
  if (status >= 500) return t("errorServer");
  return isProviderOnly
    ? t("authSignInExpired")
    : t("authSignInExpiredOrEmail");
}
