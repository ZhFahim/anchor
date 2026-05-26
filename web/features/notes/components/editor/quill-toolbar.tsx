"use client";

import { useEffect, useMemo, useState } from "react";
import {
  Bold,
  Italic,
  Underline,
  Strikethrough,
  Heading1,
  Heading2,
  Heading3,
  List,
  ListOrdered,
  ListChecks,
  Quote,
  Code,
  Undo2,
  Redo2,
  Link as LinkIcon,
} from "lucide-react";
import { Button } from "@/components/ui/button";
import { cn } from "@/lib/utils";
import type { QuillInstance } from "@/features/notes";
import { LIST_FORMATS } from "@/features/notes";

function toggleInlineFormat(quill: QuillInstance, key: string) {
  const current = quill.getFormat() ?? {};
  quill.format(key, !current[key], "user");
}

function toggleHeader(quill: QuillInstance, level: 1 | 2 | 3) {
  const current = quill.getFormat() ?? {};
  quill.format("header", current.header === level ? false : level, "user");
}

function toggleList(quill: QuillInstance, value: "ordered" | "bullet" | "unchecked") {
  const current = quill.getFormat() ?? {};
  const currentList = current.list as string | undefined;

  if (value === LIST_FORMATS.UNCHECKED) {
    const isChecklist =
      currentList === LIST_FORMATS.CHECKED || currentList === LIST_FORMATS.UNCHECKED;
    quill.format("list", isChecklist ? false : LIST_FORMATS.UNCHECKED, "user");
    return;
  }

  quill.format("list", currentList === value ? false : value, "user");
}

function toggleBlock(quill: QuillInstance, key: "blockquote" | "code-block") {
  const current = quill.getFormat() ?? {};
  quill.format(key, !current[key], "user");
}

interface QuillToolbarProps {
  getQuill: () => QuillInstance | null;
  isFocused: boolean;
  updateKey: number;
  onOpenLinkDialog: () => void;
}

