export interface RequestEscalationModel {
  id: string;
  requestId: string;
  fromRole: string;
  toRole: string;
  reason: string;
  escalatedBy: string;
  escalatedAt: Date;
}
