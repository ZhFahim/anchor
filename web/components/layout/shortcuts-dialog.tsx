"use client";

import {
  Dialog,
  DialogBody,
  DialogContent,
  DialogHeader,
  DialogTitle,
} from "@/components/ui/dialog";
import { isMac } from "@/lib/platform";

// A row: what it does, then its keys; a key list is one way of doing it.
type Row = [string, string[][]];

const sections = (mod: string): [string, Row[]][] => [
  [
    "Anywhere",
    [
      ["New note", [["N"]]],
      ["Search", [["/"], [mod, "K"]]],
      ["Go to Notes, Archive, Trash or Settings", [["G", "N / A / T / S"]]],
      ["Show or hide the sidebar", [[mod, "\\"]]],
      ["These shortcuts", [["?"]]],
    ],
  ],
  [
    "Notes",
    [
      [
        "Move between notes",
        [
          ["↑", "↓", "←", "→"],
          ["H", "J", "K", "L"],
        ],
      ],
      [
        "First or last note",
        [
          ["G", "G"],
          ["Shift", "G"],
        ],
      ],
      ["Open the note", [["Enter"], ["O"]]],
      ["Select the note", [["X"], ["Space"]]],
      ["Select up to it", [["Shift", "X"]]],
      ["New note, or new list, with no note focused", [["C"], ["L"]]],
    ],
  ],
  [
    "In a note",
    [
      ["Leave the text; again to close", [["Esc"]]],
      ["Back into the text", [["I"]]],
      ["Close, or tick a checklist item", [[mod, "Enter"]]],
      ["Pin or unpin", [["F"]]],
      ["Archive", [["E"]]],
      ["Move to trash", [["#"]]],
    ],
  ],
];

export function ShortcutsDialog({
  open,
  onOpenChange,
}: {
  open: boolean;
  onOpenChange: (open: boolean) => void;
}) {
  const mod = isMac() ? "⌘" : "Ctrl";
  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent size="lg" aria-describedby={undefined}>
        <DialogHeader>
          <DialogTitle>Keyboard shortcuts</DialogTitle>
        </DialogHeader>
        <DialogBody className="gap-5">
          {sections(mod).map(([title, rows]) => (
            <section key={title} className="grid gap-1.5">
              <h3 className="m-0 text-label text-muted-foreground uppercase">
                {title}
              </h3>
              <dl className="m-0 grid">
                {rows.map(([what, ways]) => (
                  <div
                    key={what}
                    className="flex items-center justify-between gap-4 border-border/50 border-b py-1.5 last:border-b-0"
                  >
                    <dt className="text-ui">{what}</dt>
                    <dd className="m-0 flex shrink-0 items-center gap-1.5 text-muted-foreground text-small">
                      {ways.map((keys, i) => (
                        <span
                          key={keys.join()}
                          className="flex items-center gap-1"
                        >
                          {i > 0 && <span>or</span>}
                          {keys.map((key, j) => (
                            <kbd key={j}>{key}</kbd>
                          ))}
                        </span>
                      ))}
                    </dd>
                  </div>
                ))}
              </dl>
            </section>
          ))}
        </DialogBody>
      </DialogContent>
    </Dialog>
  );
}
