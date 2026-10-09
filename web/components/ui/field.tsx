"use client";

import { CircleAlert, Info } from "lucide-react";
import * as React from "react";
import { cn } from "@/lib/utils";

interface FieldContextValue {
  id: string;
  describedBy?: string;
  invalid: boolean;
}

const FieldContext = React.createContext<FieldContextValue | null>(null);

export function useFieldControl() {
  return React.useContext(FieldContext);
}

interface FieldProps {
  label?: React.ReactNode;
  aside?: React.ReactNode;
  help?: React.ReactNode;
  error?: React.ReactNode;
  id?: string;
  className?: string;
  children: React.ReactNode;
}

export function Field({
  label,
  aside,
  help,
  error,
  id,
  className,
  children,
}: FieldProps) {
  const generatedId = React.useId();
  const controlId = id ?? generatedId;
  const messageId = `${controlId}-note`;
  const message = error || help;
  return (
    <FieldContext.Provider
      value={{
        id: controlId,
        describedBy: message ? messageId : undefined,
        invalid: !!error,
      }}
    >
      <div
        data-slot="field"
        className={cn("grid min-w-0 content-start gap-2", className)}
      >
        {label && (
          <label
            htmlFor={controlId}
            className="flex items-baseline justify-between gap-2 font-semibold text-foreground text-meta"
          >
            {label}
            {aside && (
              <span className="font-medium text-muted-foreground text-small">
                {aside}
              </span>
            )}
          </label>
        )}
        {children}
        {error ? (
          <FieldError id={messageId}>{error}</FieldError>
        ) : help ? (
          <FieldDescription id={messageId}>{help}</FieldDescription>
        ) : null}
      </div>
    </FieldContext.Provider>
  );
}

export function FieldDescription({
  className,
  ...props
}: React.ComponentProps<"p">) {
  return (
    <p
      className={cn(
        "m-0 text-muted-foreground text-small leading-normal",
        className,
      )}
      {...props}
    />
  );
}

export function FieldError({
  className,
  children,
  ...props
}: React.ComponentProps<"p">) {
  return (
    <p
      role="alert"
      className={cn(
        "m-0 flex items-start gap-1.5 font-medium text-destructive text-small leading-[1.45] [&>svg]:mt-px [&>svg]:size-3.5 [&>svg]:flex-none",
        className,
      )}
      {...props}
    >
      <CircleAlert aria-hidden />
      <span>{children}</span>
    </p>
  );
}

export function FormAlert({
  tone = "error",
  action,
  className,
  children,
}: {
  tone?: "error" | "info";
  action?: React.ReactNode;
  className?: string;
  children: React.ReactNode;
}) {
  return (
    <div
      role={tone === "error" ? "alert" : "status"}
      className={cn(
        "flex items-start gap-2.5 rounded-lg p-3 text-control leading-normal [&>svg]:mt-0.5 [&>svg]:size-4 [&>svg]:flex-none",
        tone === "error"
          ? "bg-[color-mix(in_srgb,var(--destructive)_9%,var(--card))] text-destructive"
          : "bg-muted text-foreground [&>svg]:text-muted-foreground",
        className,
      )}
    >
      {tone === "error" ? <CircleAlert aria-hidden /> : <Info aria-hidden />}
      <span className="min-w-0 flex-1">{children}</span>
      {action}
    </div>
  );
}
