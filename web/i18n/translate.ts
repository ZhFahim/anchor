import { createTranslator, type useTranslations } from "next-intl";
import english from "../messages/en.json";
import { withoutNotes } from "./messages";

export type Translate = ReturnType<typeof useTranslations>;

export const englishT: Translate = createTranslator({
  locale: "en",
  messages: withoutNotes(english),
});
