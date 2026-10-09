"use client";

import {
  useInfiniteQuery,
  useQuery,
  useQueryClient,
} from "@tanstack/react-query";
import {
  ArrowLeft,
  ChevronDown,
  ChevronsUpDown,
  ChevronUp,
  History,
  RotateCcw,
  SquarePen,
  TriangleAlert,
  X,
} from "lucide-react";
import * as React from "react";
import { Avatar } from "@/components/ui/avatar";
import { Button, IconButton } from "@/components/ui/button";
import { EmptyState, LoadFailedRow } from "@/components/ui/empty-state";
import { Skeleton, SkeletonRows } from "@/components/ui/skeleton";
import { toast } from "@/components/ui/toast";
import { Tip } from "@/components/ui/tooltip";
import { useHighlightPaint } from "@/lib/highlight-paint";
import { useDelayedFlag } from "@/lib/hooks/use-delayed-flag";
import { isPhoneWidth, useIsPhone } from "@/lib/hooks/use-is-phone";
import { cn } from "@/lib/utils";
import { getNoteRevision, getNoteRevisions, restoreNoteRevision } from "../api";
import {
  CURRENT_ENTRY_ID,
  canRestoreRevisions,
  comparisonTargetId,
  groupTimelineByDay,
  historyHasMultipleAuthors,
  revisionAuthorName,
  revisionDayTime,
  revisionLabel,
  revisionsFromPages,
  revisionTime,
  type TimelineEntry,
  timelineEntries,
} from "../history";
import { deltaToBlocks, type NoteBlock } from "../note-blocks";
import { draftTitle, hasTitle } from "../title";
import type { Note, NoteRevisionSummary } from "../types";
import {
  diffVersions,
  type Fold,
  foldLines,
  type VersionLine,
  type WordPart,
} from "../version-diff";
import { TextRuns } from "./note-body";

interface HistoryViewProps {
  noteId: string;
  note: Note | null;
  /** The live draft, saved or not. */
  title: string;
  content: string;
  currentUserId: string | null;
  saving: boolean;
  onClose: () => void;
  onRestored: (note: Note) => void;
  flushEdits: () => Promise<void>;
}

/** “Edited just now”, “Edited 12 min ago”, “Edited today at 2:14 PM”. */
function editedAgo(iso: string | undefined) {
  if (!iso) return "";
  const minutes = Math.round((Date.now() - new Date(iso).getTime()) / 60000);
  if (minutes < 1) return "Edited just now";
  if (minutes < 60) return `Edited ${minutes} min ago`;
  const when = revisionDayTime({ createdAt: iso });
  return `Edited ${when.startsWith("Today") || when.startsWith("Yesterday") ? when.charAt(0).toLowerCase() + when.slice(1) : when}`;
}

const lowercaseDay = (label: string) =>
  label.startsWith("Today") || label.startsWith("Yesterday")
    ? label.charAt(0).toLowerCase() + label.slice(1)
    : label;

