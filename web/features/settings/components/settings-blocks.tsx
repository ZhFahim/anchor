"use client";

import { Check, CircleAlert, LoaderCircle } from "lucide-react";
import * as React from "react";
import { cn } from "@/lib/utils";

export type SaveState = "idle" | "saving" | "saved" | "failed";

export function SectionHeader({
  id,
  title,
  description,
  saved,
}: {
  id?: string;
  title: React.ReactNode;
  description?: string;
  saved?: React.ReactNode;
}) {
  return (
    <header className="grid gap-0.5 px-1">
      <h2
        id={id}
        className={cn(
          "m-0 text-title",
          saved !== undefined && "flex items-center gap-2.5",
        )}
      >
        {title}
        {saved}
      </h2>
      {description && (
        <p className="m-0 text-control text-muted-foreground">{description}</p>
      )}
    </header>
  );
}

export function Section({
  id,
  title,
  description,
  children,
}: {
  id: string;
  title: string;
  description?: string;
  children: React.ReactNode;
}) {
  return (
    <section
      id={`set-${id}`}
      aria-labelledby={`set-${id}-h`}
      className="grid scroll-mt-4 gap-2.5"
    >
      <SectionHeader
        id={`set-${id}-h`}
        title={title}
        description={description}
      />
      <div className="rounded-2xl bg-card shadow-[0_0_0_1px_color-mix(in_srgb,var(--border)_60%,transparent),var(--sh-xs)] [&>*+*]:border-border/55 [&>*+*]:border-t">
        {children}
      </div>
    </section>
  );
}

export function Row({ className, ...props }: React.ComponentProps<"div">) {
  return (
    <div
      className={cn(
        "flex min-w-0 flex-wrap items-center gap-4 px-5 py-4 max-md:p-3.5",
        className,
      )}
      {...props}
    />
  );
}

export function RowText({
  title,
  text,
  saved,
}: {
  title: React.ReactNode;
  text?: React.ReactNode;
  saved?: React.ReactNode;
}) {
  return (
    <div className="grid min-w-50 flex-1 gap-0.5">
      <b className="flex flex-wrap items-center gap-x-2.5 font-semibold text-ui">
        {title}
        {saved}
      </b>
      {text && (
        <span className="text-meta text-muted-foreground leading-[1.45]">
          {text}
        </span>
      )}
    </div>
  );
}

export function SaveStatus({
  state,
  onRetry,
}: {
  state: SaveState;
  onRetry?: () => void;
}) {
  if (state === "saved")
    return (
      <span
        role="status"
        className="inline-flex animate-fade-in items-center gap-1 font-medium text-added-ink text-small [&_svg]:size-3.5"
      >
        <Check aria-hidden />
        Saved
      </span>
    );
  if (state === "saving")
    return (
      <span
        role="status"
        className="inline-flex items-center gap-1 font-medium text-muted-foreground text-small [&_svg]:size-3.5"
      >
        <LoaderCircle aria-hidden className="animate-spin" />
        Saving…
      </span>
    );
  if (state === "failed")
    return (
      <span
        role="alert"
        className="inline-flex items-center gap-1.5 font-medium text-destructive text-small [&_svg]:size-3.5"
      >
        <CircleAlert aria-hidden />
        Couldn’t save
        {onRetry && (
          <button
            type="button"
            onClick={onRetry}
            className="cursor-pointer border-0 bg-transparent p-0 font-semibold text-foreground underline decoration-current/35 underline-offset-3 hover:decoration-current"
          >
            Try again
          </button>
        )}
      </span>
    );
  return null;
}

export function useSaveStatus() {
  const [state, setState] = React.useState<SaveState>("idle");
  React.useEffect(() => {
    if (state !== "saved") return;
    const timer = window.setTimeout(() => setState("idle"), 2400);
    return () => window.clearTimeout(timer);
  }, [state]);
  return [state, setState] as const;
}
