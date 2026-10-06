"use client";

import { useQuery } from "@tanstack/react-query";
import { Hash, NotebookPen, Users } from "lucide-react";
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
    <AppPage title={<PageTitle>Admin</PageTitle>} scrollKey="admin">
      <div className="grid gap-4 pb-10">
        <div className="grid grid-cols-3 gap-3 max-md:gap-2">
          <StatCard
            icon={<Users />}
            label="People"
            value={stats.data?.totalUsers}
            failed={stats.isError}
            caption={
              waitingCount ? `${waitingCount} waiting` : "No one waiting"
            }
          />
          <StatCard
            icon={<NotebookPen />}
            label="Notes"
            value={stats.data?.totalNotes}
            failed={stats.isError}
            caption="Including trash"
          />
          <StatCard
            icon={<Hash />}
            label="Tags"
            value={stats.data?.totalTags}
            failed={stats.isError}
            caption="Across all people"
          />
        </div>
        {((stats.isError && !stats.data) || statsRetry.isRetrying) && (
          <LoadFailedRow
            message="Couldn’t load the counts."
            onRetry={statsRetry.retry}
            isRetrying={statsRetry.isRetrying}
          />
        )}
        <Tabs
          aria-label="Admin"
          panelId="admin-panel"
          value={tab}
          onValueChange={setTab}
          tabs={[
            {
              value: "people",
              label: (
                <>
                  People
                  {waitingCount > 0 && (
                    <Badge tone="warn">
                      {waitingCount}
                      <span className="sr-only"> waiting</span>
                    </Badge>
                  )}
                </>
              ),
            },
            { value: "signin", label: "Sign-in" },
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
