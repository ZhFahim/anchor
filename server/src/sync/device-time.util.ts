// Capped at now; now when missing or unreadable.
export const deviceTime = (
  reported: string | undefined,
  now: number = Date.now(),
): Date => {
  const time = reported === undefined ? NaN : Date.parse(reported);
  return new Date(Number.isNaN(time) ? now : Math.min(time, now));
};
