import { Router, Request, Response } from 'express';
import { authenticateToken } from '../middleware/auth';
import prisma from '../lib/prisma';

const router = Router();

// Get user statistics (must come before /:id route)
router.get('/statistics', authenticateToken, async (req: Request, res: Response) => {
  try {
    const totalUsers = await prisma.user.count();
    const oneWeekAgo = new Date(Date.now() - 7 * 24 * 60 * 60 * 1000);
    const oneMonthAgo = new Date(Date.now() - 30 * 24 * 60 * 60 * 1000);
    
    const newUsersThisWeek = await prisma.user.count({
      where: { createdAt: { gte: oneWeekAgo } }
    });
    
    const newUsersThisMonth = await prisma.user.count({
      where: { createdAt: { gte: oneMonthAgo } }
    });
    
    res.json({
      totalUsers,
      activeUsers: Math.floor(totalUsers * 0.7), // Estimation
      newUsersThisWeek,
      newUsersThisMonth,
    });
  } catch (error) {
    res.status(500).json({ error: 'Failed to fetch user statistics' });
  }
});

// Get all users
router.get('/', authenticateToken, async (req: Request, res: Response) => {
  try {
    const users = await prisma.user.findMany({
      orderBy: { createdAt: 'desc' },
    });

    const scoreStats = await prisma.gameScore.groupBy({
      by: ['userId'],
      _sum: { score: true },
      _count: { id: true },
      _max: { completedAt: true },
    });

    const scoreStatsMap = new Map(
      scoreStats.map((item) => [
        item.userId,
        {
          totalScore: item._sum.score ?? 0,
          gamesPlayed: item._count.id,
          lastPlayedAt: item._max.completedAt,
        },
      ]),
    );

    const enrichedUsers = users.map((user) => {
      const stats = scoreStatsMap.get(user.id);
      return {
        ...user,
        totalScore: stats?.totalScore ?? 0,
        gamesPlayed: stats?.gamesPlayed ?? 0,
        lastPlayedAt: stats?.lastPlayedAt ?? null,
      };
    });

    res.json(enrichedUsers);
  } catch (error) {
    res.status(500).json({ error: 'Failed to fetch users' });
  }
});

// Get user by ID
router.get('/:id', authenticateToken, async (req: Request, res: Response) => {
  try {
    const user = await prisma.user.findUnique({
      where: { id: req.params.id }
    });
    if (user) {
      res.json(user);
    } else {
      res.status(404).json({ error: 'User not found' });
    }
  } catch (error) {
    res.status(500).json({ error: 'Failed to fetch user' });
  }
});

// Get user-specific stats
router.get('/:id/stats', authenticateToken, async (req: Request, res: Response) => {
  try {
    const userId = req.params.id;
    
    const gamesPlayed = await prisma.gameScore.count({
      where: { userId }
    });
    
    const topicsRead = await prisma.progress.count({
      where: { userId }
    });
    
    const scores = await prisma.gameScore.findMany({
      where: { userId },
      select: { score: true }
    });
    
    const totalScore = scores.reduce((sum, s) => sum + s.score, 0);
    const averageScore = scores.length > 0 ? Math.round(totalScore / scores.length) : 0;
    
    const badges = await prisma.userBadge.count({
      where: { userId }
    });
    
    res.json({
      gamesPlayed,
      topicsRead,
      totalScore,
      badges,
      averageScore,
    });
  } catch (error) {
    res.status(500).json({ error: 'Failed to fetch user stats' });
  }
});

// Get user scores
router.get('/:id/scores', authenticateToken, async (req: Request, res: Response) => {
  try {
    const scores = await prisma.gameScore.findMany({
      where: { userId: req.params.id },
      include: { game: true },
      orderBy: { completedAt: 'desc' }
    });
    res.json(scores);
  } catch (error) {
    res.status(500).json({ error: 'Failed to fetch user scores' });
  }
});

