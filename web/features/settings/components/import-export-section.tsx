"use client";

import { Upload } from "lucide-react";
import * as React from "react";
import { Button } from "@/components/ui/button";
import { ExportMenu, ImportDialog } from "@/features/import-export";
import { Row, RowText, Section } from "./settings-blocks";

export function ImportExportSection() {
  const [importing, setImporting] = React.useState(false);
  return (
    <Section id="data" title="Import and export">
      <Row>
        <RowText
          title="Export"
          text="Download all your notes as a backup, or to move them to another app."
        />
        <ExportMenu />
      </Row>
      <Row>
        <RowText
          title="Import"
          text="Import from an Anchor backup, Google Keep, or Markdown files from Obsidian and Nextcloud Notes."
        />
        <Button variant="secondary" onClick={() => setImporting(true)}>
          <Upload aria-hidden />
          Import
        </Button>
      </Row>
      <ImportDialog open={importing} onOpenChange={setImporting} />
    </Section>
  );
}
