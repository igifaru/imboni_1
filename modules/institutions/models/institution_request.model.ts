export interface InstitutionRequestModel {
  id: string;
  citizenId: string;
  institutionId: string;
  branchId: string;
  serviceId: string;
  title: string;
  description: string;
  status: RequestStatus;
  priority: RequestPriority;
  createdAt: Date;
  resolvedAt?: Date;
}

export type RequestStatus =
  | 'SUBMITTED' | 'RECEIVED' | 'UNDER_REVIEW'
  | 'INVESTIGATION' | 'RESOLVED' | 'ESCALATED' | 'REJECTED';

export type RequestPriority = 'LOW' | 'NORMAL' | 'HIGH' | 'URGENT';
