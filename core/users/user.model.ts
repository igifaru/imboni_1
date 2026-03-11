export interface UserModel {
  id: string;
  name: string;
  phone: string;
  email?: string;
  password: string;
  role: UserRole;
  province?: string;
  district?: string;
  profilePicture?: string;
  createdAt: Date;
  updatedAt: Date;
}

export type UserRole =
  | 'CITIZEN' | 'CELL_LEADER' | 'SECTOR_LEADER'
  | 'DISTRICT_LEADER' | 'PROVINCE_LEADER'
  | 'INSTITUTION_STAFF' | 'INSTITUTION_MANAGER'
  | 'SYSTEM_ADMIN';

export interface CreateUserDto {
  name: string;
  phone: string;
  password: string;
  role?: UserRole;
}

export interface UpdateUserDto {
  name?: string;
  email?: string;
  province?: string;
  district?: string;
}
