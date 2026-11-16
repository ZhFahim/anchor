"use client";

import { useMutation } from "@tanstack/react-query";
import { HTTPError } from "ky";
import {
  ChevronRight,
  Fingerprint,
  LoaderCircle,
  Smartphone,
} from "lucide-react";
import * as React from "react";
import { toast } from "@/components/ui/toast";
import { firstName } from "@/lib/utils";
import { enrollTotpEnable, enrollTotpSetup } from "../api";
import { canUsePasskeys, enrollPasskey } from "../passkey";
import { useAuthStore } from "../store";
import type { EnrollMethods, Session, TotpSetup } from "../types";
import {
  passkeyCeremonyFailure,
  suggestPasskeyName,
  twoFactorFailure,
} from "../utils/two-factor";
import { AuthHeading, AuthMessage, linkButtonClass } from "./auth-parts";
import { RecoveryCodesDialog } from "./recovery-codes-dialog";
import { TotpSetupDialog } from "./totp-setup-dialog";

function MethodCard({
  icon,
  title,
  text,
  busy,
  disabled,
  onClick,
}: {
  icon: React.ReactNode;
  title: string;
  text: string;
  busy?: boolean;
  disabled?: boolean;
  onClick: () => void;
}) {
  return (
    <button
      type="button"
      disabled={disabled}
      onClick={onClick}
      className="flex w-full cursor-pointer items-center gap-3.5 rounded-xl border-0 bg-card p-3.5 text-left text-foreground shadow-[inset_0_0_0_1px_var(--border)] transition-shadow duration-(--duration-hover) hover:shadow-[inset_0_0_0_1px_color-mix(in_srgb,var(--muted-foreground)_55%,var(--border))] focus-visible:shadow-[inset_0_0_0_2px_var(--ring)] disabled:cursor-default disabled:opacity-55"
    >
      <span className="grid size-10 flex-none place-items-center rounded-lg bg-muted text-muted-foreground [&_svg]:size-5">
        {icon}
      </span>
      <span className="grid min-w-0 flex-1 gap-0.5">
        <b className="font-semibold text-ui">{title}</b>
        <span className="text-meta text-muted-foreground">{text}</span>
      </span>
      {busy ? (
        <LoaderCircle
          aria-hidden
          className="size-4 flex-none animate-spin text-muted-foreground"
        />
      ) : (
        <ChevronRight
          aria-hidden
          className="size-4 flex-none text-muted-foreground"
        />
      )}
    </button>
  );
}

/**
 * Shown when the admin requires a second step and the person has none: they
 * set one up with the challenge from sign-in, and only then get a session.
 */
export function EnrollmentGate({
  challenge,
  methods,
  onLeave,
  onExpired,
}: {
  challenge: string;
  methods: EnrollMethods;
  /** “Not you? Sign out”: drop the challenge and go back. */
  onLeave: () => void;
  onExpired: () => void;
}) {
  const setAuth = useAuthStore((state) => state.setAuth);
  const [setup, setSetup] = React.useState<TotpSetup | null>(null);
  // Held back until the codes are saved: a session ends this screen.
  const [saving, setSaving] = React.useState<{
    codes: string[];
    session: Session;
  } | null>(null);
  const [notice, setNotice] = React.useState<string | null>(null);

  const startSession = (session: Session) => {
    setAuth(session.user, session.access_token, session.refresh_token);
    toast.success(`Welcome, ${firstName(session.user.name)}`);
  };

  const startTotp = useMutation({
    mutationFn: () => enrollTotpSetup(challenge),
    onSuccess: setSetup,
    onError: (error) => {
      const failure = twoFactorFailure(error);
      if (failure.kind === "expired") return onExpired();
      setNotice(
        failure.kind === "network"
          ? "Couldn’t reach the server. Check your connection and try again."
          : "Couldn’t start the setup. Try again.",
      );
    },
  });
  const passkey = useMutation({
    mutationFn: () =>
      enrollPasskey(challenge, suggestPasskeyName(navigator.userAgent)),
    onSuccess: startSession,
    onError: (error) => {
      if (error instanceof HTTPError) {
        if (twoFactorFailure(error).kind === "expired") return onExpired();
        return setNotice("Couldn’t add the passkey. Try again.");
      }
      const failure = passkeyCeremonyFailure(error);
      if (failure === "cancelled") return setNotice(null);
      setNotice(
        failure === "unsupported"
          ? "This device can’t make that kind of passkey. Try the authenticator app."
          : failure === "already-registered"
            ? "This device already has a passkey for Anchor."
            : "Couldn’t add the passkey. Try again.",
      );
    },
  });

  const canPasskey = methods.passkey && canUsePasskeys();
  const canTotp = methods.totp;

  return (
    <>
      <AuthHeading
        title="Your admin requires two‑factor"
        sub="Add a second step to keep using Anchor. It takes about a minute."
      />
      {notice && <AuthMessage>{notice}</AuthMessage>}
      {!canTotp && !canPasskey && (
        <AuthMessage>
          Two-factor can’t be set up from this device. Try another browser, or
          ask an admin for help.
        </AuthMessage>
      )}
      <div className="grid gap-2.5">
        {canTotp && (
          <MethodCard
            icon={<Smartphone aria-hidden />}
            title="Authenticator app"
            text="1Password, Aegis, Google Authenticator"
            busy={startTotp.isPending}
            disabled={passkey.isPending}
            onClick={() => {
              setNotice(null);
              if (!startTotp.isPending) startTotp.mutate();
            }}
          />
        )}
        {canPasskey && (
          <MethodCard
            icon={<Fingerprint aria-hidden />}
            title="Passkey"
            text="Touch ID, Windows Hello or your phone"
            busy={passkey.isPending}
            disabled={startTotp.isPending}
            onClick={() => {
              setNotice(null);
              if (!passkey.isPending) passkey.mutate();
            }}
          />
        )}
      </div>
      <p className="m-0 text-center text-muted-foreground text-ui">
        Not you?{" "}
        <button type="button" className={linkButtonClass} onClick={onLeave}>
          Sign out
        </button>
      </p>
      <TotpSetupDialog
        setup={setup}
        onCancel={() => setSetup(null)}
        onExpired={onExpired}
        onConfirm={async (code) => {
          const result = await enrollTotpEnable({ challenge, code });
          setSetup(null);
          setSaving({
            codes: result.recoveryCodes,
            session: {
              user: result.user,
              access_token: result.access_token,
              refresh_token: result.refresh_token,
            },
          });
        }}
      />
      <RecoveryCodesDialog
        codes={saving?.codes ?? null}
        step="Step 2 of 2"
        intro="Two-factor is on. If you lose your phone, each of these codes lets you in once."
        onDone={() => saving && startSession(saving.session)}
      />
    </>
  );
}
