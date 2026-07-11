CREATE TABLE "ProjectYarnUsage" (
    "id" UUID NOT NULL,
    "ownerId" TEXT NOT NULL,
    "projectId" UUID NOT NULL,
    "yarnId" UUID,
    "yarnNameSnapshot" TEXT NOT NULL,
    "quantityUsed" INTEGER NOT NULL,
    "memo" TEXT NOT NULL DEFAULT '',
    "usedAt" TIMESTAMP(3) NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,
    "deletedAt" TIMESTAMP(3),

    CONSTRAINT "ProjectYarnUsage_pkey" PRIMARY KEY ("id")
);

CREATE INDEX "ProjectYarnUsage_ownerId_projectId_deletedAt_idx" ON "ProjectYarnUsage"("ownerId", "projectId", "deletedAt");
CREATE INDEX "ProjectYarnUsage_ownerId_yarnId_deletedAt_idx" ON "ProjectYarnUsage"("ownerId", "yarnId", "deletedAt");

ALTER TABLE "ProjectYarnUsage" ADD CONSTRAINT "ProjectYarnUsage_ownerId_fkey" FOREIGN KEY ("ownerId") REFERENCES "UserProfile"("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "ProjectYarnUsage" ADD CONSTRAINT "ProjectYarnUsage_projectId_fkey" FOREIGN KEY ("projectId") REFERENCES "Project"("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "ProjectYarnUsage" ADD CONSTRAINT "ProjectYarnUsage_yarnId_fkey" FOREIGN KEY ("yarnId") REFERENCES "Yarn"("id") ON DELETE SET NULL ON UPDATE CASCADE;
