import { afterEach, describe, expect, it, vi } from "vitest";

vi.mock("@/features/auth/store", () => ({ getAccessToken: () => null }));
vi.mock("./client", () => ({ refreshAccessToken: vi.fn() }));

const { uploadWithProgress } = await import("./upload");

afterEach(() => {
  vi.unstubAllGlobals();
});

describe("uploadWithProgress", () => {
  it("sends nothing when canceled before it starts", async () => {
    const open = vi.fn();
    vi.stubGlobal(
      "XMLHttpRequest",
      class {
        upload = {};
        open = open;
        send = vi.fn();
        setRequestHeader = vi.fn();
      },
    );
    const controller = new AbortController();
    controller.abort();

    await expect(
      uploadWithProgress("api/x", new FormData(), {
        signal: controller.signal,
      }),
    ).rejects.toMatchObject({ name: "AbortError" });
    expect(open).not.toHaveBeenCalled();
  });
});
