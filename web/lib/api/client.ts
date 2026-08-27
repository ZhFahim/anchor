import ky, { HTTPError } from "ky";
import type { RefreshTokenResponse } from "@/features/auth";
import {
  clearAccessToken,
  clearRefreshToken,
  getAccessToken,
  getRefreshToken,
  setAccessToken,
  setRefreshToken,
} from "@/features/auth";

let refreshPromise: Promise<boolean> | null = null;

// Use fetch directly to avoid interceptor loops
async function requestNewTokens(): Promise<RefreshTokenResponse> {
  const storedRefreshToken = getRefreshToken();

  if (!storedRefreshToken) {
    throw new Error("No refresh token available");
  }

  const response = await fetch("/api/auth/refresh", {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ refresh_token: storedRefreshToken }),
  });

  if (!response.ok) {
    throw new Error("Failed to refresh token");
  }

  return response.json();
}

function signOut(): void {
  clearAccessToken();
  clearRefreshToken();
  if (typeof window !== "undefined") {
    window.dispatchEvent(new CustomEvent("auth:unauthorized"));
  }
}

async function runRefresh(): Promise<boolean> {
  try {
    const tokens = await requestNewTokens();
    setAccessToken(tokens.access_token);
    setRefreshToken(tokens.refresh_token);
    return true;
  } catch {
    signOut();
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
      ({ request }) => {
        const token = getAccessToken();
        if (token) {
          request.headers.set("Authorization", `Bearer ${token}`);
        }
      },
    ],
    beforeError: [
      async ({ error }) => {
        // Extract error message from API response body
        if (error instanceof HTTPError) {
          try {
            const errorBody = (await error.response.json()) as {
              message?: string | string[];
            };
            // Handle both string messages and array of validation errors
            if (errorBody.message) {
              if (Array.isArray(errorBody.message)) {
                error.message = errorBody.message.join(", ");
              } else {
                error.message = errorBody.message;
              }
            }
          } catch {
            // If we can't parse the error body, keep the original message
          }
        }
        return error;
      },
    ],
    afterResponse: [
      async ({ request, response }) => {
        if (response.status !== 401) {
          return response;
        }

        if (request.url.includes("/api/auth/refresh")) {
          signOut();
          return response;
        }

        if (!(await refreshAccessToken())) {
          return response;
        }

        request.headers.set("Authorization", `Bearer ${getAccessToken()}`);
        return ky(request);
      },
    ],
  },
});
