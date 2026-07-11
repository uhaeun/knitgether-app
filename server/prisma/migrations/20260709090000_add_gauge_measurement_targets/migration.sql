CREATE TABLE "GaugeTarget" (
    "id" UUID NOT NULL,
    "ownerId" TEXT NOT NULL,
    "name" TEXT NOT NULL,
    "targetStitches" DOUBLE PRECISION NOT NULL,
    "targetWidth" DOUBLE PRECISION NOT NULL,
    "targetRows" DOUBLE PRECISION NOT NULL DEFAULT 0,
    "targetHeight" DOUBLE PRECISION NOT NULL DEFAULT 0,
    "isQuickMeasure" BOOLEAN NOT NULL DEFAULT false,
    "gaugeAfterWash" BOOLEAN NOT NULL DEFAULT false,
    "recommendedNeedle" TEXT,
    "sourcePatternId" UUID,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,
    "deletedAt" TIMESTAMP(3),

    CONSTRAINT "GaugeTarget_pkey" PRIMARY KEY ("id")
);

CREATE TABLE "GaugeSwatch" (
    "id" UUID NOT NULL,
    "ownerId" TEXT NOT NULL,
    "gaugeTargetId" UUID NOT NULL,
    "isSelected" BOOLEAN NOT NULL DEFAULT false,
    "knittedAt" TIMESTAMP(3),
    "needleMaterial" TEXT,
    "needleSize" TEXT,
    "needleType" TEXT,
    "notes" TEXT,
    "stitchPattern" TEXT,
    "yarnBrand" TEXT,
    "yarnColor" TEXT,
    "yarnLot" TEXT,
    "yarnName" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,
    "deletedAt" TIMESTAMP(3),

    CONSTRAINT "GaugeSwatch_pkey" PRIMARY KEY ("id")
);

CREATE TABLE "GaugeMeasurement" (
    "id" UUID NOT NULL,
    "ownerId" TEXT NOT NULL,
    "gaugeTargetId" UUID NOT NULL,
    "gaugeSwatchId" UUID NOT NULL,
    "method" TEXT NOT NULL,
    "washState" TEXT NOT NULL,
    "measuredWidth" DOUBLE PRECISION NOT NULL,
    "measuredHeight" DOUBLE PRECISION NOT NULL,
    "rawStitches" DOUBLE PRECISION NOT NULL,
    "rawRows" DOUBLE PRECISION NOT NULL DEFAULT 0,
    "normalizedStitches" DOUBLE PRECISION NOT NULL,
    "normalizedRows" DOUBLE PRECISION NOT NULL DEFAULT 0,
    "finalStitches" DOUBLE PRECISION NOT NULL,
    "finalRows" DOUBLE PRECISION NOT NULL DEFAULT 0,
    "autoStitches" DOUBLE PRECISION NOT NULL DEFAULT 0,
    "autoRows" DOUBLE PRECISION NOT NULL DEFAULT 0,
    "autoConfidence" TEXT,
    "userModified" BOOLEAN NOT NULL DEFAULT false,
    "photoPath" TEXT,
    "cornerCoordinates" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,
    "deletedAt" TIMESTAMP(3),

    CONSTRAINT "GaugeMeasurement_pkey" PRIMARY KEY ("id")
);

CREATE INDEX "GaugeTarget_ownerId_deletedAt_idx" ON "GaugeTarget"("ownerId", "deletedAt");
CREATE INDEX "GaugeTarget_sourcePatternId_idx" ON "GaugeTarget"("sourcePatternId");
CREATE INDEX "GaugeSwatch_ownerId_gaugeTargetId_deletedAt_idx" ON "GaugeSwatch"("ownerId", "gaugeTargetId", "deletedAt");
CREATE INDEX "GaugeMeasurement_ownerId_gaugeTargetId_deletedAt_idx" ON "GaugeMeasurement"("ownerId", "gaugeTargetId", "deletedAt");
CREATE INDEX "GaugeMeasurement_ownerId_gaugeSwatchId_washState_deletedAt_idx" ON "GaugeMeasurement"("ownerId", "gaugeSwatchId", "washState", "deletedAt");

ALTER TABLE "GaugeTarget" ADD CONSTRAINT "GaugeTarget_ownerId_fkey" FOREIGN KEY ("ownerId") REFERENCES "UserProfile"("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "GaugeTarget" ADD CONSTRAINT "GaugeTarget_sourcePatternId_fkey" FOREIGN KEY ("sourcePatternId") REFERENCES "PatternDocument"("id") ON DELETE SET NULL ON UPDATE CASCADE;
ALTER TABLE "GaugeSwatch" ADD CONSTRAINT "GaugeSwatch_ownerId_fkey" FOREIGN KEY ("ownerId") REFERENCES "UserProfile"("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "GaugeSwatch" ADD CONSTRAINT "GaugeSwatch_gaugeTargetId_fkey" FOREIGN KEY ("gaugeTargetId") REFERENCES "GaugeTarget"("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "GaugeMeasurement" ADD CONSTRAINT "GaugeMeasurement_ownerId_fkey" FOREIGN KEY ("ownerId") REFERENCES "UserProfile"("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "GaugeMeasurement" ADD CONSTRAINT "GaugeMeasurement_gaugeTargetId_fkey" FOREIGN KEY ("gaugeTargetId") REFERENCES "GaugeTarget"("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "GaugeMeasurement" ADD CONSTRAINT "GaugeMeasurement_gaugeSwatchId_fkey" FOREIGN KEY ("gaugeSwatchId") REFERENCES "GaugeSwatch"("id") ON DELETE CASCADE ON UPDATE CASCADE;
