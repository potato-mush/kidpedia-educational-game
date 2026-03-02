import api from '../lib/api';
import { MediaFile, MediaType } from '../types';

export const mediaService = {
  // Get all media files
  getAllMedia: async (): Promise<MediaFile[]> => {
    const response = await api.get('/media');
    return response.data;
  },

  // Get media by type
  getMediaByType: async (type: MediaType): Promise<MediaFile[]> => {
    const response = await api.get(`/media/type/${type}`);
    return response.data;
  },

  // Get media by category
  getMediaByCategory: async (category: string): Promise<MediaFile[]> => {
    const response = await api.get(`/media/category/${category}`);
    return response.data;
  },

  // Upload media file with FormData
  uploadFile: async (formData: FormData): Promise<MediaFile> => {
    const response = await api.post('/media/upload', formData, {
      headers: {
        'Content-Type': 'multipart/form-data',
      },
    });
    return response.data;
  },

  // Upload media file
  uploadMedia: async (
    file: File,
    type: MediaType,
    category?: string
  ): Promise<MediaFile> => {
    const formData = new FormData();
    formData.append('file', file);
    formData.append('type', type);
    if (category) {
      formData.append('category', category);
    }

    const response = await api.post('/media/upload', formData, {
      headers: {
        'Content-Type': 'multipart/form-data',
      },
    });
    return response.data;
  },

  // Upload multiple media files
  uploadMultipleMedia: async (
    files: File[],
    type: MediaType,
    category?: string
  ): Promise<MediaFile[]> => {
    const formData = new FormData();
    files.forEach((file) => formData.append('files', file));
    formData.append('type', type);
    if (category) {
      formData.append('category', category);
    }

    const response = await api.post('/media/upload-multiple', formData, {
      headers: {
        'Content-Type': 'multipart/form-data',
      },
    });
    return response.data;
  },

  // Delete media file
  deleteMedia: async (id: string): Promise<void> => {
    await api.delete(`/media/${id}`);
  },

  // Get media statistics
  getMediaStatistics: async () => {
    const response = await api.get('/media/statistics');
    return response.data;
  },
};
