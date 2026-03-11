export interface GovernanceLevelModel {
  id: string;
  name: string;
  level: number;          // 1=Cell, 2=Sector, 3=District, 4=Province, 5=National
  parentId?: string;
  province?: string;
  district?: string;
  sector?: string;
}
