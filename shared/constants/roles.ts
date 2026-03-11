export const Roles = {
  CITIZEN:              'CITIZEN',
  CELL_LEADER:          'CELL_LEADER',
  SECTOR_LEADER:        'SECTOR_LEADER',
  DISTRICT_LEADER:      'DISTRICT_LEADER',
  PROVINCE_LEADER:      'PROVINCE_LEADER',
  INSTITUTION_STAFF:    'INSTITUTION_STAFF',
  INSTITUTION_MANAGER:  'INSTITUTION_MANAGER',
  SYSTEM_ADMIN:         'SYSTEM_ADMIN',
} as const;

export type Role = typeof Roles[keyof typeof Roles];
export const AdminRoles: Role[] = [Roles.SYSTEM_ADMIN];
export const LeaderRoles: Role[] = [Roles.CELL_LEADER, Roles.SECTOR_LEADER, Roles.DISTRICT_LEADER, Roles.PROVINCE_LEADER];
export const InstitutionRoles: Role[] = [Roles.INSTITUTION_STAFF, Roles.INSTITUTION_MANAGER];
