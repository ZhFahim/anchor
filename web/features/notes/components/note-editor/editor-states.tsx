import { ArrowLeft, RotateCw, Trash2 } from "lucide-react";
import Link from "next/link";
import { useTranslations } from "next-intl";
import { AppPage } from "@/components/layout/app-page";
import { ErrorScreen } from "@/components/layout/error-screen";
import { Button } from "@/components/ui/button";
import { Skeleton } from "@/components/ui/skeleton";

export function EditorSkeleton() {
  const t = useTranslations();
  return (
    <div className="pg-editor">
      <article
        className="note ed"
        data-note=""
        aria-busy="true"
        aria-label={t("noteLoading")}
      >
        <div className="ed-scroll scrollbar-slim">
          <div className="ed-head">
            <Skeleton
              shape="circle"
              className="size-target-desktop rounded-button"
            />
          </div>
          <div className="note-in">
            <div className="grid gap-2">
              <Skeleton shape="title" className="h-8 w-[46%]" />
              <Skeleton style={{ width: "28%" }} />
              <span className="h-5" />
              {["96%", "88%", "92%", "58%", "84%", "70%"].map((w) => (
                <Skeleton key={w} style={{ width: w }} />
              ))}
            </div>
          </div>
        </div>
      </article>
    </div>
  );
}

export function NoteLoadFailed({ onRetry }: { onRetry: () => void }) {
  const t = useTranslations();
  return (
    <AppPage title={null}>
      <ErrorScreen
        illustration="broken"
        title={t("noteLoadFailedTitle")}
        text={t("noteLoadFailedText")}
        actions={
          <>
            <Button onClick={onRetry}>
              <RotateCw aria-hidden />
              {t("commonRetry")}
            </Button>
            <Button variant="secondary" asChild>
              <Link href="/notes">
                <ArrowLeft aria-hidden />
                {t("noteBackToNotes")}
              </Link>
            </Button>
          </>
        }
      />
    </AppPage>
  );
}

export function NoteUnavailable() {
  const t = useTranslations();
  return (
    <AppPage title={null}>
      <ErrorScreen
        illustration="note"
        title={t("noteUnavailableTitle")}
        text={t("noteUnavailableText")}
        actions={
          <>
            <Button asChild>
              <Link href="/notes">
                <ArrowLeft aria-hidden />
                {t("noteBackToNotes")}
              </Link>
            </Button>
            <Button variant="secondary" asChild>
              <Link href="/trash">
                <Trash2 aria-hidden />
                {t("noteOpenTrash")}
              </Link>
            </Button>
          </>
        }
      />
    </AppPage>
  );
}
