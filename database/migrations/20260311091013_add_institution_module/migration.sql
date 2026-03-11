/*
  Warnings:

  - The values [BANK_ADMIN,BANK_OFFICER] on the enum `UserRole` will be removed. If these variants are still used in the database, this will fail.

*/
-- CreateEnum
CREATE TYPE "InstitutionRole" AS ENUM ('INSTITUTION_ADMIN', 'BRANCH_MANAGER', 'OFFICER');

-- CreateEnum
CREATE TYPE "RequestStatus" AS ENUM ('SUBMITTED', 'RECEIVED', 'UNDER_REVIEW', 'INVESTIGATION', 'RESOLVED', 'ESCALATED', 'REJECTED');

-- CreateEnum
CREATE TYPE "RequestPriority" AS ENUM ('LOW', 'NORMAL', 'HIGH', 'URGENT');

-- AlterEnum
BEGIN;
CREATE TYPE "UserRole_new" AS ENUM ('CITIZEN', 'LEADER', 'ADMIN', 'OVERSIGHT', 'NGO', 'SUPER_ADMIN', 'INSTITUTION_ADMIN', 'BRANCH_MANAGER', 'OFFICER');
ALTER TABLE "users" ALTER COLUMN "role" DROP DEFAULT;
ALTER TABLE "users" ALTER COLUMN "role" TYPE "UserRole_new" USING ("role"::text::"UserRole_new");
ALTER TYPE "UserRole" RENAME TO "UserRole_old";
ALTER TYPE "UserRole_new" RENAME TO "UserRole";
DROP TYPE "UserRole_old";
ALTER TABLE "users" ALTER COLUMN "role" SET DEFAULT 'CITIZEN';
COMMIT;

-- CreateTable
CREATE TABLE "institution_types" (
    "id" TEXT NOT NULL,
    "name" TEXT NOT NULL,
    "description" TEXT,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "institution_types_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "institutions" (
    "id" TEXT NOT NULL,
    "name" TEXT NOT NULL,
    "type_id" TEXT NOT NULL,
    "description" TEXT,
    "email" TEXT,
    "phone" TEXT,
    "website" TEXT,
    "hq_location" TEXT,
    "status" TEXT NOT NULL DEFAULT 'ACTIVE',
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "institutions_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "institution_branches" (
    "id" TEXT NOT NULL,
    "institution_id" TEXT NOT NULL,
    "branch_name" TEXT NOT NULL,
    "province" TEXT NOT NULL,
    "district" TEXT NOT NULL,
    "sector" TEXT NOT NULL,
    "address" TEXT NOT NULL,
    "manager_id" TEXT,
    "status" TEXT NOT NULL DEFAULT 'ACTIVE',
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "institution_branches_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "institution_staff" (
    "id" TEXT NOT NULL,
    "user_id" TEXT NOT NULL,
    "institution_id" TEXT NOT NULL,
    "branch_id" TEXT,
    "role" "InstitutionRole" NOT NULL DEFAULT 'OFFICER',
    "status" TEXT NOT NULL DEFAULT 'ACTIVE',
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "institution_staff_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "institution_services" (
    "id" TEXT NOT NULL,
    "institution_id" TEXT NOT NULL,
    "service_name" TEXT NOT NULL,
    "description" TEXT,
    "processing_days" INTEGER,
    "status" TEXT NOT NULL DEFAULT 'ACTIVE',
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "institution_services_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "institution_requests" (
    "id" TEXT NOT NULL,
    "citizen_id" TEXT NOT NULL,
    "institution_id" TEXT NOT NULL,
    "branch_id" TEXT NOT NULL,
    "service_id" TEXT NOT NULL,
    "title" TEXT NOT NULL,
    "description" TEXT NOT NULL,
    "status" "RequestStatus" NOT NULL DEFAULT 'SUBMITTED',
    "priority" "RequestPriority" NOT NULL DEFAULT 'NORMAL',
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "resolved_at" TIMESTAMP(3),

    CONSTRAINT "institution_requests_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "request_escalations" (
    "id" TEXT NOT NULL,
    "request_id" TEXT NOT NULL,
    "from_role" "InstitutionRole" NOT NULL,
    "to_role" "InstitutionRole" NOT NULL,
    "reason" TEXT NOT NULL,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "request_escalations_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "institution_types_name_key" ON "institution_types"("name");

-- CreateIndex
CREATE UNIQUE INDEX "institutions_email_key" ON "institutions"("email");

-- CreateIndex
CREATE UNIQUE INDEX "institution_staff_user_id_key" ON "institution_staff"("user_id");

-- AddForeignKey
ALTER TABLE "institutions" ADD CONSTRAINT "institutions_type_id_fkey" FOREIGN KEY ("type_id") REFERENCES "institution_types"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "institution_branches" ADD CONSTRAINT "institution_branches_institution_id_fkey" FOREIGN KEY ("institution_id") REFERENCES "institutions"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "institution_staff" ADD CONSTRAINT "institution_staff_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "institution_staff" ADD CONSTRAINT "institution_staff_institution_id_fkey" FOREIGN KEY ("institution_id") REFERENCES "institutions"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "institution_staff" ADD CONSTRAINT "institution_staff_branch_id_fkey" FOREIGN KEY ("branch_id") REFERENCES "institution_branches"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "institution_services" ADD CONSTRAINT "institution_services_institution_id_fkey" FOREIGN KEY ("institution_id") REFERENCES "institutions"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "institution_requests" ADD CONSTRAINT "institution_requests_citizen_id_fkey" FOREIGN KEY ("citizen_id") REFERENCES "users"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "institution_requests" ADD CONSTRAINT "institution_requests_institution_id_fkey" FOREIGN KEY ("institution_id") REFERENCES "institutions"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "institution_requests" ADD CONSTRAINT "institution_requests_branch_id_fkey" FOREIGN KEY ("branch_id") REFERENCES "institution_branches"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "institution_requests" ADD CONSTRAINT "institution_requests_service_id_fkey" FOREIGN KEY ("service_id") REFERENCES "institution_services"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "request_escalations" ADD CONSTRAINT "request_escalations_request_id_fkey" FOREIGN KEY ("request_id") REFERENCES "institution_requests"("id") ON DELETE CASCADE ON UPDATE CASCADE;
