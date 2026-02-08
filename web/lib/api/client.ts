import ky, { HTTPError } from "ky";
import { getAccessToken, clearAccessToken, getRefreshToken, setAccessToken, setRefreshToken, clearRefreshToken } from "@/features/auth";
import type { RefreshTokenResponse } from "@/features/auth";

// Flag to prevent multiple simultaneous refresh attempts
let isRefreshing = false;
let refreshPromise: Promise<RefreshTokenResponse> | null = null;

// Function to refresh tokens (uses fetch to avoid circular dependencies)
async function attemptTokenRefresh(): Promise<RefreshTokenResponse> {
  const storedRefreshToken = getRefreshToken();

  if (!storedRefreshToken) {
    throw new Error('No refresh token available');
  }

  // Use fetch directly to avoid interceptor loops
  const response = await fetch('/api/auth/refresh', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ refresh_token: storedRefreshToken }),
  });

  if (!response.ok) {
    throw new Error('Failed to refresh token');
  }

  return response.json();
}

// Create the API client with interceptors
export const api = ky.create({
  prefixUrl: "/",
  timeout: 30000,
  hooks: {
    beforeRequest: [
      (request) => {
        const token = getAccessToken();
        if (token) {
          request.headers.set("Authorization", `Bearer ${token}`);
        }
      },
    ],
    beforeError: [
      async (error) => {
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
      async (request, _options, response) => {
        // Handle 401 errors - attempt token refresh
        if (response.status === 401) {
          // Don't try to refresh if we're already on the refresh endpoint
          if (request.url.includes('/api/auth/refresh')) {
            clearAccessToken();
            clearRefreshToken();
            if (typeof window !== "undefined") {
              window.dispatchEvent(new CustomEvent("auth:unauthorized"));
            }
            return response;
          }

          try {
            // If already refreshing, wait for that to complete
            if (isRefreshing && refreshPromise) {
              const newTokens = await refreshPromise;
              setAccessToken(newTokens.access_token);
              setRefreshToken(newTokens.refresh_token);

              // Retry the original request with new token
              request.headers.set("Authorization", `Bearer ${newTokens.access_token}`);
              return ky(request);
            }

            // Start refresh process
            isRefreshing = true;
            refreshPromise = attemptTokenRefresh();

            const newTokens = await refreshPromise;

            // Store new tokens
            setAccessToken(newTokens.access_token);
            setRefreshToken(newTokens.refresh_token);

            // Reset refresh state
            isRefreshing = false;
            refreshPromise = null;

            // Retry the original request with new token
            request.headers.set("Authorization", `Bearer ${newTokens.access_token}`);
            return ky(request);

          } catch (refreshError) {
            // Refresh failed, clear all tokens and trigger logout
            isRefreshing = false;
            refreshPromise = null;
            clearAccessToken();
            clearRefreshToken();

            if (typeof window !== "undefined") {
              window.dispatchEvent(new CustomEvent("auth:unauthorized"));
            }
          }
        }
        return response;
      },
    ],
  },
});
