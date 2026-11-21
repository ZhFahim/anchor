"use client";

import { useTranslations } from "next-intl";
import { useTheme } from "next-themes";
import { RadioCards } from "@/components/ui/radio-cards";
import { LanguageMenu } from "@/i18n/language-menu";
import { LOCALES } from "@/i18n/locales";
import { switchTheme } from "@/lib/theme";
import { cn } from "@/lib/utils";
import { Row, RowText, Section } from "./settings-blocks";

function ThemeThumb({ theme }: { theme: "light" | "dark" }) {
  return (
    <div
      className={cn(
        theme,
        "grid h-full grid-cols-[28%_1fr] bg-background text-foreground",
      )}
    >
      <i className="block bg-sidebar" />
      <em className="grid content-start gap-1 p-2 not-italic">
        <s className="block h-1.25 w-3/5 rounded-xs bg-current no-underline opacity-40" />
        <s className="block h-1.25 rounded-xs bg-current no-underline opacity-22" />
        <s className="block h-1.25 rounded-xs bg-current no-underline opacity-22" />
      </em>
    </div>
  );
}

const hasLanguages = LOCALES.length > 1;

export function AppearanceSection() {
  const t = useTranslations();
  const { theme = "system", setTheme } = useTheme();
  const frameClass =
    "relative mb-2 h-16 overflow-hidden rounded-md shadow-[inset_0_0_0_1px_color-mix(in_srgb,var(--border)_80%,transparent)]";
  return (
    <Section id="appearance" title={t("settingsAppearance")}>
      <Row className="grid items-start gap-3.5">
        <RowText title={t("settingsTheme")} text={t("settingsThemeHelp")} />
        <RadioCards
          aria-label={t("settingsTheme")}
          value={theme as "light" | "dark" | "system"}
          onValueChange={(v) => switchTheme(v, setTheme)}
          className="grid-cols-3 max-md:grid-cols-1"
          options={[
            {
              value: "light",
              label: t("settingsThemeLight"),
              description: t("settingsThemeLightHelp"),
              picture: (
                <div className={frameClass}>
                  <ThemeThumb theme="light" />
                </div>
              ),
            },
            {
              value: "dark",
              label: t("settingsThemeDark"),
              description: t("settingsThemeDarkHelp"),
              picture: (
                <div className={frameClass}>
                  <ThemeThumb theme="dark" />
                </div>
              ),
            },
            {
              value: "system",
              label: t("settingsThemeSystem"),
              description: t("settingsThemeSystemHelp"),
              picture: (
                <div className={frameClass}>
                  <div className="absolute inset-0">
                    <ThemeThumb theme="light" />
                  </div>
                  <div className="absolute inset-0 [clip-path:polygon(64%_0,100%_0,100%_100%,36%_100%)]">
                    <ThemeThumb theme="dark" />
                  </div>
                </div>
              ),
            },
          ]}
        />
      </Row>
      {hasLanguages && (
        <Row>
          <RowText
            title={t("settingsLanguage")}
            text={t("settingsLanguageHelp")}
          />
          <LanguageMenu placement="settings" />
        </Row>
      )}
    </Section>
  );
}
