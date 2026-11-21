"use client";

import { useQuery } from "@tanstack/react-query";
import { Hash, NotebookPen, Users } from "lucide-react";
import { useTranslations } from "next-intl";
import * as React from "react";
import { AppPage, PageTitle } from "@/components/layout/app-page";
import { Badge } from "@/components/ui/badge";
import { LoadFailedRow } from "@/components/ui/empty-state";
import { TabPanel, Tabs } from "@/components/ui/tabs";
import {
  AdminGuard,
  adminKeys,
  getAdminStats,
  getPendingUsers,
  PeopleTab,
  SignInTab,
  StatCard,
} from "@/features/admin";
import { useRetry } from "@/lib/hooks/use-retry";

export default function AdminPage() {
  return (
    <AdminGuard>
      <AdminPageContent />
    </AdminGuard>
  );
}

function AdminPageContent() {
  const t = useTranslations();
  const [tab, setTab] = React.useState<"people" | "signin">("people");
  const stats = useQuery({
    queryKey: adminKeys.stats,
    queryFn: getAdminStats,
  });
  const pending = useQuery({
    queryKey: adminKeys.pendingUsers,
    queryFn: getPendingUsers,
  });
  const statsRetry = useRetry(stats.refetch);
  const waitingCount = pending.data?.length ?? 0;

  return (
    <AppPage title={<PageTitle>{t("adminTitle")}</PageTitle>} scrollKey="admin">
      <div className="grid gap-4 pb-10">
        <div className="grid grid-cols-3 gap-3 max-md:gap-2">
          <StatCard
            icon={<Users />}
            label={t("adminPeople")}
            value={stats.data?.totalUsers}
            failed={stats.isError}
            caption={t("adminWaitingCount", { count: waitingCount })}
          />
          <StatCard
            icon={<NotebookPen />}
            label={t("adminNotes")}
            value={stats.data?.totalNotes}
            failed={stats.isError}
            caption={t("adminNotesCaption")}
          />
          <StatCard
            icon={<Hash />}
            label={t("adminTags")}
            value={stats.data?.totalTags}
            failed={stats.isError}
            caption={t("adminTagsCaption")}
          />
        </div>
        {((stats.isError && !stats.data) || statsRetry.isRetrying) && (
          <LoadFailedRow
            message={t("adminStatsLoadFailed")}
            onRetry={statsRetry.retry}
            isRetrying={statsRetry.isRetrying}
          />
        )}
        <Tabs
          aria-label={t("adminTitle")}
          panelId="admin-panel"
          value={tab}
          onValueChange={setTab}
          tabs={[
            {
              value: "people",
              label: (
                <>
                  {t("adminPeople")}
                  {waitingCount > 0 && (
                    <Badge tone="warn">
                      <span aria-hidden>{waitingCount}</span>
                      <span className="sr-only">
                        {t("adminWaitingCount", { count: waitingCount })}
                      </span>
                    </Badge>
                  )}
                </>
              ),
            },
            { value: "signin", label: t("adminSignInTab") },
          ]}
        />
        <TabPanel id="admin-panel" labelledBy={`admin-panel-tab-${tab}`}>
          <PeopleTab hidden={tab !== "people"} />
          <SignInTab hidden={tab !== "signin"} />
        </TabPanel>
      </div>
    </AppPage>
  );
}
