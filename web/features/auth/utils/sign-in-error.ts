import { HTTPError } from "ky";

/** "pending" when the account waits for approval, otherwise a message to show. */
export function signInError(error: Error | null, provider: string) {
  if (!error) return null;
  if (!(error instanceof HTTPError))
    return "Couldn’t reach the server. Check your connection and try again.";
  const status = error.response.status;
  if (status === 403 && /pending/i.test(error.message))
    return "pending" as const;
  if (status === 403 && /turned off/i.test(error.message))
    return `Sign in with ${provider} instead.`;
  if ((status === 401 || status === 400) && /oidc/i.test(error.message))
    return `This account signs in with ${provider}. Use the button above.`;
  if (status === 401) return "Incorrect email or password.";
  if (status === 429) return "Too many tries. Wait a minute, then try again.";
  if (status >= 500)
    return "Something went wrong on the server. Try again in a moment.";
  return "Couldn’t sign in. Try again.";
}

/** status is 0 when the server couldn't be reached. */
export function serverSignInError(status: number, isProviderOnly = false) {
  if (!status)
    return "Couldn’t reach the server. Check your connection and try again.";
  if (status === 429) return "Too many tries. Wait a minute, then try again.";
  if (status >= 500)
    return "Something went wrong on the server. Try again in a moment.";
  return isProviderOnly
    ? "That sign-in has expired. Try again."
    : "That sign-in has expired. Try again, or sign in with your email.";
}