export function HistoryView(props: HistoryViewProps) {
  const queryClient = useQueryClient();
  const [selectedId, setSelectedId] = React.useState(CURRENT_ENTRY_ID);
  const [view, setView] = React.useState<"list" | "ver">("list");
  const [unfolded, setUnfolded] = React.useState<Record<string, number[]>>({});
  const [restoring, setRestoring] = React.useState(false);
  const listRef = React.useRef<HTMLDivElement>(null);
  const mainRef = React.useRef<HTMLDivElement>(null);
  const versionNameRef = React.useRef<HTMLDivElement>(null);
  const settledViewRef = React.useRef<React.ReactNode>(null);

  const pages = useInfiniteQuery({
    queryKey: ["note-revisions", props.noteId],
    queryFn: ({ pageParam }) => getNoteRevisions(props.noteId, pageParam),
    initialPageParam: undefined as string | undefined,
    getNextPageParam: (page) => page.nextCursor ?? undefined,
  });
  const revisions = revisionsFromPages(pages.data?.pages);
  const entries = timelineEntries(revisions);
  const showAuthors = historyHasMultipleAuthors(revisions);
  const orderedIds = [CURRENT_ENTRY_ID, ...entries.map((e) => e.id)];
  const selectedIndex = Math.max(0, orderedIds.indexOf(selectedId));
  const entry = entries.find((e) => e.id === selectedId) ?? null;
  const revision = entry?.revision ?? null;
  const comparedId = revision
    ? comparisonTargetId(revisions, revision.id)
    : null;

  const detail = useQuery({
    queryKey: ["note-revisions", props.noteId, revision?.id],
    queryFn: () => getNoteRevision(props.noteId, revision?.id as string),
    enabled: !!revision,
  });
  const compared = useQuery({
    queryKey: ["note-revisions", props.noteId, comparedId],
    queryFn: () => getNoteRevision(props.noteId, comparedId as string),
    enabled: !!comparedId,
  });

  const loading =
    !!revision && (detail.isLoading || (!!comparedId && compared.isLoading));
  const failed =
    !!revision && (detail.isError || (!!comparedId && compared.isError));
  const showLoadingShapes = useDelayedFlag(loading);
  const isPhone = useIsPhone();
  const nextTitle = comparedId ? (compared.data?.title ?? "") : props.title;
  const nextContent = comparedId
    ? (compared.data?.content ?? null)
    : props.content;
  const diff = React.useMemo(
    () =>
      revision && detail.data && !loading
        ? diffVersions(detail.data.content, nextContent)
        : null,
    [revision, detail.data, loading, nextContent],
  );
  const title = revision
    ? (detail.data?.title ?? entry?.title ?? "")
    : props.title;
  const titleChanged = !!diff && draftTitle(title) !== draftTitle(nextTitle);
  const blocks = React.useMemo(
    () => (revision ? [] : deltaToBlocks(props.content)),
    [revision, props.content],
  );

  const showVersion = React.useCallback((id: string, focus = true) => {
    setSelectedId(id);
    setView("ver");
    requestAnimationFrame(() => {
      const row = listRef.current?.querySelector<HTMLElement>(
        `[data-v="${id}"]`,
      );
      row?.scrollIntoView({ block: "nearest" });
      const active = document.activeElement;
      // On phones the list is hidden.
      if (isPhoneWidth()) {
        if (!mainRef.current?.contains(active))
          versionNameRef.current?.focus({ preventScroll: true });
      } else if (focus && listRef.current?.contains(active))
        row?.focus({ preventScroll: true });
      mainRef.current?.scrollTo({ top: 0 });
    });
  }, []);
  const showList = () => {
    setView("list");
    requestAnimationFrame(() =>
      listRef.current
        ?.querySelector<HTMLElement>(`[data-v="${selectedId}"]`)
        ?.focus(),
    );
  };
  const step = (offset: number) => {
    const id = orderedIds[selectedIndex + offset];
    if (id) showVersion(id);
    else if (offset > 0 && pages.hasNextPage) void pages.fetchNextPage();
  };

  React.useEffect(() => {
    listRef.current
      ?.querySelector<HTMLElement>(`[data-v="${CURRENT_ENTRY_ID}"]`)
      ?.focus({ preventScroll: true });
  }, []);

  const restore = async () => {
    if (!revision) return;
    setRestoring(true);
    try {
      const versionBefore = props.note?.version;
      const note = await restoreNoteRevision(props.noteId, revision.id);
      applyRestored(note);
      // The server skips a restore that would change nothing.
      if (note.version === versionBefore)
        toast.success("The note already matches this version");
      else
        toast.success("Version restored", {
          undo: () => undoRestore(note.version - 1),
        });
      props.onClose();
    } catch {
      toast.error("Couldn’t restore this version", {
        retry: () => void restore(),
      });
    } finally {
      setRestoring(false);
    }
  };
  const applyRestored = (note: Note) => {
    props.onRestored(note);
    queryClient.invalidateQueries({ queryKey: ["notes"] });
    queryClient.invalidateQueries({
      queryKey: ["note-revisions", props.noteId],
    });
  };
  // The restore kept the prior text as a revision at the previous version.
  const undoRestore = async (version: number) => {
    try {
      // Unsaved edits must be saved before the undo replaces them.
      await props.flushEdits();
      const page = await getNoteRevisions(props.noteId);
      const before = page.revisions.find(
        (r) => r.cause === "restore" && r.version === version,
      );
      if (!before) throw new Error("nothing to undo");
      applyRestored(await restoreNoteRevision(props.noteId, before.id));
    } catch {
      toast.error("Couldn’t undo the restore");
    }
  };

  const canRestore = !!revision && canRestoreRevisions(props.note);
  const authorName = entry
    ? revisionAuthorName(entry, props.currentUserId)
    : "";
  const subtitle = revision
    ? [
        showAuthors ? authorName : null,
        revision.cause === "edit" ? null : revisionLabel(revision.cause),
      ]
        .filter(Boolean)
        .join(" · ")
    : editedAgo(props.note?.updatedAt);
  const comparedEntry = comparedId
    ? entries.find((e) => e.id === comparedId)
    : null;
  const backLabel = isPhone ? "Back to the version list" : "Back to the note";

  const versionView = (
    <div className="hs-paper">
      {diff && (diff.added || diff.removed || diff.changed || titleChanged) ? (
        <div className="hs-legend">
          <span className="lg add">
            <span className="sg">+</span>
            {diff.added} added
          </span>
          <span className="lg del">
            <span className="sg">−</span>
            {diff.removed} removed
          </span>
          <span className="lg chg">
            <span className="sg">±</span>
            {diff.changed + (titleChanged ? 1 : 0)} changed
          </span>
          <span className="vs">
            Compared with{" "}
            {comparedEntry
              ? lowercaseDay(revisionDayTime(comparedEntry))
              : "the current version"}
          </span>
        </div>
      ) : null}
      {revision?.cause === "conflict" && (
        <div className="callout">
          <TriangleAlert aria-hidden />
          <span>
            <b>Not saved.</b>{" "}
            {authorName === "You" ? "Your" : `${authorName}’s`} edit wasn’t
            saved because the note changed on another device first. Restore it,
            or copy what you need.
          </span>
        </div>
      )}
      {failed ? (
        <LoadFailedRow
          message="Couldn’t load this version."
          onRetry={() => {
            void detail.refetch();
            if (comparedId) void compared.refetch();
          }}
          isRetrying={detail.isFetching || compared.isFetching}
        />
      ) : (
        <>
          {titleChanged ? (
            <div className="t-chg">
              <h2 className="n-title dl del">
                {draftTitle(title) || "Untitled"}
              </h2>
              <h2 className="n-title dl add">
                {draftTitle(nextTitle) || "Untitled"}
              </h2>
            </div>
          ) : (
            <h2 className="n-title">{hasTitle(title) ? title : "Untitled"}</h2>
          )}
          {diff &&
            !diff.added &&
            !diff.removed &&
            !diff.changed &&
            !titleChanged &&
            diff.lines.length > 0 && (
              <p className="hs-note">
                {comparedId
                  ? "Same text as the version after this one."
                  : "Same text as the note is now."}
              </p>
            )}
          {revision ? (
            diff?.lines.length ? (
              <VersionBody
                lines={diff.lines}
                open={new Set(unfolded[selectedId] ?? [])}
                onOpen={(fold) =>
                  setUnfolded((prev) => ({
                    ...prev,
                    [selectedId]: [
                      ...(prev[selectedId] ?? []),
                      ...Array.from(
                        { length: fold.to - fold.from },
                        (_, i) => fold.from + i,
                      ),
                    ],
                  }))
                }
              />
            ) : (
              <p className="hs-note">This version has no text.</p>
            )
          ) : blocks.length ? (
            <VersionBody
              lines={blocks.map((block) => ({ kind: "same", block }))}
              whole
            />
          ) : (
            <p className="hs-note">This version has no text.</p>
          )}
        </>
      )}
    </div>
  );
  if (!loading) settledViewRef.current = versionView;

  return (
    <div
      className="hist"
      data-view={view}
      onKeyDown={(e) => {
        if (e.key === "Escape") {
          if (e.defaultPrevented) return;
          e.preventDefault();
          if (view === "ver" && isPhoneWidth()) showList();
          else props.onClose();
          return;
        }
        if (
          (e.target as HTMLElement).closest(
            "button:not(.hs-row), input, textarea, [data-line]",
          )
        )
          return;
        if (e.key === "ArrowDown" || e.key === "ArrowUp") {
          e.preventDefault();
          step(e.key === "ArrowDown" ? 1 : -1);
        } else if (e.key === "Home" || e.key === "End") {
          e.preventDefault();
          showVersion(
            e.key === "Home"
              ? orderedIds[0]
              : orderedIds[orderedIds.length - 1],
          );
        }
      }}
    >
      <div ref={mainRef} className="hs-main scrollbar-slim">
        <div className="hs-top">
          <Tip label={backLabel}>
            <IconButton
              label={backLabel}
              onClick={() => (isPhoneWidth() ? showList() : props.onClose())}
            >
              <ArrowLeft />
            </IconButton>
          </Tip>
          <div ref={versionNameRef} className="hs-what" tabIndex={-1}>
            <b>
              {revision && entry ? revisionDayTime(entry) : "Current version"}
            </b>
            {subtitle && <span>{subtitle}</span>}
          </div>
          <span className="hs-nav flex">
            <IconButton
              label="Newer version"
              disabled={selectedIndex === 0}
              onClick={() => step(-1)}
            >
              <ChevronUp />
            </IconButton>
            <IconButton
              label="Older version"
              disabled={
                selectedIndex === orderedIds.length - 1 && !pages.hasNextPage
              }
              onClick={() => step(1)}
            >
              <ChevronDown />
            </IconButton>
          </span>
          {canRestore && (
            <Tip
              label={
                props.saving
                  ? "Waiting for the note to save"
                  : "Put this version back on the note"
              }
            >
              <span>
                <Button
                  onClick={() => void restore()}
                  disabled={props.saving || loading || failed}
                  busy={restoring && "Restoring…"}
                >
                  <RotateCcw aria-hidden />
                  Restore
                </Button>
              </span>
            </Tip>
          )}
        </div>
        {loading &&
        (showLoadingShapes || isPhone || !settledViewRef.current) ? (
          <div className="hs-paper">
            <div
              className={cn("hs-wait", !showLoadingShapes && "invisible")}
              role="status"
              aria-busy="true"
              aria-label="Loading this version"
            >
              <Skeleton className="h-8 w-3/5" />
              <SkeletonRows count={6} />
            </div>
          </div>
        ) : loading ? (
          settledViewRef.current
        ) : (
          versionView
        )}
      </div>
      <section className="hs-side hs-pane" aria-label="Versions">
        <div className="hs-side-h">
          <h2 className="m-0 font-semibold text-lead">History</h2>
          <IconButton label="Close history" size="sm" onClick={props.onClose}>
            <X />
          </IconButton>
        </div>
        <VersionList
          listRef={listRef}
          entries={entries}
          selectedId={selectedId}
          showAuthors={showAuthors}
          currentUserId={props.currentUserId}
          currentWhen={editedAgo(props.note?.updatedAt)}
          loading={pages.isLoading}
          failed={pages.isLoadingError}
          retrying={pages.isFetching && !pages.isFetchingNextPage}
          hasMore={!!pages.hasNextPage}
          fetchingMore={pages.isFetchingNextPage}
          moreFailed={pages.isFetchNextPageError}
          onRetry={() => void pages.refetch()}
          onMore={() => void pages.fetchNextPage()}
          onPick={(id) => showVersion(id, false)}
        />
        <div className="hs-foot">
          <span className="hs-keys">
            <span aria-hidden>
              <kbd>↑</kbd>
              <kbd>↓</kbd>
            </span>
            <span className="sr-only">Up and down arrows</span> to move between
            versions
          </span>
          <span>Versions older than 90 days are deleted.</span>
        </div>
      </section>
    </div>
  );
}

