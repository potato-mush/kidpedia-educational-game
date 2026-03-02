import { useState } from 'react';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { Link } from 'react-router-dom';
import { Search, Plus, Trash2, Edit, Eye } from 'lucide-react';
import { topicService } from '../services/topicService';
import { Topic } from '../types';
import { format } from 'date-fns';

const Topics = () => {
  const [searchQuery, setSearchQuery] = useState('');
  const [selectedCategory, setSelectedCategory] = useState('all');
  const queryClient = useQueryClient();

  const { data: topics, isLoading } = useQuery({
    queryKey: ['topics'],
    queryFn: () => topicService.getAllTopics(),
  });

  const { data: categories } = useQuery({
    queryKey: ['categories'],
    queryFn: () => topicService.getCategories(),
  });

  const deleteTopicMutation = useMutation({
    mutationFn: (topicId: string) => topicService.deleteTopic(topicId),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['topics'] });
    },
  });

  const filteredTopics = topics?.filter((topic) => {
    const matchesSearch = topic.title.toLowerCase().includes(searchQuery.toLowerCase()) ||
      topic.summary.toLowerCase().includes(searchQuery.toLowerCase());
    const matchesCategory = selectedCategory === 'all' || topic.category === selectedCategory;
    return matchesSearch && matchesCategory;
  });

  const handleDeleteTopic = async (topicId: string) => {
    if (window.confirm('Are you sure you want to delete this topic?')) {
      await deleteTopicMutation.mutateAsync(topicId);
    }
  };

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <h1 className="text-3xl font-bold text-gray-900">Topics / Wiki</h1>
        <Link
          to="/topics/new"
          className="flex items-center gap-2 rounded-lg bg-primary-600 px-4 py-2 text-white hover:bg-primary-700"
        >
          <Plus className="h-5 w-5" />
          Add New Topic
        </Link>
      </div>

      {/* Filters */}
      <div className="flex gap-4">
        <div className="relative flex-1">
          <Search className="absolute left-3 top-1/2 h-5 w-5 -translate-y-1/2 text-gray-400" />
          <input
            type="text"
            placeholder="Search topics..."
            value={searchQuery}
            onChange={(e) => setSearchQuery(e.target.value)}
            className="w-full rounded-lg border border-gray-300 py-2 pl-10 pr-4 focus:border-primary-500 focus:outline-none focus:ring-1 focus:ring-primary-500"
          />
        </div>
        <select
          value={selectedCategory}
          onChange={(e) => setSelectedCategory(e.target.value)}
          className="rounded-lg border border-gray-300 px-4 py-2 focus:border-primary-500 focus:outline-none focus:ring-1 focus:ring-primary-500"
        >
          <option value="all">All Categories</option>
          {categories?.map((category) => (
            <option key={category} value={category}>
              {category}
            </option>
          ))}
        </select>
      </div>

      {/* Topics Grid */}
      <div className="grid grid-cols-1 gap-6 md:grid-cols-2 lg:grid-cols-3">
        {isLoading ? (
          <div className="col-span-full text-center text-gray-500">Loading...</div>
        ) : filteredTopics?.length === 0 ? (
          <div className="col-span-full text-center text-gray-500">No topics found</div>
        ) : (
          filteredTopics?.map((topic) => (
            <div
              key={topic.id}
              className="overflow-hidden rounded-lg bg-white shadow hover:shadow-lg transition-shadow"
            >
              <div className="aspect-video bg-gray-200">
                {topic.thumbnailPath && (
                  <img
                    src={topic.thumbnailPath}
                    alt={topic.title}
                    className="h-full w-full object-cover"
                  />
                )}
              </div>
              <div className="p-4">
                <div className="mb-2 flex items-center justify-between">
                  <span className="rounded-full bg-primary-100 px-2 py-1 text-xs font-medium text-primary-700">
                    {topic.category}
                  </span>
                  <span className="text-sm text-gray-500">
                    {topic.readCount} reads
                  </span>
                </div>
                <h3 className="mb-2 text-lg font-semibold text-gray-900">
                  {topic.title}
                </h3>
                <p className="mb-4 line-clamp-2 text-sm text-gray-600">
                  {topic.summary}
                </p>
                <div className="flex items-center justify-between">
                  <span className="text-xs text-gray-500">
                    {format(new Date(topic.createdAt), 'MMM dd, yyyy')}
                  </span>
                  <div className="flex gap-2">
                    <Link
                      to={`/topics/${topic.id}/edit`}
                      className="rounded p-1 text-primary-600 hover:bg-primary-50"
                    >
                      <Edit className="h-4 w-4" />
                    </Link>
                    <button
                      onClick={() => handleDeleteTopic(topic.id)}
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

export default Topics;
