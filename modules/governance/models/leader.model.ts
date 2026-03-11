export interface LeaderModel {
  id: string;
  userId: string;
  level: GovernanceLevel;
  province?: string;
  district?: string;
  sector?: string;
  cell?: string;
  village?: string;
  startDate: Date;
  endDate?: Date;
}

export type GovernanceLevel =
  | 'CELL' | 'SECTOR' | 'DISTRICT' | 'PROVINCE' | 'NATIONAL';
