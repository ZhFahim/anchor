"use client";

import { useQuery } from "@tanstack/react-query";
import { useParams } from "next/navigation";
import * as React from "react";
import { Brand } from "@/components/layout/brand";
import { ErrorScreen } from "@/components/layout/error-screen";
import { SplashScreen } from "@/components/layout/splash-screen";
import { Button } from "@/components/ui/button";
import { getPublicNote, PublicNoteMissing } from "@/features/notes/api";
import { NoteBody } from "@/features/notes/components/note-body";
import { deltaToBlocks } from "@/features/notes/note-blocks";
import { hasTitle } from "@/features/notes/title";
import { useHighlightPaint } from "@/lib/highlight-paint";

export default function PublicNotePage() {
  const { token } = useParams<{ token: string }>();
  const { data, error, isLoading, isFetching, refetch } = useQuery({
    queryKey: ["public-note", token],
    queryFn: () => getPublicNote(token),
    staleTime: 0,
  });
  const blocks = React.useMemo(
    () => deltaToBlocks(data?.content),
    [data?.content],
  );
  const pageRef = React.useRef<HTMLElement>(null);
  const bodyRef = React.useRef<HTMLDivElement>(null);
  useHighlightPaint(
    pageRef,
    bodyRef,
    [data?.content, data?.background],
    blocks.some((block) => block.runs.some((run) => run.highlight)),
  );

  React.useEffect(() => {
    if (data && hasTitle(data.title)) document.title = `${data.title} · Anchor`;
  }, [data]);

  if (isLoading) return <SplashScreen checking={false} />;

  if (error || !data)
    return (
      <main className="grid min-h-dvh place-items-center bg-background px-4">
        {error instanceof PublicNoteMissing ? (
          <ErrorScreen
            illustration="missing"
            title="This link doesn’t work"
            text="The note’s owner may have turned the link off, or moved the note to the trash."
            actions={null}
          />
        ) : (
          <ErrorScreen
            illustration="down"
            title="Couldn’t load this note"
            text="The server didn’t answer. Try again in a moment."
            actions={
              <Button
                variant="secondary"
                busy={isFetching && "Retrying…"}
                onClick={() => void refetch()}
              >
                Try again
              </Button>
            }
          />
        )}
      </main>
    );

  const src = (id: string) =>
    `/api/public/notes/${encodeURIComponent(token)}/attachments/${id}`;
  const images = data.attachments.filter((a) => a.type === "image");
  const audio = data.attachments.filter((a) => a.type === "audio");

  return (
    <main
      ref={pageRef}
      className="note min-h-dvh"
      data-note={data.background ?? ""}
    >
      <header className="mx-auto flex max-w-195 items-center justify-between gap-3 px-10 pt-5 pb-2 max-md:px-5">
        <Brand className="flex-none" />
        <span className="text-meta text-note-muted">Shared note</span>
      </header>
      <article className="mx-auto grid max-w-195 gap-4 px-10 pt-4 pb-20 max-md:px-5">
        <h1 className="n-title">
          {hasTitle(data.title) ? data.title : "Untitled"}
        </h1>
        {images.length > 0 && (
          <div className="grid grid-cols-[repeat(auto-fill,minmax(180px,1fr))] gap-2">
            {images.map((image) => (
              <a
                key={image.id}
                href={src(image.id)}
                target="_blank"
                rel="noopener noreferrer"
                className="block overflow-hidden rounded-lg shadow-[0_0_0_1px_var(--note-border)]"
              >
                <img
                  src={src(image.id)}
                  alt={image.originalFilename}
                  loading="lazy"
                  className="aspect-square w-full object-cover"
                />
              </a>
            ))}
          </div>
        )}
        {audio.map((clip) => (
          <audio
            key={clip.id}
            controls
            preload="none"
            src={src(clip.id)}
            aria-label={clip.originalFilename}
            className="w-full"
          />
        ))}
        <NoteBody ref={bodyRef} blocks={blocks} />
      </article>
    </main>
  );
}
