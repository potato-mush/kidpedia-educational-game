import { useQuery } from '@tanstack/react-query';
import { Users, BookOpen, Gamepad2, TrendingUp } from 'lucide-react';
import { userService } from '../services/userService';
import { topicService } from '../services/topicService';
import { gameService } from '../services/gameService';

const Dashboard = () => {
  const { data: usersStats } = useQuery({
    queryKey: ['usersStatistics'],
    queryFn: () => userService.getUsersStatistics(),
  });

  const { data: topicsStats } = useQuery({
    queryKey: ['topicsStatistics'],
    queryFn: () => topicService.getTopicStatistics(),
  });

  const { data: gamesStats } = useQuery({
    queryKey: ['gamesStatistics'],
    queryFn: () => gameService.getGameStatistics(),
  });

  const stats = [
    {
      name: 'Total Users',
      value: usersStats?.totalUsers || 0,
      icon: Users,
      color: 'bg-blue-500',
    },
    {
      name: 'Total Topics',
      value: topicsStats?.totalTopics || 0,
      icon: BookOpen,
      color: 'bg-green-500',
    },
    {
      name: 'Total Games',
      value: gamesStats?.totalGames || 0,
      icon: Gamepad2,
      color: 'bg-purple-500',
    },
    {
      name: 'Active Users',
      value: usersStats?.activeUsers || 0,
      icon: TrendingUp,
      color: 'bg-orange-500',
    },
  ];

  return (
    <div className="space-y-6">
      <h1 className="text-3xl font-bold text-gray-900">Dashboard</h1>

      {/* Stats Grid */}
      <div className="grid grid-cols-1 gap-6 sm:grid-cols-2 lg:grid-cols-4">
        {stats.map((stat) => (
          <div
            key={stat.name}
            className="overflow-hidden rounded-lg bg-white shadow"
          >
            <div className="p-6">
              <div className="flex items-center">
                <div className={`rounded-md p-3 ${stat.color}`}>
                  <stat.icon className="h-6 w-6 text-white" />
                </div>
                <div className="ml-4">
                  <p className="text-sm font-medium text-gray-600">{stat.name}</p>
                  <p className="text-2xl font-semibold text-gray-900">
                    {stat.value}
                  </p>
                </div>
              </div>
            </div>
          </div>
        ))}
      </div>

      {/* Recent Activity */}
      <div className="grid grid-cols-1 gap-6 lg:grid-cols-2">
        <div className="rounded-lg bg-white p-6 shadow">
          <h2 className="mb-4 text-lg font-semibold text-gray-900">
            Popular Topics
          </h2>
          <div className="space-y-3">
            {topicsStats?.popularTopics?.slice(0, 5).map((topic: any) => (
              <div key={topic.id} className="flex items-center justify-between">
                <span className="text-sm text-gray-700">{topic.title}</span>
                <span className="text-sm font-medium text-gray-900">
                  {topic.readCount} reads
                </span>
              </div>
            ))}
          </div>
        </div>

        <div className="rounded-lg bg-white p-6 shadow">
          <h2 className="mb-4 text-lg font-semibold text-gray-900">
            Top Games
          </h2>
          <div className="space-y-3">
            {gamesStats?.topGames?.slice(0, 5).map((game: any) => (
              <div key={game.id} className="flex items-center justify-between">
                <span className="text-sm text-gray-700">{game.title}</span>
                <span className="text-sm font-medium text-gray-900">
                  {game.playCount} plays
                </span>
              </div>
            ))}
          </div>
        </div>
      </div>
    </div>
  );
};

export default Dashboard;
