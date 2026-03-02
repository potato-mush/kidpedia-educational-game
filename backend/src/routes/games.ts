import { Router, Request, Response } from 'express';
import { authenticateToken } from '../middleware/auth';
import prisma from '../lib/prisma';

const router = Router();

// Helper function to convert database format to API format
const formatGame = (game: any) => ({
  ...game,
  configurationData: JSON.parse(game.configurationData),
});

// Helper function to format topic
const formatTopic = (topic: any) => ({
  ...topic,
  imagePaths: JSON.parse(topic.imagePaths),
  funFacts: JSON.parse(topic.funFacts),
  relatedTopicIds: JSON.parse(topic.relatedTopicIds),
});

// Get game statistics (must come before /:id route)
router.get('/statistics', authenticateToken, async (req: Request, res: Response) => {
  try {
    const totalGames = await prisma.game.count();
    
    const puzzleCount = await prisma.game.count({ where: { type: 'puzzle' } });
    const quizCount = await prisma.game.count({ where: { type: 'quiz' } });
    const soundMatchCount = await prisma.game.count({ where: { type: 'sound_match' } });
    
    // Get top games by play count (from scores)
    const gamesWithCounts = await prisma.gameScore.groupBy({
      by: ['gameId'],
      _count: { gameId: true },
      orderBy: { _count: { gameId: 'desc' } },
      take: 5
    });
    
    const topGamesPromises = gamesWithCounts.map(async (g) => {
      const game = await prisma.game.findUnique({ where: { id: g.gameId } });
      return {
        id: g.gameId,
        title: game?.title || 'Unknown',
        playCount: g._count.gameId
      };
    });
    
    const topGames = await Promise.all(topGamesPromises);
    
    res.json({
      totalGames,
      gamesByType: {
        puzzle: puzzleCount,
        quiz: quizCount,
        sound_match: soundMatchCount,
      },
      topGames,
    });
  } catch (error) {
    res.status(500).json({ error: 'Failed to fetch game statistics' });
  }
});

// Get all games
router.get('/', authenticateToken, async (req: Request, res: Response) => {
  try {
    const games = await prisma.game.findMany({
      orderBy: { createdAt: 'desc' }
    });
    console.log('=== FETCHING ALL GAMES ===');
    console.log(`Total games in database: ${games.length}`);
    games.forEach((game, index) => {
      console.log(`  ${index + 1}. ${game.title} (${game.type}) - ${game.id}`);
    });
    console.log('=========================');
    res.json(games.map(formatGame));
  } catch (error) {
    console.error('Failed to fetch games:', error);
    res.status(500).json({ error: 'Failed to fetch games' });
  }
});

// Get game by ID
router.get('/:id', authenticateToken, async (req: Request, res: Response) => {
  try {
    const game = await prisma.game.findUnique({
      where: { id: req.params.id },
      include: { topic: true }
    });
    if (game) {
      const formattedGame = formatGame(game);
      if (game.topic) {
        formattedGame.topic = formatTopic(game.topic);
      }
      res.json(formattedGame);
    } else {
      res.status(404).json({ error: 'Game not found' });
    }
  } catch (error) {
    res.status(500).json({ error: 'Failed to fetch game' });
  }
});

// Get games by topic
router.get('/topic/:topicId', authenticateToken, async (req: Request, res: Response) => {
  try {
    const games = await prisma.game.findMany({
      where: { topicId: req.params.topicId }
    });
    res.json(games.map(formatGame));
  } catch (error) {
    res.status(500).json({ error: 'Failed to fetch games by topic' });
  }
});

// Get games by type
router.get('/type/:type', authenticateToken, async (req: Request, res: Response) => {
  try {
    const games = await prisma.game.findMany({
      where: { type: req.params.type }
    });
    res.json(games.map(formatGame));
  } catch (error) {
    res.status(500).json({ error: 'Failed to fetch games by type' });
  }
});

// Create game
router.post('/', authenticateToken, async (req: Request, res: Response) => {
  try {
    console.log('=== CREATE GAME REQUEST ===');
    console.log('Request body:', JSON.stringify(req.body, null, 2));
    
    // Convert configurationData object to JSON string
    const gameData = {
      ...req.body,
      configurationData: JSON.stringify(req.body.configurationData || {})
    };
    
    console.log('Game data to save:', JSON.stringify(gameData, null, 2));
    
    const newGame = await prisma.game.create({
      data: gameData
    });
    
    console.log('✅ Game created successfully!');
    console.log('  ID:', newGame.id);
    console.log('  Title:', newGame.title);
    console.log('  Type:', newGame.type);
    console.log('==========================');
    
    res.status(201).json(formatGame(newGame));
  } catch (error) {
    console.error('❌ Failed to create game:', error);
    res.status(500).json({ 
      error: 'Failed to create game',
      details: error instanceof Error ? error.message : 'Unknown error'
    });
  }
});

// Update game
router.put('/:id', authenticateToken, async (req: Request, res: Response) => {
  try {
    console.log('=== UPDATE GAME REQUEST ===');
    console.log('Game ID:', req.params.id);
    console.log('Request Body:', JSON.stringify(req.body, null, 2));
    console.log('Configuration Data (before stringify):', req.body.configurationData);
    console.log('==========================');
    
    // Convert configurationData object to JSON string if present
    const updateData: any = { ...req.body };
    if (req.body.configurationData !== undefined) {
      updateData.configurationData = JSON.stringify(req.body.configurationData);
      console.log('Configuration Data (after stringify):', updateData.configurationData);
    }
    
    const game = await prisma.game.update({
      where: { id: req.params.id },
      data: updateData
    });
    
    console.log('Updated game:', game);
    console.log('Formatted game:', formatGame(game));
    
    res.json(formatGame(game));
  } catch (error) {
    console.error('Failed to update game:', error);
    res.status(404).json({ error: 'Game not found' });
  }
});

// Delete game
router.delete('/:id', authenticateToken, async (req: Request, res: Response) => {
  try {
    await prisma.game.delete({
      where: { id: req.params.id }
    });
    res.status(204).send();
  } catch (error) {
    res.status(404).json({ error: 'Game not found' });
  }
});

export default router;
