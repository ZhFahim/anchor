"use client";

import { useMutation } from "@tanstack/react-query";
import { Check, Copy } from "lucide-react";
import * as React from "react";
import { Button } from "@/components/ui/button";
import {
  Dialog,
  DialogBody,
  DialogContent,
  DialogDescription,
  DialogFooter,
  DialogHeader,
  DialogTitle,
} from "@/components/ui/dialog";
import { FormAlert } from "@/components/ui/field";
import { OtpInput, type OtpInputHandle } from "@/components/ui/otp-input";
import { Skeleton } from "@/components/ui/skeleton";
import { toast } from "@/components/ui/toast";
import { copyText } from "@/lib/clipboard";
import { useLastShown } from "@/lib/hooks/use-last-shown";
import type { TotpSetup } from "../types";
import { isOtpComplete } from "../utils/otp";
import {
  describeFailure,
  groupSecret,
  type TwoFactorFailure,
  twoFactorFailure,
} from "../utils/two-factor";

function Step({ n, children }: { n: number; children: React.ReactNode }) {
  return (
    <p className="m-0 flex items-center gap-2.5 font-medium text-ui">
      <span
        aria-hidden
        className="grid size-6 flex-none place-items-center rounded-full bg-primary font-bold text-note text-small"
      >
        {n}
      </span>
      {children}
    </p>
  );
}

/** Scannable whatever the theme: dark modules on a light tile. */
function QrCode({ uri }: { uri: string }) {
  const [src, setSrc] = React.useState<string | null>(null);
  React.useEffect(() => {
    let cancelled = false;
    setSrc(null);
    import("qrcode")
      .then((qr) =>
        qr.toDataURL(uri, {
          errorCorrectionLevel: "M",
          margin: 1,
          width: 320,
          color: { dark: "#14161c", light: "#ffffff" },
        }),
      )
      .then((url) => {
        if (!cancelled) setSrc(url);
      })
      .catch(() => {});
    return () => {
      cancelled = true;
    };
  }, [uri]);

  return (
    <div className="grid size-44 flex-none place-items-center rounded-xl bg-white p-1.5 shadow-[inset_0_0_0_1px_var(--border)] max-md:mx-auto">
      {src ? (
        <img
          src={src}
          alt="QR code to scan with your authenticator app"
          className="size-full [image-rendering:pixelated]"
        />
      ) : (
        <Skeleton className="size-full rounded-lg" />
      )}
    </div>
  );
}

/**
 * Turns on an authenticator app: scan or type the key, then prove it works
 * with a code. Open while there is a `setup`.
 */
export function TotpSetupDialog({
  setup,
  hasPasskeys = false,
  onCancel,
  onConfirm,
  onExpired,
}: {
  setup: TotpSetup | null;
  hasPasskeys?: boolean;
  onCancel: () => void;
  /** Rejects with the server’s error when the code is wrong. */
  onConfirm: (code: string) => Promise<void>;
  /** The sign-in this belongs to ran out. */
  onExpired?: () => void;
}) {
  const shown = useLastShown(setup, !!setup);
  const [code, setCode] = React.useState("");
  const [failure, setFailure] = React.useState<TwoFactorFailure | null>(null);
  const otp = React.useRef<OtpInputHandle>(null);

  const confirm = useMutation({
    mutationFn: onConfirm,
    onError: (error) => {
      const next = twoFactorFailure(error);
      if (next.kind === "expired") return onExpired?.();
      setFailure(next);
      if (next.kind === "wrong-code") setCode("");
    },
  });
  const isPending = confirm.isPending;

  // A new setup starts clean.
  const setupKey = setup?.secret;
  const resetConfirm = confirm.reset;
  React.useEffect(() => {
    if (!setupKey) return;
    setCode("");
    setFailure(null);
    resetConfirm();
  }, [setupKey, resetConfirm]);
  React.useEffect(() => {
    if (!isPending && failure?.kind === "wrong-code") otp.current?.focus();
  }, [isPending, failure]);

  const submit = (value: string) => {
    if (confirm.isPending || !isOtpComplete(value)) return;
    setFailure(null);
    confirm.mutate(value);
  };
  const locked = failure?.kind === "locked";

  return (
    <Dialog
      open={!!setup}
      onOpenChange={(open) => !open && !isPending && onCancel()}
    >
      <DialogContent size="md">
        <form
          className="contents"
          onSubmit={(e) => {
            e.preventDefault();
            submit(code);
          }}
        >
          <DialogHeader>
            <DialogTitle>Set up an authenticator app</DialogTitle>
            <DialogDescription>Step 1 of 2</DialogDescription>
          </DialogHeader>
          {shown && (
            <DialogBody className="gap-4">
              <Step n={1}>Scan this QR code with your authenticator app.</Step>
              <div className="flex items-center gap-4 max-md:flex-col max-md:items-stretch">
                <QrCode uri={shown.otpauthUri} />
                <div className="grid min-w-0 flex-1 gap-2">
                  <span className="text-meta text-muted-foreground">
                    Can’t scan? Enter this key instead:
                  </span>
                  <div className="flex min-w-0 items-start gap-2 rounded-field bg-[color-mix(in_srgb,var(--foreground)_3%,var(--card))] px-3 py-2 shadow-[inset_0_0_0_1px_var(--border)]">
                    <code
                      data-testid="setup-key"
                      className="min-w-0 flex-1 select-all break-words font-mono text-meta leading-6 tracking-[.01em]"
                    >
                      {groupSecret(shown.secret)}
                    </code>
                    <button
                      type="button"
                      aria-label="Copy key"
                      onClick={() =>
                        copyText(shown.secret).then(
                          () => toast.success("Key copied"),
                          () => toast.error("Couldn’t copy the key"),
                        )
                      }
                      className="-mr-1.5 mt-px grid size-7 flex-none cursor-pointer place-items-center rounded-sm border-0 bg-transparent text-muted-foreground hover:bg-foreground/6 hover:text-foreground [&_svg]:size-4"
                    >
                      <Copy aria-hidden />
                    </button>
                  </div>
                  <span className="text-meta text-muted-foreground">
                    On this phone?{" "}
                    <a
                      href={shown.otpauthUri}
                      className="font-semibold text-accent-ink underline decoration-current/35 underline-offset-3 hover:decoration-current"
                    >
                      Open in your authenticator app
                    </a>
                  </span>
                </div>
              </div>
              <Step n={2}>Enter the 6-digit code the app shows.</Step>
              <OtpInput
                ref={otp}
                autoFocus
                label="Authenticator code"
                value={code}
                onChange={setCode}
                onComplete={submit}
                disabled={isPending || locked}
                invalid={failure?.kind === "wrong-code"}
                className="max-w-93 max-md:max-w-none"
              />
              {failure && <FormAlert>{describeFailure(failure)}</FormAlert>}
              <FormAlert tone="info">
                Turning this on signs you out on all other devices.
                {hasPasskeys && " Your passkeys keep working."}
              </FormAlert>
            </DialogBody>
          )}
          <DialogFooter>
            <Button
              type="button"
              variant="quiet"
              disabled={isPending}
              onClick={onCancel}
            >
              Cancel
            </Button>
            <Button
              type="submit"
              disabled={!isOtpComplete(code) || locked}
              busy={isPending && "Turning on…"}
            >
              <Check aria-hidden />
              Turn on
            </Button>
          </DialogFooter>
        </form>
      </DialogContent>
    </Dialog>
  );
}
