import { RoleDefinitions, RoleDefinition } from './role.model';
import { Permission } from '@config/permissions';

export const roleService = {
  getAll(): RoleDefinition[] {
    return Object.values(RoleDefinitions);
  },

  getByName(name: string): RoleDefinition | undefined {
    return RoleDefinitions[name];
  },

  hasPermission(roleName: string, permission: Permission): boolean {
    const role = RoleDefinitions[roleName];
    return role?.permissions.includes(permission) ?? false;
  },
};
