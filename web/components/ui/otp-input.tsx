"use client";

import * as React from "react";
import {
  backspaceOtp,
  editOtp,
  isOtpComplete,
  OTP_LENGTH,
} from "@/features/auth/utils/otp";
import { cn } from "@/lib/utils";

export interface OtpInputHandle {
  focus: () => void;
}

interface OtpInputProps {
  value: string;
  onChange: (value: string) => void;
  /** Once, by the change that fills the last box. */
  onComplete?: (value: string) => void;
  /** Names the group for a screen reader: “Authenticator code”. */
  label: string;
  disabled?: boolean;
  invalid?: boolean;
  autoFocus?: boolean;
  className?: string;
  ref?: React.Ref<OtpInputHandle>;
}

const BOXES = Array.from({ length: OTP_LENGTH }, (_, i) => i);

/** Six boxes for a one-time code. Typing, pasting and autofill all fill them in order. */
export function OtpInput({
  value,
  onChange,
  onComplete,
  label,
  disabled,
  invalid,
  autoFocus,
  className,
  ref,
}: OtpInputProps) {
  const boxes = React.useRef<(HTMLInputElement | null)[]>([]);
  const focusBox = (index: number) => boxes.current[index]?.focus();
  // Focus moves before the next render, so the boxes read the value from here.
  const latest = React.useRef(value);
  latest.current = value;

  React.useImperativeHandle(
    ref,
    () => ({
      focus: () =>
        boxes.current[Math.min(value.length, OTP_LENGTH - 1)]?.focus(),
    }),
    [value],
  );
  React.useEffect(() => {
    if (autoFocus) boxes.current[0]?.focus();
  }, [autoFocus]);

  const apply = (edit: { value: string; focus: number }) => {
    if (edit.value === value) return focusBox(edit.focus);
    latest.current = edit.value;
    onChange(edit.value);
    focusBox(edit.focus);
    // From the change itself, not an effect: a code is sent once, however
    // the component renders.
    if (isOtpComplete(edit.value)) onComplete?.(edit.value);
  };

  return (
    // biome-ignore lint/a11y/useSemanticElements: a group of inputs, not a fieldset
    <div
      role="group"
      aria-label={label}
      className={cn("grid grid-cols-6 gap-2.5 max-md:gap-2", className)}
    >
      {BOXES.map((index) => (
        <input
          key={index}
          ref={(el) => {
            boxes.current[index] = el;
          }}
          type="text"
          inputMode="numeric"
          pattern="[0-9]*"
          autoComplete="one-time-code"
          autoCorrect="off"
          spellCheck={false}
          enterKeyHint="done"
          aria-label={`${label}, digit ${index + 1} of ${OTP_LENGTH}`}
          aria-invalid={invalid || undefined}
          disabled={disabled}
          value={value[index] ?? ""}
          onChange={(e) => apply(editOtp(value, index, e.target.value))}
          onPaste={(e) => {
            e.preventDefault();
            apply(editOtp(value, index, e.clipboardData.getData("text")));
          }}
          onKeyDown={(e) => {
            if (e.key === "Backspace" && !value[index] && index > 0) {
              e.preventDefault();
              apply(backspaceOtp(value, index));
            } else if (e.key === "ArrowLeft" && index > 0) {
              e.preventDefault();
              focusBox(index - 1);
            } else if (e.key === "ArrowRight" && index < value.length) {
              e.preventDefault();
              focusBox(index + 1);
            }
          }}
          onFocus={(e) => {
            // Keep the code in one run: a click past the end goes to the next free box.
            if (index > latest.current.length) focusBox(latest.current.length);
            else e.target.select();
          }}
          className="h-15 w-full min-w-0 rounded-field bg-(--field-bg) p-0 text-center font-semibold text-foreground text-display tabular-nums shadow-[inset_0_0_0_1px_var(--input)] outline-none transition-shadow duration-(--duration-hover) [--field-bg:var(--card)] hover:not-focus:shadow-[inset_0_0_0_1px_var(--muted-foreground)] focus:shadow-[inset_0_0_0_2px_var(--ring)] disabled:cursor-not-allowed disabled:opacity-50 aria-invalid:not-focus:shadow-[inset_0_0_0_2px_var(--destructive)] max-md:h-13 dark:[--field-bg:color-mix(in_srgb,var(--background)_65%,var(--card))]"
        />
      ))}
    </div>
  );
}
