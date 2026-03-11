export interface SystemSetting {
  key: string;
  value: string | number | boolean;
  description?: string;
  updatedAt: Date;
}

export type SettingKey =
  | 'escalation_normal_hours'
  | 'escalation_high_hours'
  | 'escalation_emergency_hours'
  | 'max_file_size_mb'
  | 'allowed_file_types'
  | 'sms_enabled'
  | 'email_enabled'
  | 'push_enabled';
