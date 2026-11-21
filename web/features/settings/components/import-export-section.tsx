"use client";

import { Upload } from "lucide-react";
import { useTranslations } from "next-intl";
import * as React from "react";
import { Button } from "@/components/ui/button";
import { ExportMenu, ImportDialog } from "@/features/import-export";
import { Row, RowText, Section } from "./settings-blocks";

export function ImportExportSection() {
  const t = useTranslations();
  const [importing, setImporting] = React.useState(false);
  return (
    <Section id="data" title={t("importExportSectionTitle")}>
      <Row>
        <RowText
          title={t("exportSettingsTitle")}
          text={t("exportSettingsText")}
        />
        <ExportMenu />
      </Row>
      <Row>
        <RowText
          title={t("importSettingsTitle")}
          text={t("importSettingsText")}
        />
        <Button variant="secondary" onClick={() => setImporting(true)}>
          <Upload aria-hidden />
          {t("importButton")}
        </Button>
      </Row>
      <ImportDialog open={importing} onOpenChange={setImporting} />
    </Section>
  );
}
