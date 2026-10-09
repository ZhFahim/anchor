import { Lock } from "lucide-react";
import type * as React from "react";

export const cardClass =
  "rounded-2xl bg-card shadow-[0_0_0_1px_color-mix(in_srgb,var(--border)_60%,transparent)]";

export function LockNote({ children }: { children: React.ReactNode }) {
  return (
    <div className="flex items-start gap-2.5 rounded-lg bg-muted px-3 py-2.5 text-meta text-muted-foreground leading-normal [&_code]:rounded-[5px] [&_code]:bg-foreground/7 [&_code]:px-1.25 [&_code]:py-px [&_code]:font-mono [&_code]:text-foreground [&_code]:text-small [&>svg]:mt-px [&>svg]:size-4 [&>svg]:flex-none">
      <Lock aria-hidden />
      <span>{children}</span>
    </div>
  );
}
