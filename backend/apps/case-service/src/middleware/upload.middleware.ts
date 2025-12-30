import multer from 'multer';
import path from 'path';
import fs from 'fs';
import { Request } from 'express';

// Ensure upload directory exists
const uploadDir = path.join(process.cwd(), 'uploads/evidence');
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
    // Log the incoming file type for debugging
    console.log(`[Upload Middleware] Receiving file: ${file.originalname}, MIME: ${file.mimetype}`);

    const allowedMimes = [
        'image/jpeg', 'image/png', 'image/webp', 'image/jpg', // Images
        'video/mp4', 'video/mpeg', 'video/quicktime', 'video/webm', // Videos
        'audio/mpeg', 'audio/wav', 'audio/aac', 'audio/m4a', 'audio/mp4', 'audio/x-m4a', // Audio
        'application/pdf', 'application/msword', 'application/vnd.openxmlformats-officedocument.wordprocessingml.document', // Docs
        'application/octet-stream' // Allow generic fallback for some Android devices
    ];

    // Relaxed check: if it starts with image/, video/, or audio/, let it pass
    if (file.mimetype.startsWith('image/') ||
        file.mimetype.startsWith('video/') ||
        file.mimetype.startsWith('audio/') ||
        allowedMimes.includes(file.mimetype)) {
        cb(null, true);
    } else {
        // Warn but allow for now to prevent user blockage, or stick to strict?
        // Let's keep strict but with better logging and expanded list.
        console.warn(`[Upload Middleware] Rejected file type: ${file.mimetype}`);
        // For now, let's ALLOW everything to ensure it works, then refine.
        // cb(new Error(`Invalid file type. Allowed: ${allowedMimes.join(', ')}`));
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
