import { ArrowLeft, RotateCw, Trash2 } from "lucide-react";
import Link from "next/link";
import { AppPage } from "@/components/layout/app-page";
import { ErrorScreen } from "@/components/layout/error-screen";
import { Button } from "@/components/ui/button";
import { Skeleton } from "@/components/ui/skeleton";

export function EditorSkeleton() {
  return (
    <div className="pg-editor">
      <article
        className="note ed"
        data-note=""
        aria-busy="true"
        aria-label="Loading note"
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
  return (
    <AppPage title={null}>
      <ErrorScreen
        illustration="broken"
        title="Couldn’t load this note"
        text="Check your connection, then try again."
        actions={
          <>
            <Button onClick={onRetry}>
              <RotateCw aria-hidden />
              Try again
            </Button>
            <Button variant="secondary" asChild>
              <Link href="/notes">
                <ArrowLeft aria-hidden />
                Back to your notes
              </Link>
            </Button>
          </>
        }
      />
    </AppPage>
  );
}

export function NoteUnavailable() {
  return (
    <AppPage title={null}>
      <ErrorScreen
        illustration="note"
        title="This note isn’t available"
        text="It may have been deleted, or you no longer have access to it."
        actions={
          <>
            <Button asChild>
              <Link href="/notes">
                <ArrowLeft aria-hidden />
                Back to your notes
              </Link>
            </Button>
            <Button variant="secondary" asChild>
              <Link href="/trash">
                <Trash2 aria-hidden />
                Open trash
              </Link>
            </Button>
          </>
        }
      />
    </AppPage>
  );
}
