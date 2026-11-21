import type english from "../messages/en.json";

export type Messages = {
  [Key in keyof typeof english as Key extends `@${string}`
    ? never
    : Key]: string;
};

export function withoutNotes(catalog: Record<string, unknown>): Messages {
  return Object.fromEntries(
    Object.entries(catalog).filter(
      ([key, value]) => !key.startsWith("@") && typeof value === "string",
    ),
  ) as Messages;
}
