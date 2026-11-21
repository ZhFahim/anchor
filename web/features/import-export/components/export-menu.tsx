"use client";

import { ChevronDown, Download, FileText, FolderArchive } from "lucide-react";
import { useTranslations } from "next-intl";
import { Button } from "@/components/ui/button";
import {
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuItem,
  DropdownMenuTrigger,
} from "@/components/ui/dropdown-menu";
import { toast } from "@/components/ui/toast";
import type { Translate } from "@/i18n/translate";
import { downloadExport } from "../api";
import type { ExportFormat } from "../types";

const CHOICES = [
  {
    format: "anchor",
    label: "exportAnchorLabel",
    hint: "exportAnchorHint",
    icon: FolderArchive,
  },
  {
    format: "markdown",
    label: "exportMarkdownLabel",
    hint: "exportMarkdownHint",
    icon: FileText,
  },
] as const;

function startExport(format: ExportFormat, t: Translate) {
  void toast
    .promise(downloadExport(format), {
      loading: t("exportPreparing"),
      success: t("exportDownloaded"),
      error: t("exportFailed"),
      retry: () => startExport(format, t),
    })
    .catch(() => {});
}

export function ExportMenu() {
  const t = useTranslations();
  return (
    <DropdownMenu>
      <DropdownMenuTrigger asChild>
        <Button variant="secondary">
          <Download aria-hidden />
          {t("exportButton")}
          <ChevronDown aria-hidden className="-mr-1 text-muted-foreground" />
        </Button>
      </DropdownMenuTrigger>
      <DropdownMenuContent align="end" className="w-72">
        {CHOICES.map((choice) => (
          <DropdownMenuItem
            key={choice.format}
            className="items-start py-2 [&>svg]:mt-0.5"
            onSelect={() => startExport(choice.format, t)}
          >
            <choice.icon />
            <span className="grid gap-0.5 whitespace-normal leading-[1.35]">
              {t(choice.label)}
              <small className="text-muted-foreground text-small">
                {t(choice.hint)}
              </small>
            </span>
          </DropdownMenuItem>
        ))}
      </DropdownMenuContent>
    </DropdownMenu>
  );
}
