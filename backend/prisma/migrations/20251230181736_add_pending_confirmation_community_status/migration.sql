-- CreateEnum
CREATE TYPE "EvidenceType" AS ENUM ('IMAGE', 'VIDEO', 'AUDIO', 'DOCUMENT');

-- AlterEnum
-- This migration adds more than one value to an enum.
-- With PostgreSQL versions 11 and earlier, this is not possible
-- in a single migration. This can be worked around by creating
-- multiple migrations, each migration adding only one value to
-- the enum.


ALTER TYPE "CaseStatus" ADD VALUE 'PENDING_CONFIRMATION';
ALTER TYPE "CaseStatus" ADD VALUE 'COMMUNITY';

-- AlterTable
ALTER TABLE "citizen_profiles" ADD COLUMN     "cell" TEXT,
ADD COLUMN     "country" TEXT DEFAULT 'Rwanda',
ADD COLUMN     "district" TEXT,
ADD COLUMN     "province" TEXT,
ADD COLUMN     "sector" TEXT,
ADD COLUMN     "village" TEXT;

-- AlterTable
ALTER TABLE "users" ADD COLUMN     "name" TEXT,
ADD COLUMN     "profile_picture" TEXT;

-- CreateTable
CREATE TABLE "evidence" (
    "id" TEXT NOT NULL,
    "case_id" TEXT NOT NULL,
    "type" "EvidenceType" NOT NULL,
    "url" TEXT NOT NULL,
    "file_name" TEXT NOT NULL,
    "file_size" INTEGER NOT NULL,
    "mime_type" TEXT NOT NULL,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "evidence_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "case_resolutions" (
    "id" TEXT NOT NULL,
    "case_id" TEXT NOT NULL,
    "notes" TEXT NOT NULL,
    "resolved_by" TEXT NOT NULL,
    "resolved_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "evidence_id" TEXT,

    CONSTRAINT "case_resolutions_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE INDEX "evidence_case_id_idx" ON "evidence"("case_id");

-- CreateIndex
CREATE UNIQUE INDEX "case_resolutions_case_id_key" ON "case_resolutions"("case_id");

-- CreateIndex
CREATE UNIQUE INDEX "case_resolutions_evidence_id_key" ON "case_resolutions"("evidence_id");

-- AddForeignKey
ALTER TABLE "cases" ADD CONSTRAINT "cases_submitter_id_fkey" FOREIGN KEY ("submitter_id") REFERENCES "users"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "evidence" ADD CONSTRAINT "evidence_case_id_fkey" FOREIGN KEY ("case_id") REFERENCES "cases"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "case_resolutions" ADD CONSTRAINT "case_resolutions_case_id_fkey" FOREIGN KEY ("case_id") REFERENCES "cases"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "case_resolutions" ADD CONSTRAINT "case_resolutions_evidence_id_fkey" FOREIGN KEY ("evidence_id") REFERENCES "evidence"("id") ON DELETE SET NULL ON UPDATE CASCADE;
