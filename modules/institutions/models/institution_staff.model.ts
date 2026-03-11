export interface InstitutionStaffModel {
  id: string;
  userId: string;
  institutionId: string;
  branchId?: string;
  role: 'BRANCH_AGENT' | 'BRANCH_MANAGER' | 'REGIONAL_MANAGER' | 'HQ_MANAGER';
  assignedAt: Date;
  active: boolean;
}
