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

  // Export user scores as CSV
  exportUserScores: async (user: UserProfile): Promise<void> => {
    const response = await api.get(`/users/${user.id}/scores/export`, {
      responseType: 'blob',
    });

    const blobUrl = window.URL.createObjectURL(new Blob([response.data], { type: 'text/csv' }));
    const link = document.createElement('a');
    const safeUsername = user.username.replace(/[^a-zA-Z0-9_-]/g, '_');
    link.href = blobUrl;
    link.setAttribute('download', `${safeUsername}_scores.csv`);
    document.body.appendChild(link);
    link.click();
    link.remove();
    window.URL.revokeObjectURL(blobUrl);
  },

  // Export all children scores as CSV
  exportAllScores: async (): Promise<void> => {
    const response = await api.get('/users/export/all-scores', {
      responseType: 'blob',
    });

    const blobUrl = window.URL.createObjectURL(new Blob([response.data], { type: 'text/csv' }));
    const link = document.createElement('a');
    link.href = blobUrl;
    link.setAttribute('download', `all_children_scores_${new Date().toISOString().split('T')[0]}.csv`);
    document.body.appendChild(link);
    link.click();
    link.remove();
    window.URL.revokeObjectURL(blobUrl);
  },
};
