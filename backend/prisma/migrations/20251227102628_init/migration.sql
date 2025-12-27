-- CreateEnum
CREATE TYPE "AdministrativeLevel" AS ENUM ('VILLAGE', 'CELL', 'SECTOR', 'DISTRICT', 'PROVINCE', 'NATIONAL');

-- CreateEnum
CREATE TYPE "UserRole" AS ENUM ('CITIZEN', 'LEADER', 'ADMIN', 'OVERSIGHT', 'NGO');

-- CreateEnum
CREATE TYPE "UserStatus" AS ENUM ('ACTIVE', 'SUSPENDED', 'INACTIVE');

-- CreateEnum
CREATE TYPE "ProtectionLevel" AS ENUM ('ANONYMOUS', 'PROTECTED', 'IDENTIFIED');

-- CreateEnum
CREATE TYPE "CaseCategory" AS ENUM ('JUSTICE', 'HEALTH', 'LAND', 'INFRASTRUCTURE', 'SECURITY', 'SOCIAL', 'EDUCATION', 'OTHER');

-- CreateEnum
CREATE TYPE "CaseUrgency" AS ENUM ('NORMAL', 'HIGH', 'EMERGENCY');

-- CreateEnum
CREATE TYPE "CaseStatus" AS ENUM ('OPEN', 'IN_PROGRESS', 'RESOLVED', 'ESCALATED', 'CLOSED');

-- CreateEnum
CREATE TYPE "ActionType" AS ENUM ('ACKNOWLEDGED', 'COMMENT', 'STATUS_UPDATE', 'ASSIGNMENT', 'RESOLUTION');

-- CreateEnum
CREATE TYPE "TriggerReason" AS ENUM ('TIME_EXPIRED', 'EMERGENCY_OVERRIDE', 'MANUAL_ESCALATION');

-- CreateEnum
CREATE TYPE "NotificationChannel" AS ENUM ('SMS', 'EMAIL', 'PUSH');

