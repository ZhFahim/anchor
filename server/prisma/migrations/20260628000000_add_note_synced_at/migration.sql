-- AlterTable
ALTER TABLE "Note" ADD COLUMN "syncedAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP;

-- Backfill before the trigger exists, or the UPDATE would fire it and overwrite syncedAt with now().
UPDATE "Note" SET "syncedAt" = "updatedAt";

-- Stamp syncedAt = now() on every write so import (or any caller) can't backdate the sync watermark.
CREATE OR REPLACE FUNCTION set_note_synced_at() RETURNS trigger AS $$
BEGIN
  NEW."syncedAt" := now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER note_set_synced_at
  BEFORE INSERT OR UPDATE ON "Note"
  FOR EACH ROW
  EXECUTE FUNCTION set_note_synced_at();

-- CreateIndex
CREATE INDEX "Note_userId_syncedAt_idx" ON "Note"("userId", "syncedAt");
