"use client";

import { ChevronDown, Info, RotateCw } from "lucide-react";
import { useTranslations } from "next-intl";
import * as React from "react";
import { ErrorScreen } from "@/components/layout/error-screen";
import { Button } from "@/components/ui/button";
import { StatusRing } from "@/components/ui/status-ring";

const RETRY_WAIT_SECONDS = [15, 30, 60];

export function ServerDownScreen({
  onRetry,
}: {
  onRetry: () => Promise<unknown> | unknown;
}) {
  const t = useTranslations();
  const [countdown, setCountdown] = React.useState({
    round: 0,
    left: RETRY_WAIT_SECONDS[0],
  });
  const [trying, setTrying] = React.useState(false);
  const busy = React.useRef(false);
  const roundSeconds =
    RETRY_WAIT_SECONDS[
      Math.min(countdown.round, RETRY_WAIT_SECONDS.length - 1)
    ];
  const secondsLeft = countdown.left;
  const connecting = trying || secondsLeft === 0;

  const retry = React.useCallback(async () => {
    if (busy.current) return;
    busy.current = true;
    setTrying(true);
    try {
      await onRetry();
    } finally {
      busy.current = false;
      setTrying(false);
      setCountdown((prev) => ({
        round: prev.round + 1,
        left: RETRY_WAIT_SECONDS[
          Math.min(prev.round + 1, RETRY_WAIT_SECONDS.length - 1)
        ],
      }));
    }
  }, [onRetry]);

  React.useEffect(() => {
    if (trying) return;
    const timer = window.setInterval(
      () =>
        setCountdown((prev) => ({ ...prev, left: Math.max(0, prev.left - 1) })),
      1000,
    );
    return () => window.clearInterval(timer);
  }, [trying]);

  React.useEffect(() => {
    if (secondsLeft === 0 && !trying) void retry();
  }, [secondsLeft, trying, retry]);

  const host = typeof window === "undefined" ? "" : window.location.host;
  return (
    <main className="grid min-h-dvh content-center bg-background px-4">
      <ErrorScreen
        illustration="down"
        title={t("appServerDownTitle")}
        text={t("appServerDownText", { host })}
        actions={
          <Button
            onClick={() => void retry()}
            aria-disabled={connecting || undefined}
          >
            <RotateCw aria-hidden />
            {t("commonRetry")}
          </Button>
        }
      >
        <p
          role="status"
          className="m-0 mt-1 inline-flex items-center gap-2 text-meta text-muted-foreground tabular-nums"
        >
          <StatusRing
            remaining={secondsLeft / roundSeconds}
            turning={connecting}
          />
          {connecting
            ? t("appConnecting")
            : t("appRetryCountdown", { count: secondsLeft })}
        </p>
        <details className="group mt-4 w-full rounded-xl bg-card text-left text-control shadow-[0_0_0_1px_color-mix(in_srgb,var(--border)_60%,transparent)]">
          <summary className="flex cursor-pointer list-none items-center gap-2 rounded-[inherit] px-3.5 py-3 font-semibold [&::-webkit-details-marker]:hidden [&>svg]:size-4 [&>svg]:text-muted-foreground">
            <Info aria-hidden />
            {t("appServerDownHelpTitle")}
            <ChevronDown
              aria-hidden
              className="ml-auto transition-transform duration-(--duration-fade) group-open:rotate-180"
            />
          </summary>
          <ul className="m-0 grid gap-1.5 pr-4 pl-10 leading-normal">
            <li>{t("appServerDownCheckConnection")}</li>
            <li>{t("appServerDownRestarting", { app: t("appName") })}</li>
            <li>
              {t.rich("appServerDownContact", {
                host,
                b: (chunks) => <b className="font-semibold">{chunks}</b>,
              })}
            </li>
          </ul>
          <p className="m-3.5 mt-3 border-border/55 border-t pt-2.5 text-muted-foreground text-small">
            {t.rich("appServerDownNoAnswer", {
              request: "GET /api/auth/me",
              code: (chunks) => (
                <code className="font-mono text-foreground text-small">
                  {chunks}
                </code>
              ),
            })}
          </p>
        </details>
      </ErrorScreen>
    </main>
  );
}
