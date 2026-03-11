/** Centralised permission keys used throughout RBAC */
export const Permissions = {
  // Governance
  CASE_CREATE:     'case:create',
  CASE_READ:       'case:read',
  CASE_UPDATE:     'case:update',
  CASE_RESOLVE:    'case:resolve',
  CASE_ESCALATE:   'case:escalate',
  // Institutions
  INST_MANAGE:     'institution:manage',
  INST_REQUEST:    'institution:request',
  BRANCH_MANAGE:   'branch:manage',
  STAFF_ASSIGN:    'staff:assign',
  // Administration
  USER_MANAGE:     'user:manage',
  ROLE_MANAGE:     'role:manage',
  SYSTEM_SETTINGS: 'system:settings',
  REPORTS_VIEW:    'reports:view',
} as const;

export type Permission = typeof Permissions[keyof typeof Permissions];
