import { describe, expect, it, vi } from "vitest";

vi.mock("@/features/auth/store", () => ({
  getAccessToken: vi.fn(() => null),
  getRefreshToken: vi.fn(() => null),
  setAccessToken: vi.fn(),
  setRefreshToken: vi.fn(),
  clearAccessToken: vi.fn(),
  clearRefreshToken: vi.fn(),
}));

import { api } from "@/lib/api/client";
import { errorBody } from "@/lib/api/error-body";
import {
  describeFailure,
  formatRecoveryCode,
  formatRetryAfter,
  groupSecret,
  isRecoveryCode,
  lastUsedLabel,
  normalizeRecoveryCode,
  passkeyCeremonyFailure,
  passkeySignInError,
  recoveryCodesFile,
  registerOutcome,
  signInChallenge,
  signInChallengeOf,
  suggestPasskeyName,
  twoFactorFailure,
} from "./two-factor";

/** The error a call to the server fails with. */
async function failed(status: number, body: object): Promise<Error> {
  const client = api.extend({
    baseUrl: "http://anchor.test",
    fetch: () => Promise.resolve(Response.json(body, { status })),
  });
  try {
    await client.post("api/auth/login");
  } catch (error) {
    return error as Error;
  }
  throw new Error("expected the call to fail");
}

const user = { id: "u1", email: "ada@example.com", name: "Ada" };

describe("signInChallenge", () => {
  it("asks for a code when the server says two-factor is required", () => {
    expect(
      signInChallenge(401, { twoFactorRequired: true, challenge: "abc" }),
    ).toEqual({ kind: "codeRequired", challenge: "abc" });
  });

  it("sends a person who has to set up a second step to the setup", () => {
    expect(
      signInChallenge(403, {
        twoFactorSetupRequired: true,
        challenge: "enroll",
        methods: { totp: true, passkey: false },
      }),
    ).toEqual({
      kind: "setupRequired",
      challenge: "enroll",
      methods: { totp: true, passkey: false },
    });
  });

  it("offers the app when the methods are missing from the answer", () => {
    expect(
      signInChallenge(403, { twoFactorSetupRequired: true, challenge: "e" }),
    ).toMatchObject({ methods: { totp: true, passkey: false } });
  });

  it("sends someone with only passkeys to their passkey, without a challenge", () => {
    expect(
      signInChallenge(403, {
        message: "Sign in with your passkey",
        passkeyRequired: true,
      }),
    ).toEqual({
      kind: "passkeyRequired",
      message: "Sign in with your passkey",
    });
    expect(signInChallenge(403, { passkeyRequired: true })).toMatchObject({
      kind: "passkeyRequired",
      message: "Sign in with your passkey",
    });
    // Only a 403 says so.
    expect(signInChallenge(401, { passkeyRequired: true })).toBeNull();
  });

  it("treats a wrong password and a pending account as plain refusals", () => {
    expect(signInChallenge(401, { message: "Invalid credentials" })).toBeNull();
    expect(
      signInChallenge(403, { message: "Account pending approval" }),
    ).toBeNull();
    expect(signInChallenge(401, null)).toBeNull();
  });

  it("needs the challenge, and the status to agree with the flag", () => {
    expect(signInChallenge(401, { twoFactorRequired: true })).toBeNull();
    expect(
      signInChallenge(403, { twoFactorRequired: true, challenge: "x" }),
    ).toBeNull();
  });

  it("reads the challenge from a failed call", async () => {
    const error = await failed(401, {
      statusCode: 401,
      message: "Two-factor code required",
      twoFactorRequired: true,
      challenge: "from-the-wire",
    });
    expect(signInChallengeOf(error)).toEqual({
      kind: "codeRequired",
      challenge: "from-the-wire",
    });
    expect(signInChallengeOf(new TypeError("Failed to fetch"))).toBeNull();
  });
});

describe("registerOutcome", () => {
  it("signs in when the server sends tokens", () => {
    expect(
      registerOutcome({ user, access_token: "a", refresh_token: "r" }),
    ).toEqual({
      kind: "signedIn",
      session: { user, access_token: "a", refresh_token: "r" },
    });
  });

  it("keeps a pending account apart from one that has to set up two-factor", () => {
    expect(registerOutcome({ user, message: "Wait for approval" })).toEqual({
      kind: "pending",
      message: "Wait for approval",
    });
    expect(
      registerOutcome({
        user,
        twoFactorSetupRequired: true,
        challenge: "enroll",
        methods: { totp: false, passkey: true },
      }),
    ).toEqual({
      kind: "setupRequired",
      challenge: "enroll",
      methods: { totp: false, passkey: true },
      user,
    });
  });
});

