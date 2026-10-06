"use client";

import { HTTPError } from "ky";
import { ArrowLeft, KeyRound } from "lucide-react";
import Link from "next/link";
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
  ACCOUNT_FIELD_HELP,
  NAME_MAX_LENGTH,
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

type Errors = {
  name?: string;
  email?: string;
  password?: string;
  form?: string;
};

export default function RegisterPage() {
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
  const providerName = oidc.data?.providerName || "your provider";
  const isProviderOnly =
    !!oidc.data?.enabled && !!oidc.data?.disableInternalAuth;

  const showRegisterError = (error: Error) => {
    const message = error.message;
    if (
      error instanceof HTTPError &&
      (error.response.status === 409 || /exist/i.test(message))
    ) {
      setErrors({
        email: "An account with this email already exists. Sign in instead?",
      });
      refs.email.current?.focus();
    } else if (error instanceof HTTPError && error.response.status === 403) {
      void registrationMode.refetch();
      void oidc.refetch();
      if (/turned off/i.test(message))
        setErrors({ form: `Sign up with ${providerName} instead.` });
    } else if (!(error instanceof HTTPError))
      setErrors({
        form: "Couldn’t reach the server. Check your connection and try again.",
      });
    else {
      const { status } = error.response;
      const field = refusedField(error);
      if (field) {
        setErrors({ [field]: ACCOUNT_FIELD_HELP[field] });
        refs[field].current?.focus();
      } else
        setErrors({
          form:
            status >= 500
              ? "Something went wrong on the server. Try again in a moment."
              : status === 429
                ? "Too many tries. Wait a minute, then try again."
                : "Couldn’t create your account.",
        });
    }
  };

  if (registrationMode.data?.mode === "disabled")
    return (
      <AuthStatusScreen
        illustration="closed"
        title="Sign-ups are closed"
        text="Ask an admin to create an account for you."
      >
        <Button size="lg" variant="secondary" className="w-full" asChild>
          <Link href="/login">
            <ArrowLeft aria-hidden />
            Back to sign in
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
    if (!name.trim()) fieldErrors.name = "Enter your name.";
    if (!/.+@.+\..+/.test(email.trim()))
      fieldErrors.email = "Enter a valid email address.";
    if (password.length < 8)
      fieldErrors.password = "Use at least 8 characters.";
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
        title="Create your account"
        sub={
          registrationMode.data?.mode === "review"
            ? "An admin approves new accounts before you can sign in."
            : "Start capturing your thoughts."
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
            Continue with {providerName}
          </Button>
          {!isProviderOnly && <OrDivider />}
        </>
      )}
      {errors.form && <AuthMessage>{errors.form}</AuthMessage>}
      {!isProviderOnly && (
        <form className="grid gap-3.5" noValidate onSubmit={submit}>
          <Field label="Name" error={errors.name}>
            <Input
              ref={refs.name}
              autoComplete="name"
              placeholder="Your name"
              maxLength={NAME_MAX_LENGTH}
              value={name}
              boxClassName="h-field-large"
              onChange={(e) => {
                setName(e.target.value);
                clearError("name");
              }}
            />
          </Field>
          <Field label="Email" error={errors.email}>
            <Input
              ref={refs.email}
              type="email"
              autoComplete="email"
              placeholder="you@example.com"
              value={email}
              boxClassName="h-field-large"
              onChange={(e) => {
                setEmail(e.target.value);
                clearError("email");
              }}
            />
          </Field>
          <Field
            label="Password"
            help="At least 8 characters."
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
            busy={register.isPending && "Creating account…"}
          >
            Create account
          </Button>
        </form>
      )}
      <p className="m-0 text-center text-muted-foreground text-ui">
        Already have an account?{" "}
        <Link href="/login" className={linkButtonClass}>
          Sign in
        </Link>
      </p>
    </>
  );
}
