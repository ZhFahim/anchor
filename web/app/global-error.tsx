"use client";

import { RotateCw } from "lucide-react";
import { DM_Sans } from "next/font/google";
import { ThemeProvider } from "next-themes";
import * as React from "react";
import { ErrorScreen } from "@/components/layout/error-screen";
import { Button } from "@/components/ui/button";
import "./globals.css";

const dmSans = DM_Sans({
  variable: "--font-dm-sans",
  subsets: ["latin"],
  display: "swap",
});

export default function GlobalError({
  error,
}: {
  error: Error & { digest?: string };
}) {
  React.useEffect(() => console.error(error), [error]);

  return (
    <html lang="en" suppressHydrationWarning className={dmSans.variable}>
      <body>
        <title>Anchor</title>
        <ThemeProvider
          attribute="class"
          defaultTheme="system"
          enableSystem
          disableTransitionOnChange
        >
          <main className="grid min-h-dvh content-center bg-background px-4">
            <ErrorScreen
              illustration="broken"
              title="Something went wrong"
              text="An unexpected error occurred. Reloading the page usually fixes it. Your saved notes are safe."
              actions={
                <Button onClick={() => window.location.reload()}>
                  <RotateCw aria-hidden />
                  Reload
                </Button>
              }
            />
          </main>
        </ThemeProvider>
      </body>
    </html>
  );
}