describe("twoFactorFailure", () => {
  it("tells a wrong code from an expired sign-in", async () => {
    expect(
      twoFactorFailure(await failed(401, { message: "Invalid code" })),
    ).toEqual({ kind: "wrong-code" });
    // The enrolment calls answer a wrong code with a 400.
    expect(
      twoFactorFailure(await failed(400, { message: "Invalid code" })),
    ).toEqual({ kind: "wrong-code" });
    expect(
      twoFactorFailure(await failed(401, { message: "Challenge expired" })),
    ).toEqual({ kind: "expired" });
  });

  it("tells the lockout from the ordinary rate limit", async () => {
    expect(
      twoFactorFailure(
        await failed(429, {
          message: "Too many attempts. Try again later.",
          retryAfterSeconds: 600,
        }),
      ),
    ).toEqual({ kind: "locked", retryAfterSeconds: 600 });
    expect(
      twoFactorFailure(
        await failed(429, { message: "ThrottlerException: Too Many Requests" }),
      ),
    ).toEqual({ kind: "throttled" });
  });

  it("recognises the refusals of the settings calls", async () => {
    expect(
      twoFactorFailure(
        await failed(403, { message: "Current password is incorrect" }),
      ),
    ).toEqual({ kind: "wrong-password" });
    expect(
      twoFactorFailure(
        await failed(403, { message: "Two-factor is required by your admin" }),
      ),
    ).toEqual({ kind: "required-by-admin" });
    expect(
      twoFactorFailure(await failed(403, { message: "Current code required" })),
    ).toEqual({ kind: "current-code-required" });
  });

  it("blames the connection or the server, not the person", async () => {
    expect(twoFactorFailure(new TypeError("Failed to fetch"))).toEqual({
      kind: "network",
    });
    expect(twoFactorFailure(await failed(502, {}))).toEqual({ kind: "server" });
  });

  it("keeps the body of the lockout reachable", async () => {
    const error = await failed(429, { retryAfterSeconds: 42 });
    expect(errorBody(error)?.retryAfterSeconds).toBe(42);
  });
});

describe("describeFailure", () => {
  it("says how long a lockout lasts", () => {
    expect(describeFailure({ kind: "locked", retryAfterSeconds: 600 })).toBe(
      "Too many wrong codes. Try again in 10 minutes.",
    );
  });

  it("names a recovery code when that is what was entered", () => {
    expect(describeFailure({ kind: "wrong-code" }, { recovery: true })).toMatch(
      /^That recovery code/,
    );
    expect(describeFailure({ kind: "wrong-code" })).toMatch(/Check your app/);
  });
});

describe("formatRetryAfter", () => {
  it("rounds up so it is never too soon", () => {
    expect(formatRetryAfter(600)).toBe("10 minutes");
    expect(formatRetryAfter(601)).toBe("11 minutes");
    expect(formatRetryAfter(61)).toBe("2 minutes");
    expect(formatRetryAfter(60)).toBe("1 minute");
    expect(formatRetryAfter(5)).toBe("1 minute");
    expect(formatRetryAfter(0)).toBe("1 minute");
  });
});

describe("recovery codes", () => {
  it("normalises like the server: trimmed, lower case, dash optional", () => {
    expect(normalizeRecoveryCode("  K7M2-9XQPA3 ")).toBe("k7m29xqpa3");
    expect(normalizeRecoveryCode("k7m2 9xqpa3")).toBe("k7m29xqpa3");
    expect(normalizeRecoveryCode("k7m2–9xqpa3")).toBe("k7m29xqpa3");
  });

  it("accepts ten characters from the code alphabet only", () => {
    expect(isRecoveryCode("k7m29-xqpa3")).toBe(true);
    expect(isRecoveryCode("K7M29XQPA3")).toBe(true);
    expect(isRecoveryCode("k7m29-xqpa")).toBe(false);
    // 0, 1, i, l and o never appear in a code.
    expect(isRecoveryCode("k7m29-xqpa0")).toBe(false);
    expect(isRecoveryCode("k7m29-xqpal")).toBe(false);
    expect(isRecoveryCode("123456")).toBe(false);
  });

  it("puts the dash back while typing", () => {
    expect(formatRecoveryCode("k7m2")).toBe("k7m2");
    expect(formatRecoveryCode("K7M29X")).toBe("k7m29-x");
    expect(formatRecoveryCode("k7m29xqpa3zz")).toBe("k7m29-xqpa3");
  });

  it("writes the codes to a file one per line", () => {
    const text = recoveryCodesFile(["k7m29-xqpa3", "h3vd4-8nepq"]);
    expect(text).toContain("k7m29-xqpa3\nh3vd4-8nepq\n");
    expect(text.startsWith("Anchor recovery codes")).toBe(true);
  });
});

