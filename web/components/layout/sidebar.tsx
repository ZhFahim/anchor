"use client";

import * as MenuPrimitive from "@radix-ui/react-dropdown-menu";
import { useMutation, useQueryClient } from "@tanstack/react-query";
import {
  Archive,
  ChevronsUpDown,
  CloudOff,
  Ellipsis,
  Hash,
  LogOut,
  Monitor,
  Moon,
  NotebookPen,
  Pencil,
  Plus,
  Settings,
  ShieldCheck,
  Sun,
  Trash2,
} from "lucide-react";
import Link from "next/link";
import { usePathname, useRouter, useSearchParams } from "next/navigation";
import { useTranslations } from "next-intl";
import { useTheme } from "next-themes";
import * as React from "react";
import { Avatar } from "@/components/ui/avatar";
import { IconButton } from "@/components/ui/button";
import { ConfirmationDialog } from "@/components/ui/confirmation-dialog";
import {
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuItem,
  DropdownMenuLabel,
  DropdownMenuSeparator,
  DropdownMenuTrigger,
} from "@/components/ui/dropdown-menu";
import { LoadFailedRow } from "@/components/ui/empty-state";
import { useGlidingFill } from "@/components/ui/segmented-control";
import { toast } from "@/components/ui/toast";
import { Tip } from "@/components/ui/tooltip";
import { useAuth } from "@/features/auth";
import { useSyncStatus, useUnsavedCount } from "@/features/sync";
import {
  deleteTag,
  sortTagsByName,
  type Tag,
  TagDialog,
  tagColorName,
  tagColorStyle,
  updateTag,
  useTags,
} from "@/features/tags";
import { TAG_COLORS } from "@/lib/design/tokens";
import { useLastShown } from "@/lib/hooks/use-last-shown";
import { rememberNewNoteButton } from "@/lib/morph";
import { glidePill, prefersReducedMotion } from "@/lib/motion";
import { isMac } from "@/lib/platform";
import { switchTheme } from "@/lib/theme";
import { cn } from "@/lib/utils";
import { Brand } from "./brand";
import { useSidebarPeek } from "./use-sidebar-peek";

interface SidebarProps {
  folded?: boolean;
  onToggleFold?: () => void;
  drawer?: boolean;
  onNavigate?: () => void;
}

const PAGES = [
  { href: "/notes", labelKey: "navNotes", icon: NotebookPen },
  { href: "/archive", labelKey: "navArchive", icon: Archive },
  { href: "/trash", labelKey: "navTrash", icon: Trash2 },
] as const;

export function newNoteHref(pathname: string, tagId?: string | null) {
  return pathname === "/notes" && tagId
    ? `/notes/new?tagId=${encodeURIComponent(tagId)}`
    : "/notes/new";
}

// 11.5px puts each icon at the center of the folded rail.
const rowClass =
  "relative flex h-8.5 min-w-0 cursor-pointer items-center gap-3 whitespace-nowrap rounded-md pr-2 pl-[11.5px] text-left font-medium text-muted-foreground text-ui no-underline transition-[background-color,color,box-shadow] duration-(--duration-hover) hover:bg-foreground/6 hover:text-foreground [&>svg]:size-4.25 [&>svg]:shrink-0 aria-[current=page]:bg-card aria-[current=page]:font-semibold aria-[current=page]:text-foreground aria-[current=page]:shadow-[var(--sh-xs),0_0_0_1px_color-mix(in_srgb,var(--border)_55%,transparent)] aria-[current=page]:[&>svg:first-child]:text-accent-strong";
const fadeClass =
  "transition-opacity delay-75 duration-(--duration-fade) group-data-narrow/sb:opacity-0 group-data-narrow/sb:delay-0 group-data-narrow/sb:duration-(--duration-exit)";
const hideClass =
  "transition-[opacity,visibility] delay-75 duration-(--duration-fade) group-data-narrow/sb:invisible group-data-narrow/sb:opacity-0 group-data-narrow/sb:delay-0 group-data-narrow/sb:duration-(--duration-exit)";
