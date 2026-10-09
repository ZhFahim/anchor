import { useEffect, useState } from "react";

export function useDelayedFlag(on: boolean, delayMs = 300): boolean {
  const [shown, setShown] = useState(false);

  useEffect(() => {
    if (!on) {
      setShown(false);
      return;
    }
    const timer = window.setTimeout(() => setShown(true), delayMs);
    return () => window.clearTimeout(timer);
  }, [on, delayMs]);

  return on && shown;
}
