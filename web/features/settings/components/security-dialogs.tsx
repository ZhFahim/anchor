"use client";

import { useMutation } from "@tanstack/react-query";
import { HTTPError } from "ky";
import { Fingerprint } from "lucide-react";
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
import { Field, FormAlert } from "@/components/ui/field";
import { Input, PasswordInput } from "@/components/ui/input";
import { OtpInput, type OtpInputHandle } from "@/components/ui/otp-input";
import { linkButtonClass } from "@/features/auth/components/auth-parts";
import { isOtpComplete } from "@/features/auth/utils/otp";
import {
  describeFailure,
  formatRecoveryCode,
  isRecoveryCode,
  passkeyCeremonyFailure,
  type TwoFactorFailure,
  twoFactorFailure,
} from "@/features/auth/utils/two-factor";
import { useLastShown } from "@/lib/hooks/use-last-shown";

export interface CodeConfirmation {
  password: string;
  /** An authenticator code, or a recovery code. */
  code: string;
  isRecoveryCode: boolean;
}

/**
 * Asks for what proves it’s you before a change to two-factor: the password
 * and/or a code from the app, or a recovery code instead.
 */
export function CodeConfirmDialog({
  open,
  onOpenChange,
  title,
  description,
  confirmLabel,
  busyLabel,
  variant = "primary",
  needsPassword,
  allowRecovery,
  onConfirm,
}: {
  open: boolean;
  onOpenChange: (open: boolean) => void;
  title: string;
  description: React.ReactNode;
  confirmLabel: string;
  busyLabel: string;
  variant?: "primary" | "destructive";
  needsPassword: boolean;
  allowRecovery: boolean;
  /** Rejects with the server’s error when something is wrong. */
  onConfirm: (input: CodeConfirmation) => Promise<void>;
}) {
  const shownTitle = useLastShown(title, open);
  const shownDescription = useLastShown(description, open);
  const shownLabel = useLastShown(confirmLabel, open);
  const [password, setPassword] = React.useState("");
  const [code, setCode] = React.useState("");
  const [recovery, setRecovery] = React.useState("");
  const [useRecovery, setUseRecovery] = React.useState(false);
  const [failure, setFailure] = React.useState<TwoFactorFailure | null>(null);
  const otp = React.useRef<OtpInputHandle>(null);

  const confirm = useMutation({
    mutationFn: onConfirm,
    onSuccess: () => onOpenChange(false),
    onError: (error) => {
      const next = twoFactorFailure(error);
      setFailure(next);
      if (next.kind === "wrong-code") {
        setCode("");
        setRecovery("");
      }
    },
  });
  const isPending = confirm.isPending;
  const resetConfirm = confirm.reset;

  React.useEffect(() => {
    if (!open) return;
    setPassword("");
    setCode("");
    setRecovery("");
    setUseRecovery(false);
    setFailure(null);
    resetConfirm();
  }, [open, resetConfirm]);
  React.useEffect(() => {
    if (!isPending && failure?.kind === "wrong-code") otp.current?.focus();
  }, [isPending, failure]);

  const locked = failure?.kind === "locked";
  const hasCode = useRecovery ? isRecoveryCode(recovery) : isOtpComplete(code);
  const canSubmit = hasCode && (!needsPassword || !!password) && !locked;
  const passwordError =
    failure?.kind === "wrong-password" ? describeFailure(failure) : null;

  return (
    <Dialog
      open={open}
      onOpenChange={(next) => !isPending && onOpenChange(next)}
    >
      <DialogContent>
        <form
          className="contents"
          onSubmit={(e) => {
            e.preventDefault();
            if (!canSubmit || confirm.isPending) return;
            setFailure(null);
            confirm.mutate({
              password,
              code: useRecovery ? formatRecoveryCode(recovery) : code,
              isRecoveryCode: useRecovery,
            });
          }}
        >
          <DialogHeader>
            <DialogTitle>{shownTitle}</DialogTitle>
            <DialogDescription>{shownDescription}</DialogDescription>
          </DialogHeader>
          <DialogBody>
            {needsPassword && (
              <Field label="Password" error={passwordError}>
                <PasswordInput
                  autoFocus
                  autoComplete="current-password"
                  value={password}
                  disabled={isPending}
                  onChange={(e) => {
                    setPassword(e.target.value);
                    if (failure?.kind === "wrong-password") setFailure(null);
                  }}
                />
              </Field>
            )}
            {useRecovery ? (
              <Field label="Recovery code">
                <Input
                  mono
                  autoFocus={!needsPassword}
                  autoComplete="off"
                  autoCapitalize="none"
                  placeholder="xxxxx-xxxxx"
                  value={recovery}
                  disabled={isPending || locked}
                  onChange={(e) => {
                    setRecovery(formatRecoveryCode(e.target.value));
                    if (failure?.kind === "wrong-code") setFailure(null);
                  }}
                />
              </Field>
            ) : (
              <div className="grid gap-2">
                <span className="font-semibold text-foreground text-meta">
                  Authenticator code
                </span>
                <OtpInput
                  ref={otp}
                  autoFocus={!needsPassword}
                  label="Authenticator code"
                  value={code}
                  onChange={(next) => {
                    setCode(next);
                    if (failure?.kind === "wrong-code") setFailure(null);
                  }}
                  disabled={isPending || locked}
                  invalid={failure?.kind === "wrong-code"}
                  className="[&_input]:h-12"
                />
              </div>
            )}
            {allowRecovery && (
              <button
                type="button"
                className={`${linkButtonClass} justify-self-start text-meta`}
                onClick={() => {
                  setUseRecovery((v) => !v);
                  setFailure(null);
                }}
              >
                {useRecovery
                  ? "Use an authenticator code instead"
                  : "Use a recovery code instead"}
              </button>
            )}
            {failure && failure.kind !== "wrong-password" && (
              <FormAlert>
                {describeFailure(failure, { recovery: useRecovery })}
              </FormAlert>
            )}
          </DialogBody>
          <DialogFooter>
            <Button
              type="button"
              variant="quiet"
              disabled={isPending}
              onClick={() => onOpenChange(false)}
            >
              Cancel
            </Button>
            <Button
              type="submit"
              variant={variant}
              disabled={!canSubmit}
              busy={isPending && busyLabel}
            >
              {shownLabel}
            </Button>
          </DialogFooter>
        </form>
      </DialogContent>
    </Dialog>
  );
}

