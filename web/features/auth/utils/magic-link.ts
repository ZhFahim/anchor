// The Android app opens anchorplus://magic-login (its AndroidManifest.xml),
// and reads the same https link from a QR code.
const APP_SCHEME = "anchorplus";
const APP_HOST = "magic-login";

/** What the QR code holds and Copy magic link copies: this page, any browser opens it. */
export function magicLinkUrl(code: string, origin: string): string {
  const url = new URL("/magic-login", origin);
  url.searchParams.set("code", code);
  return url.toString();
}

function appQuery(code: string, server: string): string {
  return new URLSearchParams({ server, code }).toString();
}

/** Opens the Android app, which signs in to [server] with [code]. */
export function appLinkUrl(code: string, server: string): string {
  return `${APP_SCHEME}://${APP_HOST}?${appQuery(code, server)}`;
}

/**
 * The same, as Chrome on Android wants it from a page: it opens whichever
 * build of the app is installed (release, preview or debug).
 */
export function androidIntentUrl(code: string, server: string): string {
  return `intent://${APP_HOST}?${appQuery(code, server)}#Intent;scheme=${APP_SCHEME};end`;
}
