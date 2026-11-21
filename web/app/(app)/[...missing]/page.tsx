"use client";

import { NotebookPen, Search } from "lucide-react";
import Link from "next/link";
import { useTranslations } from "next-intl";
import { AppPage } from "@/components/layout/app-page";
import { ErrorScreen } from "@/components/layout/error-screen";
import { Button } from "@/components/ui/button";

export default function MissingPage() {
  const t = useTranslations();
  return (
    <AppPage title={null}>
      <ErrorScreen
        illustration="missing"
        title={t("appNotFoundTitle")}
        text={t("appNotFoundText")}
        actions={
          <>
            <Button asChild>
              <Link href="/notes">
                <NotebookPen aria-hidden />
                {t("appGoToNotes")}
              </Link>
            </Button>
            <Button variant="secondary" asChild>
              <Link href="/notes?search=1">
                <Search aria-hidden />
                {t("appSearchNotes")}
              </Link>
            </Button>
          </>
        }
      />
    </AppPage>
  );
}
