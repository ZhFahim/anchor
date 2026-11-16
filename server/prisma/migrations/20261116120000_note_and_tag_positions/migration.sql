-- Each person's own order for notes and tags (drag and drop).
-- Keys are fractional indexes; "C" collation compares them byte-wise.

-- CreateTable
CREATE TABLE "NotePosition" (
    "userId" TEXT NOT NULL,
    "noteId" TEXT NOT NULL,
    "position" TEXT COLLATE "C" NOT NULL,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "NotePosition_pkey" PRIMARY KEY ("userId","noteId")
);

-- CreateIndex
CREATE INDEX "NotePosition_noteId_idx" ON "NotePosition"("noteId");

-- AddForeignKey
ALTER TABLE "NotePosition" ADD CONSTRAINT "NotePosition_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "NotePosition" ADD CONSTRAINT "NotePosition_noteId_fkey" FOREIGN KEY ("noteId") REFERENCES "Note"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AlterTable
ALTER TABLE "Tag" ADD COLUMN "position" TEXT COLLATE "C";
