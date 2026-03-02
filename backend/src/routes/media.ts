import { Router, Request, Response } from 'express';
import multer from 'multer';
import path from 'path';
import { authenticateToken } from '../middleware/auth';
import prisma from '../lib/prisma';
import fs from 'fs';

const router = Router();

// Configure multer for file uploads
const storage = multer.diskStorage({
  destination: (req, file, cb) => {
    const uploadDir = process.env.UPLOAD_DIR || './uploads';
    if (!fs.existsSync(uploadDir)) {
      fs.mkdirSync(uploadDir, { recursive: true });
    }
    cb(null, uploadDir);
  },
  filename: (req, file, cb) => {
    const uniqueName = `${Date.now()}-${file.originalname}`;
    cb(null, uniqueName);
  },
});

const upload = multer({
  storage,
  limits: {
    fileSize: parseInt(process.env.MAX_FILE_SIZE || '104857600'), // 100MB default
  },
  fileFilter: (req, file, cb) => {
    // Define allowed file extensions and MIME types
    const imageTypes = /\.(jpeg|jpg|png|gif|webp)$/i;
    const videoTypes = /\.(mp4|webm|mov|avi)$/i;
    const audioTypes = /\.(mp3|wav|ogg|m4a|aac)$/i;
    
    const imageMimeTypes = /^image\/(jpeg|jpg|png|gif|webp)$/i;
    const videoMimeTypes = /^video\/(mp4|webm|quicktime|x-msvideo)$/i;
    const audioMimeTypes = /^audio\/(mpeg|mp3|wav|ogg|x-wav|x-m4a|aac)$/i;
    
    const extname = file.originalname;
    const mimetype = file.mimetype;
    
    const isValidExtension = imageTypes.test(extname) || videoTypes.test(extname) || audioTypes.test(extname);
    const isValidMimetype = imageMimeTypes.test(mimetype) || videoMimeTypes.test(mimetype) || audioMimeTypes.test(mimetype);
    
    if (isValidExtension && isValidMimetype) {
      cb(null, true);
    } else {
      console.log('File rejected:', { filename: file.originalname, mimetype: file.mimetype });
      cb(new Error(`Invalid file type. File: ${file.originalname}, MIME: ${file.mimetype}`));
    }
  },
});

// Get media statistics (must come before /:id route)
router.get('/statistics', authenticateToken, async (req: Request, res: Response) => {
  try {
    const totalFiles = await prisma.mediaFile.count();
    const mediaFiles = await prisma.mediaFile.findMany({
      select: { size: true }
    });
    const totalSize = mediaFiles.reduce((sum, m) => sum + m.size, 0);
    
    const imageCount = await prisma.mediaFile.count({ where: { type: 'image' } });
    const videoCount = await prisma.mediaFile.count({ where: { type: 'video' } });
    const audioCount = await prisma.mediaFile.count({ where: { type: 'audio' } });
    
    res.json({
      totalFiles,
      totalSize,
      filesByType: {
        image: imageCount,
        video: videoCount,
        audio: audioCount,
      },
    });
  } catch (error) {
    res.status(500).json({ error: 'Failed to fetch media statistics' });
  }
});

// Get all media
router.get('/', authenticateToken, async (req: Request, res: Response) => {
  try {
    const mediaFiles = await prisma.mediaFile.findMany({
      orderBy: { uploadedAt: 'desc' }
    });
    res.json(mediaFiles);
  } catch (error) {
    res.status(500).json({ error: 'Failed to fetch media files' });
  }
});

// Get media by type
router.get('/type/:type', authenticateToken, async (req: Request, res: Response) => {
  try {
    const mediaFiles = await prisma.mediaFile.findMany({
      where: { type: req.params.type }
    });
    res.json(mediaFiles);
  } catch (error) {
    res.status(500).json({ error: 'Failed to fetch media by type' });
  }
});

