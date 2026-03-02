// Script to delete empty sound match games
import prisma from './lib/prisma';

async function deleteEmptyGames() {
  try {
    console.log('\n=== CHECKING FOR EMPTY SOUND MATCH GAMES ===');
    
    const soundMatchGames = await prisma.game.findMany({
      where: { type: 'sound_match' },
      orderBy: { createdAt: 'desc' }
    });

    console.log(`Found ${soundMatchGames.length} sound match games\n`);

    const gamesToDelete: string[] = [];

    for (const game of soundMatchGames) {
      const config = JSON.parse(game.configurationData);
      const pairs = config.pairs || config.sounds || [];
      
      console.log(`📋 ${game.title} (${game.id})`);
      console.log(`   Pairs: ${pairs.length}`);
      
      if (pairs.length === 0) {
        console.log(`   ❌ EMPTY - Marking for deletion`);
        gamesToDelete.push(game.id);
      } else {
        console.log(`   ✅ Has data`);
      }
      console.log('');
    }

    if (gamesToDelete.length > 0) {
      console.log(`\n🗑️  Deleting ${gamesToDelete.length} empty games...`);
      
      for (const gameId of gamesToDelete) {
        await prisma.game.delete({
          where: { id: gameId }
        });
        console.log(`   ✅ Deleted game: ${gameId}`);
      }
      
      console.log(`\n✅ Successfully deleted ${gamesToDelete.length} empty games!`);
    } else {
      console.log('✅ No empty games found!');
    }

  } catch (error) {
    console.error('❌ Error:', error);
  } finally {
    await prisma.$disconnect();
  }
}

deleteEmptyGames();
