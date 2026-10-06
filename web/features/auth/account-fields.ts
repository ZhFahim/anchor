import { HTTPError } from "ky";

export const NAME_MAX_LENGTH = 100;

export type AccountField = "name" | "email" | "password";

export const ACCOUNT_FIELD_HELP: Record<AccountField, string> = {
  name: `Enter a name of up to ${NAME_MAX_LENGTH} characters.`,
  email: "Enter a valid email address.",
  password: "Use at least 8 characters.",
};

export function refusedField(error: Error): AccountField | undefined {
  if (!(error instanceof HTTPError) || error.response.status !== 400) return;
  return (["name", "email", "password"] as const).find((field) =>
    new RegExp(`\\b${field}\\b`, "i").test(error.message),
  );
}
