import { HTTPError } from "ky";

/**
 * The JSON body of a failed call. ky reads it before the error reaches the
 * caller, so `error.response.json()` would fail; it is on `error.data`.
 */
export function errorBody(error: unknown): Record<string, unknown> | null {
  if (!(error instanceof HTTPError)) return null;
  const { data } = error;
  return data && typeof data === "object" && !Array.isArray(data)
    ? (data as Record<string, unknown>)
    : null;
}