// Export user scores as CSV
router.get('/:id/scores/export', authenticateToken, async (req: Request, res: Response) => {
  try {
    const user = await prisma.user.findUnique({
      where: { id: req.params.id },
    });

    if (!user) {
      return res.status(404).json({ error: 'User not found' });
    }

    const scores = await prisma.gameScore.findMany({
      where: { userId: req.params.id },
      include: { game: true },
      orderBy: { completedAt: 'desc' },
    });

    const escapeCsv = (value: string | number | null | undefined) => {
      const text = value == null ? '' : String(value);
      return `"${text.replace(/"/g, '""')}"`;
    };

    const header = [
      'username',
      'avatarId',
      'gameTitle',
      'gameType',
      'difficulty',
      'score',
      'timeTakenSeconds',
      'completedAt',
    ];

    const rows = scores.map((score) => [
      user.username,
      user.avatarId,
      score.game.title,
      score.game.type,
      score.game.difficulty,
      score.score,
      score.timeTaken,
      score.completedAt.toISOString(),
    ]);

    const csv = [header, ...rows]
      .map((row) => row.map((cell) => escapeCsv(cell)).join(','))
      .join('\n');

    const safeUsername = user.username.replace(/[^a-zA-Z0-9_-]/g, '_');
    const fileName = `${safeUsername}_scores.csv`;

    res.setHeader('Content-Type', 'text/csv; charset=utf-8');
    res.setHeader('Content-Disposition', `attachment; filename="${fileName}"`);
    res.send(csv);
  } catch (error) {
    res.status(500).json({ error: 'Failed to export user scores' });
  }
});

// Export all users' scores as CSV
router.get('/export/all-scores', authenticateToken, async (req: Request, res: Response) => {
  try {
    const allScores = await prisma.gameScore.findMany({
      include: { user: true, game: true },
      orderBy: { completedAt: 'desc' },
    });

    const escapeCsv = (value: string | number | null | undefined) => {
      const text = value == null ? '' : String(value);
      return `"${text.replace(/"/g, '""')}"`;
    };

    const header = [
      'username',
      'avatarId',
      'gameTitle',
      'gameType',
      'difficulty',
      'score',
      'timeTakenSeconds',
      'completedAt',
    ];

    const rows = allScores.map((score) => [
      score.user.username,
      score.user.avatarId,
      score.game.title,
      score.game.type,
      score.game.difficulty,
      score.score,
      score.timeTaken,
      score.completedAt.toISOString(),
    ]);

    const csv = [header, ...rows]
      .map((row) => row.map((cell) => escapeCsv(cell)).join(','))
      .join('\n');

    const fileName = `all_children_scores_${new Date().toISOString().split('T')[0]}.csv`;

    res.setHeader('Content-Type', 'text/csv; charset=utf-8');
    res.setHeader('Content-Disposition', `attachment; filename="${fileName}"`);
    res.send(csv);
  } catch (error) {
    res.status(500).json({ error: 'Failed to export all scores' });
  }
});

// Get user progress
router.get('/:id/progress', authenticateToken, async (req: Request, res: Response) => {
  try {
    const progress = await prisma.progress.findMany({
      where: { userId: req.params.id },
      include: { topic: true },
      orderBy: { lastAccessedAt: 'desc' }
    });
    res.json(progress);
  } catch (error) {
    res.status(500).json({ error: 'Failed to fetch user progress' });
  }
});

// Update user
router.put('/:id', authenticateToken, async (req: Request, res: Response) => {
  try {
    const user = await prisma.user.update({
      where: { id: req.params.id },
      data: req.body
    });
    res.json(user);
  } catch (error) {
    res.status(404).json({ error: 'User not found' });
  }
});

// Delete user
router.delete('/:id', authenticateToken, async (req: Request, res: Response) => {
  try {
    await prisma.user.delete({
      where: { id: req.params.id }
    });
    res.status(204).send();
  } catch (error) {
    res.status(404).json({ error: 'User not found' });
  }
});

export default router;
