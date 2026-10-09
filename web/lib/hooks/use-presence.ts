import { useEffect, useState } from "react";

/** `leaving` stays set until the element calls `done` at the end of its exit. */
export function usePresence(open: boolean) {
  const [mounted, setMounted] = useState(open);
  useEffect(() => {
    if (open) setMounted(true);
  }, [open]);
  return {
    mounted: open || mounted,
    leaving: !open && mounted,
    done: () => !open && setMounted(false),
  };
}
