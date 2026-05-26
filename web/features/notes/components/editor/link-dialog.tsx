"use client";

import { Button } from "@/components/ui/button";
import {
  Dialog,
  DialogContent,
  DialogFooter,
  DialogHeader,
  DialogTitle,
} from "@/components/ui/dialog";
import { Input } from "@/components/ui/input";
import { isLikelyUrl } from "@/features/notes";
import { Globe, Link as LinkIcon, Type } from "lucide-react";
import { useEffect, useState } from "react";

export interface LinkDialogProps {
  open: boolean;
  initialText: string;
  initialUrl: string;
  isEditing: boolean;
  onSubmit: (text: string, url: string) => void;
  onRemove?: () => void;
  onOpenChange: (open: boolean) => void;
}

// Reset on each open via a `key` prop from the parent.
export function LinkDialog({
  open,
  initialText,
  initialUrl,
  isEditing,
  onSubmit,
  onRemove,
  onOpenChange,
}: LinkDialogProps) {
  const [text, setText] = useState(initialText);
  const [url, setUrl] = useState(initialUrl);

  useEffect(() => {
    if (!open || isEditing || initialUrl) return;
    if (typeof navigator === "undefined" || !navigator.clipboard?.readText)
      return;

    let cancelled = false;
    navigator.clipboard
      .readText()
      .then((clip) => {
        if (cancelled) return;
        if (clip && isLikelyUrl(clip)) {
          setUrl((prev) => (prev ? prev : clip.trim()));
        }
      })
      .catch(() => {});
    return () => {
      cancelled = true;
    };
  }, [open, initialUrl, isEditing]);

  const submit = () => {
    const trimmedUrl = url.trim();
    if (!trimmedUrl) return;
    const finalText = text.trim() || trimmedUrl;
    onSubmit(finalText, trimmedUrl);
  };

  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent className="sm:max-w-md">
        <DialogHeader>
          <DialogTitle className="flex items-center gap-3">
            <div className="w-10 h-10 rounded-full bg-accent/10 flex items-center justify-center">
              <LinkIcon className="h-5 w-5 text-accent" />
            </div>
            {isEditing ? "Edit Link" : "Insert Link"}
          </DialogTitle>
        </DialogHeader>

        <div className="grid gap-3">
          <div className="relative">
            <Type className="absolute left-3 top-1/2 -translate-y-1/2 h-4 w-4 text-muted-foreground" />
            <Input
              value={text}
              onChange={(e) => setText(e.target.value)}
              placeholder={url.trim() || "Link text"}
              className="pl-9"
            />
          </div>
          <div className="relative">
            <Globe className="absolute left-3 top-1/2 -translate-y-1/2 h-4 w-4 text-muted-foreground" />
            <Input
              value={url}
              onChange={(e) => setUrl(e.target.value)}
              placeholder="https://..."
              className="pl-9"
              inputMode="url"
              autoFocus={!isEditing}
              onKeyDown={(e) => {
                if (e.key === "Enter") {
                  e.preventDefault();
                  submit();
                }
              }}
            />
          </div>
        </div>

        <DialogFooter className="gap-2">
          {isEditing && onRemove && (
            <Button
              type="button"
              variant="ghost"
              onClick={onRemove}
              className="text-destructive hover:text-destructive"
            >
              Remove
            </Button>
          )}
          <Button
            type="button"
            variant="ghost"
            onClick={() => onOpenChange(false)}
          >
            Cancel
          </Button>
          <Button
            type="button"
            onClick={submit}
            disabled={!url.trim()}
            className="bg-accent text-accent-foreground hover:bg-accent/90"
          >
            {isEditing ? "Save" : "Insert"}
          </Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  );
}
