/**
 * Validates that a redirect URL is safe: relative path or same-origin.
 * Returns the URL if safe, otherwise returns fallback (default '/').
 */
export function getSafeRedirectUrl(
  redirectUrl: string | null | undefined,
  fallback = "/"
): string {
  const trimmed = redirectUrl?.trim();
  if (!trimmed) {
    return fallback;
  }
  // Reject protocol-relative URLs
  if (trimmed.startsWith("//")) {
    return fallback;
  }
  // Allow relative paths (single leading /, no // in path)
  if (trimmed.startsWith("/") && !trimmed.includes("//")) {
    return trimmed;
  }
  // Allow same-origin absolute URLs
  try {
    const redirect = new URL(trimmed);
    if (typeof window !== "undefined" && redirect.origin === window.location.origin) {
      return trimmed;
    }
    // Server-side or different origin
    if (typeof window === "undefined") {
      return trimmed;
    }
  } catch {
    // Invalid URL
  }
  return fallback;
}
