import { HTTPError } from "ky";
import { describe, expect, it } from "vitest";
import { englishT } from "@/i18n/translate";
import { serverSignInError, signInError } from "./sign-in-error";

const failed = (status: number, message = "", code?: string) => {
  const error = new HTTPError(
    new Response(null, { status }),
    new Request("http://localhost/api/auth/login", { method: "POST" }),
    {} as never,
  );
  if (message) error.message = message;
  error.data = { message, ...(code ? { code } : {}) };
  return error;
};

describe("signInError", () => {
  it("says nothing before a sign-in fails", () => {
    expect(signInError(englishT, null, "Pocket ID")).toBeNull();
  });

  it("names the provider for an account that has no password", () => {
    expect(
      signInError(
        englishT,
        failed(401, "This account uses OIDC authentication.", "OIDC_ACCOUNT"),
        "Pocket ID",
      ),
    ).toBe("This account signs in with Pocket ID. Use the button above.");
  });

  it("points to the provider when email sign-in is turned off", () => {
    expect(
      signInError(
        englishT,
        failed(
          403,
          "Email and password sign-in is turned off. Sign in with Pocket ID.",
          "PASSWORD_SIGN_IN_DISABLED",
        ),
        "Pocket ID",
      ),
    ).toBe("Sign in with Pocket ID instead.");
  });

  it("says “your provider” when the provider's name is unknown", () => {
    expect(
      signInError(
        englishT,
        failed(401, "This account uses OIDC authentication.", "OIDC_ACCOUNT"),
        undefined,
      ),
    ).toBe("This account signs in with your provider. Use the button above.");
  });

  it("keeps a wrong password apart from other refusals", () => {
    expect(
      signInError(
        englishT,
        failed(401, "Invalid credentials", "INVALID_CREDENTIALS"),
        "X",
      ),
    ).toBe("Incorrect email or password.");
    expect(
      signInError(
        englishT,
        failed(403, "Account pending approval", "ACCOUNT_PENDING"),
        "X",
      ),
    ).toBe("pending");
    expect(signInError(englishT, failed(429), "X")).toMatch(/^Too many tries/);
  });

  it("blames the server, not the connection, when the server fails", () => {
    expect(signInError(englishT, failed(500), "X")).toMatch(
      /^Something went wrong/,
    );
    expect(
      signInError(englishT, failed(400, "email must be an email"), "X"),
    ).toBe("Couldn’t sign in. Try again.");
  });

  it("blames the connection when nothing answers", () => {
    expect(
      signInError(englishT, new TypeError("Failed to fetch"), "X"),
    ).toMatch(/^Couldn’t reach the server/);
  });
});

describe("serverSignInError", () => {
  it("says a refused sign-in has expired, without naming the provider", () => {
    expect(serverSignInError(englishT, 400)).toBe(
      "That sign-in has expired. Try again, or sign in with your email.",
    );
  });

  it("doesn't offer email when only the provider signs in", () => {
    expect(serverSignInError(englishT, 400, true)).toBe(
      "That sign-in has expired. Try again.",
    );
  });

  it("tells a server failure and a lost connection apart", () => {
    expect(serverSignInError(englishT, 502)).toMatch(/^Something went wrong/);
    expect(serverSignInError(englishT, 0)).toMatch(
      /^Couldn’t reach the server/,
    );
  });
});
