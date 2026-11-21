"use client";

import { useTranslations } from "next-intl";
import { Switch } from "@/components/ui/switch";
import { usePreferencesStore } from "@/features/preferences";
import {
  Row,
  RowText,
  SaveStatus,
  Section,
  useSaveStatus,
} from "./settings-blocks";

export function EditorSection() {
  const t = useTranslations();
  const { editor, setEditorPreference } = usePreferencesStore();
  const [saveStatus, setSaveStatus] = useSaveStatus();
  return (
    <Section id="editor" title={t("settingsEditor")}>
      <Row>
        <RowText
          title={
            <label htmlFor="sort-checked">{t("settingsMoveChecked")}</label>
          }
          text={t("settingsMoveCheckedHelp")}
          saved={<SaveStatus state={saveStatus} />}
        />
        <Switch
          id="sort-checked"
          checked={editor.sortChecklistItems}
          onCheckedChange={(on) => {
            setEditorPreference("sortChecklistItems", on);
            setSaveStatus("saved");
          }}
        />
      </Row>
    </Section>
  );
}
