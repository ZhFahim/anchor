import { CircleAlert, CloudOff, RotateCw } from "lucide-react";
import type * as React from "react";
import { Button } from "@/components/ui/button";
import { cn } from "@/lib/utils";

type EmptyIllustrationKind = "notes" | "search" | "archive" | "trash";

function EmptyIllustration({
  kind,
  className,
}: {
  kind: EmptyIllustrationKind;
  className?: string;
}) {
  const strokeProps = {
    stroke: "var(--muted-foreground)",
    strokeWidth: 2.2,
    fill: "none",
    strokeLinecap: "round",
    strokeLinejoin: "round",
  } as const;
  return (
    <svg
      viewBox="0 0 132 96"
      aria-hidden
      className={cn("h-24 w-33", className)}
    >
      <g data-note="color_yellow">
        <rect
          x="14"
          y="20"
          width="52"
          height="62"
          rx="10"
          transform="rotate(-9 40 51)"
          fill="var(--note)"
          stroke="var(--note-border)"
        />
      </g>
      <g data-note="color_blue">
        <rect
          x="72"
          y="16"
          width="50"
          height="60"
          rx="10"
          transform="rotate(8 97 46)"
          fill="var(--note)"
          stroke="var(--note-border)"
        />
      </g>
      <rect
        x="44"
        y="26"
        width="56"
        height="64"
        rx="11"
        fill="var(--card)"
        stroke="var(--border)"
      />
      <path
        d="M44 37a11 11 0 0 1 11-11h34a11 11 0 0 1 11 11v2H44z"
        fill="var(--accent)"
      />
      {kind === "notes" && (
        <path
          d="M58 44h26M58 52h20M58 60h24"
          {...strokeProps}
          strokeWidth={2.4}
        />
      )}
      {kind === "search" && (
        <>
          <circle cx="72" cy="54" r="9" {...strokeProps} strokeWidth={2.4} />
          <path d="M79 61l6 6" {...strokeProps} strokeWidth={2.4} />
        </>
      )}
      {kind === "archive" && (
        <>
          <path d="M60 46h24v6H60zM62 52h20v14H62z" {...strokeProps} />
          <path d="M69 57h6" {...strokeProps} />
        </>
      )}
      {kind === "trash" && (
        <path
          d="M61 47h22M68 47v-3h8v3M63 47l1.5 19h15L81 47"
          {...strokeProps}
        />
      )}
    </svg>
  );
}

interface EmptyStateProps {
  illustration?: EmptyIllustrationKind;
  icon?: React.ReactNode;
  title: React.ReactNode;
  children?: React.ReactNode;
  action?: React.ReactNode;
  size?: "default" | "sm";
  className?: string;
}

export function EmptyState({
  illustration,
  icon,
  title,
  children,
  action,
  size = "default",
  className,
}: EmptyStateProps) {
  const small = size === "sm";
  return (
    <div
      className={cn(
        "mx-auto grid max-w-95 justify-items-center gap-2 text-center",
        small ? "gap-1.5 px-3 pt-5 pb-4" : "px-5 pt-14 pb-10",
        className,
      )}
    >
      {illustration && (
        <EmptyIllustration kind={illustration} className="mb-2" />
      )}
      {icon && (
        <span className="mb-1 text-muted-foreground [&_svg]:size-6.5">
          {icon}
        </span>
      )}
      <h2
        className={cn(
          "m-0",
          small ? "font-semibold text-lead" : "text-heading",
        )}
      >
        {title}
      </h2>
      {children && (
        <p
          className={cn(
            "m-0 text-muted-foreground",
            small ? "text-meta" : "text-ui",
          )}
        >
          {children}
        </p>
      )}
      {action && <div className="mt-2.5">{action}</div>}
    </div>
  );
}

export function LoadFailedRow({
  message,
  onRetry,
  isRetrying = false,
  className,
}: {
  message: string;
  onRetry: () => void;
  isRetrying?: boolean;
  className?: string;
}) {
  return (
    <div
      role="alert"
      className={cn(
        "flex flex-wrap items-center gap-2.5 rounded-lg bg-muted py-2.5 pr-2.5 pl-3.5 text-foreground text-meta",
        className,
      )}
    >
      <CloudOff
        aria-hidden
        className="size-4 flex-none text-muted-foreground"
      />
      <span className="min-w-0 flex-1">{message}</span>
      <Button
        variant="secondary"
        size="sm"
        onClick={onRetry}
        busy={isRetrying && "Trying again…"}
      >
        <RotateCw aria-hidden />
        Try again
      </Button>
    </div>
  );
}

export function LoadFailedState({
  title,
  onRetry,
  isRetrying = false,
}: {
  title: string;
  onRetry: () => void;
  isRetrying?: boolean;
}) {
  return (
    <div role="alert">
      <EmptyState
        icon={<CircleAlert />}
        title={title}
        action={
          <Button
            variant="secondary"
            onClick={onRetry}
            busy={isRetrying && "Trying again…"}
          >
            <RotateCw aria-hidden />
            Try again
          </Button>
        }
      >
        Check your connection, then try again.
      </EmptyState>
    </div>
  );
}
