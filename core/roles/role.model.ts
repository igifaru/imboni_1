import { Permissions, Permission } from '@config/permissions';

export interface RoleDefinition {
  name: string;
  label: string;
  permissions: Permission[];
}

export const RoleDefinitions: Record<string, RoleDefinition> = {
  CITIZEN: {
    name: 'CITIZEN', label: 'Citizen',
    permissions: [Permissions.CASE_CREATE, Permissions.CASE_READ, Permissions.INST_REQUEST],
  },
  CELL_LEADER: {
    name: 'CELL_LEADER', label: 'Cell Leader',
    permissions: [Permissions.CASE_READ, Permissions.CASE_UPDATE, Permissions.CASE_RESOLVE, Permissions.CASE_ESCALATE],
  },
  INSTITUTION_MANAGER: {
    name: 'INSTITUTION_MANAGER', label: 'Institution Manager',
    permissions: [Permissions.INST_MANAGE, Permissions.BRANCH_MANAGE, Permissions.STAFF_ASSIGN],
  },
  SYSTEM_ADMIN: {
    name: 'SYSTEM_ADMIN', label: 'System Administrator',
    permissions: Object.values(Permissions) as Permission[],
  },
};
