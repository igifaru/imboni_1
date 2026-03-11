-- CreateEnum
CREATE TYPE "EvidencePurpose" AS ENUM ('SUBMISSION', 'RESOLUTION');

-- CreateEnum
CREATE TYPE "ProjectSector" AS ENUM ('ROADS', 'HEALTH', 'EDUCATION', 'WATER', 'SOCIAL_AID', 'AGRICULTURE', 'ENERGY', 'OTHER');

-- CreateEnum
CREATE TYPE "ProjectStatus" AS ENUM ('PLANNED', 'IN_PROGRESS', 'COMPLETED', 'SUSPENDED', 'CANCELLED');

-- CreateEnum
CREATE TYPE "DeliveryStatus" AS ENUM ('FULLY_DELIVERED', 'PARTIALLY_DELIVERED', 'NOT_DELIVERED', 'NOT_STARTED');

-- CreateEnum
CREATE TYPE "RiskLevel" AS ENUM ('NORMAL', 'NEEDS_REVIEW', 'HIGH_RISK');

-- AlterTable
ALTER TABLE "case_assignments" ADD COLUMN     "alert_viewed" BOOLEAN NOT NULL DEFAULT false,
ADD COLUMN     "extension_count" INTEGER NOT NULL DEFAULT 0,
ADD COLUMN     "extension_reason" TEXT;

-- AlterTable
ALTER TABLE "evidence" ADD COLUMN     "description" TEXT,
ADD COLUMN     "purpose" "EvidencePurpose" NOT NULL DEFAULT 'SUBMISSION';

-- CreateTable
CREATE TABLE "projects" (
    "id" TEXT NOT NULL,
    "project_code" TEXT NOT NULL,
    "name" TEXT NOT NULL,
    "sector" "ProjectSector" NOT NULL,
    "description" TEXT,
    "administrative_unit_id" TEXT NOT NULL,
    "gps_latitude" DOUBLE PRECISION,
    "gps_longitude" DOUBLE PRECISION,
    "approved_budget" DOUBLE PRECISION NOT NULL,
    "funding_source" TEXT,
    "implementing_agency" TEXT,
    "expected_outputs" TEXT,
    "start_date" TIMESTAMP(3),
    "end_date" TIMESTAMP(3),
    "status" "ProjectStatus" NOT NULL DEFAULT 'PLANNED',
    "risk_level" "RiskLevel" NOT NULL DEFAULT 'NORMAL',
    "risk_score" INTEGER NOT NULL DEFAULT 0,
    "verified_percentage" INTEGER NOT NULL DEFAULT 0,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "projects_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "fund_releases" (
    "id" TEXT NOT NULL,
    "project_id" TEXT NOT NULL,
    "amount" DOUBLE PRECISION NOT NULL,
    "release_date" TIMESTAMP(3) NOT NULL,
    "release_ref" TEXT,
    "description" TEXT,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "fund_releases_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "citizen_verifications" (
    "id" TEXT NOT NULL,
    "project_id" TEXT NOT NULL,
    "verifier_id" TEXT,
    "is_anonymous" BOOLEAN NOT NULL DEFAULT false,
    "delivery_status" "DeliveryStatus" NOT NULL,
    "completion_percent" INTEGER NOT NULL DEFAULT 0,
    "quality_rating" INTEGER,
    "comment" TEXT,
    "gps_latitude" DOUBLE PRECISION,
    "gps_longitude" DOUBLE PRECISION,
    "verified_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "citizen_verifications_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "verification_evidence" (
    "id" TEXT NOT NULL,
    "verification_id" TEXT NOT NULL,
    "type" "EvidenceType" NOT NULL,
    "url" TEXT NOT NULL,
    "file_name" TEXT NOT NULL,
    "file_size" INTEGER NOT NULL,
    "mime_type" TEXT NOT NULL,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "verification_evidence_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "projects_project_code_key" ON "projects"("project_code");

-- CreateIndex
CREATE INDEX "projects_sector_idx" ON "projects"("sector");

-- CreateIndex
CREATE INDEX "projects_status_idx" ON "projects"("status");

-- CreateIndex
CREATE INDEX "projects_risk_level_idx" ON "projects"("risk_level");

-- CreateIndex
CREATE INDEX "fund_releases_project_id_idx" ON "fund_releases"("project_id");

-- CreateIndex
CREATE INDEX "citizen_verifications_project_id_idx" ON "citizen_verifications"("project_id");

-- CreateIndex
CREATE INDEX "verification_evidence_verification_id_idx" ON "verification_evidence"("verification_id");

-- CreateIndex
CREATE INDEX "evidence_purpose_idx" ON "evidence"("purpose");

-- AddForeignKey
ALTER TABLE "projects" ADD CONSTRAINT "projects_administrative_unit_id_fkey" FOREIGN KEY ("administrative_unit_id") REFERENCES "administrative_units"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "fund_releases" ADD CONSTRAINT "fund_releases_project_id_fkey" FOREIGN KEY ("project_id") REFERENCES "projects"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "citizen_verifications" ADD CONSTRAINT "citizen_verifications_project_id_fkey" FOREIGN KEY ("project_id") REFERENCES "projects"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "citizen_verifications" ADD CONSTRAINT "citizen_verifications_verifier_id_fkey" FOREIGN KEY ("verifier_id") REFERENCES "users"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "verification_evidence" ADD CONSTRAINT "verification_evidence_verification_id_fkey" FOREIGN KEY ("verification_id") REFERENCES "citizen_verifications"("id") ON DELETE CASCADE ON UPDATE CASCADE;
