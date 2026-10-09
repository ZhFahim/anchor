/** A path on this site with no backslash or whitespace, like "/notes/abc?x=1". */
const PLAIN_PATH = /^\/(?![/\\])[^\\\s]*$/;

/**
 * The path, search and hash of a redirect that stays on this site, or the
 * fallback for anything that would leave it.
 */
export function getSafeRedirectUrl(
  redirectUrl: string | null | undefined,
  fallback = "/",
): string {
  const trimmed = redirectUrl?.trim();
  if (!trimmed) {
    return fallback;
  }
  if (typeof window === "undefined") {
    return PLAIN_PATH.test(trimmed) ? trimmed : fallback;
  }
  try {
    const { origin } = window.location;
    const redirect = new URL(trimmed, origin);
    if (redirect.origin === origin) {
      return redirect.pathname + redirect.search + redirect.hash;
    }
  } catch {
    // Not a URL.
  }
  return fallback;
}
