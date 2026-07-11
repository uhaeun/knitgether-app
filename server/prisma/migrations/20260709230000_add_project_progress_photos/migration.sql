CREATE TABLE "ProjectProgressPhoto" (
    "id" UUID NOT NULL,
    "ownerId" TEXT NOT NULL,
    "projectId" UUID NOT NULL,
    "fileName" TEXT NOT NULL,
    "contentType" TEXT NOT NULL,
    "byteSize" INTEGER NOT NULL,
    "storageKey" TEXT NOT NULL,
    "caption" TEXT NOT NULL DEFAULT '',
    "takenAt" TIMESTAMP(3) NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,
    "deletedAt" TIMESTAMP(3),

    CONSTRAINT "ProjectProgressPhoto_pkey" PRIMARY KEY ("id")
);

CREATE UNIQUE INDEX "ProjectProgressPhoto_storageKey_key" ON "ProjectProgressPhoto"("storageKey");
CREATE INDEX "ProjectProgressPhoto_ownerId_projectId_deletedAt_idx" ON "ProjectProgressPhoto"("ownerId", "projectId", "deletedAt");

ALTER TABLE "ProjectProgressPhoto"
ADD CONSTRAINT "ProjectProgressPhoto_ownerId_fkey"
FOREIGN KEY ("ownerId") REFERENCES "UserProfile"("id") ON DELETE CASCADE ON UPDATE CASCADE;

ALTER TABLE "ProjectProgressPhoto"
ADD CONSTRAINT "ProjectProgressPhoto_projectId_fkey"
FOREIGN KEY ("projectId") REFERENCES "Project"("id") ON DELETE CASCADE ON UPDATE CASCADE;
