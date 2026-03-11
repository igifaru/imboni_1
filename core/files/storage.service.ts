import fs from 'fs';
import path from 'path';

const UPLOAD_DIR = path.join(process.cwd(), 'uploads');

export const storageService = {
  ensureDir(subdir: string): string {
    const dir = path.join(UPLOAD_DIR, subdir);
    if (!fs.existsSync(dir)) fs.mkdirSync(dir, { recursive: true });
    return dir;
  },

  getFilePath(subdir: string, filename: string): string {
    return path.join(UPLOAD_DIR, subdir, filename);
  },

  deleteFile(filePath: string): void {
    if (fs.existsSync(filePath)) fs.unlinkSync(filePath);
  },

  getPublicUrl(subdir: string, filename: string): string {
    return `/uploads/${subdir}/${filename}`;
  },
};
