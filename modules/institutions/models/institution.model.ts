export interface InstitutionModel {
  id: string;
  typeId: string;
  name: string;
  description?: string;
  email?: string;
  phone?: string;
  website?: string;
  hqLocation?: string;
  status: 'ACTIVE' | 'INACTIVE' | 'SUSPENDED';
  createdAt: Date;
  updatedAt: Date;
}
