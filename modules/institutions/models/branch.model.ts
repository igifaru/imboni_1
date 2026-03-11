export interface BranchModel {
  id: string;
  institutionId: string;
  branchName: string;
  province: string;
  district: string;
  sector: string;
  address: string;
  managerId?: string;
  status: 'ACTIVE' | 'INACTIVE';
}
