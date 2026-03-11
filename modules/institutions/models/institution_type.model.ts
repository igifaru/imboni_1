export interface InstitutionTypeModel {
  id: string;
  name: string;        // e.g. 'BANK', 'INSURANCE', 'TELECOM'
  description?: string;
  createdAt: Date;
}
