// Script to remove invalid sound match games
import prisma from './lib/prisma';

async function removeInvalidSoundMatchGames() {
  try {
    console.log('\n=== CHECKING SOUND MATCH GAMES ===');
    
    const soundMatchGames = await prisma.game.findMany({
      where: { type: 'sound_match' },
      orderBy: { createdAt: 'desc' }
    });

    console.log(`Found ${soundMatchGames.length} sound match games\n`);

    const invalidGames: string[] = [];

    for (const game of soundMatchGames) {
      console.log(`\nChecking: ${game.title} (${game.id})`);
      
      try {
        const config = JSON.parse(game.configurationData);
        const pairs = config.pairs || [];
        
        console.log(`  - Has ${pairs.length} pairs`);
        
        // Check if pairs is empty or has invalid data
        if (pairs.length === 0) {
          console.log('  ❌ INVALID: No pairs found');
          invalidGames.push(game.id);
        } else {
          // Check if pairs have required fields
          const hasValidPairs = pairs.every((pair: any) => 
            pair.id && pair.name && pair.imagePath && pair.audioPath
          );
          
          if (!hasValidPairs) {
            console.log('  ❌ INVALID: Some pairs missing required fields');
            invalidGames.push(game.id);
          } else {
            console.log('  ✅ VALID');
          }
        }
      } catch (error) {
        console.log('  ❌ INVALID: Could not parse configuration data');
        invalidGames.push(game.id);
      }
    }

    console.log('\n=== SUMMARY ===');
    console.log(`Total sound match games: ${soundMatchGames.length}`);
    console.log(`Invalid games found: ${invalidGames.length}`);
    
    if (invalidGames.length > 0) {
      console.log('\nInvalid game IDs:');
      invalidGames.forEach(id => console.log(`  - ${id}`));
      
      console.log('\n⚠️  Deleting invalid games...');
      
      for (const gameId of invalidGames) {
        const game = soundMatchGames.find(g => g.id === gameId);
        console.log(`Deleting: ${game?.title} (${gameId})`);
        
        // Delete associated scores first
        await prisma.gameScore.deleteMany({
          where: { gameId }
        });
        
        // Delete the game
        await prisma.game.delete({
          where: { id: gameId }
        });
      }
      
      console.log(`\n✅ Successfully deleted ${invalidGames.length} invalid sound match games!`);
    } else {
      console.log('\n✅ No invalid games found!');
    }
    
  } catch (error) {
    console.error('❌ Error:', error);
  } finally {
    await prisma.$disconnect();
  }
}

removeInvalidSoundMatchGames();
