"use client";

import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { Copy, Eye, EyeOff, KeyRound, RotateCw } from "lucide-react";
import * as React from "react";
import { Button } from "@/components/ui/button";
import { ConfirmationDialog } from "@/components/ui/confirmation-dialog";
import { LoadFailedRow } from "@/components/ui/empty-state";
import { FieldDescription } from "@/components/ui/field";
import { Input } from "@/components/ui/input";
import { Skeleton } from "@/components/ui/skeleton";
import { toast } from "@/components/ui/toast";
import { Tip } from "@/components/ui/tooltip";
import {
  getApiToken,
  regenerateApiToken,
  revokeApiToken,
} from "@/features/auth/api";
import { copyText } from "@/lib/clipboard";
import { useRetry } from "@/lib/hooks/use-retry";
import { popIconIn, revealText } from "@/lib/motion";
import { Row, RowText, Section } from "./settings-blocks";

const maskToken = (token: string) =>
  token.length <= 12
    ? "•".repeat(token.length)
    : `${token.slice(0, 8)}${"•".repeat(16)}${token.slice(-4)}`;

export function ApiTokenSection() {
  const queryClient = useQueryClient();
  const generateButtonId = React.useId();
  const [shown, setShown] = React.useState(false);
  const [confirming, setConfirming] = React.useState<
    "regenerate" | "revoke" | null
  >(null);
  const tokenQuery = useQuery({
    queryKey: ["api-token"],
    queryFn: getApiToken,
    staleTime: 5 * 60 * 1000,
  });
  const tokenRetry = useRetry(tokenQuery.refetch);
  const token = tokenQuery.data?.apiToken ?? null;
  const value = token && (shown ? token : maskToken(token));
  const tokenField = React.useRef<HTMLInputElement>(null);
  const eyeButton = React.useRef<HTMLButtonElement>(null);
  const lastValue = React.useRef(value);
  const lastShown = React.useRef(shown);

  React.useLayoutEffect(() => {
    const was = lastValue.current;
    lastValue.current = value;
    const from = was ?? (value && maskToken(value));
    if (tokenField.current && value && from && from !== value)
      revealText(tokenField.current, from);
  }, [value]);
  React.useLayoutEffect(() => {
    if (lastShown.current === shown) return;
    lastShown.current = shown;
    popIconIn(eyeButton.current?.querySelector("svg"));
  }, [shown]);

  const generate = useMutation({
    mutationFn: regenerateApiToken,
    onSuccess: (res) => {
      queryClient.setQueryData(["api-token"], res);
      setShown(true);
      setConfirming(null);
      toast.success(
        token
          ? "API token regenerated. Update it in your apps."
          : "API token generated",
      );
    },
    onError: () =>
      toast.error(
        token ? "Couldn’t regenerate the token" : "Couldn’t generate a token",
        { retry: () => generate.mutate() },
      ),
  });
  const revoke = useMutation({
    mutationFn: revokeApiToken,
    onSuccess: (res) => {
      queryClient.setQueryData(["api-token"], res);
      setShown(false);
      setConfirming(null);
      toast.success("API token revoked");
    },
    onError: () =>
      toast.error("Couldn’t revoke the token", {
        retry: () => revoke.mutate(),
      }),
  });

  const copy = () => {
    if (!token) return;
    copyText(token).then(
      () => toast.success("Token copied"),
      () => toast.error("Couldn’t copy the token"),
    );
  };

  return (
    <Section
      id="token"
      title="API token"
      description="Lets other apps read your notes."
    >
      {tokenQuery.isError || tokenRetry.isRetrying ? (
        <Row>
          <LoadFailedRow
            className="flex-1"
            message="Couldn’t load your token."
            onRetry={tokenRetry.retry}
            isRetrying={tokenRetry.isRetrying}
          />
        </Row>
      ) : tokenQuery.isLoading ? (
        <Row className="grid gap-3" aria-busy="true">
          <Skeleton className="h-field w-full rounded-field" />
          <Skeleton className="h-3 w-2/3" />
        </Row>
      ) : token ? (
        <Row className="grid gap-3.5">
          <Input
            ref={tokenField}
            readOnly
            mono
            aria-label="API token"
            value={value ?? ""}
            icon={<KeyRound aria-hidden />}
            end={
              <span className="-mr-1.5 flex gap-0.5">
                <Tip label={shown ? "Hide token" : "Show token"}>
                  <button
                    ref={eyeButton}
                    type="button"
                    aria-label={shown ? "Hide token" : "Show token"}
                    onClick={() => setShown((s) => !s)}
                    className="grid size-7 cursor-pointer place-items-center rounded-sm border-0 bg-transparent text-muted-foreground hover:bg-foreground/6 hover:text-foreground [&_svg]:size-4"
                  >
                    {shown ? <EyeOff aria-hidden /> : <Eye aria-hidden />}
                  </button>
                </Tip>
                <Tip label="Copy token">
                  <button
                    type="button"
                    aria-label="Copy token"
                    onClick={copy}
                    className="grid size-7 cursor-pointer place-items-center rounded-sm border-0 bg-transparent text-muted-foreground hover:bg-foreground/6 hover:text-foreground [&_svg]:size-4"
                  >
                    <Copy aria-hidden />
                  </button>
                </Tip>
              </span>
            }
          />
          <FieldDescription>
            Anyone with this token can read your notes. If it leaks, regenerate
            it.
          </FieldDescription>
          <div className="flex flex-wrap items-center gap-2">
            <Button
              variant="secondary"
              onClick={() => setConfirming("regenerate")}
            >
              <RotateCw aria-hidden />
              Regenerate
            </Button>
            <Button variant="danger" onClick={() => setConfirming("revoke")}>
              Revoke
            </Button>
          </div>
        </Row>
      ) : (
        <Row>
          <RowText
            title="No token"
            text="Generate one when an app asks for it."
          />
          <Button
            id={generateButtonId}
            variant="secondary"
            onClick={() => generate.mutate()}
            busy={generate.isPending && "Generating…"}
          >
            <KeyRound aria-hidden />
            Generate token
          </Button>
        </Row>
      )}
      <ConfirmationDialog
        open={confirming === "regenerate"}
        onOpenChange={(open) => !open && setConfirming(null)}
        title="Regenerate the API token?"
        description="The current token will stop working right away. Apps that use it will need the new one."
        confirmLabel="Regenerate"
        busyLabel="Regenerating…"
        variant="primary"
        isPending={generate.isPending}
        onConfirm={() => generate.mutate()}
      />
      <ConfirmationDialog
        open={confirming === "revoke"}
        onOpenChange={(open) => !open && setConfirming(null)}
        title="Revoke the API token?"
        description="Apps that use it will lose access to your notes. You can generate a new token at any time."
        confirmLabel="Revoke"
        busyLabel="Revoking…"
        variant="destructive"
        isPending={revoke.isPending}
        onConfirm={() => revoke.mutate()}
        fallbackFocus={() => document.getElementById(generateButtonId)}
      />
    </Section>
  );
}
