CREATE TABLE "Yarn" (
    "id" UUID NOT NULL,
    "ownerId" TEXT NOT NULL,
    "name" TEXT NOT NULL,
    "brand" TEXT,
    "colorway" TEXT,
    "weight" TEXT,
    "quantity" INTEGER NOT NULL,
    "notes" TEXT NOT NULL DEFAULT '',
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,
    "deletedAt" TIMESTAMP(3),

    CONSTRAINT "Yarn_pkey" PRIMARY KEY ("id")
);

CREATE TABLE "Needle" (
    "id" UUID NOT NULL,
    "ownerId" TEXT NOT NULL,
    "name" TEXT NOT NULL,
    "needleType" TEXT NOT NULL,
    "size" TEXT NOT NULL,
    "length" TEXT,
    "notes" TEXT NOT NULL DEFAULT '',
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,
    "deletedAt" TIMESTAMP(3),

    CONSTRAINT "Needle_pkey" PRIMARY KEY ("id")
);

CREATE INDEX "Yarn_ownerId_deletedAt_idx" ON "Yarn"("ownerId", "deletedAt");
CREATE INDEX "Needle_ownerId_deletedAt_idx" ON "Needle"("ownerId", "deletedAt");

ALTER TABLE "Yarn" ADD CONSTRAINT "Yarn_ownerId_fkey" FOREIGN KEY ("ownerId") REFERENCES "UserProfile"("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "Needle" ADD CONSTRAINT "Needle_ownerId_fkey" FOREIGN KEY ("ownerId") REFERENCES "UserProfile"("id") ON DELETE CASCADE ON UPDATE CASCADE;
