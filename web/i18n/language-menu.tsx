"use client";

import * as MenuPrimitive from "@radix-ui/react-dropdown-menu";
import { Check, ChevronDown, Languages } from "lucide-react";
import { useTranslations } from "next-intl";
import { Button } from "@/components/ui/button";
import {
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuSeparator,
  DropdownMenuTrigger,
  menuItem,
} from "@/components/ui/dropdown-menu";
import { cn } from "@/lib/utils";
import { languageName, useLocaleChoice } from "./locale-choice";
import type { Locale } from "./locales";

const AUTOMATIC = "automatic";
const byName = new Intl.Collator("en");

/** Hidden while the app has one language. */
export function LanguageMenu({
  placement,
}: {
  placement: "auth" | "settings";
}) {
  const t = useTranslations();
  const { locales, current, picked, hasChoice, choose } = useLocaleChoice();
  if (!hasChoice) return null;
  const name = languageName(current);
  const label = t("uiLanguageCurrent", { language: name });
  const languages = [...locales].sort((a, b) =>
    byName.compare(languageName(a), languageName(b)),
  );
  return (
    <DropdownMenu>
      <DropdownMenuTrigger asChild>
        {placement === "settings" ? (
          <Button variant="secondary" aria-label={label}>
            <span lang={current}>{name}</span>
            <ChevronDown aria-hidden className="text-muted-foreground" />
          </Button>
        ) : (
          <button
            type="button"
            aria-label={label}
            className="inline-flex h-8 cursor-pointer items-center gap-1.5 justify-self-center rounded-md border-0 bg-transparent px-2.5 font-medium text-control text-muted-foreground hover:bg-foreground/6 hover:text-foreground aria-expanded:bg-foreground/6 aria-expanded:text-foreground [&_svg]:size-3.75"
          >
            <Languages aria-hidden />
            <span lang={current}>{name}</span>
            <ChevronDown aria-hidden />
          </button>
        )}
      </DropdownMenuTrigger>
      <DropdownMenuContent
        align={placement === "settings" ? "end" : "center"}
        aria-label={t("uiLanguage")}
        className="w-61 max-h-(--radix-dropdown-menu-content-available-height) overflow-y-auto"
      >
        <MenuPrimitive.RadioGroup
          value={picked ?? AUTOMATIC}
          onValueChange={(value) =>
            choose(value === AUTOMATIC ? null : (value as Locale))
          }
          className="grid gap-px"
        >
          <MenuPrimitive.RadioItem
            value={AUTOMATIC}
            className={cn(menuItem, "items-start py-2")}
          >
            <span className="grid flex-1 gap-0.5 leading-[1.3]">
              {t("uiLanguageAutomatic")}
              <small className="whitespace-normal text-muted-foreground text-small">
                {t("uiLanguageAutomaticHelp")}
              </small>
            </span>
            <MenuPrimitive.ItemIndicator className="mt-0.5">
              <Check className="size-4 text-accent-strong" />
            </MenuPrimitive.ItemIndicator>
          </MenuPrimitive.RadioItem>
          <DropdownMenuSeparator />
          {languages.map((locale) => (
            <MenuPrimitive.RadioItem
              key={locale}
              value={locale}
              className={menuItem}
            >
              <span lang={locale} className="flex-1">
                {languageName(locale)}
              </span>
              <MenuPrimitive.ItemIndicator>
                <Check className="size-4 text-accent-strong" />
              </MenuPrimitive.ItemIndicator>
            </MenuPrimitive.RadioItem>
          ))}
        </MenuPrimitive.RadioGroup>
      </DropdownMenuContent>
    </DropdownMenu>
  );
}
