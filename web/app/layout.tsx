import type { Metadata, Viewport } from "next";
import { DM_Sans, JetBrains_Mono, Playfair_Display } from "next/font/google";
import { Providers } from "./providers";
import "./globals.css";

const dmSans = DM_Sans({
  variable: "--font-dm-sans",
  subsets: ["latin"],
  display: "swap",
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

export const metadata: Metadata = {
  title: "Anchor",
  description: "Your thoughts, secured",
  other: {
    "apple-mobile-web-app-title": "Anchor",
  },
};

export const viewport: Viewport = {
  interactiveWidget: "resizes-content",
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html
      lang="en"
      suppressHydrationWarning
      className={`${dmSans.variable} ${playfair.variable} ${jetBrainsMono.variable}`}
    >
      <body>
        <Providers>{children}</Providers>
      </body>
    </html>
  );
}
