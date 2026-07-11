ALTER TABLE "Project"
ADD COLUMN "yarnId" UUID,
ADD COLUMN "yarnNameSnapshot" TEXT,
ADD COLUMN "yarnBrandSnapshot" TEXT,
ADD COLUMN "yarnColorwaySnapshot" TEXT,
ADD COLUMN "yarnWeightSnapshot" TEXT,
ADD COLUMN "needleId" UUID,
ADD COLUMN "needleNameSnapshot" TEXT,
ADD COLUMN "needleTypeSnapshot" TEXT,
ADD COLUMN "needleSizeSnapshot" TEXT,
ADD COLUMN "needleLengthSnapshot" TEXT;

CREATE INDEX "Project_ownerId_yarnId_deletedAt_idx" ON "Project"("ownerId", "yarnId", "deletedAt");
CREATE INDEX "Project_ownerId_needleId_deletedAt_idx" ON "Project"("ownerId", "needleId", "deletedAt");