// Narrow, labels stay for screen readers.
const labelClass = cn("min-w-0 flex-1 truncate", fadeClass);
const foldLabelClass =
  "col-start-1 row-start-1 truncate transition-opacity duration-(--duration-hover) group-data-narrow/sb:delay-(--duration-exit)";
// Hidden, it must stay focusable: focus returns to it from its menu and dialogs.
const tagMenuButtonClass = cn(
  "grid h-6 w-0 cursor-pointer place-items-center overflow-hidden rounded-sm text-muted-foreground opacity-0 hover:bg-foreground/8 hover:text-foreground [&>svg]:size-3.75 [&>svg]:flex-none",
  "group-focus-within/tag:mr-1 group-focus-within/tag:w-6 group-focus-within/tag:opacity-100",
  "group-hover/tag:mr-1 group-hover/tag:w-6 group-hover/tag:opacity-100",
  "group-data-menu/tag:mr-1 group-data-menu/tag:w-6 group-data-menu/tag:opacity-100",
  "[@media(hover:none)]:mr-1 [@media(hover:none)]:ml-1 [@media(hover:none)]:w-6 [@media(hover:none)]:opacity-100",
);
const pillClass =
  "rounded-md bg-card shadow-[var(--sh-xs),0_0_0_1px_color-mix(in_srgb,var(--border)_55%,transparent)]";

function SidebarIcon({ isOpen }: { isOpen: boolean }) {
  return (
    <svg
      viewBox="0 0 24 24"
      fill="none"
      stroke="currentColor"
      strokeWidth="2"
      strokeLinecap="round"
      strokeLinejoin="round"
      aria-hidden
    >
      <path
        d="M5 3h4v18H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2z"
        fill="currentColor"
        fillOpacity={0.35}
        stroke="none"
        className={cn(
          "origin-[3px_12px] transition-transform duration-(--duration-header) ease-standard transform-view",
          !isOpen && "scale-x-0",
        )}
      />
      <rect width="18" height="18" x="3" y="3" rx="2" />
      <path d="M9 3v18" />
    </svg>
  );
}

/** Elements marked data-hold-width keep their width while the sidebar moves and take the new one once it stops. */
function holdWidths() {
  const held = [
    ...document.querySelectorAll<HTMLElement>("[data-hold-width]"),
  ].filter((element) => !element.style.width);
  for (const element of held) {
    element.style.width = `${element.getBoundingClientRect().width}px`;
    if (element.parentElement) element.parentElement.style.overflowX = "clip";
  }
  return () => {
    for (const element of held) {
      element.style.width = "";
      if (element.parentElement) element.parentElement.style.overflowX = "";
    }
  };
}

