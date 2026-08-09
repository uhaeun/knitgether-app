-- CreateTable
CREATE TABLE "ProjectYarnLink" (
    "id" UUID NOT NULL,
    "ownerId" TEXT NOT NULL,
    "projectId" UUID NOT NULL,
    "yarnId" UUID,
    "nameSnapshot" TEXT NOT NULL,
    "brandSnapshot" TEXT,
    "colorwaySnapshot" TEXT,
    "weightSnapshot" TEXT,
    "linkedAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,
    "deletedAt" TIMESTAMP(3),

    CONSTRAINT "ProjectYarnLink_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "ProjectNeedleLink" (
    "id" UUID NOT NULL,
    "ownerId" TEXT NOT NULL,
    "projectId" UUID NOT NULL,
    "needleId" UUID,
    "nameSnapshot" TEXT NOT NULL,
    "typeSnapshot" TEXT,
    "sizeSnapshot" TEXT,
    "lengthSnapshot" TEXT,
    "linkedAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,
    "deletedAt" TIMESTAMP(3),

    CONSTRAINT "ProjectNeedleLink_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE INDEX "ProjectYarnLink_ownerId_projectId_deletedAt_idx" ON "ProjectYarnLink"("ownerId", "projectId", "deletedAt");

-- CreateIndex
CREATE INDEX "ProjectYarnLink_ownerId_yarnId_deletedAt_idx" ON "ProjectYarnLink"("ownerId", "yarnId", "deletedAt");

-- CreateIndex
CREATE INDEX "ProjectNeedleLink_ownerId_projectId_deletedAt_idx" ON "ProjectNeedleLink"("ownerId", "projectId", "deletedAt");

-- CreateIndex
CREATE INDEX "ProjectNeedleLink_ownerId_needleId_deletedAt_idx" ON "ProjectNeedleLink"("ownerId", "needleId", "deletedAt");

-- AddForeignKey
ALTER TABLE "ProjectYarnLink" ADD CONSTRAINT "ProjectYarnLink_ownerId_fkey" FOREIGN KEY ("ownerId") REFERENCES "UserProfile"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "ProjectYarnLink" ADD CONSTRAINT "ProjectYarnLink_projectId_fkey" FOREIGN KEY ("projectId") REFERENCES "Project"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "ProjectYarnLink" ADD CONSTRAINT "ProjectYarnLink_yarnId_fkey" FOREIGN KEY ("yarnId") REFERENCES "Yarn"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "ProjectNeedleLink" ADD CONSTRAINT "ProjectNeedleLink_ownerId_fkey" FOREIGN KEY ("ownerId") REFERENCES "UserProfile"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "ProjectNeedleLink" ADD CONSTRAINT "ProjectNeedleLink_projectId_fkey" FOREIGN KEY ("projectId") REFERENCES "Project"("id") ON DELETE CASCADE ON UPDATE CASCADE;
