import { useSyncExternalStore } from "react";

const PHONE_QUERY = "(width < 768px)";

export const isPhoneWidth = () => window.matchMedia(PHONE_QUERY).matches;

const watchPhoneWidth = (onChange: () => void) => {
  const query = window.matchMedia(PHONE_QUERY);
  query.addEventListener("change", onChange);
  return () => query.removeEventListener("change", onChange);
};

export const useIsPhone = () =>
  useSyncExternalStore(watchPhoneWidth, isPhoneWidth, () => false);
