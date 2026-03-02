import { useState } from 'react';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { Link } from 'react-router-dom';
import { Search, Plus, Trash2, Edit } from 'lucide-react';
import { gameService } from '../services/gameService';
import { topicService } from '../services/topicService';
import { Game } from '../types';
import { format } from 'date-fns';

const Games = () => {
  const [searchQuery, setSearchQuery] = useState('');
  const [selectedType, setSelectedType] = useState('all');
  const [selectedDifficulty, setSelectedDifficulty] = useState('all');
  const queryClient = useQueryClient();

  const { data: games, isLoading } = useQuery({
    queryKey: ['games'],
    queryFn: async () => {
      console.log('🔄 Fetching games from API...');
      const result = await gameService.getAllGames();
      console.log(`📦 Received ${result.length} games:`, result.map(g => g.title));
      return result;
    },
  });

  const { data: topics } = useQuery({
    queryKey: ['topics'],
    queryFn: () => topicService.getAllTopics(),
  });

  const deleteGameMutation = useMutation({
    mutationFn: (gameId: string) => gameService.deleteGame(gameId),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['games'] });
    },
  });

  const filteredGames = games?.filter((game) => {
    const matchesSearch = game.title.toLowerCase().includes(searchQuery.toLowerCase()) ||
      game.description.toLowerCase().includes(searchQuery.toLowerCase());
    const matchesType = selectedType === 'all' || game.type === selectedType;
    const matchesDifficulty = selectedDifficulty === 'all' || game.difficulty === selectedDifficulty;
    return matchesSearch && matchesType && matchesDifficulty;
  });

  const handleDeleteGame = async (gameId: string) => {
    if (window.confirm('Are you sure you want to delete this game?')) {
      await deleteGameMutation.mutateAsync(gameId);
    }
  };

  const getTopicTitle = (topicId: string) => {
    return topics?.find((t) => t.id === topicId)?.title || 'Unknown Topic';
  };

  const getDifficultyColor = (difficulty: string) => {
    switch (difficulty) {
      case 'easy':
        return 'bg-green-100 text-green-700';
      case 'medium':
        return 'bg-yellow-100 text-yellow-700';
      case 'hard':
        return 'bg-red-100 text-red-700';
      default:
        return 'bg-gray-100 text-gray-700';
    }
  };

  const getTypeIcon = (type: string) => {
    switch (type) {
      case 'puzzle':
        return '🧩';
      case 'quiz':
        return '❓';
      case 'sound_match':
        return '🔊';
      default:
        return '🎮';
    }
  };

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <h1 className="text-3xl font-bold text-gray-900">Games</h1>
        <Link
          to="/games/new"
          className="flex items-center gap-2 rounded-lg bg-primary-600 px-4 py-2 text-white hover:bg-primary-700"
        >
          <Plus className="h-5 w-5" />
          Add New Game
        </Link>
      </div>

      {/* Filters */}
      <div className="flex gap-4">
        <div className="relative flex-1">
          <Search className="absolute left-3 top-1/2 h-5 w-5 -translate-y-1/2 text-gray-400" />
          <input
            type="text"
            placeholder="Search games..."
            value={searchQuery}
            onChange={(e) => setSearchQuery(e.target.value)}
            className="w-full rounded-lg border border-gray-300 py-2 pl-10 pr-4 focus:border-primary-500 focus:outline-none focus:ring-1 focus:ring-primary-500"
          />
        </div>
        <select
          value={selectedType}
          onChange={(e) => setSelectedType(e.target.value)}
          className="rounded-lg border border-gray-300 px-4 py-2 focus:border-primary-500 focus:outline-none focus:ring-1 focus:ring-primary-500"
        >
          <option value="all">All Types</option>
          <option value="puzzle">Puzzle</option>
          <option value="quiz">Quiz</option>
          <option value="sound_match">Sound Match</option>
        </select>
        <select
          value={selectedDifficulty}
          onChange={(e) => setSelectedDifficulty(e.target.value)}
          className="rounded-lg border border-gray-300 px-4 py-2 focus:border-primary-500 focus:outline-none focus:ring-1 focus:ring-primary-500"
        >
          <option value="all">All Difficulties</option>
          <option value="easy">Easy</option>
          <option value="medium">Medium</option>
          <option value="hard">Hard</option>
        </select>
      </div>

      {/* Games Grid */}
      <div className="grid grid-cols-1 gap-6 md:grid-cols-2 lg:grid-cols-3">
        {isLoading ? (
          <div className="col-span-full text-center text-gray-500">Loading...</div>
        ) : filteredGames?.length === 0 ? (
          <div className="col-span-full text-center text-gray-500">No games found</div>
        ) : (
          filteredGames?.map((game) => (
            <div
              key={game.id}
              className="overflow-hidden rounded-lg bg-white shadow hover:shadow-lg transition-shadow"
            >
              <div className="bg-gradient-to-br from-primary-400 to-primary-600 p-6 text-center">
                <div className="text-6xl">{getTypeIcon(game.type)}</div>
              </div>
              <div className="p-4">
                <div className="mb-2 flex items-center justify-between">
                  <span className="rounded-full bg-primary-100 px-2 py-1 text-xs font-medium text-primary-700">
                    {game.type}
                  </span>
                  <span className={`rounded-full px-2 py-1 text-xs font-medium ${getDifficultyColor(game.difficulty)}`}>
                    {game.difficulty}
                  </span>
                </div>
                <h3 className="mb-2 text-lg font-semibold text-gray-900">
                  {game.title}
                </h3>
                <p className="mb-2 line-clamp-2 text-sm text-gray-600">
                  {game.description}
                </p>
                <p className="mb-4 text-xs text-gray-500">
                  Topic: {getTopicTitle(game.topicId)}
                </p>
                <div className="flex items-center justify-between">
                  <span className="text-xs text-gray-500">
                    {format(new Date(game.createdAt), 'MMM dd, yyyy')}
                  </span>
                  <div className="flex gap-2">
                    <Link
                      to={`/games/${game.id}/edit`}
                      className="rounded p-1 text-primary-600 hover:bg-primary-50"
                    >
                      <Edit className="h-4 w-4" />
                    </Link>
                    <button
                      onClick={() => handleDeleteGame(game.id)}
                      className="rounded p-1 text-red-600 hover:bg-red-50"
                    >
                      <Trash2 className="h-4 w-4" />
                    </button>
                  </div>
                </div>
              </div>
            </div>
          ))
        )}
      </div>
    </div>
  );
};

export default Games;
