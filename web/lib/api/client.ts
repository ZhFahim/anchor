import ky, { HTTPError } from "ky";
import {
  clearAccessToken,
  clearRefreshToken,
  getAccessToken,
  getRefreshToken,
  setAccessToken,
  setRefreshToken,
} from "@/features/auth/store";
import type { RefreshTokenResponse } from "@/features/auth/types";
import { fitsKeepalive, isPageClosing } from "@/lib/page-close";

let refreshPromise: Promise<boolean> | null = null;

class RefreshRefused extends Error {}

// Use fetch directly to avoid interceptor loops
async function requestNewTokens(): Promise<RefreshTokenResponse> {
  const storedRefreshToken = getRefreshToken();

  if (!storedRefreshToken) {
    throw new RefreshRefused("No refresh token available");
  }

  const response = await fetch("/api/auth/refresh", {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ refresh_token: storedRefreshToken }),
  });

  if (!response.ok) {
    if (response.status >= 500) throw new Error("Server unavailable");
    throw new RefreshRefused("Failed to refresh token");
  }

  return response.json();
}

function endSession(): void {
  if (typeof window !== "undefined") {
    window.dispatchEvent(new CustomEvent("auth:unauthorized"));
  }
}

function signOut(): void {
  clearAccessToken();
  clearRefreshToken();
  endSession();
}

async function runRefresh(): Promise<boolean> {
  try {
    const tokens = await requestNewTokens();
    setAccessToken(tokens.access_token);
    setRefreshToken(tokens.refresh_token);
    return true;
  } catch (error) {
    // Only a refused token signs out; an unreachable server keeps you in.
    if (error instanceof RefreshRefused) signOut();
    return false;
  } finally {
    refreshPromise = null;
  }
}

export function refreshAccessToken(): Promise<boolean> {
  refreshPromise ??= runRefresh();
  return refreshPromise;
}

export const api = ky.create({
  prefix: "/",
  timeout: 30000,
  hooks: {
    beforeRequest: [
      ({ request, options }) => {
        const token = getAccessToken();
        if (token) {
          request.headers.set("Authorization", `Bearer ${token}`);
        }
        // keepalive: the page is closing.
        if (isPageClosing() && fitsKeepalive(options.body))
          return new Request(request, { keepalive: true });
      },
    ],
    beforeError: [
      ({ error }) => {
        // Show the server's own message when it sends one.
        if (error instanceof HTTPError) {
          const { message } = (error.data ?? {}) as {
            message?: string | string[];
          };
          if (message) {
            error.message = Array.isArray(message)
              ? message.join(", ")
              : message;
          }
        }
        return error;
      },
    ],
    afterResponse: [
      async ({ request, response, retryCount }) => {
        if (response.status !== 401 || retryCount > 0) {
          return response;
        }

        // A failed sign-in, or a session that ended in another tab.
        if (!request.headers.has("Authorization")) {
          endSession();
          return response;
        }

        if (!(await refreshAccessToken())) {
          return response;
        }

        const headers = new Headers(request.headers);
        headers.set("Authorization", `Bearer ${getAccessToken()}`);
        return ky.retry({
          request: new Request(request, { headers }),
          delay: 0,
        });
      },
    ],
  },
});