// Get media by category
router.get('/category/:category', authenticateToken, async (req: Request, res: Response) => {
  try {
    const mediaFiles = await prisma.mediaFile.findMany({
      where: { category: req.params.category }
    });
    res.json(mediaFiles);
  } catch (error) {
    res.status(500).json({ error: 'Failed to fetch media by category' });
  }
});

// Upload single file
router.post('/upload', authenticateToken, (req: Request, res: Response) => {
  upload.single('file')(req, res, async (err) => {
    // Handle multer errors
    if (err instanceof multer.MulterError) {
      if (err.code === 'LIMIT_FILE_SIZE') {
        return res.status(400).json({ 
          error: 'File too large', 
          details: 'File size must be less than 100MB' 
        });
      }
      return res.status(400).json({ 
        error: 'Upload error', 
        details: err.message 
      });
    } else if (err) {
      return res.status(400).json({ 
        error: 'Upload error', 
        details: err.message 
      });
    }

    // No file uploaded
    if (!req.file) {
      return res.status(400).json({ error: 'No file uploaded' });
    }

    try {
      const type = req.body.type || 'image';
      const category = req.body.category || 'general';

      console.log('Uploading file:', {
        filename: req.file.filename,
        originalname: req.file.originalname,
        type,
        category,
        size: req.file.size
      });

      const mediaFile = await prisma.mediaFile.create({
        data: {
          name: req.file.originalname,
          path: `/uploads/${req.file.filename}`,
          type,
          category,
          size: req.file.size,
        }
      });

      console.log('Media file saved:', mediaFile);
      res.status(201).json(mediaFile);
    } catch (error) {
      console.error('Media upload error:', error);
      res.status(500).json({ 
        error: 'Failed to save media file', 
        details: error instanceof Error ? error.message : 'Unknown error' 
      });
    }
  });
});

// Upload multiple files
router.post('/upload-multiple', authenticateToken, (req: Request, res: Response) => {
  upload.array('files', 10)(req, res, async (err) => {
    // Handle multer errors
    if (err instanceof multer.MulterError) {
      if (err.code === 'LIMIT_FILE_SIZE') {
        return res.status(400).json({ 
          error: 'File too large', 
          details: 'Each file size must be less than 100MB' 
        });
      }
      return res.status(400).json({ 
        error: 'Upload error', 
        details: err.message 
      });
    } else if (err) {
      return res.status(400).json({ 
        error: 'Upload error', 
        details: err.message 
      });
    }

    // No files uploaded
    if (!req.files || !Array.isArray(req.files) || req.files.length === 0) {
      return res.status(400).json({ error: 'No files uploaded' });
    }

    try {
      const type = req.body.type || 'image';
      const category = req.body.category;

      const uploadedFilesPromises = req.files.map((file) => {
        return prisma.mediaFile.create({
          data: {
            name: file.originalname,
            path: `/uploads/${file.filename}`,
            type,
            category,
            size: file.size,
          }
      });
    });

    const uploadedFiles = await Promise.all(uploadedFilesPromises);
    res.status(201).json(uploadedFiles);
  } catch (error) {
    res.status(500).json({ 
      error: 'Failed to save media files',
      details: error instanceof Error ? error.message : 'Unknown error'
    });
  }
  });
});

// Delete media
router.delete('/:id', authenticateToken, async (req: Request, res: Response) => {
  try {
    const mediaFile = await prisma.mediaFile.findUnique({
      where: { id: req.params.id }
    });

    if (!mediaFile) {
      return res.status(404).json({ error: 'Media not found' });
    }

    const filePath = path.join(__dirname, '../../', mediaFile.path);
    
    // Delete physical file
    if (fs.existsSync(filePath)) {
      fs.unlinkSync(filePath);
    }
    
    // Delete from database
    await prisma.mediaFile.delete({
      where: { id: req.params.id }
    });

    res.status(204).send();
  } catch (error) {
    res.status(500).json({ error: 'Failed to delete media file' });
  }
});

export default router;
