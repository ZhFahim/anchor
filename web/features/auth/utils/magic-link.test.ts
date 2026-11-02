import { describe, expect, it } from "vitest";
import { androidIntentUrl, appLinkUrl, magicLinkUrl } from "./magic-link";

describe("magic links", () => {
  it("points the shared link at this server's sign-in page", () => {
    expect(magicLinkUrl("a-b_c", "https://notes.example.com")).toBe(
      "https://notes.example.com/magic-login?code=a-b_c",
    );
  });

  it("hands the app the server and the code", () => {
    const link = new URL(appLinkUrl("abc", "https://notes.example.com:8443"));
    expect(link.protocol).toBe("anchorplus:");
    expect(link.host).toBe("magic-login");
    expect(link.searchParams.get("server")).toBe(
      "https://notes.example.com:8443",
    );
    expect(link.searchParams.get("code")).toBe("abc");
  });

  it("opens the app from Chrome on Android", () => {
    expect(androidIntentUrl("abc", "http://10.0.0.2:3000")).toBe(
      "intent://magic-login?server=http%3A%2F%2F10.0.0.2%3A3000&code=abc#Intent;scheme=anchorplus;end",
    );
  });
});
