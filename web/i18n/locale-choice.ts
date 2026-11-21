"use client";

import { useRouter } from "next/navigation";
import { useLocale } from "next-intl";
import { useCallback, useSyncExternalStore } from "react";
import {
  isLocale,
  LOCALE_COOKIE,
  LOCALES,
  type Locale,
  localeOf,
} from "./locales";

/** A language's name in that language, capitalized as in a menu: "Français". */
export function languageName(locale: string): string {
  const name =
    new Intl.DisplayNames([locale], { type: "language" }).of(locale) ?? locale;
  return name.charAt(0).toLocaleUpperCase(locale) + name.slice(1);
}

function pickedLocale(): Locale | null {
  const value = document.cookie
    .split("; ")
    .find((part) => part.startsWith(`${LOCALE_COOKIE}=`))
    ?.split("=")[1];
  return isLocale(value) ? value : null;
}

const listeners = new Set<() => void>();

function subscribe(listener: () => void) {
  listeners.add(listener);
  return () => {
    listeners.delete(listener);
  };
}

/** `picked` is null while the browser's languages decide. */
export function useLocaleChoice() {
  const router = useRouter();
  const current = localeOf(useLocale());
  const picked = useSyncExternalStore(subscribe, pickedLocale, () => null);
  const choose = useCallback(
    (locale: Locale | null) => {
      // biome-ignore lint/suspicious/noDocumentCookie: the server reads this cookie
      document.cookie =
        locale === null
          ? `${LOCALE_COOKIE}=; path=/; max-age=0; samesite=lax`
          : `${LOCALE_COOKIE}=${locale}; path=/; max-age=31536000; samesite=lax`;
      for (const listener of listeners) listener();
      router.refresh();
    },
    [router],
  );
  return {
    locales: LOCALES,
    current,
    picked,
    hasChoice: LOCALES.length > 1,
    choose,
  };
}
