-- Files other than pictures and recordings get a table of their own, so the
-- AttachmentType enum keeps only upstream Anchor's values and its server can
-- run on this database (it fails on a NoteAttachment row of a type it
-- doesn't know, and with it every sync).
-- switch-back: makes AttachmentType upstream's again (image, audio), as
-- docker/test-switch-back.sh checks.

-- All or nothing: a file is never in both tables, or in neither.
BEGIN;

-- CreateTable
CREATE TABLE "NoteFile" (
    "id" TEXT NOT NULL,
    "noteId" TEXT NOT NULL,
    "uploadedByUserId" TEXT NOT NULL,
    "originalFilename" TEXT NOT NULL,
    "storedFilename" TEXT NOT NULL,
    "mimeType" TEXT NOT NULL,
    "fileSize" INTEGER NOT NULL,
    "position" INTEGER NOT NULL DEFAULT 0,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "NoteFile_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE INDEX "NoteFile_noteId_idx" ON "NoteFile"("noteId");

-- CreateIndex
CREATE INDEX "NoteFile_uploadedByUserId_idx" ON "NoteFile"("uploadedByUserId");

-- AddForeignKey
ALTER TABLE "NoteFile" ADD CONSTRAINT "NoteFile_noteId_fkey" FOREIGN KEY ("noteId") REFERENCES "Note"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "NoteFile" ADD CONSTRAINT "NoteFile_uploadedByUserId_fkey" FOREIGN KEY ("uploadedByUserId") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- Move the files there, keeping their ids, so the apps see no change.
INSERT INTO "NoteFile" ("id", "noteId", "uploadedByUserId", "originalFilename", "storedFilename", "mimeType", "fileSize", "position", "createdAt", "updatedAt")
SELECT "id", "noteId", "uploadedByUserId", "originalFilename", "storedFilename", "mimeType", "fileSize", "position", "createdAt", "updatedAt"
FROM "NoteAttachment" WHERE "type"::text = 'file';

DELETE FROM "NoteAttachment" WHERE "type"::text = 'file';

-- AlterEnum: back to upstream's values. Postgres can't drop one, so the
-- type is made again.
CREATE TYPE "AttachmentType_new" AS ENUM ('image', 'audio');
ALTER TABLE "NoteAttachment" ALTER COLUMN "type" TYPE "AttachmentType_new" USING ("type"::text::"AttachmentType_new");
ALTER TYPE "AttachmentType" RENAME TO "AttachmentType_old";
ALTER TYPE "AttachmentType_new" RENAME TO "AttachmentType";
DROP TYPE "public"."AttachmentType_old";

COMMIT;
