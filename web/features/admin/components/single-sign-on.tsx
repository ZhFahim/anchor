"use client";

import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import * as React from "react";
import { useShellStore } from "@/components/layout/shell-store";
import { Button } from "@/components/ui/button";
import { LoadFailedRow } from "@/components/ui/empty-state";
import { Field, FieldDescription } from "@/components/ui/field";
import { Input, InputButton, PasswordInput } from "@/components/ui/input";
import { Skeleton } from "@/components/ui/skeleton";
import { Switch } from "@/components/ui/switch";
import { toast } from "@/components/ui/toast";
import {
  Row,
  SectionHeader,
} from "@/features/settings/components/settings-blocks";
import { copyText } from "@/lib/clipboard";
import { usePresence } from "@/lib/hooks/use-presence";
import { useRetry } from "@/lib/hooks/use-retry";
import { cn } from "@/lib/utils";
import { getOidcSettings, updateOidcSettings } from "../api";
import { adminKeys } from "../queries";
import type { UpdateOidcSettingsDto } from "../types";
import { cardClass, LockNote } from "./admin-parts";

type OidcForm = Required<
  Pick<
    UpdateOidcSettingsDto,
    | "enabled"
    | "providerName"
    | "issuerUrl"
    | "clientId"
    | "disableInternalAuth"
  >
> & {
  clientSecret: string;
  clearSecret: boolean;
};

