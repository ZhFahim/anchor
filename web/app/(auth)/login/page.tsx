"use client";

import { HTTPError } from "ky";
import { ArrowLeft, KeyRound, LoaderCircle } from "lucide-react";
import Link from "next/link";
import { useSearchParams } from "next/navigation";
import * as React from "react";
import { Button } from "@/components/ui/button";
import { Field } from "@/components/ui/field";
import { Input, PasswordInput } from "@/components/ui/input";
import {
  useLogin,
  useOidcCallback,
  useOidcConfig,
  useOidcLogin,
  useRegistrationMode,
} from "@/features/auth";
import {
  AuthHeading,
  AuthMessage,
  AuthStatusScreen,
  linkButtonClass,
  OrDivider,
  PendingApprovalScreen,
} from "@/features/auth/components/auth-parts";
import { getSafeRedirectUrl } from "@/features/auth/utils/redirect";
import {
  serverSignInError,
  signInError,
} from "@/features/auth/utils/sign-in-error";

export default function LoginPage() {
  const searchParams = useSearchParams();
  const login = useLogin();
  const oidc = useOidcConfig();
  const { initiate } = useOidcLogin();
  const oidcCallback = useOidcCallback();
  const registrationMode = useRegistrationMode();
  const [email, setEmail] = React.useState("");
  const [password, setPassword] = React.useState("");
  const passwordRef = React.useRef<HTMLInputElement>(null);

  const providerName = oidc.data?.providerName || "your provider";
  const providerNameAtStart =
    providerName[0].toUpperCase() + providerName.slice(1);
  const isProviderOnly =
    !!oidc.data?.enabled && !!oidc.data?.disableInternalAuth;
  const errorMessage = signInError(login.error, providerName);

  const signInWithProvider = () => {
    const returnTo = getSafeRedirectUrl(searchParams.get("returnTo") || "/");
    initiate(returnTo !== "/" ? returnTo : undefined);
  };

  if (oidcCallback.isProcessing)
    return (
      <p
        role="status"
        className="m-0 mt-3.5 flex items-center gap-2.5 text-lead text-muted-foreground [&_svg]:size-4.5"
      >
        <LoaderCircle aria-hidden className="animate-spin" />
        Signing you in…
      </p>
    );

  const { failure } = oidcCallback;
  const isPending =
    errorMessage === "pending" ||
    (failure?.by === "server" && /pending/i.test(failure.message));
  if (failure && !isPending)
    return (
      <AuthStatusScreen
        illustration="callback"
        title="Sign-in didn’t finish"
        text={
          failure.by === "provider"
            ? `${providerNameAtStart} sent you back without signing you in. ${isProviderOnly ? "Try again." : "Try again, or sign in with your email."}`
            : serverSignInError(failure.status, isProviderOnly)
        }
      >
        {failure.by === "provider" && (
          <p className="m-0 -mt-1.5 mb-1 text-muted-foreground text-small">
            {providerNameAtStart} said:{" "}
            <code className="rounded-[5px] bg-foreground/7 px-1.25 py-px font-mono text-foreground">
              {failure.message}
            </code>
          </p>
        )}
        <Button size="lg" className="w-full" onClick={signInWithProvider}>
          <KeyRound aria-hidden />
          Try again with {providerName}
        </Button>
        <Button
          size="lg"
          variant="quiet"
          className="w-full"
          onClick={oidcCallback.clearFailure}
        >
          <ArrowLeft aria-hidden />
          Back to sign in
        </Button>
      </AuthStatusScreen>
    );

  if (isPending)
    return (
      <PendingApprovalScreen
        onBack={() => {
          login.reset();
          oidcCallback.clearFailure();
        }}
      />
    );

  return (
    <>
      <AuthHeading title="Welcome back" sub="Sign in to continue to Anchor." />
      {oidc.data?.enabled && (
        <>
          <Button
            size="lg"
            variant="secondary"
            className="w-full"
            onClick={signInWithProvider}
          >
            <KeyRound aria-hidden />
            Continue with {providerName}
          </Button>
          {!isProviderOnly && <OrDivider />}
        </>
      )}
      {oidc.isError && (
        <AuthMessage
          action={
            <button
              type="button"
              className={`${linkButtonClass} self-center whitespace-nowrap`}
              onClick={() => oidc.refetch()}
            >
              Try again
            </button>
          }
        >
          Couldn’t load the sign-in options. You can still sign in with your
          email.
        </AuthMessage>
      )}
      {errorMessage && <AuthMessage>{errorMessage}</AuthMessage>}
      {!isProviderOnly && (
        <form
          className="grid gap-3.5"
          onSubmit={(e) => {
            e.preventDefault();
            if (login.isPending) return;
            login.mutate(
              { email: email.trim(), password },
              {
                onError: (error) => {
                  if (!(error instanceof HTTPError)) return;
                  if (error.response.status === 401) {
                    setPassword("");
                    passwordRef.current?.focus();
                  } else if (error.response.status === 403) void oidc.refetch();
                },
              },
            );
          }}
        >
          <Field label="Email">
            <Input
              type="email"
              autoComplete="email"
              value={email}
              required
              boxClassName="h-field-large"
              onChange={(e) => {
                setEmail(e.target.value);
                if (login.error) login.reset();
              }}
            />
          </Field>
          <Field label="Password">
            <PasswordInput
              ref={passwordRef}
              autoComplete="current-password"
              value={password}
              required
              boxClassName="h-field-large"
              onChange={(e) => {
                setPassword(e.target.value);
                if (login.error) login.reset();
              }}
            />
          </Field>
          <Button
            type="submit"
            size="lg"
            className="w-full"
            busy={login.isPending && "Signing in…"}
          >
            Sign in
          </Button>
        </form>
      )}
      {!isProviderOnly && registrationMode.data?.mode !== "disabled" && (
        <p className="m-0 text-center text-muted-foreground text-ui">
          New to Anchor?{" "}
          <Link href="/register" className={linkButtonClass}>
            Create an account
          </Link>
        </p>
      )}
    </>
  );
}
