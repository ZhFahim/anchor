import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";

vi.mock("@/features/auth/store", () => ({
  getAccessToken: vi.fn(() => null),
  getRefreshToken: vi.fn(() => null),
  setAccessToken: vi.fn(),
  setRefreshToken: vi.fn(),
  clearAccessToken: vi.fn(),
  clearRefreshToken: vi.fn(),
}));

import * as auth from "@/features/auth/store";
import { api, isSessionless, refreshAccessToken } from "./client";
import { errorBody } from "./error-body";

afterEach(() => {
  vi.unstubAllGlobals();
  vi.resetAllMocks();
});

function replyWith(status: number, body: string, contentType: string) {
  return api.extend({
    baseUrl: "http://anchor.test",
    fetch: () =>
      Promise.resolve(
        new Response(body, {
          status,
          headers: { "content-type": contentType },
        }),
      ),
  });
}

async function errorOf(request: Promise<unknown>): Promise<Error> {
  try {
    await request;
  } catch (error) {
    return error as Error;
  }
  throw new Error("expected the request to fail");
}

async function errorMessageOf(request: Promise<unknown>): Promise<string> {
  return (await errorOf(request)).message;
}

describe("api errors", () => {
  it("show the server's message", async () => {
    const client = replyWith(
      401,
      JSON.stringify({ message: "Invalid credentials" }),
      "application/json",
    );

    expect(await errorMessageOf(client.post("api/auth/login"))).toBe(
      "Invalid credentials",
    );
  });

  it("join the server's validation messages", async () => {
    const client = replyWith(
      400,
      JSON.stringify({ message: ["email must be an email", "name is empty"] }),
      "application/json",
    );

    expect(await errorMessageOf(client.post("api/auth/register"))).toBe(
      "email must be an email, name is empty",
    );
  });

  it("keep the default message when the server sends no message", async () => {
    const client = replyWith(502, "Bad Gateway", "text/plain");

    expect(await errorMessageOf(client.post("api/notes"))).toMatch(
      /^Request failed with status code 502/,
    );
  });
});

describe("token refresh", () => {
  it("signs out when the server turns the refresh token down", async () => {
    vi.mocked(auth.getRefreshToken).mockReturnValue("old");
    const signedOut = vi.fn();
    vi.stubGlobal("window", { dispatchEvent: signedOut });
    vi.stubGlobal(
      "fetch",
      vi.fn(() => Promise.resolve(new Response("{}", { status: 401 }))),
    );
    expect(await refreshAccessToken()).toBe(false);
    expect(auth.clearAccessToken).toHaveBeenCalled();
    expect(signedOut).toHaveBeenCalled();
  });

  it("keeps you signed in when the server can't be reached", async () => {
    vi.mocked(auth.getRefreshToken).mockReturnValue("old");
    vi.stubGlobal(
      "fetch",
      vi.fn(() => Promise.reject(new TypeError("Failed to fetch"))),
    );
    expect(await refreshAccessToken()).toBe(false);
    expect(auth.clearAccessToken).not.toHaveBeenCalled();
  });

  it("keeps you signed in when the server is down", async () => {
    vi.mocked(auth.getRefreshToken).mockReturnValue("old");
    vi.stubGlobal(
      "fetch",
      vi.fn(() => Promise.resolve(new Response("", { status: 502 }))),
    );
    expect(await refreshAccessToken()).toBe(false);
    expect(auth.clearAccessToken).not.toHaveBeenCalled();
  });
});

