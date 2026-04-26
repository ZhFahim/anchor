-- AlterTable: Note.syncVersion
ALTER TABLE "Note" ADD COLUMN "syncVersion" BIGINT NOT NULL DEFAULT 0;

-- AlterTable: Tag.syncVersion
ALTER TABLE "Tag" ADD COLUMN "syncVersion" BIGINT NOT NULL DEFAULT 0;

-- AlterTable: NoteShare.syncVersion
ALTER TABLE "NoteShare" ADD COLUMN "syncVersion" BIGINT NOT NULL DEFAULT 0;

-- AlterTable: NoteAttachment.isDeleted + syncVersion
ALTER TABLE "NoteAttachment" ADD COLUMN "isDeleted" BOOLEAN NOT NULL DEFAULT false;
ALTER TABLE "NoteAttachment" ADD COLUMN "syncVersion" BIGINT NOT NULL DEFAULT 0;

-- CreateSequence
CREATE SEQUENCE "sync_version_seq" AS BIGINT START WITH 1;

-- Backfill in (updatedAt ASC, id ASC). Each table gets a non-overlapping range
-- so syncVersion is globally unique across entities.
UPDATE "Note"
SET "syncVersion" = sub.rn
FROM (
  SELECT id, ROW_NUMBER() OVER (ORDER BY "updatedAt" ASC, id ASC) AS rn FROM "Note"
) sub
WHERE "Note"."id" = sub.id;

-- Tags: continue from max(Note.syncVersion)
UPDATE "Tag"
SET "syncVersion" = sub.rn + COALESCE((SELECT MAX("syncVersion") FROM "Note"), 0)
FROM (
  SELECT id, ROW_NUMBER() OVER (ORDER BY "updatedAt" ASC, id ASC) AS rn FROM "Tag"
) sub
WHERE "Tag"."id" = sub.id;

-- NoteShares: continue from max(Tag.syncVersion)
UPDATE "NoteShare"
SET "syncVersion" = sub.rn + COALESCE((SELECT MAX("syncVersion") FROM "Tag"), 0)
FROM (
  SELECT id, ROW_NUMBER() OVER (ORDER BY "updatedAt" ASC, id ASC) AS rn FROM "NoteShare"
) sub
WHERE "NoteShare"."id" = sub.id;

-- NoteAttachments: continue from max(NoteShare.syncVersion)
UPDATE "NoteAttachment"
SET "syncVersion" = sub.rn + COALESCE((SELECT MAX("syncVersion") FROM "NoteShare"), 0)
FROM (
  SELECT id, ROW_NUMBER() OVER (ORDER BY "updatedAt" ASC, id ASC) AS rn FROM "NoteAttachment"
) sub
WHERE "NoteAttachment"."id" = sub.id;

-- Advance the sequence past the backfilled rows.
SELECT setval('sync_version_seq', GREATEST(
  COALESCE((SELECT MAX("syncVersion") FROM "Note"), 0),
  COALESCE((SELECT MAX("syncVersion") FROM "Tag"), 0),
  COALESCE((SELECT MAX("syncVersion") FROM "NoteShare"), 0),
  COALESCE((SELECT MAX("syncVersion") FROM "NoteAttachment"), 0),
  0
) + 1, false);

-- CreateTable: SyncOpLog
CREATE TABLE "SyncOpLog" (
  "id"         TEXT NOT NULL,
  "userId"     TEXT NOT NULL,
  "clientOpId" TEXT NOT NULL,
  "entityType" TEXT NOT NULL,
  "entityId"   TEXT NOT NULL,
  "resultJson" TEXT NOT NULL,
  "createdAt"  TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

  CONSTRAINT "SyncOpLog_pkey" PRIMARY KEY ("id")
);

CREATE UNIQUE INDEX "SyncOpLog_userId_clientOpId_key" ON "SyncOpLog"("userId", "clientOpId");
CREATE INDEX "SyncOpLog_createdAt_idx" ON "SyncOpLog"("createdAt");

ALTER TABLE "SyncOpLog"
  ADD CONSTRAINT "SyncOpLog_userId_fkey"
  FOREIGN KEY ("userId") REFERENCES "User"("id")
  ON DELETE CASCADE ON UPDATE CASCADE;

-- CreateIndex
CREATE INDEX "Note_userId_syncVersion_idx" ON "Note"("userId", "syncVersion");
CREATE INDEX "Tag_userId_syncVersion_idx" ON "Tag"("userId", "syncVersion");
CREATE INDEX "NoteShare_sharedWithUserId_syncVersion_idx" ON "NoteShare"("sharedWithUserId", "syncVersion");
CREATE INDEX "NoteAttachment_noteId_syncVersion_idx" ON "NoteAttachment"("noteId", "syncVersion");
