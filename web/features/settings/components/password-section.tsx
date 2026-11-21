"use client";

import { useMutation } from "@tanstack/react-query";
import { HTTPError } from "ky";
import { useTranslations } from "next-intl";
import * as React from "react";
import { Button } from "@/components/ui/button";
import { Field, FormAlert } from "@/components/ui/field";
import { PasswordInput } from "@/components/ui/input";
import { toast } from "@/components/ui/toast";
import { PASSWORD_MIN_LENGTH } from "@/features/auth/account-fields";
import { changePassword } from "@/features/auth/api";
import { useOidcConfig } from "@/features/auth/hooks/use-oidc";
import { useAuthStore } from "@/features/auth/store";
import { errorCodeOf } from "@/lib/api/error-code";
import { Row, RowText, Section } from "./settings-blocks";

export function PasswordSection() {
  const t = useTranslations();
  const user = useAuthStore((s) => s.user);
  const oidc = useOidcConfig();
  const [currentPassword, setCurrentPassword] = React.useState("");
  const [newPassword, setNewPassword] = React.useState("");
  const [currentPasswordError, setCurrentPasswordError] = React.useState<
    string | null
  >(null);
  const [newPasswordError, setNewPasswordError] = React.useState<string | null>(
    null,
  );
  const [formError, setFormError] = React.useState<string | null>(null);

  const passwordChange = useMutation({
    mutationFn: changePassword,
    onSuccess: () => {
      setCurrentPassword("");
      setNewPassword("");
      toast.success(t("settingsPasswordChanged"));
    },
    onError: (e: Error) => {
      const status = e instanceof HTTPError ? e.response.status : 0;
      if (status === 403)
        setCurrentPasswordError(t("settingsPasswordWrongCurrent"));
      else if (errorCodeOf(e) === "PASSWORD_UNCHANGED")
        setNewPasswordError(t("settingsPasswordUnchanged"));
      else
        setFormError(
          status ? t("settingsPasswordChangeFailed") : t("errorUnreachable"),
        );
    },
  });

  const isProviderOnly =
    !!oidc.data?.enabled && !!oidc.data?.disableInternalAuth;
  if (user?.hasPassword === false || isProviderOnly) {
    const provider = oidc.data?.providerName;
    return (
      <Section id="password" title={t("settingsPassword")}>
        <Row>
          <RowText
            title={
              provider
                ? t("settingsPasswordManagedBy", { provider })
                : t("settingsPasswordManagedElsewhere")
            }
            text={
              provider
                ? t("settingsPasswordChangeAt", { provider })
                : t("settingsPasswordChangeAtProvider")
            }
          />
        </Row>
      </Section>
    );
  }

  return (
    <Section id="password" title={t("settingsPassword")}>
      <Row className="block">
        <form
          className="grid gap-3.5"
          onSubmit={(e) => {
            e.preventDefault();
            if (newPassword.length < PASSWORD_MIN_LENGTH)
              return setNewPasswordError(
                t("settingsPasswordTooShort", { count: PASSWORD_MIN_LENGTH }),
              );
            setFormError(null);
            passwordChange.mutate({ currentPassword, newPassword });
          }}
        >
          <div className="grid grid-cols-2 items-start gap-3.5 max-md:grid-cols-1">
            <Field
              label={t("settingsCurrentPassword")}
              error={currentPasswordError}
            >
              <PasswordInput
                value={currentPassword}
                autoComplete="current-password"
                onChange={(e) => {
                  setCurrentPassword(e.target.value);
                  setCurrentPasswordError(null);
                }}
              />
            </Field>
            <Field
              label={t("settingsNewPassword")}
              help={t("settingsPasswordHelp", { count: PASSWORD_MIN_LENGTH })}
              error={newPasswordError}
            >
              <PasswordInput
                value={newPassword}
                autoComplete="new-password"
                onChange={(e) => {
                  setNewPassword(e.target.value);
                  setNewPasswordError(null);
                }}
              />
            </Field>
          </div>
          {formError && <FormAlert>{formError}</FormAlert>}
          <div>
            <Button
              type="submit"
              disabled={
                !currentPassword || newPassword.length < PASSWORD_MIN_LENGTH
              }
              busy={passwordChange.isPending && t("settingsChangingPassword")}
            >
              {t("settingsChangePassword")}
            </Button>
          </div>
        </form>
      </Row>
    </Section>
  );
}
