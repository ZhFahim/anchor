"use client";

import { cva, type VariantProps } from "class-variance-authority";
import * as React from "react";
import { useFieldControl } from "@/components/ui/field";
import { cn } from "@/lib/utils";

const inputBoxVariants = cva(
  "flex min-w-0 items-center gap-2 rounded-field bg-(--field-bg) px-3 shadow-[inset_0_0_0_1px_var(--input)] [--field-bg:var(--card)] dark:[--field-bg:color-mix(in_srgb,var(--background)_65%,var(--card))] transition-shadow duration-(--duration-hover) hover:not-focus-within:shadow-[inset_0_0_0_1px_var(--muted-foreground)] focus-within:shadow-[inset_0_0_0_2px_var(--ring)] has-[input[aria-invalid=true]]:not-focus-within:shadow-[inset_0_0_0_2px_var(--destructive)] has-[input:disabled]:opacity-50 [&>svg]:size-4 [&>svg]:text-muted-foreground focus-within:[&>svg]:text-foreground",
  {
    variants: {
      size: {
        default: "h-field",
        lg: "h-field-large rounded-lg",
        sm: "h-9",
      },
    },
    defaultVariants: { size: "default" },
  },
);

type InputProps = Omit<React.ComponentProps<"input">, "size"> &
  VariantProps<typeof inputBoxVariants> & {
    icon?: React.ReactNode;
    end?: React.ReactNode;
    mono?: boolean;
    boxClassName?: string;
  };

const Input = React.forwardRef<HTMLInputElement, InputProps>(
  (
    {
      className,
      boxClassName,
      size,
      icon,
      end,
      mono,
      readOnly,
      id,
      "aria-invalid": ariaInvalid,
      "aria-describedby": ariaDescribedBy,
      ...props
    },
    ref,
  ) => {
    const field = useFieldControl();
    return (
      <div
        data-slot="input"
        className={cn(
          inputBoxVariants({ size }),
          readOnly &&
            "bg-[color-mix(in_srgb,var(--foreground)_3%,var(--card))] shadow-[inset_0_0_0_1px_var(--border)] hover:shadow-[inset_0_0_0_1px_var(--border)]",
          boxClassName,
        )}
      >
        {icon}
        <input
          ref={ref}
          id={id ?? field?.id}
          readOnly={readOnly}
          spellCheck={false}
          aria-invalid={field?.invalid || ariaInvalid || undefined}
          aria-describedby={
            [field?.describedBy, ariaDescribedBy].filter(Boolean).join(" ") ||
            undefined
          }
          className={cn(
            "h-full min-w-0 flex-1 border-0 bg-transparent p-0 text-ui text-foreground outline-none placeholder:text-muted-foreground focus-visible:outline-none disabled:cursor-not-allowed [&::-webkit-search-cancel-button]:hidden",
            mono &&
              "font-mono text-meta tracking-[.01em] placeholder:font-sans placeholder:text-ui placeholder:tracking-normal",
            className,
          )}
          {...props}
        />
        {end}
      </div>
    );
  },
);
Input.displayName = "Input";

function InputButton({ className, ...props }: React.ComponentProps<"button">) {
  return (
    <button
      type="button"
      className={cn(
        "-mr-1.5 h-7 flex-none cursor-pointer rounded-sm bg-foreground/6 px-2.5 font-semibold text-small transition-colors duration-(--duration-hover) hover:bg-foreground/10",
        className,
      )}
      {...props}
    />
  );
}

const PasswordInput = React.forwardRef<
  HTMLInputElement,
  Omit<InputProps, "type" | "end">
>((props, ref) => {
  const [shown, setShown] = React.useState(false);
  const field = useFieldControl();
  return (
    <Input
      ref={ref}
      type={shown ? "text" : "password"}
      end={
        <InputButton
          aria-label={shown ? "Hide password" : "Show password"}
          aria-controls={props.id ?? field?.id}
          onClick={() => setShown((v) => !v)}
        >
          {shown ? "Hide" : "Show"}
        </InputButton>
      }
      {...props}
    />
  );
});
PasswordInput.displayName = "PasswordInput";

export { Input, InputButton, PasswordInput };
