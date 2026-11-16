"use client";

import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { HTTPError } from "ky";
import Link from "next/link";
import { LoadFailedRow } from "@/components/ui/empty-state";
import { FormAlert } from "@/components/ui/field";
import { RadioCards } from "@/components/ui/radio-cards";
import { Skeleton } from "@/components/ui/skeleton";
import { toast } from "@/components/ui/toast";
import { linkButtonClass } from "@/features/auth/components/auth-parts";
import {
  SaveStatus,
  SectionHeader,
  useSaveStatus,
} from "@/features/settings/components/settings-blocks";
import { useRetry } from "@/lib/hooks/use-retry";
import { plural } from "@/lib/utils";
import {
  getOidcSettings,
  getTwoFactorSettings,
  updateTwoFactorPolicy,
} from "../api";
import { adminKeys } from "../queries";
import type { TwoFactorPolicy, TwoFactorSettings } from "../types";
import { cardClass, LockNote } from "./admin-parts";

function Coverage({
  settings,
  providerName,
}: {
  settings: TwoFactorSettings;
  providerName: string;
}) {
  const { covered, total } = settings.coverage;
  const required = settings.policy !== "optional";
  const percent = total ? Math.round((covered / total) * 100) : 0;
  const missing = total - covered;
  return (
    <div className={`${cardClass} grid gap-3 p-4`}>
      <div className="flex flex-wrap items-baseline justify-between gap-x-4 gap-y-1">
        <b className="font-semibold text-ui">
          {required
            ? `${covered} of ${plural(total, "person", "people")} ${covered === 1 && total === 1 ? "is" : "are"} covered`
            : `${covered} of ${plural(total, "person", "people")} ${total === 1 ? "has" : "have"} two-factor on`}
        </b>
        {required && missing > 0 && (
          <span className="text-meta text-muted-foreground">
            {missing} still {missing === 1 ? "needs" : "need"} to set it up
          </span>
        )}
      </div>
      <div
        role="progressbar"
        aria-label="People with two-factor"
        aria-valuemin={0}
        aria-valuemax={total}
        aria-valuenow={covered}
        className="h-2 overflow-hidden rounded-pill bg-muted"
      >
        <div
          className="h-full rounded-pill bg-added transition-[width] duration-(--duration-move)"
          style={{ width: `${percent}%` }}
        />
      </div>
      <LockNote>
        People who sign in with {providerName} are not asked. Your provider
        handles their second step. API tokens are not affected.
      </LockNote>
    </div>
  );
}

export function TwoFactorSection() {
  const queryClient = useQueryClient();
  const settingsQuery = useQuery({
    queryKey: adminKeys.twoFactor,
    queryFn: getTwoFactorSettings,
  });
  const retry = useRetry(settingsQuery.refetch);
  const oidc = useQuery({ queryKey: adminKeys.oidc, queryFn: getOidcSettings });
  const [saveState, setSaveState] = useSaveStatus();
  const settings = settingsQuery.data;

  const save = useMutation({
    mutationFn: (policy: TwoFactorPolicy) => updateTwoFactorPolicy(policy),
    onSuccess: (next) => {
      queryClient.setQueryData(adminKeys.twoFactor, next);
      setSaveState("saved");
    },
    onError: (error, policy) => {
      // A refusal (409) says why; show it where the choice is.
      if (error instanceof HTTPError && error.response.status === 409) return;
      toast.error("Couldn’t change who needs two-factor", {
        retry: () => save.mutate(policy),
      });
    },
  });
  const conflict =
    save.error instanceof HTTPError && save.error.response.status === 409
      ? save.error.message
      : null;

  const unavailable =
    !!settings && !settings.available.totp && !settings.available.passkeys;
  const locked = !!settings?.isLocked;
  const choose = (policy: TwoFactorPolicy) => {
    if (policy === settings?.policy && !save.isPending) return;
    save.mutate(policy);
  };

  return (
    <section className="grid gap-2.5">
      <SectionHeader
        title={
          <>
            Two-factor authentication
            <span className="rounded-pill bg-warn px-1.5 py-px font-bold text-[10px] text-warn-foreground uppercase tracking-[.04em]">
              New
            </span>
          </>
        }
        description="Choose who has to use a second step when signing in with a password."
        saved={<SaveStatus state={saveState} />}
      />
      {locked && (
        <LockNote>
          Set on the server. Remove it there to change it here.
        </LockNote>
      )}
      {unavailable && (
        <LockNote>
          Two-factor isn’t available on this server yet. Set{" "}
          <code>TOTP_ENCRYPTION_KEY</code> for authenticator apps and{" "}
          <code>APP_URL</code> for passkeys, then restart it.
        </LockNote>
      )}
      {(settingsQuery.isError && !settings) || retry.isRetrying ? (
        <LoadFailedRow
          message="Couldn’t load the two-factor settings."
          onRetry={retry.retry}
          isRetrying={retry.isRetrying}
        />
      ) : !settings ? (
        <Skeleton className="h-52 w-full rounded-xl" />
      ) : (
        <>
          <RadioCards
            aria-label="Who needs two-factor"
            value={
              save.isPending && save.variables
                ? save.variables
                : settings.policy
            }
            onValueChange={choose}
            className="grid-cols-1"
            options={[
              {
                value: "optional",
                label: "Optional",
                description: "People can turn it on in their settings.",
                disabled: locked,
              },
              {
                value: "admins",
                label: "Required for admins",
                description:
                  "Admins must set up two-factor or a passkey at their next sign-in.",
                disabled: locked || unavailable,
              },
              {
                value: "everyone",
                label: "Required for everyone",
                description:
                  "Everyone with a password must set up two-factor or a passkey at their next sign-in.",
                disabled: locked || unavailable,
              },
            ]}
          />
          {conflict && (
            <FormAlert
              action={
                /your own account/i.test(conflict) ? (
                  <Link
                    href="/settings"
                    className={`${linkButtonClass} whitespace-nowrap self-center`}
                  >
                    Open settings
                  </Link>
                ) : undefined
              }
            >
              {conflict}
            </FormAlert>
          )}
          {settings.coverage.total > 0 && (
            <Coverage
              settings={settings}
              providerName={oidc.data?.providerName || "your provider"}
            />
          )}
        </>
      )}
    </section>
  );
}
