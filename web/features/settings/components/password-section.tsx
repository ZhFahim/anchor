"use client";

import { useMutation } from "@tanstack/react-query";
import { HTTPError } from "ky";
import * as React from "react";
import { Button } from "@/components/ui/button";
import { Field, FormAlert } from "@/components/ui/field";
import { PasswordInput } from "@/components/ui/input";
import { toast } from "@/components/ui/toast";
import { changePassword } from "@/features/auth/api";
import { useOidcConfig } from "@/features/auth/hooks/use-oidc";
import { useAuthStore } from "@/features/auth/store";
import { Row, RowText, Section } from "./settings-blocks";

export function PasswordSection() {
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
      toast.success("Password changed");
    },
    onError: (e: Error) => {
      const status = e instanceof HTTPError ? e.response.status : 0;
      if (status === 403)
        setCurrentPasswordError("That isn’t your current password.");
      else if (status === 400 && /different/i.test(e.message))
        setNewPasswordError(
          "Use a password that’s different from your current one.",
        );
      else
        setFormError(
          status
            ? "Couldn’t change the password. Try again in a moment."
            : "Couldn’t reach the server. Check your connection and try again.",
        );
    },
  });

  const isProviderOnly =
    !!oidc.data?.enabled && !!oidc.data?.disableInternalAuth;
  if (user?.hasPassword === false || isProviderOnly) {
    const providerName = oidc.data?.providerName || "your sign-in provider";
    return (
      <Section id="password" title="Password">
        <Row>
          <RowText
            title={`Your password is managed by ${providerName}`}
            text={`Change it in ${providerName}.`}
          />
        </Row>
      </Section>
    );
  }

  return (
    <Section id="password" title="Password">
      <Row className="block">
        <form
          className="grid gap-3.5"
          onSubmit={(e) => {
            e.preventDefault();
            if (newPassword.length < 8)
              return setNewPasswordError("Use at least 8 characters.");
            setFormError(null);
            passwordChange.mutate({ currentPassword, newPassword });
          }}
        >
          <div className="grid grid-cols-2 items-start gap-3.5 max-md:grid-cols-1">
            <Field label="Current password" error={currentPasswordError}>
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
              label="New password"
              help="At least 8 characters."
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
              disabled={!currentPassword || newPassword.length < 8}
              busy={passwordChange.isPending && "Changing password…"}
            >
              Change password
            </Button>
          </div>
        </form>
      </Row>
    </Section>
  );
}
