import { useState } from "react";

export function useRetry(refetch: () => Promise<unknown>) {
  const [isRetrying, setIsRetrying] = useState(false);
  const retry = () => {
    setIsRetrying(true);
    refetch().finally(() => setIsRetrying(false));
  };
  return { isRetrying, retry };
}
