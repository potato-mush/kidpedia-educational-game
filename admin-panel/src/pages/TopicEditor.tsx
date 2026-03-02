import { useState, useEffect, useCallback } from 'react';
import { useNavigate, useParams } from 'react-router-dom';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { useForm } from 'react-hook-form';
import { useDropzone } from 'react-dropzone';
import { ArrowLeft, Save, Upload, X, Image as ImageIcon, Film, Music, Plus } from 'lucide-react';
import { topicService } from '../services/topicService';
import { mediaService } from '../services/mediaService';
import { Topic } from '../types';

type TopicFormData = Omit<Topic, 'id' | 'createdAt' | 'readCount'>;

const TopicEditor = () => {
  const { id } = useParams();
  const navigate = useNavigate();
  const queryClient = useQueryClient();
  const isEditMode = !!id;

  const [gallery, setGallery] = useState<File[]>([]);
  const [videoFile, setVideoFile] = useState<File | null>(null);
  const [audioFile, setAudioFile] = useState<File | null>(null);
  const [thumbnailFile, setThumbnailFile] = useState<File | null>(null);
  const [funFactsList, setFunFactsList] = useState<string[]>(['']);
  const [uploadingMedia, setUploadingMedia] = useState(false);
  const [isNewCategory, setIsNewCategory] = useState(false);
  const [customCategory, setCustomCategory] = useState('');

  // Existing media paths from database (for edit mode)
  const [existingThumbnail, setExistingThumbnail] = useState<string>('');
  const [existingGallery, setExistingGallery] = useState<string[]>([]);
  const [existingVideo, setExistingVideo] = useState<string>('');
  const [existingAudio, setExistingAudio] = useState<string>('');

  const { register, handleSubmit, setValue, formState: { errors } } = useForm<TopicFormData>();

  const { data: topic } = useQuery({
    queryKey: ['topic', id],
    queryFn: () => topicService.getTopicById(id!),
    enabled: isEditMode,
  });

  const { data: categories } = useQuery({
    queryKey: ['categories'],
    queryFn: () => topicService.getCategories(),
  });

  useEffect(() => {
    if (topic) {
      Object.keys(topic).forEach((key) => {
        if (key === 'funFacts' && Array.isArray(topic.funFacts)) {
          setFunFactsList(topic.funFacts.length > 0 ? topic.funFacts : ['']);
        } else {
          setValue(key as any, (topic as any)[key]);
        }
      });

      // Load existing media paths
      if (topic.thumbnailPath) {
        setExistingThumbnail(topic.thumbnailPath);
      }
      if (topic.imagePaths && Array.isArray(topic.imagePaths)) {
        setExistingGallery(topic.imagePaths);
      }
      if (topic.videoPath) {
        setExistingVideo(topic.videoPath);
      }
      if (topic.audioPath) {
        setExistingAudio(topic.audioPath);
      }
    }
  }, [topic, setValue]);

  // Gallery dropzone
  const onGalleryDrop = useCallback((acceptedFiles: File[]) => {
    setGallery((prev) => [...prev, ...acceptedFiles]);
  }, []);

  const { getRootProps: getGalleryRootProps, getInputProps: getGalleryInputProps, isDragActive: isGalleryDragActive } = useDropzone({
    onDrop: onGalleryDrop,
    accept: { 'image/*': ['.png', '.jpg', '.jpeg', '.gif', '.webp'] },
    multiple: true,
  });

  // Video dropzone
  const onVideoDrop = useCallback((acceptedFiles: File[]) => {
    if (acceptedFiles.length > 0) {
      setVideoFile(acceptedFiles[0]);
    }
  }, []);

  const { getRootProps: getVideoRootProps, getInputProps: getVideoInputProps, isDragActive: isVideoDragActive } = useDropzone({
    onDrop: onVideoDrop,
    accept: { 'video/*': ['.mp4', '.webm', '.mov'] },
    multiple: false,
  });

  // Audio dropzone
  const onAudioDrop = useCallback((acceptedFiles: File[]) => {
    if (acceptedFiles.length > 0) {
      setAudioFile(acceptedFiles[0]);
    }
  }, []);

  const { getRootProps: getAudioRootProps, getInputProps: getAudioInputProps, isDragActive: isAudioDragActive } = useDropzone({
    onDrop: onAudioDrop,
    accept: { 'audio/*': ['.mp3', '.wav', '.ogg'] },
    multiple: false,
  });

  // Thumbnail dropzone
  const onThumbnailDrop = useCallback((acceptedFiles: File[]) => {
    if (acceptedFiles.length > 0) {
      setThumbnailFile(acceptedFiles[0]);
    }
  }, []);

  const { getRootProps: getThumbnailRootProps, getInputProps: getThumbnailInputProps, isDragActive: isThumbnailDragActive } = useDropzone({
    onDrop: onThumbnailDrop,
    accept: { 'image/*': ['.png', '.jpg', '.jpeg', '.gif', '.webp'] },
    multiple: false,
  });

  const removeGalleryImage = (index: number) => {
    setGallery((prev) => prev.filter((_, i) => i !== index));
  };

  const removeExistingGalleryImage = (index: number) => {
    setExistingGallery((prev) => prev.filter((_, i) => i !== index));
  };

  const addFunFact = () => {
    setFunFactsList((prev) => [...prev, '']);
  };

  const updateFunFact = (index: number, value: string) => {
    setFunFactsList((prev) => {
      const updated = [...prev];
      updated[index] = value;
      return updated;
    });
  };

  const removeFunFact = (index: number) => {
    setFunFactsList((prev) => prev.filter((_, i) => i !== index));
  };

  const uploadMediaFiles = async () => {
    const uploadedPaths: any = {
      imagePaths: [...existingGallery], // Start with existing gallery images
      videoPath: existingVideo, // Start with existing video
      audioPath: existingAudio, // Start with existing audio
      thumbnailPath: existingThumbnail, // Start with existing thumbnail
    };

    try {
      setUploadingMedia(true);

      // Upload thumbnail (only if new file is provided)
      if (thumbnailFile) {
        const formData = new FormData();
        formData.append('file', thumbnailFile);
        formData.append('type', 'image');
        formData.append('category', 'thumbnails');
        
        const response = await mediaService.uploadFile(formData);
        uploadedPaths.thumbnailPath = response.path;
      }

      // Upload gallery images (append to existing)
      for (const file of gallery) {
        const formData = new FormData();
        formData.append('file', file);
        formData.append('type', 'image');
        formData.append('category', 'topics');
        
        const response = await mediaService.uploadFile(formData);
        uploadedPaths.imagePaths.push(response.path);
      }

      // Upload video (only if new file is provided)
      if (videoFile) {
        const formData = new FormData();
        formData.append('file', videoFile);
        formData.append('type', 'video');
        formData.append('category', 'topics');
        
        const response = await mediaService.uploadFile(formData);
        uploadedPaths.videoPath = response.path;
      }

      // Upload audio (only if new file is provided)
      if (audioFile) {
        const formData = new FormData();
        formData.append('file', audioFile);
        formData.append('type', 'audio');
        formData.append('category', 'narrations');
        
        console.log('Uploading audio file:', { name: audioFile.name, size: audioFile.size, type: audioFile.type });
        const response = await mediaService.uploadFile(formData);
        uploadedPaths.audioPath = response.path;
      }

      setUploadingMedia(false);
      return uploadedPaths;
    } catch (error: any) {
      setUploadingMedia(false);
      console.error('Upload error:', error);
      console.error('Error details:', error.response?.data);
      throw error;
    }
  };

  const createMutation = useMutation({
    mutationFn: (data: TopicFormData) => topicService.createTopic(data),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['topics'] });
      navigate('/topics');
    },
  });

  const updateMutation = useMutation({
    mutationFn: (data: TopicFormData) => topicService.updateTopic(id!, data),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['topics'] });
      navigate('/topics');
    },
  });

  const onSubmit = async (data: TopicFormData) => {
    try {
      // Upload media files first
      const mediaPaths = await uploadMediaFiles();

      // Use custom category if "Add New" is selected
      const categoryValue = isNewCategory ? customCategory : data.category;

      if (!categoryValue || categoryValue.trim() === '') {
        alert('Please enter a category');
        return;
      }

      // Prepare form data with uploaded paths and fun facts
      const topicData: TopicFormData = {
        ...data,
        category: categoryValue,
        thumbnailPath: mediaPaths.thumbnailPath || data.thumbnailPath,
        imagePaths: mediaPaths.imagePaths.length > 0 ? mediaPaths.imagePaths : data.imagePaths || [],
        videoPath: mediaPaths.videoPath || data.videoPath,
        audioPath: mediaPaths.audioPath || data.audioPath,
        funFacts: funFactsList.filter((fact) => fact.trim() !== ''),
        relatedTopicIds: data.relatedTopicIds || [],
      };

      if (isEditMode) {
        updateMutation.mutate(topicData);
      } else {
        createMutation.mutate(topicData);
      }
    } catch (error: any) {
      console.error('Submit error:', error);
      const errorDetails = error.response?.data?.details || error.response?.data?.error || error.message || 'Unknown error';
      alert(`Failed to save topic: ${errorDetails}`);
    }
  };

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <div className="flex items-center gap-4">
          <button
            onClick={() => navigate('/topics')}
            className="rounded-lg p-2 hover:bg-gray-100"
          >
            <ArrowLeft className="h-5 w-5" />
          </button>
          <h1 className="text-3xl font-bold text-gray-900">
            {isEditMode ? 'Edit Topic' : 'Create New Topic'}
          </h1>
        </div>
      </div>

      <form onSubmit={handleSubmit(onSubmit)} className="space-y-6">
        <div className="rounded-lg bg-white p-6 shadow">
          <div className="space-y-4">
            {/* Title */}
            <div>
              <label className="block text-sm font-medium text-gray-700">
                Title *
              </label>
              <input
                {...register('title', { required: 'Title is required' })}
                type="text"
                className="mt-1 block w-full rounded-md border border-gray-300 px-3 py-2 shadow-sm focus:border-primary-500 focus:outline-none focus:ring-1 focus:ring-primary-500"
              />
              {errors.title && (
                <p className="mt-1 text-sm text-red-600">{errors.title.message}</p>
              )}
            </div>

            {/* Category */}
            <div>
              <div className="flex items-center justify-between mb-2">
                <label className="block text-sm font-medium text-gray-700">
                  Category *
                </label>
                <button
                  type="button"
                  onClick={() => setIsNewCategory(!isNewCategory)}
                  className="text-sm text-primary-600 hover:text-primary-700 font-medium flex items-center gap-1"
                >
                  <Plus className="h-4 w-4" />
                  {isNewCategory ? 'Select Existing' : 'Create New Category'}
                </button>
              </div>
              
              {isNewCategory ? (
                <input
                  type="text"
                  value={customCategory}
                  onChange={(e) => setCustomCategory(e.target.value)}
                  placeholder="Enter new category name (e.g., technology, culture)"
                  className="mt-1 block w-full rounded-md border border-gray-300 px-3 py-2 shadow-sm focus:border-primary-500 focus:outline-none focus:ring-1 focus:ring-primary-500"
                  autoFocus
                />
              ) : (
                <select
                  {...register('category', { required: !isNewCategory && 'Category is required' })}
                  className="mt-1 block w-full rounded-md border border-gray-300 px-3 py-2 shadow-sm focus:border-primary-500 focus:outline-none focus:ring-1 focus:ring-primary-500"
                >
                  <option value="">Select a category</option>
                  {categories?.map((category) => (
                    <option key={category} value={category}>
                      {category}
                    </option>
                  ))}
                </select>
              )}
              
              {!isNewCategory && errors.category && (
                <p className="mt-1 text-sm text-red-600">{errors.category.message}</p>
              )}
              
              <p className="mt-1 text-xs text-gray-500">
                {isNewCategory 
                  ? 'Enter a unique category name for organizing topics'
                  : `${categories?.length || 0} existing categories available`}
              </p>
            </div>

            {/* Summary */}
            <div>
              <label className="block text-sm font-medium text-gray-700">
                Summary *
              </label>
              <textarea
                {...register('summary', { required: 'Summary is required' })}
                rows={3}
                className="mt-1 block w-full rounded-md border border-gray-300 px-3 py-2 shadow-sm focus:border-primary-500 focus:outline-none focus:ring-1 focus:ring-primary-500"
              />
              {errors.summary && (
                <p className="mt-1 text-sm text-red-600">{errors.summary.message}</p>
              )}
            </div>

            {/* Content (Learn More) */}
            <div>
              <label className="block text-sm font-medium text-gray-700">
                Content (Learn More) *
              </label>
              <textarea
                {...register('content', { required: 'Content is required' })}
                rows={10}
                placeholder="Detailed educational content..."
                className="mt-1 block w-full rounded-md border border-gray-300 px-3 py-2 shadow-sm focus:border-primary-500 focus:outline-none focus:ring-1 focus:ring-primary-500"
              />
              {errors.content && (
                <p className="mt-1 text-sm text-red-600">{errors.content.message}</p>
              )}
            </div>

            {/* Thumbnail Image */}
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-2">
                Thumbnail Image *
              </label>
              <div
                {...getThumbnailRootProps()}
                className={`border-2 border-dashed rounded-lg p-6 text-center cursor-pointer transition-colors ${
                  isThumbnailDragActive
                    ? 'border-primary-500 bg-primary-50'
                    : 'border-gray-300 hover:border-primary-400'
                }`}
              >
                <input {...getThumbnailInputProps()} />
                <ImageIcon className="h-12 w-12 mx-auto text-gray-400 mb-2" />
                <p className="text-sm text-gray-600">
                  {isThumbnailDragActive
                    ? 'Drop thumbnail here...'
                    : 'Click to select thumbnail or drag & drop'}
                </p>
                <p className="text-xs text-gray-500 mt-1">PNG, JPG up to 5MB</p>
              </div>
              
              {/* Show existing thumbnail */}
              {!thumbnailFile && existingThumbnail && (
                <div className="mt-4">
                  <p className="text-xs text-gray-500 mb-2">Current Thumbnail:</p>
                  <div className="relative group inline-block">
                    <img
                      src={`http://localhost:8080${existingThumbnail}`}
                      alt="Current thumbnail"
                      className="h-32 w-32 object-cover rounded-lg border-2 border-gray-200"
                      onError={(e) => {
                        e.currentTarget.src = 'data:image/svg+xml,%3Csvg xmlns="http://www.w3.org/2000/svg" width="100" height="100"%3E%3Crect fill="%23ddd" width="100" height="100"/%3E%3Ctext fill="%23999" x="50%25" y="50%25" text-anchor="middle" dy=".3em"%3ENo Preview%3C/text%3E%3C/svg%3E';
                      }}
                    />
                    <button
                      type="button"
                      onClick={() => setExistingThumbnail('')}
                      className="absolute -top-2 -right-2 bg-red-500 text-white rounded-full p-1 opacity-0 group-hover:opacity-100 transition-opacity"
                    >
                      <X className="h-4 w-4" />
                    </button>
                  </div>
                  <p className="text-xs text-gray-600 mt-2">{existingThumbnail}</p>
                </div>
              )}
              
              {/* Show new thumbnail */}
              {thumbnailFile && (
                <div className="mt-4">
                  <p className="text-xs text-gray-500 mb-2">New Thumbnail:</p>
                  <div className="relative group inline-block">
                    <img
                      src={URL.createObjectURL(thumbnailFile)}
                      alt="Thumbnail preview"
                      className="h-32 w-32 object-cover rounded-lg border-2 border-green-400"
                    />
                    <button
                      type="button"
                      onClick={() => setThumbnailFile(null)}
                      className="absolute -top-2 -right-2 bg-red-500 text-white rounded-full p-1 opacity-0 group-hover:opacity-100 transition-opacity"
                    >
                      <X className="h-4 w-4" />
                    </button>
                  </div>
                  <p className="text-sm text-gray-600 mt-2">{thumbnailFile.name}</p>
                </div>
              )}
            </div>

            {/* Gallery (Multiple Images) */}
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-2">
                Gallery Images
              </label>
              <div
                {...getGalleryRootProps()}
                className={`border-2 border-dashed rounded-lg p-6 text-center cursor-pointer transition-colors ${
                  isGalleryDragActive
                    ? 'border-primary-500 bg-primary-50'
                    : 'border-gray-300 hover:border-primary-400'
                }`}
              >
                <input {...getGalleryInputProps()} />
                <ImageIcon className="h-12 w-12 mx-auto text-gray-400 mb-2" />
                <p className="text-sm text-gray-600">
                  {isGalleryDragActive
                    ? 'Drop images here...'
                    : 'Click to select images or drag & drop'}
                </p>
                <p className="text-xs text-gray-500 mt-1">PNG, JPG, GIF up to 10MB</p>
              </div>
              
              {/* Show existing gallery images */}
              {existingGallery.length > 0 && (
                <div className="mt-4">
                  <p className="text-xs text-gray-500 mb-2">Current Gallery ({existingGallery.length} images):</p>
                  <div className="grid grid-cols-4 gap-4">
                    {existingGallery.map((imagePath, index) => (
                      <div key={`existing-${index}`} className="relative group">
                        <img
                          src={`http://localhost:8080${imagePath}`}
                          alt={`Existing gallery ${index + 1}`}
                          className="w-full h-24 object-cover rounded-lg border-2 border-gray-200"
                          onError={(e) => {
                            e.currentTarget.src = 'data:image/svg+xml,%3Csvg xmlns="http://www.w3.org/2000/svg" width="100" height="100"%3E%3Crect fill="%23ddd" width="100" height="100"/%3E%3Ctext fill="%23999" x="50%25" y="50%25" text-anchor="middle" dy=".3em"%3ENo Preview%3C/text%3E%3C/svg%3E';
                          }}
                        />
                        <button
                          type="button"
                          onClick={() => removeExistingGalleryImage(index)}
                          className="absolute top-1 right-1 bg-red-500 text-white rounded-full p-1 opacity-0 group-hover:opacity-100 transition-opacity"
                        >
                          <X className="h-4 w-4" />
                        </button>
                        <p className="text-xs text-gray-600 mt-1 truncate">{imagePath.split('/').pop()}</p>
                      </div>
                    ))}
                  </div>
                </div>
              )}
              
              {/* Show new gallery images to be uploaded */}
              {gallery.length > 0 && (
                <div className="mt-4">
                  <p className="text-xs text-green-600 mb-2">New Images ({gallery.length}):</p>
                  <div className="grid grid-cols-4 gap-4">
                    {gallery.map((file, index) => (
                      <div key={`new-${index}`} className="relative group">
                        <img
                          src={URL.createObjectURL(file)}
                          alt={`Gallery ${index + 1}`}
                          className="w-full h-24 object-cover rounded-lg border-2 border-green-400"
                        />
                        <button
                          type="button"
                          onClick={() => removeGalleryImage(index)}
                          className="absolute top-1 right-1 bg-red-500 text-white rounded-full p-1 opacity-0 group-hover:opacity-100 transition-opacity"
                        >
                          <X className="h-4 w-4" />
                        </button>
                        <p className="text-xs text-gray-600 mt-1 truncate">{file.name}</p>
                      </div>
                    ))}
                  </div>
                </div>
              )}
            </div>

            {/* Video Upload */}
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-2">
                Video
              </label>
              <div
                {...getVideoRootProps()}
                className={`border-2 border-dashed rounded-lg p-6 text-center cursor-pointer transition-colors ${
                  isVideoDragActive
                    ? 'border-primary-500 bg-primary-50'
                    : 'border-gray-300 hover:border-primary-400'
                }`}
              >
                <input {...getVideoInputProps()} />
                <Film className="h-12 w-12 mx-auto text-gray-400 mb-2" />
                <p className="text-sm text-gray-600">
                  {isVideoDragActive
                    ? 'Drop video here...'
                    : 'Click to select video or drag & drop'}
                </p>
                <p className="text-xs text-gray-500 mt-1">MP4, WebM, MOV up to 50MB</p>
              </div>
              
              {/* Show existing video */}
              {!videoFile && existingVideo && (
                <div className="mt-4 flex items-center justify-between bg-gray-50 p-3 rounded-lg border-2 border-gray-200">
                  <div className="flex items-center gap-2">
                    <Film className="h-5 w-5 text-gray-600" />
                    <div>
                      <span className="text-sm text-gray-700 block">Current: {existingVideo.split('/').pop()}</span>
                      <span className="text-xs text-gray-500">{existingVideo}</span>
                    </div>
                  </div>
                  <button
                    type="button"
                    onClick={() => setExistingVideo('')}
                    className="text-red-500 hover:text-red-700"
                    title="Remove existing video"
                  >
                    <X className="h-5 w-5" />
                  </button>
                </div>
              )}
              
              {/* Show new video */}
              {videoFile && (
                <div className="mt-4 flex items-center justify-between bg-green-50 p-3 rounded-lg border-2 border-green-400">
                  <div className="flex items-center gap-2">
                    <Film className="h-5 w-5 text-green-600" />
                    <div>
                      <span className="text-sm text-green-700 font-medium block">New: {videoFile.name}</span>
                      <span className="text-xs text-gray-500">{(videoFile.size / 1024 / 1024).toFixed(2)} MB</span>
                    </div>
                  </div>
                  <button
                    type="button"
                    onClick={() => setVideoFile(null)}
                    className="text-red-500 hover:text-red-700"
                  >
                    <X className="h-5 w-5" />
                  </button>
                </div>
              )}
            </div>

            {/* Narration (Audio) Upload */}
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-2">
                Narration (Audio)
              </label>
              <div
                {...getAudioRootProps()}
                className={`border-2 border-dashed rounded-lg p-6 text-center cursor-pointer transition-colors ${
                  isAudioDragActive
                    ? 'border-primary-500 bg-primary-50'
                    : 'border-gray-300 hover:border-primary-400'
                }`}
              >
                <input {...getAudioInputProps()} />
                <Music className="h-12 w-12 mx-auto text-gray-400 mb-2" />
                <p className="text-sm text-gray-600">
                  {isAudioDragActive
                    ? 'Drop audio here...'
                    : 'Click to select audio or drag & drop'}
                </p>
                <p className="text-xs text-gray-500 mt-1">MP3, WAV, OGG up to 10MB</p>
              </div>
              
              {/* Show existing audio */}
              {!audioFile && existingAudio && (
                <div className="mt-4 flex items-center justify-between bg-gray-50 p-3 rounded-lg border-2 border-gray-200">
                  <div className="flex items-center gap-2">
                    <Music className="h-5 w-5 text-gray-600" />
                    <div>
                      <span className="text-sm text-gray-700 block">Current: {existingAudio.split('/').pop()}</span>
                      <span className="text-xs text-gray-500">{existingAudio}</span>
                    </div>
                  </div>
                  <button
                    type="button"
                    onClick={() => setExistingAudio('')}
                    className="text-red-500 hover:text-red-700"
                    title="Remove existing audio"
                  >
                    <X className="h-5 w-5" />
                  </button>
                </div>
              )}
              
              {/* Show new audio */}
              {audioFile && (
                <div className="mt-4 flex items-center justify-between bg-green-50 p-3 rounded-lg border-2 border-green-400">
                  <div className="flex items-center gap-2">
                    <Music className="h-5 w-5 text-green-600" />
                    <div>
                      <span className="text-sm text-green-700 font-medium block">New: {audioFile.name}</span>
                      <span className="text-xs text-gray-500">{(audioFile.size / 1024 / 1024).toFixed(2)} MB</span>
                    </div>
                  </div>
                  <button
                    type="button"
                    onClick={() => setAudioFile(null)}
                    className="text-red-500 hover:text-red-700"
                  >
                    <X className="h-5 w-5" />
                  </button>
                </div>
              )}
            </div>

            {/* Thumbnail Path - Keep as text input for existing assets */}
            <div>
              <label className="block text-sm font-medium text-gray-700">
                Thumbnail Path (or use first gallery image)
              </label>
              <input
                {...register('thumbnailPath')}
                type="text"
                placeholder="assets/images/... or leave empty to use first gallery image"
                className="mt-1 block w-full rounded-md border border-gray-300 px-3 py-2 shadow-sm focus:border-primary-500 focus:outline-none focus:ring-1 focus:ring-primary-500"
              />
            </div>

            {/* Fun Facts */}
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-2">
                Fun Facts
              </label>
              <div className="space-y-2">
                {funFactsList.map((fact, index) => (
                  <div key={index} className="flex gap-2">
                    <input
                      type="text"
                      value={fact}
                      onChange={(e) => updateFunFact(index, e.target.value)}
                      placeholder={`Fun fact ${index + 1}`}
                      className="flex-1 rounded-md border border-gray-300 px-3 py-2 shadow-sm focus:border-primary-500 focus:outline-none focus:ring-1 focus:ring-primary-500"
                    />
                    {funFactsList.length > 1 && (
                      <button
                        type="button"
                        onClick={() => removeFunFact(index)}
                        className="px-3 py-2 text-red-600 hover:bg-red-50 rounded-md"
                      >
                        <X className="h-5 w-5" />
                      </button>
                    )}
                  </div>
                ))}
                <button
                  type="button"
                  onClick={addFunFact}
                  className="text-sm text-primary-600 hover:text-primary-700 font-medium"
                >
                  + Add Fun Fact
                </button>
              </div>
            </div>
          </div>

          <div className="mt-6 flex justify-end gap-4">
            <button
              type="button"
              onClick={() => navigate('/topics')}
              className="rounded-lg border border-gray-300 px-4 py-2 text-gray-700 hover:bg-gray-50"
              disabled={uploadingMedia}
            >
              Cancel
            </button>
            <button
              type="submit"
              disabled={uploadingMedia || createMutation.isPending || updateMutation.isPending}
              className="flex items-center gap-2 rounded-lg bg-primary-600 px-4 py-2 text-white hover:bg-primary-700 disabled:bg-gray-400 disabled:cursor-not-allowed"
            >
              {uploadingMedia ? (
                <>
                  <Upload className="h-5 w-5 animate-spin" />
                  Uploading Media...
                </>
              ) : (
                <>
                  <Save className="h-5 w-5" />
                  {isEditMode ? 'Update Topic' : 'Create Topic'}
                </>
              )}
            </button>
          </div>
        </div>
      </form>
    </div>
  );
};

export default TopicEditor;
