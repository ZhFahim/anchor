"use client";

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
  const { editor, setEditorPreference } = usePreferencesStore();
  const [saveStatus, setSaveStatus] = useSaveStatus();
  return (
    <Section id="editor" title="Editor">
      <Row>
        <RowText
          title={
            <label htmlFor="sort-checked">
              Move checked items to the bottom
            </label>
          }
          text="Checked items move below the unchecked ones."
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
