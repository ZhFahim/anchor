"use client";

import {
  keepPreviousData,
  useMutation,
  useQuery,
  useQueryClient,
} from "@tanstack/react-query";
import { isYesterday } from "date-fns";
import {
  Check,
  Ellipsis,
  Hash,
  KeyRound,
  NotebookPen,
  Pencil,
  Search,
  ShieldAlert,
  ShieldCheck,
  Trash2,
  UserPlus,
  UserRound,
  UserRoundPlus,
} from "lucide-react";
import { useLocale, useTranslations } from "next-intl";
import * as React from "react";
import { Avatar } from "@/components/ui/avatar";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { ConfirmationDialog } from "@/components/ui/confirmation-dialog";
import {
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuItem,
  DropdownMenuSeparator,
  DropdownMenuTrigger,
} from "@/components/ui/dropdown-menu";
import { LoadFailedRow } from "@/components/ui/empty-state";
import { Input } from "@/components/ui/input";
import { SkeletonRows } from "@/components/ui/skeleton";
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from "@/components/ui/table";
import { toast } from "@/components/ui/toast";
import { useAuth } from "@/features/auth";
import type { Translate } from "@/i18n/translate";
import { errorCodeOf } from "@/lib/api/error-code";
import { useLastShown } from "@/lib/hooks/use-last-shown";
import { useRetry } from "@/lib/hooks/use-retry";
import { cn, firstName } from "@/lib/utils";
import {
  approveUser,
  deleteUser,
  getOidcSettings,
  getPendingUsers,
  getUsers,
  rejectUser,
  resetPassword,
} from "../api";
import { adminKeys } from "../queries";
import type { AdminUser } from "../types";
import { cardClass } from "./admin-parts";
import {
  AddPersonDialog,
  EditPersonDialog,
  NewPasswordDialog,
} from "./person-dialogs";

const PAGE_SIZE = 50;

function timeAgo(date: Date, locale: string) {
  const format = new Intl.RelativeTimeFormat(locale, { numeric: "always" });
  const seconds = Math.abs(Date.now() - date.getTime()) / 1000;
  if (seconds < 60) return format.format(-Math.round(seconds), "second");
  if (seconds < 3600) return format.format(-Math.round(seconds / 60), "minute");
  return format.format(-Math.round(seconds / 3600), "hour");
}

/** “Requested 2 hours ago”, “Requested yesterday”, “Requested Sep 3”. */
function requested(iso: string, t: Translate, locale: string) {
  const date = new Date(iso);
  if (isYesterday(date)) return t("adminRequestedYesterday");
  if (Date.now() - date.getTime() < 24 * 3600 * 1000)
    return t("adminRequestedAgo", { time: timeAgo(date, locale) });
  return t("adminRequestedOn", {
    date: new Intl.DateTimeFormat(locale, {
      month: "short",
      day: "numeric",
    }).format(date),
  });
}

function Person({
  user,
  you,
}: {
  user: Pick<AdminUser, "id" | "name" | "email" | "profileImage">;
  you?: boolean;
}) {
  const t = useTranslations();
  return (
    <span className="flex min-w-0 items-center gap-2.5">
      <Avatar id={user.id} name={user.name} src={user.profileImage} />
      <span className="grid min-w-0 leading-[1.3]">
        <b className="truncate font-semibold text-ui">
          {you ? t("adminPersonYou", { name: user.name }) : user.name}
        </b>
        <small className="truncate text-muted-foreground text-small">
          {user.email}
        </small>
      </span>
    </span>
  );
}