describe("a request whose token has expired", () => {
  let refresh: ReturnType<typeof vi.fn>;
  let sent: { authorization: string | null; body: string }[];

  beforeEach(() => {
    vi.mocked(auth.getAccessToken).mockReturnValue("old");
    vi.mocked(auth.getRefreshToken).mockReturnValue("refresh");
    vi.mocked(auth.setAccessToken).mockImplementation((token) => {
      vi.mocked(auth.getAccessToken).mockReturnValue(token);
    });
    refresh = vi.fn(() =>
      Promise.resolve(
        Response.json({ access_token: "new", refresh_token: "refresh-2" }),
      ),
    );
    vi.stubGlobal("fetch", refresh);
    sent = [];
  });

  function serverWith(retry: () => Promise<Response>) {
    return api.extend({
      baseUrl: "http://anchor.test",
      fetch: async (input) => {
        const request = input as Request;
        sent.push({
          authorization: request.headers.get("Authorization"),
          body: await request.text(),
        });
        return sent.length === 1
          ? Response.json({ message: "Unauthorized" }, { status: 401 })
          : retry();
      },
    });
  }

  it("is sent again with the new token and the same body", async () => {
    const client = serverWith(() => Promise.resolve(Response.json({ ok: 1 })));

    expect(
      await client.post("api/notes", { json: { title: "Hi" } }).json(),
    ).toEqual({ ok: 1 });
    expect(refresh).toHaveBeenCalledTimes(1);
    expect(sent).toEqual([
      { authorization: "Bearer old", body: '{"title":"Hi"}' },
      { authorization: "Bearer new", body: '{"title":"Hi"}' },
    ]);
  });

  it("shows the server's message when the second try fails", async () => {
    const client = serverWith(() =>
      Promise.resolve(
        Response.json({ message: "Title is too long" }, { status: 400 }),
      ),
    );

    expect(await errorMessageOf(client.post("api/notes"))).toBe(
      "Title is too long",
    );
  });

  it("refreshes only once when the new token is turned down too", async () => {
    const client = serverWith(() =>
      Promise.resolve(Response.json({ message: "Nope" }, { status: 401 })),
    );

    expect(await errorMessageOf(client.post("api/notes"))).toBe("Nope");
    expect(refresh).toHaveBeenCalledTimes(1);
    expect(sent).toHaveLength(2);
  });

  it("keeps the call's own timeout on the second try", async () => {
    const client = serverWith(
      () =>
        new Promise((resolve) =>
          setTimeout(() => resolve(Response.json({ ok: 1 })), 200),
        ),
    );

    const error = await errorOf(client.post("api/notes", { timeout: 50 }));
    expect(error.name).toBe("TimeoutError");
  });

  it("isn't refreshed when it was sent without a token", async () => {
    vi.mocked(auth.getAccessToken).mockReturnValue(null);
    const sessionEnded = vi.fn();
    vi.stubGlobal("window", { dispatchEvent: sessionEnded });
    const client = serverWith(() => Promise.resolve(Response.json({ ok: 1 })));

    expect(await errorMessageOf(client.post("api/notes"))).toBe("Unauthorized");
    expect(refresh).not.toHaveBeenCalled();
    expect(auth.clearAccessToken).not.toHaveBeenCalled();
    expect(sent).toEqual([{ authorization: null, body: "" }]);
    expect(sessionEnded).toHaveBeenCalled();
  });

  it("isn't refreshed when a code is turned down, so it isn't counted twice", async () => {
    const failing = api.extend({
      baseUrl: "http://anchor.test",
      fetch: async (input) => {
        sent.push({
          authorization: (input as Request).headers.get("Authorization"),
          body: "",
        });
        return Response.json({ message: "Invalid code" }, { status: 401 });
      },
    });

    expect(await errorMessageOf(failing.post("api/auth/2fa/enable"))).toBe(
      "Invalid code",
    );
    expect(refresh).not.toHaveBeenCalled();
    expect(sent).toHaveLength(1);
  });
});

describe("calls made without a session", () => {
  beforeEach(() => {
    // A leftover token from an earlier session must not be sent along.
    vi.mocked(auth.getAccessToken).mockReturnValue("stale");
    vi.mocked(auth.getRefreshToken).mockReturnValue("stale-refresh");
  });

  it("recognises the sign-in and enrolment paths", () => {
    for (const path of [
      "/api/auth/login",
      "/api/auth/login/2fa",
      "/api/auth/register",
      "/api/auth/enroll/totp/setup",
      "/api/auth/enroll/passkey/verify",
      "/api/auth/passkeys/login/options",
      "http://anchor.test/api/auth/login/2fa?x=1",
    ])
      expect(isSessionless(path), path).toBe(true);
    for (const path of [
      "/api/auth/me",
      "/api/auth/2fa",
      "/api/auth/passkeys/register/options",
      "/api/auth/passkeys/abc",
      "/api/notes",
      "/api/auth/loginx",
    ])
      expect(isSessionless(path), path).toBe(false);
  });

  it("hands the challenge in a 401 to the caller, without a refresh", async () => {
    const seen: (string | null)[] = [];
    const client = api.extend({
      baseUrl: "http://anchor.test",
      fetch: (input) => {
        seen.push((input as Request).headers.get("Authorization"));
        return Promise.resolve(
          Response.json(
            {
              statusCode: 401,
              message: "Two-factor code required",
              twoFactorRequired: true,
              challenge: "abc",
            },
            { status: 401 },
          ),
        );
      },
    });
    vi.stubGlobal("fetch", vi.fn());
    const sessionEnded = vi.fn();
    vi.stubGlobal("window", { dispatchEvent: sessionEnded });

    const error = await errorOf(client.post("api/auth/login"));

    expect(errorBody(error)).toMatchObject({
      twoFactorRequired: true,
      challenge: "abc",
    });
    expect(seen).toEqual([null]);
    expect(fetch).not.toHaveBeenCalled();
    expect(sessionEnded).not.toHaveBeenCalled();
    expect(auth.clearAccessToken).not.toHaveBeenCalled();
  });

  it("hands the challenge in a 403 to the caller", async () => {
    const client = replyWith(
      403,
      JSON.stringify({
        twoFactorSetupRequired: true,
        challenge: "enroll",
        methods: { totp: true, passkey: false },
      }),
      "application/json",
    );

    const error = await errorOf(client.post("api/auth/login"));

    expect(errorBody(error)).toMatchObject({
      twoFactorSetupRequired: true,
      methods: { totp: true, passkey: false },
    });
  });
});

describe("errorBody", () => {
  it("is empty for anything but a JSON object from the server", async () => {
    expect(errorBody(new TypeError("Failed to fetch"))).toBeNull();
    const text = replyWith(502, "Bad Gateway", "text/plain");
    expect(errorBody(await errorOf(text.post("api/notes")))).toBeNull();
  });
});
