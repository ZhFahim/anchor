import { cn } from "@/lib/utils";

function ShortcutHints({
  groups,
  screenReaderText,
  className,
}: {
  groups: [string[], string][];
  screenReaderText: string;
  className?: string;
}) {
  return (
    <>
      <span
        aria-hidden
        className={cn(
          "flex flex-wrap items-center gap-x-2.5 gap-y-1",
          className,
        )}
      >
        {groups.map(([keys, word]) => (
          <span
            key={word}
            className="inline-flex items-center gap-0.75 whitespace-nowrap"
          >
            {keys.map((k) => (
              <kbd
                key={k}
                className="h-4.25 min-w-4.25 rounded-[5px] px-1 font-semibold text-[10.5px] text-foreground shadow-[inset_0_-1px_0_color-mix(in_srgb,var(--foreground)_10%,transparent)]"
              >
                {k}
              </kbd>
            ))}{" "}
            {word}
          </span>
        ))}
      </span>
      <span className="sr-only">{screenReaderText}</span>
    </>
  );
}

export { ShortcutHints };