export function PeopleTab({ hidden }: { hidden?: boolean }) {
  const t = useTranslations();
  const locale = useLocale();
  const queryClient = useQueryClient();
  const { user: me } = useAuth();
  const [query, setQuery] = React.useState("");
  const [limit, setLimit] = React.useState(PAGE_SIZE);
  const [adding, setAdding] = React.useState(false);
  const [editing, setEditing] = React.useState<AdminUser | null>(null);
  const [resetting, setResetting] = React.useState<AdminUser | null>(null);
  const [newPassword, setNewPassword] = React.useState<{
    user: AdminUser;
    password: string;
  } | null>(null);
  const [deleting, setDeleting] = React.useState<AdminUser | null>(null);
  const [declining, setDeclining] = React.useState<AdminUser | null>(null);
  const shownResetting = useLastShown(resetting, !!resetting);
  const shownDeleting = useLastShown(deleting, !!deleting);
  const shownDeclining = useLastShown(declining, !!declining);

  const pending = useQuery({
    queryKey: adminKeys.pendingUsers,
    queryFn: getPendingUsers,
  });
  const pendingRetry = useRetry(pending.refetch);
  const [searched, setSearched] = React.useState("");
  React.useEffect(() => {
    const timer = window.setTimeout(() => {
      setSearched(query.trim());
      setLimit(PAGE_SIZE);
    }, 250);
    return () => window.clearTimeout(timer);
  }, [query]);
  const users = useQuery({
    queryKey: adminKeys.activeUsers(searched, limit),
    queryFn: () => getUsers(0, limit, { q: searched, status: "active" }),
    placeholderData: keepPreviousData,
  });
  const usersRetry = useRetry(users.refetch);
  const oidc = useQuery({
    queryKey: adminKeys.oidc,
    queryFn: getOidcSettings,
  });
  const providerName = oidc.data?.providerName || t("adminSingleSignOn");
  const joinedDate = new Intl.DateTimeFormat(locale, {
    month: "short",
    day: "numeric",
    year: "numeric",
  });

  const refresh = () =>
    Promise.all([
      queryClient.invalidateQueries({ queryKey: adminKeys.users }),
      queryClient.invalidateQueries({ queryKey: adminKeys.stats }),
    ]);

  const approve = useMutation({
    mutationFn: (user: AdminUser) => approveUser(user.id),
    onSuccess: async (_, user) => {
      await refresh();
      toast.success(t("adminCanSignIn", { name: firstName(user.name) }));
    },
    onError: (_, user) =>
      toast.error(t("adminApproveFailed", { name: firstName(user.name) }), {
        retry: () => approve.mutate(user),
      }),
  });
  const decline = useMutation({
    mutationFn: (user: AdminUser) => rejectUser(user.id),
    onSuccess: async (_, user) => {
      await refresh();
      setDeclining(null);
      toast.success(t("adminDeclined", { name: firstName(user.name) }));
    },
    onError: (_, user) =>
      toast.error(t("adminDeclineFailed", { name: firstName(user.name) })),
  });
  const remove = useMutation({
    mutationFn: (user: AdminUser) => deleteUser(user.id),
    onSuccess: async (_, user) => {
      await refresh();
      setDeleting(null);
      toast.success(t("adminDeleted", { name: firstName(user.name) }));
    },
    onError: (e: Error, user) =>
      toast.error(
        t(
          errorCodeOf(e) === "LAST_ADMIN"
            ? "adminDeleteOnlyAdmin"
            : "adminDeleteFailed",
          { name: firstName(user.name) },
        ),
      ),
  });
  const reset = useMutation({
    mutationFn: (user: AdminUser) => resetPassword(user.id),
    onSuccess: (res, user) => {
      setResetting(null);
      if (res.newPassword) setNewPassword({ user, password: res.newPassword });
      else
        toast.success(t("adminPasswordReset", { name: firstName(user.name) }));
    },
    onError: (_, user) =>
      toast.error(t("adminResetFailed", { name: firstName(user.name) })),
  });

  const rows = users.data?.users ?? [];
  const total = users.data?.total ?? 0;
  const waiting = pending.data ?? [];

  return (
    <div hidden={hidden} className="grid gap-3.5">
      {((pending.isError && !pending.data) || pendingRetry.isRetrying) && (
        <LoadFailedRow
          message={t("adminPendingLoadFailed")}
          onRetry={pendingRetry.retry}
          isRetrying={pendingRetry.isRetrying}
        />
      )}
      {waiting.length > 0 && (
        <div className="grid gap-0.5 rounded-2xl bg-[color-mix(in_srgb,var(--warn)_70%,var(--card))] p-1.5 shadow-[0_0_0_1px_color-mix(in_srgb,var(--warn-foreground)_18%,transparent)]">
          <header className="flex items-center gap-2 px-2.5 pt-2 pb-1.5 font-semibold text-ui text-warn-foreground [&_svg]:size-4">
            <UserRoundPlus aria-hidden />
            {t("adminWaitingForApproval", { count: waiting.length })}
          </header>
          {waiting.map((user) => (
            <div
              key={user.id}
              className="flex flex-wrap items-center gap-3 rounded-md bg-card px-2 py-1.5"
            >
              <span className="min-w-0 flex-1">
                <Person user={user} />
              </span>
              <span className="mr-1.5 whitespace-nowrap text-muted-foreground text-small max-md:hidden">
                {requested(user.createdAt, t, locale)}
              </span>
              <Button
                variant="quiet"
                size="sm"
                onClick={() => setDeclining(user)}
              >
                {t("adminDecline")}
              </Button>
              <Button
                size="sm"
                onClick={() => approve.mutate(user)}
                busy={
                  approve.isPending &&
                  approve.variables?.id === user.id &&
                  t("adminApproving")
                }
              >
                <Check aria-hidden />
                {t("adminApprove")}
              </Button>
            </div>
          ))}
        </div>
      )}

      <div data-slot="card" className={cn(cardClass, "overflow-hidden")}>
        <div className="flex flex-wrap items-center gap-2.5 py-3 pr-3 pl-3.5">
          <Input
            type="search"
            icon={<Search aria-hidden />}
            placeholder={t("adminFindPeople")}
            aria-label={t("adminFindPeople")}
            value={query}
            onChange={(e) => setQuery(e.target.value)}
            boxClassName="h-9 w-65 bg-background shadow-none focus-within:w-70 max-md:w-auto max-md:flex-1 transition-[width,box-shadow]"
          />
          <span className="flex-1 max-md:hidden" />
          <Button onClick={() => setAdding(true)}>
            <UserPlus aria-hidden />
            {t("adminAddPerson")}
          </Button>
        </div>
        {users.isError || usersRetry.isRetrying ? (
          <LoadFailedRow
            className="mx-3.5 mb-3.5"
            message={t("adminPeopleLoadFailed")}
            onRetry={usersRetry.retry}
            isRetrying={usersRetry.isRetrying}
          />
        ) : users.isLoading ? (
          <SkeletonRows count={5} className="px-3.5 py-3" />
        ) : (
          <Table className="max-md:min-w-0 max-md:[&_:is(th,td):nth-child(n+3):not(:last-child)]:hidden">
            <TableHeader>
              <tr>
                <TableHead>{t("adminColumnPerson")}</TableHead>
                <TableHead>{t("adminColumnRole")}</TableHead>
                <TableHead>{t("adminColumnSignsInWith")}</TableHead>
                <TableHead className="text-right">{t("adminNotes")}</TableHead>
                <TableHead className="text-right">{t("adminTags")}</TableHead>
                <TableHead>{t("adminColumnJoined")}</TableHead>
                <TableHead>
                  <span className="sr-only">{t("adminColumnOptions")}</span>
                </TableHead>
              </tr>
            </TableHeader>
            <TableBody>
              {rows.map((user) => {
                const you = user.id === me?.id;
                return (
                  <TableRow key={user.id}>
                    <TableCell>
                      <Person user={user} you={you} />
                    </TableCell>
                    <TableCell>
                      {user.isAdmin ? (
                        <Badge tone="ink">
                          <ShieldCheck aria-hidden />
                          {t("adminRoleAdmin")}
                        </Badge>
                      ) : (
                        <span className="text-muted-foreground">
                          {t("adminRoleMember")}
                        </span>
                      )}
                    </TableCell>
                    <TableCell dim>
                      {user.authMethod === "oidc"
                        ? providerName
                        : t("adminSignInPassword")}
                    </TableCell>
                    <TableCell numeric>{user._count?.notes ?? 0}</TableCell>
                    <TableCell numeric>{user._count?.tags ?? 0}</TableCell>
                    <TableCell dim>
                      {joinedDate.format(new Date(user.createdAt))}
                    </TableCell>
                    <TableCell className="w-11 pr-2.5 text-right">
                      <DropdownMenu>
                        <DropdownMenuTrigger asChild>
                          <button
                            type="button"
                            aria-label={t("adminPersonOptions", {
                              name: user.name,
                            })}
                            className="grid size-7 cursor-pointer place-items-center rounded-md border-0 bg-transparent text-muted-foreground hover:bg-foreground/6 hover:text-foreground aria-expanded:bg-foreground/6 [&_svg]:size-4"
                          >
                            <Ellipsis aria-hidden />
                          </button>
                        </DropdownMenuTrigger>
                        <DropdownMenuContent align="end" className="min-w-52.5">
                          <DropdownMenuItem onSelect={() => setEditing(user)}>
                            <Pencil />
                            {t("commonEdit")}
                          </DropdownMenuItem>
                          {user.authMethod !== "oidc" && (
                            <DropdownMenuItem
                              onSelect={() => setResetting(user)}
                            >
                              <KeyRound />
                              {t("adminResetPassword")}
                            </DropdownMenuItem>
                          )}
                          <DropdownMenuSeparator />
                          <DropdownMenuItem
                            tone="danger"
                            disabled={you}
                            onSelect={() => setDeleting(user)}
                          >
                            <Trash2 />
                            {t("commonDelete")}
                          </DropdownMenuItem>
                        </DropdownMenuContent>
                      </DropdownMenu>
                    </TableCell>
                  </TableRow>
                );
              })}
              {!rows.length && (
                <tr>
                  <td
                    colSpan={7}
                    className="px-3.5 py-6 text-center text-muted-foreground"
                  >
                    {searched
                      ? t("adminNoMatch", { query: searched })
                      : t("adminNoPeople")}
                  </td>
                </tr>
              )}
            </TableBody>
          </Table>
        )}
        {users.data && !users.isError && !usersRetry.isRetrying && (
          <div className="flex items-center justify-between gap-2.5 border-border/55 border-t px-3.5 py-2.5 text-meta text-muted-foreground">
            <span>{t("adminShownCount", { shown: rows.length, total })}</span>
            {rows.length < total && (
              <Button
                variant="quiet"
                size="sm"
                onClick={() => setLimit((prev) => prev + PAGE_SIZE)}
                busy={users.isPlaceholderData && t("uiLoading")}
              >
                {t("adminShowMore")}
              </Button>
            )}
          </div>
        )}
      </div>

      <AddPersonDialog
        open={adding}
        onOpenChange={setAdding}
        onDone={refresh}
      />
      <EditPersonDialog
        user={editing}
        isSelf={editing?.id === me?.id}
        onClose={() => setEditing(null)}
        onDone={refresh}
      />
      <ConfirmationDialog
        open={!!resetting}
        onOpenChange={(open) => !open && setResetting(null)}
        title={t("adminResetTitle", {
          name: firstName(shownResetting?.name ?? ""),
        })}
        description={t("adminResetMessage")}
        confirmLabel={t("adminResetPassword")}
        busyLabel={t("adminResetting")}
        variant="primary"
        isPending={reset.isPending}
        onConfirm={() => resetting && reset.mutate(resetting)}
      />
      <NewPasswordDialog
        value={newPassword}
        onClose={() => setNewPassword(null)}
      />
      <ConfirmationDialog
        open={!!declining}
        onOpenChange={(open) => !open && setDeclining(null)}
        title={t("adminDeclineTitle", {
          name: firstName(shownDeclining?.name ?? ""),
        })}
        description={t("adminDeclineMessage")}
        confirmLabel={t("adminDecline")}
        busyLabel={t("adminDeclining")}
        isPending={decline.isPending}
        onConfirm={() => declining && decline.mutate(declining)}
      />
      <ConfirmationDialog
        open={!!deleting}
        onOpenChange={(open) => !open && setDeleting(null)}
        title={t("adminDeleteTitle", { name: shownDeleting?.name ?? "" })}
        description={
          <>
            {t("adminDeleteMessage")}
            <ul className="m-0 mt-2 grid list-none gap-1.5 p-0 text-foreground [&_li]:flex [&_li]:items-center [&_li]:gap-2 [&_svg]:size-3.75 [&_svg]:text-muted-foreground">
              <li>
                <UserRound aria-hidden />
                {t("adminDeleteTheirAccount")}
              </li>
              <li>
                <NotebookPen aria-hidden />
                {t("adminDeleteNotes", {
                  count: shownDeleting?._count?.notes ?? 0,
                })}
              </li>
              <li>
                <Hash aria-hidden />
                {t("adminDeleteTags", {
                  count: shownDeleting?._count?.tags ?? 0,
                })}
              </li>
            </ul>
            {shownDeleting?.isAdmin && (
              <span className="mt-3 flex items-center gap-2 rounded-lg bg-warn px-3 py-2.5 text-meta text-warn-foreground [&_svg]:size-4">
                <ShieldAlert aria-hidden />
                {t("adminDeleteIsAdmin", {
                  name: firstName(shownDeleting.name),
                })}
              </span>
            )}
          </>
        }
        confirmLabel={t("adminDeleteConfirm", {
          name: firstName(shownDeleting?.name ?? ""),
        })}
        busyLabel={t("uiDeleting")}
        isPending={remove.isPending}
        onConfirm={() => deleting && remove.mutate(deleting)}
      />
    </div>
  );
}
