let closing = false;
const tasks = new Set<() => void>();

if (typeof window !== "undefined") {
  window.addEventListener("pagehide", () => {
    closing = true;
    for (const task of tasks) task();
  });
  window.addEventListener("pageshow", () => {
    closing = false;
  });
}

export const isPageClosing = () => closing;

/** Browsers refuse a keepalive request whose body is over 64 KiB. */
export const fitsKeepalive = (body: unknown) =>
  !body ||
  (typeof body === "string" && new TextEncoder().encode(body).length < 64_000);

export function onPageClose(task: () => void) {
  tasks.add(task);
  return () => {
    tasks.delete(task);
  };
}