export function Sidebar({
  folded = false,
  onToggleFold,
  drawer = false,
  onNavigate,
}: SidebarProps) {
  const t = useTranslations();
  const pathname = usePathname();
  const searchParams = useSearchParams();
  const router = useRouter();
  const { user, logout } = useAuth();
  const queryClient = useQueryClient();
  const online = useSyncStatus((s) => s.online);
  const unsaved = useUnsavedCount();
  const tagsQuery = useTags();
  const tags = tagsQuery.data ?? [];
  const tagsLoaded = tagsQuery.data !== undefined;
  // isError clears while Try again runs.
  const tagsFailed = !tagsLoaded && tagsQuery.errorUpdatedAt > 0;
  const sortedTags = React.useMemo(() => sortTagsByName(tags), [tags]);

  const [tagDialog, setTagDialog] = React.useState<{ tag: Tag | null } | null>(
    null,
  );
  const [tagToDelete, setTagToDelete] = React.useState<Tag | null>(null);
  const [menuTagId, setMenuTagId] = React.useState<string | null>(null);
  // A dialog from a tag's menu opens once the menu has closed and focus is back.
  const afterTagMenu = React.useRef<(() => void) | null>(null);

  const tagId = searchParams?.get("tagId");
  const currentRow =
    pathname === "/notes" && tagId
      ? `tag:${tagId}`
      : (PAGES.find((p) => pathname === p.href)?.href ?? "");

  const cachedTag = (id: string) =>
    queryClient.getQueryData<Tag[]>(["tags"])?.find((t) => t.id === id);
  const updateCachedTag = (id: string, change: Partial<Tag>) =>
    queryClient.setQueryData<Tag[]>(["tags"], (list) =>
      list?.map((t) => (t.id === id ? { ...t, ...change } : t)),
    );
  const colorMutation = useMutation({
    // Quick clicks save one after another, each on the version the last saved.
    mutationKey: ["tag-color"],
    scope: { id: "tag-color" },
    mutationFn: ({ tag, color }: { tag: Tag; color: string }) =>
      updateTag(tag.id, {
        color,
        baseVersion: cachedTag(tag.id)?.version ?? tag.version,
      }),
    onMutate: async ({ tag, color }) => {
      await queryClient.cancelQueries({ queryKey: ["tags"] });
      const previousColor = cachedTag(tag.id)?.color;
      updateCachedTag(tag.id, { color });
      return { previousColor };
    },
    onSuccess: (saved) => updateCachedTag(saved.id, { version: saved.version }),
    onError: (_, { tag }, context) => {
      updateCachedTag(tag.id, { color: context?.previousColor });
      toast.error(t("navTagColorFailed", { name: tag.name }));
    },
    onSettled: () => {
      if (queryClient.isMutating({ mutationKey: ["tag-color"] }) <= 1)
        queryClient.invalidateQueries({ queryKey: ["tags"] });
    },
  });
  const deleteMutation = useMutation({
    mutationFn: (tag: Tag) => deleteTag(tag.id),
    onSuccess: async (_, tag) => {
      await Promise.all([
        queryClient.invalidateQueries({ queryKey: ["tags"] }),
        queryClient.invalidateQueries({ queryKey: ["notes"] }),
      ]);
      if (tagId === tag.id) router.push("/notes");
      setTagToDelete(null);
    },
    onError: (_, tag) =>
      toast.error(t("navTagDeleteFailed", { name: tag.name })),
  });

  const root = React.useRef<HTMLElement>(null);
  const { isPeeking, stopPeeking, onMenuClose } = useSidebarPeek(
    root,
    folded && !drawer,
  );
  const isNarrow = folded && !isPeeking;
  React.useEffect(() => {
    if (tagDialog || tagToDelete) stopPeeking();
  }, [tagDialog, tagToDelete, stopPeeking]);
  const lastRow = React.useRef<{ key: string; folded: boolean } | null>(null);
  React.useLayoutEffect(() => {
    const el = root.current;
    const previous = lastRow.current;
    lastRow.current = { key: currentRow, folded };
    if (
      !el ||
      !previous ||
      previous.key === currentRow ||
      previous.folded !== folded
    )
      return;
    const from = el.querySelector<HTMLElement>(
      `[data-row="${CSS.escape(previous.key)}"]`,
    );
    const to = el.querySelector<HTMLElement>(
      `[data-row="${CSS.escape(currentRow)}"]`,
    );
    if (from && to) glidePill(el, from, to, pillClass);
  }, [currentRow, folded]);

  const wasFolded = React.useRef(folded);
  const releaseHeld = React.useRef<(() => void) | null>(null);
  React.useLayoutEffect(() => {
    const el = root.current;
    if (!el || wasFolded.current === folded) return;
    wasFolded.current = folded;
    if (prefersReducedMotion()) return;
    releaseHeld.current ??= holdWidths();
    el.dataset.moving = "";
    let isCurrent = true;
    const finish = () => {
      if (!isCurrent) return;
      delete el.dataset.moving;
      releaseHeld.current?.();
      releaseHeld.current = null;
    };
    const move = el
      .getAnimations()
      .find(
        (animation) =>
          animation instanceof CSSTransition &&
          (animation.transitionProperty === "width" ||
            animation.transitionProperty === "margin-right"),
      );
    if (move) move.finished.then(finish, finish);
    else finish();
    return () => {
      isCurrent = false;
    };
  }, [folded]);
  React.useEffect(() => () => releaseHeld.current?.(), []);

  const countNotes = (tag: Tag) => tag._count?.notes ?? 0;

  return (
    <aside
      ref={root}
      data-folded={folded || undefined}
      data-narrow={isNarrow || undefined}
      aria-label={t("navSidebar")}
      className={cn(
        "group/sb relative isolate z-(--z-drawer) flex min-h-0 flex-none flex-col gap-0.5 overflow-hidden bg-sidebar px-3 pt-3 pb-2.5 transition-[width,margin-right,border-radius,box-shadow] duration-(--duration-header) ease-standard data-moving:[&_.truncate]:text-clip",
        drawer
          ? "h-full w-sidebar-drawer pt-3.5"
          : isNarrow
            ? "w-sidebar-folded"
            : "w-sidebar",
        // Overlaps the page instead of pushing it.
        isPeeking &&
          "mr-[calc(var(--size-sidebar-folded)-var(--size-sidebar))] rounded-r-3xl shadow-[var(--sh-edge),var(--sh-menu)]",
      )}
    >
      <div className="flex min-h-10.5 items-center pt-0.5 pr-0.5 pb-3 pl-1.5">
        <Brand
          href="/notes"
          onNavigate={onNavigate}
          nameClassName={fadeClass}
        />
      </div>

      <Tip
        label={t("navNewNoteShortcut", { shortcut: "N" })}
        side="right"
        isDisabled={!isNarrow}
        isFocusOnly
      >
        <Link
          href={newNoteHref(pathname, tagId)}
          onClick={(e) => {
            rememberNewNoteButton(e.currentTarget);
            stopPeeking();
            onNavigate?.();
          }}
          aria-keyshortcuts="N"
          data-slot="new-note"
          data-new-note="sidebar"
          className="mb-3 flex h-9.5 items-center gap-2 overflow-hidden whitespace-nowrap rounded-md bg-foreground pr-2.5 pl-[11.5px] font-semibold text-card text-ui no-underline shadow-control transition-[background-color,transform] duration-(--duration-hover) hover:bg-[color-mix(in_srgb,var(--foreground)_88%,var(--card))] active:scale-[.98] [&>svg]:size-4.25 [&>svg]:shrink-0"
        >
          <Plus aria-hidden />
          <span className={labelClass}>{t("navNewNote")}</span>
          {!drawer && (
            <kbd
              aria-hidden
              className={cn("ml-auto bg-card/16 text-inherit", hideClass)}
            >
              N
            </kbd>
          )}
        </Link>
      </Tip>

      <nav aria-label={t("navPages")} className="grid gap-px">
        {PAGES.map(({ href, labelKey, icon: Icon }) => (
          <Tip
            key={href}
            label={t(labelKey)}
            side="right"
            isDisabled={!isNarrow}
            isFocusOnly
          >
            <Link
              href={href}
              onClick={onNavigate}
              data-row={href}
              aria-current={currentRow === href ? "page" : undefined}
              className={rowClass}
            >
              <Icon aria-hidden />
              <span className={labelClass}>{t(labelKey)}</span>
            </Link>
          </Tip>
        ))}
      </nav>

      <div className="relative mt-3.5 flex h-7.5 items-center gap-1.5 whitespace-nowrap pr-0.5 pl-[11.5px] text-label text-muted-foreground uppercase">
        <span aria-hidden className={cn("flex-1", hideClass)}>
          {t("navTags")}
        </span>
        <span className={hideClass}>
          <Tip label={t("navNewTag")}>
            <IconButton
              size="sm"
              label={t("navNewTag")}
              onClick={() => setTagDialog({ tag: null })}
            >
              <Plus />
            </IconButton>
          </Tip>
        </span>
        <span
          aria-hidden
          className="absolute inset-x-0 top-2 h-px bg-border/70 opacity-0 transition-opacity duration-(--duration-exit) group-data-narrow/sb:opacity-100 group-data-narrow/sb:delay-100 group-data-narrow/sb:duration-(--duration-fade)"
        />
      </div>

      <nav
        aria-label={t("navTags")}
        className="-mx-1 grid min-h-0 flex-1 content-start gap-px overflow-auto px-1 pb-2 scrollbar-none mask-[linear-gradient(#000_calc(100%-22px),transparent)]"
      >
        {tagsFailed && (
          <>
            <LoadFailedRow
              message={t("navTagsLoadFailed")}
              onRetry={() => tagsQuery.refetch()}
              isRetrying={tagsQuery.isFetching}
              className="mt-0.5 gap-2 py-2 pr-2 pl-[11.5px] group-data-narrow/sb:hidden [&>span]:min-w-fit"
            />
            <Tip label={t("navTagsLoadFailedRetry")} side="right">
              <IconButton
                size="sm"
                label={t("navTagsLoadFailedRetry")}
                aria-busy={tagsQuery.isFetching || undefined}
                onClick={() => tagsQuery.refetch()}
                className="hidden justify-self-center group-data-narrow/sb:inline-grid"
              >
                <CloudOff />
              </IconButton>
            </Tip>
          </>
        )}
        {tagsLoaded && sortedTags.length === 0 && (
          <p className="m-0 py-1 pr-2.5 pl-[11.5px] text-muted-foreground text-small group-data-narrow/sb:hidden">
            {t("navNoTags")}
          </p>
        )}
        {sortedTags.map((tag) => {
          const key = `tag:${tag.id}`;
          const isCurrent = currentRow === key;
          const noteCount = countNotes(tag);
          return (
            <div
              key={tag.id}
              data-row={key}
              aria-current={isCurrent ? "page" : undefined}
              data-menu={menuTagId === tag.id || undefined}
              style={tagColorStyle(tag.color)}
              className={cn(
                rowClass,
                "tag-color group/tag h-8 p-0 text-control",
              )}
            >
              <Tip
                label={t("navTagTip", { name: tag.name, count: noteCount })}
                side="right"
                isDisabled={!isNarrow}
                isFocusOnly
              >
                <Link
                  href={`/notes?tagId=${tag.id}`}
                  onClick={onNavigate}
                  aria-current={isCurrent ? "page" : undefined}
                  className="flex h-full min-w-0 flex-1 items-center gap-3 pl-[11.5px] text-inherit no-underline"
                >
                  <span
                    aria-hidden
                    className="inline-grid w-4.25 shrink-0 place-items-center text-(--hash) [&>svg]:size-3.75 [&>svg]:stroke-[2.75]"
                  >
                    <Hash />
                  </span>
                  <span className={labelClass}>{tag.name}</span>
                </Link>
              </Tip>
              <span
                className={cn(
                  "flex items-center group-data-narrow/sb:absolute group-data-narrow/sb:inset-y-0 group-data-narrow/sb:right-0",
                  hideClass,
                )}
              >
                <span className="mr-1 min-w-6 text-center font-medium text-muted-foreground text-small tabular-nums group-focus-within/tag:hidden group-hover/tag:hidden group-data-menu/tag:hidden">
                  {noteCount}
                </span>
                <DropdownMenu
                  onOpenChange={(open) => {
                    setMenuTagId(open ? tag.id : null);
                    if (!open) onMenuClose();
                  }}
                >
                  <DropdownMenuTrigger asChild>
                    <button
                      type="button"
                      aria-label={t("navTagOptions", { name: tag.name })}
                      className={tagMenuButtonClass}
                    >
                      <Ellipsis />
                    </button>
                  </DropdownMenuTrigger>
                  <DropdownMenuContent
                    className="w-57"
                    aria-label={t("navTagMenu", { name: tag.name })}
                    onCloseAutoFocus={() => {
                      const openDialog = afterTagMenu.current;
                      afterTagMenu.current = null;
                      openDialog?.();
                    }}
                  >
                    <DropdownMenuItem
                      onSelect={() => {
                        afterTagMenu.current = () => setTagDialog({ tag });
                      }}
                    >
                      <Pencil />
                      {t("navTagRename")}
                    </DropdownMenuItem>
                    <DropdownMenuLabel aria-hidden>
                      {t("navTagColor")}
                    </DropdownMenuLabel>
                    <MenuPrimitive.RadioGroup
                      value={tag.color?.toUpperCase()}
                      onValueChange={(color) =>
                        colorMutation.mutate({ tag, color })
                      }
                      className="grid grid-cols-[repeat(6,24px)] gap-2 px-2.5 pt-1.5 pb-2"
                    >
                      {TAG_COLORS.map((color) => (
                        <MenuPrimitive.RadioItem
                          key={color.stored}
                          value={color.stored}
                          onSelect={(e) => e.preventDefault()}
                          aria-label={tagColorName(color.stored, t)}
                          style={tagColorStyle(color.stored)}
                          className="tag-color grid size-6 cursor-pointer place-items-center rounded-full bg-(--tint) text-(--hash) shadow-[inset_0_0_0_1px_color-mix(in_srgb,var(--hash)_30%,transparent)] transition-transform duration-(--duration-hover) ease-standard hover:scale-110 data-highlighted:scale-110 focus-visible:outline-2 focus-visible:outline-ring focus-visible:outline-offset-2 data-[state=checked]:shadow-[0_0_0_2px_var(--card),0_0_0_3.5px_var(--accent-strong)] [&>svg]:size-3.25 [&>svg]:stroke-3"
                        >
                          <Hash aria-hidden />
                        </MenuPrimitive.RadioItem>
                      ))}
                    </MenuPrimitive.RadioGroup>
                    <DropdownMenuSeparator />
                    <DropdownMenuItem
                      tone="danger"
                      onSelect={() => {
                        afterTagMenu.current = () => setTagToDelete(tag);
                      }}
                    >
                      <Trash2 />
                      {t("navDeleteTag")}
                    </DropdownMenuItem>
                  </DropdownMenuContent>
                </DropdownMenu>
              </span>
            </div>
          );
        })}
      </nav>

      <div className="mt-auto grid gap-1.5 pt-2">
        {!online && (
          <div
            role="status"
            className="flex items-center gap-2 overflow-hidden whitespace-nowrap rounded-md bg-warn py-2 pr-2.5 pl-[12.5px] text-small text-warn-foreground leading-[1.35] [&>svg]:size-3.75 [&>svg]:shrink-0"
          >
            <CloudOff aria-hidden />
            <span className={labelClass}>
              {unsaved
                ? t("navOfflineUnsaved", { count: unsaved })
                : t("navOffline")}
            </span>
          </div>
        )}
        {onToggleFold && (
          <Tip
            label={t("navExpandSidebarShortcut", {
              shortcut: isMac() ? "⌘\\" : `${t("uiCtrlKey")}+\\`,
            })}
            side="right"
            isDisabled={!isNarrow}
            isFocusOnly
          >
            <button
              type="button"
              aria-label={
                !folded
                  ? t("navCollapseSidebar")
                  : isPeeking
                    ? t("navKeepSidebarOpen")
                    : t("navExpandSidebar")
              }
              aria-keyshortcuts={isMac() ? "Meta+\\" : "Control+\\"}
              onClick={onToggleFold}
              className={cn(
                rowClass,
                "group/fold h-8 font-normal text-control",
              )}
            >
              <SidebarIcon isOpen={!folded} />
              <span className={cn("grid min-w-0 flex-1", fadeClass)}>
                <span
                  className={cn(
                    foldLabelClass,
                    isPeeking ? "opacity-0" : "opacity-100",
                  )}
                >
                  {t("navCollapse")}
                </span>
                <span
                  className={cn(
                    foldLabelClass,
                    isPeeking ? "opacity-100" : "opacity-0",
                  )}
                >
                  {t("navKeepOpen")}
                </span>
              </span>
              <kbd
                aria-hidden
                className="ml-auto opacity-0 transition-opacity duration-(--duration-hover) group-hover/fold:opacity-100 group-focus-visible/fold:opacity-100 group-data-narrow/sb:invisible"
              >
                {isMac() ? "⌘\\" : `${t("uiCtrlKey")} \\`}
              </kbd>
            </button>
          </Tip>
        )}
        {user && (
          <AccountMenu
            user={user}
            isNarrow={isNarrow}
            onSignOut={logout}
            onNavigate={onNavigate}
            onClose={onMenuClose}
          />
        )}
      </div>

      {tagDialog && (
        <TagDialog
          open
          tag={tagDialog.tag}
          tags={tags}
          onOpenChange={(open) => !open && setTagDialog(null)}
        />
      )}
      <ConfirmationDialog
        open={!!tagToDelete}
        onOpenChange={(open) => !open && setTagToDelete(null)}
        title={t("navDeleteTagTitle", { name: tagToDelete?.name ?? "" })}
        description={
          tagToDelete && countNotes(tagToDelete)
            ? t("navDeleteTagMessage", { count: countNotes(tagToDelete) })
            : t("navDeleteTagUnused")
        }
        confirmLabel={t("navDeleteTag")}
        busyLabel={t("uiDeleting")}
        isPending={deleteMutation.isPending}
        onConfirm={() => tagToDelete && deleteMutation.mutate(tagToDelete)}
      />
    </aside>
  );
}

