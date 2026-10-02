"use client";

import { StatusRing } from "@/components/ui/status-ring";
import { useDelayedFlag } from "@/lib/hooks/use-delayed-flag";
import { AnchorLogo } from "./brand";

export function SplashScreen({ checking }: { checking: boolean }) {
  const isSlow = useDelayedFlag(checking, 3000);
  return (
    <div
      role="status"
      aria-label="Loading Anchor"
      className="grid min-h-dvh place-items-center bg-background"
    >
      <div className="relative grid place-items-center">
        <AnchorLogo className="size-11 rounded-[11px] shadow-sm animate-splash" />
        {isSlow && (
          <p className="absolute top-full m-0 mt-5 inline-flex animate-fade-in items-center gap-2 whitespace-nowrap text-meta text-muted-foreground">
            <StatusRing turning />
            Connecting…
          </p>
        )}
      </div>
    </div>
  );
}
