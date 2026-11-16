"use client";

import { useMutation, useQueryClient } from "@tanstack/react-query";
import { format } from "date-fns";
import {
  Fingerprint,
  KeyRound,
  Pencil,
  Plus,
  ShieldCheck,
  Smartphone,
  Trash2,
} from "lucide-react";
import * as React from "react";
import { Badge } from "@/components/ui/badge";
import { Button, IconButton } from "@/components/ui/button";
import { ConfirmationDialog } from "@/components/ui/confirmation-dialog";
import { LoadFailedRow } from "@/components/ui/empty-state";
import { FormAlert } from "@/components/ui/field";
import { Skeleton } from "@/components/ui/skeleton";
import { toast } from "@/components/ui/toast";
import { Tip } from "@/components/ui/tooltip";
import {
  deletePasskey,
  disableTotp,
  enableTotp,
  regenerateRecoveryCodes,
  renamePasskey,
  setupTotp,
} from "@/features/auth/api";
import { RecoveryCodesDialog } from "@/features/auth/components/recovery-codes-dialog";
import { TotpSetupDialog } from "@/features/auth/components/totp-setup-dialog";
import { addPasskey, canUsePasskeys } from "@/features/auth/passkey";
import { setAccessToken, setRefreshToken } from "@/features/auth/store";
import type { PasskeySummary, TotpSetup } from "@/features/auth/types";
import {
  describeFailure,
  lastUsedLabel,
  suggestPasskeyName,
  twoFactorFailure,
} from "@/features/auth/utils/two-factor";
import { useRetry } from "@/lib/hooks/use-retry";
import { cn } from "@/lib/utils";
import { securityKeys, useSecurity } from "../hooks/use-security";
import {
  AddPasskeyDialog,
  CodeConfirmDialog,
  RenamePasskeyDialog,
} from "./security-dialogs";
import { Row, RowText, Section } from "./settings-blocks";

function IconTile({
  children,
  tone,
}: {
  children: React.ReactNode;
  tone?: "ok";
}) {
  return (
    <span
      aria-hidden
      className={cn(
        "grid size-9.5 flex-none place-items-center rounded-lg bg-muted text-muted-foreground [&_svg]:size-4.5",
        tone === "ok" &&
          "bg-[color-mix(in_srgb,var(--added)_14%,var(--card))] text-added-ink",
      )}
    >
      {children}
    </span>
  );
}

const dayOf = (iso: string) => format(new Date(iso), "MMM d, yyyy");

type TotpDialog = "replace" | "disable" | "codes" | null;

/** Settings → Security: the authenticator app and the passkeys. */
export function SecuritySection() {
  const { status, isManagedElsewhere, providerName, isHidden } = useSecurity();
  const statusRetry = useRetry(status.refetch);

  if (isManagedElsewhere)
    return (
      <Section id="security" title="Two-factor authentication">
        <Row>
          <RowText
            title={`Two-factor is managed by ${providerName}`}
            text="This account signs in without a password. Set up the second step in your sign-in provider."
          />
        </Row>
      </Section>
    );
  if (isHidden) return null;

  if (status.isError || statusRetry.isRetrying)
    return (
      <Section id="security" title="Two-factor authentication">
        <Row>
          <LoadFailedRow
            className="flex-1"
            message="Couldn’t load your security settings."
            onRetry={statusRetry.retry}
            isRetrying={statusRetry.isRetrying}
          />
        </Row>
      </Section>
    );
  if (!status.data)
    return (
      <Section id="security" title="Two-factor authentication">
        <Row className="gap-3.5" aria-busy="true">
          <Skeleton className="size-9.5 flex-none rounded-lg" />
          <span className="grid flex-1 gap-2">
            <Skeleton className="h-3.5 w-1/3" />
            <Skeleton className="h-3 w-2/3" />
          </span>
        </Row>
      </Section>
    );

  return <SecurityBody />;
}

