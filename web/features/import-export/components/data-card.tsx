"use client";

import { useMutation } from "@tanstack/react-query";
import { Download, Loader2, Upload } from "lucide-react";
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
import { downloadExport } from "../api";
import { ImportDialog } from "./import-dialog";

export function DataImportExportCard() {
  const [importOpen, setImportOpen] = useState(false);

  const exportMutation = useMutation({
    mutationFn: downloadExport,
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
              Download a zip of all your notes, tags, and attachments
            </p>
          </div>
          <Button
            variant="outline"
            onClick={() => exportMutation.mutate()}
            disabled={exportMutation.isPending}
          >
            {exportMutation.isPending ? (
              <>
                <Loader2 className="h-4 w-4 mr-2 animate-spin" />
                Exporting...
              </>
            ) : (
              <>
                <Download className="h-4 w-4 mr-2" />
                Export
              </>
            )}
          </Button>
        </div>
        <div className="flex items-center justify-between gap-4">
          <div className="space-y-0.5">
            <p className="text-sm font-medium">Import</p>
            <p className="text-sm text-muted-foreground">
              Restore an Anchor backup or import from Google Keep
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
