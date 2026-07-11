CREATE TABLE "GaugeRecord" (
    "id" UUID NOT NULL,
    "ownerId" TEXT NOT NULL,
    "projectId" UUID,
    "projectNameSnapshot" TEXT,
    "patternNameSnapshot" TEXT,
    "measurementStage" TEXT NOT NULL,
    "sampleWidthCm" DOUBLE PRECISION NOT NULL,
    "sampleHeightCm" DOUBLE PRECISION NOT NULL,
    "stitchCount" DOUBLE PRECISION NOT NULL,
    "rowCount" DOUBLE PRECISION NOT NULL,
    "targetWidthCm" DOUBLE PRECISION NOT NULL,
    "targetHeightCm" DOUBLE PRECISION NOT NULL,
    "stitchesPer10Cm" DOUBLE PRECISION NOT NULL,
    "rowsPer10Cm" DOUBLE PRECISION NOT NULL,
    "targetStitches" INTEGER NOT NULL,
    "targetRows" INTEGER NOT NULL,
    "needle" TEXT NOT NULL,
    "memo" TEXT NOT NULL,
    "measuredAt" TIMESTAMP(3) NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,
    "deletedAt" TIMESTAMP(3),

    CONSTRAINT "GaugeRecord_pkey" PRIMARY KEY ("id")
);

CREATE INDEX "GaugeRecord_ownerId_deletedAt_idx" ON "GaugeRecord"("ownerId", "deletedAt");
CREATE INDEX "GaugeRecord_ownerId_projectId_measurementStage_deletedAt_idx" ON "GaugeRecord"("ownerId", "projectId", "measurementStage", "deletedAt");

ALTER TABLE "GaugeRecord" ADD CONSTRAINT "GaugeRecord_ownerId_fkey" FOREIGN KEY ("ownerId") REFERENCES "UserProfile"("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "GaugeRecord" ADD CONSTRAINT "GaugeRecord_projectId_fkey" FOREIGN KEY ("projectId") REFERENCES "Project"("id") ON DELETE SET NULL ON UPDATE CASCADE;