describe("groupSecret", () => {
  it("groups the key in fours for reading aloud", () => {
    expect(groupSecret("JBSWY3DPEHPK3PXP")).toBe("JBSW Y3DP EHPK 3PXP");
    expect(groupSecret("JBSWY3DPEH")).toBe("JBSW Y3DP EH");
    expect(groupSecret("JBSW Y3DP")).toBe("JBSW Y3DP");
  });
});

describe("suggestPasskeyName", () => {
  it("names the device and the browser", () => {
    expect(
      suggestPasskeyName(
        "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Safari/605.1.15",
      ),
    ).toBe("Mac · Safari");
    expect(
      suggestPasskeyName(
        "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0 Safari/537.36 Edg/120.0",
      ),
    ).toBe("Windows · Edge");
  });

  it("falls back to a plain name", () => {
    expect(suggestPasskeyName("")).toBe("My passkey");
  });
});

describe("passkeyCeremonyFailure", () => {
  const named = (name: string, code?: string) =>
    Object.assign(new Error("x"), { name, code });

  it("treats a dismissed prompt as a choice, not a failure", () => {
    expect(passkeyCeremonyFailure(named("NotAllowedError"))).toBe("cancelled");
    expect(passkeyCeremonyFailure(named("AbortError"))).toBe("cancelled");
  });

  it("notices a device that already has the passkey", () => {
    expect(passkeyCeremonyFailure(named("InvalidStateError"))).toBe(
      "already-registered",
    );
    expect(
      passkeyCeremonyFailure(
        named("Error", "ERROR_AUTHENTICATOR_PREVIOUSLY_REGISTERED"),
      ),
    ).toBe("already-registered");
  });

  it("notices a device that can’t do it", () => {
    expect(passkeyCeremonyFailure(named("NotSupportedError"))).toBe(
      "unsupported",
    );
    expect(passkeyCeremonyFailure("nope")).toBe("other");
  });
});

describe("lastUsedLabel", () => {
  const now = new Date(2026, 10, 16, 15, 0);

  it("says never for a passkey that was not used", () => {
    expect(lastUsedLabel(null, now)).toBe("Never used");
  });

  it("counts calendar days, not 24-hour spans", () => {
    expect(lastUsedLabel(new Date(2026, 10, 16, 1, 0).toISOString(), now)).toBe(
      "Last used today",
    );
    expect(
      lastUsedLabel(new Date(2026, 10, 15, 23, 0).toISOString(), now),
    ).toBe("Last used yesterday");
    expect(lastUsedLabel(new Date(2026, 10, 13, 9, 0).toISOString(), now)).toBe(
      "Last used 3 days ago",
    );
  });

  it("gives a date once it is a month back", () => {
    expect(lastUsedLabel(new Date(2026, 8, 2, 9, 0).toISOString(), now)).toBe(
      "Last used Sep 2, 2026",
    );
  });
});

describe("passkeySignInError", () => {
  it("says nothing when the person closed the prompt", () => {
    expect(
      passkeySignInError(
        Object.assign(new Error("x"), { name: "NotAllowedError" }),
      ),
    ).toBeNull();
  });

  it("tells a refused passkey from a server that is down", async () => {
    expect(
      passkeySignInError(
        await failed(401, { message: "Passkey sign-in failed" }),
      ),
    ).toMatch(/^That passkey didn’t work/);
    expect(passkeySignInError(await failed(503, {}))).toMatch(
      /^Something went wrong/,
    );
    expect(passkeySignInError(await failed(429, {}))).toMatch(
      /^Too many tries/,
    );
  });
});
