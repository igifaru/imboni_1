export interface CitizenIssueModel {
  id: string;
  referenceId: string;
  citizenId: string;
  title: string;
  description: string;
  category: string;
  province: string;
  district: string;
  sector: string;
  cell: string;
  status: IssueStatus;
  priority: IssuePriority;
  assignedTo?: string;
  createdAt: Date;
  updatedAt: Date;
}

export type IssueStatus = 'OPEN' | 'IN_PROGRESS' | 'RESOLVED' | 'CLOSED' | 'ESCALATED' | 'REJECTED';
export type IssuePriority = 'LOW' | 'NORMAL' | 'HIGH' | 'EMERGENCY';
