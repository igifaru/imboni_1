export interface InstitutionServiceModel {
  id: string;
  institutionId: string;
  serviceName: string;
  description?: string;
  processingDays?: number;
  status: 'ACTIVE' | 'INACTIVE';
}
