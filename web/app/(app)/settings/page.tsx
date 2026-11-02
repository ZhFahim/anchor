"use client";

import { useQuery } from "@tanstack/react-query";
import { AnchorLogo } from "@/components/layout/anchor-logo";
import { AppPage, PageTitle } from "@/components/layout/app-page";
import {
  ApiTokenSection,
  AppearanceSection,
  EditorSection,
  ImportExportSection,
  MagicLoginSection,
  NoteLocksSection,
  PasswordSection,
  ProfileSection,
  Row,
  SearchSection,
  Section,
  SettingsNav,
} from "@/features/settings";
import { api } from "@/lib/api/client";
import { appMode, basePath, isServerless } from "@/lib/local-backend/mode";

export default function SettingsPage() {
  // As in the Android app's About.
  const { data: server } = useQuery({
    queryKey: ["server-health"],
    queryFn: () => api.get("api/health").json<{ version?: string }>(),
    staleTime: 5 * 60 * 1000,
  });
  return (
    <AppPage title={<PageTitle>Settings</PageTitle>} scrollKey="settings">
      <div className="grid grid-cols-[176px_minmax(0,640px)] items-start gap-10 pt-1 max-md:grid-cols-[minmax(0,1fr)] max-md:gap-5">
        <SettingsNav />
        <div className="grid min-w-0 gap-8">
          <ProfileSection />
          <AppearanceSection />
          <EditorSection />
          {!isServerless && <SearchSection />}
          {!isServerless && <MagicLoginSection />}
          {!isServerless && <ApiTokenSection />}
          <ImportExportSection />
          <NoteLocksSection />
          {!isServerless && <PasswordSection />}
          <Section id="about" title="About">
            <Row>
              <div className="flex items-center gap-3">
                <AnchorLogo className="size-10 rounded-md shadow-edge" />
                <div className="grid">
                  <b className="font-semibold text-ui">
                    Anchor+ {process.env.NEXT_PUBLIC_APP_VERSION}
                  </b>
                  <span className="text-meta text-muted-foreground">
                    Your thoughts, secured.
                  </span>
                  {appMode === "local" && (
                    <span className="text-meta text-muted-foreground">
                      Your notes are kept in this browser only.{" "}
                      <a
                        href={`${basePath}/demo/demos`}
                        className="font-semibold text-accent-ink underline decoration-current/35 underline-offset-3 hover:decoration-current"
                      >
                        Watch the feature demos
                      </a>
                    </span>
                  )}
                  {!isServerless && server?.version && (
                    <span className="text-meta text-muted-foreground">
                      Server {server.version}
                    </span>
                  )}
                </div>
              </div>
            </Row>
          </Section>
        </div>
      </div>
    </AppPage>
  );
}