const nameMessage = (error: unknown): string => {
  if (error instanceof HTTPError)
    return error.response.status >= 500
      ? "Something went wrong on the server. Try again in a moment."
      : "Couldn’t save that name. Try another.";
  return "Couldn’t reach the server. Check your connection and try again.";
};

/** Names a passkey, then asks the browser to make it. */
export function AddPasskeyDialog({
  open,
  onOpenChange,
  initialName,
  onAdd,
}: {
  open: boolean;
  onOpenChange: (open: boolean) => void;
  initialName: string;
  /** Resolves once the passkey is saved. */
  onAdd: (name: string) => Promise<void>;
}) {
  const [name, setName] = React.useState(initialName);
  const [error, setError] = React.useState<string | null>(null);
  const add = useMutation({
    mutationFn: onAdd,
    onSuccess: () => onOpenChange(false),
    onError: (e) => {
      if (e instanceof HTTPError) return setError(nameMessage(e));
      const failure = passkeyCeremonyFailure(e);
      if (failure === "cancelled") return setError(null);
      setError(
        failure === "already-registered"
          ? "This device already has a passkey for Anchor."
          : failure === "unsupported"
            ? "This device can’t make that kind of passkey."
            : "Couldn’t add the passkey. Try again.",
      );
    },
  });
  const resetAdd = add.reset;
  React.useEffect(() => {
    if (!open) return;
    setName(initialName);
    setError(null);
    resetAdd();
  }, [open, initialName, resetAdd]);

  return (
    <Dialog
      open={open}
      onOpenChange={(next) => !add.isPending && onOpenChange(next)}
    >
      <DialogContent>
        <form
          className="contents"
          onSubmit={(e) => {
            e.preventDefault();
            if (!name.trim() || add.isPending) return;
            setError(null);
            add.mutate(name.trim());
          }}
        >
          <DialogHeader>
            <DialogTitle>Add a passkey</DialogTitle>
            <DialogDescription>
              Give it a name so you can tell your devices apart.
            </DialogDescription>
          </DialogHeader>
          <DialogBody>
            <Field label="Name">
              <Input
                autoFocus
                maxLength={60}
                value={name}
                disabled={add.isPending}
                onChange={(e) => setName(e.target.value)}
                onFocus={(e) => e.currentTarget.select()}
              />
            </Field>
            {error ? (
              <FormAlert>{error}</FormAlert>
            ) : (
              <FormAlert tone="info">
                Next, your browser asks you to confirm with Touch ID, Windows
                Hello or your phone.
              </FormAlert>
            )}
          </DialogBody>
          <DialogFooter>
            <Button
              type="button"
              variant="quiet"
              disabled={add.isPending}
              onClick={() => onOpenChange(false)}
            >
              Cancel
            </Button>
            <Button
              type="submit"
              disabled={!name.trim()}
              busy={add.isPending && "Waiting for your device…"}
            >
              <Fingerprint aria-hidden />
              Continue
            </Button>
          </DialogFooter>
        </form>
      </DialogContent>
    </Dialog>
  );
}

