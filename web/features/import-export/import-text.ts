import type { Translate } from "@/i18n/translate";
import type { ImportFileError } from "./adapters/types";
import type { ImportSkippedItem } from "./types";

export function importIssueText(issue: ImportSkippedItem, t: Translate) {
  switch (issue.reason) {
    case "backupAttachmentMissing":
      return t("importIssueBackupAttachmentMissing");
    case "noteFileUnreadable":
      return t("importIssueNoteFileUnreadable");
    case "trashedInKeep":
      return t("importIssueTrashedInKeep");
    case "exportAttachmentMissing":
      return t("importIssueExportAttachmentMissing");
    case "unsupportedFileType":
      return t("importIssueUnsupportedFileType", { fileType: issue.fileType });
    case "attachmentNotFound":
      return t("importIssueAttachmentNotFound");
    case "emptyFile":
      return t("importIssueEmptyFile");
    case "noteTooLarge":
      return t("importIssueNoteTooLarge");
    case "noteFailed":
      return t("importIssueNoteFailed");
    case "contentInvalid":
      return t("importIssueContentInvalid");
    case "backgroundUnknown":
      return t("importIssueBackgroundUnknown");
    case "importedWithProblem":
      return t("importIssueWarning");
    case "attachmentUnreadable":
      return t("importIssueAttachmentUnreadable");
    case "attachmentUploadFailed":
      return t("importIssueAttachmentUploadFailed");
  }
}

export function importFileErrorText(error: ImportFileError, t: Translate) {
  switch (error.reason) {
    case "backupTooNew":
      return t("importBackupTooNew");
  }
}
