-- CreateTable
CREATE TABLE "NotePin" (
    "userId" TEXT NOT NULL,
    "noteId" TEXT NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "NotePin_pkey" PRIMARY KEY ("userId", "noteId")
);

-- CreateIndex
CREATE INDEX "NotePin_noteId_idx" ON "NotePin"("noteId");

-- AddForeignKey
ALTER TABLE "NotePin" ADD CONSTRAINT "NotePin_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "NotePin" ADD CONSTRAINT "NotePin_noteId_fkey" FOREIGN KEY ("noteId") REFERENCES "Note"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- Seed per-user pins from the previous note-level flag.
-- Only the note owner keeps the pin; this intentionally clears the pin that
-- previously leaked to collaborators on shared notes.
INSERT INTO "NotePin" ("userId", "noteId")
SELECT "userId", "id" FROM "Note" WHERE "isPinned" = true;

-- Drop the note-level flag now that pin state is per-user.
ALTER TABLE "Note" DROP COLUMN "isPinned";
