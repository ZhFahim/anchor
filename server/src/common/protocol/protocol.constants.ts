// The API contract this build speaks.
export const ANCHOR_PROTOCOL = 4;

// The oldest contract this build still serves.
export const MIN_ANCHOR_PROTOCOL = 3;

export const SUPPORTED_PROTOCOLS = Array.from(
  { length: ANCHOR_PROTOCOL - MIN_ANCHOR_PROTOCOL + 1 },
  (_, offset) => MIN_ANCHOR_PROTOCOL + offset,
);
