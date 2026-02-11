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
  IndentIncrease,
  IndentDecrease,
  Quote,
  Code,
  Undo2,
  Redo2,
  Link as LinkIcon,
  Type,
  Globe,
} from "lucide-react";
import { Button } from "@/components/ui/button";
import {
  Dialog,
  DialogContent,
  DialogFooter,
  DialogHeader,
  DialogTitle,
} from "@/components/ui/dialog";
import { Input } from "@/components/ui/input";
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

const MAX_INDENT = 3;

function indentLine(quill: QuillInstance) {
  const current = quill.getFormat() ?? {};
  const indent = typeof current.indent === "number" ? current.indent : 0;
  if (indent < MAX_INDENT) {
    quill.format("indent", indent + 1, "user");
  }
}

function outdentLine(quill: QuillInstance) {
  const current = quill.getFormat() ?? {};
  const indent = typeof current.indent === "number" ? current.indent : 0;
  if (indent > 0) {
    quill.format("indent", indent - 1 || false, "user");
  }
}

interface QuillToolbarProps {
  getQuill: () => QuillInstance | null;
  isFocused: boolean;
  updateKey: number;
}

export function QuillToolbar({ getQuill, isFocused, updateKey }: QuillToolbarProps) {
  const [format, setFormat] = useState<Record<string, unknown>>({});
  const [canUndo, setCanUndo] = useState(false);
  const [canRedo, setCanRedo] = useState(false);

  const [linkDialogOpen, setLinkDialogOpen] = useState(false);
  const [linkText, setLinkText] = useState("");
  const [linkUrl, setLinkUrl] = useState("");

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
  const isList = isChecklist || isOrdered || isBullet;
  const indentLevel = typeof format.indent === "number" ? format.indent : 0;

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

  const openLinkDialog = () => {
    if (!quill) return;
    const sel = quill.getSelection();
    const text = sel && sel.length ? quill.getText(sel.index, sel.length) ?? "" : "";
    setLinkText(text);
    setLinkUrl("");
    setLinkDialogOpen(true);
  };

  const submitLink = () => {
    if (!quill) return;
    const url = linkUrl.trim();
    if (!url) return;

    const sel = quill.getSelection(true);
    if (!sel) return;

    if (sel.length === 0) {
      const text = linkText.trim() || url;
      quill.insertText(sel.index, text, "user");
      quill.formatText(sel.index, text.length, "link", url, "user");
      quill.setSelection(sel.index + text.length, 0, "user");
    } else {
      quill.format("link", url, "user");
    }

    setLinkDialogOpen(false);
  };

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
            className={btnClass(false)}
            disabled={!quill || !isList || indentLevel >= MAX_INDENT}
            title="Indent"
            onClick={() => quill && indentLine(quill)}
          >
            <IndentIncrease className="h-4 w-4" />
          </Button>
          <Button
            type="button"
            variant="ghost"
            className={btnClass(false)}
            disabled={!quill || !isList || indentLevel <= 0}
            title="Outdent"
            onClick={() => quill && outdentLine(quill)}
          >
            <IndentDecrease className="h-4 w-4" />
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
            className={btnClass(false)}
            disabled={!quill}
            title="Insert link"
            onClick={openLinkDialog}
          >
            <LinkIcon className="h-4 w-4" />
          </Button>
        </div>
      </div>

      <Dialog open={linkDialogOpen} onOpenChange={setLinkDialogOpen}>
        <DialogContent className="sm:max-w-md">
          <DialogHeader>
            <DialogTitle className="flex items-center gap-3">
              <div className="w-10 h-10 rounded-full bg-accent/10 flex items-center justify-center">
                <LinkIcon className="h-5 w-5 text-accent" />
              </div>
              Insert Link
            </DialogTitle>
          </DialogHeader>

          <div className="grid gap-3">
            <div className="relative">
              <Type className="absolute left-3 top-1/2 -translate-y-1/2 h-4 w-4 text-muted-foreground" />
              <Input
                value={linkText}
                onChange={(e) => setLinkText(e.target.value)}
                placeholder="Link text"
                className="pl-9"
              />
            </div>
            <div className="relative">
              <Globe className="absolute left-3 top-1/2 -translate-y-1/2 h-4 w-4 text-muted-foreground" />
              <Input
                value={linkUrl}
                onChange={(e) => setLinkUrl(e.target.value)}
                placeholder="https://..."
                className="pl-9"
                inputMode="url"
              />
            </div>
          </div>

          <DialogFooter className="gap-2 sm:gap-0">
            <Button type="button" variant="ghost" onClick={() => setLinkDialogOpen(false)}>
              Cancel
            </Button>
            <Button
              type="button"
              onClick={submitLink}
              disabled={!linkUrl.trim()}
              className="bg-accent text-accent-foreground hover:bg-accent/90"
            >
              Insert
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>
    </>
  );
}
