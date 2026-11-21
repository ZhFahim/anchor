"use client";

import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { useTranslations } from "next-intl";
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

const code = (chunks: React.ReactNode) => <code>{chunks}</code>;

export function SingleSignOn({ isHidden = false }: { isHidden?: boolean }) {
  const t = useTranslations();
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
      toast.success(t("adminSsoSaved"));
    },
    onError: (_, dto) =>
      toast.error(t("adminSsoSaveFailed"), {
        retry: () => save.mutate(dto),
      }),
  });

  if ((settingsQuery.isError && !settings) || settingsRetry.isRetrying)
    return (
      <section className="grid gap-2.5">
        <h2 className="m-0 px-1 text-title">{t("adminSingleSignOn")}</h2>
        <LoadFailedRow
          message={t("adminSsoLoadFailed")}
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
  const provider = form.providerName.trim();
  const hasSecret = settings.hasClientSecret && !form.clearSecret;

  const submit = () => {
    const fieldErrors: typeof errors = {};
    if (form.enabled && !form.issuerUrl.trim())
      fieldErrors.issuer = t("adminSsoIssuerMissing");
    else if (form.enabled && !/^https?:\/\/\S+$/i.test(form.issuerUrl.trim()))
      fieldErrors.issuer = t("adminSsoIssuerInvalid");
    if (form.enabled && !form.clientId.trim())
      fieldErrors.client = t("adminSsoClientIdMissing");
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
        title={t("adminSingleSignOn")}
        description={t("adminSsoHelp")}
      />
      {locked && (
        <LockNote>
          {t.rich("adminSsoLocked", {
            enabled: "OIDC_ENABLED",
            issuer: "OIDC_ISSUER_URL",
            client: "OIDC_CLIENT_ID",
            code,
          })}
        </LockNote>
      )}
      <div
        data-slot="card"
        className={cn(cardClass, "[&>*+*]:border-border/55 [&>*+*]:border-t")}
      >
        <Row>
          <div className="grid min-w-50 flex-1 gap-0.5">
            <label htmlFor="oidc-on" className="font-semibold text-ui">
              {t("adminSsoToggle")}
            </label>
            <span className="text-meta text-muted-foreground">
              {provider
                ? t("adminSsoButtonHelp", { provider })
                : t("adminSsoButtonHelpUnnamed")}
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
                  label={t("adminSsoProviderName")}
                  help={t("adminSsoProviderNameHelp")}
                >
                  <Input
                    value={form.providerName}
                    readOnly={locked}
                    onChange={(e) =>
                      updateForm({ providerName: e.target.value })
                    }
                  />
                </Field>
                <Field label={t("adminSsoIssuerUrl")} error={errors.issuer}>
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
                <Field label={t("adminSsoClientId")} error={errors.client}>
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
                    label={t("adminSsoClientSecret")}
                    aside={t("adminSsoOptional")}
                    help={t("adminSsoSecretOnServer")}
                  >
                    <Input
                      readOnly
                      value=""
                      placeholder={
                        settings.hasClientSecret
                          ? t("adminSsoSecretSaved")
                          : t("adminSsoSecretNone")
                      }
                    />
                  </Field>
                ) : hasSecret ? (
                  <Field
                    label={t("adminSsoClientSecret")}
                    aside={t("adminSsoOptional")}
                    help={t("adminSsoSecretHidden")}
                  >
                    <Input
                      type="password"
                      value={form.clientSecret}
                      placeholder={t("adminSsoSecretReplace")}
                      onChange={(e) =>
                        updateForm({ clientSecret: e.target.value })
                      }
                      end={
                        <InputButton
                          onClick={() =>
                            updateForm({ clientSecret: "", clearSecret: true })
                          }
                        >
                          {t("adminSsoSecretClear")}
                        </InputButton>
                      }
                    />
                  </Field>
                ) : (
                  <Field
                    label={t("adminSsoClientSecret")}
                    aside={t("adminSsoOptional")}
                    help={t("adminSsoSecretPhoneHelp")}
                  >
                    <PasswordInput
                      value={form.clientSecret}
                      placeholder={t("adminSsoSecretPhonePlaceholder")}
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
                  {provider
                    ? t("adminSsoOnly", { provider })
                    : t("adminSsoOnlyUnnamed")}
                </label>
                <span className="text-meta text-muted-foreground">
                  {t("adminSsoOnlyHelp")}
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
                <b className="font-semibold text-meta">
                  {t("adminSsoCallbackUrl")}
                </b>
                <Input
                  readOnly
                  mono
                  aria-label={t("adminSsoCallbackUrl")}
                  value={settings.callbackUrl}
                  boxClassName="bg-card"
                  end={
                    <InputButton
                      onClick={() =>
                        copyText(settings.callbackUrl).then(
                          () => setCopied(true),
                          () => toast.error(t("adminSsoCopyFailed")),
                        )
                      }
                    >
                      {copied ? t("commonCopied") : t("commonCopy")}
                    </InputButton>
                  }
                />
                <FieldDescription>
                  {t.rich(
                    provider
                      ? "adminSsoCallbackHelp"
                      : "adminSsoCallbackHelpUnnamed",
                    {
                      provider,
                      variable: "APP_URL",
                      code: (chunks) => (
                        <code className="rounded-[5px] bg-foreground/7 px-1.25 py-px font-mono text-foreground text-small">
                          {chunks}
                        </code>
                      ),
                    },
                  )}
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
          <span className="flex-1">{t("adminSsoUnsaved")}</span>
          <Button
            variant="quiet"
            size="sm"
            className="text-inherit hover:bg-inverse-foreground/10"
            onClick={() => {
              setForm(saved);
              setErrors({});
            }}
          >
            {t("adminSsoDiscard")}
          </Button>
          <Button
            size="sm"
            className="bg-inverse-foreground bg-none text-inverse shadow-none hover:bg-inverse-foreground/90"
            onClick={submit}
            busy={save.isPending && t("uiSaving")}
          >
            {t("commonSave")}
          </Button>
        </div>
      )}
    </section>
  );
}
