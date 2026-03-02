import { useState, useEffect, useCallback } from 'react';
import { useNavigate, useParams } from 'react-router-dom';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { useForm } from 'react-hook-form';
import { useDropzone } from 'react-dropzone';
import { ArrowLeft, Save, Upload, X, Image as ImageIcon, Music, Plus, Trash2 } from 'lucide-react';
import { gameService } from '../services/gameService';
import { topicService } from '../services/topicService';
import { mediaService } from '../services/mediaService';
import { Game } from '../types';

type GameFormData = Omit<Game, 'id' | 'createdAt'>;

// Game type configurations
interface PuzzleConfig {
  imagePath: string;
  gridSize: number; // 3=9 pieces, 4=16 pieces, 5=25 pieces
}

interface SoundMatchConfig {
  pairs: Array<{
    id: string;
    imagePath: string;
    audioPath: string;
    name: string;
  }>;
}

interface QuizConfig {
  questions: Array<{
    id: string;
    question: string;
    options: string[];
    correctIndex: number;
    explanation: string;
  }>;
}

const GameEditor = () => {
  const { id } = useParams();
  const navigate = useNavigate();
  const queryClient = useQueryClient();
  const isEditMode = !!id;

  // Form state
  const { register, handleSubmit, setValue, watch, formState: { errors } } = useForm<GameFormData>();
  const gameType = watch('type');
  const difficulty = watch('difficulty');

  // Media upload states
  const [uploadingMedia, setUploadingMedia] = useState(false);

  // Puzzle game states
  const [puzzleImage, setPuzzleImage] = useState<File | null>(null);
  const [existingPuzzleImage, setExistingPuzzleImage] = useState<string>('');

  // Sound match game states
  const [soundPairs, setSoundPairs] = useState<Array<{
    id: string;
    imageFile?: File;
    audioFile?: File;
    imagePath?: string;
    audioPath?: string;
    name: string;
  }>>([]);

  // Quiz game states
  const [quizQuestions, setQuizQuestions] = useState<Array<{
    id: string;
    question: string;
    options: string[];
    correctIndex: number;
    explanation: string;
  }>>([]);

  const { data: game } = useQuery({
    queryKey: ['game', id],
    queryFn: () => gameService.getGameById(id!),
    enabled: isEditMode,
  });

  const { data: topics } = useQuery({
    queryKey: ['topics'],
    queryFn: () => topicService.getAllTopics(),
  });

  useEffect(() => {
    if (game) {
      console.log('=== LOADING GAME FOR EDIT ===');
      console.log('Game:', game);
      console.log('Configuration Data:', game.configurationData);
      console.log('============================');
      
      // Set form values
      Object.keys(game).forEach((key) => {
        if (key !== 'configurationData') {
          setValue(key as any, (game as any)[key]);
        }
      });

      // Load game-specific configuration
      const config = game.configurationData;
      
      if (game.type === 'puzzle' && config) {
        const puzzleConfig = config as PuzzleConfig;
        console.log('Loading puzzle config:', puzzleConfig);
        if (puzzleConfig.imagePath) {
          console.log('Setting existing puzzle image:', puzzleConfig.imagePath);
          setExistingPuzzleImage(puzzleConfig.imagePath);
        }
      } else if (game.type === 'sound_match' && config) {
        const soundConfig = config as SoundMatchConfig;
        if (soundConfig.pairs && soundConfig.pairs.length > 0) {
          setSoundPairs(soundConfig.pairs.map(p => ({
            ...p,
            imagePath: p.imagePath,
            audioPath: p.audioPath,
          })));
        }
      } else if (game.type === 'quiz' && config) {
        const quizConfig = config as QuizConfig;
        if (quizConfig.questions && quizConfig.questions.length > 0) {
          setQuizQuestions(quizConfig.questions);
        }
      }
    }
  }, [game, setValue]);

  // Get grid size based on difficulty
  const getGridSize = (diff: string) => {
    switch (diff) {
      case 'easy': return 3; // 9 pieces
      case 'medium': return 4; // 16 pieces
      case 'hard': return 5; // 25 pieces
      default: return 3;
    }
  };

  // Get number of options based on difficulty
  const getQuizOptionsCount = (diff: string) => {
    switch (diff) {
      case 'easy': return 2;
      case 'medium': return 4;
      case 'hard': return 6;
      default: return 4;
    }
  };

  // Puzzle image dropzone
  const onPuzzleImageDrop = useCallback((acceptedFiles: File[]) => {
    if (acceptedFiles.length > 0) {
      setPuzzleImage(acceptedFiles[0]);
      setExistingPuzzleImage(''); // Clear existing when uploading new
    }
  }, []);

  const { getRootProps: getPuzzleRootProps, getInputProps: getPuzzleInputProps, isDragActive: isPuzzleDragActive } = useDropzone({
    onDrop: onPuzzleImageDrop,
    accept: { 'image/*': ['.png', '.jpg', '.jpeg', '.gif', '.webp'] },
    multiple: false,
  });

  // Sound Match Helper Functions
  const addSoundPair = () => {
    setSoundPairs([...soundPairs, {
      id: `pair-${Date.now()}`,
      name: `Pair ${soundPairs.length + 1}`,
    }]);
  };

  const removeSoundPair = (index: number) => {
    setSoundPairs(soundPairs.filter((_, i) => i !== index));
  };

  const updateSoundPairName = (index: number, name: string) => {
    const updated = [...soundPairs];
    updated[index].name = name;
    setSoundPairs(updated);
  };

  const updateSoundPairImage = (index: number, file: File) => {
    const updated = [...soundPairs];
    updated[index].imageFile = file;
    updated[index].imagePath = undefined; // Clear existing path
    setSoundPairs(updated);
  };

  const updateSoundPairAudio = (index: number, file: File) => {
    const updated = [...soundPairs];
    updated[index].audioFile = file;
    updated[index].audioPath = undefined; // Clear existing path
    setSoundPairs(updated);
  };

  const removeExistingSoundPairImage = (index: number) => {
    const updated = [...soundPairs];
    updated[index].imagePath = undefined;
    setSoundPairs(updated);
  };

  const removeExistingSoundPairAudio = (index: number) => {
    const updated = [...soundPairs];
    updated[index].audioPath = undefined;
    setSoundPairs(updated);
  };

  // Quiz Helper Functions
  const addQuizQuestion = () => {
    const optionsCount = getQuizOptionsCount(difficulty || 'medium');
    setQuizQuestions([...quizQuestions, {
      id: `question-${Date.now()}`,
      question: '',
      options: Array(optionsCount).fill(''),
      correctIndex: 0,
      explanation: '',
    }]);
  };

  const removeQuizQuestion = (index: number) => {
    setQuizQuestions(quizQuestions.filter((_, i) => i !== index));
  };

  const updateQuizQuestion = (index: number, field: string, value: any) => {
    const updated = [...quizQuestions];
    (updated[index] as any)[field] = value;
    setQuizQuestions(updated);
  };

  const updateQuizOption = (questionIndex: number, optionIndex: number, value: string) => {
    const updated = [...quizQuestions];
    updated[questionIndex].options[optionIndex] = value;
    setQuizQuestions(updated);
  };

  // Upload media files
  const uploadGameAssets = async () => {
    const uploadedData: any = {};

    try {
      setUploadingMedia(true);

      // Upload puzzle image
      if (puzzleImage) {
        const formData = new FormData();
        formData.append('file', puzzleImage);
        formData.append('type', 'image');
        formData.append('category', 'games/puzzle');
        
        const response = await mediaService.uploadFile(formData);
        uploadedData.puzzleImage = response.path;
      }

      // Upload sound match pairs
      if (soundPairs.length > 0) {
        uploadedData.soundPairs = [];
        
        for (const pair of soundPairs) {
          const uploadedPair: any = {
            id: pair.id,
            name: pair.name,
            imagePath: pair.imagePath || '',
            audioPath: pair.audioPath || '',
          };

          // Upload image if new file
          if (pair.imageFile) {
            const formData = new FormData();
            formData.append('file', pair.imageFile);
            formData.append('type', 'image');
            formData.append('category', 'games/sound-match');
            
            const response = await mediaService.uploadFile(formData);
            uploadedPair.imagePath = response.path;
          }

          // Upload audio if new file
          if (pair.audioFile) {
            const formData = new FormData();
            formData.append('file', pair.audioFile);
            formData.append('type', 'audio');
            formData.append('category', 'games/sound-match');
            
            const response = await mediaService.uploadFile(formData);
            uploadedPair.audioPath = response.path;
          }

          uploadedData.soundPairs.push(uploadedPair);
        }
      }

      setUploadingMedia(false);
      return uploadedData;
    } catch (error) {
      setUploadingMedia(false);
      console.error('Upload error:', error);
      throw error;
    }
  };

  const createMutation = useMutation({
    mutationFn: (data: GameFormData) => gameService.createGame(data),
    onSuccess: async (createdGame) => {
      console.log('✅ CREATE SUCCESS:', createdGame);
      console.log('Invalidating games query...');
      await queryClient.invalidateQueries({ queryKey: ['games'] });
      console.log('Navigating to /games...');
      navigate('/games');
    },
    onError: (error) => {
      console.error('❌ CREATE ERROR:', error);
    },
  });

  const updateMutation = useMutation({
    mutationFn: (data: GameFormData) => gameService.updateGame(id!, data),
    onSuccess: async (updatedGame) => {
      console.log('✅ UPDATE SUCCESS:', updatedGame);
      console.log('Invalidating queries...');
      // Invalidate both the specific game and all games list
      await queryClient.invalidateQueries({ queryKey: ['game', id] });
      await queryClient.invalidateQueries({ queryKey: ['games'] });
      console.log('Navigating to /games...');
      navigate('/games');
    },
    onError: (error) => {
      console.error('❌ UPDATE ERROR:', error);
    },
  });

  const onSubmit = async (data: GameFormData) => {
    try {
      let configurationData: any = {};

      // Upload assets
      const uploadedAssets = await uploadGameAssets();

      // Build configuration based on game type
      if (data.type === 'puzzle') {
        const gridSize = getGridSize(data.difficulty);
        configurationData = {
          imagePath: uploadedAssets.puzzleImage || existingPuzzleImage,
          gridSize,
        } as PuzzleConfig;

        console.log('=== PUZZLE CONFIG DEBUG ===');
        console.log('Uploaded puzzle image:', uploadedAssets.puzzleImage);
        console.log('Existing puzzle image:', existingPuzzleImage);
        console.log('Final configuration:', configurationData);
        console.log('==========================');

        if (!configurationData.imagePath) {
          alert('Please upload a puzzle image');
          return;
        }
      } else if (data.type === 'sound_match') {
        if (uploadedAssets.soundPairs && uploadedAssets.soundPairs.length === 6) {
          configurationData = {
            pairs: uploadedAssets.soundPairs,
          } as SoundMatchConfig;
        } else {
          alert('Sound Match game requires exactly 6 pairs (image + audio)');
          return;
        }
      } else if (data.type === 'quiz') {
        if (quizQuestions.length === 0) {
          alert('Quiz game requires at least 1 question');
          return;
        }

        // Validate all questions
        for (const q of quizQuestions) {
          if (!q.question.trim()) {
            alert('All questions must have text');
            return;
          }
          if (q.options.some(o => !o.trim())) {
            alert('All options must have text');
            return;
          }
        }

        configurationData = {
          questions: quizQuestions,
        } as QuizConfig;
      }

      const gameData: GameFormData = {
        ...data,
        configurationData,
      };
      
      console.log('=== SUBMITTING GAME DATA ===');
      console.log('Is Edit Mode:', isEditMode);
      console.log('Game ID:', id);
      console.log('Game Data:', JSON.stringify(gameData, null, 2));
      console.log('===========================');
      
      if (isEditMode) {
        await updateMutation.mutateAsync(gameData);
      } else {
        await createMutation.mutateAsync(gameData);
      }
    } catch (error: any) {
      console.error('Submit error:', error);
      alert(`Failed to save game: ${error.message || 'Unknown error'}`);
    }
  };

  const gameTypes = [
    { value: 'puzzle', label: 'Puzzle', description: 'Image puzzle game' },
    { value: 'quiz', label: 'Quiz', description: 'Multiple choice questions' },
    { value: 'sound_match', label: 'Sound Match', description: 'Match sounds with items' },
  ];

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <div className="flex items-center gap-4">
          <button
            onClick={() => navigate('/games')}
            className="rounded-lg p-2 hover:bg-gray-100"
          >
            <ArrowLeft className="h-5 w-5" />
          </button>
          <h1 className="text-3xl font-bold text-gray-900">
            {isEditMode ? 'Edit Game' : 'Create New Game'}
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

            {/* Game Type */}
            <div>
              <label className="block text-sm font-medium text-gray-700">
                Game Type *
              </label>
              <select
                {...register('type', { required: 'Game type is required' })}
                className="mt-1 block w-full rounded-md border border-gray-300 px-3 py-2 shadow-sm focus:border-primary-500 focus:outline-none focus:ring-1 focus:ring-primary-500"
              >
                <option value="">Select a game type</option>
                {gameTypes.map((type) => (
                  <option key={type.value} value={type.value}>
                    {type.label} - {type.description}
                  </option>
                ))}
              </select>
              {errors.type && (
                <p className="mt-1 text-sm text-red-600">{errors.type.message}</p>
              )}
            </div>

            {/* Topic */}
            <div>
              <label className="block text-sm font-medium text-gray-700">
                Topic *
              </label>
              <select
                {...register('topicId', { required: 'Topic is required' })}
                className="mt-1 block w-full rounded-md border border-gray-300 px-3 py-2 shadow-sm focus:border-primary-500 focus:outline-none focus:ring-1 focus:ring-primary-500"
              >
                <option value="">Select a topic</option>
                {topics?.map((topic) => (
                  <option key={topic.id} value={topic.id}>
                    {topic.title} ({topic.category})
                  </option>
                ))}
              </select>
              {errors.topicId && (
                <p className="mt-1 text-sm text-red-600">{errors.topicId.message}</p>
              )}
            </div>

            {/* Difficulty */}
            <div>
              <label className="block text-sm font-medium text-gray-700">
                Difficulty *
              </label>
              <select
                {...register('difficulty', { required: 'Difficulty is required' })}
                className="mt-1 block w-full rounded-md border border-gray-300 px-3 py-2 shadow-sm focus:border-primary-500 focus:outline-none focus:ring-1 focus:ring-primary-500"
              >
                <option value="">Select difficulty</option>
                <option value="easy">Easy</option>
                <option value="medium">Medium</option>
                <option value="hard">Hard</option>
              </select>
              {errors.difficulty && (
                <p className="mt-1 text-sm text-red-600">{errors.difficulty.message}</p>
              )}
            </div>

            {/* Description */}
            <div>
              <label className="block text-sm font-medium text-gray-700">
                Description *
              </label>
              <textarea
                {...register('description', { required: 'Description is required' })}
                rows={3}
                className="mt-1 block w-full rounded-md border border-gray-300 px-3 py-2 shadow-sm focus:border-primary-500 focus:outline-none focus:ring-1 focus:ring-primary-500"
              />
              {errors.description && (
                <p className="mt-1 text-sm text-red-600">{errors.description.message}</p>
              )}
            </div>
          </div>
        </div>

        {/* Game-Specific Configuration */}
        {gameType === 'puzzle' && (
          <div className="rounded-lg bg-white p-6 shadow">
            <h2 className="mb-4 text-xl font-semibold text-gray-900">Puzzle Configuration</h2>
            
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-2">
                Puzzle Image *
              </label>
              <p className="text-sm text-gray-500 mb-2">
                This image will be sliced into {difficulty ? getGridSize(difficulty) : '?'}x{difficulty ? getGridSize(difficulty) : '?'} pieces
              </p>
              
              <div
                {...getPuzzleRootProps()}
                className={`border-2 border-dashed rounded-lg p-6 text-center cursor-pointer transition-colors ${
                  isPuzzleDragActive
                    ? 'border-primary-500 bg-primary-50'
                    : 'border-gray-300 hover:border-primary-400'
                }`}
              >
                <input {...getPuzzleInputProps()} />
                <ImageIcon className="h-12 w-12 mx-auto text-gray-400 mb-2" />
                <p className="text-sm text-gray-600">
                  {isPuzzleDragActive
                    ? 'Drop puzzle image here...'
                    : 'Click to select image or drag & drop'}
                </p>
                <p className="text-xs text-gray-500 mt-1">PNG, JPG, GIF up to 10MB</p>
              </div>

              {/* Show existing image */}
              {!puzzleImage && existingPuzzleImage && (
                <div className="mt-4">
                  <p className="text-xs text-gray-500 mb-2">Current Image:</p>
                  <div className="relative inline-block">
                    <img
                      src={`http://localhost:8080${existingPuzzleImage}`}
                      alt="Current puzzle"
                      className="h-48 w-auto object-contain rounded-lg border-2 border-gray-200"
                      onError={(e) => {
                        e.currentTarget.src = 'data:image/svg+xml,%3Csvg xmlns="http://www.w3.org/2000/svg" width="200" height="200"%3E%3Crect fill="%23ddd" width="200" height="200"/%3E%3Ctext fill="%23999" x="50%25" y="50%25" text-anchor="middle" dy=".3em"%3ENo Preview%3C/text%3E%3C/svg%3E';
                      }}
                    />
                    <button
                      type="button"
                      onClick={() => setExistingPuzzleImage('')}
                      className="absolute -top-2 -right-2 bg-red-500 text-white rounded-full p-1"
                    >
                      <X className="h-4 w-4" />
                    </button>
                  </div>
                </div>
              )}

              {/* Show new image */}
              {puzzleImage && (
                <div className="mt-4">
                  <p className="text-xs text-green-600 mb-2">New Image:</p>
                  <div className="relative inline-block">
                    <img
                      src={URL.createObjectURL(puzzleImage)}
                      alt="New puzzle"
                      className="h-48 w-auto object-contain rounded-lg border-2 border-green-400"
                    />
                    <button
                      type="button"
                      onClick={() => setPuzzleImage(null)}
                      className="absolute -top-2 -right-2 bg-red-500 text-white rounded-full p-1"
                    >
                      <X className="h-4 w-4" />
                    </button>
                  </div>
                  <p className="text-sm text-gray-600 mt-2">{puzzleImage.name}</p>
                </div>
              )}
            </div>
          </div>
        )}

        {gameType === 'sound_match' && (
          <div className="rounded-lg bg-white p-6 shadow">
            <div className="flex items-center justify-between mb-4">
              <div>
                <h2 className="text-xl font-semibold text-gray-900">Sound Match Configuration</h2>
                <p className="text-sm text-gray-500">Add exactly 6 pairs (image + audio)</p>
              </div>
              <button
                type="button"
                onClick={addSoundPair}
                disabled={soundPairs.length >= 6}
                className="flex items-center gap-2 rounded-lg bg-primary-600 px-4 py-2 text-white hover:bg-primary-700 disabled:bg-gray-400 disabled:cursor-not-allowed"
              >
                <Plus className="h-5 w-5" />
                Add Pair
              </button>
            </div>

            {soundPairs.length === 0 && (
              <div className="text-center py-8 text-gray-500">
                No pairs added yet. Click "Add Pair" to start.
              </div>
            )}

            <div className="space-y-4">
              {soundPairs.map((pair, index) => (
                <div key={pair.id} className="border rounded-lg p-4">
                  <div className="flex items-center justify-between mb-3">
                    <input
                      type="text"
                      value={pair.name}
                      onChange={(e) => updateSoundPairName(index, e.target.value)}
                      placeholder="Pair name (e.g., Dog, Cat)"
                      className="flex-1 rounded-md border border-gray-300 px-3 py-2 mr-2"
                    />
                    <button
                      type="button"
                      onClick={() => removeSoundPair(index)}
                      className="text-red-600 hover:bg-red-50 rounded p-2"
                    >
                      <Trash2 className="h-5 w-5" />
                    </button>
                  </div>

                  <div className="grid grid-cols-2 gap-4">
                    {/* Image Upload */}
                    <div>
                      <label className="block text-sm font-medium text-gray-700 mb-2">
                        Image
                      </label>
                      <input
                        type="file"
                        accept="image/*"
                        onChange={(e) => {
                          if (e.target.files && e.target.files[0]) {
                            updateSoundPairImage(index, e.target.files[0]);
                          }
                        }}
                        className="block w-full text-sm text-gray-500 file:mr-4 file:py-2 file:px-4 file:rounded-md file:border-0 file:text-sm file:font-semibold file:bg-primary-50 file:text-primary-700 hover:file:bg-primary-100"
                      />
                      
                      {pair.imagePath && !pair.imageFile && (
                        <div className="mt-2 relative">
                          <img
                            src={`http://localhost:8080${pair.imagePath}`}
                            alt={pair.name}
                            className="h-24 w-24 object-cover rounded border"
                            onError={(e) => {
                              e.currentTarget.src = 'data:image/svg+xml,%3Csvg xmlns="http://www.w3.org/2000/svg" width="100" height="100"%3E%3Crect fill="%23ddd" width="100" height="100"/%3E%3Ctext fill="%23999" x="50%25" y="50%25" text-anchor="middle" dy=".3em"%3ENo Preview%3C/text%3E%3C/svg%3E';
                            }}
                          />
                          <button
                            type="button"
                            onClick={() => removeExistingSoundPairImage(index)}
                            className="absolute -top-1 -right-1 bg-red-500 text-white rounded-full p-1"
                          >
                            <X className="h-3 w-3" />
                          </button>
                        </div>
                      )}
                      
                      {pair.imageFile && (
                        <div className="mt-2 relative">
                          <img
                            src={URL.createObjectURL(pair.imageFile)}
                            alt="Preview"
                            className="h-24 w-24 object-cover rounded border-2 border-green-400"
                          />
                          <span className="text-xs text-green-600">New</span>
                        </div>
                      )}
                    </div>

                    {/* Audio Upload */}
                    <div>
                      <label className="block text-sm font-medium text-gray-700 mb-2">
                        Audio
                      </label>
                      <input
                        type="file"
                        accept="audio/*"
                        onChange={(e) => {
                          if (e.target.files && e.target.files[0]) {
                            updateSoundPairAudio(index, e.target.files[0]);
                          }
                        }}
                        className="block w-full text-sm text-gray-500 file:mr-4 file:py-2 file:px-4 file:rounded-md file:border-0 file:text-sm file:font-semibold file:bg-primary-50 file:text-primary-700 hover:file:bg-primary-100"
                      />
                      
                      {pair.audioPath && !pair.audioFile && (
                        <div className="mt-2 flex items-center gap-2">
                          <Music className="h-5 w-5 text-gray-600" />
                          <span className="text-xs text-gray-600">{pair.audioPath.split('/').pop()}</span>
                          <button
                            type="button"
                            onClick={() => removeExistingSoundPairAudio(index)}
                            className="text-red-500 hover:text-red-700"
                          >
                            <X className="h-4 w-4" />
                          </button>
                        </div>
                      )}
                      
                      {pair.audioFile && (
                        <div className="mt-2 flex items-center gap-2">
                          <Music className="h-5 w-5 text-green-600" />
                          <span className="text-xs text-green-600">{pair.audioFile.name}</span>
                        </div>
                      )}
                    </div>
                  </div>
                </div>
              ))}
            </div>

            {soundPairs.length > 0 && soundPairs.length < 6 && (
              <div className="mt-4 text-center text-sm text-orange-600">
                Add {6 - soundPairs.length} more pair(s) to complete the game
              </div>
            )}
            
            {soundPairs.length === 6 && (
              <div className="mt-4 text-center text-sm text-green-600">
                ✓ All 6 pairs added!
              </div>
            )}
          </div>
        )}

        {gameType === 'quiz' && (
          <div className="rounded-lg bg-white p-6 shadow">
            <div className="flex items-center justify-between mb-4">
              <div>
                <h2 className="text-xl font-semibold text-gray-900">Quiz Configuration</h2>
                <p className="text-sm text-gray-500">
                  {difficulty ? `${getQuizOptionsCount(difficulty)} options per question` : 'Select difficulty first'}
                </p>
              </div>
              <button
                type="button"
                onClick={addQuizQuestion}
                disabled={!difficulty}
                className="flex items-center gap-2 rounded-lg bg-primary-600 px-4 py-2 text-white hover:bg-primary-700 disabled:bg-gray-400 disabled:cursor-not-allowed"
              >
                <Plus className="h-5 w-5" />
                Add Question
              </button>
            </div>

            {quizQuestions.length === 0 && (
              <div className="text-center py-8 text-gray-500">
                No questions added yet. Click "Add Question" to start.
              </div>
            )}

            <div className="space-y-6">
              {quizQuestions.map((question, qIndex) => (
                <div key={question.id} className="border rounded-lg p-4">
                  <div className="flex items-start justify-between mb-3">
                    <h3 className="font-medium text-gray-900">Question {qIndex + 1}</h3>
                    <button
                      type="button"
                      onClick={() => removeQuizQuestion(qIndex)}
                      className="text-red-600 hover:bg-red-50 rounded p-2"
                    >
                      <Trash2 className="h-5 w-5" />
                    </button>
                  </div>

                  {/* Question Text */}
                  <div className="mb-3">
                    <label className="block text-sm font-medium text-gray-700 mb-1">
                      Question *
                    </label>
                    <textarea
                      value={question.question}
                      onChange={(e) => updateQuizQuestion(qIndex, 'question', e.target.value)}
                      placeholder="Enter your question..."
                      rows={2}
                      className="block w-full rounded-md border border-gray-300 px-3 py-2"
                    />
                  </div>

                  {/* Options */}
                  <div className="mb-3">
                    <label className="block text-sm font-medium text-gray-700 mb-2">
                      Options ({question.options.length})
                    </label>
                    <div className="space-y-2">
                      {question.options.map((option, oIndex) => (
                        <div key={oIndex} className="flex items-center gap-2">
                          <input
                            type="radio"
                            checked={question.correctIndex === oIndex}
                            onChange={() => updateQuizQuestion(qIndex, 'correctIndex', oIndex)}
                            className="h-4 w-4 text-primary-600"
                          />
                          <input
                            type="text"
                            value={option}
                            onChange={(e) => updateQuizOption(qIndex, oIndex, e.target.value)}
                            placeholder={`Option ${oIndex + 1}`}
                            className="flex-1 rounded-md border border-gray-300 px-3 py-2"
                          />
                          {question.correctIndex === oIndex && (
                            <span className="text-xs text-green-600 font-medium">Correct</span>
                          )}
                        </div>
                      ))}
                    </div>
                    <p className="text-xs text-gray-500 mt-1">
                      Select the radio button to mark the correct answer
                    </p>
                  </div>

                  {/* Explanation */}
                  <div>
                    <label className="block text-sm font-medium text-gray-700 mb-1">
                      Explanation
                    </label>
                    <textarea
                      value={question.explanation}
                      onChange={(e) => updateQuizQuestion(qIndex, 'explanation', e.target.value)}
                      placeholder="Explain why this is the correct answer..."
                      rows={2}
                      className="block w-full rounded-md border border-gray-300 px-3 py-2"
                    />
                  </div>
                </div>
              ))}
            </div>
          </div>
        )}

        {/* Submit Buttons */}
        <div className="flex justify-end gap-4">
          <button
            type="button"
            onClick={() => navigate('/games')}
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
                {isEditMode ? 'Update Game' : 'Create Game'}
              </>
            )}
          </button>
        </div>
      </form>
    </div>
  );
};

export default GameEditor;
