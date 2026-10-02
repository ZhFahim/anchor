import { useState } from "react";

export function useLastShown<T>(value: T, isShown: boolean): T {
  const [shown, setShown] = useState(value);
  if (isShown && !Object.is(shown, value)) setShown(value);
  return isShown ? value : shown;
}
