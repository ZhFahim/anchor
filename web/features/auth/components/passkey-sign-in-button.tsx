"use client";

import { Fingerprint } from "lucide-react";
import * as React from "react";
import { Button } from "@/components/ui/button";
import { useCapabilities, usePasskeyLogin } from "../hooks/use-auth";
import { canUsePasskeys } from "../passkey";
import { passkeySignInError } from "../utils/two-factor";
import { AuthMessage } from "./auth-parts";

/** “Sign in with a passkey”, where the server and the browser both support it. */
export function PasskeySignInButton({
  highlight = false,
}: {
  /** The password wasn’t enough: this is the way in. */
  highlight?: boolean;
}) {
  const capabilities = useCapabilities();
  const passkey = usePasskeyLogin();
  const button = React.useRef<HTMLDivElement>(null);
  const isShown = !!capabilities.data?.passkeys && canUsePasskeys();
  React.useEffect(() => {
    if (highlight && isShown) button.current?.querySelector("button")?.focus();
  }, [highlight, isShown]);
  if (!isShown) return null;

  const error = passkey.error ? passkeySignInError(passkey.error) : null;
  return (
    <div ref={button} className="contents">
      {error && <AuthMessage>{error}</AuthMessage>}
      <Button
        size="lg"
        variant={highlight ? "primary" : "secondary"}
        className="w-full"
        busy={passkey.isPending && "Waiting for your passkey…"}
        onClick={() => {
          if (!passkey.isPending) passkey.mutate();
        }}
      >
        <Fingerprint aria-hidden />
        Sign in with a passkey
      </Button>
    </div>
  );
}
