"use client";

import { AppPage, PageTitle } from "@/components/layout/app-page";
import { AnchorLogo } from "@/components/layout/brand";
import {
  ApiTokenSection,
  AppearanceSection,
  EditorSection,
  ImportExportSection,
  PasswordSection,
  ProfileSection,
  Row,
  Section,
  SettingsNav,
} from "@/features/settings";

export default function SettingsPage() {
  return (
    <AppPage title={<PageTitle>Settings</PageTitle>} scrollKey="settings">
      <div className="grid grid-cols-[176px_minmax(0,640px)] items-start gap-10 pt-1 max-md:grid-cols-[minmax(0,1fr)] max-md:gap-5">
        <SettingsNav />
        <div className="grid min-w-0 gap-8">
          <ProfileSection />
          <AppearanceSection />
          <EditorSection />
          <ApiTokenSection />
          <ImportExportSection />
          <PasswordSection />
          <Section id="about" title="About">
            <Row>
              <div className="flex items-center gap-3">
                <AnchorLogo className="size-10 rounded-md shadow-edge" />
                <div className="grid">
                  <b className="font-semibold text-ui">
                    Anchor {process.env.NEXT_PUBLIC_APP_VERSION}
                  </b>
                  <span className="text-meta text-muted-foreground">
                    Your thoughts, secured.
                  </span>
                </div>
              </div>
            </Row>
          </Section>
        </div>
      </div>
    </AppPage>
  );
}
