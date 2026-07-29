-- Add isSystem flag to DictionaryTerm so §23 seed terms can be shared across users
-- (mirrors Skill.isSystem). Read queries merge isSystem OR ownerId.

-- AlterTable
ALTER TABLE "DictionaryTerm" ADD COLUMN "isSystem" BOOLEAN NOT NULL DEFAULT false;

-- CreateIndex
CREATE INDEX "DictionaryTerm_isSystem_deletedAt_idx" ON "DictionaryTerm"("isSystem", "deletedAt");
