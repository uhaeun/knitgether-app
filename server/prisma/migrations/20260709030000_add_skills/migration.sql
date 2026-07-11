CREATE TABLE "Skill" (
    "id" UUID NOT NULL,
    "ownerId" TEXT NOT NULL,
    "name" TEXT NOT NULL,
    "abbreviation" TEXT NOT NULL,
    "description" TEXT NOT NULL,
    "category" TEXT,
    "difficulty" TEXT,
    "animationName" TEXT,
    "animationType" TEXT,
    "steps" TEXT[] NOT NULL DEFAULT ARRAY[]::TEXT[],
    "animationIds" TEXT[] NOT NULL DEFAULT ARRAY[]::TEXT[],
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,
    "deletedAt" TIMESTAMP(3),

    CONSTRAINT "Skill_pkey" PRIMARY KEY ("id")
);

CREATE TABLE "SkillAnimation" (
    "id" UUID NOT NULL,
    "ownerId" TEXT NOT NULL,
    "skillId" UUID,
    "title" TEXT NOT NULL,
    "localAssetName" TEXT,
    "durationSeconds" INTEGER,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,
    "deletedAt" TIMESTAMP(3),

    CONSTRAINT "SkillAnimation_pkey" PRIMARY KEY ("id")
);

CREATE INDEX "Skill_ownerId_deletedAt_idx" ON "Skill"("ownerId", "deletedAt");
CREATE INDEX "Skill_ownerId_category_deletedAt_idx" ON "Skill"("ownerId", "category", "deletedAt");
CREATE INDEX "SkillAnimation_ownerId_deletedAt_idx" ON "SkillAnimation"("ownerId", "deletedAt");
CREATE INDEX "SkillAnimation_skillId_idx" ON "SkillAnimation"("skillId");

ALTER TABLE "Skill" ADD CONSTRAINT "Skill_ownerId_fkey" FOREIGN KEY ("ownerId") REFERENCES "UserProfile"("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "SkillAnimation" ADD CONSTRAINT "SkillAnimation_ownerId_fkey" FOREIGN KEY ("ownerId") REFERENCES "UserProfile"("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "SkillAnimation" ADD CONSTRAINT "SkillAnimation_skillId_fkey" FOREIGN KEY ("skillId") REFERENCES "Skill"("id") ON DELETE SET NULL ON UPDATE CASCADE;