function VersionList({
  listRef,
  entries,
  selectedId,
  showAuthors,
  currentUserId,
  currentWhen,
  loading,
  failed,
  retrying,
  hasMore,
  fetchingMore,
  moreFailed,
  onRetry,
  onMore,
  onPick,
}: {
  listRef: React.RefObject<HTMLDivElement | null>;
  entries: TimelineEntry[];
  selectedId: string;
  showAuthors: boolean;
  currentUserId: string | null;
  currentWhen: string;
  loading: boolean;
  failed: boolean;
  retrying: boolean;
  hasMore: boolean;
  fetchingMore: boolean;
  moreFailed: boolean;
  onRetry: () => void;
  onMore: () => void;
  onPick: (id: string) => void;
}) {
  const endRef = React.useRef<HTMLDivElement>(null);
  const showLoadingShapes = useDelayedFlag(loading);
  const showMoreShapes = useDelayedFlag(fetchingMore);
  React.useEffect(() => {
    const el = endRef.current;
    if (!el || !hasMore || fetchingMore || moreFailed) return;
    const observer = new IntersectionObserver(
      (seen) => seen.some((s) => s.isIntersecting) && onMore(),
    );
    observer.observe(el);
    return () => observer.disconnect();
  }, [hasMore, fetchingMore, moreFailed, onMore]);

  const lastId = entries[entries.length - 1]?.id;
  const row = (
    id: string,
    first: boolean,
    children: React.ReactNode,
    cause?: NoteRevisionSummary["cause"],
  ) => (
    <button
      key={id}
      type="button"
      role="option"
      data-v={id}
      aria-selected={selectedId === id}
      tabIndex={selectedId === id ? 0 : -1}
      className={cn(
        "hs-row",
        first && "first",
        (id === lastId || (!entries.length && first)) && !hasMore && "last",
      )}
      onClick={() => onPick(id)}
    >
      {children}
      {cause && cause !== "edit" && (
        <span className={cn("hs-tag", cause === "conflict" && "warn")}>
          {revisionLabel(cause)}
        </span>
      )}
    </button>
  );

  const isEmpty = !loading && !failed && !entries.length;
  return (
    <>
      <div
        ref={listRef}
        className="hs-list scrollbar-slim"
        role="listbox"
        aria-label="Versions"
      >
        {row(
          CURRENT_ENTRY_ID,
          true,
          <>
            <span className="hs-cur" aria-hidden>
              <SquarePen />
            </span>
            <span className="hs-tx">
              <b>Current version</b>
              <span>{currentWhen}</span>
            </span>
          </>,
        )}
        {loading ? (
          <SkeletonRows
            count={4}
            className={cn("px-2.5 py-3", !showLoadingShapes && "invisible")}
          />
        ) : failed ? (
          <LoadFailedRow
            message="Couldn’t load versions."
            onRetry={onRetry}
            isRetrying={retrying}
            className="mx-1 mt-2"
          />
        ) : !entries.length ? null : (
          groupTimelineByDay(entries).map((day) => (
            <React.Fragment key={day.key}>
              <div className="hs-day" role="presentation">
                {day.label}
              </div>
              {day.entries.map((entry) =>
                row(
                  entry.id,
                  false,
                  <>
                    {showAuthors && entry.author ? (
                      <Avatar
                        id={entry.author.id}
                        name={entry.author.name}
                        src={entry.author.profileImage}
                        className="av size-6.5 text-[11px]"
                      />
                    ) : (
                      <span className="hs-dot" aria-hidden />
                    )}
                    <span className="hs-tx">
                      <b>{revisionTime(entry)}</b>
                      {showAuthors && (
                        <span>{revisionAuthorName(entry, currentUserId)}</span>
                      )}
                    </span>
                  </>,
                  entry.revision?.cause,
                ),
              )}
            </React.Fragment>
          ))
        )}
        {moreFailed ? (
          <LoadFailedRow
            message="Couldn’t load older versions."
            onRetry={onMore}
            isRetrying={fetchingMore}
            className="mx-1 my-2"
          />
        ) : (
          hasMore && (
            <div ref={endRef} className="py-3">
              {fetchingMore && (
                <SkeletonRows
                  count={2}
                  className={cn("px-2.5", !showMoreShapes && "invisible")}
                />
              )}
            </div>
          )
        )}
      </div>
      {isEmpty && (
        <EmptyState
          size="sm"
          icon={<History />}
          title="No earlier versions yet"
          className="hs-none"
        >
          A version is kept each time the note changes, for 90 days.
        </EmptyState>
      )}
    </>
  );
}