function AccountMenu({
  user,
  isNarrow,
  onSignOut,
  onNavigate,
  onClose,
}: {
  user: {
    id: string;
    name: string;
    email: string;
    profileImage?: string;
    isAdmin?: boolean;
  };
  isNarrow: boolean;
  onSignOut: () => void;
  onNavigate?: () => void;
  onClose: () => void;
}) {
  const t = useTranslations();
  const router = useRouter();
  const { theme = "system", setTheme } = useTheme();
  const [isOpen, setIsOpen] = React.useState(false);
  // Kept while the menu closes: the sidebar can narrow under it.
  const opensRight = useLastShown(isNarrow, isOpen);
  const goTo = (href: string) => {
    onNavigate?.();
    router.push(href);
  };
  return (
    <DropdownMenu
      open={isOpen}
      onOpenChange={(open) => {
        setIsOpen(open);
        if (!open) onClose();
      }}
    >
      <Tip label={user.name} side="right" isDisabled={!isNarrow} isFocusOnly>
        <DropdownMenuTrigger asChild>
          <button
            type="button"
            className="flex w-full min-w-0 cursor-pointer items-center gap-2.5 overflow-hidden whitespace-nowrap rounded-md bg-transparent py-1.5 pr-2 pl-1.25 text-left hover:bg-foreground/6 aria-expanded:bg-foreground/6"
          >
            <Avatar id={user.id} name={user.name} src={user.profileImage} />
            <span
              className={cn("grid min-w-0 flex-1 leading-tight", fadeClass)}
            >
              <b className="truncate font-semibold text-control">{user.name}</b>
              <small className="truncate text-muted-foreground text-small">
                {user.email}
              </small>
            </span>
            <ChevronsUpDown
              aria-hidden
              className={cn(
                "size-3.75 shrink-0 text-muted-foreground",
                hideClass,
              )}
            />
          </button>
        </DropdownMenuTrigger>
      </Tip>
      <DropdownMenuContent
        side={opensRight ? "right" : "top"}
        align={opensRight ? "end" : "start"}
        className="w-64"
        aria-label={t("navAccount")}
      >
        <div className="mb-1 flex items-center gap-2.5 rounded-lg bg-foreground/4 p-2.5">
          <Avatar id={user.id} name={user.name} src={user.profileImage} />
          <div className="grid min-w-0 leading-[1.3]">
            <b className="truncate font-semibold text-ui">{user.name}</b>
            <small className="truncate text-muted-foreground text-small">
              {user.email}
            </small>
          </div>
        </div>
        <DropdownMenuSeparator />
        <DropdownMenuItem onSelect={() => goTo("/settings")}>
          <Settings />
          {t("navSettings")}
        </DropdownMenuItem>
        {user.isAdmin && (
          <DropdownMenuItem onSelect={() => goTo("/admin")}>
            <ShieldCheck />
            {t("navAdmin")}
          </DropdownMenuItem>
        )}
        <ThemeChoices
          value={theme}
          onChange={(value) => switchTheme(value, setTheme)}
        />
        <DropdownMenuSeparator />
        <DropdownMenuItem tone="danger" onSelect={onSignOut}>
          <LogOut />
          {t("navSignOut")}
        </DropdownMenuItem>
      </DropdownMenuContent>
    </DropdownMenu>
  );
}

