"use client";

import { HTTPError } from "ky";
import { ArrowLeft, KeyRound } from "lucide-react";
import Link from "next/link";
import { useTranslations } from "next-intl";
import * as React from "react";
import { Button } from "@/components/ui/button";
import { Field } from "@/components/ui/field";
import { Input, PasswordInput } from "@/components/ui/input";
import {
  useOidcConfig,
  useOidcLogin,
  useRegister,
  useRegistrationMode,
} from "@/features/auth";
import {
  accountFieldHelp,
  NAME_MAX_LENGTH,
  PASSWORD_MIN_LENGTH,
  refusedField,
} from "@/features/auth/account-fields";
import {
  AuthHeading,
  AuthMessage,
  AuthStatusScreen,
  linkButtonClass,
  OrDivider,
  PendingApprovalScreen,
} from "@/features/auth/components/auth-parts";
import { providerValues } from "@/features/auth/utils/sign-in-error";
import { errorCodeOf } from "@/lib/api/error-code";

type Errors = {
  name?: string;
  email?: string;
  password?: string;
  form?: string;
};

export default function RegisterPage() {
  const t = useTranslations();
  const register = useRegister();
  const oidc = useOidcConfig();
  const { initiate } = useOidcLogin();
  const registrationMode = useRegistrationMode();
  const [name, setName] = React.useState("");
  const [email, setEmail] = React.useState("");
  const [password, setPassword] = React.useState("");
  const [errors, setErrors] = React.useState<Errors>({});
  const nameRef = React.useRef<HTMLInputElement>(null);
  const emailRef = React.useRef<HTMLInputElement>(null);
  const passwordRef = React.useRef<HTMLInputElement>(null);
  const refs = { name: nameRef, email: emailRef, password: passwordRef };
  const providerName = oidc.data?.providerName || undefined;
  const isProviderOnly =
    !!oidc.data?.enabled && !!oidc.data?.disableInternalAuth;

  const showRegisterError = (error: Error) => {
    const code = errorCodeOf(error);
    if (
      error instanceof HTTPError &&
      (error.response.status === 409 || code === "USER_EXISTS")
    ) {
      setErrors({ email: t("authEmailTakenSignIn") });
      refs.email.current?.focus();
    } else if (error instanceof HTTPError && error.response.status === 403) {
      void registrationMode.refetch();
      void oidc.refetch();
      if (code === "PASSWORD_SIGN_UP_DISABLED")
        setErrors({
          form: t(
            "authSignUpWithProviderInstead",
            providerValues(providerName),
          ),
        });
    } else if (!(error instanceof HTTPError))
      setErrors({ form: t("errorUnreachable") });
    else {
      const { status } = error.response;
      const field = refusedField(error);
      if (field) {
        setErrors({ [field]: accountFieldHelp(t, field) });
        refs[field].current?.focus();
      } else
        setErrors({
          form:
            status >= 500
              ? t("errorServer")
              : status === 429
                ? t("authTooManyTries")
                : t("authCreateFailed"),
        });
    }
  };

  if (registrationMode.data?.mode === "disabled")
    return (
      <AuthStatusScreen
        illustration="closed"
        title={t("authSignUpsClosedTitle")}
        text={t("authSignUpsClosedText")}
      >
        <Button size="lg" variant="secondary" className="w-full" asChild>
          <Link href="/login">
            <ArrowLeft aria-hidden />
            {t("authBackToSignIn")}
          </Link>
        </Button>
      </AuthStatusScreen>
    );

  if (register.isSuccess && !register.data?.access_token)
    return <PendingApprovalScreen />;

  const submit = (e: React.FormEvent) => {
    e.preventDefault();
    if (register.isPending) return;
    const fieldErrors: Errors = {};
    if (!name.trim()) fieldErrors.name = t("authEnterName");
    if (!/.+@.+\..+/.test(email.trim()))
      fieldErrors.email = t("authEnterValidEmail");
    if (password.length < PASSWORD_MIN_LENGTH)
      fieldErrors.password = t("authPasswordTooShort", {
        count: PASSWORD_MIN_LENGTH,
      });
    setErrors(fieldErrors);
    const firstInvalid = (["name", "email", "password"] as const).find(
      (field) => fieldErrors[field],
    );
    if (firstInvalid) return refs[firstInvalid].current?.focus();
    register.reset();
    register.mutate(
      { name: name.trim(), email: email.trim(), password },
      { onError: showRegisterError },
    );
  };

  const clearError = (field: keyof Errors) =>
    setErrors((prev) => ({ ...prev, [field]: undefined, form: undefined }));

  return (
    <>
      <AuthHeading
        title={t("authCreateYourAccount")}
        sub={
          registrationMode.data?.mode === "review"
            ? t("authApprovalNeeded")
            : t("authRegisterSubtitle")
        }
      />
      {oidc.data?.enabled && (
        <>
          <Button
            size="lg"
            variant="secondary"
            className="w-full"
            onClick={() => initiate()}
          >
            <KeyRound aria-hidden />
            {t("authContinueWith", { provider: oidc.data.providerName })}
          </Button>
          {!isProviderOnly && <OrDivider />}
        </>
      )}
      {errors.form && <AuthMessage>{errors.form}</AuthMessage>}
      {!isProviderOnly && (
        <form className="grid gap-3.5" noValidate onSubmit={submit}>
          <Field label={t("authNameLabel")} error={errors.name}>
            <Input
              ref={refs.name}
              autoComplete="name"
              placeholder={t("authNamePlaceholder")}
              maxLength={NAME_MAX_LENGTH}
              value={name}
              boxClassName="h-field-large"
              onChange={(e) => {
                setName(e.target.value);
                clearError("name");
              }}
            />
          </Field>
          <Field label={t("authEmailLabel")} error={errors.email}>
            <Input
              ref={refs.email}
              type="email"
              autoComplete="email"
              placeholder={t("authEmailPlaceholder")}
              value={email}
              boxClassName="h-field-large"
              onChange={(e) => {
                setEmail(e.target.value);
                clearError("email");
              }}
            />
          </Field>
          <Field
            label={t("authPasswordLabel")}
            help={t("authPasswordHelp", { count: PASSWORD_MIN_LENGTH })}
            error={errors.password}
          >
            <PasswordInput
              ref={refs.password}
              autoComplete="new-password"
              value={password}
              boxClassName="h-field-large"
              onChange={(e) => {
                setPassword(e.target.value);
                clearError("password");
              }}
            />
          </Field>
          <Button
            type="submit"
            size="lg"
            className="w-full"
            busy={register.isPending && t("authCreatingAccount")}
          >
            {t("authCreateAccount")}
          </Button>
        </form>
      )}
      <p className="m-0 text-center text-muted-foreground text-ui">
        {t.rich("authHaveAccount", {
          link: (chunks) => (
            <Link href="/login" className={linkButtonClass}>
              {chunks}
            </Link>
          ),
        })}
      </p>
    </>
  );
}