export function RenamePasskeyDialog({
  passkey,
  onClose,
  onRename,
}: {
  passkey: { id: string; name: string } | null;
  onClose: () => void;
  onRename: (id: string, name: string) => Promise<void>;
}) {
  const shown = useLastShown(passkey, !!passkey);
  const [name, setName] = React.useState("");
  const [error, setError] = React.useState<string | null>(null);
  const rename = useMutation({
    mutationFn: (value: string) => onRename(shown?.id ?? "", value),
    onSuccess: onClose,
    onError: (e) => setError(nameMessage(e)),
  });
  const resetRename = rename.reset;
  const passkeyId = passkey?.id;
  const passkeyName = passkey?.name;
  React.useEffect(() => {
    if (passkeyId === undefined) return;
    setName(passkeyName ?? "");
    setError(null);
    resetRename();
  }, [passkeyId, passkeyName, resetRename]);

  return (
    <Dialog
      open={!!passkey}
      onOpenChange={(next) => !next && !rename.isPending && onClose()}
    >
      <DialogContent>
        <form
          className="contents"
          onSubmit={(e) => {
            e.preventDefault();
            if (!name.trim() || rename.isPending) return;
            setError(null);
            rename.mutate(name.trim());
          }}
        >
          <DialogHeader>
            <DialogTitle>Rename passkey</DialogTitle>
            <DialogDescription>
              Give it a name so you can tell your devices apart.
            </DialogDescription>
          </DialogHeader>
          <DialogBody>
            <Field label="Name" error={error}>
              <Input
                autoFocus
                maxLength={60}
                value={name}
                onChange={(e) => setName(e.target.value)}
                onFocus={(e) => e.currentTarget.select()}
              />
            </Field>
          </DialogBody>
          <DialogFooter>
            <Button
              type="button"
              variant="quiet"
              disabled={rename.isPending}
              onClick={onClose}
            >
              Cancel
            </Button>
            <Button
              type="submit"
              disabled={!name.trim() || name.trim() === shown?.name}
              busy={rename.isPending && "Saving…"}
            >
              Save
            </Button>
          </DialogFooter>
        </form>
      </DialogContent>
    </Dialog>
  );
}