-- CreateTable
CREATE TABLE "administrative_units" (
    "id" TEXT NOT NULL,
    "name" TEXT NOT NULL,
    "level" "AdministrativeLevel" NOT NULL,
    "code" TEXT NOT NULL,
    "parent_id" TEXT,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "administrative_units_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "users" (
    "id" TEXT NOT NULL,
    "role" "UserRole" NOT NULL DEFAULT 'CITIZEN',
    "phone" TEXT,
    "email" TEXT,
    "password" TEXT NOT NULL,
    "status" "UserStatus" NOT NULL DEFAULT 'ACTIVE',
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "users_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "leader_assignments" (
    "id" TEXT NOT NULL,
    "user_id" TEXT NOT NULL,
    "administrative_unit_id" TEXT NOT NULL,
    "position_title" TEXT NOT NULL,
    "start_date" TIMESTAMP(3) NOT NULL,
    "end_date" TIMESTAMP(3),
    "is_active" BOOLEAN NOT NULL DEFAULT true,

    CONSTRAINT "leader_assignments_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "citizen_profiles" (
    "id" TEXT NOT NULL,
    "user_id" TEXT NOT NULL,
    "national_id" TEXT,
    "protection_level" "ProtectionLevel" NOT NULL DEFAULT 'ANONYMOUS',

    CONSTRAINT "citizen_profiles_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "cases" (
    "id" TEXT NOT NULL,
    "case_reference" TEXT NOT NULL,
    "category" "CaseCategory" NOT NULL,
    "urgency" "CaseUrgency" NOT NULL DEFAULT 'NORMAL',
    "title" TEXT NOT NULL,
    "description" TEXT NOT NULL,
    "administrative_unit_id" TEXT NOT NULL,
    "current_level" "AdministrativeLevel" NOT NULL,
    "status" "CaseStatus" NOT NULL DEFAULT 'OPEN',
    "submitted_anonymously" BOOLEAN NOT NULL DEFAULT false,
    "submitter_id" TEXT,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "resolved_at" TIMESTAMP(3),

    CONSTRAINT "cases_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "case_assignments" (
    "id" TEXT NOT NULL,
    "case_id" TEXT NOT NULL,
    "administrative_unit_id" TEXT NOT NULL,
    "leader_id" TEXT NOT NULL,
    "assigned_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "deadline_at" TIMESTAMP(3) NOT NULL,
    "completed_at" TIMESTAMP(3),
    "escalation_reason" TEXT,
    "is_active" BOOLEAN NOT NULL DEFAULT true,

    CONSTRAINT "case_assignments_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "escalation_events" (
    "id" TEXT NOT NULL,
    "case_id" TEXT NOT NULL,
    "from_level" "AdministrativeLevel" NOT NULL,
    "to_level" "AdministrativeLevel" NOT NULL,
    "triggered_by" TEXT NOT NULL DEFAULT 'SYSTEM',
    "trigger_reason" "TriggerReason" NOT NULL,
    "triggered_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "escalation_events_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "case_actions" (
    "id" TEXT NOT NULL,
    "case_id" TEXT NOT NULL,
    "performed_by" TEXT NOT NULL,
    "action_type" "ActionType" NOT NULL,
    "notes" TEXT,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "case_actions_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "audit_logs" (
    "id" TEXT NOT NULL,
    "entity_type" TEXT NOT NULL,
    "entity_id" TEXT NOT NULL,
    "action" TEXT NOT NULL,
    "performed_by" TEXT,
    "old_value" JSONB,
    "new_value" JSONB,
    "timestamp" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "audit_logs_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "notifications" (
    "id" TEXT NOT NULL,
    "user_id" TEXT NOT NULL,
    "case_id" TEXT,
    "channel" "NotificationChannel" NOT NULL,
    "message" TEXT NOT NULL,
    "sent_at" TIMESTAMP(3),
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "notifications_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "administrative_units_code_key" ON "administrative_units"("code");

-- CreateIndex
CREATE UNIQUE INDEX "users_phone_key" ON "users"("phone");

-- CreateIndex
CREATE UNIQUE INDEX "users_email_key" ON "users"("email");

-- CreateIndex
CREATE UNIQUE INDEX "citizen_profiles_user_id_key" ON "citizen_profiles"("user_id");

-- CreateIndex
CREATE UNIQUE INDEX "citizen_profiles_national_id_key" ON "citizen_profiles"("national_id");

-- CreateIndex
CREATE UNIQUE INDEX "cases_case_reference_key" ON "cases"("case_reference");

-- CreateIndex
CREATE INDEX "cases_case_reference_idx" ON "cases"("case_reference");

-- CreateIndex
CREATE INDEX "cases_status_idx" ON "cases"("status");

-- CreateIndex
CREATE INDEX "case_assignments_case_id_idx" ON "case_assignments"("case_id");

-- CreateIndex
CREATE INDEX "case_assignments_deadline_at_idx" ON "case_assignments"("deadline_at");

-- CreateIndex
CREATE INDEX "escalation_events_case_id_idx" ON "escalation_events"("case_id");

-- CreateIndex
CREATE INDEX "audit_logs_entity_type_entity_id_idx" ON "audit_logs"("entity_type", "entity_id");

-- AddForeignKey
ALTER TABLE "administrative_units" ADD CONSTRAINT "administrative_units_parent_id_fkey" FOREIGN KEY ("parent_id") REFERENCES "administrative_units"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "leader_assignments" ADD CONSTRAINT "leader_assignments_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "leader_assignments" ADD CONSTRAINT "leader_assignments_administrative_unit_id_fkey" FOREIGN KEY ("administrative_unit_id") REFERENCES "administrative_units"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "citizen_profiles" ADD CONSTRAINT "citizen_profiles_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "cases" ADD CONSTRAINT "cases_administrative_unit_id_fkey" FOREIGN KEY ("administrative_unit_id") REFERENCES "administrative_units"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "case_assignments" ADD CONSTRAINT "case_assignments_case_id_fkey" FOREIGN KEY ("case_id") REFERENCES "cases"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "case_assignments" ADD CONSTRAINT "case_assignments_administrative_unit_id_fkey" FOREIGN KEY ("administrative_unit_id") REFERENCES "administrative_units"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "case_assignments" ADD CONSTRAINT "case_assignments_leader_id_fkey" FOREIGN KEY ("leader_id") REFERENCES "users"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "escalation_events" ADD CONSTRAINT "escalation_events_case_id_fkey" FOREIGN KEY ("case_id") REFERENCES "cases"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "case_actions" ADD CONSTRAINT "case_actions_case_id_fkey" FOREIGN KEY ("case_id") REFERENCES "cases"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "case_actions" ADD CONSTRAINT "case_actions_performed_by_fkey" FOREIGN KEY ("performed_by") REFERENCES "users"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "audit_logs" ADD CONSTRAINT "audit_logs_performed_by_fkey" FOREIGN KEY ("performed_by") REFERENCES "users"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "notifications" ADD CONSTRAINT "notifications_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "notifications" ADD CONSTRAINT "notifications_case_id_fkey" FOREIGN KEY ("case_id") REFERENCES "cases"("id") ON DELETE SET NULL ON UPDATE CASCADE;
