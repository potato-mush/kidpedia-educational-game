import api from '../lib/api';
import { Topic } from '../types';

export const topicService = {
  // Get all topics
  getAllTopics: async (): Promise<Topic[]> => {
    const response = await api.get('/topics');
    return response.data;
  },

  // Get topic by ID
  getTopicById: async (id: string): Promise<Topic> => {
    const response = await api.get(`/topics/${id}`);
    return response.data;
  },

  // Get topics by category
  getTopicsByCategory: async (category: string): Promise<Topic[]> => {
    const response = await api.get(`/topics/category/${category}`);
    return response.data;
  },

  // Create topic
  createTopic: async (data: Omit<Topic, 'id' | 'createdAt' | 'readCount'>): Promise<Topic> => {
    const response = await api.post('/topics', data);
    return response.data;
  },

  // Update topic
  updateTopic: async (id: string, data: Partial<Topic>): Promise<Topic> => {
    const response = await api.put(`/topics/${id}`, data);
    return response.data;
  },

  // Delete topic
  deleteTopic: async (id: string): Promise<void> => {
    await api.delete(`/topics/${id}`);
  },

  // Get topic statistics
  getTopicStatistics: async () => {
    const response = await api.get('/topics/statistics');
    return response.data;
  },

  // Get categories
  getCategories: async (): Promise<string[]> => {
    const response = await api.get('/topics/categories');
    return response.data;
  },
};
