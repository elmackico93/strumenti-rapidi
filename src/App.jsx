// src/App.jsx
import { BrowserRouter, Routes, Route } from 'react-router-dom';
import { ThemeProvider } from './context/ThemeContext';
import { OSProvider } from './context/OSContext';
import MainLayout from './components/layout/MainLayout';
import Home from './pages/Home';
import ToolsPage from './pages/ToolsPage';

// Create global registry for tools
window.toolRegistry = {
  'image-editor': {
    acceptedFormats: ['.jpg', '.jpeg', '.png', '.webp', '.gif', '.bmp'],
    maxFileSize: 50 * 1024 * 1024 // 50MB
  },
  'pdf-converter': {
    acceptedFormats: ['.pdf', '.docx', '.doc', '.jpg', '.jpeg', '.png'],
    maxFileSize: 100 * 1024 * 1024 // 100MB
  },
  'ocr': {
    acceptedFormats: ['.jpg', '.jpeg', '.png', '.bmp', '.gif', '.webp', '.pdf'],
    maxFileSize: 10 * 1024 * 1024 // 10MB
  },
  'video-downloader': {
    acceptedFormats: [],
    maxFileSize: 0
  },
  'calculator': {
    acceptedFormats: [],
    maxFileSize: 0
  },
  'meme-creator': {
    acceptedFormats: ['.jpg', '.jpeg', '.png', '.webp', '.gif'],
    maxFileSize: 10 * 1024 * 1024 // 10MB
  }
};

function App() {
  return (
    <ThemeProvider>
      <OSProvider>
        <BrowserRouter>
          <Routes>
            <Route path="/" element={<MainLayout />}>
              <Route index element={<Home />} />
              <Route path="tools/:toolId" element={<ToolsPage />} />
            </Route>
          </Routes>
        </BrowserRouter>
      </OSProvider>
    </ThemeProvider>
  );
}

export default App;
