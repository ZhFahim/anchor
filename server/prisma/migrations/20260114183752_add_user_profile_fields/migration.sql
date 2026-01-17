-- AlterTable: Add columns as nullable first
ALTER TABLE "User"
ADD COLUMN "name" TEXT,
ADD COLUMN "profileImage" TEXT;

-- Data Migration: Set default name for existing users
UPDATE "User" SET "name" = 'User' WHERE "name" IS NULL;

-- AlterTable: Make name column NOT NULL after backfilling
ALTER TABLE "User" ALTER COLUMN "name" SET NOT NULL;