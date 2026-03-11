import { storageService } from './storage.service';

export const fileService = {
  saveEvidence(filename: string): string {
    return storageService.getPublicUrl('evidence', filename);
  },

  savePftcvEvidence(filename: string): string {
    return storageService.getPublicUrl('pftcv-evidence', filename);
  },

  deleteFile(filePath: string): void {
    storageService.deleteFile(filePath);
  },
};
