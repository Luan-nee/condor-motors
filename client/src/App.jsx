import { Route, Routes } from 'react-router-dom';
import './App.css';
import { FooterLayout } from './layouts/FooterLayout';
import { MainLayout } from './layouts/MainLayout';
import { HomePage } from './pages/Home';
import { Page404 } from './pages/Page404';

function App() {
  return (
    <Routes>
      <Route element={<MainLayout />}>
        <Route element={<FooterLayout />}>
          <Route path="/" element={<HomePage />} />
        </Route>
        <Route path="*" element={<Page404 />} />
      </Route>
    </Routes>
  );
}

export default App;
