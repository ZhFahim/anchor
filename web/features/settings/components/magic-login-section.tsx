"use client";

import { useMutation } from "@tanstack/react-query";
import { Link2, QrCode, RotateCw } from "lucide-react";
import * as React from "react";
import { encode } from "uqr";
import { Button } from "@/components/ui/button";
import {
  Dialog,
  DialogBody,
  DialogContent,
  DialogDescription,
  DialogHeader,
  DialogTitle,
} from "@/components/ui/dialog";
import { toast } from "@/components/ui/toast";
import { createMagicLogin } from "@/features/auth/api";
import type { MagicLoginCode } from "@/features/auth/types";
import { magicLinkUrl } from "@/features/auth/utils/magic-link";
import { copyText } from "@/lib/clipboard";
import { Row, RowText, Section } from "./settings-blocks";

const linkOf = (magicLogin: MagicLoginCode) =>
  magicLinkUrl(magicLogin.code, window.location.origin);

/** Black on white in either theme, as scanners read it best. */
function QrImage({ text }: { text: string }) {
  const { path, size } = React.useMemo(() => {
    const { data, size } = encode(text, { ecc: "M", border: 2 });
    const path = data
      .flatMap((row, y) =>
        row.flatMap((isDark, x) => (isDark ? [`M${x} ${y}h1v1h-1z`] : [])),
      )
      .join("");
    return { path, size };
  }, [text]);
  return (
    <svg
      role="img"
      aria-label="QR code for magic login"
      viewBox={`0 0 ${size} ${size}`}
      shapeRendering="crispEdges"
      className="mx-auto block aspect-square w-full max-w-64 rounded-lg bg-white"
    >
      <path d={path} fill="#000" />
    </svg>
  );
}

function useMinutesLeft(expiresAt: string | undefined) {
  const [now, setNow] = React.useState(() => Date.now());
  React.useEffect(() => {
    if (!expiresAt) return;
    setNow(Date.now());
    const timer = window.setInterval(() => setNow(Date.now()), 1000);
    return () => window.clearInterval(timer);
  }, [expiresAt]);
  if (!expiresAt) return null;
  return Math.max(0, Math.ceil((Date.parse(expiresAt) - now) / 60_000));
}

export function MagicLoginSection() {
  const [isQrOpen, setIsQrOpen] = React.useState(false);
  const [shown, setShown] = React.useState<MagicLoginCode | null>(null);
  const minutesLeft = useMinutesLeft(shown?.expiresAt);
  const isExpired = minutesLeft === 0;

  const showQr = useMutation({
    mutationFn: createMagicLogin,
    onSuccess: (magicLogin) => {
      setShown(magicLogin);
      setIsQrOpen(true);
    },
    onError: () =>
      toast.error("Couldn’t make a QR code", { retry: () => showQr.mutate() }),
  });

  const copy = (link: string) =>
    copyText(link).then(
      () =>
        toast.success("Magic link copied. Open it on your phone to sign in."),
      () => toast.error("Couldn’t copy the magic link"),
    );

  // Each new code ends the one before, so the open QR code shares its link.
  const copyLink = useMutation({
    mutationFn: async () =>
      shown && isQrOpen && !isExpired ? shown : createMagicLogin(),
    onSuccess: (magicLogin) => {
      setShown(magicLogin);
      return copy(linkOf(magicLogin));
    },
    onError: () =>
      toast.error("Couldn’t make a magic link", {
        retry: () => copyLink.mutate(),
      }),
  });

  return (
    <Section
      id="phone"
      title="Sign in on your phone"
      description="No password needed on the phone."
    >
      <Row>
        <RowText
          title="Show QR code for magic login"
          text="Scan it from the first screen of the Anchor+ Android app, or open the magic link on your phone. Each works once, within 10 minutes."
        />
        <div className="flex flex-wrap items-center gap-2">
          <Button
            variant="secondary"
            onClick={() => showQr.mutate()}
            busy={showQr.isPending && "Making…"}
          >
            <QrCode aria-hidden />
            Show QR code
          </Button>
          <Button
            variant="secondary"
            onClick={() => copyLink.mutate()}
            busy={copyLink.isPending && "Copying…"}
          >
            <Link2 aria-hidden />
            Copy magic link
          </Button>
        </div>
      </Row>
      <Dialog open={isQrOpen} onOpenChange={setIsQrOpen}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle>Magic login</DialogTitle>
            <DialogDescription>
              On your phone, open Anchor+ and tap <b>Scan QR code</b> on its
              first screen. It signs in to this server as you.
            </DialogDescription>
          </DialogHeader>
          <DialogBody>
            {shown && (
              <div className="relative">
                <QrImage text={linkOf(shown)} />
                {isExpired && (
                  <div className="absolute inset-0 grid place-items-center rounded-lg bg-card/90">
                    <Button
                      variant="secondary"
                      onClick={() => showQr.mutate()}
                      busy={showQr.isPending && "Making…"}
                    >
                      <RotateCw aria-hidden />
                      New QR code
                    </Button>
                  </div>
                )}
              </div>
            )}
            <p
              role="status"
              className="m-0 text-center text-meta text-muted-foreground"
            >
              {isExpired
                ? "This code has expired."
                : minutesLeft === 1
                  ? "Works once, for less than a minute more."
                  : `Works once, for ${minutesLeft} more minutes.`}
            </p>
            <Button
              variant="secondary"
              className="w-full"
              disabled={isExpired}
              onClick={() => copyLink.mutate()}
              busy={copyLink.isPending && "Copying…"}
            >
              <Link2 aria-hidden />
              Copy magic link
            </Button>
          </DialogBody>
        </DialogContent>
      </Dialog>
    </Section>
  );
}
