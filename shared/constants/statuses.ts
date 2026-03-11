export const CaseStatuses = {
  OPEN:       'OPEN',
  IN_PROGRESS:'IN_PROGRESS',
  RESOLVED:   'RESOLVED',
  CLOSED:     'CLOSED',
  ESCALATED:  'ESCALATED',
  REJECTED:   'REJECTED',
} as const;

export const RequestStatuses = {
  SUBMITTED:    'SUBMITTED',
  RECEIVED:     'RECEIVED',
  UNDER_REVIEW: 'UNDER_REVIEW',
  INVESTIGATION:'INVESTIGATION',
  RESOLVED:     'RESOLVED',
  ESCALATED:    'ESCALATED',
  REJECTED:     'REJECTED',
} as const;

export const InstitutionStatuses = {
  ACTIVE:    'ACTIVE',
  INACTIVE:  'INACTIVE',
  SUSPENDED: 'SUSPENDED',
} as const;
