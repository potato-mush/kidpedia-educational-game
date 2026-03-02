import { Router, Request, Response } from 'express';
import { authenticateToken } from '../middleware/auth';
import prisma from '../lib/prisma';

const router = Router();

// Helper function to convert database topic to API format
const formatTopic = (topic: any) => {
  // Helper to safely parse JSON or convert string to array
  const parseArrayField = (field: string) => {
    try {
      return JSON.parse(field);
    } catch {
      // If it's not valid JSON, split by space
      return field ? field.split(' ').filter(Boolean) : [];
    }
  };

  return {
    ...topic,
    imagePaths: parseArrayField(topic.imagePaths),
    funFacts: parseArrayField(topic.funFacts),
    relatedTopicIds: parseArrayField(topic.relatedTopicIds),
  };
};

// Get categories (must come before /:id route)
router.get('/categories', authenticateToken, async (req: Request, res: Response) => {
  try {
    const topics = await prisma.topic.findMany({
      select: { category: true },
      distinct: ['category']
    });
    const categories = topics.map(t => t.category);
    res.json(categories);
  } catch (error) {
    res.status(500).json({ error: 'Failed to fetch categories' });
  }
});

// Get topic statistics (must come before /:id route)
router.get('/statistics', authenticateToken, async (req: Request, res: Response) => {
  try {
    const totalTopics = await prisma.topic.count();
    const topics = await prisma.topic.findMany({
      select: { readCount: true },
    });
    const totalReads = topics.reduce((sum, t) => sum + t.readCount, 0);
    
    const popularTopics = await prisma.topic.findMany({
      orderBy: { readCount: 'desc' },
      take: 5
    });
    
    res.json({
      totalTopics,
      totalReads,
      popularTopics: popularTopics.map(formatTopic),
    });
  } catch (error) {
    res.status(500).json({ error: 'Failed to fetch topic statistics' });
  }
});

// Get all topics
router.get('/', authenticateToken, async (req: Request, res: Response) => {
  try {
    const topics = await prisma.topic.findMany({
      orderBy: { createdAt: 'desc' }
    });
    res.json(topics.map(formatTopic));
  } catch (error) {
    res.status(500).json({ error: 'Failed to fetch topics' });
  }
});

// Get topic by ID
router.get('/:id', authenticateToken, async (req: Request, res: Response) => {
  try {
    const topic = await prisma.topic.findUnique({
      where: { id: req.params.id }
    });
    if (topic) {
      res.json(formatTopic(topic));
    } else {
      res.status(404).json({ error: 'Topic not found' });
    }
  } catch (error) {
    res.status(500).json({ error: 'Failed to fetch topic' });
  }
});

// Get topics by category
router.get('/category/:category', authenticateToken, async (req: Request, res: Response) => {
  try {
    const topics = await prisma.topic.findMany({
      where: { category: req.params.category }
    });
    res.json(topics.map(formatTopic));
  } catch (error) {
    res.status(500).json({ error: 'Failed to fetch topics by category' });
  }
});

// Create topic
router.post('/', authenticateToken, async (req: Request, res: Response) => {
  try {
    console.log('Creating topic with data:', JSON.stringify(req.body, null, 2));
    
    // Convert arrays to JSON strings for Prisma
    const topicData = {
      title: req.body.title,
      category: req.body.category,
      summary: req.body.summary,
      content: req.body.content,
      imagePaths: JSON.stringify(req.body.imagePaths || []),
      videoPath: req.body.videoPath || null,
      audioPath: req.body.audioPath || null,
      funFacts: JSON.stringify(req.body.funFacts || []),
      relatedTopicIds: JSON.stringify(req.body.relatedTopicIds || []),
      thumbnailPath: req.body.thumbnailPath || '',
      readCount: 0,
    };
    
    const newTopic = await prisma.topic.create({
      data: topicData
    });
    
    console.log('Topic created successfully:', newTopic.id);
    
    // Convert JSON strings back to arrays for response
    const responseData = {
      ...newTopic,
      imagePaths: JSON.parse(newTopic.imagePaths),
      funFacts: JSON.parse(newTopic.funFacts),
      relatedTopicIds: JSON.parse(newTopic.relatedTopicIds),
    };
    
    res.status(201).json(responseData);
  } catch (error) {
    console.error('Failed to create topic:', error);
    res.status(500).json({ 
      error: 'Failed to create topic',
      details: error instanceof Error ? error.message : 'Unknown error'
    });
  }
});

// Update topic
router.put('/:id', authenticateToken, async (req: Request, res: Response) => {
  try {
    // Convert arrays to JSON strings for Prisma
    const updateData: any = {};
    
    if (req.body.title !== undefined) updateData.title = req.body.title;
    if (req.body.category !== undefined) updateData.category = req.body.category;
    if (req.body.summary !== undefined) updateData.summary = req.body.summary;
    if (req.body.content !== undefined) updateData.content = req.body.content;
    if (req.body.imagePaths !== undefined) updateData.imagePaths = JSON.stringify(req.body.imagePaths);
    if (req.body.videoPath !== undefined) updateData.videoPath = req.body.videoPath;
    if (req.body.audioPath !== undefined) updateData.audioPath = req.body.audioPath;
    if (req.body.funFacts !== undefined) updateData.funFacts = JSON.stringify(req.body.funFacts);
    if (req.body.relatedTopicIds !== undefined) updateData.relatedTopicIds = JSON.stringify(req.body.relatedTopicIds);
    if (req.body.thumbnailPath !== undefined) updateData.thumbnailPath = req.body.thumbnailPath;
    
    const topic = await prisma.topic.update({
      where: { id: req.params.id },
      data: updateData
    });
    
    // Convert JSON strings back to arrays for response
    const responseData = {
      ...topic,
      imagePaths: JSON.parse(topic.imagePaths),
      funFacts: JSON.parse(topic.funFacts),
      relatedTopicIds: JSON.parse(topic.relatedTopicIds),
    };
    
    res.json(responseData);
  } catch (error) {
    console.error('Failed to update topic:', error);
    res.status(404).json({ error: 'Topic not found' });
  }
});

// Delete topic
router.delete('/:id', authenticateToken, async (req: Request, res: Response) => {
  try {
    await prisma.topic.delete({
      where: { id: req.params.id }
    });
    res.status(204).send();
  } catch (error) {
    res.status(404).json({ error: 'Topic not found' });
  }
});

export default router;
