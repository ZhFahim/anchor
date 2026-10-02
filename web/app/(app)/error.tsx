"use client";

import { Copy, RotateCw } from "lucide-react";
import * as React from "react";
import { AppPage } from "@/components/layout/app-page";
import { ErrorScreen } from "@/components/layout/error-screen";
import { Button } from "@/components/ui/button";
import { toast } from "@/components/ui/toast";
import { copyText } from "@/lib/clipboard";

/** Like “7f3a-21c9”. */
function shortId(seed?: string) {
  const hex =
    seed?.replace(/[^0-9a-f]/gi, "") ||
    crypto
      .getRandomValues(new Uint32Array(2))
      .reduce((text, part) => text + part.toString(16), "");
  return `${hex.slice(0, 4)}-${hex.slice(4, 8)}`.toLowerCase();
}

export default function AppError({
  error,
  reset,
}: {
  error: Error & { digest?: string };
  reset: () => void;
}) {
  const id = React.useMemo(() => shortId(error.digest), [error.digest]);
  React.useEffect(() => console.error(error), [error]);

  const details = () =>
    [
      `Anchor ${process.env.NEXT_PUBLIC_APP_VERSION}`,
      `Error ${id}`,
      window.location.pathname,
      new Date().toLocaleString("en-US", {
        dateStyle: "medium",
        timeStyle: "short",
      }),
      error.message,
    ].join(" · ");

  return (
    <AppPage title={null}>
      <ErrorScreen
        illustration="broken"
        code={`Error ${id}`}
        title="Something went wrong"
        text="An unexpected error occurred. Reloading the page usually fixes it. Your saved notes are safe."
        actions={
          <>
            <Button
              onClick={() => {
                reset();
                window.location.reload();
              }}
            >
              <RotateCw aria-hidden />
              Reload
            </Button>
            <Button
              variant="secondary"
              onClick={() =>
                copyText(details()).then(
                  () => toast.success("Error details copied"),
                  () => toast.error("Couldn’t copy the details"),
                )
              }
            >
              <Copy aria-hidden />
              Copy error details
            </Button>
          </>
        }
      />
    </AppPage>
  );
}
