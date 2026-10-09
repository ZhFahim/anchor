export const adminKeys = {
  stats: ["admin", "stats"] as const,
  users: ["admin", "users"] as const,
  pendingUsers: ["admin", "users", "pending"] as const,
  activeUsers: (search: string, limit: number) =>
    ["admin", "users", "active", search, limit] as const,
  registration: ["admin", "settings", "registration"] as const,
  oidc: ["admin", "settings", "oidc"] as const,
};
