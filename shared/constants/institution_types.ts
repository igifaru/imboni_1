export const InstitutionTypes = {
  BANK:        { code: 'BANK',        label: 'Bank',                icon: 'account_balance' },
  INSURANCE:   { code: 'INSURANCE',   label: 'Insurance',           icon: 'shield' },
  TELECOM:     { code: 'TELECOM',     label: 'Telecommunications',  icon: 'cell_tower' },
  GOVERNMENT:  { code: 'GOVERNMENT',  label: 'Government Agency',   icon: 'gavel' },
  HEALTHCARE:  { code: 'HEALTHCARE',  label: 'Healthcare',          icon: 'local_hospital' },
  UTILITY:     { code: 'UTILITY',     label: 'Utility Provider',    icon: 'bolt' },
} as const;

export type InstitutionTypeCode = keyof typeof InstitutionTypes;
