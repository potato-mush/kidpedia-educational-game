import { Routes, Route, Navigate } from 'react-router-dom';
import Layout from './components/Layout';
import Dashboard from './pages/Dashboard';
import Users from './pages/Users';
import Topics from './pages/Topics';
import TopicEditor from './pages/TopicEditor';
import Games from './pages/Games';
import GameEditor from './pages/GameEditor';
import Media from './pages/Media';
import Login from './pages/Login';

function App() {
  const isAuthenticated = !!localStorage.getItem('adminToken');

  return (
    <Routes>
      <Route path="/login" element={<Login />} />
      <Route path="/" element={isAuthenticated ? <Layout /> : <Navigate to="/login" />}>
        <Route index element={<Dashboard />} />
        <Route path="users" element={<Users />} />
        <Route path="topics" element={<Topics />} />
        <Route path="topics/new" element={<TopicEditor />} />
        <Route path="topics/:id/edit" element={<TopicEditor />} />
        <Route path="games" element={<Games />} />
        <Route path="games/new" element={<GameEditor />} />
        <Route path="games/:id/edit" element={<GameEditor />} />
        <Route path="media" element={<Media />} />
      </Route>
    </Routes>
  );
}

export default App;
