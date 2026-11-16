"use client";

import { Copy, Download, Printer } from "lucide-react";
import * as React from "react";
import { Button } from "@/components/ui/button";
import { Checkbox } from "@/components/ui/checkbox";
import {
  Dialog,
  DialogBody,
  DialogContent,
  DialogDescription,
  DialogFooter,
  DialogHeader,
  DialogTitle,
} from "@/components/ui/dialog";
import { toast } from "@/components/ui/toast";
import { copyText } from "@/lib/clipboard";
import { useLastShown } from "@/lib/hooks/use-last-shown";
import {
  downloadRecoveryCodes,
  printRecoveryCodes,
} from "../utils/recovery-codes-io";

/**
 * The only time the codes are shown. It can’t be dismissed until the person
 * says they saved them.
 */
export function RecoveryCodesDialog({
  codes,
  step,
  intro,
  onDone,
}: {
  /** Open while there are codes. */
  codes: string[] | null;
  /** “Step 2 of 2”, when this follows a setup. */
  step?: string;
  intro: React.ReactNode;
  onDone: () => void;
}) {
  const [saved, setSaved] = React.useState(false);
  const shown = useLastShown(codes, !!codes);
  const shownIntro = useLastShown(intro, !!codes);
  const shownStep = useLastShown(step, !!codes);
  const checkId = React.useId();

  React.useEffect(() => {
    if (codes) setSaved(false);
  }, [codes]);

  const list = shown ?? [];
  return (
    <Dialog open={!!codes} onOpenChange={() => {}}>
      <DialogContent
        size="md"
        showClose={false}
        onEscapeKeyDown={(e) => e.preventDefault()}
        onInteractOutside={(e) => e.preventDefault()}
      >
        <DialogHeader>
          <DialogTitle className="pr-0">Save your recovery codes</DialogTitle>
          <DialogDescription>
            {shownStep ?? "Keep these somewhere safe."}
          </DialogDescription>
        </DialogHeader>
        <DialogBody>
          <p className="m-0 text-ui text-muted-foreground leading-[1.55]">
            {shownIntro}{" "}
            <b className="font-semibold text-foreground">
              We won’t show them again.
            </b>
          </p>
          <ul
            aria-label="Recovery codes"
            className="m-0 grid list-none grid-cols-2 gap-x-6 gap-y-3 rounded-xl bg-muted p-4 font-mono text-foreground text-ui max-md:gap-x-3 max-md:text-meta"
          >
            {list.map((code) => (
              <li key={code} className="select-all tracking-[.02em]">
                {code}
              </li>
            ))}
          </ul>
          <div className="flex flex-wrap gap-2">
            <Button
              variant="secondary"
              size="sm"
              onClick={() =>
                copyText(list.join("\n")).then(
                  () => toast.success("Codes copied"),
                  () => toast.error("Couldn’t copy the codes"),
                )
              }
            >
              <Copy aria-hidden />
              Copy
            </Button>
            <Button
              variant="secondary"
              size="sm"
              onClick={() => downloadRecoveryCodes(list)}
            >
              <Download aria-hidden />
              Download
            </Button>
            <Button
              variant="secondary"
              size="sm"
              onClick={() => printRecoveryCodes(list)}
            >
              <Printer aria-hidden />
              Print
            </Button>
          </div>
          <label
            htmlFor={checkId}
            className="flex cursor-pointer items-center gap-2.5 text-ui"
          >
            <Checkbox
              id={checkId}
              checked={saved}
              onCheckedChange={(checked) => setSaved(checked === true)}
            />
            I’ve saved these codes somewhere safe.
          </label>
        </DialogBody>
        <DialogFooter>
          <Button disabled={!saved} onClick={onDone}>
            Done
          </Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  );
}
