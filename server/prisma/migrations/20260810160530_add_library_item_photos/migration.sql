-- AlterTable
ALTER TABLE "Needle" ADD COLUMN     "photoByteSize" INTEGER,
ADD COLUMN     "photoContentType" TEXT,
ADD COLUMN     "photoStorageKey" TEXT;

-- AlterTable
ALTER TABLE "ToolItem" ADD COLUMN     "photoByteSize" INTEGER,
ADD COLUMN     "photoContentType" TEXT,
ADD COLUMN     "photoStorageKey" TEXT;

-- AlterTable
ALTER TABLE "Yarn" ADD COLUMN     "photoByteSize" INTEGER,
ADD COLUMN     "photoContentType" TEXT,
ADD COLUMN     "photoStorageKey" TEXT;