export function SingleSignOn({ isHidden = false }: { isHidden?: boolean }) {
  const queryClient = useQueryClient();
  const settingsQuery = useQuery({
    queryKey: adminKeys.oidc,
    queryFn: getOidcSettings,
  });
  const settingsRetry = useRetry(settingsQuery.refetch);
  const settings = settingsQuery.data;
  const saved = React.useMemo<OidcForm | null>(
    () =>
      settings
        ? {
            enabled: settings.enabled,
            providerName: settings.providerName ?? "",
            issuerUrl: settings.issuerUrl ?? "",
            clientId: settings.clientId ?? "",
            disableInternalAuth: settings.disableInternalAuth,
            clientSecret: "",
            clearSecret: false,
          }
        : null,
    [settings],
  );
  const [form, setForm] = React.useState<OidcForm | null>(null);
  const [errors, setErrors] = React.useState<{
    issuer?: string;
    client?: string;
  }>({});
  const [copied, setCopied] = React.useState(false);
  React.useEffect(() => setForm(saved), [saved]);
  React.useEffect(() => {
    if (!copied) return;
    const timer = window.setTimeout(() => setCopied(false), 1500);
    return () => window.clearTimeout(timer);
  }, [copied]);

  const dirty =
    !!form &&
    !!saved &&
    (Object.keys(saved) as (keyof OidcForm)[]).some((key) =>
      key === "clientSecret"
        ? !!form.clientSecret.trim()
        : form[key] !== saved[key],
    );
  const saveBar = usePresence(dirty);
  const setBarShown = useShellStore((st) => st.setBarShown);
  React.useEffect(() => {
    setBarShown(dirty && !isHidden);
    return () => setBarShown(false);
  }, [dirty, isHidden, setBarShown]);

  const save = useMutation({
    mutationFn: (dto: UpdateOidcSettingsDto) => updateOidcSettings(dto),
    onSuccess: (updated) => {
      queryClient.setQueryData(adminKeys.oidc, updated);
      queryClient.invalidateQueries({ queryKey: ["oidc-config"] });
      toast.success("Single sign-on settings saved");
    },
    onError: (_, dto) =>
      toast.error("Couldn’t save single sign-on", {
        retry: () => save.mutate(dto),
      }),
  });

  if ((settingsQuery.isError && !settings) || settingsRetry.isRetrying)
    return (
      <section className="grid gap-2.5">
        <h2 className="m-0 px-1 text-title">Single sign-on</h2>
        <LoadFailedRow
          message="Couldn’t load the single sign-on settings."
          onRetry={settingsRetry.retry}
          isRetrying={settingsRetry.isRetrying}
        />
      </section>
    );
  if (settingsQuery.isLoading || !form || !settings)
    return (
      <section className="grid gap-2.5">
        <Skeleton className="h-5 w-40" />
        <Skeleton className="h-40 w-full rounded-2xl" />
      </section>
    );

  const locked = settings.isLocked;
  const updateForm = (patch: Partial<OidcForm>) =>
    setForm((prev) => (prev ? { ...prev, ...patch } : prev));
  const providerName = form.providerName.trim() || "your provider";
  const hasSecret = settings.hasClientSecret && !form.clearSecret;

  const submit = () => {
    const fieldErrors: typeof errors = {};
    if (form.enabled && !form.issuerUrl.trim())
      fieldErrors.issuer = "Enter the issuer URL.";
    else if (form.enabled && !/^https?:\/\/\S+$/i.test(form.issuerUrl.trim()))
      fieldErrors.issuer = "Enter a full URL, like https://auth.example.com.";
    if (form.enabled && !form.clientId.trim())
      fieldErrors.client = "Enter the client ID.";
    setErrors(fieldErrors);
    if (fieldErrors.issuer || fieldErrors.client) return;
    const dto: UpdateOidcSettingsDto = {
      enabled: form.enabled,
      providerName: form.providerName.trim(),
      issuerUrl: form.issuerUrl.trim(),
      clientId: form.clientId.trim(),
      disableInternalAuth: form.disableInternalAuth,
    };
    if (form.clientSecret.trim()) dto.clientSecret = form.clientSecret.trim();
    else if (form.clearSecret) dto.clearClientSecret = true;
    save.mutate(dto);
  };

  return (
    <section className="grid gap-2.5">
      <SectionHeader
        title="Single sign-on"
        description="Let people sign in with your identity provider, like Pocket ID or Authelia (OIDC)."
      />
      {locked && (
        <LockNote>
          Set by <code>OIDC_ENABLED</code>, <code>OIDC_ISSUER_URL</code> and{" "}
          <code>OIDC_CLIENT_ID</code> on the server. Remove them there to change
          these here.
        </LockNote>
      )}
      <div
        data-slot="card"
        className={cn(cardClass, "[&>*+*]:border-border/55 [&>*+*]:border-t")}
      >
        <Row>
          <div className="grid min-w-50 flex-1 gap-0.5">
            <label htmlFor="oidc-on" className="font-semibold text-ui">
              Sign in with a provider
            </label>
            <span className="text-meta text-muted-foreground">
              Adds a “Continue with {providerName}” button to the sign-in page.
            </span>
          </div>
          <Switch
            id="oidc-on"
            checked={form.enabled}
            disabled={locked}
            onCheckedChange={(enabled) => updateForm({ enabled })}
          />
        </Row>
        {form.enabled && (
          <>
            <Row className="grid gap-3.5">
              <div className="grid grid-cols-2 items-start gap-3.5 max-md:grid-cols-1">
                <Field
                  label="Provider name"
                  help="Shown on the sign-in button."
                >
                  <Input
                    value={form.providerName}
                    readOnly={locked}
                    onChange={(e) =>
                      updateForm({ providerName: e.target.value })
                    }
                  />
                </Field>
                <Field label="Issuer URL" error={errors.issuer}>
                  <Input
                    value={form.issuerUrl}
                    readOnly={locked}
                    inputMode="url"
                    placeholder="https://auth.example.com"
                    onChange={(e) => {
                      updateForm({ issuerUrl: e.target.value });
                      setErrors((prev) => ({ ...prev, issuer: undefined }));
                    }}
                  />
                </Field>
              </div>
              <div className="grid grid-cols-2 items-start gap-3.5 max-md:grid-cols-1">
                <Field label="Client ID" error={errors.client}>
                  <Input
                    value={form.clientId}
                    readOnly={locked}
                    onChange={(e) => {
                      updateForm({ clientId: e.target.value });
                      setErrors((prev) => ({ ...prev, client: undefined }));
                    }}
                  />
                </Field>
                {locked ? (
                  <Field
                    label="Client secret"
                    aside="Optional"
                    help="Set on the server."
                  >
                    <Input
                      readOnly
                      value=""
                      placeholder={settings.hasClientSecret ? "Saved" : "None"}
                    />
                  </Field>
                ) : hasSecret ? (
                  <Field
                    label="Client secret"
                    aside="Optional"
                    help="The saved secret is never shown."
                  >
                    <Input
                      type="password"
                      value={form.clientSecret}
                      placeholder="Saved. Type a new one to replace it."
                      onChange={(e) =>
                        updateForm({ clientSecret: e.target.value })
                      }
                      end={
                        <InputButton
                          onClick={() =>
                            updateForm({ clientSecret: "", clearSecret: true })
                          }
                        >
                          Clear
                        </InputButton>
                      }
                    />
                  </Field>
                ) : (
                  <Field
                    label="Client secret"
                    aside="Optional"
                    help="The Anchor phone app needs a public client, so leave this empty if people sign in from their phones."
                  >
                    <PasswordInput
                      value={form.clientSecret}
                      placeholder="Leave empty for the phone app"
                      onChange={(e) =>
                        updateForm({ clientSecret: e.target.value })
                      }
                    />
                  </Field>
                )}
              </div>
            </Row>
            <Row>
              <div className="grid min-w-50 flex-1 gap-0.5">
                <label htmlFor="oidc-only" className="font-semibold text-ui">
                  Only sign in with {providerName}
                </label>
                <span className="text-meta text-muted-foreground">
                  Turns off sign-in and sign-up with email and password.
                </span>
              </div>
              <Switch
                id="oidc-only"
                checked={form.disableInternalAuth}
                disabled={locked}
                onCheckedChange={(disableInternalAuth) =>
                  updateForm({ disableInternalAuth })
                }
              />
            </Row>
            <Row className="block">
              <div className="grid gap-1.5 rounded-lg bg-muted px-3.5 py-3">
                <b className="font-semibold text-meta">Callback URL</b>
                <Input
                  readOnly
                  mono
                  aria-label="Callback URL"
                  value={settings.callbackUrl}
                  boxClassName="bg-card"
                  end={
                    <InputButton
                      onClick={() =>
                        copyText(settings.callbackUrl).then(
                          () => setCopied(true),
                          () => toast.error("Couldn’t copy the address"),
                        )
                      }
                    >
                      {copied ? "Copied" : "Copy"}
                    </InputButton>
                  }
                />
                <FieldDescription>
                  Add this as the redirect URL in {providerName}. It’s based on{" "}
                  <code className="rounded-[5px] bg-foreground/7 px-1.25 py-px font-mono text-foreground text-small">
                    APP_URL
                  </code>
                  .
                </FieldDescription>
              </div>
            </Row>
          </>
        )}
      </div>
      {saveBar.mounted && (
        <div
          role="status"
          data-slot="save-bar"
          inert={saveBar.leaving || undefined}
          onAnimationEnd={(e) =>
            e.target === e.currentTarget && saveBar.leaving && saveBar.done()
          }
          className={cn(
            "sticky bottom-3.5 z-(--z-sticky) flex items-center gap-2.5 rounded-xl bg-inverse py-2 pr-2 pl-4 text-control text-inverse-foreground shadow-bar",
            saveBar.leaving
              ? "pointer-events-none animate-rise-out"
              : "animate-rise-in",
          )}
        >
          <span className="flex-1">
            You have unsaved changes to single sign-on.
          </span>
          <Button
            variant="quiet"
            size="sm"
            className="text-inherit hover:bg-inverse-foreground/10"
            onClick={() => {
              setForm(saved);
              setErrors({});
            }}
          >
            Discard
          </Button>
          <Button
            size="sm"
            className="bg-inverse-foreground bg-none text-inverse shadow-none hover:bg-inverse-foreground/90"
            onClick={submit}
            busy={save.isPending && "Saving…"}
          >
            Save
          </Button>
        </div>
      )}
    </section>
  );
}