export function QuillToolbar({ getQuill, isFocused, updateKey, onOpenLinkDialog }: QuillToolbarProps) {
  const [format, setFormat] = useState<Record<string, unknown>>({});
  const [canUndo, setCanUndo] = useState(false);
  const [canRedo, setCanRedo] = useState(false);

  // Update toolbar state when parent signals a change (via updateKey)
  // This avoids subscribing to Quill events directly, which caused focus issues
  useEffect(() => {
    const quill = getQuill();
    if (!quill || !isFocused) {
      if (!isFocused) {
        setFormat({});
        setCanUndo(false);
        setCanRedo(false);
      }
      return;
    }

    setFormat(quill.getFormat() ?? {});
    const hist = quill.history;
    setCanUndo(Boolean(hist?.stack?.undo?.length));
    setCanRedo(Boolean(hist?.stack?.redo?.length));
  }, [getQuill, isFocused, updateKey]);

  // Get quill instance for button handlers
  const quill = getQuill();

  const headerLevel = useMemo(() => {
    const h = format.header;
    return typeof h === "number" ? h : 0;
  }, [format.header]);

  const listValue = (format.list as string | undefined) ?? "";
  const isChecklist =
    listValue === LIST_FORMATS.CHECKED || listValue === LIST_FORMATS.UNCHECKED;
  const isOrdered = listValue === LIST_FORMATS.ORDERED;
  const isBullet = listValue === LIST_FORMATS.BULLET;

  const isBold = Boolean(format.bold);
  const isItalic = Boolean(format.italic);
  const isUnderline = Boolean(format.underline);
  const isStrike = Boolean(format.strike);
  const isQuote = Boolean(format.blockquote);
  const isCode = Boolean(format["code-block"]);

  const groupClass = "flex items-center gap-0.5 rounded-full p-0.5 shrink-0";
  const dividerClass = "mx-1.5 h-4 w-px bg-border/40 shrink-0";
  const btnClass = (active?: boolean) =>
    cn(
      "h-8 w-8 rounded-full p-0 shrink-0 transition-colors duration-100",
      active ? "bg-muted/60 text-foreground" : "text-muted-foreground hover:text-foreground hover:bg-muted/30",
    );

  return (
    <>
      <div className="flex items-center overflow-x-auto scrollbar-none -mx-4 px-4 lg:mx-0 lg:px-0 lg:overflow-visible lg:flex-wrap gap-0.5">
        <div className={groupClass}>
          <Button
            type="button"
            variant="ghost"
            className={btnClass(false)}
            disabled={!quill || !canUndo}
            title="Undo"
            onClick={() => quill?.history?.undo?.()}
          >
            <Undo2 className="h-4 w-4" />
          </Button>
          <Button
            type="button"
            variant="ghost"
            className={btnClass(false)}
            disabled={!quill || !canRedo}
            title="Redo"
            onClick={() => quill?.history?.redo?.()}
          >
            <Redo2 className="h-4 w-4" />
          </Button>
        </div>

        <div className={dividerClass} />

        <div className={groupClass}>
          <Button
            type="button"
            variant="ghost"
            className={btnClass(isBold)}
            disabled={!quill}
            title="Bold"
            onClick={() => quill && toggleInlineFormat(quill, "bold")}
          >
            <Bold className="h-4 w-4" />
          </Button>
          <Button
            type="button"
            variant="ghost"
            className={btnClass(isItalic)}
            disabled={!quill}
            title="Italic"
            onClick={() => quill && toggleInlineFormat(quill, "italic")}
          >
            <Italic className="h-4 w-4" />
          </Button>
          <Button
            type="button"
            variant="ghost"
            className={btnClass(isUnderline)}
            disabled={!quill}
            title="Underline"
            onClick={() => quill && toggleInlineFormat(quill, "underline")}
          >
            <Underline className="h-4 w-4" />
          </Button>
          <Button
            type="button"
            variant="ghost"
            className={btnClass(isStrike)}
            disabled={!quill}
            title="Strikethrough"
            onClick={() => quill && toggleInlineFormat(quill, "strike")}
          >
            <Strikethrough className="h-4 w-4" />
          </Button>
        </div>

        <div className={dividerClass} />

        <div className={groupClass}>
          <Button
            type="button"
            variant="ghost"
            className={btnClass(headerLevel === 1)}
            disabled={!quill}
            title="Heading 1"
            onClick={() => quill && toggleHeader(quill, 1)}
          >
            <Heading1 className="h-4 w-4" />
          </Button>
          <Button
            type="button"
            variant="ghost"
            className={btnClass(headerLevel === 2)}
            disabled={!quill}
            title="Heading 2"
            onClick={() => quill && toggleHeader(quill, 2)}
          >
            <Heading2 className="h-4 w-4" />
          </Button>
          <Button
            type="button"
            variant="ghost"
            className={btnClass(headerLevel === 3)}
            disabled={!quill}
            title="Heading 3"
            onClick={() => quill && toggleHeader(quill, 3)}
          >
            <Heading3 className="h-4 w-4" />
          </Button>
        </div>

        <div className={dividerClass} />

        <div className={groupClass}>
          <Button
            type="button"
            variant="ghost"
            className={btnClass(isChecklist)}
            disabled={!quill}
            title="Checklist"
            onClick={() => quill && toggleList(quill, "unchecked")}
          >
            <ListChecks className="h-4 w-4" />
          </Button>
          <Button
            type="button"
            variant="ghost"
            className={btnClass(isOrdered)}
            disabled={!quill}
            title="Numbered list"
            onClick={() => quill && toggleList(quill, "ordered")}
          >
            <ListOrdered className="h-4 w-4" />
          </Button>
          <Button
            type="button"
            variant="ghost"
            className={btnClass(isBullet)}
            disabled={!quill}
            title="Bullet list"
            onClick={() => quill && toggleList(quill, "bullet")}
          >
            <List className="h-4 w-4" />
          </Button>
        </div>

        <div className={dividerClass} />

        <div className={groupClass}>
          <Button
            type="button"
            variant="ghost"
            className={btnClass(isQuote)}
            disabled={!quill}
            title="Quote"
            onClick={() => quill && toggleBlock(quill, "blockquote")}
          >
            <Quote className="h-4 w-4" />
          </Button>
          <Button
            type="button"
            variant="ghost"
            className={btnClass(isCode)}
            disabled={!quill}
            title="Code block"
            onClick={() => quill && toggleBlock(quill, "code-block")}
          >
            <Code className="h-4 w-4" />
          </Button>
          <Button
            type="button"
            variant="ghost"
            className={btnClass(Boolean(format.link))}
            disabled={!quill}
            title={format.link ? "Edit link" : "Insert link"}
            onClick={onOpenLinkDialog}
          >
            <LinkIcon className="h-4 w-4" />
          </Button>
        </div>
      </div>
    </>
  );
}
