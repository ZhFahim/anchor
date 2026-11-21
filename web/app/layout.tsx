import type { Metadata, Viewport } from "next";
import {
  DM_Sans,
  JetBrains_Mono,
  Manrope,
  Playfair_Display,
} from "next/font/google";
import { NextIntlClientProvider } from "next-intl";
import { getLocale, getTranslations } from "next-intl/server";
import { themeColorScript } from "@/lib/theme";
import { Providers } from "./providers";
import "./globals.css";

const dmSans = DM_Sans({
  variable: "--font-dm-sans",
  subsets: ["latin", "latin-ext"],
  display: "swap",
});

const manrope = Manrope({
  variable: "--font-manrope",
  subsets: ["greek", "cyrillic", "cyrillic-ext"],
  display: "swap",
  preload: false,
});

const playfair = Playfair_Display({
  variable: "--font-playfair",
  subsets: ["latin"],
  display: "swap",
});

const jetBrainsMono = JetBrains_Mono({
  variable: "--font-jetbrains-mono",
  subsets: ["latin"],
  display: "swap",
});

export async function generateMetadata(): Promise<Metadata> {
  const t = await getTranslations();
  return {
    title: t("appName"),
    description: t("appDescription"),
    other: {
      "apple-mobile-web-app-title": t("appName"),
    },
  };
}

export const viewport: Viewport = {
  interactiveWidget: "resizes-content",
};

export default async function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  const locale = await getLocale();
  return (
    <html
      lang={locale}
      suppressHydrationWarning
      className={`${dmSans.variable} ${manrope.variable} ${playfair.variable} ${jetBrainsMono.variable}`}
    >
      <body>
        <script
          // biome-ignore lint/security/noDangerouslySetInnerHtml: a fixed script
          dangerouslySetInnerHTML={{ __html: themeColorScript }}
        />
        <NextIntlClientProvider>
          <Providers>{children}</Providers>
        </NextIntlClientProvider>
      </body>
    </html>
  );
}