function SecurityBody() {
  const { status } = useSecurity();
  const data = status.data;
  const queryClient = useQueryClient();
  const [setup, setSetup] = React.useState<TotpSetup | null>(null);
  const [dialog, setDialog] = React.useState<TotpDialog>(null);
  const [codes, setCodes] = React.useState<{
    list: string[];
    intro: string;
    step?: string;
  } | null>(null);
  const [adding, setAdding] = React.useState(false);
  const [renaming, setRenaming] = React.useState<PasskeySummary | null>(null);
  const [removing, setRemoving] = React.useState<PasskeySummary | null>(null);

  const refresh = () =>
    queryClient.invalidateQueries({ queryKey: securityKeys.status });

  const startSetup = useMutation({
    mutationFn: () => setupTotp(),
    onSuccess: setSetup,
    onError: (error) => {
      const failure = twoFactorFailure(error);
      toast.error(
        failure.kind === "other" || failure.kind === "wrong-code"
          ? "Couldn’t start the setup"
          : describeFailure(failure),
      );
    },
  });
  const removePasskey = useMutation({
    mutationFn: (passkey: PasskeySummary) => deletePasskey(passkey.id),
    onSuccess: async (_, passkey) => {
      await refresh();
      setRemoving(null);
      toast.success(`“${passkey.name}” deleted`);
    },
    onError: (error) => {
      setRemoving(null);
      const failure = twoFactorFailure(error);
      toast.error(
        failure.kind === "required-by-admin"
          ? "Your admin requires two-factor. Add another way to sign in first."
          : "Couldn’t delete the passkey",
      );
    },
  });

  if (!data) return null;
  const { available, totp, passkeys } = data;
  const canAddPasskey = canUsePasskeys();
  const few = totp.recoveryCodesRemaining <= 3;

  return (
    <>
      {available.totp && (
        <Section
          id="security"
          title="Two-factor authentication"
          description="Ask for a code from an authenticator app each time you sign in with your password."
        >
          {data.required && (
            <Row className="block">
              <FormAlert tone="info">
                Your admin requires two-factor. Set up an authenticator app
                {available.passkeys ? " or add a passkey" : ""} to keep signing
                in.
              </FormAlert>
            </Row>
          )}
          <Row>
            <IconTile tone={totp.enabled ? "ok" : undefined}>
              {totp.enabled ? <ShieldCheck /> : <Smartphone />}
            </IconTile>
            <RowText
              title="Authenticator app"
              saved={
                totp.enabled ? <Badge tone="ok">On</Badge> : <Badge>Off</Badge>
              }
              text={
                totp.enabled
                  ? [
                      totp.enabledAt && `Added ${dayOf(totp.enabledAt)}`,
                      lastUsedLabel(totp.lastUsedAt),
                    ]
                      .filter(Boolean)
                      .join(" · ")
                  : "Use an app like 1Password, Aegis or Google Authenticator."
              }
            />
            {totp.enabled ? (
              <div className="flex gap-2">
                <Button
                  variant="secondary"
                  onClick={() => setDialog("replace")}
                >
                  Replace
                </Button>
                <Button
                  variant="danger"
                  className="shadow-[inset_0_0_0_1px_color-mix(in_srgb,var(--late)_40%,transparent)]"
                  onClick={() => setDialog("disable")}
                >
                  Turn off
                </Button>
              </div>
            ) : (
              <Button
                busy={startSetup.isPending && "Starting…"}
                onClick={() => !startSetup.isPending && startSetup.mutate()}
              >
                Set up
              </Button>
            )}
          </Row>
          {totp.enabled && (
            <Row>
              <IconTile>
                <KeyRound />
              </IconTile>
              <RowText
                title="Recovery codes"
                saved={
                  <Badge tone={few ? "warn" : "default"}>
                    {totp.recoveryCodesRemaining} of 10 left
                  </Badge>
                }
                text="Use one if you lose access to your authenticator app."
              />
              <Button variant="secondary" onClick={() => setDialog("codes")}>
                Get new codes
              </Button>
            </Row>
          )}
        </Section>
      )}

      {available.passkeys && (
        <Section
          id={available.totp ? "passkeys" : "security"}
          title="Passkeys"
          description="Sign in with your fingerprint, face or device PIN. A passkey replaces both your password and the code."
        >
          {passkeys.length === 0 ? (
            <Row>
              <IconTile>
                <Fingerprint />
              </IconTile>
              <RowText
                title="No passkeys yet"
                text="Add one on this device or on your phone."
              />
              {canAddPasskey && (
                <Button variant="secondary" onClick={() => setAdding(true)}>
                  <Plus aria-hidden />
                  Add a passkey
                </Button>
              )}
            </Row>
          ) : (
            <>
              {passkeys.map((passkey) => (
                <Row key={passkey.id}>
                  <IconTile>
                    <Fingerprint />
                  </IconTile>
                  <RowText
                    title={passkey.name}
                    text={[
                      `Added ${dayOf(passkey.createdAt)}`,
                      lastUsedLabel(passkey.lastUsedAt),
                    ].join(" · ")}
                  />
                  <div className="flex gap-0.5">
                    <Tip label="Rename">
                      <IconButton
                        size="sm"
                        label={`Rename ${passkey.name}`}
                        onClick={() => setRenaming(passkey)}
                      >
                        <Pencil />
                      </IconButton>
                    </Tip>
                    <Tip label="Delete">
                      <IconButton
                        size="sm"
                        tone="danger"
                        label={`Delete ${passkey.name}`}
                        onClick={() => setRemoving(passkey)}
                      >
                        <Trash2 />
                      </IconButton>
                    </Tip>
                  </div>
                </Row>
              ))}
              <Row>
                <span className="min-w-50 flex-1 text-meta text-muted-foreground">
                  Passkeys are stored by your browser or password manager, not
                  by Anchor.
                </span>
                {canAddPasskey && (
                  <Button variant="secondary" onClick={() => setAdding(true)}>
                    <Plus aria-hidden />
                    Add a passkey
                  </Button>
                )}
              </Row>
            </>
          )}
          {!canAddPasskey && (
            <Row>
              <span className="text-meta text-muted-foreground">
                This browser can’t create passkeys. Use another browser or
                device to add one.
              </span>
            </Row>
          )}
        </Section>
      )}

      <TotpSetupDialog
        setup={setup}
        hasPasskeys={passkeys.length > 0}
        onCancel={() => setSetup(null)}
        onConfirm={async (code) => {
          const result = await enableTotp(code);
          // Every other session just ended, and so did the refresh token this
          // one held: keep the new pair, or this session ends in 15 minutes.
          setAccessToken(result.access_token);
          setRefreshToken(result.refresh_token);
          setSetup(null);
          setCodes({
            list: result.recoveryCodes,
            step: "Step 2 of 2",
            intro:
              "Two-factor is on. If you lose your phone, each of these codes lets you in once.",
          });
          void refresh();
        }}
      />
      <RecoveryCodesDialog
        codes={codes?.list ?? null}
        step={codes?.step}
        intro={codes?.intro}
        onDone={() => setCodes(null)}
      />

      <CodeConfirmDialog
        open={dialog === "replace"}
        onOpenChange={(open) => !open && setDialog(null)}
        title="Replace your authenticator app"
        description="Enter a code from your current app to set up a new one. The old app stops working once the new one is on."
        confirmLabel="Continue"
        busyLabel="Checking…"
        needsPassword={false}
        allowRecovery
        onConfirm={async ({ code, isRecoveryCode }) => {
          setSetup(
            await setupTotp(isRecoveryCode ? { recoveryCode: code } : { code }),
          );
        }}
      />
      <CodeConfirmDialog
        open={dialog === "disable"}
        onOpenChange={(open) => !open && setDialog(null)}
        title="Turn off two-factor?"
        description="You’ll sign in with just your password. Your recovery codes stop working."
        confirmLabel="Turn off"
        busyLabel="Turning off…"
        variant="destructive"
        needsPassword
        allowRecovery
        onConfirm={async ({ password, code, isRecoveryCode }) => {
          await disableTotp(
            isRecoveryCode
              ? { password, recoveryCode: code }
              : { password, code },
          );
          await refresh();
          toast.success("Two-factor turned off");
        }}
      />
      <CodeConfirmDialog
        open={dialog === "codes"}
        onOpenChange={(open) => !open && setDialog(null)}
        title="Get new recovery codes"
        description="Your old codes stop working as soon as you get new ones."
        confirmLabel="Get new codes"
        busyLabel="Getting codes…"
        needsPassword
        allowRecovery={false}
        onConfirm={async ({ password, code }) => {
          const result = await regenerateRecoveryCodes({ password, code });
          setCodes({
            list: result.recoveryCodes,
            intro: "These replace your old codes. Each one lets you in once.",
          });
          void refresh();
        }}
      />

      <AddPasskeyDialog
        open={adding}
        onOpenChange={setAdding}
        initialName={suggestPasskeyName(
          typeof navigator === "undefined" ? "" : navigator.userAgent,
        )}
        onAdd={async (name) => {
          await addPasskey(name);
          await refresh();
          toast.success("Passkey added");
        }}
      />
      <RenamePasskeyDialog
        passkey={renaming}
        onClose={() => setRenaming(null)}
        onRename={async (id, name) => {
          await renamePasskey(id, name);
          await refresh();
          toast.success("Passkey renamed");
        }}
      />
      <ConfirmationDialog
        open={!!removing}
        onOpenChange={(open) => !open && setRemoving(null)}
        title={`Delete “${removing?.name ?? ""}”?`}
        description="You won’t be able to sign in with this passkey anymore. Remove it from your browser or password manager too."
        confirmLabel="Delete passkey"
        busyLabel="Deleting…"
        isPending={removePasskey.isPending}
        onConfirm={() => removing && removePasskey.mutate(removing)}
      />
    </>
  );
}
