-- CreateEnum
CREATE TYPE "ApiTokenScope" AS ENUM ('readOnly', 'readWrite');

-- AlterTable
ALTER TABLE "User" ADD COLUMN "apiTokenScope" "ApiTokenScope" NOT NULL DEFAULT 'readWrite';
