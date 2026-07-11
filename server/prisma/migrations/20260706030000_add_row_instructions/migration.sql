-- AlterTable
ALTER TABLE "RowCounter" ADD COLUMN "mode" TEXT NOT NULL DEFAULT 'simple';
ALTER TABLE "RowCounter" ADD COLUMN "sectionName" TEXT;
ALTER TABLE "RowCounter" ADD COLUMN "memo" TEXT;

-- CreateTable
CREATE TABLE "RowInstruction" (
    "id" UUID NOT NULL,
    "ownerId" TEXT NOT NULL,
    "projectId" UUID NOT NULL,
    "rowCounterId" UUID NOT NULL,
    "rowNumber" INTEGER NOT NULL,
    "instructionText" TEXT NOT NULL,
    "skillTags" TEXT NOT NULL DEFAULT '',
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,
    "deletedAt" TIMESTAMP(3),

    CONSTRAINT "RowInstruction_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "RowInstruction_rowCounterId_rowNumber_key" ON "RowInstruction"("rowCounterId", "rowNumber");

-- CreateIndex
CREATE INDEX "RowInstruction_ownerId_projectId_deletedAt_idx" ON "RowInstruction"("ownerId", "projectId", "deletedAt");

-- AddForeignKey
ALTER TABLE "RowInstruction" ADD CONSTRAINT "RowInstruction_ownerId_fkey" FOREIGN KEY ("ownerId") REFERENCES "UserProfile"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "RowInstruction" ADD CONSTRAINT "RowInstruction_projectId_fkey" FOREIGN KEY ("projectId") REFERENCES "Project"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "RowInstruction" ADD CONSTRAINT "RowInstruction_rowCounterId_fkey" FOREIGN KEY ("rowCounterId") REFERENCES "RowCounter"("id") ON DELETE CASCADE ON UPDATE CASCADE;
