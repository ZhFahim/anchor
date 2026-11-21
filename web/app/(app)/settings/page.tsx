"use client";

import { useTranslations } from "next-intl";
import { AnchorLogo } from "@/components/layout/anchor-logo";
import { AppPage, PageTitle } from "@/components/layout/app-page";
import {
  ApiTokenSection,
  AppearanceSection,
  DeleteAccountSection,
  EditorSection,
  ImportExportSection,
  PasswordSection,
  ProfileSection,
  Row,
  Section,
  SettingsNav,
} from "@/features/settings";

export default function SettingsPage() {
  const t = useTranslations();
  return (
    <AppPage
      title={<PageTitle>{t("settingsTitle")}</PageTitle>}
      scrollKey="settings"
    >
      <div className="grid grid-cols-[176px_minmax(0,640px)] items-start gap-10 pt-1 max-md:grid-cols-[minmax(0,1fr)] max-md:gap-5">
        <SettingsNav />
        <div className="grid min-w-0 gap-8">
          <ProfileSection />
          <AppearanceSection />
          <EditorSection />
          <ApiTokenSection />
          <ImportExportSection />
          <PasswordSection />
          <DeleteAccountSection />
          <Section id="about" title={t("settingsAbout")}>
            <Row>
              <div className="flex items-center gap-3">
                <AnchorLogo className="size-10 rounded-md shadow-edge" />
                <div className="grid">
                  <b className="font-semibold text-ui">
                    {t("settingsAppVersion", {
                      version: process.env.NEXT_PUBLIC_APP_VERSION ?? "",
                    })}
                  </b>
                  <span className="text-meta text-muted-foreground">
                    {t("settingsTagline")}
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