type Segment =
  | {
      list: "check" | "bullet" | "ordered";
      items: { i: number; line: VersionLine }[];
    }
  | { i: number; line: VersionLine }
  | { fold: Fold };

const MARK = {
  same: "",
  added: "dl add",
  removed: "dl del",
  changed: "dl chg",
} as const;
const isList = (t: NoteBlock["type"]): t is "check" | "bullet" | "ordered" =>
  t === "check" || t === "bullet" || t === "ordered";

function VersionBody({
  lines,
  open,
  onOpen,
  whole,
}: {
  lines: VersionLine[];
  open?: ReadonlySet<number>;
  onOpen?: (fold: Fold) => void;
  whole?: boolean;
}) {
  const docRef = React.useRef<HTMLDivElement>(null);
  useHighlightPaint(docRef, docRef, [lines, open?.size, whole]);
  // An opened fold's button goes away; focus moves to its first line.
  const focusLineRef = React.useRef<number | null>(null);
  React.useLayoutEffect(() => {
    const index = focusLineRef.current;
    if (index === null) return;
    const line = docRef.current?.querySelector<HTMLElement>(
      `[data-line="${index}"]`,
    );
    if (!line) return;
    focusLineRef.current = null;
    line.tabIndex = -1;
    line.focus();
  });
  const items = whole ? lines.map((_, i) => i) : foldLines(lines, open);
  const segments: Segment[] = [];
  for (const item of items) {
    if (typeof item !== "number") {
      segments.push({ fold: item });
      continue;
    }
    const line = lines[item];
    const last = segments[segments.length - 1];
    if (isList(line.block.type)) {
      if (last && "list" in last && last.list === line.block.type)
        last.items.push({ i: item, line });
      else segments.push({ list: line.block.type, items: [{ i: item, line }] });
    } else segments.push({ i: item, line });
  }

  return (
    <div ref={docRef} className="doc">
      {segments.map((segment) => {
        if ("fold" in segment)
          return (
            <button
              key={`f${segment.fold.from}`}
              type="button"
              className="fold"
              onClick={() => {
                focusLineRef.current = segment.fold.from;
                onOpen?.(segment.fold);
              }}
            >
              <span>
                <ChevronsUpDown aria-hidden />
                {segment.fold.to - segment.fold.from} unchanged lines
              </span>
            </button>
          );
        if ("list" in segment) {
          const Tag = segment.list === "ordered" ? "ol" : "ul";
          return (
            <Tag
              key={`l${segment.items[0].i}`}
              className={
                { check: "lst ck", bullet: "lst bul", ordered: "lst num" }[
                  segment.list
                ]
              }
            >
              {segment.items.map(({ i, line }) => (
                <li
                  key={i}
                  data-line={i}
                  data-lvl={line.block.level}
                  style={{ "--lvl": line.block.level } as React.CSSProperties}
                  className={cn(line.block.done && "done", MARK[line.kind])}
                >
                  {line.block.type === "check" ? (
                    <span className="box" aria-hidden />
                  ) : (
                    <span className="mk" aria-hidden>
                      {line.block.type === "ordered" ? line.block.marker : ""}
                    </span>
                  )}
                  <span className="tx">
                    <MarkLabel kind={line.kind} />
                    {line.block.type === "check" && (
                      <span className="sr-only">
                        {line.block.done ? "Checked: " : "Not checked: "}
                      </span>
                    )}
                    <LineText line={line} />
                  </span>
                </li>
              ))}
            </Tag>
          );
        }
        const { line } = segment;
        const block = line.block;
        const markClass = MARK[line.kind] || undefined;
        const text = (
          <>
            <MarkLabel kind={line.kind} />
            <LineText line={line} />
          </>
        );
        if (block.type === "h1" || block.type === "h2" || block.type === "h3") {
          const Tag = ({ h1: "h3", h2: "h4", h3: "h5" } as const)[block.type];
          return (
            <Tag
              key={segment.i}
              data-line={segment.i}
              className={cn(`x-${block.type}`, markClass)}
            >
              {text}
            </Tag>
          );
        }
        if (block.type === "quote")
          return (
            <blockquote
              key={segment.i}
              data-line={segment.i}
              className={markClass}
            >
              {text}
            </blockquote>
          );
        if (block.type === "code")
          return (
            <div
              key={segment.i}
              data-line={segment.i}
              className={cn("code-wrap", markClass)}
            >
              <pre className="code">{text}</pre>
            </div>
          );
        return (
          <p key={segment.i} data-line={segment.i} className={markClass}>
            {text}
          </p>
        );
      })}
    </div>
  );
}

function MarkLabel({ kind }: { kind: VersionLine["kind"] }) {
  if (kind === "same") return null;
  return (
    <span className="sr-only">
      {{ added: "Added: ", removed: "Removed: ", changed: "Changed: " }[kind]}
    </span>
  );
}

function LineText({ line }: { line: VersionLine }) {
  if (line.kind !== "changed")
    return <TextRuns runs={line.block.runs} card={false} />;
  return line.words.map((word: WordPart, i) =>
    word.kind === "same" ? (
      <React.Fragment key={i}>{word.text}</React.Fragment>
    ) : word.kind === "del" ? (
      <del key={i}>{word.text}</del>
    ) : (
      <ins key={i}>{word.text}</ins>
    ),
  );
}
