import { describe, expect, it } from "vitest";
import { newId } from "./id";

const UUID_V4 =
  /^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/;

describe("newId", () => {
  it("is a version 4 UUID", () => {
    expect(newId()).toMatch(UUID_V4);
  });

  it("builds one where randomUUID is missing, as on plain HTTP", () => {
    const randomUUID = crypto.randomUUID;
    Object.defineProperty(crypto, "randomUUID", {
      value: undefined,
      configurable: true,
    });
    try {
      expect(newId()).toMatch(UUID_V4);
    } finally {
      Object.defineProperty(crypto, "randomUUID", {
        value: randomUUID,
        configurable: true,
      });
    }
  });
});
