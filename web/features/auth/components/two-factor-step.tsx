"use client";

import { ArrowLeft } from "lucide-react";
import * as React from "react";
import { Button } from "@/components/ui/button";
import { Field } from "@/components/ui/field";
import { Input } from "@/components/ui/input";
import { OtpInput, type OtpInputHandle } from "@/components/ui/otp-input";
import { useTwoFactorLogin } from "../hooks/use-auth";
import { isOtpComplete } from "../utils/otp";
import {
  describeFailure,
  formatRecoveryCode,
  isRecoveryCode,
  type TwoFactorFailure,
  twoFactorFailure,
} from "../utils/two-factor";
import { AuthHeading, AuthMessage, linkButtonClass } from "./auth-parts";

/** The second step of a sign-in: a code from the app, or one recovery code. */
export function TwoFactorStep({
  email,
  challenge,
  onBack,
  onExpired,
}: {
  email: string;
  challenge: string;
  onBack: () => void;
  /** The challenge ran out: start the sign-in again. */
  onExpired: () => void;
}) {
  const verify = useTwoFactorLogin();
  const [mode, setMode] = React.useState<"code" | "recovery">("code");
  const [code, setCode] = React.useState("");
  const [recoveryCode, setRecoveryCode] = React.useState("");
  const [failure, setFailure] = React.useState<TwoFactorFailure | null>(null);
  const otp = React.useRef<OtpInputHandle>(null);
  const recoveryField = React.useRef<HTMLInputElement>(null);
  const isRecovery = mode === "recovery";
  const locked = failure?.kind === "locked";
  const lockedFor = locked ? failure.retryAfterSeconds : 0;

  // The lockout ends by itself.
  React.useEffect(() => {
    if (!lockedFor) return;
    const timer = window.setTimeout(() => setFailure(null), lockedFor * 1000);
    return () => window.clearTimeout(timer);
  }, [lockedFor]);

  // Back to the box once it is enabled again.
  const isPending = verify.isPending;
  React.useEffect(() => {
    if (isPending || failure?.kind !== "wrong-code") return;
    if (isRecovery) recoveryField.current?.focus();
    else otp.current?.focus();
  }, [isPending, failure, isRecovery]);

  const submit = (dto: { code: string } | { recoveryCode: string }) => {
    // A wrong code counts toward the lockout, so a code goes out once.
    if (verify.isPending) return;
    setFailure(null);
    verify.mutate(
      { challenge, ...dto },
      {
        onError: (error) => {
          const next = twoFactorFailure(error);
          if (next.kind === "expired") return onExpired();
          setFailure(next);
          if (next.kind === "wrong-code") {
            setCode("");
            setRecoveryCode("");
          }
        },
      },
    );
  };

  const switchMode = (next: "code" | "recovery") => {
    setMode(next);
    setFailure(null);
  };
  const canSubmit = isRecovery
    ? isRecoveryCode(recoveryCode)
    : isOtpComplete(code);

  return (
    <>
      {isRecovery ? (
        <AuthHeading
          title="Use a recovery code"
          sub="Enter one of the codes you saved when you turned on two-factor. Each code works once."
        />
      ) : (
        <AuthHeading
          title="Check your authenticator app"
          sub={
            <>
              Enter the 6-digit code for{" "}
              <b className="font-semibold text-foreground">{email}</b>.
            </>
          }
        />
      )}
      {failure && (
        <AuthMessage>
          {describeFailure(failure, { recovery: isRecovery })}
        </AuthMessage>
      )}
      <form
        className="grid gap-3.5"
        onSubmit={(e) => {
          e.preventDefault();
          if (!canSubmit || locked) return;
          submit(
            isRecovery
              ? { recoveryCode: formatRecoveryCode(recoveryCode) }
              : { code },
          );
        }}
      >
        {isRecovery ? (
          <Field label="Recovery code">
            <Input
              ref={recoveryField}
              mono
              autoFocus
              autoComplete="off"
              autoCapitalize="none"
              placeholder="xxxxx-xxxxx"
              value={recoveryCode}
              disabled={isPending || locked}
              boxClassName="h-field-large"
              onChange={(e) => {
                setRecoveryCode(formatRecoveryCode(e.target.value));
                if (failure?.kind === "wrong-code") setFailure(null);
              }}
            />
          </Field>
        ) : (
          <OtpInput
            ref={otp}
            autoFocus
            label="Authenticator code"
            value={code}
            onChange={(next) => {
              setCode(next);
              if (failure?.kind === "wrong-code") setFailure(null);
            }}
            onComplete={(value) => submit({ code: value })}
            disabled={isPending || locked}
            invalid={failure?.kind === "wrong-code"}
          />
        )}
        <Button
          type="submit"
          size="lg"
          className="w-full"
          disabled={!canSubmit || locked}
          busy={isPending && "Verifying…"}
        >
          Verify
        </Button>
      </form>
      <div className="grid justify-items-center gap-3 text-ui">
        <button
          type="button"
          className={linkButtonClass}
          onClick={() => switchMode(isRecovery ? "code" : "recovery")}
        >
          {isRecovery
            ? "Use an authenticator code instead"
            : "Use a recovery code instead"}
        </button>
        <button
          type="button"
          className={`${linkButtonClass} inline-flex items-center gap-1.5 [&_svg]:size-3.5`}
          onClick={onBack}
        >
          <ArrowLeft aria-hidden />
          Back to sign in
        </button>
      </div>
      {isRecovery && (
        <AuthMessage tone="info">
          After signing in, you can set up a new authenticator app under
          Settings → Security.
        </AuthMessage>
      )}
    </>
  );
}
