"use client";

import { Archive, ArchiveRestore, Lock, RotateCcw, Trash2 } from "lucide-react";
import { useLocale, useTranslations } from "next-intl";
import * as React from "react";
import { Avatar } from "@/components/ui/avatar";
import { Button } from "@/components/ui/button";
import { useRovingFocus } from "@/lib/hooks/use-roving-focus";
import { cn } from "@/lib/utils";
import type { Person } from "./note-editor-content";

type ReadOnlyBarProps =
  | {
      kind: "trash";
      deletesOn: Date;
      onRestore: () => void;
      onDelete: () => void;
      restoring?: boolean;
    }
  | { kind: "view"; sharedBy: Person }
  | { kind: "archived"; onUnarchive: () => void }
  | { kind: "refused" };

/** A new `nudge` number shakes it. */
export function ReadOnlyBar(props: ReadOnlyBarProps & { nudge?: number }) {
  const t = useTranslations();
  const locale = useLocale();
  const ref = React.useRef<HTMLDivElement>(null);
  const actions = useRovingFocus<HTMLSpanElement>();
  React.useEffect(() => {
    const el = ref.current;
    if (!props.nudge || !el) return;
    el.classList.remove("nudge", "flash");
    void el.offsetWidth;
    el.classList.add("nudge", "flash");
    const timer = window.setTimeout(() => el.classList.remove("flash"), 700);
    return () => window.clearTimeout(timer);
  }, [props.nudge]);

  const bold = (chunks: React.ReactNode) => <b>{chunks}</b>;
  const icon = (node: React.ReactNode) => (
    <span className="ic" aria-hidden>
      {node}
    </span>
  );
  return (
    <div
      ref={ref}
      role="status"
      className={cn("ro-bar")}
      onAnimationEnd={() => ref.current?.classList.remove("nudge")}
    >
      {props.kind === "trash" && (
        <>
          {icon(<Trash2 />)}
          <span className="ro-msg">
            {t.rich("noteTrashBar", {
              b: bold,
              date: new Intl.DateTimeFormat(locale, {
                month: "long",
                day: "numeric",
              }).format(props.deletesOn),
            })}
          </span>
          <span
            ref={actions.ref}
            className="ro-acts"
            role="toolbar"
            aria-label={t("noteInTrash")}
            onFocus={actions.onFocus}
            onKeyDown={actions.onKeyDown}
          >
            <Button
              onClick={props.onRestore}
              busy={props.restoring && t("noteRestoring")}
            >
              <RotateCcw aria-hidden />
              {t("noteRestore")}
            </Button>
            <Button variant="danger" onClick={props.onDelete}>
              {t("noteDeletePermanently")}
            </Button>
          </span>
        </>
      )}
      {props.kind === "view" && (
        <>
          <Avatar
            id={props.sharedBy.id}
            name={props.sharedBy.name}
            src={props.sharedBy.profileImage}
            size="md"
          />
          <span className="ro-msg">
            {t.rich("noteViewOnlyBar", {
              b: bold,
              name: props.sharedBy.name.split(" ")[0],
            })}
          </span>
        </>
      )}
      {props.kind === "archived" && (
        <>
          {icon(<Archive />)}
          <span className="ro-msg">
            {t.rich("noteArchivedBar", { b: bold })}
          </span>
          <span className="ro-acts">
            <Button variant="quiet" onClick={props.onUnarchive}>
              <ArchiveRestore aria-hidden />
              {t("noteUnarchive")}
            </Button>
          </span>
        </>
      )}
      {props.kind === "refused" && (
        <>
          {icon(<Lock />)}
          <span className="ro-msg">
            {t.rich("noteRefusedBar", { b: bold })}
          </span>
        </>
      )}
    </div>
  );
}
