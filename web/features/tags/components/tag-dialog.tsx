"use client";

import { useMutation, useQueryClient } from "@tanstack/react-query";
import { HTTPError } from "ky";
import { Hash } from "lucide-react";
import { useTranslations } from "next-intl";
import * as React from "react";
import { Button } from "@/components/ui/button";
import {
  Dialog,
  DialogBody,
  DialogContent,
  DialogFooter,
  DialogTitle,
} from "@/components/ui/dialog";
import { Field, FormAlert } from "@/components/ui/field";
import { Input } from "@/components/ui/input";
import { Tip } from "@/components/ui/tooltip";
import { TAG_COLORS } from "@/lib/design/tokens";
import { useRovingFocus } from "@/lib/hooks/use-roving-focus";
import { cn } from "@/lib/utils";
import { createTag, updateTag } from "../api";
import type { Tag } from "../types";
import { nextTagColor, tagColorName, tagColorStyle } from "../utils";
import { TagChip } from "./tag-chip";

interface TagDialogProps {
  open: boolean;
  onOpenChange: (open: boolean) => void;
  /** The tag to rename; none to make a new one. */
  tag: Tag | null;
  tags: Tag[];
  onCreated?: (tag: Tag) => void;
}

const CREATE_FAILED = {
  failed: "tagsDialogCreateFailed",
  offline: "tagsDialogCreateOffline",
  changed: "tagsDialogCreateChanged",
} as const;

const RENAME_FAILED = {
  failed: "tagsDialogRenameFailed",
  offline: "tagsDialogRenameOffline",
  changed: "tagsDialogRenameChanged",
} as const;

type SaveFailure = keyof typeof CREATE_FAILED;

export function TagDialog({
  open,
  onOpenChange,
  tag,
  tags,
  onCreated,
}: TagDialogProps) {
  const t = useTranslations();
  const queryClient = useQueryClient();
  const isNew = !tag;
  const [name, setName] = React.useState(tag?.name ?? "");
  const [color, setColor] = React.useState(
    tag?.color ?? nextTagColor(tags.length),
  );
  const [serverError, setServerError] = React.useState<string | null>(null);
  const [refusedName, setRefusedName] = React.useState<string | null>(null);
  const trimmed = name.trim();
  const taken =
    refusedName === trimmed.toLowerCase() ||
    tags.some(
      (other) =>
        other.id !== tag?.id &&
        other.name.toLowerCase() === trimmed.toLowerCase(),
    );
  const unchanged = !isNew && trimmed === tag.name;

  const mutation = useMutation({
    mutationFn: () =>
      isNew
        ? createTag({ name: trimmed, color })
        : updateTag(tag.id, { name: trimmed, baseVersion: tag.version }),
    onSuccess: (saved) => {
      queryClient.invalidateQueries({ queryKey: ["tags"] });
      if (isNew) onCreated?.(saved);
      onOpenChange(false);
    },
    onError: (error: Error) => {
      const failed = (reason: SaveFailure) =>
        isNew
          ? t(CREATE_FAILED[reason], { name: trimmed })
          : t(RENAME_FAILED[reason]);
      if (!(error instanceof HTTPError))
        return setServerError(failed("offline"));
      if (error.response.status !== 409)
        return setServerError(failed("failed"));
      queryClient.invalidateQueries({ queryKey: ["tags"] });
      // A 409 with serverTag is a version conflict, not a taken name.
      if ((error.data as { serverTag?: unknown } | undefined)?.serverTag)
        return setServerError(failed("changed"));
      setRefusedName(trimmed.toLowerCase());
    },
  });

  const submit = (e: React.FormEvent) => {
    e.preventDefault();
    if (!trimmed || taken || unchanged || mutation.isPending) return;
    setServerError(null);
    mutation.mutate();
  };

  return (
    <Dialog
      open={open}
      onOpenChange={(next) => !mutation.isPending && onOpenChange(next)}
    >
      <DialogContent>
        <form onSubmit={submit} className="contents">
          <DialogTitle>
            {isNew ? t("tagsNewTitle") : t("tagsRenameTitle")}
          </DialogTitle>
          <DialogBody>
            <Field
              label={t("tagsNameLabel")}
              error={taken ? t("tagsNameTaken", { name: trimmed }) : undefined}
            >
              <Input
                value={name}
                onChange={(e) => {
                  setName(e.target.value);
                  setServerError(null);
                }}
                placeholder={t("tagsNamePlaceholder")}
                autoFocus
                onFocus={(e) => !isNew && e.currentTarget.select()}
              />
            </Field>
            {isNew && (
              <div className="grid gap-2">
                <div className="flex items-baseline justify-between gap-2 font-semibold text-meta">
                  <span id="tag-color-label">{t("tagsColorLabel")}</span>
                  <span
                    aria-hidden
                    className="flex max-w-[60%] justify-end overflow-hidden"
                  >
                    <TagChip
                      color={color}
                      name={
                        <span
                          className={cn(
                            "truncate",
                            !trimmed && "font-medium text-muted-foreground",
                          )}
                        >
                          {trimmed || t("tagsNamePreview")}
                        </span>
                      }
                      className="max-w-full overflow-hidden font-semibold"
                    />
                  </span>
                </div>
                <ColorChoices color={color} onChange={setColor} />
              </div>
            )}
            {serverError && <FormAlert>{serverError}</FormAlert>}
          </DialogBody>
          <DialogFooter>
            <Button
              type="button"
              variant="quiet"
              onClick={() => onOpenChange(false)}
              disabled={mutation.isPending}
            >
              {t("commonCancel")}
            </Button>
            <Button
              type="submit"
              disabled={!trimmed || taken || unchanged}
              busy={
                mutation.isPending &&
                (isNew ? t("tagsCreating") : t("tagsRenaming"))
              }
            >
              {isNew ? t("tagsCreate") : t("tagsRenameAction")}
            </Button>
          </DialogFooter>
        </form>
      </DialogContent>
    </Dialog>
  );
}

function ColorChoices({
  color,
  onChange,
}: {
  color: string;
  onChange: (color: string) => void;
}) {
  const t = useTranslations();
  const roving = useRovingFocus<HTMLDivElement>({
    orientation: "both",
    selectsOnMove: true,
  });
  return (
    <div
      ref={roving.ref}
      role="radiogroup"
      aria-labelledby="tag-color-label"
      onFocus={roving.onFocus}
      onKeyDown={roving.onKeyDown}
      className="grid grid-cols-[repeat(9,28px)] gap-2 py-0.5 max-sm:grid-cols-[repeat(6,28px)]"
    >
      {TAG_COLORS.map((swatch) => {
        const selected = swatch.stored === color.toUpperCase();
        const name = tagColorName(swatch.stored, t);
        return (
          <Tip key={swatch.stored} label={name}>
            {/* biome-ignore lint/a11y/useSemanticElements: round color swatches in a radio group */}
            <button
              type="button"
              role="radio"
              aria-checked={selected}
              aria-label={name}
              onClick={() => onChange(swatch.stored)}
              style={tagColorStyle(swatch.stored)}
              className="tag-color grid size-7 cursor-pointer place-items-center rounded-full bg-(--tint) text-(--hash) shadow-[inset_0_0_0_1px_color-mix(in_srgb,var(--hash)_30%,transparent)] transition-transform duration-(--duration-hover) ease-standard hover:scale-110 aria-checked:shadow-[0_0_0_2px_var(--card),0_0_0_3.5px_var(--accent-strong)] [&>svg]:size-3.25 [&>svg]:stroke-3"
            >
              <Hash aria-hidden />
            </button>
          </Tip>
        );
      })}
    </div>
  );
}
