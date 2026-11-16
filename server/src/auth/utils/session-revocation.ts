/**
 * Access tokens carry `iat` in whole seconds, so a token counts as issued
 * before the revocation when its second is earlier than the revocation's.
 */
export function isSessionRevoked(
  issuedAt: number | undefined,
  revokedAt: Date | null,
): boolean {
  if (!revokedAt) return false;
  if (typeof issuedAt !== 'number') return true;
  return issuedAt < Math.floor(revokedAt.getTime() / 1000);
}
