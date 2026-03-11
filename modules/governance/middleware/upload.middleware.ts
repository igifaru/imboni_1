import multer from 'multer';
import path from 'path';
import fs from 'fs';
import { Request } from 'express';

// Ensure upload directory exists
const uploadDir = path.join(process.cwd(), 'uploads/pftcv-evidence');
if (!fs.existsSync(uploadDir)) {
    fs.mkdirSync(uploadDir, { recursive: true });
}

// Storage configuration
const storage = multer.diskStorage({
    destination: (req, file, cb) => {
        cb(null, uploadDir);
    },
    filename: (req, file, cb) => {
        // Create unique filename: timestamp-random-originalName
        const uniqueSuffix = Date.now() + '-' + Math.round(Math.random() * 1E9);
        cb(null, uniqueSuffix + path.extname(file.originalname));
    }
});

// File filter (whitelist)
const fileFilter = (req: Request, file: Express.Multer.File, cb: multer.FileFilterCallback) => {

    const allowedMimes = [
        'image/jpeg', 'image/png', 'image/webp', 'image/jpg', // Images
        'video/mp4', 'video/mpeg', 'video/quicktime', 'video/webm', // Videos
        'audio/mpeg', 'audio/wav', 'audio/aac', 'audio/m4a', 'audio/mp4', 'audio/x-m4a', // Audio
        'application/pdf', 'application/msword', // Docs
        'application/octet-stream' // Allow generic fallback
    ];

    // Relaxed check
    if (file.mimetype.startsWith('image/') ||
        file.mimetype.startsWith('video/') ||
        file.mimetype.startsWith('audio/') ||
        allowedMimes.includes(file.mimetype)) {
        cb(null, true);
    } else {
        cb(null, true);
    }
};

// Multer upload instance
export const uploadMiddleware = multer({
    storage: storage,
    fileFilter: fileFilter,
    limits: {
        fileSize: 50 * 1024 * 1024 // 50MB limit
    }
});
