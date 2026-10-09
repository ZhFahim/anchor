"use client";

import { ArrowLeft, CircleAlert, Info } from "lucide-react";
import Link from "next/link";
import type * as React from "react";
import { Button } from "@/components/ui/button";
import {
  StateIllustration,
  type StateIllustrationKind,
} from "@/components/ui/state-illustration";
import { cn } from "@/lib/utils";

export function AuthHeading({
  title,
  sub,
}: {
  title: string;
  sub?: React.ReactNode;
}) {
  return (
    <div className="-mb-1.5 grid gap-1">
      <h1 className="m-0 mt-3.5 text-display">{title}</h1>
      {sub && <p className="m-0 text-lead text-muted-foreground">{sub}</p>}
    </div>
  );
}

export function AuthMessage({
  tone = "error",
  children,
  action,
}: {
  tone?: "error" | "info";
  children: React.ReactNode;
  action?: React.ReactNode;
}) {
  return (
    <div
      role={tone === "error" ? "alert" : "status"}
      className={cn(
        "flex items-start gap-2.5 rounded-lg p-3 text-control leading-normal [&>svg]:mt-0.5 [&>svg]:size-4 [&>svg]:flex-none",
        tone === "error"
          ? "bg-[color-mix(in_srgb,var(--destructive)_9%,var(--card))] text-destructive"
          : "bg-muted text-foreground [&>svg]:text-muted-foreground",
      )}
    >
      {tone === "error" ? <CircleAlert aria-hidden /> : <Info aria-hidden />}
      <span className="flex-1">{children}</span>
      {action}
    </div>
  );
}

export const linkButtonClass =
  "cursor-pointer border-0 bg-transparent p-0 font-semibold text-accent-ink underline decoration-current/35 underline-offset-3 hover:decoration-current";

export function OrDivider() {
  return (
    <div className="flex items-center gap-3 text-muted-foreground text-small before:h-px before:flex-1 before:bg-border/80 after:h-px after:flex-1 after:bg-border/80">
      or
    </div>
  );
}

export function AuthStatusScreen({
  illustration,
  title,
  text,
  children,
}: {
  illustration: StateIllustrationKind;
  title: string;
  text: React.ReactNode;
  children: React.ReactNode;
}) {
  return (
    <div className="grid gap-2.5">
      <StateIllustration kind={illustration} className="-ml-6.5 mb-1.5 w-46" />
      <h1 className="m-0 text-display">{title}</h1>
      <p className="m-0 text-lead text-muted-foreground">{text}</p>
      <div className="mt-3.5 grid gap-2">{children}</div>
    </div>
  );
}

export function PendingApprovalScreen({ onBack }: { onBack?: () => void }) {
  const back = (
    <>
      <ArrowLeft aria-hidden />
      Back to sign in
    </>
  );
  return (
    <AuthStatusScreen
      illustration="waiting"
      title="You’re on the list"
      text="An admin needs to approve your account. Try signing in again later."
    >
      {onBack ? (
        <Button
          size="lg"
          variant="secondary"
          className="w-full"
          onClick={onBack}
        >
          {back}
        </Button>
      ) : (
        <Button size="lg" variant="secondary" className="w-full" asChild>
          <Link href="/login">{back}</Link>
        </Button>
      )}
    </AuthStatusScreen>
  );
}
