// Quick script to check games in database
import prisma from './lib/prisma';

async function checkGames() {
  try {
    const games = await prisma.game.findMany({
      orderBy: { createdAt: 'desc' }
    });

    console.log('\n=== GAMES IN DATABASE ===');
    console.log(`Total: ${games.length} games\n`);

    games.forEach((game, index) => {
      console.log(`${index + 1}. ${game.title}`);
      console.log(`   ID: ${game.id}`);
      console.log(`   Type: ${game.type}`);
      console.log(`   Difficulty: ${game.difficulty}`);
      console.log(`   Topic ID: ${game.topicId}`);
      console.log(`   Created: ${game.createdAt}`);
      console.log(`   Config: ${game.configurationData.substring(0, 100)}...`);
      console.log('');
    });

    console.log('========================\n');
  } catch (error) {
    console.error('Error:', error);
  } finally {
    await prisma.$disconnect();
  }
}

checkGames();
