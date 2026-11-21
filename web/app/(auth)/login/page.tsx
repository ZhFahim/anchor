"use client";

import { HTTPError } from "ky";
import { ArrowLeft, KeyRound, LoaderCircle } from "lucide-react";
import Link from "next/link";
import { useSearchParams } from "next/navigation";
import { useTranslations } from "next-intl";
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
  providerValues,
  serverSignInError,
  signInError,
} from "@/features/auth/utils/sign-in-error";

export default function LoginPage() {
  const t = useTranslations();
  const searchParams = useSearchParams();
  const login = useLogin();
  const oidc = useOidcConfig();
  const { initiate } = useOidcLogin();
  const oidcCallback = useOidcCallback();
  const registrationMode = useRegistrationMode();
  const [email, setEmail] = React.useState("");
  const [password, setPassword] = React.useState("");
  const passwordRef = React.useRef<HTMLInputElement>(null);

  const providerName = oidc.data?.providerName || undefined;
  const providerNameAtStart =
    providerName && providerName[0].toUpperCase() + providerName.slice(1);
  const isProviderOnly =
    !!oidc.data?.enabled && !!oidc.data?.disableInternalAuth;
  const errorMessage = signInError(t, login.error, providerName);

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
        {t("authSigningYouIn")}
      </p>
    );

  const { failure } = oidcCallback;
  const isPending =
    errorMessage === "pending" ||
    (failure?.by === "server" && failure.reason === "ACCOUNT_PENDING");
  if (failure && !isPending)
    return (
      <AuthStatusScreen
        illustration="callback"
        title={t("authCallbackFailedTitle")}
        text={
          failure.by === "provider"
            ? t(
                isProviderOnly
                  ? "authProviderSentBack"
                  : "authProviderSentBackOrEmail",
                providerValues(providerNameAtStart),
              )
            : serverSignInError(t, failure.status, isProviderOnly)
        }
      >
        {failure.by === "provider" && (
          <p className="m-0 -mt-1.5 mb-1 text-muted-foreground text-small">
            {t.rich("authProviderSaid", {
              ...providerValues(providerNameAtStart),
              message: failure.message,
              code: (chunks) => (
                <code className="rounded-[5px] bg-foreground/7 px-1.25 py-px font-mono text-foreground">
                  {chunks}
                </code>
              ),
            })}
          </p>
        )}
        <Button size="lg" className="w-full" onClick={signInWithProvider}>
          <KeyRound aria-hidden />
          {t("authTryAgainWith", providerValues(providerName))}
        </Button>
        <Button
          size="lg"
          variant="quiet"
          className="w-full"
          onClick={oidcCallback.clearFailure}
        >
          <ArrowLeft aria-hidden />
          {t("authBackToSignIn")}
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
      <AuthHeading
        title={t("authWelcomeBack")}
        sub={t("authSignInSubtitle", { app: t("appName") })}
      />
      {oidc.data?.enabled && (
        <>
          <Button
            size="lg"
            variant="secondary"
            className="w-full"
            onClick={signInWithProvider}
          >
            <KeyRound aria-hidden />
            {t("authContinueWith", { provider: oidc.data.providerName })}
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
              {t("commonRetry")}
            </button>
          }
        >
          {t("authOptionsLoadFailed")}
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
          <Field label={t("authEmailLabel")}>
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
          <Field label={t("authPasswordLabel")}>
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
            busy={login.isPending && t("authSigningIn")}
          >
            {t("authSignIn")}
          </Button>
        </form>
      )}
      {!isProviderOnly && registrationMode.data?.mode !== "disabled" && (
        <p className="m-0 text-center text-muted-foreground text-ui">
          {t.rich("authNewToAnchor", {
            app: t("appName"),
            link: (chunks) => (
              <Link href="/register" className={linkButtonClass}>
                {chunks}
              </Link>
            ),
          })}
        </p>
      )}
    </>
  );
}
