import prisma from './prisma';
import bcrypt from 'bcryptjs';

export async function seedDatabase() {
  try {
    // Check if data already exists
    const userCount = await prisma.user.count();
    if (userCount > 0) {
      console.log('📊 Database already seeded');
      return;
    }

    console.log('🌱 Seeding database...');

    // Create admin user
    const hashedPassword = await bcrypt.hash('admin', 10);
    await prisma.admin.create({
      data: {
        username: 'admin',
        email: 'admin@kidpedia.com',
        password: hashedPassword,
      },
    });

    // Create sample users
    const users = await Promise.all([
      prisma.user.create({
        data: {
          username: 'john_doe',
          avatarId: 'avatar_1',
        },
      }),
      prisma.user.create({
        data: {
          username: 'jane_smith',
          avatarId: 'avatar_2',
        },
      }),
    ]);

    // Create sample topics
    const topic1 = await prisma.topic.create({
      data: {
        title: 'The Solar System',
        category: 'space',
        summary: 'Learn about our amazing solar system and the planets orbiting our Sun',
        content: 'The solar system consists of the Sun and everything that orbits it, including eight planets, dwarf planets, moons, asteroids, comets, and other celestial objects. The Sun, a yellow dwarf star, makes up 99.86% of the solar system\'s mass.',
        imagePaths: JSON.stringify(['assets/images/space/solar_system.jpg', 'assets/images/space/planets.jpg']),
        videoPath: 'assets/videos/space/solar_system.mp4',
        audioPath: 'assets/audio/narrations/solar_system.mp3',
        funFacts: JSON.stringify([
          'The Sun makes up 99.86% of the solar system\'s mass',
          'Jupiter is so big that all the other planets could fit inside it',
          'A day on Venus is longer than its year',
        ]),
        relatedTopicIds: JSON.stringify([]),
        thumbnailPath: 'assets/images/space/solar_system_thumb.jpg',
        readCount: 234,
      },
    });

    const topic2 = await prisma.topic.create({
      data: {
        title: 'African Wildlife',
        category: 'animals',
        summary: 'Discover the incredible animals that roam the African savanna',
        content: 'Africa is home to some of the world\'s most iconic wildlife, including elephants, lions, giraffes, zebras, and rhinoceros. The African savanna ecosystem is one of the most diverse on Earth.',
        imagePaths: JSON.stringify(['assets/images/animals/lion.jpg', 'assets/images/animals/elephant.jpg']),
        videoPath: 'assets/videos/animals/savanna.mp4',
        audioPath: 'assets/audio/narrations/african_wildlife.mp3',
        funFacts: JSON.stringify([
          'African elephants are the largest land animals on Earth',
          'Lions can sleep up to 20 hours a day',
          'A giraffe\'s tongue can be 20 inches long',
        ]),
        relatedTopicIds: JSON.stringify([]),
        thumbnailPath: 'assets/images/animals/savanna_thumb.jpg',
        readCount: 189,
      },
    });

    // Create sample games
    const game1 = await prisma.game.create({
      data: {
        title: 'Solar System Quiz',
        type: 'quiz',
        topicId: topic1.id,
        difficulty: 'easy',
        description: 'Test your knowledge about the solar system',
        configurationData: JSON.stringify({
          questions: [
            {
              question: 'What is the largest planet in our solar system?',
              options: ['Earth', 'Jupiter', 'Saturn', 'Mars'],
              correctAnswer: 1,
            },
            {
              question: 'How many planets are in our solar system?',
              options: ['7', '8', '9', '10'],
              correctAnswer: 1,
            },
          ],
          timeLimit: 60,
          pointsPerQuestion: 10,
        }),
      },
    });

    const game2 = await prisma.game.create({
      data: {
        title: 'African Animals Puzzle',
        type: 'puzzle',
        topicId: topic2.id,
        difficulty: 'medium',
        description: 'Complete the puzzle of African wildlife',
        configurationData: JSON.stringify({
          imagePath: 'assets/images/animals/lion.jpg',
          pieces: 9,
          timeLimit: 120,
        }),
      },
    });

    // Create sample badges
    await Promise.all([
      prisma.badge.create({
        data: {
          name: 'Explorer',
          description: 'Read 5 topics',
          iconPath: 'assets/images/badges/explorer.png',
          requirement: 'read_5_topics',
        },
      }),
      prisma.badge.create({
        data: {
          name: 'Quiz Master',
          description: 'Complete 10 quizzes',
          iconPath: 'assets/images/badges/quiz_master.png',
          requirement: 'complete_10_quizzes',
        },
      }),
    ]);

    // Create sample progress
    await prisma.progress.create({
      data: {
        userId: users[0].id,
        topicId: topic1.id,
        gamesCompleted: JSON.stringify([game1.id]),
        totalScore: 95,
      },
    });

    // Create sample scores
    await prisma.gameScore.create({
      data: {
        userId: users[0].id,
        gameId: game1.id,
        score: 95,
       timeTaken: 45,
      },
    });

    console.log('✅ Database seeded successfully!');
    console.log(`   - Created ${users.length} users`);
    console.log(`   - Created 2 topics`);
    console.log(`   - Created 2 games`);
    console.log(`   - Created 2 badges`);
  } catch (error) {
    console.error('❌ Error seeding database:', error);
    throw error;
  } finally {
    await prisma.$disconnect();
  }
}

// Run seed if this file is executed directly
if (require.main === module) {
  seedDatabase()
    .catch((error) => {
      console.error(error);
      process.exit(1);
    });
}
