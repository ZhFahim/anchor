import { describe, expect, it } from "vitest";
import { localeFromHeader, localeOf, regionalTag } from "./locales";

describe("localeFromHeader", () => {
  it("takes the first language the app has", () => {
    expect(localeFromHeader("en-GB,en;q=0.9")).toBe("en");
    expect(localeFromHeader("xx,en;q=0.5")).toBe("en");
  });

  it("falls back to English", () => {
    expect(localeFromHeader(null)).toBe("en");
    expect(localeFromHeader("")).toBe("en");
    expect(localeFromHeader("*")).toBe("en");
  });
});

describe("regionalTag", () => {
  it("keeps the reader's region for dates", () => {
    expect(regionalTag("en", "en-GB,en;q=0.9")).toBe("en-GB");
    expect(regionalTag("en", "fr-FR,en-AU;q=0.8")).toBe("en-AU");
  });

  it("stays with the app's language when the browser has no region for it", () => {
    expect(regionalTag("en", "fr-FR")).toBe("en");
    expect(regionalTag("en", null)).toBe("en");
  });

  it("skips a tag that isn't valid", () => {
    expect(regionalTag("en", "en-US_POSIX,en-GB;q=0.9")).toBe("en-GB");
    expect(regionalTag("en", "en-")).toBe("en");
  });
});

describe("localeOf", () => {
  it("finds the app's language for a regional tag", () => {
    expect(localeOf("en-GB")).toBe("en");
    expect(localeOf("en")).toBe("en");
  });
});
