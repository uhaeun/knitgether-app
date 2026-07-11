CREATE TABLE "ToolItem" (
    "id" UUID NOT NULL,
    "ownerId" TEXT NOT NULL,
    "name" TEXT NOT NULL,
    "type" TEXT NOT NULL,
    "link" TEXT,
    "memo" TEXT NOT NULL DEFAULT '',
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,
    "deletedAt" TIMESTAMP(3),

    CONSTRAINT "ToolItem_pkey" PRIMARY KEY ("id")
);

CREATE TABLE "ProjectToolLink" (
    "id" UUID NOT NULL,
    "ownerId" TEXT NOT NULL,
    "projectId" UUID NOT NULL,
    "toolId" UUID NOT NULL,
    "linkedAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,
    "deletedAt" TIMESTAMP(3),

    CONSTRAINT "ProjectToolLink_pkey" PRIMARY KEY ("id")
);

CREATE INDEX "ToolItem_ownerId_type_deletedAt_idx" ON "ToolItem"("ownerId", "type", "deletedAt");
CREATE INDEX "ToolItem_ownerId_deletedAt_idx" ON "ToolItem"("ownerId", "deletedAt");

CREATE UNIQUE INDEX "ProjectToolLink_projectId_toolId_key" ON "ProjectToolLink"("projectId", "toolId");
CREATE INDEX "ProjectToolLink_ownerId_projectId_deletedAt_idx" ON "ProjectToolLink"("ownerId", "projectId", "deletedAt");
CREATE INDEX "ProjectToolLink_ownerId_toolId_deletedAt_idx" ON "ProjectToolLink"("ownerId", "toolId", "deletedAt");

ALTER TABLE "ToolItem" ADD CONSTRAINT "ToolItem_ownerId_fkey" FOREIGN KEY ("ownerId") REFERENCES "UserProfile"("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "ProjectToolLink" ADD CONSTRAINT "ProjectToolLink_ownerId_fkey" FOREIGN KEY ("ownerId") REFERENCES "UserProfile"("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "ProjectToolLink" ADD CONSTRAINT "ProjectToolLink_projectId_fkey" FOREIGN KEY ("projectId") REFERENCES "Project"("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "ProjectToolLink" ADD CONSTRAINT "ProjectToolLink_toolId_fkey" FOREIGN KEY ("toolId") REFERENCES "ToolItem"("id") ON DELETE CASCADE ON UPDATE CASCADE;
