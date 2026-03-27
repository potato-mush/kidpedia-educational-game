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

const isNonEmptyString = (value: unknown): value is string => {
  return typeof value === 'string' && value.trim().length > 0;
};

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

// Create/update child profile from app
router.post('/users/upsert', async (req: Request, res: Response) => {
  try {
    const { id, username, avatarId } = req.body as {
      id?: unknown;
      username?: unknown;
      avatarId?: unknown;
    };

    if (!isNonEmptyString(id) || !isNonEmptyString(username) || !isNonEmptyString(avatarId)) {
      return res.status(400).json({
        error: 'id, username, and avatarId are required string fields'
      });
    }

    const user = await prisma.user.upsert({
      where: { id },
      update: {
        username: username.trim(),
        avatarId: avatarId.trim(),
      },
      create: {
        id,
        username: username.trim(),
        avatarId: avatarId.trim(),
      },
    });

    res.json(user);
  } catch (error) {
    console.error('Error upserting user:', error);
    res.status(500).json({ error: 'Failed to upsert user' });
  }
});

// Get child profile by username (used by app sign-in recovery)
router.get('/users/by-username/:username', async (req: Request, res: Response) => {
  try {
    const username = decodeURIComponent(req.params.username || '').trim();
    if (!username) {
      return res.status(400).json({ error: 'username is required' });
    }

    const user = await prisma.user.findFirst({
      where: {
        username,
      },
      select: {
        id: true,
        username: true,
        avatarId: true,
      },
    });

    if (!user) {
      return res.status(404).json({ error: 'User not found' });
    }

    res.json(user);
  } catch (error) {
    console.error('Error fetching user by username:', error);
    res.status(500).json({ error: 'Failed to fetch user' });
  }
});

// Get user activity snapshot for app state restore
router.get('/users/:id/snapshot', async (req: Request, res: Response) => {
  try {
    const userId = req.params.id;
    if (!isNonEmptyString(userId)) {
      return res.status(400).json({ error: 'user id is required' });
    }

    const user = await prisma.user.findUnique({
      where: { id: userId },
      select: { id: true },
    });

    if (!user) {
      return res.status(404).json({ error: 'User not found' });
    }

    const [scores, progress, bookmarks] = await Promise.all([
      prisma.gameScore.findMany({
        where: { userId },
        include: {
          game: {
            select: {
              type: true,
              difficulty: true,
            },
          },
        },
      }),
      prisma.progress.findMany({
        where: { userId },
        select: {
          topicId: true,
          lastAccessedAt: true,
        },
      }),
      prisma.bookmark.findMany({
        where: { userId },
        select: {
          topicId: true,
        },
      }),
    ]);

    res.json({
      gameScores: scores.map((s) => ({
        id: s.id,
        gameId: s.gameId,
        gameType: s.game.type,
        score: s.score,
        timeTaken: s.timeTaken,
        completedAt: s.completedAt.toISOString(),
        difficulty: s.game.difficulty,
      })),
      progress: progress.map((p) => ({
        topicId: p.topicId,
        lastAccessedAt: p.lastAccessedAt.toISOString(),
      })),
      bookmarks: bookmarks.map((b) => ({
        topicId: b.topicId,
      })),
    });
  } catch (error) {
    console.error('Error fetching user snapshot:', error);
    res.status(500).json({ error: 'Failed to fetch user snapshot' });
  }
});

// Upsert topic progress for a user
router.post('/users/:id/progress', async (req: Request, res: Response) => {
  try {
    const userId = (req.params.id || '').trim();
    const { topicId, lastAccessedAt } = req.body as {
      topicId?: unknown;
      lastAccessedAt?: unknown;
    };

    if (!isNonEmptyString(userId) || !isNonEmptyString(topicId)) {
      return res.status(400).json({ error: 'user id and topicId are required' });
    }

    const user = await prisma.user.findUnique({
      where: { id: userId },
      select: { id: true },
    });
    if (!user) {
      return res.status(404).json({ error: 'User not found' });
    }

    const topic = await prisma.topic.findUnique({
      where: { id: topicId },
      select: { id: true },
    });
    if (!topic) {
      return res.status(404).json({ error: 'Topic not found' });
    }

    const accessedAt = isNonEmptyString(lastAccessedAt)
      ? new Date(lastAccessedAt)
      : new Date();

    const progress = await prisma.progress.upsert({
      where: {
        userId_topicId: {
          userId,
          topicId,
        },
      },
      update: {
        lastAccessedAt: accessedAt,
      },
      create: {
        userId,
        topicId,
        gamesCompleted: '[]',
        totalScore: 0,
        lastAccessedAt: accessedAt,
      },
      select: {
        userId: true,
        topicId: true,
        lastAccessedAt: true,
      },
    });

    res.json(progress);
  } catch (error) {
    console.error('Error upserting user progress:', error);
    res.status(500).json({ error: 'Failed to save user progress' });
  }
});

