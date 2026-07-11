-- CreateTable
CREATE TABLE "ProjectPatternCopy" (
    "id" UUID NOT NULL,
    "ownerId" TEXT NOT NULL,
    "projectId" UUID NOT NULL,
    "sourcePatternDocumentId" UUID,
    "titleSnapshot" TEXT NOT NULL,
    "designerSnapshot" TEXT,
    "fileNameSnapshot" TEXT,
    "pageCountSnapshot" INTEGER,
    "drawingUpdatedAt" TIMESTAMP(3),
    "copiedAt" TIMESTAMP(3) NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,
    "deletedAt" TIMESTAMP(3),

    CONSTRAINT "ProjectPatternCopy_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "ProjectPatternCopy_projectId_key" ON "ProjectPatternCopy"("projectId");

-- CreateIndex
CREATE INDEX "ProjectPatternCopy_ownerId_deletedAt_idx" ON "ProjectPatternCopy"("ownerId", "deletedAt");

-- CreateIndex
CREATE INDEX "ProjectPatternCopy_sourcePatternDocumentId_idx" ON "ProjectPatternCopy"("sourcePatternDocumentId");

-- AddForeignKey
ALTER TABLE "ProjectPatternCopy" ADD CONSTRAINT "ProjectPatternCopy_ownerId_fkey" FOREIGN KEY ("ownerId") REFERENCES "UserProfile"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "ProjectPatternCopy" ADD CONSTRAINT "ProjectPatternCopy_projectId_fkey" FOREIGN KEY ("projectId") REFERENCES "Project"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "ProjectPatternCopy" ADD CONSTRAINT "ProjectPatternCopy_sourcePatternDocumentId_fkey" FOREIGN KEY ("sourcePatternDocumentId") REFERENCES "PatternDocument"("id") ON DELETE SET NULL ON UPDATE CASCADE;
