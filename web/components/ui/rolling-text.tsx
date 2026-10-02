"use client";

import * as React from "react";
import { cn } from "@/lib/utils";

interface Line {
  text: string;
  key: number;
  out?: boolean;
}

export function RollingText({
  text,
  className,
}: {
  text: string;
  className?: string;
}) {
  const [lines, setLines] = React.useState<Line[]>([{ text, key: 0 }]);
  const lastText = React.useRef(text);
  React.useEffect(() => {
    if (text === lastText.current) return;
    lastText.current = text;
    setLines((prev) => [
      ...prev.slice(-1).map((line) => ({ ...line, out: true })),
      { text, key: (prev[prev.length - 1]?.key ?? 0) + 1 },
    ]);
  }, [text]);
  return (
    <span
      className={cn(
        "relative block h-[1.35em] overflow-hidden leading-[1.35em]",
        className,
      )}
    >
      {lines.map((line) => (
        <span
          key={line.key}
          aria-hidden={line.out || undefined}
          onAnimationEnd={() =>
            line.out &&
            setLines((prev) => prev.filter((other) => other.key !== line.key))
          }
          className={cn(
            "block truncate",
            line.out
              ? "absolute inset-0 animate-roll-out"
              : lines.length > 1 && "animate-roll-in",
          )}
        >
          {line.text}
        </span>
      ))}
    </span>
  );
}
