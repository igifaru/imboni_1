-- CreateEnum
CREATE TYPE "BankStatus" AS ENUM ('ACTIVE', 'INACTIVE');

-- CreateEnum
CREATE TYPE "BankCaseStatus" AS ENUM ('RECEIVED', 'UNDER_REVIEW', 'INVESTIGATION', 'RESOLVED', 'ESCALATED');

-- AlterEnum
-- This migration adds more than one value to an enum.
-- With PostgreSQL versions 11 and earlier, this is not possible
-- in a single migration. This can be worked around by creating
-- multiple migrations, each migration adding only one value to
-- the enum.


ALTER TYPE "UserRole" ADD VALUE 'BANK_ADMIN';
ALTER TYPE "UserRole" ADD VALUE 'BANK_OFFICER';

-- CreateTable
CREATE TABLE "banks" (
    "id" TEXT NOT NULL,
    "bank_name" TEXT NOT NULL,
    "bank_code" TEXT NOT NULL,
    "head_office_location" TEXT NOT NULL,
    "contact_email" TEXT,
    "contact_phone" TEXT,
    "status" "BankStatus" NOT NULL DEFAULT 'ACTIVE',
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "banks_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "bank_branches" (
    "id" TEXT NOT NULL,
    "bank_id" TEXT NOT NULL,
    "branch_name" TEXT NOT NULL,
    "district" TEXT NOT NULL,
    "sector" TEXT NOT NULL,
    "address" TEXT NOT NULL,
    "contact_phone" TEXT,
    "status" "BankStatus" NOT NULL DEFAULT 'ACTIVE',
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "bank_branches_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "bank_services" (
    "id" TEXT NOT NULL,
    "bank_id" TEXT NOT NULL,
    "service_name" TEXT NOT NULL,
    "description" TEXT,
    "enabled" BOOLEAN NOT NULL DEFAULT true,

    CONSTRAINT "bank_services_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "bank_cases" (
    "id" TEXT NOT NULL,
    "case_reference" TEXT NOT NULL,
    "bank_id" TEXT NOT NULL,
    "branch_id" TEXT NOT NULL,
    "service_id" TEXT NOT NULL,
    "submitter_id" TEXT NOT NULL,
    "description" TEXT NOT NULL,
    "evidence_url" TEXT,
    "status" "BankCaseStatus" NOT NULL DEFAULT 'RECEIVED',
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "bank_cases_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "bank_case_updates" (
    "id" TEXT NOT NULL,
    "case_id" TEXT NOT NULL,
    "performed_by" TEXT NOT NULL,
    "action" "BankCaseStatus" NOT NULL,
    "notes" TEXT,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "bank_case_updates_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "bank_staff_profiles" (
    "id" TEXT NOT NULL,
    "user_id" TEXT NOT NULL,
    "bank_id" TEXT NOT NULL,
    "branch_id" TEXT,
    "role" TEXT NOT NULL DEFAULT 'OFFICER',

    CONSTRAINT "bank_staff_profiles_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "banks_bank_code_key" ON "banks"("bank_code");

-- CreateIndex
CREATE UNIQUE INDEX "bank_cases_case_reference_key" ON "bank_cases"("case_reference");

-- CreateIndex
CREATE INDEX "bank_cases_case_reference_idx" ON "bank_cases"("case_reference");

-- CreateIndex
CREATE INDEX "bank_cases_status_idx" ON "bank_cases"("status");

-- CreateIndex
CREATE UNIQUE INDEX "bank_staff_profiles_user_id_key" ON "bank_staff_profiles"("user_id");

-- AddForeignKey
ALTER TABLE "bank_branches" ADD CONSTRAINT "bank_branches_bank_id_fkey" FOREIGN KEY ("bank_id") REFERENCES "banks"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "bank_services" ADD CONSTRAINT "bank_services_bank_id_fkey" FOREIGN KEY ("bank_id") REFERENCES "banks"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "bank_cases" ADD CONSTRAINT "bank_cases_bank_id_fkey" FOREIGN KEY ("bank_id") REFERENCES "banks"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "bank_cases" ADD CONSTRAINT "bank_cases_branch_id_fkey" FOREIGN KEY ("branch_id") REFERENCES "bank_branches"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "bank_cases" ADD CONSTRAINT "bank_cases_service_id_fkey" FOREIGN KEY ("service_id") REFERENCES "bank_services"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "bank_cases" ADD CONSTRAINT "bank_cases_submitter_id_fkey" FOREIGN KEY ("submitter_id") REFERENCES "users"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "bank_case_updates" ADD CONSTRAINT "bank_case_updates_case_id_fkey" FOREIGN KEY ("case_id") REFERENCES "bank_cases"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "bank_case_updates" ADD CONSTRAINT "bank_case_updates_performed_by_fkey" FOREIGN KEY ("performed_by") REFERENCES "users"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "bank_staff_profiles" ADD CONSTRAINT "bank_staff_profiles_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "bank_staff_profiles" ADD CONSTRAINT "bank_staff_profiles_bank_id_fkey" FOREIGN KEY ("bank_id") REFERENCES "banks"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "bank_staff_profiles" ADD CONSTRAINT "bank_staff_profiles_branch_id_fkey" FOREIGN KEY ("branch_id") REFERENCES "bank_branches"("id") ON DELETE SET NULL ON UPDATE CASCADE;
