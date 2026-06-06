-- The plain unique index counted soft-deleted rows, so a name could not be
-- reused after its tag was deleted. Replace it with a partial unique index
-- that only constrains active tags.
DROP INDEX "Tag_userId_name_key";

CREATE UNIQUE INDEX "Tag_userId_name_active_key"
  ON "Tag" ("userId", "name")
  WHERE "isDeleted" = false;
