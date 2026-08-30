"use client";

import { useMutation } from "@tanstack/react-query";
import { ChevronDown, Download, Loader2, Upload } from "lucide-react";
import { useState } from "react";
import { toast } from "sonner";
import { Button } from "@/components/ui/button";
import {
  Card,
  CardContent,
  CardDescription,
  CardHeader,
  CardTitle,
} from "@/components/ui/card";
import {
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuItem,
  DropdownMenuTrigger,
} from "@/components/ui/dropdown-menu";
import { downloadExport } from "../api";
import type { ExportFormat } from "../types";
import { ImportDialog } from "./import-dialog";

const EXPORT_CHOICES: {
  format: ExportFormat;
  label: string;
  hint: string;
}[] = [
  {
    format: "anchor",
    label: "Anchor backup (.zip)",
    hint: "Everything needed to restore: notes, tags, attachments",
  },
  {
    format: "markdown",
    label: "Markdown files (.zip)",
    hint: "Plain .md files for Obsidian, Nextcloud Notes and others",
  },
];

export function DataImportExportCard() {
  const [importOpen, setImportOpen] = useState(false);

  const exportMutation = useMutation({
    mutationFn: (format: ExportFormat) => downloadExport(format),
    onSuccess: () => {
      toast.success("Export downloaded");
    },
    onError: (error: Error) => {
      toast.error(error.message || "Failed to export notes");
    },
  });

  return (
    <Card className="border-0 shadow-xl bg-card/80 backdrop-blur-sm mb-6">
      <CardHeader className="space-y-1">
        <CardTitle className="text-2xl">Export & Import</CardTitle>
        <CardDescription>
          Back up your notes or bring them in from another app
        </CardDescription>
      </CardHeader>
      <CardContent className="space-y-4">
        <div className="flex items-center justify-between gap-4">
          <div className="space-y-0.5">
            <p className="text-sm font-medium">Export</p>
            <p className="text-sm text-muted-foreground">
              Download all your notes as a backup or as Markdown files
            </p>
          </div>
          <DropdownMenu>
            <DropdownMenuTrigger asChild disabled={exportMutation.isPending}>
              <Button variant="outline">
                {exportMutation.isPending ? (
                  <>
                    <Loader2 className="h-4 w-4 mr-2 animate-spin" />
                    Exporting...
                  </>
                ) : (
                  <>
                    <Download className="h-4 w-4 mr-2" />
                    Export
                    <ChevronDown className="h-4 w-4 ml-2 opacity-60" />
                  </>
                )}
              </Button>
            </DropdownMenuTrigger>
            <DropdownMenuContent align="end" className="w-64">
              {EXPORT_CHOICES.map((choice) => (
                <DropdownMenuItem
                  key={choice.format}
                  className="group flex-col items-start gap-0.5"
                  onSelect={() => exportMutation.mutate(choice.format)}
                >
                  <span className="text-sm">{choice.label}</span>
                  <span className="text-xs text-muted-foreground group-focus:text-accent-foreground">
                    {choice.hint}
                  </span>
                </DropdownMenuItem>
              ))}
            </DropdownMenuContent>
          </DropdownMenu>
        </div>
        <div className="flex items-center justify-between gap-4">
          <div className="space-y-0.5">
            <p className="text-sm font-medium">Import</p>
            <p className="text-sm text-muted-foreground">
              Restore an Anchor backup, or import from Google Keep or Markdown
            </p>
          </div>
          <Button variant="outline" onClick={() => setImportOpen(true)}>
            <Upload className="h-4 w-4 mr-2" />
            Import
          </Button>
        </div>
      </CardContent>
      <ImportDialog open={importOpen} onOpenChange={setImportOpen} />
    </Card>
  );
}