// Add bookmark for a user
router.post('/users/:id/bookmarks', async (req: Request, res: Response) => {
  try {
    const userId = (req.params.id || '').trim();
    const { topicId } = req.body as { topicId?: unknown };

    if (!isNonEmptyString(userId) || !isNonEmptyString(topicId)) {
      return res.status(400).json({ error: 'user id and topicId are required' });
    }

    const user = await prisma.user.findUnique({
      where: { id: userId },
      select: { id: true },
    });
    if (!user) {
      return res.status(404).json({ error: 'User not found' });
    }

    const topic = await prisma.topic.findUnique({
      where: { id: topicId },
      select: { id: true },
    });
    if (!topic) {
      return res.status(404).json({ error: 'Topic not found' });
    }

    const bookmark = await prisma.bookmark.upsert({
      where: {
        userId_topicId: {
          userId,
          topicId,
        },
      },
      update: {},
      create: {
        userId,
        topicId,
      },
      select: {
        userId: true,
        topicId: true,
      },
    });

    res.json(bookmark);
  } catch (error) {
    console.error('Error adding bookmark:', error);
    res.status(500).json({ error: 'Failed to add bookmark' });
  }
});

// Remove bookmark for a user
router.delete('/users/:id/bookmarks/:topicId', async (req: Request, res: Response) => {
  try {
    const userId = (req.params.id || '').trim();
    const topicId = (req.params.topicId || '').trim();

    if (!isNonEmptyString(userId) || !isNonEmptyString(topicId)) {
      return res.status(400).json({ error: 'user id and topicId are required' });
    }

    await prisma.bookmark.deleteMany({
      where: {
        userId,
        topicId,
      },
    });

    res.status(204).send();
  } catch (error) {
    console.error('Error removing bookmark:', error);
    res.status(500).json({ error: 'Failed to remove bookmark' });
  }
});

// Submit game score from app
router.post('/scores', async (req: Request, res: Response) => {
  try {
    const { userId, gameId, score, timeTaken, completedAt } = req.body as {
      userId?: unknown;
      gameId?: unknown;
      score?: unknown;
      timeTaken?: unknown;
      completedAt?: unknown;
    };

    if (!isNonEmptyString(userId) || !isNonEmptyString(gameId)) {
      return res.status(400).json({ error: 'userId and gameId are required string fields' });
    }

    if (typeof score !== 'number' || Number.isNaN(score)) {
      return res.status(400).json({ error: 'score must be a valid number' });
    }

    if (typeof timeTaken !== 'number' || Number.isNaN(timeTaken)) {
      return res.status(400).json({ error: 'timeTaken must be a valid number' });
    }

    const game = await prisma.game.findUnique({ where: { id: gameId } });
    if (!game) {
      return res.status(404).json({ error: 'Game not found' });
    }

    const user = await prisma.user.findUnique({ where: { id: userId } });
    if (!user) {
      return res.status(404).json({
        error: 'User not found. Call /api/public/users/upsert first.'
      });
    }

    const scoreRecord = await prisma.gameScore.create({
      data: {
        userId,
        gameId,
        score: Math.max(0, Math.round(score)),
        timeTaken: Math.max(0, Math.round(timeTaken)),
        completedAt: isNonEmptyString(completedAt)
          ? new Date(completedAt)
          : new Date(),
      },
    });

    res.status(201).json(scoreRecord);
  } catch (error) {
    console.error('Error submitting score:', error);
    res.status(500).json({ error: 'Failed to submit score' });
  }
});

export default router;
