import { Router, Request, Response } from 'express';
import prisma from '../lib/prisma';

const router = Router();

// Helper function to convert database format to API format
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

const formatGame = (game: any) => ({
  ...game,
  configurationData: JSON.parse(game.configurationData),
});

// Public endpoints for mobile app (no authentication required)

// Get all topics
router.get('/topics', async (req: Request, res: Response) => {
  try {
    const topics = await prisma.topic.findMany({
      orderBy: { createdAt: 'desc' }
    });
    res.json(topics.map(formatTopic));
  } catch (error) {
    console.error('Error fetching topics:', error);
    res.status(500).json({ error: 'Failed to fetch topics' });
  }
});

// Get topic by ID
router.get('/topics/:id', async (req: Request, res: Response) => {
  try {
    const topic = await prisma.topic.findUnique({
      where: { id: req.params.id }
    });
    
    if (!topic) {
      return res.status(404).json({ error: 'Topic not found' });
    }
    
    res.json(formatTopic(topic));
  } catch (error) {
    console.error('Error fetching topic:', error);
    res.status(500).json({ error: 'Failed to fetch topic' });
  }
});

// Get topics by category
router.get('/topics/category/:category', async (req: Request, res: Response) => {
  try {
    const topics = await prisma.topic.findMany({
      where: { category: req.params.category },
      orderBy: { createdAt: 'desc' }
    });
    res.json(topics.map(formatTopic));
  } catch (error) {
    console.error('Error fetching topics by category:', error);
    res.status(500).json({ error: 'Failed to fetch topics' });
  }
});

// Get all categories
router.get('/categories', async (req: Request, res: Response) => {
  try {
    const topics = await prisma.topic.findMany({
      select: { category: true },
      distinct: ['category']
    });
    
    const categories = topics.map(t => t.category);
    res.json(categories);
  } catch (error) {
    console.error('Error fetching categories:', error);
    res.status(500).json({ error: 'Failed to fetch categories' });
  }
});

// Get all games
router.get('/games', async (req: Request, res: Response) => {
  try {
    const games = await prisma.game.findMany({
      orderBy: { createdAt: 'desc' }
    });
    res.json(games.map(formatGame));
  } catch (error) {
    console.error('Error fetching games:', error);
    res.status(500).json({ error: 'Failed to fetch games' });
  }
});

// Get game by ID
router.get('/games/:id', async (req: Request, res: Response) => {
  try {
    const game = await prisma.game.findUnique({
      where: { id: req.params.id }
    });
    
    if (!game) {
      return res.status(404).json({ error: 'Game not found' });
    }
    
    res.json(formatGame(game));
  } catch (error) {
    console.error('Error fetching game:', error);
    res.status(500).json({ error: 'Failed to fetch game' });
  }
});

// Get games by type
router.get('/games/type/:type', async (req: Request, res: Response) => {
  try {
    const games = await prisma.game.findMany({
      where: { type: req.params.type },
      orderBy: { createdAt: 'desc' }
    });
    res.json(games.map(formatGame));
  } catch (error) {
    console.error('Error fetching games by type:', error);
    res.status(500).json({ error: 'Failed to fetch games' });
  }
});

// Get all badges
router.get('/badges', async (req: Request, res: Response) => {
  try {
    const badges = await prisma.badge.findMany();
    res.json(badges);
  } catch (error) {
    console.error('Error fetching badges:', error);
    res.status(500).json({ error: 'Failed to fetch badges' });
  }
});

// Increment topic read count
router.post('/topics/:id/read', async (req: Request, res: Response) => {
  try {
    const topic = await prisma.topic.update({
      where: { id: req.params.id },
      data: {
        readCount: {
          increment: 1
        }
      }
    });
    
    res.json({ success: true, readCount: topic.readCount });
  } catch (error) {
    console.error('Error incrementing read count:', error);
    res.status(500).json({ error: 'Failed to increment read count' });
  }
});

export default router;
