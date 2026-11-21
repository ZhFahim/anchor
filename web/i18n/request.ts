import { cookies, headers } from "next/headers";
import { getRequestConfig } from "next-intl/server";
import english from "../messages/en.json";
import {
  DEFAULT_LOCALE,
  isLocale,
  LOCALE_COOKIE,
  type Locale,
  localeFromHeader,
  regionalTag,
} from "./locales";
import { withoutNotes } from "./messages";

async function catalogOf(locale: Locale): Promise<Record<string, unknown>> {
  if (locale === DEFAULT_LOCALE) return english;
  return (await import(`../messages/${locale}.json`)).default;
}

/**
 * The picked language, else the browser's; English fills any message a
 * language lacks. Dates and numbers keep the browser's region.
 */
export default getRequestConfig(async () => {
  const picked = (await cookies()).get(LOCALE_COOKIE)?.value;
  const header = (await headers()).get("accept-language");
  const locale = isLocale(picked) ? picked : localeFromHeader(header);
  return {
    locale: regionalTag(locale, header),
    messages: {
      ...withoutNotes(english),
      ...withoutNotes(await catalogOf(locale)),
    },
  };
});
