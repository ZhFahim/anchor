import { HTTPError } from "ky";
import type { Translate } from "@/i18n/translate";
import { refusedFieldsOf } from "@/lib/api/error-code";

export const NAME_MAX_LENGTH = 100;

export const PASSWORD_MIN_LENGTH = 8;

export type AccountField = "name" | "email" | "password";

export function accountFieldHelp(t: Translate, field: AccountField): string {
  if (field === "name") return t("authNameTooLong", { count: NAME_MAX_LENGTH });
  if (field === "email") return t("authEnterValidEmail");
  return t("authPasswordTooShort", { count: PASSWORD_MIN_LENGTH });
}

export function refusedField(error: Error): AccountField | undefined {
  if (!(error instanceof HTTPError) || error.response.status !== 400) return;
  const refused = refusedFieldsOf(error);
  return (["name", "email", "password"] as const).find((field) =>
    refused.includes(field),
  );
}
