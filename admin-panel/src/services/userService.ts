import api from '../lib/api';
import { UserProfile, GameScore, Progress } from '../types';

export const userService = {
  // Get all users
  getAllUsers: async (): Promise<UserProfile[]> => {
    const response = await api.get('/users');
    return response.data;
  },

  // Get user by ID
  getUserById: async (id: string): Promise<UserProfile> => {
    const response = await api.get(`/users/${id}`);
    return response.data;
  },

  // Get user stats
  getUserStats: async (userId: string) => {
    const response = await api.get(`/users/${userId}/stats`);
    return response.data;
  },

  // Get user game scores
  getUserScores: async (userId: string): Promise<GameScore[]> => {
    const response = await api.get(`/users/${userId}/scores`);
    return response.data;
  },

  // Get user progress
  getUserProgress: async (userId: string): Promise<Progress[]> => {
    const response = await api.get(`/users/${userId}/progress`);
    return response.data;
  },

  // Update user
  updateUser: async (id: string, data: Partial<UserProfile>): Promise<UserProfile> => {
    const response = await api.put(`/users/${id}`, data);
    return response.data;
  },

  // Delete user
  deleteUser: async (id: string): Promise<void> => {
    await api.delete(`/users/${id}`);
  },

  // Get users statistics
  getUsersStatistics: async () => {
    const response = await api.get('/users/statistics');
    return response.data;
  },
};
