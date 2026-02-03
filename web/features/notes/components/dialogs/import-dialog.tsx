"use client";

import { useState, useCallback } from "react";
import {
  Upload,
  FileJson,
  Loader2,
  CheckCircle,
  AlertCircle,
} from "lucide-react";
import { Button } from "@/components/ui/button";
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogFooter,
  DialogHeader,
  DialogTitle,
} from "@/components/ui/dialog";
import { parseGoogleKeepZip, type ImportResult } from "../import";
import { importNotes } from "../api";
import { useQueryClient } from "@tanstack/react-query";

interface ImportDialogProps {
  open: boolean;
  onOpenChange: (open: boolean) => void;
}

type ImportStep = "select" | "preview" | "importing" | "complete" | "error";

export function ImportDialog({ open, onOpenChange }: ImportDialogProps) {
  const [step, setStep] = useState<ImportStep>("select");
  const [file, setFile] = useState<File | null>(null);
  const [parseResult, setParseResult] = useState<ImportResult | null>(null);
  const [importedCount, setImportedCount] = useState(0);
  const [tagsCreatedCount, setTagsCreatedCount] = useState(0);
  const [error, setError] = useState<string | null>(null);
  const [isDragging, setIsDragging] = useState(false);
  const queryClient = useQueryClient();

  const resetState = useCallback(() => {
    setStep("select");
    setFile(null);
    setParseResult(null);
    setImportedCount(0);
    setTagsCreatedCount(0);
    setError(null);
  }, []);

  const handleClose = useCallback(
    (isOpen: boolean) => {
      if (!isOpen) {
        resetState();
      }
      onOpenChange(isOpen);
    },
    [onOpenChange, resetState],
  );

  const handleFileSelect = useCallback(async (selectedFile: File) => {
    if (!selectedFile.name.endsWith(".zip")) {
      setError("Please select a ZIP file from Google Takeout");
      setStep("error");
      return;
    }

    setFile(selectedFile);
    setStep("importing");

    try {
      const result = await parseGoogleKeepZip(selectedFile);
      setParseResult(result);

      if (result.notes.length === 0) {
        setError(
          result.errors.length > 0
            ? result.errors[0]
            : "No notes found in the ZIP file",
        );
        setStep("error");
      } else {
        setStep("preview");
      }
    } catch (e) {
      setError(`Failed to parse ZIP file: ${e}`);
      setStep("error");
    }
  }, []);

  const handleDrop = useCallback(
    (e: React.DragEvent) => {
      e.preventDefault();
      setIsDragging(false);
      const droppedFile = e.dataTransfer.files[0];
      if (droppedFile) {
        handleFileSelect(droppedFile);
      }
    },
    [handleFileSelect],
  );

  const handleDragOver = useCallback((e: React.DragEvent) => {
    e.preventDefault();
    setIsDragging(true);
  }, []);

  const handleDragLeave = useCallback((e: React.DragEvent) => {
    e.preventDefault();
    setIsDragging(false);
  }, []);

  const handleImport = useCallback(async () => {
    if (!parseResult || parseResult.notes.length === 0) return;

    setStep("importing");
    try {
      const result = await importNotes(parseResult.notes);
      setImportedCount(result.imported);
      setTagsCreatedCount(result.tagsCreated);
      setStep("complete");
      // Invalidate notes and tags queries to refresh the lists
      queryClient.invalidateQueries({ queryKey: ["notes"] });
      queryClient.invalidateQueries({ queryKey: ["tags"] });
    } catch (e) {
      setError(`Failed to import notes: ${e}`);
      setStep("error");
    }
  }, [parseResult, queryClient]);

  return (
    <Dialog open={open} onOpenChange={handleClose}>
      <DialogContent className="sm:max-w-md">
        <DialogHeader>
          <DialogTitle className="flex items-center gap-3">
            <div className="w-10 h-10 rounded-full bg-primary/10 flex items-center justify-center">
              <Upload className="h-5 w-5 text-primary" />
            </div>
            Import from Google Keep
          </DialogTitle>
          <DialogDescription className="pt-2">
            Import your notes from a Google Takeout export.
          </DialogDescription>
        </DialogHeader>

        {step === "select" && (
          <div
            className={`border-2 border-dashed rounded-lg p-8 text-center transition-colors ${
              isDragging
                ? "border-primary bg-primary/5"
                : "border-muted-foreground/25 hover:border-primary/50"
            }`}
            onDrop={handleDrop}
            onDragOver={handleDragOver}
            onDragLeave={handleDragLeave}
          >
            <FileJson className="h-12 w-12 mx-auto text-muted-foreground mb-4" />
            <p className="text-sm text-muted-foreground mb-4">
              Drag and drop your Google Takeout ZIP file here, or click to
              browse
            </p>
            <input
              type="file"
              accept=".zip"
              className="hidden"
              id="import-file-input"
              onChange={(e) => {
                const selectedFile = e.target.files?.[0];
                if (selectedFile) handleFileSelect(selectedFile);
              }}
            />
            <Button asChild variant="outline">
              <label htmlFor="import-file-input" className="cursor-pointer">
                Select ZIP File
              </label>
            </Button>
          </div>
        )}

        {step === "preview" && parseResult && (
          <div className="space-y-4">
            <div className="bg-muted/50 rounded-lg p-4 space-y-2">
              <div className="flex justify-between text-sm">
                <span className="text-muted-foreground">Notes found:</span>
                <span className="font-medium">{parseResult.notes.length}</span>
              </div>
              {parseResult.labels.length > 0 && (
                <div className="flex justify-between text-sm">
                  <span className="text-muted-foreground">Labels found:</span>
                  <span className="font-medium">
                    {parseResult.labels.length}
                  </span>
                </div>
              )}
              {parseResult.skipped > 0 && (
                <div className="flex justify-between text-sm">
                  <span className="text-muted-foreground">
                    Skipped (empty/trashed):
                  </span>
                  <span className="font-medium">{parseResult.skipped}</span>
                </div>
              )}
            </div>
            {parseResult.labels.length > 0 && (
              <p className="text-xs text-muted-foreground">
                Labels will be automatically converted to tags during import.
              </p>
            )}
          </div>
        )}

        {step === "importing" && (
          <div className="flex flex-col items-center py-8">
            <Loader2 className="h-12 w-12 animate-spin text-primary mb-4" />
            <p className="text-sm text-muted-foreground">
              {file ? "Importing notes..." : "Parsing ZIP file..."}
            </p>
          </div>
        )}

        {step === "complete" && (
          <div className="flex flex-col items-center py-8">
            <CheckCircle className="h-12 w-12 text-green-500 mb-4" />
            <p className="text-lg font-medium mb-2">Import Complete!</p>
            <p className="text-sm text-muted-foreground text-center">
              Successfully imported {importedCount} notes
              {tagsCreatedCount > 0 && (
                <>
                  <br />
                  and created {tagsCreatedCount} new tags from labels
                </>
              )}
              .
            </p>
          </div>
        )}

        {step === "error" && (
          <div className="flex flex-col items-center py-8">
            <AlertCircle className="h-12 w-12 text-destructive mb-4" />
            <p className="text-lg font-medium mb-2">Import Failed</p>
            <p className="text-sm text-muted-foreground text-center">{error}</p>
          </div>
        )}

        <DialogFooter className="gap-2 sm:gap-0">
          {step === "select" && (
            <Button variant="ghost" onClick={() => handleClose(false)}>
              Cancel
            </Button>
          )}
          {step === "preview" && (
            <>
              <Button variant="ghost" onClick={resetState}>
                Back
              </Button>
              <Button onClick={handleImport}>
                Import {parseResult?.notes.length} Notes
              </Button>
            </>
          )}
          {step === "complete" && (
            <Button onClick={() => handleClose(false)}>Done</Button>
          )}
          {step === "error" && (
            <>
              <Button variant="ghost" onClick={() => handleClose(false)}>
                Cancel
              </Button>
              <Button variant="outline" onClick={resetState}>
                Try Again
              </Button>
            </>
          )}
        </DialogFooter>
      </DialogContent>
    </Dialog>
  );
}
