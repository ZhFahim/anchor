-- AlterEnum
-- Not used in this migration: Postgres forbids using a value it just added.
ALTER TYPE "SyncEntityType" ADD VALUE 'reminder';

-- CreateEnum
CREATE TYPE "ReminderRecurrence" AS ENUM ('none', 'daily', 'weekly', 'monthly', 'yearly');

-- CreateTable
-- remindAt is a local wall clock ("YYYY-MM-DDTHH:mm"), stored as text so no
-- session timezone applies.
CREATE TABLE "NoteReminder" (
    "userId" TEXT NOT NULL,
    "noteId" TEXT NOT NULL,
    "remindAt" TEXT NOT NULL,
    "recurrence" "ReminderRecurrence" NOT NULL DEFAULT 'none',
    "version" INTEGER NOT NULL DEFAULT 1,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "NoteReminder_pkey" PRIMARY KEY ("userId", "noteId")
);

-- CreateIndex
CREATE INDEX "NoteReminder_noteId_idx" ON "NoteReminder"("noteId");

-- AddForeignKey
ALTER TABLE "NoteReminder" ADD CONSTRAINT "NoteReminder_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "NoteReminder" ADD CONSTRAINT "NoteReminder_noteId_fkey" FOREIGN KEY ("noteId") REFERENCES "Note"("id") ON DELETE CASCADE ON UPDATE CASCADE;
