import api from '../lib/api';
import { Game } from '../types';

export const gameService = {
  // Get all games
  getAllGames: async (): Promise<Game[]> => {
    const response = await api.get('/games');
    return response.data;
  },

  // Get game by ID
  getGameById: async (id: string): Promise<Game> => {
    const response = await api.get(`/games/${id}`);
    return response.data;
  },

  // Get games by topic
  getGamesByTopic: async (topicId: string): Promise<Game[]> => {
    const response = await api.get(`/games/topic/${topicId}`);
    return response.data;
  },

  // Get games by type
  getGamesByType: async (type: string): Promise<Game[]> => {
    const response = await api.get(`/games/type/${type}`);
    return response.data;
  },

  // Create game
  createGame: async (data: Omit<Game, 'id' | 'createdAt'>): Promise<Game> => {
    const response = await api.post('/games', data);
    return response.data;
  },

  // Update game
  updateGame: async (id: string, data: Partial<Game>): Promise<Game> => {
    const response = await api.put(`/games/${id}`, data);
    return response.data;
  },

  // Delete game
  deleteGame: async (id: string): Promise<void> => {
    await api.delete(`/games/${id}`);
  },

  // Get game statistics
  getGameStatistics: async () => {
    const response = await api.get('/games/statistics');
    return response.data;
  },
};