const THEMES = [
  { value: "light", labelKey: "navThemeLight", icon: Sun },
  { value: "dark", labelKey: "navThemeDark", icon: Moon },
  { value: "system", labelKey: "navThemeSystem", icon: Monitor },
] as const;

const themeItemClass =
  "inline-flex h-7 items-center justify-center rounded-md px-2 [&>svg]:size-3.75";

function ThemeChoices({
  value,
  onChange,
}: {
  value: string;
  onChange: (value: string) => void;
}) {
  const t = useTranslations();
  const root = React.useRef<HTMLDivElement>(null);
  const fill = useGlidingFill(root, value);
  const labelId = React.useId();

  const onKeyDown = (e: React.KeyboardEvent<HTMLDivElement>) => {
    if (e.key !== "ArrowLeft" && e.key !== "ArrowRight") return;
    const items = [
      ...e.currentTarget.querySelectorAll<HTMLElement>("[data-seg]"),
    ];
    const index = items.indexOf(e.target as HTMLElement);
    if (index < 0) return;
    e.preventDefault();
    const step = e.key === "ArrowRight" ? 1 : -1;
    items[(index + step + items.length) % items.length].focus();
  };

  return (
    <div className="flex items-center justify-between gap-3 py-1 pr-1 pl-2.5 text-ui">
      <span id={labelId}>{t("navTheme")}</span>
      <MenuPrimitive.RadioGroup
        ref={root}
        data-slot="segmented-control"
        aria-labelledby={labelId}
        value={value}
        onValueChange={onChange}
        onKeyDown={onKeyDown}
        className="relative inline-flex gap-0.5 rounded-lg bg-muted p-0.75"
      >
        {THEMES.map(({ value: option, labelKey, icon: Icon }) => (
          <Tip key={option} label={t(labelKey)}>
            <MenuPrimitive.RadioItem
              value={option}
              data-seg={option}
              aria-label={t(labelKey)}
              onSelect={(e) => e.preventDefault()}
              className={cn(
                themeItemClass,
                "cursor-pointer text-muted-foreground transition-[background-color,color] duration-(--duration-hover) hover:bg-foreground/5 hover:text-foreground focus-visible:outline-2 focus-visible:outline-ring data-highlighted:bg-foreground/5 data-highlighted:text-foreground",
              )}
            >
              <Icon aria-hidden />
            </MenuPrimitive.RadioItem>
          </Tip>
        ))}
        {fill.clip && (
          <div
            ref={fill.fillRef}
            aria-hidden
            data-slot="segmented-fill"
            className="pointer-events-none absolute inset-0 flex gap-0.5 bg-primary p-0.75 text-card"
            style={{ clipPath: fill.clip }}
          >
            {THEMES.map(({ value: option, icon: Icon }) => (
              <span key={option} className={themeItemClass}>
                <Icon aria-hidden />
              </span>
            ))}
          </div>
        )}
      </MenuPrimitive.RadioGroup>
    </div>
  );
}
