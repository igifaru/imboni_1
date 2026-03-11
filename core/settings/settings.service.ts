import { SettingKey, SystemSetting } from './settings.model';

/** In-memory settings cache — replace with DB-backed store if needed */
const defaults: Record<SettingKey, SystemSetting> = {
  escalation_normal_hours:    { key: 'escalation_normal_hours',    value: 48,  updatedAt: new Date() },
  escalation_high_hours:      { key: 'escalation_high_hours',      value: 24,  updatedAt: new Date() },
  escalation_emergency_hours: { key: 'escalation_emergency_hours', value: 4,   updatedAt: new Date() },
  max_file_size_mb:           { key: 'max_file_size_mb',           value: 10,  updatedAt: new Date() },
  allowed_file_types:         { key: 'allowed_file_types',         value: 'jpg,jpeg,png,pdf,mp4', updatedAt: new Date() },
  sms_enabled:                { key: 'sms_enabled',                value: false, updatedAt: new Date() },
  email_enabled:              { key: 'email_enabled',              value: false, updatedAt: new Date() },
  push_enabled:               { key: 'push_enabled',               value: false, updatedAt: new Date() },
};

export const settingsService = {
  get<T>(key: SettingKey): T {
    return defaults[key].value as T;
  },

  set(key: SettingKey, value: SystemSetting['value']): void {
    defaults[key] = { ...defaults[key], value, updatedAt: new Date() };
  },

  getAll(): SystemSetting[] {
    return Object.values(defaults);
  },
};
