import { cn } from "@/lib/utils";

export function StatusRing({
  remaining = 1,
  turning = false,
}: {
  remaining?: number;
  turning?: boolean;
}) {
  return (
    <svg
      viewBox="0 0 20 20"
      aria-hidden
      className={cn("size-4 -rotate-90", turning && "animate-spin")}
    >
      <circle
        cx="10"
        cy="10"
        r="8"
        fill="none"
        stroke="var(--muted)"
        strokeWidth="2.5"
      />
      <circle
        cx="10"
        cy="10"
        r="8"
        fill="none"
        stroke="var(--accent-strong)"
        strokeWidth="2.5"
        strokeLinecap="round"
        pathLength={100}
        strokeDasharray={turning ? "25 75" : 100}
        strokeDashoffset={turning ? 0 : 100 - remaining * 100}
        className={
          turning
            ? undefined
            : "transition-[stroke-dashoffset] duration-1000 ease-linear"
        }
      />
    </svg>
  );
}
