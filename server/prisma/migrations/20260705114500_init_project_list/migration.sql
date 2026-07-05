-- CreateSchema
CREATE SCHEMA IF NOT EXISTS "public";

-- CreateTable
CREATE TABLE "UserProfile" (
    "id" TEXT NOT NULL,
    "displayName" TEXT NOT NULL,
    "preferredUnits" TEXT NOT NULL DEFAULT 'metric',
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,
    "deletedAt" TIMESTAMP(3),

    CONSTRAINT "UserProfile_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "Project" (
    "id" UUID NOT NULL,
    "ownerId" TEXT NOT NULL,
    "name" TEXT NOT NULL,
    "status" TEXT NOT NULL,
    "isFavorite" BOOLEAN NOT NULL DEFAULT false,
    "memo" TEXT NOT NULL DEFAULT '',
    "startDate" TIMESTAMP(3) NOT NULL,
    "lastWorkedAt" TIMESTAMP(3),
    "workspaceDisplayMode" TEXT,
    "workspaceSheetPosition" TEXT,
    "relatedSkillIds" TEXT[] DEFAULT ARRAY[]::TEXT[],
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,
    "deletedAt" TIMESTAMP(3),

    CONSTRAINT "Project_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "RowCounter" (
    "id" UUID NOT NULL,
    "ownerId" TEXT NOT NULL,
    "projectId" UUID NOT NULL,
    "name" TEXT NOT NULL DEFAULT 'Main Counter',
    "currentRow" INTEGER NOT NULL,
    "targetRow" INTEGER,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,
    "deletedAt" TIMESTAMP(3),

    CONSTRAINT "RowCounter_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "WorkSession" (
    "id" UUID NOT NULL,
    "ownerId" TEXT NOT NULL,
    "projectId" UUID NOT NULL,
    "startedAt" TIMESTAMP(3) NOT NULL,
    "endedAt" TIMESTAMP(3),
    "memo" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,
    "deletedAt" TIMESTAMP(3),

    CONSTRAINT "WorkSession_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE INDEX "Project_ownerId_deletedAt_idx" ON "Project"("ownerId", "deletedAt");

-- CreateIndex
CREATE UNIQUE INDEX "RowCounter_projectId_key" ON "RowCounter"("projectId");

-- CreateIndex
CREATE INDEX "RowCounter_ownerId_deletedAt_idx" ON "RowCounter"("ownerId", "deletedAt");

-- CreateIndex
CREATE INDEX "WorkSession_ownerId_projectId_deletedAt_idx" ON "WorkSession"("ownerId", "projectId", "deletedAt");

-- AddForeignKey
ALTER TABLE "Project" ADD CONSTRAINT "Project_ownerId_fkey" FOREIGN KEY ("ownerId") REFERENCES "UserProfile"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "RowCounter" ADD CONSTRAINT "RowCounter_ownerId_fkey" FOREIGN KEY ("ownerId") REFERENCES "UserProfile"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "RowCounter" ADD CONSTRAINT "RowCounter_projectId_fkey" FOREIGN KEY ("projectId") REFERENCES "Project"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "WorkSession" ADD CONSTRAINT "WorkSession_ownerId_fkey" FOREIGN KEY ("ownerId") REFERENCES "UserProfile"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "WorkSession" ADD CONSTRAINT "WorkSession_projectId_fkey" FOREIGN KEY ("projectId") REFERENCES "Project"("id") ON DELETE CASCADE ON UPDATE CASCADE;
