import { useState, useCallback } from 'react';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { useDropzone } from 'react-dropzone';
import { Upload, Trash2, Image as ImageIcon, Video, Music, FileIcon } from 'lucide-react';
import { mediaService } from '../services/mediaService';
import { MediaType } from '../types';

const Media = () => {
  const [selectedType, setSelectedType] = useState<MediaType | 'all'>('all');
  const [selectedCategory, setSelectedCategory] = useState('all');
  const queryClient = useQueryClient();

  const { data: mediaFiles, isLoading } = useQuery({
    queryKey: ['media'],
    queryFn: () => mediaService.getAllMedia(),
  });

  const uploadMutation = useMutation({
    mutationFn: ({ files, type, category }: { files: File[]; type: MediaType; category?: string }) =>
      mediaService.uploadMultipleMedia(files, type, category),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['media'] });
    },
  });

  const deleteMutation = useMutation({
    mutationFn: (id: string) => mediaService.deleteMedia(id),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['media'] });
    },
  });

  const onDrop = useCallback((acceptedFiles: File[]) => {
    if (acceptedFiles.length === 0) return;

    const fileType = acceptedFiles[0].type;
    let mediaType: MediaType;

    if (fileType.startsWith('image/')) {
      mediaType = 'image';
    } else if (fileType.startsWith('video/')) {
      mediaType = 'video';
    } else if (fileType.startsWith('audio/')) {
      mediaType = 'audio';
    } else {
      alert('Unsupported file type');
      return;
    }

    uploadMutation.mutate({ files: acceptedFiles, type: mediaType });
  }, [uploadMutation]);

  const { getRootProps, getInputProps, isDragActive } = useDropzone({
    onDrop,
    accept: {
      'image/*': ['.png', '.jpg', '.jpeg', '.gif', '.webp'],
      'video/*': ['.mp4', '.webm', '.mov'],
      'audio/*': ['.mp3', '.wav', '.ogg'],
    },
  });

  const filteredMedia = mediaFiles?.filter((file) => {
    const matchesType = selectedType === 'all' || file.type === selectedType;
    const matchesCategory = selectedCategory === 'all' || file.category === selectedCategory;
    return matchesType && matchesCategory;
  });

  const handleDeleteMedia = async (id: string) => {
    if (window.confirm('Are you sure you want to delete this file?')) {
      await deleteMutation.mutateAsync(id);
    }
  };

  const getIcon = (type: MediaType) => {
    switch (type) {
      case 'image':
        return ImageIcon;
      case 'video':
        return Video;
      case 'audio':
        return Music;
      default:
        return FileIcon;
    }
  };

  const formatFileSize = (bytes: number) => {
    if (bytes === 0) return '0 Bytes';
    const k = 1024;
    const sizes = ['Bytes', 'KB', 'MB', 'GB'];
    const i = Math.floor(Math.log(bytes) / Math.log(k));
    return Math.round(bytes / Math.pow(k, i) * 100) / 100 + ' ' + sizes[i];
  };

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <h1 className="text-3xl font-bold text-gray-900">Media Library</h1>
      </div>

      {/* Upload Area */}
      <div
        {...getRootProps()}
        className={`cursor-pointer rounded-lg border-2 border-dashed p-12 text-center transition-colors ${
          isDragActive
            ? 'border-primary-500 bg-primary-50'
            : 'border-gray-300 bg-white hover:border-primary-400'
        }`}
      >
        <input {...getInputProps()} />
        <Upload className="mx-auto h-12 w-12 text-gray-400" />
        <p className="mt-2 text-sm font-medium text-gray-900">
          {isDragActive ? 'Drop files here' : 'Drag & drop files here, or click to select'}
        </p>
        <p className="mt-1 text-xs text-gray-500">
          Supports: Images (PNG, JPG, GIF), Videos (MP4, WebM), Audio (MP3, WAV)
        </p>
      </div>

      {/* Filters */}
      <div className="flex gap-4">
        <select
          value={selectedType}
          onChange={(e) => setSelectedType(e.target.value as any)}
          className="rounded-lg border border-gray-300 px-4 py-2 focus:border-primary-500 focus:outline-none focus:ring-1 focus:ring-primary-500"
        >
          <option value="all">All Types</option>
          <option value="image">Images</option>
          <option value="video">Videos</option>
          <option value="audio">Audio</option>
        </select>
        <select
          value={selectedCategory}
          onChange={(e) => setSelectedCategory(e.target.value)}
          className="rounded-lg border border-gray-300 px-4 py-2 focus:border-primary-500 focus:outline-none focus:ring-1 focus:ring-primary-500"
        >
          <option value="all">All Categories</option>
          <option value="animals">Animals</option>
          <option value="space">Space</option>
          <option value="science">Science</option>
          <option value="history">History</option>
          <option value="geography">Geography</option>
        </select>
      </div>

      {/* Media Grid */}
      <div className="grid grid-cols-2 gap-6 sm:grid-cols-3 md:grid-cols-4 lg:grid-cols-5">
        {isLoading ? (
          <div className="col-span-full text-center text-gray-500">Loading...</div>
        ) : filteredMedia?.length === 0 ? (
          <div className="col-span-full text-center text-gray-500">No media files found</div>
        ) : (
          filteredMedia?.map((file) => {
            const Icon = getIcon(file.type);
            return (
              <div
                key={file.id}
                className="group relative overflow-hidden rounded-lg bg-white shadow transition-shadow hover:shadow-lg"
              >
                <div className="aspect-square bg-gray-100">
                  {file.type === 'image' ? (
                    <img
                      src={file.path}
                      alt={file.name}
                      className="h-full w-full object-cover"
                    />
                  ) : (
                    <div className="flex h-full items-center justify-center">
                      <Icon className="h-16 w-16 text-gray-400" />
                    </div>
                  )}
                </div>
                <div className="p-3">
                  <p className="truncate text-sm font-medium text-gray-900" title={file.name}>
                    {file.name}
                  </p>
                  <div className="mt-1 flex items-center justify-between text-xs text-gray-500">
                    <span>{formatFileSize(file.size)}</span>
                    <span>{file.type}</span>
                  </div>
                  {file.category && (
                    <span className="mt-2 inline-block rounded bg-primary-100 px-2 py-0.5 text-xs text-primary-700">
                      {file.category}
                    </span>
                  )}
                </div>
                <button
                  onClick={() => handleDeleteMedia(file.id)}
                  className="absolute right-2 top-2 rounded-lg bg-red-500 p-2 text-white opacity-0 transition-opacity group-hover:opacity-100"
                >
                  <Trash2 className="h-4 w-4" />
                </button>
              </div>
            );
          })
        )}
      </div>
    </div>
  );
};

export default Media;
