export const LOCALES = ["en", "de"] as const;

export type Locale = (typeof LOCALES)[number];

export const DEFAULT_LOCALE: Locale = "en";

export const LOCALE_COOKIE = "locale";

export const isLocale = (value: string | undefined): value is Locale =>
  (LOCALES as readonly string[]).includes(value ?? "");

function tagsOf(header: string | null): string[] {
  return (header ?? "")
    .split(",")
    .map((part) => {
      const [tag, ...options] = part.trim().split(";");
      const quality = options.find((option) => option.trim().startsWith("q="));
      return {
        tag: tag.trim(),
        q: quality ? Number(quality.split("=")[1]) : 1,
      };
    })
    .filter(({ tag, q }) => tag && tag !== "*" && q > 0)
    .sort((a, b) => b.q - a.q)
    .map(({ tag }) => tag);
}

/**
 * The first language from an Accept-Language header that the app has, by exact
 * tag and then by language alone (`pt-PT` takes `pt`, `pt` takes `pt-BR`).
 */
export function localeFromHeader(header: string | null): Locale {
  for (const tag of tagsOf(header).map((wanted) => wanted.toLowerCase())) {
    const exact = LOCALES.find((locale) => locale.toLowerCase() === tag);
    if (exact) return exact;
    const language = tag.split("-")[0];
    const near = LOCALES.find(
      (locale) => locale.toLowerCase().split("-")[0] === language,
    );
    if (near) return near;
  }
  return DEFAULT_LOCALE;
}

function isFormattable(tag: string): boolean {
  try {
    return Intl.DateTimeFormat.supportedLocalesOf([tag]).length > 0;
  } catch {
    return false;
  }
}

/** The browser's tag in [locale]'s language, such as en-GB, for dates and numbers. */
export function regionalTag(locale: Locale, header: string | null): string {
  if (locale.includes("-")) return locale;
  const regional = tagsOf(header).find(
    (tag) => tag.toLowerCase().split("-")[0] === locale && isFormattable(tag),
  );
  return regional ?? locale;
}

/** The longest app language a tag belongs to: de-AT is de, pt-BR is pt-BR. */
export function localeOf(tag: string): Locale {
  const wanted = tag.toLowerCase();
  return (
    [...LOCALES]
      .sort((a, b) => b.length - a.length)
      .find(
        (locale) =>
          wanted === locale.toLowerCase() ||
          wanted.startsWith(`${locale.toLowerCase()}-`),
      ) ?? DEFAULT_LOCALE
  );
}
