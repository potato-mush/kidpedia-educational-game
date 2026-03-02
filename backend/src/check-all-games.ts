// Script to check ALL games
import prisma from './lib/prisma';

async function checkAllGames() {
  try {
    console.log('\n=== CHECKING ALL GAMES ===');
    
    const allGames = await prisma.game.findMany({
      orderBy: { createdAt: 'desc' }
    });

    console.log(`\nTotal games: ${allGames.length}\n`);

    for (const game of allGames) {
      console.log(`📋 ${game.title}`);
      console.log(`   ID: ${game.id}`);
      console.log(`   Type: ${game.type}`);
      console.log(`   Topic ID: ${game.topicId}`);
      console.log(`   Config: ${game.configurationData.substring(0, 200)}...`);
      
      if (game.type === 'sound_match') {
        const config = JSON.parse(game.configurationData);
        const pairs = config.pairs || config.sounds || [];
        console.log(`   Sound Match Pairs: ${pairs.length}`);
        if (pairs.length === 0) {
          console.log(`   ❌ EMPTY GAME - SHOULD DELETE`);
        }
      }
      console.log('');
    }

  } catch (error) {
    console.error('❌ Error:', error);
  } finally {
    await prisma.$disconnect();
  }
}

checkAllGames();
