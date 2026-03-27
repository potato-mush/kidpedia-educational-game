export interface UserProfile {
  id: string;
  username: string;
  avatarId: string;
  createdAt: string;
  lastUpdated: string;
  totalScore?: number;
  gamesPlayed?: number;
  lastPlayedAt?: string | null;
}

export interface Topic {
  id: string;
  title: string;
  category: string;
  summary: string;
  content: string;
  imagePaths: string[];
  videoPath?: string;
  audioPath?: string;
  funFacts: string[];
  relatedTopicIds: string[];
  thumbnailPath: string;
  createdAt: string;
  readCount: number;
}

export interface Game {
  id: string;
  type: 'puzzle' | 'sound_match' | 'quiz';
  topicId: string;
  difficulty: 'easy' | 'medium' | 'hard';
  configurationData: Record<string, any>;
  title: string;
  description: string;
  createdAt: string;
}

export interface Badge {
  id: string;
  name: string;
  description: string;
  iconPath: string;
  requirement: string;
}

export interface LeaderboardEntry {
  id: string;
  userId: string;
  username: string;
  score: number;
  rank: number;
  avatarId: string;
}

export interface GameScore {
  id: string;
  userId: string;
  gameId: string;
  score: number;
  completedAt: string;
  timeTaken: number;
  game?: {
    id: string;
    title: string;
    type: string;
    difficulty: string;
  };
}

export interface Progress {
  id: string;
  userId: string;
  topicId: string;
  gamesCompleted: string[];
  totalScore: number;
  lastAccessedAt: string;
}

export type MediaType = 'image' | 'video' | 'audio';

export interface MediaFile {
  id: string;
  name: string;
  path: string;
  type: MediaType;
  category?: string;
  uploadedAt: string;
  size: number;
}
