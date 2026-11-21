"use client";

import { RotateCw } from "lucide-react";
import { DM_Sans } from "next/font/google";
import { NextIntlClientProvider, useTranslations } from "next-intl";
import { ThemeProvider } from "next-themes";
import * as React from "react";
import { ErrorScreen } from "@/components/layout/error-screen";
import { Button } from "@/components/ui/button";
import { withoutNotes } from "@/i18n/messages";
import english from "@/messages/en.json";
import "./globals.css";

const dmSans = DM_Sans({
  variable: "--font-dm-sans",
  subsets: ["latin"],
  display: "swap",
});

const messages = withoutNotes(english);

function GlobalErrorPage() {
  const t = useTranslations();
  return (
    <>
      <title>{t("appName")}</title>
      <ThemeProvider
        attribute="class"
        defaultTheme="system"
        enableSystem
        disableTransitionOnChange
      >
        <main className="grid min-h-dvh content-center bg-background px-4">
          <ErrorScreen
            illustration="broken"
            title={t("appErrorTitle")}
            text={t("appErrorText")}
            actions={
              <Button onClick={() => window.location.reload()}>
                <RotateCw aria-hidden />
                {t("appReload")}
              </Button>
            }
          />
        </main>
      </ThemeProvider>
    </>
  );
}

export default function GlobalError({
  error,
}: {
  error: Error & { digest?: string };
}) {
  React.useEffect(() => console.error(error), [error]);

  return (
    <html lang="en" suppressHydrationWarning className={dmSans.variable}>
      <body>
        <NextIntlClientProvider locale="en" messages={messages}>
          <GlobalErrorPage />
        </NextIntlClientProvider>
      </body>
    </html>
  );
}
