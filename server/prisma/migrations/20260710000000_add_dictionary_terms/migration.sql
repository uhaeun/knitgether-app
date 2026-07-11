CREATE TABLE "DictionaryTerm" (
    "id" UUID NOT NULL,
    "ownerId" TEXT NOT NULL,
    "term" TEXT NOT NULL,
    "fullName" TEXT,
    "description" TEXT NOT NULL,
    "relatedSkillAbbreviations" TEXT NOT NULL DEFAULT '',
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,
    "deletedAt" TIMESTAMP(3),

    CONSTRAINT "DictionaryTerm_pkey" PRIMARY KEY ("id")
);

CREATE INDEX "DictionaryTerm_ownerId_deletedAt_idx" ON "DictionaryTerm"("ownerId", "deletedAt");
CREATE INDEX "DictionaryTerm_ownerId_term_deletedAt_idx" ON "DictionaryTerm"("ownerId", "term", "deletedAt");

ALTER TABLE "DictionaryTerm"
ADD CONSTRAINT "DictionaryTerm_ownerId_fkey"
FOREIGN KEY ("ownerId") REFERENCES "UserProfile"("id")
ON DELETE CASCADE ON UPDATE CASCADE;
